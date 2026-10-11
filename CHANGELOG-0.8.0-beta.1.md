# MuscleMemory 0.8.0-beta.1

- Expose a small public `MuscleMemoryAPI.GetImpactClassification(spellID)` API for camera and combat-feedback integrations.
- Classify reviewed, curated abilities as direct, mixed, periodic-only, non-damage, or unknown, using the active class and specialization.
- Infer direct damage only from curated primary-damage function profiles; IDs without sufficient evidence remain unknown.

## Validation

The API is source-reviewed and syntax-parsed with the addon. In-client integration behavior still needs validation after reloading WoW with Mythic View 3.2.0-beta.1.
