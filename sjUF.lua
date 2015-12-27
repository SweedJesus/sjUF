-- TODO:
-- -    Move configuration code into dedicated options module

local ADDON_PATH = "Interface\\AddOns\\sjUF\\"
local PINK = "|cffff77ff[%s]|r"
local BLUE = "|cff7777ff[%s]|r"

-- Create addon module
sjUF = AceLibrary("AceAddon-2.0"):new(
"AceConsole-2.0",
"AceDebug-2.0",
"AceDB-2.0",
"AceEvent-2.0",
"FuBarPlugin-2.0")

-- RosterLib
local RL = AceLibrary("RosterLib-2.0")
-- HealComm
--local HC = AceLibrary("HealComm-1.0")
-- BetterHealComm
local BHC = AceLibrary("BetterHealComm-0.1")
-- Surface
local SF = AceLibrary("Surface-1.0")

-- Function aliases
local bitand = bit.band

-- Spell bitmasks
local DAMAGE = 0
local HEAL   = 1
local OT     = 2
local AOE    = 4
local RES    = 8

-- Group tokens
local RAID = 2
local PARTY = 1
local NONE = 0

-- ----------------------------------------------------------------------------
-- Utility functions
-- ----------------------------------------------------------------------------

local function Event(...)
    sjUF:Debug(format(PINK, event), unpack(arg))
end

-- @param a Original
-- @param b Table to fill
local function TableCopy(a, b)
    for k,v in pairs(a) do
        if (type(v) == "table") then
            Copy(a[k], b[k])
        else
            b[k] = a[k]
        end
    end
end

function TableToStringFlat(table)
    local s = "{"
    local first = true
    for k,v in pairs(table) do
        if type(v) == "table" then
            s=s..format("%s%s:%s",not first and", "or"",k,TableToStringFlat(v))
            first = false
        else
            s=s..format("%s%s:%s",not first and", "or"",k,v)
            first = false
        end
    end
    return s.."}"
end

-- Options table order iterator helper
local order_iterator = 0
local function order()
    order_iterator = order_iterator + 1
    return order_iterator
end

-- Color getter helper
local function GetColor(key)
    return sjUF.opt[key.."_r"], sjUF.opt[key.."_g"], sjUF.opt[key.."_b"], sjUF.opt[key.."_a"]
end

-- ----------------------------------------------------------------------------
-- Function generators
-- ----------------------------------------------------------------------------
-- For use in the Ace options table

local function GenericGetGenerator(key)
    return function()
        return sjUF.opt[key]
    end
end

local function GenericSetGenerator(key)
    return function(set)
        if sjUF.opt[key] ~= set then
            sjUF.opt[key] = set
            sjUF:UpdateRaidFrames()
        end
    end
end

local function ColorGetGenerator(key, use_alpha)
    local R, G, B, A = key.."_r", key.."_g", key.."_b", key.."_a"
    if sjUF.opt[A] then
        return function()
            return sjUF.opt[R], sjUF.opt[G], sjUF.opt[B], sjUF.opt[A]
        end
    else
        return function()
            return sjUF.opt[R], sjUF.opt[G], sjUF.opt[B]
        end
    end
end

local function ColorSetGenerator(key)
    local R, G, B, A = key.."_r", key.."_g", key.."_b", key.."_a"
    if sjUF.opt[A] then
        return function(r, g, b, a)
            if sjUF.opt[R] ~= r or
                sjUF.opt[G] ~= g or
                sjUF.opt[B] ~= b or
                sjUF.opt[A] ~= a then
                sjUF.opt[R], sjUF.opt[G], sjUF.opt[B], sjUF.opt[A] = r, g, b, a
                sjUF:UpdateRaidFrames()
            end
        end
    else
        return function(r, g, b)
            if sjUF.opt[R] ~= r or
                sjUF.opt[G] ~= g or
                sjUF.opt[B] ~= b then
                sjUF.opt[R], sjUF.opt[G], sjUF.opt[B] = r, g, b
                sjUF:UpdateRaidFrames()
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Unit script call-back functions
-- ----------------------------------------------------------------------------

local function UnitSetHighlight(self, set)
    if set then
        self.highlight:Show()
    else
        self.highlight:Hide()
    end
end

local function UnitOnClick()
    TargetUnit(this.unit)
end

local function UnitOnMouseDown()
    this.pushed:Show()
end

local function UnitOnMouseUp()
    this.pushed:Hide()
end

local function UnitOnEnter()
    this:SetHighlight(true)
end

local function UnitOnLeave()
    this:SetHighlight(false)
end

-- ----------------------------------------------------------------------------
-- Main Module
-- ----------------------------------------------------------------------------

-- TODO: Maybe use Surface lib instead?
-- Bars
local BAR_PATH = ADDON_PATH.."media\\bars\\"
local BAR_FLAT   = BAR_PATH.."Flat.tga"
local BAR_SMOOTH = BAR_PATH.."Smooth.tga"
local BAR_SOLID  = BAR_PATH.."Solid.tga"
sjUF.bars = {
    [BAR_FLAT]   = "Flat",
    [BAR_SMOOTH] = "Smooth",
    [BAR_SOLID]  = "Solid"
}

-- Borders
local BORDER_PATH = ADDON_PATH.."media\\borders\\"
local BORDER_ORIGINAL = BORDER_PATH.."UI-Tooltip-Border_Original.blp"
local BORDER_GRID     = BORDER_PATH.."Grid-8.tga"
sjUF.borders = {
    [BORDER_ORIGINAL] = "Tooltip-Original",
    [BORDER_GRID]     = "Tooltip-Grid"
}

-- Backgrounds
local BACKGROUND_PATH = ADDON_PATH.."media\\backgrounds\\"
local BACKGROUND_SOLID = BACKGROUND_PATH.."Solid.tga"
local BACKGROUND_WHITE = BACKGROUND_PATH.."White.tga"
sjUF.backgrounds = {
    [BACKGROUND_SOLID] = "Solid",
    [BACKGROUND_WHITE] = "White",
}

-- Energy types
local ENERGY_NONE = -1
local ENERGY_MANA = 0
local ENERGY_RAGE = 1
local ENERGY_ENERGY = 3

-- Caller codes
local UNIT_HEALTH = 0
local UNIT_AURA = 1

-- Frame references
local master, player, pet, target, tot, totot, raid

-- ----------------------------------------------------------------------------
-- Handler functions
-- ----------------------------------------------------------------------------

-- TODO: Phase out order()
function sjUF:OnInitialize()
    -- AceDB
    self.defaults = {
        -- Misc
        class_color_HUNTER_r = 0.67,
        class_color_HUNTER_g = 0.83,
        class_color_HUNTER_b = 0.45,
        class_color_WARLOCK_r = 0.58,
        class_color_WARLOCK_g = 0.51,
        class_color_WARLOCK_b = 0.79,
        class_color_PRIEST_r = 1.00,
        class_color_PRIEST_g = 1.00,
        class_color_PRIEST_b = 1.00,
        class_color_PALADIN_r = 0.96,
        class_color_PALADIN_g = 0.55,
        class_color_PALADIN_b = 0.73,
        class_color_MAGE_r = 0.41,
        class_color_MAGE_g = 0.80,
        class_color_MAGE_b = 0.94,
        class_color_ROGUE_r = 1.00,
        class_color_ROGUE_g = 0.96,
        class_color_ROGUE_b = 0.41,
        class_color_DRUID_r = 1.00,
        class_color_DRUID_g = 0.49,
        class_color_DRUID_b = 0.04,
        class_color_SHAMAN_r = 0.00,
        class_color_SHAMAN_g = 0.44,
        class_color_SHAMAN_b = 0.87,
        class_color_WARRIOR_r = 0.78,
        class_color_WARRIOR_g = 0.61,
        class_color_WARRIOR_b = 0.43,
        -- ----------
        -- Raid
        -- ----------
        -- TODO: Order these nicely
        raid_enabled = true,
        raid_locked = true,
        raid_dummy_frames = false,
        raid_use_alt_layout = false, -- false=40, true=25
        -- Styling

        raid_label_name_color_r = 0.35,
        raid_label_name_color_g = 0.35,
        raid_label_name_color_b = 0.35,
        raid_label_name_use_class_color = true,
        raid_label_name_xoff = 0,
        raid_label_name_yoff = 0,

        raid_label_health_xoff = 0,
        raid_label_health_yoff = 0,

        raid_hp_color_r = 0.35, -- GameFontDarkGraySmall text color
        raid_hp_color_g = 0.35,
        raid_hp_color_b = 0.35,
        raid_hp_use_class_color = true,

        raid_unit_status_bar_inset = 2,

        raid_status_bar_texture = BAR_FLAT,
        -- Positioning
        raid_hp_to_mp_ratio = 0.5,
        --raid_container_border = 0,
        -- Unit backdrop
        raid_unit_border_enable = true,
        raid_unit_border_texture = BORDER_GRID,
        raid_unit_border_color_r = 0.5,
        raid_unit_border_color_g = 0.5,
        raid_unit_border_color_b = 0.5,
        raid_unit_border_color_a = 1,
        raid_unit_background_enable = true,
        raid_unit_background_texture = BACKGROUND_SOLID,
        raid_unit_background_inset = 2,
        raid_unit_background_tile_size = 8,
        raid_unit_background_color_r = 1,
        raid_unit_background_color_g = 1,
        raid_unit_background_color_b = 1,
        raid_unit_background_color_a = 1,
        -- Sizing
        raid_container_width = 320,
        raid_container_height = 200,
        raid_unit_hoff = 0,
        raid_unit_voff = 0,
        -- Misc
        raid_name_char_limit = 0
    }
    self:RegisterDB("sjUF_DB")
    self:RegisterDefaults("profile", self.defaults)
    self.opt = self.db.profile
    -- AceConsole
    self.options = {
        type = "group",
        args = {
            class_colors = {
                name = "Class colors",
                desc = "Define class colors.",
                type = "group",
                args = {
                    hunter = {
                        name = "Hunter",
                        desc = "Hunter class color.",
                        type = "color",
                        get = ColorGetGenerator("class_color_HUNTER"),
                        set = ColorSetGenerator("class_color_HUNTER")
                    },
                    warlock = {
                        name = "Warlock",
                        desc = "Warlock class color.",
                        type = "color",
                        get = ColorGetGenerator("class_color_WARLOCK"),
                        set = ColorSetGenerator("class_color_WARLOCK")
                    },
                    priest = {
                        name = "Priest",
                        desc = "Priest class color.",
                        type = "color",
                        get = ColorGetGenerator("class_color_PRIEST"),
                        set = ColorSetGenerator("class_color_PRIEST")
                    },
                    paladin = {
                        name = "Paladin",
                        desc = "Paladin class color.",
                        type = "color",
                        get = ColorGetGenerator("class_color_PALADIN"),
                        set = ColorSetGenerator("class_color_PALADIN")
                    },
                    mage = {
                        name = "Mage",
                        desc = "Mage class color.",
                        type = "color",
                        get = ColorGetGenerator("class_color_MAGE"),
                        set = ColorSetGenerator("class_color_MAGE")
                    },
                    rogue = {
                        name = "Rogue",
                        desc = "Rogue class color.",
                        type = "color",
                        get = ColorGetGenerator("class_color_ROGUE"),
                        set = ColorSetGenerator("class_color_ROGUE")
                    },
                    druid = {
                        name = "Druid",
                        desc = "Druid class color.",
                        type = "color",
                        get = ColorGetGenerator("class_color_DRUID"),
                        set = ColorSetGenerator("class_color_DRUID")
                    },
                    shaman = {
                        name = "Shaman",
                        desc = "Shaman class color.",
                        type = "color",
                        get = ColorGetGenerator("class_color_SHAMAN"),
                        set = ColorSetGenerator("class_color_SHAMAN")
                    },
                    warrior = {
                        name = "Warrior",
                        desc = "Warrior class color.",
                        type = "color",
                        get = ColorGetGenerator("class_color_WARRIOR"),
                        set = ColorSetGenerator("class_color_WARRIOR")
                    }
                }
            },
            raid = {
                name = "Raid",
                desc = "Raid frames configuration.",
                type = "group",
                args = {
                    set_enabled = {
                        order = order(),
                        name = "Enable",
                        desc = "Toggle the raid frames module (container).",
                        type = "toggle",
                        get = function()
                            return self.opt.raid_enabled
                        end,
                        set = function(set)
                            self.opt.raid_enabled = set
                            if set then
                                self.raid:Show()
                                self:UpdateRaidFrames()
                            else
                                self.raid:Hide()
                            end
                        end
                    },
                    set_locked = {
                        order = order(),
                        name = "Lock",
                        desc = "Toggle the raid frames lock.",
                        type = "toggle",
                        get = function()
                            return self.opt.raid_locked
                        end,
                        set = function(set)
                            self.opt.raid_locked = set
                            if set then
                                self.raid.anchor:Hide()
                            else
                                self.raid.anchor:Show()
                            end
                        end
                    },
                    dummy_frames = {
                        order = order(),
                        name = "Show dummy frames",
                        desc = "Toggle showing dummy raid units.",
                        type = "toggle",
                        get = GenericGetGenerator("raid_dummy_frames"),
                        set = GenericSetGenerator("raid_dummy_frames")
                    },
                    use_alt_layout = {
                        order = order(),
                        name = "Use alternative layout",
                        desc = "Toggle using the alternative 25-man raid layout.",
                        type = "toggle",
                        get = GenericGetGenerator("raid_use_alt_layout"),
                        set = GenericSetGenerator("raid_use_alt_layout"),
                        map = { [false] = "40 man", [true] = "25 man" }
                    },
                    reset_position = {
                        order = order(),
                        name = "Reset position",
                        desc = "Reset the raid frames container position.",
                        type = "execute",
                        func = function()
                            self.raid:ClearAllPoints()
                            self.raid:SetPoint("CENTER", UIParent, "CENTER")
                        end
                    },
                    reset_colors = {
                        order = order(),
                        name = "Reset colors",
                        desc = "Reset all custom colors to addon defaults.",
                        type = "execute",
                        func = function()
                        end
                    },
                    -----------------------------------------------------------
                    label_name_header = {
                        order = order(),
                        name = "Name",
                        type = "header"
                    },
                    label_name_color = {
                        order = order(),
                        name = "Color",
                        desc = "Set the raid unit name color.",
                        type = "color",
                        get = ColorGetGenerator("raid_name_color"),
                        set = ColorSetGenerator("raid_name_color")
                    },
                    label_name_use_class_color = {
                        order = order(),
                        name = "Use class color",
                        desc = "Toggle using class colors for names.",
                        type = "toggle",
                        get = GenericGetGenerator("raid_label_name_use_class_color"),
                        set = GenericSetGenerator("raid_label_name_use_class_color")
                    },
                    label_name_char_limit = {
                        order = order(),
                        name = "Name character limit",
                        desc = "Set the max number of characters to display for names.",
                        type = "range",
                        min = 0,
                        max = 20,
                        step = 1,
                        get = GenericGetGenerator("raid_name_char_limit"),
                        set = GenericSetGenerator("raid_name_char_limit")
                    },
                    label_name_xoff = {
                        order = order(),
                        name = "Horizontal offset",
                        desc = "Set the raid unit name label horizontal offset.",
                        type = "range",
                        min = -20,
                        max = 20,
                        step = 0.5,
                        get = GenericGetGenerator("raid_label_name_xoff"),
                        set = GenericSetGenerator("raid_label_name_xoff")
                    },
                    label_name_yoff = {
                        order = order(),
                        name = "Vertical offset",
                        desc = "Set the raid unit name label vertical offset.",
                        type = "range",
                        min = -20,
                        max = 20,
                        step = 0.5,
                        get = GenericGetGenerator("raid_label_name_yoff"),
                        set = GenericSetGenerator("raid_label_name_yoff")
                    },
                    -----------------------------------------------------------
                    label_health_header = {
                        order = order(),
                        name = "Health label",
                        type = "header"
                    },
                    label_health_xoff = {
                        order = order(),
                        name = "Horizontal offset",
                        desc = "Set the raid unit health label horizontal offset.",
                        type = "range",
                        min = -20,
                        max = 20,
                        step = 0.5,
                        get = GenericGetGenerator("raid_label_health_xoff"),
                        set = GenericSetGenerator("raid_label_health_xoff")
                    },
                    label_health_yoff = {
                        order = order(),
                        name = "Vertical offset",
                        desc = "Set the raid unit health label vertical offset.",
                        type = "range",
                        min = -20,
                        max = 20,
                        step = 0.5,
                        get = GenericGetGenerator("raid_label_health_yoff"),
                        set = GenericSetGenerator("raid_label_health_yoff")
                    },
                    -----------------------------------------------------------
                    status_bars_header = {
                        order = order(),
                        name = "Status bars",
                        type = "header",
                    },
                    hp_to_mp_ratio = {
                        order = order(),
                        name = "HP to MP ratio",
                        desc = "Set the HP bar to MP bar height ratio.",
                        type = "range",
                        min = 0,
                        max = 1,
                        step = 0.05,
                        isPercent = true,
                        get = GenericGetGenerator("raid_hp_to_mp_ratio"),
                        set = GenericSetGenerator("raid_hp_to_mp_ratio")
                    },
                    status_bar_inset = {
                        order = order(),
                        name = "Status bar inset",
                        desc = "Set the raid unit status bar inset.",
                        type = "range",
                        min = -16,
                        max = 16,
                        step = 0.5,
                        get = GenericGetGenerator("raid_unit_status_bar_inset"),
                        set = GenericSetGenerator("raid_unit_status_bar_inset")
                    },
                    hp_color = {
                        order = order(),
                        name = "Health color",
                        desc = "Set the raid unit health bar color.",
                        type = "color",
                        get = ColorGetGenerator("raid_hp_color"),
                        set = ColorSetGenerator("raid_hp_color")
                    },
                    hp_use_class_color = {
                        order = order(),
                        name = "Use class color",
                        desc = "Toggle using class colors for HP bars.",
                        type = "toggle",
                        get = GenericGetGenerator("raid_hp_use_class_color"),
                        set = GenericSetGenerator("raid_hp_use_class_color")
                    },
                    -----------------------------------------------------------
                    unit_header = {
                        order = order(),
                        name = "Unit",
                        type = "header"
                    },
                    unit_border_enable = {
                        order = order(),
                        name = "Border enable",
                        desc = "Toggle the raid unit border.",
                        type = "toggle",
                        get = GenericGetGenerator("raid_unit_border_enable"),
                        set = GenericSetGenerator("raid_unit_border_enable")
                    },
                    unit_border_texture = {
                        order = order(),
                        name = "Border texture",
                        desc = "Set the raid unit border texture.",
                        type = "text",
                        validate = self.borders,
                        get = GenericGetGenerator("raid_unit_border_texture"),
                        set = GenericSetGenerator("raid_unit_border_texture")
                    },
                    unit_border_size = {
                        order = order(),
                        name = "Border size",
                        desc = "Set the raid unit border size.",
                        type = "range",
                        min = 1,
                        max = 32,
                        step = 1,
                        get = GenericGetGenerator("raid_unit_border_size"),
                        set = GenericSetGenerator("raid_unit_border_size")
                    },
                    unit_border_color = {
                        order = order(),
                        name = "Border color",
                        desc = "Set the raid unit border color.",
                        type = "color",
                        hasAlpha = true,
                        get = ColorGetGenerator("raid_unit_border_color"),
                        set = ColorSetGenerator("raid_unit_border_color")
                    },
                    unit_background_enable = {
                        order = order(),
                        name = "Background enable",
                        desc = "Toggle the raid unit background.",
                        type = "toggle",
                        get = GenericGetGenerator("raid_unit_background_enable"),
                        set = GenericSetGenerator("raid_unit_background_enable")
                    },
                    unit_background_texture = {
                        order = order(),
                        name = "Background texture",
                        desc = "Set the raid unit background texture.",
                        type = "text",
                        validate = self.backgrounds,
                        get = GenericGetGenerator("raid_unit_background_texture"),
                        set = GenericSetGenerator("raid_unit_background_texture")
                    },
                    unit_background_color = {
                        order = order(),
                        name = "Background color",
                        desc = "Set the raid unit background color.",
                        type = "color",
                        hasAlpha = true,
                        get = ColorGetGenerator("raid_unit_background_color"),
                        set = ColorSetGenerator("raid_unit_background_color")
                    },
                    unit_background_inset = {
                        order = order(),
                        name = "Background inset",
                        desc = "Set the raid unit background inset.",
                        type = "range",
                        min = -16,
                        max = 16,
                        step = 0.5,
                        get = GenericGetGenerator("raid_unit_background_inset"),
                        set = GenericSetGenerator("raid_unit_background_inset")
                    },
                    unit_hoff = {
                        order = order(),
                        name = "Horizontal spacing",
                        desc = "Set raid unit horizontal spacing.",
                        type = "range",
                        min = -10,
                        max = 10,
                        step = 0.5,
                        bigStep = 1,
                        get = GenericGetGenerator("raid_unit_hoff"),
                        set = GenericSetGenerator("raid_unit_hoff")
                    },
                    unit_voff = {
                        order = order(),
                        name = "Vertical spacing",
                        desc = "Set raid unit vertical spacing.",
                        type = "range",
                        min = -10,
                        max = 10,
                        step = 0.5,
                        bigStep = 1,
                        get = GenericGetGenerator("raid_unit_voff"),
                        set = GenericSetGenerator("raid_unit_voff")
                    },
                    -----------------------------------------------------------
                    container_header = {
                        order = order(),
                        name = "Container",
                        type = "header"
                    },
                    container_width = {
                        order = order(),
                        name = "Width",
                        desc = "Set the raid frame container width.",
                        type = "range",
                        min = 0,
                        max = 600,
                        step = 5,
                        bigStep = 20,
                        get = GenericGetGenerator("raid_container_width"),
                        set = GenericSetGenerator("raid_container_width")
                    },
                    container_height = {
                        order = order(),
                        name = "Height",
                        desc = "Set the raid frame container height.",
                        type = "range",
                        min = 0,
                        max = 600,
                        step = 5,
                        bigStep = 20,
                        get = GenericGetGenerator("raid_container_height"),
                        set = GenericSetGenerator("raid_container_height")
                    }
                }
            }
        }
    }
    self:RegisterChatCommand({"/sjUnitFrames", "/sjUF"}, self.options)
    -- AceDebug
    self:SetDebugging(self.opt.debugging)
    -- FuBar plugin
    self.defaultMinimapPosition = 270
    self.cannotDetachTooltip = true
    self.OnMenuRequest = self.options
    self.hasIcon = true
    self:SetIcon("Interface\\Icons\\Spell_Holy_PowerInfusion")
    -- Initialize frames
    self:InitFrames()
end

function sjUF:SetDebugging(set)
    self.opt.debugging = set
    self.debugging = set
end

-- ----------------------------------------------------------------------------
-- Event handlers
-- ----------------------------------------------------------------------------

function sjUF:OnEnable()
    --Event()
    -- Events
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")

    self:RegisterEvent("UNIT_HEALTH", "OnUnitHealth")
    self:RegisterEvent("UNIT_MAXHEALTH", "OnUnitHealth")
    self:RegisterEvent("UNIT_MANA", "OnUnitMana")
    self:RegisterEvent("UNIT_MAXMANA", "OnUnitMana")
    self:RegisterEvent("UNIT_AURA", "OnUnitAura")
    --self:RegisterEvent("UNIT_DISPLAYPOWER")

    --self:RegisterEvent("SPELLCAST_START")
    --self:RegisterEvent("SPELLCAST_INTERRUPTED")
    --self:RegisterEvent("SPELLCAST_FAILED")
    --self:RegisterEvent("SPELLCAST_DELAYED")
    --self:RegisterEvent("SPELLCAST_STOP")

    --self:RegisterEvent("HealComm_Healupdate")
    --self:RegisterEvent("HealComm_Hotupdate")
    --self:RegisterEvent("HealComm_Resupdate")

    self:RegisterEvent("BetterHealComm_Start")
    self:RegisterEvent("BetterHealComm_Stop")

    self:RegisterEvent("RosterLib_RosterChanged")
    --self:RegisterEvent("RAID_ROSTER_UPDATE",    "ScanFullRoster")
    --self:RegisterEvent("PARTY_MEMBERS_CHANGED", "OnRosterChange")

    --
    if self.opt.raid_enabled then
        self.raid:Show()
    else
        self.raid:Hide()
    end
    if self.opt.raid_locked then
        self.raid.anchor:Hide()
    else
        self.raid.anchor:Show()
    end
end

function sjUF:OnDisable()
    --Event()
    self.raid:Hide()
end

function sjUF:OnPlayerEnteringWorld()
    --Event()
    self:CheckGroupStatus()
    self:UpdateRaidFrames()
end

function sjUF:RosterLib_RosterChanged(table)
    --Event(TableToStringFlat(table))
    if self.group_status ~= self:CheckGroupStatus() then
        self:UpdateRaidFrames()
    else
        self:UpdateRaidFrameUnitIDs()
    end
    for k,v in pairs(table) do
        local old_f = self.raid_frames[v.oldunitid]
        if old_f then
            self:UpdateRaidFrameClassStyle(old_f)
            self:UpdateRaidFramePosition(old_f)
            self.raid_frames_by_name[v.oldname] = nil
            old_f.name = nil
            old_f.enabled = false
        end
    end
    for k,v in pairs(table) do
        local new_f = self.raid_frames[v.unitid]
        if new_f then
            self:UpdateRaidFrameClassStyle(new_f)
            self:UpdateRaidFramePosition(new_f)
            self.raid_frames_by_name[v.name] = new_f
            new_f.name = v.name
            new_f.enabled = true
            self:UpdateRaidFrameHealth(new_f)
        end
    end
end

function sjUF:OnUnitHealth(unitID)
    --Event(unitID)
    local f = self.raid_frames[unitID]
    if f then
        self:UpdateRaidFrameHealth(f)
    end
end

function sjUF:OnUnitMana(unitID)
    --Event(unitID)
    local f = self.raid_frames[unitID]
    if f then
        self:UpdateRaidFrameMana(f)
    end
end

function sjUF:OnUnitAura(unitID)
    --Event(unitID)
    local f = self.raid_frames[unitID]
    if f then
        self:UpdateRaidFrameBuffs(f)
    end
end

--function sjUF:UNIT_DISPLAYPOWER(unitID)
    --Event(unitID)
    --UnitFrame_UpdateManaType(self.raid_frames[unitID])
--end

local targets = {}

function sjUF:BetterHealComm_Start(from, to, type, amount)
    --self:Debug("|cffff77ff[BetterHealComm_Start]|r",from,to,type,amount)
    if bitand(type, AOE) == AOE then
        targets[1] = self.raid_frames_by_name[from]
        if self:CheckGroupStatus() == RAID then
            local g = floor(targets[1]:GetID()/5)
            for i=1,5 do
                targets[i] = self.raid_frames[i+g*5]
            end
        else
            for i=2,5 do
                targets[i] = self.raid_frames[i]
            end
        end
        for i=1,5 do
            self:UpdateRaidFrameHealth(targets[i], amount)
        end
    else
        local f = self.raid_frames_by_name[to]
        self:UpdateRaidFrameHealth(f, amount)
    end
end

function sjUF:BetterHealComm_Stop(from, to, type, amount)
    --self:Debug("|cffff77ffBetterHealComm_Stop]|r",from,to,type,amount)
    if bitand(type, AOE) == AOE then
        targets[1] = self.raid_frames_by_name[from]
        if self:CheckGroupStatus() == RAID then
            local g = floor(targets[1]:GetID()/5)
            for i=1,5 do
                targets[i] = self.raid_frames[i+g*5]
            end
        else
            for i=2,5 do
                targets[i] = self.raid_frames[i]
            end
        end
        for i=1,5 do
            self:UpdateRaidFrameHealth(targets[i], -amount)
        end
    else
        local f = self.raid_frames_by_name[to]
        self:UpdateRaidFrameHealth(f, -amount)
    end
end

-- ----------------------------------------------------------------------------
--
-- ----------------------------------------------------------------------------

function sjUF:VersionScan()
    local VERSION = "test"
    local world_channel = GetChannelName("World")
    if world_channel then
        SendAddonMessage("sjUF", VERSION, "CHANNEL", world_channel)
    else
        SendAddonMessage("sjUF", VERSION, "GUILD")
    end
end

--- Updates and returns player group status.
-- @return 0 = no group, 1 = party, 2 = raid
function sjUF:CheckGroupStatus()
    self.group_status = UnitInRaid("player") and RAID or UnitInParty("player") and PARTY or NONE
    return self.group_status
end

function sjUF:InitFrames()
    -- ----- RAID
    -- Container
    if not self.raid then
        self.raid = CreateFrame("Frame", "sjUF_Raid", UIParent)
    end
    raid = self.raid
    raid:SetClampedToScreen(true)
    raid:SetMovable(true)
    if not raid.anchor then
        raid.anchor = CreateFrame("Frame", "sjUF_RaidAnchor", raid)
    end
    -- Draggable anchor
    raid.anchor:SetFrameStrata("BACKGROUND")
    raid.anchor:SetParent(raid)
    raid.anchor:SetPoint("TOPLEFT", -5, 5)
    raid.anchor:SetPoint("BOTTOMRIGHT", 5, -5)
    if not raid.anchor.background then
        raid.anchor.background = raid.anchor:CreateTexture(nil, "BACKGROUND")
    end
    raid.anchor.background:SetTexture(0.5, 0.5, 0.5, 0.5)
    raid.anchor.background:SetAllPoints()
    raid.anchor:EnableMouse(true)
    raid.anchor:RegisterForDrag("LeftButton")
    raid.anchor:SetScript("OnDragStart", function()
        raid:StartMoving()
    end)
    raid.anchor:SetScript("OnDragStop", function()
        raid:StopMovingOrSizing()
    end)
    -- Unit frames
    self.raid_frames = self.raid_frames or {}
    self.raid_frames_by_name = self.raid_frames_by_name or {}
    for i = 1, 40 do
        self.raid_frames[i] = self.raid_frames[i] or CreateFrame("Button", "sjUF_Raid"..i, raid)
        -- Identifiers
        local f = self.raid_frames[i]
        f:Hide()
        if i == 1 then
            self.raid_frames["player"] = f
        elseif i <= 5 then
            self.raid_frames["party"..i-1] = f
        end
        self.raid_frames["raid"..i] = f
        f:SetID(i)
        f.unit = "raid"..i
        f.order = i
        f.enabled = false
        f.incoming = 0
        -- Inset frame
        f.inset = CreateFrame("Frame", "sjUF_Raid"..i.."InsetLayer", f)
        -- Overlay frame
        f.overlay = CreateFrame("Frame", "sjUF_Raid"..i.."OverlayLayer", f)
        f.overlay:SetAllPoints()
        f.overlay:SetFrameLevel(5)
        -- Text frame
        f.text = CreateFrame("Frame", "sjUF_Raid"..i.."TextLayer", f)
        f.text:SetAllPoints()
        f.text:SetFrameLevel(4)
        -- Highlight texture
        f.highlight = f.overlay:CreateTexture("sjUF_Raid"..i.."HighlightTexture")
        f.highlight:SetPoint("TOPLEFT", f.inset, "TOPLEFT", 0, 0)
        f.highlight:SetPoint("BOTTOMRIGHT", f.inset, "BOTTOMRIGHT", 0, 0)
        f.highlight:SetAlpha(0.3)
        f.highlight:SetBlendMode("ADD")
        f.highlight:Hide()
        --f.highlight:Hide()
        -- Pushed texture
        f.pushed = f.overlay:CreateTexture("sjUF_Raid"..i.."PushedTexture")
        f.pushed:SetPoint("TOPLEFT", f.inset, "TOPLEFT", 0, 0)
        f.pushed:SetPoint("BOTTOMRIGHT", f.inset, "BOTTOMRIGHT", 0, 0)
        f.pushed:SetAlpha(0.6)
        f.pushed:SetBlendMode("ADD")
        f.pushed:Hide()
        -- Name label
        f.label_name = f.text:CreateFontString("sjUF_Raid"..i.."NameLabel")
        f.label_name:SetFontObject(GameFontDarkGraySmall)
        f.label_name:SetPoint("CENTER", 0, 0)
        -- Health label
        f.label_health = f.text:CreateFontString("sjUF_Raid"..i.."HealthLabel")
        f.label_health:SetFontObject(GameFontDarkGraySmall)
        f.label_health:SetPoint("CENTER",
        self.opt.raid_label_health_xoff, self.opt.raid_label_health_yoff)
        f.label_health:SetText("TEST")
        -- Health bar
        f.bar_health = CreateFrame("StatusBar", "sjUF_Raid"..i.."HealthBar", f.inset)
        f.bar_health:SetPoint("TOP", 0, 0)
        f.bar_health:SetMinMaxValues(0, 1)
        f.bar_health:SetFrameLevel(3)
        -- Energy bar
        f.bar_energy = CreateFrame("StatusBar", "sjUF_Raid"..i.."EnergyBar", f.inset)
        f.bar_energy:SetPoint("BOTTOM", 0, 0)
        f.bar_energy:SetMinMaxValues(0, 1)
        f.bar_energy:SetFrameLevel(3)
        f.manabar = f.bar_energy
        f.energy_type = ENERGY_NONE
        -- Incoming heal
        f.bar_incoming = CreateFrame("StatusBar", "sjUF_Raid"..i.."IncomingBar", f.inset)
        f.bar_incoming:SetPoint("TOP", 0, 0)
        f.bar_incoming:SetMinMaxValues(0, 1)
        f.bar_incoming:SetFrameLevel(2)
        -- Over heal
        f.bar_overheal = CreateFrame("StatusBar", "sjUF_Raid"..i.."OverhealBar", f.inset)
        f.bar_overheal:SetPoint("TOP", 0, 0)
        f.bar_overheal:SetMinMaxValues(0, 1)
        f.bar_overheal:SetFrameLevel(4)
        -- Scripts
        f.SetHighlight = UnitSetHighlight
        f:SetScript("OnClick", UnitOnClick)
        f:SetScript("OnMouseDown", UnitOnMouseDown)
        f:SetScript("OnMouseUp", UnitOnMouseUp)
        f:SetScript("OnEnter", UnitOnEnter)
        f:SetScript("OnLeave", UnitOnLeave)
    end
end

-- Update all raid frame components
function sjUF:UpdateRaidFrames()
    self:UpdateRaidFrameUnitIDs()
    self:UpdateRaidFrameDimensions()
    self:UpdateRaidFramePositions()
    self:UpdateRaidFrameUnitStyles()
end

-- Update raid frame positions
function sjUF:UpdateRaidFrameDimensions()
    local group_status = self.opt.raid_dummy_frames and RAID or self.group_status
    -- Container
    self.raid:SetWidth(self.opt.raid_container_width)
    self.raid:SetHeight(self.opt.raid_container_height)
    -- Units
    self.units_per_row = group_status == RAID and not self.opt.raid_use_alt_layout and 8 or 5
    self.units_per_col = 5
    self.raid_unit_width =
    (self.opt.raid_container_width-(self.units_per_row-1)*self.opt.raid_unit_hoff)/self.units_per_row
    self.raid_unit_height =
    (self.opt.raid_container_height-(self.units_per_col-1)*self.opt.raid_unit_voff)/self.units_per_col
    self.raid_unit_inset_width = self.raid_unit_width-2*self.opt.raid_unit_status_bar_inset
    self.raid_unit_inset_height = self.raid_unit_height-2*self.opt.raid_unit_status_bar_inset
    for i,f in ipairs(self.raid_frames) do
        f:SetWidth(self.raid_unit_width)
        f:SetHeight(self.raid_unit_height)
    end
end

function sjUF:UpdateRaidFramePositions()
    for i,f in ipairs(self.raid_frames) do
        self:UpdateRaidFramePosition(f)
    end
end

function sjUF:UpdateRaidFramePosition(f)
    if (not self.opt.raid_use_alt_layout or f:GetID() <= 25) and
        self.opt.raid_dummy_frames or UnitExists(f.unit) then
        --self:Debug(BLUE, "URFP", "|cffbbbbffSHOW "..f.unit.."|r ")
        f:Show()
        local x = mod(f.order-1, self.units_per_row)
        local y = floor((f.order-1)/self.units_per_row)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT",
        x*self.raid_unit_width+x*self.opt.raid_unit_hoff,
        y*self.raid_unit_height+y*self.opt.raid_unit_voff)
    else
        --self:Debug(BLUE, "URFP", "|cffffbbbbHIDE "..f.unit.."|r")
        f:Hide()
    end
end

-- Update raid frame styles
function sjUF:UpdateRaidFrameUnitStyles()
    -- Update components
    self.raid_unit_backdrop = self.raid_unit_backdrop or { tile = true, insets = {} }
    if self.opt.raid_unit_border_enable then
        self.raid_unit_backdrop.edgeFile      = self.opt.raid_unit_border_texture
        self.raid_unit_backdrop.edgeSize      = self.opt.raid_unit_border_size
    else
        self.raid_unit_backdrop.edgeFile = nil
    end
    if self.opt.raid_unit_background_enable then
        self.raid_unit_backdrop.bgFile   = self.opt.raid_unit_background_texture
        self.raid_unit_backdrop.tileSize = self.opt.raid_unit_background_tile_size
        self.raid_unit_backdrop.insets.left   = self.opt.raid_unit_background_inset
        self.raid_unit_backdrop.insets.right  = self.opt.raid_unit_background_inset
        self.raid_unit_backdrop.insets.top    = self.opt.raid_unit_background_inset
        self.raid_unit_backdrop.insets.bottom = self.opt.raid_unit_background_inset
    else
        self.raid_unit_backdrop.bgFile = nil
    end
    -- Update raid units
    local inset = self.opt.raid_unit_status_bar_inset
    local scale = self.opt.raid_hp_to_mp_ratio
    local width = self.raid_unit_inset_width
    local height = self.raid_unit_inset_height
    for i,f in ipairs(self.raid_frames) do
        local _, class = UnitClass(f.unit)
        f:SetBackdrop(self.raid_unit_backdrop)
        f:SetBackdropColor(GetColor("raid_unit_background_color"))
        f:SetBackdropBorderColor(GetColor("raid_unit_border_color"))
        -- Inset frame
        f.inset:SetPoint("TOPLEFT", inset, -inset)
        f.inset:SetPoint("BOTTOMRIGHT", -inset, inset)
        -- Highlight texture
        f.highlight:SetTexture(ADDON_PATH.."media\\bars\\Highlight.tga")
        -- Pushed texture
        f.pushed:SetTexture(ADDON_PATH.."media\\bars\\Highlight.tga")
        -- Name label
        f.label_name:SetPoint("CENTER",
        self.opt.raid_label_name_xoff,
        self.opt.raid_label_name_yoff)
        -- Health label
        f.label_health:SetPoint("CENTER",
        self.opt.raid_label_health_xoff,
        self.opt.raid_label_health_yoff)
        -- Health bar
        if scale == 0 then
            f.bar_health:Hide()
        else
            f.bar_health:Show()
            f.bar_health:SetWidth(width)
            f.bar_health:SetHeight(height*scale)
            f.bar_health:SetStatusBarTexture(self.opt.raid_status_bar_texture)
        end
        -- Energy bar
        if scale == 1 then
            f.bar_energy:Hide()
        else
            f.bar_energy:Show()
            f.bar_energy:SetWidth(width)
            f.bar_energy:SetHeight(height*(1-scale))
            f.bar_energy:SetStatusBarTexture(self.opt.raid_status_bar_texture)
        end
        -- Incoming heal
        f.bar_incoming:SetWidth(width)
        f.bar_incoming:SetHeight(height*scale)
        f.bar_incoming:SetStatusBarTexture(self.opt.raid_status_bar_texture)
        f.bar_incoming:SetStatusBarColor(0, 1, 0)
        f.bar_incoming:SetAlpha(0.5)
        -- Over heal
        f.bar_overheal:SetWidth(width)
        f.bar_overheal:SetHeight(2)
        f.bar_overheal:SetStatusBarTexture(self.opt.raid_status_bar_texture)
        f.bar_overheal:SetStatusBarColor(0, 1, 0)

        self:UpdateRaidFrameClassStyle(f)
    end
end

function sjUF:UpdateRaidFrameClassStyle(f)
    local _, class = UnitClass(f.unit)
    -- Name
    if self.opt.raid_label_name_use_class_color and class then
        f.label_name:SetTextColor(GetColor("class_color_"..class))
    else
        f.label_name:SetTextColor(GetColor("raid_name_color"))
    end
    if self.opt.raid_name_char_limit == 0 then
        f.label_name:SetText(UnitName(f.unit) or f.unit)
    else
        f.label_name:SetText(strsub(UnitName(f.unit) or f.unit, 0, self.opt.raid_name_char_limit))
    end
    -- Health bar
    if self.opt.raid_hp_use_class_color and class then
        f.bar_health:SetStatusBarColor(GetColor("class_color_"..class))
    else
        f.bar_health:SetStatusBarColor(GetColor("raid_hp_color"))
    end
    -- Energy bar
    UnitFrame_UpdateManaType(f)
    --f.bar_energy:SetStatusBarColor(GetColor(f.energy_type))
end

-- Update raid frame group 1 member unit ID's
function sjUF:UpdateRaidFrameUnitIDs()
    for i=1,5 do
        local f = self.raid_frames[i]
        if self.group_status == RAID then
            f.unit = "raid"..i
        else
            f.unit = i == 1 and "player" or "party"..(i-1)
        end
        self:UpdateRaidFrameClassStyle(f)
    end
end

function sjUF:UpdateRaidFrameHealth(f, delta_incoming)
    if f.enabled then
        f.incoming = f.incoming + (delta_incoming or 0)
        local current = UnitHealth(f.unit)
        local max = UnitHealthMax(f.unit)
        local incoming = f.incoming + current
        local overheal = (incoming > max and f.incoming) or 0
        f.bar_health:SetValue(current/max)
        f.bar_incoming:SetValue(incoming/max)
        f.bar_overheal:SetValue(overheal/max)

        local g = (1-overheal/max)
        f.bar_overheal:SetStatusBarColor(1, g, 0)
        f.label_health:SetText(format("+%s", f.incoming))
    end
end

function sjUF:UpdateRaidFrameMana(f)
    --self:Debug(format(BLUE,"UpdateRaidFrameMana"),f.unit,f.name)
    local current = UnitMana(f.unit)
    local max = UnitManaMax(f.unit)
    f.bar_energy:SetValue(current/max)
end

function sjUF:UpdateRaidFrameBuffs(f)
end
