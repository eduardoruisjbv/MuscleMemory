# MuscleMemory

World of Warcraft Retail 12.1 addon. Version **0.7.0**, with an English editor and no external libraries.

MuscleMemory maps an ability’s **primary purpose** to the same action-bar position on another character. It considers specialization, rotation role, usage frequency, cooldown, charges, and conditions such as kills, as well as cast time and relative resource cost. Different resource types, such as runes and rage, are not compared directly.

## Getting started

1. Restart WoW if it was already open when you installed the addon. Enable **MuscleMemory** in the addon list.
2. Log in to your main character, arrange your action bars, and run `/mm`.
3. Click **Capture this character’s bars**. This saves a fixed reference for each character and specialization.
4. Log in to an alt, open `/mm`, and select the main character’s **class** and captured **reference**.
5. The alt’s class and specialization default to the current character. The map is prefilled with automatic suggestions.
6. Click **Apply suggestions** to use the map. To review it, open **Edit mappings** and adjust entries by clicking or dragging. **Preview** is optional.
7. Choose **Mode: character mappings** or **Mode: priority leveling**. To automate, enable **Automatic** and confirm **Authorize and enable**. Previous authorizations are disabled in this update.

The main screen shows a compact table of source, purpose, and destination. Searches across all three columns, filters, and draggable lists are available under **Edit mappings**. **Use suggestions** restores the automatic map and replaces manual mappings for this pair without changing the action bars until you apply it. Each mapping row highlights its purpose, captured keybinding, and associated abilities. Technical slot numbers appear in tooltips. **Restore bars** undoes the last application; right-clicking an individual suggestion restores only that mapping.

Right-click a destination icon to restore its automatic suggestion or exclude an ability from mapping. Manual choices are saved per main reference, class, and destination specialization. Changing the selection disables automatic application until you enable it again.

## Mounts, utilities, and leveling (0.7.0)

- Native mounts, macros, items, and flyouts from the source appear in the list and filters. Mounts are assigned the **travel / flying / speed** purpose while preserving the original selection. Availability is checked on the current character; an unavailable mount is never replaced with a random one.
- **Path of Frost** (DK) and **Water Walking** (Shaman) have their own purpose. **Battle Shout** remains a group buff: walking on water and increasing attack power have different effects, and can be mapped manually if the player wants one shared preparation key.
- In **priority leveling** mode, there is no need to capture another character. The currently learned spellbook and specialization determine eligible abilities. The mode arranges combat abilities in priority slots, places new abilities, and preserves existing utility, macro, and item positions. Available mounts follow the selected reference while respecting pinned positions and other protected actions.
- Eighteen specialization profiles have an explicit action-bar order; all others use ability purpose as a fallback. This order is a layout preference, not a DPS simulation or a prediction of which ability to cast. The native assisted-rotation list is not used as a priority order.
- Open **Edit mappings** and right-click an ability to raise/lower its priority, pin its current position, or exclude/include it in the layout. **Restore default priorities** is in the mode menu. Preferences are saved per character and specialization.
- Leveling consent applies to the character and its specializations, including progression before the first specialization. Automation responds to login, level, spellbook, talent, and specialization changes, with events coalesced. It waits for a valid state during combat, while the cursor is occupied, or while a temporary action bar is active.
- Automatic mode starts disabled and requires **Authorize and enable**. Changing mode/reference or clearing the option disables automation. **Restore bars** also disables automatic mode for the character’s specializations. In automatic mode, the undo record accumulates from the first change after consent for the current specialization; manual application restores only the latest application. Spells that are no longer available may remain pending in the undo record.
- This update adds Lua files to the TOC: **fully exit and restart WoW** to load them all.

## Commands

| Command | Action |
| --- | --- |
| `/mm` or `/musclememory` | Open/close the editor |
| `/mm capture` | Save the current bars as a reference |
| `/mm apply` | Apply the map to the current character |
| `/mm undo` | Restores this specialization’s backup and disables automatic mode |

## How suggestions work

Suggestions are automatic: capture your main character once. Characters without a selected reference use the saved main reference or the most recent capture from another profile. Editing and preview are optional. DK ↔ Warrior has initial specialization-specific mappings, with alternatives when a talent is unavailable.

- Selected ability profiles for 17 specializations across all 13 classes were reviewed against Wowhead and Icy Veins guides for patch 12.1. Usage cadence and resource/proc effects rank candidates; missing reviewed profiles or resource differences do not block functional suggestions. Usage-based alternatives appear as **Automatic alternative**, with differences shown in the tooltip. Explanations and sources are also shown there. Exact coverage is in [Rotations and sources](docs/ROTACOES-E-FONTES.md).
- The native Single-Button Assistant provides an assisted-rotation signal outside combat. The list order does not determine mappings; an unknown ability is not assigned a purpose just because it appears there. The assistant button has its own category when found in the spellbook, and the addon remains usable when the API is unavailable.
- The active spellbook provides the abilities actually available for the current talents and specialization.
- A review of core abilities across all 13 classes separates primary purpose from secondary effects. Tooltips show the authored description, sources, reference cooldown, charges, and usage conditions. Coverage and caveats are in [Ability audit](docs/AUDITORIA-HABILIDADES.md).
- **Copy before comparison:** the same ID, base/replacement ID, or same name in the same class receives the highest priority. Different IDs in the action bar and spellbook are resolved through the reference. The same ability can fill its original slots even when it appears under multiple IDs; the UI labels this **Automatic copy**. The active spellbook determines which ID can be placed on the destination.
- **Secondary effects contribute to ranking:** resource/proc effects, extra healing, control, area damage, control immunity, and interactions with offensive windows help rank alternatives. Tooltips identify secondary effects not confirmed on the alternative and differences in rotation cadence. Area damage and group control remain distinct dimensions. Rules and examples are in [Primary and secondary effects](docs/PRINCIPAL-E-SECUNDARIAS.md).
- **Reserved emergency-survival slot:** Death Pact, Divine Shield, and Ice Block share the intent of surviving an emergency. They can receive a cross-class automatic alternative while keeping their primary mechanisms explicit: healing and immunity have different effects. Immunity does not restore health; Ice Block prevents actions. Cooldowns, restrictions, and additional effects appear in the tooltip. This approximation is limited to buttons explicitly designated for emergencies; it does not equate every heal with immunity or every defense with a last resort.
- **Group control and area burst:** Blinding Sleet is control without damage; Frostwyrm’s Fury deals area damage during an offensive window, with additional stun/slow effects. The engine compares the former with group controls and the latter with area attacks on cooldown. Differences such as disorient/fear/stun, breaking on damage, and secondary effects are flagged; single-target control does not automatically replace group control.
- **Shared racial abilities:** an ability learned by both the main and destination receives the highest priority, even in older captures without classification. Will to Survive (59752) breaks stuns. The catalog does not add racial abilities to every character of a class: they must appear in the current spellbook or on a visited character. Logging into the destination confirms actual availability.
- **Breaking crowd control:** Icebound Fortitude is classified primarily as a stun break, with damage reduction retained as a secondary tooltip effect. A fear break does not automatically replace a stun break. Lichborne and Berserker Rage can share the purpose of breaking fear, with other control differences flagged.
- **Healing frequency:** Death Strike is repeatable resource-based healing/recovery. Victory Rush has a cooldown reset by a kill, while Victorious Vigor requires a recent kill. These abilities do not automatically replace Death Strike. Death Pact → Victory Rush is a preference for cooldown-based healing: the reviewed nominal cooldowns of 120 and 25 seconds remain distinct and are shown as an automatic alternative. Equal availability or power is not assumed.
- Victorious Vigor also does not automatically replace Death Pact: requiring a kill before healing differs from having an emergency heal on cooldown. If Victory Rush is not learned, the addon preserves the button without inventing this alternative.
- Base cooldowns and charge counts are collected out of combat when the APIs return public values; in-progress charge recovery can provide observed durations. Reviewed nominal values are used when no usable static value is available. The engine does not use remaining cooldown time or momentary readiness to decide mappings; a ready ability is still a cooldown ability. Talent modifications that the API does not expose statically remain a limitation.
- Abilities confirmed to be removed or passive are excluded from active-button suggestions. Reviewed IDs expand the catalog; unknown abilities remain available for manual editing.
- An initial catalog identifies purposes such as resource generation, primary spender, area spender, interrupt, defense, mobility, and healing across all 13 classes. Defenses also describe protected school, mechanism, target, usage cadence, and effect coverage.
- Physical defense, magical defense, and immunity preserve distinct schools and targets. Within the same school, target, cadence, and coverage, different defense mechanisms may receive a flagged automatic alternative. Mixed effects remain individually represented. Self/ally healing, direct/periodic/area healing, control types, and mobility also refine compatibility.
- The same spell can serve different purposes by specialization. Death Strike is treated as a defensive spender in Blood and as healing in DPS specializations.
- Abilities with compatible purpose and behavior receive suggestions. Designated emergency slots and group controls allow flagged approximations. Other comparisons preserve modeled school, target, coverage, and availability. Cast time and relative cost refine the choice. Automatic destinations are reserved for distinct sources; copies of the same ability with different IDs preserve all corresponding slots. A manual choice may reuse a destination. Manual choices across different purposes show a warning and are still respected.
- Automatic assignment is greedy, ordered by compatibility and IDs for stable results; it does not search for a globally optimal solution.
- Unknown abilities are listed with an estimated purpose but do not receive automatic mappings based on that estimate. The exception is the same ability actually available in both profiles; its own button can be preserved without estimating its purpose.
- **Not configured** means classification is insufficient or a choice is pending. **No direct catalog match** means a known source has no fully compatible destination in the available data. **Unavailable** means a saved manual destination is not in the current list. These states do not remove action-bar actions.
- The catalog is an initial set of purposes, not a complete rotation simulation. Talents, game changes, and player priorities may require adjustments.
- For characters that are not logged in, the editor combines the base catalog with spellbooks from characters you have visited. Actual availability is checked when you log in to the destination. Application is available only for the current character and specialization.

## Action bars and restoring

The addon works with Blizzard slots **1–72 and 145–180**, preserving the main character’s original indices. This includes normal pages and additional bars. Form/stance, vehicle, possession, override, and extra-action bars are not mapped. The addon does not change keybindings; it assumes characters use equivalent bindings for the same slots.

New captures also store actual Blizzard action-bar keybindings and click bindings for those buttons. Preview shows the destination’s current bindings. If a slot to be changed has a captured key with no equivalent on the destination, automatic application is disabled with an explanation; manual application remains available. Older captures without keys show **Keybinding not captured** and must be recaptured to enable this comparison. Inactive conditional pages are not assigned invented keybindings.

During mapping, empty slots and slots containing spells or mounts may be changed. Different destination macros, items, and flyouts are preserved. Main-character slots without a mapping are not cleared. Mounts use the exact source selection, including the random-favorites button; the addon does not choose which mount you prefer. The collection must make the same mount available to the character, and the mount must be visible in the filters to be picked up. Macros are copied only when the destination already has one with identical contents; the source numeric index is never reused. Older macro captures must be refreshed to record their contents. Utility items are copied when available; flyouts remain visible as pending and are not mapped.

Application is blocked during combat or while temporary bars are active. Talent/specialization events received in combat are processed after combat ends. Each application saves the previous slots before changing them. If the API rejects a change, the process stops and reports that `/mm undo` is available. Undo preserves slots you edited afterward; old spells that can no longer be placed remain pending restoration. Manual mode records only the latest application; automatic mode accumulates changes for the authorized character/specialization session.

## Current limitations

- Retail 12.1; Classic is not implemented.
- Visited characters appear individually in the source list with name, realm, and specialization. Outside automatic mode, bars are recorded on login and logout; explicit captures remain fixed and take precedence. Older records without bars appear as **not captured**: log in to the character and capture their bars. The addon cannot read action bars directly from the server for characters who are logged out. SavedVariables are shared within the same account/installation.
- Pet spellbooks, spells inside flyouts, and custom bars outside Blizzard slots are not mapped. Macros are preserved by exact content; the addon does not interpret or create macros.
- The catalog does not cover every ability, newly added specialization, or talent replacement. New specializations for the current character are discovered at runtime; unclassified abilities remain manual.
- Effect profiles represent an ability’s base function. Talent modifications, encounter-specific exceptions, and PvP/PvE differences may require manual adjustments. The model does not claim equivalence in power, duration, or reduction percentage.
- The addon does not analyze combat or choose which ability to cast. Automation arranges the layout out of combat.
- The editor and protected APIs still require validation inside WoW. Local checks use LuaJIT and simulated APIs; they do not prove frame, cursor, talent, or taint behavior in the real client.

## Installation

Copy the `MuscleMemory/` folder (the one containing `MuscleMemory.toc`) into `_retail_/Interface/AddOns/`. Its contents should end up in `AddOns/MuscleMemory/`, without an extra nested folder.

Data is stored in `WTF/Account/<account>/SavedVariables/MuscleMemory.lua`, outside the addon code.

## Development

| File | Responsibility |
| --- | --- |
| `MuscleMemory/Catalog.lua` | Base classes and purposes by spell/specialization |
| `MuscleMemory/Rotations.lua` | Reviewed contexts, guide sources, and native assistant integration |
| `MuscleMemory/Purposes.lua` | Reviewed purposes, cooldowns, charges, conditions, and racial abilities |
| `MuscleMemory/Effects.lua` | Primary/secondary effects, group control, and emergency slots |
| `MuscleMemory/FunctionModel.lua` | Primary-purpose rules, cadence, and cooldown metadata |
| `MuscleMemory/Engine.lua` | Compatibility, manual priorities, and change plan |
| `MuscleMemory/Core.lua` | Spellbook, profiles, events, application, and restore |
| `MuscleMemory/Actions.lua` | Mounts and utility actions, exact identity, and visited references |
| `MuscleMemory/Leveling.lua` | Bar priorities, pinned positions, progress, and consent |
| `MuscleMemory/UI.lua` | Editor, class/specialization selection, and ability drag-and-drop |

Run `luajit tests/run.lua` from this directory for local checks. The real-client validation checklist is in `docs/VALIDACAO-NO-WOW.md`.

No tests were run for version 0.7.0 in this pass. Local compilation checks Lua syntax; mappings and addon behavior still need validation in WoW. Results from earlier versions do not validate the new rules.

The menu design is in `docs/UI-DESIGN.md`, and comparison rules are in `docs/CLASSIFICACAO.md`. Frames are reused, mapping context is cached, and the hidden interface does not rebuild lists. The opening animation lasts 120 ms; there is no continuous `OnUpdate` loop.

APIs checked against Blizzard UI code distributed in the mirror [wow-ui-source](https://github.com/Gethe/wow-ui-source): [spellbook](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua), [spells](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua), [specializations](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpecializationInfoDocumentation.lua) and [action buttons](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua).
