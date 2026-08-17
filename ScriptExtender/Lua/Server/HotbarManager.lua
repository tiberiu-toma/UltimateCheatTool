---@class HotbarManager
--- Manages saving and restoring character hotbars to prevent them from being
--- reset when spells are programmatically re-applied (e.g., on game load).
HotbarManager = {}

-- A private cache to hold serialized hotbar data for characters.
-- Key: Character UUID, Value: Serialized hotbar table
local _HotbarCache = {}

--- Saves a character's current hotbar state to the cache.
---@param charUUID string
function HotbarManager.Save(charUUID)
    if not charUUID then return end
    local entity = Ext.Entity.Get(charUUID)

    if entity and entity.HotbarContainer and entity.HotbarContainer.Containers and entity.HotbarContainer.Containers.DefaultBarContainer then
        local hotbarData = Ext.Types.Serialize(entity.HotbarContainer.Containers.DefaultBarContainer)
        _HotbarCache[charUUID] = hotbarData
    end
end

--- Schedules a restoration of a character's saved hotbar state from the cache.
---@param charUUID string
function HotbarManager.Restore(charUUID)
    if not charUUID or not _HotbarCache[charUUID] then return end
    
    -- Use a tick-based delay to ensure the game has processed spell changes.
    local ticks = 0
    local e
    e = Ext.Events.Tick:Subscribe(function()
        ticks = ticks + 1
        -- A delay of 20 ticks is generally safe for ensuring the game state has updated.
        if ticks >= 20 then
            Ext.Events.Tick:Unsubscribe(e)

            local entity = Ext.Entity.Get(charUUID)
            if not entity then return end

            local entityUUID = entity.Uuid.EntityUuid
            local cachedHotbarData = _HotbarCache[entityUUID]

            if cachedHotbarData and entity.HotbarContainer and entity.HotbarContainer.Containers and entity.HotbarContainer.Containers.DefaultBarContainer then
                Ext.Types.Unserialize(entity.HotbarContainer.Containers.DefaultBarContainer, cachedHotbarData)
                entity:Replicate("HotbarContainer")

                -- Clean up the cached data to prevent it from being used again accidentally and to free memory.
                _HotbarCache[entityUUID] = nil
            end
        end
    end)
end

return HotbarManager