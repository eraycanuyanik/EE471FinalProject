"""Duyar'ın tanıdığı kritik ses sınıfları.

Türkiye odaklı: 'isim_cagirma' ve sözel uyarılar yerel boşluğu doldurur.
Sıralama sabittir — model çıktısının indeksleriyle eşleşir, değiştirme.
"""

LABELS = [
    "sessizlik",        # 0  - arka plan / sessizlik
    "siren",            # 1  - ambulans, polis, itfaiye
    "kapi_zili",        # 2  - kapı zili / interkom
    "bebek_aglamasi",   # 3
    "alarm",            # 4  - yangın/duman alarmı, çalar saat
    "kapi_vurma",       # 5  - kapıya vurma
    "isim_cagirma",     # 6  - birinin ismini/seslenmesini tanıma
    "kopek_havlamasi",  # 7
]

NUM_CLASSES = len(LABELS)

# Hangi sınıflar "kritik" — anında titreşim + bildirim tetikler
CRITICAL = {"siren", "kapi_zili", "bebek_aglamasi", "alarm", "kapi_vurma", "isim_cagirma"}


def idx_to_label(i: int) -> str:
    return LABELS[i]


def label_to_idx(label: str) -> int:
    return LABELS.index(label)
