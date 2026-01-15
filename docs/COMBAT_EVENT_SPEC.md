# CombatEvent Payload Specification

This file documents the server -> client `CombatEvent` payload shapes used across the project.

Fields common to all payloads:
- `type` (string): event kind (see below)
- `timestamp` (number, optional): os.clock() value server-side when event fired

Event types and payloads

- `HitConfirm`
  - `type`: "HitConfirm"
  - `damage`: number
  - `targetName`: string
  - `attackerId` (optional): player.UserId or actor id

- `SkillUsed`
  - `type`: "SkillUsed"
  - `skillId`: string
  - `damage`: number
  - `cooldown`: number

- `SkillHit`
  - `type`: "SkillHit"
  - `skillId`: string
  - `damage`: number
  - `target`: string (target model name)

- `DodgeStarted` / `DodgeFailed` / `DodgeApproved`
  - `type`: "DodgeStarted" | "DodgeFailed" | "DodgeApproved"
  - `duration` (for started): number
  - `reason` (for failed): string

- `StatAllocated`
  - `type`: "StatAllocated"
  - `field`: string (e.g., "str", "agi")

- `GuildSet`
  - `type`: "GuildSet"
  - `guildId`: string
  - `guildName`: string

- `ItemEquipped`
  - `type`: "ItemEquipped"
  - `itemId`: string
  - `itemName`: string

- `GateStarted` / `GateFailed`
  - `type`: "GateStarted" | "GateFailed"
  - `gateId` (started): string
  - `gateName` (started): string
  - `reason` (failed): string

- `MatchCreated` / `MatchFailed`
  - `type`: "MatchCreated" | "MatchFailed"
  - `matchId` (created): string
  - `arena`: string
  - `reason` (failed): string

Notes
- Keep payload lightweight and serializable. Avoid sending full Instance references across the network.
- Add `timestamp` where useful for client-side interpolation or ordering.
- Update this file when new `CombatEvent` types are added.
