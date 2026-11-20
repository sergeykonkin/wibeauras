# Configure WibeAuras

Use this guide when a player asks you to create, change, group, or remove an aura in WoW Forever.

The [demo config](examples/demo/WibeAurasConfig) shows a complete manifest, a dynamic group, and separate files for text, player health, and combat status.

## Find the player's configuration

- Locate `Interface/AddOns/WibeAurasConfig` in the player's WoW Forever installation. If several installations match and you cannot identify the intended one, ask which to use.
- Read `WibeAurasConfig.toc`, `Settings.lua`, and the aura files relevant to the request. The [starter folder](examples/WibeAurasConfig) is for first-time setup. Preserve an existing player configuration when installing or updating WibeAuras.
- Make player-specific changes in the installed `WibeAurasConfig` folder. It sits beside `WibeAuras` and `WibeAurasArchive` and stays outside engine updates. Leave engine source and SavedVariables alone for routine aura requests.

## Turn the request into a display

Identify the display type, the unit or spell to track, when it should show, and where it should appear. Use existing auras for layout conventions. Confirm ambiguous spell names and rank requirements against a WoW Forever source before choosing an ID.

| Need | Where to check |
| --- | --- |
| Show only for a class, specialization, zone, or combat state | `load` fields in [Prototypes.lua](WibeAuras/Prototypes.lua) |
| Show based on health, player conditions, or a spell cooldown | Event prototypes in [Prototypes.lua](WibeAuras/Prototypes.lua). Use the prototype's exact event key and trigger type. |
| Match a buff or debuff | Legacy `aura2` fields in [BuffTrigger2.lua](WibeAuras/BuffTrigger2.lua) or Modern `secretAura` fields in [SecretAuraTrigger.lua](WibeAuras/SecretAuraTrigger.lua) and [BlizzardAuraDisplay.lua](WibeAuras/BlizzardAuraDisplay.lua). |
| Track a Blizzard Cooldown Manager entry | [CooldownViewerTrigger.lua](WibeAuras/CooldownViewerTrigger.lua) |
| Set position, dimensions, text, or appearance | Defaults in [RegionTypes](WibeAuras/RegionTypes) and [SubRegionTypes](WibeAuras/SubRegionTypes). Look up model file IDs in [ModelPaths.lua](WibeAurasModelPaths/ModelPaths.lua). |
| Change appearance after a trigger fires | [Conditions.lua](WibeAuras/Conditions.lua) and the region's supported properties |

Check both load conditions and trigger settings. Load conditions decide where and when the engine evaluates the aura. Triggers decide when the display activates. Some prototype fields need a matching `use_*` field. Read the prototype before setting either field.

For requests that depend on restricted combat aura data, check what a Modern display supports before committing to a result. Prefer built-in triggers. Use custom Lua when the requested behavior requires it and the client exposes the necessary data.

## Add or change an aura

1. Put one display or group in each file under `Auras\`. Use a distinct filename, such as `Auras\CombatStatus.lua`.
2. Assign the display to `WibeAurasConfig.displays["Aura ID"]`. Use a unique aura ID and a unique, nonempty `uid`. Preserve the UID when editing or renaming an aura so it keeps its `aura_env.saved` state. The loader supplies `id` and `internalVersion`.
3. List a new file once in `WibeAurasConfig.toc` after `Settings.lua`. Write the aura file before updating the manifest. Changing a listed file's contents requires no manifest change.
4. Write each changed file completely to a temporary file in the same folder, then replace the destination. Preserve unrelated files and manifest entries.

Example for `Auras\CombatStatus.lua`

```lua
WibeAurasConfig.displays["Combat status"] = {
  uid = "WibeCombat01",
  regionType = "text",
  displayText = "In combat",
  yOffset = 150,
  load = { use_combat = true },
  triggers = {
    {
      trigger = { type = "unit", event = "Conditions", use_alwaystrue = true },
      untrigger = {},
    },
  },
}
```

The combat load condition controls visibility. For an always-visible text check, omit the `load` field. Keep shared options in `Settings.lua`. For example, set `cdmHideBlizzard = true` beside `displays` to run the Blizzard Cooldown Manager in the background.

## Group, rename, or remove displays

- To create a group, give its file a unique ID and UID and use `regionType = "group"` or `"dynamicgroup"`. List member IDs in the group's `controlledChildren` array in display order. Set each member's `parent` to the group ID. List every group and member file in the manifest. A dynamic group can contain displays only.
- To rename a display, change its table key and update references to its ID, including group membership and aura-to-aura anchors. Keep its UID. Update the manifest entry if you also rename the file.
- To remove a display, remove its manifest entry and group references. When removing a group, clear or reassign each retained child's `parent`. Remove a file if the user requested deletion and the file contains only the requested display.

## Verify and hand off

- Check that each manifest path exists, each aura ID and UID is unique, and all parent and child references agree. Check for cycles and unresolved anchors. Run a Lua syntax check if a compatible interpreter is available.
- Ask the player to type `/reload` and verify visibility in the intended game state. For the example above, check that it appears in combat and disappears after combat.
- If the display is missing, check that WibeAuras Config is enabled, the manifest lists the file, and the current character meets the load and trigger conditions. Inspect chat for errors prefixed with `WibeAurasConfig`. Use `/wibeauras modern <aura ID>` for Modern aura diagnostics or `/wibeauras cdm <aura ID>` for Cooldown Manager diagnostics.
- Report the changed files, the expected display behavior, and whether you verified it in the game.
