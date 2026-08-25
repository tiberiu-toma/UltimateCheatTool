TAGS = {}
TAGS.Max = 50

function TAGS.GetAll(search, page, filters)
    search = search or ""
    page = page or 1
    local pageSize = TAGS.Max

    local tagData = Ext.StaticData.GetAll("Tag")
    local allMatchingTags = {}

    for _, tagId in pairs(tagData) do
        local staticData = Ext.StaticData.Get(tagId, "Tag")
        local handle = HLP.GetAttr(staticData, "DisplayName.Handle.Handle")
        local name = HLP.GetAttr(staticData, "Name")
        local displayName = handle ~= nil and handle ~= "" and HLP.GetTranslatedString(handle, name) or name
        local displayDescription = Ext.Loca.GetTranslatedString(staticData.DisplayDescription.Handle.Handle, staticData.Description)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName))

        if matchesSearch and displayName and displayName ~= "" then
            table.insert(allMatchingTags, {
                id = tagId,
                displayName = displayName,
                displayDescription = displayDescription
            })
        end
    end

    table.sort(allMatchingTags, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingTags, page, pageSize)
end

function TAGS.Set(character, tagId)
    Osi.SetTag(character, tagId)
end

function TAGS.Clear(character, tagId)
    Osi.ClearTag(character, tagId)
end

function TAGS.Manage(payload)
    local remove = HLP.GetAttr(payload, "remove")
    HLP.ManageCharacterStat(payload, remove, "AppliedTags", TAGS.Set, TAGS.Clear, "Tag")
end

function TAGS.ManageForParty(payload, remove)
    HLP.ManageCharacterStatForParty(payload, remove, "AppliedTags", TAGS.Set, TAGS.Clear, "Tag")
end