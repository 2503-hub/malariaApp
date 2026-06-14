from __future__ import annotations

from pathlib import Path

import tensorflow as tf


REPO_ROOT = Path(__file__).resolve().parents[2]
MODEL_PATH = REPO_ROOT / "malaria_model.keras"
OUTPUT_DIR = REPO_ROOT / "malaria_app" / "assets" / "models"
OUTPUT_MODEL_PATH = OUTPUT_DIR / "malaria_classifier.tflite"
OUTPUT_LABELS_PATH = OUTPUT_DIR / "labels.txt"

LABELS = [
    "Parasitized",
    "Uninfected",
    "Not Cell Image",
]


def convert_model() -> None:
    if not MODEL_PATH.exists():
        raise FileNotFoundError(f"Model file not found: {MODEL_PATH}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Loading model from {MODEL_PATH}")
    model = tf.keras.models.load_model(MODEL_PATH, compile=False)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
    converter.optimizations = []
    converter.experimental_enable_resource_variables = False

    print("Converting to TFLite...")
    tflite_model = converter.convert()

    OUTPUT_MODEL_PATH.write_bytes(tflite_model)
    OUTPUT_LABELS_PATH.write_text("\n".join(LABELS) + "\n", encoding="utf-8")

    print(f"Saved TFLite model to {OUTPUT_MODEL_PATH}")
    print(f"Saved labels to {OUTPUT_LABELS_PATH}")


if __name__ == "__main__":
    convert_model()
