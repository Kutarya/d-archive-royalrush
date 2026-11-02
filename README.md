# Royal Rush

**0.1.0-offline — 9 Ekim 2026.** Roblox için mobil/PC odaklı, 2–16 oyunculu
Chaos Events + Crown Tournament. Kod, gerçek Part haritaları ve açılabilir place
dosyaları hazırlandı. 9 Ekim'de gerçek Studio'da tek kişilik ilk açılış,
Sky Kingdom/Neon City yarışı, Q/Dash ve yeni maça dönüş denendi; sunucu/istemci
konsollarında 0 hata, 0 uyarı görüldü. Tam oyun kabulü henüz tamamlanmadı.

## Studio'da aç

1. Roblox **Studio**'yu kur. Normal Roblox Player yerel proje dosyasını açmaz.
2. `AC-STUDIO.cmd` dosyasına çift tıkla; veya Studio'da **File → Open from File**
   ile `D:\Roblox\RoyalRush\RoyalRush.rbxl` dosyasını aç.
3. **F5 / Play** ile başlat. Varsayılan tek kişilik Studio önizlemesinde lobby,
   Sky Kingdom Race, Rising Danger, Crown Climb final ve ikinci maç denenebilir.
4. Output penceresinde server/client hatalarını izle. Çok oyunculu kontrol için
   Studio'nun Server & Clients testinde önce 2, ardından 8 client çalıştır.

Rojo eklentisi veya script kopyalayıp yapıştırmak gerekmez. `.rbxl` bütün oyun
kaynakları ile modelleri içerir; `.rbxlx` aynı içeriğin XML alternatifidir.
İlk bekleme 20 saniye, giriş 3 saniye. Hareket/zıplama Roblox varsayılanı;
power PC'de **Q**, mobilde mavi **GÜÇ**, gamepad'de **X**.

**Studio'da XP/Crowns geçici bellek profiline gider ve HUD bunu gösterir.**
Play durdurulunca silinir. Canlı DataStore kodu vardır; gerçek kalıcılık için
özel test experience'ında ayrıca doğrulanmalıdır.

## Paketteki sistemler

- Lobby, otomatik queue, küçük oyuncu formatları, çok turlu eleme, beraberlik,
  finale kalanlar, kazanan, sonuç ekranı ve sonraki maç.
- Sky Kingdom ve Neon City yarışları; Lava Factory survival/tırmanış ve Crown
  Climb finali: **3 tema, 5 harita düzeni, 15 obstacle türü**.
- **8 Chaos Event**, uyumluluk/ağırlık/ön uyarı/cleanup. İlk server maçında
  Low Gravity ilk Race'in 30. saniyesinde başlar; diğer seçimler ağırlıklıdır.
- Ücretsiz **Dash, Double Jump, Shield**. Server cooldown ve durum doğrulaması;
  oyuncu çarpışması kapalı. Race checkpoint; survival/finalde eleme.
- Türkçe/İngilizce temel HUD, spectator, tek mobil power butonu, renk yardım
  sembolleri, düşük efekt, ses düzeyi ve otomatik izleme ayarları.
- XP/level, Crowns, global/yerel win ayrımı, streak, Server King, leaderboard,
  profil migration/session lock/autosave, read-only hata davranışı.
- 14 kozmetik (biri başlangıç title'ı), sabit Crowns shop, 7 günlük ödül,
  3 günlük quest, yerel achievement kaydı ve server analytics çağrıları.
- Dış animasyon ID'si gerektirmeyen kutlama ve 10 özgün WAV dosyası.

Shop, günlük ödül ve quest aynı merkezi profil kuyruğunu kullanır. Kritik bir
kayıt hatasında satın alma/claim uygulanmaz; varsayılan profil eski veri üstüne
yazılmaz. Client XP, para, kazanan veya cooldown bildiremez. Standart Roblox
hareketi için toleranslı konum kontrolü vardır; tam server movement simulation yoktur.

## Offline doğrulama

`BUILD.cmd` haritaları üretir, iki place dosyasını build eder, kaynakları derler
ve tüm offline kontrolleri çalıştırır. `TEST.cmd` mevcut build'i kaynakla karşılaştırır
ve testleri çalıştırır. Taşınabilir araçlar `.tools` içindedir; npm install gerekmez.
`npm run build` / `npm test` aynı scriptleri çağırır.
`scripts/package.ps1` doğrulanan build'i kaynakları ve taşınabilir araçlarıyla
ZIP'e koyar; her arşiv dosyasını yeniden okuyup SHA-256 karşılaştırır.

- Saf Luau tur/veri/Remote kuralları: `evidence/core-tests.json`.
- Gerçek DataService kodu + **sahte veri bağlantısı**: `evidence/data-service-tests.json`.
- Map/Power kodunun **sahte motor bağlamındaki** sınır kontrolleri: `evidence/service-contracts.json`.
- Binary/XML geri okuma, gömülü kaynak eşleşmesi, map/rota ve 4 ekran boyutu için
  GUI geometrisi: `evidence/place-audit.json`.
- Dosya boyutu, SHA-256 ve kaynak manifesti: `evidence/build-manifest.json`.

Bu kontroller fizik, ağ replikasyonu, gerçek Cloud DataStore, işitsel kalite,
gerçek telefon safe area/FPS veya insanlarla eğlence testini kanıtlamaz.

## Açık kabul işleri

Gerçek Studio'da tam qualification → tırmanış → final akışı ve 8 client testi, harita zıplama/kaos adaleti,
Cloud save/rejoin, telefon okunabilirliği/FPS, ses playback ve 16 oyunculu özel
sunucu testi henüz yapılmadı. Public yayın yapılmadı. Robux ürünleri ve platform
badge ID'leri açılmadı; özel party servisi ve arkadaş final bonusu ilk build'de yok.
Ücretli kozmetik, sezon/ranked gibi genişlemeler sonraki sürümlere bırakıldı.

Oyun varsayılan built-in SFX yollarını kullanır. **Özgün müziklerin oyunda çalması
için WAV'ların Roblox hesabına yüklenmesi ve ID'lerinin Config.Audio.Custom'a
girilmesi gerekir.** Uydurma ID eklenmedi. [Ses yönergesi](SES-KURULUMU.md).

[Studio kabul listesi](docs/STUDIO-TEST-KONTROL.md) ·
[Uygulama durumu ve kararlar](docs/UYGULAMA-DURUMU.md) ·
[Her aşamanın çalışma günlüğü](docs/CALISMA-GUNLUGU.md) ·
[Ana tasarım](docs/ROYAL-RUSH-TASARIM.md) ·
[Geliştirme/kabul planı](docs/GELISTIRME-PLANI.md)

Çalışma kökü `D:\Roblox\RoyalRush`. Roblox kurulumu `D:\Roblox`; oyun kaynakları
kurulumun Versions/Downloads/LocalStorage dosyalarına konmadı.
