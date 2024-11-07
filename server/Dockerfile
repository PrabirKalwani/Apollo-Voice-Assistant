FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy and install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install OpenAI Whisper
RUN pip install -U openai-whisper

# Install ffmpeg
RUN apt-get update && apt-get install -y ffmpeg

# Copy the application code
COPY . .

# Expose port 5000
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
