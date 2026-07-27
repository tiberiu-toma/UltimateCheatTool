ENPC = {}
ENPC.Max = 50

function ENPC.GetAll(search, page)
    search = search or ""
    page = page or 1
    local pageSize = ENPC.Max

    local itemData = Ext.Template.GetAllRootTemplates()

    local allMatchingNPCs = {}

    for k,v in pairs(itemData) do 
        local isCharacter = HLP.GetAttr(v, "TemplateType") == "character"
        if not isCharacter then goto continue end

        local id = HLP.GetAttr(v, "Id")
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName.Handle.Handle")
        local displayName = Ext.Loca.GetTranslatedString(handle, name)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

        if matchesSearch and displayName and displayName ~= "" then
            local isNPC = true--ENPC.IsNPC(id)
            if isNPC then
                table.insert(allMatchingNPCs, {
                    id = id,
                    name = name,
                    icon = icon,
                    displayName = displayName
                })
            end
        end
        ::continue::
    end

    table.sort(allMatchingNPCs, function(a, b) return a.displayName < b.displayName end)

    local totalItems = #allMatchingNPCs
    local totalPages = math.ceil(totalItems / pageSize)
    if page > totalPages and totalPages > 0 then page = totalPages end
    if page < 1 then page = 1 end

    local startIndex = (page - 1) * pageSize + 1
    local endIndex = math.min(startIndex + pageSize - 1, totalItems)

    local npcsForPage = {}
    for i = startIndex, endIndex do
        local item = allMatchingNPCs[i]
        if item then
            npcsForPage[item.id] = item
        end
    end

    return npcsForPage, totalItems, totalPages, page
end

function ENPC.IsNPC(uuid)
    -- TO DO: Find a way of checking if a template is a character --
    
    return true;
end