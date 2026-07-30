EKP = {}
EKP.Max = 50

function tableToString(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    local str = "{ "
    for k, v in pairs(tbl) do
        str = str .. "[" .. tostring(k) .. "] = " .. tableToString(v) .. ", "
    end
    str = str:sub(1, -3) .. " }"
    return str
end   

function EKP.GetAll(search, page)
    search = search or ""
    page = page or 1
    local pageSize = EKP.Max

    local itemData = Ext.Template.GetAllRootTemplates()

    local allMatchingEquipment = {}

    for k,v in pairs(itemData) do 
        local isItem = HLP.GetAttr(v, "TemplateType") == "item"
        if not isItem then goto continue end

        local isEquipment = EKP.IsEquipable(v)
        if not isEquipment then goto continue end

        local id = HLP.GetAttr(v, "Id")
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName.Handle.Handle")
        local displayName = Ext.Loca.GetTranslatedString(handle, name)
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

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

        if matchesSearch and displayName and displayName ~= "" and icon and icon ~= "" then
            local isEquipment = EKP.IsEquipable(v)
            if isEquipment then
                table.insert(allMatchingEquipment, {
                    id = id,
                    name = name,
                    icon = icon,
                    displayName = displayName,
                    modName = modName,
                    rarity = rarity,
                    armorClass = armorClass,
                    armorType = armorType,
                    slot = slot,
                    defaultBoosts = defaultBoosts,
                    boosts = boosts,
                    boostsOnEquipMainHand = boostsOnEquipMainHand,
                    boostsOnEquipOffHand = boostsOnEquipOffHand,
                    passivesOnEquip = passivesOnEquip,
                })
            end
        end
        ::continue::
    end

    table.sort(allMatchingEquipment, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingEquipment, page, pageSize)
end

function EKP.GetAllNonStoryItems()
    local itemData = Ext.Template.GetAllRootTemplates()
    local allNonStoryEquipment = {}

    for k,v in pairs(itemData) do
        local isItem = HLP.GetAttr(v, "TemplateType") == "item"
        if not isItem then goto continue end

        if HLP.GetAttr(v, "StoryItem") then goto continue end

        local isEquipment = EKP.IsEquipable(v)
        if isEquipment then
            local id = HLP.GetAttr(v, "Id")
            if id then
                table.insert(allNonStoryEquipment, id)
            end
        end
        ::continue::
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
