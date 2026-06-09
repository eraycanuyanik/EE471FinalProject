"""Erişim — ortak ML servisi (FastAPI).

Üç modülün uç noktalarını tek serviste toplar. Çalıştır:
    uvicorn app:app --reload
"""
import base64
import io
from contextlib import asynccontextmanager

import numpy as np
import soundfile as sf
import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from modules.duyar import LABELS as DUYAR_LABELS
from modules.duyar.panns_infer import load_model, predict_waveform
from modules.duyar.wav_io import load_wav
from modules.sesver.infer import predict_landmarks
from modules.yanindayim.intent import detect_intent


@asynccontextmanager
async def lifespan(app: FastAPI):
    # PANNs modelini başlangıçta yükle ki ilk istek yavaş olmasın
    load_model()
    yield


app = FastAPI(title="Erişim ML Servisi", version="0.1.0", lifespan=lifespan)


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


_SILENT = {"label": "sessizlik", "confidence": 1.0, "critical": False, "all_scores": {}}


@app.post("/duyar/predict")
def duyar_predict(req: DuyarRequest):
    try:
        raw = base64.b64decode(req.audio_b64)
    except Exception as e:
        raise HTTPException(400, f"base64 çözülemedi: {e}")

    # soundfile iOS dahil farklı WAV biçimlerini sağlam çözer; olmazsa stdlib wave.
    wav = None
    try:
        data, sr = sf.read(io.BytesIO(raw), dtype="float32")
        if data.ndim > 1:
            data = data.mean(axis=1)
        wav = torch.from_numpy(np.ascontiguousarray(data))
    except Exception:
        try:
            wav, sr = load_wav(raw)
        except Exception as e:
            raise HTTPException(400, f"Ses çözülemedi: {e}")

    # boş / çok kısa ses -> sessizlik (çökme yerine güvenli yanıt)
    if wav is None or wav.numel() < 1600:
        print(f"[duyar] KISA/BOŞ ses: numel={0 if wav is None else wav.numel()} sr={sr}", flush=True)
        return _SILENT
    maxamp = float(wav.abs().max())
    print(f"[duyar] gelen ses: numel={wav.numel()} sr={sr} maxamp={maxamp:.4f}", flush=True)
    result = predict_waveform(wav, sr)
    print(f"[duyar] sonuc: {result['label']} %{int(result['confidence']*100)} kritik={result['critical']}", flush=True)
    return result


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
