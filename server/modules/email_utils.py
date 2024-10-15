import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from rapidfuzz import fuzz, process
import re


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
