CONS = {}
CONS.Max = 50

function CONS.GetAll(search, page, filters)
    search = search or ""
    page = page or 1
    local pageSize = CONS.Max

    local itemData = Ext.Template.GetAllRootTemplates()

    local allMatchingConsumables = {}

    for k,v in pairs(itemData) do 
        if HLP.GetAttr(v, "TemplateType") == "item" then
            local id = HLP.GetAttr(v, "Id")
            local icon = HLP.GetAttr(v, "Icon")
            local name = HLP.GetAttr(v, "Name")
            local handle = HLP.GetAttr(v, "DisplayName.Handle.Handle")
            local displayName = HLP.GetTranslatedString(handle, name)

            local stats = Ext.Stats.Get(v.Stats)
            local modId = stats and HLP.GetAttr(stats, "ModId") or nil
            local mod = modId and Ext.Mod.GetMod(modId) or nil
            local modName = mod and mod.Info and mod.Info.Name or "Unknown"

            local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

            if matchesSearch and displayName and displayName ~= "" and icon and icon ~= "" then
                local isConsumable = CONS.IsConsumable(v)
                if isConsumable then
                    table.insert(allMatchingConsumables, {
                        id = id,
                        name = name,
                        icon = icon,
                        displayName = displayName,
                        modName = modName
                    })
                end
            end
        end
    end

    local filtered = FLTR.Apply(allMatchingConsumables, filters)
    table.sort(filtered, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(filtered, page, pageSize)
end

function CONS.IsConsumable(template)
    -- Ensure the template is an item and has a Stats property before proceeding.
    if not template or template.TemplateType ~= "item" or not template.Stats then
        return false
    end

    local stats = Ext.Stats.Get(template.Stats)

    if stats == nil or stats.ModifierList ~= "Object" then
        return false
    end

    if stats.InventoryTab ~= nil and stats.InventoryTab == "Consumable" then
        return true
    end

    if stats.ItemUseType ~= nil and stats.ItemUseType == "Arrow" then
        return true
    end

    if stats.ItemUseType ~= nil and stats.ItemUseType == "Potion" then
        return true
    end

    if stats.DefaultBoosts ~= nil and stats.DefaultBoosts == "Tag(CAMPSUPPLIES)" then
        return true
    end

    if stats.ObjectCategory ~= nil and stats.ObjectCategory == "Dye" then
        return true
    end

    if stats.ItemUseType ~= nil and stats.ItemUseType == "Grenade" then
        return true
    end

    if stats.ItemUseType ~= nil and stats.ItemUseType == "Scroll" then
        return true
    end

    if stats.Name ~= nil and (stats.Name == "OBJ_Kit_ThievesTools" or stats.Name == "OBJ_Kit_TrapDisarm") then
        return true
    end

    return false
end