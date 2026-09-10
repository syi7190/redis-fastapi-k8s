# Minimal Python base image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy requirements/install dependencies
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copy FastAPI app into the image
COPY app.py .

# Start FastAPI app with Uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
