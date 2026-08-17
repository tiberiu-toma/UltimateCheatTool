RES = {}

--- Manages adding or removing a resistance boost for a character.
---@param payload table The payload from the client.
function RES.Manage(payload)
    local character = payload.character
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character].resistances then mods[character].resistances = {} end

    if payload.remove then
        local boostData = mods[character].resistances[payload.uuid]
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(character, boostData.boostString, 1, "", "")
            mods[character].resistances[payload.uuid] = nil
            Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
        end
    else
        local boostString = payload.boostString
        local displayName = payload.displayName
        if not boostString or not displayName then return end

        Osi.AddBoosts(character, boostString, "", "")

        local uniqueKey = boostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        mods[character].resistances[uniqueKey] = { displayName = displayName, boostString = boostString }
        Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    end
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Resistance" }, payload.ID)
end

--- Clears all resistance boosts for a character.
---@param payload table The payload from the client.
function RES.ClearAllBoosts(payload)
    HLP.ClearAllCharacterBoosts(payload, "resistances", "Resistance")
end

return RES