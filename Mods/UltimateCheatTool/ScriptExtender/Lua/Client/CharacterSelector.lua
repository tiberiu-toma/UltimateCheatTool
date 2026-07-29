---@class CharacterSelector
---@field Container ExtuiGroup
---@field PartyMembers table
---@field SelectedCharacter string
---@field OnChange function
CharacterSelector = {}
CharacterSelector.__index = CharacterSelector

function CharacterSelector:New(parent, onChange)
    local instance = setmetatable({
        Container = parent:AddGroup("CharacterSelector"),
        PartyMembers = {},
        SelectedCharacter = USERID, -- Default to host character
        OnChange = onChange
    }, CharacterSelector)
    return instance
end

function CharacterSelector:SetPartyMembers(members)
    self.PartyMembers = members
    -- If current selection is not in party, default to first member
    local found = false
    for _, member in ipairs(self.PartyMembers) do
        if member.uuid == self.SelectedCharacter then
            found = true
            break
        end
    end
    if not found and #self.PartyMembers > 0 then
        self:SetSelectedCharacter(self.PartyMembers[1].uuid)
    else
        -- Redraw to update the name if it was missing before
        self:Draw()
    end
end

function CharacterSelector:SetSelectedCharacter(charUUID)
    if self.SelectedCharacter ~= charUUID then
        self.SelectedCharacter = charUUID
        if self.OnChange then
            self.OnChange(charUUID)
        end
        self:Draw() -- Redraw to update selection visual
    end
end

function CharacterSelector:Draw()
    UI.DestroyChildren(self.Container)

    self.Container:AddText("Select Character to Apply Cheats To:")
    
    local selectedName = "None"
    for _, member in ipairs(self.PartyMembers) do
        if member.uuid == self.SelectedCharacter then
            selectedName = member.name
            break
        end
    end

    local comboButton = self.Container:AddButton(selectedName)
    comboButton.SameLine = true
    local popup = self.Container:AddPopup("CharacterSelectPopup")

    comboButton.OnClick = function()
        popup:Open()
    end

    local refreshButton = self.Container:AddButton("Refresh Character List")
    refreshButton.SameLine = true
    refreshButton.OnClick = function()
        SMS.FetchPartyMembers:SendToServer({ ID = USERID })
    end

    for _, member in ipairs(self.PartyMembers) do
        local itemButton = popup:AddButton(member.name)
        itemButton.OnClick = function()
            self:SetSelectedCharacter(member.uuid) -- This will trigger a redraw, effectively closing the old popup
        end
    end
end

function CharacterSelector:Init()
    self:Draw()
end

return CharacterSelector