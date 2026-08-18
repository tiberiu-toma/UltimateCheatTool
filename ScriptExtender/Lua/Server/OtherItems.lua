OITM = {}
OITM.Max = 50

function OITM.GetAll(search, page, filters)
    search = search or ""
    page = page or 1
    local pageSize = OITM.Max

    local itemData = Ext.Template.GetAllRootTemplates()
    local allMatchingItems = {}

    for k,v in pairs(itemData) do
        if HLP.GetAttr(v, "TemplateType") == "item" then
            -- Check if it's NOT equipment and NOT a consumable
            if not EKP.IsEquipable(v) and not CONS.IsConsumable(v) then
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
                    table.insert(allMatchingItems, {
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

    local filtered = FLTR.Apply(allMatchingItems, filters)
    table.sort(filtered, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(filtered, page, pageSize)
end

return OITM