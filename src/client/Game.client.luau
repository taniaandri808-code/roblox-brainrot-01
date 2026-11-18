-- Game.client.luau
-- BRAINROT EMPIRE — client HUD. One job: read the remotes, draw the UI,
-- animate the local player's own ScreenGui. Never touches server state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local moneyRemote = remotes:WaitForChild("Money")
local baseRemote = remotes:WaitForChild("BaseInfo")
local stormRemote = remotes:WaitForChild("StormWarning")
local feedRemote = remotes:WaitForChild("EventFeed")
local purchasedRemote = remotes:WaitForChild("BrainrotPurchased")

-- ---------------------------------------------------------------- helpers --

local function round(frame, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = frame
end

local function panel(parent, size, position, color, transparency)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color or Color3.fromRGB(25, 22, 35)
	frame.BackgroundTransparency = transparency or 0.15
	frame.BorderSizePixel = 0
	frame.Parent = parent
	round(frame, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 90, 140)
	stroke.Thickness = 2
	stroke.Transparency = 0.35
	stroke.Parent = frame
	return frame
end

local function label(parent, text, size, position, color, textSize)
	local t = Instance.new("TextLabel")
	t.Size = size
	t.Position = position
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextSize = textSize or 22
	t.TextStrokeTransparency = 0.4
	t.Parent = parent
	return t
end

-- -------------------------------------------------------------------- gui --

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotEmpireHUD"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Money panel: top center (clear of the Roblox menu in the top-left corner).
local moneyPanel = panel(gui, UDim2.new(0, 220, 0, 64), UDim2.new(0.5, -110, 0, 10))
local moneyLabel = label(moneyPanel, "$0", UDim2.new(1, 0, 0.6, 0), UDim2.new(0, 0, 0, 2), Color3.fromRGB(120, 255, 150), 30)
local incomeLabel = label(moneyPanel, "+0/s", UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.58, 0), Color3.fromRGB(255, 240, 150), 16)

-- Base panel: under the money panel, shows which base is yours.
local basePanel = panel(gui, UDim2.new(0, 220, 0, 28), UDim2.new(0.5, -110, 0, 80))
local baseLabel = label(basePanel, "Your base: ...", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(200, 220, 255), 15)

-- Rebirth progress: bottom center.
local rebirthPanel = panel(gui, UDim2.new(0, 320, 0, 44), UDim2.new(0.5, -160, 1, -60))
local rebirthLabel = label(rebirthPanel, "Rebirth 0 — progress", UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 90), 15)
local barBack = Instance.new("Frame")
barBack.Size = UDim2.new(1, -16, 0, 10)
barBack.Position = UDim2.new(0, 8, 1, -14)
barBack.BackgroundColor3 = Color3.fromRGB(50, 45, 70)
barBack.BorderSizePixel = 0
barBack.Parent = rebirthPanel
round(barBack, 5)
local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 240, 90)
barFill.BorderSizePixel = 0
barFill.Parent = barBack
round(barFill, 5)

-- Event feed: top right, newest first.
local feed = {}
local feedFrame = Instance.new("Frame")
feedFrame.Size = UDim2.new(0, 300, 0, 140)
feedFrame.Position = UDim2.new(1, -312, 0, 10)
feedFrame.BackgroundTransparency = 1
feedFrame.Parent = gui
local feedLayout = Instance.new("UIListLayout")
feedLayout.VerticalAlignment = Enum.VerticalAlignment.Top
feedLayout.Padding = UDim.new(0, 4)
feedLayout.Parent = feedFrame

local function pushFeed(message, color)
	local row = panel(feedFrame, UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), Color3.fromRGB(25, 22, 35), 0.25)
	local text = label(row, message, UDim2.new(1, -8, 1, 0), UDim2.new(0, 6, 0, 0), color or Color3.new(1, 1, 1), 14)
	text.TextXAlignment = Enum.TextXAlignment.Left
	table.insert(feed, 1, row)
	if #feed > 5 then
		local old = table.remove(feed)
		old:Destroy()
	end
	task.delay(8, function()
		local tween = TweenService:Create(row, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		row:Destroy()
		for i, f in ipairs(feed) do
			if f == row then
				table.remove(feed, i)
				break
			end
		end
	end)
end

-- Storm banner: center top, flashing red.
local stormBanner = panel(gui, UDim2.new(0, 420, 0, 48), UDim2.new(0.5, -210, 0, 116), Color3.fromRGB(120, 20, 20), 0.1)
local stormText = label(stormBanner, "", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.new(1, 1, 1), 22)
stormBanner.Visible = false
local stormConnection = nil

local function flashBanner(on)
	if stormConnection then
		stormConnection:Disconnect()
		stormConnection = nil
	end
	if on then
		stormConnection = task.spawn(function()
			while stormBanner.Visible do
				stormBanner.BackgroundColor3 = (stormBanner.BackgroundColor3.R > 0.5) and Color3.fromRGB(120, 20, 20) or Color3.fromRGB(60, 8, 8)
				task.wait(0.3)
			end
		end)
	end
end

-- Intro title card.
local intro = Instance.new("Frame")
intro.Size = UDim2.new(1, 0, 1, 0)
intro.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
intro.BorderSizePixel = 0
intro.Parent = gui
label(intro, "BRAINROT EMPIRE", UDim2.new(1, 0, 0.2, 0), UDim2.new(0, 0, 0.34, 0), Color3.fromRGB(255, 90, 140), 64)
label(intro, "Collect. Lock. Rebirth.", UDim2.new(1, 0, 0.1, 0), UDim2.new(0, 0, 0.56, 0), Color3.fromRGB(200, 220, 255), 24)
label(intro, "walk up to a glowing figure and hold E to buy it", UDim2.new(1, 0, 0.1, 0), UDim2.new(0, 0, 0.64, 0), Color3.fromRGB(160, 170, 200), 16)
task.delay(3, function()
	local tween = TweenService:Create(intro, TweenInfo.new(1.2), { BackgroundTransparency = 1 })
	tween:Play()
	for _, child in ipairs(intro:GetChildren()) do
		if child:IsA("TextLabel") then
			TweenService:Create(child, TweenInfo.new(1.2), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end
	tween.Completed:Wait()
	intro:Destroy()
end)

-- ------------------------------------------------------------- remotes --

moneyRemote.OnClientEvent:Connect(function(data)
	moneyLabel.Text = "$" .. tostring(data.Money)
	incomeLabel.Text = "+" .. tostring(data.Income) .. "/s"
	rebirthLabel.Text = "Rebirth " .. tostring(data.Rebirths or 0)
end)

baseRemote.OnClientEvent:Connect(function(data)
	baseLabel.Text = string.format("Your base: Base %d", data.BaseIndex)
end)

purchasedRemote.OnClientEvent:Connect(function(data)
	local name = data.Name .. (data.Mutation and (" (" .. data.Mutation .. ")") or "")
	pushFeed("New brainrot: " .. name .. "!", Color3.fromRGB(120, 255, 150))
end)

feedRemote.OnClientEvent:Connect(function(message)
	pushFeed(message)
end)

stormRemote.OnClientEvent:Connect(function(data)
	if data.Phase == "Warning" then
		stormBanner.Visible = true
		stormBanner.BackgroundColor3 = Color3.fromRGB(180, 140, 20)
		stormText.Text = "STORM INCOMING — " .. tostring(data.Seconds) .. "s — lock your base!"
		flashBanner(false)
	elseif data.Phase == "Storm" then
		stormBanner.Visible = true
		stormBanner.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
		stormText.Text = "STORM! RUN HOME!"
		flashBanner(true)
	else
		stormBanner.Visible = false
		flashBanner(false)
	end
end)
