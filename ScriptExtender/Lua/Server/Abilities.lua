ABIL = {}

function ABIL.Fetch(payload)
    local charUUID = payload.character
    if not charUUID then return end

    local abilities = {"Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma"}
    local abilityScores = {}

    for _, ability in ipairs(abilities) do
        abilityScores[ability] = Osi.GetAbility(charUUID, ability)
    end

    HLP.ToClient(
        SMS.SendAbilities,
        {
            character = charUUID,
            scores = abilityScores
        },
        payload.ID
    )
end

function ABIL.Manage(payload)
    local character = payload.character
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character].abilities then mods[character].abilities = {} end

    if payload.remove then
        local boostData = mods[character].abilities[payload.uuid]
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(character, boostData.boostString, 1, "", "")
            mods[character].abilities[payload.uuid] = nil
            Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
        end
    else
        local abilityName = payload.abilityName
        local amount = payload.amount
        if not abilityName or not amount then return end

        local boostString = string.format("Ability(%s,%d)", abilityName, amount)
        Osi.AddBoosts(character, boostString, "", "")

        local uniqueKey = boostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        mods[character].abilities[uniqueKey] = { abilityName = abilityName, amount = amount, boostString = boostString }
        Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    end
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Ability" }, payload.ID)
end

function ABIL.ClearAllBoosts(payload)
    local character = payload.character
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] or not mods[character].abilities then return end

    local abilityMods = mods[character].abilities
    for _, boostData in pairs(abilityMods) do
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(character, boostData.boostString, 1, "", "")
        end
    end

    mods[character].abilities = nil
    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Ability" }, payload.ID)
end