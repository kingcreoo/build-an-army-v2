-- // UI, initialized by KingCreoo on 9-6-2025
-- // Manages UI functions for the client :)

-- // Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- // Modules

-- // Variables
local LocalPlayer = Players.LocalPlayer
local LocalGui = LocalPlayer:WaitForChild("PlayerGui")

local HUD: ScreenGui = LocalGui:WaitForChild("HUD")
local SoldiersButton: TextButton = HUD:WaitForChild("Soldiers")

local ExpansionTweenInfo = TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local DeflationTweenInfo = TweenInfo.new(.075, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- // Functions

local function ButtonExpand(Button, Amplification)
    local OriginSize: UDim2 = Button:GetAttribute("OriginSize")
    local ExpansionSize: UDim2 = UDim2.fromScale(OriginSize.X.Scale * Amplification, OriginSize.Y.Scale * Amplification)

    local ExpansionTween = TweenService:Create(Button, ExpansionTweenInfo, {Size = ExpansionSize})
    ExpansionTween:Play()
end

local function ButtonDeflate(Button)
    local OriginSize = Button:GetAttribute("OriginSize")

    local DeflationTween = TweenService:Create(Button, DeflationTweenInfo, {Size = OriginSize})
    DeflationTween:Play()
end

-- // Events
SoldiersButton.MouseEnter:Connect(function()
    ButtonExpand(SoldiersButton, 1.1)
end)
SoldiersButton.MouseLeave:Connect(function()
    ButtonDeflate(SoldiersButton)
end)

-- TODO Wait for loading screen to finish
HUD.Enabled = true