from flask import Flask, request, jsonify
import os

# llm imports
import whisper
from llama_cpp import Llama

app = Flask(__name__)

# whisper model
model = whisper.load_model("base")
llm = Llama(
        model_path="./model/mistral-7b-instruct-v0.1.Q5_K_S.gguf",
        n_ctx=4096, 
        verbose=False,
        n_gpu_layers=-1
)

def ask_question_to_Phi(question):
    
    inp_mistral =f'''
    <s> 
    You're are a helpful Assistant, and you only response to the "Assistant"
    Remember, maintain a natural tone. Be precise, concise, and casual. \n
    </s>
    <<CONTEXT>>
    '''
    inp_mistral += f"\n<</CONTEXT>>\n<<USER>>\n{question}\n<</USER>>\n[INST]"
    
   
    print(inp_mistral)
    output = llm(
        inp_mistral,
        max_tokens=512, 
        stop=["<s>","<<USER>>","<<CONTEXT>>","[INST]"],  
        echo=False,
    )
    generated_text = output['choices'][0]['text']
    print('gentext : ',generated_text)
    return generated_text


def transcriber(file_path):
    audio = whisper.load_audio(file_path)
    audio = whisper.pad_or_trim(audio)
    
    mel = whisper.log_mel_spectrogram(audio).to(model.device)
    
    _, probs = model.detect_language(mel)
    language = max(probs, key=probs.get)
    
    options = whisper.DecodingOptions()
    result = whisper.decode(model, mel, options)
    text = result.text
    return language , text

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    
    file_path = "temp_audio.mp3"
    file.save(file_path)
    
    language , text = transcriber(file_path)
    os.remove(file_path)
    
    return jsonify({'language': language, 'transcription': text})


@app.route('/generate_output' ,methods=['POST'])
def generate_output():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    
    file_path = "temp_audio.mp3"
    file.save(file_path)
    
    language , text = transcriber(file_path)
    
    os.remove(file_path)
    result=ask_question_to_Phi (text)
    return jsonify({'question':text,'result':result})

    
if __name__ == '__main__':
    app.run(debug=True)
