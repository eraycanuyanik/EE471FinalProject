"""Yanındayım niyet (intent) tanıma — İSKELET (kural tabanlı başlangıç).

Gerçek akış: STT (Azure) -> bu intent katmanı -> eylem (ilaç hatırlat / ara /
ilaç tanı). Diarization ve görüntüden ilaç tanıma ayrı modüllerde gelecek.

Şimdilik basit anahtar-kelime eşleştirmesi; ileride küçük bir Türkçe intent
sınıflandırıcı (PyTorch) ile değiştirilecek.
"""
INTENTS = {
    "ilac_hatirlat": ["ilaç", "ilac", "hap", "doz"],
    "ara": ["ara", "telefon", "çocuğum", "cocugum", "oğlum", "kızım"],
    "ilac_tani": ["bu hangi", "hangi ilaç", "ne ilacı"],
    "yardim": ["yardım", "imdat", "düştüm", "iyi değilim"],
}


def detect_intent(text: str) -> dict:
    t = (text or "").lower()
    for intent, keywords in INTENTS.items():
        if any(k in t for k in keywords):
            return {"intent": intent, "text": text, "note": "ISKELET — kural tabanlı"}
    return {"intent": "bilinmiyor", "text": text, "note": "ISKELET — kural tabanlı"}
