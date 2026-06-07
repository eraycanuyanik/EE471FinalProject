"""Duyar çıkarım yardımcıları — API ve CLI tarafından kullanılır."""
from pathlib import Path

import torch
import torchaudio

from .audio import SAMPLE_RATE, waveform_to_logmel
from .labels import CRITICAL, LABELS
from .model import build_model
from .wav_io import load_wav

CKPT = Path(__file__).parent / "duyar_model.pt"
_model: torch.nn.Module | None = None


def load_model() -> torch.nn.Module:
    """Modeli bir kez yükler, sonra önbellekten döner."""
    global _model
    if _model is None:
        if not CKPT.exists():
            raise FileNotFoundError(
                f"Model bulunamadı: {CKPT}. Önce eğitin: "
                f"python -m modules.duyar.train --synthetic"
            )
        ckpt = torch.load(CKPT, map_location="cpu")
        m = build_model()
        m.load_state_dict(ckpt["state_dict"])
        m.eval()
        _model = m
    return _model


@torch.no_grad()
def predict_waveform(wav: torch.Tensor) -> dict:
    """(samples,) ham ses -> {label, confidence, critical, all_scores}."""
    model = load_model()
    feat = waveform_to_logmel(wav).unsqueeze(0)         # (1, 1, mel, T)
    probs = torch.softmax(model(feat), dim=1).squeeze(0)
    idx = int(probs.argmax())
    label = LABELS[idx]
    return {
        "label": label,
        "confidence": round(float(probs[idx]), 4),
        "critical": label in CRITICAL,
        "all_scores": {LABELS[i]: round(float(p), 4) for i, p in enumerate(probs)},
    }


def predict_file(path: str) -> dict:
    wav, sr = load_wav(path)
    if sr != SAMPLE_RATE:
        wav = torchaudio.functional.resample(wav, sr, SAMPLE_RATE)
    return predict_waveform(wav.mean(dim=0))


if __name__ == "__main__":
    import sys
    print(predict_file(sys.argv[1]))
