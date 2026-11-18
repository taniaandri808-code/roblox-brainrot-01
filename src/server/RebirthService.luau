-- RebirthService.luau
-- One job: rebirths. Trade everything for a permanent 2x income multiplier.

local RebirthService = {}
RebirthService.__index = RebirthService

function RebirthService.new(deps)
	local self = setmetatable({}, RebirthService)
	self.BrainrotService = deps.BrainrotService
	self.World = deps.World
	self.Remotes = deps.Remotes
	return self
end

function RebirthService:requirementFor(rebirths)
	return 10000 * (rebirths + 1)
end

function RebirthService:start()
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Rebirth"
	prompt.ObjectText = "Rebirth Altar"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 12
	prompt.Parent = self.World.rebirthPad

	prompt.Triggered:Connect(function(player)
		local state = self.BrainrotService:getPlayerState(player)
		if not state then
			return
		end
		local need = self:requirementFor(state.Rebirths.Value)
		local earned = state.Money.Value
		if earned < need then
			self.Remotes.EventFeed:FireClient(player, string.format("Rebirth needs $%d total earned. You have $%d.", need, earned))
			return
		end

		state.Rebirths.Value += 1
		state.Money.Value = 100
		-- Clear the base: every character goes back to the pasta beyond.
		for model, meta in pairs(self.BrainrotService.figures) do
			if meta.OwnerPlayer == player then
				self.BrainrotService.figures[model] = nil
				if model.Parent then
					model:Destroy()
				end
			end
		end
		state.Characters = {}
		self.BrainrotService:pulseIncome(player)
		self.Remotes.EventFeed:FireClient(player, "REBIRTH " .. state.Rebirths.Value .. "! All income now x" .. 2 ^ state.Rebirths.Value .. ". The Empire begins again.")
	end)
end

return RebirthService
