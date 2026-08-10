DMG = {}
local reapplyOnLoad = false

--- Finds all instances of an item template in the entire party's possession (equipped or in inventory).
---@param templateUUID string The root template UUID of the item to find.
---@return table A list of entity UUIDs for all found instances.
function DMG.FindItemInstancesByTemplate(templateUUID)
    local instances = {}
    local partyMembers = HLP.GetAllChars()
    if not partyMembers then return instances end

    for _, charUUID in ipairs(partyMembers) do
        -- Check equipped items
        local slots = { "Helmet", "Breast", "Gloves", "Boots", "Melee Main Weapon", "Melee Offhand Weapon", "Ranged Main Weapon", "Ranged Offhand Weapon", "Amulet", "Ring", "Ring2", "Underwear", "Cloak", "MusicalInstrument" }
        for _, slot in ipairs(slots) do
            local itemHandle = Osi.GetEquippedItem(charUUID, slot)
            if itemHandle ~= 0 then
                local item = Ext.Entity.Get(itemHandle)
                if item and item.GameObjectVisual and item.GameObjectVisual.RootTemplateId == templateUUID then
                    table.insert(instances, item.Uuid.EntityUuid)
                end
            end
        end
    end
    return instances
end

--- Reapplies all saved damage boosts to all item instances on session load.
function DMG.ReapplyAll()
    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not modifiedEquipment or HLP.Count(modifiedEquipment) == 0 then return end

    for itemTemplateUUID, modifications in pairs(modifiedEquipment) do
        if modifications.damage and HLP.Count(modifications.damage) > 0 then
            local itemInstances = DMG.FindItemInstancesByTemplate(itemTemplateUUID)
            if #itemInstances > 0 then
                for _, boostData in pairs(modifications.damage) do
                    if boostData and boostData.boostString then
                        for _, instanceUUID in ipairs(itemInstances) do
                            Osi.AddBoosts(instanceUUID, boostData.boostString, "", "")
                        end
                    end
                end
            end
        end
    end
end

--- Adds or removes a damage boost from all instances of an item.
function DMG.ManageOnItem(payload, remove)
    local itemTemplateUUID = payload.itemTemplateUUID
    if not itemTemplateUUID then return end

    local itemInstances = DMG.FindItemInstancesByTemplate(itemTemplateUUID)

    local mods = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not mods[itemTemplateUUID] then mods[itemTemplateUUID] = {} end
    if not mods[itemTemplateUUID].damage then mods[itemTemplateUUID].damage = {} end

    if remove then
        local uniqueKey = payload.uniqueKey
        if not uniqueKey then return end
        local boostData = mods[itemTemplateUUID].damage[uniqueKey]
        if boostData and boostData.boostString then
            if #itemInstances > 0 then
                for _, instanceUUID in ipairs(itemInstances) do
                    Osi.RemoveBoosts(instanceUUID, boostData.boostString, 1, "", "")
                end
            end
            mods[itemTemplateUUID].damage[uniqueKey] = nil
        end
    else
        local boostString = payload.boostString
        if not boostString then return end
        if #itemInstances > 0 then
            for _, instanceUUID in ipairs(itemInstances) do
                Osi.AddBoosts(instanceUUID, boostString, "", "")
            end
        end
        local uniqueKey = boostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        mods[itemTemplateUUID].damage[uniqueKey] = {
            boostString = boostString,
            display = payload.display
        }
    end

    -- Cleanup logic
    if HLP.Count(mods[itemTemplateUUID].damage) == 0 then
        mods[itemTemplateUUID].damage = nil
    end
    if HLP.Count(mods[itemTemplateUUID]) == 0 then
        mods[itemTemplateUUID] = nil
    end

    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Damage" }, payload.ID)
end

return DMG