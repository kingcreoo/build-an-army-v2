-- // Plot Visualizer, initialized by KingCreoo on 8-28-2025
-- // Manages animations of soldiers on a player's plot

-- // Define
local PlotVisualizer = {}

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- // Modules
local SETTINGS = require(ReplicatedStorage:WaitForChild("Settings"))
local EntityHandlerModule = require(script.Parent.EntityHandler)

-- // Variables
local Lanes = {[Players.LocalPlayer.Name] = {}}
local Soldiers = {[Players.LocalPlayer.Name] = {}}
local Targets = {[Players.LocalPlayer.Name] = {}}
local TargetTypes = {}

local SoldierTimers = {}

local SoldierModels = ReplicatedStorage:WaitForChild("Types"):WaitForChild("Soldiers")
local TargetModels = ReplicatedStorage:WaitForChild("Types"):WaitForChild("Targets")

local EntityHandler = EntityHandlerModule.new({"StandardBullet", "StandardExplosion"})

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

local function AnimateBullet(PlayerName, SoldierID, TargetSlot)
    -- 1) Get soldier and target models
    local Plot = Workspace:WaitForChild("Plots"):WaitForChild(PlayerName)
    if not Plot then
        return 0
    end

    local SoldierModel = Plot.Soldiers[SoldierID]
    local TargetModel = Plot.Targets:FindFirstChild("Target" .. string.sub(TargetSlot, 5))

    if not SoldierModel or not TargetModel then
        return 0
    end

    -- 2) Create bullet from pool
    local Bullet = EntityHandler:Create("StandardBullet")

    -- 3) Position bullet at weapon fire point
    local FirePoint = SoldierModel.Weapon.Fire
    Bullet.CFrame = FirePoint.CFrame * CFrame.Angles(0, math.rad(90), 0)
    Bullet.Parent = Workspace.Bullets

    -- 4) Calculate tween duration (distance / speed)
    local Distance = (TargetModel.PrimaryPart.Position - FirePoint.Position).Magnitude
    local BulletSpeed = 50  -- Fixed speed
    local Duration = Distance / BulletSpeed

    -- 5) Calculate straight trajectory with random spread
    local TargetPos = TargetModel.PrimaryPart.Position
    local StraightTargetPos = Vector3.new(TargetPos.X, FirePoint.Position.Y, TargetPos.Z)

    -- Add random spread
    local Spread = 2  -- studs of random variation
    local RandomX = (math.random() - 0.5) * Spread
    local RandomZ = (math.random() - 0.5) * Spread
    local FinalTargetPos = StraightTargetPos + Vector3.new(RandomX, 0, RandomZ)

    -- 6) Tween to target
    local Tween = TweenService:Create(
        Bullet,
        TweenInfo.new(Duration, Enum.EasingStyle.Linear),
        {Position = FinalTargetPos}
    )

    Tween:Play()

    -- 7) Explode & cleanup on completion
    Tween.Completed:Connect(function()
        -- Recycle bullet
        EntityHandler:Recycle(Bullet)

        -- Create explosion effect
        local Explosion = EntityHandler:Create("StandardExplosion")
        local Direction = (FinalTargetPos - FirePoint.Position).Unit
        Explosion.CFrame = CFrame.new(FinalTargetPos - Direction * .75)
        Explosion.Parent = Workspace.Explosions  -- Need this folder

        -- Configure and trigger explosion particles
        local ParticleEmitter = Explosion:WaitForChild("ParticleEmitter")
        ParticleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 70, 70))
        ParticleEmitter:Emit(8)

        -- Cleanup explosion after 1 second
        task.delay(1, function()
            EntityHandler:Recycle(Explosion)
        end)
    end)

    return Duration
end

local function DestroyTarget(InfoTable: table)
    local PlayerName = InfoTable.PlayerName
    local SlotName = InfoTable.SoldierData.Slot

    -- 1) Check if target already dead (prevent double-processing)
    if Targets[PlayerName][SlotName].State ~= "Alive" then
        return
    end

    -- 2) Mark target as dead
    Targets[PlayerName][SlotName].State = "Dead"

    -- 3) Hide target model
    local Plot = Workspace:WaitForChild("Plots"):WaitForChild(PlayerName)
    local TargetSlot = string.sub(SlotName, 5)  -- Extract "1" from "Slot1"
    local TargetModel = Plot.Targets:FindFirstChild("Target" .. TargetSlot)
    local PartsToRegenerate = {}
    if TargetModel then
        for _, Inst in pairs(TargetModel:GetChildren()) do
            if Inst.ClassName == "Part" and string.sub(Inst.Name, 1, 3) ~= "NHR" then
                Inst.Transparency = 1
                table.insert(PartsToRegenerate, Inst)
            elseif Inst:IsA("Model") then
                for _, iInst in pairs(Inst:GetChildren()) do
                    iInst.Transparency = 1
                    table.insert(PartsToRegenerate, iInst)
                end
            end
        end
    end

    -- 4) Schedule respawn
    local RespawnTime = Targets[PlayerName][SlotName]["RespawnTime"]
    task.delay(RespawnTime, function()
        -- Reset health and state
        local CurrentTargetType = TargetTypes[PlayerName]
        Targets[PlayerName][SlotName].State = "Alive"
        Targets[PlayerName][SlotName].Health = SETTINGS["TARGET_DATA"][CurrentTargetType]["TotalHealth"]
    end)

    -- 5) Animate respawn
    task.delay(.3, function()
        for _, Part in pairs(PartsToRegenerate) do
            local RegenerationTween = TweenService:Create(Part, TweenInfo.new(RespawnTime - .3), {["Transparency"] = 0})
            RegenerationTween:Play()
        end
    end)
end

local function AnimateSoldiers(SoldiersToAnimate: table)
    for _, InfoTable in pairs(SoldiersToAnimate) do
        -- 1) Animate soldier
        -- TODO soldier fire animations

        -- 2) Create, Calculate, and Animate bullet
        local TimeToHit = AnimateBullet(InfoTable.PlayerName, InfoTable.SoldierID, InfoTable.SoldierData.Slot)

        -- 3) If death, then animate & respawn target
        -- TODO target death animations
        local Damage = SETTINGS["SOLDIER_DATA"][InfoTable.SoldierData.Type]["Damage"]
        local CurrentHealth = Targets[InfoTable.PlayerName][InfoTable.SoldierData.Slot]["Health"]

        Targets[InfoTable.PlayerName][InfoTable.SoldierData.Slot].Health = CurrentHealth - Damage

        if CurrentHealth - Damage <= 0 and Targets[InfoTable.PlayerName][InfoTable.SoldierData.Slot].State == "Alive" then
            task.delay(TimeToHit, function()
                DestroyTarget(InfoTable)
            end)
        end

    end
end

RunService.Heartbeat:Connect(function()
    -- Early exit if no soldiers exist
    local HasSoldiers = false
    for _, PlayerSoldiers in pairs(Soldiers) do
        if next(PlayerSoldiers) then
            HasSoldiers = true
            break
        end
    end
    if not HasSoldiers then return end

    local CurrentTime = tick()
    local ReadyToFire = {}

    for PlayerName, PlayerSoldiers in pairs(Soldiers) do
        for SoldierID, SoldierData in pairs(PlayerSoldiers) do
            -- 0) Preliminary checking
            if not Workspace.Plots[PlayerName].Soldiers:FindFirstChild(SoldierID) then
                SoldierTimers[SoldierID] = nil
                continue
            end

            -- 1) Get soldier's base stats
            local BaseFireRate = SETTINGS["SOLDIER_DATA"][SoldierData.Type]["FireRate"]

            -- 2) Get any boosts
            -- TODO get boosts
            local AbsoluteFireRate = BaseFireRate -- + BOOSTS

            -- 3) Check if this soldier has a timer entry, if not create one
            if not SoldierTimers[SoldierID] then
                SoldierTimers[SoldierID] = CurrentTime + AbsoluteFireRate
            end

            -- 4) Check if ready to fire
            if CurrentTime >= SoldierTimers[SoldierID] then
                -- 4a) If yes, then add the soldier to ReadyToFire and prep the next fire time
                  table.insert(ReadyToFire, {
                      SoldierID = SoldierID,
                      PlayerName = PlayerName,
                      SoldierData = SoldierData
                  })
                  SoldierTimers[SoldierID] = CurrentTime + AbsoluteFireRate
              end
        end
    end

    -- Batch animate if any ready
      if #ReadyToFire > 0 then
          task.spawn(AnimateSoldiers, ReadyToFire)
      end
end)

function PlotVisualizer.SetSoldier(Player: Player, SlotNumber: string, SoldierID: string, SoldierData: table)
    -- 1) Define variables
    local Plot = Workspace:WaitForChild("Plots"):WaitForChild(Player.Name)
    local SoldierModel = SoldierModels:WaitForChild(SoldierData["Model"]):Clone()

    -- 2) Remove existing soldier
    local ExistingSoldierID = Lanes[Player.Name][tonumber(string.sub(SlotNumber, 5))]
    if ExistingSoldierID then
        Soldiers[Player.Name][ExistingSoldierID] = nil
        SoldierTimers[ExistingSoldierID] = nil
        Plot:WaitForChild("Soldiers"):WaitForChild(ExistingSoldierID):Destroy()
    end
    -- TODO create clean animation

    -- 3) Set new soldier
    Lanes[Player.Name][tonumber(string.sub(SlotNumber, 5))] = SoldierID
    SoldierData["Slot"] = SlotNumber
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
    local ExistingTargetType = TargetTypes[Player.Name]
    if ExistingTargetType then
        for _, Target in pairs(Plot:WaitForChild("Targets"):GetChildren()) do
            Target:Destroy()
            -- TODO create clean animation
        end
    end

    -- 3) Set new targets
    TargetTypes[Player.Name] = TargetType
    for _, SlotName in pairs(UnlockedLanes) do
        local TargetModel = TargetModelType:Clone()
        TargetModel:SetPrimaryPartCFrame(Plot:WaitForChild("TargetSlots"):WaitForChild(SlotName).CFrame * CFrame.Angles(0, math.rad(90), 0) + Vector3.new(0, 2.5, 0))
        TargetModel.Name = "Target" .. string.sub(SlotName, 5)
        TargetModel.Parent = Plot:WaitForChild("Targets")

        Targets[Player.Name][SlotName] = {["Health"] = SETTINGS["TARGET_DATA"][TargetType]["TotalHealth"], ["RespawnTime"] = SETTINGS["TARGET_DATA"][TargetType]["TotalRespawnTime"], ["State"] = "Alive"}
    end
end

-- // Events
Players.PlayerAdded:Connect(function(Player: Player) 
    Lanes[Player.Name] = {}
    Soldiers[Player.Name] = {}
    Targets[Player.Name] = {}
end)

Players.PlayerRemoving:Connect(function(Player: Player)
    Lanes[Player.Name] = nil
    Soldiers[Player.Name] = nil
    TargetTypes[Player.Name] = nil
    Targets[Player.Name] = nil
end)

-- // Return
return PlotVisualizer