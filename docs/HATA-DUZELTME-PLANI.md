# Oynanış düzeltme ve gerçek kabul planı

9 Ekim 2026. Kullanıcı ilk oynanışta sıkışma, animasyon ve kalite sorunları
bildirdi. İlk açılış smoke testi tam oynanış kabulü değildir.

Önceki kaynak/place ve Studio'daki kaydedilmemiş değişiklikler
`releases/before-gameplay-fixes-20261009-093830` içinde korundu.

1. Resmi MCP bağlantısı: sunucu/eklenti, gerçek Workspace okuması, Play/Output.
2. Hareket: network sahibi client ile çatışan server CFrame/velocity yazıları,
   zemin taşıması, conveyor ve dash duvar kontrolü, düşüş sonrası toparlanma.
3. Harita: başlangıç ve checkpoint spawn güvenliği, yeterli iniş alanı,
   spiral tırmanışın erişilebilir ilk basamağı, üst platform baş mesafesi.
4. Animasyon/görsel: varsayılan yürüyüş/zıplama korunur, power geri bildirimi,
   az ve okunur world yazıları, temaya uyan platform/engel siluetleri.
5. Gerçek motor kontrolü: yürüyerek bitiş, düşüp checkpoint'e dönüş,
   Race → Rising Danger → final → sonuç → yeni maç; dash/double jump/shield;
   kaos başlama/bitiş; client/server Output. Çok client ve cihaz kabulü ayrıca.
6. Yeni build/manifest/paket, açık hatalar ve her testin kanıtı; Studio'da son
   sürümü açıp kullanıcı denemesine bırakma. Public yayın bu kapsamda değil.

Kod incelemesiyle bulunan şüpheli noktalar (motor testi olmadan kapatılmaz):

- Hareketli platform `HumanoidRootPart.CFrame` değerini sunucuda her tick yazıyor.
- Conveyor oyuncunun Z hızını sabit 8 yapıyor; player input ile çatışıyor.
- Tırmanış ilk basamağı başlangıçtan çapraz uzakta; mevcut statik audit yalnız
  en yakın platformu arıyor, sıralı gerçek rotanın erişilebilirliğini kanıtlamıyor.
- Teleport model pivotunu doğrudan spawn'a koyuyor; avatar pivot/hip farkı güvenli
  ayak yüksekliğini garanti etmiyor. Recovery sonrası yürüyüş durumu doğrulanmalı.
- Sunucu knockback/jump velocity, client network simülasyonu ile birlikte test edilmeli.
- Dekor/sign ve HUD aynı görüş alanına yığılabiliyor; harekete göre okunabilirlik açık.

## MCP kurulum durumu

Yerleşik Assistant/MCP seçeneği açık Studio'da görünmedi. Roblox'un resmi
`studio-rust-mcp-server` v0.2.365 release'i kullanılıyor (artık geliştirilmediği
resmi README'de belirtiliyor). EXE SHA-256 GitHub release digest'iyle eşleşti:
`b370228d5135e291ec9c2a3436a8fe018d7b29b0f9718e45d56cfe5be74e0d0b`.
Eklenti aynı tag kaynaklarından Rojo ile üretildi. Codex `Roblox_Studio` kaydı
eklendi; MCP stdio initialize ve tools/list başarılı. Bunlar henüz Studio
Workspace'e erişimin başarılı olduğu anlamına gelmez; bağlantı ayrıca doğrulanır.

Studio kapatılırken kullanıcının mevcut değişiklikleri Kaydet ile korundu.
Yeniden açılışta eski EXE yolu pencere üretmedi; bu yol dosya sisteminde de yoktu.
Resmi imzası Valid olan mevcut Studio kurulum aracıyla kurulum onarımı başlatıldı.
