-- // Entity Handler, initialized by KingCreoo on 8-30-2025
-- // Manages pooled bullets and explosions for all player animations

-- // Define
local EntityHandler = {}
EntityHandler.__index = EntityHandler

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Variables
local Entities = ReplicatedStorage:WaitForChild("Types"):WaitForChild("Entities")

-- // Module functions

-- Creates new entity handler with pre-warmed pools
function EntityHandler.new(EntityTypes: table)
    local self = setmetatable({}, EntityHandler)

    self.Pool = {}
    self.Active = {}

    -- For each type of entity, create a pool
    for _, EntityType in pairs(EntityTypes) do
        self.Pool[EntityType] = {}
        self.Active[EntityType] = {}

        -- Pre-warm each pool with 200 entities
        local EntityTemplate = Entities:WaitForChild(EntityType)
        for _ = 1, 200 do
            local Entity = EntityTemplate:Clone()
            Entity.Parent = ReplicatedStorage
            table.insert(self.Pool[EntityType], Entity)
        end
    end

    return self
end

-- Returns one entity of the requested type
function EntityHandler:Create(Type: string)
    -- Get an entity from its pool type
    local Entity = table.remove(self.Pool[Type])

    -- Add entity to its active pool type
    table.insert(self.Active[Type], Entity)

    -- Return entity
    return Entity
end

-- Recycles an entity back to its pool
function EntityHandler:Recycle(Entity: Part)
    -- Park the entity in ReplicatedStorage
    Entity.Parent = ReplicatedStorage

    -- Remove entity from its active pool type
    for Index, Key in ipairs(self.Active[Entity.Name]) do
        if Key == Entity then
            table.remove(self.Active[Entity.Name], Index)
            break
        end
    end

    -- Re-insert the entity into its pool type
    table.insert(self.Pool[Entity.Name], Entity)
end

-- // Return
return EntityHandler