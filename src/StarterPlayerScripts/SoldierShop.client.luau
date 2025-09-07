-- // SoldierInventory, initialized by KingCreoo on 9-7-2025
-- // Manages UI functions for the client's soldier inventory :)

-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- // Modules
local SETTINGS = require(ReplicatedStorage:WaitForChild("Settings"))

-- // Variables
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetStockFunction: RemoteFunction = Remotes:WaitForChild("GetStock")
local RestockEvent: RemoteEvent = Remotes:WaitForChild("Restock")

local CurrentStock
local TimeOfStock
local RecentPurchase = {}

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
local Timer: TextLabel = Status:WaitForChild("Timer")
local RefreshButton: TextButton = Status:WaitForChild("Refresh")
local TemplateFrame: Frame = StandardFrame:WaitForChild("ScrollingFrame"):WaitForChild("Template")

local Buttons = {CloseButton, RefreshButton}

local ButtonExpandBindable: BindableEvent = UI:WaitForChild("ButtonExpand")
local ButtonDeflateBindable: BindableEvent = UI:WaitForChild("ButtonDeflate")
local CloseFrameBindable: BindableEvent = UI:WaitForChild("CloseFrame")

local FrameActive = false

-- // Functions

local function UpdateTimer()
    while true do
        local TimeRemaining = 180 - (os.time() - TimeOfStock)
        if TimeRemaining < 0 then
            TimeRemaining = 0
        end

        local Minutes = math.floor(TimeRemaining / 60)
        local Seconds = TimeRemaining % 60

        Timer.Text = "Stock resets in " .. string.format("%d:%02d", Minutes, Seconds)

        task.wait(1)
    end
end

local function EnterUtilityMode(SoldierFrame: Frame, MainFrame: Frame, UtilityFrame: Frame, UtilityButton)
    local SoldierFrameTween = TweenService:Create(SoldierFrame, UtilityInfo, {Size = SoldierFrame:GetAttribute("UtilitySize")})
    SoldierFrameTween:Play()

    local MainFrameTween = TweenService:Create(MainFrame, UtilityInfo, {Size = MainFrame:GetAttribute("UtilitySize")})
    MainFrameTween:Play()

    local UtilityButtonTween = TweenService:Create(UtilityButton, UtilityInfo, {Size = UtilityButton:GetAttribute("UtilitySize")})
    UtilityButtonTween:Play()

    local UtilityFrameTween = TweenService:Create(UtilityFrame, UtilityInfo, {Position = UtilityFrame:GetAttribute("UtilityPosition")})
    UtilityFrameTween:Play()

    task.wait(.1)
end

local function ExitUtilityMode(SoldierFrame: Frame, MainFrame: Frame, UtilityFrame: Frame, UtilityButton)
    local SoldierFrameTween = TweenService:Create(SoldierFrame, UtilityInfo, {Size = SoldierFrame:GetAttribute("StandardSize")})
    SoldierFrameTween:Play()

    local MainFrameTween = TweenService:Create(MainFrame, UtilityInfo, {Size = MainFrame:GetAttribute("StandardSize")})
    MainFrameTween:Play()

    local UtilityButtonTween = TweenService:Create(UtilityButton, UtilityInfo, {Size = UtilityButton:GetAttribute("StandardSize")})
    UtilityButtonTween:Play()

    local UtilityFrameTween = TweenService:Create(UtilityFrame, UtilityInfo, {Position = UtilityFrame:GetAttribute("StandardPosition")})
    UtilityFrameTween:Play()

    task.wait(.1)
end

local function StockStandardShop()
    for _, SoldierFrame: Frame in pairs(StandardFrame:WaitForChild("ScrollingFrame"):GetChildren()) do
        if SoldierFrame.Name == "UIListLayout" then continue end

        local Stock: TextLabel = SoldierFrame:WaitForChild("MainFrame"):WaitForChild("Stock")
        local CreditsButton: TextButton = SoldierFrame:WaitForChild("UtilityFrame"):WaitForChild("Credits")

        local Type = string.gsub(SoldierFrame.Name, "^%d+", "")
        local StockedSoldiers = CurrentStock[Type] or 0

        if StockedSoldiers == 0 then
            Stock.Text = "0x Stock"
            Stock.TextColor3 = Color3.fromRGB(255, 0, 0)

            CreditsButton.TextLabel.Text = "NO STOCK"
            CreditsButton.TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            CreditsButton.TextLabel.UIStroke.Color = Color3.fromRGB(0, 0, 0)

            CreditsButton.BackgroundColor3 = Color3.fromRGB(98, 98, 98)
            CreditsButton.UIStroke.Color = Color3.fromRGB(61, 61, 61)
        else
            Stock.Text = StockedSoldiers .. "x Stock"
            Stock.TextColor3 = Color3.fromRGB(255, 255, 255)

            CreditsButton.TextLabel.Text = "$" .. SETTINGS.SOLDIER_DATA[Type]["Price"]
            CreditsButton.TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            CreditsButton.TextLabel.UIStroke.Color = CreditsButton.UIStroke:GetAttribute("InStockColor")

            CreditsButton.BackgroundColor3 = CreditsButton:GetAttribute("InStockColor")
            CreditsButton.UIStroke.Color = CreditsButton.UIStroke:GetAttribute("InStockColor")
        end
    end
end

local function InitializeStandardShop()
    local ServerCurrentStock, ServerTimeOfStock = GetStockFunction:InvokeServer()
    CurrentStock = ServerCurrentStock
    TimeOfStock = ServerTimeOfStock

    task.spawn(UpdateTimer)

    for Num, Type in pairs(SETTINGS.SHOP_ORDER) do
        local Data = SETTINGS.SOLDIER_DATA[Type]
        local SoldierFrame = TemplateFrame:Clone()
        SoldierFrame.Name = tostring(Num+1) .. Type

        local MainFrame = SoldierFrame:WaitForChild("MainFrame")
        MainFrame:WaitForChild("Label").Text = string.upper(Type)
        MainFrame:WaitForChild("Price").Text = "$" .. Data["Price"]

        local UtilityFrame = SoldierFrame:WaitForChild("UtilityFrame")
        local CreditsButton: TextButton = UtilityFrame:WaitForChild("Credits")
        local RobuxButton: TextButton = UtilityFrame:WaitForChild("Robux")
        local GiftButton: TextButton = UtilityFrame:WaitForChild("Gift")
        local UtilityButtons = {CreditsButton, RobuxButton, GiftButton}
        CreditsButton.TextLabel.Text = "$" .. Data["Price"]
        RobuxButton.TextLabel.Text = "R$" .. Data["RobuxPrice"]

        SoldierFrame.Parent = StandardFrame:WaitForChild("ScrollingFrame")

        local Debounce = false
        local Mode = 0
        local UtilityButton = SoldierFrame:WaitForChild("UtilityButton")
        UtilityButton.MouseButton1Click:Connect(function()
            if Debounce then return end
            Debounce = true

            if Mode == 0 then
                EnterUtilityMode(SoldierFrame, MainFrame, UtilityFrame, UtilityButton)
                Mode = 1
            elseif Mode == 1 then
                ExitUtilityMode(SoldierFrame, MainFrame, UtilityFrame, UtilityButton)
                Mode = 0
            end

            task.wait(.1)
            Debounce = false
        end)

        table.insert(Buttons, CreditsButton)
        table.insert(Buttons, RobuxButton)
        table.insert(Buttons, GiftButton)
    end

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

RestockEvent.OnClientEvent:Connect(function(NewStock, TimeOfNewStock)
    CurrentStock = NewStock
    TimeOfStock = TimeOfNewStock
    RecentPurchase = {}

    StockStandardShop()
end)

InitializeStandardShop()
StockStandardShop()

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