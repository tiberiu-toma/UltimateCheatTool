EKP = {}
EKP.Max = 50

function EKP.GetTemplateData(v)
    if not v then return nil end

    local isItem = HLP.GetAttr(v, "TemplateType") == "item"
    if not isItem then return nil end

    local isEquipment = EKP.IsEquipable(v)
    if not isEquipment then return nil end

    local id = HLP.GetAttr(v, "Id")
    local icon = HLP.GetAttr(v, "Icon")
    local name = HLP.GetAttr(v, "Name")
    local handle = HLP.GetAttr(v, "DisplayName.Handle.Handle")
    local displayName = handle ~= nil and handle ~= "" and HLP.GetTranslatedString(handle, name) or name
    local rarity = nil
    local armorClass = nil
    local armorType = nil
    local slot = nil
    local defaultBoosts = nil
    local boosts = nil
    local boostsOnEquipMainHand = nil
    local boostsOnEquipOffHand = nil
    local passivesOnEquip = nil

    local stats = Ext.Stats.Get(v.Stats)

    if stats.ModifierList == "Armor" then
        rarity = HLP.GetAttr(stats, "Rarity", nil)
        armorClass = HLP.GetAttr(stats, "ArmorClass", nil)
        armorType = HLP.GetAttr(stats, "ArmorType", nil)
        slot = HLP.GetAttr(stats, "Slot", nil)
        defaultBoosts = HLP.GetAttr(stats, "DefaultBoosts", nil)
        boosts = HLP.GetAttr(stats, "Boosts", nil)
        passivesOnEquip = HLP.GetAttr(stats, "PassivesOnEquip", nil)
    end

    if stats.ModifierList == "Weapon" then
        rarity = HLP.GetAttr(stats, "Rarity", nil)
        slot = HLP.GetAttr(stats, "Slot", nil)
        defaultBoosts = HLP.GetAttr(stats, "DefaultBoosts", nil)
        boosts = HLP.GetAttr(stats, "Boosts", nil)
        boostsOnEquipMainHand = HLP.GetAttr(stats, "BoostsOnEquipMainHand", nil)
        boostsOnEquipOffHand = HLP.GetAttr(stats, "BoostsOnEquipOffHand", nil)
        passivesOnEquip = HLP.GetAttr(stats, "PassivesOnEquip", nil)
    end

    local modId = HLP.GetAttr(stats, "ModId")
    local mod = Ext.Mod.GetMod(modId)
    local modName = mod ~= nil and mod.Info ~= nil and mod.Info.Name ~= nil and mod.Info.Name or "Unknown"

    if not (displayName and displayName ~= "" and icon and icon ~= "") then
        return nil
    end

    return { id = id, name = name, icon = icon, displayName = displayName, modName = modName, rarity = rarity, armorClass = armorClass, armorType = armorType, slot = slot, defaultBoosts = defaultBoosts, boosts = boosts, boostsOnEquipMainHand = boostsOnEquipMainHand, boostsOnEquipOffHand = boostsOnEquipOffHand, passivesOnEquip = passivesOnEquip, modifierList = stats.ModifierList }
end

function EKP.GetAll(search, page, filters)
    search = search or ""
    page = page or 1
    local pageSize = EKP.Max

    local itemData = Ext.Template.GetAllRootTemplates()

    local allMatchingEquipment = {}

    for k,v in pairs(itemData) do 
        local data = EKP.GetTemplateData(v)
        if data then
            local displayName = data.displayName
            local name = data.name
            local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

            if matchesSearch then
                table.insert(allMatchingEquipment, data)
            end
        end
    end

    local filtered = FLTR.Apply(allMatchingEquipment, filters)
    table.sort(filtered, function(a, b) return a.displayName < b.displayName end)
    return UTL.Paginate(filtered, page, pageSize)
end

function EKP.GetAllEquippedItems()
    local allPartyItems = {}
    local partyMembers = HLP.GetAllChars()

    for _, charUUID in ipairs(partyMembers) do
        allPartyItems[charUUID] = EKP.GetEquippedItems(charUUID)
    end
    return allPartyItems
end

function EKP.GetEquippedItems(characterUUID)
    local equippedItems = {}
    local slots = {
        "Helmet", "Breast", "Gloves", "Boots",
        "Melee Main Weapon", "Melee Offhand Weapon", "Ranged Main Weapon", "Ranged Offhand Weapon",
        "Amulet", "Ring", "Ring2", "Underwear", "Cloak",
        "VanityBody", "VanityBoots", "MusicalInstrument", "Torch" --????
    }

    for _, slot in ipairs(slots) do
        local itemHandle = Osi.GetEquippedItem(characterUUID, slot)
        if itemHandle ~= 0 then
            local item = Ext.Entity.Get(itemHandle)
            if item and item.GameObjectVisual and item.GameObjectVisual.RootTemplateId then
                local template = Ext.Template.GetTemplate(item.GameObjectVisual.RootTemplateId)
                if template then
                    local itemData = EKP.GetTemplateData(template)
                    if itemData then
                        itemData.instanceUUID = item.Uuid.EntityUuid
                        table.insert(equippedItems, itemData)
                    end
                end
            end
        end
    end
    return equippedItems
end

function EKP.GetByUUIDs(uuids)
    local items = {}
    for _, instanceUUID in ipairs(uuids) do
        local item = Ext.Entity.Get(instanceUUID)
        if item and item.GameObjectVisual and item.GameObjectVisual.RootTemplateId then
            local template = Ext.Template.GetTemplate(item.GameObjectVisual.RootTemplateId)
            if template then
                local data = EKP.GetTemplateData(template)
                if data then
                    data.instanceUUID = instanceUUID -- Add the instance UUID to the data payload
                    items[instanceUUID] = data
                end
            end
        end
    end
    return items
end

function EKP.GetAllNonStoryItems()
    local itemData = Ext.Template.GetAllRootTemplates()
    local allNonStoryEquipment = {}

    for k,v in pairs(itemData) do
        if HLP.GetAttr(v, "TemplateType") == "item" and not HLP.GetAttr(v, "StoryItem") then
            local isEquipment = EKP.IsEquipable(v)
            if isEquipment then
                local id = HLP.GetAttr(v, "Id")
                if id then
                    table.insert(allNonStoryEquipment, id)
                end
            end
        end
    end

    return allNonStoryEquipment
end

function EKP.IsEquipable(template)
    local stats = Ext.Stats.Get(template.Stats)

    if stats == nil then
        return false
    end

    if stats.ModifierList == "Armor" or stats.ModifierList == "Weapon" then
        return true
    end
    return false
end

function EKP.Spawn(payload)
    local uuid = payload.uuid
    local amount = payload.amount or 1
    local character = payload.character

    if not character then return end

    for i=1,amount do
        Osi.TemplateAddTo(uuid, character, 1, 0)
    end
end

function EKP.SpawnForParty(payload)
    local uuid = payload.uuid
    local amount = payload.amount or 1
    local partyMembers = HLP.GetAllChars()
    if not partyMembers or #partyMembers == 0 then return end

    for _, charUUID in ipairs(partyMembers) do
        for i=1,amount do
            Osi.TemplateAddTo(uuid, charUUID, 1, 0)
        end
    end
end

function EKP.SpawnAll(payload)
    local allItems = EKP.GetAllNonStoryItems()
    local character = payload.ID
    if not character then return end

    for _,uuid in ipairs(allItems) do
        Osi.TemplateAddTo(uuid, character, 1, 0)
    end
end
