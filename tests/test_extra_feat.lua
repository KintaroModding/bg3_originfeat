-- The extra feat: while a save loads, the class level 2 rows are primed on; after the load and on every change, they
-- get the setting's value. The multiclass rows and every other row stay alone.

Harness.Mods[ModuleUUID] = { Info = { ModVersion = { 1, 0, 0, 4 } } }
Harness.InstallMCM({ extra_feat_on_level_up = true })

local NULL = "00000000-0000-0000-0000-000000000000"
local FIGHTER, WIZARD, CHAMPION = "c1000000-0000-0000-0000-000000000001", "c1000000-0000-0000-0000-000000000002",
    "c1000000-0000-0000-0000-000000000003"
local T_FIGHTER, T_WIZARD, T_CHAMPION, T_NPC, T_RACE = "7a000000-0000-0000-0000-000000000001",
    "7a000000-0000-0000-0000-000000000002", "7a000000-0000-0000-0000-000000000003",
    "7a000000-0000-0000-0000-000000000004", "7a000000-0000-0000-0000-000000000005"

Harness.StaticData.ClassDescription = {
    [FIGHTER] = { Name = "Fighter", ParentGuid = NULL, ProgressionTableUUID = T_FIGHTER },
    [WIZARD] = { Name = "Wizard", ParentGuid = NULL, ProgressionTableUUID = T_WIZARD },
    [CHAMPION] = { Name = "Champion", ParentGuid = FIGHTER, ProgressionTableUUID = T_CHAMPION },
}

local function Row(name, table, level, multiclass, allow)
    return { Name = name, TableUUID = table, Level = level, IsMulticlass = multiclass, AllowImprovement = allow }
end

local rows = {
    fighter1 = Row("Fighter", T_FIGHTER, 1, false, false),
    fighter1mc = Row("Fighter", T_FIGHTER, 1, true, false),
    fighter2 = Row("Fighter", T_FIGHTER, 2, false, false),
    fighter4 = Row("Fighter", T_FIGHTER, 4, false, true),
    wizard1mc = Row("Wizard", T_WIZARD, 1, true, true), -- another mod's feat on a multiclass row: stays
    wizard2 = Row("Wizard", T_WIZARD, 2, false, false),
    champion3 = Row("Champion", T_CHAMPION, 3, false, false),
    npc2 = Row("NPC_Fighter", T_NPC, 2, false, false),
    human2 = Row("Human", T_RACE, 2, false, false),
}
Harness.StaticData.Progression = {}
local n = 0
for _, row in pairs(rows) do
    n = n + 1
    Harness.StaticData.Progression[string.format("90000000-0000-0000-0000-%012d", n)] = row
end

Ext.Require("BootstrapServer.lua")
Ext.Require("BootstrapClient.lua")

local function Log(name)
    Harness.RunTimers()
    return Harness.Files["bg3_originfeat/" .. name] or ""
end

local function AssertFlags(on)
    AssertEq(rows.fighter2.AllowImprovement, on, "fighter2")
    AssertEq(rows.wizard2.AllowImprovement, on, "wizard2")
    AssertEq(rows.fighter1.AllowImprovement, false, "class level 1 of the first class")
    AssertEq(rows.fighter1mc.AllowImprovement, false, "multiclass row")
    AssertEq(rows.wizard1mc.AllowImprovement, true, "multiclass row of another mod")
    AssertEq(rows.fighter4.AllowImprovement, true, "the game's own feat at level 4")
    AssertEq(rows.champion3.AllowImprovement, false, "subclass row")
    AssertEq(rows.npc2.AllowImprovement, false, "NPC table without a class")
    AssertEq(rows.human2.AllowImprovement, false, "race row")
end

Test("StatsLoaded (client) primes the class level 2 rows on", function()
    Ext.Events.StatsLoaded:Fire()
    AssertFlags(true)
    AssertTrue(string.find(Log("client.log"), "StatsLoaded: Prime: 2 rows of 2 classes (2 changed).", 1, true),
        "client.log")
end)

Test("SessionLoading primes the rows on both sides", function()
    rows.fighter2.AllowImprovement = false
    Ext.Events.SessionLoading:Fire()
    AssertFlags(true)
    AssertTrue(string.find(Log("server.log"), "SessionLoading: Prime: 2 rows of 2 classes (1 changed).", 1, true),
        "server.log")
    -- The client runs after the server here, in one Lua state: the rows are already set.
    AssertTrue(string.find(Log("client.log"), "SessionLoading: Prime: 2 rows of 2 classes (0 changed).", 1, true),
        "client.log")
end)

Test("SessionLoaded sets the setting's value", function()
    Ext.Events.SessionLoaded:Fire()
    AssertFlags(true)
    AssertTrue(string.find(Log("server.log"), "SessionLoaded: Extra feat on: 2 rows of 2 classes (0 changed).", 1, true),
        "server.log")
    AssertTrue(string.find(Log("client.log"), "SessionLoaded: Extra feat on: 2 rows of 2 classes (0 changed).", 1, true),
        "client.log")
end)

Test("turning the setting off clears the rows at once", function()
    Harness.FireMCMSettingSaved("extra_feat_on_level_up", false)
    AssertFlags(false)
    AssertTrue(string.find(Log("server.log"), "Setting changed: Extra feat off: 2 rows of 2 classes (2 changed).", 1,
        true), "server.log")
end)

Test("turning it on again sets the rows", function()
    Harness.FireMCMSettingSaved("extra_feat_on_level_up", true)
    AssertFlags(true)
end)

Test("a load with the setting off primes the rows on, then clears them", function()
    Harness.MCMValues.extra_feat_on_level_up = false
    Ext.Events.SessionLoading:Fire()
    AssertFlags(true)
    Ext.Events.SessionLoaded:Fire()
    AssertFlags(false)
end)

Test("a level-up logs the character, the new level and the flags", function()
    local uuid = "0e000000-0000-0000-0000-000000000001"
    Harness.AddObject(uuid, "character", "Tav", { Components = { EocLevel = { Level = 2 } } })
    rows.fighter2.AllowImprovement = true
    Harness.Listeners["LeveledUp/1"]("S_Player_Tav_" .. uuid)
    AssertTrue(string.find(Log("server.log"), "Level up: S_Player_Tav_" .. uuid .. " to level 2, feat flag on 1 of 2 rows.",
        1, true), "server.log")
    rows.fighter2.AllowImprovement = false
end)

Test("an error while applying becomes a log line, not a crash", function()
    local original = Ext.StaticData.GetAll
    Ext.StaticData.GetAll = function() error("no static data") end
    Harness.FireMCMSettingSaved("extra_feat_on_level_up", true)
    Ext.Events.SessionLoading:Fire()
    Ext.StaticData.GetAll = original
    AssertTrue(string.find(Log("server.log"), "Setting changed: Extra feat on failed:", 1, true), "apply error")
    AssertTrue(string.find(Log("server.log"), "SessionLoading: Prime failed:", 1, true), "prime error")
    AssertTrue(string.find(Log("server.log"), "no static data", 1, true), "error text")
end)
