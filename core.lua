-- *Useful Blizzard macros*
-- MAX_PARTY_MEMBERS: 4
-- MAX_PARTY_BUFFS: 4
-- MAX_PARTY_DEBUFS: 4
-- MAX_PARTY_TOOLTIP_BUFFS: 16
-- MAX_PARTY_TOOLTIP_DEBUFS: 16
--
-- MAX_RAID_MEMBERS: 40
-- NUM_RAID_GROUPS: 8
-- MEMBERS_PER_RAID_GROUPS: 5
-- TODO:
-- Add party and other frames
-- Separate normal style from data/event styling (agro, debufs, etc)
-- Add power bars of all types to allow showing multiple (if say it's a druid)

local debug = true
local function Debug(msg)
    if (debug) then
        sjUF:Print("|cffff00ff%s|r", msg)
    end
end

-- Create addon module
sjUF = AceLibrary("AceAddon-2.0"):new(
    "AceConsole-2.0",
    "AceDB-2.0",
    "AceEvent-2.0")

-- Media
local font_myriad = "Interface\\AddOns\\sjUF\\media\\fonts\\Myriad.ttf"
local bar_flat    = "Interface\\AddOns\\sjUF\\media\\textures\\Flag"

--- Ace addon OnInitialize handler.
function sjUF:OnInitialize()
    Debug("OnInitialize")

    -- Initialize variables
    self:InitVariables()

    -- Saved variables
    self:RegisterDB("sjUF_DB")
    -- Defaults
    self:RegisterDefaults("profile", {
        font = font_myriad,
        bar_texture = bar_flat,
        raid = {
            width = 30,
            height = 20,
            font = font_myriad,
            texture = bar_flat,
            units_per_row = 8,
            unit_xoffset = 2,
            unit_yoffset = 2
        }
    })
    self.opt = self.db.profile

    -- Chat command
    self:InitOptions()
    self:RegisterChatCommand({"/sjuf"}, self.options)

    -- Master frame
    self.master = CreateFrame("Frame", "sjUF", UIParent)
    self.master.background = self.master:CreateTexture(nil, "BACKGROUND")
    self.master.background:SetTexture(1,0,0.9,1)

    self.dummy = CreateFrame("Frame", "sjUF_dummy", UIParent)
    self.dummy:SetWidth(300)
    self.dummy:SetHeight(200)
    self.dummy:SetPoint("CENTER", UIParent, "CENTER")
    self.dummy:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {
            left = 11,
            right = 12,
            top = 12,
            bottom = 11
        }
    })
    self.dummy:SetMovable(true)
    self.dummy:EnableMouse(true)
    self.dummy:RegisterForDrag("LeftButton")
    self.dummy:SetScript("OnDragStart", function()
        self.dummy:StartMoving()
    end)
    self.dummy:SetScript("OnDragStop", function()
        self.dummy:StopMovingOrSizing()
    end)

    -- Create raid frames
    for i = 1, MAX_RAID_MEMBERS do
        self:CreateUnitFrame("raid", i)
    end

    -- Update everything
    self:UpdateRaidFrames()
end

--- Ace addon OnEnable handler.
function sjUF:OnEnable()
    Debug("OnEnable")

    self.master:Show()
end

--- Ace addon OnDisable handler
function sjUF:OnDisable()
    Debug("OnDisable")

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

--- Create unit frame.
-- @param id Unit frame identifier.
-- @param index Identifier index or nil.
function sjUF:CreateUnitFrame(id, index)
    index = index or ""
    Debug(string.format("CreateUnitFrame (%s%s)", id, index))

    local f = CreateFrame("Button", "sjUF_"..id..index, self.master)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    f:SetScript("OnClick", self.OnUnitFrameClick)
    f:SetScript("OnEnter", function()
        SetUnitFrameHighlight(f, true)
    end)
    f:SetScript("OnLeave", function()
        SetUnitFrameHighlight(f, false)
    end)

    -- TODO:
    -- Move all styling configuration out into a styling function
    -- Buff/debuff bar instead of set number of frames
    -- Change font size magic numbers to configurable values
    -- Fix component layers

    f.background = f:CreateTexture(nil, "BACKGROUND")

    f.name = f:CreateFontString(nil, "ARTWORK")

    --f.hpbar = CreateFrame("StatusBar", nil, f)
    --f.hpbar:SetMinMaxValues(0, 100)
    --f.hpbar.texture = f.hpbar:CreateTexture(nil, "BORDER")

    --f.mpbar = CreateFrame("StatusBar", nil, f)
    --f.mpbar:SetMinMaxValues(0, 100)
    --f.mpbar.texture = f.mpbar:CreateTexture(nil, "BORDER")

    f.highlight = f:CreateTexture(nil, "OVERLAY")
    f.highlight:Hide()

    -- Identifiers
    if (index) then
        f:SetID(index)
    end
    f.index = index
    f.unit = id..index

    -- Reference
    self.units[id..index] = f
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
local function SetFrameWHP(f, width, height, point, relativeTo,
    relativePoint, xOffset, yOffset)

    f:SetWidth(width)
    f:SetHeight(height)
    if (point) then
        f:ClearAllPoints()
        f:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    end
end

--- Set unit frame style.
-- @param f Unit frame
-- @param id Unit frame identifier
-- @param index Identifier index or nil
function sjUF:SetUnitFrameStyle(f, id, index)
    local width  = self.opt[id].width
    local height = self.opt[id].height

    local _, class = UnitClass(f.unit)
    local color = self.class_colors[class]

    SetFrameWHP(f, width, height)
    --self:SetFrameWHP(.hpbar,

    if (color) then
        f.background:SetTexture(color.r, color.g, color.b, 0.9)
    else
        f.background:SetTexture(0, 0, 0, 0.9)
    end
    f.background:SetAllPoints(f)

    SetFrameWHP(f.name, width-10, 16, "CENTER", f, "CENTER", 5, -6)
    f.name:SetFont(self.opt.font, 11)
    f.name:SetJustifyH("LEFT")

    --f.hpbar:SetAllPoints(f)
    --f.hpbar.texture:SetTexture(self.db.profile.bar_texture)
    --f.hpbar.texture:SetTexture(1.0, 0.2, 0.2, 0.5)
    --f.hpbar.texture:SetVertexColor(1, 0, 0, 0)
    --f.hpbar:SetStatusBarTexture(f.hpbar.texture)

    --f.mpbar.texture:SetTexture(self.db.profile.bar_texture)
    --f.mpbar.texture:SetVertexColor(1, 0, 0, 0)
    --f.mpbar:SetStatusBarTexture(f.mpbar.texture)

    f.highlight:SetTexture("Interface\\AddOns\\sjUF\\media\\textures\\Highlight")
    f.highlight:SetAllPoints(f)
    f.highlight:SetAlpha(0.3)
    f.highlight:SetBlendMode("ADD")
    f.highlight:Hide()
end

--- Update raid frames.
function sjUF:UpdateRaidFrames()
    Debug("UpdateRaidFrames")

    self.master:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
    self.master:SetWidth(self.opt.raid.width * self.opt.raid.units_per_row + self.opt.raid.unit_xoffset * (self.opt.raid.units_per_row - 1))
    self.master:SetHeight(20)
    self.master.background:SetAllPoints(self.master)

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
        Debug(string.format("%s %s %s", i, row, mod))

        if (mod == 0) then
            -- Next row, anchor to frame above
            f:SetPoint("TOPLEFT", self.units["raid"..(row-1)*upr+1], "BOTTOMLEFT", 0, -self.opt.raid.unit_yoffset)
        else
            -- Anchor to frame on left
            f:SetPoint("TOPLEFT", self.units["raid"..i-1], "TOPRIGHT", self.opt.raid.unit_xoffset, 0)
        end
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

--- Initialize configuration options table.
function sjUF:InitOptions()
    self.options = self.options or {
        type = "group",
        args = {
        }
    }
end

