"""Bağımlılıksız WAV okuma/yazma (standart `wave` modülü).

torchaudio 2.11+ I/O için torchcodec + ffmpeg ister; ders projesinde fazladan
bağımlılık olmasın diye PCM WAV'ı doğrudan okuyup yazıyoruz. Mel spektrogram
hesabı saf torch olduğu için torchaudio yine kullanılabilir.
"""
import io
import wave

import numpy as np
import torch

_NORM = {1: 128.0, 2: 32768.0, 4: 2147483648.0}
_DTYPE = {1: np.uint8, 2: np.int16, 4: np.int32}


def load_wav(src) -> tuple[torch.Tensor, int]:
    """Yol (str), bytes ya da dosya-benzeri kabul eder.

    Döner: (wav, sample_rate). wav şekli (channels, samples), float32, [-1, 1].
    """
    if isinstance(src, (bytes, bytearray)):
        fobj = io.BytesIO(src)
    else:
        fobj = src  # yol ya da dosya-benzeri; wave ikisini de açar
    with wave.open(fobj, "rb") as w:
        sr = w.getframerate()
        ch = w.getnchannels()
        sw = w.getsampwidth()
        raw = w.readframes(w.getnframes())
    if sw not in _DTYPE:
        raise ValueError(f"Desteklenmeyen örnek genişliği: {sw} bayt")
    data = np.frombuffer(raw, dtype=_DTYPE[sw]).astype(np.float32)
    if sw == 1:                      # 8-bit unsigned -> [-1, 1]
        data = (data - 128.0) / _NORM[sw]
    else:
        data = data / _NORM[sw]
    data = data.reshape(-1, ch).T    # (channels, samples)
    return torch.from_numpy(data.copy()), sr


def save_wav(path: str, wav: torch.Tensor, sr: int) -> None:
    """16-bit PCM WAV yazar. wav: (channels, samples) ya da (samples,)."""
    if wav.dim() == 1:
        wav = wav.unsqueeze(0)
    ch = wav.shape[0]
    pcm = (wav.clamp(-1, 1) * 32767.0).to(torch.int16).cpu().numpy().T  # (samples, ch)
    with wave.open(path, "wb") as w:
        w.setnchannels(ch)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
