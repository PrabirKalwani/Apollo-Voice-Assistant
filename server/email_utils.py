import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from rapidfuzz import fuzz, process
import re

# Predefined list of names and emails
email_directory = {
    "kasturi": "Kasturi.Shirodkar@nmims.edu",
    "coder": "prabir.kalwani@gmail.com",
    "smarty": "snehil.sinha784@gmail.com",
    "doctor": "drshahjj@gmail.com",
    "girl": "drashtisavla1502@gmail.com"
}

def send_email(sender_email, receiver_email, subject, body, password):
    """Sends an email using the provided details."""
    # Create a secure SSL context
    context = ssl.create_default_context()

    # Create the email
    message = MIMEMultipart()
    message["From"] = sender_email
    message["To"] = receiver_email
    message["Subject"] = subject

    # Add email body
    message.attach(MIMEText(body, "plain"))

    try:
        # Connect to the Gmail SMTP server
        with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as server:
            server.login(sender_email, password)
            server.sendmail(sender_email, receiver_email, message.as_string())
        print("Email sent successfully!")
    except Exception as e:
        print(f"Failed to send email: {e}")
        raise

def is_valid_email(email):
    """Validates the given email using a basic regex pattern."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def extract_email_details(transcription):
    """Extracts email details like recipient, subject, and body from the transcription."""
    sender_email = "shahaayush866@gmail.com"
    receiver_email = None
    subject = None
    body = None

    # Extract receiver name from transcription
    receiver_match = re.search(r'send an email to\s+([a-zA-Z\s]+)', transcription, re.IGNORECASE)
    if receiver_match:
        receiver_name = receiver_match.group(1).strip().lower()
        # Use fuzzy matching to find the closest name in the directory
        match_info = process.extractOne(receiver_name, email_directory.keys(), scorer=fuzz.partial_ratio)
        if match_info:
            match, score = match_info[0], match_info[1]
            if score >= 70:  # Adjust threshold if needed
                receiver_email = email_directory.get(match)

    # If no matching receiver email was found, return None
    if not receiver_email:
        return sender_email, None, None, None

    # Extract subject
    subject_match = re.search(r'subject\s+(\b(?!is\s+)(\w+\s*)+)(?=\s+the body is)', transcription, re.IGNORECASE)
    if subject_match:
        subject = subject_match.group(1).strip()
        subject = subject.rstrip('.')  # Remove trailing full stop if present

    # Extract body (anything after the subject)
    body_match = re.search(r'body\s+(\b(?!is\s+)(\w+\s*)+)', transcription, re.IGNORECASE)
    if body_match:
        body = body_match.group(1).strip()
        
    return sender_email, receiver_email, subject, body
