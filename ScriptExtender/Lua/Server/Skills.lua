SKL = {}

function SKL.Manage(payload)
    HLP.ManageCharacterBoost(payload, "skills", "Skill", "skillName", "Skill")
end

function SKL.ClearAllBoosts(payload)
    HLP.ClearAllCharacterBoosts(payload, "skills", "Skill")
end