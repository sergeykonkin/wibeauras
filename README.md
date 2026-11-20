# WibeAuras

WibeAuras is a standalone, code-first addon for WoW Forever. It displays buffs, debuffs, cooldowns, and other trigger states.

## Player workflow

1. Before starting WoW, copy `WibeAuras` and `WibeAurasArchive` into `Interface/AddOns`. On first install, have your agent also copy [the starter configuration folder](examples/WibeAurasConfig) into `Interface/AddOns` as `WibeAurasConfig`.
2. Tell your AI agent what to display and when it should appear. Give the agent access to `Interface/AddOns/WibeAurasConfig` and this repository's configuration reference.
3. After the agent updates the aura files in `Interface/AddOns/WibeAurasConfig`, type `/reload` in WoW. The auras use their load and trigger conditions.

Addon updates replace `WibeAuras` and `WibeAurasArchive`. The installed `WibeAurasConfig` folder belongs to the player and stays outside those updates.

## Example configuration

For a fresh install, you can use the [demo config](examples/demo/WibeAurasConfig) as your `WibeAurasConfig` folder. It displays a status label and a player health bar above the center of the screen. A third label appears during combat.

To try the demo with an existing configuration, have your agent add the four demo files and their manifest entries to your existing folder.

## Configuration reference for agents

Follow the [agent guide](AGENTS.md) to create, edit, group, remove, and verify auras. It includes an example and links to the configuration fields in the engine.

Other addons can use `WibeAurasAPI:GetAuras()`, `:ExportAura()`, and `:DecodeAuraString()`. WibeAuras uses the `!WIBE:2!` export format and stores its runtime settings and persistent aura state in its own SavedVariables.

## FAQ
### Q: I thought Blizzard disabled addons for WoW Forever just like Retail?
*A: Addons are not disabled they just work differently now. There are "Secret" APIs which cannot be controlled by addons. Blizzard controls these APIs but Addons can tell them how to be displayed through the Blizzard CDM (Cooldown Manager). To see Blizzard's CDM, type `/cdm` in game chat.*

### Q: What is the Blizzard Cooldown Manager (CDM)?
*A: The CDM displays information from the buff bar or action bar. Enable it in WoW's Gameplay Enhancement settings or configure WibeAuras to run it in the background.*

### Q: What's up with Modern Auras not being able to do `xyz`?
*A: Think of a Modern aura icon as a picture the game draws for you, not one the addon draws. During a fight, the game locks that picture: addons can look at it but can't touch it. So anything the addon figures out on its own (like "you're out of range") can't be painted onto that icon until the fight ends, and that's when it catches up.*

*The only exceptions are the 'Aura Active' conditions, because the game itself paints those when it draws the icon.*

*The addon draws Legacy icons and can recolor them during combat. Legacy icons cannot read restricted aura data in combat. A separate addon-drawn indicator can display information such as range over a Modern icon.*

## Acknowledgements

This project is based on [ForeverAuras](https://www.curseforge.com/wow/addons/foreverauras), which is based on [WeakAuras2](https://github.com/WeakAuras/WeakAuras2).

- Original work - Copyright © Stanzilla

This modified version is licensed under the GNU General Public License, version 2.0.

- Modifications and additions - Copyright © 2026 Neroxrw
- See [LICENSE](LICENSE) for the complete GPL-2.0 license. Bundled libraries retain their upstream notices.

This project also includes code from [M33kAuras](https://github.com/m33shoq/M33kAuras).
