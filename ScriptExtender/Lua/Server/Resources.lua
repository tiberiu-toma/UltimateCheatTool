RSRC = {}
RSRC.Max = 50

function RSRC.GetAll(search, page)
    search = search or ""
    page = page or 1
    local pageSize = RSRC.Max

    local resourceData = Ext.StaticData.GetAll("ActionResource")
    local allMatchingResources = {}

    for _, resourceUUID in ipairs(resourceData) do
        local staticData = Ext.StaticData.Get(resourceUUID, "ActionResource")
        if staticData then
            local name = staticData.Name
            local displayName = HLP.GetTranslatedString(staticData.DisplayName.Handle.Handle, name)
            local description = Ext.Loca.GetTranslatedString(staticData.Description.Handle.Handle)
            local maxLevel = staticData.MaxLevel or 0 -- Get MaxLevel, default to 0

            local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

            if matchesSearch and displayName and displayName ~= "" then
                table.insert(allMatchingResources, {
                    id = name,
                    uuid = resourceUUID,
                    name = name,
                    displayName = displayName,
                    description = description,
                    maxLevel = maxLevel
                })
            end
        end
    end

    table.sort(allMatchingResources, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingResources, page, pageSize)
end

return RSRC