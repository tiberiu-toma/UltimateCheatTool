MVM = {}

function MVM.Rotate(char, tget, x, y, z)
    if not char then return end 

    if tget then
        x,y,z = Osi.GetPosition(tget)
    end

    if not x or not y or not z then return end 

    local position = {x,y,z}

    -- ROTATE CHAR --
    Ext.ServerNet.PostMessageToClient(GetHostCharacter(), "rotate_character", Ext.Json.Stringify( { character = char, position = position } ))

    -- ROTATE PROP --
    local prop = PTP.GetAnimProp(char)
    if prop then
        Ext.Timer.WaitFor(250, function()
            Ext.ServerNet.PostMessageToClient(GetHostCharacter(), "rotate_character", Ext.Json.Stringify( { character = prop, position = position } ))
        end)
    end
end

function MVM.Move(char, tget, x, y, z)
    if not char then return end 

    if tget and not x then
        x,y,z = Osi.GetPosition(tget)
    end

    -- MOVE CHAR --
    Osi.TeleportToPosition(char, x, y, z, "", 0, 0, 0, 0, 0)

    -- MOVE PROPS --
    local prop = PTP.GetAnimProp(char)
    if prop then
        Ext.Timer.WaitFor(250, function()
            Osi.TeleportToPosition(prop, x, y, z, "", 0, 0, 0, 0, 0)
        end)
    end
end