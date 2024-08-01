## Apollo: Voice Based Assistant

This project features a Bot which is a voice based assistant

## Installation

### Prerequisites

#### Have the Following Tools / Programming Languages in your machine for this to work

```bash
Python : Version 3
Docker
Docker-Compose
```

### Requirenments

#### Lets Get our local models downloaded

```bash
python -m venv .venv
source .venv/bin/activate (LINUX) OR .venv/Scripts/activate (WINDOWS)
cd server
pip install -r requirenments.txt
```

#### After this lets add our llm make sure you are in the main directory

```bash
cd server
mkdir model
```

#### From the list below add your model in `./model` folder

#### Model List

| Model Name  | Download                                                                                                           | Size    |
| :---------- | :----------------------------------------------------------------------------------------------------------------- | :------ |
| `Phi3 Mini` | [Phi3-mini](https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/blob/main/Phi-3-mini-4k-instruct-q4.gguf) | 2.39 GB |

## API Reference

#### Converting Data from Voice To Text

```http
  POST http://localhost:6969/transcribe

```

MULTIPART FORM
| Parameter | Type | Description |
| :-------- | :------- | :-------------------------------- |
| `file` | `file` | **REQUIRED** file that you want to add to weaviate|

## Issues

Please Do Reach Out at prabir.kalwani@gmail.com
