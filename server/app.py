from flask import Flask, request, jsonify
import os
import whisper
from dotenv import load_dotenv
from modules.email_utils import send_email
from modules.gemini_utils import extract_email_details, ask_question_to_model
import logging
from flask_cors import CORS
import datetime
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from google.auth.transport.requests import Request  # Ensure this is imported

load_dotenv()

app = Flask(__name__)
CORS(app)

logging.basicConfig(level=logging.DEBUG)
whisper_model = whisper.load_model("base")

# smtp api
sender_email = os.getenv("SENDER_EMAIL")
password = os.getenv("EMAIL_PASSWORD")
CREDENTIALS_FILE = 'credentials.json'
SCOPES = ['https://www.googleapis.com/auth/calendar']


def send_email_response(sender_email, receiver_email, subject, body, question_text, password):
    if body and subject:
        email_body = body
        email_subject = subject
        result = None
    else:
        result = ask_question_to_model(question_text)
        email_body = f"Transcription: {question_text}\n\nModel Response: {result}"
        email_subject = "AI Transcription and Response"

    try:
        send_email(sender_email, receiver_email,
                   email_subject, email_body, password)
        return jsonify({
            'message': 'Email sent successfully!',
            'question': question_text,
        }), 200
    except Exception as e:
        logging.error(f"Failed to send email: {e}")
        return jsonify({'error': f"Failed to send email: {e}"}), 500


def transcribe_audio(file_path):
    try:
        audio = whisper.load_audio(file_path)
        audio = whisper.pad_or_trim(audio)

        mel = whisper.log_mel_spectrogram(audio).to(whisper_model.device)
        _, probs = whisper_model.detect_language(mel)
        language = max(probs, key=probs.get)

        options = whisper.DecodingOptions()
        result = whisper.decode(whisper_model, mel, options)

        return language, result.text
    except Exception as e:
        logging.error(f"Error transcribing audio: {e}")
        return None, None


def create_service():
    creds = None
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)
    else:
        flow = InstalledAppFlow.from_client_secrets_file(
            CREDENTIALS_FILE, SCOPES)
        creds = flow.run_local_server(port=0)
        with open('token.json', 'w') as token:
            token.write(creds.to_json())

    service = build('calendar', 'v3', credentials=creds)
    return service


def revoke_token(creds):
    try:
        request = Request()
        creds.revoke(request)
        print("Token revoked.")
    except Exception as e:
        print(f"Error revoking token: {e}")
        return False
    return True


def logout_oauth():
    if os.path.exists('./token.json'):
        os.remove('./token.json')
        print("Token file deleted.")
        return True
    else:
        print("Token Not Deleted")
        return False


@app.route('/logout-of-oauth', methods=['POST'])
def logout_of_oauth():
    if logout_oauth():
        return jsonify({'status': 'success', 'message': 'Logged out successfully.'}), 200
    return jsonify({'status': 'error', 'message': 'Logout failed.'}), 400


@app.route('/create_invite', methods=['POST'])
def create_invite():
    data = request.json
    date_str = data.get('date')
    time_str = data.get('time')
    summary = data.get('summary', 'Event')

    try:
        event_date_time = datetime.datetime.strptime(
            f"{date_str} {time_str}", '%Y-%m-%d %H:%M')
        start_time = event_date_time.isoformat() + 'Z'  # 'Z' indicates UTC time
        end_time = (event_date_time + datetime.timedelta(hours=1)
                    ).isoformat() + 'Z'  # 1-hour duration

        service = create_service()

        event = {
            'summary': summary,
            'start': {
                'dateTime': start_time,
                'timeZone': 'UTC',
            },
            'end': {
                'dateTime': end_time,
                'timeZone': 'UTC',
            },
        }

        created_event = service.events().insert(
            calendarId='primary', body=event).execute()
        return jsonify({'status': 'success', 'event_id': created_event['id']}), 200

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 400


@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    file_path = "temp_audio.mp3"
    file.save(file_path)

    try:
        language, text = transcribe_audio(file_path)
        if not language or not text:
            return jsonify({'error': 'Failed to transcribe audio'}), 500
        return jsonify({'language': language, 'transcription': text}), 200
    finally:
        if os.path.exists(file_path):
            os.remove(file_path)


@app.route('/generate_output', methods=['POST'])
def generate_output():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    file_path = "temp_audio.mp3"
    file.save(file_path)

    try:
        language, question_text = transcribe_audio(file_path)
        if not language or not question_text:
            return jsonify({'error': 'Failed to transcribe audio'}), 500

        if "send an email" in question_text.lower():
            receiver_email, subject, body = extract_email_details(
                question_text)

            if not sender_email or not receiver_email:
                return jsonify({'error': 'Invalid sender or receiver email.'}), 400

            return send_email_response(sender_email, receiver_email, subject, body, question_text, password)

        # Fallback to generating a response from the model
        result = ask_question_to_model(question_text)
        return jsonify({
            'question': question_text,
            'result': result,
        }), 200
    except Exception as e:
        logging.error(f"Error in generate_output: {e}")
        return jsonify({'error': f"An error occurred: {e}"}), 500
    finally:
        if os.path.exists(file_path):
            os.remove(file_path)


@app.route('/generate_output_text', methods=['POST'])
def text_output():
    data = request.json
    question = data.get("question")

    if question != "":
        result = ask_question_to_model(question)
        return jsonify({
            'question': question,
            'response': result
        })
    else:
        return jsonify({
            'error': f"An error occurred"
        })


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=1234)
