# Royal Rush sesleri

`content/audio` içindeki 10 mono, 24 kHz, 16 bit WAV bu proje için algoritmik
olarak üretildi. Dış kayıt, melodi veya müzik dosyası indirilmedi. Üretici:
`python tools/audio.py`; süre, boyut ve SHA-256 `content/audio/manifest.json`.
WAV dosyaları yeniden okunarak doğrulandı; Roblox playback yapılmadı.

Mevcut oyun temel geri bildirim için Roblox built-in karakter SFX yollarını
kullanır. Özgün üç müzik döngüsü ve yedi SFX henüz Roblox asset'i değildir.

1. Studio kullanılabilir olduğunda WAV'ları kendi hesabının/oyun grubunun
   Asset Manager'ından içe aktar; gerekiyorsa experience'a kullanım yetkisi ver.
2. `src/shared/Config.luau` içindeki `Audio.Custom` tablosuna gerçek ID'leri
   `LobbyMusic = "rbxassetid://GERCEK_ID"` biçiminde ekle. Studio'da doğrudan
   düzenleyeceksen Explorer → ReplicatedStorage → RoyalRush → Config.
3. Anahtarlar: `LobbyMusic`, `RoundMusic`, `FinalMusic`, `Click`, `Power`, `Warning`,
   `Qualified`, `Eliminated`, `Victory`, `Countdown`. İstediğin kadarını bağlayabilirsin.
4. Kaynaktan değiştirdiysen `BUILD.cmd` ile yeni `.rbxl` üret. Studio içinde
   düzenlediysen ayrı kopya kaydet; source build o değişikliği içermez.
5. Gerçek oyunda loading/moderation/permission ve Music/SFX ayarlarını test et.

Audio asset ID'leri ve experience izinleri hesabına bağlı olduğu için dosyaya
sahte ID yerleştirilmedi. İlk oynanış döngüsü müzik yüklemeden de hazırlanmıştır.

Kaynak: [Roblox audio içe aktarma](https://create.roblox.com/docs/audio/assets).
Built-in yol referansı:
[Roblox Core-Scripts karakter sesleri](https://github.com/Roblox/Core-Scripts/blob/master/PlayerScripts/StarterCharacterScripts/Sound.server.lua).
