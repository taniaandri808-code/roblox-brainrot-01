-- StormService.luau
-- One job: the Brainrot Storm threat. Every 90 seconds a storm sweeps the map
-- for 12 seconds and clears the brainrots off any unlocked base.

local StormService = {}
StormService.__index = StormService

local STORM_PERIOD = 90
local WARNING_SECONDS = 10
local STORM_SECONDS = 12

function StormService.new(deps)
	local self = setmetatable({}, StormService)
	self.BrainrotService = deps.BrainrotService
	self.World = deps.World
	self.Remotes = deps.Remotes
	self.rng = Random.new()
	return self
end

function StormService:makeCloud()
	local cloud = Instance.new("Part")
	cloud.Name = "StormCloud"
	cloud.Anchored = true
	cloud.CanCollide = false
	cloud.Size = Vector3.new(60, 14, 60)
	cloud.Color = Color3.fromRGB(45, 40, 60)
	cloud.Material = Enum.Material.SmoothPlastic
	cloud.Transparency = 0.35
	cloud.Position = Vector3.new(0, 60, 0)

	local light = Instance.new("PointLight")
	light.Name = "Flash"
	light.Range = 60
	light.Brightness = 0
	light.Color = Color3.fromRGB(190, 130, 255)
	light.Parent = cloud

	cloud.Parent = workspace
	return cloud
end

function StormService:start()
	task.spawn(function()
		local cloud = self:makeCloud()
		local flash = cloud:FindFirstChild("Flash")
		while true do
			task.wait(STORM_PERIOD)

			-- Warning phase: banner + countdown on every client.
			for t = WARNING_SECONDS, 1, -1 do
				self.Remotes.StormWarning:FireAllClients({ Phase = "Warning", Seconds = t })
				task.wait(1)
			end

			self.BrainrotService:setStormActive(true)
			self.Remotes.StormWarning:FireAllClients({ Phase = "Storm", Seconds = STORM_SECONDS })

			-- The cloud sweeps across the map.
			local start = Vector3.new(-140, 60, -40)
			local finish = Vector3.new(140, 60, 40)
			cloud.Position = start
			local steps = 24
			for i = 1, steps do
				cloud.Position = start:Lerp(finish, i / steps)
				if flash then
					flash.Brightness = (i % 2 == 0) and 4 or 0
				end
				task.wait(STORM_SECONDS / steps)
			end
			if flash then
				flash.Brightness = 0
			end

			-- Damage phase resolves per player at the end of the sweep.
			for player, state in pairs(self.BrainrotService.players or {}) do
				if not state.BaseLocked and #state.Characters > 0 then
					local lost = self.BrainrotService:removeRandomCharacter(player)
					if lost then
						self.Remotes.EventFeed:FireClient(player, "The storm blew " .. lost.Name .. " off your base! Buy a Lock!")
					end
				end
			end

			self.BrainrotService:setStormActive(false)
			self.Remotes.StormWarning:FireAllClients({ Phase = "Over", Seconds = 0 })
		end
	end)
end

return StormService
