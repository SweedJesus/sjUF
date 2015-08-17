-- TODO:
-- Add party and other frames
-- Add power bars of all types to allow showing multiple (if say it's a druid)
-- Repair FuBar loading (reference BugSackFu)
-- Better chain of and separation in updating layout and unit data

-- Create addon module
sjUF = AceLibrary("AceAddon-2.0"):new(
"AceConsole-2.0",
"AceDB-2.0",
"AceEvent-2.0",
"FuBarPlugin-2.0")

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
    self:RegisterDefaults("profile", self.defaults)
    self.opt = self.db.profile

    -- Chat command
    self:RegisterChatCommand({"/sjuf"}, self.options)

    -- Master frame
    self.master = CreateFrame("Frame", "sjUF", UIParent)
    self.master.background = self.master:CreateTexture(nil, "BACKGROUND")
    self.master.background:SetTexture(1,0,0.9,1)

    -- Create raid frames
    for i = 1, MAX_RAID_MEMBERS do
        self:CreateUnitFrame("raid"..i)
    end
end

--- Ace addon OnEnable handler.
function sjUF:OnEnable()
    self:UpdateRaidFrames()
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
function sjUF:CreateUnitFrame(unitID)
    local domain = gsub(unitID, "%d*", '')
    local index  = gsub(unitID, "%D*", '')
    local f = CreateFrame("Button", nil, self.master)

    -- Functionality
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    f:SetScript("OnClick", function()
        TargetUnit(f.unitID)
    end)
    f:SetScript("OnEnter", function()
        SetUnitFrameHighlight(f, true)
    end)
    f:SetScript("OnLeave", function()
        SetUnitFrameHighlight(f, false)
    end)

    -- TODO:
    -- Buff/debuff bar instead of set number of frames

    f.backdrop = CreateFrame("Frame", nil, f)
    f.backdrop:SetFrameLevel(1)

    f.name = f:CreateFontString(nil, "ARTWORK")

    f.hp_bar = CreateFrame("StatusBar", nil, f)
    f.hp_bar:SetMinMaxValues(0, 100)
    f.hp_bar:SetFrameLevel(2)

    f.mp_bar = CreateFrame("StatusBar", nil, f)
    f.mp_bar:SetMinMaxValues(0, 100)
    f.mp_bar:SetFrameLevel(2)

    f.hp_text = f:CreateFontString(nil, "ARTWORK")

    f.mp_text = f:CreateFontString(nil, "ARTWORK")

    f.highlight = f:CreateTexture(nil, "OVERLAY")
    f.highlight:SetTexture("Interface\\AddOns\\sjUF\\media\\textures\\Highlight")
    f.highlight:SetAllPoints(f)
    f.highlight:SetAlpha(0.3)
    f.highlight:SetBlendMode("ADD")
    f.highlight:Hide()

    -- Identifiers
    f.domain = domain
    if (index ~= '') then
        f.index = index
    end
    f.unitID = unitID

    -- Reference
    self.units[unitID] = f
end

--- Set unit frame style.
-- @param f Unit frame
function sjUF:SetUnitFrameStyle(f)
    local unitID = f.unitID
    local style = self.opt[f.domain].style
    local _, class = UnitClass(unitID)
    local hp_color = self.opt.colors.classes[class] or self.opt.colors.default
    local mp_color = self.opt.colors.powers[0] -- mana

    -- Frame
    SetFrameWHP(f, style.frame.width, style.frame.height)

    -- Backdrop
    SetFrameWHP(f.backdrop,
    style.frame.width + style.backdrop.edge_inset,
    style.frame.height + style.backdrop.edge_inset,
    "CENTER", f, "CENTER")
    local backdrop = self.units[unitID]:GetBackdrop() or {}
    if (style.backdrop.background_enabled) then
        backdrop.bgFile = style.backdrop.background_texture
    else
        backdrop.bgFile = nil
    end
    if (style.backdrop.edge_enabled) then
        backdrop.edgeFile = style.backdrop.edge_texture
    else
        backdrop.edgeFile = nil
    end
    backdrop.tile = true
    backdrop.tileSize = 16
    backdrop.edgeSize = 16
    backdrop.insets = backdrop.insets or {}
    backdrop.insets.left = style.backdrop.background_inset
    backdrop.insets.right = style.backdrop.background_inset
    backdrop.insets.top = style.backdrop.background_inset
    backdrop.insets.bottom = style.backdrop.background_inset
    f.backdrop:SetBackdrop(backdrop)
    f.backdrop:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    if (style.backdrop.background_enabled or
        style.backdrop.edge_enabled) then
        f.backdrop:Show()
    else
        f.backdrop:Hide()
    end

    -- Status bar scales
    local hp_scale, mp_scale
    if (style.mp_bar.enabled) then
        local total = style.hp_bar.height_weight + style.mp_bar.height_weight
        hp_scale = style.hp_bar.height_weight / total
        mp_scale = 1 - hp_scale
    else
        hp_scale = 1
        mp_scale = 0
    end

    -- HP bar
    SetFrameWHP(f.hp_bar, style.frame.width, style.frame.height*hp_scale,
    "TOP", f, "TOP")
    f.hp_bar:SetStatusBarTexture(style.hp_bar.texture)
    f.hp_bar:SetStatusBarColor(hp_color.r, hp_color.g, hp_color.b)

    -- MP bar
    SetFrameWHP(f.mp_bar, style.frame.width, style.frame.height*mp_scale,
    "TOP", f.hp_bar, "BOTTOM")
    f.mp_bar:SetStatusBarTexture(style.mp_bar.texture)
    f.mp_bar:SetStatusBarColor(mp_color.r, mp_color.g, mp_color.b)
    if (style.mp_bar.enabled) then
        f.mp_bar:Show()
    else
        f.mp_bar:Hide()
    end

    -- Name text
    SetFrameWHP(f.name, style.frame.width-2, style.name_text.font_size,
    "TOPLEFT", f, "TOPLEFT", style.name_text.xoffset, style.name_text.yoffset)
    f.name:SetFont(style.name_text.font, style.name_text.font_size)
    f.name:SetJustifyH(style.name_text.hjust)
    if (style.name_text.enabled) then
        f.name:Show()
    else
        f.name:Hide()
    end

    -- HP text
    SetFrameWHP(f.hp_text, style.frame.width-2, style.hp_text.font_size,
    "TOPLEFT", f, "TOPLEFT", style.hp_text.xoffset, style.hp_text.yoffset)
    f.hp_text:SetFont(style.hp_text.font, style.hp_text.font_size)
    f.hp_text:SetJustifyH(style.hp_text.hjust)
    if (style.hp_text.enabled) then
        f.hp_text:Show()
    else
        f.hp_text:Hide()
    end

    -- MP text
    SetFrameWHP(f.mp_text, style.frame.width-4, style.mp_text.font_size,
    "TOPLEFT", f, "TOPLEFT", style.mp_text.xoffset, style.mp_text.yoffset)
    f.mp_text:SetFont(style.mp_text.font, style.mp_text.font_size)
    f.mp_text:SetJustifyH(style.mp_text.hjust)
    if (style.mp_text.enabled) then
        f.mp_text:Show()
    else
        f.mp_text:Hide()
    end
end

function sjUF:UpdateUnitInfo(f)
    local name = UnitName(f.unitID)
    if (name and self.opt[f.domain].style.name_text.short) then
        name = string.sub(unit, 1, self.opt.raid.name_text.short_num_chars)
    end
    f.name:SetText(name or f.unitID)
    f.hp_text:SetText("Health")
    f.mp_text:SetText("Power")
end

--- Update raid frames.
-- Updates raid frame layouts, that is styling and positioning. Does not update
-- unit data (name, health, power).
function sjUF:UpdateRaidFrames()
    if not self.opt.raid.enabled then
        for i = 1, 40 do
            self.units["raid"..i]:Hide()
        end
    else
        -- self.master:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
        --self.master:SetWidth(self.opt.raid.width * self.opt.raid.units_per_row + self.opt.raid.xoffset * (self.opt.raid.units_per_row - 1))
        -- self.master:SetHeight(20)
        -- self.master.background:SetAllPoints(self.master)

        -- Update styles
        for i = 1, MAX_RAID_MEMBERS do
            self:SetUnitFrameStyle(self.units["raid"..i])
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
                f:SetPoint("TOPLEFT", self.units["raid"..(row-1)*upr+1],
                "BOTTOMLEFT", 0, -self.opt.raid.units_yoffset)
            else
                -- Anchor to frame on left
                f:SetPoint("TOPLEFT", self.units["raid"..i-1],
                "TOPRIGHT", self.opt.raid.units_xoffset, 0)
            end
        end
    end
end

--- Update raid units.
-- Updates the data of raid units, that is name, health and power values. Does
-- not update raid frame layouts (styling, positioning).
function sjUF:UpdateRaidUnits()
    if self.opt.raid.enabled then
        for i = 1, MAX_RAID_MEMBERS do
            self:UpdateUnitInfo(self.units["raid"..i])
            --local f = self.units["raid"..i]
            --local unit = UnitName(f.unit) or f.unit
            --if (self.opt.raid.name_short) then
            --unit = string.sub(unit, 1, self.opt.raid.name_short_chars)
            --end
            --if (self.opt.raid.name_enabled) then
            --f.name:SetText(unit)
            --end
            --if (self.opt.raid.hp_text_enabled) then
            --f.hp_text:SetText("Health")
            --end
            --if (self.opt.raid.mp_text_enabled) then
            --f.mp_text:SetText("Power")
            --end
        end
    end
end

function sjUF:InitVariables()
    self.units = {}
end
