-- // SoldierInventory, initialized by KingCreoo on 9-7-2025
-- // Manages UI functions for the client's soldier inventory :)

-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- // Modules
local SETTINGS = require(ReplicatedStorage:WaitForChild("Settings"))

-- // Variables
local UtilityInfo = TweenInfo.new(.065, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local LocalPlayer = Players.LocalPlayer
local UI = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("UI")

local LocalGui = LocalPlayer:WaitForChild("PlayerGui")
local FramesGui = LocalGui:WaitForChild("Frames")

local SoldierShopFrame: Frame = FramesGui:WaitForChild("SoldierShop")
local CloseButton: TextButton = SoldierShopFrame:WaitForChild("Close")

local StandardFrame: Frame = SoldierShopFrame:WaitForChild("Standard")
local PremiumFrame: Frame = SoldierShopFrame:WaitForChild("Premium")

local Status: Frame = StandardFrame:WaitForChild("Status")
local RefreshButton: TextButton = Status:WaitForChild("Refresh")
local TemplateFrame: Frame = StandardFrame:WaitForChild("ScrollingFrame"):WaitForChild("Template")

local Buttons = {CloseButton, RefreshButton}

local ButtonExpandBindable: BindableEvent = UI:WaitForChild("ButtonExpand")
local ButtonDeflateBindable: BindableEvent = UI:WaitForChild("ButtonDeflate")
local CloseFrameBindable: BindableEvent = UI:WaitForChild("CloseFrame")

local FrameActive = false

-- // Functions

local function InitializeStandardShop()
    for Num, Type in pairs(SETTINGS.SHOP_ORDER) do
        local Data = SETTINGS.SOLDIER_DATA[Type]
        local SoldierFrame = TemplateFrame:Clone()
        SoldierFrame.Name = tostring(Num+1) .. Type

        local MainFrame = SoldierFrame:WaitForChild("MainFrame")
        MainFrame:WaitForChild("Label").Text = string.upper(Type)
        MainFrame:WaitForChild("Price").Text = "$" .. Data["Price"]


        SoldierFrame.Parent = StandardFrame:WaitForChild("ScrollingFrame")

    TemplateFrame:Destroy()
end

-- // Events
CloseButton.MouseButton1Click:Connect(function()
    if FrameActive == false then return end
    CloseFrameBindable:Fire(SoldierShopFrame)
end)

SoldierShopFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    FrameActive = SoldierShopFrame.Visible
end)

InitializeStandardShop()
for _, Button in pairs(Buttons) do
    Button.MouseEnter:Connect(function()
        if FrameActive == false then return end
        ButtonExpandBindable:Fire(Button, 1.1)
    end)
    Button.MouseLeave:Connect(function()
        if FrameActive == false then return end
        ButtonDeflateBindable:Fire(Button)
    end)
end