"""Duyar veri seti.

İki mod:
  1) Gerçek veri: data/<label>/*.wav klasör yapısı (ESC-50, UrbanSound8K,
     kendi Türkçe isim kayıtların vb. buraya kopyalanır).
  2) Sentetik veri (--synthetic): sınıf başına farklı frekans/zarf
     karakterli sahte sesler üretir. Amaç pipeline'ı veri olmadan da
     uçtan uca çalıştırıp test edebilmek. GERÇEK doğruluk beklenmez.
"""
import math
from pathlib import Path

import torch
import torchaudio
from torch.utils.data import Dataset

from .audio import N_SAMPLES, SAMPLE_RATE, waveform_to_logmel
from .labels import LABELS, NUM_CLASSES, label_to_idx
from .wav_io import load_wav


class FolderAudioDataset(Dataset):
    """data/<label>/*.wav yapısından okur."""

    def __init__(self, root: str = "data"):
        self.items: list[tuple[Path, int]] = []
        root_path = Path(root)
        for label in LABELS:
            for wav in (root_path / label).glob("*.wav"):
                self.items.append((wav, label_to_idx(label)))
        if not self.items:
            raise FileNotFoundError(
                f"'{root}' altında ses bulunamadı. Gerçek veri ekleyin ya da "
                f"--synthetic ile eğitin."
            )

    def __len__(self) -> int:
        return len(self.items)

    def __getitem__(self, i: int):
        path, y = self.items[i]
        wav, sr = load_wav(str(path))
        if sr != SAMPLE_RATE:
            wav = torchaudio.functional.resample(wav, sr, SAMPLE_RATE)
        return waveform_to_logmel(wav.mean(dim=0)), y


class SyntheticAudioDataset(Dataset):
    """Sınıf başına ayırt edici sahte sesler üretir (pipeline testi için)."""

    # her sınıfa kabaca farklı bir temel frekans + modülasyon profili
    PROFILES = [
        (0.0, 0.0),     # sessizlik -> neredeyse gürültü
        (700, 4.0),     # siren -> dalgalanan yüksek ton
        (1200, 0.0),    # kapi_zili -> sabit yüksek ton
        (450, 8.0),     # bebek_aglamasi -> hızlı modülasyon
        (1000, 2.0),    # alarm
        (150, 0.0),     # kapi_vurma -> düşük darbe
        (300, 1.0),     # isim_cagirma -> konuşma benzeri
        (550, 6.0),     # kopek_havlamasi
    ]

    def __init__(self, per_class: int = 200, seed: int = 0):
        self.per_class = per_class
        self.seed = seed

    def __len__(self) -> int:
        return self.per_class * NUM_CLASSES

    def __getitem__(self, i: int):
        label = i % NUM_CLASSES
        g = torch.Generator().manual_seed(self.seed * 100003 + i)
        base_freq, mod_hz = self.PROFILES[label]
        t = torch.linspace(0, 1.0, N_SAMPLES)

        if base_freq == 0.0:  # sessizlik
            wav = 0.02 * torch.randn(N_SAMPLES, generator=g)
        else:
            freq = base_freq * (1 + 0.3 * torch.sin(2 * math.pi * mod_hz * t)) if mod_hz else base_freq
            wav = torch.sin(2 * math.pi * freq * t)
            wav = wav + 0.05 * torch.randn(N_SAMPLES, generator=g)  # gürültü
            wav = wav * (0.6 + 0.4 * torch.rand(1, generator=g))     # rastgele şiddet
        return waveform_to_logmel(wav), label


def build_dataset(synthetic: bool, root: str = "data", per_class: int = 200):
    if synthetic:
        return SyntheticAudioDataset(per_class=per_class)
    return FolderAudioDataset(root=root)
