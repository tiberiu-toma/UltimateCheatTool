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
            local isNPC = true
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

    return UTL.Paginate(allMatchingNPCs, page, pageSize)
end