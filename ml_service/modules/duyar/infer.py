"""Duyar çıkarım yardımcıları — API ve CLI tarafından kullanılır."""
from pathlib import Path

import torch
import torchaudio

from .audio import N_SAMPLES, SAMPLE_RATE, waveform_to_logmel
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
    """(samples,) ham ses -> {label, confidence, critical, all_scores}.

    1 sn'den uzun ses gelirse 1 sn'lik (yarı örtüşen) pencerelere bölüp
    softmax çıktısını ortalar — uzun kliplerde tek pencerenin sessiz kısma
    denk gelmesini önler.
    """
    model = load_model()
    if wav.dim() > 1:
        wav = wav.mean(dim=0)

    hop = N_SAMPLES // 2
    if wav.shape[-1] > int(1.5 * N_SAMPLES):
        windows = [wav[s:s + N_SAMPLES] for s in range(0, wav.shape[-1] - N_SAMPLES + 1, hop)]
    else:
        windows = [wav]
    feats = torch.stack([waveform_to_logmel(w) for w in windows])  # (W, 1, mel, T)
    probs = torch.softmax(model(feats), dim=1).mean(dim=0)          # pencere ortalaması
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
