DMG = {}

--- Adds or removes a damage boost from all instances of an item.
function DMG.ManageOnItem(payload, remove)
    local itemInstanceUUID = payload.itemInstanceUUID
    if not itemInstanceUUID then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not mods[itemInstanceUUID] then mods[itemInstanceUUID] = {} end
    if not mods[itemInstanceUUID].damage then mods[itemInstanceUUID].damage = {} end

    if remove then
        local uniqueKey = payload.uniqueKey
        if not uniqueKey then return end
        local boostData = mods[itemInstanceUUID].damage[uniqueKey]
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(itemInstanceUUID, boostData.boostString, 1, "", "")
            mods[itemInstanceUUID].damage[uniqueKey] = nil
        end
    else
        local boostString = payload.boostString
        if not boostString then return end
        Osi.AddBoosts(itemInstanceUUID, boostString, "", "")

        local uniqueKey = boostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        mods[itemInstanceUUID].damage[uniqueKey] = {
            boostString = boostString,
            display = payload.display
        }
        -- Store template UUID for re-application logic
        mods[itemInstanceUUID].templateUUID = payload.templateUUID
    end

    -- Cleanup logic
    if HLP.Count(mods[itemInstanceUUID].damage) == 0 then
        mods[itemInstanceUUID].damage = nil
    end
    if HLP.Count(mods[itemInstanceUUID]) == 0 then
        mods[itemInstanceUUID] = nil
    end

    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Damage" }, payload.ID)
end

return DMG