local Pagination = Ext.Require("Client/Pagination.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class TagTab
---@field Tab ExtuiTabItem
---@field AllTags table
---@field ResultCount int
---@field TagsArea ExtuiGroup
---@field TagSearch ExtuiGroup
---@field AppliedTags table
---@field AppliedTagsArea ExtuiGroup
---@field CurrentPage number
---@field TotalPages number
---@field TotalItems number
---@field SearchText string
---@field PaginationAreaTop ExtuiGroup
---@field PaginationAreaBottom ExtuiGroup
TagTab = {}
TagTab.__index = TagTab

---@param holder ExtuiTabBar
function TagTab:GetAllTags(page)
    self.CurrentPage = page or 1
    SMS.FetchTags:SendToServer({ ID=USERID, search=self.SearchText, page=self.CurrentPage })
end

function TagTab:New(holder)
    if UI.TagTab then return end

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Tags")),
        AllTags = {},
        ResultCount = 0,
        AppliedTags = {},
        CurrentPage = 1,
        TotalPages = 1,
        TotalItems = 0,
        SearchText = ""
    }, TagTab)
    return instance
end

function TagTab:SetTags(payload)
    UI.DestroyChildren(self.TagsArea)
    UI.DestroyChildren(self.PaginationAreaTop)
    UI.DestroyChildren(self.PaginationAreaBottom)

    local items = payload.data
    self.AllTags = items
    self.ResultCount = HLP.Count(items)

    self.TotalItems = payload.totalItems or 0
    self.TotalPages = payload.totalPages or 1
    self.CurrentPage = payload.currentPage or 1

    if self.TotalItems == 0 then
        self.TagsArea:AddText("No tags found.")
        return
    end

    local shownCount = HLP.Count(self.AllTags)
    local maxTableWidth = 3
    local tableWidth = math.min(shownCount, maxTableWidth)

    Pagination:CreateControls({
        parent = self.PaginationAreaTop,
        idSuffix = "Top",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetAllTags(page) end
    })

    self.TagsArea:AddText("Showing " .. shownCount .. " of " .. self.TotalItems .. " items.")

    local t = self.TagsArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row = t:AddRow()

    for uuid,data in kpairs(self.AllTags) do
        if i % maxTableWidth == 1 then
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
        local tagButton = cell:AddButton(shortName)
        local txt = cell:AddText(name)
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
            self:GetAppliedTags()
        end

        addButton.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.ManageTag:SendToServer({ character = charUUID, uuid=uuid, data=data })
            if not self.AppliedTags[charUUID] then self.AppliedTags[charUUID] = {} end
            self.AppliedTags[charUUID][uuid] = data
            self:GetAppliedTags()
        end

        i = i + 1
        ::continue::
    end

    Pagination:CreateControls({
        parent = self.PaginationAreaBottom,
        idSuffix = "Bottom",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetAllTags(page) end
    })
end

function TagTab:GetAppliedTags()
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
    local row = t:AddRow()

    for uuid,data in kpairs(appliedForChar) do
        if i % maxTableWidth == 1 then
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
        local tagButton = cell:AddButton(shortName)
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
            SMS.ManageTag:SendToServer({ character = charUUID, uuid=uuid, unlearn=1 })
            if self.AppliedTags[charUUID] then self.AppliedTags[charUUID][uuid] = nil end
            self:GetAppliedTags()
        end

        i = i + 1
        ::continue::
    end
end

function TagTab:AddTagSearch()
    UI.DestroyChildren(self.TagSearch)

    local sep = self.TagSearch:AddSeparatorText(LCL.Get("", "Search Tags:"))

    local search = self.TagSearch:AddInputText("", "")
    local btn = self.TagSearch:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search"))

    btn.OnClick = function()
        self.SearchText = search.Text
        self:GetAllTags(1)
    end
end

function TagTab:Init()
    self.AppliedTags = Ext.Vars.GetModVariables(ModuleUUID).AppliedTags or {}
    self.AppliedTagsArea = self.Tab:AddGroup("AppliedTags")

    self:GetAppliedTags()

    self.TagSearch = self.Tab:AddGroup("TagSearch")
    self.PaginationAreaTop = self.Tab:AddGroup("PaginationAreaTop")
    self.TagsArea = self.Tab:AddGroup("AllTags")
    self.PaginationAreaBottom = self.Tab:AddGroup("PaginationAreaBottom")

    self:AddTagSearch()

    self.AllTags = {}
    self:GetAllTags(1)
end

return TagTab