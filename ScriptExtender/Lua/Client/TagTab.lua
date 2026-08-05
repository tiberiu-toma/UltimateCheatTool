local BaseTab = Ext.Require("Client/BaseTab.lua")
local UIState = Ext.Require("Client/UIState.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class TagTab : BaseTab
---@field AppliedTags table
---@field AppliedTagsArea ExtuiGroup
TagTab = {}
setmetatable(TagTab, { __index = BaseTab })
TagTab.__index = TagTab

function TagTab:New(holder)
    local config = {
        tabName = "Tags",
        tabNameHandle = "UCT_TagTab_Label",
        idPrefix = "Tag",
        fetchMessage = SMS.FetchTags,
        searchLabel = "Search Tags:",
        searchLabelHandle = "UCT_SearchTags_Label",
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

    local t = self.MainArea:AddTable("TagGrid", tableWidth)
    t.SizingFixedSame = false
    t.NoHostExtendX = true

    local i = 1
    local row

    for uuid,data in kpairs(self.Items) do
        if (i - 1) % self.Config.maxTableWidth == 0 then
            row = t:AddRow()
        end

        local name = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))
        if not name then goto continue end
        local description = LCL.PreprocessXML(HLP.GetAttr(data, "displayDescription"))
        if not description then goto continue end

        local shortName = name
        if HLP.Strlen(shortName) > 25 then
            shortName = HLP.Cut(shortName, 1, 25) .. "..."
        end

        local cell = row:AddCell()
        local tagButton = cell:AddButton(shortName .. "##Tag" .. uuid)
        local popup = cell:AddPopup("AddTag" .. uuid)

        tagButton.OnClick = function()
            popup:Open()
        end

        local actionsTable = popup:AddTable("TagActionsTable" .. uuid, 2)
        actionsTable.SizingFixedSame = false
        actionsTable.NoHostExtendX = true

        local row1 = actionsTable:AddRow()
        local addButton = row1:AddCell():AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb72", "Add") .. "##Add" .. uuid)
        local removeButton = row1:AddCell():AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove") .. "##Remove" .. uuid)
        local row2 = actionsTable:AddRow()
        local addForPartyBtn = row2:AddCell():AddButton(LCL.Get("UCT_TagTab_AddForParty", "Add for Party") .. "##AddParty" .. uuid)
        local removeForPartyBtn = row2:AddCell():AddButton(LCL.Get("UCT_TagTab_RemoveForParty", "Remove for Party") .. "##RemoveParty" .. uuid)

        local tagInfoFields = {
            { key = "id", label = "ID" },
            { key = "displayName", label = "Name" },
            { key = "displayDescription", label = "Description" },
        }
        InfoPopup:AddInfo(popup, data, tagInfoFields)

        removeButton.OnClick = function()
            SMS.ManageTag:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, remove=1 })
        end

        addButton.OnClick = function()
            SMS.ManageTag:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, data=data })
        end

        addForPartyBtn.OnClick = function()
            SMS.AddTagForParty:SendToServer({ ID = USERID, uuid = uuid, data = data })
        end

        removeForPartyBtn.OnClick = function()
            SMS.RemoveTagForParty:SendToServer({ ID = USERID, uuid = uuid })
        end

        i = i + 1
        ::continue::
    end
end

function TagTab:GetAppliedTags()
    self.AppliedTags = Ext.Vars.GetModVariables(ModuleUUID).AppliedTags or {}

    UI_Utils.DestroyChildren(self.AppliedTagsArea)

    local charUUID = UIState.SelectedCharacter
    if not charUUID then
        self.AppliedTagsArea:AddText(LCL.Get("UCT_TagTab_SelectCharacter", "Select a character to see their tags."))
        return
    end

    local appliedForChar = self.AppliedTags[charUUID] or {}
    local totalApplied = HLP.Count(appliedForChar)
    if totalApplied == 0 then
        self.AppliedTagsArea:AddText(LCL.Get("UCT_NoCustomTags", "You don't have any custom tags applied."))
        return
    end

    local maxTableWidth = self.Config.maxTableWidth or 3
    local tableWidth = math.min(totalApplied, maxTableWidth)
    
    local header = self.AppliedTagsArea:AddCollapsingHeader("Applied Tags##AppliedTagsHeader")

    local t = header:AddTable("AppliedTagsGrid", tableWidth)
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

        local name = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))
        if not name then goto continue end
        local description = LCL.PreprocessXML(HLP.GetAttr(data, "displayDescription"))
        if not description then goto continue end

        local shortName = name
        if HLP.Strlen(shortName) > 25 then
            shortName = HLP.Cut(shortName, 1, 25) .. "..."
        end

        local cell = row:AddCell()
        local tagButton = cell:AddButton(shortName .. "##AppliedTag" .. uuid)
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

        local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove") .. "##" .. uuid)
        removeButton.OnClick = function()
            SMS.ManageTag:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, remove=1 })
        end

        i = i + 1
        drawnCount = drawnCount + 1
        ::continue::
    end
end

return TagTab