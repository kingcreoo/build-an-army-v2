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