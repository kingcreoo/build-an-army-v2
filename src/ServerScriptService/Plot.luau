-- // PlotManager, initialized by KingCreoo on 8-19-2025
-- // Manages the functions of a player's plot

-- // Define
local PlotManager = {}
PlotManager.__index = PlotManager

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- // Modules
local Data = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Data"))
local RewardLoop = require(ServerScriptService:WaitForChild("Server"):WaitForChild("RewardLoop"))

-- // Variables
local PlotTemplate = ReplicatedStorage:WaitForChild("PlotTemplate")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local SetSoldierEvent: RemoteEvent = Remotes:WaitForChild("SetSoldier")
local SetTargetEvent: RemoteEvent = Remotes:WaitForChild("SetTarget")

local SetSoldierBindable: BindableEvent = Remotes:WaitForChild("SetSoldierBindable")
local SetTargetBindable: BindableEvent = Remotes:WaitForChild("SetTargetBindable")

local ClearSoldierEvent: RemoteEvent = Remotes:WaitForChild("ClearSoldier")
local ClearSoldierBindable: BindableEvent = Remotes:WaitForChild("ClearSoldierBindable")

-- // Local functions

local function IsSoldierActive(ActiveSoldiers, SoldierID)
    for Index, ID in pairs(ActiveSoldiers) do
        if ID == SoldierID then
            return Index
        end
    end
    return false
end

local function ReindexTable(Table)
    local Result = {}
    for _, Value in pairs(Table) do
        table.insert(Result, Value)
    end
    return Result
end

-- // Module functions
function PlotManager.new(Player: Player, PlayerData: table, PlotAnchor: Part)
    local self = setmetatable({}, PlotManager)

    self.Player = Player
    self.Anchor = PlotAnchor

    self.RLActiveSoldiers = {}
    self.RLActiveTarget = nil

    self:Populate(PlayerData)
    self:Create(PlotAnchor)
    RewardLoop.SetupRewards(self.Player)

    return self
end

function PlotManager:Deactivate(SoldierID: string)
    -- 1) Get player data
    local PlayerData = Data.Get(self.Player)

    -- 2) Gauruntee player owns this soldier
    if not PlayerData["Inventory"]["SoldierInventory"][SoldierID] then
        print('1')
        return false, PlayerData
    end

    -- 3) Gauruntee soldier is active
    local Index = IsSoldierActive(PlayerData["Inventory"]["ActiveSoldiers"], SoldierID)
    if not Index then
        print('2')
        return false, PlayerData
    end

    -- Deactivate soldier --

    -- 1) Deactivate solder in the player data
    PlayerData["Inventory"]["ActiveSoldiers"][Index] = nil

    -- 2) Shuffle active soldiers
    PlayerData["Inventory"]["ActiveSoldiers"] = ReindexTable(PlayerData["Inventory"]["ActiveSoldiers"])

    -- 3) Set Data
    Data.Set(self.Player, PlayerData, true)

    -- 4) Fire ClearSoldier() functions
    ClearSoldierEvent:FireAllClients(self.Player, "Slot" .. Index)
    ClearSoldierBindable:Fire(self.Player.Name, "Slot" .. Index)

    -- 5) Return to client
    return true, PlayerData
end

function PlotManager:Activate(SoldierID: string)
    -- 1) Get player data
    local PlayerData = Data.Get(self.Player)

    -- 2) Gauruntee player owns this soldier
    if not PlayerData["Inventory"]["SoldierInventory"][SoldierID] then
        return false, PlayerData
    end

    -- 3) Gauruntee soldier is inactive
    local Index = IsSoldierActive(PlayerData["Inventory"]["ActiveSoldiers"], SoldierID)
    if Index then
        return false, PlayerData
    end

    -- 4) Gauruntee there is room to activate this soldier
    local UnlockedLanes = {}
    local PlotUnlocks = PlayerData.Plot.Unlocks
    for i = 1, 7 do
        if PlotUnlocks["Slot" .. tostring(i)] then
            table.insert(UnlockedLanes, "Slot" .. tostring(i))
        end
    end

    if #PlayerData["Inventory"]["ActiveSoldiers"] >= #UnlockedLanes then
        return false, PlayerData
    end

    -- Activate soldier --

    -- 1) Fire own function
    self:SetSoldier("Slot" .. #PlayerData["Inventory"]["ActiveSoldiers"] + 1, SoldierID)

    -- 2) Return to client
    return true, PlayerData
end

function PlotManager:SetSoldier(SlotNumber: string, SoldierID: string)
    -- 1) Get PlayerData
    local PlayerData = Data.Get(self.Player)

    -- 2) Check that player unlocked this slot
    if PlayerData["Plot"]["Unlocks"][SlotNumber] == false then
        warn("Player does not own slot number! Aborting.")

        return
    end

    -- 3) Check that player actually owns this soldier
    local SoldierData = PlayerData["Inventory"]["SoldierInventory"][SoldierID]
    if not SoldierData then
        return
    end

    -- 4) Update data
    PlayerData["Inventory"]["ActiveSoldiers"][tonumber(string.sub(SlotNumber, 5))] = SoldierID
    self.RLActiveSoldiers[tonumber(string.sub(SlotNumber, 5))] = SoldierID
    Data.Set(self.Player, PlayerData, true)

    -- 5) Fire all clients to manage animating the soldier, and fire server
    SetSoldierEvent:FireAllClients(self.Player, SlotNumber, SoldierID, SoldierData)
    SetSoldierBindable:Fire(self.Player.Name, SlotNumber, SoldierID, SoldierData)
end

function PlotManager:SetTarget(TargetType: string)
    -- 1) Get PlayerData
    local PlayerData = Data.Get(self.Player)

    -- 2) Verify this player has unlocked this target
    if not PlayerData["Inventory"]["TargetInventory"][TargetType] then
        warn("Player does not own this target! Aborting...")

        return
    end

    -- 3) Update data
    PlayerData["Inventory"]["ActiveTarget"] = TargetType
    self.RLActiveTarget = TargetType
    Data.Set(self.Player, PlayerData)

    -- 4) Get unlocked lanes
    local UnlockedLanes = {}
    local PlotUnlocks = PlayerData.Plot.Unlocks
    for i = 1, 7 do
        if PlotUnlocks["Slot" .. tostring(i)] then
            table.insert(UnlockedLanes, "Slot" .. tostring(i))
        end
    end

    -- 5) Fire all clients to manage animating the target
    SetTargetEvent:FireAllClients(self.Player, UnlockedLanes, TargetType)
    SetTargetBindable:Fire(self.Player.Name, UnlockedLanes, TargetType)
end

function PlotManager:Populate(PlayerData: table)
    -- 1) Create the plot from a template
    self.Plot = PlotTemplate:Clone()

    -- 2) Set active soldiers
    local ActiveSoldiers = PlayerData["Inventory"]["ActiveSoldiers"]
    if #ActiveSoldiers > 0 then
        for SlotNumber, SoldierID in ipairs(ActiveSoldiers) do
            self:SetSoldier("Slot" .. SlotNumber, SoldierID)
        end
    end

    -- 3) Set the active target
    local ActiveTarget = PlayerData["Inventory"]["ActiveTarget"]
    if ActiveTarget ~= "" then
        self:SetTarget(PlayerData["Inventory"]["ActiveTarget"])
    end

    -- 5) Check for claiming
    local Debounce = false
    self.Plot.Collect.Touched:Connect(function(hit)
        local Humanoid = hit.Parent:FindFirstChild("Humanoid")
        if not Humanoid then return end

        local HitPlayer = Players:GetPlayerFromCharacter(hit.Parent)

        -- If the hit player is different than this plot's player, we skip
        if HitPlayer ~= self.Player then return end

        -- If there's debounce, we skip
        if Debounce then return end

        Debounce = true
        RewardLoop.ClaimRewards(self.Player)

        task.wait(1)  -- Cooldown
        Debounce = false
    end)
end

function PlotManager:Create(PlotAnchor: Part)
    -- 1) Send plot to physical space (at anchor)
    self.Plot:SetPrimaryPartCFrame(PlotAnchor.CFrame)
    self.Plot.Name = self.Player.Name
    self.Plot.Parent = workspace:WaitForChild("Plots")

    -- 2) TODO Clean spawn animation
end

function PlotManager:Cleanup()
    -- 1) Destroy physical plot
    self.Plot:Destroy()
end

-- // Return
return PlotManager