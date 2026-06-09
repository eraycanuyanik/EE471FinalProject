"""Duyar çıkarımı — önceden eğitilmiş AudioSet modeli (PANNs CNN14).

Sıfırdan küçük CNN yerine, Google AudioSet'te (527 ses sınıfı) eğitilmiş hazır
PANNs modelini kullanır. AudioSet olasılıklarını Duyar etiketlerine eşler.
'Speech' (konuşma) AudioSet'te ayrı bir sınıf olduğundan normal konuşma KRİTİK
sayılmaz → asıl yanlış-alarm sorununu kökten çözer.

Model ilk kullanımda ~/panns_data altına iner (~300MB).
"""
import numpy as np
import torch
import torchaudio

from .wav_io import load_wav

PANNS_SR = 32_000  # CNN14 32 kHz ile eğitildi

# --- AudioSet etiketi -> Duyar kritik etiketi eşlemesi ---
CRITICAL_MAP = {
    "siren": ["Siren", "Civil defense siren", "Ambulance (siren)", "Police car (siren)",
              "Fire engine, fire truck (siren)", "Emergency vehicle", "Car alarm"],
    "kapi_zili": ["Doorbell", "Ding-dong", "Church bell", "Bell", "Bicycle bell",
                  "Telephone bell ringing"],
    "bebek_aglamasi": ["Baby cry, infant cry", "Crying, sobbing"],
    "alarm": ["Alarm", "Alarm clock", "Smoke detector, smoke alarm",
              "Fire alarm", "Buzzer", "Beep, bleep"],
    "kapi_vurma": ["Knock"],
    "kopek_havlamasi": ["Dog", "Bark", "Bow-wow", "Howl", "Growling", "Whimper (dog)"],
    "isim_cagirma": ["Shout", "Yell", "Children shouting", "Screaming"],
}
SPEECH_LABELS = ["Speech", "Male speech, man speaking", "Female speech, woman speaking",
                 "Child speech, kid speaking", "Conversation", "Narration, monologue",
                 "Hubbub, speech noise, speech babble"]
SILENCE_LABELS = ["Silence"]

# Kritik kabul eşiği. AudioSet çok-etiketli olduğu için doğru sınıf çoğu zaman
# 0.15-0.6 arası alır → eşik düşük tutulur. isim_cagirma (bağırma) konuşmaya
# yakın olduğundan daha yüksek; böylece normal/yüksek sesli konuşma alarm vermez.
THRESH = {"_default": 0.12, "isim_cagirma": 0.30, "kapi_vurma": 0.15, "kapi_zili": 0.18}
SPEECH_THRESH = 0.30

_model = None
_idx = None  # {duyar_label: [audioset_indices]}, ayrıca 'speech','silence'


def _build_index():
    from panns_inference.config import labels as AUDIOSET
    pos = {name: i for i, name in enumerate(AUDIOSET)}
    idx = {k: [pos[n] for n in names if n in pos] for k, names in CRITICAL_MAP.items()}
    idx["_speech"] = [pos[n] for n in SPEECH_LABELS if n in pos]
    idx["_silence"] = [pos[n] for n in SILENCE_LABELS if n in pos]
    return idx


def load_model():
    global _model, _idx
    if _model is None:
        from panns_inference import AudioTagging
        _model = AudioTagging(checkpoint_path=None, device="cpu")
        _idx = _build_index()
    return _model


def _max_at(probs: np.ndarray, indices: list[int]) -> float:
    return float(probs[indices].max()) if indices else 0.0


@torch.no_grad()
def predict_waveform(wav: torch.Tensor, sr: int) -> dict:
    """Mono ham ses + örnekleme hızı -> {label, confidence, critical, all_scores}."""
    load_model()
    if wav.dim() > 1:
        wav = wav.mean(dim=0)
    if wav.numel() < 800:  # neredeyse boş ses -> güvenli yanıt
        return {"label": "sessizlik", "confidence": 1.0, "critical": False, "all_scores": {}}
    if sr != PANNS_SR:
        wav = torchaudio.functional.resample(wav, sr, PANNS_SR)

    audio = wav.unsqueeze(0).cpu().numpy().astype(np.float32)  # (1, samples)
    clipwise, _ = _model.inference(audio)
    probs = clipwise[0]  # (527,)

    # her kritik etiket için skor
    crit_scores = {label: _max_at(probs, _idx[label]) for label in CRITICAL_MAP}
    speech_score = _max_at(probs, _idx["_speech"])
    silence_score = _max_at(probs, _idx["_silence"])

    best_label = max(crit_scores, key=crit_scores.get)
    best_score = crit_scores[best_label]
    thr = THRESH.get(best_label, THRESH["_default"])

    if best_score >= thr:
        # Ham AudioSet olasılığı düşük olabilir; eşiğe göre anlaşılır bir
        # güven yüzdesine kalibre et (eşik=%50, eşiğin 2 katı≈%99).
        conf = min(0.99, 0.5 + 0.5 * (best_score - thr) / thr)
        label, confidence, critical = best_label, conf, True
    elif speech_score >= SPEECH_THRESH:
        label, confidence, critical = "konusma", speech_score, False
    elif silence_score >= 0.1:
        label, confidence, critical = "sessizlik", silence_score, False
    else:
        label, confidence, critical = "diger", 1.0 - best_score, False

    all_scores = {k: round(v, 4) for k, v in crit_scores.items()}
    all_scores["konusma"] = round(speech_score, 4)
    all_scores["sessizlik"] = round(silence_score, 4)
    return {
        "label": label,
        "confidence": round(float(confidence), 4),
        "critical": critical,
        "all_scores": all_scores,
    }


def predict_file(path: str) -> dict:
    wav, sr = load_wav(path)
    return predict_waveform(wav, sr)


if __name__ == "__main__":
    import sys
    print(predict_file(sys.argv[1]))
