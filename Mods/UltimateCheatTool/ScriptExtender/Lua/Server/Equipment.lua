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
            local isEquipment = EKP.IsEquipable(id)
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

    local totalItems = #allMatchingEquipment
    local totalPages = math.ceil(totalItems / pageSize)
    if page > totalPages and totalPages > 0 then page = totalPages end
    if page < 1 then page = 1 end

    local startIndex = (page - 1) * pageSize + 1
    local endIndex = math.min(startIndex + pageSize - 1, totalItems)

    local equipmentForPage = {}
    for i = startIndex, endIndex do
        local item = allMatchingEquipment[i]
        if item then
            equipmentForPage[item.id] = item
        end
    end

    return equipmentForPage, totalItems, totalPages, page
end

function EKP.IsEquipable(uuid)
    return true
end