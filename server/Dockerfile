FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt
RUN pip install -U openai-whisper

# Copy the application code
COPY . .

# Copy the credentials and firebase service files
COPY credentials.json /app/credentials.json
COPY firebaseservice.json /app/firebaseservice.json

EXPOSE 5000

CMD ["python", "app.py"]
