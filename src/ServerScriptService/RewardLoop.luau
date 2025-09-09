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
local ClearSoldierBindable: BindableEvent = Remotes:WaitForChild("ClearSoldierBindable")

local Soldiers = {}
local Targets = {}
local TargetTypes = {}
local Timers = {}
local PendingRewards = {}
local DueDeaths = {}

-- // Local Functions

local function OnPlayerRemoving(Player)
    Soldiers[Player.Name] = nil
    Targets[Player.Name] = nil
    TargetTypes[Player.Name] = nil
    Timers[Player.Name] = nil
    DueDeaths[Player.Name] = nil
    task.delay(5, function()
        PendingRewards[Player.Name] = nil
    end)
end

local function CalculateTimeToHit(Plot: Model, BulletSpeed: number)
    -- TODO calculate boosts, and also set distances for each world
    local Distance = (Plot.Info.Target1.Position - Plot.Info.Slot1.Position).Magnitude
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
        FireSoldierEvent:FireClient(Players:FindFirstChild(InfoTable.PlayerName), InfoTable)

        -- 1) Get stats
        local Damage = SETTINGS["SOLDIER_DATA"][InfoTable.SoldierData.Type]["Damage"]
        local CurrentHealth = Targets[InfoTable.PlayerName][InfoTable.SoldierData.Slot]["Health"]

        -- 2) Set damage
        Targets[InfoTable.PlayerName][InfoTable.SoldierData.Slot].Health = CurrentHealth - Damage

        -- 3) If the target died, we give the rewards at the right time
        if CurrentHealth - Damage <= 0 and Targets[InfoTable.PlayerName][InfoTable.SoldierData.Slot].State == "Alive" then
            DueDeaths[InfoTable.PlayerName][InfoTable.SoldierData.Slot] = true
            local BulletSpeed = SETTINGS["SOLDIER_DATA"][InfoTable.SoldierData.Type]["BulletSpeed"]
            local TimeToHit = CalculateTimeToHit(Workspace.Plots:FindFirstChild(InfoTable.PlayerName), BulletSpeed)
            task.delay(TimeToHit, function()
                AddReward(InfoTable)
                task.delay(SETTINGS["TARGET_DATA"][TargetTypes[InfoTable.PlayerName]]["TotalRespawnTime"], function()
                    DueDeaths[InfoTable.PlayerName][InfoTable.SoldierData.Slot] = false
                end)
            end)
        end
    end
end

-- // Module Functions

function RewardLoop.GetPendingRewards(PlayerName: string)
    return PendingRewards[PlayerName]
end

function RewardLoop.ClearSoldier(PlayerName: string, Slot: string)
    -- 0) Check if player exists in tables
    if not Soldiers[PlayerName] then return end

    -- 1) Find and remove soldier in specified slot
    local SoldierIDToRemove
    for ExistingSoldierID, ExistingSoldierData in pairs(Soldiers[PlayerName]) do
        if ExistingSoldierData.Slot == Slot then
            SoldierIDToRemove = ExistingSoldierID
            break
        end
    end

    if SoldierIDToRemove then
        Soldiers[PlayerName][SoldierIDToRemove] = nil
        Timers[PlayerName][SoldierIDToRemove] = nil
    end

    -- 2) Reindex remaining soldiers by moving higher slots down
    local RemovedSlotNumber = tonumber(string.sub(Slot, 5))
    for _, SoldierData in pairs(Soldiers[PlayerName]) do
        local CurrentSlotNumber = tonumber(string.sub(SoldierData.Slot, 5))
        if CurrentSlotNumber > RemovedSlotNumber then
            -- Move soldier down one slot
            SoldierData.Slot = "Slot" .. tostring(CurrentSlotNumber - 1)
        end
    end
end

function RewardLoop.SetSoldier(PlayerName: string, Slot: string, SoldierID: string, SoldierData: table)
    -- 0) If the player doesn't have tables yet for whatever reason, we set them
    if not Soldiers[PlayerName] then
        Soldiers[PlayerName] = {}
        Targets[PlayerName] = {}
        TargetTypes[PlayerName] = ""
        PendingRewards[PlayerName] = 0
        DueDeaths[PlayerName] = {}
    end

    -- 1) Remove existing soldier in that slot
    for ExistingSoldierID, ExistingSoldierData in pairs(Soldiers[PlayerName]) do
        if ExistingSoldierData.Slot == Slot then
            Soldiers[PlayerName][ExistingSoldierID] = nil
            Timers[PlayerName][ExistingSoldierID] = nil
            break
        end
    end

    -- 2) Add new soldier
    SoldierData.Slot = Slot
    task.delay(2, function()
      Soldiers[PlayerName][SoldierID] = SoldierData
    end)
end

function RewardLoop.SetTarget(PlayerName: string, UnlockedLanes: table, TargetType: string)
    -- 1) Clear existing targets, and set new type
    Targets[PlayerName] = {}
    TargetTypes[PlayerName] = TargetType

    -- 2) Create new targets for each unlocked lane
    for _, SlotName in pairs(UnlockedLanes) do
        Targets[PlayerName][SlotName] = {
            Health = SETTINGS["TARGET_DATA"][TargetType]["TotalHealth"],
            State = "Alive",
            Type = TargetType
        }
    end
end

function RewardLoop.SetupPlayer(Player, PlayerData)
    Soldiers[Player.Name] = {}
    Targets[Player.Name] = {}
    TargetTypes[Player.Name] = ""
    Timers[Player.Name] = {}
    DueDeaths[Player.Name] = {}
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

                -- Check if the target is due to die
                if DueDeaths[PlayerName][SoldierData.Slot] == true then
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
ClearSoldierBindable.Event:Connect(function(PlayerName: string, Slot: string)
    RewardLoop.ClearSoldier(PlayerName, Slot)
end)

-- // Return
return RewardLoop