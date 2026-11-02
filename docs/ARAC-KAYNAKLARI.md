# Taşınabilir build araçları

Araçlar değiştirilmeden resmi release'lerinden alındı; `.tools/toolchain.json`
arşiv SHA-256 / published digest / kaynaklarını içerir. Oyun bu araçlara yalnız
offline build/test sırasında ihtiyaç duyar; Studio'da place açmak için gerekmez.

| Araç | Sürüm | Kaynak / lisans |
| --- | --- | --- |
| Rojo | 7.7.1 | [Kaynak](https://github.com/rojo-rbx/rojo/tree/v7.7.1), MPL-2.0; `.tools/licenses/rojo-MPL-2.0.txt` |
| Lune | 0.10.5 | [Kaynak](https://github.com/lune-org/lune/tree/v0.10.5), MPL-2.0; `.tools/licenses/lune-MPL-2.0.txt` |
| Luau | 0.741 | [Kaynak](https://github.com/luau-lang/luau/tree/0.741), MIT; `.tools/licenses/luau-MIT.txt` |

Resmi API referansları UYGULAMA-DURUMU.md ve SES-KURULUMU.md içinde bağlıdır.
Haritalar, GUI ve WAV'lar bu projenin kaynaklarından üretilir; dış marketplace
script/model kullanımı yoktur.
