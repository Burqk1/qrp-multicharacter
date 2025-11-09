Config = {}

-- Genel Ayarlar
Config.MaxCharacters = 4 -- Maksimum karakter sayısı
Config.StartingMoney = {
    cash = 500,
    bank = 5000
}

-- Karakter Seçim Kamerası ve RPC Ayarları
Config.Camera = {
    -- Kamera modu: "static" (sabit kamera) veya "cinematic" (karakteri takip eden kamera)
    mode = "cinematic", -- "static" veya "cinematic"

    -- Cinematic mod için
    cinematic = {
        useRPC = true, -- RPC (Remote Procedure Call) kullan
        useBucket = true, -- Oyuncuyu ayrı routing bucket'a at (diğer oyuncular görmesin)
        bucketId = 999999, -- Bucket ID (benzersiz olmalı)
        walkAnimation = "move_m@confident", -- Yürüme animasyonu
        walkSpeed = 1.0, -- Yürüme hızı

        -- Rastgele spawn lokasyonları (GTA gibi - karakterler farklı yerlerde görünür)
        randomLocations = {
            -- Beach
            -- vector4(-1652.24, -1045.81, 13.15, 320.61),
            -- Downtown
            -- vector4(223.48, -809.37, 30.73, 249.44),
            -- -- Vinewood Hills
            -- vector4(1264.43, -430.52, 70.01, 156.78),
            -- -- Mirror Park
            -- vector4(1207.84, -620.12, 66.44, 17.89),
            -- -- Vespucci Canals
            -- vector4(-1022.24, -1487.58, 5.60, 298.45),
            -- -- Del Perro Pier
            -- vector4(-1820.12, -1204.35, 13.02, 334.12),
            -- -- Legion Square
            -- vector4(195.32, -934.67, 30.69, 141.23),
            -- -- Rockford Hills
            -- vector4(-884.67, -448.23, 39.60, 27.89),
            -- -- Little Seoul
            -- vector4(-526.89, -217.45, 37.65, 209.34),
            -- -- Strawberry Ave
            vector4(82.34, -1948.67, 20.75, 318.90),
        },
        -- Kamera animasyonu
        camera = {
            -- Boşta kamera (karakter seçili değilken - GTA gibi gökyüzünden)
            idle = {
                coords = vector3(300.0, -200.0, 350.0), -- Gökyüzü - şehre bakış
                pointAt = vector3(300.0, -200.0, 50.0), -- Şehir merkezine bak
                fov = 70.0, -- Geniş açı
            },
            -- Başlangıç kamerası (otelin içi - uzaktan)
            start = {
                coords = vector3(330.0, -225.0, 56.0), -- Uzak mesafe
                pointAt = vector3(322.71, -217.57, 54.59), -- Karakterin başına bak
                fov = 50.0,
                duration = 2000, -- 2 saniye bu pozisyonda kal
            },
            -- Takip kamerası (karakter yürürken - önden soldan)
            follow = {
                offset = vector3(-0.8, 3.2, 0.0), -- Karakterin önünden soldan (x negatif = solda, y = mesafe, z = yükseklik)
                fov = 50.0, -- Daha geniş açı için tam boy görünüm
            },
            -- Geçiş ayarları
            transition = {
                duration = 3000, -- Sky'dan karaktere geçiş süresi (milisaniye)
                easeType = "smooth", -- Yumuşak geçiş
            }
        },

        -- Başlangıç aktivitesi (rastgele seçilir)
        initialActivities = {
            "wander",    -- Yürüyor
            "stand",     -- Duruyor
            "phone",     -- Telefonda
            "smoke",     -- Sigara içiyor
        },
    },

    -- Static mod için (eski sistem)
    static = {
        coords = vector4(-1355.93, -1487.78, 520.75, 120.0),
        fov = 50.0,
        enableBlur = true,
        blurIntensity = 10.0
    }
}

-- Spawn Lokasyonları
Config.DefaultSpawn = vector4(-1037.82, -2737.49, 20.17, 329.08) -- Airport

Config.SpawnLocations = {
    {
        name = "Havaalanı",
        coords = vector4(-1037.82, -2737.49, 20.17, 329.08),
        icon = "✈️"
    },
    {
        name = "Otobüs Durağı",
        coords = vector4(223.48, -809.37, 30.73, 249.44),
        icon = "🚌"
    },
    {
        name = "Motel",
        coords = vector4(327.56, -229.38, 54.22, 163.5),
        icon = "🏨"
    },
    {
        name = "Sahil",
        coords = vector4(-1652.24, -1045.81, 13.15, 320.61),
        icon = "🏖️"
    }
}

-- Ped Modelleri (Karakter oluşturma için)
Config.PedModels = {
    male = {
        "mp_m_freemode_01"
    },
    female = {
        "mp_f_freemode_01"
    }
}

-- Başlangıç İtemleri (QB-Core'un kendi sistemi kullanılır - qb-core/shared/main.lua içinde QBCore.Shared.StarterItems)
Config.StartingItems = {} -- Boş bırakın, QB-Core'un starter items'ını kullanır

-- UI Ayarları
Config.UI = {
    useMouse = true, -- Fare kontrolünü aç/kapa
    enableEscapeKey = true -- ESC tuşu ile kapatmayı aç/kapa
}

-- Karakter Silme Ayarları
Config.DeleteCharacter = {
    enabled = true, -- Karakter silme özelliğini aç/kapa
    requireConfirmation = true -- Silme onayı iste
}

-- Skinchanger/Appearance Script Ayarları
-- Kullandığınız appearance scriptine göre ayarlayın
Config.Appearance = {
    script = "qb-clothing", -- "qb-clothing", "illenium-appearance", "fivem-appearance" vb.
    openOnCreate = true -- Yeni karakter oluşturulduğunda appearance ekranını aç
}

-- Debug Mode
Config.Debug = true -- Debug mesajlarını göster/gizle
