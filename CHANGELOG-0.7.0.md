# MuscleMemory 0.7.0 beta

- Display native mount buttons and utility actions in the source list and filters.
- Copy the exact selected mount, including the random favorite button, when available on the destination character.
- Classify Path of Frost and Water Walking separately from attack-power buffs.
- List visited characters individually by character, realm and specialization; clearly identify profiles without a saved action-bar layout.
- Record visited layouts outside automatic mode while preserving explicitly captured reference layouts.
- Add a leveling layout mode that places learned abilities and updates combat-button priorities after level, spellbook, talent and specialization changes.
- Add explicit automatic-mode consent, custom combat-button priority, pinned positions, exclusions and restoration to the beginning of an automatic session.
- Preserve existing utility positions and protected item, macro and flyout actions in leveling mode. Travel buttons can follow the selected origin.
- Match macros by exact captured content instead of reusing an index from another character. Macros are not created or interpreted.
- Defer changes during combat, temporary bars and an occupied cursor. Disable automation if the game rejects a placement.

## Upgrade

Fully restart WoW: this release adds Lua files to the TOC. Existing automatic settings require new consent. Log into characters with an uncaptured profile and capture their bars to make those layouts available as origins.

## Validation status

Local Lua syntax compilation only. Automated tests were not run for this release. UI frames, mount cursor behavior, protected actions, leveling transitions and taint still require real-client validation.
