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

return SETTINGS