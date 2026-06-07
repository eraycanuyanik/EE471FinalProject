# Erişim — Mimari

## 1. Genel bakış

Tek bir Flutter uygulaması (mobil kabuk) + tek bir Python ML servisi (FastAPI). Üç modül
de aynı altyapıyı paylaşır; böylece kod tekrarı azalır ve "tek çatı altında üç ürün"
vizyonu teknik olarak da gerçekleşir.

```
┌─────────────────────────────────────────────────┐
│              Flutter Mobil Kabuk (app/)           │
│   ┌──────────┐  ┌──────────┐  ┌───────────────┐   │
│   │  SesVer  │  │  Duyar   │  │  Yanındayım   │   │
│   │ (kamera) │  │ (mikrofon│  │ (tek buton)   │   │
│   └────┬─────┘  └────┬─────┘  └───────┬───────┘   │
│        │  kamera/mikrofon/bildirim    │           │
└────────┼─────────────┼────────────────┼───────────┘
         │   REST / WebSocket (JSON + binary)        │
┌────────▼─────────────▼────────────────▼───────────┐
│            ML Servisi (ml_service/, FastAPI)       │
│  /sesver/predict   /duyar/predict   /yanindayim/*  │
│  ┌──────────────┐ ┌─────────────┐ ┌─────────────┐  │
│  │ MediaPipe +  │ │ Log-mel +   │ │ Diarization │  │
│  │ PyTorch sınıf│ │ CNN sınıf.  │ │ + STT/TTS   │  │
│  └──────────────┘ └─────────────┘ └─────────────┘  │
└────────────────────────────────────────────────────┘
                         │
                   Azure TTS / STT (bulut)
```

## 2. Karar: on-device vs cloud

| İş | Yer | Neden |
|----|-----|-------|
| Duyar ses sınıflandırma | **On-device** (TFLite/ONNX export) | Sürekli + arka planda dinleme; gecikme ve gizlilik kritik |
| SesVer landmark çıkarımı | On-device (MediaPipe) | Kamera akışı düşük gecikme ister |
| SesVer dizi sınıflandırma | Cloud (ağır model) | Geçici frame dizisi → daha büyük model |
| TTS / STT | Cloud (Azure) | Kalite ve Türkçe desteği |
| Diarization | Cloud | Hesaplama yoğun |

> Bu repodaki `ml_service` geliştirme/eğitim ortamıdır. Üretimde Duyar modeli `.onnx`/`.tflite`
> olarak telefona gömülür; servis ise eğitim + ağır modüller için kalır.

## 3. Modül detayları

### Duyar (çalışan) — ses sınıflandırma
- **Girdi:** 1 sn'lik mono 16 kHz ses penceresi.
- **Özellik:** log-mel spektrogram (64 mel, 16 kHz).
- **Model:** küçük 2D CNN → softmax (`modules/duyar/model.py`).
- **Sınıflar:** siren, kapı_zili, bebek_ağlaması, alarm, kapı_vurma, isim_çağırma, köpek, sessizlik (`labels.py`).
- **Çıktı:** sınıf + güven skoru → telefon titreşim/bildirim.
- **Türkçe boşluk:** "isim_çağırma" ve sözel uyarı ("dikkat!") tanıma yerelde eksik — projenin katma değeri.

### SesVer (iskelet) — işaret dili → konuşma
- MediaPipe Hands + FaceMesh → her frame için landmark vektörü.
- Landmark dizisi → PyTorch (LSTM/Transformer) → kelime/işaret sınıfı.
- Sınıf → cümle → Azure TTS.
- Ters mod: STT → metin → işaret animasyon dizisi (avatar).

### Yanındayım (iskelet) — yaşlı asistanı
- Tek buton → STT → niyet (intent) → eylem (ilaç hatırlat / ara / "bu hangi ilaç").
- Diarization: kim konuşuyor (yaşlı vs bakıcı vs ziyaretçi).
- İlaç tanıma: kamera → görüntü sınıflandırma → ilaç adı + doz.

## 4. API sözleşmesi (taslak)

```
POST /duyar/predict      body: {audio: base64 wav}  -> {label, confidence, all_scores}
POST /sesver/predict     body: {landmarks: [...]}    -> {gloss, sentence}
POST /yanindayim/intent  body: {text: "..."}         -> {intent, slots}
GET  /health                                          -> {status, modules}
```

## 5. Yol haritası (ders teslimi için gerçekçi)
1. ✅ Repo iskeleti + ortak servis + Duyar çalışan başlangıç
2. ✅ Duyar: gerçek veri seti (ESC-50) ile eğitim → ~%80 doğrulama doğruluğu
3. ✅ Flutter mobil uygulama: 3 modül + Duyar mikrofon→API→titreşim akışı
4. ✅ Yanındayım: STT (konuşma→metin) + ilaç hatırlatma (bildirim) + intent
5. ✅ SesVer: kamera + landmark pipeline iskeleti (ML Kit gerçek cihazda)
6. ⬜ Duyar 'isim_cagirma' için Türkçe seslenme kayıtları topla
7. ⬜ Duyar ONNX export → on-device çıkarım
8. ⬜ SesVer: fiziksel cihazda ML Kit el landmark + TİD sınıflandırıcı
9. ⬜ Sunum + rapor

### Önemli teknik kısıt: ML Kit & iOS simülatörü
Google ML Kit iOS pod'ları Apple Silicon **arm64 iOS simülatörünü desteklemez** (yalnızca
fiziksel cihaz + Intel simülatör). Bu yüzden SesVer'in gerçek el landmark takibi fiziksel
iPhone gerektirir. Tüm uygulamanın simülatörde çalışabilmesi için ML Kit bağımlılığı
varsayılan olarak kaldırıldı; eklemek için `app/lib/modules/sesver/sesver_screen.dart`
başındaki yönergeleri izleyin.
