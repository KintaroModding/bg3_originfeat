local Common = Ext.Require("Shared/Common.lua")
local Settings = Ext.Require("Shared/Settings.lua")
local ExtraFeat = Ext.Require("Shared/ExtraFeat.lua")
local ClientLog = Ext.Require("Client/ClientLog.lua")

-- The level-up screen runs on the client, so the client sets the flags too (a multiplayer client has its own copy of
-- the static data).
local function ApplyExtraFeat(when)
    ClientLog.Add(when .. ": " .. ExtraFeat.ApplyAndDescribe((Settings.Get("extra_feat_on_level_up"))) .. ".")
end

-- StatsLoaded runs only in the client Lua state: at the game start and in the first save load after it, which takes
-- the flags from the static data. Both it and SessionLoading set the primed values for that load
-- (Shared/ExtraFeat.lua); the setting's value follows on SessionLoaded.
Ext.Events.StatsLoaded:Subscribe(function()
    ClientLog.Add("StatsLoaded: " .. ExtraFeat.PrimeAndDescribe() .. ".")
end)

Ext.Events.SessionLoading:Subscribe(function()
    ClientLog.Add("SessionLoading: " .. ExtraFeat.PrimeAndDescribe() .. ".")
end)

Ext.Events.SessionLoaded:Subscribe(function()
    ClientLog.Add("Origin Feat " .. Common.ModVersion() .. " loaded.")
    ApplyExtraFeat("SessionLoaded")
end)

Settings.OnChange(function()
    ApplyExtraFeat("Setting changed")
end)
