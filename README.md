# qrp-multicharacter

A multicharacter selection and creation screen for QBCore. When a player joins the server, it lists their characters, shows the selected character in front of the camera wearing its outfit, and lets them create a new character and choose a spawn point. The UI is written with Vue 3 + Vite + Tailwind CSS.

Version: `1.0.0` (`fxmanifest.lua`).

## Features

- Character slots (`Config.MaxCharacters`, default 4). An occupied slot shows the character's name, job, playtime, bank balance and phone number.
- New character form: first name, last name, date of birth, nationality (a list of 12 options) and gender.
- The selected character is spawned with its saved appearance (`playerskins` table) and shown to the camera with an animation.
- Two camera modes: `static` and `cinematic` (see below).
- Optional portrait mode: depth of field (DOF) blur on the camera.
- Spawn point selector after a character is chosen. If the character has a saved last position, it is added to the top of the list as "Last Location". Switch between locations with `←` / `→` and spawn with `Enter`.
- When a new character is created, the appearance/clothing menu can be opened (`qb-clothing`, `illenium-appearance`, `fivem-appearance`).
- The UI is in English and Turkish. The initial language is set with `Config.UI.defaultLanguage` and can be changed with the language button on screen.
- Optional character delete button (`Config.DeleteCharacter`).

## Requirements

- `qb-core`
- `oxmysql`
- Appearance script: `qb-clothing`, `illenium-appearance` or `fivem-appearance`
- Node.js and npm to build the UI

The script uses QBCore's `players` table and the appearance script's `playerskins` table. It has no SQL file of its own.

## Installation

1. Clone the repo into your `resources` folder:

   ```bash
   git clone https://github.com/Burqk1/qrp-multicharacter.git
   ```

2. Build the UI. The build output (`html/`) is not included in git; `fxmanifest.lua` loads the UI from `html/index.html`:

   ```bash
   cd qrp-multicharacter/web
   npm install
   npm run build
   ```

   `vite.config.js` writes the output to the `html/` directory one level up.

3. Start it in `server.cfg` after its dependencies:

   ```cfg
   ensure oxmysql
   ensure qb-core
   ensure qb-clothing        # veya kullandığınız görünüm scripti
   ensure qrp-multicharacter
   ```

4. This resource opens the character screen by itself (`qrp-multicharacter:server:requestCharacters` is triggered when the session starts). Don't run it alongside another multicharacter script that does the same job (e.g. `qb-multicharacter`).

## Configuration (`config.lua`)

### General

| Key | Default | Description |
|---|---|---|
| `Config.MaxCharacters` | `4` | Number of slots shown |
| `Config.StartingMoney` | `cash = 500`, `bank = 5000` | Starting money for a new character. If the table is removed, QBCore's `QBConfig.Money.MoneyTypes` values are used. |
| `Config.StartingItems` | `{}` | Items given to a new character, in the form `{ item = 'ad', amount = 1 }`. For `id_card`, the ID info is filled in automatically. If empty, the script gives no items. |
| `Config.DefaultSpawn` | Airport | Used when no spawn point is given in the `qrp-multicharacter:client:spawnPlayer` event |
| `Config.SpawnLocations` | 4 locations | Locations in the spawn selector: `name`, `coords` (`vector4`), `icon` |
| `Config.Debug` | `false` | Prints detailed logs to the console |

### UI (`Config.UI`)

| Key | Default | Description |
|---|---|---|
| `enableEscapeKey` | `true` | If `false`, the `Esc` key doesn't close the UI |
| `defaultLanguage` | `"en"` | Initial UI language: `"en"` or `"tr"` |

### Character deletion (`Config.DeleteCharacter`)

| Key | Default | Description |
|---|---|---|
| `enabled` | `true` | Shows the "Sil" ("Delete") button on an occupied slot. If `false`, the button is hidden, and the client NUI callback and the server's `deleteCharacter` event also reject the request. |
| `requireConfirmation` | `true` | If `true`, the first press shows "Silmeyi onayla" ("Confirm delete") on the button, and the character is deleted on the second press |

### Camera (`Config.Camera`)

The `mode` value can be `"static"` or `"cinematic"`.

- **static** (default): The camera first looks at the city from the `cinematic.camera.idle` position. When a character is selected, the ped is spawned at a random point from `cinematic.randomLocations` and the camera moves in on it.
- **cinematic**: Only takes effect when `cinematic.useRPC = true`. The character walks or does an activity at the selected point, and the camera follows it.

Fields used:

| Key | Description |
|---|---|
| `static.fov` | Camera FOV when moving in on the character |
| `static.portraitMode` | If `true`, DOF blur is enabled |
| `cinematic.useRPC` | Must be `true` for `cinematic` mode to be enabled |
| `cinematic.useBucket` | In `cinematic` mode, moves the player to a separate routing bucket during selection (population disabled) |
| `cinematic.bucketId` | ID of that bucket (default `999999`) |
| `cinematic.walkAnimation` | Walk animation set |
| `cinematic.randomLocations` | Points where the ped is spawned (list of `vector4`). Both modes use this. |
| `cinematic.initialActivities` | `wander`, `stand`, `phone`, `smoke` |
| `cinematic.camera.idle` | Sky/city view: `coords`, `pointAt`, `fov` |
| `cinematic.camera.follow` | Follow camera: `offset`, `fov` |
| `cinematic.camera.transition.duration` | Transition time from the sky to the character (ms) |

### Appearance (`Config.Appearance`)

| Key | Default | Description |
|---|---|---|
| `script` | `"qb-clothing"` | `qb-clothing`, `illenium-appearance` or `fivem-appearance` |
| `openOnCreate` | `true` | Opens the appearance menu when a new character is created |

## Character deletion

The "Sil" ("Delete") button in the UI calls the `deleteCharacter` NUI callback, which in turn calls the `qrp-multicharacter:server:deleteCharacter` event. If `Config.DeleteCharacter.enabled` is on and the character belongs to the player's license, the server calls `QBCore.Player.DeleteCharacter` and then sends the updated character list back to the UI. The server-side `DeleteCharacter` export is not affected by this setting. The button was added in the source code (`web/src/components/CharacterSelection.vue`); rebuild the UI (`npm run build`) for it to take effect.

## Exports

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

## Events

Server (triggered from the client):

- `qrp-multicharacter:server:requestCharacters`
- `qrp-multicharacter:server:selectCharacter` (`citizenid`)
- `qrp-multicharacter:server:createCharacter` (form data)
- `qrp-multicharacter:server:deleteCharacter` (`citizenid`)
- QBCore callback: `qrp-multicharacter:server:getAppearance` (`citizenid`)

Client (triggered from the server):

- `qrp-multicharacter:client:openCharacterSelection`
- `qrp-multicharacter:client:closeNUI`
- `qrp-multicharacter:client:transitionToSpawnSelector`
- `qrp-multicharacter:client:openSpawnSelector`
- `qrp-multicharacter:client:characterDeleted`
- `qrp-multicharacter:client:spawnPlayer`

When the player spawns, `QBCore:Server:OnPlayerLoaded` and `QBCore:Client:OnPlayerLoaded` are triggered.

## Development

`web/package.json` scripts:

```bash
cd web
npm run dev       # Vite geliştirme sunucusu (port 3000), tarayıcıda örnek verilerle açılır
npm run build     # ../html/ klasörüne derleme
npm run preview   # Derlenmiş çıktıyı önizleme
```

`web/README.md` is Vite's default template file, and `web/src/components/HelloWorld.vue` is also left over from the template. `HelloWorld.vue` and `CharacterSlot.vue` are not imported anywhere; the components used on screen are `CharacterSelection.vue` and `SpawnSelector.vue`.

## License

There is no LICENSE file in the repo.
