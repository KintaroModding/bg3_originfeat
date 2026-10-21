local Common = Ext.Require("Shared/Common.lua")
local Settings = Ext.Require("Shared/Settings.lua")
local ExtraFeat = Ext.Require("Shared/ExtraFeat.lua")
local ServerLog = Ext.Require("Server/ServerLog.lua")

local function ApplyExtraFeat(when)
    ServerLog.Add(when .. ": " .. ExtraFeat.ApplyAndDescribe((Settings.Get("extra_feat_on_level_up"))) .. ".")
end

-- Both Lua states start again on every save load. While the save loads, the flags must hold the primed values
-- (Shared/ExtraFeat.lua); the setting's value follows on SessionLoaded.
Ext.Events.SessionLoading:Subscribe(function()
    ServerLog.Add("SessionLoading: " .. ExtraFeat.PrimeAndDescribe() .. ".")
end)

Ext.Events.SessionLoaded:Subscribe(function()
    ServerLog.Add("Origin Feat " .. Common.ModVersion() .. " loaded.")
    ServerLog.Add("Settings: " .. Settings.Describe() .. ".")
    ApplyExtraFeat("SessionLoaded")
end)

-- In multiplayer, the host's server holds the values that count: apply rules that change the game here.
Settings.OnChange(function(settingId)
    local reason = settingId and ("Setting changed (" .. tostring(settingId) .. ")") or "MCM profile changed"
    ServerLog.Add(reason .. ": " .. Settings.Describe() .. ".")
    ApplyExtraFeat("Setting changed")
end)

-- The flags at each level-up show whether something changed them after the mod set them.
Ext.Osiris.RegisterListener("LeveledUp", 1, "after", function(character)
    local level = "?"
    pcall(function()
        local uuid = string.match(character, "%x+%-%x+%-%x+%-%x+%-%x+$") or character
        level = tostring(Ext.Entity.Get(uuid).EocLevel.Level)
    end)
    ServerLog.Add(string.format("Level up: %s to level %s, %s.", tostring(character), level, ExtraFeat.DescribeFlags()))
end)
