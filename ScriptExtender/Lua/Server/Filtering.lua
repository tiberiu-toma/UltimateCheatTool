FLTR = {}

local vanillaMods = { Gustav = true, GustavDev = true, GustavX = true, SharedDev = true, Shared = true }

--- Applies a set of common filters to a list of items.
---@param items table The list of items to filter.
---@param filters table The filter criteria from the client.
---@return table The new list of filtered items.
function FLTR.Apply(items, filters)
    if not filters then return items end

    local filteredItems = {}
    for _, item in ipairs(items) do
        local matches = true

        -- Mod Name Filter
        if filters.modName and filters.modName ~= "All" then
            if filters.modName == "Larian" then
                if not vanillaMods[item.modName] then
                    matches = false
                end
            elseif item.modName ~= filters.modName then
                matches = false
            end
        end
        if not matches then goto continue end

        -- Rarity Filter
        if filters.rarity and filters.rarity ~= "All" and item.rarity ~= filters.rarity then
            matches = false
        end
        if not matches then goto continue end

        -- ModifierList Filter
        if filters.modifierList and filters.modifierList ~= "All" and item.modifierList ~= filters.modifierList then
            matches = false
        end
        if not matches then goto continue end

        -- Slot Filter
        if filters.slot and filters.slot ~= "All" and item.slot ~= filters.slot then
            matches = false
        end
        if not matches then goto continue end

        -- Spell Level Filter
        if filters.spellLevel and filters.spellLevel ~= "All" then
            local itemLevel = item.level
            if filters.spellLevel == "Cantrip" then
                if itemLevel ~= 0 then matches = false end
            elseif tostring(itemLevel) ~= filters.spellLevel then
                matches = false
            end
        end
        if not matches then goto continue end

        -- Spell School Filter
        if filters.spellSchool and filters.spellSchool ~= "All" and item.spellSchool ~= filters.spellSchool then
            matches = false
        end
        if not matches then goto continue end

        table.insert(filteredItems, item)
        ::continue::
    end
    return filteredItems
end

--- A generic function to get a sorted list of unique mod names from a data source.
---@param dataSource table The data source to iterate over.
---@param extractor function A function that takes an item from the data source and returns its mod name.
---@return table A sorted list of mod names.
function FLTR.GetModNames(dataSource, extractor)
    local modNames = { All = true }
    local hasLarianContent = false

    for _, item in pairs(dataSource) do
        local modName = extractor(item)
        if modName and modName ~= "Unknown" then
            if vanillaMods[modName] then
                hasLarianContent = true
            else
                modNames[modName] = true
            end
        end
    end

    if hasLarianContent then
        modNames["Larian"] = true
    end

    local sortedModNames = { "All" }
    for name, _ in pairs(modNames) do if name ~= "All" then table.insert(sortedModNames, name) end end
    table.sort(sortedModNames)
    return sortedModNames
end