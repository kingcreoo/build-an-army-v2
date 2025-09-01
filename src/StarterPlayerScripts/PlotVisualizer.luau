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

local function EquipWeapon(SoldierModel: Model, WeaponType: string)
    -- 1) Clone and parent weapon
    local Weapon = ReplicatedStorage:WaitForChild("Types"):WaitForChild("Weapons"):WaitForChild(WeaponType):Clone()
    Weapon.Parent = SoldierModel
    Weapon.Name = "Weapon"

    -- 2) Create Motor6D joint to attach weapon to hand
    local Handle = Weapon:WaitForChild("Handle")
    local Joint = Instance.new("Motor6D")
    Joint.Parent = Handle
    Joint.Part0 = SoldierModel:WaitForChild("Right Arm")
    Joint.Part1 = Handle

      -- 3) Set weapon offsets from SETTINGS
    Joint.C0 = SETTINGS["WEAPON_DATA"][WeaponType]["C0"]
    Joint.C1 = SETTINGS["WEAPON_DATA"][WeaponType]["C1"]

    -- 4) Play idle animation
    local Animator = SoldierModel:WaitForChild("AnimationController"):WaitForChild("Animator")
    local IdleAnimation = SoldierModel:WaitForChild("Animations"):WaitForChild(WeaponType .. "Idle")
    local Track = Animator:LoadAnimation(IdleAnimation)
    Track:Play()
end
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
    SoldierModel:SetPrimaryPartCFrame(Plot:WaitForChild("SoldierSlots"):WaitForChild(SlotNumber).CFrame * CFrame.Angles(0, math.rad(-90), 0) + Vector3.new(0,2.5,0))
    SoldierModel.Parent = Plot:WaitForChild("Soldiers")
    EquipWeapon(SoldierModel, "M4")
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
        TargetModel:SetPrimaryPartCFrame(Plot:WaitForChild("TargetSlots"):WaitForChild(SlotName).CFrame * CFrame.Angles(0, math.rad(90), 0) + Vector3.new(0, 2.5, 0))
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