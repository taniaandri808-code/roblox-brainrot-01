-- BrainrotCatalog.luau
-- The full roster of collectible brainrot figures plus rarity and mutation tables.
-- One job: define the data and the weighted rolls. No gameplay logic lives here.

local BrainrotCatalog = {}

BrainrotCatalog.RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

BrainrotCatalog.RARITY_COLORS = {
	Common = Color3.fromRGB(190, 190, 190),
	Uncommon = Color3.fromRGB(85, 200, 85),
	Rare = Color3.fromRGB(70, 130, 255),
	Epic = Color3.fromRGB(170, 85, 255),
	Legendary = Color3.fromRGB(255, 170, 40),
	Mythic = Color3.fromRGB(255, 60, 90),
	Secret = Color3.fromRGB(30, 30, 40),
}

-- Weighted rarity roll: Common is common, Secret is once in a blue moon.
BrainrotCatalog.RARITY_WEIGHTS = {
	Common = 45,
	Uncommon = 25,
	Rare = 15,
	Epic = 8,
	Legendary = 4,
	Mythic = 2,
	Secret = 1,
}

-- Mutations multiply income and repaint the figure.
BrainrotCatalog.MUTATIONS = {
	Golden = { Multiplier = 2, Color = Color3.fromRGB(255, 200, 40) },
	Diamond = { Multiplier = 4, Color = Color3.fromRGB(120, 220, 255) },
	Rainbow = { Multiplier = 8, Color = Color3.fromRGB(255, 90, 200) },
	Galaxy = { Multiplier = 15, Color = Color3.fromRGB(80, 40, 160) },
}

-- The cast: 22 original pasta-brainrot citizens of the Empire.
BrainrotCatalog.CHARACTERS = {
	{ Name = "Soggy Croissantini", Desc = "Fell in the fountain. Still hustling.", Rarity = "Common", IncomePerSecond = 1, Color = Color3.fromRGB(222, 184, 135), Shape = "block" },
	{ Name = "Brick Frogini", Desc = "Hops exactly once per hour.", Rarity = "Common", IncomePerSecond = 2, Color = Color3.fromRGB(120, 160, 90), Shape = "sphere" },
	{ Name = "Coughing Pigeotto", Desc = "Do not stand downwind.", Rarity = "Common", IncomePerSecond = 3, Color = Color3.fromRGB(150, 150, 165), Shape = "sphere" },
	{ Name = "Marinara Meatballino", Desc = "Rolls downhill. Has never stopped.", Rarity = "Uncommon", IncomePerSecond = 6, Color = Color3.fromRGB(165, 60, 45), Shape = "sphere" },
	{ Name = "Espresso Gatorino", Desc = "Four shots in, no shots left.", Rarity = "Uncommon", IncomePerSecond = 8, Color = Color3.fromRGB(70, 45, 30), Shape = "block" },
	{ Name = "Gelato Gargoyle", Desc = "Melts only when nobody watches.", Rarity = "Uncommon", IncomePerSecond = 11, Color = Color3.fromRGB(235, 170, 200), Shape = "block" },
	{ Name = "Noodle Necked Nino", Desc = "His neck is the longest tradition.", Rarity = "Rare", IncomePerSecond = 22, Color = Color3.fromRGB(245, 214, 130), Shape = "wedge" },
	{ Name = "Mozzarella Mammoth", Desc = "Stretchy, ancient, mildly threatening.", Rarity = "Rare", IncomePerSecond = 28, Color = Color3.fromRGB(240, 240, 225), Shape = "block" },
	{ Name = "Vespa Vulture", Desc = "Circles the plaza looking for parking.", Rarity = "Rare", IncomePerSecond = 36, Color = Color3.fromRGB(90, 100, 190), Shape = "sphere" },
	{ Name = "Cannoli Colossus", Desc = "Two hundred pounds of filling.", Rarity = "Epic", IncomePerSecond = 65, Color = Color3.fromRGB(200, 150, 95), Shape = "block" },
	{ Name = "Risotto Rhino", Desc = "Creamy armor. Mildly buttered.", Rarity = "Epic", IncomePerSecond = 85, Color = Color3.fromRGB(215, 190, 120), Shape = "sphere" },
	{ Name = "Tarantella Toad", Desc = "Dances at 140 BPM. Forever.", Rarity = "Epic", IncomePerSecond = 115, Color = Color3.fromRGB(60, 170, 90), Shape = "sphere" },
	{ Name = "Cappuccino Kraken", Desc = "Eight arms, all holding cups.", Rarity = "Legendary", IncomePerSecond = 230, Color = Color3.fromRGB(120, 75, 45), Shape = "sphere" },
	{ Name = "Tiramisu T-Rex", Desc = "Ladyfingers for teeth.", Rarity = "Legendary", IncomePerSecond = 310, Color = Color3.fromRGB(140, 90, 60), Shape = "block" },
	{ Name = "Focaccia Phantom", Desc = "Haunted by olive oil.", Rarity = "Legendary", IncomePerSecond = 400, Color = Color3.fromRGB(235, 200, 150), Shape = "wedge" },
	{ Name = "Ballerino Bison", Desc = "Pirouettes at highway speed.", Rarity = "Mythic", IncomePerSecond = 740, Color = Color3.fromRGB(90, 60, 60), Shape = "block" },
	{ Name = "Gorgonzola Godzilla", Desc = "Smells the city before it arrives.", Rarity = "Mythic", IncomePerSecond = 990, Color = Color3.fromRGB(110, 150, 110), Shape = "block" },
	{ Name = "Parmesan Palpatine", Desc = "Grated eternal.", Rarity = "Mythic", IncomePerSecond = 1250, Color = Color3.fromRGB(225, 220, 190), Shape = "sphere" },
	{ Name = "Heron Zestini", Desc = "The zesty one. The chosen one.", Rarity = "Secret", IncomePerSecond = 1800, Color = Color3.fromRGB(70, 200, 170), Shape = "sphere" },
	{ Name = "Omega Bruschetta", Desc = "The loaf that ends all loaves.", Rarity = "Secret", IncomePerSecond = 2500, Color = Color3.fromRGB(30, 30, 40), Shape = "wedge" },
	{ Name = "Nonna's Final Form", Desc = "She has seen everything. She forgives nothing.", Rarity = "Secret", IncomePerSecond = 3300, Color = Color3.fromRGB(190, 60, 70), Shape = "block" },
	{ Name = "Turbulent Tortellini", Desc = "Spins so fast it predates causality.", Rarity = "Secret", IncomePerSecond = 4200, Color = Color3.fromRGB(50, 120, 230), Shape = "sphere" },
}

function BrainrotCatalog.rollRarity(rng)
	local total = 0
	for _, r in ipairs(BrainrotCatalog.RARITIES) do
		total = total + BrainrotCatalog.RARITY_WEIGHTS[r]
	end
	local roll = rng:NextNumber(0, total)
	local acc = 0
	for _, r in ipairs(BrainrotCatalog.RARITIES) do
		acc = acc + BrainrotCatalog.RARITY_WEIGHTS[r]
		if roll <= acc then
			return r
		end
	end
	return "Common"
end

function BrainrotCatalog.rollMutation(rng)
	-- 70% no mutation, otherwise pick uniformly from the mutation table.
	if rng:NextNumber(0, 1) <= 0.7 then
		return nil
	end
	local names = {}
	for name in pairs(BrainrotCatalog.MUTATIONS) do
		table.insert(names, name)
	end
	return names[rng:NextInteger(1, #names)]
end

function BrainrotCatalog.pickRandom(rng, rarity)
	local pool = {}
	for _, c in ipairs(BrainrotCatalog.CHARACTERS) do
		if rarity == nil or c.Rarity == rarity then
			table.insert(pool, c)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[rng:NextInteger(1, #pool)]
end

return BrainrotCatalog
