-- Create addon module
sjUF = AceLibrary("AceAddon-2.0"):new(
    "AceDB-2.0",
    "AceConsole-2.0")

-- Media
-- TODO:
-- Add customization
-- Maybe replace with Ace Surface-1.0 library for handling textures
local font_myriad = "Interface\\AddOns\\sjUF\\media\\fonts\\Myriad.ttf"
local bar_flat    = "Interface\\AddOns\\sjUF\\media\\bars\\Flag.tga"

--- Ace addon OnInitialize handler.
function sjUF:OnInitialize()
    self:InitVariables()

    -- Saved variables
    self:RegisterDB("sjUF_DB")
    self:RegisterDefaults("profile", {
        -- Fonts
        font = font_myriad,
    })
    self.opt = self.db.profile

    self.master = CreateFrame("Frame", "sjUF", UIParent)

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

    -- Party member frames
    for i = 1, MAX_PARTY_MEMBERS do
        self:CreateUnitFrame("party", i)
    end

    -- Raid member frames
    for i = 1, MAX_RAID_MEMBERS do
        self:CreateUnitFrame("raid", i)
    end
end

--- Initialize member variables.
function sjUF:InitVariables()
    self.frames = {}
end

--- Create unit frame.
-- @param group Unit group ("player", "party", "raid")
-- @param id Numeric unit ID (party: 1-4, raid: 1-40)
function sjUF:CreateUnitFrame(group, id)
    local f = CreateFrame("Button", "sjUF_"..group..id, self.master)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    f:SetScript("OnClick", self.OnUnitFrameClick)
    f:SetScript("OnEnter", self.OnUnitFrameEnter)
    f:SetScript("OnLeave", self.OnUnitFrameLeave)

    -- TODO:
    -- Move all styling configuration out into a styling function
    -- Buff/debuff bar instead of set number of frames

    f.name = f:CreateFontString(nil, "ARTWORK")
    f.name:SetFont(self.opt.font, 11)
    f.name:SetJustifyH("LEFT")

    f.hpbar = CreateFrame("StatusBar", nil, f)
    f.hpbar:SetStatusBarTexture

    --f.buff1 = CreateFrame("Button", nil, f)
    --f.buff1.texture = f.buff1:CreateTexture(nil, "ARTWORK")
    --f.buff1.texture:SetAllPoints(f.buff1)
    --f.buff1.count = f.buff1:CreateFontString(nil, "OVERLAY")
    --f.buff1.count:SetFont(self.opt.font, 9)
    --f.buff1.count:SetJustifyH("CENTER")
    --f.buff1.count:SetPoint("CENTER", f.buff1, "CENTER", 0, 0)
    --f.buff1:Hide()

    -- Reference
    self.frames[group..id] = f
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
