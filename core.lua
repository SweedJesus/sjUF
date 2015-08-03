-- TODO:
-- Add party and other frames
-- Add power bars of all types to allow showing multiple (if say it's a druid)
-- Buffs to track:
--      Arcane Power/Power Infusion

-- Create addon module
sjUF = AceLibrary("AceAddon-2.0"):new(
    "AceConsole-2.0",
    "AceDB-2.0",
    "AceEvent-2.0",
    "FuBarPlugin-2.0")

-- Media
local font_myriad        = "Interface\\AddOns\\sjUF\\media\\fonts\\Myriad.ttf"
local bar_flat           = "Interface\\AddOns\\sjUF\\media\\textures\\Flat"
local bar_solid          = "Interface\\AddOns\\sjUF\\media\\textures\\Solid"
local background_tooltip = "Interface\\Tooltips\\UI-Tooltip-Background"
local border_tooltip     = "Interface\\Tooltips\\UI-Tooltip-Border"

--- Ace addon OnInitialize handler.
function sjUF:OnInitialize()
    -- FuBar icon (minimap)
    self.defaultMinimapPosition = 0
    self.cannotDetachTooltip = true
    self.OnMenuRequest = self.options
    self.hasIcon = true
    self:SetIcon("Interface\\Icons\\Spell_Holy_PowerInfusion")

    -- Initialize variables
    self:InitVariables()

    -- Saved variables
    self:RegisterDB("sjUF_DB")
    -- Defaults
    self:RegisterDefaults("profile", {
        dummy_units = true,
        power_colors = {
            mana      = { r = 0.18, g = 0.45, b = 0.75 },
            rage      = { r = 0.89, g = 0.18, b = 0.29 },
            focus     = { r = 1.00, g = 0.70, b = 0.00 },
            energy    = { r = 1.00, g = 1.00, b = 0.13 },
            happiness = { r = 0.00, g = 1.00, b = 1.00 }
        },
        raid = {
            -- Layout
            width = 40,
            height = 30,
            units_per_row = 8,
            xoffset = 5,
            yoffset = 5,
            -- Media
            background = background_tooltip,
            border = border_tooltip,
            -- HP bar
            hp_bar_texture = bar_flat,
            hp_bar_class_color = true,
            hp_bar_height_weight = 11,
            -- MP bar
            mp_bar_texture = bar_flat,
            mp_bar_height_weight = 1,
            -- Name text
            name_enable = true,
            name_xoffset = 2,
            name_yoffset = -2,
            name_font = font_myriad,
            name_font_size = 10,
            name_hjust = "LEFT",
            name_short = true,
            name_short_chars = 3,
            -- HP text
            hp_text_enable = true,
            hp_text_xoffset = 2,
            hp_text_yoffset = -14,
            hp_text_font = font_myriad,
            hp_text_font_size = 8,
            hp_text_hjust = "CENTER",
            -- MP text
            mp_text_enable = false,
            mp_text_xoffset = 2,
            mp_text_yoffset = -16,
            mp_text_font = font_myriad,
            mp_text_font_size = 8,
            mp_text_hjust = "CENTER"
        }
    })
    self.opt = self.db.profile

    -- Chat command
    self:RegisterChatCommand({"/sjuf"}, self.options)

    -- Master frame
    self.master = CreateFrame("Frame", "sjUF", UIParent)
    self.master.background = self.master:CreateTexture(nil, "BACKGROUND")
    self.master.background:SetTexture(1,0,0.9,1)

    -- Create raid frames
    for i = 1, MAX_RAID_MEMBERS do
        self:CreateUnitFrame("raid", i)
    end

    -- Update everything
    self:UpdateRaidFrames()
end

--- Ace addon OnEnable handler.
function sjUF:OnEnable()
    self:UpdateRaidUnits()

    self.master:Show()
end

--- Ace addon OnDisable handler
function sjUF:OnDisable()
    self.master:Hide()
end

--- Set unit frame highlight state.
-- @param frame Unit frame.
-- @param state Highlighted state.
local function SetUnitFrameHighlight(frame, state)
    if (state) then
        frame.highlight:Show()
    else
        frame.highlight:Hide()
    end
end

--- Set frame width, height and point.
-- @param f Frame to set.
-- @param width New width
-- @param height New height
-- @param point Point on this region at which it is to be anchored to another.
-- @param relativeTo Reference to the other region to which this region is to
-- be anchored.
-- @param relativePoint Point on the other region to which this region is to be
-- anchored.
-- @param xOffset Horizontal offset between point and relative point.
-- @param yOffset Vertical offset between point and relative point.
local function SetFrameWHP(f, width, height, point, relativeTo, relativePoint, xOffset, yOffset)
    f:SetWidth(width)
    f:SetHeight(height)
    if (point) then
        f:ClearAllPoints()
        f:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    end
end

--- Create unit frame.
-- @param id Unit frame identifier.
-- @param index Identifier index or nil.
function sjUF:CreateUnitFrame(id, index)
    index = index or ""
    local f = CreateFrame("Button", "sjUF_"..id..index, self.master)

    -- Functionality
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    f:SetScript("OnClick", self.OnUnitFrameClick)
    f:SetScript("OnEnter", function() SetUnitFrameHighlight(f, true) end)
    f:SetScript("OnLeave", function() SetUnitFrameHighlight(f, false) end)

    -- TODO:
    -- Buff/debuff bar instead of set number of frames

    f.backdrop = CreateFrame("Frame", nil, f)
    f.backdrop:SetFrameLevel(1)

    f.name = f:CreateFontString(nil, "ARTWORK")

    f.hp_bar = CreateFrame("StatusBar", nil, f)
    f.hp_bar:SetMinMaxValues(0, 100)
    f.hp_bar:SetFrameLevel(2)
    f.hp_text = f:CreateFontString(nil, "ARTWORK")
    -- f.hp_bar:Hide()

    f.mp_bar = CreateFrame("StatusBar", nil, f)
    f.mp_bar:SetMinMaxValues(0, 100)
    f.mp_bar:SetFrameLevel(2)
    f.mp_text = f:CreateFontString(nil, "ARTWORK")
    -- f.mp_bar:Hide()

    f.highlight = f:CreateTexture(nil, "OVERLAY")
    f.highlight:SetTexture("Interface\\AddOns\\sjUF\\media\\textures\\Highlight")
    -- f.highlight:SetTexture("border_tooltip")
    f.highlight:SetAllPoints(f)
    f.highlight:SetAlpha(0.3)
    f.highlight:SetBlendMode("ADD")
    f.highlight:Hide()

    -- Identifiers
    if (index) then
        f:SetID(index)
    end
    f.id = id
    f.index = index
    f.unit = id..index

    -- Reference
    self.units[id..index] = f
end

--- Set unit frame style.
-- @param f Unit frame
function sjUF:SetUnitFrameStyle(f)
    local id = f.id
    local index = f.index
    local unit = f.unit
    local style = self.opt[id]

    local _, class = UnitClass(f.unit)
    local color = self.class_colors[class]

    -- Frame
    SetFrameWHP(f, style.width, style.height)

    -- Backdrop
    SetFrameWHP(f.backdrop, style.width+10, style.height+10, "CENTER", f, "CENTER")
    f.backdrop:SetBackdrop({
        edgeFile = "Interface\\AddOns\\sjUF\\media\\borders\\UI-Tooltip-Border_Grid",
        edgeSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    f.backdrop:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local hp_bar_scale = style.hp_bar_height_weight/(style.hp_bar_height_weight+style.mp_bar_height_weight)

    -- HP bar
    SetFrameWHP(f.hp_bar, style.width, style.height*hp_bar_scale, "TOP", f, "TOP")
    f.hp_bar:SetStatusBarTexture(style.hp_bar_texture)
     --f.hp_bar:SetStatusBarColor(0, 1, 0, 1)

    -- MP bar
    local color = self.opt.power_colors.mana
    SetFrameWHP(f.mp_bar, style.width, style.height*(1-hp_bar_scale), "TOP", f.hp_bar, "BOTTOM")
    f.mp_bar:SetStatusBarTexture(style.mp_bar_texture)
    f.mp_bar:SetStatusBarColor(color.r, color.g, color.b)

    -- Name
    SetFrameWHP(f.name, style.width-4, style.name_font_size,
    "TOPLEFT", f, "TOPLEFT", style.name_xoffset, style.name_yoffset)
    f.name:SetFont(style.name_font, style.name_font_size)
    f.name:SetJustifyH(style.name_hjust)

    -- HP text
    SetFrameWHP(f.hp_text, style.width-4, style.hp_text_font_size,
    "TOPLEFT", f, "TOPLEFT", style.hp_text_xoffset, style.hp_text_yoffset)
    f.hp_text:SetFont(style.hp_text_font, style.hp_text_font_size)
    f.hp_text:SetJustifyH(style.hp_text_hjust)
    if (style.hp_text_enable) then
        f.hp_text:Show()
    else
        f.hp_text:Hide()
    end

    -- MP text
    SetFrameWHP(f.mp_text, style.width-4, style.mp_text_font_size,
    "TOPLEFT", f, "TOPLEFT", style.mp_text_xoffset, style.mp_text_yoffset)
    f.mp_text:SetFont(style.mp_text_font, style.mp_text_font_size)
    f.mp_text:SetJustifyH(style.mp_text_hjust)
    if (style.mp_text_enable) then
        f.mp_text:Show()
    else
        f.mp_text:Hide()
    end
end

--- Update raid frames.
function sjUF:UpdateRaidFrames()
    -- self.master:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
    -- self.master:SetWidth(self.opt.raid.width * self.opt.raid.units_per_row + self.opt.raid.xoffset * (self.opt.raid.units_per_row - 1))
    -- self.master:SetHeight(20)
    -- self.master.background:SetAllPoints(self.master)

    -- Update styles
    for i = 1, MAX_RAID_MEMBERS do
        self:SetUnitFrameStyle(self.units["raid"..i], "raid", i)
    end

    -- Update positioning
    local upr, f, row, mod = self.opt.raid.units_per_row
    self.units.raid1:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
    for i = 2, MAX_RAID_MEMBERS do
        f = self.units["raid"..i]
        row = floor((i-1) / upr)
        mod = (i-1) - floor((i-1) / upr) * upr

        if (mod == 0) then
            -- Next row, anchor to frame above
            f:SetPoint("TOPLEFT", self.units["raid"..(row-1)*upr+1], "BOTTOMLEFT", 0, -self.opt.raid.yoffset)
        else
            -- Anchor to frame on left
            f:SetPoint("TOPLEFT", self.units["raid"..i-1], "TOPRIGHT", self.opt.raid.xoffset, 0)
        end
    end
end

--- Update unit.
function sjUF:UpdateUnit(unit)
    local f = self.units[unit]
    f.name:SetText(UnitName(f.unit) or f.unit)
    f.hp_text:SetText("Health")
    f.mp_text:SetText("Mana")
end

--- Update raid units.
function sjUF:UpdateRaidUnits()
    for i = 1, MAX_RAID_MEMBERS do
        self:UpdateUnit("raid"..i)
    end
end

--- Unit frame OnClick handler.
function sjUF:OnUnitFrameClick()
    TargetUnit(this.unit)
end

function sjUF:InitVariables()
    self.units = {}
    self.class_colors = {
        ["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45, colorStr = "|cffabd473" },
        ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "|cff9482c9" },
        ["PRIEST"]  = { r = 1.00, g = 1.00, b = 1.00, colorStr = "|cffffffff" },
        ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "|cfff58cba" },
        ["MAGE"]    = { r = 0.41, g = 0.8,  b = 0.94, colorStr = "|cff69ccf0" },
        ["ROGUE"]   = { r = 1.00, g = 0.96, b = 0.41, colorStr = "|cfffff569" },
        ["DRUID"]   = { r = 1.00, g = 0.49, b = 0.04, colorStr = "|cffff7d0a" },
        ["SHAMAN"]  = { r = 0.00, g = 0.44, b = 0.87, colorStr = "|cff0070de" },
        ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "|cffc79c6e" },
    }
end
