from flask import Flask, request, jsonify
import os
import whisper
from llama_cpp import Llama
from transformers import GPT2Tokenizer
from email_utils import send_email
import re

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
        max_tokens=128, 
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


# Email validation function
def is_valid_email(email):
    # Simple regex for basic email validation
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

# Extract email details from transcription
def extract_email_details(transcription):
    sender_email = "shahaayush866@gmail.com"
    receiver_email = "prabir.kalwani@gmail.com"
    subject = None
    body = None

    # Extract sender email
    sender_match = re.search(r'from\s+([\w\.-]+@[\w\.-]+)', transcription)
    if sender_match:
        sender_email = sender_match.group(1) if is_valid_email(sender_match.group(1)) else send_email

    # Extract receiver email
    receiver_match = re.search(r'to\s+([\w\.-]+@[\w\.-]+)', transcription)
    if receiver_match:
        receiver_email = receiver_match.group(1) if is_valid_email(receiver_match.group(1)) else None

    # Extract subject
    subject_match = re.search(r'subject\s+(.+)', transcription, re.IGNORECASE)
    if subject_match:
        subject = subject_match.group(1).strip()

    # Extract body (anything after the subject)
    body_match = re.search(r'body\s+(.+)', transcription, re.IGNORECASE)
    if body_match:
        body = body_match.group(1).strip()

    return sender_email, receiver_email, subject, body


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
        
        # Generate response from the LLM (Phi)
        result = ask_question_to_model(question_text)

        # Compose the email body
        body = f"Transcription: {question_text}\n\nModel Response: {result}"

        password = os.getenv("EMAIL_PASSWORD")  # Use environment variables for security

        # Send email
        try:
            send_email(sender_email, receiver_email, subject or "AI Transcription and Response", body, password)
            return jsonify({
                'message': 'Email sent successfully!',
                'question': question_text,
                'result': result,
                'conversation': memory["history"]
            })
        except Exception as e:
            return jsonify({'error': f"Failed to send email: {e}"})
    

    # Generate response from the LLM (Phi)
    result = ask_question_to_model(question_text)

    # Save conversation to memory
    save_context(question_text, result)


    # # Check if the transcription contains the phrase "Send an email"
    # if "send an email" in question_text.lower():
    #     # Email details
    #     sender_email = "shahaayush866@gmail.com"  # Replace with your sender email
    #     receiver_email = "prabir.kalwani@gmail.com"  # Replace with receiver email
    #     subject = "AI Transcription and Response"
    #     body = f"Transcription: {question_text}\n\nModel Response: {result}"
    #     password = os.getenv("EMAIL_PASSWORD")  # Use environment variables for security

    #     # Send email
    #     try:
    #         send_email(sender_email, receiver_email, subject, body, password)
    #         return jsonify({
    #             'message': 'Email sent successfully!',
    #             'question': question_text,
    #             'result': result,
    #             'conversation': memory["history"]
    #         })
    #     except Exception as e:
    #         return jsonify({'error': f"Failed to send email: {e}"})
    

    # Return the result along with conversation history
    return jsonify({
        'question': question_text,
        'result': result,
        'conversation': memory["history"]
    })

if __name__ == '__main__':
    app.run(debug=True)
