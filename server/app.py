from flask import Flask, request, jsonify
import os
import whisper
from dotenv import load_dotenv
from modules.email_utils import send_email
from modules.gemini_utils import extract_email_details, ask_question_to_model

load_dotenv()

app = Flask(__name__)

# Prequisite init
whisper_model = whisper.load_model("base")
sender_email = os.getenv("SENDER_EMAIL")
password = os.getenv("EMAIL_PASSWORD")


def send_email_response(sender_email, receiver_email, subject, body, question_text, password):
    if body and subject:
        email_body = body
        email_subject = subject
        result = None
    else:
        result = ask_question_to_model(question_text)
        email_body = f"Transcription: {
            question_text}\n\nModel Response: {result}"
        email_subject = "AI Transcription and Response"

    try:
        send_email(sender_email, receiver_email,
                   email_subject, email_body, password)
        return jsonify({
            'message': 'Email sent successfully!',
            'question': question_text,
        })
    except Exception as e:
        return jsonify({'error': f"Failed to send email: {e}"})


def transcribe_audio(file_path):
    audio = whisper.load_audio(file_path)
    audio = whisper.pad_or_trim(audio)

    mel = whisper.log_mel_spectrogram(audio).to(whisper_model.device)
    _, probs = whisper_model.detect_language(mel)
    language = max(probs, key=probs.get)

    options = whisper.DecodingOptions()
    result = whisper.decode(whisper_model, mel, options)

    return language, result.text


@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    file_path = "temp_audio.mp3"
    file.save(file_path)

    language, text = transcribe_audio(file_path)
    os.remove(file_path)

    return jsonify({'language': language, 'transcription': text})


@app.route('/conversation', methods=['POST'])
def conversation():
    # request file from the user
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    file = request.files['file']
    file_path = "temp_audio.mp3"
    file.save(file_path)
    # transcribe the file given by user
    language, question_text = transcribe_audio(file_path)
    os.remove(file_path)
    # send email logic
    if "send an email" in question_text.lower():
        receiver_email, subject, body = extract_email_details(
            question_text)

        if not sender_email or not receiver_email:
            return jsonify({'error': 'Invalid sender or receiver email.'}), 400

        return send_email_response(sender_email, receiver_email, subject, body, question_text, password)

    # revert to basic answer
    result = ask_question_to_model(question_text)

    return jsonify({
        'question': question_text,
        'result': result,
    })


if __name__ == '__main__':
    app.run(debug=True)
