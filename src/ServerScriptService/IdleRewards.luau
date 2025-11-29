-- Idle Rewards, created by Creoo on 11-24-2025
-- Manages calculating and distributing idle rewards

-- // Define
local IdleRewards = {}

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- // Modules
local Settings = require(ReplicatedStorage:WaitForChild("Settings"))
local Data = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Data"))

-- // Variables
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local IdleRewardsEvent: RemoteEvent = Remotes:WaitForChild("IdleRewards")

local Rewards = {}

-- // Local Functions

local function CalculateRewards(PlayerData: table, TimeAway: number)
    local TotalPossibleRewards = 0

    -- Get player's active setup
    local ActiveSoldiers = PlayerData["Inventory"]["ActiveSoldiers"]
    local SoldierInventory = PlayerData["Inventory"]["SoldierInventory"]
    local ActiveTarget = PlayerData["Inventory"]["ActiveTarget"]

    -- Get target stats
    local TargetData = Settings["TARGET_DATA"][ActiveTarget]
    local TargetHealth = TargetData["TotalHealth"]
    local TargetRespawnTime = TargetData["TotalRespawnTime"]
    local TargetReward = TargetData["Reward"]

    -- Get distance
    local Distance = Settings["DISTANCES"]["Worlds"]["Default"]

    for _, SoldierID in pairs(ActiveSoldiers) do
        local SoldierData = SoldierInventory[SoldierID]

        if SoldierData then
            local SoldierStats = Settings["SOLDIER_DATA"][SoldierData["Type"]]

            -- Calculate how many shots to kill the target
            local ShotsToKill = math.ceil(TargetHealth / SoldierStats["Damage"])

            -- Time when the last bullet fires
            local LastShotTime = (ShotsToKill - 1) * SoldierStats["FireRate"]

            -- Calculate travel time for last bullet
            local TravelTime = Distance / SoldierStats["BulletSpeed"]

            -- Calculate total kill cycle time
            local CycleTime = LastShotTime + TravelTime + TargetRespawnTime

            -- Calculate rewards per second for this soldier, then multiply by time away
            local SoldierRPS = TargetReward / CycleTime
            local SoldierTotal = SoldierRPS * TimeAway

            -- Add total soldier rewards to the running total
            TotalPossibleRewards += SoldierTotal
        end
    end

    return math.floor(TotalPossibleRewards)
end

-- // Module Functions

-- Calculates if player is valid for rewards & assigns rewards to valid players
function IdleRewards.OnPlayerAdded(Player: Player, PlayerData: table)

end

function IdleRewards.ClaimRewards(Player: Player)

end

-- // Events

IdleRewardsEvent.OnServerEvent:Connect(IdleRewards.ClaimRewards)

-- // Return
return IdleRewards