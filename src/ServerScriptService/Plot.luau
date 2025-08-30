-- // PlotManager, initialized by KingCreoo on 8-19-2025
-- // Manages the functions of a player's plot

-- // Define
local PlotManager = {}
PlotManager.__index = PlotManager

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- // Modules
local Data = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Data"))

-- // Variables
local PlotTemplate = ReplicatedStorage:WaitForChild("PlotTemplate")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local SetSoldierEvent: RemoteEvent = Remotes:WaitForChild("SetSoldier")
local SetTargetEvent: RemoteEvent = Remotes:WaitForChild("SetTarget")

-- // Module functions
function PlotManager.new(Player: Player, PlayerData: table, PlotAnchor: Part)
    local self = setmetatable({}, PlotManager)

    self.Player = Player
    self.Anchor = PlotAnchor

    self.RLActiveSoldiers = {}
    self.RLActiveTarget = nil

    self:Populate(PlayerData)
    self:Create(PlotAnchor)

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

    -- 5) Fire all clients to manage animating the soldier
    SetSoldierEvent:FireAllClients(self.Player, SlotNumber, SoldierID, SoldierData)
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