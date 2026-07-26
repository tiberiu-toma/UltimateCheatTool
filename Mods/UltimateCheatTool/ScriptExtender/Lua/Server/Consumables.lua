CONS = {}
CONS.Max = 50000

function CONS.GetAll(search)
    search = search or ""

    local itemData = Ext.Template.GetAllRootTemplates()

    local consumableCount = 0
    local consumable = {}

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

            local isConsumable = CONS.IsConsumable(id)

            if isConsumable then
                consumableCount = consumableCount + 1
                
                consumable[id] = {
                    id = id,
                    name = name,
                    icon = icon,
                    displayName = displayName
                }
            end
        end
            
        if HLP.Count(consumable) >= EKP.Max then break end 
    end

    print(consumableCount .. " Total Consumables")
    return consumable
end

function CONS.IsConsumable(uuid)
    return true
end