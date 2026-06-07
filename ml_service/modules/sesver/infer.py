"""SesVer çıkarımı — İSKELET.

Gerçek akış:
  1) Flutter/MediaPipe her frame için el+yüz landmark'larını çıkarır.
  2) Landmark dizisi (T, D) -> PyTorch LSTM/Transformer -> işaret (gloss) sınıfı.
  3) Gloss dizisi -> cümle -> Azure TTS.

Şimdilik landmark hareket miktarına göre basit bir yer tutucu döndürür ki
API sözleşmesi ve uçtan uca akış test edilebilsin.

TODO: TID (Türk İşaret Dili) küçük kelime seti topla (5-10 işaret),
      LSTM sınıflandırıcı eğit, gloss->cümle kuralları ekle.
"""
GLOSSES = ["merhaba", "tesekkurler", "yardim", "evet", "hayir"]


def predict_landmarks(landmarks: list[list[float]]) -> dict:
    if not landmarks:
        return {"gloss": None, "sentence": "", "note": "landmark yok"}
    # yer tutucu: hareket enerjisine göre deterministik bir gloss seç
    energy = sum(abs(v) for frame in landmarks for v in frame)
    gloss = GLOSSES[int(energy) % len(GLOSSES)]
    return {
        "gloss": gloss,
        "sentence": gloss.capitalize(),
        "note": "ISKELET — gerçek model henüz eğitilmedi",
    }
