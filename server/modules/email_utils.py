import json
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from rapidfuzz import process, fuzz
import re

EMAILS_FILE = "email_directory.json"  

def load_email_directory():
    with open(EMAILS_FILE, 'r') as f:
        return json.load(f)

def get_email_by_name(name, threshold=75):
    """Retrieve the email address by name with the closest match."""
    try:
        # Load the directory of names and emails
        with open("email_directory.json", "r") as file:
            email_directory = json.load(file)

        # Find the closest match for the given name
        closest_match = process.extractOne(name, email_directory.keys(), score_cutoff=threshold)
        
        if closest_match:
            # Ensure we only get matched_name and score, ignoring any extra elements
            matched_name = closest_match[0]
            return email_directory.get(matched_name, None)
        else:
            print(f"No close match found for the name: {name}")
            return None
    except FileNotFoundError:
        print("Error: email_directory.json not found.")
        return None
    except Exception as e:
        print(f"Error in get_email_by_name: {e}")
        return None

def send_email(sender_email, receiver_email, subject, body, password):
    """Sends an email using the provided details."""
    context = ssl.create_default_context()
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