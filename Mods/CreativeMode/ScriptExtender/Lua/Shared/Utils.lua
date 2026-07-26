UTL = {}

function GetTableKeys(tbl, prefix, result)
    result = result or {}
    prefix = prefix or ""

    for k, v in pairs(tbl) do
        local full_key = prefix ~= "" and (prefix .. "." .. tostring(k)) or tostring(k)
        table.insert(result, full_key)

        if type(v) == "table" then
            GetTableKeys(v, full_key, result)
        end
    end

    return result
end

function GetMapKeysByShorthand(val)
    local keys = {}
    local names = {}

    for shorthand,mapNames in pairs(MapKeyShorthands) do
        if shorthand == val then
            names = mapNames
        end
    end

    keys = GetMapKeysByNames(names)

    return keys
end

function GetMapKeysByNames(tbl)
    local keys = {}

    for _,name in pairs(tbl) do
        for mpKey,mpName in pairs(BG3MapKeys) do
            if mpName == name then 
                table.insert(keys, mpKey)
            end
        end
    end

    return keys
end

function UTL.GetMapKeyOverridePairs(animOverrides, applyDefaultToAll)
    local mapKeys = BG3MapKeys
    local result = {}
    local defaultAnimID = nil

    applyDefaultToAll = applyDefaultToAll or false

    -- 1. Find the default ("*") animID
    for animID, overrideShorthands in pairs(animOverrides) do
        for _, shorthand in ipairs(overrideShorthands) do
            if shorthand == "*" then
                defaultAnimID = animID
                break
            end
        end
        if defaultAnimID then break end
    end

    -- 2. Apply default to ALL mapKey IDs
    if defaultAnimID and applyDefaultToAll then
        local allNames = {}
        local keys = {}

        --[[for mKey,mName in pairs(BG3MapKeys) do
            result[mKey] = defaultAnimID
        end]]

        for shorthand,mpNames in pairs(MapKeyShorthands) do
            if shorthand ~= "head" then
                local v = GetMapKeysByShorthand(shorthand)

                for _,k in pairs(v) do
                    result[k] = defaultAnimID
                end
            end
        end
    end

    -- 3. Apply specific overrides (overwrite default)
    for animID, overrideShorthands in pairs(animOverrides) do
        for _, shorthand in ipairs(overrideShorthands) do
            if shorthand ~= "*" then
                local mpKeys = GetMapKeysByShorthand(shorthand)
                --Ext.Dump(mpKeys)

                for _, key in pairs(mpKeys) do
                    result[key] = animID
                end
            end
        end
    end

    --Ext.Dump(result)

    return result
end

--[[

function UTL.GetMapKeyOverridePairs(animOverrides, applyDefaultToAll)
    local mapKeys = BG3MapKeys
    local result = {}
    local defaultAnimID = nil

    applyDefaultToAll = applyDefaultToAll or false

    -- 1. Find the default ("*") animID
    for animID, overrideKeys in pairs(animOverrides) do
        for _, key in ipairs(overrideKeys) do
            if key == "*" then
                defaultAnimID = animID
                break
            end
        end
        if defaultAnimID then break end
    end

    -- 2. Apply default to ALL mapKey IDs
    if defaultAnimID then
        for _, idList in pairs(mapKeys) do
            for _, mapKeyID in ipairs(idList) do
                result[mapKeyID] = defaultAnimID
            end
        end
    end

    -- 3. Apply specific overrides (overwrite default)
    for animID, overrideKeys in pairs(animOverrides) do
        for _, key in ipairs(overrideKeys) do
            if key ~= "*" and mapKeys[key] then
                for _, mapKeyID in ipairs(mapKeys[key]) do
                    result[mapKeyID] = animID
                end
            end
        end
    end


    return result
end

function UTL.GetMapKeyOverridePairs(tbl)
    local keyAnimPairs = {}

    for typ,keys in pairs(BG3MapKeys) do
      --[[ local keyMatch = "*" 
        for _,ks in pairs(tbl) do 
            for k,_ in pairs(ks) do 
                if k == typ then 
                    keyMatch = typ 
                end
            end
        end
        for animID,maps in pairs(tbl) do
            for _,map in pairs(maps) do 
                if map == typ then
                    for _, kk in pairs(keys) do 
                        if not keyAnimPairs[map] then
                            keyAnimPairs[kk] =  animID 
                        else
                            --table.insert(keyAnimPairs[map], animID)
                        end
                    end
                end
            end
        end
    end

    local allMapKeys = {}
    for k,v in pairs(BG3MapKeys) do 
        for _,key in pairs(v) do
            table.insert(allMapKeys, v)
        end
    end

    return keyAnimPairs
end
]]