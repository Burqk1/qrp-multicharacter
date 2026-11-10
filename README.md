# qrp-multicharacter

QBCore için çoklu karakter seçim ve oluşturma ekranı. Oyuncu sunucuya girdiğinde karakterlerini listeler, seçilen karakteri kamera önünde kıyafetiyle gösterir, yeni karakter oluşturmayı ve doğma noktası seçmeyi sağlar. Arayüz Vue 3 + Vite + Tailwind CSS ile yazılmıştır.

Sürüm: `1.0.0` (`fxmanifest.lua`).

## Özellikler

- Karakter slotları (`Config.MaxCharacters`, varsayılan 4). Dolu slotta karakterin adı, işi, oyun süresi, banka bakiyesi ve telefon numarası gösterilir.
- Yeni karakter formu: ad, soyad, doğum tarihi, uyruk (12 seçenekli liste) ve cinsiyet.
- Seçilen karakter kayıtlı görünümüyle (`playerskins` tablosu) oluşturulup bir animasyonla kameraya gösterilir.
- İki kamera modu: `static` ve `cinematic` (aşağıya bakın).
- İsteğe bağlı portre modu: kamerada alan derinliği (DOF) bulanıklığı.
- Karakter seçildikten sonra doğma noktası seçici. Karakterin kayıtlı son konumu varsa listenin başına "Last Location" olarak eklenir. Konumlar arasında `←` / `→` ile geçilir, `Enter` ile doğulur.
- Yeni karakter oluşturulunca görünüm/kıyafet menüsü açılabilir (`qb-clothing`, `illenium-appearance`, `fivem-appearance`).
- Arayüz İngilizce ve Türkçe; ekrandaki dil düğmesiyle değiştirilir.

## Gereksinimler

- `qb-core`
- `oxmysql`
- Görünüm scripti: `qb-clothing`, `illenium-appearance` veya `fivem-appearance`
- Arayüzü derlemek için Node.js ve npm

Script, QBCore'un `players` tablosunu ve görünüm scriptinin `playerskins` tablosunu kullanır. Kendine ait bir SQL dosyası yoktur.

## Kurulum

1. Repoyu `resources` klasörüne klonlayın:

   ```bash
   git clone https://github.com/Burqk1/qrp-multicharacter.git
   ```

2. Arayüzü derleyin. Derleme çıktısı (`html/`) git'e dahil değil; `fxmanifest.lua` arayüzü `html/index.html` üzerinden yükler:

   ```bash
   cd qrp-multicharacter/web
   npm install
   npm run build
   ```

   `vite.config.js` çıktıyı bir üst klasördeki `html/` dizinine yazar.

3. `server.cfg` dosyasında bağımlılıklardan sonra başlatın:

   ```cfg
   ensure oxmysql
   ensure qb-core
   ensure qb-clothing        # veya kullandığınız görünüm scripti
   ensure qrp-multicharacter
   ```

4. Bu resource karakter ekranını kendisi açar (oturum başlayınca `qrp-multicharacter:server:requestCharacters` tetiklenir). Aynı işi yapan başka bir multicharacter scriptiyle (ör. `qb-multicharacter`) birlikte çalıştırmayın.

## Yapılandırma (`config.lua`)

### Genel

| Anahtar | Varsayılan | Açıklama |
|---|---|---|
| `Config.MaxCharacters` | `4` | Gösterilen slot sayısı |
| `Config.StartingItems` | `{}` | Yeni karaktere verilecek eşyalar, `{ item = 'ad', amount = 1 }` biçiminde. `id_card` için kimlik bilgileri otomatik doldurulur. Boşsa script eşya vermez. |
| `Config.DefaultSpawn` | Havaalanı | `qrp-multicharacter:client:spawnPlayer` olayında doğma noktası verilmezse kullanılır |
| `Config.SpawnLocations` | 4 konum | Doğma seçicideki konumlar: `name`, `coords` (`vector4`), `icon` |
| `Config.Debug` | `false` | Konsola ayrıntılı log basar |

### Kamera (`Config.Camera`)

`mode` değeri `"static"` veya `"cinematic"` olabilir.

- **static** (varsayılan): Kamera önce `cinematic.camera.idle` konumundan şehre bakar. Bir karakter seçilince ped, `cinematic.randomLocations` içinden rastgele bir noktada oluşturulur ve kamera ona yaklaşır.
- **cinematic**: Yalnızca `cinematic.useRPC = true` iken etkinleşir. Karakter seçilen noktada yürür veya bir aktivite yapar, kamera onu takip eder.

Kullanılan alanlar:

| Anahtar | Açıklama |
|---|---|
| `static.fov` | Karaktere yaklaşırken kameranın FOV'u |
| `static.portraitMode` | `true` ise DOF bulanıklığı açılır |
| `cinematic.useRPC` | `cinematic` modunun açılması için `true` olmalı |
| `cinematic.useBucket` | `cinematic` modda oyuncuyu seçim sırasında ayrı bir routing bucket'a alır (popülasyon kapalı) |
| `cinematic.bucketId` | Bu bucket'ın ID'si (varsayılan `999999`) |
| `cinematic.walkAnimation` | Yürüme animasyon seti |
| `cinematic.randomLocations` | Pedin oluşturulacağı noktalar (`vector4` listesi). Her iki mod da bunu kullanır. |
| `cinematic.initialActivities` | `wander`, `stand`, `phone`, `smoke` |
| `cinematic.camera.idle` | Gökyüzü/şehir görünümü: `coords`, `pointAt`, `fov` |
| `cinematic.camera.follow` | Takip kamerası: `offset`, `fov` |
| `cinematic.camera.transition.duration` | Gökyüzünden karaktere geçiş süresi (ms) |

### Görünüm (`Config.Appearance`)

| Anahtar | Varsayılan | Açıklama |
|---|---|---|
| `script` | `"qb-clothing"` | `qb-clothing`, `illenium-appearance` veya `fivem-appearance` |
| `openOnCreate` | `true` | Yeni karakter oluşturulunca görünüm menüsünü açar |

### Şu an kodda kullanılmayan ayarlar

Aşağıdaki anahtarlar `config.lua` içinde tanımlı ama `client/main.lua` veya `server/main.lua` tarafından okunmuyor. Değiştirmeniz bir şey değiştirmez:

- `Config.StartingMoney`
- `Config.PedModels`
- `Config.UI` (`useMouse`, `enableEscapeKey`, `defaultLanguage`). Arayüz her zaman İngilizce başlar, dil düğmeyle değiştirilir.
- `Config.DeleteCharacter.enabled`. `requireConfirmation` okunuyor ama içi boş (TODO).
- `Config.Camera.cinematic.walkSpeed`, `camera.start`, `camera.transition.easeType`
- `Config.Camera.static.coords`, `static.characterPosition`, `static.animations`

## Karakter silme

Sunucuda `qrp-multicharacter:server:deleteCharacter` olayı ve `deleteCharacter` NUI callback'i var. Sunucu, karakterin oyuncunun lisansına ait olduğunu kontrol edip `QBCore.Player.DeleteCharacter` çağırıyor. Ancak mevcut Vue arayüzünde bu callback'i çağıran bir silme düğmesi yok.

## Exportlar

Client:

```lua
exports['qrp-multicharacter']:OpenCharacterSelection(characters)
exports['qrp-multicharacter']:CloseCharacterSelection()
```

Server:

```lua
exports['qrp-multicharacter']:GetPlayerCharacters(license)        -- players tablosundaki satırlar
exports['qrp-multicharacter']:SelectCharacter(source, citizenid)  -- lisans kontrolü + QBCore.Player.Login
exports['qrp-multicharacter']:DeleteCharacter(source, citizenid)  -- lisans kontrolü + QBCore.Player.DeleteCharacter
```

## Olaylar

Server (client'tan tetiklenir):

- `qrp-multicharacter:server:requestCharacters`
- `qrp-multicharacter:server:selectCharacter` (`citizenid`)
- `qrp-multicharacter:server:createCharacter` (form verisi)
- `qrp-multicharacter:server:deleteCharacter` (`citizenid`)
- QBCore callback: `qrp-multicharacter:server:getAppearance` (`citizenid`)

Client (server'dan tetiklenir):

- `qrp-multicharacter:client:openCharacterSelection`
- `qrp-multicharacter:client:closeNUI`
- `qrp-multicharacter:client:transitionToSpawnSelector`
- `qrp-multicharacter:client:openSpawnSelector`
- `qrp-multicharacter:client:characterDeleted`
- `qrp-multicharacter:client:spawnPlayer`

Oyuncu doğduğunda `QBCore:Server:OnPlayerLoaded` ve `QBCore:Client:OnPlayerLoaded` tetiklenir.

## Geliştirme

`web/package.json` scriptleri:

```bash
cd web
npm run dev       # Vite geliştirme sunucusu (port 3000), tarayıcıda örnek verilerle açılır
npm run build     # ../html/ klasörüne derleme
npm run preview   # Derlenmiş çıktıyı önizleme
```

`web/README.md` Vite'ın varsayılan şablon dosyasıdır; `web/src/components/HelloWorld.vue` de şablondan kalmadır. `HelloWorld.vue` ve `CharacterSlot.vue` hiçbir yerde import edilmiyor; ekranda kullanılan bileşenler `CharacterSelection.vue` ve `SpawnSelector.vue`.

## Lisans

Repoda bir LICENSE dosyası yok.
