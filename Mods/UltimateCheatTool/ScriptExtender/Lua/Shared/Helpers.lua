HLP = {}

HLP.Companions = {
    ["shadowheart"] = "3ed74f06-3c60-42dc-83f6-f034cb47c679",
    ["gale"] = "ad9af97d-75da-406a-ae13-7071c563f604",
    ["astarion"] = "c7c13742-bacd-460a-8f65-f864fe41f255",
    ["wyll"] = "c774d764-4a17-48dc-b470-32ace9ce447d",
    ["laezel"] = "58a69333-40bf-8358-1d17-fff240d7fb12",
    ["karlach"] = "2c76687d-93a2-477b-8b18-8a14b549304c",
    ["halsin"] = "7628bc0e-52b8-42a7-856a-13a6fd413323",
    ["minsc"] = "0de603c5-42e2-4811-9dad-f652de080eba",
    ["jaheira"] = "91b6b200-7d00-4d62-8dc9-99e8339dfa1a",
    ["minthara"] = "25721313-0c15-4935-8176-9f134385451b",
}

function HLP.Ucfirst(str)
    if not str or str == "" then return str end
    local firstLetter = string.sub(str, 1, 1)
    local remainingLetters = string.sub(str, 2)
    return string.upper(firstLetter) .. remainingLetters
end

-- Returns true if any value in the table (nested or not) is "non-empty"
function HLP.IsEmpty(tbl)
    if type(tbl) ~= "table" then
        return false
    end

    for _, v in pairs(tbl) do
        if type(v) == "table" then
            -- recurse into nested table
            if HLP.IsEmpty(v) then
                return true
            end
        else
            -- check for meaningful primitive value
            if v ~= nil and v ~= false then
                if type(v) == "string" then
                    if v ~= "" then
                        return true
                    end
                else
                    return true
                end
            end
        end
    end

    return false
end

function HLP.MakeUUID(str)
    local function Hash32(str, seed)
        local hash = seed or 2166136261
        for i = 1, #str do
            hash = hash ~ str:byte(i)
            hash = (hash * 16777619) % 4294967296
        end
        return hash
    end

    local h1 = Hash32(str, 2166136261)
    local h2 = Hash32(str, 2166136261 ~ 0xAAAAAAAA)
    local h3 = Hash32(str, 2166136261 ~ 0x55555555)
    local h4 = Hash32(str, 2166136261 ~ 0x12345678)

    local hex = string.format("%08x%08x%08x%08x", h1, h2, h3, h4)

    return string.format("%s-%s-%s-%s-%s",
        hex:sub(1, 8),
        hex:sub(9, 12),
        hex:sub(13, 16),
        hex:sub(17, 20),
        hex:sub(21, 32)
    )
end

function HLP.GetByKey(root, targetKey)
    local results = {}
    local visited = {}

    local function recurse(obj)
        -- Prevent infinite loops (cycles)
        if visited[obj] then return end
        visited[obj] = true

        -- Only process tables or userdata
        local t = type(obj)
        if t ~= "table" and t ~= "userdata" then
            return
        end

        -- Safely iterate (userdata may error)
        local success, err = pcall(function()
            for k, v in pairs(obj) do
                -- Match key
                if k == targetKey then
                    table.insert(results, v)
                end

                -- Recurse deeper
                if type(v) == "table" or type(v) == "userdata" then
                    recurse(v)
                end
            end
        end)

        -- If iteration fails (some userdata), just skip it
        if not success then
            return
        end
    end

    recurse(root)
    return results
end

function HLP.GetByKeys(root, targetKeys)
    local results = {}
    local visited = {}

    -- Normalize input into a lookup set
    local keySet = {}

    if type(targetKeys) == "table" then
        for _, key in ipairs(targetKeys) do
            keySet[key] = true
        end
    else
        keySet[targetKeys] = true
    end

    local function recurse(obj)
        if visited[obj] then return end
        visited[obj] = true

        local t = type(obj)
        if t ~= "table" and t ~= "userdata" then
            return
        end

        local success = pcall(function()
            for k, v in pairs(obj) do
                -- Match against any key in the set
                if keySet[k] then
                    table.insert(results, v)
                end

                if type(v) == "table" or type(v) == "userdata" then
                    recurse(v)
                end
            end
        end)

        if not success then
            return
        end
    end

    recurse(root)
    return results
end

function HLP.GetByValue(root, targetValue)
    local results = {}
    local visited = {}

    local function recurse(obj)
        if visited[obj] then return end
        visited[obj] = true

        local t = type(obj)
        if t ~= "table" and t ~= "userdata" then
            return
        end

        local success = pcall(function()
            for k, v in pairs(obj) do
                -- Match value
                if v == targetValue then
                    table.insert(results, k)
                end

                -- Recurse into nested structures
                if type(v) == "table" or type(v) == "userdata" then
                    recurse(v)
                end
            end
        end)

        if not success then
            return
        end
    end

    recurse(root)
    return results
end

function HLP.Count(tbl)
    local count = 0
    for k,v in pairs(tbl) do
        count = count + 1 
    end
    return count
end

function HLP.GetByValues(root, targetValues)
    local results = {}
    local visited = {}

    -- Normalize values into a lookup set
    local valueSet = {}

    if type(targetValues) == "table" then
        for _, v in ipairs(targetValues) do
            valueSet[v] = true
        end
    else
        -- Allow single value fallback
        valueSet[targetValues] = true
    end

    local function recurse(obj)
        if visited[obj] then return end
        visited[obj] = true

        local t = type(obj)
        if t ~= "table" and t ~= "userdata" then
            return
        end

        local success = pcall(function()
            for k, v in pairs(obj) do
                -- Match against any value in the set
                if valueSet[v] then
                    table.insert(results, k)
                end

                if type(v) == "table" or type(v) == "userdata" then
                    recurse(v)
                end
            end
        end)

        if not success then
            return
        end
    end

    recurse(root)
    return results
end

function HLP.GetFirst(tbl)
    for k,v in kpairs(tbl) do
        return v
    end
end

-- searchString: string to search for
-- properties: array-like table of property names to check
-- mainTable: table in the form { key = { property = value, ... } }
-- useNormalize: optional boolean, defaults to true
--
-- Returns: flat array of keys whose listed properties match the search string
function HLP.Search(searchString, properties, mainTable, useNormalize)
    if useNormalize == nil then
        useNormalize = true
    end

    local results = {}

    -- Prepare search string
    local needle = searchString
    if needle == nil then
        needle = ""
    else
        needle = tostring(needle)
    end

    if useNormalize then
        needle = HLP.Normalize(needle)
    end

    for key, entry in pairs(mainTable) do
        if type(entry) == "table" then
            local matched = false

            for _, propertyName in ipairs(properties) do
                local value = entry[propertyName]

                if value ~= nil then
                    local haystack = tostring(value)

                    if useNormalize then
                        haystack = HLP.Normalize(haystack)
                    end

                    if haystack:find(needle, 1, true) then
                        matched = true
                        break
                    end
                end
            end

            if matched then
                results[key] = entry
            end
        end
    end

    return results
end

function HLP.Flatten(root)
    local results = {}
    local visited = {}

    local function recurse(obj)
        if visited[obj] then return end
        visited[obj] = true

        local t = type(obj)

        if t ~= "table" and t ~= "userdata" then
            return
        end

        local success = pcall(function()
            for _, v in pairs(obj) do
                local vt = type(v)

                if vt == "table" or vt == "userdata" then
                    -- Recurse, but DO NOT insert
                    recurse(v)
                else
                    -- Only insert terminal values
                    table.insert(results, v)
                end
            end
        end)

        if not success then
            return
        end
    end

    recurse(root)
    return results
end

function HLP.Contains(tbl, val, normalize, include_keys)
    include_keys = include_keys or false

    val = HLP.Normalize(val, normalize)

    for k,v in pairs(tbl) do
        v = HLP.Normalize(v, normalize)
        k = HLP.Normalize(k, normalize)

        if string.match(val, v) then
            return true
        end
        if string.match(val, k) and include_keys == true then
            return true
        end
    end

    return false
end

local function isIndexable(v)
    local t = type(v)
    return t == "table" or t == "userdata"
end

local function safeGet(obj, key)
    local ok, result = pcall(function()
        return obj[key]
    end)
    if ok then
        return result
    end
    return nil
end

local function safeSet(obj, key, value)
    pcall(function()
        obj[key] = value
    end)
end

function HLP.Merge(a, b)
    -- If b is nil, just return a
    if b == nil then
        return a
    end

    -- If a is nil, return b
    if a == nil then
        return b
    end

    -- If either is not indexable, override directly
    if not isIndexable(a) or not isIndexable(b) then
        return b
    end

    -- Create result (preserve original a structure)
    local result = {}

    -- Copy from a first
    for k, v in pairs(a) do
        result[k] = v
    end

    -- Merge / override from b
    for k, vB in pairs(b) do
        local vA = safeGet(a, k)

        if isIndexable(vA) and isIndexable(vB) then
            result[k] = HLP.Merge(vA, vB)
        else
            result[k] = vB
        end
    end

    return result
end

function HLP.Cut(str, index, offset)
    return string.sub(str, index, offset)
end

function HLP.Strlen(str)
    return string.len(str)
end

function HLP.Trim(s)
    if not s then return "" end
    return s:match'^%s*(.*%S)' or ''
end

function HLP.StrContains(needle, haystack, normalize)
    needle = HLP.Normalize(needle, normalize)
    haystack = HLP.Normalize(haystack, normalize)

    if string.match(haystack, needle) then return true end 
    return false
end

function kpairs(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, function(x, y)
        local tx, ty = type(x), type(y)

        if tx == ty then
            return tostring(x) < tostring(y)
        else
            return tx < ty
        end
    end)
    local i = 0
    local iter = function ()
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

function HLP.GetAttr(data, keys, fallback)
    fallback = fallback or nil

    if data == nil or type(keys) ~= "string" then
        return fallback
    end

    local current = data

    for key in string.gmatch(keys, "[^%.]+") do
        if current == nil then
            return fallback
        end

        local success, result = pcall(function()
            return current[key]
        end)

        if not success then
            return fallback
        end

        current = result
    end

    return current
end

function HLP.StrContainsAlt(str, sub)
    str = str:lower()
    sub = sub:lower()
    
    return (string.find(str, sub, 1, true) ~= nil)
end

function HLP.Slice(t, start, stop)
    local sliced = {}
    local keys = {}

    for key,_ in kpairs(t) do 
        table.insert(keys, key)
    end

    local max = math.min(stop or #keys, #keys)

    for i = start, max do
        local key = keys[i]
        if key ~= nil then
            table.insert(sliced, t[key])
        end
    end

    return sliced
end

function HLP.Normalize(str, ignore)
    if ignore == true then return str end
    if type(str) ~= "string" then 
        str = tostring(str)
    end 

    str = string.lower(str)
    str = string.gsub(str, "-", "")
    str = string.gsub(str, "_", "")

    return str
end