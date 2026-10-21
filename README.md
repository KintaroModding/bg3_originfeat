# Origin Feat

Every character picks a feat at level 2. An MCM switch turns it off after the first level-up, so later classes give no extra feats.

A mod for Baldur's Gate 3 (Patch 8), made with game version 4.1.1.7398727. It needs
[Norbyte's Script Extender](https://github.com/Norbyte/bg3se) and the
[Mod Configuration Menu](https://github.com/AtilioA/BG3-MCM) (MCM) 1.41. This README is for developers. What the mod
does, how to install it and its compatibility are in [openmods.md](openmods.md), the mod page on
[openmods](https://openmods.nexus).

## How it works

The level-up screen shows the feat page when the progression row of the new level has `AllowImprovement`. The base
game sets it on class levels 4, 8 and 12 (and a few more). `Shared/ExtraFeat.lua` sets it, while the setting
`extra_feat_on_level_up` is on, on the class level 2 rows (`Level` 2, not `IsMulticlass`) of the base classes: the
class descriptions without a `ParentGuid`, so classes of other mods count too, and the NPC and origin tables (which
have no class description) do not. The base game has 12 such rows.

Class rows count the class level, so while the setting is on, every class a character takes to level 2 gives a feat:
the player turns the setting off after the first level-up. Race rows (`ProgressionType` 2) count the total character
level, but the level-up screen ignores `AllowImprovement` there (game test of 1.0.0.0).

The script changes the flags in the static data (`Ext.StaticData`). Game tests (1.0.0.1 to 1.0.0.3) showed when the
game reads them:

- The first save load after the game start reloads the static data and takes the flags; later loads (in game or from
  the main menu) keep those values until the game ends.
- Class level 2 shows the feat page only when the flag was on at that load and is on at the level-up. So while a save
  loads (`StatsLoaded` in the client, `SessionLoading` on both sides) the script sets the rows on, and after the load
  (`SessionLoaded`) and after every change of the setting it sets the setting's value. The switch then works at once,
  in both directions.
- A multiclass row (`Level` 1, `IsMulticlass`) uses only the value from that load, so no setting can control it during
  play: the mod leaves these rows alone, and a new class never gives a feat.

The static data outlives the Lua state of a session, so the script cannot know a row's original value after a load:
off sets `false`, which is the base game's value on all these rows. The server log also shows the flags at each
level-up.

## Settings

The Mod Configuration Menu shows the settings of `MCM_blueprint.json`. `Shared/Settings.lua` reads them:
`Settings.Get(id)` returns the value and its source (`MCM` or `default`), and `Settings.OnChange(fn)` reports a change
or an MCM profile switch. Without MCM (missing, or loaded after this mod) the values of `Settings.Defaults` apply. The
tests check that `Settings.Defaults` and the blueprint list the same settings with the same defaults. `meta.lsx` lists
MCM 1.41.0.0 (`755a8a72-407f-4f0d-9a33-274ac0f0b53d`) as a dependency, so the mod managers load MCM first; only then
does MCM put its `MCM` table into this mod. The setting ids are part of the players' saved settings: never rename one
after a release.

## Build

Requirements: Windows PowerShell and [LSLib](https://github.com/Norbyte/lslib/releases) (`Divine.exe`).
`build.ps1` looks for `_tools\lslib\Packed\Tools\Divine.exe` in the parent folders of the project; set `BG3_TOOLS` to
a folder that holds `lslib\` to use another place.

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1             # dist\bg3_originfeat.pak
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Deploy     # build, then copy the .pak to the Mods folder
powershell -ExecutionPolicy Bypass -File .\deploy.ps1 -Wait      # copy the .pak when the game is closed
```

`deploy.ps1` copies the .pak to the `Mods` folder below `BG3_DATA_DIR` (the BG3 user-data folder), else to
`%LOCALAPPDATA%\Larian Studios\Baldur's Gate 3\Mods`; `-ModsDir` overrides both. The running game locks the .pak, so
the script stops (exit code 2) or, with `-Wait`, waits until the game is closed.

## Project layout

```
src/                                     Mod files (packed into the .pak)
  Mods/bg3_originfeat/meta.lsx           Mod metadata (UUID f79371e9-6c6f-41ba-8a65-f04e668b6020), MCM dependency
  Mods/bg3_originfeat/MCM_blueprint.json The Mod Configuration Menu page (the settings)
  Mods/bg3_originfeat/ScriptExtender/
    Config.json
    Lua/BootstrapServer.lua              Server entry point
    Lua/BootstrapClient.lua              Client entry point
    Lua/Shared/Common.lua                Shared helpers (mod version)
    Lua/Shared/FileWriter.lua            Throttled file output in the Script Extender folder
    Lua/Shared/Settings.lua              MCM settings with defaults (Settings.Defaults)
    Lua/Shared/ExtraFeat.lua             The feat flag on the class rows of the first level-up in a class
    Lua/Server/ServerLog.lua             server.log
    Lua/Client/ClientLog.lua             client.log
docs/                                    Cover and screenshots for openmods.md
tests/                                   Offline tests (Lua 5.4 through lupa)
scripts/bump_version.py                  Raises the last version digit in meta.lsx
scripts/show_log.py                      Prints the mod's log files and MCM settings
build.ps1                                Builds dist/bg3_originfeat.pak from src/ (.loca.xml -> .loca, .lsf.lsx -> .lsf)
deploy.ps1                               Copies the .pak to the Mods folder
openmods.json, openmods.md               Data and mod page for openmods.nexus
```

Versioning: every change raises the last version digit (1.0.0.0 -> 1.0.0.1):

```powershell
python scripts\bump_version.py           # both Version64 values in meta.lsx
python scripts\bump_version.py --show
```

Logs: the mod writes `server.log` and `client.log` to
`%LOCALAPPDATA%\Larian Studios\Baldur's Gate 3\Script Extender\bg3_originfeat\`. Each load writes a line like
`Origin Feat 1.0.0.1 loaded.`, so the logs show which version runs, and server.log gets a line with every setting,
for example `Settings: extra_feat_on_level_up = true (MCM).`, also after each change. Both logs then show what
the setting did, for example `Extra feat on: 12 rows of 12 classes (12 changed).` MCM stores the settings in
`Script Extender\BG3MCM\Profiles\<Profile>\bg3_originfeat\settings.json`. `python scripts\show_log.py` prints the
newest log lines and these settings (from `BG3_DATA_DIR`, if set).

Tests:

```powershell
python -m pip install lupa
python tests\run_tests.py
```

The tests run every mod script against mocks of the Script Extender API (`tests/harness.lua`). The IMGUI, audio and
resource mocks are checked against the Script Extender IDE helpers (`tests/gen_extui_api.py` refreshes
`tests/extui_api.json`), so a property or method that does not exist in the real API fails the tests.

## License

MIT, see [LICENSE](LICENSE).
