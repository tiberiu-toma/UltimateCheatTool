CONS = {}
CONS.Max = 50

function CONS.GetAll(search, page)
    search = search or ""
    page = page or 1
    local pageSize = CONS.Max

    local itemData = Ext.Template.GetAllRootTemplates()

    local allMatchingConsumables = {}

    for k,v in pairs(itemData) do 
        local isItem = HLP.GetAttr(v, "TemplateType") == "item"
        if not isItem then goto continue end

        local id = HLP.GetAttr(v, "Id")
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName.Handle.Handle")
        local displayName = Ext.Loca.GetTranslatedString(handle, name)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

        if matchesSearch and displayName and displayName ~= "" and icon and icon ~= "" then
            local isConsumable = CONS.IsConsumable(v)
            if isConsumable then
                table.insert(allMatchingConsumables, {
                    id = id,
                    name = name,
                    icon = icon,
                    displayName = displayName
                })
            end
        end
        ::continue::
    end

    table.sort(allMatchingConsumables, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingConsumables, page, pageSize)
end

function CONS.IsConsumable(template)
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
    return false
end