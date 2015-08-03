-- Fonts
sjUF.fonts = {

}

-- Status bar textures
sjUF.bar_textures = {
    ["Interface\\AddOns\\sjUF\\media\\textures\\Flat"]  = "Flat",
    ["Interface\\AddOns\\sjUF\\media\\textures\\Solid"] = "Solid"
}

-- Configuration options
sjUF.options = {
    type = "group",
    args = {
        power_colors = {
            name = "Power colors",
            desc = "Colors for class power (mana, energy, rage)",
            type = "group",
            args = {
                mana = {
                    name = "Mana",
                    desc = "Mana color",
                    type = "color",
                    get = function()
                        local c = sjUF.opt.power_colors.mana
                        return c.r, c.g, c.b
                    end,
                    set = function(r, g, b, a)
                        sjUF.opt.power_colors.mana = { r = r, g = g, b = b }
                        sjUF:UpdateRaidFrames()
                    end,
                    hasAlpha = true,
                    order = 1
                }
            }
        },
        raid = {
            name = "Raid",
            desc = "Raid frames configuration",
            type = "group",
            args = {
                width = {
                    name = "Raid unit frame width",
                    desc = "Width of each raid member unit frame",
                    type = "range",
                    min = 1,
                    max = 100,
                    step = 1,
                    get = function() return sjUF.opt.raid.width end,
                    set = function(set)
                        sjUF.opt.raid.width = set
                        sjUF:UpdateRaidFrames()
                    end,
                    order = 1
                },
                height = {
                    name = "Raid unit frame height",
                    desc = "Height of each raid member unit frame",
                    type = "range",
                    min = 1,
                    max = 100,
                    step = 1,
                    get = function() return sjUF.opt.raid.height end,
                    set = function(set)
                        sjUF.opt.raid.height = set
                        sjUF:UpdateRaidFrames()
                    end,
                    order = 2
                },
                units_per_row = {
                    name = "Units per row",
                    desc = "Raid member unit frames to show per row",
                    type = "range",
                    min = 1,
                    max = 40,
                    step = 1,
                    get = function() return sjUF.opt.raid.units_per_row end,
                    set = function(set)
                        sjUF.opt.raid.units_per_row = set
                        sjUF:UpdateRaidFrames()
                    end,
                    order = 3
                },
                xoffset = {
                    name = "Frame horizontal spacing",
                    desc = "Horizontal spacing between raid unit frames",
                    type = "range",
                    min = 1,
                    max = 30,
                    step = 1,
                    get = function() return sjUF.opt.raid.xoffset end,
                    set = function(set)
                        sjUF.opt.raid.xoffset = set
                        sjUF:UpdateRaidFrames()
                    end,
                    order = 4
                },
                yoffset = {
                    name = "Frame vertical spacing",
                    desc = "Vertical spacing between raid unit frames",
                    type = "range",
                    min = 1,
                    max = 30,
                    step = 1,
                    get = function() return sjUF.opt.raid.yoffset end,
                    set = function(set)
                        sjUF.opt.raid.yoffset = set
                        sjUF:UpdateRaidFrames()
                    end,
                    order = 5
                },
                hp_bar = {
                    name = "Health bar",
                    desc = "Health bar configuration",
                    type = "group",
                    args = {
                        texture = {
                            name = "Texture",
                            desc = "Status bar texture",
                            type = "text",
                            get = function()
                                return sjUF.opt.hp_bar_texture
                            end,
                            set = function(set)
                                sjUF.opt.raid.hp_bar_texture = set
                                sjUF:UpdateRaidFrames()
                            end,
                            validate = sjUF.bar_textures,
                            order = 1
                        },
                        height_weight = {
                            name = "Height weight",
                            desc = "Status bar height scaling weight",
                            type = "range",
                            min = 1,
                            max = 20,
                            step = 1,
                            get = function()
                                return sjUF.opt.raid.hp_bar_height_weight
                            end,
                            set = function(set)
                                sjUF.opt.raid.hp_bar_height_weight = set
                                sjUF:UpdateRaidFrames()
                            end,
                            order = 2
                        },
                        class_color = {
                            name = "Class color",
                            desc = "Color by unit class",
                            type = "toggle",
                            get = function()
                                return sjUF.opt.raid.hp_bar_class_color
                            end,
                            set = function(set)
                                sjUF.opt.raid.hp_bar_class_color = set
                                sjUF:UpdateRaidFrames()
                            end,
                            order = 3
                        }
                    }
                },
                mp_bar = {
                    name = "Power bar",
                    desc = "Power bar configuration",
                    type = "group",
                    args = {
                        texture = {
                            name = "Texture",
                            desc = "Status bar texture",
                            type = "text",
                            get = function()
                                return sjUF.opt.mp_bar_texture
                            end,
                            set = function(set)
                                sjUF.opt.raid.mp_bar_texture = set
                                sjUF:UpdateRaidFrames()
                            end,
                            validate = sjUF.bar_textures,
                            order = 1
                        },
                        height_weight = {
                            name = "Height weight",
                            desc = "Status bar height scaling weight",
                            type = "range",
                            min = 1,
                            max = 20,
                            step = 1,
                            get = function()
                                return sjUF.opt.raid.mp_bar_height_weight
                            end,
                            set = function(set)
                                sjUF.opt.raid.mp_bar_height_weight = set
                                sjUF:UpdateRaidFrames()
                            end,
                            order = 1
                        }
                    }
                }
            }
        }
    }
}
