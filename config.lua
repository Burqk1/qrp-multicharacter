Config = {}

Config.MaxCharacters = 4 
Config.StartingMoney = {
    cash = 500,
    bank = 5000
}

Config.Camera = {
    -- Kamera modu: "static" (sabit kamera) veya "cinematic" (karakteri takip eden kamera)
    mode = "static", -- "static" veya "cinematic"

    -- Cinematic mod için
    cinematic = {
        useRPC = true, -- RPC (Remote Procedure Call) kullan
        useBucket = true, -- Oyuncuyu ayrı routing bucket'a at (diğer oyuncular görmesin)
        bucketId = 999999, -- Bucket ID (benzersiz olmalı)
        walkAnimation = "move_m@confident", -- Yürüme animasyonu
        walkSpeed = 1.0, -- Yürüme hızı

        randomLocations = {

            vector4(82.34, -1948.67, 20.75, 318.90),
        },
        -- Kamera animasyonu
        camera = {
            idle = {
                coords = vector3(300.0, -200.0, 350.0), -- Gökyüzü - şehre bakış
                pointAt = vector3(300.0, -200.0, 50.0), -- Şehir merkezine bak
                fov = 70.0, -- Geniş açı
            },
            start = {
                coords = vector3(330.0, -225.0, 56.0), -- Uzak mesafe
                pointAt = vector3(322.71, -217.57, 54.59), -- Karakterin başına bak
                fov = 50.0,
                duration = 2000, -- 2 saniye bu pozisyonda kal
            },
            follow = {
                offset = vector3(-0.8, 3.2, 0.0), -- Karakterin önünden soldan (x negatif = solda, y = mesafe, z = yükseklik)
                fov = 40.0, -- Daha dar açı - karakter daha yakın ve büyük görünür (portre modu gibi)
            },
            transition = {
                duration = 3000, -- Sky'dan karaktere geçiş süresi (milisaniye)
                easeType = "smooth", -- Yumuşak geçiş
            }
        },

        initialActivities = {
            "wander",    -- Yürüyor
            "stand",     -- Duruyor
            "phone",     -- Telefonda
            "smoke",     -- Sigara içiyor
        },
    },

    static = {
        coords = vector4(-1355.93, -1487.78, 520.75, 120.0), -- Kamera pozisyonu
        fov = 40.0, -- Dar açı - karakter daha yakın ve büyük (portre modu gibi)
        portraitMode = true, -- Portre modu blur efekti - false yapın blur istemiyorsanız



        characterPosition = vector4(-1360.0, -1495.0, 519.75, 300.0),

        animations = {
            "WORLD_HUMAN_STAND_MOBILE",    -- Telefonda
            "WORLD_HUMAN_SMOKING",         -- Sigara içiyor
            "WORLD_HUMAN_AA_COFFEE",       -- Kahve içiyor
            "WORLD_HUMAN_CLIPBOARD",       -- Panoya bakıyor
            "WORLD_HUMAN_STAND_IMPATIENT", -- Sabırsız duruş
        }
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

Config.StartingItems = {} -- Boş bırakın, QB-Core'un starter items'ını kullanır

Config.UI = {
    useMouse = true, -- Fare kontrolünü aç/kapa
    enableEscapeKey = true, -- ESC tuşu ile kapatmayı aç/kapa
    defaultLanguage = "en" -- Varsayılan dil: "en" veya "tr"
}

Config.DeleteCharacter = {
    enabled = true, -- Karakter silme özelliğini aç/kapa
    requireConfirmation = true -- Silme onayı iste
}


Config.Appearance = {
    script = "qb-clothing", -- "qb-clothing", "illenium-appearance", "fivem-appearance" vb.
    openOnCreate = true -- Yeni karakter oluşturulduğunda appearance ekranını aç
}

-- Debug Mode
Config.Debug = false -- Debug mesajlarını göster/gizle
