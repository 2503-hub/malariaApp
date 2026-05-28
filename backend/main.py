from io import BytesIO
from pathlib import Path

import numpy as np
import tensorflow as tf
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image

# -------------------------
# CONFIG
# -------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_PATH = BASE_DIR / "malaria_model.keras"

IMG_SIZE = (64, 64)
CLASS_NAMES = ["Parasitized", "Uninfected"]

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

    # IMPORTANT: normalize (helps model stability)
    image_array = image_array / 255.0

    return np.expand_dims(image_array, axis=0)

# -------------------------
# HEALTH CHECK
# -------------------------
@app.get("/")
def health_check():
    return {
        "status": "running",
        "model": MODEL_PATH.name
    }

# -------------------------
# PREDICT ENDPOINT
# -------------------------
@app.post("/predict")
async def predict(file: UploadFile = File(...)):

    # DEBUG (important for your 400 error)
    print("Received filename:", file.filename)
    print("Received content-type:", file.content_type)

    # Validate file
    if file is None:
        raise HTTPException(status_code=400, detail="No file uploaded")

    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Please upload an image."
        )

    # Read image
    image_bytes = await file.read()

    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file uploaded")

    # Preprocess
    image_array = prepare_image(image_bytes)

    # Predict
    prob = float(model.predict(image_array, verbose=0)[0][0])

    predicted_index = int(prob >= 0.5)
    confidence = prob if predicted_index == 1 else 1 - prob

    return {
        "label": CLASS_NAMES[predicted_index],
        "confidence": round(confidence * 100, 2),
        "probability": round(prob, 6),
    }