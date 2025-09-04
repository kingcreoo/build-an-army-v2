-- // Settings, initialized by KingCreoo on 8-19-2025
-- // Holds all basic game data

local SETTINGS = {}

SETTINGS.DEFAULT_DATA = {
    ["leaderstats"] = {
        ["Credits"] = 100
    },
    ["Plot"] = {
        ["Unlocks"] = {
            ["Slot1"] = true,
            ["Slot2"] = true,
            ["Slot3"] = false,
            ["Slot4"] = false,
            ["Slot5"] = false,
            ["Slot6"] = false,
            ["Slot7"] = false
        }
    },
    ["Inventory"] = {
        ["ActiveSoldiers"] = {},
        ["SoldierInventory"] = {},
        ["ActiveTarget"] = "",
        ["TargetInventory"] = {},
    }
}

SETTINGS.SOLDIER_DATA = {
    ["Default"] = {
        ["FireRate"] = 4,
        ["Damage"] = 1,
        ["BulletSpeed"] = 40
    }
}

SETTINGS.WEAPON_DATA = {
    ["M4"] = {
        ["C0"] = CFrame.new(-0.697, -2.093, 0.167) * CFrame.Angles(math.rad(-90), 0, 0),
        ["C1"] = CFrame.new(0, -0.062, -0.489)
    }
}

SETTINGS.TARGET_DATA = {
    ["Default"] = {
        ["TotalHealth"] = 3,
        ["TotalRespawnTime"] = 1,
        ["Reward"] = 3
    }
}

SETTINGS.DISTANCES = {
    ["Worlds"] = {
        ["Default"] = 55,
    },
    ["Tares"] = {
        ["Default"] = .75
    }
}

return SETTINGS