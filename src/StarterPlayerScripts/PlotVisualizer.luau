local Workspace = game:GetService("Workspace")
-- // Plot Visualizer, initialized by KingCreoo on 8-28-2025
-- // Manages animations of soldiers on a player's plot

-- // Define
local PlotVisualizer = {}

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- // Modules

-- // Variables
local Lanes = {[Players.LocalPlayer.Name] = {}}
local Soldiers = {[Players.LocalPlayer.Name] = {}}
local Targets = {}

local SoldierModels = ReplicatedStorage:WaitForChild("Types"):WaitForChild("Soldiers")
local TargetModels = ReplicatedStorage:WaitForChild("Types"):WaitForChild("Targets")

-- // Functions

function PlotVisualizer.SetSoldier(Player: Player, SlotNumber: string, SoldierID: string, SoldierData: table)
    -- 1) Define variables
    local Plot = Workspace:WaitForChild("Plots"):WaitForChild(Player.Name)
    local SoldierModel = SoldierModels:WaitForChild(SoldierData["Model"]):Clone()

    -- 2) Remove existing soldier
    local ExistingSoldierID = Lanes[Player.Name][tonumber(string.sub(SlotNumber, 5))]
    if ExistingSoldierID then
        Soldiers[Player.Name][ExistingSoldierID] = nil
        Plot:WaitForChild("Soldiers"):WaitForChild(ExistingSoldierID):Destroy()
    end
    -- TODO create clean animation

    -- 3) Set new soldier
    Lanes[Player.Name][tonumber(string.sub(SlotNumber, 5))] = SoldierID
    Soldiers[Player.Name][SoldierID] = SoldierData
    SoldierModel.Name = SoldierID
    SoldierModel:SetPrimaryPartCFrame(Plot:WaitForChild("SoldierSlots"):WaitForChild(SlotNumber).CFrame + Vector3.new(0,3,0))
    SoldierModel.Parent = Plot:WaitForChild("Soldiers")
end

function PlotVisualizer.SetTarget(Player: Player, UnlockedLanes: table, TargetType: string)
    -- 1) Define variables
    local Plot = Workspace:WaitForChild("Plots"):WaitForChild(Player.Name)
    local TargetModelType = TargetModels:WaitForChild(TargetType)

    -- 2) Remove existing targets
    local ExistingTargetType = Targets[Player.Name]
    if ExistingTargetType then
        for _, Target in pairs(Plot:WaitForChild("Targets"):GetChildren()) do
            Target:Destroy()
            -- TODO create clean animation
        end
    end

    -- 3) Set new targets
    Targets[Player.Name] = TargetType
    for _, SlotName in pairs(UnlockedLanes) do
        local TargetModel = TargetModelType:Clone()
        TargetModel:SetPrimaryPartCFrame(Plot:WaitForChild("TargetSlots"):WaitForChild(SlotName).CFrame + Vector3.new(0, 3, 0))
        TargetModel.Parent = Plot:WaitForChild("Targets")
    end
end

-- // Events
Players.PlayerAdded:Connect(function(Player: Player) 
    Lanes[Player.Name] = {}
    Soldiers[Player.Name] = {}
end)

Players.PlayerRemoving:Connect(function(Player: Player)
    Lanes[Player.Name] = nil
    Soldiers[Player.Name] = nil
    Targets[Player.Name] = nil
end)

-- // Return
return PlotVisualizer