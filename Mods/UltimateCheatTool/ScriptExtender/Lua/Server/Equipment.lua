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

        local id = HLP.GetAttr(v, "Id")
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName.Handle.Handle")
        local displayName = Ext.Loca.GetTranslatedString(handle, name)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

        if matchesSearch and displayName and displayName ~= "" and icon and icon ~= "" then
            local isEquipment = EKP.IsEquipable(v)
            if isEquipment then
                table.insert(allMatchingEquipment, {
                    id = id,
                    name = name,
                    icon = icon,
                    displayName = displayName
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
