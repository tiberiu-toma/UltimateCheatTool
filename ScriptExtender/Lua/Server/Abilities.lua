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
    HLP.ManageCharacterBoost(payload, "abilities", "Ability", "abilityName", "Ability")
end

function ABIL.ClearAllBoosts(payload)
    HLP.ClearAllCharacterBoosts(payload, "abilities", "Ability")
end