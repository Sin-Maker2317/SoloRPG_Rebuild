Enemies: store enemy prefab templates here.

Templates must include:
- A `Humanoid` child
- A `HumanoidRootPart` child (PrimaryPart)
- `IsEnemy` attribute set to true on the Model

Spawners expect `Workspace:FindFirstChild("Enemies")` at runtime.
