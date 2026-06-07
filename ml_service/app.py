"""Erişim — ortak ML servisi (FastAPI).

Üç modülün uç noktalarını tek serviste toplar. Çalıştır:
    uvicorn app:app --reload
"""
import base64

import torchaudio
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from modules.duyar import LABELS as DUYAR_LABELS
from modules.duyar.audio import SAMPLE_RATE
from modules.duyar.infer import predict_waveform
from modules.duyar.wav_io import load_wav
from modules.sesver.infer import predict_landmarks
from modules.yanindayim.intent import detect_intent

app = FastAPI(title="Erişim ML Servisi", version="0.1.0")


@app.get("/health")
def health():
    return {
        "status": "ok",
        "modules": {
            "duyar": "active",
            "sesver": "skeleton",
            "yanindayim": "skeleton",
        },
    }


# ---------- Duyar (çalışan) ----------
class DuyarRequest(BaseModel):
    audio_b64: str  # base64 ile kodlanmış WAV


@app.post("/duyar/predict")
def duyar_predict(req: DuyarRequest):
    try:
        raw = base64.b64decode(req.audio_b64)
        wav, sr = load_wav(raw)
    except Exception as e:
        raise HTTPException(400, f"Ses çözülemedi: {e}")
    if sr != SAMPLE_RATE:
        wav = torchaudio.functional.resample(wav, sr, SAMPLE_RATE)
    return predict_waveform(wav.mean(dim=0))


@app.get("/duyar/labels")
def duyar_labels():
    return {"labels": DUYAR_LABELS}


# ---------- SesVer (iskelet) ----------
class SesVerRequest(BaseModel):
    landmarks: list[list[float]]  # frame başına landmark vektörü


@app.post("/sesver/predict")
def sesver_predict(req: SesVerRequest):
    return predict_landmarks(req.landmarks)


# ---------- Yanındayım (iskelet) ----------
class IntentRequest(BaseModel):
    text: str


@app.post("/yanindayim/intent")
def yanindayim_intent(req: IntentRequest):
    return detect_intent(req.text)
