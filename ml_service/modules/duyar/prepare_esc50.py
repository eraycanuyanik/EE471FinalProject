"""ESC-50 veri setini Duyar etiketlerine eşler ve data/<etiket>/ altına kopyalar.

Kullanım (önce ESC-50'yi data/ESC-50-master altına aç):
    python -m modules.duyar.prepare_esc50

ESC-50: https://github.com/karolpiczak/ESC-50  (2000 klip, 50 sınıf, 5sn @ 44.1kHz)
"""
import csv
import shutil
from pathlib import Path

import torch

from .labels import LABELS
from .wav_io import save_wav

DATA = Path(__file__).resolve().parents[2] / "data"
ESC50 = DATA / "ESC-50-master"

# ESC-50 kategorisi -> Duyar etiketi
MAPPING = {
    "siren": "siren",
    "crying_baby": "bebek_aglamasi",
    "dog": "kopek_havlamasi",
    "clock_alarm": "alarm",
    "door_wood_knock": "kapi_vurma",
    "church_bells": "kapi_zili",   # ESC-50'de kapı zili yok; "kilise çanı" en yakın vekil
}
# Not: 'isim_cagirma' ESC-50'de yok (konuşma içermez) -> kendi Türkçe kayıtların gerekir.
# 'sessizlik' -> aşağıda sentetik sessizlik klipleri üretilir.


def main():
    if not ESC50.exists():
        raise SystemExit(f"ESC-50 bulunamadı: {ESC50}\n"
                         f"Önce data/esc50.zip indirip açın.")
    meta = ESC50 / "meta" / "esc50.csv"
    audio = ESC50 / "audio"

    # hedef klasörleri temizle/oluştur
    for label in LABELS:
        (DATA / label).mkdir(parents=True, exist_ok=True)

    counts = {label: 0 for label in LABELS}
    with open(meta) as f:
        for row in csv.DictReader(f):
            cat = row["category"]
            if cat in MAPPING:
                label = MAPPING[cat]
                shutil.copy(audio / row["filename"], DATA / label / row["filename"])
                counts[label] += 1

    # sessizlik sınıfı: düşük genlikli gürültü klipleri üret
    sil_dir = DATA / "sessizlik"
    for i in range(40):
        g = torch.Generator().manual_seed(1000 + i)
        wav = 0.01 * torch.randn(16000, generator=g)  # ~sessiz oda
        save_wav(str(sil_dir / f"silence_{i:03d}.wav"), wav, 16000)
        counts["sessizlik"] += 1

    print("=== Duyar veri özeti (data/<etiket>/) ===")
    for label in LABELS:
        flag = "" if counts[label] else "  ⚠️ veri yok"
        print(f"  {label:<18} {counts[label]:>4} klip{flag}")
    print("\nNot: 'isim_cagirma' için kendi Türkçe seslenme kayıtlarınızı "
          "data/isim_cagirma/ altına .wav olarak ekleyin.")


if __name__ == "__main__":
    main()
