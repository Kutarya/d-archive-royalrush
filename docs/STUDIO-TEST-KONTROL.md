# Studio ve canlı kabul kontrolü

İlk offline teslimde bu kutular açık bırakıldı. 9 Ekim 2026 sabahında gerçek
Studio ilk açılış testi yapıldı; yalnız doğrudan görülen maddeler işaretlendi.
Kanıt: `../evidence/studio-smoke-2026-10-09.md`. Tam maç/çok oyuncu/telefon testi açık.
Hata bulunursa Output ve adımlar `CALISMA-GUNLUGU.md` dosyasına kaydedilir.

## 1 — Tek kişi ilk açılış

- [x] RoyalRush.rbxl açılıyor; lobby, portal, taht ve istasyonlar görünüyor.
- [x] F5 ile karakter lobby'ye gelir; UI görünür, geçici Studio profili etiketi var.
- [x] 20 s intermission + en fazla 6 s streaming + 3 s giriş; ilk Race başlar.
- [ ] WASD/touch hareket, default jump ve Q/mobil güç çalışır.
- [ ] İlk Race'te 27. s uyarı; 30. s Low Gravity; event sonunda fizik geri döner.
- [ ] Race düşüşü checkpoint'e döner; PERFECT iptal olur; son kapı olmadan finish yok.
- [ ] Solo Race → Rising Danger → Crown Climb; crown'a ulaşınca sonuç/taht.
- [ ] Sonuçtan sonra yeni maç; arena/effect birikmez; Output hata içermez.

Kısmi kontrol: PC'de Q/Dash ileri atılımı ve 10 saniye cooldown gerçek motorda
görüldü. İlk iki yarış finish yapılmadan süre sonunda beraberlik/sonuç verdi;
lobby'ye dönüp yeni maç başladı (Sky Kingdom → Neon City → Sky Kingdom).
Super Speed ön uyarısı/aktif UI görüldü. F9 Client/Server: 0 hata, 0 uyarı.
Touch/jump, tüm etkinin fiziği ve instance birikmesi ölçülmediği için kapsamlı
maddeler açık tutuldu.

## 2 — Gerçek multiplayer

- [ ] Server & Clients ile 2 oyuncu: direkt final, bir kazanan veya açık beraberlik.
- [ ] 8 client: ilk 6 Race qualifier, survival hedef 4, final, XP/Crowns, ikinci maç.
- [ ] Her client kendi HUD/profilini alır; spectator hedef değiştirebilir.
- [ ] Aynı server adımındaki final toplu ölüm/eşit finish yanlış galip seçmez.
- [ ] Late join: lobby'de NEXT MATCH bilgisi; mevcut round'a yarışmacı girmez.
- [ ] Hazırlık sırasında ayrılma/streaming timeout turnuvayı donmuş bırakmaz.
- [ ] Race sıfır finisher olursa yalnız bir kolay retry; sonra sonuç/yeniden lobby.
- [ ] AFK queue kapanır; lobiye dönen aktif oyuncu aynı turu sürdüremez.
- [ ] 16 oyunculu özel test server'ında 12→8→4→1 hedefi ve peak performans.

## 3 — Güç/engel/kaos adaleti

- [ ] 15 obstacle türü hareket ve tehlike yönünü anlaşılır gösterir.
- [ ] Hareketli platform taşır; gerçek network altında jitter/geri çekme yoktur.
- [ ] Avatar ölçekleri zıplamayı bozmaz; mobil route ücretsiz power'larla geçilir.
- [ ] Dash duvarı aşmaz; Double Jump yalnız havada; cooldown server'da uygulanır.
- [ ] Shield bir knockback'i engeller ve kısa temas koruması verir; aura doğru biter.
- [ ] Shield lav/void ölümünü engellemez; lobby practice quest/win üretmez.
- [ ] 8 event uyarı/etki/cleanup; yanlış map, checkpoint kilidi, görsel körlük yoktur.
- [ ] Lag/ping, normal zıplama, dash, knockback validator'ı yanlış geri çekmez.
- [ ] İnsanlar neden elendiklerini anlar ve ikinci maç oynamak ister.

## 4 — Kalıcı veri ve güvenlik

Önce ayrı özel **test experience** kullan. Config.Persistence.Store için ayrı
`RoyalRush_Test_v1` adı ve StudioCloud=true ancak cloud testi sırasında.
Studio API access gerekli olabilir; üretim profilinde test yapma. Testten sonra
StudioCloud=false'ya dön. Public ayarlarda max players=16 ayrıca ayarlanır.

- [ ] XP/Crowns/Wins/owned/equipped/settings/daily/quest gerçek rejoin'de korunur.
- [ ] İkinci server session lock; API/lock hatası eski veri üstüne default yazmaz.
- [ ] Autosave, PlayerRemoving ve shutdown senaryolarında actual save/lock release.
- [ ] Yinelenen shop/daily/quest isteği para/ödülü iki kez uygulamaz.
- [ ] Kayıt hatasında kritik satın alma rollback; okunabilir save durumu.
- [ ] Malformed/spam/yanlış state Remote sonuç, para veya power vermez.
- [ ] Local/private wins global kaydı artırmaz; public sonuç board'da doğru görünür.
- [ ] Analytics event'leri Creator Dashboard'da görülür; sahte KPI raporu yoktur.

## 5 — Mobil/ses/yayın

- [ ] Telefon portrait/landscape safe area; jump/joystick/power çakışmaz.
- [ ] Text okunur; modal scroll/touch; color assist/low effects/volumes/auto spectate.
- [ ] Telefon FPS, memory, instance/particle limitleri; ölçüm bütçesi kaydedilir.
- [ ] Built-in SFX çalar; özgün WAV'ların asset/experience izinleri tamamlanır.
- [ ] Tester'larla map/kaos/tur süreleri ve ikinci maç davranışı ölçülür.
- [ ] İsim, thumbnail, açıklama, yaş/region/cihaz/yayın ayarları gözden geçer.
- [ ] G1/G2/G3 kabulünden sonra kapalı yayın ve public yayın ayrı kaydedilir.

Gerçek test kaydı: build SHA-256, Studio sürümü, cihaz/oyuncu sayısı, map/event/power,
server/client Output, beklenen/gerçek davranış, sonuç ve açık hata.
