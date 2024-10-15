import google.generativeai as genai
import os
import json
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
sender_email = os.getenv("SENDER_EMAIL")

generation_config = {
    "temperature": 1,
    "top_p": 0.95,
    "top_k": 64,
    "max_output_tokens": 8192,
    "response_mime_type": "text/plain",
}

model = genai.GenerativeModel(
    model_name="gemini-1.5-flash",
    generation_config=generation_config,
)

model_mail = genai.GenerativeModel(
    model_name="gemini-1.5-pro",
    generation_config=generation_config,
    system_instruction='''
From the transcription, please extract the receiver's email. You can improvise the subject and body based on the transcription and return them in this format:
{
    "email": "",
    "subject": "",
    "body": ""
}
'''
)


def ask_question_to_model(question):
    chat_session = model.start_chat(history=[])
    response = chat_session.send_message(question)
    return response.text


def extract_email_details(transcription):
    chat_session = model_mail.start_chat()

    response = chat_session.send_message(transcription)

    # Convert response text (string formatted like JSON) to a Python dictionary
    response_text = response.text
    print("response :", response_text)
    try:
        # Load the string into a Python dictionary
        email_data = json.loads(response_text)
    except json.JSONDecodeError:
        print("Error: The response is not a valid JSON string.")
        return None, None, None

    # Extract the email details
    receiver_email = email_data.get("email")
    subject = email_data.get("subject")
    body = email_data.get("body")

    return receiver_email, subject, body
