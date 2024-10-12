from flask import Flask, request, jsonify
import os
import whisper
from llama_cpp import Llama
from transformers import GPT2Tokenizer
from dotenv import load_dotenv

# Import email-related utilities from email_utils
from email_utils import send_email, extract_email_details

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)

# Whisper model initialization
whisper_model = whisper.load_model("base")

# LLM (Phi 3 Mini 4K Instruction) initialization
llm_model = Llama(
    model_path="./model/Phi 3 Mini 4K Instruction.gguf",
    n_ctx=4096,
    verbose=False,
    n_gpu_layers=-1
)

# Tokenizer for conversation memory management
tokenizer = GPT2Tokenizer.from_pretrained("gpt2")

# In-memory conversation storage
memory = {"history": []}

# Helper to get the conversation context (for the LLM)
def get_conversation():
    return "\n".join([f"Human: {item['input']}\nAI: {item['output']}" for item in memory["history"]])

# Save the conversation context (user input and model output)
def save_context(user_input, ai_output):
    memory["history"].append({"input": user_input, "output": ai_output})
    manage_memory()

# Ensure conversation history doesn't exceed 2000 tokens
def manage_memory():
    conversation_text = get_conversation()
    tokens = tokenizer.tokenize(conversation_text)
    num_tokens = len(tokens)

    # Trim history if it exceeds the 2000 token limit
    while num_tokens >= 2000:
        memory["history"].pop(0)
        conversation_text = get_conversation()
        tokens = tokenizer.tokenize(conversation_text)
        num_tokens = len(tokens)

# Helper function to interact with the LLM model (Phi)
def ask_question_to_model(question):
    context = get_conversation()

    # Input format for the LLM
    input_text = f'''
    <s> 
    You're a helpful Assistant. You respond to the "Assistant".
    Maintain a natural tone. Be precise, concise, and avoid unnecessary repetition.\n
    </s>
    <<USER>>
    {question}
    <</USER>>
    [INST]
    '''

    output = llm_model(
        input_text,
        max_tokens=512,
        temperature=0.3,
        stop=["</s>", "[INST]"],
        echo=False,
    )

    generated_text = output['choices'][0]['text']
    clean_output = clean_generated_text(generated_text)
    return clean_output

# Clean the generated output (remove unwanted tokens or markers)
def clean_generated_text(generated_text):
    return generated_text.replace("[INST]", "").strip()

# Whisper transcriber (speech-to-text)
def transcribe_audio(file_path):
    audio = whisper.load_audio(file_path)
    audio = whisper.pad_or_trim(audio)

    mel = whisper.log_mel_spectrogram(audio).to(whisper_model.device)
    _, probs = whisper_model.detect_language(mel)
    language = max(probs, key=probs.get)

    options = whisper.DecodingOptions()
    result = whisper.decode(whisper_model, mel, options)

    return language, result.text

# API route to transcribe audio
@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    file_path = "temp_audio.mp3"
    file.save(file_path)

    # Transcribe the audio
    language, text = transcribe_audio(file_path)
    os.remove(file_path)

    return jsonify({'language': language, 'transcription': text})

# API route to transcribe and generate AI output
@app.route('/generate_output', methods=['POST'])
def generate_output():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    file_path = "temp_audio.mp3"
    file.save(file_path)

    # Transcribe the audio and get the question
    language, question_text = transcribe_audio(file_path)
    os.remove(file_path)

    # Check if email should be sent
    if "send an email" in question_text.lower():
        # Extract email details
        sender_email, receiver_email, subject, body = extract_email_details(question_text)

        # Check if emails are valid
        if not sender_email or not receiver_email:
            return jsonify({'error': 'Invalid sender or receiver email.'}), 400

        password = os.getenv("EMAIL_PASSWORD")  # Use environment variables for security

        # Directly send email if the subject and body are provided
        return send_email_response(sender_email, receiver_email, subject, body, question_text, password)
    
    
    result = ask_question_to_model(question_text)

    # Save conversation to memory
    save_context(question_text, result)

    # Return the result along with conversation history
    return jsonify({
        'question': question_text,
        'result': result,
        'conversation': memory["history"]
    })

def send_email_response(sender_email, receiver_email, subject, body, question_text, password):
    """Handles sending the email and returns the appropriate response."""
    
    # Use the provided body and subject directly if present
    if body and subject:  
        email_body = body
        email_subject = subject
        result = None  # No need to generate model response when subject and body are provided
    else:
        # If no subject or body is provided, fall back to generating a response from the LLM (Phi)
        result = ask_question_to_model(question_text)
        email_body = f"Transcription: {question_text}\n\nModel Response: {result}"
        email_subject = "AI Transcription and Response"

    try:
        # Send the email using the provided subject and body (or generated content if applicable)
        send_email(sender_email, receiver_email, email_subject, email_body, password)
        return jsonify({
            'message': 'Email sent successfully!',
            'question': question_text,
            'result': result,
            'conversation': memory["history"]
        })
    except Exception as e:
        return jsonify({'error': f"Failed to send email: {e}"})

if __name__ == '__main__':
    app.run(debug=True)
