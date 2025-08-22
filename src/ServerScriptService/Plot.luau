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

-- // Module functions
function PlotManager.new(Player: Player, PlayerData: table, PlotAnchor: Part)
    local self = setmetatable({}, PlotManager)

    self.Player = Player
    self.Anchor = PlotAnchor

    self:Populate(PlayerData)
    self:Create(PlotAnchor)

    return self
end
function PlotManager:Create(PlotAnchor: Part)
    -- 1) Send plot to physical space (at anchor)
    self.Plot:SetPrimaryPartCFrame(PlotAnchor.CFrame)
    self.Plot.Parent = workspace:WaitForChild("Plots")

    -- 2) TODO Clean spawn animation
end

function PlotManager:Cleanup()
    -- 1) Destroy physical plot
    self.Plot:Destroy()
end

-- // Return
return PlotManager