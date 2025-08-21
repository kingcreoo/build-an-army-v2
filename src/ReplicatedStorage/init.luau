-- // Settings, initialized by KingCreoo on 8-19-2025
-- // Holds all basic game data

local SETTINGS = {}

SETTINGS.DEFAULT_DATA = {
    ["leaderstats"] = {
        ["Credits"] = 100
    },
    ["Plot"] = {
        ["ActiveSoldiers"] = {
            ["1"] = "Default",
            ["2"] = "Default"
        },
        ["ActiveTarget"] = "Default",
        ["Unlocks"] = {
            ["1"] = true,
            ["2"] = true,
            ["3"] = false,
            ["4"] = false,
            ["5"] = false
        }
    },
    ["Inventory"] = {
        ["InactiveSoldiers"] = {},
        ["InactiveTargets"] = {}
    }
}

return SETTINGS