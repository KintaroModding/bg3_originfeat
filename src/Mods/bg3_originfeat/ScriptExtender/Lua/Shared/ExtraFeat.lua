-- The extra feat: AllowImprovement (the feat page of the level-up screen) on the class level 2 progression rows. Class
-- rows count the class level, so while the setting is on, every class a character takes to level 2 gives a feat; the
-- player turns the setting off after the first level-up. Race rows count the total level, but the level-up screen
-- ignores AllowImprovement there (game test of 1.0.0.0, 2026-10-21).
--
-- When the game reads the flags (game tests of 1.0.0.1 to 1.0.0.3, 2026-10-21):
-- - The first save load after the game start reloads the static data (the client gets StatsLoaded) and takes the flags
--   from it; later loads, in game or from the main menu, keep what that load took, until the game ends.
-- - Class level 2: the feat page needs the flag both at that load and at the level-up. Primed on at the load, the row
--   follows the setting at once, in both directions.
-- - Class level 1 taken as a multiclass: only the value at that load counts, so no setting could turn a feat there on
--   or off during play. The mod leaves these rows alone: a new class never gives a feat.
-- So while a save loads, Prime() sets the rows on; after the load and after every change, Apply() sets the setting's
-- value.
--
-- The flags live in the static data, which outlives the Lua state of one session, so a row cannot tell its original
-- value after a load. Off therefore sets false: the base game has no feat on any of these rows.

local ExtraFeat = {}

local NULL_GUID = "00000000-0000-0000-0000-000000000000"

local function IsGuid(value)
    return value ~= nil and value ~= "" and value ~= NULL_GUID
end

--- Returns the progression tables of the base classes, { [tableUuid] = className }: class descriptions without a
--- parent (subclasses have one), classes of other mods too. NPC and origin tables have no class description.
function ExtraFeat.ClassTables()
    local tables = {}
    for _, guid in ipairs(Ext.StaticData.GetAll("ClassDescription")) do
        local class = Ext.StaticData.Get(guid, "ClassDescription")
        if class ~= nil and not IsGuid(class.ParentGuid) and IsGuid(class.ProgressionTableUUID) then
            tables[class.ProgressionTableUUID] = class.Name
        end
    end
    return tables
end

--- Returns the class level 2 rows (not the multiclass rows), and the class tables.
function ExtraFeat.Rows()
    local tables = ExtraFeat.ClassTables()
    local rows = {}
    for _, guid in ipairs(Ext.StaticData.GetAll("Progression")) do
        local row = Ext.StaticData.Get(guid, "Progression")
        if row ~= nil and tables[row.TableUUID] ~= nil and row.Level == 2 and row.IsMulticlass ~= true then
            rows[#rows + 1] = row
        end
    end
    return rows, tables
end

--- Sets AllowImprovement on every row of ExtraFeat.Rows() to `on`. Returns { Rows, Changed, Classes }.
function ExtraFeat.Apply(on)
    local rows, tables = ExtraFeat.Rows()
    local changed = 0
    for _, row in ipairs(rows) do
        if row.AllowImprovement ~= on then
            row.AllowImprovement = on
            changed = changed + 1
        end
    end
    local classes = 0
    for _ in pairs(tables) do
        classes = classes + 1
    end
    return { Rows = #rows, Changed = changed, Classes = classes }
end

--- While a save loads: every row on, so the setting can turn the feat on and off later (see the top of this file).
function ExtraFeat.Prime()
    return ExtraFeat.Apply(true)
end

--- Returns "feat flag on 12 of 12 rows" for the log; an error becomes the text.
function ExtraFeat.DescribeFlags()
    local ok, text = pcall(function()
        local rows = ExtraFeat.Rows()
        local on = 0
        for _, row in ipairs(rows) do
            if row.AllowImprovement == true then
                on = on + 1
            end
        end
        return string.format("feat flag on %d of %d rows", on, #rows)
    end)
    return ok and text or ("feat flags unreadable: " .. tostring(text))
end

local function Describe(label, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        return label .. " failed: " .. tostring(result)
    end
    return string.format("%s: %d rows of %d classes (%d changed)", label, result.Rows, result.Classes, result.Changed)
end

--- Applies the setting and returns a line for the log; an error becomes a log line too.
function ExtraFeat.ApplyAndDescribe(on)
    return Describe("Extra feat " .. (on and "on" or "off"), ExtraFeat.Apply, on)
end

--- Primes the flags for a load and returns a line for the log.
function ExtraFeat.PrimeAndDescribe()
    return Describe("Prime", ExtraFeat.Prime)
end

return ExtraFeat
