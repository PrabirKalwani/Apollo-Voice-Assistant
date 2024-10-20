# Apollo: Voice Based Assistant

This is a python project that levearages the power of gemini to create a voice based assistant application on flutter with a python backend using RESTful API's

## Flutter Frontend

To setup the flutter frontend

```bash
  flutter pub get
  flutter run
```

## Python Backend

### Register User

- **Endpoint**: `/register`
- **Method**: POST
- **Description**: Registers a new user with email and password.
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```
- **Response**: Returns the user's UID on success.

### Login User

- **Endpoint**: `/login`
- **Method**: POST
- **Description**: Logs in a user with email and password.
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```
- **Response**: Returns a custom authentication token on success.

### Logout User

- **Endpoint**: `/logout`
- **Method**: POST
- **Description**: Logs out the current user.
- **Response**: Returns a success message.

### Reset Password

- **Endpoint**: `/reset-password`
- **Method**: POST
- **Description**: Sends a password reset email to the user.
- **Request Body**:
  ```json
  {
    "email": "user@example.com"
  }
  ```
- **Response**: Confirms that the password reset email was sent.

## Audio Transcription and Processing APIs

### Transcribe Audio

- **Endpoint**: `/transcribe`
- **Method**: POST
- **Description**: Transcribes an audio file and returns the text.
- **Request**: Multipart form data with 'file' key containing the audio file.
- **Response**: Returns the detected language and transcribed text.

### Generate Output

- **Endpoint**: `/generate_output`
- **Method**: POST
- **Description**: Transcribes audio, processes the content, and generates a response. It can either send an email or generate a response using an AI model.
- **Request**: Multipart form data with 'file' key containing the audio file.
- **Response**: Returns the transcribed question and either a confirmation of email sent or the AI model's response.

## Google Calendar APIs

### Create Calendar Invite

- **Endpoint**: `/create_invite`
- **Method**: POST
- **Description**: Creates a new event in the user's Google Calendar.
- **Request Body**:
  ```json
  {
    "date": "2024-03-15",
    "time": "14:30",
    "summary": "Team Meeting"
  }
  ```
- **Response**: Returns the created event's ID on success.

### Logout of OAuth

- **Endpoint**: `/logout-of-oauth`
- **Method**: POST
- **Description**: Revokes the Google Calendar OAuth token and deletes the local token file.
- **Response**: Confirms successful logout from Google OAuth.

## Setup and Configuration

- Ensure all required libraries are installed `pip install -r requirenments.txt `
- Set up environment variables in a `.env` file:
  - `SENDER_EMAIL`: Email address for sending emails
  - `EMAIL_PASSWORD`: Password for the sender email account
  - `GEMINI_API_KEY`:API key for interacting with gemini
- Place the Firebase service account JSON file as `firebaseService.json` in the root directory.
- Set up Google OAuth 2.0 credentials and save them as `credentials.json` in the root directory.

## Running the Application

To run the application, execute the following command:

```
python app.py
```

The server will start in debug mode, listening on `http://127.0.0.1:5000/`.
