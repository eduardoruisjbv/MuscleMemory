# MuscleMemory 0.8.0-beta.3

- Fix a Lua error when right-clicking an ability in leveling mode; "Exclude from automatic layout" works again, and menu entries for removed features are gone.
- Retry the scan when the spellbook is not ready at login instead of failing on Apply or Clear bars.
- Use the same learned-ability check in full and light refreshes, so override spells are no longer dropped after a talent or spec change.
- Clearing the bars again after an interrupted clear keeps the original positions in Restore bars.
- The collection export reflects newly learned abilities without waiting for a full rescan.
- Equivalence (non-leveling) automatic mode no longer removes extra copies placed by the player.
- New messages, statuses and tooltips are now in English like the rest of the interface.

## Validation

- Every Lua file loads under luajit.
- In-client behavior still needs validation in WoW.
