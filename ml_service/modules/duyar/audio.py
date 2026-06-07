"""Ses ön işleme: ham dalga formu -> log-mel spektrogram.

Tüm modül tek bir örnekleme hızı ve pencere boyutu kullanır ki eğitim ile
çıkarım birebir aynı özellikleri üretsin.
"""
import torch
import torchaudio

SAMPLE_RATE = 16_000      # 16 kHz mono
CLIP_SECONDS = 1.0        # 1 sn'lik pencere
N_SAMPLES = int(SAMPLE_RATE * CLIP_SECONDS)
N_MELS = 64
N_FFT = 512
HOP = 256

_mel = torchaudio.transforms.MelSpectrogram(
    sample_rate=SAMPLE_RATE, n_fft=N_FFT, hop_length=HOP, n_mels=N_MELS
)
_to_db = torchaudio.transforms.AmplitudeToDB(top_db=80.0)


def fix_length(wav: torch.Tensor) -> torch.Tensor:
    """Dalga formunu tam N_SAMPLES'a sıfır-dolgu / kırpma ile sabitler."""
    if wav.dim() > 1:          # çok kanallı -> mono
        wav = wav.mean(dim=0)
    n = wav.shape[-1]
    if n < N_SAMPLES:
        wav = torch.nn.functional.pad(wav, (0, N_SAMPLES - n))
    elif n > N_SAMPLES:
        wav = wav[:N_SAMPLES]
    return wav


def waveform_to_logmel(wav: torch.Tensor) -> torch.Tensor:
    """(samples,) ham ses -> (1, N_MELS, T) log-mel özellik haritası."""
    wav = fix_length(wav)
    spec = _mel(wav)                 # (N_MELS, T)
    spec = _to_db(spec)
    # normalizasyon (yaklaşık 0 ortalama / birim varyans)
    spec = (spec - spec.mean()) / (spec.std() + 1e-6)
    return spec.unsqueeze(0)         # (1, N_MELS, T)
