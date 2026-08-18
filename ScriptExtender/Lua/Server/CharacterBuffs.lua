CBF = {}

--- Manages adding or removing a character buff boost.
---@param payload table The payload from the client.
function CBF.Manage(payload)
    local character = payload.character
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character].characterBuffs then mods[character].characterBuffs = {} end

    if payload.remove then
        local boostData = mods[character].characterBuffs[payload.uuid]
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(character, boostData.boostString, 1, "", "")
            mods[character].characterBuffs[payload.uuid] = nil
            Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
        end
    else
        local boostString = payload.boostString
        local displayName = payload.displayName
        if not boostString or not displayName then return end

        Osi.AddBoosts(character, boostString, "", "")

        local uniqueKey = boostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        mods[character].characterBuffs[uniqueKey] = { displayName = displayName, boostString = boostString }
        Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    end
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "CharacterBuffs" }, payload.ID)
end

--- Clears all character buff boosts for a character.
---@param payload table The payload from the client.
function CBF.ClearAllBoosts(payload)
    HLP.ClearAllCharacterBoosts(payload, "characterBuffs", "CharacterBuffs")
end

return CBF