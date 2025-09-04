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
    Data.Set(self.Player, PlayerData)

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