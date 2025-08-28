-- // Client, initialized by KingCreoo on 8-19-2025
-- // Manages basic client-side functions

-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Modules
local PlotVisualizer = require(script.PlotVisualizer)

-- // Variables
local LocalPlayer = Players.LocalPlayer

local PublicAnimations = true

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local SetSoldierEvent: RemoteEvent = Remotes:WaitForChild("SetSoldier")
local SetTargetEvent: RemoteEvent = Remotes:WaitForChild("SetTarget")

-- // Functions

local function OnSetSoldier(Player: Player, SlotNumber: string, SoldierID: string, SoldierData: table)
    -- 1) Check for public animations being disabled
    if Player ~= LocalPlayer and not PublicAnimations then return end

    -- 2) Set the soldier
    PlotVisualizer.SetSoldier(Player, SlotNumber, SoldierID, SoldierData)

    -- 3) Start soldier animation loop
end

local function OnSetTarget(Player: Player, UnlockedLanes: table, TargetType: string)
    -- 1) Check for public animations being disabled
    if Player ~= LocalPlayer and not PublicAnimations then return end

    -- 2) Set the targets
    PlotVisualizer.SetTarget(Player, UnlockedLanes, TargetType)
end

-- // Events
SetSoldierEvent.OnClientEvent:Connect(OnSetSoldier)
SetTargetEvent.OnClientEvent:Connect(OnSetTarget)