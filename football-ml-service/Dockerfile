# Dockerfile for ML Prediction Service
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY app.py .
COPY train.py .
COPY .env .

# Create models directory (will be mounted or populated by train)
RUN mkdir -p /app/models

EXPOSE 5001

# Run with gunicorn for production
CMD ["gunicorn", "-b", "0.0.0.0:5001", "-w", "2", "--timeout", "120", "app:app"]
