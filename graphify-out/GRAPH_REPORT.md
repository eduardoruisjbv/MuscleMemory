# Graph Report - MuscleMemory  (2026-10-26)

## Corpus Check
- 18 files · ~26,844 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 4 file(s) not represented in the graph (top: (none) 4)

## Summary
- 201 nodes · 406 edges · 18 communities (10 shown, 8 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `be79059c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- UI.lua
- Core.lua
- steps
- FunctionModel.lua
- Actions.lua
- Collection.lua
- MuscleMemory
- Catalog.lua
- Leveling.lua
- Rotations.lua
- Engine.lua
- MuscleMemory 0.7.0 beta
- MuscleMemory 0.8.0-beta.1
- MuscleMemory 0.8.0-beta.2 — HOTFIX
- MuscleMemory 0.8.0-beta.3

## God Nodes (most connected - your core abstractions)
1. `MM:RefreshUI()` - 23 edges
2. `MM:CreateUI()` - 18 edges
3. `MM:Scan()` - 14 edges
4. `MM:CreateRow()` - 14 edges
5. `MM:Menu()` - 12 edges
6. `MM:ShowPreview()` - 12 edges
7. `MM:StopDrag()` - 11 edges
8. `MM:Copy()` - 10 edges
9. `MM:Settings()` - 10 edges
10. `MM:Context()` - 10 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (18 total, 8 thin omitted)

### Community 0 - "UI.lua"
Cohesion: 0.16
Nodes (42): animateOpening(), availabilityText(), bindings(), button(), enabled(), hint(), icon(), label() (+34 more)

### Community 1 - "Core.lua"
Cohesion: 0.19
Nodes (31): isLearned(), MM:Apply(), MM:Capture(), MM:ClearBars(), MM:Context(), MM:Copy(), MM:DescribePlanBindings(), MM:GetApplyState() (+23 more)

### Community 2 - "steps"
Cohesion: 0.08
Nodes (24): CF_API_TOKEN, tag, jobs, upload, name, permissions, contents, types (+16 more)

### Community 3 - "FunctionModel.lua"
Cohesion: 0.21
Nodes (16): controlBreak(), copy(), isHeal(), isRepeatable(), MM:ApplyPurposeProfile(), MM:CompareEffects(), MM:CompareUsage(), MM:GetFunctionProfile() (+8 more)

### Community 4 - "Actions.lua"
Cohesion: 0.29
Nodes (10): MM:ActionEntry(), MM:ActionKey(), MM:ActionMatches(), MM:DecorateAction(), MM:EnrichActions(), MM:FindExactMacro(), MM:PutAction(), MM:ResolveUtilityAction() (+2 more)

### Community 5 - "Collection.lua"
Cohesion: 0.29
Nodes (8): abilitySnapshot(), encodeJSON(), isArray(), jsonString(), MM:SetCollectionEnabled(), MM:ShowCollectionExport(), MM:StoreCollectionSnapshot(), MM:ToggleCollection()

### Community 6 - "MuscleMemory"
Cohesion: 0.20
Nodes (9): Action bars and restoring, Commands, Current limitations, Development, Getting started, How suggestions work, Installation, Mounts, utilities, and leveling (0.7.0) (+1 more)

### Community 8 - "Leveling.lua"
Cohesion: 0.39
Nodes (6): caster(), functionFamily(), MM:AutoAuthorized(), MM:BuildCurrentPlan(), MM:IsLevelingMode(), MM:ProgressiveDamageScore()

### Community 10 - "Engine.lua"
Cohesion: 0.60
Nodes (3): defenseKey(), MM:Score(), MM:Suggest()

### Community 11 - "MuscleMemory 0.7.0 beta"
Cohesion: 0.50
Nodes (3): MuscleMemory 0.7.0 beta, Upgrade, Validation status

## Knowledge Gaps
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Should `steps` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._