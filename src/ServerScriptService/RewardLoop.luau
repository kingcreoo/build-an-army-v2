-- // RewardLoop, initialized on 9-2-2025 by KingCreoo
-- // Manages rewarding the players for their soldiers kills

-- // Define
local RewardLoop = {}

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- // Modules
local SETTINGS = require(ReplicatedStorage:WaitForChild("Settings"))

-- // Variables
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local SetSoldierBindable: BindableEvent = Remotes:WaitForChild("SetSoldierBindable")
local SetTargetBindable: BindableEvent = Remotes:WaitForChild("SetTargetBindable")
local SyncTablesFunction: RemoteFunction = Remotes:WaitForChild("SyncTables")
local FireSoldierEvent: RemoteEvent = Remotes:WaitForChild("FireSoldier")

local SoldierModels = ReplicatedStorage:WaitForChild("Types"):WaitForChild("Soldiers")
local TargetModels = ReplicatedStorage:WaitForChild("Types"):WaitForChild("Targets")

local Soldiers = {}
local Targets = {}
local TargetTypes = {}
local Timers = {}
local PendingRewards = {}

-- // Local Functions

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

local function OnPlayerRemoving(Player)
    Soldiers[Player.Name] = nil
    Targets[Player.Name] = nil
    TargetTypes[Player.Name] = nil
    Timers[Player.Name] = nil
    task.delay(5, function()
        PendingRewards[Player.Name] = nil
    end)
end

local function CalculateTimeToHit(BulletSpeed: number, Tare: number)
    -- TODO calculate boosts, and also set distances for each world
    local Distance = SETTINGS["DISTANCES"]["Worlds"]["Default"] - Tare
    local Duration = Distance / BulletSpeed

    return Duration
end

local function AddReward(InfoTable: table)
    local PlayerName = InfoTable.PlayerName
    local Slot = InfoTable.SoldierData.Slot

    -- 0) Check that this target is still applied
    if TargetTypes[PlayerName] ~= Targets[PlayerName][Slot].Type then
        return
    end

    -- 1) Mark target as dead
    Targets[PlayerName][Slot].State = "Dead"

    -- 2) Calculate and add reward
    local TargetType = Targets[PlayerName][Slot].Type -- Need to store this
    local RewardAmount = SETTINGS["TARGET_DATA"][TargetType]["Reward"] -- Add to SETTINGS
    PendingRewards[PlayerName] = PendingRewards[PlayerName] + RewardAmount
    local Collect = Workspace.Plots[PlayerName].Collect
    Collect.GUI.Amount.Text = "$" .. PendingRewards[PlayerName]

    -- 3) Schedule respawn
    local RespawnTime = SETTINGS["TARGET_DATA"][TargetType]["TotalRespawnTime"]
    task.delay(RespawnTime, function()
        Targets[PlayerName][Slot].State = "Alive"
        Targets[PlayerName][Slot].Health = SETTINGS["TARGET_DATA"][TargetType]["TotalHealth"]
    end)
end

local function FireSoldiers(SoldiersToFire)
    for _, InfoTable in pairs(SoldiersToFire) do
        -- Fire local client
        task.spawn(function()
            InfoTable.FirePoint = Workspace.Plots:FindFirstChild(InfoTable.PlayerName).Info:FindFirstChild(InfoTable.SoldierData.Slot).CFrame
            FireSoldierEvent:FireClient(Players:FindFirstChild(InfoTable.PlayerName), InfoTable)
        end)

        -- 1) Get stats
        local Damage = SETTINGS["SOLDIER_DATA"][InfoTable.SoldierData.Type]["Damage"]
        local CurrentHealth = Targets[InfoTable.PlayerName][InfoTable.SoldierData.Slot]["Health"]

        -- 2) Set damage
        Targets[InfoTable.PlayerName][InfoTable.SoldierData.Slot].Health = CurrentHealth - Damage

        -- 3) If the target died, we give the rewards at the right time
        if CurrentHealth - Damage <= 0 and Targets[InfoTable.PlayerName][InfoTable.SoldierData.Slot].State == "Alive" then
        local BulletSpeed = SETTINGS["SOLDIER_DATA"][InfoTable.SoldierData.Type]["BulletSpeed"]
        local TimeToHit = CalculateTimeToHit(BulletSpeed, SETTINGS["DISTANCES"]["Tares"][TargetTypes[InfoTable.PlayerName]])
            task.delay(TimeToHit, function()
                AddReward(InfoTable)
            end)
        end
    end
end

-- // Module Functions

function RewardLoop.GetPendingRewards(PlayerName: string)
    return PendingRewards[PlayerName]
end

function RewardLoop.SetSoldier(PlayerName: string, Slot: string, SoldierID: string, SoldierData: table)
    -- 0) Define variables
    local Plot = Workspace.Plots:WaitForChild(PlayerName)
    local SoldierModel = SoldierModels:WaitForChild(SoldierData["Model"]):Clone()

    if not Soldiers[PlayerName] then
        Soldiers[PlayerName] = {}
        Targets[PlayerName] = {}
        TargetTypes[PlayerName] = ""
        PendingRewards[PlayerName] = 0
    end

    -- 1) Remove existing soldier in that slot
    for ExistingSoldierID, ExistingSoldierData in pairs(Soldiers[PlayerName]) do
        if ExistingSoldierData.Slot == Slot then
            Soldiers[PlayerName][ExistingSoldierID] = nil
            Timers[PlayerName][ExistingSoldierID] = nil
            Plot:WaitForChild("Soldiers"):WaitForChild(ExistingSoldierID):Destroy()
            break
        end
    end

    -- 2) Add new soldier
    SoldierData.Slot = Slot
    Soldiers[PlayerName][SoldierID] = SoldierData
    SoldierModel.Name = SoldierID
    SoldierModel:SetPrimaryPartCFrame(Plot:WaitForChild("SoldierSlots"):WaitForChild(Slot).CFrame * CFrame.Angles(0, math.rad(-90), 0) + Vector3.new(0,2.5,0))
    SoldierModel.Parent = Plot:WaitForChild("Soldiers")
    EquipWeapon(SoldierModel, "M4")
    SoldierModel:SetAttribute("FirePoint", SoldierModel:FindFirstChild("Weapon"):FindFirstChild("Fire").CFrame)
end

function RewardLoop.SetTarget(PlayerName: string, UnlockedLanes: table, TargetType: string)
    -- 0) Define variables
    local Plot = Workspace:WaitForChild("Plots"):WaitForChild(PlayerName)
    local TargetModelType = TargetModels:WaitForChild(TargetType)

    -- 1) Clear existing targets, and set new type
    Targets[PlayerName] = {}
    TargetTypes[PlayerName] = TargetType
    for _, Target in pairs(Plot:WaitForChild("Targets"):GetChildren()) do
        Target:Destroy()
        -- TODO create clean animation
    end

    -- 2) Create new targets for each unlocked lane
    for _, SlotName in pairs(UnlockedLanes) do
        Targets[PlayerName][SlotName] = {
            Health = SETTINGS["TARGET_DATA"][TargetType]["TotalHealth"],
            State = "Alive",
            Type = TargetType
        }
    end

    for _, SlotName in pairs(UnlockedLanes) do
        local TargetModel = TargetModelType:Clone()
        TargetModel:SetPrimaryPartCFrame(Plot:WaitForChild("TargetSlots"):WaitForChild(SlotName).CFrame * CFrame.Angles(0, math.rad(90), 0) + Vector3.new(0, 2.5, 0))
        TargetModel.Name = "Target" .. string.sub(SlotName, 5)
        TargetModel.Parent = Plot:WaitForChild("Targets")
    end
end

function RewardLoop.SetupPlayer(Player, PlayerData)
    Soldiers[Player.Name] = {}
    Targets[Player.Name] = {}
    TargetTypes[Player.Name] = ""
    Timers[Player.Name] = {}
    print(PlayerData)
    if PlayerData["PendingRewards"] then
        PendingRewards[Player.Name] = PlayerData["PendingRewards"]
    else
        PendingRewards[Player.Name] = 0
    end
end

function RewardLoop.SetupRewards(Player)
    local Collect = Workspace.Plots[Player.Name].Collect
    Collect.GUI.Amount.Text = "$" .. PendingRewards[Player.Name]
end

function RewardLoop.Init()
    RunService.Heartbeat:Connect(function()
        -- 1) Get time and set variables
        local CurrentTime = tick()
        local ReadyToFire = {}

        -- 2) Run loop for each player
        for PlayerName, PlayerSoldiers in pairs(Soldiers) do
            for SoldierID, SoldierData in pairs(PlayerSoldiers) do
                -- 0) Check if target is alive
                if not Targets[PlayerName][SoldierData.Slot] or Targets[PlayerName][SoldierData.Slot].State ~= "Alive" then
                    continue
                end

                -- 1) Get soldier's base stats
                local BaseFireRate = SETTINGS["SOLDIER_DATA"][SoldierData.Type]["FireRate"]

                -- 2) Get any boosts
                -- TODO get boosts
                local AbsoluteFireRate = BaseFireRate -- + BOOSTS

                -- 3) Check if this soldier has a timer entry, if not create one
                if not Timers[PlayerName][SoldierID] then
                    Timers[PlayerName][SoldierID] = CurrentTime + AbsoluteFireRate
                end

                -- 4) Check if ready to fire
                if CurrentTime >= Timers[PlayerName][SoldierID] then
                    -- 4a) If yes, then add the soldier to ReadyToFire and prep the next fire time
                    table.insert(ReadyToFire, {
                        SoldierID = SoldierID,
                        PlayerName = PlayerName,
                        SoldierData = SoldierData
                    })
                    Timers[PlayerName][SoldierID] = CurrentTime + AbsoluteFireRate
                end
            end
        end

        -- Batch animate if any ready
        if #ReadyToFire > 0 then
            task.spawn(FireSoldiers, ReadyToFire)
        end
    end)
end

function RewardLoop.ClaimRewards(Player)
    -- 1) Get amount
    local Amount = PendingRewards[Player.Name] or 0
    if Amount <= 0 then return end

    -- 2) Get & Set player data
    local Data = require(script.Parent.Data)
    local PlayerData = Data.Get(Player)

    PlayerData["leaderstats"]["Credits"] += Amount
    PlayerData["PendingRewards"] = 0
    PendingRewards[Player.Name] = 0

    Data.Set(Player, PlayerData)

    -- 3) Update GUI
    local Collect = Workspace.Plots[Player.Name].Collect
    Collect.GUI.Amount.Text = "$0"

    -- 4) TODO client event for effects
end

function RewardLoop.SyncTables()
    return Soldiers, Targets, Timers, PendingRewards
end

-- // Events
Players.PlayerRemoving:Connect(OnPlayerRemoving)
SetSoldierBindable.Event:Connect(function(PlayerName: string, Slot: string, SoldierID: string, SoldierData: table)
    RewardLoop.SetSoldier(PlayerName, Slot, SoldierID, SoldierData)
end)
SetTargetBindable.Event:Connect(function(PlayerName: string, UnlockedLanes: table, TargetType: string)
    RewardLoop.SetTarget(PlayerName, UnlockedLanes, TargetType)
end)
SyncTablesFunction.OnServerInvoke = function()
    return RewardLoop.SyncTables()
end

-- // Return
return RewardLoop