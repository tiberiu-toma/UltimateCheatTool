local channel = "rotate_character"

Ext.Events.NetMessage:Subscribe(function(data)
    if data.Channel == channel then
        local data = Ext.Json.Parse(data.Payload)

        local character = data["character"]
        local position = data["position"]

        RotateTo(character, position)
    end
end)

function RotateTo(character, position)
    local char = Ext.Entity.Get(character)

    if not char then return end
    
    local charTransform = char.Transform.Transform
    local charx = charTransform.Translate[1]
    local chary = charTransform.Translate[3]
    local vecx = charx - position[1]
    local vecy = chary - position[3]
    local RadToLookAt = Ext.Math.Atan2(vecx,vecy)
    if char.Steering then
        char.Steering.TargetRotation = RadToLookAt
    elseif char.Visual then
        local yaw = RadToLookAt

        local half = yaw * 0.5
        local qx = 0
        local qy = math.sin(half)
        local qz = 0
        local qw = math.cos(half)

        if GetAttr(char, "Visual.Visual") then
            char.Visual.Visual:SetWorldRotate({qx, qy, qz, qw})
        end

        --Ext.Dump({qx, qy, qz, qw})
    else
        ----print("Can't rotate Entity " .. char.Uuid.EntityUuid)
    end
end

function GetAttr(data, keys, fallback)
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