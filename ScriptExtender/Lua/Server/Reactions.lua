REACT = {}
REACT.Max = 50

function REACT.GetAll(search, page, filters)
    search = search or ""
    page = page or 1
    local pageSize = REACT.Max

    local itemData = Ext.Stats.GetStats("InterruptData")
    local allMatchingReactions = {}

    for k, v in pairs(itemData) do
        local id = v
        v = Ext.Stats.Get(v)
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName")
        local description = Ext.Loca.GetTranslatedString(HLP.GetAttr(v, "Description"))
        local cost = HLP.GetAttr(v, "Cost") -- Add this line to retrieve the cost

        local modId = HLP.GetAttr(v, "ModId")
        local mod = Ext.Mod.GetMod(modId)
        local modName = mod and mod.Info and mod.Info.Name or "Unknown"

        local displayName = handle ~= nil and handle ~= "" and HLP.GetTranslatedString(handle, name) or name
        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName))

        if matchesSearch and displayName and displayName ~= "" then
            table.insert(allMatchingReactions, {
                id = id,
                name = name,
                icon = icon,
                displayName = displayName,
                description = description,
                modName = modName,
                cost = cost -- Add this line to include the cost
            })
        end
    end

    local filtered = FLTR.Apply(allMatchingReactions, filters)
    table.sort(filtered, function(a, b) return a.displayName < b.displayName end)
    return UTL.Paginate(filtered, page, pageSize)
end

function REACT.Manage(payload)
    local character = payload.character
    if not character then return end
    
    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character].reactions then mods[character].reactions = {} end

    if payload.remove then
        local reactionData = mods[character].reactions[payload.uuid]
        if reactionData and reactionData.boostString then
            Osi.RemoveBoosts(character, reactionData.boostString, 1, "", "")
        end
        mods[character].reactions[payload.uuid] = nil
    else
        local boostString = string.format("UnlockInterrupt(%s)", payload.uuid)
        Osi.AddBoosts(character, boostString, "", "")
        mods[character].reactions[payload.uuid] = {
            data = payload.data,
            boostString = boostString
        }
    end
    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Reaction" }, payload.ID)
end

function REACT.ClearAllBoosts(payload)
    HLP.ClearAllCharacterBoosts(payload, "reactions", "Reaction")
end

return REACT