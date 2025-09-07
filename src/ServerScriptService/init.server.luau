-- // Server, initialized by KingCreoo on 8-19-2025
-- // Manages basic server functions & connectivity

-- // Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- // Modules
local Data = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Data"))
local Plot = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Plot"))
local SETTINGS = require(ReplicatedStorage:WaitForChild("Settings"))
local RewardLoop = require(ServerScriptService:WaitForChild("Server"):WaitForChild("RewardLoop"))

-- // Variables
local Anchors = Workspace:WaitForChild("Anchors")
local OccupiedAnchors = {}
local PlayerPlotManagers = {}
local CurrentStock
local TimeOfStock
local RecentPurchases = {}

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RestockEvent: RemoteEvent = Remotes:WaitForChild("Restock")
local GetStockFunction: RemoteFunction = Remotes:WaitForChild("GetStock")
local PurchaseSoldierFunction: RemoteFunction = Remotes:WaitForChild("PurchaseSoldier")

-- // Functions
local function RNGStock(Rarity)
    if math.random() <= Rarity then
        return math.random(1, 10)
    else
        return 0
    end
end

local function Restock()
    local Stocks = {}
    for _, Type in ipairs(SETTINGS.SHOP_ORDER) do
        Stocks[Type] = RNGStock(SETTINGS.SOLDIER_DATA[Type]["Rarity"])
    end

    RecentPurchases = {}

    return Stocks
end

local function CreateSoldier(Type: string)
    local SoldierID = HttpService:GenerateGUID()
    local SoldierData = {["Model"] = Type, ["Type"] = Type}

    return SoldierID, SoldierData
end

local function InjectSoldier(Player: Player, Type: string)
    local PlayerData = Data.Get(Player)

    local SoldierID = HttpService:GenerateGUID()
    local SoldierData = {["Model"] = Type, ["Type"] = Type}

    PlayerData["Inventory"]["SoldierInventory"][SoldierID] = SoldierData
    Data.Set(Player, PlayerData)

    PlayerPlotManagers[Player.Name]:SetSoldier("Slot" .. #PlayerData["Inventory"]["ActiveSoldiers"] + 1, SoldierID)
end

local function InjectTarget(Player: Player, TargetType: string)
    local PlayerData = Data.Get(Player)

    if not PlayerData["Inventory"]["TargetInventory"][TargetType] then
        PlayerData["Inventory"]["TargetInventory"][TargetType] = true
    end

    if PlayerData["Inventory"]["ActiveTarget"] ~= TargetType then
        PlayerPlotManagers[Player.Name]:SetTarget(TargetType)
    end
end

local function PurchaseSoldier(Player: Player, Type: string)
    -- 1) Check if the soldier is in stock for this player
    if CurrentStock[Type] <= 0 then return "Stock" end

    if not RecentPurchases[Player.Name] then
        RecentPurchases[Player.Name] = {}
    elseif RecentPurchases[Player.Name][Type] and CurrentStock[Type] - RecentPurchases[Player.Name][Type] <= 0 then
        return "Stock"
    end

    -- 2) Check if player has sufficient funds
    local PlayerData = Data.Get(Player)
    if PlayerData["leaderstats"]["Credits"] <= SETTINGS["SOLDIER_DATA"][Type]["Price"] then
        return "Insufficient"
    end

    -- 3) Subtract player funds & stock
    PlayerData["leaderstats"]["Credits"] -= SETTINGS["SOLDIER_DATA"][Type]["Price"]

    if not RecentPurchases[Player.Name][Type] then
        RecentPurchases[Player.Name][Type] = 1
    else
        RecentPurchases[Player.Name][Type] += 1
    end

    -- 4) Add soldier to player's inventory
    local SoldierID, SoldierData = CreateSoldier(Type)
    PlayerData["Inventory"]["SoldierInventory"][SoldierID] = SoldierData
    Data.Set(Player, PlayerData)

    return "Purchased", PlayerData
end

local function InitializeLeaderstats(Player: Player, PlayerData: table)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = Player

    for StatName, Value in pairs(PlayerData["leaderstats"]) do
        local Stat = Instance.new(string.upper(string.sub(type(Value), 1, 1)) .. string.sub(type(Value), 2) .. "Value")
        Stat.Name = StatName
        Stat.Value = Value
        Stat.Parent = leaderstats
    end
end

local function AssignPlotAnchor()
    local AssignedAnchor
    for _, Anchor in ipairs(Anchors:GetChildren()) do
        if not table.find(OccupiedAnchors, Anchor) then
            AssignedAnchor = Anchor
            table.insert(OccupiedAnchors, AssignedAnchor)

            return AssignedAnchor
        end
    end
end

local function OnPlayerAdded(Player: Player)
    -- 1) Load player's data
    local PlayerData, NewPlayer = Data.Initialize(Player)
    print(Player.Name .. " has joined. Their data:")
    print(PlayerData)
    -- 1a) Tutorial for new players
    if NewPlayer then
        -- For now, skip lol
        print(Player.Name .. " is a new player. Skipping tutorial.")
    end
    -- 1b) Init player in the rewardloop
    RewardLoop.SetupPlayer(Player, PlayerData)

    -- 2) Create player's plot
    local PlayerPlot = Plot.new(Player, PlayerData, AssignPlotAnchor())
    PlayerPlotManagers[Player.Name] = PlayerPlot

    -- 3) Initialize player's leaderstats
    InitializeLeaderstats(Player, PlayerData)

    -- 4) Teleport player's character to their plot
    local Character = Player.Character or Player.CharacterAdded:Wait()
    Character:SetPrimaryPartCFrame(PlayerPlot.Plot.Spawn.CFrame + Vector3.new(0, 3, 0))

    -- 5) TODO Present player's offline earnings
end

local function OnPlayerRemoving(Player: Player)
    -- 1) Remove player's data (save & write logoff details too)
    Data.Remove(Player)

    -- 2) Cleanup player's plot (& set vacant)
    local PlayerPlot = PlayerPlotManagers[Player.Name]
    table.remove(OccupiedAnchors, table.find(OccupiedAnchors, PlayerPlot.Anchor))
    PlayerPlot:Cleanup()
    PlayerPlotManagers[Player.Name] = nil
end

-- // Events & Calling
RewardLoop.Init()
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

task.spawn(function()
    while true do
        CurrentStock = Restock()
        TimeOfStock = os.time()

        RestockEvent:FireAllClients(CurrentStock, TimeOfStock)

        task.wait(180)
    end
end)

GetStockFunction.OnServerInvoke = function()
    return CurrentStock, TimeOfStock
end

PurchaseSoldierFunction.OnServerInvoke = function(Player: Player, Type: string)
    local Arg1, Arg2 = PurchaseSoldier(Player, Type)

    return Arg1, Arg2
end