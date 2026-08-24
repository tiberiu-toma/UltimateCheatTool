SPLL = {}
SPLL.Max = 50

function SPLL.GetAll(search, page, filters)
    search = search or ""
    page = page or 1
    local pageSize = SPLL.Max

    local itemData = Ext.Stats.GetStats("SpellData")

    local allMatchingSpells = {}

    for k,v in pairs(itemData) do 
        local id = v
        v = Ext.Stats.Get(v)
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName")
        
        local spellType = HLP.GetAttr(v, "SpellType")
        local spellSchool = HLP.GetAttr(v, "SpellSchool")
        local useCosts = HLP.GetAttr(v, "UseCosts")
        local level = HLP.GetAttr(v, "Level")
        local cooldown = HLP.GetAttr(v, "Cooldown")

        local modId = HLP.GetAttr(v, "ModId")
        local mod = Ext.Mod.GetMod(modId)
        local modName = mod ~= nil and mod.Info ~= nil and mod.Info.Name ~= nil and mod.Info.Name or "Unknown"

        local displayName = handle ~= nil and handle ~= "" and HLP.GetTranslatedString(handle, name) or name

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

        if matchesSearch and displayName and displayName ~= "" and icon and icon ~= "unknown" then
            table.insert(allMatchingSpells, {
                id = id,
                name = name,
                icon = icon,
                displayName = displayName,
                spellType = spellType,
                spellSchool = spellSchool,
                useCosts = useCosts,
                level = level,
                cooldown = cooldown,
                modName = modName
            })
        end
    end

    local filtered = FLTR.Apply(allMatchingSpells, filters)
    table.sort(filtered, function(a, b) return a.displayName < b.displayName end)
    return UTL.Paginate(filtered, page, pageSize)
end

function SPLL._Manage(character, uuid, data, ability, unlearn)
    if not character then return end
    
    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character].spells then mods[character].spells = {} end

    if unlearn then
        local spellData = mods[character].spells[uuid]
        if spellData then
            local boostStringToRemove = spellData.boostString
            if not boostStringToRemove and spellData.spellName and spellData.learningStrategy and spellData.castingAbility then
                -- Fallback for data from older versions that didn't store the boostString directly
                boostStringToRemove = string.format("UnlockSpell(%s,%s,%s,,%s)", spellData.spellName, spellData.learningStrategy, "d136c5d9-0ff0-43da-acce-a74a07f8d6bf", spellData.castingAbility)
            end

            if boostStringToRemove then
                Osi.RemoveBoosts(character, boostStringToRemove, 1, "", "")
            end
            mods[character].spells[uuid] = nil
        end
    else
        local learningStrategy = "AddChildren"
        local boostString = string.format("UnlockSpell(%s,%s,%s,,%s)", uuid, learningStrategy, "d136c5d9-0ff0-43da-acce-a74a07f8d6bf", ability)
        Osi.AddBoosts(character, boostString, "", "")
        mods[character].spells[uuid] = {
            spellName = uuid,
            learningStrategy = learningStrategy,
            castingAbility = ability,
            data = data,
            boostString = boostString
        }
    end
    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
end

function SPLL.Manage(payload)
    SPLL._Manage(payload.character, payload.uuid, payload.data, payload.ability or "Wisdom", HLP.GetAttr(payload, "unlearn"))
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Spell" }, payload.ID)
end

function SPLL.ManageForParty(payload, unlearn)
    local uuid = payload.uuid
    local data = payload.data

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    if unlearn then
        for _, member in ipairs(partyMembers) do
            SPLL._Manage(member.uuid, uuid, data, nil, true)
        end
    else
        local ability = payload.ability or "Wisdom"
        for _, member in ipairs(partyMembers) do
            SPLL._Manage(member.uuid, uuid, data, ability, false)
        end
    end

    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Spell" }, payload.ID)
end