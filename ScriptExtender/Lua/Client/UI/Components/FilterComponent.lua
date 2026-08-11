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
        row:AddCell():AddText("Mod:")
        local selectedIndex = 1
        for i, v in ipairs(self.ModNameOptions) do if v == self.State.modName then selectedIndex = i; break end end
        local combo = row:AddCell():AddCombo("##ModNameFilter")
        combo.Options = self.ModNameOptions
        combo.SelectedIndex = selectedIndex - 1
        combo.OnChange = function(c)
            self.State.modName = self.ModNameOptions[c.SelectedIndex + 1]
            self.OnChange()
        end
    end

    if self.Config.modifierList then
        row:AddCell():AddText("Type:")
        local selectedIndex = 1
        for i, v in ipairs(self.ModifierListOptions) do if v == self.State.modifierList then selectedIndex = i; break end end
        local combo = row:AddCell():AddCombo("##ModifierListFilter")
        combo.Options = self.ModifierListOptions
        combo.SelectedIndex = selectedIndex - 1
        combo.OnChange = function(c)
            self.State.modifierList = self.ModifierListOptions[c.SelectedIndex + 1]
            self.OnChange()
        end
    end

    if self.Config.slot then
        row:AddCell():AddText("Slot:")
        local selectedIndex = 1
        for i, v in ipairs(self.SlotOptions) do if v == self.State.slot then selectedIndex = i; break end end
        local combo = row:AddCell():AddCombo("##SlotFilter")
        combo.Options = self.SlotOptions
        combo.SelectedIndex = selectedIndex - 1
        combo.OnChange = function(c)
            self.State.slot = self.SlotOptions[c.SelectedIndex + 1]
            self.OnChange()
        end
    end

    if self.Config.rarity then
        row:AddCell():AddText("Rarity:")
        local selectedIndex = 1
        for i, v in ipairs(self.RarityOptions) do if v == self.State.rarity then selectedIndex = i; break end end
        local combo = row:AddCell():AddCombo("##RarityFilter")
        combo.Options = self.RarityOptions
        combo.SelectedIndex = selectedIndex - 1
        combo.OnChange = function(c)
            self.State.rarity = self.RarityOptions[c.SelectedIndex + 1]
            self.OnChange()
        end
    end
end

return FilterComponent