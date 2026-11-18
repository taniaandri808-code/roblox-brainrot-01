-- ThiefService.luau
-- One job: the roving thief. Every 60 seconds it walks to an unlocked base,
-- grabs a brainrot and runs; a nearby player can catch it for a bounty.

local ThiefService = {}
ThiefService.__index = ThiefService

local THIEF_PERIOD = 60
local WALK_SPEED = 14 -- studs per second
local CATCH_REWARD = 250

function ThiefService.new(deps)
	local self = setmetatable({}, ThiefService)
	self.BrainrotService = deps.BrainrotService
	self.World = deps.World
	self.Remotes = deps.Remotes
	self.rng = Random.new()
	return self
end

function ThiefService:makeThief()
	local model = Instance.new("Model")
	model.Name = "Thief"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.Size = Vector3.new(2.4, 4, 1.6)
	body.Color = Color3.fromRGB(35, 25, 40)
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Color = Color3.fromRGB(230, 200, 170)
	head.CFrame = body.CFrame * CFrame.new(0, 2.6, 0)
	head.Parent = model

	local bag = Instance.new("Part")
	bag.Name = "Bag"
	bag.Anchored = true
	bag.Size = Vector3.new(1.6, 2, 1.2)
	bag.Color = Color3.fromRGB(120, 90, 40)
	bag.CFrame = body.CFrame * CFrame.new(1.6, 0.5, 0)
	bag.Parent = model

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(6, 0, 1.6, 0)
	gui.StudsOffset = Vector3.new(0, 4.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 70, 70)
	label.TextStrokeTransparency = 0.2
	label.Text = "THIEF!"
	label.Parent = gui

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Catch! (+$" .. CATCH_REWARD .. ")"
	prompt.ObjectText = "Thief"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.Parent = body

	model.Parent = workspace
	model:PivotTo(CFrame.new(self.World.stormGate.Position))
	return model, prompt
end

-- Moves a model from where it stands to `target` at WALK_SPEED. Returns false
-- if the thief was caught mid-walk.
function ThiefService:walkTo(model, target, caught)
	local from = model:GetPivot().Position
	local distance = (target - from).Magnitude
	local steps = math.max(1, math.floor(distance / (WALK_SPEED * 0.1)))
	local origin = model:GetPivot()
	for i = 1, steps do
		if caught.Value then
			return false
		end
		local alpha = i / steps
		local pos = from:Lerp(target, alpha)
		model:PivotTo(CFrame.new(pos) * (origin - origin.Position))
		task.wait(0.1)
	end
	return true
end

function ThiefService:start()
	task.spawn(function()
		while true do
			task.wait(THIEF_PERIOD)
			if not self.BrainrotService:isStormActive() then
				-- Pick an unlocked base that actually has characters on it.
				local targets = {}
				for player, state in pairs(self.BrainrotService.players or {}) do
					if not state.BaseLocked and #state.Characters > 0 then
						table.insert(targets, player)
					end
				end
				if #targets > 0 then
					local victim = targets[self.rng:NextInteger(1, #targets)]
					self:runHeist(victim)
				end
			end
		end
	end)
end

function ThiefService:runHeist(victim)
	local model, prompt = self:makeThief()
	local caught = { Value = false }
	local catcher = { Player = nil }

	prompt.Triggered:Connect(function(player)
		if caught.Value then
			return
		end
		caught.Value = true
		catcher.Player = player
		local state = self.BrainrotService:getPlayerState(player)
		if state then
			state.Money.Value += CATCH_REWARD
			self.Remotes.EventFeed:FireClient(player, "You caught the thief! +$" .. CATCH_REWARD)
		end
	end)

	local state = self.BrainrotService:getPlayerState(victim)
	local basePos = state and state.Base.Origin.Position or Vector3.new(0, 0, 0)
	local reached = self:walkTo(model, basePos + Vector3.new(0, 0, 8), caught)

	if not caught.Value and reached then
		local stolen = self.BrainrotService:removeRandomCharacter(victim)
		if stolen then
			self.Remotes.EventFeed:FireClient(victim, "The thief stole " .. stolen.Name .. "! Buy a Lock!")
			-- Flee with the loot.
			local gate = self.World.stormGate.Position
			self:walkTo(model, gate, caught)
		end
	end

	if not caught.Value then
		model:Destroy()
	else
		task.wait(0.3)
		model:Destroy()
		if catcher.Player then
			self.Remotes.EventFeed:FireClient(catcher.Player, "The thief dropped a bag of pasta. It is worth nothing. Still: victory.")
		end
	end
end

return ThiefService
