SKL = {}

function SKL.Manage(payload)
    local character = payload.character
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character].skills then mods[character].skills = {} end

    if payload.remove then
        local boostData = mods[character].skills[payload.uuid]
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(character, boostData.boostString, 1, "", "")
            mods[character].skills[payload.uuid] = nil
            Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
        end
    else
        local skillName = payload.skillName
        local amount = payload.amount
        if not skillName or not amount then return end

        local boostString = string.format("Skill(%s,%d)", skillName, amount)
        Osi.AddBoosts(character, boostString, "", "")

        local uniqueKey = boostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        mods[character].skills[uniqueKey] = { skillName = skillName, amount = amount, boostString = boostString }
        Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    end
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Skill" }, payload.ID)
end

function SKL.ClearAllBoosts(payload)
    local character = payload.character
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] or not mods[character].skills then return end

    local skillMods = mods[character].skills
    for _, boostData in pairs(skillMods) do
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(character, boostData.boostString, 1, "", "")
        end
    end

    mods[character].skills = nil
    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Skill" }, payload.ID)
end