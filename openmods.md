# Origin Feat

Every character picks a feat at level 2. An MCM switch turns it off after the first level-up, so later classes give no extra feats.

## What it does

- At level 2, the level-up screen shows the feat page: pick a feat or an ability score improvement, as at level 4.
- One switch in the Mod Configuration Menu, **Extra feat on level up** (on by default). While it is on, every class
  that reaches class level 2 gives a feat.
- Turn the switch off after your characters reached level 2. Then later classes give no extra feats. The switch works
  at once, without a reload.
- Works for every class, also classes from other mods.

## Screenshots

![Origin Feat cover](docs/cover.jpg)

## How to install

1. Install [Norbyte's Script Extender](https://github.com/Norbyte/bg3se). It updates itself.
2. Install the [Mod Configuration Menu](https://github.com/KintaroModding/bg3_mcm/releases/latest), version 1.41 or
   later. The official Mod Configuration Menu 1.41 or later works too; keep only one of them.
3. Download `bg3_originfeat.pak` from the latest release on GitHub.
4. Copy it to `%LOCALAPPDATA%\Larian Studios\Baldur's Gate 3\Mods`.
5. Enable **Origin Feat** in your mod manager (BG3 Mod Manager or the in-game mod manager), below the Mod
   Configuration Menu.

To update the mod, replace the `.pak` with the one from the new release. To remove it, disable it in the mod manager
and delete the `.pak`. Saves made with the mod can then show a warning about a missing mod.

## How to use

- Open the Mod Configuration Menu (main menu, Esc menu, or the Insert key) and select **Origin Feat**.
- **Extra feat on level up** (default: on): while it is on, class level 2 gives a feat. A change applies at once,
  also during a game.
- Start a new game with the switch on, level your characters to 2 in their first class and pick their feats. Then
  turn the switch off.
- The Mod Configuration Menu stores the settings in its profile, not in the savegame: turn the switch on again before
  you start the next new game.

## Compatibility

- Game version: Patch 8
- Works with mods that add feats: they show on the same feat page.
- Works with classes from other mods: the mod finds every class when a game loads.
- Mods that give a feat at class level 2 (for example "feat every level" mods): with the switch off, Origin Feat
  removes the feat flag of class level 2, also when the other mod set it.

## Known issues

- A new class (multiclass) never gives a feat from this mod, also not at level 2. Take level 2 in your first class,
  then multiclass. The game reads the feat flag of a new class only once per game start, so no switch can control it
  during play.
- Multiplayer is not tested yet. The host's setting counts.

## How to build

Anyone can build this mod from its source code and check that the download matches it.

1. Install the tools: Windows PowerShell 5.1 (part of Windows) and [LSLib](https://github.com/Norbyte/lslib/releases)
   v1.20.4. Put LSLib into a folder `_tools\lslib\` above the repository, or set `BG3_TOOLS` to the folder that holds
   `lslib\`.
2. Build it: `powershell -ExecutionPolicy Bypass -File .\build.ps1`
3. Find the file: `dist\bg3_originfeat.pak`

The offline tests need Python 3 with lupa: `python -m pip install lupa`, then `python tests\run_tests.py`.

## Credits

Made by Kintaro. MIT license: you may use, change and share this mod.
