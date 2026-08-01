local BaseTab = Ext.Require("Client/BaseTab.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class TagTab : BaseTab
---@field AppliedTags table
---@field AppliedTagsArea ExtuiGroup
TagTab = {}
setmetatable(TagTab, { __index = BaseTab })
TagTab.__index = TagTab

function TagTab:New(holder)
    if UI.TagTab then return end

    local config = {
        tabName = "Tags",
        idPrefix = "Tag",
        fetchMessage = SMS.FetchTags,
        searchLabel = "Search Tags:",
        noItemsText = "No tags found.",
        maxTableWidth = 3
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, TagTab) -- Re-set metatable to the child class
    instance.AppliedTags = {}
    return instance
end

function TagTab:Init()
    self.AppliedTagsArea = self.Tab:AddGroup("AppliedTags")
    self:GetAppliedTags()

    -- This will create the search, pagination, and main areas and fetch the first page of all tags
    BaseTab.Init(self)
end

function TagTab:DrawGrid()
    local shownCount = HLP.Count(self.Items)
    local tableWidth = math.min(shownCount, self.Config.maxTableWidth)

    local t = self.MainArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row

    for uuid,data in kpairs(self.Items) do
        if (i - 1) % self.Config.maxTableWidth == 0 then
            row = t:AddRow()
        end

        local name = HLP.GetAttr(data, "displayName")
        if not name then goto continue end
        local description = HLP.GetAttr(data, "displayDescription")
        if not description then goto continue end

        local shortName = name
        if HLP.Strlen(shortName) > 25 then
            shortName = HLP.Cut(shortName, 1, 25) .. "..."
        end

        local cell = row:AddCell()
        local tagButton = cell:AddButton(shortName .. "##Tag" .. uuid)
        cell:AddText(name)
        local popup = cell:AddPopup("AddTag" .. uuid)

        tagButton.OnClick = function()
            popup:Open()
        end

        local addButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb72", "Add"))
        local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
        removeButton.SameLine = true

        local tagInfoFields = {
            { key = "id", label = "ID" },
            { key = "displayName", label = "Name" },
            { key = "displayDescription", label = "Description" },
        }
        InfoPopup:AddInfo(popup, data, tagInfoFields)

        removeButton.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.ManageTag:SendToServer({ character = charUUID, uuid=uuid, remove=1 })
            if self.AppliedTags[charUUID] then self.AppliedTags[charUUID][uuid] = nil end
            self:GetAppliedTags(true)
        end

        addButton.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.ManageTag:SendToServer({ character = charUUID, uuid=uuid, data=data })
            if not self.AppliedTags[charUUID] then self.AppliedTags[charUUID] = {} end
            self.AppliedTags[charUUID][uuid] = data
            self:GetAppliedTags(true)
        end

        i = i + 1
        ::continue::
    end
end

function TagTab:GetAppliedTags(noRefetch)
    if not noRefetch then
        self.AppliedTags = Ext.Vars.GetModVariables(ModuleUUID).AppliedTags or {}
    end

    UI.DestroyChildren(self.AppliedTagsArea)

    local charUUID = UI.CharSelector and UI.CharSelector.SelectedCharacter
    if not charUUID then
        self.AppliedTagsArea:AddText("Select a character to see their tags.")
        return
    end

    local appliedForChar = self.AppliedTags[charUUID] or {}
    local totalApplied = HLP.Count(appliedForChar)
    if totalApplied == 0 then
        self.AppliedTagsArea:AddText("You don't have any custom tags applied.")
        return
    end

    local maxTableWidth = 5
    local tableWidth = math.min(totalApplied, maxTableWidth)

    local header = self.AppliedTagsArea:AddCollapsingHeader("Applied Tags")

    local t = header:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row
    local drawnCount = 0
    local maxDrawn = 50 -- Performance cap

    for uuid,data in kpairs(appliedForChar) do
        if drawnCount >= maxDrawn then
            header:AddText("...and more (list truncated for performance).")
            break
        end

        if (i - 1) % maxTableWidth == 0 then
            row = t:AddRow()
        end

        local name = HLP.GetAttr(data, "displayName")
        if not name then goto continue end
        local description = HLP.GetAttr(data, "displayDescription")
        if not description then goto continue end

        local shortName = name
        if HLP.Strlen(shortName) > 25 then
            shortName = HLP.Cut(shortName, 1, 25) .. "..."
        end

        local cell = row:AddCell()
        local tagButton = cell:AddButton(shortName .. "##AppliedTag" .. uuid)
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("ManageTag" .. uuid)

        tagButton.OnClick = function()
            popup:Open()
        end

        local appliedTagInfoFields = {
            { key = "id", label = "ID" },
            { key = "displayName", label = "Name" },
            { key = "displayDescription", label = "Description" },
        }
        InfoPopup:AddInfo(popup, data, appliedTagInfoFields)

        local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
        removeButton.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.ManageTag:SendToServer({ character = charUUID, uuid=uuid, remove=1 })
            if self.AppliedTags[charUUID] then self.AppliedTags[charUUID][uuid] = nil end
            self:GetAppliedTags(true)
        end

        i = i + 1
        drawnCount = drawnCount + 1
        ::continue::
    end
end

return TagTab