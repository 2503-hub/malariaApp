FROM python:3.10-slim

# Install build tools needed by TensorFlow and other wheels.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Make the backend package imports resolve correctly when running from /app.
ENV PYTHONPATH=/app/backend

# Copy requirements first to maximize Docker layer caching.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the backend code and model artifact.
COPY backend/ ./backend/
COPY malaria_model.keras .

# Hugging Face Spaces expects this port for Docker apps.
EXPOSE 7860

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "7860"]
