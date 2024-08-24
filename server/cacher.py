import os
from transformers import GPT2Tokenizer


# Create cache directory if it doesn't exist
cache_dir = "./model/cache"
os.makedirs(cache_dir, exist_ok=True)

# Load and cache GPT-2 tokenizer
tokenizer = GPT2Tokenizer.from_pretrained("openai-community/gpt2", cache_dir=cache_dir)
print("GPT-2 tokenizer cached.")

print("All specified models cached successfully.")