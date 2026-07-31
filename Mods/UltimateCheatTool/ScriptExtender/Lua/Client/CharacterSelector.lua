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
        SelectedCharacter = _C().Uuid.EntityUuid,
        OnChange = onChange,
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

    local selectedName = "None"
    local selectedIcon = "EC_Portrait_Generic"
    for _, member in ipairs(self.PartyMembers) do
        if member.uuid == self.SelectedCharacter then
            selectedName = member.name
            selectedIcon = member.icon or "EC_Portrait_Generic"
            break
        end
    end

    local layoutTable = self.Container:AddTable("CharacterSelectorLayout", 2)
    layoutTable.SizingFixedSame = true
    layoutTable.NoHostExtendX = true

    local row1 = layoutTable:AddRow()
    row1:AddCell():AddText("Select Character to Apply Cheats To:")
    local imageCell = row1:AddCell()
    local comboImageButton = imageCell:AddImageButton("char_select_img", selectedIcon, {100 * ViewPortScale, 100 * ViewPortScale})

    local row2 = layoutTable:AddRow()
    local refreshCell = row2:AddCell()
    local refreshButton = refreshCell:AddButton("Refresh Party")
    refreshButton.OnClick = function()
        SMS.FetchPartyMembers:SendToServer({ ID = USERID })
        self:SetSelectedCharacter(_C().Uuid.EntityUuid)
    end
    local nameCell = row2:AddCell()
    nameCell:AddText(selectedName)

    local popup = self.Container:AddPopup("CharacterSelectPopup")

    -- Clicking the image opens the selection popup.
    comboImageButton.OnClick = function()
        popup:Open()
    end

    for _, member in ipairs(self.PartyMembers) do
        local memberGroup = popup:AddGroup("popup_member_"..member.uuid)
        
        local icon = member.icon or "EC_Portrait_Generic"
        -- Use a smaller icon in the dropdown for better spacing.
        local itemImageButton = memberGroup:AddImageButton("popup_char_img_"..member.uuid, icon, {60 * ViewPortScale, 60 * ViewPortScale})

        -- Center the text in the dropdown item.
        memberGroup:AddText(member.name)

        itemImageButton.OnClick = function()
            self:SetSelectedCharacter(member.uuid) -- This will trigger a redraw, effectively closing the old popup
        end
    end
end

function CharacterSelector:Init()
    SMS.FetchPartyMembers:SendToServer({ ID = USERID })
    self:SetSelectedCharacter(_C().Uuid.EntityUuid)
    self:Draw()
end

return CharacterSelector