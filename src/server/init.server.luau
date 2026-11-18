-- init.server.luau
-- BRAINROT EMPIRE — server entry point.
-- Builds the world, wires every service together and starts the game.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServerFolder = script.Parent
local WorldBuilder = require(ServerFolder.WorldBuilder)
local BrainrotCatalog = require(ServerFolder.BrainrotCatalog)
local BrainrotService = require(ServerFolder.BrainrotService)
local StormService = require(ServerFolder.StormService)
local RebirthService = require(ServerFolder.RebirthService)
local ThiefService = require(ServerFolder.ThiefService)

-- The Remotes folder must exist before the services create their events.
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- 1. Build the map and grab the references the services share.
local world = WorldBuilder.build(workspace)

-- 2. Core loop: figures, bases, income, locks.
local brainrotService = BrainrotService.new({
	Catalog = BrainrotCatalog,
	World = world,
	Remotes = remotes,
})

-- 3. Threats: the Brainrot Storm and the Thief.
local stormService = StormService.new({
	BrainrotService = brainrotService,
	World = world,
	Remotes = remotes,
})

local thiefService = ThiefService.new({
	BrainrotService = brainrotService,
	World = world,
	Remotes = remotes,
})

-- 4. Progression: rebirths at the altar.
local rebirthService = RebirthService.new({
	BrainrotService = brainrotService,
	World = world,
	Remotes = remotes,
})

-- 5. Players: hand out bases in a stable order as they join.
local nextBaseIndex = 0
local function onPlayerAdded(player)
	nextBaseIndex = (nextBaseIndex % #world.bases) + 1
	brainrotService:setupPlayer(player, nextBaseIndex)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	brainrotService:teardownPlayer(player)
end)

-- 6. Start everything.
brainrotService:start()
stormService:start()
thiefService:start()
rebirthService:start()

print("[BRAINROT EMPIRE] server ready")
