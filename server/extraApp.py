from flask import Flask, request, jsonify
import os
# llm imports
import whisper
from llama_cpp import Llama
from transformers import GPT2Tokenizer



app = Flask(__name__)


# whisper model
model = whisper.load_model("base")
llm = Llama(
        model_path="./model/Phi 3 Mini 4K Instruction.gguf",
        n_ctx=4096, 
        verbose=False,
        n_gpu_layers=-1
)

# memory managenment 
memory = {"history": []}
tokenizer = GPT2Tokenizer.from_pretrained("gpt2")

# output the current conversation stored in the memory 
def get_conversation():
    conversation_text = "\n".join([f"Human: {item['input']}\nAI: {item['output']}" for item in load_memory()])
    return conversation_text


# appending the conversation to the context 
def save_context(user_input, ai_output):
    global memory
    memory["history"].append({"input": user_input, "output": ai_output})
    manage_memory()


# printing the history 
def load_memory():
    global memory
    return memory["history"]

# conversation buffer of 2000 tokens 
def manage_memory():
    global memory
    full_history = load_memory()
    conversation_text = "\n".join([f"Human: {item['input']}\nAI: {item['output']}" for item in full_history])
    tokens = tokenizer.tokenize(conversation_text)
    num_tokens = len(tokens)

    if num_tokens >= 2000:
        while num_tokens >= 2000:
            memory["history"].pop(0)  # Remove the oldest conversation
            conversation_text = "\n".join([f"Human: {item['input']}\nAI: {item['output']}" for item in load_memory()])
            tokens = tokenizer.tokenize(conversation_text)
            num_tokens = len(tokens)


def ask_question_to_Mistral(question):
    
    inp_mistral =f'''
    <s> 
    You're are a helpful Assistant, and you only response to the "Assistant"
    Remember, maintain a natural tone. Be precise, concise, and casual. 
    Do not add extra information or explanations unless specifically asked.\n
    </s>
    <<CONTEXT>>
    '''
    inp_mistral += f"\n<</CONTEXT>>\n<<USER>>\n{question}\n<</USER>>\n[INST]"
    
   
    print(inp_mistral)
    output = llm(
        inp_mistral,
        max_tokens=128, 
        temperature=0.3,
        stop=["<|endoftext|>"],  
        echo=False,
    )
    
    generated_text = output['choices'][0]['text']
    
    
    # print('gentext : ',generated_text)
    # return generated_text
    
    clean_output = clean_generated_text(generated_text)
    
    # print('gentext : ', clean_output)
    return clean_output


# Helper function to clean the generated output
def clean_generated_text(generated_text):
    # Remove unwanted tokens or instructions
    clean_text = generated_text
    
    # Remove any markers such as **response:** or **instruction:**, or [INST] etc.
    clean_text = clean_text.replace("**response:**", "").replace("**instruction:**", "").replace("[INST]", "")
    
    # Remove any extra spaces or newlines
    clean_text = clean_text.strip()
    
    return clean_text


# def ask_question_to_llama(question):
    
#     inp_llama =f'''
#     <|begin_of_text|>
#     <|start_header_id|>system<|end_header_id|>
#     You're are a helpful Assistant, and you only response to the "Assistant"
#     Remember, maintain a natural tone. Be precise, concise, and casual. \n
#    <|eot_id|>
#    <|start_header_id|>Context<|end_header_id|>
#     '''
#     inp_llama += f"\n<|eot_id|>\n<|start_header_id|>user<|end_header_id|>\n{question}\n <|eot_id|>\n<|start_header_id|>assistant<|end_header_id|>"
    
   
#     print(inp_llama)
#     output = llm(
#         inp_llama,
#         max_tokens=512, 
#         stop=["<s>","<<USER>>","<<CONTEXT>>","[INST]"],  
#         echo=False,
#     )
#     generated_text = output['choices'][0]['text']
#     print('gentext : ',generated_text)
#     return generated_text



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
    result=ask_question_to_Mistral(text)
    question = text 
    output = result 
    # save output in memory 
    save_context(question,output)
    # check context 
    manage_memory()
    # check output 
    conversation = load_memory()
    return jsonify({'question':question,'result':output ,"conversation":conversation})



if __name__ == '__main__':
    app.run(debug=True)
