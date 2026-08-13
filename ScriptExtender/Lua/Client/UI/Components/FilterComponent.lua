---@class FilterComponent
---@field Parent ExtuiGroup
---@field Config table
---@field OnChange function
---@field State table
---@field ModNameOptions table
---@field RarityOptions table
---@field ModifierListOptions table
---@field SlotOptions table
FilterComponent = {}
FilterComponent.__index = FilterComponent

function FilterComponent:New(parent, config, onChange)
    local instance = setmetatable({
        Parent = parent,
        Config = config or {},
        OnChange = onChange,
        State = {
            modName = "All",
            rarity = "All",
            modifierList = "All",
            slot = "All"
        },
        ModNameOptions = { "All" },
        RarityOptions = { "All", "Common", "Uncommon", "Rare", "VeryRare", "Legendary" },
        ModifierListOptions = { "All", "Weapon", "Armor" },
        SlotOptions = {
            "All", "Helmet", "Breast", "Gloves", "Boots", "Melee Main Weapon", 
            "Melee Offhand Weapon", "Ranged Main Weapon", "Ranged Offhand Weapon", 
            "Amulet", "Ring", "Ring2", "Underwear", "Cloak", "MusicalInstrument"
        }
    }, FilterComponent)
    return instance
end

---@param row ExtuiTableRow
---@param label string
---@param options table
---@param stateKey string
local function _CreateFilterCombo(self, row, label, options, stateKey)
    row:AddCell():AddText(label .. ":")
    local selectedIndex = 1
    for i, v in ipairs(options) do if v == self.State[stateKey] then selectedIndex = i; break end end
    local combo = row:AddCell():AddCombo("##" .. stateKey .. "Filter")
    combo.Options = options
    combo.SelectedIndex = selectedIndex - 1
    combo.OnChange = function(c)
        self.State[stateKey] = options[c.SelectedIndex + 1]
        self.OnChange()
    end
end

function FilterComponent:SetModNameOptions(modNames)
    self.ModNameOptions = modNames
    self:Draw()
end

function FilterComponent:GetState()
    return self.State
end

function FilterComponent:Draw()
    UI_Utils.DestroyChildren(self.Parent)
    self.Parent:AddSeparatorText("Filters")
    local filterTable = self.Parent:AddTable("FilterComponentTable", 8)
    filterTable.NoHostExtendX = true

    local row = filterTable:AddRow()

    if self.Config.mod then
        _CreateFilterCombo(self, row, "Mod", self.ModNameOptions, "modName")
    end

    if self.Config.modifierList then
        _CreateFilterCombo(self, row, "Type", self.ModifierListOptions, "modifierList")
    end

    if self.Config.slot then
        _CreateFilterCombo(self, row, "Slot", self.SlotOptions, "slot")
    end

    if self.Config.rarity then
        _CreateFilterCombo(self, row, "Rarity", self.RarityOptions, "rarity")
    end
end

return FilterComponent