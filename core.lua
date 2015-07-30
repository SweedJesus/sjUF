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

-- Create addon module
sjUF = AceLibrary("AceAddon-2.0"):new(
    "AceDB-2.0",
    "AceConsole-2.0")

-- Media
local font_myriad = "Interface\\AddOns\\sjUF\\media\\fonts\\Myriad"
local bar_flat    = "Interface\\AddOns\\sjUF\\media\\textures\\Flag"

--- Ace addon OnInitialize handler.
function sjUF:OnInitialize()
    -- Saved variables
    self:RegisterDB("sjUF_DB")
    self:RegisterDefaults("profile", {
        font = font_myriad,
        bar_texture = bar_flat,
        frame_styles = {
            raid = {
                width = 60,
                height = 40,
                font = font_myriad,
                texture = bar_flat
            }
        }
    })
    self.opt = self.db.profile

    -- Master frame
    self.master = CreateFrame("Frame", "sjUF", UIParent)

    -- Create raid frames
    self.frames = {}
    for i = 1, MAX_RAID_MEMBERS do
        self:CreateUnitFrame("raid", i)
    end
end

--- Create unit frame.
-- @param id Unit frame identifier
-- @param index Identifier index or nil
function sjUF:CreateUnitFrame(id, index)
    local f = CreateFrame("Button", "sjUF_"..id..index, self.master)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    f:SetScript("OnClick", self.OnUnitFrameClick)
    f:SetScript("OnEnter", self.OnUnitFrameEnter)
    f:SetScript("OnLeave", self.OnUnitFrameLeave)

    -- TODO:
    -- Move all styling configuration out into a styling function
    -- Buff/debuff bar instead of set number of frames
    -- Change font size magic numbers to configurable values
    -- Fix component layers

    f.name = f:CreateFontString(nil, "ARTWORK")
    f.name:SetFont(self.opt.font, 11)
    f.name:SetJustifyH("LEFT")

    f.hpbar = CreateFrame("StatusBar", nil, f)
    f.hpbar:SetMinMaxValues(0, 100)
    f.hpbar.texture = f.hpbar:CreateTexture(nil, "BORDER")
    f.hpbar.texture:SetTexture(self.opt.bar_texture)
    f.hpbar.texture:SetVertexColor(1, 0, 0, 0)
    f.hpbar:SetStatusBarTexture(f.hpbar.texture)

    f.mpbar = CreateFrame("StatusBar", nil, f)
    f.mpbar:SetMixMaxValues(0, 100)
    f.mpbar.texture = f.mpbar:CreateTexture(nil, "BORDER")
    f.mpbar.texture:SetTexture(self.opt.bar_texture)
    f.mpbar.texture:SetVertexColor(1, 0, 0, 0)
    f.mpbar:SetStatusBarTexture(f.mpbar.texture)

    f.highlight = f:CreateTexture(nil, "OVERLAY")
    f.highlight:SetAlpha(0.3)
    f.highlight:SetBlendMode("ADD")
    f.highlight:SetTexture("Interface\\AddOns\\sjUF\\textures\\Highlight")
    f.highlight:Hide()

    -- Set style
    self:SetStyle(f, id, index)

    -- Identifiers
    f:SetID(index)
    f.index = index
    f.unit = id..index

    -- Reference
    self.frames[id..index] = f
end

--- Set unit frame style.
-- @param f Unit frame
-- @param id Unit frame identifier
-- @param index Identifier index or nil
function sjUF:SetUnitFrameStyle(f, id, index)
    local unit = id..index
    local width  = self.opt.frame_styles[unit].width
    local height = self.opt.frame_styles[unit].height

    self:SetFrameWHP(f, width, height)
    self:SetFrameWHP(f.name, width-10, 16, "TOPLEFT", f, "TOPLEFT", 5, -6)
end

--- Set frame width, height and point.
-- @param frame Frame to set.
-- @param width New width
-- @param height New height
-- @param point Point on this region at which it is to be anchored to another.
-- @param relativeTo Reference to the other region to which this region is to
-- be anchored.
-- @param relativePoint oint on the other region to which this region is to be
-- anchored.
-- @param xOffset Horizontal offset between point and relative point.
-- @param yOffset Vertical offset between point and relative point.
function sjUF:SetFrameWHP(frame, width, height, point, relativeTo,
    relativePoint, xOffset, yOffset)

    f:SetWidth(w)
    f:SetHeight(h)
    if (p) then
        f:ClearAllPoints()
        f:SetPoint(p, r, pr, xo, yo)
    end
end

--- Unit frame OnClick handler.
function sjUF:OnUnitFrameClick()
end

--- Unit frame OnEnter handler.
function sjUF:OnUnitFrameEnter()
end

--- Unit frame OnLeave handler.
function sjUF:OnUnitFrameLeave()

end
