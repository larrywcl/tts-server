#!/usr/bin/env python3
"""
TTS Server - Generate podcast-quality speech via HTTP API
"""

import argparse
import os
import tempfile
from pathlib import Path

import torch
import soundfile as sf
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import uvicorn

# ============================================================
# Config
# ============================================================

MODEL = "Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice"
DEVICE = "mps"  # Apple Silicon GPU
DTYPE = torch.float16
OUTPUT_DIR = Path(tempfile.gettempdir()) / "tts_output"
OUTPUT_DIR.mkdir(exist_ok=True)

# ============================================================
# Models
# ============================================================

class GenerateRequest(BaseModel):
    text: str
    speaker: str = "Ryan"
    language: str = "English"
    instruct: str = ""

class Segment(BaseModel):
    text: str
    speaker: str = "Ryan"
    language: str = "English"
    instruct: str = ""

class BatchRequest(BaseModel):
    segments: list[Segment]
    pause_seconds: float = 0.5

# ============================================================
# App
# ============================================================

app = FastAPI(title="TTS Server", version="1.0.0")
model = None

@app.on_event("startup")
async def startup():
    global model
    print(f"Loading {MODEL} on {DEVICE}...")
    from qwen_tts import Qwen3TTSModel
    model = Qwen3TTSModel.from_pretrained(MODEL, device_map=DEVICE, dtype=DTYPE)
    print(f"Ready! Speakers: {model.get_supported_speakers()}")

@app.get("/health")
async def health():
    return {"status": "ok", "model": MODEL, "ready": model is not None}

@app.get("/speakers")
async def speakers():
    return {"speakers": model.get_supported_speakers() if model else []}

@app.post("/generate")
async def generate(req: GenerateRequest):
    if not model:
        raise HTTPException(503, "Model not loaded")
    
    wavs, sr = model.generate_custom_voice(
        text=req.text,
        language=req.language,
        speaker=req.speaker,
        instruct=req.instruct or None,
    )
    
    path = OUTPUT_DIR / f"tts_{os.urandom(4).hex()}.wav"
    sf.write(str(path), wavs[0], sr)
    return FileResponse(str(path), media_type="audio/wav", filename="speech.wav")

@app.post("/generate_batch")
async def generate_batch(req: BatchRequest):
    if not model:
        raise HTTPException(503, "Model not loaded")
    
    import numpy as np
    
    chunks = []
    sr = None
    
    for seg in req.segments:
        wavs, sr = model.generate_custom_voice(
            text=seg.text,
            language=seg.language,
            speaker=seg.speaker,
            instruct=seg.instruct or None,
        )
        chunks.append(wavs[0])
        chunks.append(np.zeros(int(sr * req.pause_seconds)))  # Pause
    
    combined = np.concatenate(chunks)
    path = OUTPUT_DIR / f"batch_{os.urandom(4).hex()}.wav"
    sf.write(str(path), combined, sr)
    return FileResponse(str(path), media_type="audio/wav", filename="podcast.wav")

# ============================================================
# Main
# ============================================================

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=11435)
    args = parser.parse_args()
    
    print(f"Starting TTS server on {args.host}:{args.port}")
    uvicorn.run(app, host=args.host, port=args.port)
