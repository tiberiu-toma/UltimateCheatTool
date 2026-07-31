local Pagination = Ext.Require("Client/Pagination.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class PassiveTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field AllPassives table
---@field ResultCount int
---@field PassivesArea ExtuiCollapsingHeader
---@field PassiveSearch ExtuiGroup
---@field AddedPassives table
---@field AddedPassivesArea ExtuiGroup
---@field AmountOptions table
---@field CurrentPage number
---@field TotalPages number
---@field TotalItems number
---@field SearchText string
---@field PaginationAreaTop ExtuiGroup
---@field PaginationAreaBottom ExtuiGroup
PassiveTab = {}
PassiveTab.__index = PassiveTab

---@param holder ExtuiTabBar
function PassiveTab:GetAllPassives(page)
    self.CurrentPage = page or 1
    SMS.FetchPassives:SendToServer({ ID=USERID, search=self.SearchText, page=self.CurrentPage })
end

function PassiveTab:New(holder)
    if UI.PassiveTab then return end

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Passives")),
        AllPassives = {},
        ResultCount = 0,
        AddedPassives = {},
        AmountOptions = {1},
        CurrentPage = 1,
        TotalPages = 1,
        TotalItems = 0,
        SearchText = ""
    }, PassiveTab)
    return instance
end

function PassiveTab:SetPassives(payload)
    UI.DestroyChildren(self.PassivesArea)
    UI.DestroyChildren(self.PaginationAreaTop)
    UI.DestroyChildren(self.PaginationAreaBottom)

    local items = payload.data
    self.AllPassives = items
    self.ResultCount = HLP.Count(items)

    self.TotalItems = payload.totalItems or 0
    self.TotalPages = payload.totalPages or 1
    self.CurrentPage = payload.currentPage or 1

    if self.TotalItems == 0 then
        self.PassivesArea:AddText("No passives found.")
        -- No pagination controls needed if there are no items.
        return
    end

    local shownCount = HLP.Count(self.AllPassives)
    local maxTableWidth = 5
    local tableWidth = math.min(shownCount, maxTableWidth)
    
    Pagination:CreateControls({
        parent = self.PaginationAreaTop,
        idSuffix = "Top",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetAllPassives(page) end
    })

    self.PassivesArea:AddText("Showing " .. shownCount .. " of " .. self.TotalItems .. " items.")

    local t = self.PassivesArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.AllPassives) do
        if i % maxTableWidth == 1 then
            row = t:AddRow()
        end

        local uuid = HLP.GetAttr(data, "id")
        local icon = HLP.GetAttr(data, "icon")
        if not icon or icon == "unknown" or icon == "" then
            icon = "EC_Portrait_Generic"
        end
        local name = HLP.GetAttr(data, "displayName")

        local description = HLP.GetAttr(data, "description")
        local boosts = HLP.GetAttr(data, "boosts")
        local conditions = HLP.GetAttr(data, "conditions")
        local modName = HLP.GetAttr(data, "modName")

        if not name then
            goto continue
        end

        local fullName = name
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local PassiveItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("AddPassive")

        PassiveItem.OnClick = function()
            popup:Open()
        end

        local addPassiveBtn = popup:AddButton(LCL.Get("UCT_PassiveTab_Add", "Add"))
        local removePassiveBtn = popup:AddButton(LCL.Get("UCT_PassiveTab_Remove", "Remove"))
        removePassiveBtn.SameLine = true
        local addToSelectedItem = popup:AddButton(LCL.Get("UCT_PassiveTab_AddToSelectedItem", "Add to Selected Item"))
        local removeFromSelectedItem = popup:AddButton(LCL.Get("UCT_PassiveTab_RemoveFromSelectedItem", "Remove from Selected"))
        removeFromSelectedItem.SameLine = true

        local equipmentData = UI.EquipmentSelector.SelectedEquipment
        if not equipmentData then
            addToSelectedItem.Disabled = true
            removeFromSelectedItem.Disabled = true
        else
            addToSelectedItem.OnClick = function()
                if equipmentData and equipmentData.id then
                    local charUUID = UI.CharSelector.SelectedCharacter
                    SMS.AddPassiveOnItem:SendToServer({ character = charUUID, itemTemplateUUID = equipmentData.id, passiveUUID = uuid, data = data })
                    -- Optimistically update the local data and refresh the UI
                    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
                    if not modifiedEquipment[equipmentData.id] then modifiedEquipment[equipmentData.id] = {} end
                    if not modifiedEquipment[equipmentData.id].passives then modifiedEquipment[equipmentData.id].passives = {} end
                    modifiedEquipment[equipmentData.id].passives[uuid] = data
                    self:GetAddedPassives()
                end
            end
            removeFromSelectedItem.OnClick = function()
                if equipmentData and equipmentData.id then
                    local charUUID = UI.CharSelector.SelectedCharacter
                    SMS.RemovePassiveFromItem:SendToServer({ character = charUUID, itemTemplateUUID = equipmentData.id, passiveUUID = uuid })
                    -- Optimistically update the local data and refresh the UI
                    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
                    if modifiedEquipment[equipmentData.id] and modifiedEquipment[equipmentData.id].passives then
                        modifiedEquipment[equipmentData.id].passives[uuid] = nil
                    end
                    self:GetAddedPassives()
                end
            end
        end

        data.fullName = fullName
        local passiveInfoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
            { key = "description", label = "Description", formatter = function(value)
                local cleanDescription = value:gsub("</?LSTag[^>]*>", ""):gsub("<[Bb][Rr]>", "\n")
                return "\n\t" .. cleanDescription:gsub(";", "\n\t"):gsub("%. ", ".\n\t")
            end },
            { key = "boosts", label = "Boosts", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "conditions", label = "Conditions", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "modName", label = "Mod Name" },
        }
        InfoPopup:AddInfo(popup, data, passiveInfoFields)
        
        removePassiveBtn.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.AddPassive:SendToServer({ character = charUUID, uuid=uuid, remove=1})
            if self.AddedPassives[charUUID] then self.AddedPassives[charUUID][uuid] = nil end
            self:GetAddedPassives()
        end

        addPassiveBtn.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.AddPassive:SendToServer({ character = charUUID, uuid=uuid, amount=1, data=data })
            if not self.AddedPassives[charUUID] then self.AddedPassives[charUUID] = {} end
            self.AddedPassives[charUUID][uuid] = data
            self:GetAddedPassives()
        end

        i = i + 1

        ::continue::
    end

    Pagination:CreateControls({
        parent = self.PaginationAreaBottom,
        idSuffix = "Bottom",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetAllPassives(page) end
    })
end

---@param parent ExtuiGroup
---@param passives table
---@param maxTableWidth number
---@param onRemove function
function PassiveTab:_DrawPassiveGrid(parent, passives, maxTableWidth, onRemove)
    local total = HLP.Count(passives)
    if total == 0 then
        return
    end

    local tableWidth = math.min(total, maxTableWidth)
    local t = parent:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row = t:AddRow()

    for uuid, data in kpairs(passives) do
        if i > 1 and (i - 1) % maxTableWidth == 0 then
            row = t:AddRow()
        end

        local icon = HLP.GetAttr(data, "icon") or "EC_Portrait_Generic"
        if icon == "unknown" or icon == "" then icon = "EC_Portrait_Generic" end
        local fullName = HLP.GetAttr(data, "displayName")

        if not fullName then goto continue end

        local name = fullName
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local passiveItem = cell:AddImageButton("", icon, {100 * ViewPortScale, 100 * ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("ManagePassive_" .. uuid)

        passiveItem.OnClick = function() popup:Open() end

        data.fullName = fullName
        local infoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
        InfoPopup:AddInfo(popup, data, infoFields)

        local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
        removeButton.OnClick = function()
            onRemove(uuid, data)
        end

        i = i + 1
        ::continue::
    end
end

function PassiveTab:GetAddedPassives()
    UI.DestroyChildren(self.AddedPassivesArea)

    local header = self.AddedPassivesArea:AddCollapsingHeader("Added Passives")

    local layoutTable = header:AddTable("AddedPassivesLayout", 2)
    layoutTable.SizingFixedSame = true
    layoutTable.NoHostExtendX = true

    local row = layoutTable:AddRow()
    local charPassivesCell = row:AddCell()
    local itemPassivesCell = row:AddCell()

    -- Column 1: Character Passives
    charPassivesCell:AddSeparatorText("On Character")
    local charUUID = UI.CharSelector and UI.CharSelector.SelectedCharacter
    if not charUUID then
        charPassivesCell:AddText("Select a character.")
    else
        local addedForChar = self.AddedPassives[charUUID] or {}
        if HLP.Count(addedForChar) == 0 then
            charPassivesCell:AddText("No custom passives.")
        else
            self:_DrawPassiveGrid(charPassivesCell, addedForChar, 3, function(uuid, data)
                local charUUID = UI.CharSelector.SelectedCharacter
                SMS.AddPassive:SendToServer({ character = charUUID, uuid = uuid, remove = 1 })
                if self.AddedPassives[charUUID] then self.AddedPassives[charUUID][uuid] = nil end
                self:GetAddedPassives()
            end)
        end
    end

    -- Column 2: Item Passives
    itemPassivesCell:AddSeparatorText("On Selected Item")
    local equipmentData = UI.EquipmentSelector.SelectedEquipment
    if not equipmentData then
        itemPassivesCell:AddText("No item selected.")
    else
        local itemTemplateUUID = equipmentData.id
        local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
        local itemMods = modifiedEquipment[itemTemplateUUID]
        local itemPassives = itemMods and itemMods.passives

        if not itemPassives or HLP.Count(itemPassives) == 0 then
            itemPassivesCell:AddText("No custom passives.")
        else
            self:_DrawPassiveGrid(itemPassivesCell, itemPassives, 3, function(uuid, data)
                local charUUID = UI.CharSelector.SelectedCharacter
                SMS.RemovePassiveFromItem:SendToServer({ character = charUUID, itemTemplateUUID = itemTemplateUUID, passiveUUID = uuid })
                -- Optimistically update the client-side variable to avoid UI lag
                local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment
                if modifiedEquipment and modifiedEquipment[itemTemplateUUID] and modifiedEquipment[itemTemplateUUID].passives then
                    modifiedEquipment[itemTemplateUUID].passives[uuid] = nil
                    if HLP.Count(modifiedEquipment[itemTemplateUUID].passives) == 0 then modifiedEquipment[itemTemplateUUID].passives = nil end
                    if HLP.Count(modifiedEquipment[itemTemplateUUID]) == 0 then modifiedEquipment[itemTemplateUUID] = nil end
                    -- Set the modified table back to the variable
                    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
                end
                self:GetAddedPassives()
            end)
        end
    end
end

function PassiveTab:AddPassiveSearch()
    UI.DestroyChildren(self.PassiveSearch)

    local sep = self.PassiveSearch:AddSeparatorText(LCL.Get("", "Search Passives:"))

    local search = self.PassiveSearch:AddInputText("", "")
    local btn = self.PassiveSearch:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search"))

    btn.OnClick = function()
        self.SearchText = search.Text
        self:GetAllPassives(1)
    end
end

function PassiveTab:Init()
    self.AddedPassives = Ext.Vars.GetModVariables(ModuleUUID).AddedPassives or {}
    self.AddedPassivesArea = self.Tab:AddGroup("AddedPassives")

    self:GetAddedPassives()

    self.PassiveSearch = self.Tab:AddGroup("PassiveSearch")
    self.PaginationAreaTop = self.Tab:AddGroup("PaginationAreaTop")
    self.PassivesArea = self.Tab:AddGroup("AllPassives")
    self.PaginationAreaBottom = self.Tab:AddGroup("PaginationAreaBottom")

    self:AddPassiveSearch()

    self.AllPassives = {}
    self:GetAllPassives(1)
end

return PassiveTab