import google.generativeai as genai
import os
import json
from dotenv import load_dotenv
load_dotenv()
import re
from modules.email_utils import get_email_by_name

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
From the transcription, please extract the receiver's email. Give proper formatted subject and body based on the transcription exactly as given and return them in this format:
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


def extract_email_details(question_text):
    """Extracts name, subject, and body for email from the question text and fetches email from directory."""
    try:
        # Extract the name after "send an email to"
        name_match = re.search(r"send an email to (\w+)", question_text, re.IGNORECASE)
        name = name_match.group(1) if name_match else None

        # Fetch email based on the name
        if name:
            receiver_email = get_email_by_name(name)
            if not receiver_email:
                print(f"No close match found for the name: {name}")
                return None  # Return None if no matching email found
        else:
            print("No name found in the text.")
            return None

        # Default values for subject and body
        subject = "Notification from Apollo Chat Assistant"
        body = "This Email is sent using Apollo Chat Assistant."

        # Extract subject and body text from the question, if available
        # For subject: extract text after "subject is" until a period or "body is" keyword
        subject_match = re.search(r"subject\s*is\s*([^\.\n]+)", question_text, re.IGNORECASE)
        body_match = re.search(r"body\s*is\s*([^\n]+)", question_text, re.IGNORECASE)

        # Set the extracted subject and body text, capitalizing the first letter of each
        if subject_match:
            subject = subject_match.group(1).strip().capitalize()
        if body_match:
            body = body_match.group(1).strip().capitalize()

        # Return the email, formatted subject, and body
        return receiver_email, subject, body

    except Exception as e:
        print(f"Error in extract_email_details: {e}")
        return None
