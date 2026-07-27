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

function EKP.GetAll(search)
    search = search or ""

    local itemData = Ext.Template.GetAllRootTemplates()

    local equipmentCount = 0
    local equipment = {}

    for k,v in pairs(itemData) do 
        local isItem = HLP.GetAttr(v, "TemplateType") == "item"

        local id = HLP.GetAttr(v, "Id")
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName.Handle.Handle")

        local displayName = Ext.Loca.GetTranslatedString(handle, name)

        local matchesSearch = true

        if search ~= "" then
            matchesSearch = HLP.StrContains(search, name) or HLP.StrContains(search, displayName)
        end

        if isItem and matchesSearch then

            local isEquipment = EKP.IsEquipable(id)

            if isEquipment then
                equipmentCount = equipmentCount + 1
                
                equipment[id] = {
                    id = id,
                    name = name,
                    icon = icon,
                    displayName = displayName
                }
            end
        end
            
        if HLP.Count(equipment) >= EKP.Max then break end 
    end

    --print(equipmentCount .. " Total Equipment")
    return equipment
end

function EKP.IsEquipable(uuid)
    return true
end