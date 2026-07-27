PASSV = {}
PASSV.Max = 50

function PASSV.GetAll(search)
    search = search or ""

    local itemData = Ext.Stats.GetStats("PassiveData")

    local passiveCount = 0
    local passives = {}

    for k,v in pairs(itemData) do 
        local id = v
        v = Ext.Stats.Get(v)
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName")

        local displayName = Ext.Loca.GetTranslatedString(handle)

        local matchesSearch = true

        if search ~= "" then
            matchesSearch = HLP.StrContains(search, displayName)
        end

        if matchesSearch then

            local isPassive = true

            if isPassive and displayName and displayName ~= "" then
                passiveCount = passiveCount + 1
                
                passives[id] = {
                    id = id,
                    name = name,
                    icon = icon,
                    displayName = displayName,
                }
            end
        end
            
        if HLP.Count(passives) >= PASSV.Max then break end 
    end

    return passives
end

function PASSV.Learn(passiveId, unlearn)
    if unlearn then
        Osi.RemovePassive(GetHostCharacter(), passiveId)
    else
        Osi.AddPassive(GetHostCharacter(), passiveId)
    end
end