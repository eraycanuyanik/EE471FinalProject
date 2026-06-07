# Erişim — Flutter Mobil Kabuk (yer tutucu)

Üç modülü tek uygulamada toplayan mobil kabuk. Henüz oluşturulmadı.

## Planlanan yapı
```
app/
├── lib/
│   ├── main.dart            # ana menü: SesVer / Duyar / Yanındayım
│   ├── core/
│   │   ├── api_client.dart  # ml_service ile REST/WebSocket
│   │   └── theme.dart       # büyük buton, yüksek kontrast (erişilebilirlik)
│   └── modules/
│       ├── sesver/          # kamera + MediaPipe + TTS
│       ├── duyar/           # mikrofon + arka plan servis + titreşim/bildirim
│       └── yanindayim/      # tek buton + STT + ilaç hatırlatma
└── pubspec.yaml
```

## Oluşturmak için
```bash
cd app
flutter create . --org com.erisim --project-name erisim
# sonra önerilen paketler:
#   record / flutter_sound   (mikrofon)
#   flutter_local_notifications + vibration (Duyar uyarıları)
#   camera + google_mlkit (SesVer landmark)
#   http / web_socket_channel (ml_service)
```

## Erişilebilirlik ilkeleri
- Yüksek kontrast, büyük dokunma hedefleri, ekran okuyucu etiketleri.
- Duyar: görsel + titreşimli uyarı (işitmeye bağımlı değil).
- Yanındayım: tek ekran, tek büyük buton (yaşlı kullanıcı).
