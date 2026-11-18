-- BrainrotService.luau
-- One job: the core collecting loop. Spawns figures, sells them from the display
-- field, places them on bases, ticks income, sells locks, owns all player state.

local BrainrotCatalog = require(script.Parent.BrainrotCatalog)

local BrainrotService = {}
BrainrotService.__index = BrainrotService

local BASE_LOCK_BASE_COST = 500
local SLOT_COUNT = 4
local pad_free -- forward declaration; frees a display pad

function BrainrotService.new(deps)
	local self = setmetatable({}, BrainrotService)
	self.Catalog = deps.Catalog
	self.World = deps.World
	self.Remotes = deps.Remotes
	self.rng = Random.new()
	self.players = {} -- [player] = state
	self.figures = {} -- [model] = { Def, Mutation, BaseIndex, Slot }

	self.moneyRemote = Instance.new("RemoteEvent")
	self.moneyRemote.Name = "Money"
	self.moneyRemote.Parent = self.Remotes

	self.baseRemote = Instance.new("RemoteEvent")
	self.baseRemote.Name = "BaseInfo"
	self.baseRemote.Parent = self.Remotes

	self.purchasedRemote = Instance.new("RemoteEvent")
	self.purchasedRemote.Name = "BrainrotPurchased"
	self.purchasedRemote.Parent = self.Remotes

	self.feedRemote = Instance.new("RemoteEvent")
	self.feedRemote.Name = "EventFeed"
	self.feedRemote.Parent = self.Remotes

	self.stormRemote = Instance.new("RemoteEvent")
	self.stormRemote.Name = "StormWarning"
	self.stormRemote.Parent = self.Remotes

	return self
end

function BrainrotService:feed(player, message)
	if player then
		self.feedRemote:FireClient(player, message)
	else
		self.feedRemote:FireAllClients(message)
	end
end

function BrainrotService:getPlayerState(player)
	return self.players[player]
end

function BrainrotService:incomeMultiplier(player)
	local state = self.players[player]
	if not state then
		return 1
	end
	return 2 ^ state.Rebirths
end

function BrainrotService:setupPlayer(player, baseIndex)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 100 -- starting cash, enough for a first Common friend
	money.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	local income = Instance.new("IntValue")
	income.Name = "IncomePerSec"
	income.Value = 0
	income.Parent = leaderstats

	local base = self.World.bases[baseIndex]
	base.Owner = player
	self.players[player] = {
		Money = money,
		Rebirths = rebirths,
		IncomePerSec = income,
		Characters = {},
		BaseLocked = false,
		Base = base,
		BaseIndex = baseIndex,
	}

	self.baseRemote:FireClient(player, { BaseIndex = baseIndex, Color = base.Color.R, Color2 = base.Color.G, Color3 = base.Color.B })
	self:feed(player, "Welcome to BRAINROT EMPIRE! Your base is Base " .. baseIndex .. ".")
end

function BrainrotService:teardownPlayer(player)
	local state = self.players[player]
	if not state then
		return
	end
	for model, meta in pairs(self.figures) do
		if meta.OwnerPlayer == player then
			self.figures[model] = nil
			if model.Parent then
				model:Destroy()
			end
		end
	end
	state.Base.Owner = nil
	self.players[player] = nil
end

local function makeFigureModel(parent, def, mutationDef)
	local model = Instance.new("Model")
	model.Name = def.Name

	local color = def.Color
	if mutationDef then
		color = mutationDef.Color
	end

	local body
	if def.Shape == "sphere" then
		body = Instance.new("Part")
		body.Shape = Enum.PartType.Ball
	else
		body = Instance.new("Part")
	end
	body.Name = "Body"
	body.Anchored = true
	body.Size = def.Shape == "sphere" and Vector3.new(3, 3, 3) or Vector3.new(3, 3.5, 2)
	body.Color = color
	body.Material = mutationDef and Enum.Material.Neon or Enum.Material.SmoothPlastic
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Color = Color3.new(1, 1, 1)
	head.Material = Enum.Material.SmoothPlastic
	head.CFrame = body.CFrame * CFrame.new(0, 2.4, 0)
	head.Parent = model

	local eye1 = Instance.new("Part")
	eye1.Name = "Eye"
	eye1.Anchored = true
	eye1.Shape = Enum.PartType.Ball
	eye1.Size = Vector3.new(0.3, 0.3, 0.3)
	eye1.Color = Color3.new(0, 0, 0)
	eye1.CFrame = head.CFrame * CFrame.new(-0.35, 0.15, -0.7)
	eye1.Parent = model
	local eye2 = eye1:Clone()
	eye2.CFrame = head.CFrame * CFrame.new(0.35, 0.15, -0.7)
	eye2.Parent = model

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.new(6, 0, 2.2, 0)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextStrokeTransparency = 0.2
	text.TextColor3 = BrainrotCatalog.RARITY_COLORS[def.Rarity]
	text.Text = def.Name
	text.Parent = gui

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0.5, 0)
	sub.Position = UDim2.new(0, 0, 1, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextStrokeTransparency = 0.2
	sub.TextColor3 = mutationDef and mutationDef.Color or Color3.new(1, 1, 1)
	sub.Text = ""
	sub.Parent = gui

	return model, text, sub
end

-- Spawns a random figure on a free display pad. Rolls rarity and mutation.
function BrainrotService:spawnFigure()
	for _, pad in ipairs(self.World.spawnPads) do
		if not pad.Busy then
			pad.Busy = true
			local rarity = self.Catalog.rollRarity(self.rng)
			local def = self.Catalog.pickRandom(self.rng, rarity)
			local mutation = self.Catalog.rollMutation(self.rng)
			local mutationDef = mutation and self.Catalog.MUTATIONS[mutation] or nil

			local model, _, sub = makeFigureModel(workspace, def, mutationDef)
			model:PivotTo(pad.CFrame)
			sub.Text = "$" .. def.IncomePerSecond .. "/s" .. (mutation and ("  " .. mutation) or "")

			local price = 25 * def.IncomePerSecond
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Buy — $" .. price
			prompt.ObjectText = def.Name .. (mutation and (" (" .. mutation .. ")") or "")
			prompt.HoldDuration = 0.25
			prompt.MaxActivationDistance = 12
			prompt.Parent = model:FindFirstChild("Body")

			local meta = { Def = def, Mutation = mutation, Pad = pad, Price = price, OwnerPlayer = nil }
			self.figures[model] = meta

			prompt.Triggered:Connect(function(player)
				self:tryPurchase(player, model, meta)
			end)

			return model
		end
	end
	return nil
end

function BrainrotService:tryPurchase(player, model, meta)
	local state = self.players[player]
	if not state or meta.OwnerPlayer then
		return
	end
	if state.Money.Value < meta.Price then
		self:feed(player, "Not enough money for " .. meta.Def.Name .. " ($" .. meta.Price .. ")")
		return
	end
	-- Find a free slot on the buyer's base.
	local base = state.Base
	local slotFrame = nil
	local usedSlots = {}
	for _, m in pairs(self.figures) do
		if m.OwnerPlayer == player then
			usedSlots[m.Slot] = true
		end
	end
	for i = 1, SLOT_COUNT do
		if not usedSlots[i] then
			slotFrame = base.Slots[i]
			meta.Slot = i
			break
		end
	end
	if not slotFrame then
		self:feed(player, "Your base is full! Rebirth or expand your empire another way.")
		return
	end

	state.Money.Value -= meta.Price
	meta.OwnerPlayer = player
	meta.BaseIndex = state.BaseIndex
	pad_free(meta)

	model:PivotTo(slotFrame * CFrame.new(0, 2.6, 0))
	local label = model:FindFirstChild("Body", true)
	state.Characters[#state.Characters + 1] = { Name = meta.Def.Name, Rarity = meta.Def.Rarity, Mutation = meta.Mutation, IncomePerSecond = meta.Def.IncomePerSecond }

	self:pulseIncome(player)
	self.purchasedRemote:FireClient(player, { Name = meta.Def.Name, Mutation = meta.Mutation, Price = meta.Price })
	self:feed(player, "Bought " .. meta.Def.Name .. (meta.Mutation and (" (" .. meta.Mutation .. ")!") or "!"))
end

-- Frees the display pad a figure occupied, if any.
pad_free = function(meta)
	if meta.Pad then
		meta.Pad.Busy = false
		meta.Pad = nil
	end
end

function BrainrotService:pulseIncome(player)
	local state = self.players[player]
	if not state then
		return
	end
	local total = 0
	for _, c in ipairs(state.Characters) do
		total += c.IncomePerSecond
	end
	state.IncomePerSec.Value = total * self:incomeMultiplier(player)
end

function BrainrotService:startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			for player, state in pairs(self.players) do
				local income = 0
				for _, c in ipairs(state.Characters) do
					income += c.IncomePerSecond
				end
				income *= self:incomeMultiplier(player)
				if income > 0 then
					state.Money.Value += income
				end
				self.moneyRemote:FireClient(player, { Money = state.Money.Value, Income = income, Rebirths = state.Rebirths.Value })
			end
		end
	end)
end

function BrainrotService:setupLockPads()
	for _, base in ipairs(self.World.bases) do
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Buy Lock — $" .. BASE_LOCK_BASE_COST
		prompt.ObjectText = "Base Lock"
		prompt.HoldDuration = 0.5
		prompt.Parent = base.LockPad
		prompt.Triggered:Connect(function(player)
			local state = self.players[player]
			if not state then
				return
			end
			if state.Base ~= base then
				return
			end
			if state.BaseLocked then
				self:feed(player, "Your base is already locked.")
				return
			end
			local cost = BASE_LOCK_BASE_COST * (1 + state.Rebirths)
			if state.Money.Value < cost then
				self:feed(player, "A lock costs $" .. cost .. ".")
				return
			end
			state.Money.Value -= cost
			state.BaseLocked = true
			base.LockPad.Color = Color3.fromRGB(90, 255, 120)
			prompt.ActionText = "LOCKED"
			self:feed(player, "Base locked! The storm and the thief can't touch your brainrots.")
		end)
	end
end

-- Used by StormService and ThiefService: removes a random character from an
-- unlocked base. Returns the removed character's name, or nil.
function BrainrotService:removeRandomCharacter(player)
	local state = self.players[player]
	if not state or state.BaseLocked or #state.Characters == 0 then
		return nil
	end
	local index = self.rng:NextInteger(1, #state.Characters)
	local removed = table.remove(state.Characters, index)
	for model, meta in pairs(self.figures) do
		if meta.OwnerPlayer == player and meta.Def.Name == removed.Name then
			self.figures[model] = nil
			if model.Parent then
				model:Destroy()
			end
			break
		end
	end
	self:pulseIncome(player)
	return removed
end

function BrainrotService:isStormActive()
	return self.stormActive == true
end

function BrainrotService:setStormActive(active)
	self.stormActive = active
end

function BrainrotService:start()
	self:startIncomeLoop()
	self:setupLockPads()
	task.spawn(function()
		while true do
			self:spawnFigure()
			task.wait(6)
		end
	end)
end

return BrainrotService
