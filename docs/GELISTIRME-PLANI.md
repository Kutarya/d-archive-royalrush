# Royal Rush — Geliştirme ve kabul planı

Sürüm: **Plan 1.0** · Tarih: **9 Ekim 2026**.
Bu belge geliştirme ve gerçek kabul koşullarını tanımlar. Kaynak/asset/place
teslimi hazırdır; gerçek runtime kabulü ayrı tutulur. [Güncel durum](UYGULAMA-DURUMU.md).
Kuralların ana kaynağı [oyun tasarımı](ROYAL-RUSH-TASARIM.md).

**9 Ekim uygulama güncellemesi:** Kullanıcı Studio olmadan projeyi şimdi
tamamlamamı istedi. Bu nedenle kaynak/harita/place geliştirmesi ve offline testler
ilerleyecek; aşağıdaki gerçek Studio/insan/telefon kabul kapıları ayrı açık kalacak.
Bu değişiklik testlerin yapıldığı iddiası değildir. Güncel uygulama durumu
[çalışma günlüğünde](CALISMA-GUNLUGU.md) tutulur.

## 1. Çalışma ilkesi ve teslim sırası

Önce hareket + parkur + eleme; sonra Chaos ve power; sonra gerçek veri ve HUD;
ancak tam akış ve insan testi geçince ekonomi/sosyal içerik.

Her milestone döngüsü: **uygula → Studio Playtest → server/client Output oku →
ilgili gameplay'i dene → sorunu düzelt → kanıtı kaydet**.
Luau analizi, unit test veya dosyanın oluşması gerçek oyun testinin yerine geçmez.
Studio/ağ/tester eksikse kod durumu ile runtime kabulü ayrı kaydedilir; aşama
geçti diye işaretlenmez. Plan hazırlamak için bütün milestone'lar düşünülebilir.

| Sıra | Teslimat | Sonraki işe geçiş koşulu |
| --- | --- | --- |
| M0 | Çalışan Studio, test ortamı ve motor kararı | İki client gerçekten bağlanıyor |
| M1–M3 | Lobby, Race, tam turnuva ve Crown Climb | Basit haritada maç ve ikinci maç çalışıyor |
| M4–M5 | 4 Chaos, 2 power | Yetki/temizlik ve hareket kabulü |
| M6–M7 | Profil, ödül, HUD/spectator | G1: sekiz client ile eksiksiz gerçek akış |
| G2 | İnsanlarla çekirdek oyun testi | Eğlence/adalet sorunları düzeltilmiş |
| M8–M9 | Küçük shop, daily, sosyal prestij | Kalıcı ekonomi ve quest tutarlılığı |
| M10A | İki gerçek map ve MVP polish | G3: kapalı MVP kabulü |
| M10B | Public V1.0 içerik artışı | İçerik ve adalet regresyonları |
| M11–M12 | Güvenlik, performans, yayın adayı | G4: ölçüm ve yayın hazırlığı kabulü |

Süre tahmini şu anda verilmez: Studio kurulumu, kullanılabilir cihazlar ve ilk
parkurun üretim hızı ölçülmeden gün/hafta sözü gerçekçi değildir. M3'ten sonra
ölçülen iş süresine göre aşama tahmini güncellenir.

## 2. Planlanan proje düzeni

Çalışma kökü: `D:\Roblox\RoyalRush`. Aşağıdaki kaynak dizinleri uygulama başlarken
oluşturulur; şu anda README ve tasarım belgeleri dışında oyun kaynağı yoktur.

```text
RoyalRush/
  README.md
  docs/
    ROYAL-RUSH-TASARIM.md
    GELISTIRME-PLANI.md
  src/
    server/       # match, round, map, chaos, power, data, reward servisleri
    client/       # HUD, input, kamera, spectator, ses ve VFX
    shared/       # tipler, config, sözleşmeler; gerekirse saf simulation
  content/
    maps/         # test edilmiş map modelleri/segmentleri
    obstacles/    # yeniden kullanılabilir modeller ve parametreler
  tests/          # anlamlı kural, sınır, veri ve güvenlik testleri
  place/          # düzenlenebilir Studio proje dosyası
  evidence/
    M01/...       # loglar, görüntüler, test raporları
  releases/       # kabulü geçmiş build ve sürüm notları
```

ServerScriptService'te server; StarterPlayer/StarterGui'de client;
ReplicatedStorage'ta güvenli shared/network sözleşmesi; ServerStorage'ta map
kaynakları; Workspace'te lobby ve yalnızca aktif arena. Gizli profil/işlem
kayıtları client'a kopyalanmaz. Config ve içerik sürümü build kaydına girer.

M0'da Studio ile kaynak senkronizasyon yöntemi seçilir. Uygunsa Rojo; aksi halde
düzenlenebilir Studio dosyası ve denetlenebilir Luau kaynakları. Kurulmamış bir
araç veya bağlanmamış plugin çalışıyor varsayılmaz. Kaynak ve map yedeği sürüm
kontrolünde tutulur; bağımlılık kurulumunda sürüm ve kaynak doğrulanır.

## 3. Milestone'lar

### M0 — Studio ve küçük teknik doğrulama

İş: Roblox Studio'nun gerçekten kurulu/açılır olduğunu doğrula; boş test place'i
kaydet; server ve iki client aç; Output'u gözlemle. Ayrı dev/test veri alanı ve
gerekirse erişimi kısıtlı test experience'ı belirle. Production DataStore ile
Studio'nun deneysel kodunu aynı kayıt alanında çalıştırma.

Hareket motoru için küçük spike: normal yürüyüş/zıplama, hareketli platform,
Dash ve gecikme. Güncel server authority ayarları bu Studio'da uygunsa ölç;
uygun değilse standart hareket + server doğrulama sınırını kaydet. Bu tercih
sonraki power/obstacle mimarisini belirler.

Kabul: iki client aynı server'da; projeyi kapat/aç ve tekrar Play; beklenmeyen
server/client hata yok; motor kararı ve gözlenen sorunlar yazılı. İnstaller veya
bir .lua dosyası bu kabulü karşılamaz.

Mevcut başlangıç durumu: bu oturumdaki son kurulum denemesi SSL bağlantı hatası
verdi; Studio kurulumu doğrulanmadı. M0'da bu sorun çözülmeden Playtest geçti
denmeyecek. Tasarım belgelerinin hazırlanması bu engelden bağımsızdır.

### M1 — Proje yapısı, lobby ve state machine

İş: Luau tipleri ve temel config; merkezi state machine; tek maç sahibi servis;
queue/AFK tercihi; küçük lobby, portal, spawn ve taht alanı. Roster snapshot,
matchId/roundId/stateVersion ve iptal yolları ilk günden var.

Test: 1 kişiyle bekleme; 2 kişiyle geri sayım; geri sayımda birinin ayrılması;
üçüncü oyuncunun sonradan gelişi; queue dışındaki kişinin maça alınmaması.
State değişince eski callback'in işlem yapamadığını doğrula.

Kabul: Waiting ↔ Intermission doğru; kadro iki altına düşünce iptal; spawn güvenli;
Play'i durdurup yeniden başlatınca önceki görevler/bağlantılar kalmıyor. Geçici
state testi gerçek turnuva kabulü olarak sunulmuyor.

### M2 — Sky Kingdom Race ve fiziksel parkur

İş: geniş normal rota, start/finish, server checkpoint'leri, düşüş dönüşü,
qualification kontenjanı. İlk obstacle seti: MovingPlatform, RotatingBeam,
Spinner, DoorTiming. Dengeyi görmek için yalnızca gerekli HUD yazıları.

Test: güçsüz rota tamamla; platform üzerinde durup taşın; kenardan zıpla;
checkpoint'e dön; finish'i iki kez tetikle; checkpoint atlama ve keyfî teleport
ile finish dene; son geçerli frame ve deadline sınırını dene. Aynı örneklemede
kontenjan sınırını geçen iki oyuncuyu beraber qualification kuralıyla kontrol et.

Kabul: geçerli ilk finisher'lar sayılıyor; ölü/lobby oyuncusu finish alamıyor;
aynı kişi iki slot tüketmiyor. Mobil dokunmatik simülasyonla bütün zorunlu
zıplamalar yapılabiliyor. Güç zorunlu değil. Gerçek telefon testi daha sonra ayrıca.

### M3 — Çoklu turlar, final ve yeniden maç

İş: tasarımdaki 2–16 kadro tablosu; geçiş/teleport/load-unload; basit survival
greybox; Rising Danger kuralı ve Crown Climb. Taç bitişi veya tek hayatta kalan
galip. İlk seremoni ve lobby dönüşü; ödüller henüz kalıcı değildir.

Test: 2 oyunculu düello; 4 oyunculu kısa format; 8 → 6 → 4 → 1 akışı; finalde
taca ulaşma ve son hayatta kalan olmak iki ayrı senaryo. 16 oyunculu kontenjan
mantığını kural düzeyinde doğrula; bunu 16 gerçek client testi diye raporlama.
Timeout'ta az finisher, sıfır finisher retry, toplu ölüm, beraberlik, disconnect
ve map hazırlık hatasını dene. Survival overtime sonunda kalan herkes devam eder.

Kabul: merkezi servis tek galip/beraberlik üretir; geçişte roster korunur;
geç kalan oyuncu sonraki maçta; arka arkaya üç maç bitip lobby'ye döner;
harita/connection/task artığı birikmez. Map sanatı ve veri kaydı henüz kabul edilmez.

### M4 — Chaos framework ve dört event

İş: geçerli event havuzu, tier ağırlıkları, uyumluluk/etki bütçesi, server seed,
uyarı/start/stop/cleanup. Low Gravity, Super Speed, Vanishing Platforms,
Meteor Shower. Developer'a özel test seçimi oyuncu remote'uyla açılmaz.

Test: her eventi tek başına, düşüş/respawn, disconnect, round bitişi ve map unload
sırasında dene. Warn ile start arasında tur biterse event başlamamalı. Low Gravity
lobby'yi veya bir sonraki turu bozmamalı. Meteor gerçek hasar alanı ve göstergesi
eşleşmeli. Uygunsuz kombinasyon seçilmemeli; geçerli havuz boşsa olay atlanmalı.

Kabul: dört event'in gameplay etkisi görüldü ve tamamen geri alındı; server/client
aynı aktif durumu gösteriyor; bütün normal rotalar uygun event altında geçilebilir;
ilk Race referans testinde Low Gravity 30. saniyede çalışıyor. Test modu seçimi
production yetki açığı oluşturmuyor.

### M5 — Dash ve Double Jump

İş: ücretsiz loadout, maç kilidi, input bağlantısı, tek mobil power butonu,
server sahiplik/state/cooldown kontrolü, ölçülü VFX. Havada ikinci itiş ve
duvarı aşmayan Dash; karakter lifecycle temizliği.

Test: cooldown spam; yanlış tip/NaN/sonsuz değer; ölü/spectator/lobby kullanımı;
power değiştirip aktif maçı etkileme; yeniden spawn ile cooldown reset abuse;
duvara Dash; Low Gravity/Speed ile kullanım; 150–250 ms gecikmede geri bildirim.

Kabul: her iki güç anlamlı ve ücretsiz; rota güçsüz geçilebilir; cooldown server
tarafında doğru; client VFX reddedilmiş isteği geçerli aktivasyon gibi göstermiyor.
Double Jump aynı uçuşta tekrarlanmıyor. Q ile mobil buton aynı işleme bağlı.

### M6 — Gerçek profil ve ödül kaydı

İş: PlayerDataService, DataVersion 1, Level/TotalXP, Crowns/Wins/LocalWins,
settings; merkezi RewardService ve match/round tekilleştirme. Autosave, ayrılma,
server kapanışı, session lock ve dev/production ayrımı. Ödül UI'sı gerçek server
bakiyesini kullanır; bu aşamada Robux ürünü yoktur.

Test: yeni/var olan profil; kazanılan ödülle ayrıl/rejoin; hızlı server değişimi;
iki save'in sırayla retry olması; yükleme/kayıt hatası; lock kaybı; eski sürüm
migration; aynı sonuç iki kez; kritik kayıt sırasında ayrılma. Hata enjeksiyonu
testi ile gerçek cloud rejoin ayrı kanıtlar.

Kabul: gerçek test DataStore'da rejoin sonrası XP/Crowns/istatistik doğru;
default profil eski veriyi ezmiyor; bir result tekrarlandığında ikinci para yok;
yerel/rekabet wins ayrımı doğru. Cloud testi yapılamadıysa yalnızca yerel profil
adaptörü kabul edildi denir; kalıcı save tamamlandı denmez.

### M7 — Tam HUD, sonuç ve spectator

İş: timer, quota/alive, chaos, cooldown, qualification/eleme nedeni, sonuç,
Perfect/Clutch, spectator geçişi, lobby dönüşü ve basit erişilebilirlik ayarları.
UI input sırasında hareketi veya kamerayı gereksiz kilitlemez.

Test: küçük telefon/tablet/PC; jump-power çakışması; safe area; doğru event deadline;
spectate hedefi ölür/ayrılır; kimse yaşamaz; karakter yeniden doğar; spectator'dan
ikinci maça geçer. Ağda geç gelen state mesajları HUD'u geriye döndürmez.

Kabul: gerçek durumla HUD tutarlı; kamera geri dönüyor; temel düğmeler erişilebilir;
sonuçtaki ödül kaydedilen bakiye ile eşleşiyor. **G1 kabulü** bu aşamanın sonunda.

### G1 — İlk gerçek oynanabilir akış kapısı

Sekiz **gerçek Studio client**; NPC/test tablosu sekiz oyuncu diye sayılmaz.
Tek server, tercihen aynı testte kayıt kanıtı; eski tur kalıntılarını yakalamak
için bütün senaryo ikinci maçla tekrar edilir:

1. Sekiz oyuncu lobby'ye girer; 20 saniye geri sayım.
2. Sky Kingdom Race yüklenir; spawn tamamlanır; 3–2–1.
3. 27. saniye Chaos uyarısı; 30. saniye Low Gravity; sonra geri alma.
4. İlk altı geçerli finisher qualify; kalanlar elenir/izler veya lobby'ye döner.
5. Survival başlar; dört oyuncu devam eder. Draw/overtime farklı testte sınanır.
6. Crown Climb finali ve Rising Lava; kontrollü senaryoda üçü elenir, tek kişi kazanır.
7. Ayrı tekrarında birden fazla kişi yaşarken ilk geçerli Crown finish de galip verir.
8. Taç/seremoni; her ödül bir kez; profil kaydı ve rejoin kontrolü.
9. Lobby dönüşü; ikinci maç başlar, aynı oyuncularda kamera/HUD/hız/fizik normaldir.

Kanıt: server ve sekiz client Output, state/qualification/winner kaydı, gerçek
oyun görüntüsü, kaydedilen/rejoin profil karşılaştırması ve sürüm/seed bilgisi.
Otomatik giriş kullanılırsa belirtilir; insan keyif testiyle karıştırılmaz.
Bu akış geçmeden **M8 shop veya M9 daily geliştirmesine geçilmez**.

### G2 — İnsanlarla hareket ve eğlence testi

En az 4–8 insanla birkaç maç; yeni/mobil oyuncu dahil. İlk 10 saniyede hedefi
anlama, ilk qualification süresi, açık ölüm nedeni, kaçış penceresi, Dash/Double
Jump algısı ve kendi isteğiyle ikinci maç kontrol edilir. Core sorunlar önce
düzeltilir. Sadece geliştiricinin haritayı ezberleyerek tamamlaması kabul değildir.

20–30 yeni oyunculuk daha geniş gözlem kapalı MVP'de toplanabilir. Küçük ilk
grupta gerçek D1/D7 veya genel oyuncu kitlesi başarısı iddia edilmez. İnsan testi
henüz yoksa G2 açık kalır; geniş kozmetik üretimi yerine core tuning yapılır.

### M8 — Küçük shop ve kozmetik

İş: 4–6 garantili Crowns ürünü; sahiplik/equip; trail/title/victory; basit preview.
Gameplay gövdesi, hız ve power değişmez. Bir galibiyet sunumu, temizlenebilir
taç/confetti; sabit fiyat ve server ürün kataloğu.

Test: yetersiz bakiye, bilinmeyen ürün, eski fiyat, spam/çift tıklama, aynı ürün
tekrar satın alma, save hatası, çıkış/rejoin; equip sırasında character ölümü.
Kozmetik kaydı ile para düşümü tutarlı olmalı. VFX düşük ayarda sadeleşmeli.

Kabul: ürün/para tek tutarlı işlem; double spend veya item kaybı yok; ürün power
avantajı vermiyor. Gerçek Robux satışı bu küçük MVP shop'unun ön koşulu değil.

### M9 — Daily, quests, streak, Server King, leaderboard

İş: 7 günlük geri dönüş dostu claim; günlük üç görev; server tarih sınırı;
tekilleştirilmiş quest ödülü. Oturum streak'i ve kalıcı BestStreak; taht/avatar
görseli; küçük public leaderboard; temel achievements.

Test: gece/gün/hafta sınırı, client saatini değiştirme, claim spam, rejoin,
tekrarlanan gameplay event, kazanıp ayrılma, kaybetme, private/düello sonuçları.
Leaderboard erişim hatası maçı durdurmamalı. Kuyrukta beklemek görevi ilerletmez.

Kabul: claim/quest ödülü bir defa; eski streak yanlış devralınmıyor; queue ve
AFK durumu ödül kasmıyor; local/private win global kayda girmiyor. Weekly Quest
bu aşamaya gizlice eklenmez; V1.1 kapsamıdır.

### M10A — Kapalı MVP içerik ve polish

İş: Sky Kingdom ve Lava Factory iki gerçek map; toplam 10 obstacle; ilk dört
event/iki power. Map okunabilirliği, gerçek ses varlıkları, 1 victory animasyonu,
lobby ışık/portal, accessibility ve mobile safe area tamamlanır. Tamamen rastgele
segment üretimi yerine test edilmiş rotalar kullanılır.

Test: her map × uygun round × event × power kombinasyonunda rota/hitbox; yeni
oyuncu normal rota ve riskli kısa yol; streamed checkpoint dönüşü; 2/4/8 kişilik
maçlar; uygun koşulda 16 gerçek katılımcıyla ayrı test. Karelerin aynı renkte
değiştirilmesi yeni map veya yeni obstacle türü sayılmaz.

**G3 kapalı MVP kabulü:** G1/G2 regresyonu temiz; iki map gerçekten farklı;
telefonda oynanış denendi; 20–30 yeni oyuncudan ürün gözlemi/ikinci maç ölçümü;
save/rejoin ve kritik ekonomi testleri geçiyor. Önemli core kusur varsa Public
içerik sayısını büyütmek yerine önce bu kusur giderilir.

### M10B — Public V1.0 için kontrollü içerik artışı

İş: Neon City; 5 ek obstacle ile toplam en az 15 anlamlı tip; 4 ek event ile 8;
Shield ile 3 power; 12–16 kozmetik. Arkadaş katılımı ve final/spectate sunumu.
Her ek içerik bağımsız config, compatibility ve cleanup ile gelir.

Test: map/round/event uygunluk tablosu; World Is Breaking güvenli kaçışları;
Shield lav/void'u engellemiyor; bütün power'lar ücretsiz ve yan seçenek olarak
işlevli; düşük grafik modu; arkadaş geç katılırsa aynı sonraki maça katılım.

Kabul: yeni içerik G1/G3 akışını bozmadı. Rarity adı veya yeni model rengi farklı
mekanik yerine sayılmadı. Modüler rastgele rota ancak ayrıca ulaşılabilirlik ve
mobile regresyonu geçerse açılır.

### M11 — Güvenlik, veri dayanıklılığı ve performans

İş: mevcut kontrolleri uç koşullarda doğrula; rate limit, payload sınırı,
hareket/finish sınırı, profil/işlem tekilleştirme. Görsel havuzlama, streaming,
particle/ışık bütçeleri. Analytics dış gönderim ve ölçüm pipeline'ı doğrulanır.
Satış planlanıyorsa ProcessReceipt katmanı burada ayrıca gerçek platform
sandbox/test davranışı ve kayıt/tekrar senaryolarıyla kabul edilir.

Test: remote flood, yanlış state/roundId, NaN/sonsuz, finish spoof, checkpoint
atlama, speed/teleport; meşru Dash/Low Gravity/jump pad/platform taşıması; gecikme,
jitter, bağlantı kopması; aynı receipt'in tekrar gelişi; ürün kayıt hatası.

Performans: gerçek 16 katılımcı + en yoğun geçerli Chaos + spectator geçişleri;
seçilen düşük/orta sınıf telefon ve PC. Cihaz/model/ayar, FPS dağılımı, bellek,
server script/physics süresi kaydedilir. En az 10 ardışık maçta kalıcı büyüme
gözlenirse cleanup sorunu araştırılır; normal dalgalanma otomatik leak değildir.

Kabul: yetkisiz sonuç/para/power yok; yüksek pingli meşru oyuncuya otomatik ban
yok; hedef telefonda tipik 30 FPS veya üstü, PC'de 60 hedefi; önemli takılmalar
ve açık veri hataları giderildi. Telefon, gerçek 16 oyuncu veya cloud erişimi
test edilmediyse ilgili kabul açık kalır; simülasyon aynı şey diye sunulmaz.

### M12 — Yayın adayı ve yayın hazırlığı

İş: kabul edilen place/source snapshot, build/config sürümü, sürüm notları,
bilinen sınırlar, önceki sürüme dönüş planı. Creator Hub kimlikleri ve yetkileri,
16 oyuncu kapasitesi, mobil cihaz desteği, açıklama/icon/thumbnail, content
olgunluk bilgisi, ses/asset hakları, mağaza bilgileri ve test/prod ayrımı kontrol edilir.

Ücretli ürün varsa dinamik platform fiyatı gösterilir; gerçek ürün ID'si, receipt
ve sahiplik akışı doğrulanır. Test ürün/fiyatı veya sahte bakiye public build'de
kalmaz. Robux fiyatlarını ve son art direction'ı insan değerlendirmesi belirler.
Kaynak tasarıma bakıp "tüm cihazlarda sorunsuz" pazarlaması yapılmaz.

**G4 yayın adayı kabulü:** G1–G3 regresyonu, M11 güvenlik/performance, gerçek data,
seçilen mobil cihazlar ve 16 katılımcı kanıtı; kritik açık hata yok. Test edilmemiş
özellik kapalıdır. Data migration, eski build'e dönünce yeni veriyi ezmez.

Bu turdaki teslimat tasarım ve plan dosyalarıdır. Roblox'a yükleme veya halka açık
yayın yapılmış değildir. M12, gelecekte yayınlanacak adayın hazırlanmasını tanımlar.

## 4. Kritik test matrisi

| Alan | En az sınanacak durum | Beklenen sonuç |
| --- | --- | --- |
| Kadro | 1/2/3/4/8/16; queue dışı; geç katılım | Doğru format, roster ve minimum sayı |
| Geçiş | Eski round callback'i, map yükleme hatası, iptal | Yeni tur etkilenmiyor; güvenli dönüş |
| Race | İlk K, eşzamanlı sınır, timeout, 0/1 finisher | Gerçek finisher, açık tie/retry/galip kuralı |
| Survival | Hedef sayı, overtime, toplu ölüm | Rastgele eleme yok; doğru devam/beraberlik |
| Final | Crown finish, tek yaşayan, aynı anda ölüm/finish | Tek doğrulanmış galip veya beraberlik |
| Checkpoint | Önceki sıra, aktif hazard, streaming gecikmesi | Güvenli dönüş; shortcut/koruma abuse yok |
| Power | Cooldown, air limit, wall, death/reset, event combo | Server sınırı; ücretsiz eşit erişim |
| Chaos | Her event start/stop, tur bitişi, uygun havuz boş | Yanlış combo yok; tam geri alma |
| Kamera/UI | Spectate ölüm/kopma, lobby, sonraki maç, telefon | Görünür hedef, geri dönen kamera, erişilebilir UI |
| Profil | Load fail, save fail, rejoin, lock/migration | Eski veri korunuyor; doğru save durumu |
| Ödül/shop | Tekrarlı result/claim/purchase, işlemde ayrılma | Tek ödül, para ve sahiplik tutarlı |
| Sosyal | Global/local/private, streak kaybı, arkadaş gelişi | Rekabet kaydı ve prestij doğru |
| Ağ | Normal ve 150/250 ms gecikme; jitter/packet loss | Meşru hareket yanlış exploit sayılmıyor |
| Performans | Gerçek telefon, 16 katılımcı, yoğun VFX, 10 maç | Ölçülmüş hedefler; cleanup doğru |
| İkinci maç | Bütün ilk akışı bir kez daha tekrar et | Timer, loadout, gravity, HUD, veri artık taşımıyor |

Studio'nun yerel multi-client testi en fazla **8 client** sunar. 16 kişilik ürün
kabulü ayrıca erişimi sınırlı gerçek çok oyunculu testte yapılır. Device Simulator
ekran/dokunmayı gösterir; telefonun gerçek GPU/FPS/belleğini kanıtlamaz. Network
Simulator gecikme/jitter/packet loss denemelerinde kullanılabilir.
[Roblox Studio testing modes](https://create.roblox.com/docs/studio/testing-modes).

## 5. Kanıt dosyasının asgari biçimi

Her kabul kaydında aşağıdaki bilgiler bulunur:

```text
Aşama / tarih:
Build ve config sürümü:
Studio sürümü / kullanılan ağ modeli:
Client sayısı; gerçek insan mı, otomatik giriş mi:
Cihaz(lar), grafik ayarı, ağ koşulu:
Map / segment / event seed:
Denediğimiz senaryo ve beklenen sonuç:
Gerçekte gözlenen sonuç:
Server Output / client Output bağlantıları:
Gameplay görüntüsü / ölçüm dosyası:
Cloud kayıt ve rejoin kanıtı (ilgiliyse):
Kalan hata veya denenmemiş koşul:
Durum: tasarlandı / uygulandı / yerel test geçti / gerçek runtime kabulü geçti
```

Kimlik doğrulama bilgileri, token, cookie veya özel kullanıcı verisi test raporuna
yazılmaz. Output okunamadıysa "Console temiz" denmez. Ölçülmeyen FPS ve
insanlarca denenmeyen eğlence için sonuç uydurulmaz.

## 6. Bugünkü kayıt ve ilk sonraki adım

- Tamamlanan: fikir incelemesi, kuralların geliştirilmesi, kapsam ve 12 aşamalı plan.
- Tamamlanmayan: Studio kurulumu doğrulaması, oyun kodu/build, herhangi bir gameplay testi.
- İlk uygulama işi: **M0**, ardından yalnızca **M1 lobby + state machine**.
- İlk büyük teslim hedefi: **G1 — sekiz client ile tam maç ve ikinci maç**.
- En önemli ürün sorusu: **Oyuncu kendi isteğiyle bir maç daha oynuyor mu?**
