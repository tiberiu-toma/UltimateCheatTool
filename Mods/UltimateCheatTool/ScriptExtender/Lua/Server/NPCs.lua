ENPC = {}
ENPC.Max = 50000

function ENPC.GetAll(search)
    search = search or ""

    local itemData = Ext.Template.GetAllRootTemplates()

    local charCount = 0
    local NPCs = {}

    for k,v in pairs(itemData) do 
        local isCharacter = HLP.GetAttr(v, "TemplateType") == "character"

        local id = HLP.GetAttr(v, "Id")
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName.Handle.Handle")

        local displayName = Ext.Loca.GetTranslatedString(handle, name)

        local matchesSearch = true

        if search ~= "" then
            matchesSearch = HLP.StrContains(search, name) or HLP.StrContains(search, displayName)
        end

        if isCharacter and matchesSearch then

            local isNPC = true--ENPC.IsNPC(id)

            if isNPC then
                charCount = charCount + 1
                
                NPCs[id] = {
                    id = id,
                    name = name,
                    icon = icon,
                    displayName = displayName
                }
            end
        end
            
        if HLP.Count(NPCs) >= ENPC.Max then break end 
    end

    --print(charCount .. " Total Characters")
    return NPCs
end

function ENPC.IsNPC(uuid)
    -- TO DO: Find a way of checking if a template is a character --
    
    return true;
end