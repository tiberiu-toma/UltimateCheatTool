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
            local isConsumable = CONS.IsConsumable(id)
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

    local totalItems = #allMatchingConsumables
    local totalPages = math.ceil(totalItems / pageSize)
    if page > totalPages and totalPages > 0 then page = totalPages end
    if page < 1 then page = 1 end

    local startIndex = (page - 1) * pageSize + 1
    local endIndex = math.min(startIndex + pageSize - 1, totalItems)

    local consumablesForPage = {}
    for i = startIndex, endIndex do
        local item = allMatchingConsumables[i]
        if item then
            consumablesForPage[item.id] = item
        end
    end

    return consumablesForPage, totalItems, totalPages, page
end

function CONS.IsConsumable(uuid)
    return true
end