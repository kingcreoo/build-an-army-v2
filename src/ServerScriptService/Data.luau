-- // Data, initialized by KingCreoo on 8-19-2025
-- // Module for managing player data persistence

local Data = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Settings = require(ReplicatedStorage:WaitForChild("Settings"))

local DataStore = DataStoreService:GetDataStore("DataStore2")

local Database = {}
local Saves = {}

-- Deep-clone a table so DEFAULT_DATA isn't mutated
local function DeepCopy(Table: table)
    local Copy = {}

    for K, V in pairs(Table) do
        if type(V) == "table" then
            Copy[K] = DeepCopy(V)
        else
            Copy[K] = V
        end
    end

    return Copy
end

-- Handle gathering player's data upon joining the game
function Data.Initialize(Player: Player)
    local PlayerData
    local NewPlayer

    local Success, ErrorMessage = pcall(function()
        PlayerData = DataStore:GetAsync("Player_" .. Player.UserId)
    end)

    if not Success then
        warn(ErrorMessage)
    end

    if not PlayerData then
        PlayerData = DeepCopy(Settings.DEFAULT_DATA)
        NewPlayer = true
    end

    Database[Player.Name] = PlayerData

    return PlayerData, NewPlayer
end

-- Handle setting player's data after changes
function Data.Set(Player: Player, PlayerData: table)
    Database[Player.Name] = PlayerData

    local Leaderstats = Player:FindFirstChild("leaderstats")
    if Leaderstats then
        for Stat, Value in pairs(PlayerData["Stats"]) do
            local StatObject = Leaderstats:FindFirstChild(Stat)
            if StatObject then
                StatObject.Value = Value
            end
        end
    end

    local TimeOfTransaction = os.time()
    local ToSave

    if not Saves[Player.Name] then
        ToSave = true
    else
        if TimeOfTransaction - Saves[Player.Name] > 60 then
            ToSave = true
        end
    end

    if not ToSave then return end

    Saves[Player.Name] = TimeOfTransaction

    local Success, ErrorMessage = pcall(function()
        DataStore:SetAsync("Player_" .. Player.UserId, PlayerData)
    end)

    if not Success then
        warn(ErrorMessage)
    end
end

-- Returns player's data from the database
function Data.Get(Player: Player)
    return Database[Player.Name]
end

-- Removes player's data from the database
function Data.Remove(Player: Player)
    local PlayerData = DeepCopy(Database[Player.Name])
    print("Removing " .. Player.Name .. ". Their data:")
    print(PlayerData)
    Database[Player.Name] = nil

    local Success, ErrorMessage = pcall(function()
        DataStore:SetAsync("Player_" .. Player.UserId, PlayerData)
    end)

    if not Success then
        warn(ErrorMessage)
    end
end

return Data