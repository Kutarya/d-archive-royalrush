# Royal Rush — Çalışma günlüğü

## 9 Ekim 2026 — Studio olmadan geliştirme başlangıcı

Kullanıcı projeyi şimdi hazırlamamı, bitene kadar ilerlememi ve yaptıklarımı
her aşamada kaydetmemi istedi. Studio Playtest engeli kaynak ve paket üretimini
durdurmayacak; motor/çok oyunculu/telefon kabulü ayrı açık iş olarak tutulacak.

Hedef teslimat: Studio'da ek kod kopyalamadan açılabilen `.rbxl`/`.rbxlx`,
denetlenebilir Luau kaynakları, gerçek harita modelleri, offline kural/veri
testleri, yeniden üretilebilir build ve kullanım talimatı.

İlk inceleme: mevcut proje yalnızca tasarım belgelerinden oluşuyor. Node.js,
Python ve Git var; Rojo/Lune/Luau araçları PATH'te yok. Taşınabilir araçlar
proje içinde, resmi yayınlarından indirilecek. Roblox'a yayın yapılmayacak.

Test sınıfları:
- Luau derleme/sözdizimi ve saf kural testi: bu bilgisayarda yapılabilir.
- Place serialize/deserialize ve içerik denetimi: Studio olmadan yapılabilir.
- Gerçek Roblox fiziği, replikasyon, 8/16 client, Cloud DataStore, telefon FPS:
  Studio/Roblox ile sonradan yapılacak; şimdi geçti denmeyecek.

## Aşama 1 — Araçlar, kurallar ve harita üretimi

Resmi yayınlardan proje içi Rojo 7.7.1, Lune 0.10.5 ve Luau 0.741 indirildi.
Arşiv SHA-256 değerleri yayın metadata digest'leriyle kontrol edildi;
`.tools/toolchain.json` sürüm/kaynak/hash kaydıdır. Global kurulum yapılmadı.

Config, MatchRules, RoundModel, Profile, ChaosSelection ve RateLimiter yazıldı.
İlk Luau derlemesi geçti; bu sözdizimi/bytecode kontrolüdür, runtime kabulü değildir.
RoundModel aynı server örneklemesindeki ölümleri toplu işleyerek callback sırasının
galip seçmesini önler. Race sınırındaki eşit finisher'lar birlikte geçer.

MapBuilder; Sky Kingdom, Neon City ve Lava Factory'nin survival/ascent/final
düzenleri için gerçek Part/Model/trigger/spawn üretir. İlk serialization'da Lune
legacy Font alias uyumsuzluğu görüldü; açık FontFace kullanılarak düzeltildi.
Harita metadata/nesne sayısı `evidence/map-generation.json` dosyasına yazılıyor.

## Aşama 2 — Server uygulaması

Map/obstacle animasyonu ve taşıma, alan tabanlı hazard kontrolü, checkpoint,
Dash/Double Jump/Shield, sekiz Chaos handler, tur yönetimi, queue/AFK/spectator
durumları, ödül, profil kuyruğu, session lock, fixed cosmetic shop/daily/quest
işlemleri, Server King ve leaderboard kodları yazıldı.

F5 tek kişilik Studio kontrolü için solo pratik turnuvası tasarlandı; public
sunucuda minimum iki kişi korunuyor. Studio varsayılanı cloud yerine açıkça
etiketlenen geçici bellek profili. Gerçek veri yükleme hatasında profil read-only;
default eski kayıt üstüne yazılmıyor. Robux ürünleri açılmadı.

Kaynak incelemesinde survival timeout'unda qualify ödül sırası, başlangıçta yeniden
doğan karakterin spawn yeri ve aynı katılım ödülünün her frame yeniden kuyruğa
eklenmesi düzeltildi. Aynı server'daki ilk Race 30. saniyede Low Gravity gösterir;
sonraki maçlar uyumlu ağırlıklı havuzu kullanır. Mühendislik doğrulaması devam ediyor;
bu kayıt server'ın gerçek Roblox motorunda çalıştırıldığı anlamına gelmez.

## Aşama 3 — Client, arayüz ve ilk doğrulamalar

Türkçe/İngilizce HUD, mobil tek power butonu, Q/gamepad girişi, spectator,
kozmetik shop, loadout, yedi günlük reward, üç quest ve ayarlar eklendi.
Meteor/şok uyarıları client'ta fizik üretmeyen görseller kullanır. Düşük efekt
seçenekleri ve renge ek GO/!/↑/? sembolleri uygulandı. Victory kozmetiği kazananın
confetti rengine bağlandı; taht avatarında dış asset gerektirmeyen kutlama var.

64 ilk saf Luau testi geçti. SessionStore bozuk lock/revision kontrolü eklenince
65 test geçti: tur eşitliği, 8→6→4→1 model akışı, veri migration/session ownership,
idempotent reward, shop/daily/quest, Remote payload/rate limit ve event uyumu.
Bu akış sekiz gerçek Roblox client'ı veya gerçek Cloud DataStore değildir.

Server kodu incelemesinde yüklenemeyen oyuncular çıkarılınca quota'nın azaltılması,
erken durdurulan Chaos'a survive quest verilmemesi ve eski map metadata cleanup'ı
düzeltildi. İlk finish analytics'i eklendi. Harita yükleme isteği hata verirse
client başarılı ACK göndermiyor. Lobby power pratiği ödül/quest üretmez.

İlk binary `.rbxl` ve XML `.rbxlx` Rojo ile üretildi. Serialized audit'te Lune'un
CFrame/Position alias farkı nedeniyle denetim kodu düzeltildi. 320 px genişlikte
power açıklamasının 5 px taşması bulundu; 88 px açıklama genişliğiyle düzeltildi.
GUI nesne sayısı için gereksiz tahmini assertion gerçek round-trip karşılaştırması
ile değiştirildi. Son build/audit ve teslim paketi aşaması sürüyor.

## Aşama 4 — Kayıt/oynanış sınırları ve teslim hazırlığı

Gerçek DataService sahte UpdateAsync transport ile çalıştırıldı: load/save hatası,
future schema, kritik satın alma rollback, sırayla işlem/retry, session kaybı,
shutdown flush/unlock ve Studio belleği. Sahte bağlantı testi canlı DataStore değildir.
Session kaybında profil read-only olur, sıradaki işlemler de reddedilir; queue 32 ile
sınırlanır. Cosmetic/UI observer hatası veri kuyruğunu kilitlemez.

Kod incelemesinde Rising Danger overtime lavının son deck'i de kaplayarak bütün
başarılı oyuncuları aynı anda öldürebileceği bulundu: nonfinal lav güvenli üst
deck'in altında durur. Finalde lav yükselmeye devam eder. Survival outer falling
tile'larının temas davranışı ve hızlı geçişlerde laser/knock swept kontrolü eklendi.
Shield'in engellediği ilk vuruştan hemen sonraki frame'de tekrar itilme sorunu bir
saniyelik temas aralığıyla düzeltildi; aktif shield görseli eklenip cleanup'a bağlandı.
Map/Power gerçek kodu sahte motor bağlamıyla altı sınır testi geçti; motor fiziği değil.

ScreenInsets resmi API belgesine göre CoreUISafeInsets seçildi: hem notch hem
Roblox üst barı için. Gerçek telefon UI testi açık. İlk build scriptiyle 65 saf kural,
8 sahte DataService ve 165 serialized/GUI/rota kontrolü geçti. Observer izolasyonu
sonradan eklendiğinden final build bunu da yeniden doğrulayacak.

10 özgün PCM WAV üretildi ve yeniden açılarak format/süre/örnek sayıları doğrulandı.
Müzik için gerçek Roblox audio upload/asset permission/ID hâlâ gerekir; ID uydurulmadı.
BUILD.cmd / TEST.cmd / AC-STUDIO.cmd ile kaynak/build/sonradan açma yolu hazırlandı.
Studio locator'ın CheckOnly sonucu: place var, RobloxStudioBeta.exe bulunamadı.
README, uygulama durumu, ses yönergesi ve gerçek Studio kabul listesi güncellendi.

## Aşama 5 — Final offline build

Son kaynaklardan BUILD.cmd'nin çağırdığı build.ps1 çalıştırıldı. Sonuç:
- Luau compile: src/tools/tests sözdizimi/bytecode üretimi başarılı.
- Saf tur/veri/Remote kuralları: 65 geçti, 0 hata.
- Gerçek DataService + sahte transport: 9 geçti, 0 hata.
- Gerçek Map/Power kodu + sahte motor bağlamı: 6 geçti, 0 hata.
- Binary/XML kaynak/map/rota/GUI audit: 165 geçti, 0 hata; 25 gömülü script.
- Toplam 245 offline kontrol. 10 WAV ayrıca yeniden okundu.

Dosyalar: RoyalRush.rbxl (70.860 bayt), RoyalRush.rbxlx (1.236.090 bayt).
Kesin SHA-256 değerleri evidence/build-manifest.json dosyasında; bu manifest
RuntimeTested=false ve Published=false olarak işaretlidir. Paketleme scripti
her ZIP entry'sini açıp byte boyutu/SHA-256 ile kaynak dosyasına karşılaştırır.

Kaynak/harita/place/notlar teslimi tamamlandı. Native Studio Play, 8/16 gerçek
client, gerçek cloud rejoin, gerçek mobil FPS/okunabilirlik ve ses playback
yapılmadı. Bu kabul işleri STUDIO-TEST-KONTROL.md içinde açık bırakıldı; Studio
olmadan "oyun kusursuz/kanıtlandı/public hazır" sonucu çıkarılmıyor.

## Aşama 6 — Gerçek Studio ilk açılış ve kullanıcı denemesi

9 Ekim 2026 sabahı kullanıcının açık Studio'sunda Ctrl+O ile
`D:\Roblox\RoyalRush\RoyalRush.rbxl` yüklendi. Aydınlatma dönüşüm bildirimi
kapatıldı. F5 gerçek Play testi: lobby/avatar/Türkçe HUD/geçici profil etiketi,
20 s bekleme/streaming/3 s giriş ve Sky Kingdom Race görüldü. Finish yapılmadan
süre bittiğinde beraberlik/sonuç, lobby ve Neon City yeni maçı çalıştı.

Neon City'de Super Speed ön uyarısı ve aktif UI görüldü. Viewport'ta Q/Dash
denendi: ileri atılım ve 10 saniyelik cooldown. İstemci/sunucu F9 konsolları
0 hata/0 uyarı gösterdi; Output ilk ve ikinci maç geçişlerini verdi. Üçüncü
maçta Sky Kingdom tekrar başladı. Pencere büyütüldü ve Play'in gereksiz panelleri
gizlendi. Kullanıcıya temiz başlangıç bırakmak için kısa test durduruldu.

SHA-256 dosyadan yeniden doğrulandı; kaynak veya place değiştirilmedi.
Kanıt `evidence/studio-smoke-2026-10-09.md` içine yazıldı. README, uygulama
durumu ve kabul listesi gerçek ilk açılışı yansıtacak şekilde güncellendi.
Yalnız üç doğrudan görülen kabul kutusu işaretlendi. Tam qualification → final,
2/8/16 client, cloud rejoin, mobil ve ses testleri hâlâ açık. Yayın yapılmadı.

Notlar yazıldıktan sonra F5 ile temiz Play oturumu yeniden başlatıldı. Avatar
lobby'ye geldi; başlangıç profili 0 Crowns ve yeni geri sayım görüldü. Studio
açık ve Play çalışır durumda kullanıcı denemesine bırakıldı.


## 2 Kasım 2026 — GitHub arşiv aktarımı

Kullanıcı D: projelerini GitHub'a aktarıp ardından yerel kopyaları silmeyi istedi.
Hedef özel depo: https://github.com/Kutarya/d-archive-royalrush. Kaynak anlık kopyası ve
şifreli tam dosya arşivleri aktarılır; sırlar kaynak görünümünden çıkarılır.
Yerel silme yalnız bütün dosyaların arşiv CRC/boyut denetimi, GitHub SHA-256
eşleşmesi ve son kaynak değişiklik kontrolünden sonra yapılabilir. Bu not
tek başına aktarımın veya silmenin tamamlandığını kanıtlamaz; nihai durum
GitHub release dosyaları ve sahibine teslim edilen aktarım raporundadır.
