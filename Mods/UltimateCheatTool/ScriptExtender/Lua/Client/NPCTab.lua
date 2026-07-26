---@class NPCTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field AllNPCs table
---@field ResultCount int
---@field NPCArea ExtuiCollapsingHeader
---@field NPCSearch ExtuiGroup
---@field SpawnedNPCs table
---@field SpawnedNPCsArea ExtuiGroup
---@field AmountOptions table
NPCTab = {}
NPCTab.__index = NPCTab

---@param holder ExtuiTabBar
function NPCTab:GetAllNPCs(search)    
    search = search or ""
    SMS.FetchNPCs:SendToServer({ ID=USERID, search=search })
end

function NPCTab:New(holder)
    if UI.NPCTab then return end 

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "NPCs")),
        AllNPCs = {},
        ResultCount = 0,

        SpawnedNPCs = {},
        
        AmountOptions = {1}
    }, NPCTab)
    return instance
end

function NPCTab:SetNPCs(items)
    UI.DestroyChildren(self.NPCArea)

    self.AllNPCs = items
    self.ResultCount = HLP.Count(items)

    local shownCount = HLP.Count(self.AllNPCs)

    if shownCount == 0 then
        self.NPCArea:AddText("No items found.")
        return
    end

    local maxTableWidth = 4
    local tableWidth = math.min(shownCount, maxTableWidth) 

    self.NPCArea:AddText("Showing " .. shownCount .. " items (max: 50)")

    local t = self.NPCArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.AllNPCs) do
        if i % maxTableWidth == 1 then
            row = t:AddRow()
        end
        
        local uuid = HLP.GetAttr(data, "id")
        local icon = HLP.GetAttr(data, "icon")
        if icon then
            --icon = icon:match("%((.-)%)")
            icon = "EC_Portrait_Generic"
        end
        local name = HLP.GetAttr(data, "displayName")

        if not name then
            --print("Skipping invalid entry:", uuid)
            goto continue
        end

        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local NPCItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("AddItem")

        NPCItem.OnClick = function()
            popup:Open()
        end

        local selectNPC = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb75", "Spawn"))

        selectNPC.OnClick = function()
            SMS.SpawnCharacter:SendToServer({ uuid=uuid, amount=1, data=data })

            self.SpawnedNPCs[uuid] = data
            self:GetSpawnedNPCs()
        end

        i = i + 1

        ::continue::
    end

    --print(i .. " total cells added")
end

function NPCTab:GetSpawnedNPCs()
    UI.DestroyChildren(self.SpawnedNPCsArea)

    local totalSpawned = HLP.Count(self.SpawnedNPCs)

    if totalSpawned == 0 then
        self.SpawnedNPCsArea:AddText("You haven't spawned any NPCs.")
        return
    end

    local maxTableWidth = 4
    local tableWidth = math.min(totalSpawned, maxTableWidth) 

    local header = self.SpawnedNPCsArea:AddCollapsingHeader("Spawned NPCs")

    local t = header:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.SpawnedNPCs) do
        if i % maxTableWidth == 1 then
            row = t:AddRow()
        end
        
        local uuid = HLP.GetAttr(data, "id")
        local icon = HLP.GetAttr(data, "icon")
        if icon then
            --icon = icon:match("%((.-)%)")
            icon = "EC_Portrait_Generic"
        end
        local name = HLP.GetAttr(data, "displayName")

        if not name then
            --print("Skipping invalid entry:", uuid)
            goto continue
        end

        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local NPCItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("ManageNPC")

        NPCItem.OnClick = function()
            popup:Open()
        end

        local removeNPC = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
        local enableCombat = popup:AddButton(LCL.Get("h684797ebd2ea4495b56dcc96c031bf261", "Enable Combat"))
        local disableCombat = popup:AddButton(LCL.Get("h684797ebd2ea4495b56dcc96c031bf262", "Disable Combat"))

        removeNPC.OnClick = function()
            SMS.DespawnCharacter:SendToServer({ uuid=uuid })

            self.SpawnedNPCs[uuid] = nil
            self:GetSpawnedNPCs()
        end

        enableCombat.OnClick = function()
            SMS.ManageNPC:SendToServer({ uuid=uuid,can=1,topic="combat" })
        end
        disableCombat.OnClick = function()
            SMS.ManageNPC:SendToServer({ uuid=uuid,can=0,topic="combat" })
        end

        i = i + 1

        ::continue::
    end

    --print(i .. " total cells added")
end

function NPCTab:AddNPCSearch()
    UI.DestroyChildren(self.NPCSearch)

    local sep = self.NPCSearch:AddSeparatorText(LCL.Get("hbea4aec9a88b4a34b615f347cb48d3ed1", "Search NPCs:"))

    local search = self.NPCSearch:AddInputText("", "")
    local btn = self.NPCSearch:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search"))

    btn.OnClick = function()
        local txt = search.Text 

        self:GetAllNPCs(txt)
    end
end

function NPCTab:Init()
    self.SpawnedNPCs = Ext.Vars.GetModVariables(ModuleUUID).SpawnedNPCs or {}
    self.SpawnedNPCsArea = self.Tab:AddGroup("SpawnedNPCs")

    self:GetSpawnedNPCs()

    self.NPCSearch = self.Tab:AddGroup("NPCSearch")
    self.NPCArea = self.Tab:AddGroup("AllNPCs")

    self:AddNPCSearch()

    self.AllNPCs = {}
    self:GetAllNPCs()
end

return NPCTab