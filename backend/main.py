import logging
from io import BytesIO
import os
import os
from pathlib import Path
from typing import List

import numpy as np
import tensorflow as tf
from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from huggingface_hub import hf_hub_download
from fastapi.responses import JSONResponse
from PIL import Image
from pydantic import BaseModel
from schemas.chat import ChatResponse

# -------------------------
# CONFIG
# -------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
# Download model from HF Hub if not available locally
_local_model = BASE_DIR / "malaria_model.keras"
if _local_model.exists():
    MODEL_PATH = _local_model
else:
    MODEL_PATH = Path(hf_hub_download(
        repo_id="Mari-25/malaria-model",
        filename="malaria_model.keras",
        token=os.getenv("HF_TOKEN")
    ))
    
IMG_SIZE = (64, 64)
# Must match the notebook's image_dataset_from_directory(class_names=...) order.
CLASS_NAMES = ["Parasitized", "Uninfected", "NotACellImage"]
DISPLAY_LABELS = {
    "Parasitized": "Parasitized",
    "Uninfected": "Uninfected",
    "NotACellImage": "Not Cell Image",
}
CONFIDENCE_THRESHOLD = 0.60
logger = logging.getLogger("malaria_api")


class PredictionResult(BaseModel):
    image_name: str
    prediction: str
    confidence: float


class BatchSummary(BaseModel):
    total_images: int
    parasitized_count: int
    uninfected_count: int
    invalid_images_count: int
    infection_percentage: float


class BatchPredictionResponse(BaseModel):
    results: List[PredictionResult]
    summary: BatchSummary


from routers.auth import router as auth_router
from routers.chat import router as chat_router
from database.database import init_db


CHAT_SUGGESTIONS = [
    "Symptoms",
    "Prevention",
    "Treatment",
    "About Malaria",
]

MALARIA_KNOWLEDGE_BASE = {
    "about": {
        "keywords": [
            "about",
            "malaria",
            "what is",
            "cause",
            "causes",
            "mosquito",
            "parasite",
            "spread",
        ],
        "reply": (
            "Malaria is a serious but preventable and treatable disease caused "
            "by Plasmodium parasites. It usually spreads through the bite of "
            "infected female Anopheles mosquitoes. It does not normally spread "
            "directly from person to person. The most dangerous species is often "
            "P. falciparum, especially in many parts of Africa."
        ),
    },
    "symptoms": {
        "keywords": [
            "symptom",
            "symptoms",
            "fever",
            "headache",
            "chills",
            "tired",
            "fatigue",
            "seizure",
            "breathing",
        ],
        "reply": (
            "Common early malaria symptoms include fever, headache, and chills. "
            "Symptoms often begin about 10 to 15 days after an infected mosquito "
            "bite. Severe warning signs include extreme tiredness, confusion or "
            "impaired consciousness, repeated convulsions, difficulty breathing, "
            "dark or bloody urine, yellow eyes or skin, and abnormal bleeding. "
            "Seek urgent medical care for severe symptoms."
        ),
    },
    "prevention": {
        "keywords": [
            "prevent",
            "prevention",
            "avoid",
            "net",
            "repellent",
            "mosquito",
            "protect",
            "vaccine",
            "chemoprophylaxis",
        ],
        "reply": (
            "Malaria prevention focuses on avoiding mosquito bites and using "
            "preventive medicines when appropriate. Helpful steps include sleeping "
            "under insecticide-treated nets, using mosquito repellent such as DEET, "
            "IR3535, or Icaridin after dusk, wearing protective clothing, using "
            "window screens, and reducing mosquito exposure. Travellers to malaria "
            "areas should speak with a clinician several weeks before travel about "
            "chemoprophylaxis."
        ),
    },
    "treatment": {
        "keywords": [
            "treat",
            "treatment",
            "medicine",
            "drug",
            "cure",
            "artemisinin",
            "chloroquine",
            "primaquine",
            "doctor",
        ],
        "reply": (
            "Malaria requires medical treatment. WHO recommends confirming suspected "
            "malaria with microscopy or a rapid diagnostic test where possible. "
            "Treatment depends on the parasite type, local drug resistance, age or "
            "weight, and pregnancy status. Artemisinin-based combination therapies "
            "are commonly used for P. falciparum malaria. Do not self-medicate; "
            "follow a qualified health professional's guidance."
        ),
    },
    "parasitized": {
        "keywords": [
            "parasitized",
            "positive",
            "infected",
            "parasite detected",
            "what does parasitized mean",
        ],
        "reply": (
            "Parasitized means the model saw visual patterns in the blood smear "
            "image that are consistent with malaria-infected red blood cells. This "
            "is an AI screening result, not a final diagnosis. A clinician should "
            "confirm suspected malaria with appropriate laboratory testing."
        ),
    },
    "uninfected": {
        "keywords": [
            "uninfected",
            "negative",
            "no malaria",
            "not infected",
        ],
        "reply": (
            "Uninfected means the model did not detect malaria-like parasite patterns "
            "in that image. A negative AI result does not rule out malaria if symptoms "
            "are present, the image quality is poor, or the parasite level is low. "
            "Seek testing and medical care if symptoms continue."
        ),
    },
    "rejected": {
        "keywords": [
            "rejected",
            "invalid",
            "not cell",
            "not cell image",
            "why was my image rejected",
            "uncertain",
        ],
        "reply": (
            "An image may be rejected when it does not look like a valid blood smear "
            "cell image, is too blurry, too dark, cropped poorly, or contains an "
            "object that is not a microscope blood-cell sample. Try uploading a clear, "
            "focused smear image with visible cells."
        ),
    },
    "accuracy": {
        "keywords": [
            "accuracy",
            "accurate",
            "confidence",
            "model",
            "reliable",
            "score",
        ],
        "reply": (
            "The confidence score shows how strongly the model favored its selected "
            "class for that image. It is not the same as clinical accuracy. Model "
            "accuracy depends on training data, image quality, microscope conditions, "
            "and validation results. Use this app as a screening aid, not as a "
            "replacement for professional diagnosis."
        ),
    },
}

# -------------------------
# APP
# -------------------------
app = FastAPI(title="Malaria Detection API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Unhandled error while processing %s %s", request.method, request.url)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error. Please try again."},
    )


@app.on_event("startup")
def on_startup() -> None:
    init_db()


# -------------------------
# LOAD MODEL
# -------------------------
model = tf.keras.models.load_model(MODEL_PATH)

# -------------------------
# IMAGE PREPROCESSING
# -------------------------
def prepare_image(image_bytes: bytes) -> np.ndarray:
    image = Image.open(BytesIO(image_bytes)).convert("RGB")
    image = image.resize(IMG_SIZE)
    image_array = np.array(image, dtype=np.float32)
    # Do not divide by 255 here. The model's first layer is Rescaling(1./255).
    return np.expand_dims(image_array, axis=0)


def predict_image(image_array: np.ndarray) -> tuple[str, float, np.ndarray]:
    raw_output = np.asarray(model.predict(image_array, verbose=0)[0])

    if raw_output.size == 1:
        prob = float(raw_output[0])
        predicted_index = int(prob >= 0.5)
        label = CLASS_NAMES[predicted_index]
        confidence = prob if predicted_index == 1 else 1 - prob
        probabilities = np.array([1 - prob, prob], dtype=np.float32)
        return DISPLAY_LABELS[label], confidence, probabilities

    predicted_index = int(np.argmax(raw_output))
    label = CLASS_NAMES[predicted_index]
    confidence = float(raw_output[predicted_index])
    return DISPLAY_LABELS[label], confidence, raw_output


def summarize_batch(results: List[PredictionResult]) -> BatchSummary:
    parasitized_count = sum(1 for item in results if item.prediction == "Parasitized")
    uninfected_count = sum(1 for item in results if item.prediction == "Uninfected")
    invalid_images_count = sum(
        1 for item in results if item.prediction == "Not Cell Image"
    )
    valid_total = parasitized_count + uninfected_count
    infection_percentage = (
        (parasitized_count / valid_total) * 100 if valid_total > 0 else 0
    )

    return BatchSummary(
        total_images=len(results),
        parasitized_count=parasitized_count,
        uninfected_count=uninfected_count,
        invalid_images_count=invalid_images_count,
        infection_percentage=round(infection_percentage, 2),
    )


def answer_chat(message: str) -> ChatResponse:
    normalized_message = message.strip().lower()

    if not normalized_message:
        return ChatResponse(
            topic="general",
            reply=(
                "Ask me about malaria symptoms, prevention, treatment, or what "
                "your prediction result means."
            ),
            suggestions=CHAT_SUGGESTIONS,
        )

    for topic, entry in MALARIA_KNOWLEDGE_BASE.items():
        if any(keyword in normalized_message for keyword in entry["keywords"]):
            return ChatResponse(
                topic=topic,
                reply=f"{entry['reply']}\n\nThis assistant provides general health information only. For diagnosis or treatment decisions, please consult a qualified health professional.",
                suggestions=CHAT_SUGGESTIONS,
            )

    return ChatResponse(
        topic="general",
        reply=(
            "I can help with malaria-related questions, including symptoms, "
            "causes, prevention, treatment guidance, and prediction results. "
            "For urgent symptoms such as confusion, seizures, severe weakness, "
            "difficulty breathing, yellow eyes, or dark urine, seek medical care "
            "immediately."
        ),
        suggestions=CHAT_SUGGESTIONS,
    )

# -------------------------
# HEALTH CHECK
# -------------------------
@app.get("/")
def health_check():
    return {
        "status": "running",
        "model": Path(MODEL_PATH).name,
        "classes": CLASS_NAMES,
    }

# -------------------------
# PREDICT ENDPOINT
# -------------------------
@app.post("/predict")
def predict(file: UploadFile = File(...)):
    print("Received filename:", file.filename)
    print("Received content-type:", file.content_type)

    image_bytes = file.file.read()

    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file uploaded")

    try:
        image_array = prepare_image(image_bytes)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image: {e}")

    label, confidence, probabilities = predict_image(image_array)

    if label == "Not Cell Image":
        return {
            "label": label,
            "confidence": round(confidence * 100, 2),
            "detail": "The uploaded image does not appear to be a blood cell smear. Please upload a valid cell image.",
        }

    if confidence < CONFIDENCE_THRESHOLD:
        return {
            "label": "Uncertain",
            "confidence": round(confidence * 100, 2),
            "detail": "Model is not confident enough. Please upload a clearer cell image.",
            "predicted_label": label,
        }

    return {
        "label": label,
        "confidence": round(confidence * 100, 2),
        "probabilities": {
            "Parasitized": round(float(probabilities[0]), 4),
            "Uninfected": round(float(probabilities[1]), 4),
            "Not Cell Image": round(float(probabilities[2]), 4)
            if len(probabilities) > 2
            else 0,
        },
    }


@app.post("/predict-batch", response_model=BatchPredictionResponse)
async def predict_batch(files: List[UploadFile] = File(...)):
    if not files:
        raise HTTPException(status_code=400, detail="No files uploaded")

    results: List[PredictionResult] = []

    for file in files:
        image_name = file.filename or "unnamed-image"
        image_bytes = await file.read()

        if len(image_bytes) == 0:
            results.append(
                PredictionResult(
                    image_name=image_name,
                    prediction="Not Cell Image",
                    confidence=0,
                )
            )
            continue

        try:
            image_array = prepare_image(image_bytes)
            label, confidence, _ = predict_image(image_array)
            if confidence < CONFIDENCE_THRESHOLD and label != "Not Cell Image":
                label = "Not Cell Image"
        except Exception:
            label = "Not Cell Image"
            confidence = 0

        results.append(
            PredictionResult(
                image_name=image_name,
                prediction=label,
                confidence=round(confidence * 100, 2),
            )
        )

    return BatchPredictionResponse(
        results=results,
        summary=summarize_batch(results),
    )


app.include_router(auth_router)
app.include_router(chat_router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=7860, reload=True)
