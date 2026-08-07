GEN = {}

function GEN.AddGold(payload)
    local character = payload.ID
    local amount = payload.Amount
    if character and amount then
        Osi.AddGold(character, amount)
    end
end

function GEN.AddExperience(payload)
    local amount = payload.Amount
    if amount then
        Osi.AddExplorationExperience(GetHostCharacter(), amount)
    end
end

function GEN.AddTadpoles(payload)
    local character = payload.ID
    local amount = payload.Amount
    if character and amount then
        Osi.AddTadpole(character, amount)
    end
end

function GEN.AddInspiration(payload)
    local character = payload.ID
    local amount = payload.Amount
    if character and amount then
        Osi.GiveInspirationPoints(character, amount, "", "")
    end
end

function GEN.RestoreParty(payload)
    Osi.RestoreParty(GetHostCharacter())
end

function GEN.ResetCooldowns(payload)
    local character = payload.ID
    if character then
        Osi.ResetCooldowns(character)
    end
end

function GEN.StartRespec(payload)
    local character = payload.ID
    if character then
        Osi.StartRespec(character)
    end
end

function GEN.StartChangeAppearance(payload)
    local character = payload.ID
    if character then
        Osi.StartChangeAppearance(character)
    end
end