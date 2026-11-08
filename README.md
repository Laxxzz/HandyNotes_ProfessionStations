<p align="center">
  <a href="https://discord.gg/simplelootcouncil"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-discord.png" alt="Discord"></a>
  <a href="https://ko-fi.com/laxxz"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-kofi.png" alt="Ko-fi"></a>
  <a href="https://github.com/Laxxzz/HandyNotes_ProfessionStations/issues"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-issue.png" alt="Report an issue"></a>
</p>

**HandyNotes: Profession Stations** is a HandyNotes plugin for **Retail and WoW: Forever** that pins every profession crafting station on your world map and minimap: anvils, forges, cooking fires, moonwells, alchemy labs, looms and every other station a recipe needs.

## Features

- Every profession crafting station, on the map and minimap
- Station types grouped by profession, with Check all
- Icon scale and transparency options
- Record a station the addon is missing, right where you stand
- Hide any built-in pin, and bring it back later
- Left-click a pin for a TomTom waypoint (optional)

## Getting Started

Requires [HandyNotes](https://www.curseforge.com/wow/addons/handynotes). [TomTom](https://www.curseforge.com/wow/addons/tomtom) is optional. Install it, then `/reload`; the pins appear on their own.

Open the settings with `/pstations options`, or under HandyNotes settings > Plugins > Profession Stations. Standing at a station the addon does not know? `/pstations add <station type>` records it.

## Commands

`/pstations` (or `/pst`):

| Command | Effect |
|---|---|
| `options` (or `o`) | Open the settings |
| `add <station type> [label]` | Record a station where you stand. The type is a full name or the start of one (`add tanning rack`, `add tinker`) |
| `types` | List this game's station types |
| `remove` | Delete a recorded pin, or hide a built-in one, beside you (shift-right-click a pin does the same) |
| `restore` | Bring hidden pins back |
| `where` | Print your map id and position |

## Languages

Every client language: English, German, Spanish (Spain and Latin America), French, Italian, Korean, Brazilian Portuguese, Russian, and Simplified and Traditional Chinese. Station and profession names use the game's own translations. The interface text is machine-made drafts; corrections from native speakers are welcome. Individual object names such as "The Great Anvil" exist only in English in the sources, so other clients show the station type instead.

## Where the pins come from

The client has no API that lists world objects, so the pins are generated offline by `tools/build_data.py`: the crafting stations each profession recipe requires, matched to world object spawns and mapped onto the in-game map. Retail and Forever each get their own data. Objects new to Forever are not in the sources yet, so record them in game with `/pstations add`.

Spawn data is derived from [QuestieDB](https://github.com/Questie/Questie) (GPL-3.0) and the TrinityCore and cmangos world databases (GPL-2.0).

## AI Use

Claude was used in the development of this addon with a custom-built addon development tool constructed from Blizzard's API patch notes.

## Support

HandyNotes: Profession Stations is free. If it saves you hunting for the nearest anvil, you can support its development.

<p align="center"><a href="https://ko-fi.com/laxxz"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-kofi.png" alt="Support Laxx on Ko-fi"></a></p>

## Licence

See [LICENSE](LICENSE).
