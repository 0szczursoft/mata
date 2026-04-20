--[[

Sirius

© 2024 Sirius 
All Rights Reserved.

Tweaked by 0szczur
--]]


-- Official Sirius Core Execution Script


-- Ensure the game is loaded 
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Check License Tier
local Pro = true -- We're open sourced now!

-- Create Variables for Roblox Services
local coreGui = game:GetService("CoreGui")
local httpService = game:GetService("HttpService")
local lighting = game:GetService("Lighting")
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local guiService = game:GetService("GuiService")
local statsService = game:GetService("Stats")
local starterGui = game:GetService("StarterGui")
local teleportService = game:GetService("TeleportService")
local tweenService = game:GetService("TweenService")
local userInputService = game:GetService('UserInputService')
local gameSettings = UserSettings():GetService("UserGameSettings")

-- Variables
local camera = workspace.CurrentCamera
-- Make transit function global singleton
getgenv()._siriusStartTransit = function(targetHum)
	local cam = workspace.CurrentCamera
	if getgenv()._siriusActiveTransit then getgenv()._siriusActiveTransit:Disconnect() end
	if getgenv()._siriusCurrentProxy then getgenv()._siriusCurrentProxy:Destroy() end
	
	local targetRoot = targetHum and (targetHum.RootPart or targetHum.Parent:FindFirstChild("HumanoidRootPart"))
	if not targetHum or not targetRoot then return end
	
	local proxy = Instance.new("Part")
	proxy.Name = "SiriusSpecProxy"
	proxy.Transparency = 1
	proxy.Anchored = true
	proxy.CanCollide = false
	proxy.CanQuery = false
	proxy.Size = Vector3.new(0.01, 0.01, 0.01)
	proxy.Position = cam and cam.Focus.Position or targetRoot.Position
	proxy.Parent = workspace
	
	getgenv()._siriusCurrentProxy = proxy
	cam.CameraSubject = proxy
	
	local startPos = proxy.Position
	local startTime = tick()
	local duration = 0.9 
	
	getgenv()._siriusActiveTransit = runService.Heartbeat:Connect(function()
		local t = math.clamp((tick() - startTime) / duration, 0, 1)
		local goalPos = targetRoot.Position + Vector3.new(0, 1.5, 0)
		local alpha = t < 0.5 and 16 * t * t * t * t * t or 1 - math.pow(-2 * t + 2, 5) / 2
		proxy.Position = startPos:Lerp(goalPos, alpha)
		
		if t >= 1 or not targetRoot.Parent then
			if getgenv()._siriusActiveTransit then getgenv()._siriusActiveTransit:Disconnect() getgenv()._siriusActiveTransit = nil end
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = targetHum
			task.delay(0.05, function() if proxy and proxy.Parent then proxy:Destroy() end end)
		end
	end)
end
local getMessage = replicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 1) and replicatedStorage.DefaultChatSystemChatEvents:WaitForChild("OnMessageDoneFiltering", 1)
local localPlayer = players.LocalPlayer
local notifications = {}
local friendsCooldown = 0
local mouse = localPlayer:GetMouse()
local promptedDisconnected = false
local smartBarOpen = false
local debounce = false
local searchingForPlayer = false
local musicQueue = {}
local currentAudio
local lowerName = localPlayer.Name:lower()
local lowerDisplayName = localPlayer.DisplayName:lower()
local placeId = game.PlaceId
local jobId = game.JobId
local checkingForKey = false
local originalTextValues = {}
local creatorId = game.CreatorId
local noclipDefaults = {}
local movers = {}
local creatorType = game.CreatorType
local espContainer = Instance.new("Folder", gethui and gethui() or coreGui)
local oldVolume = gameSettings.MasterVolume

-- Configurable Core Values
local siriusValues = {
	siriusVersion = "1.26",
	siriusName = "Sirius",
	releaseType = "Stable",
	siriusFolder = "Sirius",
	settingsFile = "settings.srs",
	interfaceAsset = 14183548964,
	cdn = "https://cdn.sirius.menu/SIRIUS-SCRIPT-CORE-ASSETS/",
	icons = "https://cdn.sirius.menu/SIRIUS-SCRIPT-CORE-ASSETS/Icons/",
	enableExperienceSync = true, -- Games are no longer available due to a lack of whitelisting, they may be made open source at a later date, however they are patched as of now and are useless to the end user. Turning this on may introduce "fake functionality".
	games = {
		BreakingPoint = {
			name = "Breaking Point",
			description = "Players are seated around a table. Their only goal? To be the last one standing. Execute this script to gain an unfair advantage.",
			id = 648362523,
			enabled = true,
			raw = "BreakingPoint",
			minimumTier = "Free",
		},
		MurderMystery2 = {
			name = "Murder Mystery 2",
			description = "A murder has occured, will you be the one to find the murderer, or kill your next victim? Execute this script to gain an unfair advantage.",
			id = 142823291,
			enabled = true,
			raw = "MurderMystery2",
			minimumTier = "Free",
		},
		TowerOfHell = {
			name = "Tower Of Hell",
			description = "A difficult popular parkouring game, with random levels and modifiers. Execute this script to gain an unfair advantage.",
			id = 1962086868,
			enabled = true,
			raw = "TowerOfHell",
			minimumTier = "Free",
		},
		Strucid = {
			name = "Strucid",
			description = "Fight friends and enemies in Strucid with building mechanics! Execute this script to gain an unfair advantage.",
			id = 2377868063,
			enabled = true,
			raw = "Strucid",
			minimumTier = "Free",
		},
		PhantomForces = {
			name = "Phantom Forces",
			description = "One of the most popular FPS shooters from the team at StyLiS Studios. Execute this script to gain an unfair advantage.",
			id = 292439477,
			enabled = true,
			raw = "PhantomForces",
			minimumTier = "Pro",
		},
	},
	trustedScripts = {
		[155615604] = {title = "Prison Life Pirno.cxx (Sirius Trusted)", script = [[loadstring(game:HttpGet("https://pastebin.com/raw/TPKUkjSH"))()]]},
		[606849621] = {title = "Jailbreak Allium (Sirius Trusted)", script = [[loadstring(game:HttpGet("https://lucii.space/AlliumLoader.lua"))()]]},
		[13772394625] = {title = "Blade Ball (Sirius Trusted)", script = [[getgenv().SCRIPT_KEY='KEYLESS' loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/245a7b9319ee4b2c3ae55789847e7df70b6be54b4ebcd6b95a905b69cffbd6e2/download"))()]]},
	},
	rawTree = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/Sirius/games/",
	neonModule = "https://raw.githubusercontent.com/shlexware/Sirius/request/library/neon.lua",
	senseRaw = "https://raw.githubusercontent.com/shlexware/Sirius/request/library/sense/source.lua",
	executors = {"synapse x", "script-ware", "krnl", "scriptware", "comet", "valyse", "fluxus", "electron", "hydrogen", "volt", "potassium", "wave", "synapse z", "cosmic", "isaeva", "volcano", "velocity", "seliware", "bunni.fun", "macsploit", "opiumware"},
	devs = {"pro0097865", "just_noskill", "vciprorc"}, -- Developer names for [Dev] tag
	disconnectTypes = { {"ban", {"ban", "perm"}}, {"network", {"internet connection", "network"}} },
	nameGeneration = {
		adjectives = {"Cool", "Awesome", "Epic", "Ninja", "Super", "Mystic", "Swift", "Golden", "Diamond", "Silver", "Mint", "Roblox", "Amazing"},
		nouns = {"Player", "Gamer", "Master", "Legend", "Hero", "Ninja", "Wizard", "Champion", "Warrior", "Sorcerer"}
	},
	administratorRoles = {"mod","admin","staff","dev","founder","owner","supervis","manager","management","executive","president","chairman","chairwoman","chairperson","director"},
	transparencyProperties = {
		UIStroke = {'Transparency'},
		Frame = {'BackgroundTransparency'},
		TextButton = {'BackgroundTransparency', 'TextTransparency'},
		TextLabel = {'BackgroundTransparency', 'TextTransparency'},
		TextBox = {'BackgroundTransparency', 'TextTransparency'},
		ImageLabel = {'BackgroundTransparency', 'ImageTransparency'},
		ImageButton = {'BackgroundTransparency', 'ImageTransparency'},
		ScrollingFrame = {'BackgroundTransparency', 'ScrollBarImageTransparency'}
	},
	buttonPositions = {Character = UDim2.new(0.5, -155, 1, -29), Scripts = UDim2.new(0.5, -122, 1, -29), Playerlist = UDim2.new(0.5, -68, 1, -29)},
	chatSpy = {
		enabled = true,
		visual = {
			Color = Color3.fromRGB(26, 148, 255),
			Font = Enum.Font.SourceSansBold,
			TextSize = 18
		},
	},
	pingProfile = {
		recentPings = {},
		adaptiveBaselinePings = {},
		pingNotificationCooldown = 0,
		maxSamples = 12, -- max num of recent pings stored
		spikeThreshold = 1.75, -- high Ping in comparison to average ping (e.g 100 avg would be high at 150)
		adaptiveBaselineSamples = 30, -- how many samples Sirius takes before deciding on a fixed high ping value
		adaptiveHighPingThreshold = 120 -- default value
	},
	frameProfile = {
		frameNotificationCooldown = 0,
		fpsQueueSize = 10,
		lowFPSThreshold = 20, -- what's low fps!??!?!
		totalFPS = 0,
		fpsQueue = {},
	},
	actions = {
		{
			name = "Noclip",
			images = {14385986465, 9134787693},
			color = Color3.fromRGB(40, 230, 150), -- Fine-tuned Green
			enabled = false,
			rotateWhileEnabled = false,
			callback = function() end,
		},
		{
			name = "Flight",
			images = {9134755504, 14385992605},
			color = Color3.fromRGB(230, 50, 65), -- Fine-tuned Red
			enabled = false,
			rotateWhileEnabled = false,
			callback = function(value)
				local character = localPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.PlatformStand = value
				end
			end,
		},
		{
			name = "Refresh",
			images = {9134761478, 9134761478},
			color = Color3.fromRGB(70, 230, 110), -- Fine-tuned Emerald
			enabled = false,
			rotateWhileEnabled = true,
			disableAfter = 3,
			callback = function()
				task.spawn(function()
					local character = localPlayer.Character
					if character then
						local cframe = character:GetPivot()
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							humanoid:ChangeState(Enum.HumanoidStateType.Dead)
						end
						character = localPlayer.CharacterAdded:Wait()
						task.defer(character.PivotTo, character, cframe)
					end
				end)
			end,
		},
		{
			name = "Respawn",
			images = {9134762943, 9134762943},
			color = Color3.fromRGB(70, 130, 240), -- Fine-tuned Blue
			enabled = false,
			rotateWhileEnabled = true,
			disableAfter = 2,
			callback = function()
				local character = localPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				end
			end,
		},
			{
			name = "Invulnerability",
			images = {9134765994, 14386216487},
			color = Color3.fromRGB(230, 60, 125), -- Fine-tuned Pink/Magenta
			enabled = false,
			rotateWhileEnabled = false,
			callback = function(value)
				local char = localPlayer.Character
				local cam = workspace.CurrentCamera
				
				if value then
					if char then
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum then
							local nHum = hum:Clone()
							nHum.Parent = char
							localPlayer.Character = nil
							pcall(function()
								nHum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
								nHum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
								nHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
							end)
							nHum.BreakJointsOnDeath = true
							hum:Destroy()
							localPlayer.Character = char
							cam.CameraSubject = nHum
							nHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
							local script = char:FindFirstChild("Animate")
							if script then
								script.Disabled = true
								task.wait()
								script.Disabled = false
							end
							nHum.Health = nHum.MaxHealth
						end
					end
				else
					-- Restart to default by resetting char completely (respawning or reloading character)
					-- IY usually reloads character or just leaves the cloned humanoid.
					-- To be safe, we just let them reset manually, or we re-enable states if humanoid is found
					if char then
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum then
							pcall(function()
								hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
								hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
								hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
							end)
						end
					end
				end
			end,
		},
		{
			name = "Fling",
			images = {9134785384, 14386226155},
			color = Color3.fromRGB(240, 120, 80), -- Fine-tuned Orange/Coral
			enabled = false,
			rotateWhileEnabled = true,
			callback = function(value)
				local IY_LOADED = getgenv().IY_LOADED
				if IY_LOADED and getgenv().execCmd then
					getgenv().execCmd(value and "fling" or "unfling")
					return
				end

				-- Fallback if IY not found
				local character = localPlayer.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not root then return end

				if value then
					for _, v in ipairs(character:GetDescendants()) do
						if v:IsA("BasePart") then
							v.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
							v.CanCollide = false
							v.Massless = true
							v.Velocity = Vector3.new(0, 0, 0)
						end
					end

					local angularVelocity = Instance.new("BodyAngularVelocity")
					angularVelocity.Name = "SiriusFlingBAMBAM"
					angularVelocity.Parent = root
					angularVelocity.AngularVelocity = Vector3.new(0, 99999, 0)
					angularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
					angularVelocity.P = math.huge

					getgenv()._siriusWalkFling = runService.Stepped:Connect(function()
						if root and root.Parent then
							angularVelocity.AngularVelocity = Vector3.new(0, 99999, 0)
						end
					end)
				else
					if getgenv()._siriusWalkFling then
						getgenv()._siriusWalkFling:Disconnect()
						getgenv()._siriusWalkFling = nil
					end

					if root and root.Parent then
						local angularVelocity = root:FindFirstChild("SiriusFlingBAMBAM")
						if angularVelocity then angularVelocity:Destroy() end
						root.Velocity = Vector3.new(0, 0, 0)
						root.RotVelocity = Vector3.new(0, 0, 0)
					end

					for _, v in pairs(character:GetDescendants()) do
						if v:IsA("BasePart") then
							v.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
							v.CanCollide = true
							v.Massless = false
						end
					end
				end
			end,
		},
		{
			name = "Extrasensory Perception",
			images = {9134780101, 14386232387},
			color = Color3.fromRGB(245, 220, 40), -- Fine-tuned Yellow
			enabled = false,
			rotateWhileEnabled = false,
			callback = function(value)
				local filter = getgenv()._siriusESPTeams
				local hasFilter = type(filter) == "table" and #filter > 0
				local container = gethui and gethui() or coreGui
				
				for _, instance in ipairs(container:GetChildren()) do
					pcall(function()
						if instance:IsA("Highlight") and string.find(instance.Name, "SiriusUniversal_HL_") then
							local playerName = string.gsub(instance.Name, "SiriusUniversal_HL_", "")
							local player = Players:FindFirstChild(playerName)
							
							local allowed = true
							if hasFilter and player then
								local teamName = player.Team and player.Team.Name or "No Team"
								allowed = table.find(filter, teamName) ~= nil
							end
							
							instance.Enabled = value and allowed
							if value and allowed and player and player.Character then
								instance.Adornee = player.Character
							end
						elseif instance:IsA("BillboardGui") and string.find(instance.Name, "SiriusUniversal_BB_") then
							local playerName = string.gsub(instance.Name, "SiriusUniversal_BB_", "")
							local player = Players:FindFirstChild(playerName)
							
							local allowed = true
							if hasFilter and player then
								local teamName = player.Team and player.Team.Name or "No Team"
								allowed = table.find(filter, teamName) ~= nil
							end
							
							instance.Enabled = value and allowed
							if value and allowed and player and player.Character then
								local head = player.Character:FindFirstChild("Head")
								if head then instance.Adornee = head end
							end
						end
					end)
				end
			end,
		},
		{
			name = "Night and Day",
			images = {9134778004, 10137794784},
			color = Color3.fromRGB(150, 120, 240), -- Fine-tuned Purple
			enabled = false,
			rotateWhileEnabled = false,
			callback = function(value)
				tweenService:Create(lighting, TweenInfo.new(0.5), { ClockTime = value and 12 or 24 }):Play()
			end,
		},
		{
			name = "Global Audio",
			images = {9134774810, 14386246782},
			color = Color3.fromRGB(240, 135, 75), -- Fine-tuned Amber
			enabled = false,
			rotateWhileEnabled = false,
			callback = function(value)
				if value then
					oldVolume = gameSettings.MasterVolume
					gameSettings.MasterVolume = 0
				else
					gameSettings.MasterVolume = oldVolume
				end
			end,
		},
		{
			name = "Visibility",
			images = {14386256326, 9134770786},
			color = Color3.fromRGB(120, 160, 240), -- Fine-tuned Azure Blue
			enabled = false,
			rotateWhileEnabled = false,
			callback = function(value)
				if value then
					if getgenv()._siriusIsInvis then return end
					getgenv()._siriusIsInvis = true
					
					local player = localPlayer
					local char = player.Character
					if not char then return end
					
					char.Archivable = true
					local clone = char:Clone()
					clone.Parent = game:GetService("Lighting")
					clone.Name = ""
					
					local oldPos = char.HumanoidRootPart.CFrame
					char:MoveTo(Vector3.new(0, math.pi*1000000, 0))
					
					local cam = workspace.CurrentCamera
					cam.CameraType = Enum.CameraType.Scriptable
					task.wait(0.2)
					cam.CameraType = Enum.CameraType.Custom
					
					char.Parent = game:GetService("Lighting")
					clone.Parent = workspace
					clone.HumanoidRootPart.CFrame = oldPos
					player.Character = clone
					
					cam.CameraSubject = clone:FindFirstChildOfClass("Humanoid")
					
					local anim = clone:FindFirstChild("Animate")
					if anim then
						anim.Disabled = true
						task.wait()
						anim.Disabled = false
					end
					
					for _, v in pairs(clone:GetDescendants()) do
						if v:IsA("BasePart") then
							v.Transparency = (v.Name == "HumanoidRootPart") and 1 or 0.5
						end
					end
					
					getgenv()._siriusRealChar = char
					getgenv()._siriusCloneChar = clone
					
					getgenv()._siriusInvisDied = clone:FindFirstChildOfClass("Humanoid").Died:Connect(function()
						if getgenv()._siriusRealChar then
							player.Character = getgenv()._siriusRealChar
							getgenv()._siriusRealChar.Parent = workspace
							getgenv()._siriusRealChar:FindFirstChildOfClass("Humanoid"):Destroy()
						end
					end)
				else
					if not getgenv()._siriusIsInvis then return end
					getgenv()._siriusIsInvis = false
					
					local player = localPlayer
					local realChar = getgenv()._siriusRealChar
					local cloneChar = getgenv()._siriusCloneChar
					
					if getgenv()._siriusInvisDied then
						getgenv()._siriusInvisDied:Disconnect()
						getgenv()._siriusInvisDied = nil
					end
					
					if cloneChar and realChar then
						local oldPos = cloneChar.HumanoidRootPart.CFrame
						realChar.HumanoidRootPart.CFrame = oldPos
						cloneChar:Destroy()
						player.Character = realChar
						realChar.Parent = workspace
						
						local anim = realChar:FindFirstChild("Animate")
						if anim then
							anim.Disabled = true
							task.wait()
							anim.Disabled = false
						end
						
						local cam = workspace.CurrentCamera
						cam.CameraSubject = realChar:FindFirstChildOfClass("Humanoid")
					end
				end
			end,
		},
	},
	sliders = {
		{
			name = "player speed",
			color = Color3.fromRGB(80, 255, 140), -- Vibrant Mint
			values = {0, 300},
			default = 16,
			value = 16,
			active = false,
			callback = function(value)
				local character = localPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if character then
					humanoid.WalkSpeed = value
				end
			end,
		},
		{
			name = "jump power",
			color = Color3.fromRGB(50, 160, 255), -- Vibrant Azure
			values = {0, 350},
			default = 50,
			value = 50,
			active = false,
			callback = function(value)
				local character = localPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if character then
					if humanoid.UseJumpPower then
						humanoid.JumpPower = value
					else
						humanoid.JumpHeight = value
					end
				end
			end,
		},
		{
			name = "flight speed",
			color = Color3.fromRGB(255, 60, 60), -- Vibrant Red
			values = {1, 25},
			default = 3,
			value = 3,
			active = false,
			callback = function(value) end,
		},
		{
			name = "field of view",
			color = Color3.fromRGB(255, 200, 50), -- Vibrant Gold
			values = {45, 120},
			default = 70,
			value = 70,
			active = false,
			callback = function(value)
				tweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), { FieldOfView = value }):Play()
			end,
		},
	}
}

local siriusSettings = {
	{
		name = 'General',
		description = 'The general settings for Sirius, from simple to unique features.',
		color = Color3.fromRGB(0, 150, 255), -- Deep Sky Blue
		minimumLicense = 'Free',
		categorySettings = {
			{
				name = 'Anonymous Client',
				description = 'Randomise your username in real-time in any CoreGui parented interface, including Sirius. You will still appear as your actual name to others in-game. This setting can be performance intensive.',
				settingType = 'Boolean',
				current = false,

				id = 'anonmode'
			},
			{
				name = 'Chat Spy',
				description = 'This will only work on the legacy Roblox chat system. Sirius will display whispers usually hidden from you in the chat box.',
				settingType = 'Boolean',
				current = true,

				id = 'chatspy'
			},
			{
				name = 'Hide Toggle Button',
				description = 'This will remove the option to open the smartBar with the toggle button.',
				settingType = 'Boolean',
				current = false,

				id = 'hidetoggle'
			},
			{
				name = 'Now Playing Notifications',
				description = 'When active, Sirius will notify you when the next song in your Music queue plays.',
				settingType = 'Boolean',
				current = true,

				id = 'nowplaying'
			},
			{
				name = 'Friend Notifications',
				settingType = 'Boolean', 
				current = true,

				id = 'friendnotifs'
			},
			{
				name = 'Load Hidden',
				settingType = 'Boolean',
				current = false,

				id = 'loadhidden'
			}, 
			{
				name = 'Startup Sound Effect',
				settingType = 'Boolean',
				current = true,

				id = 'startupsound'
			}, 
			{
				name = 'Anti Idle',
				description = 'Remove all callbacks and events linked to the LocalPlayer Idled state. This may prompt detection from Adonis or similar anti-cheats.',
				settingType = 'Boolean',
				current = true,

				id = 'antiidle'
			},
			{
				name = 'Client-Based Anti Kick',
				description = 'Cancel any kick request involving you sent by the client. This may prompt detection from Adonis or similar anti-cheats. You will need to rejoin and re-run Sirius to toggle.',
				settingType = 'Boolean',
				current = false,

				id = 'antikick'
			},
			{
				name = 'Muffle audio while unfocused',
				settingType = 'Boolean', 
				current = true,

				id = 'muffleunfocused'
			},
		}
	},
	{
		name = 'Keybinds',
		description = 'Assign keybinds to actions or change keybinds such as the one to open/close Sirius.',
		color = Color3.fromRGB(0, 255, 128), -- Vibrant Teal
		minimumLicense = 'Free',
		categorySettings = {
			{
				name = 'Toggle smartBar',
				settingType = 'Key',
				current = "K",
				id = 'smartbar'
			},
			{
				name = 'Open ScriptSearch',
				settingType = 'Key',
				current = "T",
				id = 'scriptsearch'
			},
			{
				name = 'NoClip',
				settingType = 'Key',
				current = nil,
				id = 'noclip',
				callback = function()
					local noclip = siriusValues.actions[1]
					noclip.enabled = not noclip.enabled
					noclip.callback(noclip.enabled)
				end
			},
			{
				name = 'Flight',
				settingType = 'Key',
				current = nil,
				id = 'flight',
				callback = function()
					local flight = siriusValues.actions[2]
					flight.enabled = not flight.enabled
					flight.callback(flight.enabled)
				end
			},
			{
				name = 'Refresh',
				settingType = 'Key',
				current = nil,
				id = 'refresh',
				callback = function()
					local refresh = siriusValues.actions[3]
					if not refresh.enabled then
						refresh.enabled = true
						refresh.callback()
					end
				end
			},
			{
				name = 'Respawn',
				settingType = 'Key',
				current = nil,
				id = 'respawn',
				callback = function()
					local respawn = siriusValues.actions[4]
					if not respawn.enabled then
						respawn.enabled = true
						respawn.callback()
					end
				end
			},
			{
				name = 'Invulnerability',
				settingType = 'Key',
				current = nil,
				id = 'invulnerability',
				callback = function()
					local invulnerability = siriusValues.actions[5]
					invulnerability.enabled = not invulnerability.enabled
					invulnerability.callback(invulnerability.enabled)
				end
			},
			{
				name = 'Fling',
				settingType = 'Key',
				current = nil,
				id = 'fling',
				callback = function()
					local fling = siriusValues.actions[6]
					fling.enabled = not fling.enabled
					fling.callback(fling.enabled)
				end
			},
			{
				name = 'ESP',
				settingType = 'Key',
				current = nil,
				id = 'esp',
				callback = function()
					local esp = siriusValues.actions[7]
					esp.enabled = not esp.enabled
					esp.callback(esp.enabled)
				end
			},
			{
				name = 'Night and Day',
				settingType = 'Key',
				current = nil,
				id = 'nightandday',
				callback = function()
					local nightandday = siriusValues.actions[8]
					nightandday.enabled = not nightandday.enabled
					nightandday.callback(nightandday.enabled)
				end
			},
			{
				name = 'Global Audio',
				settingType = 'Key',
				current = nil,
				id = 'globalaudio',
				callback = function()
					local globalaudio = siriusValues.actions[9]
					globalaudio.enabled = not globalaudio.enabled
					globalaudio.callback(globalaudio.enabled)
				end
			},
			{
				name = 'Visibility',
				settingType = 'Key',
				current = nil,
				id = 'visibility',
				callback = function()
					local visibility = siriusValues.actions[10]
					visibility.enabled = not visibility.enabled
					visibility.callback(visibility.enabled)
				end
			},
		}
	},
	{
		name = 'Performance',
		description = 'Tweak and test your performance settings for Roblox in Sirius.',
		color = Color3.fromRGB(255, 120, 0), -- Radiant Orange
		minimumLicense = 'Free',
		categorySettings = {
			{
				name = 'Artificial FPS Limit',
				description = 'Sirius will automatically set your FPS to this number when you are tabbed-in to Roblox.',
				settingType = 'Number',
				values = {20, 5000},
				current = 240,

				id = 'fpscap'
			},
			{
				name = 'Limit FPS while unfocused',
				description = 'Sirius will automatically set your FPS to 60 when you tab-out or unfocus from Roblox.',
				settingType = 'Boolean', -- number for the cap below!! with min and max val
				current = true,

				id = 'fpsunfocused'
			},
			{
				name = 'Adaptive Latency Warning',
				description = 'Sirius will check your average latency in the background and notify you if your current latency significantly goes above your average latency.',
				settingType = 'Boolean',
				current = true,

				id = 'latencynotif'
			},
			{
				name = 'Adaptive Performance Warning',
				description = 'Sirius will check your average FPS in the background and notify you if your current FPS goes below a specific number.',
				settingType = 'Boolean',
				current = true,

				id = 'fpsnotif'
			},
		}
	},
	{
		name = 'Detections',
		description = 'Sirius detects and prevents anything malicious or possibly harmful to your wellbeing.',
		color = Color3.fromRGB(255, 0, 0), -- Pure Saturated Red
		minimumLicense = 'Free',
		categorySettings = {
			{
				name = 'Spatial Shield',
				description = 'Suppress loud sounds played from any audio source in-game, in real-time with Spatial Shield.',
				settingType = 'Boolean',
				minimumLicense = 'Pro',
				current = true,

				id = 'spatialshield'
			},
			{
				name = 'Spatial Shield Threshold',
				description = 'How loud a sound needs to be to be suppressed.',
				settingType = 'Number',
				minimumLicense = 'Pro',
				values = {100, 1000},
				current = 300,

				id = 'spatialshieldthreshold'
			},
			{
				name = 'Moderator Detection',
				description = 'Be notified whenever Sirius detects a player joins your session that could be a game moderator.',
				settingType = 'Boolean', 
				minimumLicense = 'Pro',
				current = true,

				id = 'moddetection'
			},
			{
				name = 'Intelligent HTTP Interception',
				description = 'Block external HTTP/HTTPS requests from being sent/recieved and ask you before allowing it to run.',
				settingType = 'Boolean',
				minimumLicense = 'Essential',
				current = true,

				id = 'intflowintercept'
			},
			{
				name = 'Intelligent Clipboard Interception',
				description = 'Block your clipboard from being set and ask you before allowing it to set your clipboard.',
				settingType = 'Boolean',
				minimumLicense = 'Essential',
				current = true,

				id = 'intflowinterceptclip'
			},
		},
	},
	{
		name = 'Chat Safety',
		description = 'Sirius detects and prevents anything malicious or spammy in the chat.',
		color = Color3.fromRGB(0, 200, 255), -- Azure Sky Blue
		minimumLicense = 'Free',
		categorySettings = {
			{
				name = 'Anti-Spam Bot',
				description = 'Automatically filter and hide messages from known spam bots.',
				settingType = 'Boolean',
				current = true,
				id = 'antispambot'
			},
			{
				name = 'Spam Notifications',
				description = 'Notify you whenever a suspected spam message is blocked.',
				settingType = 'Boolean',
				current = true,
				id = 'spamnotifications'
			},
		}
	},
	{
		name = 'Logging',
		description = 'Send logs to your specified webhook URL of things like player joins and leaves and messages.',
		color = Color3.fromRGB(255, 230, 0), -- Radiant Yellow
		minimumLicense = 'Free',
		categorySettings = {
			{
				name = 'Log Messages',
				description = 'Log messages sent by any player to your webhook.',
				settingType = 'Boolean',
				current = false,

				id = 'logmsg'
			},
			{
				name = 'Message Webhook URL',
				description = 'Discord Webhook URL',
				settingType = 'Input',
				current = 'No Webhook',

				id = 'logmsgurl'
			},
			{
				name = 'Log PlayerAdded and PlayerRemoving',
				description = 'Log whenever any player leaves or joins your session.',
				settingType = 'Boolean',
				current = false,

				id = 'logplrjoinleave'
			},
			{
				name = 'Player Added and Removing Webhook URL',
				description = 'Discord Webhook URL',
				settingType = 'Input',
				current = 'No Webhook',

				id = 'logplrjoinleaveurl'
			},
		}
	},
	{
		name = 'Infinite Yield',
		description = 'Use settings and menus strictly tied to Infinite Yield, fully accessible within Sirius.',
		color = Color3.fromRGB(230, 40, 40),
		minimumLicense = 'Free',
		categorySettings = {
			{
				name = 'Keybind 1 Command',
				description = 'Command to run (e.g. "vfly" or "noclip").',
				settingType = 'Input',
				current = '',
				id = 'iy_cmd1'
			},
			{
				name = 'Keybind 1',
				description = 'Execute Keybind 1 Command.',
				settingType = 'Key',
				callback = function()
					local cmd = ""
					for _, cat in ipairs(siriusSettings) do
						for _, set in ipairs(cat.categorySettings) do
							if set.id == 'iy_cmd1' then cmd = set.current end
						end
					end
					if cmd ~= "" and getgenv().execCmd then getgenv().execCmd(cmd) end
				end,
				id = 'iy_key1'
			},
			{
				name = 'Keybind 2 Command',
				description = 'Command to run on Key 2.',
				settingType = 'Input',
				current = '',
				id = 'iy_cmd2'
			},
			{
				name = 'Keybind 2',
				description = 'Execute Keybind 2 Command.',
				settingType = 'Key',
				callback = function()
					local cmd = ""
					for _, cat in ipairs(siriusSettings) do
						for _, set in ipairs(cat.categorySettings) do
							if set.id == 'iy_cmd2' then cmd = set.current end
						end
					end
					if cmd ~= "" and getgenv().execCmd then getgenv().execCmd(cmd) end
				end,
				id = 'iy_key2'
			},
			{
				name = 'Keybind 3 Command',
				description = 'Command to run on Key 3.',
				settingType = 'Input',
				current = '',
				id = 'iy_cmd3'
			},
			{
				name = 'Keybind 3',
				description = 'Execute Keybind 3 Command.',
				settingType = 'Key',
				callback = function()
					local cmd = ""
					for _, cat in ipairs(siriusSettings) do
						for _, set in ipairs(cat.categorySettings) do
							if set.id == 'iy_cmd3' then cmd = set.current end
						end
					end
					if cmd ~= "" and getgenv().execCmd then getgenv().execCmd(cmd) end
				end,
				id = 'iy_key3'
			},
		}
	},
}

-- Generate random username
local randomAdjective = siriusValues.nameGeneration.adjectives[math.random(1, #siriusValues.nameGeneration.adjectives)]
local randomNoun = siriusValues.nameGeneration.nouns[math.random(1, #siriusValues.nameGeneration.nouns)]
local randomNumber = math.random(100, 3999) -- You can customize the range
local randomUsername = randomAdjective .. randomNoun .. randomNumber

-- Initialise Sirius Client Interface
local guiParent = gethui and gethui() or coreGui
local sirius = guiParent:FindFirstChild("Sirius")
if sirius then
	sirius:Destroy()
end

local UI = game:GetObjects('rbxassetid://'..siriusValues.interfaceAsset)[1]
UI.Name = siriusValues.siriusName
UI.Parent = guiParent
UI.Enabled = false

-- Create Variables for Interface Elements
local characterPanel = UI.Character
local customScriptPrompt = UI.CustomScriptPrompt
local securityPrompt = UI.SecurityPrompt
local disconnectedPrompt = UI.Disconnected
local gameDetectionPrompt = UI.GameDetection
local homeContainer = UI.Home
local moderatorDetectionPrompt = UI.ModeratorDetectionPrompt
local musicPanel = UI.Music
local notificationContainer = UI.Notifications
local playerlistPanel = UI.Playerlist
local scriptSearch = UI.ScriptSearch
local scriptsPanel = UI.Scripts
local settingsPanel = UI.Settings
local smartBar = UI.SmartBar
local toggle = UI.Toggle
local starlight = UI.Starlight
local toastsContainer = UI.Toasts

-- Modern Glassmorphic Deep Shadow UI Refresh
for _, panel in pairs({characterPanel, customScriptPrompt, securityPrompt, disconnectedPrompt, gameDetectionPrompt, homeContainer, moderatorDetectionPrompt, musicPanel, playerlistPanel, scriptSearch, scriptsPanel, settingsPanel, smartBar}) do
	if panel and panel:IsA("Frame") then
		panel.BackgroundColor3 = Color3.fromRGB(15, 15, 18) -- True Apple Void
		panel.BackgroundTransparency = 0.3 -- Pure Glass translucency
		
		-- Deep Liquid Refraction (Gradient)
		if not panel:FindFirstChild("SiriusLiquidRefraction") then
			local grad = Instance.new("UIGradient")
			grad.Name = "SiriusLiquidRefraction"
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 65, 80)), -- Soft top catch
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 18)), -- Deep body
				ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 8)) -- Shadow base
			})
			grad.Rotation = 45
			grad.Parent = panel
		end

		-- Inner Light Bleed (Subtle Interior Glow)
		if not panel:FindFirstChild("SiriusInnerGlow") then
			local glow = Instance.new("Frame")
			glow.Name = "SiriusInnerGlow"
			glow.Size = UDim2.new(1, 0, 1, 0)
			glow.BackgroundTransparency = 1
			glow.ZIndex = 2
			
			local innerGrad = Instance.new("UIGradient")
			innerGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
			innerGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.9), -- Very subtle top light
				NumberSequenceKeypoint.new(0.12, 1),
				NumberSequenceKeypoint.new(1, 1)
			})
			innerGrad.Rotation = 45
			innerGrad.Parent = glow
			
			local innerCorner = Instance.new("UICorner")
			innerCorner.CornerRadius = UDim.new(0, 28)
			innerCorner.Parent = glow
			glow.Parent = panel
		end

		-- Moving Liquid Sheen (Faster Refractive Highlight)
		if not panel:FindFirstChild("SiriusGlassSheen") then
			local sheen = Instance.new("Frame")
			sheen.Name = "SiriusGlassSheen"
			sheen.Size = UDim2.new(2, 0, 2, 0)
			sheen.Position = UDim2.new(-1, 0, -0.5, 0)
			sheen.BackgroundTransparency = 1
			sheen.ZIndex = 3
			
			local sheenGrad = Instance.new("UIGradient")
			sheenGrad.Name = "SheenGrad"
			sheenGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
			sheenGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.49, 1),
				NumberSequenceKeypoint.new(0.5, 0.85), -- Sharp Sheen
				NumberSequenceKeypoint.new(0.51, 1),
				NumberSequenceKeypoint.new(1, 1)
			})
			sheenGrad.Rotation = 45
			sheenGrad.Parent = sheen
			sheen.Parent = panel

			task.spawn(function()
				while task.wait(5) and sheen and sheen.Parent do
					pcall(function()
						sheenGrad.Offset = Vector2.new(-1.3, 0)
						tweenService:Create(sheenGrad, TweenInfo.new(1.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Offset = Vector2.new(1.3, 0)}):Play()
					end)
				end
			end)
		end

		-- Sharp Edge Highlight (1px Rim)
		if not panel:FindFirstChild("SiriusModernStroke") then
			local stroke = Instance.new("UIStroke")
			stroke.Name = "SiriusModernStroke"
			stroke.Thickness = 1.1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			
			local strokeGrad = Instance.new("UIGradient")
			strokeGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 255)), -- Catch
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(60, 60, 80)), -- Mid
				ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 25)) -- Dark
			})
			strokeGrad.Rotation = 45
			strokeGrad.Parent = stroke
			stroke.Parent = panel
		end
		
		local crn = panel:FindFirstChildWhichIsA("UICorner")
		if crn then crn.CornerRadius = UDim.new(0, 28) end -- Large Liquid Corners
	end
end

-- Interface Caching
if not getgenv().cachedInGameUI then getgenv().cachedInGameUI = {} end
if not getgenv().cachedCoreUI then getgenv().cachedCoreUI = {} end

-- Malicious Behavior Prevention
local indexSetClipboard = "setclipboard"
local originalSetClipboard = getgenv()[indexSetClipboard]

local index = http_request and "http_request" or "request"
local originalRequest = getgenv()[index]

-- put this into siriusValues, like the fps and ping shit
local suppressedSounds = {}
local soundSuppressionNotificationCooldown = 0
local soundInstances = {}
local cachedIds = {}
local cachedText = {}

if not getMessage then siriusValues.chatSpy.enabled = false end

-- Call External Modules

-- httpRequest
local httpRequest = originalRequest

-- Sirius Functions
local function checkSirius() return UI.Parent end
local function getPing() return math.clamp(statsService.Network.ServerStatsItem["Data Ping"]:GetValue(), 10, 700) end
local function checkFolder()
	if isfolder then
		if not isfolder(siriusValues.siriusFolder) then makefolder(siriusValues.siriusFolder) end
		if not isfolder(siriusValues.siriusFolder.."/Music") then
			makefolder(siriusValues.siriusFolder.."/Music")
			writefile(siriusValues.siriusFolder.."/Music/readme.txt", "Hey there! Place your MP3 or other audio files in this folder, and have the ability to play them through the Sirius Music UI!")
		end
		if not isfolder(siriusValues.siriusFolder.."/Assets/Icons") then makefolder(siriusValues.siriusFolder.."/Assets/Icons") end
		if not isfolder(siriusValues.siriusFolder.."/Assets") then makefolder(siriusValues.siriusFolder.."/Assets") end
		
		-- Workspace Script Folders
		if not isfolder(siriusValues.siriusFolder.."/Universal") then makefolder(siriusValues.siriusFolder.."/Universal") end
		if not isfolder(siriusValues.siriusFolder.."/Custom") then makefolder(siriusValues.siriusFolder.."/Custom") end
	end
end
local function isPanel(name) return not table.find({"Home", "Music", "Settings"}, name) end

local function fetchFromCDN(path, write, savePath)
	pcall(function()
		checkFolder()

		local file = game:HttpGet(siriusValues.cdn..path) or nil
		if not file then return end
		if not write then return file end


		writefile(siriusValues.siriusFolder.."/"..savePath, file)

		return
	end)
end

local function fetchIcon(iconName)
	pcall(function()
		checkFolder()

		local pathCDN = siriusValues.icons..iconName..".png"
		local path = siriusValues.siriusFolder.."/Assets/"..iconName..".png"

		if not isfile(path) then
			local file = game:HttpGet(pathCDN)
			if not file then return end

			writefile(path, file)
		end

		local imageToReturn = getcustomasset(path)

		return imageToReturn
	end)
end

local function storeOriginalText(element)
	originalTextValues[element] = element.Text
end

local function undoAnonymousChanges()
	for element, originalText in pairs(originalTextValues) do
		element.Text = originalText
	end
end

local function createEsp(player)
	if player == localPlayer or not checkSirius() then 
		return
	end

	local function isAllowedByFilter()
		if not getgenv()._siriusESPTeams or #getgenv()._siriusESPTeams == 0 then return true end
		local teamName = player.Team and player.Team.Name or "No Team"
		return table.find(getgenv()._siriusESPTeams, teamName)
	end

	local function getEspState()
		for _, act in ipairs(siriusValues.actions) do
			if act.name == "Extrasensory Perception" then return act.enabled end
		end
		return false
	end

	local container = gethui and gethui() or coreGui
	
	-- Cleanup existing
	local oldH = container:FindFirstChild("SiriusUniversal_HL_"..player.Name)
	if oldH then oldH:Destroy() end
	local oldB = container:FindFirstChild("SiriusUniversal_BB_"..player.Name)
	if oldB then oldB:Destroy() end

	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = player.Character
	highlight.Name = "SiriusUniversal_HL_"..player.Name
	highlight.Enabled = getEspState() and (isAllowedByFilter() ~= nil)
	highlight.Parent = container

	local bb = Instance.new("BillboardGui")
	bb.Name = "SiriusUniversal_BB_"..player.Name
	bb.Size = UDim2.new(0, 140, 0, 40) -- Initial size, will be updated dynamically
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Enabled = getEspState() and (isAllowedByFilter() ~= nil)
	bb.Parent = container


	local function updateColors()
		local col = player.TeamColor and player.TeamColor.Color or Color3.fromRGB(245, 220, 40)
		highlight.OutlineColor = col
		highlight.FillColor = col
		return col
	end
	updateColors()


	player.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		highlight.Adornee = char
		bb.Adornee = char:FindFirstChild("Head")
	end)


	local nameLabel = Instance.new("TextLabel", bb)
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.RichText = true
	
	local isDev = table.find(siriusValues.devs, player.Name:lower())
	nameLabel.Text = player.DisplayName.." (@"..player.Name..")"..(isDev and " <font color='#00ff00'>[DEV]</font>" or "")
	
	nameLabel.TextColor3 = updateColors()
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold

	local distLabel = Instance.new("TextLabel", bb)
	distLabel.Name = "DistLabel"
	distLabel.Size = UDim2.new(1, 0, 0.4, 0)
	distLabel.Position = UDim2.new(0, 0, 0.52, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = "0 studs"
	distLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	distLabel.TextStrokeTransparency = 0.5
	distLabel.TextScaled = true
	distLabel.Font = Enum.Font.Gotham


	local function updateAdornee(char)
		if char then
			highlight.Adornee = char
			local head = char:FindFirstChild("Head")
			bb.Adornee = head
		end
	end

	updateAdornee(player.Character)
	
	player.CharacterAdded:Connect(function(character)
		if not checkSirius() then return end
		task.wait(0.2)
		updateAdornee(character)
	end)

	-- ULTRA ROBUST POLLING LOOP
	task.spawn(function()
		while checkSirius() and player and player.Parent do
			local success, err = pcall(function()
				if not highlight.Parent or not bb.Parent then return end
				
				local active = getEspState() and (isAllowedByFilter() ~= nil)
				
				-- Force state
				if highlight.Enabled ~= active then highlight.Enabled = active end
				if bb.Enabled ~= active then bb.Enabled = active end
				
				if active then
					-- Advanced Dynamic Scaling
					local myChar = localPlayer.Character
					local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
					local hisChar = player.Character
					local hisHrp = hisChar and hisChar:FindFirstChild("HumanoidRootPart")
					
					if myHrp and hisHrp then
						local dist = (myHrp.Position - hisHrp.Position).Magnitude
						distLabel.Text = math.floor(dist).." studs"
						
						-- Calculate scale: discrete when close, moderately larger when far
						local scaleFactor = math.clamp(dist / 180, 0.5, 1.3)
						bb.Size = UDim2.new(0, 140 * scaleFactor, 0, 40 * scaleFactor)
					end
					
					-- Color Update
					local teamCol = updateColors()
					nameLabel.TextColor3 = teamCol
					
					-- Ensure Adornee is still valid
					if player.Character and (not highlight.Adornee or highlight.Adornee ~= player.Character) then
						highlight.Adornee = player.Character
					end
					if player.Character and player.Character:FindFirstChild("Head") and (not bb.Adornee or bb.Adornee ~= player.Character.Head) then
						bb.Adornee = player.Character.Head
					end
				end
			end)
			task.wait(0.1)
		end
		-- Auto cleanup when player leaves or sirius closes
		pcall(function() highlight:Destroy() end)
		pcall(function() bb:Destroy() end)
	end)
end


local function makeDraggable(object)
	local dragging = false
	local relative = nil

	local offset = Vector2.zero
	local screenGui = object:FindFirstAncestorWhichIsA("ScreenGui")
	if screenGui and screenGui.IgnoreGuiInset then
		offset += guiService:GetGuiInset()
	end

	object.InputBegan:Connect(function(input, processed)
		if processed then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - userInputService:GetMouseLocation()
			dragging = true
		end
	end)

	local inputEnded = userInputService.InputEnded:Connect(function(input)
		if not dragging then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = false
		end
	end)

	local renderStepped = runService.RenderStepped:Connect(function()
		if dragging then
			local position = userInputService:GetMouseLocation() + relative + offset
			object.Position = UDim2.fromOffset(position.X, position.Y)
		end
	end)

	object.Destroying:Connect(function()
		inputEnded:Disconnect()
		renderStepped:Disconnect()
	end)
end

local function checkAction(target)
	local toReturn = {}

	for _, action in ipairs(siriusValues.actions) do
		if action.name == target then
			toReturn.action = action
			break
		end
	end

	for _, action in ipairs(characterPanel.Interactions.Grid:GetChildren()) do
		if action.name == target then
			toReturn.object = action
			break
		end
	end

	return toReturn
end

local function checkSetting(settingTarget, categoryTarget)
	for _, category in ipairs(siriusSettings) do
		if categoryTarget then
			if category.name == categoryTarget then
				for _, setting in ipairs(category.categorySettings) do
					if setting.name == settingTarget then
						return setting
					end
				end
			end
			return
		else
			for _, setting in ipairs(category.categorySettings) do
				if setting.name == settingTarget then
					return setting
				end
			end
		end
	end
end

local function wipeTransparency(ins, target, checkSelf, tween, duration)
	local transparencyProperties = siriusValues.transparencyProperties

	local function applyTransparency(obj)
		local properties = transparencyProperties[obj.className]

		if properties then
			local tweenProperties = {}

			for _, property in ipairs(properties) do
				tweenProperties[property] = target
			end

			for property, transparency in pairs(tweenProperties) do
				if tween then
					tweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {[property] = transparency}):Play()
				else
					obj[property] = transparency
				end

			end
		end
	end

	if checkSelf then
		applyTransparency(ins)
	end

	for _, descendant in ipairs(ins:getDescendants()) do
		applyTransparency(descendant)
	end
end

local function blurSignature(value)
	if not value then
		if lighting:FindFirstChild("SiriusBlur") then
			lighting:FindFirstChild("SiriusBlur"):Destroy()
		end
	else
		if not lighting:FindFirstChild("SiriusBlur") then
			local blurLight = Instance.new("DepthOfFieldEffect", lighting)
			blurLight.Name = "SiriusBlur"
			blurLight.Enabled = true
			blurLight.FarIntensity = 0
			blurLight.FocusDistance = 51.6
			blurLight.InFocusRadius = 50
			blurLight.NearIntensity = 0.8
		end
	end
end

local function figureNotifications()
	if checkSirius() then
		local notificationsSize = 0

		if #notifications > 0 then
			blurSignature(true)
		else
			blurSignature(false)
		end

		for i = #notifications, 0, -1 do
			local notification = notifications[i]
			if notification then
				if notificationsSize == 0 then
					notificationsSize = notification.Size.Y.Offset + 2
				else
					notificationsSize += notification.Size.Y.Offset + 5
				end
				local desiredPosition = UDim2.new(0.5, 0, 0, notificationsSize)
				if notification.Position ~= desiredPosition then
					notification:TweenPosition(desiredPosition, "Out", "Quint", 0.8, true)
				end
			end
		end	
	end
end

local contentProvider = game:GetService("ContentProvider")

local function queueNotification(Title, Description, Image)
	task.spawn(function()		
		if checkSirius() then
			local newNotification = notificationContainer.Template:Clone()
			newNotification.Parent = notificationContainer
			newNotification.Name = Title or "Unknown Title"
			newNotification.Visible = true

			newNotification.Title.Text = Title or "Unknown Title"
			newNotification.Description.Text = Description or "Unknown Description"
			newNotification.Time.Text = "now"

			-- Prepare for animation
			newNotification.AnchorPoint = Vector2.new(0.5, 1)
			newNotification.Position = UDim2.new(0.5, 0, -1, 0)
			newNotification.Size = UDim2.new(0, 320, 0, 500)
			newNotification.Description.Size = UDim2.new(0, 241, 0, 400)
			wipeTransparency(newNotification, 1, true)

			newNotification.Description.Size = UDim2.new(0, 241, 0, newNotification.Description.TextBounds.Y)
			newNotification.Size = UDim2.new(0, 100, 0, newNotification.Description.TextBounds.Y + 50)

			table.insert(notifications, newNotification)
			figureNotifications()

			local notificationSound = Instance.new("Sound")
			notificationSound.Parent = UI
			notificationSound.SoundId = "rbxassetid://255881176"
			notificationSound.Name = "notificationSound"
			notificationSound.Volume = 0.65
			notificationSound.PlayOnRemove = true
			notificationSound:Destroy()


			if not tonumber(Image) then
				newNotification.Icon.Image = 'rbxassetid://14317577326'
			else
				newNotification.Icon.Image = 'rbxassetid://'..Image or 0
			end

			newNotification:TweenPosition(UDim2.new(0.5, 0, 0, newNotification.Size.Y.Offset + 2), "Out", "Quint", 0.9, true)
			task.wait(0.1)
			tweenService:Create(newNotification, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 320, 0, newNotification.Description.TextBounds.Y + 50)}):Play()
			task.wait(0.05)
			tweenService:Create(newNotification, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.35}):Play()
			tweenService:Create(newNotification.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0.7}):Play()
			task.wait(0.05)
			tweenService:Create(newNotification.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
			task.wait(0.04)
			tweenService:Create(newNotification.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			task.wait(0.04)
			tweenService:Create(newNotification.Description, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.15}):Play()
			tweenService:Create(newNotification.Time, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.5}):Play()



			newNotification.Interact.MouseButton1Click:Connect(function()
				local foundNotification = table.find(notifications, newNotification)
				if foundNotification then table.remove(notifications, foundNotification) end

				tweenService:Create(newNotification, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1.5, 0, 0, newNotification.Position.Y.Offset)}):Play()

				task.wait(0.4)
				newNotification:Destroy()
				figureNotifications()
				return
			end)

			local waitTime = (#newNotification.Description.Text*0.1)+2
			if waitTime <= 1 then waitTime = 2.5 elseif waitTime > 10 then waitTime = 10 end

			task.wait(waitTime)

			local foundNotification = table.find(notifications, newNotification)
			if foundNotification then table.remove(notifications, foundNotification) end

			tweenService:Create(newNotification, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1.5, 0, 0, newNotification.Position.Y.Offset)}):Play()

			task.wait(1.2)

			newNotification:Destroy()
			figureNotifications()
		end
	end)
end

-- Register queueNotification globally so closures defined earlier can access it
getgenv().queueNotification = queueNotification

local function checkLastVersion()
	checkFolder()

	local lastVersion = isfile and isfile(siriusValues.siriusFolder.."/".."version.srs") and readfile(siriusValues.siriusFolder.."/".."version.srs") or nil

	if lastVersion then
		if lastVersion ~= siriusValues.siriusVersion then queueNotification("Sirius has been updated", "Sirius has been updated to version "..siriusValues.siriusVersion..", check our Discord for all new features and changes.", 4400701828)  end
	end

	if writefile then writefile(siriusValues.siriusFolder.."/".."version.srs", siriusValues.siriusVersion) end
end

local function removeReverbs(timing)
	timing = timing or 0.65

	for index, sound in next, soundInstances do
		if sound:FindFirstChild("SiriusAudioProfile") then
			local reverb = sound:FindFirstChild("SiriusAudioProfile")
			tweenService:Create(reverb, TweenInfo.new(timing, Enum.EasingStyle.Exponential), {HighGain = 0}):Play()
			tweenService:Create(reverb, TweenInfo.new(timing, Enum.EasingStyle.Exponential), {LowGain = 0}):Play()
			tweenService:Create(reverb, TweenInfo.new(timing, Enum.EasingStyle.Exponential), {MidGain = 0}):Play()

			task.delay(timing + 0.03, reverb.Destroy, reverb)
		end
	end
end

local function playNext()
	if #musicQueue == 0 then currentAudio.Playing = false currentAudio.SoundId = "" musicPanel.Playing.Text = "Not Playing" return end

	if not currentAudio then
		local newAudio = Instance.new("Sound")
		newAudio.Parent = UI
		newAudio.Name = "Audio"
		currentAudio = newAudio
	end

	musicPanel.Menu.TogglePlaying.ImageRectOffset = currentAudio.Playing and Vector2.new(804, 124) or Vector2.new(764, 244)
	local asset = getcustomasset(siriusValues.siriusFolder.."/Music/"..musicQueue[1].sound)

	if checkSetting("Now Playing Notifications").current then queueNotification("Now Playing", musicQueue[1].sound, 4400695581) end

	if musicPanel.Queue.List:FindFirstChild(tostring(musicQueue[1].instanceName)) then
		musicPanel.Queue.List:FindFirstChild(tostring(musicQueue[1].instanceName)):Destroy()
	end

	currentAudio.SoundId = asset
	musicPanel.Playing.Text = musicQueue[1].sound
	currentAudio:Play()
	musicPanel.Menu.TogglePlaying.ImageRectOffset = currentAudio.Playing and Vector2.new(804, 124) or Vector2.new(764, 244)
	currentAudio.Ended:Wait()

	table.remove(musicQueue, 1)

	playNext()
end

local function addToQueue(file)
	if not getcustomasset then return end
	checkFolder()
	if not isfile(siriusValues.siriusFolder.."/Music/"..file) then queueNotification("Unable to locate file", "Please ensure that your audio file is in the Sirius/Music folder and that you are including the file extension (e.g mp3 or ogg).", 4370341699) return end
	musicPanel.AddBox.Input.Text = ""

	local newAudio = musicPanel.Queue.List.Template:Clone()
	newAudio.Parent = musicPanel.Queue.List
	newAudio.Size = UDim2.new(0, 254, 0, 40)
	newAudio.Close.ImageTransparency = 1
	newAudio.Name = file
	if string.len(newAudio.FileName.Text) > 26 then
		newAudio.FileName.Text = string.sub(tostring(file), 1,24)..".."
	else
		newAudio.FileName.Text = file
	end
	newAudio.Visible = true
	newAudio.Duration.Text = ""

	table.insert(musicQueue, {sound = file, instanceName = newAudio.Name})

	local getLength = Instance.new("Sound", workspace)
	getLength.SoundId = getcustomasset(siriusValues.siriusFolder.."/Music/"..file)
	getLength.Volume = 0
	getLength:Play()
	task.wait(0.05)
	newAudio.Duration.Text = tostring(math.round(getLength.TimeLength)).."s"
	getLength:Stop()
	getLength:Destroy()

	newAudio.MouseEnter:Connect(function()
		tweenService:Create(newAudio, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
		tweenService:Create(newAudio.Close, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
		tweenService:Create(newAudio.Duration, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	end)

	newAudio.MouseLeave:Connect(function()
		tweenService:Create(newAudio.Close, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
		tweenService:Create(newAudio, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
		tweenService:Create(newAudio.Duration, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {TextTransparency = 0.7}):Play()
	end)

	newAudio.Close.MouseButton1Click:Connect(function()
		if not string.find(currentAudio.Name, file) then
			for i,v in pairs(musicQueue) do
				for _,b in pairs(v) do
					if b == newAudio.Name then
						newAudio:Destroy()
						table.remove(musicQueue, i)
					end
				end
			end
		else
			for i,v in pairs(musicQueue) do
				for _,b in pairs(v) do
					if b == newAudio.Name then
						newAudio:Destroy()
						table.remove(musicQueue, i)
						playNext()
					end
				end
			end
		end
	end)

	if #musicQueue == 1 then
		playNext()
	end
end

local function openMusic()
	debounce = true
	musicPanel.Visible = true
	musicPanel.Queue.List.Template.Visible = false

	debounce = false
end

local function closeMusic()
	debounce = true
	musicPanel.Visible = false

	debounce = false
end

local function createReverb(timing)
	for index, sound in next, soundInstances do
		if not sound:FindFirstChild("SiriusAudioProfile") then
			local reverb = Instance.new("EqualizerSoundEffect")

			reverb.Name = "SiriusAudioProfile"
			reverb.Parent = sound

			reverb.Enabled = false

			reverb.HighGain = 0
			reverb.LowGain = 0
			reverb.MidGain = 0
			reverb.Enabled = true

			if timing then
				tweenService:Create(reverb, TweenInfo.new(timing, Enum.EasingStyle.Exponential), {HighGain = -20}):Play()
				tweenService:Create(reverb, TweenInfo.new(timing, Enum.EasingStyle.Exponential), {LowGain = 5}):Play()
				tweenService:Create(reverb, TweenInfo.new(timing, Enum.EasingStyle.Exponential), {MidGain = -20}):Play()
			end
		end
	end
end

local function runScript(raw)
	loadstring(game:HttpGet(raw))()
end

local function syncExperienceInformation()
	siriusValues.currentCreator = creatorId

	if creatorType == Enum.CreatorType.Group then
		siriusValues.currentGroup = creatorId
		siriusValues.currentCreator = "group"
	end

	local success, info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(placeId)
	end)

	if success and info and info.Name then
		local function closeGameDetection()
			tweenService:Create(gameDetectionPrompt.Layer.ScriptSubtitle, TweenInfo.new(0.3, Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()
			tweenService:Create(gameDetectionPrompt.Layer.Run, TweenInfo.new(0.3, Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()
			tweenService:Create(gameDetectionPrompt.Layer.Run, TweenInfo.new(0.3, Enum.EasingStyle.Quint),  {BackgroundTransparency = 1}):Play()
			tweenService:Create(gameDetectionPrompt.Layer.Close, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
			tweenService:Create(gameDetectionPrompt.Thumbnail, TweenInfo.new(0.3, Enum.EasingStyle.Quint),  {ImageTransparency = 1}):Play()
			tweenService:Create(gameDetectionPrompt.ScriptTitle, TweenInfo.new(0.3, Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()
			tweenService:Create(gameDetectionPrompt.Layer.Run.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint),  {Transparency = 1}):Play()
			task.wait(0.05)
			tweenService:Create(gameDetectionPrompt, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 400, 0, 0)}):Play()
			tweenService:Create(gameDetectionPrompt.UICorner, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {CornerRadius = UDim.new(0, 5)}):Play()
			tweenService:Create(gameDetectionPrompt.Thumbnail.UICorner, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {CornerRadius = UDim.new(0, 5)}):Play()
			task.wait(0.41)
			gameDetectionPrompt.Visible = false
		end

		local scriptData = nil
		local rawFile = ""
		local isTrusted = false

		-- Check for Sirius Trusted Scripts first
		if siriusValues.trustedScripts[placeId] then
			scriptData = siriusValues.trustedScripts[placeId]
			rawFile = scriptData.script
			isTrusted = true
		else
			local searchSuccess, responseReq = pcall(function()
				if httpRequest then
					return httpRequest({Url = "https://scriptblox.com/api/script/search?q="..httpService:UrlEncode(info.Name).."&mode=free&max=10&page=1", Method = "GET"})
				else
					return {Body = game:HttpGet("https://scriptblox.com/api/script/search?q="..httpService:UrlEncode(info.Name).."&mode=free&max=10&page=1")}
				end
			end)
			
			if searchSuccess and responseReq and responseReq.Body then
				local respData = httpService:JSONDecode(responseReq.Body)
				if respData.result and respData.result.scripts and #respData.result.scripts > 0 then
					local bestScore = -999
					for _, script in ipairs(respData.result.scripts) do
						-- Safety Check: Script must be older than 4 days
						local isSafeAge = true
						if script.createdAt then
							local success, dt = pcall(function() return DateTime.fromIsoDate(script.createdAt) end)
							if success and dt then
								local ageSeconds = os.time() - dt.UnixTimestamp
								if ageSeconds < (4 * 24 * 60 * 60) then
									isSafeAge = false
								end
							end
						end

						if isSafeAge then
							if script.isPatched then continue end
							
							local score = 0
							if script.hasNegativeReviews then score = score - 300 end
							if script.hasPositiveReviews then score = score + 100 end

							local successAge, dt = pcall(function() return DateTime.fromIsoDate(script.createdAt) end)
							if successAge and dt then
								local ageSeconds = os.time() - dt.UnixTimestamp
								if ageSeconds >= 907200 and ageSeconds <= 5184000 then
									score = score + 250 -- Age bonus (1.5w - 2mo)
								end
							end

							if type(script.features) == "table" then
								for _, f in ipairs(script.features) do
									if type(f) == "string" then
										local fl = f:lower()
										if fl:match("keyless") or fl:match("no key") then 
											score = score + 300 
										elseif fl:match("key system") or fl:match("key required") then
											score = score - 100
										end
									end
								end
							end
							if score > bestScore then
								bestScore = score
								scriptData = script
							end
						end
					end
					if scriptData then rawFile = scriptData.script end
				end
			end
		end

		if scriptData and rawFile ~= "" then
			gameDetectionPrompt.ScriptTitle.Text = info.Name
			gameDetectionPrompt.Layer.ScriptSubtitle.Text = (isTrusted and "⭐ " or "") .. scriptData.title
			gameDetectionPrompt.Thumbnail.Image = "https://assetgame.roblox.com/Game/Tools/ThumbnailAsset.ashx?aid="..tostring(placeId).."&fmt=png&wd=420&ht=420"

			gameDetectionPrompt.Size = UDim2.new(0, 550, 0, 0)
			gameDetectionPrompt.Position = UDim2.new(0.5, 0, 0, 120)
			gameDetectionPrompt.UICorner.CornerRadius = UDim.new(0, 45)
			gameDetectionPrompt.Thumbnail.UICorner.CornerRadius = UDim.new(0, 45)
			local runCrn = gameDetectionPrompt.Layer.Run:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", gameDetectionPrompt.Layer.Run)
			runCrn.CornerRadius = UDim.new(1, 0) -- Full pill shape for the button
			gameDetectionPrompt.ScriptTitle.Position = UDim2.new(0, 30, 0.5, 0)
			gameDetectionPrompt.Layer.Visible = false
			gameDetectionPrompt.Warning.Visible = false

			wipeTransparency(gameDetectionPrompt, 1, true)
			gameDetectionPrompt.Visible = true

			tweenService:Create(gameDetectionPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(14, 14, 18)}):Play()
			tweenService:Create(gameDetectionPrompt.Thumbnail, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {ImageTransparency = 0.4}):Play()
			tweenService:Create(gameDetectionPrompt.ScriptTitle, TweenInfo.new(0.6, Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
			tweenService:Create(gameDetectionPrompt, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 587, 0, 44)}):Play()
			tweenService:Create(gameDetectionPrompt, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5, 0, 0, 150)}):Play()

			task.wait(1)
			wipeTransparency(gameDetectionPrompt.Layer, 1, true)
			gameDetectionPrompt.Layer.Visible = true

			tweenService:Create(gameDetectionPrompt, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 473, 0, 154)}):Play()
			tweenService:Create(gameDetectionPrompt.ScriptTitle, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 23, 0.352, 0)}):Play()
			tweenService:Create(gameDetectionPrompt, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5, 0, 0, 200)}):Play()
			tweenService:Create(gameDetectionPrompt.UICorner, TweenInfo.new(1, Enum.EasingStyle.Exponential), {CornerRadius = UDim.new(0, 45)}):Play()
			tweenService:Create(gameDetectionPrompt.Thumbnail.UICorner, TweenInfo.new(1, Enum.EasingStyle.Exponential), {CornerRadius = UDim.new(0, 45)}):Play()
			tweenService:Create(gameDetectionPrompt.Thumbnail, TweenInfo.new(1, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5}):Play()

			task.wait(0.3)
			tweenService:Create(gameDetectionPrompt.Layer.ScriptSubtitle, TweenInfo.new(0.6, Enum.EasingStyle.Quint),  {TextTransparency = 0.3}):Play()
			tweenService:Create(gameDetectionPrompt.Layer.Run, TweenInfo.new(0.6, Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
			tweenService:Create(gameDetectionPrompt.Layer.Run.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint),  {Transparency = 0.85}):Play()
			tweenService:Create(gameDetectionPrompt.Layer.Run, TweenInfo.new(0.6, Enum.EasingStyle.Quint),  {BackgroundTransparency = 0.6}):Play()

			task.wait(0.2)
			tweenService:Create(gameDetectionPrompt.Layer.Close, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()

			if getgenv()._siriusGameDetectionRunConn then getgenv()._siriusGameDetectionRunConn:Disconnect() end
			getgenv()._siriusGameDetectionRunConn = gameDetectionPrompt.Layer.Run.MouseButton1Click:Connect(function()
				closeGameDetection()
				queueNotification("Running Script", "Now running execution for "..info.Name, 4400701828)
				local func, err = loadstring(rawFile)
				if func then task.spawn(func) else queueNotification("Error", tostring(err), 4370336704) end
			end)

			if getgenv()._siriusGameDetectionCloseConn then getgenv()._siriusGameDetectionCloseConn:Disconnect() end
			getgenv()._siriusGameDetectionCloseConn = gameDetectionPrompt.Layer.Close.MouseButton1Click:Connect(function()
				closeGameDetection()
			end)
		end
	end
end

-- Panel Open Glow Pulse — creates an expanding ring of light when a panel is opened
local function createPanelGlowPulse(panel)
	if not panel or not panel:IsA("GuiObject") then return end
	task.spawn(function()
		local pulse = Instance.new("ImageLabel")
		pulse.Name = "GlowPulse"
		pulse.Image = "rbxassetid://6073489140"
		pulse.BackgroundTransparency = 1
		pulse.ImageTransparency = 0.6
		pulse.ImageColor3 = Color3.fromRGB(60, 120, 255)
		pulse.Size = UDim2.new(0.3, 0, 0.3, 0)
		pulse.Position = UDim2.new(0.5, 0, 0.5, 0)
		pulse.AnchorPoint = Vector2.new(0.5, 0.5)
		pulse.ZIndex = -1
		pulse.Parent = panel

		tweenService:Create(pulse, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {
			Size = UDim2.new(2.5, 0, 5, 0),
			ImageTransparency = 1
		}):Play()
		task.wait(0.85)
		pulse:Destroy()
	end)
end

-- Home Panel Floating Particles
local function createFloatingParticles(container)
	if not container or not container:IsA("GuiObject") then return end
	
	-- Clear old particles
	for _, child in ipairs(container:GetChildren()) do
		if child.Name == "SiriusParticle" then child:Destroy() end
	end
	
	for i = 1, 12 do
		task.spawn(function()
			local particle = Instance.new("Frame")
			particle.Name = "SiriusParticle"
			particle.BackgroundColor3 = Color3.fromRGB(
				math.random(80, 180),
				math.random(120, 220),
				255
			)
			particle.BackgroundTransparency = math.random(70, 90) / 100
			particle.BorderSizePixel = 0
			local sz = math.random(2, 5)
			particle.Size = UDim2.new(0, sz, 0, sz)
			particle.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, math.random() * 0.8 + 0.1, 0)
			particle.ZIndex = -1
			particle.Parent = container
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = particle
			
			-- Float animation loop
			local startX = particle.Position.X.Scale
			local startY = particle.Position.Y.Scale
			
			while particle and particle.Parent and checkSirius() do
				local targetX = math.clamp(startX + (math.random() - 0.5) * 0.15, 0.02, 0.98)
				local targetY = math.clamp(startY + (math.random() - 0.5) * 0.15, 0.02, 0.98)
				local duration = math.random(30, 60) / 10
				
				tweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Position = UDim2.new(targetX, 0, targetY, 0),
					BackgroundTransparency = math.random(65, 92) / 100
				}):Play()
				
				task.wait(duration)
				startX = targetX
				startY = targetY
			end
		end)
	end
end

-- Cleanup particles when Home closes
local function destroyFloatingParticles(container)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do
		if child.Name == "SiriusParticle" then
			tweenService:Create(child, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
			task.delay(0.45, function() if child and child.Parent then child:Destroy() end end)
		end
	end
end

local function triggerTransitionEffect()
	-- Subtle bloom pulse on panel transitions
	task.spawn(function()
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "SiriusPanelBloom"
		bloom.Intensity = 0
		bloom.Size = 30
		bloom.Threshold = 1.1
		bloom.Parent = lighting

		tweenService:Create(bloom, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Intensity = 0.15, Threshold = 0.95}):Play()
		task.wait(0.3)
		tweenService:Create(bloom, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Intensity = 0, Threshold = 1.1}):Play()
		task.wait(0.65)
		bloom:Destroy()
	end)
end


local function updateSlider(data, setValue, forceValue)
	local sliderObj = data.object
	if not sliderObj then return end
	
	local progress = sliderObj:FindFirstChild("Progress")
	local info = sliderObj:FindFirstChild("Information")
	local interact = sliderObj:FindFirstChild("Interact") or sliderObj
	local grad = progress:FindFirstChildWhichIsA("UIGradient")
	
	local inverse_interpolation
	
	if setValue ~= nil then -- Explicit nil check to allow 0
		setValue = math.clamp(setValue, data.values[1], data.values[2])
		inverse_interpolation = (setValue - data.values[1]) / (data.values[2] - data.values[1])
	else
		local absPos = interact.AbsolutePosition.X
		local absSize = interact.AbsoluteSize.X
		local mousePos = userInputService:GetMouseLocation().X
		
		if absSize > 0 then
			local posX = math.clamp(mousePos, absPos, absPos + absSize)
			inverse_interpolation = (posX - absPos) / absSize
		else
			inverse_interpolation = 0
		end
	end

	-- Handle potential NaN
	if inverse_interpolation ~= inverse_interpolation then inverse_interpolation = 0 end

	-- Tweenable Offset Mask Logic
	if grad then
		-- Map 0-1 percentage to Offset X (-0.5 to 0.5 to center the 0.5 cut-off)
		local targetOffsetX = -(0.5 - inverse_interpolation)
		tweenService:Create(grad, TweenInfo.new(.18, Enum.EasingStyle.Quint), {
			Offset = Vector2.new(targetOffsetX, 0)
		}):Play()
	else
		tweenService:Create(progress, TweenInfo.new(.18, Enum.EasingStyle.Quint), {Size = UDim2.new(inverse_interpolation, 0, 1, 0)}):Play()
	end

	local value = math.floor(data.values[1] + (data.values[2] - data.values[1]) * inverse_interpolation + .5)
	info.Text = value.." "..data.name
	data.value = value

	if data.callback and (setValue == nil or forceValue) then
		task.spawn(data.callback, value)
	end
end

local function resetSliders()
	for _, v in pairs(siriusValues.sliders) do
		updateSlider(v, v.default, true)
	end
end


local function sortActions()	
	characterPanel.Interactions.Grid.Template.Visible = false
	characterPanel.Interactions.Sliders.Template.Visible = false

	for _, action in ipairs(siriusValues.actions) do
		local newAction = characterPanel.Interactions.Grid.Template:Clone()
		newAction.Name = action.name
		newAction.Parent = characterPanel.Interactions.Grid
		newAction.BackgroundColor3 = action.color
		newAction.UIStroke.Color = action.color
		newAction.Icon.Image = "rbxassetid://"..action.images[2]
		newAction.Visible = true

		newAction.BackgroundTransparency = 0.6 -- Slightly more glassmorphic
		newAction.Transparency = 0.65

		
		local crn = newAction:FindFirstChildWhichIsA("UICorner")
		if crn then crn.CornerRadius = UDim.new(0, 18) end -- Full Pill for 36px height

		local stroke = newAction:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke", newAction)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Thickness = 0.8
		stroke.Transparency = 0.75 -- Subtle internal look
		stroke.Color = action.color
		
		newAction.Parent.ClipsDescendants = false -- Prevent Outline Clipping


		newAction.MouseEnter:Connect(function()
			characterPanel.Interactions.ActionsTitle.Text = string.upper(action.name)
			if action.enabled or debounce then return end
			tweenService:Create(newAction, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.4}):Play()
			tweenService:Create(newAction.UIStroke, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Transparency = 0.6}):Play()
		end)

		newAction.MouseLeave:Connect(function()
			if action.enabled or debounce then return end
			tweenService:Create(newAction, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.55}):Play()
			tweenService:Create(newAction.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.7}):Play()
		end)

		characterPanel.Interactions.Grid.MouseLeave:Connect(function()
			characterPanel.Interactions.ActionsTitle.Text = "PLAYER ACTIONS"
		end)

		newAction.Interact.MouseButton1Click:Connect(function()
			local success, response = pcall(function()
				action.enabled = not action.enabled
				action.callback(action.enabled)

				if action.enabled then
					newAction.Icon.Image = "rbxassetid://"..action.images[1]
					tweenService:Create(newAction, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.1}):Play()
					tweenService:Create(newAction.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
					tweenService:Create(newAction.Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0.1}):Play()

					if action.disableAfter then
						task.delay(action.disableAfter, function()
							action.enabled = false
							newAction.Icon.Image = "rbxassetid://"..action.images[2]
							tweenService:Create(newAction, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.55}):Play()
							tweenService:Create(newAction.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
							tweenService:Create(newAction.Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
						end)
					end

					if action.rotateWhileEnabled then
						repeat
							newAction.Icon.Rotation = 0
							tweenService:Create(newAction.Icon, TweenInfo.new(0.75, Enum.EasingStyle.Quint), {Rotation = 360}):Play()
							task.wait(1)
						until not action.enabled
						newAction.Icon.Rotation = 0
					end
				else
					newAction.Icon.Image = "rbxassetid://"..action.images[2]
					tweenService:Create(newAction, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.55}):Play()
					tweenService:Create(newAction.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
					tweenService:Create(newAction.Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
				end
			end)

			if not success then
				queueNotification("Action Error", "This action ('"..(action.name).."') had an error while running, please report this to the Sirius team at sirius.menu/discord", 4370336704)
				action.enabled = false
				newAction.Icon.Image = "rbxassetid://"..action.images[2]
				tweenService:Create(newAction, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.55}):Play()
				tweenService:Create(newAction.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
				tweenService:Create(newAction.Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
			end
		end)
	end

	if localPlayer.Character then
		if not localPlayer.Character:FindFirstChildOfClass('Humanoid').UseJumpPower then
			siriusValues.sliders[2].name = "jump height"
			siriusValues.sliders[2].default = 7.2
			siriusValues.sliders[2].values = {0, 120}
		end
	end


	-- Prepare Template for pill shape before cloning
	local temp = characterPanel.Interactions.Sliders.Template
	local tCrn = temp:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", temp)
	tCrn.CornerRadius = UDim.new(0, 16) -- Fixed radius matching half of 32px height
	local tpCrn = temp.Progress:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", temp.Progress)
	tpCrn.CornerRadius = UDim.new(0, 16) 

	-- Align Sliders container with the heading (push further right to align)
	characterPanel.Interactions.Sliders.Position = UDim2.new(0, 30, 0, 75)
	
	for _, slider in ipairs(siriusValues.sliders) do
		local newSlider = characterPanel.Interactions.Sliders.Template:Clone()
		newSlider.Name = slider.name.." Slider"
		newSlider.Parent = characterPanel.Interactions.Sliders
		newSlider.BackgroundColor3 = slider.color
		newSlider.Visible = true
		newSlider.Size = UDim2.new(0, 240, 0, 32)
		newSlider.ClipsDescendants = false

		local progress = newSlider.Progress
		local info = newSlider.Information
		progress.BackgroundColor3 = slider.color
		newSlider.UIStroke.Color = slider.color
		info.Text = slider.name

		-- Standard pill rounding
		local crn = newSlider:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", newSlider)
		crn.CornerRadius = UDim.new(0, 16)
		local prgCrn = progress:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", progress)
		prgCrn.CornerRadius = UDim.new(0, 16)
		
		-- Fixed Gradient Mask for perfect left-side rounding
		local grad = Instance.new("UIGradient", progress)
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.499, 0),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(1, 1)
		})
		grad.Offset = Vector2.new(-0.5, 0) -- Start fully hidden at 0%
		progress.Size = UDim2.new(1, 0, 1, 0) -- Full width for perfect rounding

		slider.object = newSlider

		newSlider.MouseEnter:Connect(function()
			if debounce or slider.active then return end
			tweenService:Create(newSlider, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.35}):Play()
			tweenService:Create(newSlider.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
			tweenService:Create(info, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0.05}):Play()
		end)

		newSlider.MouseLeave:Connect(function()
			if debounce or slider.active then return end
			tweenService:Create(newSlider, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.8}):Play()
			tweenService:Create(newSlider.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.6}):Play()
			tweenService:Create(info, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
		end)

		newSlider.Interact.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not debounce and checkSirius() then
				slider.active = true
				updateSlider(slider)

				tweenService:Create(slider.object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.9}):Play()
				tweenService:Create(slider.object.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
				tweenService:Create(info, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0.05}):Play()
			end
		end)

		updateSlider(slider, slider.default, true)
	end
end

local function getAdaptiveHighPingThreshold()
	local adaptiveBaselinePings = siriusValues.pingProfile.adaptiveBaselinePings

	if #adaptiveBaselinePings == 0 then
		return siriusValues.pingProfile.adaptiveHighPingThreshold
	end

	table.sort(adaptiveBaselinePings)
	local median
	if #adaptiveBaselinePings % 2 == 0 then
		median = (adaptiveBaselinePings[#adaptiveBaselinePings/2] + adaptiveBaselinePings[#adaptiveBaselinePings/2 + 1]) / 2
	else
		median = adaptiveBaselinePings[math.ceil(#adaptiveBaselinePings/2)]
	end

	return median * siriusValues.pingProfile.spikeThreshold
end

local function checkHighPing()
	local recentPings = siriusValues.pingProfile.recentPings
	local adaptiveBaselinePings = siriusValues.pingProfile.adaptiveBaselinePings

	local currentPing = getPing()
	table.insert(recentPings, currentPing)

	if #recentPings > siriusValues.pingProfile.maxSamples then
		table.remove(recentPings, 1)
	end

	if #adaptiveBaselinePings < siriusValues.pingProfile.adaptiveBaselineSamples then
		if currentPing >= 350 then currentPing = 300 end

		table.insert(adaptiveBaselinePings, currentPing)

		return false
	end

	local averagePing = 0
	for _, ping in ipairs(recentPings) do
		averagePing = averagePing + ping
	end
	averagePing = averagePing / #recentPings

	if averagePing > getAdaptiveHighPingThreshold() then
		return true
	end

	return false
end

local function checkTools()
	task.wait(0.03)
	if localPlayer.Backpack and localPlayer.Character then
		if localPlayer.Backpack:FindFirstChildOfClass('Tool') or localPlayer.Character:FindFirstChildOfClass('Tool') then
			return true
		end
	else
		return false
	end
end

local function closePanel(panelName, openingOther)
	triggerTransitionEffect()
	debounce = true

	local button = smartBar.Buttons:FindFirstChild(panelName)
	local panel = UI:FindFirstChild(panelName)

	if not isPanel(panelName) then return end
	if not (panel and button) then return end

	local panelSize = UDim2.new(0, 581, 0, 246)

	if not openingOther then
		if panel.Name == "Character" then -- Character Panel Animation

			tweenService:Create(characterPanel.Interactions.PropertiesTitle, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()

			for _, slider in ipairs(characterPanel.Interactions.Sliders:GetChildren()) do
				if slider.ClassName == "Frame" then 
					tweenService:Create(slider, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
					tweenService:Create(slider.Progress, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
					tweenService:Create(slider.UIStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
					tweenService:Create(slider.Shadow, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
					tweenService:Create(slider.Information, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play() -- tween the text after
				end
			end

			tweenService:Create(characterPanel.Interactions.Reset, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
			tweenService:Create(characterPanel.Interactions.ActionsTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()

			for _, gridButton in ipairs(characterPanel.Interactions.Grid:GetChildren()) do
				if gridButton.ClassName == "Frame" then 
					tweenService:Create(gridButton, TweenInfo.new(0.21, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
					tweenService:Create(gridButton.UIStroke, TweenInfo.new(0.1, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					tweenService:Create(gridButton.Icon, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
					tweenService:Create(gridButton.Shadow, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
				end
			end

			tweenService:Create(characterPanel.Interactions.Serverhop, TweenInfo.new(.15,Enum.EasingStyle.Quint),  {BackgroundTransparency = 1}):Play()
			tweenService:Create(characterPanel.Interactions.Serverhop.Title, TweenInfo.new(.15,Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()
			tweenService:Create(characterPanel.Interactions.Serverhop.UIStroke, TweenInfo.new(.15,Enum.EasingStyle.Quint),  {Transparency = 1}):Play()

			tweenService:Create(characterPanel.Interactions.Rejoin, TweenInfo.new(.15,Enum.EasingStyle.Quint),  {BackgroundTransparency = 1}):Play()
			tweenService:Create(characterPanel.Interactions.Rejoin.Title, TweenInfo.new(.15,Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()
			tweenService:Create(characterPanel.Interactions.Rejoin.UIStroke, TweenInfo.new(.15,Enum.EasingStyle.Quint),  {Transparency = 1}):Play()

		elseif panel.Name == "Scripts" then -- Scripts Panel Animation

			for _, scriptButton in ipairs(scriptsPanel.Interactions.Selection:GetChildren()) do
				if scriptButton.ClassName == "Frame" then
					tweenService:Create(scriptButton, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
					if scriptButton:FindFirstChild('Icon') then tweenService:Create(scriptButton.Icon, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play() end
					tweenService:Create(scriptButton.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
					if scriptButton:FindFirstChild('Subtitle') then	tweenService:Create(scriptButton.Subtitle, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play() end
					tweenService:Create(scriptButton.UIStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
				end
			end

		elseif panel.Name == "Playerlist" then -- Playerlist Panel Animation

			for _, playerIns in ipairs(playerlistPanel.Interactions.List:GetDescendants()) do
				if playerIns.ClassName == "Frame" then
					tweenService:Create(playerIns, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
				elseif playerIns.ClassName == "TextLabel" or playerIns.ClassName == "TextButton" then
					if playerIns.Name == "DisplayName" then
						tweenService:Create(playerIns, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
					else
						tweenService:Create(playerIns, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
					end
				elseif playerIns.ClassName == "ImageLabel" or playerIns.ClassName == "ImageButton" then
					tweenService:Create(playerIns, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
					if playerIns.Name == "Avatar" then tweenService:Create(playerIns, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play() end
				elseif playerIns.ClassName == "UIStroke" then
					tweenService:Create(playerIns, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
				end
			end

			tweenService:Create(playerlistPanel.Interactions.SearchFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
			tweenService:Create(playerlistPanel.Interactions.SearchFrame.Icon, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
			tweenService:Create(playerlistPanel.Interactions.SearchFrame.SearchBox, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
			tweenService:Create(playerlistPanel.Interactions.SearchFrame.UIStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
			tweenService:Create(playerlistPanel.Interactions.List, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ScrollBarImageTransparency = 1}):Play()


		end

		tweenService:Create(panel.Icon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		tweenService:Create(panel.Title, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
		tweenService:Create(panel.UIStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
		tweenService:Create(panel.Shadow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		task.wait(0.03)

		tweenService:Create(panel, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {BackgroundTransparency = 1}):Play()
		tweenService:Create(panel, TweenInfo.new(1.1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = button.Size}):Play()
		tweenService:Create(panel, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = siriusValues.buttonPositions[panelName]}):Play()
		tweenService:Create(toggle, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 1, -85)}):Play()
	end

	-- Animate interactive elements
	if openingOther then
		tweenService:Create(panel, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 350, 1, -90)}):Play()
		wipeTransparency(panel, 1, true, true, 0.3)
	end

	task.wait(0.5)
	panel.Size = panelSize
	panel.Visible = false

	debounce = false
end

local function openPanel(panelName)
	if debounce then return end
	triggerTransitionEffect()
	debounce = true

	local button = smartBar.Buttons:FindFirstChild(panelName)
	local panel = UI:FindFirstChild(panelName)

	if not isPanel(panelName) then return end
	if not (panel and button) then return end

	for _, otherPanel in ipairs(UI:GetChildren()) do
		if smartBar.Buttons:FindFirstChild(otherPanel.Name) then
			if isPanel(otherPanel.Name) and otherPanel.Visible then
				task.spawn(closePanel, otherPanel.Name, true)
				task.wait()
			end
		end
	end

	local panelSize = UDim2.new(0, 581, 0, 246)

	panel.Size = button.Size
	panel.Position = siriusValues.buttonPositions[panelName]

	wipeTransparency(panel, 1, true)

	panel.Visible = true
	createPanelGlowPulse(panel)

	tweenService:Create(toggle, TweenInfo.new(0.65, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 0, 1, -(panelSize.Y.Offset + 95))}):Play()

	tweenService:Create(panel, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
	tweenService:Create(panel, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {Size = panelSize}):Play()
	tweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 0, 1, -90)}):Play()
	task.wait(0.1)
	tweenService:Create(panel.Shadow, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0.7}):Play()
	tweenService:Create(panel.Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
	task.wait(0.05)
	tweenService:Create(panel.Title, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	tweenService:Create(panel.UIStroke, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {Transparency = 0.95}):Play()
	task.wait(0.05)

	-- Animate interactive elements
	if panel.Name == "Character" then -- Character Panel Animation
		tweenService:Create(characterPanel.Interactions.PropertiesTitle, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {TextTransparency = 0.65}):Play()

		local sliderInfo = {}
		for _, slider in ipairs(characterPanel.Interactions.Sliders:GetChildren()) do
			if slider.ClassName == "Frame" then 
				local progress = slider:FindFirstChild("Progress")
				local info = slider:FindFirstChild("Information")
				local gradient = progress:FindFirstChildWhichIsA("UIGradient")

				table.insert(sliderInfo, {slider.Name, progress.Size, info.Text})
				
				progress.Size = UDim2.new(1, 0, 1, 0)
				if gradient then gradient.Offset = Vector2.new(-0.5, 0) end -- Reset to zero
				progress.BackgroundTransparency = 0

				tweenService:Create(slider, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.8}):Play()
				tweenService:Create(slider.UIStroke, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Transparency = 0.6}):Play()
				if slider:FindFirstChild("Shadow") then tweenService:Create(slider.Shadow, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {ImageTransparency = 0.6}):Play() end
				tweenService:Create(info, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {TextTransparency = 0.2}):Play()
				
				local sCrn = slider:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", slider)
				sCrn.CornerRadius = UDim.new(0, 16)
				local pCrn = progress:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", progress)
				pCrn.CornerRadius = UDim.new(0, 16)
			end
		end

		for _, sliderV in pairs(sliderInfo) do
			if characterPanel.Interactions.Sliders:FindFirstChild(sliderV[1]) then
				local slider = characterPanel.Interactions.Sliders:FindFirstChild(sliderV[1])
				local progress = slider.Progress
				local info = slider.Information
				local gradient = progress:FindFirstChildWhichIsA("UIGradient")

				local tweenValue = Instance.new("IntValue", UI)
				local tweenTo
				local name

				for _, sliderFound in ipairs(siriusValues.sliders) do
					if sliderFound.name.." Slider" == slider.Name then
						local inv = (sliderFound.value - sliderFound.values[1]) / (sliderFound.values[2] - sliderFound.values[1])
						tweenTo = sliderFound.value
						name = sliderFound.name
						targetOffsetX = -(0.5 - inv)
						break
					end
				end

				if gradient then
					tweenService:Create(gradient, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Offset = Vector2.new(targetOffsetX, 0)}):Play()
				end

				local function animateNumber(n)
					tweenService:Create(tweenValue, TweenInfo.new(0.35, Enum.EasingStyle.Exponential), {Value = n}):Play()
					task.delay(0.4, tweenValue.Destroy, tweenValue)
				end

				tweenValue:GetPropertyChangedSignal("Value"):Connect(function()
					info.Text = tostring(tweenValue.Value).." "..name
				end)

				animateNumber(tweenTo)
			end
		end

		tweenService:Create(characterPanel.Interactions.Reset, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {ImageTransparency = 0.7}):Play()
		tweenService:Create(characterPanel.Interactions.ActionsTitle, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {TextTransparency = 0.65}):Play()

		for _, gridButton in ipairs(characterPanel.Interactions.Grid:GetChildren()) do
			if gridButton.ClassName == "Frame" then 
				for _, action in ipairs(siriusValues.actions) do
					if action.name == gridButton.Name then
						if action.enabled then
							tweenService:Create(gridButton, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.1}):Play()
							tweenService:Create(gridButton.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
							tweenService:Create(gridButton.Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0.1}):Play()
						else
							tweenService:Create(gridButton, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.55}):Play()
							tweenService:Create(gridButton.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
							tweenService:Create(gridButton.Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
						end
						break
					end
				end

				tweenService:Create(gridButton.Shadow, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {ImageTransparency = 0.6}):Play()
			end
		end

		tweenService:Create(characterPanel.Interactions.Serverhop, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0}):Play()
		tweenService:Create(characterPanel.Interactions.Serverhop.Title, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0.5}):Play()
		tweenService:Create(characterPanel.Interactions.Serverhop.UIStroke, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Transparency = 0}):Play()

		tweenService:Create(characterPanel.Interactions.Rejoin, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0}):Play()
		tweenService:Create(characterPanel.Interactions.Rejoin.Title, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0.5}):Play()
		tweenService:Create(characterPanel.Interactions.Rejoin.UIStroke, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Transparency = 0}):Play()

	elseif panel.Name == "Scripts" then -- Scripts Panel Animation

		pcall(function() 
			scriptsPanel.Interactions.Selection.ScrollingEnabled = false 
			scriptsPanel.Interactions.Selection.ScrollBarThickness = 0
			scriptsPanel.Interactions.Selection.Active = false
		end)
		for _, scriptButton in ipairs(scriptsPanel.Interactions.Selection:GetChildren()) do
			if scriptButton.ClassName == "Frame" then
				tweenService:Create(scriptButton, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
				if scriptButton:FindFirstChild('Icon') then tweenService:Create(scriptButton.Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play() end
				tweenService:Create(scriptButton.Title, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
				if scriptButton:FindFirstChild('Subtitle') then	tweenService:Create(scriptButton.Subtitle, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 0.3}):Play() end
				tweenService:Create(scriptButton.UIStroke, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {Transparency = 0.2}):Play()
			end
		end

	elseif panel.Name == "Playerlist" then -- Playerlist Panel Animation

		for _, playerIns in ipairs(playerlistPanel.Interactions.List:GetDescendants()) do
			if playerIns.Name ~= "Interact" and playerIns.Name ~= "Role" then 
				if playerIns.ClassName == "Frame" then
					tweenService:Create(playerIns, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.2}):Play()
				elseif playerIns.ClassName == "TextLabel" or playerIns.ClassName == "TextButton" then
					if playerIns.Name == "UsernameSub" then
						tweenService:Create(playerIns, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
					else
						tweenService:Create(playerIns, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
					end
				elseif playerIns.ClassName == "ImageLabel" or playerIns.ClassName == "ImageButton" then
					tweenService:Create(playerIns, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
					if playerIns.Name == "Avatar" then tweenService:Create(playerIns, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play() end
				elseif playerIns.ClassName == "UIStroke" then
					tweenService:Create(playerIns, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {Transparency = 1}):Play() -- Hide default outline on entrance
				end
			end
		end

		tweenService:Create(playerlistPanel.Interactions.SearchFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.5}):Play()
		
		local searchCrn = playerlistPanel.Interactions.SearchFrame:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", playerlistPanel.Interactions.SearchFrame)
		searchCrn.CornerRadius = UDim.new(0, 22) -- Pill Shape
		
		tweenService:Create(playerlistPanel.Interactions.SearchFrame.Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0.3}):Play()
		task.wait(0.01)
		tweenService:Create(playerlistPanel.Interactions.SearchFrame.SearchBox, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {TextTransparency = 0.2}):Play()
		
		local sStroke = playerlistPanel.Interactions.SearchFrame:FindFirstChild("UIStroke") or Instance.new("UIStroke", playerlistPanel.Interactions.SearchFrame)
		sStroke.Thickness = 0.8
		sStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		tweenService:Create(sStroke, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {Transparency = 0.8}):Play()
		
		task.wait(0.05)
		tweenService:Create(playerlistPanel.Interactions.List, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {ScrollBarImageTransparency = 0.85}):Play()


	end

	task.wait(0.45)
	debounce = false
end

local function rejoin()
	queueNotification("Rejoining Session", "We're queueing a rejoin to this session, give us a moment.", 4400696294)

	if #players:GetPlayers() <= 1 then
		task.wait()
		teleportService:Teleport(placeId, localPlayer)
	else
		teleportService:TeleportToPlaceInstance(placeId, jobId, localPlayer)
	end
end

local function serverhop()
	local highestPlayers = 0
	local servers = {}

	for _, v in ipairs(httpService:JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100")).data) do
		if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= jobId then
			if v.playing > highestPlayers then
				highestPlayers = v.playing
				servers[1] = v.id
			end
		end
	end

	if #servers > 0 then
		queueNotification("Teleporting", "We're now moving you to the new session, this may take a few seconds.", 4335479121)
		task.wait(0.3)
		teleportService:TeleportToPlaceInstance(placeId, servers[1])
	else
		return queueNotification("No Servers Found", "We couldn't find another server, this may be the only server.", 4370317928)
	end

end

local function ensureFrameProperties()
	UI.Enabled = true
	characterPanel.Visible = false
	customScriptPrompt.Visible = false
	disconnectedPrompt.Visible = false
	playerlistPanel.Interactions.List.Template.Visible = false
	gameDetectionPrompt.Visible = false
	homeContainer.Visible = false
	moderatorDetectionPrompt.Visible = false
	musicPanel.Visible = false
	notificationContainer.Visible = true
	playerlistPanel.Visible = false
	scriptSearch.Visible = false
	scriptsPanel.Visible = false
	settingsPanel.Visible = false
	smartBar.Visible = false
	musicPanel.Playing.Text = "Not Playing"
	if not getcustomasset then smartBar.Buttons.Music.Visible = false end
	toastsContainer.Visible = true
	makeDraggable(settingsPanel)
	makeDraggable(musicPanel)
end

local function checkFriends()
	if friendsCooldown == 0 then
		friendsCooldown = 40 -- Increased cooldown to respect rate limits

		local playersFriends = {}
		local success, page = pcall(players.GetFriendsAsync, players, localPlayer.UserId)

		if success then
			repeat
				local info = page:GetCurrentPage()
				for i, friendInfo in pairs(info) do
					table.insert(playersFriends, friendInfo)
				end
				if not page.IsFinished then 
					page:AdvanceToNextPageAsync()
				end
			until page.IsFinished
		end

		local friendsInTotal = 0
		local onlineFriendsCount = 0 
		local friendsInGameCurrent = 0 
		
		-- Use GetFriendsOnline for Joining logic
		local ok, onlineFriendsData = pcall(function() return localPlayer:GetFriendsOnline(200) end)
		local joinableFriend = nil

		for i,v in pairs(playersFriends) do
			friendsInTotal  = friendsInTotal + 1
			if players:FindFirstChild(v.Username) then
				friendsInGameCurrent = friendsInGameCurrent + 1
			end
		end
		
		if ok and type(onlineFriendsData) == "table" then
			onlineFriendsCount = #onlineFriendsData
			for _, friend in ipairs(onlineFriendsData) do
				-- Roblox uses JobId or GameId depending on context
				local friendJob = friend.JobId or friend.GameId or friend.gameId
				if tostring(friend.PlaceId) == tostring(placeId) and friendJob ~= jobId and friendJob ~= "" then
					friend.JobId = friendJob -- Normalize
					joinableFriend = friend
					break
				end
			end
		end

		if not checkSirius() then return end

		homeContainer.Interactions.Friends.All.Value.Text = tostring(friendsInTotal).." friends"
		homeContainer.Interactions.Friends.Offline.Value.Text = tostring(math.max(0, friendsInTotal - onlineFriendsCount)).." friends"
		homeContainer.Interactions.Friends.Online.Value.Text = tostring(onlineFriendsCount).." friends online"
		
		if joinableFriend then
			homeContainer.Interactions.Friends.InGame.Value.Text = "JOIN: " .. (joinableFriend.UserName or joinableFriend.Username)
			homeContainer.Interactions.Friends.InGame.Value.TextColor3 = Color3.fromRGB(0, 255, 140) -- Neon Emerald
			pcall(function()
				homeContainer.Interactions.Friends.InGame.BackgroundColor3 = Color3.fromRGB(0, 124, 89)
				homeContainer.Interactions.Friends.InGame.BackgroundTransparency = 0.2
			end)
			getgenv()._siriusJoinableFriend = joinableFriend
		else
			homeContainer.Interactions.Friends.InGame.Value.Text = tostring(friendsInGameCurrent).." in this server"
			homeContainer.Interactions.Friends.InGame.Value.TextColor3 = Color3.fromRGB(255, 255, 255)
			pcall(function()
				homeContainer.Interactions.Friends.InGame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
				homeContainer.Interactions.Friends.InGame.BackgroundTransparency = 0
			end)
			getgenv()._siriusJoinableFriend = nil
		end

	else
		friendsCooldown -= 1
	end
end

function promptModerator(player, role)
	local serversAvailable = false
	local promptClosed = false

	if moderatorDetectionPrompt.Visible then return end

	moderatorDetectionPrompt.Size = UDim2.new(0, 283, 0, 175)
	moderatorDetectionPrompt.UIGradient.Offset = Vector2.new(0, 1)
	wipeTransparency(moderatorDetectionPrompt, 1, true)

	moderatorDetectionPrompt.DisplayName.Text = player.DisplayName
	moderatorDetectionPrompt.Rank.Text = role
	moderatorDetectionPrompt.Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=420&height=420&format=png"

	moderatorDetectionPrompt.Visible = true

	for _, v in ipairs(game:GetService("HttpService"):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data) do
		if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= game.JobId then
			serversAvailable = true
		end
	end

	if not serversAvailable then
		moderatorDetectionPrompt.Serverhop.Visible = false
	else
		moderatorDetectionPrompt.ServersAvailableFade.Visible = true
	end

	tweenService:Create(moderatorDetectionPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
	tweenService:Create(moderatorDetectionPrompt, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 300, 0, 186)}):Play()
	tweenService:Create(moderatorDetectionPrompt.UIGradient, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Offset = Vector2.new(0, 0.65)}):Play()
	tweenService:Create(moderatorDetectionPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	tweenService:Create(moderatorDetectionPrompt.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	tweenService:Create(moderatorDetectionPrompt.Avatar, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.7}):Play()
	tweenService:Create(moderatorDetectionPrompt.Avatar, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
	tweenService:Create(moderatorDetectionPrompt.DisplayName, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	tweenService:Create(moderatorDetectionPrompt.Rank, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	tweenService:Create(moderatorDetectionPrompt.Serverhop, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.7}):Play()
	tweenService:Create(moderatorDetectionPrompt.Leave, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.7}):Play()
	task.wait(0.2)
	tweenService:Create(moderatorDetectionPrompt.Serverhop, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	tweenService:Create(moderatorDetectionPrompt.Leave, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	task.wait(0.3)
	tweenService:Create(moderatorDetectionPrompt.Close, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 0.6}):Play()

	local function closeModPrompt()
		tweenService:Create(moderatorDetectionPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 283, 0, 175)}):Play()
		tweenService:Create(moderatorDetectionPrompt.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Offset = Vector2.new(0, 1)}):Play()
		tweenService:Create(moderatorDetectionPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt.Avatar, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt.Avatar, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt.DisplayName, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt.Rank, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt.Serverhop, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt.Leave, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt.Serverhop, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt.Leave, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
		tweenService:Create(moderatorDetectionPrompt.Close, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		task.wait(0.5)
		moderatorDetectionPrompt.Visible = false
	end

	moderatorDetectionPrompt.Leave.MouseButton1Click:Connect(function()
		closeModPrompt()
		game:Shutdown()
	end)

	moderatorDetectionPrompt.Serverhop.MouseEnter:Connect(function()
		tweenService:Create(moderatorDetectionPrompt.ServersAvailableFade, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
	end)

	moderatorDetectionPrompt.Serverhop.MouseLeave:Connect(function()
		tweenService:Create(moderatorDetectionPrompt.ServersAvailableFade, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
	end)

	moderatorDetectionPrompt.Serverhop.MouseButton1Click:Connect(function()
		if promptClosed then return end
		serverhop()
		closeModPrompt()
	end)

	moderatorDetectionPrompt.Close.MouseButton1Click:Connect(function()
		closeModPrompt()
		promptClosed = true
	end)
end

local function UpdateHome()
	if not checkSirius() then return end

	local function format(Int)
		return string.format("%02i", Int)
	end

	local function convertToHMS(Seconds)
		local Minutes = (Seconds - Seconds%60)/60
		Seconds = Seconds - Minutes*60
		local Hours = (Minutes - Minutes%60)/60
		Minutes = Minutes - Hours*60
		return format(Hours)..":"..format(Minutes)..":"..format(Seconds)
	end

	-- Home Title
	homeContainer.Title.Text = "Welcome home, "..localPlayer.DisplayName

	-- Players
	homeContainer.Interactions.Server.Players.Value.Text = #players:GetPlayers().." playing"
	homeContainer.Interactions.Server.MaxPlayers.Value.Text = players.MaxPlayers.." players can join this server"

	-- Ping
	homeContainer.Interactions.Server.Latency.Value.Text = math.floor(getPing()).."ms"

	-- Region (Fetch Once)
	if not getgenv()._siriusFetchedRegion then
		getgenv()._siriusFetchedRegion = "Fetching..."
		homeContainer.Interactions.Server.Region.Value.Text = "Fetching..."
		task.spawn(function()
			local success, result = pcall(function()
				local url = "http://ip-api.com/json/"
				if httpRequest then
					local response = httpRequest({
						Url = url,
						Method = "GET"
					})
					return httpService:JSONDecode(response.Body)
				else
					local res = game:HttpGet(url)
					return httpService:JSONDecode(res)
				end
			end)
			
			if success and result and result.country then
				getgenv()._siriusFetchedRegion = (result.city or "Unknown City") .. ", " .. result.country
			else
				getgenv()._siriusFetchedRegion = "Unknown Region"
			end
			
			if checkSirius() then
				homeContainer.Interactions.Server.Region.Value.Text = getgenv()._siriusFetchedRegion
			end
		end)
	else
		homeContainer.Interactions.Server.Region.Value.Text = getgenv()._siriusFetchedRegion
	end

	-- Player Information
	local isDev = table.find(siriusValues.devs, localPlayer.Name:lower())
	homeContainer.Interactions.User.Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..localPlayer.UserId.."&width=420&height=420&format=png"
	homeContainer.Interactions.User.Title.RichText = true
	homeContainer.Interactions.User.Title.Text = localPlayer.DisplayName .. (isDev and " <font color='#00ff00'>[Dev]</font>" or "")
	homeContainer.Interactions.User.Subtitle.Text = "@" .. localPlayer.Name -- Show username here as requestede too
	
	-- Update Executor
	homeContainer.Interactions.Client.Title.Text = identifyexecutor()
	if not table.find(siriusValues.executors, string.lower(identifyexecutor())) then
		homeContainer.Interactions.Client.Subtitle.Text = "This executor is not verified as supported - but may still work just fine."
	end

	-- Update Friends Statuses
	checkFriends()
end

local function openHome()
	if debounce then return end
	debounce = true
	homeContainer.Visible = true
	createFloatingParticles(homeContainer)

	local homeBlur = Instance.new("BlurEffect", lighting)
	homeBlur.Size = 0
	homeBlur.Name = "HomeBlur"

	homeContainer.BackgroundTransparency = 1
	homeContainer.Title.TextTransparency = 1
	homeContainer.Subtitle.TextTransparency = 1

	for _, homeItem in ipairs(homeContainer.Interactions:GetChildren()) do

		wipeTransparency(homeItem, 1, true)

		homeItem.Position = UDim2.new(0, homeItem.Position.X.Offset - 20, 0, homeItem.Position.Y.Offset - 20)
		homeItem.Size = UDim2.new(0, homeItem.Size.X.Offset + 30, 0, homeItem.Size.Y.Offset + 20)

		if homeItem.UIGradient.Offset.Y > 0 then
			homeItem.UIGradient.Offset = Vector2.new(0, homeItem.UIGradient.Offset.Y + 3)
			homeItem.UIStroke.UIGradient.Offset = Vector2.new(0, homeItem.UIStroke.UIGradient.Offset.Y + 3)
		else
			homeItem.UIGradient.Offset = Vector2.new(0, homeItem.UIGradient.Offset.Y - 3)
			homeItem.UIStroke.UIGradient.Offset = Vector2.new(0, homeItem.UIStroke.UIGradient.Offset.Y - 3)
		end
		
		local homeCrn = homeItem:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", homeItem)
		homeCrn.CornerRadius = UDim.new(0, 38) -- Extra Rounded for Home Items
		
		local homeStroke = homeItem:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke", homeItem)
		homeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		homeStroke.Thickness = 1
		homeStroke.Color = Color3.fromRGB(80, 80, 90)
		homeStroke.Transparency = 1 -- Hide initially for animation
		
		if homeItem.Parent:IsA("ScrollingFrame") or homeItem.Parent:IsA("Frame") then
			homeItem.Parent.ClipsDescendants = false -- Prevent Outline Clipping
		end

	end

	tweenService:Create(homeContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.9}):Play()
	tweenService:Create(homeBlur, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = 5}):Play()

	tweenService:Create(camera, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {FieldOfView = camera.FieldOfView + 5}):Play()

	task.wait(0.25)

	for _, inGameUI in ipairs(localPlayer:FindFirstChildWhichIsA("PlayerGui"):GetChildren()) do
		if inGameUI:IsA("ScreenGui") then
			if inGameUI.Enabled then
				if not table.find(getgenv().cachedInGameUI, inGameUI.Name) then
					table.insert(getgenv().cachedInGameUI, #getgenv().cachedInGameUI+1, inGameUI.Name)
				end

				inGameUI.Enabled = false
			end
		end
	end

	table.clear(getgenv().cachedCoreUI)

	for _, coreUI in pairs({"PlayerList", "Chat", "EmotesMenu", "Health", "Backpack"}) do
		if game:GetService("StarterGui"):GetCoreGuiEnabled(coreUI) then
			table.insert(getgenv().cachedCoreUI, #getgenv().cachedCoreUI+1, coreUI)
		end
	end

	for _, coreUI in pairs(getgenv().cachedCoreUI) do
		game:GetService("StarterGui"):SetCoreGuiEnabled(coreUI, false)
	end

	createReverb(0.8)

	tweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {FieldOfView = camera.FieldOfView - 40}):Play()

	tweenService:Create(homeContainer, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.3}):Play()
	tweenService:Create(homeContainer.Title, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	tweenService:Create(homeContainer.Subtitle, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
	tweenService:Create(homeBlur, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Size = 20}):Play()

	for _, homeItem in ipairs(homeContainer.Interactions:GetChildren()) do
		for _, otherHomeItem in ipairs(homeItem:GetDescendants()) do
			if otherHomeItem.ClassName == "Frame" then
				tweenService:Create(otherHomeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.5}):Play()
			elseif otherHomeItem.ClassName == "TextLabel" then
				if otherHomeItem.Name == "Title" then
					tweenService:Create(otherHomeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
				else
					tweenService:Create(otherHomeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0.3}):Play()
				end
			elseif otherHomeItem.ClassName == "ImageLabel" then
				tweenService:Create(otherHomeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.8}):Play()
				tweenService:Create(otherHomeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
			end
		end

		homeItem.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
		if homeItem:FindFirstChild("UIGradient") then homeItem.UIGradient.Enabled = false end

		tweenService:Create(homeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
		tweenService:Create(homeItem.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Transparency = 0}):Play()
		tweenService:Create(homeItem, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0, homeItem.Position.X.Offset + 20, 0, homeItem.Position.Y.Offset + 20)}):Play()
		tweenService:Create(homeItem, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.new(0, homeItem.Size.X.Offset - 30, 0, homeItem.Size.Y.Offset - 20)}):Play()

		task.delay(0.03, function()
			if homeItem.UIGradient.Offset.Y > 0 then
				tweenService:Create(homeItem.UIGradient, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Offset = Vector2.new(0, homeItem.UIGradient.Offset.Y - 3)}):Play()
				tweenService:Create(homeItem.UIStroke.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Offset = Vector2.new(0, homeItem.UIStroke.UIGradient.Offset.Y - 3)}):Play()
			else
				tweenService:Create(homeItem.UIGradient, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Offset = Vector2.new(0, homeItem.UIGradient.Offset.Y + 3)}):Play()
				tweenService:Create(homeItem.UIStroke.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Offset = Vector2.new(0, homeItem.UIStroke.UIGradient.Offset.Y + 3)}):Play()
			end
		end)

		task.wait(0.02)
	end

	task.wait(0.85)

	debounce = false
end

local function closeHome()
	if debounce then return end
	debounce = true

	destroyFloatingParticles(homeContainer)

	tweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {FieldOfView = camera.FieldOfView + 35}):Play()

	for _, obj in ipairs(lighting:GetChildren()) do
		if obj.Name == "HomeBlur" then
			tweenService:Create(obj, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Size = 0}):Play()
			task.delay(0.6, obj.Destroy, obj)
		end
	end

	tweenService:Create(homeContainer, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
	tweenService:Create(homeContainer.Title, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
	tweenService:Create(homeContainer.Subtitle, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()

	for _, homeItem in ipairs(homeContainer.Interactions:GetChildren()) do
		for _, otherHomeItem in ipairs(homeItem:GetDescendants()) do
			if otherHomeItem.ClassName == "Frame" then
				tweenService:Create(otherHomeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
			elseif otherHomeItem.ClassName == "TextLabel" then
				if otherHomeItem.Name == "Title" then
					tweenService:Create(otherHomeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
				else
					tweenService:Create(otherHomeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
				end
			elseif otherHomeItem.ClassName == "ImageLabel" then
				tweenService:Create(otherHomeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
				tweenService:Create(otherHomeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
			end
		end
		tweenService:Create(homeItem, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
		tweenService:Create(homeItem.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
	end

	task.wait(0.2)

	for _, cachedInGameUIObject in pairs(getgenv().cachedInGameUI) do
		for _, currentPlayerUI in ipairs(localPlayer:FindFirstChildWhichIsA("PlayerGui"):GetChildren()) do
			if table.find(getgenv().cachedInGameUI, currentPlayerUI.Name) then
				currentPlayerUI.Enabled = true
			end 
		end
	end

	for _, coreUI in pairs(getgenv().cachedCoreUI) do
		game:GetService("StarterGui"):SetCoreGuiEnabled(coreUI, true)
	end

	removeReverbs(0.5)

	task.wait(0.52)

	homeContainer.Visible = false
	debounce = false
end


local function openScriptSearch()
	debounce = true

	scriptSearch.Size = UDim2.new(0, 480, 0, 23)
	scriptSearch.Position = UDim2.new(0.5, 0, 0.5, 0)
	scriptSearch.SearchBox.Position = UDim2.new(0.509, 0, 0.5, 0)
	scriptSearch.Icon.Position = UDim2.new(0.04, 0, 0.5, 0)
	scriptSearch.SearchBox.Text = ""
	scriptSearch.SearchBox.TextEditable = true
	scriptSearch.UIGradient.Offset = Vector2.new(0, 2)
	scriptSearch.SearchBox.PlaceholderText = "Search ScriptBlox.com"
	scriptSearch.List.Template.Visible = false
	scriptSearch.List.Visible = false
	scriptSearch.Visible = true

	wipeTransparency(scriptSearch, 1, true)

	tweenService:Create(scriptSearch, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0}):Play()
	tweenService:Create(scriptSearch, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Size = UDim2.new(0, 580, 0, 43)}):Play()
	tweenService:Create(scriptSearch.Shadow, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {ImageTransparency = 0.85}):Play()
	task.wait(0.03)
	tweenService:Create(scriptSearch.Icon, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {ImageTransparency = 0}):Play()
	task.wait(0.02)
	tweenService:Create(scriptSearch.SearchBox, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
	
	local boxCrn = scriptSearch.SearchBox:FindFirstChildWhichIsA("UICorner")
	if boxCrn then boxCrn.CornerRadius = UDim.new(0, 12) end


	task.wait(0.3)
	scriptSearch.SearchBox:CaptureFocus()
	task.wait(0.2)
	debounce = false
end

local function closeScriptSearch()
	debounce = true

	wipeTransparency(scriptSearch, 1, false)

	task.wait(0.1)

	scriptSearch.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	scriptSearch.UIGradient.Enabled = false
	tweenService:Create(scriptSearch, TweenInfo.new(0.4, Enum.EasingStyle.Quint),  {Size = UDim2.new(0, 520, 0, 0)}):Play()
	scriptSearch.SearchBox:ReleaseFocus()

	task.wait(0.5)

	for _, createdScript in ipairs(scriptSearch.List:GetChildren()) do
		if createdScript.Name ~= "Placeholder" and createdScript.Name ~= "Template" and createdScript.ClassName == "Frame" then
			createdScript:Destroy()
		end
	end

	task.wait(0.1)
	scriptSearch.BackgroundColor3 = Color3.fromRGB(255 ,255, 255)
	scriptSearch.Visible = false
	scriptSearch.UIGradient.Enabled = true
	debounce = false
end

local function createScript(result)
	local newScript = UI.ScriptSearch.List.Template:Clone()
	newScript.Name = result.title
	newScript.Parent = UI.ScriptSearch.List
	newScript.Visible = true

	for _, tag in ipairs(newScript.Tags:GetChildren()) do
		if tag.ClassName == "Frame" then
			tag.Shadow.ImageTransparency = 1
			tag.BackgroundTransparency = 1
			tag.Title.TextTransparency = 1
		end
	end

	task.spawn(function()
		local response

		local success, ErrorStatement = pcall(function()
			local responseRequest = httpRequest({
				Url = "https://www.scriptblox.com/api/script/"..result['slug'],
				Method = "GET"
			})

			response = httpService:JSONDecode(responseRequest.Body)
		end)

		if not newScript or not newScript.Parent then return end

		if not success or not response or not response.script then
			-- Still show the script entry even without details
			tweenService:Create(newScript, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {BackgroundTransparency = 0.8}):Play()
			tweenService:Create(newScript.ScriptName, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
			tweenService:Create(newScript.Execute, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {BackgroundTransparency = 0.8}):Play()
			tweenService:Create(newScript.Execute, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
			return
		end

		local descLabel = newScript:FindFirstChild("ScriptDescription")
		if descLabel then
			if type(response.script.features) == "string" then
				descLabel.Text = response.script.features
			elseif type(response.script.features) == "table" then
				descLabel.Text = table.concat(response.script.features, ", ")
			else
				descLabel.Text = ""
			end
		end

		local likes = response.script.likeCount or 0
		local dislikes = response.script.dislikeCount or 0

		if likes ~= dislikes then
			newScript.Tags.Review.Title.Text = (likes > dislikes) and "Positive Reviews" or "Negative Reviews"
			newScript.Tags.Review.BackgroundColor3 = (likes > dislikes) and Color3.fromRGB(0, 139, 102) or Color3.fromRGB(180, 0, 0)
			newScript.Tags.Review.Size = (likes > dislikes) and UDim2.new(0, 145, 1, 0) or UDim2.new(0, 150, 1, 0)
		elseif likes > 0 then
			newScript.Tags.Review.Title.Text = "Mixed Reviews"
			newScript.Tags.Review.BackgroundColor3 = Color3.fromRGB(198, 132, 0)
			newScript.Tags.Review.Size = UDim2.new(0, 130, 1, 0)
		else
			newScript.Tags.Review.Visible = false
		end
		
		local isKeyless = false
		if type(response.script.features) == "table" then
			for _, f in ipairs(response.script.features) do
				if type(f) == "string" and (f:lower():match("keyless") or f:lower():match("no key")) then
					isKeyless = true
				end
			end
		elseif type(response.script.features) == "string" then
			local fl = response.script.features:lower()
			if fl:match("keyless") or fl:match("no key") then
				isKeyless = true
			end
		end
		
		if isKeyless and newScript.Tags:FindFirstChild("Review") then
			local keylessTag = newScript.Tags.Review:Clone()
			keylessTag.Name = "Keyless"
			keylessTag.Title.Text = "Keyless"
			keylessTag.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			keylessTag.Size = UDim2.new(0, 90, 1, 0)
			keylessTag.Parent = newScript.Tags
			keylessTag.Visible = true
		end

		local authorLabel = newScript:FindFirstChild("ScriptAuthor")
		if authorLabel and response.script.owner then
			authorLabel.Text = "uploaded by "..response.script.owner.username
		end
		if newScript.Tags:FindFirstChild("Verified") and response.script.owner then
			newScript.Tags.Verified.Visible = response.script.owner.verified or false
		end

		tweenService:Create(newScript, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {BackgroundTransparency = 0.8}):Play()
		tweenService:Create(newScript.ScriptName, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
		tweenService:Create(newScript.Execute, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {BackgroundTransparency = 0.8}):Play()
		tweenService:Create(newScript.Execute, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()

		newScript.Tags.Visible = true

		if descLabel then
			tweenService:Create(descLabel, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0.3}):Play()
		end
		if authorLabel then
			tweenService:Create(authorLabel, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {TextTransparency = 0.7}):Play()
		end

		for _, tag in ipairs(newScript.Tags:GetChildren()) do
			if tag.ClassName == "Frame" then
				pcall(function()
					tweenService:Create(tag.Shadow, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {ImageTransparency = 0.7}):Play()
					tweenService:Create(tag, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {BackgroundTransparency = 0}):Play()
					tweenService:Create(tag.Title, TweenInfo.new(.5, Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
				end)
			end
		end
	end)

	wipeTransparency(newScript, 1, true)

	newScript.ScriptName.Text = result.title


	newScript.Tags.Visible = false
	newScript.Tags.Patched.Visible = result.isPatched or false

	newScript.Execute.MouseButton1Click:Connect(function()
		queueNotification("ScriptSearch", "Running "..result.title.. " via ScriptSearch" , 4384403532)
		closeScriptSearch()
		loadstring(result.script)()
	end)
end

local function extractDomain(link)
	local domainToReturn = link:match("([%w-_]+%.[%w-_%.]+)")
	return domainToReturn
end

local function securityDetection(title, content, link, gradient, actions)
	if not checkSirius() then return end

	local domain = extractDomain(link) or link
	checkFolder()
	local currentAllowlist = isfile and isfile(siriusValues.siriusFolder.."/".."allowedLinks.srs") and readfile(siriusValues.siriusFolder.."/".."allowedLinks.srs") or nil
	if currentAllowlist then currentAllowlist = httpService:JSONDecode(currentAllowlist) if table.find(currentAllowlist, domain) then return true end end

	local newSecurityPrompt = securityPrompt:Clone()

	newSecurityPrompt.Parent = UI
	newSecurityPrompt.Name = link

	wipeTransparency(newSecurityPrompt, 1, true)
	newSecurityPrompt.Size = UDim2.new(0, 478, 0, 150)

	newSecurityPrompt.Title.Text = title
	newSecurityPrompt.Subtitle.Text = content
	newSecurityPrompt.FoundLink.Text = domain

	newSecurityPrompt.Visible = true
	newSecurityPrompt.UIGradient.Color = gradient

	newSecurityPrompt.Buttons.Template.Visible = false

	local function closeSecurityPrompt()
		tweenService:Create(newSecurityPrompt, TweenInfo.new(0.52, Enum.EasingStyle.Quint),  {Size = UDim2.new(0, 500, 0, 165)}):Play()
		tweenService:Create(newSecurityPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {BackgroundTransparency = 1}):Play()
		tweenService:Create(newSecurityPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()
		tweenService:Create(newSecurityPrompt.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()
		tweenService:Create(newSecurityPrompt.FoundLink, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()


		for _, button in ipairs(newSecurityPrompt.Buttons:GetChildren()) do
			if button.Name ~= "Template" and button.ClassName == "TextButton" then
				tweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quint),  {BackgroundTransparency = 1}):Play()
				tweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()
			end
		end
		task.wait(0.55)
		newSecurityPrompt:Destroy()
	end

	local decision

	for _, action in ipairs(actions) do
		local newAction = newSecurityPrompt.Buttons.Template:Clone()
		newAction.Name = action[1]
		newAction.Text = action[1]
		newAction.Parent = newSecurityPrompt.Buttons
		newAction.Visible = true
		newAction.Size = UDim2.new(0, newAction.TextBounds.X + 50, 0, 36) -- textbounds
		
		local crn = newAction:FindFirstChildWhichIsA("UICorner")
		if crn then crn.CornerRadius = UDim.new(0, 12) end

		newAction.MouseButton1Click:Connect(function()
			if action[2] then
				if action[3] then
					checkFolder()
					if currentAllowlist then
						table.insert(currentAllowlist, domain)
						writefile(siriusValues.siriusFolder.."/".."allowedLinks.srs", httpService:JSONEncode(currentAllowlist))
					else
						writefile(siriusValues.siriusFolder.."/".."allowedLinks.srs", httpService:JSONEncode({domain}))
					end
				end
				decision = true
			else
				decision = false
			end

			closeSecurityPrompt()
		end)
	end

	tweenService:Create(newSecurityPrompt, TweenInfo.new(0.4, Enum.EasingStyle.Quint),  {Size = UDim2.new(0, 576, 0, 181)}):Play()
	tweenService:Create(newSecurityPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {BackgroundTransparency = 0}):Play()
	tweenService:Create(newSecurityPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
	tweenService:Create(newSecurityPrompt.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {TextTransparency = 0.3}):Play()
	task.wait(0.03)
	tweenService:Create(newSecurityPrompt.FoundLink, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {TextTransparency = 0.2}):Play()

	task.wait(0.1)

	for _, button in ipairs(newSecurityPrompt.Buttons:GetChildren()) do
		if button.Name ~= "Template" and button.ClassName == "TextButton" then
			tweenService:Create(button, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {BackgroundTransparency = 0.7}):Play()
			tweenService:Create(button, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {TextTransparency = 0.05}):Play()
			task.wait(0.1)
		end
	end

	newSecurityPrompt.FoundLink.MouseEnter:Connect(function()
		newSecurityPrompt.FoundLink.Text = link
		tweenService:Create(newSecurityPrompt.FoundLink, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {TextTransparency = 0.4}):Play()
	end)

	newSecurityPrompt.FoundLink.MouseLeave:Connect(function()
		newSecurityPrompt.FoundLink.Text = domain
		tweenService:Create(newSecurityPrompt.FoundLink, TweenInfo.new(0.5, Enum.EasingStyle.Quint),  {TextTransparency = 0.2}):Play()
	end)

	repeat task.wait() until decision
	return decision
end

if Essential or Pro then
	getgenv()[index] = function(data)
		if checkSirius() and checkSetting("Intelligent HTTP Interception").current then
			local title = "Do you trust this source?"
			local content = "Sirius has prevented data from being sent off-client, would you like to allow data to be sent or retrieved from this source?"
			local url = data.Url or "Unknown Link"
			local gradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),ColorSequenceKeypoint.new(1, Color3.new(0.764706, 0.305882, 0.0941176))})
			local actions = {{"Always Allow", true, true}, {"Allow just this once", true}, {"Don't Allow", false}}

			if url == "http://127.0.0.1:6463/rpc?v=1" then
				local bodyDecoded = httpService:JSONDecode(data.Body)

				if bodyDecoded.cmd == "INVITE_BROWSER" then
					title = "Would you like to join this Discord server?"
					content = "Sirius has prevented your Discord client from automatically joining this Discord server, would you like to continue and join, or block it?"
					url = bodyDecoded.args and "discord.gg/"..bodyDecoded.args.code or "Unknown Invite"
					gradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),ColorSequenceKeypoint.new(1, Color3.new(0.345098, 0.396078, 0.94902))})
					actions = {{"Allow", true}, {"Don't Allow", false}}
				end
			elseif url:lower():find("webhook") and (url:lower():find("discord.com") or url:lower():find("discordapp.com")) then
				title = "🚨 Dangerous Webhook Detected!"
				content = "Sirius has detected a Discord Webhook request. This is frequently used by scripts to steal private data or log your actions. Are you sure you want to allow this?"
				gradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 0, 0))})
				actions = {{"Block Request", false}, {"Allow (UNSAFE)", true}}
			end

			local answer = securityDetection(title, content, url, gradient, actions)


			if answer then 
				return originalRequest(data)
			else
				return
			end
		else
			return originalRequest(data)
		end
	end

	getgenv()[indexSetClipboard] = function(data)
		if checkSirius() and checkSetting("Intelligent Clipboard Interception").current then
			local title = "Would you like to copy this to your clipboard?"
			local content = "Sirius has prevented a script from setting the below text to your clipboard, would you like to allow this, or prevent it from copying?"
			local url = data or "Unknown Clipboard"
			local gradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),ColorSequenceKeypoint.new(1, Color3.new(0.776471, 0.611765, 0.529412))})
			local actions = {{"Allow", true}, {"Don't Allow", false}}

			if tostring(data):lower():find("webhook") and (tostring(data):lower():find("discord.com") or tostring(data):lower():find("discordapp.com")) then
				title = "🚨 Webhook Link in Clipboard!"
				content = "Sirius detected a Discord Webhook URL being sent to your clipboard. This is often part of a malicious data-logging sequence. Block it?"
				gradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50))})
				actions = {{"Block Clipboard", false}, {"Allow Copy", true}}
			end

			local answer = securityDetection(title, content, url, gradient, actions)

			if answer then 
				return originalSetClipboard(data)
			else
				return
			end
		else
			return originalSetClipboard(data)
		end
	end
end


local function searchScriptBlox(query)
	local response

	local success, ErrorStatement = pcall(function()
		local responseRequest = httpRequest({
			Url = "https://scriptblox.com/api/script/search?q="..httpService:UrlEncode(query).."&mode=free&max=20&page=1",
			Method = "GET"
		})

		response = httpService:JSONDecode(responseRequest.Body)
	end)

	if not success then
		queueNotification("ScriptSearch", "ScriptSearch backend encountered an error, try again later", 4384402990)
		closeScriptSearch()
		return
	end

	tweenService:Create(scriptSearch.NoScriptsTitle, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()
	tweenService:Create(scriptSearch.NoScriptsDesc, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 1}):Play()

	for _, createdScript in ipairs(scriptSearch.List:GetChildren()) do
		if createdScript.Name ~= "Placeholder" and createdScript.Name ~= "Template" and createdScript.ClassName == "Frame" then
			wipeTransparency(createdScript, 1, true)
		end
	end

	scriptSearch.List.Visible = true
	task.wait(0.5)

	scriptSearch.List.CanvasPosition = Vector2.new(0,0)

	for _, createdScript in ipairs(scriptSearch.List:GetChildren()) do
		if createdScript.Name ~= "Placeholder" and createdScript.Name ~= "Template" and createdScript.ClassName == "Frame" then
			createdScript:Destroy()
		end
	end

	tweenService:Create(scriptSearch, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Size = UDim2.new(0, 580, 0, 529)}):Play()
	tweenService:Create(scriptSearch.Icon, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Position = UDim2.new(0.054, 0, 0.056, 0)}):Play()
	tweenService:Create(scriptSearch.SearchBox, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Position = UDim2.new(0.523, 0, 0.056, 0)}):Play()
	tweenService:Create(scriptSearch.UIGradient, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Offset = Vector2.new(0, 0.6)}):Play()

	if response then
		local scriptCreated = false
		for _, scriptResult in pairs(response.result.scripts) do
			-- Safety Filter: Skip scripts younger than 4 days
			if scriptResult.createdAt then
				local s, dt = pcall(function() return DateTime.fromIsoDate(scriptResult.createdAt) end)
				if s and dt and (os.time() - dt.UnixTimestamp) < (4 * 24 * 60 * 60) then
					continue
				end
			end

			local success, response = pcall(function()
				createScript(scriptResult)
			end)

			scriptCreated = true
		end

		if not scriptCreated then
			task.wait(0.2)
			tweenService:Create(scriptSearch.NoScriptsTitle, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
			task.wait(0.1)
			tweenService:Create(scriptSearch.NoScriptsDesc, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
		else
			tweenService:Create(scriptSearch.List, TweenInfo.new(.3,Enum.EasingStyle.Quint),  {ScrollBarImageTransparency = 0}):Play()
		end
	else
		queueNotification("ScriptSearch", "ScriptSearch backend encountered an error, try again later", 4384402990)
		closeScriptSearch()
		return
	end
end

local function openSmartBar()
	smartBarOpen = true

	coreGui.RobloxGui.Backpack.Position = UDim2.new(0,0,0,0)

	-- Set Values for frame properties
	smartBar.BackgroundTransparency = 1
	smartBar.Time.TextTransparency = 1
	smartBar.UIStroke.Transparency = 1
	smartBar.Shadow.ImageTransparency = 1
	smartBar.Visible = true
	smartBar.Position = UDim2.new(0.5, 0, 1.25, 0)
	smartBar.Size = UDim2.new(0, 531, 0, 64)
	toggle.Rotation = 180
	toggle.Visible = not checkSetting("Hide Toggle Button").current

	if checkTools() then
		toggle.Position = UDim2.new(0.5,0,1,-68)
	else
		toggle.Position = UDim2.new(0.5, 0, 1, -5)
	end


	smartBar.Buttons.ClipsDescendants = false -- Prevent Outline Clipping
	for _, button in ipairs(smartBar.Buttons:GetChildren()) do
		if button.Name == "StarryBackground" then continue end
		button.UIGradient.Rotation = -120
		button.UIStroke.UIGradient.Rotation = -120
		button.Size = UDim2.new(0,30,0,30)
		button.Position = UDim2.new(button.Position.X.Scale, 0, 1.3, 0)
		button.BackgroundTransparency = 1
		button.UIStroke.Transparency = 1
		button.UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Fix clipping
		button.Icon.ImageTransparency = 1
		if button:FindFirstChildWhichIsA("UICorner") then
			button:FindFirstChildWhichIsA("UICorner").CornerRadius = UDim.new(1, 0) -- Pill
		end
	end


	tweenService:Create(coreGui.RobloxGui.Backpack, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Position = UDim2.new(-0.325,0,0,0)}):Play()

	smartBar.UIStroke.Transparency = 1
	tweenService:Create(toggle, TweenInfo.new(0.82, Enum.EasingStyle.Quint), {Rotation = 0}):Play()
	tweenService:Create(smartBar, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 0, 1, -12)}):Play()
	tweenService:Create(toastsContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 0, 1, -110)}):Play()
	tweenService:Create(toggle, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 0, 1, -85)}):Play()
	tweenService:Create(smartBar, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Size = UDim2.new(0,581,0,70)}):Play()
	tweenService:Create(smartBar, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
	tweenService:Create(smartBar.Shadow, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {ImageTransparency = 0.7}):Play()
	tweenService:Create(toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()

	task.spawn(function()
		tweenService:Create(smartBar.Time, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
		tweenService:Create(smartBar.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.95}):Play()
		
		-- Ambient glow behind SmartBar
		local ambientGlow = smartBar:FindFirstChild("SiriusAmbientGlow")
		if not ambientGlow then
			ambientGlow = Instance.new("ImageLabel")
			ambientGlow.Name = "SiriusAmbientGlow"
			ambientGlow.Image = "rbxassetid://6073489140"
			ambientGlow.BackgroundTransparency = 1
			ambientGlow.ImageTransparency = 1
			ambientGlow.Size = UDim2.new(1.8, 0, 4, 0)
			ambientGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
			ambientGlow.AnchorPoint = Vector2.new(0.5, 0.5)
			ambientGlow.ImageColor3 = Color3.fromRGB(40, 80, 200)
			ambientGlow.ZIndex = -1
			ambientGlow.Parent = smartBar
		end
		tweenService:Create(ambientGlow, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {ImageTransparency = 0.82}):Play()

		for _, button in ipairs(smartBar.Buttons:GetChildren()) do
			if button.Name == "StarryBackground" then continue end
			tweenService:Create(button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0}):Play()
			tweenService:Create(button.Icon, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {ImageTransparency = 0.2}):Play()
			tweenService:Create(button, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 36, 0, 36)}):Play()
			tweenService:Create(button.UIGradient, TweenInfo.new(1, Enum.EasingStyle.Quint), {Rotation = 50}):Play()
			tweenService:Create(button.UIStroke.UIGradient, TweenInfo.new(1, Enum.EasingStyle.Quint), {Rotation = 50}):Play()
			tweenService:Create(button, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {Position = UDim2.new(button.Position.X.Scale, 0, 0.5, 0)}):Play()
			tweenService:Create(button, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
			tweenService:Create(button.Icon, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
			task.wait(0.03)
		end
	end)
end

-- SIRIUS: Modern Chat Tagging Support
task.spawn(function()
	local success, tcs = pcall(function() return game:GetService("TextChatService") end)
	if success and tcs then
		tcs.OnIncomingMessage = function(message)
			if message.TextSource then
				local player = players:GetPlayerByUserId(message.TextSource.UserId)
				if player and table.find(siriusValues.devs, player.Name:lower()) then
					local props = Instance.new("TextChatMessageProperties")
					props.PrefixText = "<font color='#00ff00'>[DEV]</font> " .. message.PrefixText
					return props
				end
			end
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════════

-- Ambient glow breathing, dynamic gradient cycling, floating particles
-- ═══════════════════════════════════════════════════════════════════════

-- SmartBar Ambient Glow Breathing Loop
task.spawn(function()
	local breatheColors = {
		Color3.fromRGB(40, 80, 200),   -- Deep Blue
		Color3.fromRGB(100, 50, 220),  -- Purple
		Color3.fromRGB(50, 180, 200),  -- Cyan
		Color3.fromRGB(80, 60, 255),   -- Electric Blue
		Color3.fromRGB(40, 80, 200),   -- Back to Deep Blue
	}
	local colorIndex = 1

	while task.wait(4) do
		if not checkSirius() then break end
		local ambientGlow = smartBar:FindFirstChild("SiriusAmbientGlow")
		if ambientGlow and smartBarOpen then
			-- Breathe intensity
			tweenService:Create(ambientGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.75}):Play()
			
			-- Cycle color
			colorIndex = (colorIndex % #breatheColors) + 1
			tweenService:Create(ambientGlow, TweenInfo.new(3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageColor3 = breatheColors[colorIndex]}):Play()
			
			task.wait(2)
			if ambientGlow and ambientGlow.Parent then
				tweenService:Create(ambientGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.88}):Play()
			end
		end
	end
end)

local function closeSmartBar()
	smartBarOpen = false

	-- Fade out ambient glow
	local ambientGlow = smartBar:FindFirstChild("SiriusAmbientGlow")
	if ambientGlow then
		tweenService:Create(ambientGlow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	end

	for _, otherPanel in ipairs(UI:GetChildren()) do
		if smartBar.Buttons:FindFirstChild(otherPanel.Name) then
			if isPanel(otherPanel.Name) and otherPanel.Visible then
				task.spawn(closePanel, otherPanel.Name, true)
				task.wait()
			end
		end
	end

	tweenService:Create(smartBar.Time, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
	for _, Button in ipairs(smartBar.Buttons:GetChildren()) do
		tweenService:Create(Button.UIStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
		tweenService:Create(Button, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 30, 0, 30)}):Play()
		tweenService:Create(Button, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
		tweenService:Create(Button.Icon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	end

	tweenService:Create(coreGui.RobloxGui.Backpack, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()

	tweenService:Create(smartBar, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {BackgroundTransparency = 1}):Play()
	tweenService:Create(smartBar.UIStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
	tweenService:Create(smartBar.Shadow, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	tweenService:Create(smartBar, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.new(0,531,0,64)}):Play()
	tweenService:Create(smartBar, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0,1, 73)}):Play()

	-- If tools, move the toggle
	if checkTools() then
		tweenService:Create(toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5,0,1,-68)}):Play()
		tweenService:Create(toastsContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 1, -90)}):Play()
		tweenService:Create(toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
	else
		tweenService:Create(toastsContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 1, -28)}):Play()
		tweenService:Create(toggle, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 1, -5)}):Play()
		tweenService:Create(toggle, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Rotation = 180}):Play()
	end
end

local function windowFocusChanged(value)
	if checkSirius() then
		if value then -- Window Focused
			setfpscap(tonumber(checkSetting("Artificial FPS Limit").current))
			removeReverbs(0.5)
		else          -- Window unfocused
			if checkSetting("Muffle audio while unfocused").current then createReverb(0.7) end
			if checkSetting("Limit FPS while unfocused").current then setfpscap(60) end
		end
	end
end

local function onChatted(player, message)
	local enabled = checkSetting("Chat Spy").current and siriusValues.chatSpy.enabled
	local chatSpyVisuals = siriusValues.chatSpy.visual

	if not message or not checkSirius() then return end

	if enabled and player ~= localPlayer then
		local message2 = message:gsub("[\n\r]",''):gsub("\t",' '):gsub("[ ]+",' ')
		local hidden = true

		local get = getMessage.OnClientEvent:Connect(function(packet, channel)
			if packet.SpeakerUserId == player.UserId and packet.Message == message2:sub(#message2-#packet.Message+1) and (channel=="All" or (channel=="Team" and players[packet.FromSpeaker].Team == localPlayer.Team)) then
				hidden = false
			end
		end)

		task.wait(1)

		get:Disconnect()

		if hidden and enabled then
			chatSpyVisuals.Text = "Sirius Spy - [".. player.Name .."]: "..message2
			starterGui:SetCore("ChatMakeSystemMessage", chatSpyVisuals)
		end
	end

	if checkSetting("Log Messages").current then
		local logData = {
			["content"] = message,
			["avatar_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=420&height=420&format=png",
			["username"] = player.DisplayName,
			["allowed_mentions"] = {parse = {}}
		}

		logData = httpService:JSONEncode(logData)

		pcall(function()
			local req = originalRequest({
				Url = checkSetting("Message Webhook URL").current,
				Method = 'POST',
				Headers = {
					['Content-Type'] = 'application/json',
				},
				Body = logData
			})
		end)
	end
end

local function sortPlayers()
	local newTable = playerlistPanel.Interactions.List:GetChildren()

	for index, player in ipairs(newTable) do
		if player.ClassName ~= "Frame" or player.Name == "Placeholder" then
			table.remove(newTable, index)
		end
	end

	table.sort(newTable, function(playerA, playerB)
		return playerA.Name < playerB.Name
	end)

	for index, frame in ipairs(newTable) do
		if frame.ClassName == "Frame" then
			if frame.Name ~= "Placeholder" then
				frame.LayoutOrder = index 
			end
		end
	end
end

local function kill(targetPlayer)
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local targetChar = targetPlayer.Character
	local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	
	if not hrp or not targetHRP then
		return
	end

	queueNotification("Attempting Kill", "Flinging "..targetPlayer.DisplayName.." to the void...", 9134785384)
	
	-- Save original position
	local originalCFrame = hrp.CFrame
	
	-- Create Fling mechanics
	local thrust = Instance.new("BodyThrust")
	thrust.Force = Vector3.new(9999, 9999, 9999)
	thrust.Name = "SiriusKillThrust"
	thrust.Parent = hrp
	
	local angular = Instance.new("BodyAngularVelocity")
	angular.AngularVelocity = Vector3.new(0, 9e5, 0)
	angular.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	angular.Name = "SiriusKillAngular"
	angular.Parent = hrp
	
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Massless = true
			part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5) -- High density
			part.CanCollide = false
		end
	end
	if hrp then hrp.CanCollide = true end -- Root must collide to fling correctly
	
	local flingConn
	flingConn = runService.Heartbeat:Connect(function()
		local tChar = targetPlayer.Character
		local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
		if tHrp and hrp then
			hrp.CFrame = tHrp.CFrame * CFrame.Angles(math.rad(math.random(0,360)), math.rad(math.random(0,360)), math.rad(math.random(0,360)))
			hrp.Velocity = Vector3.new(0, 50000, 0)
			hrp.RotVelocity = Vector3.new(50000, 50000, 50000)
		else
			-- Target died or left
			if flingConn then
				flingConn:Disconnect()
				flingConn = nil
			end
		end
	end)
	
	-- Stop Flinging after 2.5s
	task.delay(2.5, function()
		if flingConn then flingConn:Disconnect() end
		if thrust then thrust:Destroy() end
		if angular then angular:Destroy() end
		
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Massless = false
					part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
					part.CanCollide = true
				end
			end
			if hrp then
				-- Stabilization Loop to prevent launching
				local stabilizeStart = tick()
				local stabilizeConn
				stabilizeConn = runService.Heartbeat:Connect(function()
					if tick() - stabilizeStart > 1.5 or not hrp.Parent then
						stabilizeConn:Disconnect()
						return
					end
					hrp.Velocity = Vector3.new(0,0,0)
					hrp.RotVelocity = Vector3.new(0,0,0)
					hrp.CFrame = originalCFrame
				end)
			end
		end
	end)
end

local function teleportTo(player)
	if players:FindFirstChild(player.Name) then
		queueNotification("Teleportation", "Teleporting to "..player.DisplayName..".")

		local target = workspace:FindFirstChild(player.Name).HumanoidRootPart
		localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(target.Position.X, target.Position.Y, target.Position.Z)
	else
		queueNotification("Teleportation Error", player.DisplayName.." has left this server.")
	end
end

local function createHL(tgtPlayer, char)
	if not char then return end
	local container = gethui and gethui() or coreGui
	if not getgenv()._siriusSingleESP then getgenv()._siriusSingleESP = {} end
	if not getgenv()._siriusSingleESPGui then getgenv()._siriusSingleESPGui = {} end

	local existing = container:FindFirstChild("SiriusESP_"..tgtPlayer.Name)
	if existing then existing:Destroy() end
	-- Highlight
	local hl = Instance.new("Highlight")
	hl.Name = "SiriusESP_"..tgtPlayer.Name
	hl.Adornee = char
	hl.FillColor = (tgtPlayer == localPlayer and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 200, 0))
	hl.OutlineColor = (tgtPlayer == localPlayer and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 255, 0))
	hl.FillTransparency = 0.5
	hl.OutlineTransparency = 0
	hl.Parent = container
	getgenv()._siriusSingleESP[tgtPlayer.Name] = hl

	-- BillboardGui
	local head = char:FindFirstChild("Head")
	if head then
		local bb = container:FindFirstChild("SiriusESPGui_"..tgtPlayer.Name)
		if bb then bb:Destroy() end
		bb = Instance.new("BillboardGui")
		bb.Name = "SiriusESPGui_"..tgtPlayer.Name
		bb.Adornee = head
		bb.Size = UDim2.new(0, 200, 0, 50)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true
		bb.Parent = container
		
		local nameLabel = Instance.new("TextLabel", bb)
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.RichText = true
		local isDev = table.find(siriusValues.devs, tgtPlayer.Name:lower())
		nameLabel.Text = tgtPlayer.DisplayName.." (@"..tgtPlayer.Name..")"..(isDev and " <font color='#00ff00'>[Dev]</font>" or "")
		nameLabel.TextColor3 = (tgtPlayer == localPlayer and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 255, 0))
		nameLabel.TextStrokeTransparency = 0.3
		nameLabel.TextScaled = false
		nameLabel.TextSize = (tgtPlayer == localPlayer and 14 or 12)
		nameLabel.Font = Enum.Font.GothamBold
		
		local distLabel = Instance.new("TextLabel", bb)
		distLabel.Name = "DistLabel"
		distLabel.Size = UDim2.new(1, 0, 0.5, 0)
		distLabel.Position = UDim2.new(0, 0, 0.5, 0)
		distLabel.BackgroundTransparency = 1
		distLabel.Text = "0 studs"
		distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		distLabel.TextStrokeTransparency = 0.3
		distLabel.TextScaled = false
		distLabel.TextSize = 11
		distLabel.Font = Enum.Font.Gotham
		
		getgenv()._siriusSingleESPGui[tgtPlayer.Name] = bb
		task.spawn(function()
			while bb and bb.Parent and getgenv()._siriusSingleESP[tgtPlayer.Name] do
				local myChar = localPlayer.Character
				local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
				local tgtHRP = tgtPlayer.Character and tgtPlayer.Character:FindFirstChild("HumanoidRootPart")
				if myHRP and tgtHRP then
					distLabel.Text = math.floor((myHRP.Position - tgtHRP.Position).Magnitude).." studs"
				end
				task.wait(0.5)
			end
		end)
	end
end

local function createPlayer(player)
	if not checkSirius() then return end

	if playerlistPanel.Interactions.List:FindFirstChild(player.Name) then return end

	local newPlayer = playerlistPanel.Interactions.List.Template:Clone()
	newPlayer.Name = player.Name
	newPlayer.Parent = playerlistPanel.Interactions.List
	newPlayer.Visible = not searchingForPlayer

	newPlayer.NoActions.Visible = false
	newPlayer.PlayerInteractions.Visible = false
	newPlayer.Role.Visible = false

	newPlayer.Size = UDim2.new(0, 539, 0, 48) -- Slightly taller for premium feel
	newPlayer.BackgroundColor3 = Color3.fromRGB(15, 15, 18) -- Deeper dark theme
	newPlayer.BackgroundTransparency = 0.2
	
	local cardCrn = newPlayer:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", newPlayer)
	cardCrn.CornerRadius = UDim.new(0, 14)
	
	local cardStroke = newPlayer:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke", newPlayer)
	cardStroke.Thickness = 0.8 -- Thinner, more 'internal'
	cardStroke.Color = Color3.fromRGB(70, 70, 100) -- Premium blueish default
	cardStroke.Transparency = 0.5
	cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	newPlayer.DisplayName.Position = UDim2.new(0, 65, 0.5, -8)
	newPlayer.DisplayName.Size = UDim2.new(0, 220, 0, 18)
	newPlayer.DisplayName.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Add Username label if not exists
	local usernameLabel = newPlayer:FindFirstChild("UsernameSub")
	if not usernameLabel then
		usernameLabel = newPlayer.DisplayName:Clone()
		usernameLabel.Name = "UsernameSub"
		usernameLabel.Parent = newPlayer
		usernameLabel.TextSize = 14 -- Increased readability handle
		usernameLabel.TextScaled = false -- Prevent auto-scaling
		usernameLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
		usernameLabel.TextTransparency = 0.5 
		usernameLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular)
	end
	usernameLabel.Position = UDim2.new(0, 65, 0.5, 8)
	usernameLabel.Text = "@"..player.Name
	usernameLabel.Visible = true

	newPlayer.Avatar.Size = UDim2.new(0, 36, 0, 36)
	newPlayer.Avatar.Position = UDim2.new(0, 18, 0.5, 0)
	newPlayer.Avatar.AnchorPoint = Vector2.new(0, 0.5)
	local avCrn = newPlayer.Avatar:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", newPlayer.Avatar)
	avCrn.CornerRadius = UDim.new(1, 0) -- Circular


	sortPlayers()

	newPlayer.DisplayName.TextTransparency = 0
	newPlayer.DisplayName.TextSize = 19 -- Increased readability main
	newPlayer.DisplayName.TextScaled = false -- Disabled scaling
	newPlayer.DisplayName.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular)
	newPlayer.DisplayName.RichText = true
	
	local dispName = player.DisplayName
	if table.find(siriusValues.devs, player.Name:lower()) then
		dispName = dispName .. " <font color='#00ff00' face='GothamBold'>[DEV]</font>"
	end
	newPlayer.DisplayName.Text = dispName
	newPlayer.Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=420&height=420&format=png"


	if creatorType == Enum.CreatorType.Group then
		task.spawn(function()
			local role = player:GetRoleInGroup(creatorId)
			if role == "Guest" then
				newPlayer.Role.Text = "Group Rank: None"
			else
				newPlayer.Role.Text = "Group Rank: "..role
			end

			newPlayer.Role.Visible = true
			newPlayer.Role.TextTransparency = 1
		end)
	end

	local function updateInteractionStyle(interaction)
		local bg = Color3.fromRGB(22, 22, 26) 
		local stroke = Color3.fromRGB(70, 70, 90)
		local iconCol = Color3.fromRGB(160, 160, 175)
		local bgTrans = 0.45
		local iconTrans = 0

		if interaction.Name == "Spectate" and getgenv()._siriusSpectateTarget == player.Name then
			bg = Color3.fromRGB(0, 255, 170) 
			stroke = Color3.fromRGB(100, 255, 210)
			iconCol = Color3.fromRGB(0, 60, 45)
			bgTrans = 0.1
		elseif interaction.Name == "Locate" and getgenv()._siriusSingleESP and getgenv()._siriusSingleESP[player.Name] then
			if player == localPlayer and getgenv()._siriusSpectateTarget ~= nil then
				-- Keep neutral
			else
				bg = Color3.fromRGB(255, 200, 0)
				stroke = Color3.fromRGB(255, 240, 100)
				iconCol = Color3.fromRGB(60, 50, 0)
				bgTrans = 0.1
			end
		end

		tweenService:Create(interaction, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundColor3 = bg, BackgroundTransparency = bgTrans}):Play()
		tweenService:Create(interaction.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageColor3 = iconCol, ImageTransparency = iconTrans}):Play()
		if interaction:FindFirstChild("UIStroke") then
			tweenService:Create(interaction.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Color = stroke, Transparency = 0.25}):Play()
		end
		if interaction:FindFirstChild("Shadow") then
			tweenService:Create(interaction.Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 0.7}):Play()
		end
	end

	local function openInteractions()
		if newPlayer.PlayerInteractions.Visible then return end

		newPlayer.PlayerInteractions.BackgroundTransparency = 1
		for _, interaction in ipairs(newPlayer.PlayerInteractions:GetChildren()) do
			if interaction.ClassName == "Frame" and interaction.Name ~= "Placeholder" then
				interaction.BackgroundTransparency = 1
				interaction.Shadow.ImageTransparency = 1
				interaction.Icon.ImageTransparency = 1
				interaction.UIStroke.Transparency = 1
			end
		end

		newPlayer.PlayerInteractions.Visible = true

		for _, interaction in ipairs(newPlayer.PlayerInteractions:GetChildren()) do
			if interaction.ClassName == "Frame" and interaction.Name ~= "Placeholder" then
				local intStroke = interaction:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke", interaction)
				intStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				intStroke.Thickness = 1.1
				
				local intCrn = interaction:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", interaction)
				intCrn.CornerRadius = UDim.new(0, 12)

				updateInteractionStyle(interaction)
			end
		end
	end

	local function closeInteractions()
		if not newPlayer.PlayerInteractions.Visible then return end
		for _, interaction in ipairs(newPlayer.PlayerInteractions:GetChildren()) do
			if interaction.ClassName == "Frame" and interaction.Name ~= "Placeholder" then
				tweenService:Create(interaction.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
				tweenService:Create(interaction.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
				tweenService:Create(interaction.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
				tweenService:Create(interaction, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
			end
		end
		task.wait(0.35)
		newPlayer.PlayerInteractions.Visible = false
	end

	newPlayer.MouseEnter:Connect(function()
		if debounce or not playerlistPanel.Visible then return end
		tweenService:Create(newPlayer, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(25, 25, 30), BackgroundTransparency = 0.1}):Play()
		tweenService:Create(cardStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Transparency = 0.1, Color = Color3.fromRGB(90, 90, 120)}):Play()
		tweenService:Create(newPlayer.DisplayName, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	end)

	newPlayer.MouseLeave:Connect(function()
		if debounce or not playerlistPanel.Visible then return end
		task.spawn(closeInteractions)
		
		-- Always collapse on leave to maintain a clean list
		tweenService:Create(newPlayer, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
			Size = UDim2.new(0, 539, 0, 48),
			BackgroundColor3 = Color3.fromRGB(15, 15, 18),
			BackgroundTransparency = 0.2
		}):Play()
		
		tweenService:Create(newPlayer.DisplayName, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 65, 0.5, -8), TextTransparency = 0}):Play()
		tweenService:Create(usernameLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 65, 0.5, 8), TextTransparency = 0.5}):Play()
		tweenService:Create(newPlayer.Avatar, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 36, 0, 36)}):Play()
		tweenService:Create(cardStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Transparency = 0.6, Color = Color3.fromRGB(50, 50, 60)}):Play()
		tweenService:Create(newPlayer.Role, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
	end)

	newPlayer.Interact.MouseButton1Click:Connect(function()
		if debounce or not playerlistPanel.Visible then return end
		
		local isExpanded = newPlayer.Size.Y.Offset > 50
		local targetY = isExpanded and 48 or 85
		local targetAvatarSize = isExpanded and 36 or 54
		
		if targetY == 48 then
			-- COLLAPSE
			task.spawn(closeInteractions)
			tweenService:Create(newPlayer.DisplayName, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 65, 0.5, -8)}):Play()
			tweenService:Create(usernameLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 65, 0.5, 8), TextTransparency = 0.5}):Play()
			tweenService:Create(newPlayer.Role, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
			
			tweenService:Create(newPlayer, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
				Size = UDim2.new(0, 539, 0, 48),
				BackgroundColor3 = Color3.fromRGB(15, 15, 18),
				BackgroundTransparency = 0.2
			}):Play()
		else
			-- EXPAND
			if creatorType == Enum.CreatorType.Group then
				tweenService:Create(newPlayer.DisplayName, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 85, 0.3, 0)}):Play()
				tweenService:Create(usernameLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 85, 0.45, 0)}):Play()
				tweenService:Create(newPlayer.Role, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 85, 0.6, 0), TextTransparency = 0.4}):Play()
			else
				tweenService:Create(newPlayer.DisplayName, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 85, 0.4, 0)}):Play()
				tweenService:Create(usernameLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 85, 0.6, 0)}):Play()
			end

			if player ~= localPlayer then openInteractions() end

			tweenService:Create(newPlayer, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
				Size = UDim2.new(0, 539, 0, targetY),
				BackgroundColor3 = Color3.fromRGB(35, 35, 45),
				BackgroundTransparency = 0.2
			}):Play()
		end

		tweenService:Create(newPlayer.DisplayName, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
		tweenService:Create(usernameLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = (targetY == 48 and 0.5 or 0.3)}):Play()
		
		tweenService:Create(newPlayer.Avatar, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0, targetAvatarSize, 0, targetAvatarSize)}):Play()
		tweenService:Create(cardStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
			Transparency = (targetY == 48 and 0.6 or 0.2), 
			Color = (targetY == 48 and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(90, 90, 120))
		}):Play()
	end)

	newPlayer.PlayerInteractions.Kill.Interact.MouseButton1Click:Connect(function()
		-- Premium Feedback Flash
		tweenService:Create(newPlayer.PlayerInteractions.Kill, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(255, 65, 85), BackgroundTransparency = 0.15}):Play()
		tweenService:Create(newPlayer.PlayerInteractions.Kill.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		tweenService:Create(newPlayer.PlayerInteractions.Kill.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Color = Color3.fromRGB(255, 120, 130), Transparency = 0}):Play()
		
		kill(player)
		task.wait(0.7)
		updateInteractionStyle(newPlayer.PlayerInteractions.Kill)
	end)

	newPlayer.PlayerInteractions.Teleport.Interact.MouseButton1Click:Connect(function()
		-- Premium Feedback Flash
		tweenService:Create(newPlayer.PlayerInteractions.Teleport, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(0, 200, 255), BackgroundTransparency = 0.15}):Play()
		tweenService:Create(newPlayer.PlayerInteractions.Teleport.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		tweenService:Create(newPlayer.PlayerInteractions.Teleport.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Color = Color3.fromRGB(100, 220, 255), Transparency = 0}):Play()
		
		teleportTo(player)
		task.wait(0.7)
		updateInteractionStyle(newPlayer.PlayerInteractions.Teleport)
	end)

		newPlayer.PlayerInteractions.Spectate.Interact.MouseButton1Click:Connect(function()
		local currentlySpectating = getgenv()._siriusSpectateTarget
		local isReturning = (currentlySpectating == player.Name) or (player == localPlayer and currentlySpectating ~= nil)

		if isReturning then
			if getgenv().unspectateAll then
				getgenv().unspectateAll()
			end
		else
			-- START SPECTATE
			if getgenv()._siriusSpectateConn then getgenv()._siriusSpectateConn:Disconnect() getgenv()._siriusSpectateConn = nil end
			if getgenv()._siriusSpectateCharConn then getgenv()._siriusSpectateCharConn:Disconnect() getgenv()._siriusSpectateCharConn = nil end
			
			getgenv()._siriusSpectateTarget = player.Name
			getgenv()._siriusSelfESPDisabled = false -- Reset disable flag on new spectate
			
			-- Self ESP
			if localPlayer.Character then
				createHL(localPlayer, localPlayer.Character)
			end
			
			for _, card in ipairs(playerlistPanel.Interactions.List:GetChildren()) do
				if card:FindFirstChild("PlayerInteractions") and card.PlayerInteractions:FindFirstChild("Spectate") then
					updateInteractionStyle(card.PlayerInteractions.Spectate)
				end
			end
			
			local targetHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if targetHum then
				getgenv()._siriusStartTransit(targetHum)
			else
				queueNotification("Spectate Info", player.DisplayName.." has no active character right now.", 9134770786)
			end

			getgenv()._siriusSpectateConn = runService.Heartbeat:Connect(function()
				if getgenv()._siriusSpectateTarget == player.Name then
					if not getgenv()._siriusCurrentProxy and workspace.CurrentCamera.CameraSubject ~= targetHum then
						if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
							workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
						end
					end
				else
					if getgenv()._siriusSpectateConn then getgenv()._siriusSpectateConn:Disconnect() getgenv()._siriusSpectateConn = nil end
				end
			end)

			getgenv()._siriusSpectateCharConn = player.CharacterAdded:Connect(function(char)
				task.wait(0.5)
				local hum = char:WaitForChild("Humanoid", 5)
				if hum and getgenv()._siriusSpectateTarget == player.Name then
					workspace.CurrentCamera.CameraSubject = hum
				end
			end)

			queueNotification("Spectate ON", player.DisplayName, 9134770786)
		end
	end)

		newPlayer.PlayerInteractions.Locate.Interact.MouseButton1Click:Connect(function()
		if not getgenv()._siriusSingleESP then getgenv()._siriusSingleESP = {} end
		if not getgenv()._siriusSingleESPGui then getgenv()._siriusSingleESPGui = {} end
		local container = gethui and gethui() or coreGui
		if getgenv()._siriusSingleESP[player.Name] then
			getgenv()._siriusSingleESP[player.Name]:Destroy()
			getgenv()._siriusSingleESP[player.Name] = nil
			if getgenv()._siriusSingleESPGui[player.Name] then
				getgenv()._siriusSingleESPGui[player.Name]:Destroy()
				getgenv()._siriusSingleESPGui[player.Name] = nil
			end
			
			-- Self-ESP Support
			if player == localPlayer and getgenv()._siriusSpectateTarget == nil then
				-- Normally don't remove self-esp if we're spectating, but if we aren't, clean up
			end

			tweenService:Create(newPlayer.PlayerInteractions.Locate, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(30, 30, 33)}):Play()
			tweenService:Create(newPlayer.PlayerInteractions.Locate.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageColor3 = Color3.fromRGB(100, 100, 100)}):Play()
			tweenService:Create(newPlayer.PlayerInteractions.Locate.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Color = Color3.fromRGB(55, 55, 60)}):Play()
			queueNotification("ESP OFF", player.DisplayName, 9134780101)
		else
				createHL(player, player.Character)
			player.CharacterAdded:Connect(function(newChar)
				task.wait(0.1)
				if getgenv()._siriusSingleESP and getgenv()._siriusSingleESP[player.Name] then
					createHL(player, newChar)
				end
			end)
			updateInteractionStyle(newPlayer.PlayerInteractions.Locate)
			queueNotification("ESP ON", player.DisplayName, 9134780101)
		end
	end)
end

local function removePlayer(player)
	if not checkSirius() then return end

	if playerlistPanel.Interactions.List:FindFirstChild(player.Name) then
		playerlistPanel.Interactions.List:FindFirstChild(player.Name):Destroy()
	end
	
	-- Cleanup ESP objects
	local container = gethui and gethui() or coreGui
	local oldH = container:FindFirstChild("SiriusUniversal_HL_"..player.Name)
	if oldH then oldH:Destroy() end
	local oldB = container:FindFirstChild("SiriusUniversal_BB_"..player.Name)
	if oldB then oldB:Destroy() end
end

local function openSettings()
	debounce = true

	settingsPanel.BackgroundTransparency = 1
	settingsPanel.Title.TextTransparency = 1
	settingsPanel.Subtitle.TextTransparency = 1
	settingsPanel.Back.ImageTransparency = 1
	settingsPanel.Shadow.ImageTransparency = 1

	wipeTransparency(settingsPanel.SettingTypes, 1, true)

	settingsPanel.Visible = true
	settingsPanel.UIGradient.Enabled = true
	settingsPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	settingsPanel.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0.0470588, 0.0470588, 0.0470588)),ColorSequenceKeypoint.new(1, Color3.new(0.0470588, 0.0470588, 0.0470588))})
	settingsPanel.UIGradient.Offset = Vector2.new(0, 1.7)
	settingsPanel.SettingTypes.Visible = true
	settingsPanel.SettingLists.Visible = false
	settingsPanel.Size = UDim2.new(0, 550, 0, 340)
	settingsPanel.Title.Position = UDim2.new(0.045, 0, 0.057, 0)

	settingsPanel.Title.Text = "Settings"
	settingsPanel.Subtitle.Text = "Adjust your preferences, set new keybinds, test out new features and more."

	tweenService:Create(settingsPanel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 613, 0, 384)}):Play()
	tweenService:Create(settingsPanel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
	tweenService:Create(settingsPanel.Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 0.7}):Play()
	tweenService:Create(settingsPanel.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
	tweenService:Create(settingsPanel.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()

	task.wait(0.1)

	for _, settingType in ipairs(settingsPanel.SettingTypes:GetChildren()) do
		if settingType.ClassName == "Frame" then
			local gradientRotation = math.random(78, 95)

			tweenService:Create(settingType.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Rotation = gradientRotation}):Play()
			tweenService:Create(settingType.Shadow.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Rotation = gradientRotation}):Play()
			tweenService:Create(settingType.UIStroke.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Rotation = gradientRotation}):Play()
			tweenService:Create(settingType, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
			tweenService:Create(settingType.Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 0.7}):Play()
			tweenService:Create(settingType.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Transparency = 0}):Play()
			tweenService:Create(settingType.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0.2}):Play()

			task.wait(0.02)
		end
	end

	for _, settingList in ipairs(settingsPanel.SettingLists:GetChildren()) do
		if settingList.ClassName == "ScrollingFrame" then
			for _, setting in ipairs(settingList:GetChildren()) do
				if setting.ClassName == "Frame" then
					setting.Visible = true
				end
			end
		end
	end

	debounce = false
end

local function closeSettings()
	debounce = true

	for _, settingType in ipairs(settingsPanel.SettingTypes:GetChildren()) do
		if settingType.ClassName == "Frame" then
			tweenService:Create(settingType, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
			tweenService:Create(settingType.Shadow, TweenInfo.new(0.05, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
			tweenService:Create(settingType.UIStroke, TweenInfo.new(0.05, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
			tweenService:Create(settingType.Title, TweenInfo.new(0.05, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
		end
	end

	tweenService:Create(settingsPanel.Shadow, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	tweenService:Create(settingsPanel.Back, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	tweenService:Create(settingsPanel.Title, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
	tweenService:Create(settingsPanel.Subtitle, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()

	for _, settingList in ipairs(settingsPanel.SettingLists:GetChildren()) do
		if settingList.ClassName == "ScrollingFrame" then
			for _, setting in ipairs(settingList:GetChildren()) do
				if setting.ClassName == "Frame" then
					setting.Visible = false
				end
			end
		end
	end

	tweenService:Create(settingsPanel, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 520, 0, 0)}):Play()
	tweenService:Create(settingsPanel, TweenInfo.new(0.55, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()

	task.wait(0.55)

	settingsPanel.Visible = false
	debounce = false
end

local function saveSettings()
	checkFolder()

	if isfile and isfile(siriusValues.siriusFolder.."/"..siriusValues.settingsFile) then
		writefile(siriusValues.siriusFolder.."/"..siriusValues.settingsFile, httpService:JSONEncode(siriusSettings))
	end
end


local function assembleSettings()
	if isfile and isfile(siriusValues.siriusFolder.."/"..siriusValues.settingsFile) then
		local currentSettings

		local success, response = pcall(function()
			currentSettings = httpService:JSONDecode(readfile(siriusValues.siriusFolder.."/"..siriusValues.settingsFile))
		end)

		if success then
			for _, liveCategory in ipairs(siriusSettings) do
				for _, liveSetting in ipairs(liveCategory.categorySettings) do
					for _, category in ipairs(currentSettings) do
						for _, setting in ipairs(category.categorySettings) do
							if liveSetting.id == setting.id then
								liveSetting.current = setting.current
							end
						end
					end
				end
			end

			writefile(siriusValues.siriusFolder.."/"..siriusValues.settingsFile, httpService:JSONEncode(siriusSettings)) -- Update file with any new settings added
		end
	else
		if writefile then
			checkFolder()
			if not isfile(siriusValues.siriusFolder.."/"..siriusValues.settingsFile) then
				writefile(siriusValues.siriusFolder.."/"..siriusValues.settingsFile, httpService:JSONEncode(siriusSettings))
			end
		end 
	end

	for _, category in siriusSettings do
		local newCategory = settingsPanel.SettingTypes.Template:Clone()
		newCategory.Name = category.name
		newCategory.Title.Text = string.upper(category.name)
		newCategory.Parent = settingsPanel.SettingTypes
		newCategory.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0.0392157, 0.0392157, 0.0392157)),ColorSequenceKeypoint.new(1, category.color)})

		newCategory.Visible = true

		local hue, sat, val = Color3.toHSV(category.color)

		hue = math.clamp(hue + 0.01, 0, 1) sat = math.clamp(sat + 0.1, 0, 1) val = math.clamp(val + 0.2, 0, 1)

		local newColor = Color3.fromHSV(hue, sat, val)
		newCategory.UIStroke.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0.117647, 0.117647, 0.117647)),ColorSequenceKeypoint.new(1, newColor)})
		newCategory.Shadow.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0.117647, 0.117647, 0.117647)),ColorSequenceKeypoint.new(1, newColor)})
		
		newCategory.UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Fix clipping
		newCategory.Parent.ClipsDescendants = false -- Fix clipping


		local newList = settingsPanel.SettingLists.Template:Clone()
		if category.name == 'Infinite Yield' then
			newList.ScrollingEnabled = false
			newList.ScrollBarThickness = 0
		end
		newList.Name = category.name
		newList.Parent = settingsPanel.SettingLists

		newList.Visible = true

		for _, obj in ipairs(newList:GetChildren()) do if obj.Name ~= "Placeholder" and obj.Name ~= "UIListLayout" then obj:Destroy() end end 

		settingsPanel.Back.MouseButton1Click:Connect(function()
			tweenService:Create(settingsPanel.Back, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
			tweenService:Create(settingsPanel.Back, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.002, 0, 0.052, 0)}):Play()
			tweenService:Create(settingsPanel.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.045, 0, 0.057, 0)}):Play()
			tweenService:Create(settingsPanel.UIGradient, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Offset = Vector2.new(0, 1.3)}):Play()
			settingsPanel.Title.Text = "Settings"
			settingsPanel.Subtitle.Text = "Adjust your preferences, set new keybinds, test out new features and more"
			settingsPanel.SettingTypes.Visible = true
			settingsPanel.SettingLists.Visible = false
			local COREGUI_KBM = game:GetService("CoreGui")
			if COREGUI_KBM:FindFirstChild("SiriusKeybindManager") then
				COREGUI_KBM.SiriusKeybindManager:Destroy()
			end
			if lighting:FindFirstChild("KBMBlur") then lighting.KBMBlur:Destroy() end
		end)

		newCategory.Interact.MouseButton1Click:Connect(function()
			-- Intercept the "Infinite Yield" category to open custom keybind UI
			if category.name == 'Infinite Yield' then
				-- === SIRIUS PREMIUM KEYBIND MANAGER v6 ===
				local COREGUI_KBM = game:GetService("CoreGui")
				if COREGUI_KBM:FindFirstChild("SiriusKeybindManager") then
					COREGUI_KBM.SiriusKeybindManager:Destroy()
				end
				if lighting:FindFirstChild("KBMBlur") then lighting.KBMBlur:Destroy() end

				local kbmGui = Instance.new("ScreenGui", COREGUI_KBM)
				kbmGui.Name = "SiriusKeybindManager"
				kbmGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				kbmGui.DisplayOrder = 9999

				-- Backdrop 
				local backdrop = Instance.new("TextButton", kbmGui)
				backdrop.Name = "Backdrop"
				backdrop.Size = UDim2.fromScale(1, 1)
				backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				backdrop.BackgroundTransparency = 1
				backdrop.BorderSizePixel = 0
				backdrop.AutoButtonColor = false
				backdrop.Text = ""
				backdrop.ZIndex = 1

				-- Main Panel (Ultra Black)
				local panel = Instance.new("Frame", kbmGui)
				panel.Name = "Panel"
				panel.Size = UDim2.new(0, 580, 0, 540)
				panel.Position = UDim2.new(0.5, -290, 0.5, -240)
				panel.BackgroundColor3 = Color3.fromRGB(8, 8, 10) -- Sirius Void Black
				panel.BackgroundTransparency = 1
				panel.BorderSizePixel = 0
				panel.ZIndex = 2
				Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)

				local panelStroke = Instance.new("UIStroke", panel)
				panelStroke.Color = Color3.fromRGB(255, 255, 255)
				panelStroke.Thickness = 1
				panelStroke.Transparency = 1
				panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

				-- Ambient Glow
				local glow = Instance.new("ImageLabel", panel)
				glow.Name = "Glow"
				glow.Size = UDim2.new(1.4, 0, 1.4, 0)
				glow.Position = UDim2.new(0.5, 0, 0.5, 0)
				glow.AnchorPoint = Vector2.new(0.5, 0.5)
				glow.Image = "rbxassetid://6073489140"
				glow.ImageColor3 = Color3.fromRGB(0, 0, 0)
				glow.ImageTransparency = 1
				glow.BackgroundTransparency = 1
				glow.ZIndex = 1

				-- Blur Effect (like Home tab)
				local kbmBlur = Instance.new("BlurEffect", lighting)
				kbmBlur.Size = 0
				kbmBlur.Name = "KBMBlur"

				-- App Animations
				local function animIn()
					tweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -290, 0.5, -270), BackgroundTransparency = 0.02}):Play()
					tweenService:Create(backdrop, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
					tweenService:Create(panelStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.92}):Play()
					tweenService:Create(glow, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {ImageTransparency = 0.35}):Play()
					tweenService:Create(kbmBlur, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Size = 20}):Play()
				end

				-- Layout Elements
				local header = Instance.new("Frame", panel)
				header.Size = UDim2.new(1, 0, 0, 64)
				header.BackgroundTransparency = 1
				header.ZIndex = 5

				local headerTitle = Instance.new("TextLabel", header)
				headerTitle.Size = UDim2.new(1, -120, 0, 24)
				headerTitle.Position = UDim2.new(0, 24, 0, 18)
				headerTitle.Text = "KEYBIND MANAGER"
				headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
				headerTitle.Font = Enum.Font.GothamBold
				headerTitle.TextSize = 15
				headerTitle.TextXAlignment = Enum.TextXAlignment.Left
				headerTitle.BackgroundTransparency = 1
				headerTitle.ZIndex = 5

				local closeBtn = Instance.new("ImageButton", panel)
				closeBtn.Size = UDim2.new(0, 32, 0, 32)
				closeBtn.Position = UDim2.new(1, -44, 0, 15)
				closeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
				closeBtn.Image = "rbxassetid://6031094678"
				closeBtn.ImageColor3 = Color3.fromRGB(220, 220, 230)
				closeBtn.BorderSizePixel = 0
				closeBtn.ZIndex = 6
				Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
				local closePad = Instance.new("UIPadding", closeBtn)
				closePad.PaddingTop = UDim.new(0, 9) closePad.PaddingBottom = UDim.new(0, 9)
				closePad.PaddingLeft = UDim.new(0, 9) closePad.PaddingRight = UDim.new(0, 9)

				-- Component: Hover Anim
				local function addHover(obj, color1, color2)
					obj.MouseEnter:Connect(function() tweenService:Create(obj, TweenInfo.new(0.3), {BackgroundColor3 = color2}):Play() end)
					obj.MouseLeave:Connect(function() tweenService:Create(obj, TweenInfo.new(0.3), {BackgroundColor3 = color1}):Play() end)
				end

				-- Add Section Container
				local addSection = Instance.new("Frame", panel)
				addSection.Size = UDim2.new(1, -48, 0, 150)
				addSection.Position = UDim2.new(0, 24, 0, 80)
				addSection.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
				addSection.ZIndex = 4
				Instance.new("UICorner", addSection).CornerRadius = UDim.new(0, 14)
				local addStroke = Instance.new("UIStroke", addSection)
				addStroke.Color = Color3.fromRGB(255, 255, 255)
				addStroke.Transparency = 0.95

				-- Inputs logic
				local isToggle = false
				local isKeyUp = false
				local selectedKey = nil
				local capturing = false

				-- Key button
				local kbmKeyBtn = Instance.new("TextButton", addSection)
				kbmKeyBtn.Size = UDim2.new(0, 120, 0, 34)
				kbmKeyBtn.Position = UDim2.new(0, 15, 0, 20)
				kbmKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
				kbmKeyBtn.Text = "Click to bind"
				kbmKeyBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
				kbmKeyBtn.Font = Enum.Font.GothamMedium
				kbmKeyBtn.TextSize = 12
				kbmKeyBtn.ZIndex = 5
				Instance.new("UICorner", kbmKeyBtn).CornerRadius = UDim.new(1, 0)
				addHover(kbmKeyBtn, Color3.fromRGB(25, 25, 35), Color3.fromRGB(35, 35, 45))

				-- Cmd Box
				local kbmCmdBox = Instance.new("TextBox", addSection)
				kbmCmdBox.Size = UDim2.new(1, -160, 0, 34)
				kbmCmdBox.Position = UDim2.new(0, 145, 0, 20)
				kbmCmdBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
				kbmCmdBox.Text = ""
				kbmCmdBox.PlaceholderText = "Command (e.g. fly)"
				kbmCmdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
				kbmCmdBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
				kbmCmdBox.Font = Enum.Font.GothamMedium
				kbmCmdBox.TextSize = 12
				kbmCmdBox.ZIndex = 5
				Instance.new("UICorner", kbmCmdBox).CornerRadius = UDim.new(1, 0)

				-- Toggle Box (Secondary) - Hidden by default
				local kbmToggleBox = Instance.new("TextBox", addSection)
				kbmToggleBox.Size = UDim2.new(1, -160, 0, 34)
				kbmToggleBox.Position = UDim2.new(0, 145, 0, 62)
				kbmToggleBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
				kbmToggleBox.Text = ""
				kbmToggleBox.PlaceholderText = "Toggle-off command (e.g. unfly)"
				kbmToggleBox.TextColor3 = Color3.fromRGB(255, 255, 255)
				kbmToggleBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
				kbmToggleBox.Font = Enum.Font.GothamMedium
				kbmToggleBox.TextSize = 12
				kbmToggleBox.ZIndex = 5
				kbmToggleBox.Visible = false
				Instance.new("UICorner", kbmToggleBox).CornerRadius = UDim.new(1, 0)

				-- Controls row
				local toggleBtn = Instance.new("TextButton", addSection)
				toggleBtn.Size = UDim2.new(0, 110, 0, 30)
				toggleBtn.Position = UDim2.new(0, 15, 0, 105)
				toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
				toggleBtn.Text = "Toggle: OFF"
				toggleBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
				toggleBtn.Font = Enum.Font.GothamMedium
				toggleBtn.TextSize = 11
				toggleBtn.ZIndex = 5
				Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
				addHover(toggleBtn, Color3.fromRGB(25, 25, 35), Color3.fromRGB(35, 35, 45))

				local triggerBtn = Instance.new("TextButton", addSection)
				triggerBtn.Size = UDim2.new(0, 130, 0, 30)
				triggerBtn.Position = UDim2.new(0, 135, 0, 105)
				triggerBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
				triggerBtn.Text = "Trigger: KeyDown"
				triggerBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
				triggerBtn.Font = Enum.Font.GothamMedium
				triggerBtn.TextSize = 11
				triggerBtn.ZIndex = 5
				Instance.new("UICorner", triggerBtn).CornerRadius = UDim.new(1, 0)
				addHover(triggerBtn, Color3.fromRGB(25, 25, 35), Color3.fromRGB(35, 35, 45))

				local addBtn = Instance.new("TextButton", addSection)
				addBtn.Size = UDim2.new(0, 80, 0, 30)
				addBtn.Position = UDim2.new(1, -95, 0, 105)
				addBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
				addBtn.Text = "ADD"
				addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				addBtn.Font = Enum.Font.GothamBold
				addBtn.TextSize = 12
				addBtn.ZIndex = 5
				Instance.new("UICorner", addBtn).CornerRadius = UDim.new(1, 0)

				-- List section
				local scroll = Instance.new("ScrollingFrame", panel)
				scroll.Size = UDim2.new(1, -48, 1, -260)
				scroll.Position = UDim2.new(0, 24, 0, 245)
				scroll.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
				scroll.BorderSizePixel = 0
				scroll.ScrollBarThickness = 1
				scroll.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 50)
				scroll.ZIndex = 4
				Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 14)
				local listPadding = Instance.new("UIPadding", scroll)
				listPadding.PaddingTop = UDim.new(0, 12)
				listPadding.PaddingLeft = UDim.new(0, 12)
				listPadding.PaddingRight = UDim.new(0, 12)
				local listLayout = Instance.new("UIListLayout", scroll)
				listLayout.Padding = UDim.new(0, 8)
				listLayout.SortOrder = Enum.SortOrder.LayoutOrder

				-- Logic: Refresh
				local function refreshKBM()
					for _, c in ipairs(scroll:GetChildren()) do
						if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
					end

					local bTable = getgenv().binds or binds or {}
					if #bTable == 0 then
						local noBinds = Instance.new("TextLabel", scroll)
						noBinds.Size = UDim2.new(1, 0, 0, 50)
						noBinds.Text = "No active keybinds found."
						noBinds.TextColor3 = Color3.fromRGB(100, 100, 110)
						noBinds.Font = Enum.Font.Gotham
						noBinds.TextSize = 12
						noBinds.BackgroundTransparency = 1
						return
					end

					for i, v in ipairs(bTable) do
						local bFrame = Instance.new("Frame", scroll)
						bFrame.Size = UDim2.new(1, 0, 0, 42)
						bFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
						bFrame.ZIndex = 5
						Instance.new("UICorner", bFrame).CornerRadius = UDim.new(0, 10)

						local keyTxt = tostring(v.KEY or "")
						if keyTxt:find("Enum.KeyCode.") then keyTxt = keyTxt:sub(14) end
						local display = "[" .. keyTxt .. "] " .. tostring(v.COMMAND)
						if v.TOGGLE then display = display .. " / " .. tostring(v.TOGGLE) end

						local label = Instance.new("TextLabel", bFrame)
						label.Size = UDim2.new(1, -50, 1, 0)
						label.Position = UDim2.new(0, 15, 0, 0)
						label.Text = display
						label.TextColor3 = Color3.fromRGB(200, 200, 210)
						label.Font = Enum.Font.GothamMedium
						label.TextSize = 12
						label.TextXAlignment = Enum.TextXAlignment.Left
						label.BackgroundTransparency = 1
						label.ZIndex = 6

						local del = Instance.new("ImageButton", bFrame)
						del.Size = UDim2.new(0, 24, 0, 24)
						del.Position = UDim2.new(1, -34, 0.5, -12)
						del.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
						del.Image = "rbxassetid://6031094678"
						del.ZIndex = 7
						Instance.new("UICorner", del).CornerRadius = UDim.new(0, 8)
						local delPad = Instance.new("UIPadding", del)
						delPad.PaddingTop = UDim.new(0, 6) delPad.PaddingBottom = UDim.new(0, 6)
						delPad.PaddingLeft = UDim.new(0, 6) delPad.PaddingRight = UDim.new(0, 6)

						del.MouseButton1Click:Connect(function()
							local unbindFunc = getgenv().unkeybind or unkeybind
							if unbindFunc then unbindFunc(v.COMMAND, v.KEY) end
							task.wait(0.1)
							refreshKBM()
						end)
					end
					listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
						scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
					end)
					scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
				end

				-- Interactions
				toggleBtn.MouseButton1Click:Connect(function()
					isToggle = not isToggle
					toggleBtn.Text = isToggle and "Toggle: ON" or "Toggle: OFF"
					toggleBtn.TextColor3 = isToggle and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(150, 150, 160)
					triggerBtn.Visible = not isToggle
					kbmToggleBox.Visible = isToggle
					-- Adjust cmd box size if toggle is on
					kbmCmdBox.PlaceholderText = isToggle and "Command (On)" or "Command (e.g. fly)"
				end)

				triggerBtn.MouseButton1Click:Connect(function()
					isKeyUp = not isKeyUp
					triggerBtn.Text = isKeyUp and "Trigger: KeyUp" or "Trigger: KeyDown"
					triggerBtn.TextColor3 = isKeyUp and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(150, 150, 160)
				end)

				kbmKeyBtn.MouseButton1Click:Connect(function()
					capturing = true
					kbmKeyBtn.Text = "Binding..."
					kbmKeyBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
				end)

				userInputService.InputBegan:Connect(function(input, gp)
					if not capturing or gp then return end
					if input.UserInputType == Enum.UserInputType.Keyboard then
						selectedKey = tostring(input.KeyCode)
						kbmKeyBtn.Text = selectedKey:sub(14)
					elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
						selectedKey = "LeftClick"
						kbmKeyBtn.Text = selectedKey
					elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
						selectedKey = "RightClick"
						kbmKeyBtn.Text = selectedKey
					end
					capturing = false
					kbmKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				end)

				addBtn.MouseButton1Click:Connect(function()
					if selectedKey and kbmCmdBox.Text ~= "" then
						local addFunc = getgenv().addbind or addbind
						local saveFunc = getgenv().updatesaves or updatesaves
						local refreshBFunc = getgenv().refreshbinds or refreshbinds
						
						pcall(function()
							if isToggle then
								addFunc(kbmCmdBox.Text, selectedKey, false, kbmToggleBox.Text ~= "" and kbmToggleBox.Text or "un"..kbmCmdBox.Text)
							else
								addFunc(kbmCmdBox.Text, selectedKey, isKeyUp)
							end
							if saveFunc then saveFunc() end
							if refreshBFunc then refreshBFunc() end
						end)
						task.wait(0.1)
						refreshKBM()
						kbmCmdBox.Text = ""
						kbmToggleBox.Text = ""
						selectedKey = nil
						kbmKeyBtn.Text = "Click to bind"
					end
				end)

				local function closeKBM()
					tweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, -290, 0.5, -240), BackgroundTransparency = 1}):Play()
					tweenService:Create(backdrop, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
					tweenService:Create(panelStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
					tweenService:Create(kbmBlur, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = 0}):Play()
					task.wait(0.4)
					if kbmBlur then kbmBlur:Destroy() end
					kbmGui:Destroy()
				end

				closeBtn.MouseButton1Click:Connect(closeKBM)
				backdrop.MouseButton1Click:Connect(closeKBM)

				animIn()
				refreshKBM()
				return -- Don't open normal settings list
			end

			if settingsPanel.SettingLists:FindFirstChild(category.name) then
				settingsPanel.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0.0470588, 0.0470588, 0.0470588)),ColorSequenceKeypoint.new(1, category.color)})
				settingsPanel.SettingTypes.Visible = false
				settingsPanel.SettingLists.Visible = true
				settingsPanel.SettingLists.UIPageLayout:JumpTo(settingsPanel.SettingLists[category.name])
				settingsPanel.Subtitle.Text = category.description
				settingsPanel.Back.Visible = true
				settingsPanel.Title.Text = category.name

				local gradientRotation = math.random(78, 95)
				settingsPanel.UIGradient.Rotation = gradientRotation
				tweenService:Create(settingsPanel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Offset = Vector2.new(0, 0.65)}):Play()
				tweenService:Create(settingsPanel.Back, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
				tweenService:Create(settingsPanel.Back, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.041, 0, 0.052, 0)}):Play()
				tweenService:Create(settingsPanel.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.091, 0, 0.057, 0)}):Play()
			else
				-- error
				closeSettings()
			end
		end)

		newCategory.MouseEnter:Connect(function()
			tweenService:Create(newCategory.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
			tweenService:Create(newCategory.UIGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Offset = Vector2.new(0, 0.4)}):Play()
			tweenService:Create(newCategory.UIStroke.UIGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Offset = Vector2.new(0, 0.2)}):Play()
			tweenService:Create(newCategory.Shadow.UIGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Offset = Vector2.new(0, 0.2)}):Play()
		end)

		newCategory.MouseLeave:Connect(function()
			tweenService:Create(newCategory.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0.2}):Play()
			tweenService:Create(newCategory.UIGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Offset = Vector2.new(0, 0.65)}):Play()
			tweenService:Create(newCategory.UIStroke.UIGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Offset = Vector2.new(0, 0.4)}):Play()
			tweenService:Create(newCategory.Shadow.UIGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Offset = Vector2.new(0, 0.4)}):Play()
		end)

		for _, setting in ipairs(category.categorySettings) do
			if not setting.hidden then
				local settingType = setting.settingType
				local minimumLicense = setting.minimumLicense
				local object = nil

				if settingType == "Boolean" then
					local newSwitch = settingsPanel.SettingLists.Template.SwitchTemplate:Clone()
					object = newSwitch
					newSwitch.Name = setting.name
					newSwitch.Parent = newList
					newSwitch.Visible = true
					newSwitch.Title.Text = setting.name

					if setting.current == true then
						newSwitch.Switch.Indicator.Position = UDim2.new(1, -20, 0.5, 0)
						newSwitch.Switch.Indicator.UIStroke.Color = Color3.fromRGB(220, 220, 220)
						newSwitch.Switch.Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)			
						newSwitch.Switch.Indicator.BackgroundTransparency = 0.6
					end


					if minimumLicense then
						if (minimumLicense == "Pro" and not Pro) or (minimumLicense == "Essential" and not (Pro or Essential)) then
							newSwitch.Switch.Indicator.Position = UDim2.new(1, -40, 0.5, 0)
							newSwitch.Switch.Indicator.UIStroke.Color = Color3.fromRGB(255, 255, 255)
							newSwitch.Switch.Indicator.BackgroundColor3 = Color3.fromRGB(235, 235, 235)			
							newSwitch.Switch.Indicator.BackgroundTransparency = 0.75
						end
					end

					newSwitch.Interact.MouseButton1Click:Connect(function()
						if minimumLicense then
							if (minimumLicense == "Pro" and not Pro) or (minimumLicense == "Essential" and not (Pro or Essential)) then
								queueNotification("This feature is locked", "You must be "..minimumLicense.." or higher to use "..setting.name..". \n\nUpgrade at https://sirius.menu.", 4483345875)
								return
							end
						end

						setting.current = not setting.current
						saveSettings()
						if setting.current == true then
							tweenService:Create(newSwitch.Switch.Indicator, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 0.5, 0)}):Play()
							tweenService:Create(newSwitch.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,12,0,12)}):Play()
							tweenService:Create(newSwitch.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Color = Color3.fromRGB(200, 200, 200)}):Play()
							tweenService:Create(newSwitch.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
							tweenService:Create(newSwitch.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0.5}):Play()
							tweenService:Create(newSwitch.Switch.Indicator, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.6}):Play()
							task.wait(0.05)
							tweenService:Create(newSwitch.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,17,0,17)}):Play()							
						else
							tweenService:Create(newSwitch.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -40, 0.5, 0)}):Play()
							tweenService:Create(newSwitch.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,12,0,12)}):Play()
							tweenService:Create(newSwitch.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Color = Color3.fromRGB(255, 255, 255)}):Play()
							tweenService:Create(newSwitch.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0.7}):Play()
							tweenService:Create(newSwitch.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(235, 235, 235)}):Play()
							tweenService:Create(newSwitch.Switch.Indicator, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.75}):Play()
							task.wait(0.05)
							tweenService:Create(newSwitch.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,17,0,17)}):Play()
						end
					end)

				elseif settingType == "Input" then
					local newInput = settingsPanel.SettingLists.Template.InputTemplate:Clone()
					object = newInput

					newInput.Name = setting.name
					newInput.InputFrame.InputBox.Text = setting.current
					newInput.InputFrame.InputBox.PlaceholderText = setting.placeholder or "input"
					newInput.Parent = newList

					if string.len(setting.current) > 19 then
						newInput.InputFrame.InputBox.Text = string.sub(tostring(setting.current), 1,17)..".."
					else
						newInput.InputFrame.InputBox.Text = setting.current
					end

					newInput.Visible = true
					newInput.Title.Text = setting.name
					newInput.InputFrame.InputBox.TextWrapped = false
					newInput.InputFrame.Size = UDim2.new(0, newInput.InputFrame.InputBox.TextBounds.X + 24, 0, 30)

					newInput.InputFrame.InputBox.FocusLost:Connect(function()
						if minimumLicense then
							if (minimumLicense == "Pro" and not Pro) or (minimumLicense == "Essential" and not (Pro or Essential)) then
								queueNotification("This feature is locked", "You must be "..minimumLicense.." or higher to use "..setting.name..". \n\nUpgrade at https://sirius.menu.", 4483345875)
								newInput.InputFrame.InputBox.Text = setting.current
								return
							end
						end

						if newInput.InputFrame.InputBox.Text ~= nil or "" then
							setting.current = newInput.InputFrame.InputBox.Text
							saveSettings()
						end
						if string.len(setting.current) > 24 then
							newInput.InputFrame.InputBox.Text = string.sub(tostring(setting.current), 1,22)..".."
						else
							newInput.InputFrame.InputBox.Text = setting.current
						end
					end)

					newInput.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
						tweenService:Create(newInput.InputFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, newInput.InputFrame.InputBox.TextBounds.X + 24, 0, 30)}):Play()
					end)

				elseif settingType == "Number" then
					local newInput = settingsPanel.SettingLists.Template.InputTemplate:Clone()
					object = newInput

					newInput.Name = setting.name
					newInput.InputFrame.InputBox.Text = tostring(setting.current)
					newInput.InputFrame.InputBox.PlaceholderText = setting.placeholder or "number"
					newInput.Parent = newList

					if string.len(setting.current) > 19 then
						newInput.InputFrame.InputBox.Text = string.sub(tostring(setting.current), 1,17)..".."
					else
						newInput.InputFrame.InputBox.Text = setting.current
					end

					newInput.Visible = true
					newInput.Title.Text = setting.name
					newInput.InputFrame.InputBox.TextWrapped = false
					newInput.InputFrame.Size = UDim2.new(0, newInput.InputFrame.InputBox.TextBounds.X + 24, 0, 30)

					newInput.InputFrame.InputBox.FocusLost:Connect(function()

						if minimumLicense then
							if (minimumLicense == "Pro" and not Pro) or (minimumLicense == "Essential" and not (Pro or Essential)) then
								queueNotification("This feature is locked", "You must be "..minimumLicense.." or higher to use "..setting.name..". \n\nUpgrade at https://sirius.menu.", 4483345875)
								newInput.InputFrame.InputBox.Text = setting.current
								return
							end
						end

						local inputValue = tonumber(newInput.InputFrame.InputBox.Text)

						if inputValue then
							if setting.values then
								local minValue = setting.values[1]
								local maxValue = setting.values[2]

								if inputValue < minValue then
									setting.current = minValue
								elseif inputValue > maxValue then
									setting.current = maxValue
								else
									setting.current = inputValue
								end

								saveSettings()
							else
								setting.current = inputValue
								saveSettings()
							end
						else
							newInput.InputFrame.InputBox.Text = tostring(setting.current)
						end

						if string.len(setting.current) > 24 then
							newInput.InputFrame.InputBox.Text = string.sub(tostring(setting.current), 1,22)..".."
						else
							newInput.InputFrame.InputBox.Text = tostring(setting.current)
						end
					end)

					newInput.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
						tweenService:Create(newInput.InputFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, newInput.InputFrame.InputBox.TextBounds.X + 24, 0, 30)}):Play()
					end)

				elseif settingType == "Key" then
					local newKeybind = settingsPanel.SettingLists.Template.InputTemplate:Clone()
					object = newKeybind
					newKeybind.Name = setting.name
					newKeybind.InputFrame.InputBox.PlaceholderText = setting.placeholder or "listening.."
					newKeybind.InputFrame.InputBox.Text = setting.current or "No Keybind"
					newKeybind.Parent = newList

					newKeybind.Visible = true
					newKeybind.Title.Text = setting.name
					newKeybind.InputFrame.InputBox.TextWrapped = false
					newKeybind.InputFrame.Size = UDim2.new(0, newKeybind.InputFrame.InputBox.TextBounds.X + 24, 0, 30)

					newKeybind.InputFrame.InputBox.FocusLost:Connect(function()
						checkingForKey = false

						if minimumLicense then
							if (minimumLicense == "Pro" and not Pro) or (minimumLicense == "Essential" and not (Pro or Essential)) then
								queueNotification("This feature is locked", "You must be "..minimumLicense.." or higher to use "..setting.name..". \n\nUpgrade at https://sirius.menu.", 4483345875)
								newKeybind.InputFrame.InputBox.Text = setting.current
								return
							end
						end

						if newKeybind.InputFrame.InputBox.Text == nil or newKeybind.InputFrame.InputBox.Text == "" then
							newKeybind.InputFrame.InputBox.Text = "No Keybind"
							setting.current = nil
							newKeybind.InputFrame.InputBox:ReleaseFocus()
							saveSettings()
						end
					end)

					newKeybind.InputFrame.InputBox.Focused:Connect(function()
						checkingForKey = {data = setting, object = newKeybind}
						newKeybind.InputFrame.InputBox.Text = ""
					end)

					newKeybind.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
						tweenService:Create(newKeybind.InputFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, newKeybind.InputFrame.InputBox.TextBounds.X + 24, 0, 30)}):Play()
					end)

				elseif settingType == "Button" then
					local newButton = settingsPanel.SettingLists.Template.InputTemplate:Clone()
					object = newButton
					newButton.Name = setting.name
					newButton.Parent = newList
					newButton.Visible = true
					newButton.Title.Text = setting.name
					newButton.InputFrame.InputBox.Text = "TAP ▸"
					newButton.InputFrame.InputBox.TextEditable = false
					newButton.InputFrame.InputBox.ClearTextOnFocus = false
					newButton.InputFrame.InputBox.TextColor3 = Color3.fromRGB(200, 200, 200)
					newButton.InputFrame.Size = UDim2.new(0, 60, 0, 30)

					local interactBtn = Instance.new("TextButton")
					interactBtn.Name = "Interact"
					interactBtn.Size = UDim2.new(1, 0, 1, 0)
					interactBtn.BackgroundTransparency = 1
					interactBtn.Text = ""
					interactBtn.ZIndex = 5
					interactBtn.Parent = newButton

					newButton.Interact.MouseButton1Click:Connect(function()
						if setting.callback then
							task.spawn(setting.callback)
						end
					end)

				end

				if object then
					if setting.description then
						object.Description.Visible = true
						object.Description.TextWrapped = true
						object.Description.Size = UDim2.new(0, 333, 5, 0)
						object.Description.Size = UDim2.new(0, 333, 0, 999)
						object.Description.Text = setting.description
						object.Description.Size = UDim2.new(0, 333, 0, object.Description.TextBounds.Y + 10)
						object.Size = UDim2.new(0, 558, 0, object.Description.TextBounds.Y + 44)
					end

					if minimumLicense then
						object.LicenseDisplay.Visible = true
						object.Title.Position = UDim2.new(0, 18, 0, 26)
						object.Description.Position = UDim2.new(0, 18, 0, 43)
						object.Size = UDim2.new(0, 558, 0, object.Size.Y.Offset + 13)
						object.LicenseDisplay.Text = string.upper(minimumLicense).." FEATURE"
					end

					local objectTouching
					object.MouseEnter:Connect(function()
						objectTouching = true
						tweenService:Create(object.UIStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0.45}):Play()
						tweenService:Create(object, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.83}):Play()
					end)

					object.MouseLeave:Connect(function()
						objectTouching = false
						tweenService:Create(object.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0.6}):Play()
						tweenService:Create(object, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.9}):Play()
					end)

					if object:FindFirstChild('Interact') then
						object.Interact.MouseButton1Click:Connect(function()
							tweenService:Create(object.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 1}):Play()
							tweenService:Create(object, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.8}):Play()
							task.wait(0.1)
							if objectTouching then
								tweenService:Create(object.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0.45}):Play()
								tweenService:Create(object, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.83}):Play()
							else
								tweenService:Create(object.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0.6}):Play()
								tweenService:Create(object, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.9}):Play()
							end
						end)
					end
				end
			end
		end
	end
end

local function initialiseAntiKick()
	if checkSetting("Client-Based Anti Kick").current then
		if hookmetamethod then 
			local originalIndex
			local originalNamecall

			originalIndex = hookmetamethod(game, "__index", function(self, method)
				if self == localPlayer and method:lower() == "kick" and checkSetting("Client-Based Anti Kick").current and checkSirius() then
					queueNotification("Kick Prevented", "Sirius has prevented you from being kicked by the client.", 4400699701)
					return error("Expected ':' not '.' calling member function Kick", 2)
				end
				return originalIndex(self, method)
			end)

			originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
				if self == localPlayer and getnamecallmethod():lower() == "kick" and checkSetting("Client-Based Anti Kick").current and checkSirius() then
					queueNotification("Kick Prevented", "Sirius has prevented you from being kicked by the client.", 4400699701)
					return
				end
				return originalNamecall(self, ...)
			end)
		end
	end
end

local function boost()
	local success, result = pcall(function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/boost.lua'))()
	end)

	if not success then
		print('Error with boost file.')
		print(result)
	end
end

local function start()
	if siriusValues.releaseType == "Experimental" then -- Make this more secure.
		if not Pro then localPlayer:Kick("This is an experimental release, you must be Pro to run this. \n\nUpgrade at https://sirius.menu/") return end
	end
	windowFocusChanged(true)

	UI.Enabled = true

	assembleSettings()
	ensureFrameProperties()
	sortActions()
	initialiseAntiKick()
	checkLastVersion()
	
	-- Self-ESP Persistence Loop
	localPlayer.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		if getgenv()._siriusSpectateTarget ~= nil and not getgenv()._siriusSelfESPDisabled then
			createHL(localPlayer, char)
		end
	end)

	task.spawn(boost)

	smartBar.Time.Text = os.date("%H")..":"..os.date("%M")

	toggle.Visible = not checkSetting("Hide Toggle Button").current

	if not checkSetting("Load Hidden").current then 
		if checkSetting("Startup Sound Effect").current then
			local startupPath = siriusValues.siriusFolder.."/Assets/startup.wav"
			local startupAsset

			if isfile(startupPath) then
				startupAsset = getcustomasset(startupPath) or nil
			else
				startupAsset = fetchFromCDN("startup.wav", true, "Assets/startup.wav")
				startupAsset = isfile(startupPath) and getcustomasset(startupPath) or nil
			end

			if startupAsset then
				local startupSound = Instance.new("Sound")
				startupSound.Parent = UI
				startupSound.SoundId = startupAsset
				startupSound.Name = "startupSound"
				startupSound.Volume = 0.85
				startupSound.PlayOnRemove = true
				startupSound:Destroy()	
			end
		end

		-- createStarryBackground()
		local glow = Instance.new("ImageLabel", UI)
		glow.Name = "IntroGlow"
		glow.BackgroundTransparency = 1
		glow.Image = "rbxassetid://6073489140"
		glow.ImageColor3 = Color3.fromRGB(80, 140, 255) -- Brighter Blue
		glow.ImageTransparency = 1
		glow.Size = UDim2.new(2, 0, 1.5, 0) 
		glow.Position = UDim2.new(0.5, 0, 1.4, 0) -- Adjusted start
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.ZIndex = -1 

		-- Secondary warm glow layer for depth
		local warmGlow = Instance.new("ImageLabel", UI)
		warmGlow.Name = "IntroWarmGlow"
		warmGlow.BackgroundTransparency = 1
		warmGlow.Image = "rbxassetid://6073489140"
		warmGlow.ImageColor3 = Color3.fromRGB(180, 100, 255) -- Purple accent
		warmGlow.ImageTransparency = 1
		warmGlow.Size = UDim2.new(1.2, 0, 1, 0)
		warmGlow.Position = UDim2.new(0.5, 0, 1.2, 0)
		warmGlow.AnchorPoint = Vector2.new(0.5, 0.5)
		warmGlow.ZIndex = -1

		-- Intro bloom flare
		local introBloom = Instance.new("BloomEffect")
		introBloom.Name = "SiriusIntroBloom"
		introBloom.Intensity = 0
		introBloom.Size = 40
		introBloom.Threshold = 1.1
		introBloom.Parent = lighting

		tweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {Size = UDim2.new(1.8, 0, 1.2, 0), ImageTransparency = 0.3, Position = UDim2.new(0.5, 0, 1.05, 0)}):Play()
		tweenService:Create(warmGlow, TweenInfo.new(1.8, Enum.EasingStyle.Quint), {ImageTransparency = 0.55, Position = UDim2.new(0.5, 0, 1.0, 0)}):Play()
		tweenService:Create(introBloom, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Intensity = 0.25, Threshold = 0.9}):Play()

		task.wait(0.6)
		openSmartBar()
		
		-- Fade bloom back
		tweenService:Create(introBloom, TweenInfo.new(1.5, Enum.EasingStyle.Exponential), {Intensity = 0, Threshold = 1.1}):Play()

		task.delay(1.5, function()
			tweenService:Create(glow, TweenInfo.new(2.5, Enum.EasingStyle.Quint), {ImageTransparency = 1, Size = UDim2.new(2.5, 0, 1.8, 0)}):Play()
			tweenService:Create(warmGlow, TweenInfo.new(2, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
			task.wait(2.6)
			glow:Destroy()
			warmGlow:Destroy()
			introBloom:Destroy()
		end)
	else 
		closeSmartBar() 
	end

	-- Utility: Unspectate All
	getgenv().unspectateAll = function()
		getgenv()._siriusSpectateTarget = nil
		getgenv()._siriusSelfESPDisabled = true -- Also disable automation
		
		if getgenv()._siriusSpectateConn then
			getgenv()._siriusSpectateConn:Disconnect()
			getgenv()._siriusSpectateConn = nil
		end
		if getgenv()._siriusSpectateCharConn then
			getgenv()._siriusSpectateCharConn:Disconnect()
			getgenv()._siriusSpectateCharConn = nil
		end
		local cam = workspace.CurrentCamera
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and getgenv()._siriusStartTransit then
			getgenv()._siriusStartTransit(hum)
		elseif hum then
			workspace.CurrentCamera.CameraSubject = hum
		end

		-- REMOVE SELF ESP
		if getgenv()._siriusSingleESP and getgenv()._siriusSingleESP[localPlayer.Name] then
			getgenv()._siriusSingleESP[localPlayer.Name]:Destroy()
			getgenv()._siriusSingleESP[localPlayer.Name] = nil
			if getgenv()._siriusSingleESPGui and getgenv()._siriusSingleESPGui[localPlayer.Name] then
				getgenv()._siriusSingleESPGui[localPlayer.Name]:Destroy()
				getgenv()._siriusSingleESPGui[localPlayer.Name] = nil
			end
		end

		queueNotification("Spectate OFF", "Camera returned.", 9134770786)
		
		for _, frame in ipairs(playerlistPanel.Interactions.List:GetChildren()) do
			if frame:IsA("Frame") and frame.Name ~= "Placeholder" and frame.Name ~= "Template" then
				local interact = frame:FindFirstChild("PlayerInteractions")
				local specBtn = interact and interact:FindFirstChild("Spectate")
				local locBtn = interact and interact:FindFirstChild("Locate")
				
				if specBtn then
					tweenService:Create(specBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(30, 30, 33)}):Play()
					tweenService:Create(specBtn.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageColor3 = Color3.fromRGB(100, 100, 100)}):Play()
					tweenService:Create(specBtn.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Color = Color3.fromRGB(55, 55, 60)}):Play()
				end

				-- If this is the localplayer card, also ensure its Locate button resets visually
				if frame.Name == localPlayer.Name and locBtn then
					tweenService:Create(locBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(30, 30, 33)}):Play()
					tweenService:Create(locBtn.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageColor3 = Color3.fromRGB(100, 100, 100)}):Play()
					tweenService:Create(locBtn.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Color = Color3.fromRGB(55, 55, 60)}):Play()
				end
			end
		end
	end

	-- Utility: Un-ESP All
	getgenv().unESPAll = function()
		local count = 0
		getgenv()._siriusSelfESPDisabled = true -- Explicitly disable the automated self-esp
		
		if getgenv()._siriusSingleESP then
			for _, hl in pairs(getgenv()._siriusSingleESP) do
				if hl then hl:Destroy() count = count + 1 end
			end
			table.clear(getgenv()._siriusSingleESP)
		end
		if getgenv()._siriusSingleESPGui then
			for _, gui in pairs(getgenv()._siriusSingleESPGui) do
				if gui then gui:Destroy() end
			end
			table.clear(getgenv()._siriusSingleESPGui)
		end
		if count > 0 then
			queueNotification("ESP OFF", "All trackers cleared.", 9134780101)
		end
		
		for _, frame in ipairs(playerlistPanel.Interactions.List:GetChildren()) do
			if frame:IsA("Frame") and frame.Name ~= "Placeholder" and frame.Name ~= "Template" then
				local interact = frame:FindFirstChild("PlayerInteractions")
				local locBtn = interact and interact:FindFirstChild("Locate")
				if locBtn then
					tweenService:Create(locBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(30, 30, 33)}):Play()
					tweenService:Create(locBtn.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageColor3 = Color3.fromRGB(100, 100, 100)}):Play()
					tweenService:Create(locBtn.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Color = Color3.fromRGB(55, 55, 60)}):Play()
				end
			end
		end
	end

	-- Add visual buttons to playerlistPanel (moving to header area)
	task.spawn(function()
		playerlistPanel.ClipsDescendants = false
		local function createUtilityBtn(name, text, btnColor, pos, callback, checkFn)
			local btn = Instance.new("TextButton")
			btn.Name = name
			btn.Size = UDim2.new(0, 85, 0, 26)
			btn.Position = pos
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			btn.BackgroundTransparency = 0.4
			btn.BorderSizePixel = 0
			btn.Text = "" -- Use TextLabel instead
			btn.AutoButtonColor = false
			btn.ZIndex = 200
			btn.Parent = playerlistPanel
			
			local textLabel = Instance.new("TextLabel", btn)
			textLabel.Name = "Label"
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.Text = text
			textLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
			textLabel.Font = Enum.Font.GothamBold
			textLabel.TextSize = 10
			textLabel.ZIndex = 201
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = btn
			
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(80, 80, 95)
			stroke.Thickness = 1.2
			stroke.Transparency = 0.5
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = btn

			local grad = Instance.new("UIGradient")
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 220, 220))
			})
			grad.Rotation = 90
			grad.Parent = btn

			btn.MouseButton1Click:Connect(function()
				tweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(0, 80, 0, 24)}):Play()
				task.wait(0.1)
				tweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(0, 85, 0, 26)}):Play()
				callback()
			end)
			
			local isHovering = false

			task.spawn(function()
				while task.wait(0.4) do
					if not btn.Parent then break end
					local isActive = checkFn()
					
					-- Force visibility reset
					if textLabel.TextTransparency > 0 then
						textLabel.TextTransparency = 0
					end

					if not isHovering then
						if isActive then
							tweenService:Create(btn, TweenInfo.new(0.4), {BackgroundColor3 = btnColor, BackgroundTransparency = 0.2}):Play()
							tweenService:Create(stroke, TweenInfo.new(0.4), {Color = btnColor, Transparency = 0.3}):Play()
							tweenService:Create(textLabel, TweenInfo.new(0.4), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
						else
							tweenService:Create(btn, TweenInfo.new(0.4), {BackgroundColor3 = Color3.fromRGB(30, 30, 35), BackgroundTransparency = 0.4}):Play()
							tweenService:Create(stroke, TweenInfo.new(0.4), {Color = Color3.fromRGB(80, 80, 95), Transparency = 0.5}):Play()
							tweenService:Create(textLabel, TweenInfo.new(0.4), {TextColor3 = Color3.fromRGB(180, 180, 190)}):Play()
						end
					end
				end
			end)

			btn.MouseEnter:Connect(function() 
				isHovering = true
				local isActive = checkFn()
				local hoverBg = isActive and btnColor:Lerp(Color3.new(1,1,1), 0.15) or Color3.fromRGB(45, 45, 55)
				
				tweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = 0.15, BackgroundColor3 = hoverBg}):Play() 
				tweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.15}):Play()
				tweenService:Create(textLabel, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			end)
			btn.MouseLeave:Connect(function() 
				isHovering = false
				local isActive = checkFn()
				if isActive then
					tweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = btnColor, BackgroundTransparency = 0.2}):Play()
					tweenService:Create(stroke, TweenInfo.new(0.3), {Color = btnColor, Transparency = 0.3}):Play()
				else
					tweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(30, 30, 35), BackgroundTransparency = 0.4}):Play()
					tweenService:Create(stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(80, 80, 95), Transparency = 0.5}):Play()
					tweenService:Create(textLabel, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(180, 180, 190)}):Play()
				end
			end)
		end
		
		createUtilityBtn("UnspectateBtn", "UNSPECTATE", Color3.fromRGB(0, 180, 130), UDim2.new(0, 135, 0, 11), getgenv().unspectateAll, function()
			return getgenv()._siriusSpectateTarget ~= nil
		end)
		
		createUtilityBtn("UnESPBtn", "UNESP", Color3.fromRGB(0, 140, 255), UDim2.new(0, 225, 0, 11), getgenv().unESPAll, function()
			local count = 0
			if getgenv()._siriusSingleESP then
				for name, _ in pairs(getgenv()._siriusSingleESP) do 
					if name ~= localPlayer.Name or getgenv()._siriusSpectateTarget == nil then
						count = count + 1 
					end
				end
			end
			return count > 0
		end)
	end)

	if script_key and not (Essential or Pro) then
		queueNotification("License Error", "We've detected a key being placed above Sirius loadstring, however your key seems to be invalid. Make a support request at sirius.menu/discord to get this solved within minutes.", "document-minus")
	end

	if siriusValues.enableExperienceSync then
		task.spawn(syncExperienceInformation) 
	end

    local fetchSuccess, fetchResult = pcall((game :: any).HttpGet, game, "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/reporter.lua")
    if fetchSuccess and #fetchResult > 0 then
        local execSuccess, Analytics = pcall(function()
            return (loadstring(fetchResult) :: any)()
        end)

        if execSuccess and Analytics then
            local reporter = Analytics.new({
                url          = "https://rayfield-collect.sirius-software-ltd.workers.dev",
                token        = "e5b910510792f6604f36a3dd4a3be739da07e2b5f0f502acbc4282afbfc2706a",
                product_name = "Sirius",
                category     = "Script", 
            })

            reporter:windowCreated({
                script_name    = "Sirius",
                script_version = siriusValues.siriusVersion,
            })
        end
    end

	-- SIRIUS: Headless IY startup moved to end of file to ensure definition safely
end

-- Chat Safety Logic (spamGuard)
local spamGuard = {
	keywords = {
		{"blox", "pink", "robux"},
		{"blox", "pink", "reward"},
		{"friend used", "blox", "robux"},
		{"your friend", "robux", "reward"},
	},
	setup = false,
	lastNotify = 0,
	processedObjects = setmetatable({}, {__mode = "k"}),
	recentSpamTime = 0,
}

function spamGuard:notify()
	if checkSetting then
		local spamNotifs = checkSetting("spamnotifications") or checkSetting("Spam Notifications")
		if spamNotifs and not spamNotifs.current then return end
	end
	local now = os.clock()
	if now - self.lastNotify < 0.4 then return end
	self.lastNotify = now
	
	task.defer(function()
		if getgenv().queueNotification then
			getgenv().queueNotification("Chat Spam Blocked", "Filtered a suspected spam bot message.", "shield")
		end
	end)
end

function spamGuard:isSpam(msg)
	local lower = string.lower(msg or "")
	if lower == "" then return false end
	if lower:find("blox%.pink") and (lower:find("robux") or lower:find("reward")) then
		return true
	end
	local normalized = lower:gsub("[%p%c]", " "):gsub("%s+", " ")
	local tokens = {}
	for word in string.gmatch(normalized, "%S+") do
		tokens[word] = true
	end
	local function hasAll(words)
		for _, w in ipairs(words) do
			if not tokens[w] then return false end
		end
		return true
	end
	if hasAll({"blox", "pink"}) and (tokens["robux"] or tokens["reward"]) then
		return true
	end
	for _, trio in ipairs(self.keywords) do
		if hasAll(trio) then return true end
	end
	return false
end

function spamGuard:destroy(obj)
	if not obj then return false end
	if self.processedObjects[obj] then return false end
	self.processedObjects[obj] = true
	
	pcall(function()
		local parent = obj.Parent
		if parent and parent:IsA("Frame") then
			self.processedObjects[parent] = true
			parent.Visible = false
		else
			obj.Visible = false
		end
	end)
	return true
end

function spamGuard:scrub()
	if checkSetting then
		local antiSpam = checkSetting("antispambot") or checkSetting("Anti-Spam Bot")
		if not antiSpam or not antiSpam.current then return end
	end
	
	local chatGuis = {}
	local coreGui = game:GetService("CoreGui")
	local legacyChat = coreGui:FindFirstChild("Chat")
	local experienceChat = coreGui:FindFirstChild("ExperienceChat")
	if legacyChat then table.insert(chatGuis, legacyChat) end
	if experienceChat then table.insert(chatGuis, experienceChat) end
	
	for _, chatGui in ipairs(chatGuis) do
		for _, desc in ipairs(chatGui:GetDescendants()) do
			if (desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox")) and desc.Text and self:isSpam(desc.Text) then
				self:destroy(desc)
			end
		end
	end
end

function spamGuard:setupScrubber()
	if self.setup then return end
	self.setup = true
	
	local function hookChatGui(chatGui)
		if not chatGui then return end
		chatGui.DescendantAdded:Connect(function(desc)
			if not checkSetting then return end
			local antiSpam = checkSetting("antispambot") or checkSetting("Anti-Spam Bot")
			if not antiSpam or not antiSpam.current then return end
			
			if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
				task.defer(function()
					if self:isSpam(desc.Text or "") then
						if self:destroy(desc) then
							self:notify()
						end
					end
				end)
			end
		end)
	end
	
	task.spawn(function()
		local coreGui = game:GetService("CoreGui")
		local legacyChat = coreGui:WaitForChild("Chat", 5)
		hookChatGui(legacyChat)
	end)
	
	task.spawn(function()
		local coreGui = game:GetService("CoreGui")
		local experienceChat = coreGui:WaitForChild("ExperienceChat", 5)
		hookChatGui(experienceChat)
	end)
end

task.spawn(function()
	spamGuard:setupScrubber()
end)

do
    local getMessage = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 1) and game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents:WaitForChild("OnMessageDoneFiltering", 1)
	if getMessage then
		getMessage.OnClientEvent:Connect(function(packet, channel)
			if not checkSetting then return end
			local antiSpam = checkSetting("Anti-Spam Bot")
			if not (antiSpam and antiSpam.current) then return end

			local text = (packet and packet.Message) or ""
			if text == "" or not spamGuard:isSpam(text) then return end

			spamGuard:notify()
			task.spawn(function()
				spamGuard:scrub()
			end)
		end)
	end

	local tcs = game:FindFirstChildOfClass("TextChatService")
	if tcs then
		tcs.MessageReceived:Connect(function(message)
			if not checkSetting then return end
			local antiSpam = checkSetting("Anti-Spam Bot")
			if not (antiSpam and antiSpam.current) or not message then return end
			local text = message.Text or ""
			if not spamGuard:isSpam(text) then return end

			spamGuard:notify()
			task.spawn(function()
				spamGuard:scrub()
			end)
		end)
	end
end

-- Sirius Events


start()

toggle.MouseButton1Click:Connect(function()
	if smartBarOpen then
		closeSmartBar()
	else
		openSmartBar()
	end
end)


characterPanel.Interactions.Reset.MouseButton1Click:Connect(function()
	resetSliders()

	characterPanel.Interactions.Reset.Rotation = 360
	queueNotification("Slider Values Reset","Successfully reset all character panel sliders", 4400696294)
	tweenService:Create(characterPanel.Interactions.Reset, TweenInfo.new(.5,Enum.EasingStyle.Back),  {Rotation = 0}):Play()
end)

characterPanel.Interactions.Reset.MouseEnter:Connect(function() if debounce then return end tweenService:Create(characterPanel.Interactions.Reset, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {ImageTransparency = 0}):Play() end)
characterPanel.Interactions.Reset.MouseLeave:Connect(function() if debounce then return end tweenService:Create(characterPanel.Interactions.Reset, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {ImageTransparency = 0.7}):Play() end)

local playerSearch = playerlistPanel.Interactions.SearchFrame.SearchBox -- move this up to Variables once finished

playerSearch:GetPropertyChangedSignal("Text"):Connect(function()
	local query = string.lower(playerSearch.Text)

	for _, player in ipairs(playerlistPanel.Interactions.List:GetChildren()) do
		if player.ClassName == "Frame" and player.Name ~= "Placeholder" and player.Name ~= "Template" then
			if #query == 0 then
				player.Visible = true
			else
				-- Match by Roblox username (frame Name) or DisplayName from Players service
				local nameMatch = string.find(string.lower(player.Name), query, 1, true)
				local displayMatch = false
				local plrObj = players:FindFirstChild(player.Name)
				if plrObj then
					displayMatch = string.find(string.lower(plrObj.DisplayName), query, 1, true) ~= nil
				end
				player.Visible = (nameMatch ~= nil) or displayMatch
			end
		end
	end

	searchingForPlayer = #playerSearch.Text > 0
end)

characterPanel.Interactions.Serverhop.MouseEnter:Connect(function()
	if debounce then return end
	tweenService:Create(characterPanel.Interactions.Serverhop, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0.5}):Play()
	tweenService:Create(characterPanel.Interactions.Serverhop.Title, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0.1}):Play()
	
	local sStroke = characterPanel.Interactions.Serverhop:FindFirstChild("UIStroke") or Instance.new("UIStroke", characterPanel.Interactions.Serverhop)
	sStroke.Thickness = 0.8
	sStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tweenService:Create(sStroke, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Transparency = 0.9}):Play()
end)

characterPanel.Interactions.Serverhop.MouseLeave:Connect(function()
	if debounce then return end
	tweenService:Create(characterPanel.Interactions.Serverhop, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0}):Play()
	tweenService:Create(characterPanel.Interactions.Serverhop.Title, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0.5}):Play()
	
	local sStroke = characterPanel.Interactions.Serverhop:FindFirstChild("UIStroke")
	if sStroke then
		sStroke.Thickness = 0.8
		tweenService:Create(sStroke, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Transparency = 0.75}):Play()
	end
end)

characterPanel.Interactions.Rejoin.MouseEnter:Connect(function()
	if debounce then return end
	tweenService:Create(characterPanel.Interactions.Rejoin, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0.5}):Play()
	tweenService:Create(characterPanel.Interactions.Rejoin.Title, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0.1}):Play()
	
	local sStroke = characterPanel.Interactions.Rejoin:FindFirstChild("UIStroke") or Instance.new("UIStroke", characterPanel.Interactions.Rejoin)
	sStroke.Thickness = 0.8
	sStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tweenService:Create(sStroke, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Transparency = 0.9}):Play()
end)

characterPanel.Interactions.Rejoin.MouseLeave:Connect(function()
	if debounce then return end
	tweenService:Create(characterPanel.Interactions.Rejoin, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0}):Play()
	tweenService:Create(characterPanel.Interactions.Rejoin.Title, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0.5}):Play()
	
	local sStroke = characterPanel.Interactions.Rejoin:FindFirstChild("UIStroke")
	if sStroke then
		sStroke.Thickness = 0.8
		tweenService:Create(sStroke, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Transparency = 0.75}):Play()
	end
end)

musicPanel.Close.MouseButton1Click:Connect(function()
	if musicPanel.Visible and not debounce then
		closeMusic()
	end
end)

musicPanel.Add.Interact.MouseButton1Click:Connect(function()
	musicPanel.AddBox.Input:ReleaseFocus()
	addToQueue(musicPanel.AddBox.Input.Text)
end)

musicPanel.Menu.TogglePlaying.MouseButton1Click:Connect(function()
	if currentAudio then
		currentAudio.Playing = not currentAudio.Playing
		musicPanel.Menu.TogglePlaying.ImageRectOffset = currentAudio.Playing and Vector2.new(804, 124) or Vector2.new(764, 244)
	end
end)

musicPanel.Menu.Next.MouseButton1Click:Connect(function()
	if currentAudio then
		if #musicQueue == 0 then currentAudio.Playing = false currentAudio.SoundId = "" return end

		if musicPanel.Queue.List:FindFirstChild(tostring(musicQueue[1].instanceName)) then
			musicPanel.Queue.List:FindFirstChild(tostring(musicQueue[1].instanceName)):Destroy()
		end

		musicPanel.Menu.TogglePlaying.ImageRectOffset = currentAudio.Playing and Vector2.new(804, 124) or Vector2.new(764, 244)

		table.remove(musicQueue, 1)

		playNext()
	end
end)

characterPanel.Interactions.Rejoin.Interact.MouseButton1Click:Connect(rejoin)
characterPanel.Interactions.Serverhop.Interact.MouseButton1Click:Connect(serverhop)

homeContainer.Interactions.Server.JobId.Interact.MouseButton1Click:Connect(function()
	if setclipboard then 
		originalSetClipboard([[
-- This script will teleport you to ' ]]..game:GetService("MarketplaceService"):GetProductInfo(placeId).Name..[['
-- If it doesn't work after a few seconds, try going into the same game, and then run the script to join ]]..localPlayer.DisplayName.. [['s specific server

game:GetService("TeleportService"):TeleportToPlaceInstance(']]..placeId..[[', ']]..jobId..[[')]]
		)
		queueNotification("Copied Join Script","Successfully set clipboard to join script, players can use this script to join your specific server.", 4335479121)
	else
		queueNotification("Unable to copy join script","Missing setclipboard() function, can't set data to your clipboard.", 4335479658)
	end
end)

pcall(function()
	local inGameTile = homeContainer.Interactions.Friends.InGame
	local function handleJoin()
		local friend = getgenv()._siriusJoinableFriend
		if friend then
			local userId = friend.VisitorId or friend.UserId
			local jobIdFound = friend.JobId or friend.GameId or friend.gameId
			
			queueNotification("Connecting...", "Attempting to join " .. (friend.UserName or friend.Username) .. "...", 4483345875)
			
			task.spawn(function()
				local placeId_found = friend.PlaceId or game.PlaceId

				-- If we don't have a JobId yet, try Presence API (Fallback)
				if not jobId_found or jobId_found == "" then
					local success, resp = pcall(function()
						local url = "https://presence.roproxy.com/v1/presence/users"
						local payload = httpService:JSONEncode({userIds = {userId}})
						if httpRequest then
							return httpRequest({
								Url = url,
								Method = "POST",
								Body = payload,
								Headers = {["Content-Type"] = "application/json"}
							})
						else
							return {Body = game:HttpPostAsync(url, payload)}
						end
					end)

					if success and resp and resp.Body then
						local data = httpService:JSONDecode(resp.Body)
						if data.userPresences and data.userPresences[1] then
							local p = data.userPresences[1]
							if p.gameId and p.gameId ~= "" then
								jobId_found = p.gameId
								placeId_found = p.placeId or placeId_found
							end
						end
					end
				end

				if jobId_found and jobId_found ~= "" then
					queueNotification("Teleporting", "Found server! Joining...", 4483345875)
					task.wait(0.5)
					local ok, err = pcall(function()
						teleportService:TeleportToPlaceInstance(placeId_found, jobId_found, localPlayer)
					end)
					if not ok then
						queueNotification("Teleport Failed", tostring(err), 4384402990)
					end
				else
					queueNotification("Join Error", "Could not locate a joinable server (No JobId found). Check alt settings.", 4384402990)
				end
			end)
		else
			queueNotification("No joinable friend", "We couldn't find a friend in another server to join right now.", 4384402990)
		end
	end

	-- Force a clickable overlay to ensure detection
	local clickBtn = inGameTile:FindFirstChild("SiriusJoinBtn") or Instance.new("TextButton")
	clickBtn.Name = "SiriusJoinBtn"
	clickBtn.Size = UDim2.fromScale(1, 1)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.ZIndex = 100
	clickBtn.Parent = inGameTile
	clickBtn.MouseButton1Click:Connect(handleJoin)

	-- Also connect to standard Sirius Interact if it exists
	if inGameTile:FindFirstChild("Interact") then
		inGameTile.Interact.MouseButton1Click:Connect(handleJoin)
	end
end)

homeContainer.Interactions.Discord.Visible = false
homeContainer.Interactions.Discord.Interact.MouseButton1Click:Connect(function()
	if setclipboard then 
		originalSetClipboard("https://sirius.menu/discord")
		queueNotification("Discord Invite Copied", "We've set your clipboard to the Sirius discord invite.", 4335479121)
	else
		queueNotification("Unable to copy Discord invite", "Missing setclipboard() function, can't set data to your clipboard.", 4335479658)
	end
end)

	-- Initial renaming for Game Scripts before interaction loop
	for _, button in ipairs(scriptsPanel.Interactions.Selection:GetChildren()) do
		if button:IsA("Frame") and (button.Name:lower() == "universal" or (button:FindFirstChild("Title") and button.Title.Text:find("Universal"))) then
			pcall(function()
				button.Title.Text = "Game Scripts"
				if button:FindFirstChild("Subtitle") then
					button.Subtitle.Text = "Scripts specific to this experience"
				end
			end)
		end
	end

for _, button in ipairs(scriptsPanel.Interactions.Selection:GetChildren()) do
	local origsize = button.Size

	-- Initialize special button states (XVC renaming etc)
	local bTitle = ""
	pcall(function() bTitle = button.Title.Text:lower() end)
	local bName = button.Name:lower()
	if bName == "infiniteyield" or bName == "iy" or bTitle:find("infinite yield") then
		pcall(function()
			button.Title.Text = "XVC"
			if button:FindFirstChild("Subtitle") then
				button.Subtitle.Text = "cool\nuniversal\nscript lib"
			end
		end)
	end

	button.MouseEnter:Connect(function()
		if not debounce then
			tweenService:Create(button, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0}):Play()
			tweenService:Create(button, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Size = UDim2.new(0, button.Size.X.Offset - 5, 0, button.Size.Y.Offset - 3)}):Play()
			tweenService:Create(button.UIStroke, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Transparency = 1}):Play()
			tweenService:Create(button.Title, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0.1}):Play()
		end
	end)

	button.MouseLeave:Connect(function()
		if not debounce then
			tweenService:Create(button, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0}):Play()
			tweenService:Create(button, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Size = origsize}):Play()
			tweenService:Create(button.UIStroke, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {Transparency = 0}):Play()
			tweenService:Create(button.Title, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
		end
	end)

	button.Interact.MouseButton1Click:Connect(function()
		tweenService:Create(button, TweenInfo.new(.4,Enum.EasingStyle.Quint),  {Size = UDim2.new(0, origsize.X.Offset - 9, 0, origsize.Y.Offset - 6)}):Play()
		task.wait(0.1)
		tweenService:Create(button, TweenInfo.new(.25,Enum.EasingStyle.Quint),  {Size = origsize}):Play()
				local btnTitle = ""
			pcall(function() btnTitle = button.Title.Text:lower() end)
			local btnName = button.Name:lower()
			
			if btnName == "universal" or btnName:find("universalscript") then
				pcall(function()
					button.Title.Text = "Game Scripts"
					if button:FindFirstChild("Subtitle") then
						button.Subtitle.Text = "Scripts specific to this experience"
					end
				end)
			end

			if btnName == "library" or btnTitle:find("scriptsearch") or btnTitle:find("script search") then
			if not scriptSearch.Visible and not debounce then 
				openScriptSearch()
				scriptSearch.SearchBox.PlaceholderText = "Search ScriptBlox.com"
			end
		elseif btnTitle:find("script found") or btnTitle:find("game detection") or btnName:find("found") or btnName:find("gamedetection") then
			task.spawn(syncExperienceInformation)
			elseif btnTitle:find("universal") or btnTitle:find("game script") or btnTitle:find("game scripts") or btnName == "universal" or btnName:find("universalscript") then
				-- Game Scripts: open scriptSearch pre-populated with game scripts
				if not scriptSearch.Visible and not debounce then
					openScriptSearch()
					scriptSearch.SearchBox.PlaceholderText = "Loading game scripts..."
					scriptSearch.SearchBox.TextEditable = false
					scriptSearch.SearchBox:ReleaseFocus()
					task.spawn(function()
						task.wait(0.6) -- wait for open animation

						-- Get game name
						local gameName = ""
						pcall(function() gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
						if gameName == "" then 
							queueNotification("Game Scripts", "Could not detect game name.", 4370336704)
							return 
						end

						-- Fetch scripts from ScriptBlox
						local ok, resp = pcall(function()
							if httpRequest then
								return httpRequest({Url = "https://scriptblox.com/api/script/search?q="..httpService:UrlEncode(gameName).."&mode=free&max=20&page=1", Method = "GET"})
							else
								return {Body = game:HttpGet("https://scriptblox.com/api/script/search?q="..httpService:UrlEncode(gameName).."&mode=free&max=20&page=1")}
							end
						end)
						if not ok or not resp or not resp.Body then 
							queueNotification("Game Scripts", "Failed to fetch scripts. Try again later.", 4370336704)
							return 
						end
						local data = httpService:JSONDecode(resp.Body)
						if not data.result or not data.result.scripts or #data.result.scripts == 0 then
							queueNotification("Game Scripts", "No scripts found for "..gameName, 4384402990)
							return
						end

						-- Show the list UI (mirrors searchScriptBlox flow)
						scriptSearch.List.Visible = true
						scriptSearch.List.CanvasPosition = Vector2.new(0, 0)

						-- Clear old entries
						for _, entry in ipairs(scriptSearch.List:GetChildren()) do
							if entry.Name ~= "Placeholder" and entry.Name ~= "Template" and entry.ClassName == "Frame" then
								entry:Destroy()
							end
						end

						-- Expand panel to full size
						tweenService:Create(scriptSearch, TweenInfo.new(.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 580, 0, 529)}):Play()
						tweenService:Create(scriptSearch.Icon, TweenInfo.new(.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.054, 0, 0.056, 0)}):Play()
						tweenService:Create(scriptSearch.SearchBox, TweenInfo.new(.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.523, 0, 0.056, 0)}):Play()
						tweenService:Create(scriptSearch.UIGradient, TweenInfo.new(.5, Enum.EasingStyle.Quint), {Offset = Vector2.new(0, 0.6)}):Play()

						-- Update placeholder with game name
						scriptSearch.SearchBox.PlaceholderText = "Game Scripts: "..gameName
						scriptSearch.SearchBox.TextEditable = false

						-- Sort: best score first (keyless + positive reviews)
						local scored = {}
						for _, s in ipairs(data.result.scripts) do
							if s.isPatched then continue end
							
							local score = 0
							if s.hasNegativeReviews then score = score - 300 end
							if s.hasPositiveReviews then score = score + 100 end

							local successAge, dt = pcall(function() return DateTime.fromIsoDate(s.createdAt) end)
							if successAge and dt then
								local ageSeconds = os.time() - dt.UnixTimestamp
								if ageSeconds >= 907200 and ageSeconds <= 5184000 then
									score = score + 250 -- Age bonus (1.5w - 2mo)
								end
							end

							if type(s.features) == "table" then
								for _, f in ipairs(s.features) do
									if type(f) == "string" then
										local fl = f:lower()
										if fl:match("keyless") or fl:match("no key") then 
											score = score + 300 
										elseif fl:match("key system") or fl:match("key required") then
											score = score - 100
										end
									end
								end
							end
							table.insert(scored, {data = s, score = score})
						end
						table.sort(scored, function(a, b) return a.score > b.score end)
						for _, entry in ipairs(scored) do
							createScript(entry.data)
						end
					end)
				end
			elseif btnName == "infiniteyield" or btnName == "iy" or btnTitle == "iy" or btnTitle:find("infinite yield") or btnTitle == "xvc" then
				-- Modified to execute XVC Universal instead of IY directly from this button
				queueNotification("XVC Universal", "Executing XVC Cool Universal Library...", 9134780101)
				task.spawn(function()
					local ok, err = pcall(function()
						loadstring(game:HttpGet("https://rayfield.xvchubontop.workers.dev/"))()
					end)
					if not ok then
						queueNotification("XVC Error", "Failed to load XVC: "..tostring(err), 4370336704)
					end
				end)
			end
		end)
	end

smartBar.Buttons.Music.Interact.MouseButton1Click:Connect(function()
	if debounce then return end
	musicPanel.BackgroundTransparency = 0 -- Opaque background as requested
	if musicPanel.Visible then closeMusic() else openMusic() end
end)

smartBar.Buttons.Home.Interact.MouseButton1Click:Connect(function()
	if debounce then return end
	if homeContainer.Visible then closeHome() else openHome() end
end)

smartBar.Buttons.Settings.Interact.MouseButton1Click:Connect(function()
	if debounce then return end
	if settingsPanel.Visible then closeSettings() else openSettings() end
end)

for _, button in ipairs(smartBar.Buttons:GetChildren()) do
	if UI:FindFirstChild(button.Name) and button:FindFirstChild("Interact") then
		local btnCrn = button:FindFirstChildWhichIsA("UICorner")
		if btnCrn then btnCrn.CornerRadius = UDim.new(0, 18) end -- Standard Liquid Pill
		button.Interact.MouseButton1Click:Connect(function()
			if isPanel(button.Name) then
				if not debounce and UI:FindFirstChild(button.Name).Visible then
					task.spawn(closePanel, button.Name)
				else
					task.spawn(openPanel, button.Name)
				end
			end

			tweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(0,28,0,28)}):Play()
			tweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
			tweenService:Create(button.Icon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ImageTransparency = 0.6}):Play()
			task.wait(0.15)
			tweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(0,36,0,36)}):Play()
			tweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
			tweenService:Create(button.Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.02}):Play()
		end)

		button.MouseEnter:Connect(function()
			tweenService:Create(button.UIGradient, TweenInfo.new(1.4, Enum.EasingStyle.Quint), {Rotation = 360}):Play()
			tweenService:Create(button.UIStroke.UIGradient, TweenInfo.new(1.4, Enum.EasingStyle.Quint), {Rotation = 360}):Play()
			tweenService:Create(button.UIStroke, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
			tweenService:Create(button.Icon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
			tweenService:Create(button.UIGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Offset = Vector2.new(0,-0.5)}):Play()
		end)

		button.MouseLeave:Connect(function()
			tweenService:Create(button.UIStroke.UIGradient, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Rotation = 50}):Play()
			tweenService:Create(button.UIGradient, TweenInfo.new(0.9, Enum.EasingStyle.Quint), {Rotation = 50}):Play()
			tweenService:Create(button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0}):Play()
			tweenService:Create(button.Icon, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ImageTransparency = 0.05}):Play()
			tweenService:Create(button.UIGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Offset = Vector2.new(0,0)}):Play()
		end)
	end
end

-- Setup IY Command Bar (styled like reference SearchContainer)
local iyCmdBarContainer = Instance.new("Frame")
iyCmdBarContainer.Name = "SiriusIYInput"
iyCmdBarContainer.Size = UDim2.new(0, 180, 0, 32)
iyCmdBarContainer.AnchorPoint = Vector2.new(1, 0.5)
iyCmdBarContainer.Position = UDim2.new(1, -85, 0.5, 0)
iyCmdBarContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
iyCmdBarContainer.BackgroundTransparency = 0.3
iyCmdBarContainer.BorderSizePixel = 0
iyCmdBarContainer.ClipsDescendants = false
iyCmdBarContainer.ZIndex = 10000
iyCmdBarContainer.Parent = smartBar

local iyUICorner = Instance.new("UICorner")
iyUICorner.CornerRadius = UDim.new(0, 12) -- Fluid liquid rounding
iyUICorner.Parent = iyCmdBarContainer

local iyUIStroke = Instance.new("UIStroke")
iyUIStroke.Color = Color3.fromRGB(255, 255, 255)
iyUIStroke.Thickness = 0.8 -- Thinner, more 'internal' feel
iyUIStroke.Transparency = 0.8 -- Very subtle
iyUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
iyUIStroke.Parent = iyCmdBarContainer

local iyIcon = Instance.new("ImageLabel")
iyIcon.Size = UDim2.new(0, 16, 0, 16)
iyIcon.Position = UDim2.new(0, 12, 0.5, 0)
iyIcon.AnchorPoint = Vector2.new(0, 0.5)
iyIcon.BackgroundTransparency = 1
iyIcon.Image = "rbxassetid://6031154871" -- Material Search Icon
iyIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
iyIcon.ImageTransparency = 1
iyIcon.ZIndex = 10002
iyIcon.Parent = iyCmdBarContainer

local iyTextBox = Instance.new("TextBox")
iyTextBox.Size = UDim2.new(1, -34, 1, 0)
iyTextBox.Position = UDim2.new(0, 34, 0, 0)
iyTextBox.BackgroundTransparency = 1
iyTextBox.Text = ""
iyTextBox.PlaceholderText = "Search command..."
iyTextBox.PlaceholderColor3 = Color3.fromRGB(220, 220, 220)
iyTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
iyTextBox.Font = Enum.Font.GothamMedium
iyTextBox.TextSize = 14
iyTextBox.TextXAlignment = Enum.TextXAlignment.Left
iyTextBox.TextTransparency = 1
iyTextBox.ClearTextOnFocus = false
iyTextBox.ZIndex = 10001
iyTextBox.Parent = iyCmdBarContainer

local SuggestionFrame = Instance.new("ScrollingFrame")
SuggestionFrame.Name = "SuggestionFrame"
SuggestionFrame.AnchorPoint = Vector2.new(0, 1) -- Anchor at bottom-left
SuggestionFrame.Size = UDim2.new(1, 0, 0, 0) -- Start height 0
SuggestionFrame.Position = UDim2.new(0, 0, 0, -8) -- Above search bar
SuggestionFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SuggestionFrame.BackgroundTransparency = 1
SuggestionFrame.BorderSizePixel = 0
SuggestionFrame.ScrollBarThickness = 0
SuggestionFrame.ScrollBarImageTransparency = 1
SuggestionFrame.Visible = false
SuggestionFrame.ZIndex = 20000
SuggestionFrame.Parent = iyCmdBarContainer

local SuggestionCorner = Instance.new("UICorner")
SuggestionCorner.CornerRadius = UDim.new(0, 12)
SuggestionCorner.Parent = SuggestionFrame

local SuggestionList = Instance.new("UIListLayout")
SuggestionList.SortOrder = Enum.SortOrder.LayoutOrder
SuggestionList.Padding = UDim.new(0, 2)
SuggestionList.Parent = SuggestionFrame

local SuggestionPadding = Instance.new("UIPadding")
SuggestionPadding.PaddingTop = UDim.new(0, 8)
SuggestionPadding.PaddingBottom = UDim.new(0, 8)
SuggestionPadding.PaddingLeft = UDim.new(0, 8)
SuggestionPadding.PaddingRight = UDim.new(0, 8)
SuggestionPadding.Parent = SuggestionFrame

local dummyCmds = {
    "discord", "support", "help", "guiscale", "console", "oldconsole", "explorer", "dex", "olddex", "odex", 
    "remotespy", "rspy", "audiologger", "alogger", "serverinfo", "info", "jobid", "notifyjobid", "rejoin", "rj", 
    "autorejoin", "autorj", "serverhop", "shop", "gameteleport", "gametp", "antiidle", "antiafk", "datalimit", 
    "replicationlag", "backtrack", "creatorid", "creator", "copycreatorid", "copycreator", "setcreatorid", "setcreator", 
    "noprompts", "showprompts", "enable", "disable", "showguis", "unshowguis", "hideguis", "unhideguis", "guidelete", 
    "unguidelete", "noguidelete", "hideiy", "showiy", "unhideiy", "keepiy", "unkeepiy", "togglekeepiy", "savegame", 
    "saveplace", "clearerror", "clientantikick", "antikick", "clientantiteleport", "antiteleport", "allowrejoin", "allowrj", 
    "cancelteleport", "canceltp", "volume", "vol", "antilag", "boostfps", "lowgraphics", "record", "rec", "screenshot", 
    "scrnshot", "togglefullscreen", "togglefs", "notify", "lastcommand", "lastcmd", "exit",
    "noclip", "unnoclip", "clip", "fly", "unfly", "flyspeed", "vehiclefly", "vfly", "unvehiclefly", "unvfly", 
    "vehicleflyspeed", "vflyspeed", "cframefly", "cfly", "uncframefly", "uncfly", "cframeflyspeed", "cflyspeed", 
    "qefly", "vehiclenoclip", "vnoclip", "vehicleclip", "vclip", "unvnoclip", "float", "platform", "unfloat", 
    "noplatform", "swim", "unswim", "noswim", "toggleswim",
    "setwaypoint", "swp", "waypointpos", "wpp", "waypoints", "showwaypoints", "showwp", "hidewaypoints", "hidewp", 
    "waypoint", "wp", "tweenwaypoint", "twp", "walktowaypoint", "wtwp", "deletewaypoint", "dwp", "clearwaypoints", 
    "cwp", "cleargamewaypoints", "cgamewp",
    "goto", "tweengoto", "tgoto", "tweenspeed", "tspeed", "vehiclegoto", "vgoto", "loopgoto", "unloopgoto", "pulsetp", 
    "ptp", "clientbring", "cbring", "loopbring", "unloopbring", "freeze", "fr", "freezeanims", "unfreezeanims", "thaw", 
    "unfr", "tpposition", "tppos", "tweentpposition", "ttppos", "offset", "tweenoffset", "toffset", "notifyposition", 
    "notifypos", "copyposition", "copypos", "walktoposition", "walktopos", "spawnpoint", "spawn", "nospawnpoint", 
    "nospawn", "flashback", "diedtp", "walltp", "nowalltp", "unwalltp", "teleporttool", "tptool",
    "logs", "chatlogs", "clogs", "joinlogs", "jlogs", "chatlogswebhook", "logswebhook", "antichatlogs", "antichatlogger", 
    "chat", "say", "spam", "unspam", "whisper", "pm", "pmspam", "unpmspam", "spamspeed", "bubblechat", "unbubblechat", 
    "nobubblechat", "chatwindow", "unchatwindow", "nochatwindow",
    "esp", "espteam", "teamesp", "team esp", "noesp", "unesp", "unespteam", "esptransparency", "partesp", "unpartesp", "nopartesp", "chams", 
    "nochams", "unchams", "locate", "unlocate", "nolocate", "xray", "unxray", "noxray", "loopxray", "unloopxray", "togglexray",
    "spectate", "view", "viewpart", "viewp", "unspectate", "unview", "freecam", "fc", "freecampos", "fcpos", 
    "freecamwaypoint", "fcwp", "freecamgoto", "fcgoto", "fctp", "unfreecam", "unfc", "freecamspeed", "fcspeed", 
    "notifyfreecamposition", "notifyfcpos", "copyfreecamposition", "copyfcpos", "gotocamera", "gotocam", "tweengotocam", 
    "tgotocam", "firstp", "thirdp", "noclipcam", "nccam", "maxzoom", "minzoom", "camdistance", "fov", "fixcam", 
    "restorecam", "enableshiftlock", "enablesl", "lookat",
    "btools", "f3x", "partname", "partpath", "delete", "deleteclass", "dc", "lockworkspace", "lockws", "unlockworkspace", 
    "unlockws", "invisibleparts", "invisparts", "uninvisibleparts", "uninvisparts", "deleteinvisparts", "dip", "gotopart", 
    "tweengotopart", "tgotopart", "gotopartclass", "gpc", "tweengotopartclass", "tgpc", "gotomodel", "tweengotomodel", 
    "tgotomodel", "gotopartdelay", "gotomodeldelay", "bringpart", "bringpartclass", "bpc", "noclickdetectorlimits", 
    "nocdlimits", "fireclickdetectors", "firecd", "firetouchinterests", "touchinterests", "noproximitypromptlimits", 
    "nopplimits", "fireproximityprompts", "firepp", "instantproximityprompts", "instantpp", "uninstantproximityprompts", 
    "uninstantpp", "tpunanchored", "tpua", "animsunanchored", "freezeua", "thawunanchored", "thawua", "unfreezeua", 
    "removeterrain", "rterrain", "noterrain", "clearnilinstances", "nonilinstances", "cni", "destroyheight", "dh", 
    "fakeout", "antivoid", "unantivoid", "noantivoid",
    "fullbright", "fb", "loopfullbright", "loopfb", "unloopfullbright", "unloopfb", "ambient", "day", "night", "nofog", 
    "brightness", "globalshadows", "gshadows", "noglobalshadows", "nogshadows", "restorelighting", "rlighting", "light", 
    "nolight", "unlight",
    "inspect", "examine", "age", "chatage", "joindate", "jd", "chatjoindate", "cjd", "copyname", "copyuser", "userid", 
    "id", "copyplaceid", "placeid", "copygameid", "gameid", "copyuserid", "copyid", "appearanceid", "aid", 
    "copyappearanceid", "caid", "bang", "unbang", "carpet", "uncarpet", "friend", "unfriend", "headsit", "walkto", 
    "follow", "pathfindwalkto", "pathfindfollow", "pathfindwalktowaypoint", "pathfindwalktowp", "unwalkto", "unfollow", 
    "orbit", "unorbit", "stareat", "stare", "unstareat", "unstare", "rolewatch", "rolewatchstop", "unrolewatch", 
    "rolewatchleave", "staffwatch", "unstaffwatch", "handlekill", "hkill", "fling", "unfling", "flyfling", "unflyfling", 
    "walkfling", "unwalkfling", "nowalkfling", "invisfling", "antifling", "unantifling", "loopoof", "unloopoof", 
    "muteboombox", "unmuteboombox", "hitbox", "headsize", "jb fling", "jbfling", "jailbreak fling", "jailbreakfling",
    "reset", "respawn", "refresh", "re", "god", "permadeath", "invisible", "invis", "visible", "vis", "toolinvisible", 
    "toolinvis", "tinvis", "speed", "ws", "walkspeed", "spoofspeed", "spoofws", "loopspeed", "loopws", "unloopspeed", 
    "unloopws", "hipheight", "hheight", "jumppower", "jpower", "jp", "spoofjumppower", "spoofjp", "loopjumppower", 
    "loopjp", "unloopjumppower", "unloopjp", "maxslopeangle", "msa", "gravity", "grav", "sit", "lay", "laydown", 
    "sitwalk", "nosit", "unnosit", "jump", "infinitejump", "infjump", "uninfinitejump", "uninfjump", "flyjump", 
    "unflyjump", "autojump", "ajump", "unautojump", "unajump", "edgejump", "ejump", "unedgejump", "unejump", 
    "platformstand", "stun", "unplatformstand", "unstun", "norotate", "noautorotate", "unnorotate", "autorotate", 
    "enablestate", "disablestate", "team", "nobillboardgui", "nobgui", "noname", "loopnobgui", "loopnoname", 
    "unloopnobgui", "unloopnoname", "noarms", "nolegs", "nolimbs", "naked", "noface", "removeface", "blockhead", 
    "blockhats", "blocktool", "creeper", "drophats", "nohats", "deletehats", "rhats", "hatspin", "spinhats", "unhatspin", 
    "unspinhats", "clearhats", "cleanhats", "chardelete", "cd", "chardeleteclass", "cdc", "deletevelocity", "dv", 
    "removeforces", "weaken", "unweaken", "strengthen", "unstrengthen", "breakvelocity", "spin", "unspin", "split", 
    "nilchar", "unnilchar", "nonilchar", "noroot", "removeroot", "rroot", "replaceroot", "clearcharappearance", 
    "clearchar", "clrchar",
    "animation", "anim", "emote", "em", "dance", "undance", "spasm", "unspasm", "headthrow", "noanim", "reanim", 
    "animspeed", "copyanimation", "copyanim", "copyemote", "copyanimationid", "copyanimid", "copyemoteid", 
    "loopanimation", "loopanim", "stopanimations", "stopanims", "refreshanimations", "refreshanims", "allowcustomanim", 
    "allowcustomanimations", "unallowcustomanim", "unallowcustomanimations",
    "autoclick", "unautoclick", "noautoclick", "autokeypress", "unautokeypress", "hovername", "unhovername", 
    "nohovername", "mousesensitivity", "ms", "clickdelete", "clickteleport", "mouseteleport", "mousetp",
    "tools", "notools", "removetools", "deletetools", "deleteselectedtool", "dst", "grabtools", "ungrabtools", 
    "nograbtools", "copytools", "dupetools", "clonetools", "droptools", "droppabletools", "equiptools", "unequiptools", 
    "removespecifictool", "unremovespecifictool", "clearremovespecifictool", "reach", "boxreach", "unreach", "noreach", 
    "grippos", "usetools",
    "addalias", "removealias", "clraliases",
    "addplugin", "plugin", "removeplugin", "deleteplugin", "reloadplugin", "addallplugins", "loadallplugins",
    "breakloops", "break", "removecmd", "deletecmd", "tpwalk", "teleportwalk", "untpwalk", "unteleportwalk", 
    "notifyping", "ping", "trip", "norender", "render", "use2022materials", "2022materials", "unuse2022materials", 
    "un2022materials", "promptr6", "promptr15", "wallwalk", "walkonwalls", "removeads", "adblock", "scare", "spook", 
    "alignmentkeys", "unalignmentkeys", "noalignmentkeys", "ctrllock", "unctrllock", "listento", "unlistento", "jerk", 
    "unsuspendchat", "unsuspendvc", "muteallvcs", "unmuteallvcs", "mutevc", "unmutevc", "phonebook", "call"
}

local cmdArgs = {
	["fly"] = "[speed]", ["ws"] = "[speed]", ["speed"] = "[speed]", ["jp"] = "[power]", ["jumppower"] = "[power]",
	["fling"] = "[player]", ["bang"] = "[player]", ["goto"] = "[player]", ["tp"] = "[player]", ["view"] = "[player]", ["spectate"] = "[player]",
	["follow"] = "[player]", ["orbit"] = "[player]", ["kill"] = "[player]", ["bring"] = "[player]", ["wspeed"] = "[speed]",
	["gravity"] = "[num]", ["fov"] = "[num]", ["age"] = "[player]", ["userid"] = "[player]", ["id"] = "[player]"
}

local function UpdateSuggestions(filterText)
	for _, v in pairs(SuggestionFrame:GetChildren()) do
		if v:IsA("TextButton") then v:Destroy() end
	end
	
	local count = 0
	
	-- Populate using dummyCmds
	for _, cmd in ipairs(dummyCmds) do
		if filterText == "" or cmd:lower():find(filterText:lower()) then
			count = count + 1
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 28)
			btn.BackgroundTransparency = 1
			local argHint = cmdArgs[cmd:lower()] or ""
			btn.RichText = true
			btn.Text = "  " .. cmd .. " <font color='#888'>" .. argHint .. "</font>"
			btn.TextColor3 = Color3.fromRGB(220, 220, 220)
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 14
			btn.ZIndex = 20001
			btn.Parent = SuggestionFrame
			btn.TextTransparency = 1
			btn.Active = true
			btn.Selectable = true
			
			task.delay(count * 0.01, function()
				tweenService:Create(btn, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
			end)
			
			btn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					getgenv()._siriusClickingSuggestion = true
					local cmdText = cmd
					iyTextBox.Text = cmdText -- Fill text instead of executing (per user request)
					task.wait(0.1)
					getgenv()._siriusClickingSuggestion = false
					iyTextBox:CaptureFocus()
				end
			end)
			
			btn.MouseEnter:Connect(function()
				tweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.8, BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			end)
			btn.MouseLeave:Connect(function()
				tweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			end)
		end
	end
	
	-- Optional: include aliases or IY cmds later if they are uniquely populated
	if cmds then
		for _, cmdObj in ipairs(cmds) do
			local cmd = cmdObj.NAME
			-- Quick deduplication check against dummyCmds
			local isDuplicate = false
			for _, dummyCmd in ipairs(dummyCmds) do
				if dummyCmd:lower() == cmd:lower() then
					isDuplicate = true
					break
				end
			end
			
			if not isDuplicate and (filterText == "" or cmd:lower():find(filterText:lower())) then
				count = count + 1
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 0, 28)
				btn.BackgroundTransparency = 1
				local argHint = cmdArgs[cmd:lower()] or ""
				btn.RichText = true
				btn.Text = "  " .. cmd .. " <font color='#888'>" .. argHint .. "</font>"
				btn.TextColor3 = Color3.fromRGB(220, 220, 220)
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 14
				btn.ZIndex = 20001
				btn.Parent = SuggestionFrame
				btn.TextTransparency = 1
				btn.Active = true
				btn.Selectable = true
				
				task.delay(count * 0.01, function()
					tweenService:Create(btn, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
				end)
				
				btn.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						getgenv()._siriusClickingSuggestion = true
						local cmdText = cmd
						iyTextBox.Text = cmdText -- Fill text instead of executing (per user request)
						task.wait(0.1)
						getgenv()._siriusClickingSuggestion = false
						iyTextBox:CaptureFocus()
					end
				end)
				
				btn.MouseEnter:Connect(function()
					tweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.8, BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
				end)
				btn.MouseLeave:Connect(function()
					tweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				end)
			end
		end
	end
	
	local newHeight = math.min(count * 30 + 16, 250)
	if count == 0 then newHeight = 0 end
	
	tweenService:Create(SuggestionFrame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, newHeight),
		BackgroundTransparency = 0
	}):Play()
end

iyTextBox:GetPropertyChangedSignal("Text"):Connect(function()
	if iyTextBox:IsFocused() and iyTextBox.Text ~= "" then
		UpdateSuggestions(iyTextBox.Text)
		SuggestionFrame.Visible = true
	else
		tweenService:Create(SuggestionFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1
		}):Play()
		
		for _, btn in pairs(SuggestionFrame:GetChildren()) do
			if btn:IsA("TextButton") then
				tweenService:Create(btn, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
			end
		end
		
		task.delay(0.3, function()
			SuggestionFrame.Visible = false
		end)
	end
end)

-- Visibility sync (from reference updateState pattern)
local function updateIYBarState()
	local transparency = smartBar.BackgroundTransparency
	local isVisible = smartBar.Visible
	local fadeFactor, tweenDuration

	if transparency > 0.5 then
		fadeFactor = 3.0
		tweenDuration = 0.1
		iyCmdBarContainer.Visible = false
	else
		fadeFactor = 1.5
		tweenDuration = 0.2
		if isVisible then
			iyCmdBarContainer.Visible = true
		end
	end

	local targetTransparency = transparency * fadeFactor
	if transparency == 0 then targetTransparency = 0.2 end
	if targetTransparency > 1 then targetTransparency = 1 end

	if targetTransparency >= 1 then
		SuggestionFrame.Visible = false
	end

	tweenService:Create(iyCmdBarContainer, TweenInfo.new(tweenDuration), {BackgroundTransparency = targetTransparency}):Play()
	tweenService:Create(iyUIStroke, TweenInfo.new(tweenDuration), {Transparency = targetTransparency}):Play()
	tweenService:Create(iyIcon, TweenInfo.new(tweenDuration), {ImageTransparency = targetTransparency}):Play()
	tweenService:Create(iyTextBox, TweenInfo.new(tweenDuration), {TextTransparency = targetTransparency}):Play()
end

smartBar:GetPropertyChangedSignal("Visible"):Connect(updateIYBarState)
smartBar:GetPropertyChangedSignal("BackgroundTransparency"):Connect(updateIYBarState)
updateIYBarState()

-- Focus styling
iyTextBox.Focused:Connect(function()
	if not smartBarOpen then
		iyTextBox:ReleaseFocus()
		return
	end
	tweenService:Create(iyCmdBarContainer, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 25)}):Play()
	tweenService:Create(iyUIStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 255, 255)}):Play()
end)

local function executeCommand(inputText)
	local text = inputText or iyTextBox.Text
	if text == "" then return end

	local cmdWord = text:match("^(%S+)")
	cmdWord = cmdWord and cmdWord:lower() or ""
	local hasArgs = text:match("^%S+%s+(%S+)") ~= nil

	local overrideCmds = {
		["noclip"] = "Noclip", ["clip"] = "Noclip",
		["fly"] = "Flight", ["unfly"] = "Flight",
		["refresh"] = "Refresh", ["re"] = "Refresh",
		["respawn"] = "Respawn",
		["god"] = "Invulnerability", ["ungod"] = "Invulnerability",
		["fling"] = "Fling", ["unfling"] = "Fling",
		["esp"] = "Extrasensory Perception", ["unesp"] = "Extrasensory Perception", ["extrasensory"] = "Extrasensory Perception",
		["espteam"] = "SiriusESPTeam", ["selectteams"] = "SiriusESPTeam", ["teamesp"] = "SiriusESPTeam",
		["global"] = "Global Audio", 
		["visibility"] = "Visibility", ["invisibility"] = "Visibility", ["vis"] = "Visibility", ["invis"] = "Visibility",
		["view"] = "SiriusSpectate", ["unview"] = "SiriusSpectate", ["spectate"] = "SiriusSpectate", ["unspectate"] = "SiriusSpectate"
	}

	-- Handle phrases and specific team esp combos
	if text:lower():match("^team esp") or text:lower():match("^esp team") or text:lower():match("^select teams") then
		getgenv().execCmd("espteam")
		return
	end

	if text:lower():match("^jb fling") or text:lower():match("^jailbreak fling") then
		getgenv().execCmd("walkfling")
		return
	end

	if not hasArgs and overrideCmds[cmdWord] then
		local targetName = overrideCmds[cmdWord]
		
		local targetState = true
		if string.match(cmdWord, "^un") or cmdWord == "clip" or cmdWord == "vis" or cmdWord == "visibility" then
			targetState = false
		end

		if cmdWord == "extrasensory" and not text:lower():match("perception") then
			targetName = nil
		end
		if cmdWord == "global" and not text:lower():match("audio") then
			targetName = nil
		end

		if targetName == "SiriusSpectate" then
			local targetPlayerName = text:match("^%S+%s+(%S+)")
			local targetPlayer = nil
			
			if targetPlayerName and targetPlayerName ~= "all" and targetPlayerName ~= "others" and targetPlayerName ~= "me" then
				for _, p in ipairs(players:GetPlayers()) do
					if p.Name:lower():sub(1, #targetPlayerName) == targetPlayerName:lower() or p.DisplayName:lower():sub(1, #targetPlayerName) == targetPlayerName:lower() then
						targetPlayer = p
						break
					end
				end
			end
			
			if not targetPlayer or cmdWord == "unview" or cmdWord == "unspectate" then
				getgenv()._siriusSpectateTarget = nil
				if getgenv()._siriusSpectateConn then getgenv()._siriusSpectateConn:Disconnect() getgenv()._siriusSpectateConn = nil end
				if getgenv()._siriusSpectateCharConn then getgenv()._siriusSpectateCharConn:Disconnect() getgenv()._siriusSpectateCharConn = nil end
				
				task.spawn(function()
					for _, card in ipairs(playerlistPanel.Interactions.List:GetChildren()) do
						if card:FindFirstChild("PlayerInteractions") and card.PlayerInteractions:FindFirstChild("Spectate") then
							updateInteractionStyle(card.PlayerInteractions.Spectate)
						end
					end
				end)

				local myHum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
				if myHum and getgenv()._siriusStartTransit then
					getgenv()._siriusStartTransit(myHum)
				end
			else
				getgenv()._siriusSpectateTarget = targetPlayer.Name
				
				task.spawn(function()
					for _, card in ipairs(playerlistPanel.Interactions.List:GetChildren()) do
						if card:FindFirstChild("PlayerInteractions") and card.PlayerInteractions:FindFirstChild("Spectate") then
							updateInteractionStyle(card.PlayerInteractions.Spectate)
						end
					end
				end)

				local targetHum = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
				if targetHum and getgenv()._siriusStartTransit then
					getgenv()._siriusStartTransit(targetHum)
				end
			end
			return
		end

		if targetName == "SiriusESPTeam" then
			local actionData = checkAction(targetName)
			if actionData and actionData.action and actionData.object then
				local object = actionData.object
				local act = actionData.action

				if act.disableAfter then
					if not act.enabled then
						act.enabled = true
						task.spawn(act.callback)
						object.Icon.Image = "rbxassetid://"..act.images[1]
						tweenService:Create(object, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.1}):Play()
						tweenService:Create(object.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
						tweenService:Create(object.Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0.1}):Play()

						task.delay(act.disableAfter, function()
							act.enabled = false
							object.Icon.Image = "rbxassetid://"..act.images[2]
							tweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.55}):Play()
							tweenService:Create(object.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
							tweenService:Create(object.Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
						end)
					end
				else
					if act.enabled ~= targetState then
						act.enabled = targetState
						task.spawn(act.callback, act.enabled)
						
						if act.enabled then
							object.Icon.Image = "rbxassetid://"..act.images[1]
							tweenService:Create(object, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.1}):Play()
							tweenService:Create(object.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
							tweenService:Create(object.Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0.1}):Play()
						else
							object.Icon.Image = "rbxassetid://"..act.images[2]
							tweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.55}):Play()
							tweenService:Create(object.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
							tweenService:Create(object.Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
						end
					end
				end
				return
			end
		end
	end
	if getgenv().execCmd then
		local ok, err = pcall(getgenv().execCmd, text)
		if not ok then queueNotification("Command Error", tostring(err), 4370336704) end
		return
	end

	queueNotification("IY", "Command system not ready. Load IY from Settings first.", 9134780101)
end

iyTextBox.FocusLost:Connect(function(enterPressed)
	if getgenv()._siriusClickingSuggestion then 
		return -- Don't clear text if we just clicked a suggestion
	end
	
	tweenService:Create(iyCmdBarContainer, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(10, 10, 12)}):Play()
	tweenService:Create(iyUIStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 100, 100)}):Play()

	tweenService:Create(SuggestionFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1
	}):Play()
	for _, btn in pairs(SuggestionFrame:GetChildren()) do
		if btn:IsA("TextButton") then
			tweenService:Create(btn, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		end
	end
	task.delay(0.3, function() SuggestionFrame.Visible = false end)

	if enterPressed then
		local text = iyTextBox.Text
		if text ~= "" then
			-- Autocomplete to first suggestion
			local firstSuggestion = nil
			local dummyCmds = {
				"fly", "unfly", "noclip", "clip", "refresh", "re", "respawn", "god", "ungod", "extrasensory perception",
				"esp", "unesp", "global audio", "invisibility", "visibility", "vis", "invis", "fling", "unfling", "spectate", "view"
			}
			for _, cmd in ipairs(dummyCmds) do
				if cmd:lower():sub(1, #text) == text:lower() then
					firstSuggestion = cmd
					break
				end
			end
			-- Fallback to containing search if no start-match
			if not firstSuggestion then
				for _, cmd in ipairs(dummyCmds) do
					if cmd:lower():find(text:lower()) then
						firstSuggestion = cmd
						break
					end
				end
			end
			
			local finalCmd = firstSuggestion or text
			iyTextBox.Text = ""
			executeCommand(finalCmd)
		end
	end
end)

userInputService.InputBegan:Connect(function(input, processed)
	if not checkSirius() then return end

	-- Support the standard IY ';' prefix for cmdbar focusing
	if input.KeyCode == Enum.KeyCode.Semicolon and not processed then
		task.spawn(function()
			if not smartBarOpen then
				openSmartBar()
				task.wait(0.1)
			end
			-- Wait for the input character to actually be processed so it doesn't get captured in TextBox
			task.wait()
			iyTextBox:CaptureFocus()
			-- Clear any semicolon typed
			if iyTextBox.Text == ";" then iyTextBox.Text = "" end
		end)
		return
	end

	if checkingForKey then
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			local splitMessage = string.split(tostring(input.KeyCode), ".")
			local newKeyNoEnum = splitMessage[3]
			checkingForKey.object.InputFrame.InputBox.Text = tostring(newKeyNoEnum)
			checkingForKey.data.current = tostring(newKeyNoEnum)
			checkingForKey.object.InputFrame.InputBox:ReleaseFocus()
			saveSettings()
		end

		return
	end

	for _, category in ipairs(siriusSettings) do
		for _, setting in ipairs(category.categorySettings) do
			if setting.settingType == "Key" then
				if setting.current ~= nil and setting.current ~= "" and setting.current ~= "No Keybind" then
					local assignedKey = tostring(setting.current)
					if input.KeyCode.Name == assignedKey and not processed then
						if setting.callback then
							task.spawn(setting.callback)

							local action = checkAction(setting.name) or nil
							if action then
								local object = action.object
								action = action.action

								if action.enabled then
									object.Icon.Image = "rbxassetid://"..action.images[1]
									tweenService:Create(object, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.1}):Play()
									tweenService:Create(object.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
									tweenService:Create(object.Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0.1}):Play()

									if action.disableAfter then
										task.delay(action.disableAfter, function()
											action.enabled = false
											object.Icon.Image = "rbxassetid://"..action.images[2]
											tweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.55}):Play()
											tweenService:Create(object.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
											tweenService:Create(object.Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
										end)
									end

									if action.rotateWhileEnabled then
										repeat
											object.Icon.Rotation = 0
											tweenService:Create(object.Icon, TweenInfo.new(0.75, Enum.EasingStyle.Quint), {Rotation = 360}):Play()
											task.wait(1)
										until not action.enabled
										object.Icon.Rotation = 0
									end
								else
									object.Icon.Image = "rbxassetid://"..action.images[2]
									tweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.55}):Play()
									tweenService:Create(object.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
									tweenService:Create(object.Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
								end
							end
						end
					end
				end
			end
		end
	end

	if input.KeyCode == Enum.KeyCode[checkSetting("Open ScriptSearch").current] and not processed and not debounce then
		if scriptSearch.Visible then
			closeScriptSearch()
		else
			openScriptSearch()
		end
	end

	if input.KeyCode == Enum.KeyCode[checkSetting("Toggle smartBar").current] and not processed and not debounce then
		if smartBarOpen then 
			closeSmartBar()
		else
			openSmartBar()
		end
	end
end)

userInputService.InputEnded:Connect(function(input, processed)
	if not checkSirius() then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		for _, slider in pairs(siriusValues.sliders) do
			if slider.active then
				slider.active = false

				if characterPanel.Visible and not debounce and slider.object and checkSirius() then
					tweenService:Create(slider.object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.8}):Play()
					tweenService:Create(slider.object.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
					tweenService:Create(slider.object.Information, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0.3}):Play()
				end
			end
		end
	end
end)

camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
	task.wait(.5)
	-- Slider padding update removed as it's now dynamic
end)

scriptSearch.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if #scriptSearch.SearchBox.Text > 0 then
		tweenService:Create(scriptSearch.Icon, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		tweenService:Create(scriptSearch.SearchBox, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	else
		tweenService:Create(scriptSearch.Icon, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {ImageColor3 = Color3.fromRGB(150, 150, 150)}):Play()
		tweenService:Create(scriptSearch.SearchBox, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
	end
end)

scriptSearch.SearchBox.FocusLost:Connect(function(enterPressed)
	tweenService:Create(scriptSearch.Icon, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {ImageColor3 = Color3.fromRGB(150, 150, 150)}):Play()
	tweenService:Create(scriptSearch.SearchBox, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()

	if #scriptSearch.SearchBox.Text > 0 then
		if enterPressed then
			local success, response = pcall(function()
				searchScriptBlox(scriptSearch.SearchBox.Text)
			end)
		end
	elseif scriptSearch.SearchBox.TextEditable then
		closeScriptSearch()
	end
end)

scriptSearch.SearchBox.Focused:Connect(function()
	if #scriptSearch.SearchBox.Text > 0 then
		tweenService:Create(scriptSearch.Icon, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		tweenService:Create(scriptSearch.SearchBox, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end
end)

userInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		for _, slider in pairs(siriusValues.sliders) do
			if slider.active then
				updateSlider(slider)
			end
		end
	end
end)

	-- Game Scripts are now handled via the Universal button opening scriptSearch with auto-populated results

for index, player in ipairs(players:GetPlayers()) do
	createPlayer(player)
	createEsp(player)
	player.Chatted:Connect(function(message) onChatted(player, message) end)
end

players.PlayerAdded:Connect(function(player)
	if not checkSirius() then return end

	createPlayer(player)
	createEsp(player)

	player.Chatted:Connect(function(message) onChatted(player, message) end)

	if checkSetting("Log PlayerAdded and PlayerRemoving").current then
		local logData = {
			["content"] = player.DisplayName.." (@"..player.Name..") left the server.",
			["avatar_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=420&height=420&format=png",
			["username"] = player.DisplayName,
			["allowed_mentions"] = {parse = {}}
		}

		logData = httpService:JSONEncode(logData)

		pcall(function()
			local req = originalRequest({
				Url = checkSetting("Player Added and Removing Webhook URL").current,
				Method = 'POST',
				Headers = {
					['Content-Type'] = 'application/json',
				},
				Body = logData
			})
		end)

	end

	if checkSetting("Moderator Detection").current and Pro then
		local roleFound = player:GetRoleInGroup(creatorId)

		if siriusValues.currentCreator == "group" then
			for _, role in pairs(siriusValues.administratorRoles) do 
				if string.find(string.lower(roleFound), role) then
					promptModerator(player, roleFound)
					queueNotification("Administrator Joined", siriusValues.currentGroup .." "..roleFound.." ".. player.DisplayName .." has joined your session", 3944670656) -- change to group name
				end
			end
		end
	end

	if checkSetting("Friend Notifications").current then
		if localPlayer:IsFriendsWith(player.UserId) then
			queueNotification("Friend Joined", "Your friend "..player.DisplayName.." has joined your server.", 4370335364)
		end
	end
end)

players.PlayerRemoving:Connect(function(player)
	if checkSetting("Log PlayerAdded and PlayerRemoving").current then
		local logData = {
			["content"] = player.DisplayName.." (@"..player.Name..") joined the server.",
			["avatar_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=420&height=420&format=png",
			["username"] = player.DisplayName,
			["allowed_mentions"] = {parse = {}}
		}

		logData = httpService:JSONEncode(logData)

		pcall(function()
			local req = originalRequest({
				Url = checkSetting("Player Added and Removing Webhook URL").current,
				Method = 'POST',
				Headers = {
					['Content-Type'] = 'application/json',
				},
				Body = logData
			})
		end)
	end

	removePlayer(player)

	local highlight = espContainer:FindFirstChild(player.Name)
	if highlight then
		highlight:Destroy()
	end
end)

runService.RenderStepped:Connect(function(frame)
	if not checkSirius() then return end
	local fps = math.round(1/frame)

	table.insert(siriusValues.frameProfile.fpsQueue, fps)
	siriusValues.frameProfile.totalFPS += fps

	if #siriusValues.frameProfile.fpsQueue > siriusValues.frameProfile.fpsQueueSize then
		siriusValues.frameProfile.totalFPS -= siriusValues.frameProfile.fpsQueue[1]
		table.remove(siriusValues.frameProfile.fpsQueue, 1)
	end
end)

runService.Stepped:Connect(function()
	if not checkSirius() then return end

	local character = localPlayer.Character
	if character then
		-- No Clip
		local noclipEnabled = siriusValues.actions[1].enabled
		local flingEnabled = siriusValues.actions[6].enabled

		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				if noclipDefaults[part] == nil then
					task.wait()
					noclipDefaults[part] = part.CanCollide
				else
					if noclipEnabled then
						part.CanCollide = false
					else
						part.CanCollide = noclipDefaults[part]
					end
				end
			end
		end
	end
end)

runService.Heartbeat:Connect(function()
	if not checkSirius() then return end

	local character = localPlayer.Character
	local primaryPart = character and character.PrimaryPart
	if primaryPart then
		local bodyVelocity, bodyGyro = unpack(movers)
		if not bodyVelocity then
			bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.one * 9e9

			bodyGyro = Instance.new("BodyGyro")
			bodyGyro.MaxTorque = Vector3.one * 9e9
			bodyGyro.P = 9e4

			local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
			bodyAngularVelocity.AngularVelocity = Vector3.yAxis * 9e9
			bodyAngularVelocity.MaxTorque = Vector3.yAxis * 9e9
			bodyAngularVelocity.P = 9e9

			movers = { bodyVelocity, bodyGyro, bodyAngularVelocity }
		end

		-- Fly
		if siriusValues.actions[2].enabled then
			local camCFrame = camera.CFrame
			local velocity = Vector3.zero
			local rotation = camCFrame.Rotation

			if userInputService:IsKeyDown(Enum.KeyCode.W) then
				velocity += camCFrame.LookVector
				rotation *= CFrame.Angles(math.rad(-40), 0, 0)
			end
			if userInputService:IsKeyDown(Enum.KeyCode.S) then
				velocity -= camCFrame.LookVector
				rotation *= CFrame.Angles(math.rad(40), 0, 0)
			end
			if userInputService:IsKeyDown(Enum.KeyCode.D) then
				velocity += camCFrame.RightVector
				rotation *= CFrame.Angles(0, 0, math.rad(-40))
			end
			if userInputService:IsKeyDown(Enum.KeyCode.A) then
				velocity -= camCFrame.RightVector
				rotation *= CFrame.Angles(0, 0, math.rad(40))
			end
			if userInputService:IsKeyDown(Enum.KeyCode.Space) then
				velocity += Vector3.yAxis
			end
			if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				velocity -= Vector3.yAxis
			end

			local tweenInfo = TweenInfo.new(0.5)
			tweenService:Create(bodyVelocity, tweenInfo, { Velocity = velocity * siriusValues.sliders[3].value * 45 }):Play()
			bodyVelocity.Parent = primaryPart

			if not siriusValues.actions[6].enabled then
				tweenService:Create(bodyGyro, tweenInfo, { CFrame = rotation }):Play()
				bodyGyro.Parent = primaryPart
			end
		else
			bodyVelocity.Parent = nil
			bodyGyro.Parent = nil
		end
	end
end)

runService.Heartbeat:Connect(function(frame)
	if not checkSirius() then return end
	if Pro then
		if checkSetting("Spatial Shield").current and tonumber(checkSetting("Spatial Shield Threshold").current) then
			for index, sound in next, soundInstances do
				if not sound then
					table.remove(soundInstances, index)
				elseif gameSettings.MasterVolume * sound.PlaybackLoudness * sound.Volume >= tonumber(checkSetting("Spatial Shield Threshold").current) then
					if sound.Volume > 0.55 then 
						suppressedSounds[sound.SoundId] = "S"
						sound.Volume = 0.5 	
					elseif sound.Volume > 0.2 and sound.Volume < 0.55 then
						suppressedSounds[sound.SoundId] = "S2"
						sound.Volume = 0.1
					elseif sound.Volume < 0.2 then
						suppressedSounds[sound.SoundId] = "Mute"
						sound.Volume = 0
					end
					if soundSuppressionNotificationCooldown == 0 then
						queueNotification("Spatial Shield","A high-volume audio is being played ("..sound.Name..") and it has been suppressed.", 4483362458) 
						soundSuppressionNotificationCooldown = 15
					end
					table.remove(soundInstances, index)
				end
			end
		end
	end

	if checkSetting("Anonymous Client").current then
		for _, text in ipairs(cachedText) do
			local lowerText = string.lower(text.Text)
			if string.find(lowerText, lowerName, 1, true) or string.find(lowerText, lowerDisplayName, 1, true) then

				storeOriginalText(text)

				local newText = string.gsub(string.gsub(lowerText, lowerName, randomUsername), lowerDisplayName, randomUsername)
				text.Text = string.gsub(newText, "^%l", string.upper)
			end
		end
	else
		undoAnonymousChanges()
	end
end)

for _, instance in next, game:GetDescendants() do
	if instance:IsA("Sound") then
		if suppressedSounds[instance.SoundId] then
			if suppressedSounds[instance.SoundId] == "S" then
				instance.Volume = 0.5
			elseif suppressedSounds[instance.SoundId] == "S2" then
				instance.Volume = 0.1
			else
				instance.Volume = 0
			end
		else
			if not table.find(cachedIds, instance.SoundId) then
				table.insert(soundInstances, instance)
				table.insert(cachedIds, instance.SoundId)
			end
		end
	elseif instance:IsA("TextLabel") or instance:IsA("TextButton") then
		if not table.find(cachedText, instance) then
			table.insert(cachedText, instance)
		end
	end
end

game.DescendantAdded:Connect(function(instance)
	if checkSirius() then
		if instance:IsA("Sound") then
			if suppressedSounds[instance.SoundId] then
				if suppressedSounds[instance.SoundId] == "S" then
					instance.Volume = 0.5
				elseif suppressedSounds[instance.SoundId] == "S2" then
					instance.Volume = 0.1
				else
					instance.Volume = 0
				end
			else
				if not table.find(cachedIds, instance.SoundId) then
					table.insert(soundInstances, instance)
					table.insert(cachedIds, instance.SoundId)
				end
			end
		elseif instance:IsA("TextLabel") or instance:IsA("TextButton") then
			if not table.find(cachedText, instance) then
				table.insert(cachedText, instance)
			end
		end
	end
end)


task.spawn(function()
while task.wait(1) do
	if not checkSirius() then
		if espContainer then espContainer:Destroy() end
		undoAnonymousChanges()
		break
	end

	smartBar.Time.Text = os.date("%H")..":"..os.date("%M")
	task.spawn(UpdateHome)

	if getconnections then
		for _, connection in getconnections(localPlayer.Idled) do
			if not checkSetting("Anti Idle").current then connection:Enable() else connection:Disable() end
		end
	end

	toggle.Visible = not checkSetting("Hide Toggle Button").current

	-- Disconnected Check
	local disconnectedRobloxUI = coreGui.RobloxPromptGui.promptOverlay:FindFirstChild("ErrorPrompt")

	if disconnectedRobloxUI and not promptedDisconnected then
		local reasonPrompt = disconnectedRobloxUI.MessageArea.ErrorFrame.ErrorMessage.Text

		promptedDisconnected = true
		disconnectedPrompt.Parent = coreGui.RobloxPromptGui

		local disconnectType
		local foundString

		for _, preDisconnectType in ipairs(siriusValues.disconnectTypes) do
			for _, typeString in pairs(preDisconnectType[2]) do
				if string.find(reasonPrompt, typeString) then
					disconnectType = preDisconnectType[1]
					foundString = true
					break
				end
			end
		end

		if not foundString then disconnectType = "kick" end

		wipeTransparency(disconnectedPrompt, 1, true)
		disconnectedPrompt.Visible = true

		if disconnectType == "ban" then
			disconnectedPrompt.Content.Text = "You've been banned, would you like to leave this server?"
			disconnectedPrompt.Action.Text = "Leave"
			disconnectedPrompt.Action.Size = UDim2.new(0, 77, 0, 36) -- use textbounds

			disconnectedPrompt.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
				ColorSequenceKeypoint.new(1, Color3.new(0.819608, 0.164706, 0.164706))
			})
		elseif disconnectType == "kick" then
			disconnectedPrompt.Content.Text = "You've been kicked, would you like to serverhop?"
			disconnectedPrompt.Action.Text = "Serverhop"
			disconnectedPrompt.Action.Size = UDim2.new(0, 114, 0, 36)

			disconnectedPrompt.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
				ColorSequenceKeypoint.new(1, Color3.new(0.0862745, 0.596078, 0.835294))
			})
		elseif disconnectType == "network" then
			disconnectedPrompt.Content.Text = "You've lost connection, would you like to rejoin?"
			disconnectedPrompt.Action.Text = "Rejoin"
			disconnectedPrompt.Action.Size = UDim2.new(0, 82, 0, 36)

			disconnectedPrompt.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
				ColorSequenceKeypoint.new(1, Color3.new(0.862745, 0.501961, 0.0862745))
			})
		end

		tweenService:Create(disconnectedPrompt, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0}):Play()
		tweenService:Create(disconnectedPrompt.Title, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()
		tweenService:Create(disconnectedPrompt.Content, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0.3}):Play()
		tweenService:Create(disconnectedPrompt.Action, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {BackgroundTransparency = 0.7}):Play()
		tweenService:Create(disconnectedPrompt.Action, TweenInfo.new(.5,Enum.EasingStyle.Quint),  {TextTransparency = 0}):Play()

		disconnectedPrompt.Action.MouseButton1Click:Connect(function()
			if disconnectType == "ban" then
				game:Shutdown() -- leave
			elseif disconnectType == "kick" then
				serverhop()
			elseif disconnectType == "network" then
				rejoin()
			end
		end)
	end

	if Pro then
		-- all Pro checks here!

		-- Two-Way Adaptive Latency Checks
		if checkHighPing() then
			if siriusValues.pingProfile.pingNotificationCooldown <= 0 then
				if checkSetting("Adaptive Latency Warning").current then
					queueNotification("High Latency Warning","We've noticed your latency has reached a higher value than usual, you may find that you are lagging or your actions are delayed in-game. Consider checking for any background downloads on your machine.", 4370305588)
					siriusValues.pingProfile.pingNotificationCooldown = 120
				end
			end
		end

		if siriusValues.pingProfile.pingNotificationCooldown > 0 then
			siriusValues.pingProfile.pingNotificationCooldown -= 1
		end

		-- Adaptive frame time checks
		if siriusValues.frameProfile.frameNotificationCooldown <= 0 then
			if #siriusValues.frameProfile.fpsQueue > 0 then
				local avgFPS = siriusValues.frameProfile.totalFPS / #siriusValues.frameProfile.fpsQueue

				if avgFPS < siriusValues.frameProfile.lowFPSThreshold then
					if checkSetting("Adaptive Performance Warning").current then
						queueNotification("Degraded Performance","We've noticed your client's frames per second have decreased. Consider checking for any background tasks or programs on your machine.", 4384400106)
						siriusValues.frameProfile.frameNotificationCooldown = 120	
					end
				end
			end
		end

		if siriusValues.frameProfile.frameNotificationCooldown > 0 then
			siriusValues.frameProfile.frameNotificationCooldown -= 1
		end
	end
end
end)


getgenv().Bundled_IY_Execute = function()
if IY_LOADED and not _G.IY_DEBUG then
	-- error("Infinite Yield is already running!", 0)
	return
end

pcall(function() 
	getgenv().IY_LOADED = true 
end)
if not game:IsLoaded() then game.Loaded:Wait() end

function missing(t, f, fallback)
	if type(f) == t then return f end
	return fallback
end

cloneref = missing("function", cloneref, function(...) return ... end)
sethidden =  missing("function", sethiddenproperty or set_hidden_property or set_hidden_prop)
gethidden =  missing("function", gethiddenproperty or get_hidden_property or get_hidden_prop)
queueteleport =  missing("function", queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport))
httprequest =  missing("function", request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request))
everyClipboard = missing("function", setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set))
firetouchinterest = missing("function", firetouchinterest)
waxwritefile, waxreadfile = writefile, readfile
writefile = missing("function", waxwritefile) and function(file, data, safe)
	if safe == true then return pcall(waxwritefile, file, data) end
	waxwritefile(file, data)
end
readfile = missing("function", waxreadfile) and function(file, safe)
	if safe == true then return pcall(waxreadfile, file) end
	return waxreadfile(file)
end
isfile = missing("function", isfile, readfile and function(file)
	local success, result = pcall(function()
		return readfile(file)
	end)
	return success and result ~= nil and result ~= ""
end)
makefolder = missing("function", makefolder)
isfolder = missing("function", isfolder)
waxgetcustomasset = missing("function", getcustomasset or getsynasset)
hookfunction = missing("function", hookfunction)
hookmetamethod = missing("function", hookmetamethod)
getnamecallmethod = missing("function", getnamecallmethod or get_namecall_method)
checkcaller = missing("function", checkcaller, function() return false end)
newcclosure = missing("function", newcclosure)
getgc = missing("function", getgc or get_gc_objects)
setthreadidentity = missing("function", setthreadidentity or (syn and syn.set_thread_identity) or syn_context_set or setthreadcontext)
replicatesignal = missing("function", replicatesignal)
getconnections = missing("function", getconnections or get_signal_cons)

Services = setmetatable({}, {
	__index = function(self, name)
		local success, cache = pcall(function()
			return cloneref(game:GetService(name))
		end)
		if success then
			rawset(self, name, cache)
			return cache
		else
			error("Invalid Service: " .. tostring(name))
		end
	end
})

Players = Services.Players
UserInputService = Services.UserInputService
TweenService = Services.TweenService
HttpService = Services.HttpService
MarketplaceService = Services.MarketplaceService
RunService = Services.RunService
TeleportService = Services.TeleportService
StarterGui = Services.StarterGui
GuiService = Services.GuiService
Lighting = Services.Lighting
ContextActionService = Services.ContextActionService
ReplicatedStorage = Services.ReplicatedStorage
GroupService = Services.GroupService
PathService = Services.PathfindingService
SoundService = Services.SoundService
Teams = Services.Teams
StarterPlayer = Services.StarterPlayer
InsertService = Services.InsertService
ChatService = Services.Chat
ProximityPromptService = Services.ProximityPromptService
ContentProvider = Services.ContentProvider
StatsService = Services.Stats
MaterialService = Services.MaterialService
AvatarEditorService = Services.AvatarEditorService
TextService = Services.TextService
TextChatService = Services.TextChatService
CaptureService = Services.CaptureService
VoiceChatService = Services.VoiceChatService
SocialService = Services.SocialService

PlayerGui = cloneref(Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui"))
COREGUI = Services.CoreGui or PlayerGui
IYMouse = cloneref(Players.LocalPlayer:GetMouse())
PlaceId, JobId = game.PlaceId, game.JobId
xpcall(function()
	IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform())
end, function()
	IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)
isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService
--[[rcdEnabled = select(2, pcall(function()
    return gethidden(workspace, "RejectCharacterDeletions") ~= Enum.RejectCharacterDeletions.Disabled
end)) or false]]

-- xylex & europa
local iyassets = {
	["infiniteyield/assets/bindsandplugins.png"] = "rbxassetid://5147695474",
	["infiniteyield/assets/close.png"] = "rbxassetid://5054663650",
	["infiniteyield/assets/editaliases.png"] = "rbxassetid://5147488658",
	["infiniteyield/assets/editkeybinds.png"] = "rbxassetid://129697930",
	["infiniteyield/assets/edittheme.png"] = "rbxassetid://4911962991",
	["infiniteyield/assets/editwaypoints.png"] = "rbxassetid://5147488592",
	["infiniteyield/assets/imgstudiopluginlogo.png"] = "rbxassetid://4113050383",
	["infiniteyield/assets/logo.png"] = "rbxassetid://1352543873",
	["infiniteyield/assets/minimize.png"] = "rbxassetid://2406617031",
	["infiniteyield/assets/pin.png"] = "rbxassetid://6234691350",
	["infiniteyield/assets/reference.png"] = "rbxassetid://3523243755",
	["infiniteyield/assets/settings.png"] = "rbxassetid://1204397029"
}

local function getcustomasset(asset)
	if waxgetcustomasset then
		local success, result = pcall(function()
			return waxgetcustomasset(asset)
		end)
		if success and result ~= nil and result ~= "" then
			return result
		end
	end
	return iyassets[asset]
end

if makefolder and isfolder and writefile and isfile then
	pcall(function() -- good executor trust
		local assets = "https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/"
		for _, folder in {"infiniteyield", "infiniteyield/assets"} do
			if not isfolder(folder) then
				makefolder(folder)
			end
		end
		for path in iyassets do
			if not isfile(path) then
				writefile(path, game:HttpGet((path:gsub("infiniteyield/", assets))))
			end
		end
		if IsOnMobile then writefile("infiniteyield/assets/.nomedia", "") end
	end)
end

currentVersion = "6.4"

ScaledHolder = Instance.new("Frame")
Scale = Instance.new("UIScale")
Holder = Instance.new("Frame")
Title = Instance.new("TextLabel")
Dark = Instance.new("Frame")
Cmdbar = Instance.new("TextBox")
CMDsF = Instance.new("ScrollingFrame")
cmdListLayout = Instance.new("UIListLayout")
SettingsButton = Instance.new("ImageButton")
ColorsButton = Instance.new("ImageButton")
Settings = Instance.new("Frame")
Prefix = Instance.new("TextLabel")
PrefixBox = Instance.new("TextBox")
Keybinds = Instance.new("TextLabel")
StayOpen = Instance.new("TextLabel")
Button = Instance.new("Frame")
On = Instance.new("TextButton")
Positions = Instance.new("TextLabel")
EventBind = Instance.new("TextLabel")
Plugins = Instance.new("TextLabel")
Example = Instance.new("TextButton")
Notification = Instance.new("Frame")
Title_2 = Instance.new("TextLabel")
Text_2 = Instance.new("TextLabel")
CloseButton = Instance.new("TextButton")
CloseImage = Instance.new("ImageLabel")
PinButton = Instance.new("TextButton")
PinImage = Instance.new("ImageLabel")
Tooltip = Instance.new("Frame")
Title_3 = Instance.new("TextLabel")
Description = Instance.new("TextLabel")
IntroBackground = Instance.new("Frame")
Logo = Instance.new("ImageLabel")
Credits = Instance.new("TextBox")
KeybindsFrame = Instance.new("Frame")
Close = Instance.new("TextButton")
Add = Instance.new("TextButton")
Delete = Instance.new("TextButton")
Holder_2 = Instance.new("ScrollingFrame")
Example_2 = Instance.new("Frame")
Text_3 = Instance.new("TextLabel")
Delete_2 = Instance.new("TextButton")
KeybindEditor = Instance.new("Frame")
background_2 = Instance.new("Frame")
Dark_3 = Instance.new("Frame")
Directions = Instance.new("TextLabel")
BindTo = Instance.new("TextButton")
TriggerLabel = Instance.new("TextLabel")
BindTriggerSelect = Instance.new("TextButton")
Add_2 = Instance.new("TextButton")
Toggles = Instance.new("ScrollingFrame")
ClickTP  = Instance.new("TextLabel")
Select = Instance.new("TextButton")
ClickDelete = Instance.new("TextLabel")
Select_2 = Instance.new("TextButton")
Cmdbar_2 = Instance.new("TextBox")
Cmdbar_3 = Instance.new("TextBox")
CreateToggle = Instance.new("TextLabel")
Button_2 = Instance.new("Frame")
On_2 = Instance.new("TextButton")
shadow_2 = Instance.new("Frame")
PopupText_2 = Instance.new("TextLabel")
Exit_2 = Instance.new("TextButton")
ExitImage_2 = Instance.new("ImageLabel")
PositionsFrame = Instance.new("Frame")
Close_3 = Instance.new("TextButton")
Delete_5 = Instance.new("TextButton")
Part = Instance.new("TextButton")
Holder_4 = Instance.new("ScrollingFrame")
Example_4 = Instance.new("Frame")
Text_5 = Instance.new("TextLabel")
Delete_6 = Instance.new("TextButton")
TP = Instance.new("TextButton")
AliasesFrame = Instance.new("Frame")
Close_2 = Instance.new("TextButton")
Delete_3 = Instance.new("TextButton")
Holder_3 = Instance.new("ScrollingFrame")
Example_3 = Instance.new("Frame")
Text_4 = Instance.new("TextLabel")
Delete_4 = Instance.new("TextButton")
Aliases = Instance.new("TextLabel")
PluginsFrame = Instance.new("Frame")
Close_4 = Instance.new("TextButton")
Add_3 = Instance.new("TextButton")
Holder_5 = Instance.new("ScrollingFrame")
Example_5 = Instance.new("Frame")
Text_6 = Instance.new("TextLabel")
Delete_7 = Instance.new("TextButton")
PluginEditor = Instance.new("Frame")
background_3 = Instance.new("Frame")
Dark_2 = Instance.new("Frame")
Img = Instance.new("ImageButton")
AddPlugin = Instance.new("TextButton")
FileName = Instance.new("TextBox")
About = Instance.new("TextLabel")
Directions_2 = Instance.new("TextLabel")
shadow_3 = Instance.new("Frame")
PopupText_3 = Instance.new("TextLabel")
Exit_3 = Instance.new("TextButton")
ExitImage_3 = Instance.new("ImageLabel")
AliasHint = Instance.new("TextLabel")
PluginsHint = Instance.new("TextLabel")
PositionsHint = Instance.new("TextLabel")
ToPartFrame = Instance.new("Frame")
background_4 = Instance.new("Frame")
ChoosePart = Instance.new("TextButton")
CopyPath = Instance.new("TextButton")
Directions_3 = Instance.new("TextLabel")
Path = Instance.new("TextLabel")
shadow_4 = Instance.new("Frame")
PopupText_5 = Instance.new("TextLabel")
Exit_4 = Instance.new("TextButton")
ExitImage_5 = Instance.new("ImageLabel")
logs = Instance.new("Frame")
shadow = Instance.new("Frame")
Hide = Instance.new("TextButton")
ImageLabel = Instance.new("ImageLabel")
PopupText = Instance.new("TextLabel")
Exit = Instance.new("TextButton")
ImageLabel_2 = Instance.new("ImageLabel")
background = Instance.new("Frame")
chat = Instance.new("Frame")
Clear = Instance.new("TextButton")
SaveChatlogs = Instance.new("TextButton")
Toggle = Instance.new("TextButton")
scroll_2 = Instance.new("ScrollingFrame")
join = Instance.new("Frame")
Toggle_2 = Instance.new("TextButton")
Clear_2 = Instance.new("TextButton")
scroll_3 = Instance.new("ScrollingFrame")
listlayout = Instance.new("UIListLayout",scroll_3)
selectChat = Instance.new("TextButton")
selectJoin = Instance.new("TextButton")

function randomString()
	local length = math.random(10,20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

PARENT = nil
MAX_DISPLAY_ORDER = 2147483647
if get_hidden_gui or gethui then
    local hiddenUI = get_hidden_gui or gethui
    local Main = Instance.new("ScreenGui")
    Main.Name = "Sirius_IY_GUI"
    Main.ResetOnSpawn = false
    Main.DisplayOrder = MAX_DISPLAY_ORDER
    Main.Parent = hiddenUI()
    PARENT = Main
elseif (not is_sirhurt_closure) and (syn and syn.protect_gui) then
    local Main = Instance.new("ScreenGui")
    Main.Name = "Sirius_IY_GUI"
    Main.ResetOnSpawn = false
    Main.DisplayOrder = MAX_DISPLAY_ORDER
    syn.protect_gui(Main)
    Main.Parent = COREGUI
    PARENT = Main
else
    local Main = Instance.new("ScreenGui")
    Main.Name = "Sirius_IY_GUI"
    Main.ResetOnSpawn = false
    Main.DisplayOrder = MAX_DISPLAY_ORDER
    Main.Parent = COREGUI
    PARENT = Main
end

shade1 = {}
shade2 = {}
shade3 = {}
text1 = {}
text2 = {}
scroll = {}

ScaledHolder.Name = randomString()
ScaledHolder.Size = UDim2.fromScale(1, 1)
ScaledHolder.BackgroundTransparency = 1
ScaledHolder.Parent = nil -- SIRIUS: IY UI suppressed, headless mode
Scale.Name = randomString()

Holder.Name = randomString()
Holder.Parent = ScaledHolder
Holder.Active = true
Holder.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Holder.BorderSizePixel = 0
Holder.Position = UDim2.new(1, -250, 1, -220)
Holder.Size = UDim2.new(0, 250, 0, 220)
Holder.ZIndex = 10
table.insert(shade2,Holder)

Title.Name = "Title"
Title.Parent = Holder
Title.Active = true
Title.BackgroundColor3 = Color3.fromRGB(36,36,37)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(0, 250, 0, 20)
Title.Font = Enum.Font.SourceSans
Title.TextSize = 18
Title.Text = "Infinite Yield FE v" .. currentVersion

do
	local emoji = ({
		["01 01"] = "🎆",
		[(function(Year)
			local A = math.floor(Year/100)
			local B = math.floor((13+8*A)/25)
			local C = (15-B+A-math.floor(A/4))%30
			local D = (4+A-math.floor(A/4))%7
			local E = (19*(Year%19)+C)%30
			local F = (2*(Year%4)+4*(Year%7)+6*E+D)%7
			local G = (22+E+F)
			if E == 29 and F == 6 then
				return "04 19"
			elseif E == 28 and F == 6 then
				return "04 18"
			elseif 31 < G then
				return ("04 %02d"):format(G-31)
			end
			return ("03 %02d"):format(G)
		end)(tonumber(os.date"%Y"))] = "🥚",
		["10 31"] = "🎃",
		["12 25"] = "🎄"
	})[os.date("%m %d")]
	if emoji then
		Title.Text = ("%s %s %s"):format(emoji, Title.Text, emoji)
	end
end

Title.TextColor3 = Color3.new(1, 1, 1)
Title.ZIndex = 10
table.insert(shade1,Title)
table.insert(text1,Title)

Dark.Name = "Dark"
Dark.Parent = Holder
Dark.Active = true
Dark.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
Dark.BorderSizePixel = 0
Dark.Position = UDim2.new(0, 0, 0, 45)
Dark.Size = UDim2.new(0, 250, 0, 175)
Dark.ZIndex = 10
table.insert(shade1,Dark)

Cmdbar.Name = "Cmdbar"
Cmdbar.Parent = Holder
Cmdbar.BackgroundTransparency = 1
Cmdbar.BorderSizePixel = 0
Cmdbar.Position = UDim2.new(0, 5, 0, 20)
Cmdbar.Size = UDim2.new(0, 240, 0, 25)
Cmdbar.Font = Enum.Font.SourceSans
Cmdbar.TextSize = 18
Cmdbar.TextXAlignment = Enum.TextXAlignment.Left
Cmdbar.TextColor3 = Color3.new(1, 1, 1)
Cmdbar.Text = ""
Cmdbar.ZIndex = 10
Cmdbar.PlaceholderText = "Command Bar"

CMDsF.Name = "CMDs"
CMDsF.Parent = Holder
CMDsF.BackgroundTransparency = 1
CMDsF.BorderSizePixel = 0
CMDsF.Position = UDim2.new(0, 5, 0, 45)
CMDsF.Size = UDim2.new(0, 245, 0, 175)
CMDsF.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)
CMDsF.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
CMDsF.CanvasSize = UDim2.new(0, 0, 0, 0)
CMDsF.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
CMDsF.ScrollBarThickness = 8
CMDsF.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
CMDsF.VerticalScrollBarInset = 'Always'
CMDsF.ZIndex = 10
table.insert(scroll,CMDsF)

cmdListLayout.Parent = CMDsF

SettingsButton.Name = "SettingsButton"
SettingsButton.Parent = Holder
SettingsButton.BackgroundTransparency = 1
SettingsButton.Position = UDim2.new(0, 230, 0, 0)
SettingsButton.Size = UDim2.new(0, 20, 0, 20)
SettingsButton.Image = getcustomasset("infiniteyield/assets/settings.png")
SettingsButton.ZIndex = 10

ReferenceButton = Instance.new("ImageButton")
ReferenceButton.Name = "ReferenceButton"
ReferenceButton.Parent = Holder
ReferenceButton.BackgroundTransparency = 1
ReferenceButton.Position = UDim2.new(0, 212, 0, 2)
ReferenceButton.Size = UDim2.new(0, 16, 0, 16)
ReferenceButton.Image = getcustomasset("infiniteyield/assets/reference.png")
ReferenceButton.ZIndex = 10

Settings.Name = "Settings"
Settings.Parent = Holder
Settings.Active = true
Settings.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
Settings.BorderSizePixel = 0
Settings.Position = UDim2.new(0, 0, 0, 220)
Settings.Size = UDim2.new(0, 250, 0, 175)
Settings.ZIndex = 10
table.insert(shade1,Settings)

SettingsHolder = Instance.new("ScrollingFrame")
SettingsHolder.Name = "Holder"
SettingsHolder.Parent = Settings
SettingsHolder.BackgroundTransparency = 1
SettingsHolder.BorderSizePixel = 0
SettingsHolder.Size = UDim2.new(1,0,1,0)
SettingsHolder.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)
SettingsHolder.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
SettingsHolder.CanvasSize = UDim2.new(0, 0, 0, 235)
SettingsHolder.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
SettingsHolder.ScrollBarThickness = 8
SettingsHolder.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
SettingsHolder.VerticalScrollBarInset = 'Always'
SettingsHolder.ZIndex = 10
table.insert(scroll,SettingsHolder)

Prefix.Name = "Prefix"
Prefix.Parent = SettingsHolder
Prefix.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Prefix.BorderSizePixel = 0
Prefix.BackgroundTransparency = 1
Prefix.Position = UDim2.new(0, 5, 0, 5)
Prefix.Size = UDim2.new(1, -10, 0, 20)
Prefix.Font = Enum.Font.SourceSans
Prefix.TextSize = 14
Prefix.Text = "Prefix"
Prefix.TextColor3 = Color3.new(1, 1, 1)
Prefix.TextXAlignment = Enum.TextXAlignment.Left
Prefix.ZIndex = 10
table.insert(shade2,Prefix)
table.insert(text1,Prefix)

PrefixBox.Name = "PrefixBox"
PrefixBox.Parent = Prefix
PrefixBox.BackgroundColor3 = Color3.fromRGB(78, 78, 79)
PrefixBox.BorderSizePixel = 0
PrefixBox.Position = UDim2.new(1, -20, 0, 0)
PrefixBox.Size = UDim2.new(0, 20, 0, 20)
PrefixBox.Font = Enum.Font.SourceSansBold
PrefixBox.TextSize = 14
PrefixBox.Text = ''
PrefixBox.TextColor3 = Color3.new(0, 0, 0)
PrefixBox.ZIndex = 10
table.insert(shade3,PrefixBox)
table.insert(text2,PrefixBox)

function makeSettingsButton(name,iconID,off)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
	button.BorderSizePixel = 0
	button.Position = UDim2.new(0,0,0,0)
	button.Size = UDim2.new(1,0,0,25)
	button.Text = ""
	button.ZIndex = 10
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Parent = button
	icon.Position = UDim2.new(0,5,0,5)
	icon.Size = UDim2.new(0,16,0,16)
	icon.BackgroundTransparency = 1
	icon.Image = iconID
	icon.ZIndex = 10
	if off then
		icon.ScaleType = Enum.ScaleType.Crop
		icon.ImageRectSize = Vector2.new(16,16)
		icon.ImageRectOffset = Vector2.new(off,0)
	end
	local label = Instance.new("TextLabel")
	label.Name = "ButtonLabel"
	label.Parent = button
	label.BackgroundTransparency = 1
	label.Text = name
	label.Position = UDim2.new(0,28,0,0)
	label.Size = UDim2.new(1,-28,1,0)
	label.Font = Enum.Font.SourceSans
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 14
	label.ZIndex = 10
	label.TextXAlignment = Enum.TextXAlignment.Left
	table.insert(shade2,button)
	table.insert(text1,label)
	return button
end

ColorsButton = makeSettingsButton("Edit Theme",getcustomasset("infiniteyield/assets/edittheme.png"))
ColorsButton.Position = UDim2.new(0, 5, 0, 55)
ColorsButton.Size = UDim2.new(1, -10, 0, 25)
ColorsButton.Name = "Colors"
ColorsButton.Parent = SettingsHolder

Keybinds = makeSettingsButton("Edit Keybinds",getcustomasset("infiniteyield/assets/editkeybinds.png"))
Keybinds.Position = UDim2.new(0, 5, 0, 85)
Keybinds.Size = UDim2.new(1, -10, 0, 25)
Keybinds.Name = "Keybinds"
Keybinds.Parent = SettingsHolder

Aliases = makeSettingsButton("Edit Aliases",getcustomasset("infiniteyield/assets/editaliases.png"))
Aliases.Position = UDim2.new(0, 5, 0, 115)
Aliases.Size = UDim2.new(1, -10, 0, 25)
Aliases.Name = "Aliases"
Aliases.Parent = SettingsHolder

StayOpen.Name = "StayOpen"
StayOpen.Parent = SettingsHolder
StayOpen.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
StayOpen.BorderSizePixel = 0
StayOpen.BackgroundTransparency = 1
StayOpen.Position = UDim2.new(0, 5, 0, 30)
StayOpen.Size = UDim2.new(1, -10, 0, 20)
StayOpen.Font = Enum.Font.SourceSans
StayOpen.TextSize = 14
StayOpen.Text = "Keep Menu Open"
StayOpen.TextColor3 = Color3.new(1, 1, 1)
StayOpen.TextXAlignment = Enum.TextXAlignment.Left
StayOpen.ZIndex = 10
table.insert(shade2,StayOpen)
table.insert(text1,StayOpen)

Button.Name = "Button"
Button.Parent = StayOpen
Button.BackgroundColor3 = Color3.fromRGB(78, 78, 79)
Button.BorderSizePixel = 0
Button.Position = UDim2.new(1, -20, 0, 0)
Button.Size = UDim2.new(0, 20, 0, 20)
Button.ZIndex = 10
table.insert(shade3,Button)

On.Name = "On"
On.Parent = Button
On.BackgroundColor3 = Color3.fromRGB(150, 150, 151)
On.BackgroundTransparency = 1
On.BorderSizePixel = 0
On.Position = UDim2.new(0, 2, 0, 2)
On.Size = UDim2.new(0, 16, 0, 16)
On.Font = Enum.Font.SourceSans
On.FontSize = Enum.FontSize.Size14
On.Text = ""
On.TextColor3 = Color3.new(0, 0, 0)
On.ZIndex = 10

Positions = makeSettingsButton("Edit/Goto Waypoints",getcustomasset("infiniteyield/assets/editwaypoints.png"))
Positions.Position = UDim2.new(0, 5, 0, 145)
Positions.Size = UDim2.new(1, -10, 0, 25)
Positions.Name = "Waypoints"
Positions.Parent = SettingsHolder

EventBind = makeSettingsButton("Edit Event Binds",getcustomasset("infiniteyield/assets/bindsandplugins.png"),759)
EventBind.Position = UDim2.new(0, 5, 0, 205)
EventBind.Size = UDim2.new(1, -10, 0, 25)
EventBind.Name = "EventBinds"
EventBind.Parent = SettingsHolder

Plugins = makeSettingsButton("Manage Plugins",getcustomasset("infiniteyield/assets/bindsandplugins.png"),743)
Plugins.Position = UDim2.new(0, 5, 0, 175)
Plugins.Size = UDim2.new(1, -10, 0, 25)
Plugins.Name = "Plugins"
Plugins.Parent = SettingsHolder

Example.Name = "Example"
Example.Parent = Holder
Example.BackgroundTransparency = 1
Example.BorderSizePixel = 0
Example.Size = UDim2.new(0, 190, 0, 20)
Example.Visible = false
Example.Font = Enum.Font.SourceSans
Example.TextSize = 18
Example.Text = "Example"
Example.TextColor3 = Color3.new(1, 1, 1)
Example.TextXAlignment = Enum.TextXAlignment.Left
Example.ZIndex = 10
table.insert(text1,Example)

Notification.Name = randomString()
Notification.Parent = ScaledHolder
Notification.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
Notification.BorderSizePixel = 0
Notification.Position = UDim2.new(1, -500, 1, 20)
Notification.Size = UDim2.new(0, 250, 0, 100)
Notification.ZIndex = 10
table.insert(shade1,Notification)

Title_2.Name = "Title"
Title_2.Parent = Notification
Title_2.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Title_2.BorderSizePixel = 0
Title_2.Size = UDim2.new(0, 250, 0, 20)
Title_2.Font = Enum.Font.SourceSans
Title_2.TextSize = 14
Title_2.Text = "Notification Title"
Title_2.TextColor3 = Color3.new(1, 1, 1)
Title_2.ZIndex = 10
table.insert(shade2,Title_2)
table.insert(text1,Title_2)

Text_2.Name = "Text"
Text_2.Parent = Notification
Text_2.BackgroundTransparency = 1
Text_2.BorderSizePixel = 0
Text_2.Position = UDim2.new(0, 5, 0, 25)
Text_2.Size = UDim2.new(0, 240, 0, 75)
Text_2.Font = Enum.Font.SourceSans
Text_2.TextSize = 16
Text_2.Text = "Notification Text"
Text_2.TextColor3 = Color3.new(1, 1, 1)
Text_2.TextWrapped = true
Text_2.ZIndex = 10
table.insert(text1,Text_2)

CloseButton.Name = "CloseButton"
CloseButton.Parent = Notification
CloseButton.BackgroundTransparency = 1
CloseButton.Position = UDim2.new(1, -20, 0, 0)
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Text = ""
CloseButton.ZIndex = 10

CloseImage.Parent = CloseButton
CloseImage.BackgroundColor3 = Color3.new(1, 1, 1)
CloseImage.BackgroundTransparency = 1
CloseImage.Position = UDim2.new(0, 5, 0, 5)
CloseImage.Size = UDim2.new(0, 10, 0, 10)
CloseImage.Image = getcustomasset("infiniteyield/assets/close.png")
CloseImage.ZIndex = 10

PinButton.Name = "PinButton"
PinButton.Parent = Notification
PinButton.BackgroundTransparency = 1
PinButton.Size = UDim2.new(0, 20, 0, 20)
PinButton.ZIndex = 10
PinButton.Text = ""

PinImage.Parent = PinButton
PinImage.BackgroundColor3 = Color3.new(1, 1, 1)
PinImage.BackgroundTransparency = 1
PinImage.Position = UDim2.new(0, 3, 0, 3)
PinImage.Size = UDim2.new(0, 14, 0, 14)
PinImage.ZIndex = 10
PinImage.Image = getcustomasset("infiniteyield/assets/pin.png")

Tooltip.Name = randomString()
Tooltip.Parent = ScaledHolder
Tooltip.Active = true
Tooltip.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
Tooltip.BackgroundTransparency = 0.1
Tooltip.BorderSizePixel = 0
Tooltip.Size = UDim2.new(0, 200, 0, 96)
Tooltip.Visible = false
Tooltip.ZIndex = 10
table.insert(shade1,Tooltip)

Title_3.Name = "Title"
Title_3.Parent = Tooltip
Title_3.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Title_3.BackgroundTransparency = 0.1
Title_3.BorderSizePixel = 0
Title_3.Size = UDim2.new(0, 200, 0, 20)
Title_3.Font = Enum.Font.SourceSans
Title_3.TextSize = 14
Title_3.Text = ""
Title_3.TextColor3 = Color3.new(1, 1, 1)
Title_3.TextTransparency = 0.1
Title_3.ZIndex = 10
table.insert(shade2,Title_3)
table.insert(text1,Title_3)

Description.Name = "Description"
Description.Parent = Tooltip
Description.BackgroundTransparency = 1
Description.BorderSizePixel = 0
Description.Size = UDim2.new(0,180,0,72)
Description.Position = UDim2.new(0,10,0,18)
Description.Font = Enum.Font.SourceSans
Description.TextSize = 16
Description.Text = ""
Description.TextColor3 = Color3.new(1, 1, 1)
Description.TextTransparency = 0.1
Description.TextWrapped = true
Description.ZIndex = 10
table.insert(text1,Description)

IntroBackground.Name = "IntroBackground"
IntroBackground.Parent = Holder
IntroBackground.Active = true
IntroBackground.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
IntroBackground.BorderSizePixel = 0
IntroBackground.Position = UDim2.new(0, 0, 0, 45)
IntroBackground.Size = UDim2.new(0, 250, 0, 175)
IntroBackground.ZIndex = 10

Logo.Name = "Logo"
Logo.Parent = Holder
Logo.BackgroundTransparency = 1
Logo.BorderSizePixel = 0
Logo.Position = UDim2.new(0, 125, 0, 127)
Logo.Size = UDim2.new(0, 10, 0, 10)
Logo.Image = getcustomasset("infiniteyield/assets/logo.png")
Logo.ImageTransparency = 0
Logo.ZIndex = 10

Credits.Name = "Credits"
Credits.Parent = Holder
Credits.BackgroundTransparency = 1
Credits.BorderSizePixel = 0
Credits.Position = UDim2.new(0, 0, 0.9, 30)
Credits.Size = UDim2.new(0, 250, 0, 20)
Credits.Font = Enum.Font.SourceSansLight
Credits.FontSize = Enum.FontSize.Size14
Credits.Text = "Edge // Zwolf // Moon // Toon // Peyton // ATP"
Credits.TextColor3 = Color3.new(1, 1, 1)
Credits.ZIndex = 10

KeybindsFrame.Name = "KeybindsFrame"
KeybindsFrame.Parent = Settings
KeybindsFrame.Active = true
KeybindsFrame.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
KeybindsFrame.BorderSizePixel = 0
KeybindsFrame.Position = UDim2.new(0, 0, 0, 175)
KeybindsFrame.Size = UDim2.new(0, 250, 0, 175)
KeybindsFrame.ZIndex = 10
table.insert(shade1,KeybindsFrame)

Close.Name = "Close"
Close.Parent = KeybindsFrame
Close.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Close.BorderSizePixel = 0
Close.Position = UDim2.new(0, 205, 0, 150)
Close.Size = UDim2.new(0, 40, 0, 20)
Close.Font = Enum.Font.SourceSans
Close.TextSize = 14
Close.Text = "Close"
Close.TextColor3 = Color3.new(1, 1, 1)
Close.ZIndex = 10
table.insert(shade2,Close)
table.insert(text1,Close)

Add.Name = "Add"
Add.Parent = KeybindsFrame
Add.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Add.BorderSizePixel = 0
Add.Position = UDim2.new(0, 5, 0, 150)
Add.Size = UDim2.new(0, 40, 0, 20)
Add.Font = Enum.Font.SourceSans
Add.TextSize = 14
Add.Text = "Add"
Add.TextColor3 = Color3.new(1, 1, 1)
Add.ZIndex = 10
table.insert(shade2,Add)
table.insert(text1,Add)

Delete.Name = "Delete"
Delete.Parent = KeybindsFrame
Delete.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Delete.BorderSizePixel = 0
Delete.Position = UDim2.new(0, 50, 0, 150)
Delete.Size = UDim2.new(0, 40, 0, 20)
Delete.Font = Enum.Font.SourceSans
Delete.TextSize = 14
Delete.Text = "Clear"
Delete.TextColor3 = Color3.new(1, 1, 1)
Delete.ZIndex = 10
table.insert(shade2,Delete)
table.insert(text1,Delete)

Holder_2.Name = "Holder"
Holder_2.Parent = KeybindsFrame
Holder_2.BackgroundTransparency = 1
Holder_2.BorderSizePixel = 0
Holder_2.Position = UDim2.new(0, 0, 0, 0)
Holder_2.Size = UDim2.new(0, 250, 0, 145)
Holder_2.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)
Holder_2.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_2.CanvasSize = UDim2.new(0, 0, 0, 0)
Holder_2.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_2.ScrollBarThickness = 0
Holder_2.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_2.VerticalScrollBarInset = 'Always'
Holder_2.ZIndex = 10

Example_2.Name = "Example"
Example_2.Parent = KeybindsFrame
Example_2.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Example_2.BorderSizePixel = 0
Example_2.Size = UDim2.new(0, 10, 0, 20)
Example_2.Visible = false
Example_2.ZIndex = 10
table.insert(shade2,Example_2)

Text_3.Name = "Text"
Text_3.Parent = Example_2
Text_3.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Text_3.BorderSizePixel = 0
Text_3.Position = UDim2.new(0, 10, 0, 0)
Text_3.Size = UDim2.new(0, 240, 0, 20)
Text_3.Font = Enum.Font.SourceSans
Text_3.TextSize = 14
Text_3.Text = "nom"
Text_3.TextColor3 = Color3.new(1, 1, 1)
Text_3.TextXAlignment = Enum.TextXAlignment.Left
Text_3.ZIndex = 10
table.insert(shade2,Text_3)
table.insert(text1,Text_3)

Delete_2.Name = "Delete"
Delete_2.Parent = Text_3
Delete_2.BackgroundColor3 = Color3.fromRGB(78, 78, 79)
Delete_2.BorderSizePixel = 0
Delete_2.Position = UDim2.new(0, 200, 0, 0)
Delete_2.Size = UDim2.new(0, 40, 0, 20)
Delete_2.Font = Enum.Font.SourceSans
Delete_2.TextSize = 14
Delete_2.Text = "Delete"
Delete_2.TextColor3 = Color3.new(0, 0, 0)
Delete_2.ZIndex = 10
table.insert(shade3,Delete_2)
table.insert(text2,Delete_2)

KeybindEditor.Name = randomString()
KeybindEditor.Parent = ScaledHolder
KeybindEditor.Active = true
KeybindEditor.BackgroundTransparency = 1
KeybindEditor.Position = UDim2.new(0.5, -180, 0, -500)
KeybindEditor.Size = UDim2.new(0, 360, 0, 20)
KeybindEditor.ZIndex = 10

background_2.Name = "background"
background_2.Parent = KeybindEditor
background_2.Active = true
background_2.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
background_2.BorderSizePixel = 0
background_2.Position = UDim2.new(0, 0, 0, 20)
background_2.Size = UDim2.new(0, 360, 0, 185)
background_2.ZIndex = 10
table.insert(shade1,background_2)

Dark_3.Name = "Dark"
Dark_3.Parent = background_2
Dark_3.Active = true
Dark_3.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Dark_3.BorderSizePixel = 0
Dark_3.Position = UDim2.new(0, 135, 0, 0)
Dark_3.Size = UDim2.new(0, 2, 0, 185)
Dark_3.ZIndex = 10
table.insert(shade2,Dark_3)

Directions.Name = "Directions"
Directions.Parent = background_2
Directions.BackgroundTransparency = 1
Directions.BorderSizePixel = 0
Directions.Position = UDim2.new(0, 10, 0, 15)
Directions.Size = UDim2.new(0, 115, 0, 90)
Directions.ZIndex = 10
Directions.Font = Enum.Font.SourceSans
Directions.Text = "Click the button below and press a key/mouse button. Then select what you want to bind it to."
Directions.TextColor3 = Color3.fromRGB(255, 255, 255)
Directions.TextSize = 14.000
Directions.TextWrapped = true
Directions.TextYAlignment = Enum.TextYAlignment.Top
table.insert(text1,Directions)

BindTo.Name = "BindTo"
BindTo.Parent = background_2
BindTo.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
BindTo.BorderSizePixel = 0
BindTo.Position = UDim2.new(0, 10, 0, 95)
BindTo.Size = UDim2.new(0, 115, 0, 50)
BindTo.ZIndex = 10
BindTo.Font = Enum.Font.SourceSans
BindTo.Text = "Click to bind"
BindTo.TextColor3 = Color3.fromRGB(255, 255, 255)
BindTo.TextSize = 16.000
table.insert(shade2,BindTo)
table.insert(text1,BindTo)

TriggerLabel.Name = "TriggerLabel"
TriggerLabel.Parent = background_2
TriggerLabel.BackgroundTransparency = 1
TriggerLabel.Position = UDim2.new(0, 10, 0, 155)
TriggerLabel.Size = UDim2.new(0, 45, 0, 20)
TriggerLabel.ZIndex = 10
TriggerLabel.Font = Enum.Font.SourceSans
TriggerLabel.Text = "Trigger:"
TriggerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TriggerLabel.TextSize = 14.000
TriggerLabel.TextXAlignment = Enum.TextXAlignment.Left
table.insert(text1,TriggerLabel)

BindTriggerSelect.Name = "BindTo"
BindTriggerSelect.Parent = background_2
BindTriggerSelect.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
BindTriggerSelect.BorderSizePixel = 0
BindTriggerSelect.Position = UDim2.new(0, 60, 0, 155)
BindTriggerSelect.Size = UDim2.new(0, 65, 0, 20)
BindTriggerSelect.ZIndex = 10
BindTriggerSelect.Font = Enum.Font.SourceSans
BindTriggerSelect.Text = "KeyDown"
BindTriggerSelect.TextColor3 = Color3.fromRGB(255, 255, 255)
BindTriggerSelect.TextSize = 16.000
table.insert(shade2,BindTriggerSelect)
table.insert(text1,BindTriggerSelect)

Add_2.Name = "Add"
Add_2.Parent = background_2
Add_2.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Add_2.BorderSizePixel = 0
Add_2.Position = UDim2.new(0, 310, 0, 35)
Add_2.Size = UDim2.new(0, 40, 0, 20)
Add_2.ZIndex = 10
Add_2.Font = Enum.Font.SourceSans
Add_2.Text = "Add"
Add_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Add_2.TextSize = 14.000
table.insert(shade2,Add_2)
table.insert(text1,Add_2)

Toggles.Name = "Toggles"
Toggles.Parent = background_2
Toggles.BackgroundTransparency = 1
Toggles.BorderSizePixel = 0
Toggles.Position = UDim2.new(0, 150, 0, 125)
Toggles.Size = UDim2.new(0, 200, 0, 50)
Toggles.ZIndex = 10
Toggles.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Toggles.CanvasSize = UDim2.new(0, 0, 0, 50)
Toggles.ScrollBarThickness = 8
Toggles.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Toggles.VerticalScrollBarInset = Enum.ScrollBarInset.Always
table.insert(scroll,Toggles)

ClickTP.Name = "Click TP (Hold Key & Click)"
ClickTP.Parent = Toggles
ClickTP.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
ClickTP.BorderSizePixel = 0
ClickTP.Size = UDim2.new(0, 200, 0, 20)
ClickTP.ZIndex = 10
ClickTP.Font = Enum.Font.SourceSans
ClickTP.Text = "    Click TP (Hold Key & Click)"
ClickTP.TextColor3 = Color3.fromRGB(255, 255, 255)
ClickTP.TextSize = 14.000
ClickTP.TextXAlignment = Enum.TextXAlignment.Left
table.insert(shade2,ClickTP)
table.insert(text1,ClickTP)

Select.Name = "Select"
Select.Parent = ClickTP
Select.BackgroundColor3 = Color3.fromRGB(78, 78, 79)
Select.BorderSizePixel = 0
Select.Position = UDim2.new(0, 160, 0, 0)
Select.Size = UDim2.new(0, 40, 0, 20)
Select.ZIndex = 10
Select.Font = Enum.Font.SourceSans
Select.Text = "Add"
Select.TextColor3 = Color3.fromRGB(0, 0, 0)
Select.TextSize = 14.000
table.insert(shade3,Select)
table.insert(text2,Select)

ClickDelete.Name = "Click Delete (Hold Key & Click)"
ClickDelete.Parent = Toggles
ClickDelete.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
ClickDelete.BorderSizePixel = 0
ClickDelete.Position = UDim2.new(0, 0, 0, 25)
ClickDelete.Size = UDim2.new(0, 200, 0, 20)
ClickDelete.ZIndex = 10
ClickDelete.Font = Enum.Font.SourceSans
ClickDelete.Text = "    Click Delete (Hold Key & Click)"
ClickDelete.TextColor3 = Color3.fromRGB(255, 255, 255)
ClickDelete.TextSize = 14.000
ClickDelete.TextXAlignment = Enum.TextXAlignment.Left
table.insert(shade2,ClickDelete)
table.insert(text1,ClickDelete)

Select_2.Name = "Select"
Select_2.Parent = ClickDelete
Select_2.BackgroundColor3 = Color3.fromRGB(78, 78, 79)
Select_2.BorderSizePixel = 0
Select_2.Position = UDim2.new(0, 160, 0, 0)
Select_2.Size = UDim2.new(0, 40, 0, 20)
Select_2.ZIndex = 10
Select_2.Font = Enum.Font.SourceSans
Select_2.Text = "Add"
Select_2.TextColor3 = Color3.fromRGB(0, 0, 0)
Select_2.TextSize = 14.000
table.insert(shade3,Select_2)
table.insert(text2,Select_2)

Cmdbar_2.Name = "Cmdbar_2"
Cmdbar_2.Parent = background_2
Cmdbar_2.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Cmdbar_2.BorderSizePixel = 0
Cmdbar_2.Position = UDim2.new(0, 150, 0, 35)
Cmdbar_2.Size = UDim2.new(0, 150, 0, 20)
Cmdbar_2.ZIndex = 10
Cmdbar_2.Font = Enum.Font.SourceSans
Cmdbar_2.PlaceholderText = "Command"
Cmdbar_2.Text = ""
Cmdbar_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Cmdbar_2.TextSize = 14.000
Cmdbar_2.TextXAlignment = Enum.TextXAlignment.Left

Cmdbar_3.Name = "Cmdbar_3"
Cmdbar_3.Parent = background_2
Cmdbar_3.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Cmdbar_3.BorderSizePixel = 0
Cmdbar_3.Position = UDim2.new(0, 150, 0, 60)
Cmdbar_3.Size = UDim2.new(0, 150, 0, 20)
Cmdbar_3.ZIndex = 10
Cmdbar_3.Font = Enum.Font.SourceSans
Cmdbar_3.PlaceholderText = "Command 2"
Cmdbar_3.Text = ""
Cmdbar_3.TextColor3 = Color3.fromRGB(255, 255, 255)
Cmdbar_3.TextSize = 14.000
Cmdbar_3.TextXAlignment = Enum.TextXAlignment.Left

CreateToggle.Name = "CreateToggle"
CreateToggle.Parent = background_2
CreateToggle.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
CreateToggle.BackgroundTransparency = 1
CreateToggle.BorderSizePixel = 0
CreateToggle.Position = UDim2.new(0, 152, 0, 10)
CreateToggle.Size = UDim2.new(0, 198, 0, 20)
CreateToggle.ZIndex = 10
CreateToggle.Font = Enum.Font.SourceSans
CreateToggle.Text = "Create Toggle"
CreateToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
CreateToggle.TextSize = 14.000
CreateToggle.TextXAlignment = Enum.TextXAlignment.Left
table.insert(text1,CreateToggle)

Button_2.Name = "Button"
Button_2.Parent = CreateToggle
Button_2.BackgroundColor3 = Color3.fromRGB(78, 78, 79)
Button_2.BorderSizePixel = 0
Button_2.Position = UDim2.new(1, -20, 0, 0)
Button_2.Size = UDim2.new(0, 20, 0, 20)
Button_2.ZIndex = 10
table.insert(shade3,Button_2)

On_2.Name = "On"
On_2.Parent = Button_2
On_2.BackgroundColor3 = Color3.fromRGB(150, 150, 151)
On_2.BackgroundTransparency = 1
On_2.BorderSizePixel = 0
On_2.Position = UDim2.new(0, 2, 0, 2)
On_2.Size = UDim2.new(0, 16, 0, 16)
On_2.ZIndex = 10
On_2.Font = Enum.Font.SourceSans
On_2.Text = ""
On_2.TextColor3 = Color3.fromRGB(0, 0, 0)
On_2.TextSize = 14.000

shadow_2.Name = "shadow"
shadow_2.Parent = KeybindEditor
shadow_2.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
shadow_2.BorderSizePixel = 0
shadow_2.Size = UDim2.new(0, 360, 0, 20)
shadow_2.ZIndex = 10
table.insert(shade2,shadow_2)

PopupText_2.Name = "PopupText_2"
PopupText_2.Parent = shadow_2
PopupText_2.BackgroundTransparency = 1
PopupText_2.Size = UDim2.new(1, 0, 0.949999988, 0)
PopupText_2.ZIndex = 10
PopupText_2.Font = Enum.Font.SourceSans
PopupText_2.Text = "Set Keybinds"
PopupText_2.TextColor3 = Color3.fromRGB(255, 255, 255)
PopupText_2.TextSize = 14.000
PopupText_2.TextWrapped = true
table.insert(text1,PopupText_2)

Exit_2.Name = "Exit_2"
Exit_2.Parent = shadow_2
Exit_2.BackgroundTransparency = 1
Exit_2.Position = UDim2.new(1, -20, 0, 0)
Exit_2.Size = UDim2.new(0, 20, 0, 20)
Exit_2.ZIndex = 10
Exit_2.Text = ""

ExitImage_2.Parent = Exit_2
ExitImage_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ExitImage_2.BackgroundTransparency = 1
ExitImage_2.Position = UDim2.new(0, 5, 0, 5)
ExitImage_2.Size = UDim2.new(0, 10, 0, 10)
ExitImage_2.ZIndex = 10
ExitImage_2.Image = getcustomasset("infiniteyield/assets/close.png")

PositionsFrame.Name = "PositionsFrame"
PositionsFrame.Parent = Settings
PositionsFrame.Active = true
PositionsFrame.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
PositionsFrame.BorderSizePixel = 0
PositionsFrame.Size = UDim2.new(0, 250, 0, 175)
PositionsFrame.Position = UDim2.new(0, 0, 0, 175)
PositionsFrame.ZIndex = 10
table.insert(shade1,PositionsFrame)

Close_3.Name = "Close"
Close_3.Parent = PositionsFrame
Close_3.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Close_3.BorderSizePixel = 0
Close_3.Position = UDim2.new(0, 205, 0, 150)
Close_3.Size = UDim2.new(0, 40, 0, 20)
Close_3.Font = Enum.Font.SourceSans
Close_3.TextSize = 14
Close_3.Text = "Close"
Close_3.TextColor3 = Color3.new(1, 1, 1)
Close_3.ZIndex = 10
table.insert(shade2,Close_3)
table.insert(text1,Close_3)

Delete_5.Name = "Delete"
Delete_5.Parent = PositionsFrame
Delete_5.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Delete_5.BorderSizePixel = 0
Delete_5.Position = UDim2.new(0, 50, 0, 150)
Delete_5.Size = UDim2.new(0, 40, 0, 20)
Delete_5.Font = Enum.Font.SourceSans
Delete_5.TextSize = 14
Delete_5.Text = "Clear"
Delete_5.TextColor3 = Color3.new(1, 1, 1)
Delete_5.ZIndex = 10
table.insert(shade2,Delete_5)
table.insert(text1,Delete_5)

Part.Name = "PartGoto"
Part.Parent = PositionsFrame
Part.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Part.BorderSizePixel = 0
Part.Position = UDim2.new(0, 5, 0, 150)
Part.Size = UDim2.new(0, 40, 0, 20)
Part.Font = Enum.Font.SourceSans
Part.TextSize = 14
Part.Text = "Part"
Part.TextColor3 = Color3.new(1, 1, 1)
Part.ZIndex = 10
table.insert(shade2,Part)
table.insert(text1,Part)

Holder_4.Name = "Holder"
Holder_4.Parent = PositionsFrame
Holder_4.BackgroundTransparency = 1
Holder_4.BorderSizePixel = 0
Holder_4.Position = UDim2.new(0, 0, 0, 0)
Holder_4.Selectable = false
Holder_4.Size = UDim2.new(0, 250, 0, 145)
Holder_4.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)
Holder_4.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_4.CanvasSize = UDim2.new(0, 0, 0, 0)
Holder_4.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_4.ScrollBarThickness = 0
Holder_4.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_4.VerticalScrollBarInset = 'Always'
Holder_4.ZIndex = 10

Example_4.Name = "Example"
Example_4.Parent = PositionsFrame
Example_4.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Example_4.BorderSizePixel = 0
Example_4.Size = UDim2.new(0, 10, 0, 20)
Example_4.Visible = false
Example_4.Position = UDim2.new(0, 0, 0, -5)
Example_4.ZIndex = 10
table.insert(shade2,Example_4)

Text_5.Name = "Text"
Text_5.Parent = Example_4
Text_5.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Text_5.BorderSizePixel = 0
Text_5.Position = UDim2.new(0, 10, 0, 0)
Text_5.Size = UDim2.new(0, 240, 0, 20)
Text_5.Font = Enum.Font.SourceSans
Text_5.TextSize = 14
Text_5.Text = "Position"
Text_5.TextColor3 = Color3.new(1, 1, 1)
Text_5.TextXAlignment = Enum.TextXAlignment.Left
Text_5.ZIndex = 10
table.insert(shade2,Text_5)
table.insert(text1,Text_5)

Delete_6.Name = "Delete"
Delete_6.Parent = Text_5
Delete_6.BackgroundColor3 = Color3.fromRGB(78, 78, 79)
Delete_6.BorderSizePixel = 0
Delete_6.Position = UDim2.new(0, 200, 0, 0)
Delete_6.Size = UDim2.new(0, 40, 0, 20)
Delete_6.Font = Enum.Font.SourceSans
Delete_6.TextSize = 14
Delete_6.Text = "Delete"
Delete_6.TextColor3 = Color3.new(0, 0, 0)
Delete_6.ZIndex = 10
table.insert(shade3,Delete_6)
table.insert(text2,Delete_6)

TP.Name = "TP"
TP.Parent = Text_5
TP.BackgroundColor3 = Color3.fromRGB(78, 78, 79)
TP.BorderSizePixel = 0
TP.Position = UDim2.new(0, 155, 0, 0)
TP.Size = UDim2.new(0, 40, 0, 20)
TP.Font = Enum.Font.SourceSans
TP.TextSize = 14
TP.Text = "Goto"
TP.TextColor3 = Color3.new(0, 0, 0)
TP.ZIndex = 10
table.insert(shade3,TP)
table.insert(text2,TP)

AliasesFrame.Name = "AliasesFrame"
AliasesFrame.Parent = Settings
AliasesFrame.Active = true
AliasesFrame.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
AliasesFrame.BorderSizePixel = 0
AliasesFrame.Position = UDim2.new(0, 0, 0, 175)
AliasesFrame.Size = UDim2.new(0, 250, 0, 175)
AliasesFrame.ZIndex = 10
table.insert(shade1,AliasesFrame)

Close_2.Name = "Close"
Close_2.Parent = AliasesFrame
Close_2.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Close_2.BorderSizePixel = 0
Close_2.Position = UDim2.new(0, 205, 0, 150)
Close_2.Size = UDim2.new(0, 40, 0, 20)
Close_2.Font = Enum.Font.SourceSans
Close_2.TextSize = 14
Close_2.Text = "Close"
Close_2.TextColor3 = Color3.new(1, 1, 1)
Close_2.ZIndex = 10
table.insert(shade2,Close_2)
table.insert(text1,Close_2)

Delete_3.Name = "Delete"
Delete_3.Parent = AliasesFrame
Delete_3.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Delete_3.BorderSizePixel = 0
Delete_3.Position = UDim2.new(0, 5, 0, 150)
Delete_3.Size = UDim2.new(0, 40, 0, 20)
Delete_3.Font = Enum.Font.SourceSans
Delete_3.TextSize = 14
Delete_3.Text = "Clear"
Delete_3.TextColor3 = Color3.new(1, 1, 1)
Delete_3.ZIndex = 10
table.insert(shade2,Delete_3)
table.insert(text1,Delete_3)

Holder_3.Name = "Holder"
Holder_3.Parent = AliasesFrame
Holder_3.BackgroundTransparency = 1
Holder_3.BorderSizePixel = 0
Holder_3.Position = UDim2.new(0, 0, 0, 0)
Holder_3.Size = UDim2.new(0, 250, 0, 145)
Holder_3.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)
Holder_3.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_3.CanvasSize = UDim2.new(0, 0, 0, 0)
Holder_3.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_3.ScrollBarThickness = 0
Holder_3.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_3.VerticalScrollBarInset = 'Always'
Holder_3.ZIndex = 10

Example_3.Name = "Example"
Example_3.Parent = AliasesFrame
Example_3.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Example_3.BorderSizePixel = 0
Example_3.Size = UDim2.new(0, 10, 0, 20)
Example_3.Visible = false
Example_3.ZIndex = 10
table.insert(shade2,Example_3)

Text_4.Name = "Text"
Text_4.Parent = Example_3
Text_4.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Text_4.BorderSizePixel = 0
Text_4.Position = UDim2.new(0, 10, 0, 0)
Text_4.Size = UDim2.new(0, 240, 0, 20)
Text_4.Font = Enum.Font.SourceSans
Text_4.TextSize = 14
Text_4.Text = "honk"
Text_4.TextColor3 = Color3.new(1, 1, 1)
Text_4.TextXAlignment = Enum.TextXAlignment.Left
Text_4.ZIndex = 10
table.insert(shade2,Text_4)
table.insert(text1,Text_4)

Delete_4.Name = "Delete"
Delete_4.Parent = Text_4
Delete_4.BackgroundColor3 = Color3.fromRGB(78, 78, 79)
Delete_4.BorderSizePixel = 0
Delete_4.Position = UDim2.new(0, 200, 0, 0)
Delete_4.Size = UDim2.new(0, 40, 0, 20)
Delete_4.Font = Enum.Font.SourceSans
Delete_4.TextSize = 14
Delete_4.Text = "Delete"
Delete_4.TextColor3 = Color3.new(0, 0, 0)
Delete_4.ZIndex = 10
table.insert(shade3,Delete_4)
table.insert(text2,Delete_4)

PluginsFrame.Name = "PluginsFrame"
PluginsFrame.Parent = Settings
PluginsFrame.Active = true
PluginsFrame.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
PluginsFrame.BorderSizePixel = 0
PluginsFrame.Position = UDim2.new(0, 0, 0, 175)
PluginsFrame.Size = UDim2.new(0, 250, 0, 175)
PluginsFrame.ZIndex = 10
table.insert(shade1,PluginsFrame)

Close_4.Name = "Close"
Close_4.Parent = PluginsFrame
Close_4.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Close_4.BorderSizePixel = 0
Close_4.Position = UDim2.new(0, 205, 0, 150)
Close_4.Size = UDim2.new(0, 40, 0, 20)
Close_4.Font = Enum.Font.SourceSans
Close_4.TextSize = 14
Close_4.Text = "Close"
Close_4.TextColor3 = Color3.new(1, 1, 1)
Close_4.ZIndex = 10
table.insert(shade2,Close_4)
table.insert(text1,Close_4)

Add_3.Name = "Add"
Add_3.Parent = PluginsFrame
Add_3.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Add_3.BorderSizePixel = 0
Add_3.Position = UDim2.new(0, 5, 0, 150)
Add_3.Size = UDim2.new(0, 40, 0, 20)
Add_3.Font = Enum.Font.SourceSans
Add_3.TextSize = 14
Add_3.Text = "Add"
Add_3.TextColor3 = Color3.new(1, 1, 1)
Add_3.ZIndex = 10
table.insert(shade2,Add_3)
table.insert(text1,Add_3)

Holder_5.Name = "Holder"
Holder_5.Parent = PluginsFrame
Holder_5.BackgroundTransparency = 1
Holder_5.BorderSizePixel = 0
Holder_5.Position = UDim2.new(0, 0, 0, 0)
Holder_5.Selectable = false
Holder_5.Size = UDim2.new(0, 250, 0, 145)
Holder_5.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)
Holder_5.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_5.CanvasSize = UDim2.new(0, 0, 0, 0)
Holder_5.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_5.ScrollBarThickness = 0
Holder_5.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
Holder_5.VerticalScrollBarInset = 'Always'
Holder_5.ZIndex = 10

Example_5.Name = "Example"
Example_5.Parent = PluginsFrame
Example_5.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Example_5.BorderSizePixel = 0
Example_5.Size = UDim2.new(0, 10, 0, 20)
Example_5.Visible = false
Example_5.ZIndex = 10
table.insert(shade2,Example_5)

Text_6.Name = "Text"
Text_6.Parent = Example_5
Text_6.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Text_6.BorderSizePixel = 0
Text_6.Position = UDim2.new(0, 10, 0, 0)
Text_6.Size = UDim2.new(0, 240, 0, 20)
Text_6.Font = Enum.Font.SourceSans
Text_6.TextSize = 14
Text_6.Text = "F4 > Toggle Fly"
Text_6.TextColor3 = Color3.new(1, 1, 1)
Text_6.TextXAlignment = Enum.TextXAlignment.Left
Text_6.ZIndex = 10
table.insert(shade2,Text_6)
table.insert(text1,Text_6)

Delete_7.Name = "Delete"
Delete_7.Parent = Text_6
Delete_7.BackgroundColor3 = Color3.fromRGB(78, 78, 79)
Delete_7.BorderSizePixel = 0
Delete_7.Position = UDim2.new(0, 200, 0, 0)
Delete_7.Size = UDim2.new(0, 40, 0, 20)
Delete_7.Font = Enum.Font.SourceSans
Delete_7.TextSize = 14
Delete_7.Text = "Delete"
Delete_7.TextColor3 = Color3.new(0, 0, 0)
Delete_7.ZIndex = 10
table.insert(shade3,Delete_7)
table.insert(text2,Delete_7)

PluginEditor.Name = randomString()
PluginEditor.Parent = ScaledHolder
PluginEditor.BorderSizePixel = 0
PluginEditor.Active = true
PluginEditor.BackgroundTransparency = 1
PluginEditor.Position = UDim2.new(0.5, -180, 0, -500)
PluginEditor.Size = UDim2.new(0, 360, 0, 20)
PluginEditor.ZIndex = 10

background_3.Name = "background"
background_3.Parent = PluginEditor
background_3.Active = true
background_3.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
background_3.BorderSizePixel = 0
background_3.Position = UDim2.new(0, 0, 0, 20)
background_3.Size = UDim2.new(0, 360, 0, 160)
background_3.ZIndex = 10
table.insert(shade1,background_3)

Dark_2.Name = "Dark"
Dark_2.Parent = background_3
Dark_2.Active = true
Dark_2.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
Dark_2.BorderSizePixel = 0
Dark_2.Position = UDim2.new(0, 222, 0, 0)
Dark_2.Size = UDim2.new(0, 2, 0, 160)
Dark_2.ZIndex = 10
table.insert(shade2,Dark_2)

Img.Name = "Img"
Img.Parent = background_3
Img.BackgroundTransparency = 1
Img.Position = UDim2.new(0, 242, 0, 3)
Img.Size = UDim2.new(0, 100, 0, 95)
Img.Image = getcustomasset("infiniteyield/assets/imgstudiopluginlogo.png")
Img.ZIndex = 10

AddPlugin.Name = "AddPlugin"
AddPlugin.Parent = background_3
AddPlugin.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
AddPlugin.BorderSizePixel = 0
AddPlugin.Position = UDim2.new(0, 235, 0, 100)
AddPlugin.Size = UDim2.new(0, 115, 0, 50)
AddPlugin.Font = Enum.Font.SourceSans
AddPlugin.TextSize = 14
AddPlugin.Text = "Add Plugin"
AddPlugin.TextColor3 = Color3.new(1, 1, 1)
AddPlugin.ZIndex = 10
table.insert(shade2,AddPlugin)
table.insert(text1,AddPlugin)

FileName.Name = "FileName"
FileName.Parent = background_3
FileName.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
FileName.BorderSizePixel = 0
FileName.Position = UDim2.new(0.028, 0, 0.625, 0)
FileName.Size = UDim2.new(0, 200, 0, 50)
FileName.Font = Enum.Font.SourceSans
FileName.TextSize = 14
FileName.Text = "Plugin File Name"
FileName.TextColor3 = Color3.new(1, 1, 1)
FileName.ZIndex = 10
table.insert(shade2,FileName)
table.insert(text1,FileName)

About.Name = "About"
About.Parent = background_3
About.BackgroundTransparency = 1
About.BorderSizePixel = 0
About.Position = UDim2.new(0, 17, 0, 10)
About.Size = UDim2.new(0, 187, 0, 49)
About.Font = Enum.Font.SourceSans
About.TextSize = 14
About.Text = "Plugins are .iy files and should be located in the 'workspace' folder of your exploit."
About.TextColor3 = Color3.fromRGB(255, 255, 255)
About.TextWrapped = true
About.TextYAlignment = Enum.TextYAlignment.Top
About.ZIndex = 10
table.insert(text1,About)

Directions_2.Name = "Directions"
Directions_2.Parent = background_3
Directions_2.BackgroundTransparency = 1
Directions_2.BorderSizePixel = 0
Directions_2.Position = UDim2.new(0, 17, 0, 60)
Directions_2.Size = UDim2.new(0, 187, 0, 49)
Directions_2.Font = Enum.Font.SourceSans
Directions_2.TextSize = 14
Directions_2.Text = "Type the name of the plugin file you want to add below."
Directions_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Directions_2.TextWrapped = true
Directions_2.TextYAlignment = Enum.TextYAlignment.Top
Directions_2.ZIndex = 10
table.insert(text1,Directions_2)

shadow_3.Name = "shadow"
shadow_3.Parent = PluginEditor
shadow_3.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
shadow_3.BorderSizePixel = 0
shadow_3.Size = UDim2.new(0, 360, 0, 20)
shadow_3.ZIndex = 10
table.insert(shade2,shadow_3)

PopupText_3.Name = "PopupText"
PopupText_3.Parent = shadow_3
PopupText_3.BackgroundTransparency = 1
PopupText_3.Size = UDim2.new(1, 0, 0.95, 0)
PopupText_3.ZIndex = 10
PopupText_3.Font = Enum.Font.SourceSans
PopupText_3.TextSize = 14
PopupText_3.Text = "Add Plugins"
PopupText_3.TextColor3 = Color3.new(1, 1, 1)
PopupText_3.TextWrapped = true
table.insert(text1,PopupText_3)

Exit_3.Name = "Exit"
Exit_3.Parent = shadow_3
Exit_3.BackgroundTransparency = 1
Exit_3.Position = UDim2.new(1, -20, 0, 0)
Exit_3.Size = UDim2.new(0, 20, 0, 20)
Exit_3.Text = ""
Exit_3.ZIndex = 10

ExitImage_3.Parent = Exit_3
ExitImage_3.BackgroundColor3 = Color3.new(1, 1, 1)
ExitImage_3.BackgroundTransparency = 1
ExitImage_3.Position = UDim2.new(0, 5, 0, 5)
ExitImage_3.Size = UDim2.new(0, 10, 0, 10)
ExitImage_3.Image = getcustomasset("infiniteyield/assets/close.png")
ExitImage_3.ZIndex = 10

AliasHint.Name = "AliasHint"
AliasHint.Parent = AliasesFrame
AliasHint.BackgroundTransparency = 1
AliasHint.BorderSizePixel = 0
AliasHint.Position = UDim2.new(0, 25, 0, 40)
AliasHint.Size = UDim2.new(0, 200, 0, 50)
AliasHint.Font = Enum.Font.SourceSansItalic
AliasHint.TextSize = 16
AliasHint.Text = "Add aliases by using the 'addalias' command"
AliasHint.TextColor3 = Color3.new(1, 1, 1)
AliasHint.TextStrokeColor3 = Color3.new(1, 1, 1)
AliasHint.TextWrapped = true
AliasHint.ZIndex = 10
table.insert(text1,AliasHint)

PluginsHint.Name = "PluginsHint"
PluginsHint.Parent = PluginsFrame
PluginsHint.BackgroundTransparency = 1
PluginsHint.BorderSizePixel = 0
PluginsHint.Position = UDim2.new(0, 25, 0, 40)
PluginsHint.Size = UDim2.new(0, 200, 0, 50)
PluginsHint.Font = Enum.Font.SourceSansItalic
PluginsHint.TextSize = 16
PluginsHint.Text = "Download plugins from the IY Discord (discord.gg/78ZuWSq)"
PluginsHint.TextColor3 = Color3.new(1, 1, 1)
PluginsHint.TextStrokeColor3 = Color3.new(1, 1, 1)
PluginsHint.TextWrapped = true
PluginsHint.ZIndex = 10
table.insert(text1,PluginsHint)

PositionsHint.Name = "PositionsHint"
PositionsHint.Parent = PositionsFrame
PositionsHint.BackgroundTransparency = 1
PositionsHint.BorderSizePixel = 0
PositionsHint.Position = UDim2.new(0, 25, 0, 40)
PositionsHint.Size = UDim2.new(0, 200, 0, 70)
PositionsHint.Font = Enum.Font.SourceSansItalic
PositionsHint.TextSize = 16
PositionsHint.Text = "Use the 'swp' or 'setwaypoint' command to add a position using your character (NOTE: Part teleports will not save)"
PositionsHint.TextColor3 = Color3.new(1, 1, 1)
PositionsHint.TextStrokeColor3 = Color3.new(1, 1, 1)
PositionsHint.TextWrapped = true
PositionsHint.ZIndex = 10
table.insert(text1,PositionsHint)

ToPartFrame.Name = randomString()
ToPartFrame.Parent = ScaledHolder
ToPartFrame.Active = true
ToPartFrame.BackgroundTransparency = 1
ToPartFrame.Position = UDim2.new(0.5, -180, 0, -500)
ToPartFrame.Size = UDim2.new(0, 360, 0, 20)
ToPartFrame.ZIndex = 10

background_4.Name = "background"
background_4.Parent = ToPartFrame
background_4.Active = true
background_4.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
background_4.BorderSizePixel = 0
background_4.Position = UDim2.new(0, 0, 0, 20)
background_4.Size = UDim2.new(0, 360, 0, 117)
background_4.ZIndex = 10
table.insert(shade1,background_4)

ChoosePart.Name = "ChoosePart"
ChoosePart.Parent = background_4
ChoosePart.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
ChoosePart.BorderSizePixel = 0
ChoosePart.Position = UDim2.new(0, 100, 0, 55)
ChoosePart.Size = UDim2.new(0, 75, 0, 30)
ChoosePart.Font = Enum.Font.SourceSans
ChoosePart.TextSize = 14
ChoosePart.Text = "Select Part"
ChoosePart.TextColor3 = Color3.new(1, 1, 1)
ChoosePart.ZIndex = 10
table.insert(shade2,ChoosePart)
table.insert(text1,ChoosePart)

CopyPath.Name = "CopyPath"
CopyPath.Parent = background_4
CopyPath.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
CopyPath.BorderSizePixel = 0
CopyPath.Position = UDim2.new(0, 185, 0, 55)
CopyPath.Size = UDim2.new(0, 75, 0, 30)
CopyPath.Font = Enum.Font.SourceSans
CopyPath.TextSize = 14
CopyPath.Text = "Copy Path"
CopyPath.TextColor3 = Color3.new(1, 1, 1)
CopyPath.ZIndex = 10
table.insert(shade2,CopyPath)
table.insert(text1,CopyPath)

Directions_3.Name = "Directions"
Directions_3.Parent = background_4
Directions_3.BackgroundTransparency = 1
Directions_3.BorderSizePixel = 0
Directions_3.Position = UDim2.new(0, 51, 0, 17)
Directions_3.Size = UDim2.new(0, 257, 0, 32)
Directions_3.Font = Enum.Font.SourceSans
Directions_3.TextSize = 14
Directions_3.Text = 'Click on a part and then click the "Select Part" button below to set it as a teleport location'
Directions_3.TextColor3 = Color3.new(1, 1, 1)
Directions_3.TextWrapped = true
Directions_3.TextYAlignment = Enum.TextYAlignment.Top
Directions_3.ZIndex = 10
table.insert(text1,Directions_3)

Path.Name = "Path"
Path.Parent = background_4
Path.BackgroundTransparency = 1
Path.BorderSizePixel = 0
Path.Position = UDim2.new(0, 0, 0, 94)
Path.Size = UDim2.new(0, 360, 0, 16)
Path.Font = Enum.Font.SourceSansItalic
Path.TextSize = 14
Path.Text = ""
Path.TextColor3 = Color3.new(1, 1, 1)
Path.TextScaled = true
Path.TextWrapped = true
Path.TextYAlignment = Enum.TextYAlignment.Top
Path.ZIndex = 10
table.insert(text1,Path)

shadow_4.Name = "shadow"
shadow_4.Parent = ToPartFrame
shadow_4.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
shadow_4.BorderSizePixel = 0
shadow_4.Size = UDim2.new(0, 360, 0, 20)
shadow_4.ZIndex = 10
table.insert(shade2,shadow_4)

PopupText_5.Name = "PopupText"
PopupText_5.Parent = shadow_4
PopupText_5.BackgroundTransparency = 1
PopupText_5.Size = UDim2.new(1, 0, 0.95, 0)
PopupText_5.ZIndex = 10
PopupText_5.Font = Enum.Font.SourceSans
PopupText_5.TextSize = 14
PopupText_5.Text = "Teleport to Part"
PopupText_5.TextColor3 = Color3.new(1, 1, 1)
PopupText_5.TextWrapped = true
table.insert(text1,PopupText_5)

Exit_4.Name = "Exit"
Exit_4.Parent = shadow_4
Exit_4.BackgroundTransparency = 1
Exit_4.Position = UDim2.new(1, -20, 0, 0)
Exit_4.Size = UDim2.new(0, 20, 0, 20)
Exit_4.Text = ""
Exit_4.ZIndex = 10

ExitImage_5.Parent = Exit_4
ExitImage_5.BackgroundColor3 = Color3.new(1, 1, 1)
ExitImage_5.BackgroundTransparency = 1
ExitImage_5.Position = UDim2.new(0, 5, 0, 5)
ExitImage_5.Size = UDim2.new(0, 10, 0, 10)
ExitImage_5.Image = getcustomasset("infiniteyield/assets/close.png")
ExitImage_5.ZIndex = 10

logs.Name = randomString()
logs.Parent = ScaledHolder
logs.Active = true
logs.BackgroundTransparency = 1
logs.Position = UDim2.new(0, 0, 1, 10)
logs.Size = UDim2.new(0, 338, 0, 20)
logs.ZIndex = 10

shadow.Name = "shadow"
shadow.Parent = logs
shadow.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)
shadow.BorderSizePixel = 0
shadow.Position = UDim2.new(0, 0, 0.00999999978, 0)
shadow.Size = UDim2.new(0, 338, 0, 20)
shadow.ZIndex = 10
table.insert(shade2,shadow)

Hide.Name = "Hide"
Hide.Parent = shadow
Hide.BackgroundTransparency = 1
Hide.Position = UDim2.new(1, -40, 0, 0)
Hide.Size = UDim2.new(0, 20, 0, 20)
Hide.ZIndex = 10
Hide.Text = ""

ImageLabel.Parent = Hide
ImageLabel.BackgroundColor3 = Color3.new(1, 1, 1)
ImageLabel.BackgroundTransparency = 1
ImageLabel.Position = UDim2.new(0, 3, 0, 3)
ImageLabel.Size = UDim2.new(0, 14, 0, 14)
ImageLabel.Image = getcustomasset("infiniteyield/assets/minimize.png")
ImageLabel.ZIndex = 10

PopupText.Name = "PopupText"
PopupText.Parent = shadow
PopupText.BackgroundTransparency = 1
PopupText.Size = UDim2.new(1, 0, 0.949999988, 0)
PopupText.ZIndex = 10
PopupText.Font = Enum.Font.SourceSans
PopupText.FontSize = Enum.FontSize.Size14
PopupText.Text = "Logs"
PopupText.TextColor3 = Color3.new(1, 1, 1)
PopupText.TextWrapped = true
table.insert(text1,PopupText)

Exit.Name = "Exit"
Exit.Parent = shadow
Exit.BackgroundTransparency = 1
Exit.Position = UDim2.new(1, -20, 0, 0)
Exit.Size = UDim2.new(0, 20, 0, 20)
Exit.ZIndex = 10
Exit.Text = ""

ImageLabel_2.Parent = Exit
ImageLabel_2.BackgroundColor3 = Color3.new(1, 1, 1)
ImageLabel_2.BackgroundTransparency = 1
ImageLabel_2.Position = UDim2.new(0, 5, 0, 5)
ImageLabel_2.Size = UDim2.new(0, 10, 0, 10)
ImageLabel_2.Image = getcustomasset("infiniteyield/assets/close.png")
ImageLabel_2.ZIndex = 10

background.Name = "background"
background.Parent = logs
background.Active = true
background.BackgroundColor3 = Color3.new(0.141176, 0.141176, 0.145098)
background.BorderSizePixel = 0
background.ClipsDescendants = true
background.Position = UDim2.new(0, 0, 1, 0)
background.Size = UDim2.new(0, 338, 0, 245)
background.ZIndex = 10

chat.Name = "chat"
chat.Parent = background
chat.Active = true
chat.BackgroundColor3 = Color3.new(0.141176, 0.141176, 0.145098)
chat.BorderSizePixel = 0
chat.ClipsDescendants = true
chat.Size = UDim2.new(0, 338, 0, 245)
chat.ZIndex = 10
table.insert(shade1,chat)

Clear.Name = "Clear"
Clear.Parent = chat
Clear.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)
Clear.BorderSizePixel = 0
Clear.Position = UDim2.new(0, 5, 0, 220)
Clear.Size = UDim2.new(0, 50, 0, 20)
Clear.ZIndex = 10
Clear.Font = Enum.Font.SourceSans
Clear.FontSize = Enum.FontSize.Size14
Clear.Text = "Clear"
Clear.TextColor3 = Color3.new(1, 1, 1)
table.insert(shade2,Clear)
table.insert(text1,Clear)

SaveChatlogs.Name = "SaveChatlogs"
SaveChatlogs.Parent = chat
SaveChatlogs.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)
SaveChatlogs.BorderSizePixel = 0
SaveChatlogs.Position = UDim2.new(0, 258, 0, 220)
SaveChatlogs.Size = UDim2.new(0, 75, 0, 20)
SaveChatlogs.ZIndex = 10
SaveChatlogs.Font = Enum.Font.SourceSans
SaveChatlogs.FontSize = Enum.FontSize.Size14
SaveChatlogs.Text = "Save To .txt"
SaveChatlogs.TextColor3 = Color3.new(1, 1, 1)
table.insert(shade2,SaveChatlogs)
table.insert(text1,SaveChatlogs)

Toggle.Name = "Toggle"
Toggle.Parent = chat
Toggle.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)
Toggle.BorderSizePixel = 0
Toggle.Position = UDim2.new(0, 60, 0, 220)
Toggle.Size = UDim2.new(0, 66, 0, 20)
Toggle.ZIndex = 10
Toggle.Font = Enum.Font.SourceSans
Toggle.FontSize = Enum.FontSize.Size14
Toggle.Text = "Disabled"
Toggle.TextColor3 = Color3.new(1, 1, 1)
table.insert(shade2,Toggle)
table.insert(text1,Toggle)

scroll_2.Name = "scroll"
scroll_2.Parent = chat
scroll_2.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)
scroll_2.BorderSizePixel = 0
scroll_2.Position = UDim2.new(0, 5, 0, 25)
scroll_2.Size = UDim2.new(0, 328, 0, 190)
scroll_2.ZIndex = 10
scroll_2.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
scroll_2.CanvasSize = UDim2.new(0, 0, 0, 10)
scroll_2.ScrollBarThickness = 8
scroll_2.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
table.insert(scroll,scroll_2)
table.insert(shade2,scroll_2)

join.Name = "join"
join.Parent = background
join.Active = true
join.BackgroundColor3 = Color3.new(0.141176, 0.141176, 0.145098)
join.BorderSizePixel = 0
join.ClipsDescendants = true
join.Size = UDim2.new(0, 338, 0, 245)
join.Visible = false
join.ZIndex = 10
table.insert(shade1,join)

Toggle_2.Name = "Toggle"
Toggle_2.Parent = join
Toggle_2.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)
Toggle_2.BorderSizePixel = 0
Toggle_2.Position = UDim2.new(0, 60, 0, 220)
Toggle_2.Size = UDim2.new(0, 66, 0, 20)
Toggle_2.ZIndex = 10
Toggle_2.Font = Enum.Font.SourceSans
Toggle_2.FontSize = Enum.FontSize.Size14
Toggle_2.Text = "Disabled"
Toggle_2.TextColor3 = Color3.new(1, 1, 1)
table.insert(shade2,Toggle_2)
table.insert(text1,Toggle_2)

Clear_2.Name = "Clear"
Clear_2.Parent = join
Clear_2.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)
Clear_2.BorderSizePixel = 0
Clear_2.Position = UDim2.new(0, 5, 0, 220)
Clear_2.Size = UDim2.new(0, 50, 0, 20)
Clear_2.ZIndex = 10
Clear_2.Font = Enum.Font.SourceSans
Clear_2.FontSize = Enum.FontSize.Size14
Clear_2.Text = "Clear"
Clear_2.TextColor3 = Color3.new(1, 1, 1)
table.insert(shade2,Clear_2)
table.insert(text1,Clear_2)

scroll_3.Name = "scroll"
scroll_3.Parent = join
scroll_3.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)
scroll_3.BorderSizePixel = 0
scroll_3.Position = UDim2.new(0, 5, 0, 25)
scroll_3.Size = UDim2.new(0, 328, 0, 190)
scroll_3.ZIndex = 10
scroll_3.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
scroll_3.CanvasSize = UDim2.new(0, 0, 0, 10)
scroll_3.ScrollBarThickness = 8
scroll_3.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
table.insert(scroll,scroll_3)
table.insert(shade2,scroll_3)

selectChat.Name = "selectChat"
selectChat.Parent = background
selectChat.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)
selectChat.BorderSizePixel = 0
selectChat.Position = UDim2.new(0, 5, 0, 5)
selectChat.Size = UDim2.new(0, 164, 0, 20)
selectChat.ZIndex = 10
selectChat.Font = Enum.Font.SourceSans
selectChat.FontSize = Enum.FontSize.Size14
selectChat.Text = "Chat Logs"
selectChat.TextColor3 = Color3.new(1, 1, 1)
table.insert(shade2,selectChat)
table.insert(text1,selectChat)

selectJoin.Name = "selectJoin"
selectJoin.Parent = background
selectJoin.BackgroundColor3 = Color3.new(0.305882, 0.305882, 0.309804)
selectJoin.BorderSizePixel = 0
selectJoin.Position = UDim2.new(0, 169, 0, 5)
selectJoin.Size = UDim2.new(0, 164, 0, 20)
selectJoin.ZIndex = 10
selectJoin.Font = Enum.Font.SourceSans
selectJoin.FontSize = Enum.FontSize.Size14
selectJoin.Text = "Join Logs"
selectJoin.TextColor3 = Color3.new(1, 1, 1)
table.insert(shade3,selectJoin)
table.insert(text1,selectJoin)

function create(data)
	local insts = {}
	for i,v in pairs(data) do insts[v[1]] = Instance.new(v[2]) end

	for _,v in pairs(data) do
		for prop,val in pairs(v[3]) do
			if type(val) == "table" then
				insts[v[1]][prop] = insts[val[1]]
			else
				insts[v[1]][prop] = val
			end
		end
	end

	return insts[1]
end

ViewportTextBox = (function()

	local funcs = {}
	funcs.Update = function(self)
		local cursorPos = self.TextBox.CursorPosition
		local text = self.TextBox.Text
		if text == "" then self.TextBox.Position = UDim2.new(0,2,0,0) return end
		if cursorPos == -1 then return end

		local cursorText = text:sub(1,cursorPos-1)
		local pos = nil
		local leftEnd = -self.TextBox.Position.X.Offset
		local rightEnd = leftEnd + self.View.AbsoluteSize.X

		local totalTextSize = TextService:GetTextSize(text,self.TextBox.TextSize,self.TextBox.Font,Vector2.new(999999999,100)).X
		local cursorTextSize = TextService:GetTextSize(cursorText,self.TextBox.TextSize,self.TextBox.Font,Vector2.new(999999999,100)).X

		if cursorTextSize > rightEnd then
			pos = math.max(-2,cursorTextSize - self.View.AbsoluteSize.X + 2)
		elseif cursorTextSize < leftEnd then
			pos = math.max(-2,cursorTextSize-2)
		elseif totalTextSize < rightEnd then
			pos = math.max(-2,totalTextSize - self.View.AbsoluteSize.X + 2)
		end

		if pos then
			self.TextBox.Position = UDim2.new(0,-pos,0,0)
			self.TextBox.Size = UDim2.new(1,pos,1,0)
		end
	end

	local mt = {}
	mt.__index = funcs

	local function convert(textbox)
		local obj = setmetatable({OffsetX = 0, TextBox = textbox},mt)

		local view = Instance.new("Frame")
		view.BackgroundTransparency = textbox.BackgroundTransparency
		view.BackgroundColor3 = textbox.BackgroundColor3
		view.BorderSizePixel = textbox.BorderSizePixel
		view.BorderColor3 = textbox.BorderColor3
		view.Position = textbox.Position
		view.Size = textbox.Size
		view.ClipsDescendants = true
		view.Name = textbox.Name
		view.ZIndex = 10
		textbox.BackgroundTransparency = 1
		textbox.Position = UDim2.new(0,4,0,0)
		textbox.Size = UDim2.new(1,-8,1,0)
		textbox.TextXAlignment = Enum.TextXAlignment.Left
		textbox.Name = "Input"
		table.insert(text1,textbox)
		table.insert(shade2,view)

		obj.View = view

		textbox.Changed:Connect(function(prop)
			if prop == "Text" or prop == "CursorPosition" or prop == "AbsoluteSize" then
				obj:Update()
			end
		end)

		obj:Update()

		view.Parent = textbox.Parent
		textbox.Parent = view

		return obj
	end

	return {convert = convert}
end)()

ViewportTextBox.convert(Cmdbar).View.ZIndex = 10
ViewportTextBox.convert(Cmdbar_2).View.ZIndex = 10
ViewportTextBox.convert(Cmdbar_3).View.ZIndex = 10

function writefileExploit()
	if writefile then
		return true
	end
end

function readfileExploit()
	if readfile then
		return true
	end
end

function isNumber(str)
	if tonumber(str) ~= nil or str == "inf" then
		return true
	end
end

function vtype(o, t)
	if o == nil then return false end
	if type(o) == "userdata" then return typeof(o) == t end
	return type(o) == t
end

function getRoot(char)
	if char and char:FindFirstChildOfClass("Humanoid") then
		return char:FindFirstChildOfClass("Humanoid").RootPart
	else
		return nil
	end
end

function tools(plr)
	if plr:FindFirstChildOfClass("Backpack"):FindFirstChildOfClass("Tool") or plr.Character:FindFirstChildOfClass("Tool") then
		return true
	end
end

function r15(plr)
	if plr.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15 then
		return true
	end
end

function breakVelocity()
    local V3 = Vector3.new(0, 0, 0)
    for _, v in ipairs(Players.LocalPlayer.Character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Velocity, v.RotVelocity = V3, V3
        end
    end
end

function toClipboard(txt)
	if everyClipboard then
		everyClipboard(tostring(txt)) -- some executor errored without tostring btw so dont call me out for this
		notify("Clipboard", "Copied to clipboard")
	else
		notify("Clipboard", "Your exploit doesn't have the ability to use the clipboard")
	end
end

function chatMessage(str)
	str = tostring(str)
	if not isLegacyChat then
		TextChatService.TextChannels.RBXGeneral:SendAsync(str)
	else
		ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
	end
end

function getHierarchy(obj)
	local fullname
	local period

	if string.find(obj.Name,' ') then
		fullname = '["'..obj.Name..'"]'
		period = false
	else
		fullname = obj.Name
		period = true
	end

	local getS = obj
	local parent = obj
	local service = ''

	if getS.Parent ~= game then
		repeat
			getS = getS.Parent
			service = getS.ClassName
		until getS.Parent == game
	end

	if parent.Parent ~= getS then
		repeat
			parent = parent.Parent
			if string.find(tostring(parent),' ') then
				if period then
					fullname = '["'..parent.Name..'"].'..fullname
				else
					fullname = '["'..parent.Name..'"]'..fullname
				end
				period = false
			else
				if period then
					fullname = parent.Name..'.'..fullname
				else
					fullname = parent.Name..''..fullname
				end
				period = true
			end
		until parent.Parent == getS
	elseif string.find(tostring(parent),' ') then
		fullname = '["'..parent.Name..'"]'
		period = false
	end

	if period then
		return 'game:GetService("'..service..'").'..fullname
	else
		return 'game:GetService("'..service..'")'..fullname
	end
end

AllWaypoints = {}

local cooldown = false
function writefileCooldown(name,data)
	task.spawn(function()
		if not cooldown then
			cooldown = true
			writefile(name, data, true)
		else
			repeat wait() until cooldown == false
			writefileCooldown(name,data)
		end
		wait(3)
		cooldown = false
	end)
end

function dragGUI(gui)
	task.spawn(function()
		local dragging
		local dragInput
		local dragStart = Vector3.new(0,0,0)
		local startPos
		local function update(input)
			local delta = input.Position - dragStart
			local Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			TweenService:Create(gui, TweenInfo.new(.20), {Position = Position}):Play()
		end
		gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = gui.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		gui.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				update(input)
			end
		end)
	end)
end

dragGUI(logs)
dragGUI(KeybindEditor)
dragGUI(PluginEditor)
dragGUI(ToPartFrame)

eventEditor = (function()
	local events = {}

	local function registerEvent(name,sets)
		events[name] = {
			commands = {},
			sets = sets or {}
		}
	end

	local onEdited = nil

	local function fireEvent(name,...)
		local args = {...}
		local event = events[name]
		if event then
			for i,cmd in pairs(event.commands) do
				local metCondition = true
				for idx,set in pairs(event.sets) do
					local argVal = args[idx]
					local cmdSet = cmd[2][idx]
					local condType = set.Type
					if condType == "Player" then
						if cmdSet == 0 then
							metCondition = metCondition and (tostring(Players.LocalPlayer) == argVal)
						elseif cmdSet ~= 1 then
							metCondition = metCondition and table.find(getPlayer(cmdSet,Players.LocalPlayer),argVal)
						end
					elseif condType == "String" then
						if cmdSet ~= 0 then
							metCondition = metCondition and string.find(argVal:lower(),cmdSet:lower())
						end
					elseif condType == "Number" then
						if cmdSet ~= 0 then
							metCondition = metCondition and tonumber(argVal)<=tonumber(cmdSet)
						end
					end
					if not metCondition then break end
				end

				if metCondition then
					pcall(task.spawn(function()
						local cmdStr = cmd[1]
						for count,arg in pairs(args) do
							cmdStr = cmdStr:gsub("%$"..count,arg)
						end
						wait(cmd[3] or 0)
						execCmd(cmdStr)
					end))
				end
			end
		end
	end

	local main = create({
		{1,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderSizePixel=0,Name="EventEditor",Position=UDim2.new(0.5,-175,0,-500),Size=UDim2.new(0,350,0,20),ZIndex=10,}},
		{2,"Frame",{BackgroundColor3=currentShade2,BorderSizePixel=0,Name="TopBar",Parent={1},Size=UDim2.new(1,0,0,20),ZIndex=10,}},
		{3,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={2},Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,0,0.95,0),Text="Event Editor",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=10,}},
		{4,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Close",Parent={2},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{5,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=getcustomasset("infiniteyield/assets/close.png"),Parent={4},Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,10,0,10),ZIndex=10,}},
		{6,"Frame",{BackgroundColor3=currentShade1,BorderSizePixel=0,Name="Content",Parent={1},Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,0,202),ZIndex=10,}},
		{7,"ScrollingFrame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",CanvasSize=UDim2.new(0,0,0,100),Name="List",Parent={6},Position=UDim2.new(0,5,0,5),ScrollBarImageColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),ScrollBarThickness=8,Size=UDim2.new(1,-10,1,-10),TopImage="rbxasset://textures/ui/Scroll/scroll-middle.png",ZIndex=10,}},
		{8,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Holder",Parent={7},Size=UDim2.new(1,0,1,0),ZIndex=10,}},
		{9,"UIListLayout",{Parent={8},SortOrder=2,}},
		{10,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderColor3=Color3.new(0.3137255012989,0.3137255012989,0.3137255012989),BorderSizePixel=0,ClipsDescendants=true,Name="Settings",Parent={6},Position=UDim2.new(1,0,0,0),Size=UDim2.new(0,150,1,0),ZIndex=10,}},
		{11,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),Name="Slider",Parent={10},Position=UDim2.new(0,-150,0,0),Size=UDim2.new(1,0,1,0),ZIndex=10,}},
		{12,"Frame",{BackgroundColor3=Color3.new(0.23529413342476,0.23529413342476,0.23529413342476),BorderColor3=Color3.new(0.3137255012989,0.3137255012989,0.3137255012989),BorderSizePixel=0,Name="Line",Parent={11},Size=UDim2.new(0,1,1,0),ZIndex=10,}},
		{13,"ScrollingFrame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",CanvasSize=UDim2.new(0,0,0,100),Name="List",Parent={11},Position=UDim2.new(0,0,0,25),ScrollBarImageColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),ScrollBarThickness=8,Size=UDim2.new(1,0,1,-25),TopImage="rbxasset://textures/ui/Scroll/scroll-middle.png",ZIndex=10,}},
		{14,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Holder",Parent={13},Size=UDim2.new(1,0,1,0),ZIndex=10,}},
		{15,"UIListLayout",{Parent={14},SortOrder=2,}},
		{16,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={11},Size=UDim2.new(1,0,0,20),Text="Event Settings",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{17,"TextButton",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),Font=3,Name="Close",BorderSizePixel=0,Parent={11},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),Text="<",TextColor3=Color3.new(1,1,1),TextSize=18,ZIndex=10,}},
		{18,"Folder",{Name="Templates",Parent={10},}},
		{19,"Frame",{BackgroundColor3=Color3.new(0.19607844948769,0.19607844948769,0.19607844948769),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),Name="Players",Parent={18},Position=UDim2.new(0,0,0,25),Size=UDim2.new(1,0,0,86),Visible=false,ZIndex=10,}},
		{20,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={19},Size=UDim2.new(1,0,0,20),Text="Choose Players",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{21,"TextLabel",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Any",Parent={19},Position=UDim2.new(0,5,0,42),Size=UDim2.new(1,-10,0,20),Text="Any Player",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{22,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="Button",Parent={21},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{23,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={22},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{24,"TextLabel",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Me",Parent={19},Position=UDim2.new(0,5,0,20),Size=UDim2.new(1,-10,0,20),Text="Me Only",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{25,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="Button",Parent={24},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{26,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={25},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{27,"TextBox",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,ClearTextOnFocus=false,Font=3,Name="Custom",Parent={19},PlaceholderColor3=Color3.new(0.47058826684952,0.47058826684952,0.47058826684952),PlaceholderText="Custom Player Set",Position=UDim2.new(0,5,0,64),Size=UDim2.new(1,-35,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{28,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="CustomButton",Parent={19},Position=UDim2.new(1,-25,0,64),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{29,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={28},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{30,"Frame",{BackgroundColor3=Color3.new(0.19607844948769,0.19607844948769,0.19607844948769),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),Name="Strings",Parent={18},Position=UDim2.new(0,0,0,25),Size=UDim2.new(1,0,0,64),Visible=false,ZIndex=10,}},
		{31,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={30},Size=UDim2.new(1,0,0,20),Text="Choose String",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{32,"TextLabel",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Any",Parent={30},Position=UDim2.new(0,5,0,20),Size=UDim2.new(1,-10,0,20),Text="Any String",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{33,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="Button",Parent={32},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{34,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={33},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{54,"Frame",{BackgroundColor3=Color3.new(0.19607844948769,0.19607844948769,0.19607844948769),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),Name="Numbers",Parent={18},Position=UDim2.new(0,0,0,25),Size=UDim2.new(1,0,0,64),Visible=false,ZIndex=10,}},
		{55,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={54},Size=UDim2.new(1,0,0,20),Text="Choose String",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{56,"TextLabel",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Any",Parent={54},Position=UDim2.new(0,5,0,20),Size=UDim2.new(1,-10,0,20),Text="Any Number",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{57,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="Button",Parent={56},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{58,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={57},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{59,"TextBox",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,ClearTextOnFocus=false,Font=3,Name="Custom",Parent={54},PlaceholderColor3=Color3.new(0.47058826684952,0.47058826684952,0.47058826684952),PlaceholderText="Number",Position=UDim2.new(0,5,0,42),Size=UDim2.new(1,-35,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{60,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="CustomButton",Parent={54},Position=UDim2.new(1,-25,0,42),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{61,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={60},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{35,"TextBox",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,ClearTextOnFocus=false,Font=3,Name="Custom",Parent={30},PlaceholderColor3=Color3.new(0.47058826684952,0.47058826684952,0.47058826684952),PlaceholderText="Match String",Position=UDim2.new(0,5,0,42),Size=UDim2.new(1,-35,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{36,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="CustomButton",Parent={30},Position=UDim2.new(1,-25,0,42),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{37,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={36},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{38,"Frame",{BackgroundColor3=Color3.new(0.19607844948769,0.19607844948769,0.19607844948769),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),Name="DelayEditor",Parent={18},Position=UDim2.new(0,0,0,25),Size=UDim2.new(1,0,0,24),Visible=false,ZIndex=10,}},
		{39,"TextBox",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,Font=3,Name="Secs",Parent={38},PlaceholderColor3=Color3.new(0.47058826684952,0.47058826684952,0.47058826684952),Position=UDim2.new(0,60,0,2),Size=UDim2.new(1,-65,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{40,"TextLabel",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Label",Parent={39},Position=UDim2.new(0,-55,0,0),Size=UDim2.new(1,0,1,0),Text="Delay (s):",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{41,"Frame",{BackgroundColor3=currentShade1,BorderSizePixel=0,ClipsDescendants=true,Name="EventTemplate",Parent={6},Size=UDim2.new(1,0,0,20),Visible=false,ZIndex=10,}},
		{42,"TextButton",{BackgroundColor3=currentText1,BackgroundTransparency=1,Font=3,Name="Expand",Parent={41},Size=UDim2.new(0,20,0,20),Text=">",TextColor3=Color3.new(1,1,1),TextSize=18,ZIndex=10,}},
		{43,"TextLabel",{BackgroundColor3=currentText1,BackgroundTransparency=1,Font=3,Name="EventName",Parent={41},Position=UDim2.new(0,25,0,0),Size=UDim2.new(1,-25,0,20),Text="OnSpawn",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{44,"Frame",{BackgroundColor3=Color3.new(0.19607844948769,0.19607844948769,0.19607844948769),BorderSizePixel=0,BackgroundTransparency=1,ClipsDescendants=true,Name="Cmds",Parent={41},Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),ZIndex=10,}},
		{45,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BorderColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),Name="Add",Parent={44},Position=UDim2.new(0,0,1,-20),Size=UDim2.new(1,0,0,20),ZIndex=10,}},
		{46,"TextBox",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClearTextOnFocus=false,Font=3,Parent={45},PlaceholderColor3=Color3.new(0.7843137383461,0.7843137383461,0.7843137383461),PlaceholderText="Add new command",Position=UDim2.new(0,5,0,0),Size=UDim2.new(1,-10,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{47,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Holder",Parent={44},Size=UDim2.new(1,0,1,-20),ZIndex=10,}},
		{48,"UIListLayout",{Parent={47},SortOrder=2,}},
		{49,"Frame",{currentShade1,BorderSizePixel=0,ClipsDescendants=true,Name="CmdTemplate",Parent={6},Size=UDim2.new(1,0,0,20),Visible=false,ZIndex=10,}},
		{50,"TextBox",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClearTextOnFocus=false,Font=3,Parent={49},PlaceholderColor3=Color3.new(1,1,1),Position=UDim2.new(0,5,0,0),Size=UDim2.new(1,-45,0,20),Text="a\\b\\c\\d",TextColor3=currentText1,TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{51,"TextButton",{BackgroundColor3=currentShade1,BorderSizePixel=0,Font=3,Name="Delete",Parent={49},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),Text="X",TextColor3=Color3.new(1,1,1),TextSize=18,ZIndex=10,}},
		{52,"TextButton",{BackgroundColor3=currentShade1,BorderSizePixel=0,Font=3,Name="Settings",Parent={49},Position=UDim2.new(1,-40,0,0),Size=UDim2.new(0,20,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=18,ZIndex=10,}},
		{53,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=getcustomasset("infiniteyield/assets/settings.png"),Parent={52},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),ZIndex=10,}},
	})
	main.Name = randomString()
	local mainFrame = main:WaitForChild("Content")
	local eventList = mainFrame:WaitForChild("List")
	local eventListHolder = eventList:WaitForChild("Holder")
	local cmdTemplate = mainFrame:WaitForChild("CmdTemplate")
	local eventTemplate = mainFrame:WaitForChild("EventTemplate")
	local settingsFrame = mainFrame:WaitForChild("Settings"):WaitForChild("Slider")
	local settingsTemplates = mainFrame.Settings:WaitForChild("Templates")
	local settingsList = settingsFrame:WaitForChild("List"):WaitForChild("Holder")
	table.insert(shade2,main.TopBar) table.insert(shade1,mainFrame) table.insert(shade2,eventTemplate)
	table.insert(text1,eventTemplate.EventName) table.insert(shade1,eventTemplate.Cmds.Add) table.insert(shade1,cmdTemplate)
	table.insert(text1,cmdTemplate.TextBox) table.insert(shade2,cmdTemplate.Delete) table.insert(shade2,cmdTemplate.Settings)
	table.insert(scroll,mainFrame.List) table.insert(shade1,settingsFrame) table.insert(shade2,settingsFrame.Line)
	table.insert(shade2,settingsFrame.Close) table.insert(scroll,settingsFrame.List) table.insert(shade2,settingsTemplates.DelayEditor.Secs)
	table.insert(text1,settingsTemplates.DelayEditor.Secs) table.insert(text1,settingsTemplates.DelayEditor.Secs.Label) table.insert(text1,settingsTemplates.Players.Title)
	table.insert(shade3,settingsTemplates.Players.CustomButton) table.insert(shade2,settingsTemplates.Players.Custom) table.insert(text1,settingsTemplates.Players.Custom)
	table.insert(shade3,settingsTemplates.Players.Any.Button) table.insert(shade3,settingsTemplates.Players.Me.Button) table.insert(text1,settingsTemplates.Players.Any)
	table.insert(text1,settingsTemplates.Players.Me) table.insert(text1,settingsTemplates.Strings.Title) table.insert(text1,settingsTemplates.Strings.Any)
	table.insert(shade3,settingsTemplates.Strings.Any.Button) table.insert(shade3,settingsTemplates.Strings.CustomButton) table.insert(text1,settingsTemplates.Strings.Custom)
	table.insert(shade2,settingsTemplates.Strings.Custom)
	table.insert(text1,settingsTemplates.Players.Me) table.insert(text1,settingsTemplates.Numbers.Title) table.insert(text1,settingsTemplates.Numbers.Any)
	table.insert(shade3,settingsTemplates.Numbers.Any.Button) table.insert(shade3,settingsTemplates.Numbers.CustomButton) table.insert(text1,settingsTemplates.Numbers.Custom)
	table.insert(shade2,settingsTemplates.Numbers.Custom)

	local tweenInf = TweenInfo.new(0.25,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)

	local currentlyEditingCmd = nil

	settingsFrame:WaitForChild("Close").MouseButton1Click:Connect(function()
		settingsFrame:TweenPosition(UDim2.new(0,-150,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
	end)

	local function resizeList()
		local size = 0

		for i,v in pairs(eventListHolder:GetChildren()) do
			if v.Name == "EventTemplate" then
				size = size + 20
				if v.Expand.Rotation == 90 then
					size = size + 20*(1+(#events[v.EventName:GetAttribute("RawName")].commands or 0))
				end
			end
		end

		TweenService:Create(eventList,tweenInf,{CanvasSize = UDim2.new(0,0,0,size)}):Play()

		if size > eventList.AbsoluteSize.Y then
			eventListHolder.Size = UDim2.new(1,-8,1,0)
		else
			eventListHolder.Size = UDim2.new(1,0,1,0)
		end
	end

	local function resizeSettingsList()
		local size = 0

		for i,v in pairs(settingsList:GetChildren()) do
			if v:IsA("Frame") then
				size = size + v.AbsoluteSize.Y
			end
		end

		settingsList.Parent.CanvasSize = UDim2.new(0,0,0,size)

		if size > settingsList.Parent.AbsoluteSize.Y then
			settingsList.Size = UDim2.new(1,-8,1,0)
		else
			settingsList.Size = UDim2.new(1,0,1,0)
		end
	end

	local function setupCheckbox(button,callback)
		local enabled = button.On.BackgroundTransparency == 0

		local function update()
			button.On.BackgroundTransparency = (enabled and 0 or 1)
		end

		button.On.MouseButton1Click:Connect(function()
			enabled = not enabled
			update()
			if callback then callback(enabled) end
		end)

		return {
			Toggle = function(nocall) enabled = not enabled update() if not nocall and callback then callback(enabled) end end,
			Enable = function(nocall) if enabled then return end enabled = true update()if not nocall and callback then callback(enabled) end end,
			Disable = function(nocall) if not enabled then return end enabled = false update()if not nocall and callback then callback(enabled) end end,
			IsEnabled = function() return enabled end
		}
	end

	local function openSettingsEditor(event,cmd)
		currentlyEditingCmd = cmd

		for i,v in pairs(settingsList:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end

		local delayEditor = settingsTemplates.DelayEditor:Clone()
		delayEditor.Secs.FocusLost:Connect(function()
			cmd[3] = tonumber(delayEditor.Secs.Text) or 0
			delayEditor.Secs.Text = cmd[3]
			if onEdited then onEdited() end
		end)
		delayEditor.Secs.Text = cmd[3]
		delayEditor.Visible = true
		table.insert(shade2,delayEditor.Secs)
		table.insert(text1,delayEditor.Secs)
		table.insert(text1,delayEditor.Secs.Label)
		delayEditor.Parent = settingsList

		for i,v in pairs(event.sets) do
			if v.Type == "Player" then
				local template = settingsTemplates.Players:Clone()
				template.Title.Text = v.Name or "Player"

				local me,any,custom

				me = setupCheckbox(template.Me.Button,function(on)
					if not on then return end
					any.Disable()
					custom.Disable()
					cmd[2][i] = 0
					if onEdited then onEdited() end
				end)

				any = setupCheckbox(template.Any.Button,function(on)
					if not on then return end
					me.Disable()
					custom.Disable()
					cmd[2][i] = 1
					if onEdited then onEdited() end
				end)

				local customTextBox = template.Custom
				custom = setupCheckbox(template.CustomButton,function(on)
					if not on then return end
					me.Disable()
					any.Disable()
					cmd[2][i] = customTextBox.Text
					if onEdited then onEdited() end
				end)

				ViewportTextBox.convert(customTextBox)
				customTextBox.FocusLost:Connect(function()
					if custom:IsEnabled() then
						cmd[2][i] = customTextBox.Text
						if onEdited then onEdited() end
					end
				end)

				local cVal = cmd[2][i]
				if cVal == 0 then
					me:Enable()
				elseif cVal == 1 then
					any:Enable()
				else
					custom:Enable()
					customTextBox.Text = cVal
				end

				template.Visible = true
				table.insert(text1,template.Title)
				table.insert(shade3,template.CustomButton)
				table.insert(shade3,template.Any.Button)
				table.insert(shade3,template.Me.Button)
				table.insert(text1,template.Any)
				table.insert(text1,template.Me)
				template.Parent = settingsList
			elseif v.Type == "String" then
				local template = settingsTemplates.Strings:Clone()
				template.Title.Text = v.Name or "String"

				local any,custom

				any = setupCheckbox(template.Any.Button,function(on)
					if not on then return end
					custom.Disable()
					cmd[2][i] = 0
					if onEdited then onEdited() end
				end)

				local customTextBox = template.Custom
				custom = setupCheckbox(template.CustomButton,function(on)
					if not on then return end
					any.Disable()
					cmd[2][i] = customTextBox.Text
					if onEdited then onEdited() end
				end)

				ViewportTextBox.convert(customTextBox)
				customTextBox.FocusLost:Connect(function()
					if custom:IsEnabled() then
						cmd[2][i] = customTextBox.Text
						if onEdited then onEdited() end
					end
				end)

				local cVal = cmd[2][i]
				if cVal == 0 then
					any:Enable()
				else
					custom:Enable()
					customTextBox.Text = cVal
				end

				template.Visible = true
				table.insert(text1,template.Title)
				table.insert(text1,template.Any)
				table.insert(shade3,template.Any.Button)
				table.insert(shade3,template.CustomButton)
				template.Parent = settingsList
			elseif v.Type == "Number" then
				local template = settingsTemplates.Numbers:Clone()
				template.Title.Text = v.Name or "Number"

				local any,custom

				any = setupCheckbox(template.Any.Button,function(on)
					if not on then return end
					custom.Disable()
					cmd[2][i] = 0
					if onEdited then onEdited() end
				end)

				local customTextBox = template.Custom
				custom = setupCheckbox(template.CustomButton,function(on)
					if not on then return end
					any.Disable()
					cmd[2][i] = customTextBox.Text
					if onEdited then onEdited() end
				end)

				ViewportTextBox.convert(customTextBox)
				customTextBox.FocusLost:Connect(function()
					cmd[2][i] = tonumber(customTextBox.Text) or 0
					customTextBox.Text = cmd[2][i]
					if custom:IsEnabled() then
						if onEdited then onEdited() end
					end
				end)

				local cVal = cmd[2][i]
				if cVal == 0 then
					any:Enable()
				else
					custom:Enable()
					customTextBox.Text = cVal
				end

				template.Visible = true
				table.insert(text1,template.Title)
				table.insert(text1,template.Any)
				table.insert(shade3,template.Any.Button)
				table.insert(shade3,template.CustomButton)
				template.Parent = settingsList
			end
		end
		resizeSettingsList()
		settingsFrame:TweenPosition(UDim2.new(0,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
	end

	local function defaultSettings(ev)
		local res = {}

		for i,v in pairs(ev.sets) do
			if v.Type == "Player" then
				res[#res+1] = v.Default or 0
			elseif v.Type == "String" then
				res[#res+1] = v.Default or 0
			elseif v.Type == "Number" then
				res[#res+1] = v.Default or 0
			end
		end

		return res
	end

	local function refreshList()
		for i,v in pairs(eventListHolder:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end

		for name,event in pairs(events) do
			local eventF = eventTemplate:Clone()
			eventF.EventName.Text = name
			eventF.Visible = true
			eventF.EventName:SetAttribute("RawName", name)
			table.insert(shade2,eventF)
			table.insert(text1,eventF.EventName)
			table.insert(shade1,eventF.Cmds.Add)

			local expanded = false
			eventF.Expand.MouseButton1Down:Connect(function()
				expanded = not expanded
				eventF:TweenSize(UDim2.new(1,0,0,20 + (expanded and 20*#eventF.Cmds.Holder:GetChildren() or 0)),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
				eventF.Expand.Rotation = expanded and 90 or 0
				resizeList()
			end)

			local function refreshCommands()
				for i,v in pairs(eventF.Cmds.Holder:GetChildren()) do
					if v.Name == "CmdTemplate" then
						v:Destroy()
					end
				end

				eventF.EventName.Text = name..(#event.commands > 0 and " ("..#event.commands..")" or "")

				for i,cmd in pairs(event.commands) do
					local cmdF = cmdTemplate:Clone()
					local cmdTextBox = cmdF.TextBox
					ViewportTextBox.convert(cmdTextBox)
					cmdTextBox.Text = cmd[1]
					cmdF.Visible = true
					table.insert(shade1,cmdF)
					table.insert(shade2,cmdF.Delete)
					table.insert(shade2,cmdF.Settings)

					cmdTextBox.FocusLost:Connect(function()
						event.commands[i] = {cmdTextBox.Text,cmd[2],cmd[3]}
						if onEdited then onEdited() end
					end)

					cmdF.Settings.MouseButton1Click:Connect(function()
						openSettingsEditor(event,cmd)
					end)

					cmdF.Delete.MouseButton1Click:Connect(function()
						table.remove(event.commands,i)
						refreshCommands()
						resizeList()

						if currentlyEditingCmd == cmd then
							settingsFrame:TweenPosition(UDim2.new(0,-150,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
						end
						if onEdited then onEdited() end
					end)

					cmdF.Parent = eventF.Cmds.Holder
				end

				eventF:TweenSize(UDim2.new(1,0,0,20 + (expanded and 20*#eventF.Cmds.Holder:GetChildren() or 0)),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
			end

			local newBox = eventF.Cmds.Add.TextBox
			ViewportTextBox.convert(newBox)
			newBox.FocusLost:Connect(function(enter)
				if enter then
					event.commands[#event.commands+1] = {newBox.Text,defaultSettings(event),0}
					newBox.Text = ""

					refreshCommands()
					resizeList()
					if onEdited then onEdited() end
				end
			end)

			--eventF:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeList)

			eventF.Parent = eventListHolder

			refreshCommands()
		end

		resizeList()
	end

	local function saveData()
		local result = {}
		for i,v in pairs(events) do
			result[i] = v.commands
		end
		return HttpService:JSONEncode(result)
	end

	local function loadData(str)
		local data = HttpService:JSONDecode(str)
		for i,v in pairs(data) do
			if events[i] then
				events[i].commands = v
			end
		end
	end

	local function addCmd(event,data)
		table.insert(events[event].commands,data)
	end

	local function setOnEdited(f)
		if type(f) == "function" then
			onEdited = f
		end
	end

	main.TopBar.Close.MouseButton1Click:Connect(function()
		main:TweenPosition(UDim2.new(0.5,-175,0,-500), "InOut", "Quart", 0.5, true, nil)
	end)
	dragGUI(main)
	main.Parent = ScaledHolder

	return {
		RegisterEvent = registerEvent,
		FireEvent = fireEvent,
		Refresh = refreshList,
		SaveData = saveData,
		LoadData = loadData,
		AddCmd = addCmd,
		Frame = main,
		SetOnEdited = setOnEdited
	}
end)()

reference = (function()
	local main = create({
		{1,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,Name="Main",Position=UDim2.new(0.5,-250,0,-500),Size=UDim2.new(0,500,0,20),ZIndex=10,}},
		{2,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="TopBar",Parent={1},Size=UDim2.new(1,0,0,20),ZIndex=10,}},
		{3,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={2},Size=UDim2.new(1,0,0.94999998807907,0),Text="Reference",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{4,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Close",Parent={2},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{5,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=getcustomasset("infiniteyield/assets/close.png"),Parent={4},Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,10,0,10),ZIndex=10,}},
		{6,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BorderSizePixel=0,Name="Content",Parent={1},Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,0,300),ZIndex=10,}},
		{7,"ScrollingFrame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",CanvasSize=UDim2.new(0,0,0,1313),Name="List",Parent={6},ScrollBarImageColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),ScrollBarThickness=8,Size=UDim2.new(1,0,1,0),TopImage="rbxasset://textures/ui/Scroll/scroll-middle.png",VerticalScrollBarInset=2,ZIndex=10,}},
		{8,"UIListLayout",{Parent={7},SortOrder=2,}},
		{9,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,429),ZIndex=10,}},
		{10,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={9},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Special Player Cases",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{11,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={9},Position=UDim2.new(0,8,0,25),Size=UDim2.new(1,-8,0,20),Text="These keywords can be used to quickly select groups of players in commands:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{12,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={9},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{13,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Cases",Parent={9},Position=UDim2.new(0,8,0,55),Size=UDim2.new(1,-16,0,342),ZIndex=10,}},
		{14,"UIListLayout",{Parent={13},SortOrder=2,}},
		{15,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=-4,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{16,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={15},Size=UDim2.new(1,0,1,0),Text="all",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{17,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={15},Position=UDim2.new(0,15,0,0),Size=UDim2.new(1,0,1,0),Text="- includes everyone",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{18,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=-3,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{19,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={18},Size=UDim2.new(1,0,1,0),Text="others",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{20,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={18},Position=UDim2.new(0,37,0,0),Size=UDim2.new(1,0,1,0),Text="- includes everyone except you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{21,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=-2,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{22,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={21},Size=UDim2.new(1,0,1,0),Text="me",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{23,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={21},Position=UDim2.new(0,19,0,0),Size=UDim2.new(1,0,1,0),Text="- includes your player only",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{24,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{25,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={24},Size=UDim2.new(1,0,1,0),Text="#[number]",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{26,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={24},Position=UDim2.new(0,59,0,0),Size=UDim2.new(1,0,1,0),Text="- gets a specified amount of random players",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{27,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{28,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={27},Size=UDim2.new(1,0,1,0),Text="random",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{29,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={27},Position=UDim2.new(0,44,0,0),Size=UDim2.new(1,0,1,0),Text="- affects a random player",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{30,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{31,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={30},Size=UDim2.new(1,0,1,0),Text="%[team name]",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{32,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={30},Position=UDim2.new(0,78,0,0),Size=UDim2.new(1,0,1,0),Text="- includes everyone on a given team",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{33,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{34,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={33},Size=UDim2.new(1,0,1,0),Text="allies / team",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{35,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={33},Position=UDim2.new(0,63,0,0),Size=UDim2.new(1,0,1,0),Text="- players who are on your team",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{36,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{37,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={36},Size=UDim2.new(1,0,1,0),Text="enemies / nonteam",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{38,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={36},Position=UDim2.new(0,101,0,0),Size=UDim2.new(1,0,1,0),Text="- players who are not on your team",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{39,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{40,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={39},Size=UDim2.new(1,0,1,0),Text="friends",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{41,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={39},Position=UDim2.new(0,40,0,0),Size=UDim2.new(1,0,1,0),Text="- anyone who is friends with you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{42,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{43,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={42},Size=UDim2.new(1,0,1,0),Text="nonfriends",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{44,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={42},Position=UDim2.new(0,61,0,0),Size=UDim2.new(1,0,1,0),Text="- anyone who is not friends with you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{45,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{46,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={45},Size=UDim2.new(1,0,1,0),Text="guests",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{47,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={45},Position=UDim2.new(0,36,0,0),Size=UDim2.new(1,0,1,0),Text="- guest players (obsolete)",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{48,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{49,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={48},Size=UDim2.new(1,0,1,0),Text="bacons",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{50,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={48},Position=UDim2.new(0,40,0,0),Size=UDim2.new(1,0,1,0),Text="- anyone with the \"bacon\" or pal hair",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{51,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{52,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={51},Size=UDim2.new(1,0,1,0),Text="age[number]",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{53,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={51},Position=UDim2.new(0,71,0,0),Size=UDim2.new(1,0,1,0),Text="- includes anyone below or at the given age",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{54,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{55,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={54},Size=UDim2.new(1,0,1,0),Text="rad[number]",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{56,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={54},Position=UDim2.new(0,70,0,0),Size=UDim2.new(1,0,1,0),Text="- includes anyone within the given radius",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{57,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{58,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={57},Size=UDim2.new(1,0,1,0),Text="nearest",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{59,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={57},Position=UDim2.new(0,43,0,0),Size=UDim2.new(1,0,1,0),Text="- gets the closest player to you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{60,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{61,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={60},Size=UDim2.new(1,0,1,0),Text="farthest",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{62,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={60},Position=UDim2.new(0,46,0,0),Size=UDim2.new(1,0,1,0),Text="- gets the farthest player from you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{63,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{64,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={63},Size=UDim2.new(1,0,1,0),Text="group[ID]",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{65,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={63},Position=UDim2.new(0,55,0,0),Size=UDim2.new(1,0,1,0),Text="- gets players who are in a certain group",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{66,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{67,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={66},Size=UDim2.new(1,0,1,0),Text="alive",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{68,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={66},Position=UDim2.new(0,27,0,0),Size=UDim2.new(1,0,1,0),Text="- gets players who are alive",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{69,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{70,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={69},Size=UDim2.new(1,0,1,0),Text="dead",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{71,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={69},Position=UDim2.new(0,29,0,0),Size=UDim2.new(1,0,1,0),Text="- gets players who are dead",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{72,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=-1,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{73,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={72},Size=UDim2.new(1,0,1,0),Text="@username",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{74,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={72},Position=UDim2.new(0,66,0,0),Size=UDim2.new(1,0,1,0),Text="- searches for players by username only (ignores displaynames)",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{75,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,180),ZIndex=10,}},
		{76,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={75},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Various Operators",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{77,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={75},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{78,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={75},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,16),Text="Use commas to separate multiple expressions:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{79,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={75},Position=UDim2.new(0,8,0,75),Size=UDim2.new(1,-8,0,16),Text="Use - to exclude, and + to include players in your expression:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{80,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={75},Position=UDim2.new(0,8,0,91),Size=UDim2.new(1,-8,0,16),Text=";locate %blue-friends (gets players in blue team who aren't your friends)",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{81,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={75},Position=UDim2.new(0,8,0,46),Size=UDim2.new(1,-8,0,16),Text=";locate noob,noob2,bob",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{82,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={75},Position=UDim2.new(0,8,0,120),Size=UDim2.new(1,-8,0,16),Text="Put ! before a command to run it with the last arguments it was ran with:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{83,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={75},Position=UDim2.new(0,8,0,136),Size=UDim2.new(1,-8,0,32),Text="After running ;offset 0 100 0,  you can run !offset anytime to repeat that command with the same arguments that were used to run it last time",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{84,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,154),ZIndex=10,}},
		{85,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={84},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Command Looping",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{86,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={84},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,20),Text="Form: [How many times it loops]^[delay (optional)]^[command]",TextColor3=Color3.new(1,1,1),TextSize=15,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{87,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={84},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{88,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={84},Position=UDim2.new(0,8,0,50),Size=UDim2.new(1,-8,0,20),Text="Use the 'breakloops' command to stop all running loops.",TextColor3=Color3.new(1,1,1),TextSize=15,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{89,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={84},Position=UDim2.new(0,8,0,80),Size=UDim2.new(1,-8,0,16),Text="Examples:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{90,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={84},Position=UDim2.new(0,8,0,98),Size=UDim2.new(1,-8,0,42),Text=";5^btools - gives you 5 sets of btools\n;10^3^drophats - drops your hats every 3 seconds 10 times\n;inf^0.1^animspeed 100 - infinitely loops your animation speed to 100",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{91,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,120),ZIndex=10,}},
		{92,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={91},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Execute Multiple Commands at Once",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{93,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={91},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,20),Text="You can execute multiple commands at once using \"\\\"",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{94,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={91},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{95,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={91},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,-8,0,16),Text="Examples:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{96,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={91},Position=UDim2.new(0,8,0,78),Size=UDim2.new(1,-8,0,32),Text=";drophats\\respawn - drops your hats and respawns you\n;enable inventory\\enable playerlist\\refresh - enables those coregui items and refreshes you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{97,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,75),ZIndex=10,}},
		{98,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={97},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Browse Command History",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{99,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={97},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,32),Text="While focused on the command bar, you can use the up and down arrow keys to browse recently used commands",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{100,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={97},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{101,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,75),ZIndex=10,}},
		{102,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={101},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Autocomplete in the Command Bar",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{103,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={101},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,32),Text="While focused on the command bar, you can use the tab key to insert the top suggested command into the command bar.",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{104,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={101},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{105,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,175),ZIndex=10,}},
		{106,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={105},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Using Event Binds",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{107,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={105},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,32),Text="Use event binds to set up commands that get executed when certain events happen. You can edit the conditions for an event command to run (such as which player triggers it).",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{108,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={105},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{109,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={105},Position=UDim2.new(0,8,0,70),Size=UDim2.new(1,-8,0,48),Text="Some events may send arguments; you can use them in your event command by using $ followed by the argument number ($1, $2, etc). You can find out the order and types of these arguments by looking at the settings of the event command.",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{110,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={105},Position=UDim2.new(0,8,0,130),Size=UDim2.new(1,-8,0,16),Text="Example:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{111,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={105},Position=UDim2.new(0,8,0,148),Size=UDim2.new(1,-8,0,16),Text="Setting up 'goto $1' on the OnChatted event will teleport you to any player that chats.",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
	})
	for i,v in pairs(main.Content.List:GetDescendants()) do
		if v:IsA("TextLabel") then
			table.insert(text1,v)
		end
	end
	table.insert(scroll,main.Content.List)
	table.insert(shade1,main.Content)
	table.insert(shade2,main.TopBar)
	main.Name = randomString()
	main.TopBar.Close.MouseButton1Click:Connect(function()
		main:TweenPosition(UDim2.new(0.5,-250,0,-500), "InOut", "Quart", 0.5, true, nil)
	end)
	dragGUI(main)
	main.Parent = ScaledHolder

	ReferenceButton.MouseButton1Click:Connect(function()
		main:TweenPosition(UDim2.new(0.5,-250,0.5,-150), "InOut", "Quart", 0.5, true, nil)
	end)
end)()

currentShade1 = Color3.fromRGB(2, 2, 4) -- Void
currentShade2 = Color3.fromRGB(4, 4, 6) -- Deep Shadow
currentShade3 = Color3.fromRGB(8, 8, 10) -- Shadow
currentText1 = Color3.fromRGB(255, 255, 255) -- White
currentText2 = Color3.fromRGB(200, 200, 200) -- Light Grey
currentScroll = Color3.fromRGB(12, 12, 15)

defaultGuiScale = IsOnMobile and 0.9 or 1
defaultsettings = {
	prefix = ';';
	StayOpen = false;
	guiScale = defaultGuiScale;
	espTransparency = 0.3;
	keepIY = true;
	logsEnabled = false;
	jLogsEnabled = false;
	binds = {};
	WayPoints = {};
	PluginsTable = {};
	currentShade1 = {currentShade1.R,currentShade1.G,currentShade1.B};
	currentShade2 = {currentShade2.R,currentShade2.G,currentShade2.B};
	currentShade3 = {currentShade3.R,currentShade3.G,currentShade3.B};
	currentText1 = {currentText1.R,currentText1.G,currentText1.B};
	currentText2 = {currentText2.R,currentText2.G,currentText2.B};
	currentScroll = {currentScroll.R,currentScroll.G,currentScroll.B};
	eventBinds = eventEditor.SaveData()
}
getgenv().binds = binds
getgenv().aliases = aliases

defaults = HttpService:JSONEncode(defaultsettings)
nosaves = false
useFactorySettings = function()
	prefix = ';'
	StayOpen = false
	guiScale = defaultGuiScale
	KeepInfYield = true
	espTransparency = 0.3
	logsEnabled = false
	jLogsEnabled = false
	logsWebhook = nil
	aliases = {}
	binds = {}
	WayPoints = {}
	PluginsTable = {}
end

function createPopup(title, text)
	local Popup = Instance.new("Frame")
	local background = Instance.new("Frame")
	local Directions = Instance.new("TextLabel")
	local shadow = Instance.new("Frame")
	local PopupText = Instance.new("TextLabel")
	local Exit = Instance.new("TextButton")
	local ExitImage = Instance.new("ImageLabel")

	Popup.Name = randomString()
	Popup.Parent = ScaledHolder
	Popup.Active = true
	Popup.BackgroundTransparency = 1
	Popup.Position = UDim2.new(0.5, -180, 0, -500)
	Popup.Size = UDim2.new(0, 360, 0, 20)
	Popup.ZIndex = 10

	background.Name = "background"
	background.Parent = Popup
	background.Active = true
	background.BackgroundColor3 = Color3.fromRGB(1, 1, 2)
	background.BorderSizePixel = 0
	background.Position = UDim2.new(0, 0, 0, 20)
	background.Size = UDim2.new(0, 360, 0, 205)
	background.ZIndex = 10

	Directions.Name = "Directions"
	Directions.Parent = background
	Directions.BackgroundTransparency = 1
	Directions.BorderSizePixel = 0
	Directions.Position = UDim2.new(0, 10, 0, 10)
	Directions.Size = UDim2.new(0, 340, 0, 185)
	Directions.Font = Enum.Font.SourceSans
	Directions.TextSize = 14
	Directions.Text = text
	Directions.TextColor3 = Color3.new(1, 1, 1)
	Directions.TextWrapped = true
	Directions.TextXAlignment = Enum.TextXAlignment.Left
	Directions.TextYAlignment = Enum.TextYAlignment.Top
	Directions.ZIndex = 10

	shadow.Name = "shadow"
	shadow.Parent = Popup
	shadow.BackgroundColor3 = Color3.fromRGB(30, 30, 33)
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.new(0, 360, 0, 20)
	shadow.ZIndex = 10

	PopupText.Name = "PopupText"
	PopupText.Parent = shadow
	PopupText.BackgroundTransparency = 1
	PopupText.Size = UDim2.new(1, 0, 0.95, 0)
	PopupText.ZIndex = 10
	PopupText.Font = Enum.Font.SourceSans
	PopupText.TextSize = 14
	PopupText.Text = title
	PopupText.TextColor3 = Color3.new(1, 1, 1)
	PopupText.TextWrapped = true

	Exit.Name = "Exit"
	Exit.Parent = shadow
	Exit.BackgroundTransparency = 1
	Exit.Position = UDim2.new(1, -20, 0, 0)
	Exit.Size = UDim2.new(0, 20, 0, 20)
	Exit.Text = ""
	Exit.ZIndex = 10

	ExitImage.Parent = Exit
	ExitImage.BackgroundColor3 = Color3.new(1, 1, 1)
	ExitImage.BackgroundTransparency = 1
	ExitImage.Position = UDim2.new(0, 5, 0, 5)
	ExitImage.Size = UDim2.new(0, 10, 0, 10)
	ExitImage.Image = getcustomasset("infiniteyield/assets/close.png")
	ExitImage.ZIndex = 10

	Popup:TweenPosition(UDim2.new(0.5, -180, 0, 150), "InOut", "Quart", 0.5, true, nil)

	Exit.MouseButton1Click:Connect(function()
		Popup:TweenPosition(UDim2.new(0.5, -180, 0, -500), "InOut", "Quart", 0.5, true, nil)
		task.wait(0.6)
		Popup:Destroy()
	end)
end

local loadedEventData = nil
local jsonAttempts = 0
function saves()
	if writefileExploit() and readfileExploit() and jsonAttempts < 10 then
		local readSuccess, out = readfile("IY_FE.iy", true)
		if readSuccess then
			if out ~= nil and tostring(out):gsub("%s", "") ~= "" then
				local success, response = pcall(function()
					local json = HttpService:JSONDecode(out)
					if vtype(json.prefix, "string") then prefix = json.prefix else prefix = ';' end
					if vtype(json.StayOpen, "boolean") then StayOpen = json.StayOpen else StayOpen = false end
					if vtype(json.guiScale, "number") then guiScale = json.guiScale else guiScale = defaultGuiScale end
					if vtype(json.keepIY, "boolean") then KeepInfYield = json.keepIY else KeepInfYield = true end
					if vtype(json.espTransparency, "number") then espTransparency = json.espTransparency else espTransparency = 0.3 end
					if vtype(json.logsEnabled, "boolean") then logsEnabled = json.logsEnabled else logsEnabled = false end
					if vtype(json.jLogsEnabled, "boolean") then jLogsEnabled = json.jLogsEnabled else jLogsEnabled = false end
					if vtype(json.logsWebhook, "string") then logsWebhook = json.logsWebhook else logsWebhook = nil end
					if vtype(json.aliases, "table") then aliases = json.aliases else aliases = {} end
					if vtype(json.binds, "table") then binds = json.binds else binds = {} end
					if vtype(json.spawnCmds, "table") then spawnCmds = json.spawnCmds end
					if vtype(json.WayPoints, "table") then AllWaypoints = json.WayPoints else WayPoints = {} AllWaypoints = {} end
					if vtype(json.PluginsTable, "table") then PluginsTable = json.PluginsTable else PluginsTable = {} end
					if vtype(json.currentShade1, "table") then currentShade1 = Color3.new(json.currentShade1[1],json.currentShade1[2],json.currentShade1[3]) end
					if vtype(json.currentShade2, "table") then currentShade2 = Color3.new(json.currentShade2[1],json.currentShade2[2],json.currentShade2[3]) end
					if vtype(json.currentShade3, "table") then currentShade3 = Color3.new(json.currentShade3[1],json.currentShade3[2],json.currentShade3[3]) end
					if vtype(json.currentText1, "table") then currentText1 = Color3.new(json.currentText1[1],json.currentText1[2],json.currentText1[3]) end
					if vtype(json.currentText2, "table") then currentText2 = Color3.new(json.currentText2[1],json.currentText2[2],json.currentText2[3]) end
					if vtype(json.currentScroll, "table") then currentScroll = Color3.new(json.currentScroll[1],json.currentScroll[2],json.currentScroll[3]) end
					if vtype(json.eventBinds, "string") then loadedEventData = json.eventBinds end
				end)
				if not success then
					jsonAttempts = jsonAttempts + 1
					warn("Save Json Error:", response)
					warn("Overwriting Save File")
					writefile("IY_FE.iy", defaults, true)
					wait()
					saves()
				end
			else
				writefile("IY_FE.iy", defaults, true)
				wait()
				local dReadSuccess, dOut = readfile("IY_FE.iy", true)
				if dReadSuccess and dOut ~= nil and tostring(dOut):gsub("%s", "") ~= "" then
					saves()
				else
					nosaves = true
					useFactorySettings()
					createPopup("File Error", "There was a problem writing a save file to your PC.\n\nPlease contact the developer/support team for your exploit and tell them writefile/readfile is not working.\n\nYour settings, keybinds, waypoints, and aliases will not save if you continue.\n\nThings to try:\n> Make sure a 'workspace' folder is located in the same folder as your exploit\n> If your exploit is inside of a zip/rar file, extract it.\n> Rejoin the game and try again or restart your PC and try again.")
				end
			end
		else
			writefile("IY_FE.iy", defaults, true)
			wait()
			local dReadSuccess, dOut = readfile("IY_FE.iy", true)
			if dReadSuccess and dOut ~= nil and tostring(dOut):gsub("%s", "") ~= "" then
				saves()
			else
				nosaves = true
				useFactorySettings()
				createPopup("File Error", "There was a problem writing a save file to your PC.\n\nPlease contact the developer/support team for your exploit and tell them writefile/readfile is not working.\n\nYour settings, keybinds, waypoints, and aliases will not save if you continue.\n\nThings to try:\n> Make sure a 'workspace' folder is located in the same folder as your exploit\n> If your exploit is inside of a zip/rar file, extract it.\n> Rejoin the game and try again or restart your PC and try again.")
			end
		end
	else
		if jsonAttempts >= 10 then
			nosaves = true
			useFactorySettings()
			createPopup("File Error", "Sorry, we have attempted to parse your save file, but it is unreadable!\n\nInfinite Yield is now using factory settings until your exploit's file system works.\n\nYour save file has not been deleted.")
		else
			nosaves = true
			useFactorySettings()
		end
	end
end

saves()
getgenv().binds = binds
getgenv().aliases = aliases
getgenv().PluginsTable = PluginsTable
getgenv().prefix = prefix
getgenv().StayOpen = StayOpen


function updatesaves()
getgenv().updatesaves = updatesaves
	if nosaves == false and writefileExploit() then
		local update = {
			prefix = prefix;
			StayOpen = StayOpen;
			guiScale = guiScale;
			keepIY = KeepInfYield;
			espTransparency = espTransparency;
			logsEnabled = logsEnabled;
			jLogsEnabled = jLogsEnabled;
			logsWebhook = logsWebhook;
			aliases = aliases;
			binds = binds or {};
			WayPoints = AllWaypoints;
			PluginsTable = PluginsTable;
			currentShade1 = {currentShade1.R,currentShade1.G,currentShade1.B};
			currentShade2 = {currentShade2.R,currentShade2.G,currentShade2.B};
			currentShade3 = {currentShade3.R,currentShade3.G,currentShade3.B};
			currentText1 = {currentText1.R,currentText1.G,currentText1.B};
			currentText2 = {currentText2.R,currentText2.G,currentText2.B};
			currentScroll = {currentScroll.R,currentScroll.G,currentScroll.B};
			eventBinds = eventEditor.SaveData()
		}
		writefileCooldown("IY_FE.iy", HttpService:JSONEncode(update))
	end
end

eventEditor.SetOnEdited(updatesaves)

pWayPoints = {}
WayPoints = {}

if #AllWaypoints > 0 then
	for i = 1, #AllWaypoints do
		if not AllWaypoints[i].GAME or AllWaypoints[i].GAME == PlaceId then
			WayPoints[#WayPoints + 1] = {NAME = AllWaypoints[i].NAME, COORD = {AllWaypoints[i].COORD[1], AllWaypoints[i].COORD[2], AllWaypoints[i].COORD[3]}, GAME = AllWaypoints[i].GAME}
		end
	end
end

if type(binds) ~= "table" then binds = {} end
getgenv().binds = binds

if type(PluginsTable) == "table" then
	for i = #PluginsTable, 1, -1 do
		if string.sub(PluginsTable[i], -3) ~= ".iy" then
			table.remove(PluginsTable, i)
		end
	end
end

function Time()
	local HOUR = math.floor((tick() % 86400) / 3600)
	local MINUTE = math.floor((tick() % 3600) / 60)
	local SECOND = math.floor(tick() % 60)
	local AP = HOUR > 11 and 'PM' or 'AM'
	HOUR = (HOUR % 12 == 0 and 12 or HOUR % 12)
	HOUR = HOUR < 10 and '0' .. HOUR or HOUR
	MINUTE = MINUTE < 10 and '0' .. MINUTE or MINUTE
	SECOND = SECOND < 10 and '0' .. SECOND or SECOND
	return HOUR .. ':' .. MINUTE .. ':' .. SECOND .. ' ' .. AP
end

PrefixBox.Text = prefix
local SettingsOpen = false
local isHidden = false

if StayOpen == false then
	On.BackgroundTransparency = 1
else
	On.BackgroundTransparency = 0
end

if logsEnabled then
	Toggle.Text = 'Enabled'
else
	Toggle.Text = 'Disabled'
end

if jLogsEnabled then
	Toggle_2.Text = 'Enabled'
else
	Toggle_2.Text = 'Disabled'
end

function maximizeHolder()
	if StayOpen == false then
		Holder.Position = UDim2.new(1, Holder.Position.X.Offset, 1, -220)
	end
end

minimizeNum = -20
function minimizeHolder()
	if StayOpen == false then
		Holder.Position = UDim2.new(1, Holder.Position.X.Offset, 1, minimizeNum)
	end
end

function cmdbarHolder()
	if StayOpen == false then
		Holder.Position = UDim2.new(1, Holder.Position.X.Offset, 1, -45)
	end
end

pinNotification = nil
local notifyCount = 0
function notify(text,text2,length)
	-- SIRIUS: Route IY notifications through Sirius notification system
	task.spawn(function()
		local title = "Infinite Yield"
		local body = tostring(text)
		if text2 then
			title = body
			body = tostring(text2)
		end
		if getgenv().queueNotification then
			getgenv().queueNotification(title, body, 9134780101)
		end
	end)
end
local function _notifyOld(text,text2,length)
	task.spawn(function()
		local LnotifyCount = notifyCount+1
		local notificationPinned = false
		notifyCount = notifyCount+1
		if pinNotification then pinNotification:Disconnect() end
		pinNotification = PinButton.MouseButton1Click:Connect(function()
			task.spawn(function()
				pinNotification:Disconnect()
				notificationPinned = true
				Title_2.BackgroundTransparency = 1
				wait(0.5)
				Title_2.BackgroundTransparency = 0
			end)
		end)
		Notification:TweenPosition(UDim2.new(1, Notification.Position.X.Offset, 1, 0), "InOut", "Quart", 0.5, true, nil)
		wait(0.6)
		local closepressed = false
		if text2 then
			Title_2.Text = text
			Text_2.Text = text2
		else
			Title_2.Text = 'Notification'
			Text_2.Text = text
		end
		Notification:TweenPosition(UDim2.new(1, Notification.Position.X.Offset, 1, -100), "InOut", "Quart", 0.5, true, nil)
		CloseButton.MouseButton1Click:Connect(function()
			Notification:TweenPosition(UDim2.new(1, Notification.Position.X.Offset, 1, 0), "InOut", "Quart", 0.5, true, nil)
			closepressed = true
			pinNotification:Disconnect()
		end)
		if length and isNumber(length) then
			wait(length)
		else
			wait(10)
		end
		if LnotifyCount == notifyCount then
			if closepressed == false and notificationPinned == false then
				pinNotification:Disconnect()
				Notification:TweenPosition(UDim2.new(1, Notification.Position.X.Offset, 1, 0), "InOut", "Quart", 0.5, true, nil)
			end
			notifyCount = 0
		end
	end)
end

local lastMessage = nil
local lastLabel = nil
local dupeCount = 1
function CreateLabel(Name, Text)
	if lastMessage == Name..Text then
		dupeCount = dupeCount+1
		lastLabel.Text = Time()..' - ['..Name..']: '..Text..' (x'..dupeCount..')'
	else
		if dupeCount > 1 then dupeCount = 1 end
		if #scroll_2:GetChildren() >= 2546 then
			scroll_2:ClearAllChildren()
		end
		local alls = 0
		for i,v in pairs(scroll_2:GetChildren()) do
			if v then
				alls = v.Size.Y.Offset + alls
			end
			if not v then
				alls = 0
			end
		end
		local tl = Instance.new('TextLabel')
		lastMessage = Name..Text
		lastLabel = tl
		tl.Name = Name
		tl.Parent = scroll_2
		tl.ZIndex = 10
		tl.RichText = true
		tl.Text = Time().." - ["..Name.."]: "..Text
		tl.Text = tl.ContentText
		tl.Size = UDim2.new(0,322,0,84)
		tl.BackgroundTransparency = 1
		tl.BorderSizePixel = 0
		tl.Font = "SourceSans"
		tl.Position = UDim2.new(-1,0,0,alls)
		tl.TextTransparency = 1
		tl.TextScaled = false
		tl.TextSize = 14
		tl.TextWrapped = true
		tl.TextXAlignment = "Left"
		tl.TextYAlignment = "Top"
		tl.TextColor3 = currentText1
		tl.Size = UDim2.new(0,322,0,tl.TextBounds.Y)
		table.insert(text1,tl)
		scroll_2.CanvasSize = UDim2.new(0,0,0,alls+tl.TextBounds.Y)
		scroll_2.CanvasPosition = Vector2.new(0,scroll_2.CanvasPosition.Y+tl.TextBounds.Y)
		tl:TweenPosition(UDim2.new(0,3,0,alls), 'In', 'Quint', 0.5)
		TweenService:Create(tl, TweenInfo.new(1.25, Enum.EasingStyle.Linear), { TextTransparency = 0 }):Play()
	end
end

function CreateJoinLabel(plr,ID)
	if #scroll_3:GetChildren() >= 2546 then
		scroll_3:ClearAllChildren()
	end
	local infoFrame = Instance.new("Frame")
	local info1 = Instance.new("TextLabel")
	local info2 = Instance.new("TextLabel")
	local ImageLabel_3 = Instance.new("ImageLabel")
	infoFrame.Name = randomString()
	infoFrame.Parent = scroll_3
	infoFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	infoFrame.BackgroundTransparency = 1
	infoFrame.BorderColor3 = Color3.new(0.105882, 0.164706, 0.207843)
	infoFrame.Size = UDim2.new(1, 0, 0, 50)
	info1.Name = randomString()
	info1.Parent = infoFrame
	info1.BackgroundTransparency = 1
	info1.BorderSizePixel = 0
	info1.Position = UDim2.new(0, 45, 0, 0)
	info1.Size = UDim2.new(0, 135, 1, 0)
	info1.ZIndex = 10
	info1.Font = Enum.Font.SourceSans
	info1.FontSize = Enum.FontSize.Size14
	info1.Text = "Username: "..plr.Name.."\nJoined Server: "..Time()
	info1.TextColor3 = Color3.new(1, 1, 1)
	info1.TextWrapped = true
	info1.TextXAlignment = Enum.TextXAlignment.Left
	info2.Name = randomString()
	info2.Parent = infoFrame
	info2.BackgroundTransparency = 1
	info2.BorderSizePixel = 0
	info2.Position = UDim2.new(0, 185, 0, 0)
	info2.Size = UDim2.new(0, 140, 1, -5)
	info2.ZIndex = 10
	info2.Font = Enum.Font.SourceSans
	info2.FontSize = Enum.FontSize.Size14
	info2.Text = "User ID: "..ID.."\nAccount Age: "..plr.AccountAge.."\nJoined Roblox: Loading..."
	info2.TextColor3 = Color3.new(1, 1, 1)
	info2.TextWrapped = true
	info2.TextXAlignment = Enum.TextXAlignment.Left
	info2.TextYAlignment = Enum.TextYAlignment.Center
	ImageLabel_3.Parent = infoFrame
	ImageLabel_3.BackgroundTransparency = 1
	ImageLabel_3.BorderSizePixel = 0
	ImageLabel_3.Size = UDim2.new(0, 45, 1, 0)
	ImageLabel_3.Image = Players:GetUserThumbnailAsync(ID, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
	scroll_3.CanvasSize = UDim2.new(0, 0, 0, listlayout.AbsoluteContentSize.Y)
	scroll_3.CanvasPosition = Vector2.new(0,scroll_2.CanvasPosition.Y+infoFrame.AbsoluteSize.Y)
	wait()
	local user = game:HttpGet("https://users.roblox.com/v1/users/"..ID)
	local json = HttpService:JSONDecode(user)
	local date = json["created"]:sub(1,10)
	local splitDates = string.split(date,"-")
	info2.Text = string.gsub(info2.Text, "Loading...",splitDates[2].."/"..splitDates[3].."/"..splitDates[1])
end

IYMouse.KeyDown:Connect(function(Key)
	if (Key==prefix) then
		RunService.RenderStepped:Wait()
		Cmdbar:CaptureFocus()
		maximizeHolder()
	end
end)

local lastMinimizeReq = 0
Holder.MouseEnter:Connect(function()
	lastMinimizeReq = 0
	maximizeHolder()
end)

Holder.MouseLeave:Connect(function()
	if not Cmdbar:IsFocused() then
		local reqTime = tick()
		lastMinimizeReq = reqTime
		wait(1)
		if lastMinimizeReq ~= reqTime then return end
		if not Cmdbar:IsFocused() then
			minimizeHolder()
		end
	end
end)

function updateColors(color,ctype)
	if ctype == shade1 then
		for i,v in pairs(shade1) do
			v.BackgroundColor3 = color
		end
		currentShade1 = color
	elseif ctype == shade2 then
		for i,v in pairs(shade2) do
			v.BackgroundColor3 = color
		end
		currentShade2 = color
	elseif ctype == shade3 then
		for i,v in pairs(shade3) do
			v.BackgroundColor3 = color
		end
		currentShade3 = color
	elseif ctype == text1 then
		for i,v in pairs(text1) do
			v.TextColor3 = color
			if v:IsA("TextBox") then
				v.PlaceholderColor3 = color	
			end
		end
		currentText1 = color
	elseif ctype == text2 then
		for i,v in pairs(text2) do
			v.TextColor3 = color
		end
		currentText2 = color
	elseif ctype == scroll then
		for i,v in pairs(scroll) do
			v.ScrollBarImageColor3 = color
		end
		currentScroll = color
	end
end

local colorpickerOpen = false
ColorsButton.MouseButton1Click:Connect(function()
	cache_currentShade1 = currentShade1
	cache_currentShade2 = currentShade2
	cache_currentShade3 = currentShade3
	cache_currentText1 = currentText1
	cache_currentText2 = currentText2
	cache_currentScroll = currentScroll
	if not colorpickerOpen then
		colorpickerOpen = true
		picker = game:GetObjects("rbxassetid://4908465318")[1]
		picker.Name = randomString()
		picker.Parent = ScaledHolder

		local ColorPicker do
			ColorPicker = {}

			ColorPicker.new = function()
				local newMt = setmetatable({},{})

				local pickerGui = picker.ColorPicker
				local pickerTopBar = pickerGui.TopBar
				local pickerExit = pickerTopBar.Exit
				local pickerFrame = pickerGui.Content
				local colorSpace = pickerFrame.ColorSpaceFrame.ColorSpace
				local colorStrip = pickerFrame.ColorStrip
				local previewFrame = pickerFrame.Preview
				local basicColorsFrame = pickerFrame.BasicColors
				local customColorsFrame = pickerFrame.CustomColors
				local defaultButton = pickerFrame.Default
				local cancelButton = pickerFrame.Cancel
				local shade1Button = pickerFrame.Shade1
				local shade2Button = pickerFrame.Shade2
				local shade3Button = pickerFrame.Shade3
				local text1Button = pickerFrame.Text1
				local text2Button = pickerFrame.Text2
				local scrollButton = pickerFrame.Scroll

				local colorScope = colorSpace.Scope
				local colorArrow = pickerFrame.ArrowFrame.Arrow

				local hueInput = pickerFrame.Hue.Input
				local satInput = pickerFrame.Sat.Input
				local valInput = pickerFrame.Val.Input

				local redInput = pickerFrame.Red.Input
				local greenInput = pickerFrame.Green.Input
				local blueInput = pickerFrame.Blue.Input

				local mouse = IYMouse

				local hue,sat,val = 0,0,1
				local red,green,blue = 1,1,1
				local chosenColor = Color3.new(0,0,0)

				local basicColors = {Color3.new(0,0,0),Color3.new(0.66666668653488,0,0),Color3.new(0,0.33333334326744,0),Color3.new(0.66666668653488,0.33333334326744,0),Color3.new(0,0.66666668653488,0),Color3.new(0.66666668653488,0.66666668653488,0),Color3.new(0,1,0),Color3.new(0.66666668653488,1,0),Color3.new(0,0,0.49803924560547),Color3.new(0.66666668653488,0,0.49803924560547),Color3.new(0,0.33333334326744,0.49803924560547),Color3.new(0.66666668653488,0.33333334326744,0.49803924560547),Color3.new(0,0.66666668653488,0.49803924560547),Color3.new(0.66666668653488,0.66666668653488,0.49803924560547),Color3.new(0,1,0.49803924560547),Color3.new(0.66666668653488,1,0.49803924560547),Color3.new(0,0,1),Color3.new(0.66666668653488,0,1),Color3.new(0,0.33333334326744,1),Color3.new(0.66666668653488,0.33333334326744,1),Color3.new(0,0.66666668653488,1),Color3.new(0.66666668653488,0.66666668653488,1),Color3.new(0,1,1),Color3.new(0.66666668653488,1,1),Color3.new(0.33333334326744,0,0),Color3.new(1,0,0),Color3.new(0.33333334326744,0.33333334326744,0),Color3.new(1,0.33333334326744,0),Color3.new(0.33333334326744,0.66666668653488,0),Color3.new(1,0.66666668653488,0),Color3.new(0.33333334326744,1,0),Color3.new(1,1,0),Color3.new(0.33333334326744,0,0.49803924560547),Color3.new(1,0,0.49803924560547),Color3.new(0.33333334326744,0.33333334326744,0.49803924560547),Color3.new(1,0.33333334326744,0.49803924560547),Color3.new(0.33333334326744,0.66666668653488,0.49803924560547),Color3.new(1,0.66666668653488,0.49803924560547),Color3.new(0.33333334326744,1,0.49803924560547),Color3.new(1,1,0.49803924560547),Color3.new(0.33333334326744,0,1),Color3.new(1,0,1),Color3.new(0.33333334326744,0.33333334326744,1),Color3.new(1,0.33333334326744,1),Color3.new(0.33333334326744,0.66666668653488,1),Color3.new(1,0.66666668653488,1),Color3.new(0.33333334326744,1,1),Color3.new(1,1,1)}
				local customColors = {}

				dragGUI(picker)

				local function updateColor(noupdate)
					local relativeX,relativeY,relativeStripY = 219 - hue*219, 199 - sat*199, 199 - val*199
					local hsvColor = Color3.fromHSV(hue,sat,val)

					if noupdate == 2 or not noupdate then
						hueInput.Text = tostring(math.ceil(359*hue))
						satInput.Text = tostring(math.ceil(255*sat))
						valInput.Text = tostring(math.floor(255*val))
					end
					if noupdate == 1 or not noupdate then
						redInput.Text = tostring(math.floor(255*red))
						greenInput.Text = tostring(math.floor(255*green))
						blueInput.Text = tostring(math.floor(255*blue))
					end

					chosenColor = Color3.new(red,green,blue)

					colorScope.Position = UDim2.new(0,relativeX-9,0,relativeY-9)
					colorStrip.ImageColor3 = Color3.fromHSV(hue,sat,1)
					colorArrow.Position = UDim2.new(0,-2,0,relativeStripY-4)
					previewFrame.BackgroundColor3 = chosenColor

					newMt.Color = chosenColor
					if newMt.Changed then newMt:Changed(chosenColor) end
				end

				local function colorSpaceInput()
					local relativeX = mouse.X - colorSpace.AbsolutePosition.X
					local relativeY = mouse.Y - colorSpace.AbsolutePosition.Y

					if relativeX < 0 then relativeX = 0 elseif relativeX > 219 then relativeX = 219 end
					if relativeY < 0 then relativeY = 0 elseif relativeY > 199 then relativeY = 199 end

					hue = (219 - relativeX)/219
					sat = (199 - relativeY)/199

					local hsvColor = Color3.fromHSV(hue,sat,val)
					red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b

					updateColor()
				end

				local function colorStripInput()
					local relativeY = mouse.Y - colorStrip.AbsolutePosition.Y

					if relativeY < 0 then relativeY = 0 elseif relativeY > 199 then relativeY = 199 end	

					val = (199 - relativeY)/199

					local hsvColor = Color3.fromHSV(hue,sat,val)
					red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b

					updateColor()
				end

				local function hookButtons(frame,func)
					frame.ArrowFrame.Up.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							frame.ArrowFrame.Up.BackgroundTransparency = 0.5
						elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
							local releaseEvent,runEvent

							local startTime = tick()
							local pressing = true
							local startNum = tonumber(frame.Text)

							if not startNum then return end

							releaseEvent = UserInputService.InputEnded:Connect(function(input)
								if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
								releaseEvent:Disconnect()
								pressing = false
							end)

							startNum = startNum + 1
							func(startNum)
							while pressing do
								if tick()-startTime > 0.3 then
									startNum = startNum + 1
									func(startNum)
								end
								wait(0.1)
							end
						end
					end)

					frame.ArrowFrame.Up.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							frame.ArrowFrame.Up.BackgroundTransparency = 1
						end
					end)

					frame.ArrowFrame.Down.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							frame.ArrowFrame.Down.BackgroundTransparency = 0.5
						elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
							local releaseEvent,runEvent

							local startTime = tick()
							local pressing = true
							local startNum = tonumber(frame.Text)

							if not startNum then return end

							releaseEvent = UserInputService.InputEnded:Connect(function(input)
								if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
								releaseEvent:Disconnect()
								pressing = false
							end)

							startNum = startNum - 1
							func(startNum)
							while pressing do
								if tick()-startTime > 0.3 then
									startNum = startNum - 1
									func(startNum)
								end
								wait(0.1)
							end
						end
					end)

					frame.ArrowFrame.Down.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							frame.ArrowFrame.Down.BackgroundTransparency = 1
						end
					end)
				end

				colorSpace.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local releaseEvent,mouseEvent

						releaseEvent = UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
							releaseEvent:Disconnect()
							mouseEvent:Disconnect()
						end)

						mouseEvent = UserInputService.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement then
								colorSpaceInput()
							end
						end)

						colorSpaceInput()
					end
				end)

				colorStrip.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local releaseEvent,mouseEvent

						releaseEvent = UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
							releaseEvent:Disconnect()
							mouseEvent:Disconnect()
						end)

						mouseEvent = UserInputService.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement then
								colorStripInput()
							end
						end)

						colorStripInput()
					end
				end)

				local function updateHue(str)
					local num = tonumber(str)
					if num then
						hue = math.clamp(math.floor(num),0,359)/359
						local hsvColor = Color3.fromHSV(hue,sat,val)
						red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
						hueInput.Text = tostring(hue*359)
						updateColor(1)
					end
				end
				hueInput.FocusLost:Connect(function() updateHue(hueInput.Text) end) hookButtons(hueInput,updateHue)

				local function updateSat(str)
					local num = tonumber(str)
					if num then
						sat = math.clamp(math.floor(num),0,255)/255
						local hsvColor = Color3.fromHSV(hue,sat,val)
						red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
						satInput.Text = tostring(sat*255)
						updateColor(1)
					end
				end
				satInput.FocusLost:Connect(function() updateSat(satInput.Text) end) hookButtons(satInput,updateSat)

				local function updateVal(str)
					local num = tonumber(str)
					if num then
						val = math.clamp(math.floor(num),0,255)/255
						local hsvColor = Color3.fromHSV(hue,sat,val)
						red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
						valInput.Text = tostring(val*255)
						updateColor(1)
					end
				end
				valInput.FocusLost:Connect(function() updateVal(valInput.Text) end) hookButtons(valInput,updateVal)

				local function updateRed(str)
					local num = tonumber(str)
					if num then
						red = math.clamp(math.floor(num),0,255)/255
						local newColor = Color3.new(red,green,blue)
						hue,sat,val = Color3.toHSV(newColor)
						redInput.Text = tostring(red*255)
						updateColor(2)
					end
				end
				redInput.FocusLost:Connect(function() updateRed(redInput.Text) end) hookButtons(redInput,updateRed)

				local function updateGreen(str)
					local num = tonumber(str)
					if num then
						green = math.clamp(math.floor(num),0,255)/255
						local newColor = Color3.new(red,green,blue)
						hue,sat,val = Color3.toHSV(newColor)
						greenInput.Text = tostring(green*255)
						updateColor(2)
					end
				end
				greenInput.FocusLost:Connect(function() updateGreen(greenInput.Text) end) hookButtons(greenInput,updateGreen)

				local function updateBlue(str)
					local num = tonumber(str)
					if num then
						blue = math.clamp(math.floor(num),0,255)/255
						local newColor = Color3.new(red,green,blue)
						hue,sat,val = Color3.toHSV(newColor)
						blueInput.Text = tostring(blue*255)
						updateColor(2)
					end
				end
				blueInput.FocusLost:Connect(function() updateBlue(blueInput.Text) end) hookButtons(blueInput,updateBlue)

				local colorChoice = Instance.new("TextButton")
				colorChoice.Name = "Choice"
				colorChoice.Size = UDim2.new(0,25,0,18)
				colorChoice.BorderColor3 = Color3.new(96/255,96/255,96/255)
				colorChoice.Text = ""
				colorChoice.AutoButtonColor = false
				colorChoice.ZIndex = 10

				local row = 0
				local column = 0
				for i,v in pairs(basicColors) do
					local newColor = colorChoice:Clone()
					newColor.BackgroundColor3 = v
					newColor.Position = UDim2.new(0,1 + 30*column,0,21 + 23*row)

					newColor.MouseButton1Click:Connect(function()
						red,green,blue = v.r,v.g,v.b
						local newColor = Color3.new(red,green,blue)
						hue,sat,val = Color3.toHSV(newColor)
						updateColor()
					end)	

					newColor.Parent = basicColorsFrame
					column = column + 1
					if column == 6 then row = row + 1 column = 0 end
				end

				row = 0
				column = 0
				for i = 1,12 do
					local color = customColors[i] or Color3.new(0,0,0)
					local newColor = colorChoice:Clone()
					newColor.BackgroundColor3 = color
					newColor.Position = UDim2.new(0,1 + 30*column,0,20 + 23*row)

					newColor.MouseButton1Click:Connect(function()
						local curColor = customColors[i] or Color3.new(0,0,0)
						red,green,blue = curColor.r,curColor.g,curColor.b
						hue,sat,val = Color3.toHSV(curColor)
						updateColor()
					end)

					newColor.MouseButton2Click:Connect(function()
						customColors[i] = chosenColor
						newColor.BackgroundColor3 = chosenColor
					end)

					newColor.Parent = customColorsFrame
					column = column + 1
					if column == 6 then row = row + 1 column = 0 end
				end

				shade1Button.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,shade1) end end)
				shade1Button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade1Button.BackgroundTransparency = 0.4 end end)
				shade1Button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade1Button.BackgroundTransparency = 0 end end)

				shade2Button.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,shade2) end end)
				shade2Button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade2Button.BackgroundTransparency = 0.4 end end)
				shade2Button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade2Button.BackgroundTransparency = 0 end end)

				shade3Button.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,shade3) end end)
				shade3Button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade3Button.BackgroundTransparency = 0.4 end end)
				shade3Button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade3Button.BackgroundTransparency = 0 end end)

				text1Button.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,text1) end end)
				text1Button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then text1Button.BackgroundTransparency = 0.4 end end)
				text1Button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then text1Button.BackgroundTransparency = 0 end end)

				text2Button.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,text2) end end)
				text2Button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then text2Button.BackgroundTransparency = 0.4 end end)
				text2Button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then text2Button.BackgroundTransparency = 0 end end)

				scrollButton.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,scroll) end end)
				scrollButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then scrollButton.BackgroundTransparency = 0.4 end end)
				scrollButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then scrollButton.BackgroundTransparency = 0 end end)

				cancelButton.MouseButton1Click:Connect(function() if newMt.Cancel then newMt:Cancel() end end)
				cancelButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then cancelButton.BackgroundTransparency = 0.4 end end)
				cancelButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then cancelButton.BackgroundTransparency = 0 end end)

				defaultButton.MouseButton1Click:Connect(function() if newMt.Default then newMt:Default() end end)
				defaultButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then defaultButton.BackgroundTransparency = 0.4 end end)
				defaultButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then defaultButton.BackgroundTransparency = 0 end end)

				pickerExit.MouseButton1Click:Connect(function()
					picker:TweenPosition(UDim2.new(0.5, -219, 0, -500), "InOut", "Quart", 0.5, true, nil)
				end)

				updateColor()

				newMt.SetColor = function(self,color)
					red,green,blue = color.r,color.g,color.b
					hue,sat,val = Color3.toHSV(color)
					updateColor()
				end

				return newMt
			end
		end

		picker:TweenPosition(UDim2.new(0.5, -219, 0, 100), "InOut", "Quart", 0.5, true, nil)

		local Npicker = ColorPicker.new()
		Npicker.Confirm = function(self,color,ctype) updateColors(color,ctype) wait() updatesaves() end
		Npicker.Cancel = function(self)
			updateColors(cache_currentShade1,shade1)
			updateColors(cache_currentShade2,shade2)
			updateColors(cache_currentShade3,shade3)
			updateColors(cache_currentText1,text1)
			updateColors(cache_currentText2,text2)
			updateColors(cache_currentScroll,scroll)
			wait()
			updatesaves()
		end
		Npicker.Default = function(self)
			updateColors(Color3.fromRGB(36, 36, 37),shade1)
			updateColors(Color3.fromRGB(46, 46, 47),shade2)
			updateColors(Color3.fromRGB(78, 78, 79),shade3)
			updateColors(Color3.new(1, 1, 1),text1)
			updateColors(Color3.new(0, 0, 0),text2)
			updateColors(Color3.fromRGB(78,78,79),scroll)
			wait()
			updatesaves()
		end
	else
		picker:TweenPosition(UDim2.new(0.5, -219, 0, 100), "InOut", "Quart", 0.5, true, nil)
	end
end)


SettingsButton.MouseButton1Click:Connect(function()
	if SettingsOpen == false then SettingsOpen = true
		Settings:TweenPosition(UDim2.new(0, 0, 0, 45), "InOut", "Quart", 0.5, true, nil)
		CMDsF.Visible = false
	else SettingsOpen = false
		CMDsF.Visible = true
		Settings:TweenPosition(UDim2.new(0, 0, 0, 220), "InOut", "Quart", 0.5, true, nil)
	end
end)

On.MouseButton1Click:Connect(function()
	if isHidden == false then
		if StayOpen == false then
			StayOpen = true
			On.BackgroundTransparency = 0
		else
			StayOpen = false
			On.BackgroundTransparency = 1
		end
		updatesaves()
	end
end)

Clear.MouseButton1Down:Connect(function()
	for _, child in pairs(scroll_2:GetChildren()) do
		child:Destroy()
	end
	scroll_2.CanvasSize = UDim2.new(0, 0, 0, 10)
end)

Clear_2.MouseButton1Down:Connect(function()
	for _, child in pairs(scroll_3:GetChildren()) do
		child:Destroy()
	end
	scroll_3.CanvasSize = UDim2.new(0, 0, 0, 10)
end)

Toggle.MouseButton1Down:Connect(function()
	if logsEnabled then
		logsEnabled = false
		Toggle.Text = 'Disabled'
		updatesaves()
	else
		logsEnabled = true
		Toggle.Text = 'Enabled'
		updatesaves()
	end
end)

Toggle_2.MouseButton1Down:Connect(function()
	if jLogsEnabled then
		jLogsEnabled = false
		Toggle_2.Text = 'Disabled'
		updatesaves()
	else
		jLogsEnabled = true
		Toggle_2.Text = 'Enabled'
		updatesaves()
	end
end)

selectChat.MouseButton1Down:Connect(function()
	join.Visible = false
	chat.Visible = true
	table.remove(shade3,table.find(shade3,selectChat))
	table.remove(shade2,table.find(shade2,selectJoin))
	table.insert(shade2,selectChat)
	table.insert(shade3,selectJoin)
	selectJoin.BackgroundColor3 = currentShade3
	selectChat.BackgroundColor3 = currentShade2
end)

selectJoin.MouseButton1Down:Connect(function()
	chat.Visible = false
	join.Visible = true	
	table.remove(shade3,table.find(shade3,selectJoin))
	table.remove(shade2,table.find(shade2,selectChat))
	table.insert(shade2,selectJoin)
	table.insert(shade3,selectChat)
	selectChat.BackgroundColor3 = currentShade3
	selectJoin.BackgroundColor3 = currentShade2
end)

if not writefileExploit() then
	notify("Saves", "Your exploit does not support read/write file. Your settings will not save.")
end

avatarcache = {}
function sendChatWebhook(player, message)
	if httprequest and vtype(logsWebhook, "string") then
		local id = player.UserId
		local avatar = avatarcache[id]
		if not avatar then
			local d = HttpService:JSONDecode(httprequest({
				Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. id .. "&size=420x420&format=Png&isCircular=false",
				Method = "GET"
			}).Body)["data"]
			avatar = d and d[1].state == "Completed" and d[1].imageUrl or "https://files.catbox.moe/i968v2.jpg"
			avatarcache[id] = avatar
		end
		local log = HttpService:JSONEncode({
			content = message,
			avatar_url = avatar,
			username = formatUsername(player),
			allowed_mentions = {parse = {}}
		})
		httprequest({
			Url = logsWebhook,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = log
		})
	end
end

ChatLog = function(player)
	player.Chatted:Connect(function(message)
		if logsEnabled == true then
			CreateLabel(player.Name, message)
			sendChatWebhook(player, message)
		end
	end)
end

JoinLog = function(plr)
	if jLogsEnabled == true then
		CreateJoinLabel(plr,plr.UserId)
	end
end

CleanFileName = function(name)
	return tostring(name):gsub("[*\\?:<>|]+", ""):sub(1, 175)
end

SaveChatlogs.MouseButton1Down:Connect(function()
	if writefileExploit() then
		if #scroll_2:GetChildren() > 0 then
			notify("Loading",'Hold on a sec')
			local placeName = CleanFileName(MarketplaceService:GetProductInfo(PlaceId).Name)
			local writelogs = '-- Infinite Yield Chat logs for "'..placeName..'"\n'
			for _, child in pairs(scroll_2:GetChildren()) do
				writelogs = writelogs..'\n'..child.Text
			end
			local writelogsFile = tostring(writelogs)
			local fileext = 0
			local function nameFile()
				local file
				pcall(function() file = readfile(placeName..' Chat Logs ('..fileext..').txt') end)
				if file then
					fileext = fileext+1
					nameFile()
				else
					writefileCooldown(placeName..' Chat Logs ('..fileext..').txt', writelogsFile)
				end
			end
			nameFile()
			notify('Chat Logs','Saved chat logs to the workspace folder within your exploit folder.')
		end
	else
		notify('Chat Logs','Your exploit does not support write file. You cannot save chat logs.')
	end
end)

if isLegacyChat then
	for _, plr in pairs(Players:GetPlayers()) do
		ChatLog(plr)
	end
end

Players.PlayerRemoving:Connect(function(player)
	if ESPenabled or CHMSenabled or COREGUI:FindFirstChild(player.Name..'_LC') then
		for i,v in pairs(COREGUI:GetChildren()) do
			if v.Name == player.Name..'_ESP' or v.Name == player.Name..'_LC' or v.Name == player.Name..'_CHMS' then
				v:Destroy()
			end
		end
	end
	if viewing ~= nil and player == viewing then
		workspace.CurrentCamera.CameraSubject = Players.LocalPlayer.Character
		viewing = nil
		if viewDied then
			viewDied:Disconnect()
			viewChanged:Disconnect()
		end
		notify('Spectate','View turned off (player left)')
	end
	eventEditor.FireEvent("OnLeave", player.Name)
end)

Exit.MouseButton1Down:Connect(function()
	logs:TweenPosition(UDim2.new(0, 0, 1, 10), "InOut", "Quart", 0.3, true, nil)
end)

Hide.MouseButton1Down:Connect(function()
	if logs.Position ~= UDim2.new(0, 0, 1, -20) then
		logs:TweenPosition(UDim2.new(0, 0, 1, -20), "InOut", "Quart", 0.3, true, nil)
	else
		logs:TweenPosition(UDim2.new(0, 0, 1, -265), "InOut", "Quart", 0.3, true, nil)
	end
end)

EventBind.MouseButton1Click:Connect(function()
	eventEditor.Frame:TweenPosition(UDim2.new(0.5,-175,0.5,-101), "InOut", "Quart", 0.5, true, nil)
end)

Keybinds.MouseButton1Click:Connect(function()
	KeybindsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
	wait(0.5)
	SettingsHolder.Visible = false
end)

Close.MouseButton1Click:Connect(function()
	SettingsHolder.Visible = true
	KeybindsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
end)

Keybinds.MouseButton1Click:Connect(function()
	KeybindsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
	wait(0.5)
	SettingsHolder.Visible = false
end)

Add.MouseButton1Click:Connect(function()
	KeybindEditor:TweenPosition(UDim2.new(0.5, -180, 0, 260), "InOut", "Quart", 0.5, true, nil)
end)

Delete.MouseButton1Click:Connect(function()
	binds = {}
	refreshbinds()
	updatesaves()
	notify('Keybinds Updated','Removed all keybinds')
end)

Close_2.MouseButton1Click:Connect(function()
	SettingsHolder.Visible = true
	AliasesFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
end)

Aliases.MouseButton1Click:Connect(function()
	AliasesFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
	wait(0.5)
	SettingsHolder.Visible = false
end)

Close_3.MouseButton1Click:Connect(function()
	SettingsHolder.Visible = true
	PositionsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
end)

Positions.MouseButton1Click:Connect(function()
	PositionsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
	wait(0.5)
	SettingsHolder.Visible = false
end)

local selectionBox = Instance.new("SelectionBox")
selectionBox.Name = randomString()
selectionBox.Color3 = Color3.new(255,255,255)
selectionBox.Adornee = nil
selectionBox.Parent = PARENT

local selected = Instance.new("SelectionBox")
selected.Name = randomString()
selected.Color3 = Color3.new(0,166,0)
selected.Adornee = nil
selected.Parent = PARENT

local ActivateHighlight = nil
local ClickSelect = nil
function selectPart()
	ToPartFrame:TweenPosition(UDim2.new(0.5, -180, 0, 335), "InOut", "Quart", 0.5, true, nil)
	local function HighlightPart()
		if selected.Adornee ~= IYMouse.Target then
			selectionBox.Adornee = IYMouse.Target
		else
			selectionBox.Adornee = nil
		end
	end
	ActivateHighlight = IYMouse.Move:Connect(HighlightPart)
	local function SelectPart()
		if IYMouse.Target ~= nil then
			selected.Adornee = IYMouse.Target
			Path.Text = getHierarchy(IYMouse.Target)
		end
	end
	ClickSelect = IYMouse.Button1Down:Connect(SelectPart)
end

Part.MouseButton1Click:Connect(function()
	selectPart()
end)

Exit_4.MouseButton1Click:Connect(function()
	ToPartFrame:TweenPosition(UDim2.new(0.5, -180, 0, -500), "InOut", "Quart", 0.5, true, nil)
	if ActivateHighlight then
		ActivateHighlight:Disconnect()
	end
	if ClickSelect then
		ClickSelect:Disconnect()
	end
	selectionBox.Adornee = nil
	selected.Adornee = nil
	Path.Text = ""
end)

CopyPath.MouseButton1Click:Connect(function()
	if Path.Text ~= "" then
		toClipboard(Path.Text)
	else
		notify('Copy Path','Select a part to copy its path')
	end
end)

ChoosePart.MouseButton1Click:Connect(function()
	if Path.Text ~= "" then
		local tpNameExt = ''
		local function handleWpNames()
			local FoundDupe = false
			for i,v in pairs(pWayPoints) do
				if v.NAME:lower() == selected.Adornee.Name:lower()..tpNameExt then
					FoundDupe = true
				end
			end
			if not FoundDupe then
				notify('Modified Waypoints',"Created waypoint: "..selected.Adornee.Name..tpNameExt)
				pWayPoints[#pWayPoints + 1] = {NAME = selected.Adornee.Name..tpNameExt, COORD = {selected.Adornee}}
			else
				if isNumber(tpNameExt) then
					tpNameExt = tpNameExt+1
				else
					tpNameExt = 1
				end
				handleWpNames()
			end
		end
		handleWpNames()
		refreshwaypoints()
	else
		notify('Part Selection','Select a part first')
	end
end)

cmds={}
customAlias = {}
Delete_3.MouseButton1Click:Connect(function()
	customAlias = {}
	aliases = {}
	notify('Aliases Modified','Removed all aliases')
	updatesaves()
	refreshaliases()
end)

PrefixBox:GetPropertyChangedSignal("Text"):Connect(function()
	prefix = PrefixBox.Text
	Cmdbar.PlaceholderText = "Command Bar ("..prefix..")"
	updatesaves()
end)

function CamViewport()
	if workspace.CurrentCamera then
		return workspace.CurrentCamera.ViewportSize.X
	end
end

function UpdateToViewport()
	if Holder.Position.X.Offset < -CamViewport() then
		Holder:TweenPosition(UDim2.new(1, -CamViewport(), Holder.Position.Y.Scale, Holder.Position.Y.Offset), "InOut", "Quart", 0.04, true, nil)
		Notification:TweenPosition(UDim2.new(1, -CamViewport() + 250, Notification.Position.Y.Scale, Notification.Position.Y.Offset), "InOut", "Quart", 0.04, true, nil)
	end
end
CameraChanged = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateToViewport)

function updateCamera(child, parent)
	if parent ~= workspace then
		CamMoved:Disconnect()
		CameraChanged:Disconnect()
		repeat wait() until workspace.CurrentCamera
		CameraChanged = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateToViewport)
		CamMoved = workspace.CurrentCamera.AncestryChanged:Connect(updateCamera)
	end
end
CamMoved = workspace.CurrentCamera.AncestryChanged:Connect(updateCamera)

function dragMain(dragpoint,gui)
	task.spawn(function()
		local dragging
		local dragInput
		local dragStart = Vector3.new(0,0,0)
		local startPos
		local function update(input)
			local pos = -250
			local delta = input.Position - dragStart
			if startPos.X.Offset + delta.X <= -500 then
				local Position = UDim2.new(1, -250, Notification.Position.Y.Scale, Notification.Position.Y.Offset)
				TweenService:Create(Notification, TweenInfo.new(.20), {Position = Position}):Play()
				pos = 250
			else
				local Position = UDim2.new(1, -500, Notification.Position.Y.Scale, Notification.Position.Y.Offset)
				TweenService:Create(Notification, TweenInfo.new(.20), {Position = Position}):Play()
				pos = -250
			end
			if startPos.X.Offset + delta.X <= -250 and -CamViewport() <= startPos.X.Offset + delta.X then
				local Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, gui.Position.Y.Scale, gui.Position.Y.Offset)
				TweenService:Create(gui, TweenInfo.new(.20), {Position = Position}):Play()
				local Position2 = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X + pos, Notification.Position.Y.Scale, Notification.Position.Y.Offset)
				TweenService:Create(Notification, TweenInfo.new(.20), {Position = Position2}):Play()
			elseif startPos.X.Offset + delta.X > -500 then
				local Position = UDim2.new(1, -250, gui.Position.Y.Scale, gui.Position.Y.Offset)
				TweenService:Create(gui, TweenInfo.new(.20), {Position = Position}):Play()
			elseif -CamViewport() > startPos.X.Offset + delta.X then
				gui:TweenPosition(UDim2.new(1, -CamViewport(), gui.Position.Y.Scale, gui.Position.Y.Offset), "InOut", "Quart", 0.04, true, nil)
				local Position = UDim2.new(1, -CamViewport(), gui.Position.Y.Scale, gui.Position.Y.Offset)
				TweenService:Create(gui, TweenInfo.new(.20), {Position = Position}):Play()
				local Position2 = UDim2.new(1, -CamViewport() + 250, Notification.Position.Y.Scale, Notification.Position.Y.Offset)
				TweenService:Create(Notification, TweenInfo.new(.20), {Position = Position2}):Play()
			end
		end
		dragpoint.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = gui.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		dragpoint.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				update(input)
			end
		end)
	end)
end

dragMain(Title,Holder)

Match = function(name,str)
	str = str:gsub("%W", "%%%1")
	return name:lower():find(str:lower()) and true
end

local canvasPos = Vector2.new(0,0)
local topCommand = nil
IndexContents = function(str,bool,cmdbar,Ianim)
	CMDsF.CanvasPosition = Vector2.new(0,0)
	local SizeY = 0
	local indexnum = 0
	local frame = CMDsF
	topCommand = nil
	local chunks = {}
	if str:sub(#str,#str) == "\\" then str = "" end
	for w in string.gmatch(str,"[^\\]+") do
		table.insert(chunks,w)
	end
	if #chunks > 0 then str = chunks[#chunks] end
	if str:sub(1,1) == "!" then str = str:sub(2) end
	for i,v in next, frame:GetChildren() do
		if v:IsA("TextButton") then
			if bool then
				if Match(v.Text,str) then
					indexnum = indexnum + 1
					v.Visible = true
					if topCommand == nil then
						topCommand = v.Text
					end
				else
					v.Visible = false
				end
			else
				v.Visible = true
				if topCommand == nil then
					topCommand = v.Text
				end
			end
		end
	end
	frame.CanvasSize = UDim2.new(0,0,0,cmdListLayout.AbsoluteContentSize.Y)
	if not Ianim then
		if indexnum == 0 or string.find(str, " ") then
			if not cmdbar then
				minimizeHolder()
			elseif cmdbar then
				cmdbarHolder()
			end
		else
			maximizeHolder()
		end
	else
		minimizeHolder()
	end
end

task.spawn(function()
	if not isLegacyChat then return end
	local chatbox
	local success, result = pcall(function() chatbox = PlayerGui:WaitForChild("Chat").Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar end)
	if success then
		local function chatboxFocused()
			canvasPos = CMDsF.CanvasPosition
		end
		local chatboxFocusedC = chatbox.Focused:Connect(chatboxFocused)

		local function Index()
			if chatbox.Text:lower():sub(1,1) == prefix then
				if SettingsOpen == true then
					wait(0.2)
					CMDsF.Visible = true
					Settings:TweenPosition(UDim2.new(0, 0, 0, 220), "InOut", "Quart", 0.2, true, nil)
				end
				IndexContents(PlayerGui.Chat.Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar.Text:lower():sub(2),true)
			else
				minimizeHolder()
				if SettingsOpen == true then
					wait(0.2)
					Settings:TweenPosition(UDim2.new(0, 0, 0, 45), "InOut", "Quart", 0.2, true, nil)
					CMDsF.Visible = false
				end
			end
		end
		local chatboxFunc = chatbox:GetPropertyChangedSignal("Text"):Connect(Index)

		local function chatboxFocusLost(enterpressed)
			if not enterpressed or chatbox.Text:lower():sub(1,1) ~= prefix then
				IndexContents('',true)
			end
			CMDsF.CanvasPosition = canvasPos
			minimizeHolder()
		end
		local chatboxFocusLostC = chatbox.FocusLost:Connect(chatboxFocusLost)

		PlayerGui:WaitForChild("Chat").Frame.ChatBarParentFrame.ChildAdded:Connect(function(newbar)
			wait()
			if newbar:FindFirstChild('BoxFrame') then
				chatbox = PlayerGui:WaitForChild("Chat").Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar
				if chatboxFocusedC then chatboxFocusedC:Disconnect() end
				chatboxFocusedC = chatbox.Focused:Connect(chatboxFocused)
				if chatboxFunc then chatboxFunc:Disconnect() end
				chatboxFunc = chatbox:GetPropertyChangedSignal("Text"):Connect(Index)
				if chatboxFocusLostC then chatboxFocusLostC:Disconnect() end
				chatboxFocusLostC = chatbox.FocusLost:Connect(chatboxFocusLost)
			end
		end)
		--else
		--print('Custom chat detected. Will not provide suggestions for commands typed in the chat.')
	end
end)

function autoComplete(str,curText)
	local endingChar = {"[", "/", "(", " "}
	local stop = 0
	for i=1,#str do
		local c = str:sub(i,i)
		if table.find(endingChar, c) then
			stop = i
			break
		end
	end
	curText = curText or Cmdbar.Text
	local subPos = 0
	local pos = 1
	local findRes = string.find(curText,"\\",pos)
	while findRes do
		subPos = findRes
		pos = findRes+1
		findRes = string.find(curText,"\\",pos)
	end
	if curText:sub(subPos+1,subPos+1) == "!" then subPos = subPos + 1 end
	Cmdbar.Text = curText:sub(1,subPos) .. str:sub(1, stop - 1)..' '
	RunService.RenderStepped:Wait()
	Cmdbar.Text = Cmdbar.Text:gsub( '\t', '' )
	Cmdbar.CursorPosition = #Cmdbar.Text+1--1020
end

CMDs = {}
CMDs[#CMDs + 1] = {NAME = 'discord / support / help', DESC = 'Invite to the Infinite Yield discord server.'}
CMDs[#CMDs + 1] = {NAME = 'guiscale [number]', DESC = 'Changes the size of the gui. [number] accepts both decimals and whole numbers. Min is 0.4 and Max is 2'}
CMDs[#CMDs + 1] = {NAME = 'console', DESC = 'Loads Roblox console'}
CMDs[#CMDs + 1] = {NAME = 'oldconsole', DESC = 'Loads old Roblox console'}
CMDs[#CMDs + 1] = {NAME = 'explorer / dex', DESC = 'Opens DEX by Moon'}
CMDs[#CMDs + 1] = {NAME = 'olddex / odex', DESC = 'Opens Old DEX by Moon'}
CMDs[#CMDs + 1] = {NAME = 'remotespy / rspy', DESC = 'Opens Simple Spy V3'}
CMDs[#CMDs + 1] = {NAME = 'executor', DESC = 'Opens an internal executor gui by dnezero'}
CMDs[#CMDs + 1] = {NAME = 'audiologger / alogger', DESC = 'Opens Edges audio logger'}
CMDs[#CMDs + 1] = {NAME = 'serverinfo / info', DESC = 'Gives you info about the server'}
CMDs[#CMDs + 1] = {NAME = 'jobid', DESC = 'Copies the games JobId to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'notifyjobid', DESC = 'Notifies you the games JobId'}
CMDs[#CMDs + 1] = {NAME = 'rejoin / rj', DESC = 'Makes you rejoin the game'}
CMDs[#CMDs + 1] = {NAME = 'autorejoin / autorj', DESC = 'Automatically rejoins the server if you get kicked/disconnected'}
CMDs[#CMDs + 1] = {NAME = 'serverhop / shop', DESC = 'Teleports you to a different server'}
CMDs[#CMDs + 1] = {NAME = 'gameteleport / gametp [place ID]', DESC = 'Joins a game by ID'}
CMDs[#CMDs + 1] = {NAME = 'antiidle / antiafk', DESC = 'Prevents the game from kicking you for being idle/afk'}
CMDs[#CMDs + 1] = {NAME = 'datalimit [num]', DESC = 'Set outgoing KBPS limit'}
CMDs[#CMDs + 1] = {NAME = 'replicationlag / backtrack [num]', DESC = 'Set IncomingReplicationLag'}
CMDs[#CMDs + 1] = {NAME = 'creatorid / creator', DESC = 'Notifies you the creators ID'}
CMDs[#CMDs + 1] = {NAME = 'copycreatorid / copycreator', DESC = 'Copies the creators ID to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'setcreatorid / setcreator', DESC = 'Sets your userid to the creators ID'}
CMDs[#CMDs + 1] = {NAME = 'noprompts', DESC = 'Prevents the game from showing you purchase/premium prompts'}
CMDs[#CMDs + 1] = {NAME = 'showprompts', DESC = 'Allows the game to show purchase/premium prompts again'}
CMDs[#CMDs + 1] = {NAME = 'enable [inventory/playerlist/chat/reset/emotes/all]', DESC = 'Toggles visibility of coregui items'}
CMDs[#CMDs + 1] = {NAME = 'disable [inventory/playerlist/chat/reset/emotes/all]', DESC = 'Toggles visibility of coregui items'}
CMDs[#CMDs + 1] = {NAME = 'showguis', DESC = 'Shows any invisible GUIs'}
CMDs[#CMDs + 1] = {NAME = 'unshowguis', DESC = 'Undoes showguis'}
CMDs[#CMDs + 1] = {NAME = 'hideguis', DESC = 'Hides any GUIs in PlayerGui'}
CMDs[#CMDs + 1] = {NAME = 'unhideguis', DESC = 'Undoes hideguis'}
CMDs[#CMDs + 1] = {NAME = 'guidelete', DESC = 'Enables backspace to delete GUI'}
CMDs[#CMDs + 1] = {NAME = 'unguidelete / noguidelete', DESC = 'Disables guidelete'}
CMDs[#CMDs + 1] = {NAME = 'hideiy', DESC = 'Hides the main IY GUI'}
CMDs[#CMDs + 1] = {NAME = 'showiy / unhideiy', DESC = 'Shows IY again'}
CMDs[#CMDs + 1] = {NAME = 'keepiy', DESC = 'Auto execute IY when you teleport through servers'}
CMDs[#CMDs + 1] = {NAME = 'unkeepiy', DESC = 'Disable keepiy'}
CMDs[#CMDs + 1] = {NAME = 'togglekeepiy', DESC = 'Toggles keepiy'}
CMDs[#CMDs + 1] = {NAME = 'removeads / adblock', DESC = 'Automatically removes ad billboards'}
CMDs[#CMDs + 1] = {NAME = 'savegame / saveplace', DESC = 'Uses saveinstance to save the game'}
CMDs[#CMDs + 1] = {NAME = 'clearerror', DESC = 'Clears the annoying box and blur when a game kicks you'}
CMDs[#CMDs + 1] = {NAME = 'antigameplaypaused', DESC = 'Clears the annoying box shown when a game is loading assets due to network lag'}
CMDs[#CMDs + 1] = {NAME = 'unantigameplaypaused', DESC = 'Disables antigameplaypaused'}
CMDs[#CMDs + 1] = {NAME = 'clientantikick / antikick (CLIENT)', DESC = 'Prevents localscripts from kicking you'}
CMDs[#CMDs + 1] = {NAME = 'clientantiteleport / antiteleport (CLIENT)', DESC = 'Prevents localscripts from teleporting you'}
CMDs[#CMDs + 1] = {NAME = 'allowrejoin / allowrj [true/false] (CLIENT)', DESC = 'Changes if antiteleport allows you to rejoin or not'}
CMDs[#CMDs + 1] = {NAME = 'cancelteleport / canceltp', DESC = 'Cancels teleports in progress'}
CMDs[#CMDs + 1] = {NAME = 'volume / vol [0-10]', DESC = 'Adjusts your game volume on a scale of 0 to 10'}
CMDs[#CMDs + 1] = {NAME = 'antilag / boostfps / lowgraphics', DESC = 'Lowers game quality to boost FPS'}
CMDs[#CMDs + 1] = {NAME = 'record / rec', DESC = 'Starts Roblox recorder'}
CMDs[#CMDs + 1] = {NAME = 'screenshot / scrnshot', DESC = 'Takes a screenshot'}
CMDs[#CMDs + 1] = {NAME = 'togglefullscreen / togglefs', DESC = 'Toggles fullscreen'}
CMDs[#CMDs + 1] = {NAME = 'notify [text]', DESC = 'Sends you a notification with the provided text'}
CMDs[#CMDs + 1] = {NAME = 'lastcommand / lastcmd', DESC = 'Executes the previous command used'}
CMDs[#CMDs + 1] = {NAME = 'notifyping / ping', DESC = 'Notify yourself your ping'}
CMDs[#CMDs + 1] = {NAME = 'norender', DESC = 'Disable 3d Rendering to decrease the amount of CPU the client uses'}
CMDs[#CMDs + 1] = {NAME = 'render', DESC = 'Enable 3d Rendering'}
CMDs[#CMDs + 1] = {NAME = 'use2022materials / 2022materials', DESC = 'Enables 2022 material textures'}
CMDs[#CMDs + 1] = {NAME = 'unuse2022materials / un2022materials', DESC = 'Disables 2022 material textures'}
CMDs[#CMDs + 1] = {NAME = 'alignmentkeys', DESC = 'Enables the left and right alignment keys (comma and period)'}
CMDs[#CMDs + 1] = {NAME = 'unalignmentkeys / noalignmentkeys', DESC = 'Disables the alignment keys'}
CMDs[#CMDs + 1] = {NAME = 'ctrllock', DESC = 'Binds Shiftlock to LeftControl'}
CMDs[#CMDs + 1] = {NAME = 'unctrllock', DESC = 'Re-binds Shiftlock to LeftShift'}
CMDs[#CMDs + 1] = {NAME = 'exit', DESC = 'Kills roblox process'}
CMDs[#CMDs + 1] = {NAME = 'removecmd / deletecmd', DESC = 'Removes a command until the script is reloaded'}
CMDs[#CMDs + 1] = {NAME = 'breakloops / break (cmd loops)', DESC = 'Stops any cmd loops (;100^1^cmd)'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'noclip', DESC = 'Go through objects'}
CMDs[#CMDs + 1] = {NAME = 'unnoclip / clip', DESC = 'Disables noclip'}
CMDs[#CMDs + 1] = {NAME = 'fly [speed]', DESC = 'Makes you fly'}
CMDs[#CMDs + 1] = {NAME = 'unfly', DESC = 'Disables fly'}
CMDs[#CMDs + 1] = {NAME = 'flyspeed [num]', DESC = 'Set fly speed (default is 20)'}
CMDs[#CMDs + 1] = {NAME = 'vehiclefly / vfly [speed]', DESC = 'Makes you fly in a vehicle'}
CMDs[#CMDs + 1] = {NAME = 'unvehiclefly / unvfly', DESC = 'Disables vehicle fly'}
CMDs[#CMDs + 1] = {NAME = 'vehicleflyspeed  / vflyspeed [num]', DESC = 'Set vehicle fly speed'}
CMDs[#CMDs + 1] = {NAME = 'cframefly / cfly [speed]', DESC = 'Makes you fly, bypassing some anti cheats (works on mobile)'}
CMDs[#CMDs + 1] = {NAME = 'uncframefly / uncfly', DESC = 'Disables cfly'}
CMDs[#CMDs + 1] = {NAME = 'cframeflyspeed  / cflyspeed [num]', DESC = 'Sets cfly speed'}
CMDs[#CMDs + 1] = {NAME = 'qefly [true / false]', DESC = 'Enables or disables the Q and E hotkeys for fly'}
CMDs[#CMDs + 1] = {NAME = 'vehiclenoclip / vnoclip', DESC = 'Turns off vehicle collision'}
CMDs[#CMDs + 1] = {NAME = 'vehicleclip / vclip / unvnoclip', DESC = 'Enables vehicle collision'}
CMDs[#CMDs + 1] = {NAME = 'float /  platform', DESC = 'Spawns a platform beneath you causing you to float'}
CMDs[#CMDs + 1] = {NAME = 'unfloat / noplatform', DESC = 'Removes the platform'}
CMDs[#CMDs + 1] = {NAME = 'swim', DESC = 'Allows you to swim in the air'}
CMDs[#CMDs + 1] = {NAME = 'unswim / noswim', DESC = 'Stops you from swimming everywhere'}
CMDs[#CMDs + 1] = {NAME = 'toggleswim', DESC = 'Toggles swimming'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'setwaypoint / swp [name]', DESC = 'Sets a waypoint at your position'}
CMDs[#CMDs + 1] = {NAME = 'waypointpos / wpp [name] [X Y Z]', DESC = 'Sets a waypoint with specified coordinates'}
CMDs[#CMDs + 1] = {NAME = 'waypoints', DESC = 'Shows a list of currently active waypoints'}
CMDs[#CMDs + 1] = {NAME = 'showwaypoints / showwp', DESC = 'Shows all currently set waypoints'}
CMDs[#CMDs + 1] = {NAME = 'hidewaypoints / hidewp', DESC = 'Hides shown waypoints'}
CMDs[#CMDs + 1] = {NAME = 'waypoint / wp [name]', DESC = 'Teleports player to a waypoint'}
CMDs[#CMDs + 1] = {NAME = 'tweenwaypoint / twp [name]', DESC = 'Tweens player to a waypoint'}
CMDs[#CMDs + 1] = {NAME = 'walktowaypoint / wtwp [name]', DESC = 'Walks player to a waypoint'}
CMDs[#CMDs + 1] = {NAME = 'deletewaypoint / dwp [name]', DESC = 'Deletes a waypoint'}
CMDs[#CMDs + 1] = {NAME = 'clearwaypoints / cwp', DESC = 'Clears all waypoints'}
CMDs[#CMDs + 1] = {NAME = 'cleargamewaypoints / cgamewp', DESC = 'Clears all waypoints for the game you are in'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'goto [player]', DESC = 'Go to a player'}
CMDs[#CMDs + 1] = {NAME = 'tweengoto / tgoto [player]', DESC = 'Tween to a player (bypasses some anti cheats)'}
CMDs[#CMDs + 1] = {NAME = 'tweenspeed / tspeed [num]', DESC = 'Sets how fast all tween commands go (default is 1)'}
CMDs[#CMDs + 1] = {NAME = 'vehiclegoto / vgoto [player]', DESC = 'Go to a player while in a vehicle'}
CMDs[#CMDs + 1] = {NAME = 'loopgoto [player] [distance] [delay]', DESC = 'Loop teleport to a player'}
CMDs[#CMDs + 1] = {NAME = 'unloopgoto', DESC = 'Stops teleporting you to a player'}
CMDs[#CMDs + 1] = {NAME = 'pulsetp / ptp [player] [seconds]', DESC = 'Teleports you to a player for a specified amount of time'}
CMDs[#CMDs + 1] = {NAME = 'clientbring / cbring [player] (CLIENT)', DESC = 'Bring a player'}
CMDs[#CMDs + 1] = {NAME = 'loopbring [player] [distance] [delay] (CLIENT)', DESC = 'Loop brings a player to you (useful for killing)'}
CMDs[#CMDs + 1] = {NAME = 'unloopbring [player]', DESC = 'Undoes loopbring'}
CMDs[#CMDs + 1] = {NAME = 'freeze / fr [player] (CLIENT)', DESC = 'Freezes a player'}
CMDs[#CMDs + 1] = {NAME = 'freezeanims', DESC = 'Freezes your animations / pauses your animations - Does not work on default animations'}
CMDs[#CMDs + 1] = {NAME = 'unfreezeanims', DESC = 'Unfreezes your animations / plays your animations'}
CMDs[#CMDs + 1] = {NAME = 'thaw / unfr [player] (CLIENT)', DESC = 'Unfreezes a player'}
CMDs[#CMDs + 1] = {NAME = 'anchor', DESC = 'Anchors your characters RootPart'}
CMDs[#CMDs + 1] = {NAME = 'unanchor', DESC = 'Unanchors your characters RootPart'}
CMDs[#CMDs + 1] = {NAME = 'tpposition / tppos [X Y Z]', DESC = 'Teleports you to certain coordinates'}
CMDs[#CMDs + 1] = {NAME = 'tweentpposition / ttppos [X Y Z]', DESC = 'Tween to coordinates (bypasses some anti cheats)'}
CMDs[#CMDs + 1] = {NAME = 'offset [X Y Z]', DESC = 'Offsets you by certain coordinates'}
CMDs[#CMDs + 1] = {NAME = 'tweenoffset / toffset [X Y Z]', DESC = 'Tween offset (bypasses some anti cheats)'}
CMDs[#CMDs + 1] = {NAME = 'thru [num]', DESC = 'Teleports you [num] studs ahead of where your character is facing'}
CMDs[#CMDs + 1] = {NAME = 'notifyposition / notifypos [player]', DESC = 'Notifies you the coordinates of a character'}
CMDs[#CMDs + 1] = {NAME = 'copyposition / copypos [player]', DESC = 'Copies the coordinates of a character to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'walktoposition / walktopos [X Y Z]', DESC = 'Makes you walk to a coordinate'}
CMDs[#CMDs + 1] = {NAME = 'spawnpoint / spawn [delay]', DESC = 'Sets a position where you will spawn'}
CMDs[#CMDs + 1] = {NAME = 'nospawnpoint / nospawn', DESC = 'Removes your custom spawn point'}
CMDs[#CMDs + 1] = {NAME = 'flashback / diedtp', DESC = 'Teleports you to where you last died'}
CMDs[#CMDs + 1] = {NAME = 'walltp', DESC = 'Teleports you above/over any wall you run into'}
CMDs[#CMDs + 1] = {NAME = 'nowalltp / unwalltp', DESC = 'Disables walltp'}
CMDs[#CMDs + 1] = {NAME = 'teleporttool / tptool', DESC = 'Gives you a teleport tool'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'logs', DESC = 'Opens the logs GUI'}
CMDs[#CMDs + 1] = {NAME = 'chatlogs / clogs', DESC = 'Log what people say or whisper'}
CMDs[#CMDs + 1] = {NAME = 'joinlogs / jlogs', DESC = 'Log when people join'}
CMDs[#CMDs + 1] = {NAME = 'chatlogswebhook / logswebhook [url]', DESC = 'Set a discord webhook for chatlogs to go to (provide no url to disable this)'}
CMDs[#CMDs + 1] = {NAME = 'chat / say [text]', DESC = 'Makes you chat a string (possible mute bypass)'}
CMDs[#CMDs + 1] = {NAME = 'spam [text]', DESC = 'Makes you spam the chat'}
CMDs[#CMDs + 1] = {NAME = 'unspam', DESC = 'Turns off spam'}
CMDs[#CMDs + 1] = {NAME = 'whisper / pm [player] [text]', DESC = 'Makes you whisper a string to someone (possible mute bypass)'}
CMDs[#CMDs + 1] = {NAME = 'pmspam [player] [text]', DESC = 'Makes you spam a players whispers'}
CMDs[#CMDs + 1] = {NAME = 'unpmspam [player]', DESC = 'Turns off pm spam'}
CMDs[#CMDs + 1] = {NAME = 'spamspeed [num]', DESC = 'How quickly you spam (default is 1)'}
CMDs[#CMDs + 1] = {NAME = 'bubblechat (CLIENT)', DESC = 'Enables bubble chat for your client'}
CMDs[#CMDs + 1] = {NAME = 'unbubblechat / nobubblechat', DESC = 'Disables the bubblechat command'}
CMDs[#CMDs + 1] = {NAME = 'chatwindow', DESC = 'Enables the chat window for your client'}
CMDs[#CMDs + 1] = {NAME = 'unchatwindow / nochatwindow', DESC = 'Disables the chat window for your client'}
CMDs[#CMDs + 1] = {NAME = 'darkchat', DESC = 'Makes the chat window dark for your client'}
CMDs[#CMDs + 1] = {NAME = 'listento [player]', DESC = 'Listens to the area around a player. Can also eavesdrop with vc'}
CMDs[#CMDs + 1] = {NAME = 'unlistento', DESC = 'Disables listento'}
CMDs[#CMDs + 1] = {NAME = 'muteallvoices / muteallvcs', DESC = 'Mutes voice chat for all players'}
CMDs[#CMDs + 1] = {NAME = 'unmuteallvoices / unmuteallvcs', DESC = 'Unmutes voice chat for all players'}
CMDs[#CMDs + 1] = {NAME = 'mutevc [player]', DESC = 'Mutes the voice chat of a player'}
CMDs[#CMDs + 1] = {NAME = 'unmutevc [player]', DESC = 'Unmutes the voice chat of a player'}
CMDs[#CMDs + 1] = {NAME = 'phonebook / call', DESC = 'Prompts the Roblox phonebook UI to let you call your friends. Needs voice chat enabled'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'esp', DESC = 'View all players and their status'}
CMDs[#CMDs + 1] = {NAME = 'espteam', DESC = 'ESP but teammates are green and bad guys are red'}
CMDs[#CMDs + 1] = {NAME = 'noesp / unesp / unespteam', DESC = 'Removes ESP'}
CMDs[#CMDs + 1] = {NAME = 'esptransparency [number]', DESC = 'Changes the transparency of ESP related commands'}
CMDs[#CMDs + 1] = {NAME = 'partesp [part name]', DESC = 'Highlights a part'}
CMDs[#CMDs + 1] = {NAME = 'unpartesp / nopartesp [part name]', DESC = 'removes partesp'}
CMDs[#CMDs + 1] = {NAME = 'chams', DESC = 'ESP but without text in the way'}
CMDs[#CMDs + 1] = {NAME = 'nochams / unchams', DESC = 'Removes chams'}
CMDs[#CMDs + 1] = {NAME = 'locate [player]', DESC = 'View a single player and their status'}
CMDs[#CMDs + 1] = {NAME = 'unlocate / nolocate [player]', DESC = 'Removes locate'}
CMDs[#CMDs + 1] = {NAME = 'xray', DESC = 'Makes all parts in workspace transparent'}
CMDs[#CMDs + 1] = {NAME = 'unxray / noxray', DESC = 'Restores transparency to all parts in workspace'}
CMDs[#CMDs + 1] = {NAME = 'loopxray', DESC = 'Makes all parts in workspace transparent but looped'}
CMDs[#CMDs + 1] = {NAME = 'unloopxray', DESC = 'Unloops xray'}
CMDs[#CMDs + 1] = {NAME = 'togglexray', DESC = 'Toggles xray'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'spectate / view [player]', DESC = 'View a player'}
CMDs[#CMDs + 1] = {NAME = 'viewpart / viewp [part name]', DESC = 'View a part'}
CMDs[#CMDs + 1] = {NAME = 'unspectate / unview', DESC = 'Stops viewing player'}
CMDs[#CMDs + 1] = {NAME = 'freecam / fc', DESC = 'Allows you to freely move camera around the game'}
CMDs[#CMDs + 1] = {NAME = 'freecampos / fcpos [X Y Z]', DESC = 'Moves / opens freecam in a certain position'}
CMDs[#CMDs + 1] = {NAME = 'freecamwaypoint / fcwp [name]', DESC = 'Moves / opens freecam to a waypoint'}
CMDs[#CMDs + 1] = {NAME = 'freecamgoto / fcgoto / fctp [player]', DESC = 'Moves / opens freecam to a player'}
CMDs[#CMDs + 1] = {NAME = 'unfreecam / unfc', DESC = 'Disables freecam'}
CMDs[#CMDs + 1] = {NAME = 'freecamspeed / fcspeed [num]', DESC = 'Adjusts freecam speed (default is 1)'}
CMDs[#CMDs + 1] = {NAME = 'notifyfreecamposition / notifyfcpos', DESC = 'Noitifies you your freecam coordinates'}
CMDs[#CMDs + 1] = {NAME = 'copyfreecamposition / copyfcpos', DESC = 'Copies your freecam coordinates to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'gotocamera / gotocam', DESC = 'Teleports you to the location of your camera'}
CMDs[#CMDs + 1] = {NAME = 'tweengotocam / tgotocam', DESC = 'Tweens you to the location of your camera'}
CMDs[#CMDs + 1] = {NAME = 'firstp', DESC = 'Forces camera to go into first person'}
CMDs[#CMDs + 1] = {NAME = 'thirdp', DESC = 'Allows camera to go into third person'}
CMDs[#CMDs + 1] = {NAME = 'noclipcam / nccam', DESC = 'Allows camera to go through objects like walls'}
CMDs[#CMDs + 1] = {NAME = 'maxzoom [num]', DESC = 'Maximum camera zoom'}
CMDs[#CMDs + 1] = {NAME = 'minzoom [num]', DESC = 'Minimum camera zoom'}
CMDs[#CMDs + 1] = {NAME = 'camdistance [num]', DESC = 'Changes camera distance from your player'}
CMDs[#CMDs + 1] = {NAME = 'fov [num]', DESC = 'Adjusts field of view (default is 70)'}
CMDs[#CMDs + 1] = {NAME = 'fixcam / restorecam', DESC = 'Fixes camera'}
CMDs[#CMDs + 1] = {NAME = 'enableshiftlock / enablesl', DESC = 'Enables the shift lock option'}
CMDs[#CMDs + 1] = {NAME = 'lookat [player]', DESC = 'Moves your camera view to a player'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'btools (CLIENT)', DESC = 'Gives you building tools (DOES NOT REPLICATE)'}
CMDs[#CMDs + 1] = {NAME = 'f3x (CLIENT)', DESC = 'Gives you F3X building tools (DOES NOT REPLICATE)'}
CMDs[#CMDs + 1] = {NAME = 'partname / partpath', DESC = 'Allows you to click a part to see its path & name'}
CMDs[#CMDs + 1] = {NAME = 'delete [instance name] (CLIENT)', DESC = 'Removes any part with a certain name from the workspace (DOES NOT REPLICATE)'}
CMDs[#CMDs + 1] = {NAME = 'deleteclass / dc [class name] (CLIENT)', DESC = 'Removes any part with a certain classname from the workspace (DOES NOT REPLICATE)'}
CMDs[#CMDs + 1] = {NAME = 'lockworkspace / lockws', DESC = 'Locks the whole workspace'}
CMDs[#CMDs + 1] = {NAME = 'unlockworkspace / unlockws', DESC = 'Unlocks the whole workspace'}
CMDs[#CMDs + 1] = {NAME = 'invisibleparts / invisparts (CLIENT)', DESC = 'Shows invisible parts'}
CMDs[#CMDs + 1] = {NAME = 'uninvisibleparts / uninvisparts (CLIENT)', DESC = 'Makes parts affected by invisparts return to normal'}
CMDs[#CMDs + 1] = {NAME = 'deleteinvisparts / dip (CLIENT)', DESC = 'Deletes invisible parts'}
CMDs[#CMDs + 1] = {NAME = 'gotopart [part name]', DESC = 'Moves your character to a part or multiple parts'}
CMDs[#CMDs + 1] = {NAME = 'tweengotopart / tgotopart [part name]', DESC = 'Tweens your character to a part or multiple parts'}
CMDs[#CMDs + 1] = {NAME = 'gotopartclass / gpc [class name]', DESC = 'Moves your character to a part or multiple parts based on classname'}
CMDs[#CMDs + 1] = {NAME = 'tweengotopartclass / tgpc [class name]', DESC = 'Tweens your character to a part or multiple parts based on classname'}
CMDs[#CMDs + 1] = {NAME = 'gotomodel [part name]', DESC = 'Moves your character to a model or multiple models'}
CMDs[#CMDs + 1] = {NAME = 'tweengotomodel / tgotomodel [part name]', DESC = 'Tweens your character to a model or multiple models'}
CMDs[#CMDs + 1] = {NAME = 'gotopartdelay / gotomodeldelay [num]', DESC = 'Adjusts how quickly you teleport to each part (default is 0.1)'}
CMDs[#CMDs + 1] = {NAME = 'bringpart [part name] (CLIENT)', DESC = 'Moves a part or multiple parts to your character'}
CMDs[#CMDs + 1] = {NAME = 'bringpartclass / bpc [class name] (CLIENT)', DESC = 'Moves a part or multiple parts to your character based on classname'}
CMDs[#CMDs + 1] = {NAME = 'noclickdetectorlimits / nocdlimits', DESC = 'Sets all click detectors MaxActivationDistance to math.huge'}
CMDs[#CMDs + 1] = {NAME = 'fireclickdetectors / firecd [name]', DESC = 'Uses all click detectors in a game or uses the optional name'}
CMDs[#CMDs + 1] = {NAME = 'firetouchinterests / touchinterests [name]', DESC = 'Uses all touchinterests in a game or uses the optional name'}
CMDs[#CMDs + 1] = {NAME = 'noproximitypromptlimits / nopplimits', DESC = 'Sets all proximity prompts MaxActivationDistance to math.huge'}
CMDs[#CMDs + 1] = {NAME = 'fireproximityprompts / firepp [name]', DESC = 'Uses all proximity prompts in a game or uses the optional name'}
CMDs[#CMDs + 1] = {NAME = 'instantproximityprompts / instantpp', DESC = 'Disable the cooldown for proximity prompts'}
CMDs[#CMDs + 1] = {NAME = 'uninstantproximityprompts / uninstantpp', DESC = 'Undo the cooldown removal'}
CMDs[#CMDs + 1] = {NAME = 'tpunanchored / tpua [player]', DESC = 'Teleports unanchored parts to a player'}
CMDs[#CMDs + 1] = {NAME = 'animsunanchored / freezeua', DESC = 'Freezes unanchored parts'}
CMDs[#CMDs + 1] = {NAME = 'thawunanchored / thawua / unfreezeua', DESC = 'Thaws unanchored parts'}
CMDs[#CMDs + 1] = {NAME = 'removeterrain / rterrain / noterrain', DESC = 'Removes all terrain'}
CMDs[#CMDs + 1] = {NAME = 'clearnilinstances / nonilinstances / cni', DESC = 'Removes nil instances'}
CMDs[#CMDs + 1] = {NAME = 'destroyheight / dh [num]', DESC = 'Sets FallenPartsDestroyHeight'}
CMDs[#CMDs + 1] = {NAME = 'fakeout', DESC = 'Tp to the void and then back (useful to kill people attached to you)'}
CMDs[#CMDs + 1] = {NAME = 'antivoid', DESC = 'Prevents you from falling into the void by launching you upwards'}
CMDs[#CMDs + 1] = {NAME = 'unantivoid / noantivoid', DESC = 'Disables antivoid'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'fullbright / fb (CLIENT)', DESC = 'Makes the map brighter / more visible'}
CMDs[#CMDs + 1] = {NAME = 'loopfullbright / loopfb (CLIENT)', DESC = 'Makes the map brighter / more visible but looped'}
CMDs[#CMDs + 1] = {NAME = 'unloopfullbright / unloopfb', DESC = 'Unloops fullbright'}
CMDs[#CMDs + 1] = {NAME = 'ambient [num] [num] [num] (CLIENT)', DESC = 'Changes ambient'}
CMDs[#CMDs + 1] = {NAME = 'day (CLIENT)', DESC = 'Changes the time to day for the client'}
CMDs[#CMDs + 1] = {NAME = 'night (CLIENT)', DESC = 'Changes the time to night for the client'}
CMDs[#CMDs + 1] = {NAME = 'nofog (CLIENT)', DESC = 'Removes fog'}
CMDs[#CMDs + 1] = {NAME = 'brightness [num] (CLIENT)', DESC = 'Changes the brightness lighting property'}
CMDs[#CMDs + 1] = {NAME = 'globalshadows / gshadows (CLIENT)', DESC = 'Enables global shadows'}
CMDs[#CMDs + 1] = {NAME = 'noglobalshadows / nogshadows (CLIENT)', DESC = 'Disables global shadows'}
CMDs[#CMDs + 1] = {NAME = 'restorelighting / rlighting', DESC = 'Restores Lighting properties'}
CMDs[#CMDs + 1] = {NAME = 'light [radius] [brightness] (CLIENT)', DESC = 'Gives your player dynamic light'}
CMDs[#CMDs + 1] = {NAME = 'nolight / unlight', DESC = 'Removes dynamic light from your player'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'inspect / examine [player]', DESC = 'Opens InspectMenu for a certain player'}
CMDs[#CMDs + 1] = {NAME = 'age [player]', DESC = 'Tells you the age of a player'}
CMDs[#CMDs + 1] = {NAME = 'chatage [player]', DESC = 'Chats the age of a player'}
CMDs[#CMDs + 1] = {NAME = 'joindate / jd [player]', DESC = 'Tells you the date the player joined Roblox'}
CMDs[#CMDs + 1] = {NAME = 'chatjoindate / cjd [player]', DESC = 'Chats the date the player joined Roblox'}
CMDs[#CMDs + 1] = {NAME = 'copyname / copyuser [player]', DESC = 'Copies a players full username to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'userid / id [player]', DESC = 'Notifies a players user ID'}
CMDs[#CMDs + 1] = {NAME = 'copyplaceid / placeid', DESC = 'Copies the current place id to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'copygameid / gameid', DESC = 'Copies the current game id to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'copyuserid / copyid [player]', DESC = 'Copies a players user ID to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'appearanceid / aid [player]', DESC = 'Notifies a players appearance ID'}
CMDs[#CMDs + 1] = {NAME = 'copyappearanceid / caid [player]', DESC = 'Copies a players appearance ID to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'bang [player] [speed]', DESC = 'owo'}
CMDs[#CMDs + 1] = {NAME = 'unbang', DESC = 'uwu'}
CMDs[#CMDs + 1] = {NAME = 'jerk', DESC = 'Makes you jork it'}
CMDs[#CMDs + 1] = {NAME = 'scare / spook [player]', DESC = 'Teleports in front of a player for half a second'}
CMDs[#CMDs + 1] = {NAME = 'carpet [player]', DESC = 'Be someones carpet'}
CMDs[#CMDs + 1] = {NAME = 'uncarpet', DESC = 'Undoes carpet'}
CMDs[#CMDs + 1] = {NAME = 'friend [player]', DESC = 'Sends a friend request to certain players'}
CMDs[#CMDs + 1] = {NAME = 'unfriend [player]', DESC = 'Unfriends certain players'}
CMDs[#CMDs + 1] = {NAME = 'headsit [player]', DESC = 'Sit on a players head'}
CMDs[#CMDs + 1] = {NAME = 'walkto / follow [player]', DESC = 'Follow a player'}
CMDs[#CMDs + 1] = {NAME = 'pathfindwalkto / pathfindfollow [player]', DESC = 'Follow a player using pathfinding'}
CMDs[#CMDs + 1] = {NAME = 'pathfindwalktowaypoint / pathfindwalktowp [waypoint]', DESC = 'Walk to a waypoint using pathfinding'}
CMDs[#CMDs + 1] = {NAME = 'unwalkto / unfollow', DESC = 'Stops following a player'}
CMDs[#CMDs + 1] = {NAME = 'orbit [player] [speed] [distance]', DESC = 'Makes your character orbit around a player with an optional speed and an optional distance'}
CMDs[#CMDs + 1] = {NAME = 'unorbit', DESC = 'Disables orbit'}
CMDs[#CMDs + 1] = {NAME = 'stareat / stare [player]', DESC = 'Stare / look at a player'}
CMDs[#CMDs + 1] = {NAME = 'unstareat / unstare [player]', DESC = 'Disables stareat'}
CMDs[#CMDs + 1] = {NAME = 'rolewatch [group id] [role name]', DESC = 'Notify if someone from a watched group joins the server'}
CMDs[#CMDs + 1] = {NAME = 'rolewatchstop / unrolewatch', DESC = 'Disable Rolewatch'}
CMDs[#CMDs + 1] = {NAME = 'rolewatchleave', DESC = 'Toggle if you should leave the game if someone from a watched group joins the server'}
CMDs[#CMDs + 1] = {NAME = 'staffwatch', DESC = 'Notify if a staff member of the game joins the server'}
CMDs[#CMDs + 1] = {NAME = 'unstaffwatch', DESC = 'Disable Staffwatch'}
CMDs[#CMDs + 1] = {NAME = 'findfriendgroups', DESC = 'Notifies you if any players are friends with each other'}
CMDs[#CMDs + 1] = {NAME = 'handlekill / hkill [player] [radius] (TOOL)', DESC = 'Kills a player using tool damage (YOU NEED A TOOL)'}
CMDs[#CMDs + 1] = {NAME = 'fling', DESC = 'Flings anyone you touch'}
CMDs[#CMDs + 1] = {NAME = 'unfling', DESC = 'Disables the fling command'}
CMDs[#CMDs + 1] = {NAME = 'flyfling [speed]', DESC = 'Basically the invisfling command but not invisible'}
CMDs[#CMDs + 1] = {NAME = 'unflyfling', DESC = 'Disables the flyfling command'}
CMDs[#CMDs + 1] = {NAME = 'walkfling / jbfling / jb fling / jailbreakfling / jailbreak fling', DESC = 'Basically fling but no spinning'}
CMDs[#CMDs + 1] = {NAME = 'unwalkfling / nowalkfling', DESC = 'Disables walkfling'}
CMDs[#CMDs + 1] = {NAME = 'invisfling', DESC = 'Enables invisible fling (the invis part is patched, try using the god command before using this)'}
CMDs[#CMDs + 1] = {NAME = 'antifling', DESC = 'Disables player collisions to prevent you from being flung'}
CMDs[#CMDs + 1] = {NAME = 'unantifling', DESC = 'Disables antifling'}
CMDs[#CMDs + 1] = {NAME = 'loopoof', DESC = 'Loops everyones character sounds (everyone can hear)'}
CMDs[#CMDs + 1] = {NAME = 'unloopoof', DESC = 'Stops the oof chaos'}
CMDs[#CMDs + 1] = {NAME = 'muteboombox [player]', DESC = 'Mutes someones boombox'}
CMDs[#CMDs + 1] = {NAME = 'unmuteboombox [player]', DESC = 'Unmutes someones boombox'}
CMDs[#CMDs + 1] = {NAME = 'hitbox [player] [size] [transparency]', DESC = 'Expands the hitbox for players HumanoidRootPart (default is 1)'}
CMDs[#CMDs + 1] = {NAME = 'headsize [player] [size]', DESC = 'Expands the head size for players Head (default is 1)'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'reset', DESC = 'Resets your character normally'}
CMDs[#CMDs + 1] = {NAME = 'respawn', DESC = 'Respawns you'}
CMDs[#CMDs + 1] = {NAME = 'refresh / re', DESC = 'Respawns and brings you back to the same position'}
CMDs[#CMDs + 1] = {NAME = 'god', DESC = 'Makes your character difficult to kill in most games'}
CMDs[#CMDs + 1] = {NAME = 'invisible / invis', DESC = 'Makes you invisible to other players'}
CMDs[#CMDs + 1] = {NAME = 'visible / vis', DESC = 'Makes you visible to other players'}
CMDs[#CMDs + 1] = {NAME = 'toolinvisible / toolinvis / tinvis', DESC = 'Makes you invisible to other players and able to use tools'}
CMDs[#CMDs + 1] = {NAME = 'speed / ws / walkspeed [num]', DESC = 'Change your walkspeed (default is 16)'}
CMDs[#CMDs + 1] = {NAME = 'spoofspeed / spoofws [num]', DESC = 'Spoofs your WalkSpeed on the Client'}
CMDs[#CMDs + 1] = {NAME = 'loopspeed / loopws [num]', DESC = 'Loops your walkspeed'}
CMDs[#CMDs + 1] = {NAME = 'unloopspeed / unloopws', DESC = 'Turns off loopspeed'}
CMDs[#CMDs + 1] = {NAME = 'hipheight / hheight [num]', DESC = 'Adjusts hip height'}
CMDs[#CMDs + 1] = {NAME = 'jumppower / jpower / jp [num]', DESC = 'Change a players jump height (default is 50)'}
CMDs[#CMDs + 1] = {NAME = 'spoofjumppower / spoofjp [num]', DESC = 'Spoofs your JumpPower on the Client'}
CMDs[#CMDs + 1] = {NAME = 'loopjumppower / loopjp [num]', DESC = 'Loops your jump height'}
CMDs[#CMDs + 1] = {NAME = 'unloopjumppower / unloopjp', DESC = 'Turns off loopjumppower'}
CMDs[#CMDs + 1] = {NAME = 'maxslopeangle / msa [num]', DESC = 'Adjusts MaxSlopeAngle'}
CMDs[#CMDs + 1] = {NAME = 'gravity / grav [num] (CLIENT)', DESC = 'Change your gravity'}
CMDs[#CMDs + 1] = {NAME = 'sit', DESC = 'Makes your character sit'}
CMDs[#CMDs + 1] = {NAME = 'lay / laydown', DESC = 'Makes your character lay down'}
CMDs[#CMDs + 1] = {NAME = 'sitwalk', DESC = 'Makes your character sit while still being able to walk'}
CMDs[#CMDs + 1] = {NAME = 'nosit', DESC = 'Prevents your character from sitting'}
CMDs[#CMDs + 1] = {NAME = 'unnosit', DESC = 'Disables nosit'}
CMDs[#CMDs + 1] = {NAME = 'jump', DESC = 'Makes your character jump'}
CMDs[#CMDs + 1] = {NAME = 'infinitejump / infjump', DESC = 'Allows you to jump before hitting the ground'}
CMDs[#CMDs + 1] = {NAME = 'uninfinitejump / uninfjump', DESC = 'Disables infjump'}
CMDs[#CMDs + 1] = {NAME = 'flyjump', DESC = 'Allows you to hold space to fly up'}
CMDs[#CMDs + 1] = {NAME = 'unflyjump', DESC = 'Disables flyjump'}
CMDs[#CMDs + 1] = {NAME = 'autojump / ajump', DESC = 'Automatically jumps when you run into an object'}
CMDs[#CMDs + 1] = {NAME = 'unautojump / unajump', DESC = 'Disables autojump'}
CMDs[#CMDs + 1] = {NAME = 'edgejump / ejump', DESC = 'Automatically jumps when you get to the edge of an object'}
CMDs[#CMDs + 1] = {NAME = 'unedgejump / unejump', DESC = 'Disables edgejump'}
CMDs[#CMDs + 1] = {NAME = 'platformstand / stun', DESC = 'Enables PlatformStand'}
CMDs[#CMDs + 1] = {NAME = 'unplatformstand / unstun', DESC = 'Disables PlatformStand'}
CMDs[#CMDs + 1] = {NAME = 'norotate / noautorotate', DESC = 'Disables AutoRotate'}
CMDs[#CMDs + 1] = {NAME = 'unnorotate / autorotate', DESC = 'Enables AutoRotate'}
CMDs[#CMDs + 1] = {NAME = 'enablestate [StateType]', DESC = 'Enables a humanoid state type'}
CMDs[#CMDs + 1] = {NAME = 'disablestate [StateType]', DESC = 'Disables a humanoid state type'}
CMDs[#CMDs + 1] = {NAME = 'team [team name] (CLIENT)', DESC = 'Changes your team. Sometimes fools localscripts.'}
CMDs[#CMDs + 1] = {NAME = 'nobillboardgui / nobgui / noname', DESC = 'Removes billboard and surface GUIs from your players (i.e. name GUIs at cafes)'}
CMDs[#CMDs + 1] = {NAME = 'loopnobgui / loopnoname', DESC = 'Loop removes billboard and surface GUIs from your players (i.e. name GUIs at cafes)'}
CMDs[#CMDs + 1] = {NAME = 'unloopnobgui / unloopnoname', DESC = 'Disables loopnobgui'}
CMDs[#CMDs + 1] = {NAME = 'noarms', DESC = 'Removes your arms'}
CMDs[#CMDs + 1] = {NAME = 'nolegs', DESC = 'Removes your legs'}
CMDs[#CMDs + 1] = {NAME = 'nolimbs', DESC = 'Removes your limbs'}
CMDs[#CMDs + 1] = {NAME = 'naked (CLIENT)', DESC = 'Removes your clothing'}
CMDs[#CMDs + 1] = {NAME = 'noface / removeface', DESC = 'Removes your face'}
CMDs[#CMDs + 1] = {NAME = 'blockhead', DESC = 'Turns your head into a block'}
CMDs[#CMDs + 1] = {NAME = 'blockhats', DESC = 'Turns your hats into blocks'}
CMDs[#CMDs + 1] = {NAME = 'blocktool', DESC = 'Turns the currently selected tool into a block'}
CMDs[#CMDs + 1] = {NAME = 'creeper', DESC = 'Makes you look like a creeper'}
CMDs[#CMDs + 1] = {NAME = 'drophats', DESC = 'Drops your hats'}
CMDs[#CMDs + 1] = {NAME = 'nohats / deletehats / rhats', DESC = 'Deletes your hats'}
CMDs[#CMDs + 1] = {NAME = 'hatspin / spinhats', DESC = 'Spins your characters accessories'}
CMDs[#CMDs + 1] = {NAME = 'unhatspin / unspinhats', DESC = 'Undoes spinhats'}
CMDs[#CMDs + 1] = {NAME = 'clearhats / cleanhats', DESC = 'Clears hats in the workspace'}
CMDs[#CMDs + 1] = {NAME = 'chardelete / cd [instance name]', DESC = 'Removes any part with a certain name from your character'}
CMDs[#CMDs + 1] = {NAME = 'chardeleteclass / cdc [class name]', DESC = 'Removes any part with a certain classname from your character'}
CMDs[#CMDs + 1] = {NAME = 'deletevelocity / dv / removeforces', DESC = 'Removes any velocity / force instances in your character'}
CMDs[#CMDs + 1] = {NAME = 'weaken [num]', DESC = 'Makes your character less dense'}
CMDs[#CMDs + 1] = {NAME = 'unweaken', DESC = 'Sets your characters CustomPhysicalProperties to default'}
CMDs[#CMDs + 1] = {NAME = 'strengthen [num]', DESC = 'Makes your character more dense (CustomPhysicalProperties)'}
CMDs[#CMDs + 1] = {NAME = 'unstrengthen', DESC = 'Sets your characters CustomPhysicalProperties to default'}
CMDs[#CMDs + 1] = {NAME = 'breakvelocity', DESC = 'Sets your characters velocity to 0'}
CMDs[#CMDs + 1] = {NAME = 'spin [speed]', DESC = 'Spins your character'}
CMDs[#CMDs + 1] = {NAME = 'unspin', DESC = 'Disables spin'}
CMDs[#CMDs + 1] = {NAME = 'split', DESC = 'Splits your character in half'}
CMDs[#CMDs + 1] = {NAME = 'nilchar', DESC = 'Sets your characters parent to nil'}
CMDs[#CMDs + 1] = {NAME = 'unnilchar / nonilchar', DESC = 'Sets your characters parent to workspace'}
CMDs[#CMDs + 1] = {NAME = 'noroot / removeroot / rroot', DESC = 'Removes your characters HumanoidRootPart'}
CMDs[#CMDs + 1] = {NAME = 'replaceroot', DESC = 'Replaces your characters HumanoidRootPart'}
CMDs[#CMDs + 1] = {NAME = 'clearcharappearance / clearchar / clrchar', DESC = 'Removes all accessory, shirt, pants, charactermesh, and bodycolors'}
CMDs[#CMDs + 1] = {NAME = 'tpwalk / teleportwalk [num]', DESC = 'Teleports you to your move direction'}
CMDs[#CMDs + 1] = {NAME = 'untpwalk / unteleportwalk', DESC = 'Undoes tpwalk / teleportwalk'}
CMDs[#CMDs + 1] = {NAME = 'trip', DESC = 'Makes your character fall over'}
CMDs[#CMDs + 1] = {NAME = 'wallwalk / walkonwalls', DESC = 'Walk on walls'}
CMDs[#CMDs + 1] = {NAME = 'promptr6', DESC = 'Prompts the game to switch your rig type to R6'}
CMDs[#CMDs + 1] = {NAME = 'promptr15', DESC = 'Prompts the game to switch your rig type to R15'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'animation / anim [ID] [speed]', DESC = 'Makes your character perform an animation (must be an animation on the marketplace or by roblox/stickmasterluke to replicate)'}
CMDs[#CMDs + 1] = {NAME = 'emote / em [ID] [speed]', DESC = 'Makes your character perform an emote (must be on the marketplace or by roblox/stickmasterluke to replicate)'}
CMDs[#CMDs + 1] = {NAME = 'dance', DESC = 'Makes you  d a n c e'}
CMDs[#CMDs + 1] = {NAME = 'undance', DESC = 'Stops dance animations'}
CMDs[#CMDs + 1] = {NAME = 'spasm', DESC = 'Makes you  c r a z y'}
CMDs[#CMDs + 1] = {NAME = 'unspasm', DESC = 'Stops spasm'}
CMDs[#CMDs + 1] = {NAME = 'headthrow', DESC = 'Simply makes you throw your head'}
CMDs[#CMDs + 1] = {NAME = 'noanim', DESC = 'Disables your animations'}
CMDs[#CMDs + 1] = {NAME = 'reanim', DESC = 'Restores your animations'}
CMDs[#CMDs + 1] = {NAME = 'animspeed [num]', DESC = 'Changes the speed of your current animation'}
CMDs[#CMDs + 1] = {NAME = 'copyanimation / copyanim / copyemote [player]', DESC = 'Copies someone elses animation'}
CMDs[#CMDs + 1] = {NAME = 'copyanimationid / copyanimid / copyemoteid [player]', DESC = 'Copies your animation id or someone elses to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'loopanimation / loopanim', DESC = 'Loops your current animation'}
CMDs[#CMDs + 1] = {NAME = 'stopanimations / stopanims', DESC = 'Stops running animations'}
CMDs[#CMDs + 1] = {NAME = 'refreshanimations / refreshanims', DESC = 'Refreshes animations'}
CMDs[#CMDs + 1] = {NAME = 'allowcustomanim / allowcustomanimations', DESC = 'Lets you use custom animation packs instead'}
CMDs[#CMDs + 1] = {NAME = 'unallowcustomanim / unallowcustomanimations', DESC = 'Doesn\'t let you use custom animation packs instead'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'autoclick [click delay] [release delay]', DESC = 'Automatically clicks your mouse with a set delay'}
CMDs[#CMDs + 1] = {NAME = 'unautoclick / noautoclick', DESC = 'Turns off autoclick'}
CMDs[#CMDs + 1] = {NAME = 'autokeypress [key] [down delay] [up delay]', DESC = 'Automatically presses a key with a set delay'}
CMDs[#CMDs + 1] = {NAME = 'unautokeypress', DESC = 'Stops autokeypress'}
CMDs[#CMDs + 1] = {NAME = 'hovername', DESC = 'Shows a players username when your mouse is hovered over them'}
CMDs[#CMDs + 1] = {NAME = 'unhovername / nohovername', DESC = 'Turns off hovername'}
CMDs[#CMDs + 1] = {NAME = 'mousesensitivity / ms [0-10]', DESC = 'Sets your mouse sensitivity (affects first person and right click drag) (default is 1)'}
CMDs[#CMDs + 1] = {NAME = 'clickdelete', DESC = 'Go to Settings > Keybinds > Add for click delete'}
CMDs[#CMDs + 1] = {NAME = 'clickteleport', DESC = 'Go to Settings > Keybinds > Add for click teleport'}
CMDs[#CMDs + 1] = {NAME = 'mouseteleport / mousetp', DESC = 'Teleports your character to your mouse. This is recommended as a keybind'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'tools', DESC = 'Copies tools from ReplicatedStorage and Lighting'}
CMDs[#CMDs + 1] = {NAME = 'notools / removetools / deletetools', DESC = 'Removes tools from character and backpack'}
CMDs[#CMDs + 1] = {NAME = 'deleteselectedtool / dst', DESC = 'Removes any currently selected tools'}
CMDs[#CMDs + 1] = {NAME = 'grabtools', DESC = 'Automatically get tools that are dropped'}
CMDs[#CMDs + 1] = {NAME = 'ungrabtools / nograbtools', DESC = 'Disables grabtools'}
CMDs[#CMDs + 1] = {NAME = 'copytools [player] (CLIENT)', DESC = 'Copies a players tools'}
CMDs[#CMDs + 1] = {NAME = 'dupetools / clonetools [num]', DESC = 'Duplicates your inventory tools a set amount of times'}
CMDs[#CMDs + 1] = {NAME = 'droptools', DESC = 'Drops your tools'}
CMDs[#CMDs + 1] = {NAME = 'droppabletools', DESC = 'Makes your tools droppable'}
CMDs[#CMDs + 1] = {NAME = 'equiptools', DESC = 'Equips every tool in your inventory at once'}
CMDs[#CMDs + 1] = {NAME = 'unequiptools', DESC = 'Unequips every tool you are currently holding at once'}
CMDs[#CMDs + 1] = {NAME = 'removespecifictool [name]', DESC = 'Automatically remove a specific tool from your inventory'}
CMDs[#CMDs + 1] = {NAME = 'unremovespecifictool [name]', DESC = 'Stops removing a specific tool from your inventory'}
CMDs[#CMDs + 1] = {NAME = 'clearremovespecifictool', DESC = 'Stop removing all specific tools from your inventory'}
CMDs[#CMDs + 1] = {NAME = 'reach [num]', DESC = 'Increases the hitbox of your held tool'}
CMDs[#CMDs + 1] = {NAME = 'boxreach [num]', DESC = 'Increases the hitbox of your held tool in a box shape'}
CMDs[#CMDs + 1] = {NAME = 'unreach / noreach', DESC = 'Turns off reach'}
CMDs[#CMDs + 1] = {NAME = 'grippos [X Y Z]', DESC = 'Changes your current tools grip position'}
CMDs[#CMDs + 1] = {NAME = 'usetools [amount] [delay]', DESC = 'Activates all tools in your backpack at the same time'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'addalias [cmd] [alias]', DESC = 'Adds an alias to a command'}
CMDs[#CMDs + 1] = {NAME = 'removealias [alias]', DESC = 'Removes a custom alias'}
CMDs[#CMDs + 1] = {NAME = 'clraliases', DESC = 'Removes all custom aliases'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'addplugin / plugin [name]', DESC = 'Add a plugin via command'}
CMDs[#CMDs + 1] = {NAME = 'removeplugin / deleteplugin [name]', DESC = 'Remove a plugin via command'}
CMDs[#CMDs + 1] = {NAME = 'reloadplugin [name]', DESC = 'Reloads a plugin'}
CMDs[#CMDs + 1] = {NAME = 'addallplugins / loadallplugins', DESC = 'Adds all available plugins from the workspace folder'}
-- wait()

for i = 1, #CMDs do
	local newcmd = Example:Clone()
	newcmd.Parent = CMDsF
	newcmd.Visible = false
	newcmd.Text = CMDs[i].NAME
	newcmd.Name = "CMD"
	table.insert(text1, newcmd)
	if CMDs[i].DESC ~= "" then
		newcmd:SetAttribute("Title", CMDs[i].NAME)
		newcmd:SetAttribute("Desc", CMDs[i].DESC)
		newcmd.MouseButton1Down:Connect(function()
			if not IsOnMobile and newcmd.Visible and newcmd.TextTransparency == 0 then
				local currentText = Cmdbar.Text
				Cmdbar:CaptureFocus()
				autoComplete(newcmd.Text, currentText)
				maximizeHolder()
			end
		end)
	end
end

IndexContents("", true)

function checkTT()
	local t
	local guisAtPosition = COREGUI:GetGuiObjectsAtPosition(IYMouse.X, IYMouse.Y)

	for _, gui in pairs(guisAtPosition) do
		if gui.Parent == CMDsF then
			t = gui
		end
	end

	if t ~= nil and t:GetAttribute("Title") ~= nil then
		local x = IYMouse.X
		local y = IYMouse.Y
		local xP
		local yP
		if IYMouse.X > 200 then
			xP = x - 201
		else
			xP = x + 21
		end
		if IYMouse.Y > (IYMouse.ViewSizeY-96) then
			yP = y - 97
		else
			yP = y
		end
		Tooltip.Position = UDim2.new(0, xP, 0, yP)
		Description.Text = t:GetAttribute("Desc")
		if t:GetAttribute("Title") ~= nil then
			Title_3.Text = t:GetAttribute("Title")
		else
			Title_3.Text = ''
		end
		Tooltip.Visible = true
	else
		Tooltip.Visible = false
	end
end

function FindInTable(tbl,val)
	if tbl == nil then return false end
	for _,v in pairs(tbl) do
		if v == val then return true end
	end 
	return false
end

function GetInTable(Table, Name)
	for i = 1, #Table do
		if Table[i] == Name then
			return i
		end
	end
	return false
end

function respawn(plr)
	if invisRunning then TurnVisible() end
    local char = plr.Character
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
    char:ClearAllChildren()
    local newChar = Instance.new("Model")
    newChar.Parent = workspace
    plr.Character = newChar
    task.wait()
    plr.Character = char
    newChar:Destroy()
end

local refreshCmd = false
function refresh(plr)
	refreshCmd = true
	local root = getRoot(plr.Character)
	local pos = root.CFrame
	local pos1 = workspace.CurrentCamera.CFrame
	respawn(plr)
	task.spawn(function()
		local char = plr.CharacterAdded:Wait()
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		while not humanoid do
			wait()
			humanoid = char:FindFirstChildOfClass("Humanoid")
		end
		humanoid.RootPart.CFrame, workspace.CurrentCamera.CFrame = pos, task.wait() and pos1
		refreshCmd = false
	end)
end

local lastDeath

function onDied()
	task.spawn(function()
		if pcall(function() Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') end) and Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
			Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').Died:Connect(function()
				if getRoot(Players.LocalPlayer.Character) then
					lastDeath = getRoot(Players.LocalPlayer.Character).CFrame
				end
			end)
		else
			wait(2)
			onDied()
		end
	end)
end

Clip = true
spDelay = 0.1
Players.LocalPlayer.CharacterAdded:Connect(function()
	NOFLY()
	Floating = false

	if not Clip then
		execCmd('clip')
	end

	repeat wait() until getRoot(Players.LocalPlayer.Character)

	pcall(function()
		if spawnpoint and not refreshCmd and spawnpos ~= nil then
			wait(spDelay)
			getRoot(Players.LocalPlayer.Character).CFrame = spawnpos
		end
	end)

	onDied()
end)

onDied()

local booly = {
    truthy = { ["true"] = true, ["t"] = true, ["1"] = true, yes = true, y = true, on = true, enable = true, enabled = true },
    falsy = { ["false"] = true, ["f"] = true, ["0"] = true, no = true, n = true, off = true, disable = true, disabled = true }
}

function parseBoolean(raw, default)
    raw = tostring(raw)
    if booly.truthy[raw] then return true end
    if booly.falsy[raw] then return false end
    return default or false
end

function getstring(begin, args)
    return table.concat(args or cargs, " ", begin)
end

findCmd=function(cmd_name)
	for i,v in pairs(cmds)do
		if v.NAME:lower()==cmd_name:lower() or FindInTable(v.ALIAS,cmd_name:lower()) then
			return v
		end
	end
	return customAlias[cmd_name:lower()]
end

function splitString(str,delim)
	local broken = {}
	if delim == nil then delim = "," end
	for w in string.gmatch(str,"[^"..delim.."]+") do
		table.insert(broken,w)
	end
	return broken
end

cmdHistory = {}
local lastCmds = {}
local historyCount = 0
local split=" "
local lastBreakTime = 0
function execCmd(cmdStr,speaker,store)
	cmdStr = cmdStr:gsub("%s+$","")
	task.spawn(function()
		local rawCmdStr = cmdStr
		cmdStr = string.gsub(cmdStr,"\\\\","%%BackSlash%%")
		local commandsToRun = splitString(cmdStr,"\\")
		for i,v in pairs(commandsToRun) do
			v = string.gsub(v,"%%BackSlash%%","\\")
			local x,y,num = v:find("^(%d+)%^")
			local cmdDelay = 0
			local infTimes = false
			if num then
				v = v:sub(y+1)
				local x,y,del = v:find("^([%d%.]+)%^")
				if del then
					v = v:sub(y+1)
					cmdDelay = tonumber(del) or 0
				end
			else
				local x,y = v:find("^inf%^")
				if x then
					infTimes = true
					v = v:sub(y+1)
					local x,y,del = v:find("^([%d%.]+)%^")
					if del then
						v = v:sub(y+1)
						del = tonumber(del) or 1
						cmdDelay = (del > 0 and del or 1)
					else
						cmdDelay = 1
					end
				end
			end
			num = tonumber(num or 1)

			if v:sub(1,1) == "!" then
				local chunks = splitString(v:sub(2),split)
				if chunks[1] and lastCmds[chunks[1]] then v = lastCmds[chunks[1]] end
			end

			local args = splitString(v,split)
			local cmdName = args[1]
			local cmd = findCmd(cmdName)
			if cmd then
				table.remove(args,1)
				cargs = args
				if not speaker then speaker = Players.LocalPlayer end
				if store then
					if speaker == Players.LocalPlayer then
						if cmdHistory[1] ~= rawCmdStr and rawCmdStr:sub(1,11) ~= 'lastcommand' and rawCmdStr:sub(1,7) ~= 'lastcmd' then
							table.insert(cmdHistory,1,rawCmdStr)
						end
					end
					if #cmdHistory > 30 then table.remove(cmdHistory) end

					lastCmds[cmdName] = v
				end
				local cmdStartTime = tick()
				if infTimes then
					while lastBreakTime < cmdStartTime do
						local success,err = pcall(cmd.FUNC,args, speaker)
						if not success and _G.IY_DEBUG then
							warn("Command Error:", cmdName, err)
						end
						wait(cmdDelay)
					end
				else
					for rep = 1,num do
						if lastBreakTime > cmdStartTime then break end
						local success,err = pcall(function()
							cmd.FUNC(args, speaker)
						end)
						if not success and _G.IY_DEBUG then
							warn("Command Error:", cmdName, err)
						end
						if cmdDelay ~= 0 then wait(cmdDelay) end
					end
				end
			end
		end
	end)
end	
getgenv().execCmd = execCmd

function addcmd(name,alias,func,plgn)
	cmds[#cmds+1]=
		{
			NAME=name;
			ALIAS=alias or {};
			FUNC=func;
			PLUGIN=plgn;
		}
end

function removecmd(cmd)
	if cmd ~= " " then
		for i = #cmds,1,-1 do
			if cmds[i].NAME == cmd or FindInTable(cmds[i].ALIAS,cmd) then
				table.remove(cmds, i)
				for a,c in pairs(CMDsF:GetChildren()) do
					if string.find(c.Text, "^"..cmd.."$") or string.find(c.Text, "^"..cmd.." ") or string.find(c.Text, " "..cmd.."$") or string.find(c.Text, " "..cmd.." ") then
						c.TextTransparency = 0.7
						c.MouseButton1Click:Connect(function()
							notify(c.Text, "Command has been disabled by you or a plugin")
						end)
					end
				end
			end
		end
	end
end

function overridecmd(name, func)
	local cmd = findCmd(name)
	if cmd and cmd.FUNC then cmd.FUNC = func end
end

function addbind(cmd,key,iskeyup,toggle)
getgenv().addbind = addbind
	if toggle then
		binds[#binds+1]=
			{
				COMMAND=cmd;
				KEY=key;
				ISKEYUP=iskeyup;
				TOGGLE = toggle;
			}
	else
		binds[#binds+1]=
			{
				COMMAND=cmd;
				KEY=key;
				ISKEYUP=iskeyup;
			}
	end
end

function addcmdtext(text,name,desc)
	local newcmd = Example:Clone()
	local tooltipText = tostring(text)
	local tooltipDesc = tostring(desc)
	newcmd.Parent = CMDsF
	newcmd.Visible = false
	newcmd.Text = text
	newcmd.Name = 'PLUGIN_'..name
	table.insert(text1,newcmd)
	if desc and desc ~= '' then
		newcmd:SetAttribute("Title", tooltipText)
		newcmd:SetAttribute("Desc", tooltipDesc)
		newcmd.MouseButton1Down:Connect(function()
			if newcmd.Visible and newcmd.TextTransparency == 0 then
				Cmdbar:CaptureFocus()
				autoComplete(newcmd.Text)
				maximizeHolder()
			end
		end)
	end
end

local WorldToScreen = function(Object)
	local ObjectVector = workspace.CurrentCamera:WorldToScreenPoint(Object.Position)
	return Vector2.new(ObjectVector.X, ObjectVector.Y)
end

local MousePositionToVector2 = function()
	return Vector2.new(IYMouse.X, IYMouse.Y)
end

local GetClosestPlayerFromCursor = function()
	local found = nil
	local ClosestDistance = math.huge
	for i, v in pairs(Players:GetPlayers()) do
		if v ~= Players.LocalPlayer and v.Character and v.Character:FindFirstChildOfClass("Humanoid") then
			for k, x in pairs(v.Character:GetChildren()) do
				if string.find(x.Name, "Torso") then
					local Distance = (WorldToScreen(x) - MousePositionToVector2()).Magnitude
					if Distance < ClosestDistance then
						ClosestDistance = Distance
						found = v
					end
				end
			end
		end
	end
	return found
end

SpecialPlayerCases = {
	["all"] = function(speaker) return Players:GetPlayers() end,
	["others"] = function(speaker)
		local plrs = {}
		for i,v in pairs(Players:GetPlayers()) do
			if v ~= speaker then
				table.insert(plrs,v)
			end
		end
		return plrs
	end,
	["me"] = function(speaker)return {speaker} end,
	["#(%d+)"] = function(speaker,args,currentList)
		local returns = {}
		local randAmount = tonumber(args[1])
		local players = {unpack(currentList)}
		for i = 1,randAmount do
			if #players == 0 then break end
			local randIndex = math.random(1,#players)
			table.insert(returns,players[randIndex])
			table.remove(players,randIndex)
		end
		return returns
	end,
	["random"] = function(speaker,args,currentList)
		local players = Players:GetPlayers()
		local localplayer = Players.LocalPlayer
		table.remove(players, table.find(players, localplayer))
		return {players[math.random(1,#players)]}
	end,
	["%%(.+)"] = function(speaker,args)
		local returns = {}
		local team = args[1]
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Team and string.sub(string.lower(plr.Team.Name),1,#team) == string.lower(team) then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["allies"] = function(speaker)
		local returns = {}
		local team = speaker.Team
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Team == team then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["enemies"] = function(speaker)
		local returns = {}
		local team = speaker.Team
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Team ~= team then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["team"] = function(speaker)
		local returns = {}
		local team = speaker.Team
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Team == team then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["nonteam"] = function(speaker)
		local returns = {}
		local team = speaker.Team
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Team ~= team then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["friends"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if plr:IsFriendsWith(speaker.UserId) and plr ~= speaker then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["nonfriends"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if not plr:IsFriendsWith(speaker.UserId) and plr ~= speaker then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["guests"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Guest then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["bacons"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Character:FindFirstChild('Pal Hair') or plr.Character:FindFirstChild('Kate Hair') then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["age(%d+)"] = function(speaker,args)
		local returns = {}
		local age = tonumber(args[1])
		if not age == nil then return end
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.AccountAge <= age then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["nearest"] = function(speaker,args,currentList)
		local speakerChar = speaker.Character
		if not speakerChar or not getRoot(speakerChar) then return end
		local lowest = math.huge
		local NearestPlayer = nil
		for _,plr in pairs(currentList) do
			if plr ~= speaker and plr.Character then
				local distance = plr:DistanceFromCharacter(getRoot(speakerChar).Position)
				if distance < lowest then
					lowest = distance
					NearestPlayer = {plr}
				end
			end
		end
		return NearestPlayer
	end,
	["farthest"] = function(speaker,args,currentList)
		local speakerChar = speaker.Character
		if not speakerChar or not getRoot(speakerChar) then return end
		local highest = 0
		local Farthest = nil
		for _,plr in pairs(currentList) do
			if plr ~= speaker and plr.Character then
				local distance = plr:DistanceFromCharacter(getRoot(speakerChar).Position)
				if distance > highest then
					highest = distance
					Farthest = {plr}
				end
			end
		end
		return Farthest
	end,
	["group(%d+)"] = function(speaker,args)
		local returns = {}
		local groupID = tonumber(args[1])
		for _,plr in pairs(Players:GetPlayers()) do
			if plr:IsInGroup(groupID) then  
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["alive"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["dead"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if (not plr.Character or not plr.Character:FindFirstChildOfClass("Humanoid")) or plr.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["rad(%d+)"] = function(speaker,args)
		local returns = {}
		local radius = tonumber(args[1])
		local speakerChar = speaker.Character
		if not speakerChar or not getRoot(speakerChar) then return end
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Character and getRoot(plr.Character) then
				local magnitude = (getRoot(plr.Character).Position-getRoot(speakerChar).Position).magnitude
				if magnitude <= radius then table.insert(returns,plr) end
			end
		end
		return returns
	end,
	["cursor"] = function(speaker)
		local plrs = {}
		local v = GetClosestPlayerFromCursor()
		if v ~= nil then table.insert(plrs, v) end
		return plrs
	end,
	["npcs"] = function(speaker,args)
		local returns = {}
		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA("Model") and getRoot(v) and v:FindFirstChildWhichIsA("Humanoid") and Players:GetPlayerFromCharacter(v) == nil then
				local clone = Instance.new("Player")
				clone.Name = v.Name .. " - " .. v:FindFirstChildWhichIsA("Humanoid").DisplayName
				clone.Character = v
				table.insert(returns, clone)
			end
		end
		return returns
	end,
}

function toTokens(str)
	local tokens = {}
	for op,name in string.gmatch(str,"([+-])([^+-]+)") do
		table.insert(tokens,{Operator = op,Name = name})
	end
	return tokens
end

function onlyIncludeInTable(tab,matches)
	local matchTable = {}
	local resultTable = {}
	for i,v in pairs(matches) do matchTable[v.Name] = true end
	for i,v in pairs(tab) do if matchTable[v.Name] then table.insert(resultTable,v) end end
	return resultTable
end

function removeTableMatches(tab,matches)
	local matchTable = {}
	local resultTable = {}
	for i,v in pairs(matches) do matchTable[v.Name] = true end
	for i,v in pairs(tab) do if not matchTable[v.Name] then table.insert(resultTable,v) end end
	return resultTable
end

function getPlayersByName(Name)
	local Name,Len,Found = string.lower(Name),#Name,{}
	for _,v in pairs(Players:GetPlayers()) do
		if Name:sub(0,1) == '@' then
			if string.sub(string.lower(v.Name),1,Len-1) == Name:sub(2) then
				table.insert(Found,v)
			end
		else
			if string.sub(string.lower(v.Name),1,Len) == Name or string.sub(string.lower(v.DisplayName),1,Len) == Name then
				table.insert(Found,v)
			end
		end
	end
	return Found
end

function getPlayer(list,speaker)
	if list == nil then return {speaker.Name} end
	local nameList = splitString(list,",")

	local foundList = {}

	for _,name in pairs(nameList) do
		if string.sub(name,1,1) ~= "+" and string.sub(name,1,1) ~= "-" then name = "+"..name end
		local tokens = toTokens(name)
		local initialPlayers = Players:GetPlayers()

		for i,v in pairs(tokens) do
			if v.Operator == "+" then
				local tokenContent = v.Name
				local foundCase = false
				for regex,case in pairs(SpecialPlayerCases) do
					local matches = {string.match(tokenContent,"^"..regex.."$")}
					if #matches > 0 then
						foundCase = true
						initialPlayers = onlyIncludeInTable(initialPlayers,case(speaker,matches,initialPlayers))
					end
				end
				if not foundCase then
					initialPlayers = onlyIncludeInTable(initialPlayers,getPlayersByName(tokenContent))
				end
			else
				local tokenContent = v.Name
				local foundCase = false
				for regex,case in pairs(SpecialPlayerCases) do
					local matches = {string.match(tokenContent,"^"..regex.."$")}
					if #matches > 0 then
						foundCase = true
						initialPlayers = removeTableMatches(initialPlayers,case(speaker,matches,initialPlayers))
					end
				end
				if not foundCase then
					initialPlayers = removeTableMatches(initialPlayers,getPlayersByName(tokenContent))
				end
			end
		end

		for i,v in pairs(initialPlayers) do table.insert(foundList,v) end
	end

	local foundNames = {}
	for i,v in pairs(foundList) do table.insert(foundNames,v.Name) end

	return foundNames
end

function formatUsername(player)
	if player.DisplayName ~= player.Name then
		return string.format("%s (%s)", player.Name, player.DisplayName)
	end
	return player.Name
end

getprfx=function(strn)
	if strn:sub(1,string.len(prefix))==prefix then return{'cmd',string.len(prefix)+1}
	end return
end

function do_exec(str, plr)
	str = str:gsub('/e ', '')
	local t = getprfx(str)
	if not t then return end
	str = str:sub(t[2])
	if t[1]=='cmd' then
		execCmd(str, plr, true)
		IndexContents('',true,false,true)
		CMDsF.CanvasPosition = canvasPos
	end
end

lastTextBoxString,lastTextBoxCon,lastEnteredString = nil,nil,nil

UserInputService.TextBoxFocused:Connect(function(obj)
	if lastTextBoxCon then lastTextBoxCon:Disconnect() end
	if obj == Cmdbar then lastTextBoxString = nil return end
	lastTextBoxString = obj.Text
	lastTextBoxCon = obj:GetPropertyChangedSignal("Text"):Connect(function()
		if not (UserInputService:IsKeyDown(Enum.KeyCode.Return) or UserInputService:IsKeyDown(Enum.KeyCode.KeypadEnter)) then
			lastTextBoxString = obj.Text
		end
	end)
end)

UserInputService.InputBegan:Connect(function(input,gameProcessed)
	if gameProcessed then
		if Cmdbar and Cmdbar:IsFocused() then
			if input.KeyCode == Enum.KeyCode.Up then
				historyCount = historyCount + 1
				if historyCount > #cmdHistory then historyCount = #cmdHistory end
				Cmdbar.Text = cmdHistory[historyCount] or ""
				Cmdbar.CursorPosition = 1020
			elseif input.KeyCode == Enum.KeyCode.Down then
				historyCount = historyCount - 1
				if historyCount < 0 then historyCount = 0 end
				Cmdbar.Text = cmdHistory[historyCount] or ""
				Cmdbar.CursorPosition = 1020
			end
		elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
			lastEnteredString = lastTextBoxString
		end
	end
end)

Players.LocalPlayer.Chatted:Connect(function()
	wait()
	if lastEnteredString then
		local message = lastEnteredString
		lastEnteredString = nil
		do_exec(message, Players.LocalPlayer)
	end
end)

Cmdbar.PlaceholderText = "Command Bar ("..prefix..")"
Cmdbar:GetPropertyChangedSignal("Text"):Connect(function()
	if Cmdbar:IsFocused() then
		IndexContents(Cmdbar.Text,true,true)
	end
end)

local tabComplete = nil
tabAllowed = true
Cmdbar.FocusLost:Connect(function(enterpressed)
	if enterpressed then
		local cmdbarText = Cmdbar.Text:gsub("^"..prefix,"")
		execCmd(cmdbarText,Players.LocalPlayer,true)
	end
	if tabComplete then tabComplete:Disconnect() end
	wait()
	if not Cmdbar:IsFocused() then
		Cmdbar.Text = ""
		IndexContents('',true,false,true)
		if SettingsOpen == true then
			wait(0.2)
			Settings:TweenPosition(UDim2.new(0, 0, 0, 45), "InOut", "Quart", 0.2, true, nil)
			CMDsF.Visible = false
		end
	end
	CMDsF.CanvasPosition = canvasPos
end)

Cmdbar.Focused:Connect(function()
	historyCount = 0
	canvasPos = CMDsF.CanvasPosition
	if SettingsOpen == true then
		wait(0.2)
		CMDsF.Visible = true
		Settings:TweenPosition(UDim2.new(0, 0, 0, 220), "InOut", "Quart", 0.2, true, nil)
	end
	tabComplete = UserInputService.InputBegan:Connect(function(input,gameProcessed)
		if Cmdbar:IsFocused() then
			if tabAllowed == true and input.KeyCode == Enum.KeyCode.Tab and topCommand ~= nil then
				autoComplete(topCommand)
			end
		else
			tabComplete:Disconnect()
		end
	end)
end)

ESPenabled = false
CHMSenabled = false

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function ESP(plr, logic, force)
	task.spawn(function()
		for i,v in pairs(COREGUI:GetChildren()) do
			if v.Name == plr.Name..'_ESP' then
				v:Destroy()
			end
		end
		wait()
		if plr.Character and (plr.Name ~= Players.LocalPlayer.Name or force) and not COREGUI:FindFirstChild(plr.Name..'_ESP') then
			local ESPholder = Instance.new("Folder")
			ESPholder.Name = plr.Name..'_ESP'
			ESPholder.Parent = COREGUI
			repeat wait(1) until plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
			for b,n in pairs (plr.Character:GetChildren()) do
				if (n:IsA("BasePart")) then
					local a = Instance.new("BoxHandleAdornment")
					a.Name = plr.Name
					a.Parent = ESPholder
					a.Adornee = n
					a.AlwaysOnTop = true
					a.ZIndex = 10
					a.Size = n.Size
					a.Transparency = espTransparency
					if logic == true then
						a.Color = BrickColor.new(plr.TeamColor == Players.LocalPlayer.TeamColor and "Bright green" or "Bright red")
					else
						a.Color = plr.TeamColor
					end
				end
			end
			if plr.Character and plr.Character:FindFirstChild('Head') then
				local BillboardGui = Instance.new("BillboardGui")
				local TextLabel = Instance.new("TextLabel")
				BillboardGui.Adornee = plr.Character.Head
				BillboardGui.Name = plr.Name
				BillboardGui.Parent = ESPholder
				BillboardGui.Size = UDim2.new(0, 100, 0, 150)
				BillboardGui.StudsOffset = Vector3.new(0, 1, 0)
				BillboardGui.AlwaysOnTop = true
				TextLabel.Parent = BillboardGui
				TextLabel.BackgroundTransparency = 1
				TextLabel.Position = UDim2.new(0, 0, 0, -50)
				TextLabel.Size = UDim2.new(0, 100, 0, 100)
				TextLabel.Font = Enum.Font.SourceSansSemibold
				TextLabel.TextSize = 20
				TextLabel.TextColor3 = Color3.new(1, 1, 1)
				TextLabel.TextStrokeTransparency = 0
				TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
				TextLabel.RichText = true
				local espName = plr.DisplayName
				if table.find(siriusValues.devs, plr.Name:lower()) then
					espName = espName .. " <font color='#00ff00'>[Dev]</font>"
				end
				TextLabel.Text = 'Name: '..espName
				TextLabel.ZIndex = 10
				local espLoopFunc
				local teamChange
				local addedFunc
				addedFunc = plr.CharacterAdded:Connect(function()
					if ESPenabled then
						espLoopFunc:Disconnect()
						teamChange:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
						ESP(plr, logic)
						addedFunc:Disconnect()
					else
						teamChange:Disconnect()
						addedFunc:Disconnect()
					end
				end)
				teamChange = plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
					if ESPenabled then
						espLoopFunc:Disconnect()
						addedFunc:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
						ESP(plr, logic)
						teamChange:Disconnect()
					else
						teamChange:Disconnect()
					end
				end)
				local function espLoop()
					if COREGUI:FindFirstChild(plr.Name..'_ESP') then
						if plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid") and Players.LocalPlayer.Character and getRoot(Players.LocalPlayer.Character) and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
							local pos = math.floor((getRoot(Players.LocalPlayer.Character).Position - getRoot(plr.Character).Position).magnitude)
							TextLabel.Text = 'Name: '..plr.Name..' | Health: '..round(plr.Character:FindFirstChildOfClass('Humanoid').Health, 1)..' | Studs: '..pos
						end
					else
						teamChange:Disconnect()
						addedFunc:Disconnect()
						espLoopFunc:Disconnect()
					end
				end
				espLoopFunc = RunService.RenderStepped:Connect(espLoop)
			end
		end
	end)
end

function CHMS(plr)
	task.spawn(function()
		for i,v in pairs(COREGUI:GetChildren()) do
			if v.Name == plr.Name..'_CHMS' then
				v:Destroy()
			end
		end
		wait()
		if plr.Character and plr.Name ~= Players.LocalPlayer.Name and not COREGUI:FindFirstChild(plr.Name..'_CHMS') then
			local ESPholder = Instance.new("Folder")
			ESPholder.Name = plr.Name..'_CHMS'
			ESPholder.Parent = COREGUI
			repeat wait(1) until plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
			for b,n in pairs (plr.Character:GetChildren()) do
				if (n:IsA("BasePart")) then
					local a = Instance.new("BoxHandleAdornment")
					a.Name = plr.Name
					a.Parent = ESPholder
					a.Adornee = n
					a.AlwaysOnTop = true
					a.ZIndex = 10
					a.Size = n.Size
					a.Transparency = espTransparency
					a.Color = plr.TeamColor
				end
			end
			local addedFunc
			local teamChange
			local CHMSremoved
			addedFunc = plr.CharacterAdded:Connect(function()
				if CHMSenabled then
					ESPholder:Destroy()
					teamChange:Disconnect()
					repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
					CHMS(plr)
					addedFunc:Disconnect()
				else
					teamChange:Disconnect()
					addedFunc:Disconnect()
				end
			end)
			teamChange = plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
				if CHMSenabled then
					ESPholder:Destroy()
					addedFunc:Disconnect()
					repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
					CHMS(plr)
					teamChange:Disconnect()
				else
					teamChange:Disconnect()
				end
			end)
			CHMSremoved = ESPholder.AncestryChanged:Connect(function()
				teamChange:Disconnect()
				addedFunc:Disconnect()
				CHMSremoved:Disconnect()
			end)
		end
	end)
end

function Locate(plr)
	task.spawn(function()
		for i,v in pairs(COREGUI:GetChildren()) do
			if v.Name == plr.Name..'_LC' then
				v:Destroy()
			end
		end
		wait()
		if plr.Character and plr.Name ~= Players.LocalPlayer.Name and not COREGUI:FindFirstChild(plr.Name..'_LC') then
			local ESPholder = Instance.new("Folder")
			ESPholder.Name = plr.Name..'_LC'
			ESPholder.Parent = COREGUI
			repeat wait(1) until plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
			for b,n in pairs (plr.Character:GetChildren()) do
				if (n:IsA("BasePart")) then
					local a = Instance.new("BoxHandleAdornment")
					a.Name = plr.Name
					a.Parent = ESPholder
					a.Adornee = n
					a.AlwaysOnTop = true
					a.ZIndex = 10
					a.Size = n.Size
					a.Transparency = espTransparency
					a.Color = plr.TeamColor
				end
			end
			if plr.Character and plr.Character:FindFirstChild('Head') then
				local BillboardGui = Instance.new("BillboardGui")
				local TextLabel = Instance.new("TextLabel")
				BillboardGui.Adornee = plr.Character.Head
				BillboardGui.Name = plr.Name
				BillboardGui.Parent = ESPholder
				BillboardGui.Size = UDim2.new(0, 100, 0, 150)
				BillboardGui.StudsOffset = Vector3.new(0, 1, 0)
				BillboardGui.AlwaysOnTop = true
				TextLabel.Parent = BillboardGui
				TextLabel.BackgroundTransparency = 1
				TextLabel.Position = UDim2.new(0, 0, 0, -50)
				TextLabel.Size = UDim2.new(0, 100, 0, 100)
				TextLabel.Font = Enum.Font.SourceSansSemibold
				TextLabel.TextSize = 20
				TextLabel.TextColor3 = Color3.new(1, 1, 1)
				TextLabel.TextStrokeTransparency = 0
				TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
				TextLabel.Text = 'Name: '..plr.Name
				TextLabel.ZIndex = 10
				local lcLoopFunc
				local addedFunc
				local teamChange
				addedFunc = plr.CharacterAdded:Connect(function()
					if ESPholder ~= nil and ESPholder.Parent ~= nil then
						lcLoopFunc:Disconnect()
						teamChange:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
						Locate(plr)
						addedFunc:Disconnect()
					else
						teamChange:Disconnect()
						addedFunc:Disconnect()
					end
				end)
				teamChange = plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
					if ESPholder ~= nil and ESPholder.Parent ~= nil then
						lcLoopFunc:Disconnect()
						addedFunc:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
						Locate(plr)
						teamChange:Disconnect()
					else
						teamChange:Disconnect()
					end
				end)
				local function lcLoop()
					if COREGUI:FindFirstChild(plr.Name..'_LC') then
						if plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid") and Players.LocalPlayer.Character and getRoot(Players.LocalPlayer.Character) and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
							local pos = math.floor((getRoot(Players.LocalPlayer.Character).Position - getRoot(plr.Character).Position).magnitude)
							TextLabel.Text = 'Name: '..plr.Name..' | Health: '..round(plr.Character:FindFirstChildOfClass('Humanoid').Health, 1)..' | Studs: '..pos
						end
					else
						teamChange:Disconnect()
						addedFunc:Disconnect()
						lcLoopFunc:Disconnect()
					end
				end
				lcLoopFunc = RunService.RenderStepped:Connect(lcLoop)
			end
		end
	end)
end

local bindsGUI = KeybindEditor
local awaitingInput = false
local keySelected = false

function refreshbinds()
getgenv().refreshbinds = refreshbinds
	if Holder_2 then
		Holder_2:ClearAllChildren()
		Holder_2.CanvasSize = UDim2.new(0, 0, 0, 10)
		for i = 1, #binds do
			local YSize = 25
			local Position = ((i * YSize) - YSize)
			local newbind = Example_2:Clone()
			newbind.Parent = Holder_2
			newbind.Visible = true
			newbind.Position = UDim2.new(0,0,0, Position + 5)
			table.insert(shade2,newbind)
			table.insert(shade2,newbind.Text)
			table.insert(text1,newbind.Text)
			table.insert(shade3,newbind.Text.Delete)
			table.insert(text2,newbind.Text.Delete)
			local input = tostring(binds[i].KEY)
			local key
			if input == 'RightClick' or input == 'LeftClick' then
				key = input
			else
				key = input:sub(14)
			end
			if binds[i].TOGGLE then
				newbind.Text.Text = key.." > "..binds[i].COMMAND.." / "..binds[i].TOGGLE
			else
				newbind.Text.Text = key.." > "..binds[i].COMMAND.."  "..(binds[i].ISKEYUP and "(keyup)" or "(keydown)")
			end
			Holder_2.CanvasSize = UDim2.new(0,0,0, Position + 30)
			newbind.Text.Delete.MouseButton1Click:Connect(function()
				unkeybind(binds[i].COMMAND,binds[i].KEY)
			end)
		end
	end
end

refreshbinds()

toggleOn = {}

function unkeybind(cmd,key)
getgenv().unkeybind = unkeybind
	for i = #binds,1,-1 do
		if binds[i].COMMAND == cmd and binds[i].KEY == key then
			toggleOn[binds[i]] = nil
			table.remove(binds, i)
		end
	end
	refreshbinds()
	updatesaves()
	if key == 'RightClick' or key == 'LeftClick' then
		notify('Keybinds Updated','Unbinded '..key..' from '..cmd)
	else
		notify('Keybinds Updated','Unbinded '..key:sub(14)..' from '..cmd)
	end
end

PositionsFrame.Delete.MouseButton1Click:Connect(function()
	execCmd('cpos')
end)

function refreshwaypoints()
	if #WayPoints > 0 or #pWayPoints > 0 then
		PositionsHint:Destroy()
	end
	if Holder_4 then
		Holder_4:ClearAllChildren()
		Holder_4.CanvasSize = UDim2.new(0, 0, 0, 10)
		local YSize = 25
		local num = 1
		for i = 1, #WayPoints do
			local Position = ((num * YSize) - YSize)
			local newpoint = Example_4:Clone()
			newpoint.Parent = Holder_4
			newpoint.Visible = true
			newpoint.Position = UDim2.new(0,0,0, Position + 5)
			newpoint.Text.Text = WayPoints[i].NAME
			table.insert(shade2,newpoint)
			table.insert(shade2,newpoint.Text)
			table.insert(text1,newpoint.Text)
			table.insert(shade3,newpoint.Text.Delete)
			table.insert(text2,newpoint.Text.Delete)
			table.insert(shade3,newpoint.Text.TP)
			table.insert(text2,newpoint.Text.TP)
			Holder_4.CanvasSize = UDim2.new(0,0,0, Position + 30)
			newpoint.Text.Delete.MouseButton1Click:Connect(function()
				execCmd('dpos '..WayPoints[i].NAME)
			end)
			newpoint.Text.TP.MouseButton1Click:Connect(function()
				execCmd("loadpos "..WayPoints[i].NAME)
			end)
			num = num+1
		end
		for i = 1, #pWayPoints do
			local Position = ((num * YSize) - YSize)
			local newpoint = Example_4:Clone()
			newpoint.Parent = Holder_4
			newpoint.Visible = true
			newpoint.Position = UDim2.new(0,0,0, Position + 5)
			newpoint.Text.Text = pWayPoints[i].NAME
			table.insert(shade2,newpoint)
			table.insert(shade2,newpoint.Text)
			table.insert(text1,newpoint.Text)
			table.insert(shade3,newpoint.Text.Delete)
			table.insert(text2,newpoint.Text.Delete)
			table.insert(shade3,newpoint.Text.TP)
			table.insert(text2,newpoint.Text.TP)
			Holder_4.CanvasSize = UDim2.new(0,0,0, Position + 30)
			newpoint.Text.Delete.MouseButton1Click:Connect(function()
				execCmd('dpos '..pWayPoints[i].NAME)
			end)
			newpoint.Text.TP.MouseButton1Click:Connect(function()
				execCmd("loadpos "..pWayPoints[i].NAME)
			end)
			num = num+1
		end
	end
end

refreshwaypoints()

function refreshaliases()
	if #aliases > 0 then
		AliasHint:Destroy()
	end
	if Holder_3 then
		Holder_3:ClearAllChildren()
		Holder_3.CanvasSize = UDim2.new(0, 0, 0, 10)
		for i = 1, #aliases do
			local YSize = 25
			local Position = ((i * YSize) - YSize)
			local newalias = Example_3:Clone()
			newalias.Parent = Holder_3
			newalias.Visible = true
			newalias.Position = UDim2.new(0,0,0, Position + 5)
			newalias.Text.Text = aliases[i].CMD.." > "..aliases[i].ALIAS
			table.insert(shade2,newalias)
			table.insert(shade2,newalias.Text)
			table.insert(text1,newalias.Text)
			table.insert(shade3,newalias.Text.Delete)
			table.insert(text2,newalias.Text.Delete)
			Holder_3.CanvasSize = UDim2.new(0,0,0, Position + 30)
			newalias.Text.Delete.MouseButton1Click:Connect(function()
				execCmd('removealias '..aliases[i].ALIAS)
			end)
		end
	end
end

local bindChosenKeyUp = false

BindTo.MouseButton1Click:Connect(function()
	awaitingInput = true
	BindTo.Text = 'Press something'
end)

BindTriggerSelect.MouseButton1Click:Connect(function()
	bindChosenKeyUp = not bindChosenKeyUp
	BindTriggerSelect.Text = bindChosenKeyUp and "KeyUp" or "KeyDown"
end)

newToggle = false
Cmdbar_3.Parent.Visible = false
On_2.MouseButton1Click:Connect(function()
	if newToggle == false then newToggle = true
		On_2.BackgroundTransparency = 0
		Cmdbar_3.Parent.Visible = true
		BindTriggerSelect.Visible = false
	else newToggle = false
		On_2.BackgroundTransparency = 1
		Cmdbar_3.Parent.Visible = false
		BindTriggerSelect.Visible = true
	end
end)

Add_2.MouseButton1Click:Connect(function()
	if keySelected then
		if string.find(Cmdbar_2.Text, "\\\\") or string.find(Cmdbar_3.Text, "\\\\") then
			notify('Keybind Error','Only use one backslash to keybind multiple commands into one keybind or command')
		else
			if newToggle and Cmdbar_3.Text ~= '' and Cmdbar_2.text ~= '' then
				addbind(Cmdbar_2.Text,keyPressed,false,Cmdbar_3.Text)
			elseif not newToggle and Cmdbar_2.text ~= '' then
				addbind(Cmdbar_2.Text,keyPressed,bindChosenKeyUp)
			else
				return
			end
			refreshbinds()
			updatesaves()
			if keyPressed == 'RightClick' or keyPressed == 'LeftClick' then
				notify('Keybinds Updated','Binded '..keyPressed..' to '..Cmdbar_2.Text..(newToggle and " / "..Cmdbar_3.Text or ""))
			else
				notify('Keybinds Updated','Binded '..keyPressed:sub(14)..' to '..Cmdbar_2.Text..(newToggle and " / "..Cmdbar_3.Text or ""))
			end
		end
	end
end)

Exit_2.MouseButton1Click:Connect(function()
	Cmdbar_2.Text = 'Command'
	Cmdbar_3.Text = 'Command 2'
	BindTo.Text = 'Click to bind'
	bindChosenKeyUp = false
	BindTriggerSelect.Text = "KeyDown"
	keySelected = false
	KeybindEditor:TweenPosition(UDim2.new(0.5, -180, 0, -500), "InOut", "Quart", 0.5, true, nil)
end)

function onInputBegan(input,gameProcessed)
	if awaitingInput then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			keyPressed = tostring(input.KeyCode)
			BindTo.Text = keyPressed:sub(14)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			keyPressed = 'LeftClick'
			BindTo.Text = 'LeftClick'
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			keyPressed = 'RightClick'
			BindTo.Text = 'RightClick'
		end
		awaitingInput = false
		keySelected = true
	end
	if not gameProcessed and #binds > 0 then
		for i,v in pairs(binds) do
			if not v.ISKEYUP then
				if (input.UserInputType == Enum.UserInputType.Keyboard and v.KEY:lower()==tostring(input.KeyCode):lower()) or (input.UserInputType == Enum.UserInputType.MouseButton1 and v.KEY:lower()=='leftclick') or (input.UserInputType == Enum.UserInputType.MouseButton2 and v.KEY:lower()=='rightclick') then
					if v.TOGGLE then
						local isOn = toggleOn[v] == true
						toggleOn[v] = not isOn
						if isOn then
							execCmd(v.TOGGLE,Players.LocalPlayer)
						else
							execCmd(v.COMMAND,Players.LocalPlayer)
						end
					else
						execCmd(v.COMMAND,Players.LocalPlayer)
					end
				end
			end
		end
	end
end

function onInputEnded(input,gameProcessed)
	if not gameProcessed and #binds > 0 then
		for i,v in pairs(binds) do
			if v.ISKEYUP then
				if (input.UserInputType == Enum.UserInputType.Keyboard and v.KEY:lower()==tostring(input.KeyCode):lower()) or (input.UserInputType == Enum.UserInputType.MouseButton1 and v.KEY:lower()=='leftclick') or (input.UserInputType == Enum.UserInputType.MouseButton2 and v.KEY:lower()=='rightclick') then
					execCmd(v.COMMAND,Players.LocalPlayer)
				end
			end
		end
	end
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

ClickTP.Select.MouseButton1Click:Connect(function()
	if keySelected then
		addbind('clicktp',keyPressed,bindChosenKeyUp)
		refreshbinds()
		updatesaves()
		if keyPressed == 'RightClick' or keyPressed == 'LeftClick' then
			notify('Keybinds Updated','Binded '..keyPressed..' to click tp')
		else
			notify('Keybinds Updated','Binded '..keyPressed:sub(14)..' to click tp')
		end
	end
end)

ClickDelete.Select.MouseButton1Click:Connect(function()
	if keySelected then
		addbind('clickdel',keyPressed,bindChosenKeyUp)
		refreshbinds()
		updatesaves()
		if keyPressed == 'RightClick' or keyPressed == 'LeftClick' then
			notify('Keybinds Updated','Binded '..keyPressed..' to click delete')
		else
			notify('Keybinds Updated','Binded '..keyPressed:sub(14)..' to click delete')
		end
	end
end)

local function clicktpFunc()
	pcall(function()
		local character = Players.LocalPlayer.Character
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart then
			humanoid.Sit = false
			wait(0.1)
		end

		local hipHeight = humanoid and humanoid.HipHeight > 0 and (humanoid.HipHeight + 1)
		local rootPart = getRoot(character)
		local rootPartPosition = rootPart.Position
		local hitPosition = IYMouse.Hit.Position
		local newCFrame = CFrame.new(
			hitPosition, 
			Vector3.new(rootPartPosition.X, hitPosition.Y, rootPartPosition.Z)
		) * CFrame.Angles(0, math.pi, 0)

		rootPart.CFrame = newCFrame + Vector3.new(0, hipHeight or 4, 0)
		breakVelocity()
	end)
end

IYMouse.Button1Down:Connect(function()
	for i,v in pairs(binds) do
		if v.COMMAND == 'clicktp' then
			local input = v.KEY
			if input == 'RightClick' and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and Players.LocalPlayer.Character then
				clicktpFunc()
			elseif input == 'LeftClick' and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and Players.LocalPlayer.Character then
				clicktpFunc()
			elseif UserInputService:IsKeyDown(Enum.KeyCode[input:sub(14)]) and Players.LocalPlayer.Character then
				clicktpFunc()
			end
		elseif v.COMMAND == 'clickdel' then
			local input = v.KEY
			if input == 'RightClick' and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				pcall(function() IYMouse.Target:Destroy() end)
			elseif input == 'LeftClick' and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				pcall(function() IYMouse.Target:Destroy() end)
			elseif UserInputService:IsKeyDown(Enum.KeyCode[input:sub(14)]) then
				pcall(function() IYMouse.Target:Destroy() end)
			end
		end
	end
end)

PluginsGUI = PluginEditor.background

function addPlugin(name)
	if name:lower() == 'plugin file name' or name:lower() == 'iy_fe.iy' or name == 'iy_fe' then
		notify('Plugin Error','Please enter a valid plugin')
	else
		local file
		local fileName
		if name:sub(-3) == '.iy' then
			pcall(function() file = readfile(name) end)
			fileName = name
		else
			pcall(function() file = readfile(name..'.iy') end)
			fileName = name..'.iy'
		end
		if file then
			if not FindInTable(PluginsTable, fileName) then
				table.insert(PluginsTable, fileName)
				LoadPlugin(fileName)
				refreshplugins()
				pcall(eventEditor.Refresh)
			else
				notify('Plugin Error','This plugin is already added')
			end
		else
			notify('Plugin Error','Cannot locate file "'..fileName..'". Is the file in the correct folder?')
		end
	end
end

function deletePlugin(name)
	local pName = name..'.iy'
	if name:sub(-3) == '.iy' then
		pName = name
	end
	for i = #cmds,1,-1 do
		if cmds[i].PLUGIN == pName then
			table.remove(cmds, i)
		end
	end
	for i,v in pairs(CMDsF:GetChildren()) do
		if v.Name == 'PLUGIN_'..pName then
			v:Destroy()
		end
	end
	for i,v in pairs(PluginsTable) do
		if v == pName then
			table.remove(PluginsTable, i)
			notify('Removed Plugin',pName..' was removed')
		end
	end
	IndexContents('',true)
	refreshplugins()
end

function refreshplugins(dontSave)
	if #PluginsTable > 0 then
		PluginsHint:Destroy()
	end
	if Holder_5 then
		Holder_5:ClearAllChildren()
		Holder_5.CanvasSize = UDim2.new(0, 0, 0, 10)
		for i,v in pairs(PluginsTable) do
			local pName = v
			local YSize = 25
			local Position = ((i * YSize) - YSize)
			local newplugin = Example_5:Clone()
			newplugin.Parent = Holder_5
			newplugin.Visible = true
			newplugin.Position = UDim2.new(0,0,0, Position + 5)
			newplugin.Text.Text = pName
			table.insert(shade2,newplugin)
			table.insert(shade2,newplugin.Text)
			table.insert(text1,newplugin.Text)
			table.insert(shade3,newplugin.Text.Delete)
			table.insert(text2,newplugin.Text.Delete)
			Holder_5.CanvasSize = UDim2.new(0,0,0, Position + 30)
			newplugin.Text.Delete.MouseButton1Click:Connect(function()
				deletePlugin(pName)
			end)
		end
		if not dontSave then
			updatesaves()
		end
	end
end

local PluginCache
function LoadPlugin(val,startup)
	local plugin

	function CatchedPluginLoad()
		plugin = loadfile(val)()
	end

	function handlePluginError(plerror)
		notify('Plugin Error','An error occurred with the plugin, "'..val..'" and it could not be loaded')
		if FindInTable(PluginsTable,val) then
			for i,v in pairs(PluginsTable) do
				if v == val then
					table.remove(PluginsTable,i)
				end
			end
		end
		updatesaves()

		print("Original Error: "..tostring(plerror))
		print("Plugin Error, stack traceback: "..tostring(debug.traceback()))

		plugin = nil

		return false
	end

	xpcall(CatchedPluginLoad, handlePluginError)

	if plugin ~= nil then
		if not startup then
			notify('Loaded Plugin',"Name: "..plugin["PluginName"].."\n".."Description: "..plugin["PluginDescription"])
		end
		addcmdtext('',val)
		addcmdtext(string.upper('--'..plugin["PluginName"]),val,plugin["PluginDescription"])
		if plugin["Commands"] then
			for i,v in pairs(plugin["Commands"]) do 
				local cmdExt = ''
				local cmdName = i
				local function handleNames()
					cmdName = i
					if findCmd(cmdName..cmdExt) then
						if isNumber(cmdExt) then
							cmdExt = cmdExt+1
						else
							cmdExt = 1
						end
						handleNames()
					else
						cmdName = cmdName..cmdExt
					end
				end
				handleNames()
				addcmd(cmdName, v["Aliases"], v["Function"], val)
				if v["ListName"] then
					local newName = v.ListName
					local cmdNames = {i,unpack(v.Aliases)}
					for i,v in pairs(cmdNames) do
						newName = newName:gsub(v,v..cmdExt)
					end
					addcmdtext(newName,val,v["Description"])
				else
					addcmdtext(cmdName,val,v["Description"])
				end
			end
		end
		IndexContents('',true)
	elseif plugin == nil then
		plugin = nil
	end
end

function FindPlugins()
	if PluginsTable ~= nil and type(PluginsTable) == "table" then
		for i,v in pairs(PluginsTable) do
			LoadPlugin(v,true)
		end
		refreshplugins(true)
	end
end

AddPlugin.MouseButton1Click:Connect(function()
	addPlugin(PluginsGUI.FileName.Text)
end)

Exit_3.MouseButton1Click:Connect(function()
	PluginEditor:TweenPosition(UDim2.new(0.5, -180, 0, -500), "InOut", "Quart", 0.5, true, nil)
	FileName.Text = 'Plugin File Name'
end)

Add_3.MouseButton1Click:Connect(function()
	PluginEditor:TweenPosition(UDim2.new(0.5, -180, 0, 310), "InOut", "Quart", 0.5, true, nil)
end)

Plugins.MouseButton1Click:Connect(function()
	if writefileExploit() then
		PluginsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
		wait(0.5)
		SettingsHolder.Visible = false
	else
		notify('Incompatible Exploit','Your exploit is unable to use plugins (missing read/writefile)')
	end
end)

Close_4.MouseButton1Click:Connect(function()
	SettingsHolder.Visible = true
	PluginsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
end)

local TeleportCheck = false
--[[
Players.LocalPlayer.OnTeleport:Connect(function(State)
	if KeepInfYield and (not TeleportCheck) and queueteleport then
		TeleportCheck = true
		queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()")
	end
end)
]]

addcmd('addalias',{},function(args, speaker)
	if #args < 2 then return end
	local cmd = string.lower(args[1])
	local alias = string.lower(args[2])
	for i,v in pairs(cmds) do
		if v.NAME:lower()==cmd or FindInTable(v.ALIAS,cmd) then
			customAlias[alias] = v
			aliases[#aliases + 1] = {CMD = cmd, ALIAS = alias}
			notify('Aliases Modified',"Added "..alias.." as an alias to "..cmd)
			updatesaves()
			refreshaliases()
			break
		end
	end
end)

addcmd('removealias',{},function(args, speaker)
	if #args < 1 then return end
	local alias = string.lower(args[1])
	if customAlias[alias] then
		local cmd = customAlias[alias].NAME
		customAlias[alias] = nil
		for i = #aliases,1,-1 do
			if aliases[i].ALIAS == tostring(alias) then
				table.remove(aliases, i)
			end
		end
		notify('Aliases Modified',"Removed the alias "..alias.." from "..cmd)
		updatesaves()
		refreshaliases()
	end
end)

addcmd('clraliases',{},function(args, speaker)
	customAlias = {}
	aliases = {}
	notify('Aliases Modified','Removed all aliases')
	updatesaves()
	refreshaliases()
end)

addcmd('discord', {'support', 'help'}, function(args, speaker)
	if everyClipboard then
		toClipboard('https://discord.com/invite/78ZuWSq')
		notify('Discord Invite', 'Copied to clipboard!\ndiscord.gg/78ZuWSq')
	else
		notify('Discord Invite', 'discord.gg/78ZuWSq')
	end
	if httprequest then
		httprequest({
			Url = 'http://127.0.0.1:6463/rpc?v=1',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json',
				Origin = 'https://discord.com'
			},
			Body = HttpService:JSONEncode({
				cmd = 'INVITE_BROWSER',
				nonce = HttpService:GenerateGUID(false),
				args = {code = '78ZuWSq'}
			})
		})
	end
end)

addcmd('keepiy', {}, function(args, speaker)
	if queueteleport then
		KeepInfYield = true
		notify('KeepIY','Infinite Yield will now run after you teleport')
		updatesaves()
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing queue_on_teleport)')
	end
end)

addcmd('unkeepiy', {}, function(args, speaker)
	if queueteleport then
		KeepInfYield = false
		notify('KeepIY','Infinite Yield will no longer run after you teleport')
		updatesaves()
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing queue_on_teleport)')
	end
end)

addcmd('togglekeepiy', {}, function(args, speaker)
	if queueteleport then
		KeepInfYield = not KeepInfYield
		updatesaves()
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing queue_on_teleport)')
	end
end)

local canOpenServerinfo = true
addcmd('serverinfo',{'info','sinfo'},function(args, speaker)
	if not canOpenServerinfo then return end
	canOpenServerinfo = false
	task.spawn(function()
		local FRAME = Instance.new("Frame")
		local shadow = Instance.new("Frame")
		local PopupText = Instance.new("TextLabel")
		local Exit = Instance.new("TextButton")
		local ExitImage = Instance.new("ImageLabel")
		local background = Instance.new("Frame")
		local TextLabel = Instance.new("TextLabel")
		local TextLabel2 = Instance.new("TextLabel")
		local TextLabel3 = Instance.new("TextLabel")
		local Time = Instance.new("TextLabel")
		local appearance = Instance.new("TextLabel")
		local maxplayers = Instance.new("TextLabel")
		local name = Instance.new("TextLabel")
		local placeid = Instance.new("TextLabel")
		local playerid = Instance.new("TextLabel")
		local players = Instance.new("TextLabel")
		local CopyApp = Instance.new("TextButton")
		local CopyPlrID = Instance.new("TextButton")
		local CopyPlcID = Instance.new("TextButton")
		local CopyPlcName = Instance.new("TextButton")

		FRAME.Name = randomString()
		FRAME.Parent = ScaledHolder
		FRAME.Active = true
		FRAME.BackgroundTransparency = 1
		FRAME.Position = UDim2.new(0.5, -130, 0, -500)
		FRAME.Size = UDim2.new(0, 250, 0, 20)
		FRAME.ZIndex = 10
		dragGUI(FRAME)

		shadow.Name = "shadow"
		shadow.Parent = FRAME
		shadow.BackgroundColor3 = currentShade2
		shadow.BorderSizePixel = 0
		shadow.Size = UDim2.new(0, 250, 0, 20)
		shadow.ZIndex = 10
		table.insert(shade2,shadow)

		PopupText.Name = "PopupText"
		PopupText.Parent = shadow
		PopupText.BackgroundTransparency = 1
		PopupText.Size = UDim2.new(1, 0, 0.95, 0)
		PopupText.ZIndex = 10
		PopupText.Font = Enum.Font.SourceSans
		PopupText.TextSize = 14
		PopupText.Text = "Server"
		PopupText.TextColor3 = currentText1
		PopupText.TextWrapped = true
		table.insert(text1,PopupText)

		Exit.Name = "Exit"
		Exit.Parent = shadow
		Exit.BackgroundTransparency = 1
		Exit.Position = UDim2.new(1, -20, 0, 0)
		Exit.Size = UDim2.new(0, 20, 0, 20)
		Exit.Text = ""
		Exit.ZIndex = 10

		ExitImage.Parent = Exit
		ExitImage.BackgroundColor3 = Color3.new(1, 1, 1)
		ExitImage.BackgroundTransparency = 1
		ExitImage.Position = UDim2.new(0, 5, 0, 5)
		ExitImage.Size = UDim2.new(0, 10, 0, 10)
		ExitImage.Image = getcustomasset("infiniteyield/assets/close.png")
		ExitImage.ZIndex = 10

		background.Name = "background"
		background.Parent = FRAME
		background.Active = true
		background.BackgroundColor3 = currentShade1
		background.BorderSizePixel = 0
		background.Position = UDim2.new(0, 0, 1, 0)
		background.Size = UDim2.new(0, 250, 0, 250)
		background.ZIndex = 10
		table.insert(shade1,background)

		TextLabel.Name = "Text Label"
		TextLabel.Parent = background
		TextLabel.BackgroundTransparency = 1
		TextLabel.BorderSizePixel = 0
		TextLabel.Position = UDim2.new(0, 5, 0, 80)
		TextLabel.Size = UDim2.new(0, 100, 0, 20)
		TextLabel.ZIndex = 10
		TextLabel.Font = Enum.Font.SourceSansLight
		TextLabel.TextSize = 20
		TextLabel.Text = "Run Time:"
		TextLabel.TextColor3 = currentText1
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,TextLabel)

		TextLabel2.Name = "Text Label2"
		TextLabel2.Parent = background
		TextLabel2.BackgroundTransparency = 1
		TextLabel2.BorderSizePixel = 0
		TextLabel2.Position = UDim2.new(0, 5, 0, 130)
		TextLabel2.Size = UDim2.new(0, 100, 0, 20)
		TextLabel2.ZIndex = 10
		TextLabel2.Font = Enum.Font.SourceSansLight
		TextLabel2.TextSize = 20
		TextLabel2.Text = "Statistics:"
		TextLabel2.TextColor3 = currentText1
		TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,TextLabel2)

		TextLabel3.Name = "Text Label3"
		TextLabel3.Parent = background
		TextLabel3.BackgroundTransparency = 1
		TextLabel3.BorderSizePixel = 0
		TextLabel3.Position = UDim2.new(0, 5, 0, 10)
		TextLabel3.Size = UDim2.new(0, 100, 0, 20)
		TextLabel3.ZIndex = 10
		TextLabel3.Font = Enum.Font.SourceSansLight
		TextLabel3.TextSize = 20
		TextLabel3.Text = "Local Player:"
		TextLabel3.TextColor3 = currentText1
		TextLabel3.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,TextLabel3)

		Time.Name = "Time"
		Time.Parent = background
		Time.BackgroundTransparency = 1
		Time.BorderSizePixel = 0
		Time.Position = UDim2.new(0, 5, 0, 105)
		Time.Size = UDim2.new(0, 100, 0, 20)
		Time.ZIndex = 10
		Time.Font = Enum.Font.SourceSans
		Time.FontSize = Enum.FontSize.Size14
		Time.Text = "LOADING"
		Time.TextColor3 = currentText1
		Time.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,Time)

		appearance.Name = "appearance"
		appearance.Parent = background
		appearance.BackgroundTransparency = 1
		appearance.BorderSizePixel = 0
		appearance.Position = UDim2.new(0, 5, 0, 55)
		appearance.Size = UDim2.new(0, 100, 0, 20)
		appearance.ZIndex = 10
		appearance.Font = Enum.Font.SourceSans
		appearance.FontSize = Enum.FontSize.Size14
		appearance.Text = "Appearance: LOADING"
		appearance.TextColor3 = currentText1
		appearance.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,appearance)

		maxplayers.Name = "maxplayers"
		maxplayers.Parent = background
		maxplayers.BackgroundTransparency = 1
		maxplayers.BorderSizePixel = 0
		maxplayers.Position = UDim2.new(0, 5, 0, 175)
		maxplayers.Size = UDim2.new(0, 100, 0, 20)
		maxplayers.ZIndex = 10
		maxplayers.Font = Enum.Font.SourceSans
		maxplayers.FontSize = Enum.FontSize.Size14
		maxplayers.Text = "LOADING"
		maxplayers.TextColor3 = currentText1
		maxplayers.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,maxplayers)

		name.Name = "name"
		name.Parent = background
		name.BackgroundTransparency = 1
		name.BorderSizePixel = 0
		name.Position = UDim2.new(0, 5, 0, 215)
		name.Size = UDim2.new(0, 240, 0, 30)
		name.ZIndex = 10
		name.Font = Enum.Font.SourceSans
		name.FontSize = Enum.FontSize.Size14
		name.Text = "Place Name: LOADING"
		name.TextColor3 = currentText1
		name.TextWrapped = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextYAlignment = Enum.TextYAlignment.Top
		table.insert(text1,name)

		placeid.Name = "placeid"
		placeid.Parent = background
		placeid.BackgroundTransparency = 1
		placeid.BorderSizePixel = 0
		placeid.Position = UDim2.new(0, 5, 0, 195)
		placeid.Size = UDim2.new(0, 100, 0, 20)
		placeid.ZIndex = 10
		placeid.Font = Enum.Font.SourceSans
		placeid.FontSize = Enum.FontSize.Size14
		placeid.Text = "Place ID: LOADING"
		placeid.TextColor3 = currentText1
		placeid.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,placeid)

		playerid.Name = "playerid"
		playerid.Parent = background
		playerid.BackgroundTransparency = 1
		playerid.BorderSizePixel = 0
		playerid.Position = UDim2.new(0, 5, 0, 35)
		playerid.Size = UDim2.new(0, 100, 0, 20)
		playerid.ZIndex = 10
		playerid.Font = Enum.Font.SourceSans
		playerid.FontSize = Enum.FontSize.Size14
		playerid.Text = "Player ID: LOADING"
		playerid.TextColor3 = currentText1
		playerid.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,playerid)

		players.Name = "players"
		players.Parent = background
		players.BackgroundTransparency = 1
		players.BorderSizePixel = 0
		players.Position = UDim2.new(0, 5, 0, 155)
		players.Size = UDim2.new(0, 100, 0, 20)
		players.ZIndex = 10
		players.Font = Enum.Font.SourceSans
		players.FontSize = Enum.FontSize.Size14
		players.Text = "LOADING"
		players.TextColor3 = currentText1
		players.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,players)

		CopyApp.Name = "CopyApp"
		CopyApp.Parent = background
		CopyApp.BackgroundColor3 = currentShade2
		CopyApp.BorderSizePixel = 0
		CopyApp.Position = UDim2.new(0, 210, 0, 55)
		CopyApp.Size = UDim2.new(0, 35, 0, 20)
		CopyApp.Font = Enum.Font.SourceSans
		CopyApp.TextSize = 14
		CopyApp.Text = "Copy"
		CopyApp.TextColor3 = currentText1
		CopyApp.ZIndex = 10
		table.insert(shade2,CopyApp)
		table.insert(text1,CopyApp)

		CopyPlrID.Name = "CopyPlrID"
		CopyPlrID.Parent = background
		CopyPlrID.BackgroundColor3 = currentShade2
		CopyPlrID.BorderSizePixel = 0
		CopyPlrID.Position = UDim2.new(0, 210, 0, 35)
		CopyPlrID.Size = UDim2.new(0, 35, 0, 20)
		CopyPlrID.Font = Enum.Font.SourceSans
		CopyPlrID.TextSize = 14
		CopyPlrID.Text = "Copy"
		CopyPlrID.TextColor3 = currentText1
		CopyPlrID.ZIndex = 10
		table.insert(shade2,CopyPlrID)
		table.insert(text1,CopyPlrID)

		CopyPlcID.Name = "CopyPlcID"
		CopyPlcID.Parent = background
		CopyPlcID.BackgroundColor3 = currentShade2
		CopyPlcID.BorderSizePixel = 0
		CopyPlcID.Position = UDim2.new(0, 210, 0, 195)
		CopyPlcID.Size = UDim2.new(0, 35, 0, 20)
		CopyPlcID.Font = Enum.Font.SourceSans
		CopyPlcID.TextSize = 14
		CopyPlcID.Text = "Copy"
		CopyPlcID.TextColor3 = currentText1
		CopyPlcID.ZIndex = 10
		table.insert(shade2,CopyPlcID)
		table.insert(text1,CopyPlcID)

		CopyPlcName.Name = "CopyPlcName"
		CopyPlcName.Parent = background
		CopyPlcName.BackgroundColor3 = currentShade2
		CopyPlcName.BorderSizePixel = 0
		CopyPlcName.Position = UDim2.new(0, 210, 0, 215)
		CopyPlcName.Size = UDim2.new(0, 35, 0, 20)
		CopyPlcName.Font = Enum.Font.SourceSans
		CopyPlcName.TextSize = 14
		CopyPlcName.Text = "Copy"
		CopyPlcName.TextColor3 = currentText1
		CopyPlcName.ZIndex = 10
		table.insert(shade2,CopyPlcName)
		table.insert(text1,CopyPlcName)

		local SINFOGUI = background
		FRAME:TweenPosition(UDim2.new(0.5, -130, 0, 100), "InOut", "Quart", 0.5, true, nil) 
		wait(0.5)
		Exit.MouseButton1Click:Connect(function()
			FRAME:TweenPosition(UDim2.new(0.5, -130, 0, -500), "InOut", "Quart", 0.5, true, nil) 
			wait(0.6)
			FRAME:Destroy()
			canOpenServerinfo = true
		end)
		local Asset = MarketplaceService:GetProductInfo(PlaceId)
		SINFOGUI.name.Text = "Place Name: " .. Asset.Name
		SINFOGUI.playerid.Text = "Player ID: " ..speaker.UserId
		SINFOGUI.maxplayers.Text = Players.MaxPlayers.. " Players Max"
		SINFOGUI.placeid.Text = "Place ID: " ..PlaceId

		CopyApp.MouseButton1Click:Connect(function()
			toClipboard(speaker.CharacterAppearanceId)
		end)
		CopyPlrID.MouseButton1Click:Connect(function()
			toClipboard(speaker.UserId)
		end)
		CopyPlcID.MouseButton1Click:Connect(function()
			toClipboard(PlaceId)
		end)
		CopyPlcName.MouseButton1Click:Connect(function()
			toClipboard(Asset.Name)
		end)

		repeat
			players = Players:GetPlayers()
			SINFOGUI.players.Text = #players.. " Player(s)"
			SINFOGUI.appearance.Text = "Appearance: " ..speaker.CharacterAppearanceId
			local seconds = math.floor(workspace.DistributedGameTime)
			local minutes = math.floor(workspace.DistributedGameTime / 60)
			local hours = math.floor(workspace.DistributedGameTime / 60 / 60)
			local seconds = seconds - (minutes * 60)
			local minutes = minutes - (hours * 60)
			if hours < 1 then if minutes < 1 then
					SINFOGUI.Time.Text = seconds .. " Second(s)" else
					SINFOGUI.Time.Text = minutes .. " Minute(s), " .. seconds .. " Second(s)"
				end
			else
				SINFOGUI.Time.Text = hours .. " Hour(s), " .. minutes .. " Minute(s), " .. seconds .. " Second(s)"
			end
			wait(1)
		until SINFOGUI.Parent == nil
	end)
end)

addcmd("jobid", {}, function(args, speaker)
	toClipboard("roblox://placeId=" .. PlaceId .. "&gameInstanceId=" .. JobId)
end)

addcmd('notifyjobid',{},function(args, speaker)
	notify('JobId / PlaceId',JobId..' / '..PlaceId)
end)

addcmd('breakloops',{'break'},function(args, speaker)
	lastBreakTime = tick()
end)

addcmd('gametp',{'gameteleport'},function(args, speaker)
	TeleportService:Teleport(args[1])
end)

addcmd("rejoin", {"rj"}, function(args, speaker)
	if #Players:GetPlayers() <= 1 then
		Players.LocalPlayer:Kick("\nRejoining...")
		wait()
		TeleportService:Teleport(PlaceId, Players.LocalPlayer)
	else
		TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Players.LocalPlayer)
	end
end)

addcmd("autorejoin", {"autorj"}, function(args, speaker)
	GuiService.ErrorMessageChanged:Connect(function()
		execCmd("rejoin")
	end)
	notify("Auto Rejoin", "Auto rejoin enabled")
end)

addcmd("serverhop", {"shop"}, function(args, speaker)
	-- thanks to Amity for fixing
	local servers = {}
	local req = game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
	local body = HttpService:JSONDecode(req)

	if body and body.data then
		for i, v in next, body.data do
			if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= JobId then
				table.insert(servers, 1, v.id)
			end
		end
	end

	if #servers > 0 then
		TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], Players.LocalPlayer)
	else
		return notify("Serverhop", "Couldn't find a server.")
	end
end)

addcmd("exit", {}, function(args, speaker)
	game:Shutdown()
end)

addcmd('noclip',{},function(args, speaker)
	local action = siriusValues.actions[1]
	if not action.enabled then
		action.enabled = true
		action.callback(true)
	end
end)

addcmd('clip',{'unnoclip'},function(args, speaker)
	local action = siriusValues.actions[1]
	if action.enabled then
		action.enabled = false
		action.callback(false)
	end
end)

addcmd('togglenoclip',{},function(args, speaker)
	if Clip then
		execCmd('noclip')
	else
		execCmd('clip')
	end
end)

FLYING = false
QEfly = true
iyflyspeed = 1
vehicleflyspeed = 1
function sFLY(vfly)
	local plr = Players.LocalPlayer
	local char = plr.Character or plr.CharacterAdded:Wait()
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
		humanoid = char:FindFirstChildOfClass("Humanoid")
	end

	if flyKeyDown or flyKeyUp then
		flyKeyDown:Disconnect()
		flyKeyUp:Disconnect()
	end

	local T = getRoot(char)
	local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local SPEED = 0

	local function FLY()
		FLYING = true
		local BG = Instance.new('BodyGyro')
		local BV = Instance.new('BodyVelocity')
		BG.P = 9e4
		BG.Parent = T
		BV.Parent = T
		BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		BG.CFrame = T.CFrame
		BV.Velocity = Vector3.new(0, 0, 0)
		BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		task.spawn(function()
			repeat task.wait()
				local camera = workspace.CurrentCamera
				if not vfly and humanoid then
					humanoid.PlatformStand = true
				end

				if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
					SPEED = 50
				elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
					SPEED = 0
				end
				if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
					BV.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
					lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
				elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
					BV.Velocity = ((camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
				else
					BV.Velocity = Vector3.new(0, 0, 0)
				end
				BG.CFrame = camera.CFrame
			until not FLYING
			CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			SPEED = 0
			BG:Destroy()
			BV:Destroy()

			if humanoid then humanoid.PlatformStand = false end
		end)
	end

	flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.W then
			CONTROL.F = (vfly and vehicleflyspeed or iyflyspeed)
		elseif input.KeyCode == Enum.KeyCode.S then
			CONTROL.B = - (vfly and vehicleflyspeed or iyflyspeed)
		elseif input.KeyCode == Enum.KeyCode.A then
			CONTROL.L = - (vfly and vehicleflyspeed or iyflyspeed)
		elseif input.KeyCode == Enum.KeyCode.D then
			CONTROL.R = (vfly and vehicleflyspeed or iyflyspeed)
		elseif input.KeyCode == Enum.KeyCode.E and QEfly then
			CONTROL.Q = (vfly and vehicleflyspeed or iyflyspeed)*2
		elseif input.KeyCode == Enum.KeyCode.Q and QEfly then
			CONTROL.E = -(vfly and vehicleflyspeed or iyflyspeed)*2
		end
		pcall(function() camera.CameraType = Enum.CameraType.Track end)
	end)

	flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.W then
			CONTROL.F = 0
		elseif input.KeyCode == Enum.KeyCode.S then
			CONTROL.B = 0
		elseif input.KeyCode == Enum.KeyCode.A then
			CONTROL.L = 0
		elseif input.KeyCode == Enum.KeyCode.D then
			CONTROL.R = 0
		elseif input.KeyCode == Enum.KeyCode.E then
			CONTROL.Q = 0
		elseif input.KeyCode == Enum.KeyCode.Q then
			CONTROL.E = 0
		end
	end)
	FLY()
end

function NOFLY()
	FLYING = false
	if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end
	if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
		Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
	end
	pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

local velocityHandlerName = randomString()
local gyroHandlerName = randomString()
local mfly1
local mfly2

local unmobilefly = function(speaker)
	pcall(function()
		FLYING = false
		local root = getRoot(speaker.Character)
		root:FindFirstChild(velocityHandlerName):Destroy()
		root:FindFirstChild(gyroHandlerName):Destroy()
		speaker.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
		mfly1:Disconnect()
		mfly2:Disconnect()
	end)
end

local mobilefly = function(speaker, vfly)
	unmobilefly(speaker)
	FLYING = true

	local root = getRoot(speaker.Character)
	local camera = workspace.CurrentCamera
	local v3none = Vector3.new()
	local v3zero = Vector3.new(0, 0, 0)
	local v3inf = Vector3.new(9e9, 9e9, 9e9)

	local controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
	local bv = Instance.new("BodyVelocity")
	bv.Name = velocityHandlerName
	bv.Parent = root
	bv.MaxForce = v3zero
	bv.Velocity = v3zero

	local bg = Instance.new("BodyGyro")
	bg.Name = gyroHandlerName
	bg.Parent = root
	bg.MaxTorque = v3inf
	bg.P = 1000
	bg.D = 50

	mfly1 = speaker.CharacterAdded:Connect(function()
		local bv = Instance.new("BodyVelocity")
		bv.Name = velocityHandlerName
		bv.Parent = root
		bv.MaxForce = v3zero
		bv.Velocity = v3zero

		local bg = Instance.new("BodyGyro")
		bg.Name = gyroHandlerName
		bg.Parent = root
		bg.MaxTorque = v3inf
		bg.P = 1000
		bg.D = 50
	end)

	mfly2 = RunService.RenderStepped:Connect(function()
		root = getRoot(speaker.Character)
		camera = workspace.CurrentCamera
		if speaker.Character:FindFirstChildWhichIsA("Humanoid") and root and root:FindFirstChild(velocityHandlerName) and root:FindFirstChild(gyroHandlerName) then
			local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
			local VelocityHandler = root:FindFirstChild(velocityHandlerName)
			local GyroHandler = root:FindFirstChild(gyroHandlerName)

			VelocityHandler.MaxForce = v3inf
			GyroHandler.MaxTorque = v3inf
			if not vfly then humanoid.PlatformStand = true end
			GyroHandler.CFrame = camera.CoordinateFrame
			VelocityHandler.Velocity = v3none

			local direction = controlModule:GetMoveVector()
			if direction.X > 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
			if direction.X < 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
			if direction.Z > 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
			if direction.Z < 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
		end
	end)
end

addcmd('fly',{},function(args, speaker)
	if not IsOnMobile then
		NOFLY()
		wait()
		sFLY()
	else
		mobilefly(speaker)
	end
	if args[1] and isNumber(args[1]) then
		iyflyspeed = args[1]
	end
end)

addcmd('flyspeed',{'flysp'},function(args, speaker)
	local speed = args[1] or 1
	if isNumber(speed) then
		iyflyspeed = speed
	end
end)

addcmd('unfly',{'nofly','novfly','unvehiclefly','novehiclefly','unvfly'},function(args, speaker)
	if not IsOnMobile then NOFLY() else unmobilefly(speaker) end
end)

addcmd('vfly',{'vehiclefly'},function(args, speaker)
	if not IsOnMobile then
		NOFLY()
		wait()
		sFLY(true)
	else
		mobilefly(speaker, true)
	end
	if args[1] and isNumber(args[1]) then
		vehicleflyspeed = args[1]
	end
end)

addcmd('togglevfly',{},function(args, speaker)
	if FLYING then
		if not IsOnMobile then NOFLY() else unmobilefly(speaker) end
	else
		if not IsOnMobile then sFLY(true) else mobilefly(speaker, true) end
	end
end)

addcmd('vflyspeed',{'vflysp','vehicleflyspeed','vehicleflysp'},function(args, speaker)
	local speed = args[1] or 1
	if isNumber(speed) then
		vehicleflyspeed = speed
	end
end)

addcmd('qefly',{'flyqe'},function(args, speaker)
	if args[1] == 'false' then
		QEfly = false
	else
		QEfly = true
	end
end)

addcmd('togglefly',{},function(args, speaker)
	if FLYING then
		if not IsOnMobile then NOFLY() else unmobilefly(speaker) end
	else
		if not IsOnMobile then sFLY() else mobilefly(speaker) end
	end
end)

CFspeed = 50
addcmd('cframefly', {'cfly'}, function(args, speaker)
	if args[1] and isNumber(args[1]) then
		CFspeed = args[1]
	end

	-- Full credit to peyton#9148 (apeyton)
	speaker.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
	local Head = speaker.Character:WaitForChild("Head")
	Head.Anchored = true
	if CFloop then CFloop:Disconnect() end
	CFloop = RunService.Heartbeat:Connect(function(deltaTime)
		local moveDirection = speaker.Character:FindFirstChildOfClass('Humanoid').MoveDirection * (CFspeed * deltaTime)
		local headCFrame = Head.CFrame
		local camera = workspace.CurrentCamera
		local cameraCFrame = camera.CFrame
		local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
		cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
		local cameraPosition = cameraCFrame.Position
		local headPosition = headCFrame.Position

		local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
		Head.CFrame = CFrame.new(headPosition) * (cameraCFrame - cameraPosition) * CFrame.new(objectSpaceVelocity)
	end)
end)

addcmd('uncframefly',{'uncfly'},function(args, speaker)
	if CFloop then
		CFloop:Disconnect()
		speaker.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
		local Head = speaker.Character:WaitForChild("Head")
		Head.Anchored = false
	end
end)

addcmd('cframeflyspeed',{'cflyspeed'},function(args, speaker)
	if isNumber(args[1]) then
		CFspeed = args[1]
	end
end)

Floating = false
floatName = randomString()
addcmd('float', {'platform'},function(args, speaker)
	Floating = true
	local pchar = speaker.Character
	if pchar and not pchar:FindFirstChild(floatName) then
		task.spawn(function()
			local Float = Instance.new('Part')
			Float.Name = floatName
			Float.Parent = pchar
			Float.Transparency = 1
			Float.Size = Vector3.new(2,0.2,1.5)
			Float.Anchored = true
			local FloatValue = -3.1
			Float.CFrame = getRoot(pchar).CFrame * CFrame.new(0,FloatValue,0)
			notify('Float','Float Enabled (Q = down & E = up)')
			qUp = IYMouse.KeyUp:Connect(function(KEY)
				if KEY == 'q' then
					FloatValue = FloatValue + 0.5
				end
			end)
			eUp = IYMouse.KeyUp:Connect(function(KEY)
				if KEY == 'e' then
					FloatValue = FloatValue - 1.5
				end
			end)
			qDown = IYMouse.KeyDown:Connect(function(KEY)
				if KEY == 'q' then
					FloatValue = FloatValue - 0.5
				end
			end)
			eDown = IYMouse.KeyDown:Connect(function(KEY)
				if KEY == 'e' then
					FloatValue = FloatValue + 1.5
				end
			end)
			floatDied = speaker.Character:FindFirstChildOfClass('Humanoid').Died:Connect(function()
				FloatingFunc:Disconnect()
				Float:Destroy()
				qUp:Disconnect()
				eUp:Disconnect()
				qDown:Disconnect()
				eDown:Disconnect()
				floatDied:Disconnect()
			end)
			local function FloatPadLoop()
				if pchar:FindFirstChild(floatName) and getRoot(pchar) then
					Float.CFrame = getRoot(pchar).CFrame * CFrame.new(0,FloatValue,0)
				else
					FloatingFunc:Disconnect()
					Float:Destroy()
					qUp:Disconnect()
					eUp:Disconnect()
					qDown:Disconnect()
					eDown:Disconnect()
					floatDied:Disconnect()
				end
			end			
			FloatingFunc = RunService.Heartbeat:Connect(FloatPadLoop)
		end)
	end
end)

addcmd('unfloat',{'nofloat','unplatform','noplatform'},function(args, speaker)
	Floating = false
	local pchar = speaker.Character
	notify('Float','Float Disabled')
	if pchar:FindFirstChild(floatName) then
		pchar:FindFirstChild(floatName):Destroy()
	end
	if floatDied then
		FloatingFunc:Disconnect()
		qUp:Disconnect()
		eUp:Disconnect()
		qDown:Disconnect()
		eDown:Disconnect()
		floatDied:Disconnect()
	end
end)

addcmd('togglefloat',{},function(args, speaker)
	if Floating then
		execCmd('unfloat')
	else
		execCmd('float')
	end
end)

swimming = false
local oldgrav = workspace.Gravity
local swimbeat = nil
addcmd('swim',{},function(args, speaker)
	if not swimming and speaker and speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid") then
		oldgrav = workspace.Gravity
		workspace.Gravity = 0
		local swimDied = function()
			workspace.Gravity = oldgrav
			swimming = false
		end
		local Humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
		gravReset = Humanoid.Died:Connect(swimDied)
		local enums = Enum.HumanoidStateType:GetEnumItems()
		table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
		for i, v in pairs(enums) do
			Humanoid:SetStateEnabled(v, false)
		end
		Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
		swimbeat = RunService.Heartbeat:Connect(function()
			pcall(function()
				getRoot(speaker.Character).Humanoid.RootPart.Velocity = ((Humanoid.MoveDirection ~= Vector3.new() or UserInputService:IsKeyDown(Enum.KeyCode.Space)) and getRoot(speaker.Character).Humanoid.RootPart.Velocity or Vector3.new())
			end)
		end)
		swimming = true
	end
end)

addcmd('unswim',{'noswim'},function(args, speaker)
	if speaker and speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid") then
		workspace.Gravity = oldgrav
		swimming = false
		if gravReset then
			gravReset:Disconnect()
		end
		if swimbeat ~= nil then
			swimbeat:Disconnect()
			swimbeat = nil
		end
		local Humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
		local enums = Enum.HumanoidStateType:GetEnumItems()
		table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
		for i, v in pairs(enums) do
			Humanoid:SetStateEnabled(v, true)
		end
	end
end)

addcmd('toggleswim',{},function(args, speaker)
	if swimming then
		execCmd('unswim')
	else
		execCmd('swim')
	end
end)

addcmd('setwaypoint',{'swp','setwp','spos','saveposition','savepos'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if getRoot(speaker.Character) then
		notify('Modified Waypoints',"Created waypoint: "..getstring(1, args))
		local torso = getRoot(speaker.Character)
		WayPoints[#WayPoints + 1] = {NAME = WPName, COORD = {math.floor(torso.Position.X), math.floor(torso.Position.Y), math.floor(torso.Position.Z)}, GAME = PlaceId}
		if AllWaypoints ~= nil then
			AllWaypoints[#AllWaypoints + 1] = {NAME = WPName, COORD = {math.floor(torso.Position.X), math.floor(torso.Position.Y), math.floor(torso.Position.Z)}, GAME = PlaceId}
		end
	end	
	refreshwaypoints()
	updatesaves()
end)

addcmd('waypointpos',{'wpp','setwaypointposition','setpos','setwaypoint','setwaypointpos'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if getRoot(speaker.Character) then
		notify('Modified Waypoints',"Created waypoint: "..getstring(1, args))
		WayPoints[#WayPoints + 1] = {NAME = WPName, COORD = {args[2], args[3], args[4]}, GAME = PlaceId}
		if AllWaypoints ~= nil then
			AllWaypoints[#AllWaypoints + 1] = {NAME = WPName, COORD = {args[2], args[3], args[4]}, GAME = PlaceId}
		end
	end	
	refreshwaypoints()
	updatesaves()
end)

addcmd('waypoints',{'positions'},function(args, speaker)
	if SettingsOpen == false then SettingsOpen = true
		Settings:TweenPosition(UDim2.new(0, 0, 0, 45), "InOut", "Quart", 0.5, true, nil)
		CMDsF.Visible = false
	end
	KeybindsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
	AliasesFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
	PluginsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
	PositionsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
	wait(0.5)
	SettingsHolder.Visible = false
	maximizeHolder()
end)

waypointParts = {}
addcmd('showwaypoints',{'showwp','showwps'},function(args, speaker)
	execCmd('hidewaypoints')
	wait()
	for i,_ in pairs(WayPoints) do
		local x = WayPoints[i].COORD[1]
		local y = WayPoints[i].COORD[2]
		local z = WayPoints[i].COORD[3]
		local part = Instance.new("Part")
		part.Size = Vector3.new(5,5,5)
		part.CFrame = CFrame.new(x,y,z)
		part.Parent = workspace
		part.Anchored = true
		part.CanCollide = false
		table.insert(waypointParts,part)
		local view = Instance.new("BoxHandleAdornment")
		view.Adornee = part
		view.AlwaysOnTop = true
		view.ZIndex = 10
		view.Size = part.Size
		view.Parent = part
	end
	for i,v in pairs(pWayPoints) do
		local view = Instance.new("BoxHandleAdornment")
		view.Adornee = pWayPoints[i].COORD[1]
		view.AlwaysOnTop = true
		view.ZIndex = 10
		view.Size = pWayPoints[i].COORD[1].Size
		view.Parent = pWayPoints[i].COORD[1]
		table.insert(waypointParts,view)
	end
end)

addcmd('hidewaypoints',{'hidewp','hidewps'},function(args, speaker)
	for i,v in pairs(waypointParts) do
		v:Destroy()
	end
	waypointParts = {}
end)

addcmd('waypoint',{'wp','lpos','loadposition','loadpos'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if speaker.Character then
		for i,_ in pairs(WayPoints) do
			if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
				local x = WayPoints[i].COORD[1]
				local y = WayPoints[i].COORD[2]
				local z = WayPoints[i].COORD[3]
				getRoot(speaker.Character).CFrame = CFrame.new(x,y,z)
			end
		end
		for i,_ in pairs(pWayPoints) do
			if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
				getRoot(speaker.Character).CFrame = CFrame.new(pWayPoints[i].COORD[1].Position)
			end
		end
	end
end)

tweenSpeed = 1
addcmd('tweenspeed',{'tspeed'},function(args, speaker)
	local newSpeed = args[1] or 1
	if tonumber(newSpeed) then
		tweenSpeed = tonumber(newSpeed)
	end
end)

addcmd('tweenwaypoint',{'twp'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if speaker.Character then
		for i,_ in pairs(WayPoints) do
			local x = WayPoints[i].COORD[1]
			local y = WayPoints[i].COORD[2]
			local z = WayPoints[i].COORD[3]
			if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
				TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(x,y,z)}):Play()
			end
		end
		for i,_ in pairs(pWayPoints) do
			if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
				TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pWayPoints[i].COORD[1].Position)}):Play()
			end
		end
	end
end)

addcmd('walktowaypoint',{'wtwp'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if speaker.Character then
		for i,_ in pairs(WayPoints) do
			local x = WayPoints[i].COORD[1]
			local y = WayPoints[i].COORD[2]
			local z = WayPoints[i].COORD[3]
			if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
				if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
					speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
					wait(.1)
				end
				speaker.Character:FindFirstChildOfClass('Humanoid').WalkToPoint = Vector3.new(x,y,z)
			end
		end
		for i,_ in pairs(pWayPoints) do
			if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
				if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
					speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
					wait(.1)
				end
				speaker.Character:FindFirstChildOfClass('Humanoid').WalkToPoint = Vector3.new(pWayPoints[i].COORD[1].Position)
			end
		end
	end
end)

addcmd('deletewaypoint',{'dwp','dpos','deleteposition','deletepos'},function(args, speaker)
	for i,v in pairs(WayPoints) do
		if v.NAME:lower() == tostring(getstring(1, args)):lower() then
			notify('Modified Waypoints',"Deleted waypoint: " .. v.NAME)
			table.remove(WayPoints, i)
		end
	end
	if AllWaypoints ~= nil and #AllWaypoints > 0 then
		for i,v in pairs(AllWaypoints) do
			if v.NAME:lower() == tostring(getstring(1, args)):lower() then
				if not v.GAME or v.GAME == PlaceId then
					table.remove(AllWaypoints, i)
				end
			end
		end
	end
	for i,v in pairs(pWayPoints) do
		if v.NAME:lower() == tostring(getstring(1, args)):lower() then
			notify('Modified Waypoints',"Deleted waypoint: " .. v.NAME)
			table.remove(pWayPoints, i)
		end
	end
	refreshwaypoints()
	updatesaves()
end)

addcmd('clearwaypoints',{'cwp','clearpositions','cpos','clearpos'},function(args, speaker)
	WayPoints = {}
	pWayPoints = {}
	refreshwaypoints()
	updatesaves()
	AllWaypoints = {}
	notify('Modified Waypoints','Removed all waypoints')
end)

addcmd('cleargamewaypoints',{'cgamewp'},function(args, speaker)
	for i,v in pairs(WayPoints) do
		if v.GAME == PlaceId then
			table.remove(WayPoints, i)
		end
	end
	if AllWaypoints ~= nil and #AllWaypoints > 0 then
		for i,v in pairs(AllWaypoints) do
			if v.GAME == PlaceId then
				table.remove(AllWaypoints, i)
			end
		end
	end
	for i,v in pairs(pWayPoints) do
		if v.GAME == PlaceId then
			table.remove(pWayPoints, i)
		end
	end
	refreshwaypoints()
	updatesaves()
	notify('Modified Waypoints','Deleted game waypoints')
end)


local coreGuiTypeNames = {
	-- predefined aliases
	["inventory"] = Enum.CoreGuiType.Backpack,
	["leaderboard"] = Enum.CoreGuiType.PlayerList,
	["emotes"] = Enum.CoreGuiType.EmotesMenu
}

-- Load the full list of enums
for _, enumItem in ipairs(Enum.CoreGuiType:GetEnumItems()) do
	coreGuiTypeNames[enumItem.Name:lower()] = enumItem
end

addcmd('enable',{},function(args, speaker)
	local input = args[1] and args[1]:lower()
	if input then
		if input == "reset" then
			StarterGui:SetCore("ResetButtonCallback", true)
		else
			local coreGuiType = coreGuiTypeNames[input]
			if coreGuiType then
				StarterGui:SetCoreGuiEnabled(coreGuiType, true)
			end
		end
	end
end)

addcmd('disable',{},function(args, speaker)
	local input = args[1] and args[1]:lower()
	if input then
		if input == "reset" then
			StarterGui:SetCore("ResetButtonCallback", false)
		else
			local coreGuiType = coreGuiTypeNames[input]
			if coreGuiType then
				StarterGui:SetCoreGuiEnabled(coreGuiType, false)
			end
		end
	end
end)


local invisGUIS = {}
addcmd('showguis',{},function(args, speaker)
	for i,v in pairs(PlayerGui:GetDescendants()) do
		if (v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("ScrollingFrame")) and not v.Visible then
			v.Visible = true
			if not FindInTable(invisGUIS,v) then
				table.insert(invisGUIS,v)
			end
		end
	end
end)

addcmd('unshowguis',{},function(args, speaker)
	for i,v in pairs(invisGUIS) do
		v.Visible = false
	end
	invisGUIS = {}
end)

local hiddenGUIS = {}
addcmd('hideguis',{},function(args, speaker)
	for i,v in pairs(PlayerGui:GetDescendants()) do
		if (v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("ScrollingFrame")) and v.Visible then
			v.Visible = false
			if not FindInTable(hiddenGUIS,v) then
				table.insert(hiddenGUIS,v)
			end
		end
	end
end)

addcmd('unhideguis',{},function(args, speaker)
	for i,v in pairs(hiddenGUIS) do
		v.Visible = true
	end
	hiddenGUIS = {}
end)

function deleteGuisAtPos()
	pcall(function()
		local guisAtPosition = PlayerGui:GetGuiObjectsAtPosition(IYMouse.X, IYMouse.Y)
		for _, gui in pairs(guisAtPosition) do
			if gui.Visible == true then
				gui:Destroy()
			end
		end
	end)
end

local deleteGuiInput
addcmd('guidelete',{},function(args, speaker)
	deleteGuiInput = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if not gameProcessedEvent then
			if input.KeyCode == Enum.KeyCode.Backspace then
				deleteGuisAtPos()
			end
		end
	end)
	notify('GUI Delete Enabled','Hover over a GUI and press backspace to delete it')
end)

addcmd('unguidelete',{'noguidelete'},function(args, speaker)
	if deleteGuiInput then deleteGuiInput:Disconnect() end
	notify('GUI Delete Disabled','GUI backspace delete has been disabled')
end)

local wasStayOpen = StayOpen
addcmd('hideiy',{},function(args, speaker)
	isHidden = true
	wasStayOpen = StayOpen
	if StayOpen == true then
		StayOpen = false
		On.BackgroundTransparency = 1
	end
	minimizeNum = 0
	minimizeHolder()
	if not (args[1] and tostring(args[1]) == 'nonotify') then notify('IY Hidden','You can press the prefix key to access the command bar') end
end)

addcmd('showiy',{'unhideiy'},function(args, speaker)
	isHidden = false
	minimizeNum = -20
	if wasStayOpen then
		maximizeHolder()
		StayOpen = true
		On.BackgroundTransparency = 0
	else
		minimizeHolder()
	end
end)

addcmd('rec', {'record'}, function(args, speaker)
	return COREGUI:ToggleRecording()
end)

addcmd('screenshot', {'scrnshot'}, function(args, speaker)
	return COREGUI:TakeScreenshot()
end)

addcmd('togglefs', {'togglefullscreen'}, function(args, speaker)
	return GuiService:ToggleFullscreen()
end)

addcmd('inspect', {'examine'}, function(args, speaker)
	for _, v in ipairs(getPlayer(args[1], speaker)) do
		GuiService:CloseInspectMenu()
		GuiService:InspectPlayerFromUserId(Players[v].UserId)
	end
end)

addcmd("savegame", {"saveplace"}, function(args, speaker)
	if saveinstance then
		notify("Loading", "Downloading game. This will take a while")
		saveinstance()
		notify("Game Saved", "Saved place to the workspace folder within your exploit folder.")
	else
		notify("Incompatible Exploit", "Your exploit does not support this command (missing saveinstance)")
	end
end)

addcmd("clearerror", {"clearerrors"}, function(args, speaker)
    GuiService:ClearError()
end)

addcmd("antigameplaypaused", {}, function(args, speaker)
    pcall(function() networkPaused:Disconnect() end)
    networkPaused = COREGUI.RobloxGui.ChildAdded:Connect(function(obj)
        if obj.Name == "CoreScripts/NetworkPause" then
            obj:Destroy()
        end
    end)
    COREGUI.RobloxGui["CoreScripts/NetworkPause"]:Destroy()
end)

addcmd("unantigameplaypaused", {}, function(args, speaker)
    networkPaused:Disconnect()
end)

addcmd('clientantikick',{'antikick'},function(args, speaker)
	if not hookmetamethod then 
		return notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
	end
	local LocalPlayer = Players.LocalPlayer
	local oldhmmi
	local oldhmmnc
	local oldKickFunction
	if hookfunction then
		oldKickFunction = hookfunction(LocalPlayer.Kick, function() end)
	end
	oldhmmi = hookmetamethod(game, "__index", function(self, method)
		if self == LocalPlayer and method:lower() == "kick" then
			return error("Expected ':' not '.' calling member function Kick", 2)
		end
		return oldhmmi(self, method)
	end)
	oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
		if self == LocalPlayer and getnamecallmethod():lower() == "kick" then
			return
		end
		return oldhmmnc(self, ...)
	end)

	notify('Client Antikick','Client anti kick is now active (only effective on localscript kick)')
end)

allow_rj = true
addcmd('clientantiteleport',{'antiteleport'},function(args, speaker)
	if not hookmetamethod then 
		return notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
	end
	local TeleportService = TeleportService
	local oldhmmi
	local oldhmmnc
	oldhmmi = hookmetamethod(game, "__index", function(self, method)
		if self == TeleportService then
			if method:lower() == "teleport" then
				return error("Expected ':' not '.' calling member function Kick", 2)
			elseif method == "TeleportToPlaceInstance" then
				return error("Expected ':' not '.' calling member function TeleportToPlaceInstance", 2)
			end
		end
		return oldhmmi(self, method)
	end)
	oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
		if self == TeleportService and getnamecallmethod():lower() == "teleport" or getnamecallmethod() == "TeleportToPlaceInstance" then
			return
		end
		return oldhmmnc(self, ...)
	end)

	notify('Client AntiTP','Client anti teleport is now active (only effective on localscript teleport)')
end)

addcmd('allowrejoin',{'allowrj'},function(args, speaker)
	if args[1] and args[1] == 'false' then
		allow_rj = false
		notify('Client AntiTP','Allow rejoin set to false')
	else
		allow_rj = true
		notify('Client AntiTP','Allow rejoin set to true')
	end
end)

addcmd("cancelteleport", {"canceltp"}, function(args, speaker)
	TeleportService:TeleportCancel()
end)

addcmd("volume",{ "vol"}, function(args, speaker)
	UserSettings():GetService("UserGameSettings").MasterVolume = args[1]/10
end)

addcmd("antilag", {"boostfps", "lowgraphics"}, function(args, speaker)
	local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 1
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	Lighting.FogStart = 9e9
	settings().Rendering.QualityLevel = 1
	for _, v in pairs(game:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CastShadow = false
			v.Material = "Plastic"
			v.Reflectance = 0
			v.BackSurface = "SmoothNoOutlines"
			v.BottomSurface = "SmoothNoOutlines"
			v.FrontSurface = "SmoothNoOutlines"
			v.LeftSurface = "SmoothNoOutlines"
			v.RightSurface = "SmoothNoOutlines"
			v.TopSurface = "SmoothNoOutlines"
		elseif v:IsA("Decal") then
			v.Transparency = 1
			v.Texture = ""
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
			v.Lifetime = NumberRange.new(0)
		end
	end
	for _, v in pairs(Lighting:GetDescendants()) do
		if v:IsA("PostEffect") then
			v.Enabled = false
		end
	end
	workspace.DescendantAdded:Connect(function(child)
		task.spawn(function()
			if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
				RunService.Heartbeat:Wait()
				child:Destroy()
			elseif child:IsA("BasePart") then
				child.CastShadow = false
			end
		end)
	end)
end)

addcmd("setfpscap", {"fpscap", "maxfps"}, function(args, speaker)
	if fpscaploop then
		task.cancel(fpscaploop)
		fpscaploop = nil
	end

	local fpsCap = 60
	local num = tonumber(args[1]) or 1e6
	if num == "none" then
		return
	elseif num > 0 then
		fpsCap = num
	else
		return notify("Invalid argument", "Please provide a number above 0 or 'none'.")
	end

	if setfpscap and type(setfpscap) == "function" then
		setfpscap(fpsCap)
	else
		fpscaploop = task.spawn(function()
			local timer = os.clock()
			while true do
				if os.clock() >= timer + 1 / fpsCap then
					timer = os.clock()
					task.wait()
				end
			end
		end)
	end
end)

addcmd('notify',{},function(args, speaker)
	notify(getstring(1, args))
end)

addcmd('lastcommand',{'lastcmd'},function(args, speaker)
	if cmdHistory[1]:sub(1,11) ~= 'lastcommand' and cmdHistory[1]:sub(1,7) ~= 'lastcmd' then
		execCmd(cmdHistory[1])
	end
end)

addcmd('esp',{},function(args, speaker)
	local action = siriusValues.actions[7]
	action.enabled = true
	action.callback(true)
	
	-- Sync UI Grid Button Visuals
	local grid = characterPanel.Interactions.Grid
	local btn = grid:FindFirstChild("Extrasensory Perception")
	if btn then
		btn.Icon.Image = "rbxassetid://"..action.images[1]
		tweenService:Create(btn, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.1}):Play()
		tweenService:Create(btn.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
		tweenService:Create(btn.Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {ImageTransparency = 0.1}):Play()
	end
end)

addcmd('espteam',{'selectteams','select teams','team esp','teamesp','esp team'},function(args, speaker)
	-- Find ESP action dynamically
	local espAction = nil
	for _, act in ipairs(siriusValues.actions) do
		if act.name == "Extrasensory Perception" then
			espAction = act
			break
		end
	end

	-- Force enable ESP if off
	if espAction and not espAction.enabled then
		espAction.enabled = true
		espAction.callback(true)
	end

	-- Create/Show Team Selection UI (SIRIUS SOLID VERSION)
	if COREGUI:FindFirstChild("SiriusTeamESP_UI") then
		COREGUI.SiriusTeamESP_UI:Destroy()
	end
	
	getgenv()._siriusESPTeams = getgenv()._siriusESPTeams or {}
	
	local gui = Instance.new("ScreenGui", COREGUI)
	gui.Name = "SiriusTeamESP_UI"
	
	local frame = Instance.new("Frame", gui)
	frame.ClipsDescendants = true
	frame.Size = UDim2.new(0, 360, 0, 420)
	frame.Position = UDim2.new(0.5, -180, 0.5, -210)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 17) -- Solid Dark Sirius
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	
	local uiCorner = Instance.new("UICorner", frame)
	uiCorner.CornerRadius = UDim.new(0, 25)
	
	local uiStroke = Instance.new("UIStroke", frame)
	uiStroke.Color = Color3.fromRGB(60, 60, 65)
	uiStroke.Thickness = 1
	uiStroke.Transparency = 0.2
	
	local shadow = Instance.new("ImageLabel", frame)
	shadow.Size = UDim2.new(1.3, 0, 1.3, 0)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Image = "rbxassetid://6073489140"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.4
	shadow.BackgroundTransparency = 1
	shadow.ZIndex = -1

	local header = Instance.new("Frame", frame)
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundTransparency = 1
	
	local title = Instance.new("TextLabel", header)
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.Text = "SELECT TEAMS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255) -- White font
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1
	
	local list = Instance.new("ScrollingFrame", frame)
	list.Size = UDim2.new(1, -30, 1, -70)
	list.Position = UDim2.new(0, 15, 0, 55)
	list.BackgroundTransparency = 1
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.ScrollBarThickness = 1
	list.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85)
	
	local layout = Instance.new("UIGridLayout", list)
	layout.CellSize = UDim2.new(0, 160, 0, 42)
	layout.CellPadding = UDim2.new(0, 8, 0, 8)
	
	local function updateESP()
		if espAction then espAction.callback(espAction.enabled) end
	end
	
	local function createTeamBtn(name, color)
		local btn = Instance.new("Frame", list)
		btn.Name = name
		local isActive = table.find(getgenv()._siriusESPTeams, name) ~= nil
		btn.BackgroundColor3 = isActive and Color3.fromRGB(0, 124, 89) or Color3.fromRGB(25, 25, 28)
		btn.BorderSizePixel = 0
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = isActive and Color3.fromRGB(0, 134, 96) or Color3.fromRGB(50, 50, 55)
		stroke.Thickness = 1
		
		local label = Instance.new("TextLabel", btn)
		label.Size = UDim2.new(1, -10, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.Text = name
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 11
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		
		local clicker = Instance.new("TextButton", btn)
		clicker.Size = UDim2.new(1, 0, 1, 0)
		clicker.BackgroundTransparency = 1
		clicker.Text = ""

		clicker.MouseButton1Click:Connect(function()
			local idx = table.find(getgenv()._siriusESPTeams, name)
			if idx then
				table.remove(getgenv()._siriusESPTeams, idx)
				btn.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
				stroke.Color = Color3.fromRGB(50, 50, 55)
			else
				table.insert(getgenv()._siriusESPTeams, name)
				btn.BackgroundColor3 = Color3.fromRGB(0, 124, 89)
				stroke.Color = Color3.fromRGB(0, 134, 96)
			end
			updateESP()
		end)
	end
	
	for _, team in ipairs(game:GetService("Teams"):GetChildren()) do
		createTeamBtn(team.Name, team.TeamColor.Color)
	end
	createTeamBtn("No Team", Color3.fromRGB(150, 150, 150))
	
	list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	
	local close = Instance.new("TextButton", header)
	close.Size = UDim2.new(0, 30, 0, 30)
	close.Position = UDim2.new(1, -40, 0.5, -15)
	close.Text = "×"
	close.TextSize = 24
	close.TextColor3 = Color3.fromRGB(150, 150, 155)
	close.BackgroundTransparency = 1
	close.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	-- Minimal entrance
	frame.Position = UDim2.new(0.5, -180, 0.5, -200)
	tweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, -180, 0.5, -210)}):Play()
end)

addcmd('noesp',{'unesp','unespteam'},function(args, speaker)
	local action = siriusValues.actions[7]
	action.enabled = false
	action.callback(false)
	
	-- Sync UI Grid Button Visuals
	local grid = characterPanel.Interactions.Grid
	local btn = grid:FindFirstChild("Extrasensory Perception")
	if btn then
		btn.Icon.Image = "rbxassetid://"..action.images[2]
		tweenService:Create(btn, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.55}):Play()
		tweenService:Create(btn.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
		tweenService:Create(btn.Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
	end
end)

addcmd('team',{},function(args, speaker)
	if args[1] and (args[1]:lower() == "esp" or args[1]:lower() == "team") then
		execCmd("espteam")
	end
end)

addcmd('selfesp',{},function(args, speaker)
	ESP(speaker, false, true)
end)

addcmd('unselfesp',{},function(args, speaker)
	for i,v in pairs(COREGUI:GetChildren()) do
		if v.Name == speaker.Name..'_ESP' then
			v:Destroy()
		end
	end
end)

-- Cleaned up redundant code

addcmd("esptransparency", {}, function(args, speaker)
    espTransparency = tonumber(args[1]) or 0.3
    if ESPenabled then execCmd("esp") end
    if CHMSenabled then execCmd("chams") end
    updatesaves()
end)

local espParts = {}
local partEspTrigger = nil
function partAdded(part)
	if #espParts > 0 then
		if FindInTable(espParts,part.Name:lower()) then
			local a = Instance.new("BoxHandleAdornment")
			a.Name = part.Name:lower().."_PESP"
			a.Parent = part
			a.Adornee = part
			a.AlwaysOnTop = true
			a.ZIndex = 0
			a.Size = part.Size
			a.Transparency = espTransparency
			a.Color = BrickColor.new("Lime green")
		end
	else
		partEspTrigger:Disconnect()
		partEspTrigger = nil
	end
end

addcmd('partesp',{},function(args, speaker)
	local partEspName = getstring(1, args):lower()
	if not FindInTable(espParts,partEspName) then
		table.insert(espParts,partEspName)
		for i,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and v.Name:lower() == partEspName then
				local a = Instance.new("BoxHandleAdornment")
				a.Name = partEspName.."_PESP"
				a.Parent = v
				a.Adornee = v
				a.AlwaysOnTop = true
				a.ZIndex = 0
				a.Size = v.Size
				a.Transparency = espTransparency
				a.Color = BrickColor.new("Lime green")
			end
		end
	end
	if partEspTrigger == nil then
		partEspTrigger = workspace.DescendantAdded:Connect(partAdded)
	end
end)

addcmd('unpartesp',{'nopartesp'},function(args, speaker)
	if args[1] then
		local partEspName = getstring(1, args):lower()
		if FindInTable(espParts,partEspName) then
			table.remove(espParts, GetInTable(espParts, partEspName))
		end
		for i,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BoxHandleAdornment") and v.Name == partEspName..'_PESP' then
				v:Destroy()
			end
		end
	else
		partEspTrigger:Disconnect()
		partEspTrigger = nil
		espParts = {}
		for i,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BoxHandleAdornment") and v.Name:sub(-5) == '_PESP' then
				v:Destroy()
			end
		end
	end
end)

addcmd('chams',{},function(args, speaker)
	if not ESPenabled then
		CHMSenabled = true
		for i,v in pairs(Players:GetPlayers()) do
			if v.Name ~= speaker.Name then
				CHMS(v)
			end
		end
	else
		notify('Chams','Disable ESP (noesp) before using chams')
	end
end)

addcmd('nochams',{'unchams'},function(args, speaker)
	CHMSenabled = false
	for i,v in pairs(Players:GetPlayers()) do
		local chmsplr = v
		for i,c in pairs(COREGUI:GetChildren()) do
			if c.Name == chmsplr.Name..'_CHMS' then
				c:Destroy()
			end
		end
	end
end)

addcmd('locate',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		Locate(Players[v])
	end
end)

addcmd('nolocate',{'unlocate'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	if args[1] then
		for i,v in pairs(players) do
			for i,c in pairs(COREGUI:GetChildren()) do
				if c.Name == Players[v].Name..'_LC' then
					c:Destroy()
				end
			end
		end
	else
		for i,c in pairs(COREGUI:GetChildren()) do
			if string.sub(c.Name, -3) == '_LC' then
				c:Destroy()
			end
		end
	end
end)

viewing = nil
addcmd('view',{'spectate'},function(args, speaker)
	StopFreecam()
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		if viewDied then
			viewDied:Disconnect()
			viewChanged:Disconnect()
		end
		viewing = Players[v]
		workspace.CurrentCamera.CameraSubject = viewing.Character
		notify('Spectate','Viewing ' .. Players[v].Name)
		local function viewDiedFunc()
			repeat wait() until Players[v].Character ~= nil and getRoot(Players[v].Character)
			workspace.CurrentCamera.CameraSubject = viewing.Character
		end
		viewDied = Players[v].CharacterAdded:Connect(viewDiedFunc)
		local function viewChangedFunc()
			workspace.CurrentCamera.CameraSubject = viewing.Character
		end
		viewChanged = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(viewChangedFunc)
	end
end)

addcmd('viewpart',{'viewp'},function(args, speaker)
	StopFreecam()
	if args[1] then
		for i,v in pairs(workspace:GetDescendants()) do
			if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
				wait(0.1)
				workspace.CurrentCamera.CameraSubject = v
			end
		end
	end
end)

addcmd('unview',{'unspectate'},function(args, speaker)
	StopFreecam()
	if viewing ~= nil then
		viewing = nil
		notify('Spectate','View turned off')
	end
	if viewDied then
		viewDied:Disconnect()
		viewChanged:Disconnect()
	end
	workspace.CurrentCamera.CameraSubject = speaker.Character
end)


fcRunning = false
local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCamera = workspace.CurrentCamera
	if newCamera then
		Camera = newCamera
	end
end)

local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value

Spring = {} do
	Spring.__index = Spring

	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end

	function Spring:Update(dt, goal)
		local f = self.f*2*math.pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = math.exp(-f*dt)

		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay

		self.p = p1
		self.v = v1

		return p1
	end

	function Spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end
end

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()

local velSpring = Spring.new(5, Vector3.new())
local panSpring = Spring.new(5, Vector2.new())

Input = {} do

	keyboard = {
		W = 0,
		A = 0,
		S = 0,
		D = 0,
		E = 0,
		Q = 0,
		Up = 0,
		Down = 0,
		LeftShift = 0,
	}

	mouse = {
		Delta = Vector2.new(),
	}

	NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
	PAN_MOUSE_SPEED = Vector2.new(1, 1)*(math.pi/64)
	NAV_ADJ_SPEED = 0.75
	NAV_SHIFT_MUL = 0.25

	navSpeed = 1

	function Input.Vel(dt)
		navSpeed = math.clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)

		local kKeyboard = Vector3.new(
			keyboard.D - keyboard.A,
			keyboard.E - keyboard.Q,
			keyboard.S - keyboard.W
		)*NAV_KEYBOARD_SPEED

		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)

		return (kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
	end

	function Input.Pan(dt)
		local kMouse = mouse.Delta*PAN_MOUSE_SPEED
		mouse.Delta = Vector2.new()
		return kMouse
	end

	do
		function Keypress(action, state, input)
			keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		function MousePan(action, state, input)
			local delta = input.Delta
			mouse.Delta = Vector2.new(-delta.y, -delta.x)
			return Enum.ContextActionResult.Sink
		end

		function Zero(t)
			for k, v in pairs(t) do
				t[k] = v*0
			end
		end

		function Input.StartCapture()
			ContextActionService:BindActionAtPriority("FreecamKeyboard",Keypress,false,INPUT_PRIORITY,
				Enum.KeyCode.W,
				Enum.KeyCode.A,
				Enum.KeyCode.S,
				Enum.KeyCode.D,
				Enum.KeyCode.E,
				Enum.KeyCode.Q,
				Enum.KeyCode.Up,
				Enum.KeyCode.Down
			)
			ContextActionService:BindActionAtPriority("FreecamMousePan",MousePan,false,INPUT_PRIORITY,Enum.UserInputType.MouseMovement)
		end

		function Input.StopCapture()
			navSpeed = 1
			Zero(keyboard)
			Zero(mouse)
			ContextActionService:UnbindAction("FreecamKeyboard")
			ContextActionService:UnbindAction("FreecamMousePan")
		end
	end
end

function GetFocusDistance(cameraFrame)
	local znear = 0.1
	local viewport = Camera.ViewportSize
	local projy = 2*math.tan(cameraFov/2)
	local projx = viewport.x/viewport.y*projy
	local fx = cameraFrame.rightVector
	local fy = cameraFrame.upVector
	local fz = cameraFrame.lookVector

	local minVect = Vector3.new()
	local minDist = 512

	for x = 0, 1, 0.5 do
		for y = 0, 1, 0.5 do
			local cx = (x - 0.5)*projx
			local cy = (y - 0.5)*projy
			local offset = fx*cx - fy*cy + fz
			local origin = cameraFrame.p + offset*znear
			local _, hit = workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
			local dist = (hit - origin).magnitude
			if minDist > dist then
				minDist = dist
				minVect = offset.unit
			end
		end
	end

	return fz:Dot(minVect)*minDist
end

local function StepFreecam(dt)
	local vel = velSpring:Update(dt, Input.Vel(dt))
	local pan = panSpring:Update(dt, Input.Pan(dt))

	local zoomFactor = math.sqrt(math.tan(math.rad(70/2))/math.tan(math.rad(cameraFov/2)))

	cameraRot = cameraRot + pan*Vector2.new(0.75, 1)*8*(dt/zoomFactor)
	cameraRot = Vector2.new(math.clamp(cameraRot.x, -math.rad(90), math.rad(90)), cameraRot.y%(2*math.pi))

	local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*Vector3.new(1, 1, 1)*64*dt)
	cameraPos = cameraCFrame.p

	Camera.CFrame = cameraCFrame
	Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
	Camera.FieldOfView = cameraFov
end

local PlayerState = {} do
	mouseBehavior = ""
	mouseIconEnabled = ""
	cameraType = ""
	cameraFocus = ""
	cameraCFrame = ""
	cameraFieldOfView = ""

	function PlayerState.Push()
		cameraFieldOfView = Camera.FieldOfView
		Camera.FieldOfView = 70

		cameraType = Camera.CameraType
		Camera.CameraType = Enum.CameraType.Custom

		cameraCFrame = Camera.CFrame
		cameraFocus = Camera.Focus

		mouseIconEnabled = UserInputService.MouseIconEnabled
		UserInputService.MouseIconEnabled = true

		mouseBehavior = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	function PlayerState.Pop()
		Camera.FieldOfView = 70

		Camera.CameraType = cameraType
		cameraType = nil

		Camera.CFrame = cameraCFrame
		cameraCFrame = nil

		Camera.Focus = cameraFocus
		cameraFocus = nil

		UserInputService.MouseIconEnabled = mouseIconEnabled
		mouseIconEnabled = nil

		UserInputService.MouseBehavior = mouseBehavior
		mouseBehavior = nil
	end
end

function StartFreecam(pos)
	if fcRunning then
		StopFreecam()
	end
	local cameraCFrame = Camera.CFrame
	if pos then
		cameraCFrame = pos
	end
	cameraRot = Vector2.new()
	cameraPos = cameraCFrame.p
	cameraFov = Camera.FieldOfView

	velSpring:Reset(Vector3.new())
	panSpring:Reset(Vector2.new())

	PlayerState.Push()
	RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
	Input.StartCapture()
	fcRunning = true
end

function StopFreecam()
	if not fcRunning then return end
	Input.StopCapture()
	RunService:UnbindFromRenderStep("Freecam")
	PlayerState.Pop()
	workspace.Camera.FieldOfView = 70
	fcRunning = false
end

addcmd('freecam',{'fc'},function(args, speaker)
	StartFreecam()
end)

addcmd('freecampos',{'fcpos','fcp','freecamposition','fcposition'},function(args, speaker)
	if not args[1] then return end
	local freecamPos = CFrame.new(args[1],args[2],args[3])
	StartFreecam(freecamPos)
end)

addcmd('freecamwaypoint',{'fcwp'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if speaker.Character then
		for i,_ in pairs(WayPoints) do
			local x = WayPoints[i].COORD[1]
			local y = WayPoints[i].COORD[2]
			local z = WayPoints[i].COORD[3]
			if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
				StartFreecam(CFrame.new(x,y,z))
			end
		end
		for i,_ in pairs(pWayPoints) do
			if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
				StartFreecam(CFrame.new(pWayPoints[i].COORD[1].Position))
			end
		end
	end
end)

addcmd('freecamgoto',{'fcgoto','freecamtp','fctp'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		StartFreecam(getRoot(Players[v].Character).CFrame)
	end
end)

addcmd('unfreecam',{'nofreecam','unfc','nofc'},function(args, speaker)
	StopFreecam()
end)

addcmd('freecamspeed',{'fcspeed'},function(args, speaker)
	local FCspeed = args[1] or 1
	if isNumber(FCspeed) then
		NAV_KEYBOARD_SPEED = Vector3.new(FCspeed, FCspeed, FCspeed)
	end
end)

addcmd('notifyfreecamposition',{'notifyfcpos'},function(args, speaker)
	if fcRunning then
		local X,Y,Z = workspace.CurrentCamera.CFrame.Position.X,workspace.CurrentCamera.CFrame.Position.Y,workspace.CurrentCamera.CFrame.Position.Z
		local Format, Round = string.format, math.round
		notify("Current Position", Format("%s, %s, %s", Round(X), Round(Y), Round(Z)))
	end
end)

addcmd('copyfreecamposition',{'copyfcpos'},function(args, speaker)
	if fcRunning then
		local X,Y,Z = workspace.CurrentCamera.CFrame.Position.X,workspace.CurrentCamera.CFrame.Position.Y,workspace.CurrentCamera.CFrame.Position.Z
		local Format, Round = string.format, math.round
		toClipboard(Format("%s, %s, %s", Round(X), Round(Y), Round(Z)))
	end
end)

addcmd('gotocamera',{'gotocam','tocam'},function(args, speaker)
	getRoot(speaker.Character).CFrame = workspace.Camera.CFrame
end)

addcmd('tweengotocamera',{'tweengotocam','tgotocam','ttocam'},function(args, speaker)
	TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = workspace.Camera.CFrame}):Play()
end)

addcmd('fov',{},function(args, speaker)
	local fov = args[1] or 70
	if isNumber(fov) then
		workspace.CurrentCamera.FieldOfView = fov
	end
end)

local preMaxZoom = Players.LocalPlayer.CameraMaxZoomDistance
local preMinZoom = Players.LocalPlayer.CameraMinZoomDistance
addcmd('lookat',{},function(args, speaker)
	if speaker.CameraMaxZoomDistance ~= 0.5 then
		preMaxZoom = speaker.CameraMaxZoomDistance
		preMinZoom = speaker.CameraMinZoomDistance
	end
	speaker.CameraMaxZoomDistance = 0.5
	speaker.CameraMinZoomDistance = 0.5
	wait()
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local target = Players[v].Character
		if target and target:FindFirstChild('Head') then
			workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.p, target.Head.CFrame.p)
			wait(0.1)
		end
	end
	speaker.CameraMaxZoomDistance = preMaxZoom
	speaker.CameraMinZoomDistance = preMinZoom
end)

addcmd('fixcam',{'restorecam'},function(args, speaker)
	StopFreecam()
	execCmd('unview')
	workspace.CurrentCamera:remove()
	wait(.1)
	repeat wait() until speaker.Character ~= nil
	workspace.CurrentCamera.CameraSubject = speaker.Character:FindFirstChildWhichIsA('Humanoid')
	workspace.CurrentCamera.CameraType = "Custom"
	speaker.CameraMinZoomDistance = 0.5
	speaker.CameraMaxZoomDistance = 400
	speaker.CameraMode = "Classic"
	speaker.Character.Head.Anchored = false
end)

addcmd("enableshiftlock", {"enablesl", "shiftlock"}, function(args, speaker)
	local function enableShiftlock() 
		speaker.DevEnableMouseLock = true 
	end
	speaker:GetPropertyChangedSignal("DevEnableMouseLock"):Connect(enableShiftlock)
	enableShiftlock()
	notify("Shiftlock", "Shift lock should now be available")
end)

addcmd('firstp',{},function(args, speaker)
	speaker.CameraMode = "LockFirstPerson"
end)

addcmd('thirdp',{},function(args, speaker)
	speaker.CameraMode = "Classic"
end)

addcmd('noclipcam', {'nccam'}, function(args, speaker)
	local sc = (debug and debug.setconstant) or setconstant
	local gc = (debug and debug.getconstants) or getconstants
	if not sc or not getgc or not gc then
		return notify('Incompatible Exploit', 'Your exploit does not support this command (missing setconstant or getconstants or getgc)')
	end
	local pop = speaker.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
	for _, v in pairs(getgc()) do
		if type(v) == 'function' and getfenv(v).script == pop then
			for i, v1 in pairs(gc(v)) do
				if tonumber(v1) == .25 then
					sc(v, i, 0)
				elseif tonumber(v1) == 0 then
					sc(v, i, .25)
				end
			end
		end
	end
end)

addcmd('maxzoom',{},function(args, speaker)
	speaker.CameraMaxZoomDistance = args[1]
end)

addcmd('minzoom',{},function(args, speaker)
	speaker.CameraMinZoomDistance = args[1]
end)

addcmd('camdistance',{},function(args, speaker)
	local camMax = speaker.CameraMaxZoomDistance
	local camMin = speaker.CameraMinZoomDistance
	if camMax < tonumber(args[1]) then
		camMax = args[1]
	end
	speaker.CameraMaxZoomDistance = args[1]
	speaker.CameraMinZoomDistance = args[1]
	wait()
	speaker.CameraMaxZoomDistance = camMax
	speaker.CameraMinZoomDistance = camMin
end)

addcmd('unlockws',{'unlockworkspace'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Locked = false
		end
	end
end)

addcmd('lockws',{'lockworkspace'},function(args, speaker) 
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Locked = true
		end
	end
end)

addcmd('delete',{'remove'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() then
			v:Destroy()
		end
	end
	notify('Item(s) Deleted','Deleted ' ..getstring(1, args))
end)

addcmd('deleteclass',{'removeclass','deleteclassname','removeclassname','dc'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.ClassName:lower() == getstring(1, args):lower() then
			v:Destroy()
		end
	end
	notify('Item(s) Deleted','Deleted items with ClassName ' ..getstring(1, args))
end)

addcmd('chardelete',{'charremove','cd'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() then
			v:Destroy()
		end
	end
	notify('Item(s) Deleted','Deleted ' ..getstring(1, args))
end)

addcmd('chardeleteclass',{'charremoveclass','chardeleteclassname','charremoveclassname','cdc'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v.ClassName:lower() == getstring(1, args):lower() then
			v:Destroy()
		end
	end
	notify('Item(s) Deleted','Deleted items with ClassName ' ..getstring(1, args))
end)

addcmd('deletevelocity',{'dv','removevelocity','removeforces'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("RocketPropulsion") or v:IsA("BodyThrust") or v:IsA("BodyAngularVelocity") or v:IsA("AngularVelocity") or v:IsA("BodyForce") or v:IsA("VectorForce") or v:IsA("LineForce") then
			v:Destroy()
		end
	end
end)

addcmd('deleteinvisparts',{'deleteinvisibleparts','dip'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Transparency == 1 and v.CanCollide then
			v:Destroy()
		end
	end
end)

local shownParts = {}
addcmd('invisibleparts',{'invisparts'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Transparency == 1 then
			if not table.find(shownParts,v) then
				table.insert(shownParts,v)
			end
			v.Transparency = 0
		end
	end
end)

addcmd('uninvisibleparts',{'uninvisparts'},function(args, speaker)
	for i,v in pairs(shownParts) do
		v.Transparency = 1
	end
	shownParts = {}
end)

addcmd("btools", {}, function(args, speaker)
	for i = 1, 4 do
		local Tool = Instance.new("HopperBin")
		Tool.BinType = i
		Tool.Name = randomString()
		Tool.Parent = speaker:FindFirstChildWhichIsA("Backpack")
	end
end)

addcmd("f3x", {"fex"}, function(args, speaker)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/f3x.lua"))()
end)

addcmd("partpath", {"partname"}, function(args, speaker)
	selectPart()
end)

addcmd("antiafk", {"antiidle"}, function(args, speaker)
	if getconnections then
		for _, connection in pairs(getconnections(speaker.Idled)) do
			if connection["Disable"] then
				connection["Disable"](connection)
			elseif connection["Disconnect"] then
				connection["Disconnect"](connection)
			end
		end
	else
		speaker.Idled:Connect(function()
			Services.VirtualUser:CaptureController()
			Services.VirtualUser:ClickButton2(Vector2.new())
		end)
	end
	if not (args[1] and tostring(args[1]) == "nonotify") then notify("Anti Idle", "Anti idle is enabled") end
end)

addcmd("datalimit", {}, function(args, speaker)
	local kbps = tonumber(args[1])
	if kbps then
		Services.NetworkClient:SetOutgoingKBPSLimit(kbps)
	end
end)

addcmd("replicationlag", {"backtrack"}, function(args, speaker)
	if tonumber(args[1]) then
		settings():GetService("NetworkSettings").IncomingReplicationLag = args[1]
	end
end)

addcmd("noprompts", {"nopurchaseprompts"}, function(args, speaker)
	COREGUI.PurchasePromptApp.Enabled = false
end)

addcmd("showprompts", {"showpurchaseprompts"}, function(args, speaker)
	COREGUI.PurchasePromptApp.Enabled = true
end)

promptNewRig = function(speaker, rig)
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		AvatarEditorService:PromptSaveAvatar(humanoid.HumanoidDescription, Enum.HumanoidRigType[rig])
		local result = AvatarEditorService.PromptSaveAvatarCompleted:Wait()
		if result == Enum.AvatarPromptResult.Success then
			execCmd("reset")
		end
	end
end

addcmd("promptr6", {}, function(args, speaker)
	promptNewRig(speaker, "R6")
end)

addcmd("promptr15", {}, function(args, speaker)
	promptNewRig(speaker, "R15")
end)

addcmd("wallwalk", {"walkonwalls"}, function(args, speaker)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/wallwalker.lua"))()
end)

addcmd('age',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local ages = {}
	for i,v in pairs(players) do
		local p = Players[v]
		table.insert(ages, p.Name.."'s age is: "..p.AccountAge)
	end
	notify('Account Age',table.concat(ages, ',\n'))
end)

addcmd('chatage',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local ages = {}
	for i,v in pairs(players) do
		local p = Players[v]
		table.insert(ages, p.Name.."'s age is: "..p.AccountAge)
	end
	local chatString = table.concat(ages, ', ')
	chatMessage(chatString)
end)

addcmd('joindate',{'jd'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local dates = {}
	for i,v in pairs(players) do
		local p = Players[v]

		local secondsOld = p.AccountAge * 24 * 60 * 60
		local now = os.time()
		local dateJoined  = p.Name .. " joined: " .. os.date("%m/%d/%y", now - secondsOld)

		table.insert(dates, dateJoined)
	end
	notify('Join Date (Month/Day/Year)',table.concat(dates, ',\n'))
end)

addcmd('chatjoindate',{'cjd'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local dates = {}
	for i,v in pairs(players) do
		local p = Players[v]

		local secondsOld = p.AccountAge * 24 * 60 * 60
		local now = os.time()
		local dateJoined  = p.Name .. " joined: " .. os.date("%m/%d/%y", now - secondsOld)

		table.insert(dates, dateJoined)
	end
	local chatString = table.concat(dates, ', ')
	chatMessage(chatString)
end)

addcmd('copyname',{'copyuser'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local name = tostring(Players[v].Name)
		toClipboard(name)
	end
end)

addcmd('userid',{'id'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local id = tostring(Players[v].UserId)
		notify('User ID',id)
	end
end)

addcmd("copyplaceid", {"placeid"}, function(args, speaker)
	toClipboard(PlaceId)
end)

addcmd("copygameid", {"gameid"}, function(args, speaker)
	toClipboard(game.GameId)
end)

addcmd('copyid',{'copyuserid'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local id = tostring(Players[v].UserId)
		toClipboard(id)
	end
end)

addcmd('creatorid',{'creator'},function(args, speaker)
	if game.CreatorType == Enum.CreatorType.User then
		notify('Creator ID',game.CreatorId)
	elseif game.CreatorType == Enum.CreatorType.Group then
		local OwnerID = GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
		speaker.UserId = OwnerID
		notify('Creator ID',OwnerID)
	end
end)

addcmd('copycreatorid',{'copycreator'},function(args, speaker)
	if game.CreatorType == Enum.CreatorType.User then
		toClipboard(game.CreatorId)
		notify('Copied ID','Copied creator ID to clipboard')
	elseif game.CreatorType == Enum.CreatorType.Group then
		local OwnerID = GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
		toClipboard(OwnerID)
		notify('Copied ID','Copied creator ID to clipboard')
	end
end)

addcmd('setcreatorid',{'setcreator'},function(args, speaker)
	if game.CreatorType == Enum.CreatorType.User then
		speaker.UserId = game.CreatorId
		notify('Set ID','Set UserId to '..game.CreatorId)
	elseif game.CreatorType == Enum.CreatorType.Group then
		local OwnerID = GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
		speaker.UserId = OwnerID
		notify('Set ID','Set UserId to '..OwnerID)
	end
end)

addcmd('appearanceid',{'aid'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local aid = tostring(Players[v].CharacterAppearanceId)
		notify('Appearance ID',aid)
	end
end)

addcmd('copyappearanceid',{'caid'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local aid = tostring(Players[v].CharacterAppearanceId)
		toClipboard(aid)
	end
end)

addcmd('norender',{},function(args, speaker)
	RunService:Set3dRenderingEnabled(false)
end)

addcmd('render',{},function(args, speaker)
	RunService:Set3dRenderingEnabled(true)
end)

addcmd('2022materials',{'use2022materials'},function(args, speaker)
	if sethidden then
		sethidden(MaterialService, "Use2022Materials", true)
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing sethiddenproperty)')
	end
end)

addcmd('un2022materials',{'unuse2022materials'},function(args, speaker)
	if sethidden then
		sethidden(MaterialService, "Use2022Materials", false)
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing sethiddenproperty)')
	end
end)

addcmd("goto", {"to"}, function(args, speaker)
    local character = speaker and speaker.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local players = getPlayer(args[1], speaker)
    for _, v in pairs(players) do
        if Players[v].Character ~= nil then
            if humanoid and humanoid.SeatPart then
                humanoid.Sit = false
                task.wait(0.1)
            end
            getRoot(speaker.Character).CFrame = getRoot(Players[v].Character):GetPivot() + Vector3.new(3, 1, 0)
        end
    end
    execCmd("breakvelocity")
end)

addcmd("tweengoto", {"tgoto", "tto", "tweento"}, function(args, speaker)
    local character = speaker and speaker.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

    local oldState = humanoid and humanoid:GetStateEnabled(Enum.HumanoidStateType.Seated)
    if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end

    local players = getPlayer(args[1], speaker)
    for _, v in pairs(players) do
        if Players[v].Character ~= nil then
            if humanoid and humanoid.SeatPart then
                humanoid.Sit = false
                task.wait(0.1)
            end
            TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {
                CFrame = getRoot(Players[v].Character):GetPivot() + Vector3.new(3, 1, 0)
            }):Play()
        end
    end
    execCmd("breakvelocity")

    if type(oldState) == "boolean" then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, oldState)
    end
end)

addcmd('vehiclegoto',{'vgoto','vtp','vehicletp'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			local seat = speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart
			local vehicleModel = seat:FindFirstAncestorWhichIsA("Model")
			vehicleModel:MoveTo(getRoot(Players[v].Character).Position)
		end
	end
end)

addcmd('pulsetp',{'ptp'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			local startPos = getRoot(speaker.Character).CFrame
			local seconds = args[2] or 1
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			getRoot(speaker.Character).CFrame = getRoot(Players[v].Character).CFrame + Vector3.new(3,1,0)
			wait(seconds)
			getRoot(speaker.Character).CFrame = startPos
		end
	end
	execCmd('breakvelocity')
end)

local vnoclipParts = {}
addcmd('vehiclenoclip',{'vnoclip'},function(args, speaker)
	vnoclipParts = {}
	local seat = speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart
	local vehicleModel = seat.Parent
	repeat
		if vehicleModel.ClassName ~= "Model" then
			vehicleModel = vehicleModel.Parent
		end
	until vehicleModel.ClassName == "Model"
	wait(0.1)
	execCmd('noclip')
	for i,v in pairs(vehicleModel:GetDescendants()) do
		if v:IsA("BasePart") and v.CanCollide then
			table.insert(vnoclipParts,v)
			v.CanCollide = false
		end
	end
end)

addcmd("vehicleclip", {"vclip", "unvnoclip", "unvehiclenoclip"}, function(args, speaker)
	execCmd("clip")
	for i, v in pairs(vnoclipParts) do
		v.CanCollide = true
	end
	vnoclipParts = {}
end)

addcmd("togglevnoclip", {}, function(args, speaker)
	execCmd(Clip and "vnoclip" or "vclip")
end)

addcmd('clientbring',{'cbring'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			if Players[v].Character:FindFirstChildOfClass('Humanoid') then
				Players[v].Character:FindFirstChildOfClass('Humanoid').Sit = false
			end
			wait()
			getRoot(Players[v].Character).CFrame = getRoot(speaker.Character).CFrame + Vector3.new(3,1,0)
		end
	end
end)

local bringT = {}
addcmd('loopbring',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			if Players[v].Name ~= speaker.Name and not FindInTable(bringT, Players[v].Name) then
				table.insert(bringT, Players[v].Name)
				local plrName = Players[v].Name
				local pchar=Players[v].Character
				local distance = 3
				if args[2] and isNumber(args[2]) then
					distance = args[2]
				end
				local lDelay = 0
				if args[3] and isNumber(args[3]) then
					lDelay = args[3]
				end
				repeat
					for i,c in pairs(players) do
						if Players:FindFirstChild(v) then
							pchar = Players[v].Character
							if pchar~= nil and Players[v].Character ~= nil and getRoot(pchar) and speaker.Character ~= nil and getRoot(speaker.Character) then
								getRoot(pchar).CFrame = getRoot(speaker.Character).CFrame + Vector3.new(distance,1,0)
							end
							wait(lDelay)
						else 
							for a,b in pairs(bringT) do if b == plrName then table.remove(bringT, a) end end
						end
					end
				until not FindInTable(bringT, plrName)
			end
		end)
	end
end)

addcmd('unloopbring',{'noloopbring'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			for a,b in pairs(bringT) do if b == Players[v].Name then table.remove(bringT, a) end end
		end)
	end
end)

local walkto = false
local waypointwalkto = false
addcmd('walkto',{'follow'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			walkto = true
			repeat wait()
				speaker.Character:FindFirstChildOfClass('Humanoid'):MoveTo(getRoot(Players[v].Character).Position)
			until Players[v].Character == nil or not getRoot(Players[v].Character) or walkto == false
		end
	end
end)

addcmd('pathfindwalkto',{'pathfindfollow'},function(args, speaker)
	walkto = false
	wait()
	local players = getPlayer(args[1], speaker)
	local hum = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	local path = PathService:CreatePath()
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			walkto = true
			repeat wait()
				local success, response = pcall(function()
					path:ComputeAsync(getRoot(speaker.Character).Position, getRoot(Players[v].Character).Position)
					local waypoints = path:GetWaypoints()
					local distance 
					for waypointIndex, waypoint in pairs(waypoints) do
						local waypointPosition = waypoint.Position
						hum:MoveTo(waypointPosition)
						repeat 
							distance = (waypointPosition - hum.Parent.PrimaryPart.Position).magnitude
							wait()
						until
						distance <= 5
					end	 
				end)
				if not success then
					speaker.Character:FindFirstChildOfClass('Humanoid'):MoveTo(getRoot(Players[v].Character).Position)
				end
			until Players[v].Character == nil or not getRoot(Players[v].Character) or walkto == false
		end
	end
end)

addcmd('pathfindwalktowaypoint',{'pathfindwalktowp'},function(args, speaker)
	waypointwalkto = false
	wait()
	local WPName = tostring(getstring(1, args))
	local hum = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	local path = PathService:CreatePath()
	if speaker.Character then
		for i,_ in pairs(WayPoints) do
			if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
				if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
					speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
					wait(.1)
				end
				local TrueCoords = Vector3.new(WayPoints[i].COORD[1], WayPoints[i].COORD[2], WayPoints[i].COORD[3])
				waypointwalkto = true
				repeat wait()
					local success, response = pcall(function()
						path:ComputeAsync(getRoot(speaker.Character).Position, TrueCoords)
						local waypoints = path:GetWaypoints()
						local distance 
						for waypointIndex, waypoint in pairs(waypoints) do
							local waypointPosition = waypoint.Position
							hum:MoveTo(waypointPosition)
							repeat 
								distance = (waypointPosition - hum.Parent.PrimaryPart.Position).magnitude
								wait()
							until
							distance <= 5
						end
					end)
					if not success then
						speaker.Character:FindFirstChildOfClass('Humanoid'):MoveTo(TrueCoords)
					end
				until not speaker.Character or waypointwalkto == false
			end
		end
		for i,_ in pairs(pWayPoints) do
			if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
				if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
					speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
					wait(.1)
				end
				local TrueCoords = pWayPoints[i].COORD[1].Position
				waypointwalkto = true
				repeat wait()
					local success, response = pcall(function()
						path:ComputeAsync(getRoot(speaker.Character).Position, TrueCoords)
						local waypoints = path:GetWaypoints()
						local distance 
						for waypointIndex, waypoint in pairs(waypoints) do
							local waypointPosition = waypoint.Position
							hum:MoveTo(waypointPosition)
							repeat 
								distance = (waypointPosition - hum.Parent.PrimaryPart.Position).magnitude
								wait()
							until
							distance <= 5
						end
					end)
					if not success then
						speaker.Character:FindFirstChildOfClass('Humanoid'):MoveTo(TrueCoords)
					end
				until not speaker.Character or waypointwalkto == false
			end
		end
	end
end)

addcmd('unwalkto',{'nowalkto','unfollow','nofollow'},function(args, speaker)
	walkto = false
	waypointwalkto = false
end)

addcmd("orbit", {}, function(args, speaker)
	execCmd("unorbit nonotify")
	local target = Players:FindFirstChild(getPlayer(args[1], speaker)[1])
	local root = getRoot(speaker.Character)
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	if target and target.Character and getRoot(target.Character) and root and humanoid then
		local rotation = 0
		local speed = tonumber(args[2]) or 0.2
		local distance = tonumber(args[3]) or 6
		orbit1 = RunService.Heartbeat:Connect(function()
			pcall(function()
				rotation = rotation + speed
				root.CFrame = CFrame.new(getRoot(target.Character).Position) * CFrame.Angles(0, math.rad(rotation), 0) * CFrame.new(distance, 0, 0)
			end)
		end)
		orbit2 = RunService.RenderStepped:Connect(function()
			pcall(function()
				root.CFrame = CFrame.new(root.Position, getRoot(target.Character).Position)
			end)
		end)
		orbit3 = humanoid.Died:Connect(function() execCmd("unorbit") end)
		orbit4 = humanoid.Seated:Connect(function(value) if value then execCmd("unorbit") end end)
		notify("Orbit", "Started orbiting " .. formatUsername(target))
	end
end)

addcmd("unorbit", {}, function(args, speaker)
	if orbit1 then orbit1:Disconnect() end
	if orbit2 then orbit2:Disconnect() end
	if orbit3 then orbit3:Disconnect() end
	if orbit4 then orbit4:Disconnect() end
	if args[1] ~= "nonotify" then notify("Orbit", "Stopped orbiting player") end
end)

addcmd('freeze',{'fr'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	if players ~= nil then
		for i,v in pairs(players) do
			task.spawn(function()
				for i, x in next, Players[v].Character:GetDescendants() do
					if x:IsA("BasePart") and not x.Anchored then
						x.Anchored = true
					end
				end
			end)
		end
	end
end)


addcmd('thaw',{'unfreeze','unfr'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	if players ~= nil then
		for i,v in pairs(players) do
			task.spawn(function()
				for i, x in next, Players[v].Character:GetDescendants() do
					if x.Name ~= floatName and x:IsA("BasePart") and x.Anchored then
						x.Anchored = false
					end
				end
			end)
		end
	end
end)

addcmd("anchor", {}, function(args, speaker)
    getRoot(speaker.Character).Anchored = true
end)

addcmd("unanchor", {}, function(args, speaker)
    getRoot(speaker.Character).Anchored = false
end)

oofing = false
addcmd('loopoof',{},function(args, speaker)
	oofing = true
	repeat wait(0.1)
		for i,v in pairs(Players:GetPlayers()) do
			if v.Character ~= nil and v.Character:FindFirstChild'Head' then
				for _,x in pairs(v.Character.Head:GetChildren()) do
					if x:IsA'Sound' then x.Playing = true end
				end
			end
		end
	until oofing == false
end)

addcmd('unloopoof',{},function(args, speaker)
	oofing = false
end)

local notifiedRespectFiltering = false
addcmd('muteboombox',{},function(args, speaker)
	if not notifiedRespectFiltering and SoundService.RespectFilteringEnabled then notifiedRespectFiltering = true notify('RespectFilteringEnabled','RespectFilteringEnabled is set to true (the command will still work but may only be clientsided)') end
	local players = getPlayer(args[1], speaker)
	if players ~= nil then
		for i,v in pairs(players) do
			task.spawn(function()
				for i, x in next, Players[v].Character:GetDescendants() do
					if x:IsA("Sound") and x.Playing == true then
						x.Playing = false
					end
				end
				for i, x in next, Players[v]:FindFirstChildOfClass("Backpack"):GetDescendants() do
					if x:IsA("Sound") and x.Playing == true then
						x.Playing = false
					end
				end
			end)
		end
	end
end)

addcmd('unmuteboombox',{},function(args, speaker)
	if not notifiedRespectFiltering and SoundService.RespectFilteringEnabled then notifiedRespectFiltering = true notify('RespectFilteringEnabled','RespectFilteringEnabled is set to true (the command will still work but may only be clientsided)') end
	local players = getPlayer(args[1], speaker)
	if players ~= nil then
		for i,v in pairs(players) do
			task.spawn(function()
				for i, x in next, Players[v].Character:GetDescendants() do
					if x:IsA("Sound") and x.Playing == false then
						x.Playing = true
					end
				end
			end)
		end
	end
end)

addcmd("reset", {}, function(args, speaker)
	local humanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Dead)
	else
		speaker.Character:BreakJoints()
	end
end)

addcmd('freezeanims',{},function(args, speaker)
	local Humanoid = speaker.Character:FindFirstChildOfClass("Humanoid") or speaker.Character:FindFirstChildOfClass("AnimationController")
	local ActiveTracks = Humanoid:GetPlayingAnimationTracks()
	for _, v in pairs(ActiveTracks) do
		v:AdjustSpeed(0)
	end
end)

addcmd('unfreezeanims',{},function(args, speaker)
	local Humanoid = speaker.Character:FindFirstChildOfClass("Humanoid") or speaker.Character:FindFirstChildOfClass("AnimationController")
	local ActiveTracks = Humanoid:GetPlayingAnimationTracks()
	for _, v in pairs(ActiveTracks) do
		v:AdjustSpeed(1)
	end
end)

addcmd("respawn", {}, function(args, speaker)
	siriusValues.actions[4].callback()
end)

addcmd("refresh", {"re"}, function(args, speaker)
	siriusValues.actions[3].callback()
end)

addcmd("god", {}, function(args, speaker)
	local action = siriusValues.actions[5]
	action.enabled = not action.enabled
	action.callback(action.enabled)
	notify("God Mode", "Sirius God Mode " .. (action.enabled and "Enabled" or "Disabled"))
end)

invisRunning = false
addcmd('invisible',{'invis'},function(args, speaker)
	if invisRunning then return end
	invisRunning = true
	-- Full credit to AmokahFox @V3rmillion
	local Player = speaker
	repeat wait(.1) until Player.Character
	local Character = Player.Character
	Character.Archivable = true
	local IsInvis = false
	local IsRunning = true
	local InvisibleCharacter = Character:Clone()
	InvisibleCharacter.Parent = Lighting
	local Void = workspace.FallenPartsDestroyHeight
	InvisibleCharacter.Name = ""
	local CF

	local invisFix = RunService.Stepped:Connect(function()
		pcall(function()
			local IsInteger
			if tostring(Void):find'-' then
				IsInteger = true
			else
				IsInteger = false
			end
			local Pos = Player.Character.Humanoid.RootPart.Position
			local Pos_String = tostring(Pos)
			local Pos_Seperate = Pos_String:split(', ')
			local X = tonumber(Pos_Seperate[1])
			local Y = tonumber(Pos_Seperate[2])
			local Z = tonumber(Pos_Seperate[3])
			if IsInteger == true then
				if Y <= Void then
					Respawn()
				end
			elseif IsInteger == false then
				if Y >= Void then
					Respawn()
				end
			end
		end)
	end)

	for i,v in pairs(InvisibleCharacter:GetDescendants())do
		if v:IsA("BasePart") then
			if v.Name == "HumanoidRootPart" then
				v.Transparency = 1
			else
				v.Transparency = .5
			end
		end
	end

	function Respawn()
		IsRunning = false
		if IsInvis == true then
			pcall(function()
				Player.Character = Character
				wait()
				Character.Parent = workspace
				Character:FindFirstChildWhichIsA'Humanoid':Destroy()
				IsInvis = false
				InvisibleCharacter.Parent = nil
				invisRunning = false
			end)
		elseif IsInvis == false then
			pcall(function()
				Player.Character = Character
				wait()
				Character.Parent = workspace
				Character:FindFirstChildWhichIsA'Humanoid':Destroy()
				TurnVisible()
			end)
		end
	end

	local invisDied
	invisDied = InvisibleCharacter:FindFirstChildOfClass'Humanoid'.Died:Connect(function()
		Respawn()
		invisDied:Disconnect()
	end)

	if IsInvis == true then return end
	IsInvis = true
	CF = workspace.CurrentCamera.CFrame
	local CF_1 = Player.Character.Humanoid.RootPart.CFrame
	Character:MoveTo(Vector3.new(0,math.pi*1000000,0))
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	wait(.2)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	InvisibleCharacter = InvisibleCharacter
	Character.Parent = Lighting
	InvisibleCharacter.Parent = workspace
	InvisibleCharacter.Humanoid.RootPart.CFrame = CF_1
	Player.Character = InvisibleCharacter
	execCmd('fixcam')
	Player.Character.Animate.Disabled = true
	Player.Character.Animate.Disabled = false

	function TurnVisible()
		if IsInvis == false then return end
		invisFix:Disconnect()
		invisDied:Disconnect()
		CF = workspace.CurrentCamera.CFrame
		Character = Character
		local CF_1 = Player.Character.Humanoid.RootPart.CFrame
		Character.Humanoid.RootPart.CFrame = CF_1
		InvisibleCharacter:Destroy()
		Player.Character = Character
		Character.Parent = workspace
		IsInvis = false
		Player.Character.Animate.Disabled = true
		Player.Character.Animate.Disabled = false
		invisDied = Character:FindFirstChildOfClass'Humanoid'.Died:Connect(function()
			Respawn()
			invisDied:Disconnect()
		end)
		invisRunning = false
	end
	notify('Invisible','You now appear invisible to other players')
end)

addcmd("visible", {"vis","uninvisible"}, function(args, speaker)
	TurnVisible()
end)

addcmd("toggleinvis", {}, function(args, speaker)
	execCmd(invisRunning and "visible" or "invisible")
end)

addcmd('toolinvisible',{'toolinvis','tinvis'},function(args, speaker)
	local Char  = Players.LocalPlayer.Character
	local touched = false
	local tpdback = false
	local box = Instance.new('Part')
	box.Anchored = true
	box.CanCollide = true
	box.Size = Vector3.new(10,1,10)
	box.Position = Vector3.new(0,10000,0)
	box.Parent = workspace
	local boxTouched = box.Touched:connect(function(part)
		if (part.Parent.Name == Players.LocalPlayer.Name) then
			if touched == false then
				touched = true
				local function apply()
					local no = Char.Humanoid.RootPart:Clone()
					task.wait(.25)
					Char.Humanoid.RootPart:Destroy()
					no.Parent = Char
					Char:MoveTo(loc)
					touched = false
				end
				if Char then
					apply()
				end
			end
		end
	end)
	repeat wait() until Char
	local cleanUp
	cleanUp = Players.LocalPlayer.CharacterAdded:connect(function(char)
		boxTouched:Disconnect()
		box:Destroy()
		cleanUp:Disconnect()
	end)
	loc = Char.Humanoid.RootPart.Position
	Char:MoveTo(box.Position + Vector3.new(0,.5,0))
end)

addcmd("strengthen", {}, function(args, speaker)
	for _, child in pairs(speaker.Character:GetDescendants()) do
		if child.ClassName == "Part" then
			if args[1] then
				child.CustomPhysicalProperties = PhysicalProperties.new(args[1], 0.3, 0.5)
			else
				child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
			end
		end
	end
end)

addcmd("weaken", {}, function(args, speaker)
	for _, child in pairs(speaker.Character:GetDescendants()) do
		if child.ClassName == "Part" then
			if args[1] then
				child.CustomPhysicalProperties = PhysicalProperties.new(-args[1], 0.3, 0.5)
			else
				child.CustomPhysicalProperties = PhysicalProperties.new(0, 0.3, 0.5)
			end
		end
	end
end)

addcmd("unweaken", {"unstrengthen"}, function(args, speaker)
	for _, child in pairs(speaker.Character:GetDescendants()) do
		if child.ClassName == "Part" then
			child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
		end
	end
end)

addcmd("breakvelocity", {}, function(args, speaker)
	local BeenASecond, V3 = false, Vector3.new(0, 0, 0)
	delay(1, function()
		BeenASecond = true
	end)
	while not BeenASecond do
		for _, v in ipairs(speaker.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Velocity, v.RotVelocity = V3, V3
			end
		end
		wait()
	end
end)

addcmd('jpower',{'jumppower','jp'},function(args, speaker)
	local jpower = args[1] or 50
	if isNumber(jpower) then
		if speaker.Character:FindFirstChildOfClass('Humanoid').UseJumpPower then
			speaker.Character:FindFirstChildOfClass('Humanoid').JumpPower = jpower
		else
			speaker.Character:FindFirstChildOfClass('Humanoid').JumpHeight  = jpower
		end
	end
end)

addcmd("maxslopeangle", {"msa"}, function(args, speaker)
	local sangle = args[1] or 89
	if isNumber(sangle) then
		speaker.Character:FindFirstChildWhichIsA("Humanoid").MaxSlopeAngle = sangle
	end
end)

addcmd("gravity", {"grav"}, function(args, speaker)
	local grav = args[1] or oldgrav
	if isNumber(grav) then
		workspace.Gravity = grav
	end
end)

addcmd("hipheight", {"hheight"}, function(args, speaker)
	local hipHeight = args[1] or (r15(speaker) and 2.1 or 0)
	if isNumber(hipHeight) then
		speaker.Character:FindFirstChildWhichIsA("Humanoid").HipHeight = hipHeight
	end
end)

addcmd("dance", {}, function(args, speaker)
	pcall(execCmd, "undance")
	local dances = {"27789359", "30196114", "248263260", "45834924", "33796059", "28488254", "52155728"}
	if r15(speaker) then
		dances = {"3333432454", "4555808220", "4049037604", "4555782893", "10214311282", "10714010337", "10713981723", "10714372526", "10714076981", "10714392151", "11444443576"}
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. dances[math.random(1, #dances)]
	danceTrack = speaker.Character:FindFirstChildWhichIsA("Humanoid"):LoadAnimation(animation)
	danceTrack.Looped = true
	danceTrack:Play()
end)

addcmd("undance", {"nodance"}, function(args, speaker)
	danceTrack:Stop()
	danceTrack:Destroy()
end)

addcmd('nolimbs',{'rlimbs'},function(args, speaker)
	if r15(speaker) then
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "RightUpperLeg" or
				v.Name == "LeftUpperLeg" or
				v.Name == "RightUpperArm" or
				v.Name == "LeftUpperArm" then
				v:Destroy()
			end
		end
	else
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "Right Leg" or
				v.Name == "Left Leg" or
				v.Name == "Right Arm" or
				v.Name == "Left Arm" then
				v:Destroy()
			end
		end
	end
end)

addcmd('noarms',{'rarms'},function(args, speaker)
	if r15(speaker) then
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "RightUpperArm" or
				v.Name == "LeftUpperArm" then
				v:Destroy()
			end
		end
	else
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "Right Arm" or
				v.Name == "Left Arm" then
				v:Destroy()
			end
		end
	end
end)

addcmd('nolegs',{'rlegs'},function(args, speaker)
	if r15(speaker) then
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "RightUpperLeg" or
				v.Name == "LeftUpperLeg" then
				v:Destroy()
			end
		end
	else
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "Right Leg" or
				v.Name == "Left Leg" then
				v:Destroy()
			end
		end
	end
end)

addcmd("sit", {}, function(args, speaker)
	speaker.Character:FindFirstChildWhichIsA("Humanoid").Sit = true
end)

addcmd("lay", {"laydown"}, function(args, speaker)
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	humanoid.Sit = true
	task.wait(0.1)
	humanoid.RootPart.CFrame = humanoid.RootPart.CFrame * CFrame.Angles(math.pi * 0.5, 0, 0)
	for _, v in ipairs(humanoid:GetPlayingAnimationTracks()) do
		v:Stop()
	end
end)

addcmd("sitwalk", {}, function(args, speaker)
	local anims = speaker.Character.Animate
	local sit = anims.sit:FindFirstChildWhichIsA("Animation").AnimationId
	anims.idle:FindFirstChildWhichIsA("Animation").AnimationId = sit
	anims.walk:FindFirstChildWhichIsA("Animation").AnimationId = sit
	anims.run:FindFirstChildWhichIsA("Animation").AnimationId = sit
	anims.jump:FindFirstChildWhichIsA("Animation").AnimationId = sit
	speaker.Character:FindFirstChildWhichIsA("Humanoid").HipHeight = not r15(speaker) and -1.5 or 0.5
end)

addcmd("nosit", {}, function(args, speaker)
	speaker.Character:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Seated, false)
end)

addcmd("unnosit", {}, function(args, speaker)
	speaker.Character:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Seated, true)
end)

addcmd("jump", {}, function(args, speaker)
	speaker.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
end)

local infJump
infJumpDebounce = false
addcmd("infjump", {"infinitejump"}, function(args, speaker)
	if infJump then infJump:Disconnect() end
	infJumpDebounce = false
	infJump = UserInputService.JumpRequest:Connect(function()
		if not infJumpDebounce then
			infJumpDebounce = true
			speaker.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
			wait()
			infJumpDebounce = false
		end
	end)
end)

addcmd("uninfjump", {"uninfinitejump", "noinfjump", "noinfinitejump"}, function(args, speaker)
	if infJump then infJump:Disconnect() end
	infJumpDebounce = false
end)

local flyjump
addcmd("flyjump", {}, function(args, speaker)
	if flyjump then flyjump:Disconnect() end
	flyjump = UserInputService.JumpRequest:Connect(function()
		speaker.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
	end)
end)

addcmd("unflyjump", {"noflyjump"}, function(args, speaker)
	if flyjump then flyjump:Disconnect() end
end)

local HumanModCons = {}
addcmd('autojump',{'ajump'},function(args, speaker)
	local Char = speaker.Character
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local function autoJump()
		if Char and Human then
			local check1 = workspace:FindPartOnRay(Ray.new(Human.RootPart.Position-Vector3.new(0,1.5,0), Human.RootPart.CFrame.lookVector*3), Human.Parent)
			local check2 = workspace:FindPartOnRay(Ray.new(Human.RootPart.Position+Vector3.new(0,1.5,0), Human.RootPart.CFrame.lookVector*3), Human.Parent)
			if check1 or check2 then
				Human.Jump = true
			end
		end
	end
	autoJump()
	HumanModCons.ajLoop = (HumanModCons.ajLoop and HumanModCons.ajLoop:Disconnect() and false) or RunService.RenderStepped:Connect(autoJump)
	HumanModCons.ajCA = (HumanModCons.ajCA and HumanModCons.ajCA:Disconnect() and false) or speaker.CharacterAdded:Connect(function(nChar)
		Char, Human = nChar, nChar:WaitForChild("Humanoid")
		autoJump()
		HumanModCons.ajLoop = (HumanModCons.ajLoop and HumanModCons.ajLoop:Disconnect() and false) or RunService.RenderStepped:Connect(autoJump)
	end)
end)

addcmd('unautojump',{'noautojump', 'noajump', 'unajump'},function(args, speaker)
	HumanModCons.ajLoop = (HumanModCons.ajLoop and HumanModCons.ajLoop:Disconnect() and false) or nil
	HumanModCons.ajCA = (HumanModCons.ajCA and HumanModCons.ajCA:Disconnect() and false) or nil
end)

addcmd('edgejump',{'ejump'},function(args, speaker)
	local Char = speaker.Character
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	-- Full credit to NoelGamer06 @V3rmillion
	local state
	local laststate
	local lastcf
	local function edgejump()
		if Char and Human then
			laststate = state
			state = Human:GetState()
			if laststate ~= state and state == Enum.HumanoidStateType.Freefall and laststate ~= Enum.HumanoidStateType.Jumping then
				Char.Humanoid.RootPart.CFrame = lastcf
				Char.Humanoid.RootPart.Velocity = Vector3.new(Char.Humanoid.RootPart.Velocity.X, Human.JumpPower or Human.JumpHeight, Char.Humanoid.RootPart.Velocity.Z)
			end
			lastcf = Char.Humanoid.RootPart.CFrame
		end
	end
	edgejump()
	HumanModCons.ejLoop = (HumanModCons.ejLoop and HumanModCons.ejLoop:Disconnect() and false) or RunService.RenderStepped:Connect(edgejump)
	HumanModCons.ejCA = (HumanModCons.ejCA and HumanModCons.ejCA:Disconnect() and false) or speaker.CharacterAdded:Connect(function(nChar)
		Char, Human = nChar, nChar:WaitForChild("Humanoid")
		edgejump()
		HumanModCons.ejLoop = (HumanModCons.ejLoop and HumanModCons.ejLoop:Disconnect() and false) or RunService.RenderStepped:Connect(edgejump)
	end)
end)

addcmd('unedgejump',{'noedgejump', 'noejump', 'unejump'},function(args, speaker)
	HumanModCons.ejLoop = (HumanModCons.ejLoop and HumanModCons.ejLoop:Disconnect() and false) or nil
	HumanModCons.ejCA = (HumanModCons.ejCA and HumanModCons.ejCA:Disconnect() and false) or nil
end)

addcmd("team", {}, function(args, speaker)
	local teamName = getstring(1, args)
	local team = nil
	local root = speaker.Character and getRoot(speaker.Character)
	for _, v in ipairs(Teams:GetChildren()) do
		if v.Name:lower():match(teamName:lower()) then
			team = v
			break
		end
	end
	if not team then
		return notify("Invalid Team", teamName .. " is not a valid team")
	end
	if root and firetouchinterest then
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("SpawnLocation") and v.BrickColor == team.TeamColor and v.AllowTeamChangeOnTouch == true then
				firetouchinterest(v, root, 0)
				firetouchinterest(v, root, 1)
				break
			end
		end
	else
		speaker.Team = team
	end
end)

addcmd('nobgui',{'unbgui','nobillboardgui','unbillboardgui','noname','rohg'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants())do
		if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
			v:Destroy()
		end
	end
end)

addcmd('loopnobgui',{'loopunbgui','loopnobillboardgui','loopunbillboardgui','loopnoname','looprohg'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants())do
		if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
			v:Destroy()
		end
	end
	local function charPartAdded(part)
		if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
			wait()
			part:Destroy()
		end
	end
	charPartTrigger = speaker.Character.DescendantAdded:Connect(charPartAdded)
end)

addcmd('unloopnobgui',{'unloopunbgui','unloopnobillboardgui','unloopunbillboardgui','unloopnoname','unlooprohg'},function(args, speaker)
	if charPartTrigger then
		charPartTrigger:Disconnect()
	end
end)

addcmd('spasm',{},function(args, speaker)
	if not r15(speaker) then
		local pchar=speaker.Character
		local AnimationId = "33796059"
		SpasmAnim = Instance.new("Animation")
		SpasmAnim.AnimationId = "rbxassetid://"..AnimationId
		Spasm = pchar:FindFirstChildOfClass('Humanoid'):LoadAnimation(SpasmAnim)
		Spasm:Play()
		Spasm:AdjustSpeed(99)
	else
		notify('R6 Required','This command requires the r6 rig type')
	end
end)

addcmd('unspasm',{'nospasm'},function(args, speaker)
	Spasm:Stop()
	SpasmAnim:Destroy()
end)

addcmd('headthrow',{},function(args, speaker)
	if not r15(speaker) then
		local AnimationId = "35154961"
		local Anim = Instance.new("Animation")
		Anim.AnimationId = "rbxassetid://"..AnimationId
		local k = speaker.Character:FindFirstChildOfClass('Humanoid'):LoadAnimation(Anim)
		k:Play(0)
		k:AdjustSpeed(1)
	else
		notify('R6 Required','This command requires the r6 rig type')
	end
end)

local function anim2track(asset_id)
	local objs = game:GetObjects(asset_id)
	for i = 1, #objs do
		if objs[i]:IsA("Animation") then
			return objs[i].AnimationId
		end
	end
	return asset_id
end

addcmd("animation", {"anim"}, function(args, speaker)
	local animid = tostring(args[1])
	if not animid:find("rbxassetid://") then
		animid = "rbxassetid://" .. animid
	end
	animid = anim2track(animid)
	local animation = Instance.new("Animation")
	animation.AnimationId = animid
	local anim = speaker.Character:FindFirstChildWhichIsA("Humanoid"):LoadAnimation(animation)
	anim.Priority = Enum.AnimationPriority.Movement
	anim:Play()
	if args[2] then anim:AdjustSpeed(tostring(args[2])) end
end)

addcmd("emote", {"em"}, function(args, speaker)
	local anim = humanoid:PlayEmoteAndGetAnimTrackById(args[1])
	if args[2] then anim:AdjustSpeed(tostring(args[2])) end
end)


addcmd('noanim',{},function(args, speaker)
	speaker.Character.Animate.Disabled = true
end)

addcmd('reanim',{},function(args, speaker)
	speaker.Character.Animate.Disabled = false
end)

addcmd('animspeed',{},function(args, speaker)
	local Char = speaker.Character
	local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

	for i,v in next, Hum:GetPlayingAnimationTracks() do
		v:AdjustSpeed(tonumber(args[1] or 1))
	end
end)

addcmd('copyanimation',{'copyanim','copyemote'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for _,v in ipairs(players)do
		local char = Players[v].Character
		for _, v1 in pairs(speaker.Character:FindFirstChildOfClass('Humanoid'):GetPlayingAnimationTracks()) do
			v1:Stop()
		end
		for _, v1 in pairs(Players[v].Character:FindFirstChildOfClass('Humanoid'):GetPlayingAnimationTracks()) do
			if not string.find(v1.Animation.AnimationId, "507768375") then
				local ANIM = speaker.Character:FindFirstChildOfClass('Humanoid'):LoadAnimation(v1.Animation)
				ANIM:Play(.1, 1, v1.Speed)
				ANIM.TimePosition = v1.TimePosition
				task.spawn(function()
					v1.Stopped:Wait()
					ANIM:Stop()
					ANIM:Destroy()
				end)
			end
		end
	end
end)

addcmd("copyanimationid", {"copyanimid", "copyemoteid"}, function(args, speaker)
	local copyAnimId = function(player)
		local found = "Animations Copied"

		for _, v in pairs(player.Character:FindFirstChildWhichIsA("Humanoid"):GetPlayingAnimationTracks()) do
			local animationId = v.Animation.AnimationId
			local assetId = animationId:find("rbxassetid://") and animationId:match("%d+")

			if not string.find(animationId, "507768375") and not string.find(animationId, "180435571") then
				if assetId then
					local success, result = pcall(function()
						return MarketplaceService:GetProductInfo(tonumber(assetId)).Name
					end)
					local name = success and result or "Failed to get name"
					found = found .. "\n\nName: " .. name .. "\nAnimation Id: " .. animationId
				else
					found = found .. "\n\nAnimation Id: " .. animationId
				end
			end
		end

		if found ~= "Animations Copied" then
			toClipboard(found)
		else
			notify("Animations", "No animations to copy")
		end
	end

	if args[1] then
		copyAnimId(Players[getPlayer(args[1], speaker)[1]])
	else
		copyAnimId(speaker)
	end
end)

addcmd('stopanimations',{'stopanims','stopanim'},function(args, speaker)
	local Char = speaker.Character
	local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

	for i,v in next, Hum:GetPlayingAnimationTracks() do
		v:Stop()
	end
end)

addcmd('refreshanimations', {'refreshanimation', 'refreshanims', 'refreshanim'}, function(args, speaker)
	local Char = speaker.Character or speaker.CharacterAdded:Wait()
	local Human = Char and Char:WaitForChild('Humanoid', 15)
	local Animate = Char and Char:WaitForChild('Animate', 15)
	if not Human or not Animate then
		return notify('Refresh Animations', 'Failed to get Animate/Humanoid')
	end
	Animate.Disabled = true
	for _, v in ipairs(Human:GetPlayingAnimationTracks()) do
		v:Stop()
	end
	Animate.Disabled = false
end)

addcmd('allowcustomanim', {'allowcustomanimations'}, function(args, speaker)
	StarterPlayer.AllowCustomAnimations = true
	execCmd('refreshanimations')
end)

addcmd('unallowcustomanim', {'unallowcustomanimations'}, function(args, speaker)
	StarterPlayer.AllowCustomAnimations = false
	execCmd('refreshanimations')
end)

addcmd('loopanimation', {'loopanim'},function(args, speaker)
	local Char = speaker.Character
	local Human = Char and Char.FindFirstChildWhichIsA(Char, "Humanoid")
	for _, v in ipairs(Human.GetPlayingAnimationTracks(Human)) do
		v.Looped = true
	end
end)

addcmd('tpposition',{'tppos'},function(args, speaker)
	if #args < 3 then return end
	local tpX,tpY,tpZ = tonumber((args[1]:gsub(",", ""))),tonumber((args[2]:gsub(",", ""))),tonumber((args[3]:gsub(",", "")))
	local char = speaker.Character
	if char and getRoot(char) then
		getRoot(char).CFrame = CFrame.new(tpX,tpY,tpZ)
	end
end)

addcmd('tweentpposition',{'ttppos'},function(args, speaker)
	if #args < 3 then return end
	local tpX,tpY,tpZ = tonumber((args[1]:gsub(",", ""))),tonumber((args[2]:gsub(",", ""))),tonumber((args[3]:gsub(",", "")))
	local char = speaker.Character
	if char and getRoot(char) then
		TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(tpX,tpY,tpZ)}):Play()
	end
end)

addcmd("offset", {}, function(args, speaker)
    if #args < 3 then return end
    speaker.Character:TranslateBy(Vector3.new(tonumber(args[1]) or 0, tonumber(args[2]) or 0, tonumber(args[3]) or 0))
end)

addcmd("tweenoffset", {"toffset"}, function(args, speaker)
    if #args < 3 then return end
    local tpX, tpY, tpZ = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    local root = getRoot(speaker.Character)
    local pos = root.Position + Vector3.new(tpX, tpY, tpZ)
    TweenService:Create(root, TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)}):Play()
    breakVelocity()
end)

addcmd("clickteleport", {}, function(args, speaker)
    if speaker ~= Players.LocalPlayer then return end
    notify("Click TP", "Go to Settings > Keybinds > Add to set up click teleport")
end)

addcmd("mouseteleport", {"mousetp"}, function(args, speaker)
    local root = getRoot(speaker.Character)
    local pos = IYMouse.Hit
    if root and pos then
        root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z, select(4, root.CFrame:components()))
        breakVelocity()
    end
end)

addcmd("tptool", {"teleporttool"}, function(args, speaker)
    local TpTool = Instance.new("Tool")
    TpTool.Name = "Teleport Tool"
    TpTool.RequiresHandle = false
    TpTool.Parent = speaker:FindFirstChildOfClass("Backpack")
    TpTool.Activated:Connect(function()
        local root = getRoot(speaker.Character)
        local pos = IYMouse.Hit
        if not root or not pos then return end
        root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z, select(4, root.CFrame:components()))
        breakVelocity()
    end)
end)

addcmd("thru", {}, function(args, speaker)
    local root = getRoot(speaker.Character)
    local num = tonumber(args[1]) or 5
    local pos = root.CFrame.Position + (root.CFrame.LookVector * num)
    root.CFrame = CFrame.new(pos, pos + root.CFrame.LookVector)
end)

addcmd('clickdelete',{},function(args, speaker)
	if speaker == Players.LocalPlayer then
		notify('Click Delete','Go to Settings > Keybinds > Add to set up click delete')
	end
end)

addcmd('getposition',{'getpos','notifypos','notifyposition'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		local char = Players[v].Character
		local pos = char and (getRoot(char) or char:FindFirstChildWhichIsA("BasePart"))
		pos = pos and pos.Position
		if not pos then
			return notify('Getposition Error','Missing character')
		end
		local roundedPos = math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)
		notify('Current Position',roundedPos)
	end
end)

addcmd('copyposition',{'copypos'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		local char = Players[v].Character
		local pos = char and (getRoot(char) or char:FindFirstChildWhichIsA("BasePart"))
		pos = pos and pos.Position
		if not pos then
			return notify('Getposition Error','Missing character')
		end
		local roundedPos = math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)
		toClipboard(roundedPos)
	end
end)

addcmd('walktopos',{'walktoposition'},function(args, speaker)
	if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
		speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
		wait(.1)
	end
	speaker.Character:FindFirstChildOfClass('Humanoid').WalkToPoint = Vector3.new(args[1],args[2],args[3])
end)

addcmd('speed',{'ws','walkspeed'},function(args, speaker)
	if args[2] then
		local speed = args[2] or 16
		if isNumber(speed) then
			speaker.Character:FindFirstChildOfClass('Humanoid').WalkSpeed = speed
		end
	else
		local speed = args[1] or 16
		if isNumber(speed) then
			speaker.Character:FindFirstChildOfClass('Humanoid').WalkSpeed = speed
		end
	end
end)

addcmd('spoofspeed',{'spoofws','spoofwalkspeed'},function(args, speaker)
	if args[1] and isNumber(args[1]) then
		if hookmetamethod then
			local char = speaker.Character
			local setspeed;
			local index; index = hookmetamethod(game, "__index", function(self, key)
				if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "WalkSpeed" or key == "walkSpeed") and self:IsDescendantOf(char) then
					return setspeed or args[1]
				end
				return index(self, key)
			end)
			local newindex; newindex = hookmetamethod(game, "__newindex", function(self, key, value)
				if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "WalkSpeed" or key == "walkSpeed") and self:IsDescendantOf(char) then
					setspeed = tonumber(value)
				end
				return newindex(self, key, value)
			end)
		else
			notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
		end
	end
end)

addcmd('loopspeed',{'loopws'},function(args, speaker)
	local speed = args[1] or 16
	if args[2] then
		speed = args[2] or 16
	end
	if isNumber(speed) then
		local Char = speaker.Character or workspace:FindFirstChild(speaker.Name)
		local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
		local function WalkSpeedChange()
			if Char and Human then
				Human.WalkSpeed = speed
			end
		end
		WalkSpeedChange()
		HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange)
		HumanModCons.wsCA = (HumanModCons.wsCA and HumanModCons.wsCA:Disconnect() and false) or speaker.CharacterAdded:Connect(function(nChar)
			Char, Human = nChar, nChar:WaitForChild("Humanoid")
			WalkSpeedChange()
			HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange)
		end)
	end
end)

addcmd('unloopspeed',{'unloopws'},function(args, speaker)
	HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or nil
	HumanModCons.wsCA = (HumanModCons.wsCA and HumanModCons.wsCA:Disconnect() and false) or nil
end)

addcmd('spoofjumppower',{'spoofjp'},function(args, speaker)
	if args[1] and isNumber(args[1]) then
		if hookmetamethod then
			local char = speaker.Character
			local setpower;
			local index; index = hookmetamethod(game, "__index", function(self, key)
				if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "JumpPower" or key == "jumpPower") and self:IsDescendantOf(char) then
					return setpower or args[1]
				end
				return index(self, key)
			end)
			local newindex; newindex = hookmetamethod(game, "__newindex", function(self, key, value)
				if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "JumpPower" or key == "jumpPower") and self:IsDescendantOf(char) then
					setpower = tonumber(value)
				end
				return newindex(self, key, value)
			end)
		else
			notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
		end
	end
end)

addcmd('loopjumppower',{'loopjp','loopjpower'},function(args, speaker)
	local jpower = args[1] or 50
	if isNumber(jpower) then
		local Char = speaker.Character or workspace:FindFirstChild(speaker.Name)
		local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
		local function JumpPowerChange()
			if Char and Human then
				if speaker.Character:FindFirstChildOfClass('Humanoid').UseJumpPower then
					speaker.Character:FindFirstChildOfClass('Humanoid').JumpPower = jpower
				else
					speaker.Character:FindFirstChildOfClass('Humanoid').JumpHeight  = jpower
				end
			end
		end
		JumpPowerChange()
		HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("JumpPower"):Connect(JumpPowerChange)
		HumanModCons.jpCA = (HumanModCons.jpCA and HumanModCons.jpCA:Disconnect() and false) or speaker.CharacterAdded:Connect(function(nChar)
			Char, Human = nChar, nChar:WaitForChild("Humanoid")
			JumpPowerChange()
			HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("JumpPower"):Connect(JumpPowerChange)
		end)
	end
end)

addcmd('unloopjumppower',{'unloopjp','unloopjpower'},function(args, speaker)
	local Char = speaker.Character or workspace:FindFirstChild(speaker.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or nil
	HumanModCons.jpCA = (HumanModCons.jpCA and HumanModCons.jpCA:Disconnect() and false) or nil
	if Char and Human then
		if speaker.Character:FindFirstChildOfClass('Humanoid').UseJumpPower then
			speaker.Character:FindFirstChildOfClass('Humanoid').JumpPower = 50
		else
			speaker.Character:FindFirstChildOfClass('Humanoid').JumpHeight  = 50
		end
	end
end)

addcmd('tools',{'gears'},function(args, speaker)
	local function copy(instance)
		for i,c in pairs(instance:GetChildren())do
			if c:IsA('Tool') or c:IsA('HopperBin') then
				c:Clone().Parent = speaker:FindFirstChildOfClass("Backpack")
			end
			copy(c)
		end
	end
	copy(Lighting)
	local function copy(instance)
		for i,c in pairs(instance:GetChildren())do
			if c:IsA('Tool') or c:IsA('HopperBin') then
				c:Clone().Parent = speaker:FindFirstChildOfClass("Backpack")
			end
			copy(c)
		end
	end
	copy(ReplicatedStorage)
	notify('Tools','Copied tools from ReplicatedStorage and Lighting')
end)

addcmd('notools',{'rtools','clrtools','removetools','deletetools','dtools'},function(args, speaker)
	for i,v in pairs(speaker:FindFirstChildOfClass("Backpack"):GetDescendants()) do
		if v:IsA('Tool') or v:IsA('HopperBin') then
			v:Destroy()
		end
	end
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA('Tool') or v:IsA('HopperBin') then
			v:Destroy()
		end
	end
end)

addcmd('deleteselectedtool',{'dst'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA('Tool') or v:IsA('HopperBin') then
			v:Destroy()
		end
	end
end)

addcmd("console", {}, function(args, speaker)
	StarterGui:SetCore("DevConsoleVisible", true)
end)

addcmd('oldconsole',{},function(args, speaker)
	-- Thanks wally!!
	notify("Loading",'Hold on a sec')
	local _, str = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/console.lua", true)
	end)

	local s, e = loadstring(str)
	if typeof(s) ~= "function" then
		return
	end

	local success, message = pcall(s)
	if (not success) then
		if printconsole then
			printconsole(message)
		elseif printoutput then
			printoutput(message)
		end
	end
	wait(1)
	notify('Console','Press F9 to open the console')
end)

addcmd("explorer", {"dex"}, function(args, speaker)
	notify("Loading", "Hold on a sec")
	loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
end)

addcmd('olddex', {'odex'}, function(args, speaker)
	notify('Loading old explorer', 'Hold on a sec')

	local getobjects = function(a)
		local Objects = {}
		if a then
			local b = InsertService:LoadLocalAsset(a)
			if b then 
				table.insert(Objects, b) 
			end
		end
		return Objects
	end

	local Dex = getobjects("rbxassetid://10055842438")[1]
	Dex.Parent = PARENT

	local function Load(Obj, Url)
		local function GiveOwnGlobals(Func, Script)
			-- Fix for this edit of dex being poorly made
			-- I (Alex) would like to commemorate whoever added this dex in somehow finding the worst dex to ever exist
			local Fenv, RealFenv, FenvMt = {}, {
				script = Script,
				getupvalue = function(a, b)
					return nil -- force it to use globals
				end,
				getreg = function() -- It loops registry for some idiotic reason so stop it from doing that and just use a global
					return {} -- force it to use globals
				end,
				getprops = getprops or function(inst)
					if getproperties then
						local props = getproperties(inst)
						if props[1] and gethiddenproperty then
							local results = {}
							for _,name in pairs(props) do
								local success, res = pcall(gethiddenproperty, inst, name)
								if success then
									results[name] = res
								end
							end

							return results
						end

						return props
					end

					return {}
				end
			}, {}
			FenvMt.__index = function(a,b)
				return RealFenv[b] == nil and getgenv()[b] or RealFenv[b]
			end
			FenvMt.__newindex = function(a, b, c)
				if RealFenv[b] == nil then 
					getgenv()[b] = c 
				else 
					RealFenv[b] = c 
				end
			end
			setmetatable(Fenv, FenvMt)
			pcall(setfenv, Func, Fenv)
			return Func
		end

		local function LoadScripts(_, Script)
			if Script:IsA("LocalScript") then
				task.spawn(function()
					GiveOwnGlobals(loadstring(Script.Source,"="..Script:GetFullName()), Script)()
				end)
			end
			table.foreach(Script:GetChildren(), LoadScripts)
		end

		LoadScripts(nil, Obj)
	end

	Load(Dex)
end)

addcmd('remotespy',{'rspy'},function(args, speaker)
	notify("Loading",'Hold on a sec')
	-- Full credit to exx, creator of SimpleSpy
	-- also thanks to Amity for fixing
	loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
end)

addcmd("executor", {}, function(args, speaker)
    -- by dnezero
    notify("Loading", "Hold on a sec")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/executor.lua"))()
end)

addcmd('audiologger',{'alogger'},function(args, speaker)
	notify("Loading",'Hold on a sec')
	loadstring(game:HttpGet(('https://raw.githubusercontent.com/infyiff/backup/main/audiologger.lua'),true))()
end)

local loopgoto = nil
addcmd('loopgoto',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		loopgoto = nil
		if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
			speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
			wait(.1)
		end
		loopgoto = Players[v]
		local distance = 3
		if args[2] and isNumber(args[2]) then
			distance = args[2]
		end
		local lDelay = 0
		if args[3] and isNumber(args[3]) then
			lDelay = args[3]
		end
		repeat
			if Players:FindFirstChild(v) then
				if Players[v].Character ~= nil then
					getRoot(speaker.Character).CFrame = getRoot(Players[v].Character).CFrame + Vector3.new(distance,1,0)
				end
				wait(lDelay)
			else
				loopgoto = nil
			end
		until loopgoto ~= Players[v]
	end
end)

addcmd('unloopgoto',{'noloopgoto'},function(args, speaker)
	loopgoto = nil
end)

addcmd('headsit',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	if headSit then headSit:Disconnect() end
	for i,v in pairs(players)do
		speaker.Character:FindFirstChildOfClass('Humanoid').Sit = true
		headSit = RunService.Heartbeat:Connect(function()
			if Players:FindFirstChild(Players[v].Name) and Players[v].Character ~= nil and getRoot(Players[v].Character) and getRoot(speaker.Character) and speaker.Character:FindFirstChildOfClass('Humanoid').Sit == true then
				getRoot(speaker.Character).CFrame = getRoot(Players[v].Character).CFrame * CFrame.Angles(0,math.rad(0),0)* CFrame.new(0,1.6,0.4)
			else
				headSit:Disconnect()
			end
		end)
	end
end)

addcmd('chat',{'say'},function(args, speaker)
	local cString = getstring(1, args)
	chatMessage(cString)
end)


spamming = false
spamspeed = 1
addcmd('spam',{},function(args, speaker)
	spamming = true
	local spamstring = getstring(1, args)
	repeat wait(spamspeed)
		chatMessage(spamstring)
	until spamming == false
end)

addcmd('nospam',{'unspam'},function(args, speaker)
	spamming = false
end)

addcmd('whisper',{'pm'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			local plrName = Players[v].Name
			local pmstring = getstring(2, args)
			chatMessage("/w "..plrName.." "..pmstring)
		end)
	end
end)

pmspamming = {}
addcmd('pmspam',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			local plrName = Players[v].Name
			if FindInTable(pmspamming, plrName) then return end
			table.insert(pmspamming, plrName)
			local pmspamstring = getstring(2, args)
			repeat
				if Players:FindFirstChild(v) then
					wait(spamspeed)
					chatMessage("/w "..plrName.." "..pmspamstring)
				else
					for a,b in pairs(pmspamming) do if b == plrName then table.remove(pmspamming, a) end end
				end
			until not FindInTable(pmspamming, plrName)
		end)
	end
end)

addcmd('nopmspam',{'unpmspam'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			for a,b in pairs(pmspamming) do
				if b == Players[v].Name then
					table.remove(pmspamming, a)
				end
			end
		end)
	end
end)

addcmd('spamspeed',{},function(args, speaker)
	local speed = args[1] or 1
	if isNumber(speed) then
		spamspeed = speed
	end
end)

addcmd('bubblechat',{},function(args, speaker)
	if isLegacyChat then
		ChatService.BubbleChatEnabled = true
	else
		TextChatService.BubbleChatConfiguration.Enabled = true
	end
end)

addcmd('unbubblechat',{'nobubblechat'},function(args, speaker)
	if isLegacyChat then
		ChatService.BubbleChatEnabled = false
	else
		TextChatService.BubbleChatConfiguration.Enabled = false
	end
end)

addcmd("chatwindow", {}, function(args, speaker)
	TextChatService.ChatWindowConfiguration.Enabled = true
end)

addcmd("unchatwindow", {"nochatwindow"}, function(args, speaker)
	TextChatService.ChatWindowConfiguration.Enabled = false
end)

addcmd("darkchat", {}, function(args, speaker)
    local BCC = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
    local CWC = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
    local CIBC = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
    if BCC then
        BCC.Enabled = true
        BCC.BackgroundColor3 = Color3.fromRGB()
        BCC.BackgroundTransparency = 0.3
        BCC.TailVisible = true
        BCC.TextColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
    end
    if CWC then
        CWC.Enabled = true
        CWC.BackgroundColor3 = Color3.fromRGB()
        CWC.BackgroundTransparency = 0.3
        CWC.TextColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
        CWC.TextStrokeColor3 = Color3.fromRGB()
        CWC.TextStrokeTransparency = 0.5
    end
    if CIBC then
        CIBC.Enabled = true
        CIBC.BackgroundColor3 = Color3.fromRGB()
        CIBC.BackgroundTransparency = 0.5
        CIBC.PlaceholderColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
        CIBC.TextColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
        CIBC.TextStrokeColor3 = Color3.fromRGB()
        CIBC.TextStrokeTransparency = 0.5
    end
end)

addcmd('blockhead',{},function(args, speaker)
	speaker.Character.Head:FindFirstChildOfClass("SpecialMesh"):Destroy()
end)

addcmd('blockhats',{},function(args, speaker)
	for _,v in pairs(speaker.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
		for i,c in pairs(v:GetDescendants()) do
			if c:IsA("SpecialMesh") then
				c:Destroy()
			end
		end
	end
end)

addcmd('blocktool',{},function(args, speaker)
	for _,v in pairs(speaker.Character:GetChildren()) do
		if v:IsA("Tool") or v:IsA("HopperBin") then
			for i,c in pairs(v:GetDescendants()) do
				if c:IsA("SpecialMesh") then
					c:Destroy()
				end
			end
		end
	end
end)

addcmd('creeper',{},function(args, speaker)
	if r15(speaker) then
		speaker.Character.Head:FindFirstChildOfClass("SpecialMesh"):Destroy()
		speaker.Character.LeftUpperArm:Destroy()
		speaker.Character.RightUpperArm:Destroy()
		speaker.Character:FindFirstChildOfClass("Humanoid"):RemoveAccessories()
	else
		speaker.Character.Head:FindFirstChildOfClass("SpecialMesh"):Destroy()
		speaker.Character["Left Arm"]:Destroy()
		speaker.Character["Right Arm"]:Destroy()
		speaker.Character:FindFirstChildOfClass("Humanoid"):RemoveAccessories()
	end
end)

function getTorso(x)
	x = x or Players.LocalPlayer.Character
	return x:FindFirstChild("Torso") or x:FindFirstChild("UpperTorso") or x:FindFirstChild("LowerTorso") or x:FindFirstChild("HumanoidRootPart")
end

addcmd("bang", {"rape"}, function(args, speaker)
	execCmd("unbang")
	wait()
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	bangAnim = Instance.new("Animation")
	bangAnim.AnimationId = not r15(speaker) and "rbxassetid://148840371" or "rbxassetid://5918726674"
	bang = humanoid:LoadAnimation(bangAnim)
	bang:Play(0.1, 1, 1)
	bang:AdjustSpeed(args[2] or 3)
	bangDied = humanoid.Died:Connect(function()
		bang:Stop()
		bangAnim:Destroy()
		bangDied:Disconnect()
		bangLoop:Disconnect()
	end)
	if args[1] then
		local players = getPlayer(args[1], speaker)
		for _, v in pairs(players) do
			local bangplr = Players[v].Name
			local bangOffet = CFrame.new(0, 0, 1.1)
			bangLoop = RunService.Stepped:Connect(function()
				pcall(function()
					local otherRoot = getTorso(Players[bangplr].Character)
					getRoot(speaker.Character).CFrame = otherRoot.CFrame * bangOffet
				end)
			end)
		end
	end
end)

addcmd("unbang", {"unrape"}, function(args, speaker)
	if bangDied then
		bangDied:Disconnect()
		bang:Stop()
		bangAnim:Destroy()
		bangLoop:Disconnect()
	end
end)

addcmd('carpet',{},function(args, speaker)
	if not r15(speaker) then
		execCmd('uncarpet')
		wait()
		local players = getPlayer(args[1], speaker)
		for i,v in pairs(players)do
			carpetAnim = Instance.new("Animation")
			carpetAnim.AnimationId = "rbxassetid://282574440"
			carpet = speaker.Character:FindFirstChildOfClass('Humanoid'):LoadAnimation(carpetAnim)
			carpet:Play(.1, 1, 1)
			local carpetplr = Players[v].Name
			carpetDied = speaker.Character:FindFirstChildOfClass'Humanoid'.Died:Connect(function()
				carpetLoop:Disconnect()
				carpet:Stop()
				carpetAnim:Destroy()
				carpetDied:Disconnect()
			end)
			carpetLoop = RunService.Heartbeat:Connect(function()
				pcall(function()
					getRoot(Players.LocalPlayer.Character).CFrame = getRoot(Players[carpetplr].Character).CFrame
				end)
			end)
		end
	else
		notify('R6 Required','This command requires the r6 rig type')
	end
end)

addcmd('uncarpet',{'nocarpet'},function(args, speaker)
	if carpetLoop then
		carpetLoop:Disconnect()
		carpetDied:Disconnect()
		carpet:Stop()
		carpetAnim:Destroy()
	end
end)

addcmd('friend',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		speaker:RequestFriendship(Players[v])
	end
end)

addcmd('unfriend',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		speaker:RevokeFriendship(Players[v])
	end
end)

addcmd('bringpart',{},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			v.CFrame = getRoot(speaker.Character).CFrame
		end
	end
end)

addcmd('bringpartclass',{'bpc'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.ClassName:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			v.CFrame = getRoot(speaker.Character).CFrame
		end
	end
end)

gotopartDelay = 0.1
addcmd('gotopart',{'topart'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			getRoot(speaker.Character).CFrame = v.CFrame
		end
	end
end)

addcmd('tweengotopart',{'tgotopart','ttopart'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = v.CFrame}):Play()
		end
	end
end)

addcmd('gotopartclass',{'gpc'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.ClassName:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			getRoot(speaker.Character).CFrame = v.CFrame
		end
	end
end)

addcmd('tweengotopartclass',{'tgpc'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.ClassName:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = v.CFrame}):Play()
		end
	end
end)

addcmd('gotomodel',{'tomodel'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() and v:IsA("Model") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			getRoot(speaker.Character).CFrame = v:GetModelCFrame()
		end
	end
end)

addcmd('tweengotomodel',{'tgotomodel','ttomodel'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() and v:IsA("Model") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = v:GetModelCFrame()}):Play()
		end
	end
end)

addcmd('gotopartdelay',{},function(args, speaker)
	local gtpDelay = args[1] or 0.1
	if isNumber(gtpDelay) then
		gotopartDelay = gtpDelay
	end
end)

addcmd('noclickdetectorlimits',{'nocdlimits','removecdlimits'},function(args, speaker)
	for i,v in ipairs(workspace:GetDescendants()) do
		if v:IsA("ClickDetector") then
			v.MaxActivationDistance = math.huge
		end
	end
end)

addcmd('fireclickdetectors',{'firecd','firecds'}, function(args, speaker)
	if fireclickdetector then
		if args[1] then
			local name = getstring(1, args):lower()
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ClickDetector") and descendant.Name:lower() == name or descendant.Parent.Name:lower() == name then
					fireclickdetector(descendant)
				end
			end
		else
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ClickDetector") then
					fireclickdetector(descendant)
				end
			end
		end
	else
		notify("Incompatible Exploit", "Your exploit does not support this command (missing fireclickdetector)")
	end
end)

addcmd('noproximitypromptlimits',{'nopplimits','removepplimits'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then
			v.MaxActivationDistance = math.huge
		end
	end
end)

addcmd('fireproximityprompts',{'firepp'},function(args, speaker)
	if fireproximityprompt then
		if args[1] then
			local name = getstring(1, args)
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ProximityPrompt") and descendant.Name == name or descendant.Parent.Name == name then
					fireproximityprompt(descendant)
				end
			end
		else
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ProximityPrompt") then
					fireproximityprompt(descendant)
				end
			end
		end
	else
		notify("Incompatible Exploit", "Your exploit does not support this command (missing fireproximityprompt)")
	end
end)

local PromptButtonHoldBegan = nil
addcmd('instantproximityprompts',{'instantpp'},function(args, speaker)
	if fireproximityprompt then
		execCmd("uninstantproximityprompts")
		wait(0.1)
		PromptButtonHoldBegan = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
			fireproximityprompt(prompt)
		end)
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing fireproximityprompt)')
	end
end)

addcmd('uninstantproximityprompts',{'uninstantpp'},function(args, speaker)
	if PromptButtonHoldBegan ~= nil then
		PromptButtonHoldBegan:Disconnect()
		PromptButtonHoldBegan = nil
	end
end)

addcmd('notifyping',{'ping'},function(args, speaker)
	notify("Ping", math.round(speaker:GetNetworkPing() * 1000) .. "ms")
end)

addcmd('grabtools', {}, function(args, speaker)
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	for _, child in ipairs(workspace:GetChildren()) do
		if speaker.Character and child:IsA("BackpackItem") and child:FindFirstChild("Handle") then
			humanoid:EquipTool(child)
		end
	end

	if grabtoolsFunc then 
		grabtoolsFunc:Disconnect() 
	end

	grabtoolsFunc = workspace.ChildAdded:Connect(function(child)
		if speaker.Character and child:IsA("BackpackItem") and child:FindFirstChild("Handle") then
			humanoid:EquipTool(child)
		end
	end)

	notify("Grabtools", "Picking up any dropped tools")
end)

addcmd('nograbtools',{'ungrabtools'},function(args, speaker)
	if grabtoolsFunc then 
		grabtoolsFunc:Disconnect() 
	end

	notify("Grabtools", "Grabtools has been disabled")
end)

local specifictoolremoval = {}
addcmd('removespecifictool',{},function(args, speaker)
	if args[1] and speaker:FindFirstChildOfClass("Backpack") then
		local tool = string.lower(getstring(1, args))
		local RST = RunService.RenderStepped:Connect(function()
			if speaker:FindFirstChildOfClass("Backpack") then
				for i,v in pairs(speaker:FindFirstChildOfClass("Backpack"):GetChildren()) do
					if v.Name:lower() == tool then
						v:Remove()
					end
				end
			end
		end)
		specifictoolremoval[tool] = RST
	end
end)

addcmd('unremovespecifictool',{},function(args, speaker)
	if args[1] then
		local tool = string.lower(getstring(1, args))
		if specifictoolremoval[tool] ~= nil then
			specifictoolremoval[tool]:Disconnect()
			specifictoolremoval[tool] = nil
		end
	end
end)

addcmd('clearremovespecifictool',{},function(args, speaker)
	for obj in pairs(specifictoolremoval) do
		specifictoolremoval[obj]:Disconnect()
		specifictoolremoval[obj] = nil
	end
end)

addcmd('light',{},function(args, speaker)
	local light = Instance.new("PointLight")
	light.Parent = getRoot(speaker.Character)
	light.Range = 30
	if args[1] then
		light.Brightness = args[2]
		light.Range = args[1]
	else
		light.Brightness = 5
	end
end)

addcmd('unlight',{'nolight'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v.ClassName == "PointLight" then
			v:Destroy()
		end
	end
end)

addcmd('copytools',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			for i,v in pairs(Players[v]:FindFirstChildOfClass("Backpack"):GetChildren()) do
				if v:IsA('Tool') or v:IsA('HopperBin') then
					v:Clone().Parent = speaker:FindFirstChildOfClass("Backpack")
				end
			end
		end)
	end
end)

addcmd('naked',{},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Clothing") or v:IsA("ShirtGraphic") then
			v:Destroy()
		end
	end
end)

addcmd('noface',{'removeface'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Decal") and v.Name == 'face' then
			v:Destroy()
		end
	end
end)

addcmd('spawnpoint',{'spawn'},function(args, speaker)
	spawnpos = getRoot(speaker.Character).CFrame
	spawnpoint = true
	spDelay = tonumber(args[1]) or 0.1
	notify('Spawn Point','Spawn point created at '..tostring(spawnpos))
end)

addcmd('nospawnpoint',{'nospawn','removespawnpoint'},function(args, speaker)
	spawnpoint = false
	notify('Spawn Point','Removed spawn point')
end)

addcmd('flashback',{'diedtp'},function(args, speaker)
	if lastDeath ~= nil then
		if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
			speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
			wait(.1)
		end
		getRoot(speaker.Character).CFrame = lastDeath
	end
end)

addcmd('hatspin',{'spinhats'},function(args, speaker)
	execCmd('unhatspin')
	wait(.5)
	for _,v in pairs(speaker.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
		local keep = Instance.new("BodyPosition") keep.Name = randomString() keep.Parent = v.Handle
		local spin = Instance.new("BodyAngularVelocity") spin.Name = randomString() spin.Parent = v.Handle
		v.Handle:FindFirstChildOfClass("Weld"):Destroy()
		if args[1] then
			spin.AngularVelocity = Vector3.new(0, args[1], 0)
			spin.MaxTorque = Vector3.new(0, args[1] * 2, 0)
		else
			spin.AngularVelocity = Vector3.new(0, 100, 0)
			spin.MaxTorque = Vector3.new(0, 200, 0)
		end
		keep.P = 30000
		keep.D = 50
		spinhats = RunService.Stepped:Connect(function()
			pcall(function()
				keep.Position = Players.LocalPlayer.Character.Head.Position
			end)
		end)
	end
end)

addcmd('unhatspin',{'unspinhats'},function(args, speaker)
	if spinhats then
		spinhats:Disconnect()
	end
	for _,v in pairs(speaker.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
		v.Parent = workspace
		for i,c in pairs(v.Handle) do
			if c:IsA("BodyPosition") or c:IsA("BodyAngularVelocity") then
				c:Destroy()
			end
		end
		wait()
		v.Parent = speaker.Character
	end
end)

addcmd('clearhats',{'cleanhats'},function(args, speaker)
	if firetouchinterest then
		local Player = Players.LocalPlayer
		local Character = Player.Character
		local Old = getRoot(Character).CFrame
		local Hats = {}

		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Accessory") then
				table.insert(Hats, child)
			end
		end

		for _, accessory in ipairs(Character:FindFirstChildOfClass("Humanoid"):GetAccessories()) do
			accessory:Destroy()
		end

		for i = 1, #Hats do
			repeat RunService.Heartbeat:wait() until Hats[i]
			firetouchinterest(Hats[i].Handle,getRoot(Character),0)
			repeat RunService.Heartbeat:wait() until Character:FindFirstChildOfClass("Accessory")
			Character:FindFirstChildOfClass("Accessory"):Destroy()
			repeat RunService.Heartbeat:wait() until not Character:FindFirstChildOfClass("Accessory")
		end

		execCmd("reset")

		Player.CharacterAdded:Wait()

		for i = 1,20 do 
			RunService.Heartbeat:Wait()
			if getRoot(Player.Character) then
				getRoot(Player.Character).Humanoid.RootPart.CFrame = Old
			end
		end
	else
		notify("Incompatible Exploit","Your exploit does not support this command (missing firetouchinterest)")
	end
end)

addcmd('split',{},function(args, speaker)
	if r15(speaker) then
		speaker.Character.UpperTorso.Waist:Destroy()
	else
		notify('R15 Required','This command requires the r15 rig type')
	end
end)

addcmd('nilchar',{},function(args, speaker)
	if speaker.Character ~= nil then
		speaker.Character.Parent = nil
	end
end)

addcmd('unnilchar',{'nonilchar'},function(args, speaker)
	if speaker.Character ~= nil then
		speaker.Character.Parent = workspace
	end
end)

addcmd('noroot',{'removeroot','rroot'},function(args, speaker)
	if speaker.Character ~= nil then
		local char = Players.LocalPlayer.Character
		char.Parent = nil
		char.Humanoid.RootPart:Destroy()
		char.Parent = workspace
	end
end)

addcmd('replaceroot',{'replacerootpart'},function(args, speaker)
	if speaker.Character ~= nil and getRoot(speaker.Character) then
		local Char = speaker.Character
		local OldParent = Char.Parent
		local HRP = Char and getRoot(Char)
		local OldPos = HRP.CFrame
		Char.Parent = game
		local HRP1 = HRP:Clone()
		HRP1.Parent = Char
		HRP = HRP:Destroy()
		HRP1.CFrame = OldPos
		Char.Parent = OldParent
	end
end)

addcmd('clearcharappearance',{'clearchar','clrchar'},function(args, speaker)
	speaker:ClearCharacterAppearance()
end)

addcmd('equiptools',{},function(args, speaker)
	for i,v in pairs(speaker:FindFirstChildOfClass("Backpack"):GetChildren()) do
		if v:IsA("Tool") or v:IsA("HopperBin") then
			v.Parent = speaker.Character
		end
	end
end)

addcmd('unequiptools',{},function(args, speaker)
	speaker.Character:FindFirstChildOfClass('Humanoid'):UnequipTools()
end)

local function GetHandleTools(p)
	p = p or Players.LocalPlayer
	local r = {}
	for _, v in ipairs(p.Character and p.Character:GetChildren() or {}) do
		if v.IsA(v, "BackpackItem") and v.FindFirstChild(v, "Handle") then
			r[#r + 1] = v
		end
	end
	for _, v in ipairs(p.Backpack:GetChildren()) do
		if v.IsA(v, "BackpackItem") and v.FindFirstChild(v, "Handle") then
			r[#r + 1] = v
		end
	end
	return r
end
addcmd('dupetools', {'clonetools'}, function(args, speaker)
	local LOOP_NUM = tonumber(args[1]) or 1
	local OrigPos = speaker.Character.Humanoid.RootPart.Position
	local Tools, TempPos = {}, Vector3.new(math.random(-2e5, 2e5), 2e5, math.random(-2e5, 2e5))
	for i = 1, LOOP_NUM do
		local Human = speaker.Character:WaitForChild("Humanoid")
		wait(.1, Human.Parent:MoveTo(TempPos))
		Human.RootPart.Anchored = speaker:ClearCharacterAppearance(wait(.1)) or true
		local t = GetHandleTools(speaker)
		while #t > 0 do
			for _, v in ipairs(t) do
				task.spawn(function()
					for _ = 1, 25 do
						v.Parent = speaker.Character
						v.Handle.Anchored = true
					end
					for _ = 1, 5 do
						v.Parent = workspace
					end
					table.insert(Tools, v.Handle)
				end)
			end
			t = GetHandleTools(speaker)
		end
		wait(.1)
		speaker.Character = speaker.Character:Destroy()
		speaker.CharacterAdded:Wait():WaitForChild("Humanoid").Parent:MoveTo(LOOP_NUM == i and OrigPos or TempPos, wait(.1))
		if i == LOOP_NUM or i % 5 == 0 then
			local HRP = speaker.Character.Humanoid.RootPart
			if type(firetouchinterest) == "function" then
				for _, v in ipairs(Tools) do
					v.Anchored = not firetouchinterest(v, HRP, 1, firetouchinterest(v, HRP, 0)) and false or false
				end
			else
				for _, v in ipairs(Tools) do
					task.spawn(function()
						local x = v.CanCollide
						v.CanCollide = false
						v.Anchored = false
						for _ = 1, 10 do
							v.CFrame = HRP.CFrame
							wait()
						end
						v.CanCollide = x
					end)
				end
			end
			wait(.1)
			Tools = {}
		end
		TempPos = TempPos + Vector3.new(10, math.random(-5, 5), 0)
	end
end)

addcmd('touchinterests', {'touchinterest', 'firetouchinterests', 'firetouchinterest'}, function(args, speaker)
	local Root = getRoot(speaker.Character) or speaker.Character:FindFirstChildWhichIsA("BasePart")

	if not firetouchinterest then
		notify("Incompatible Exploit", "Your exploit does not support this command (missing firetouchinterest)")
		return
	end

	local function Touch(x)
		x = x.FindFirstAncestorWhichIsA(x, "Part")
		if x then
			return task.spawn(function()
				firetouchinterest(x, Root, 1, wait() and firetouchinterest(x, Root, 0))
			end)
		end
		x.CFrame = Root.CFrame
	end

	if args[1] then
		local name = getstring(1, args):lower()
		print(name..' -name')
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("TouchTransmitter") and v.Name:lower() == name or v.Parent.Name:lower() == name then
				Touch(v)
			end
		end
	else
		for _, v in ipairs(workspace:GetDescendants()) do
			if v.IsA(v, "TouchTransmitter") then
				Touch(v)
			end
		end
	end
end)

addcmd('fullbright',{'fb','fullbrightness'},function(args, speaker)
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.FogEnd = 100000
	Lighting.GlobalShadows = false
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end)

addcmd('loopfullbright',{'loopfb'},function(args, speaker)
	if brightLoop then
		brightLoop:Disconnect()
	end
	local function brightFunc()
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	end

	brightLoop = RunService.RenderStepped:Connect(brightFunc)
end)

addcmd('unloopfullbright',{'unloopfb'},function(args, speaker)
	if brightLoop then
		brightLoop:Disconnect()
	end
end)

addcmd('ambient',{},function(args, speaker)
	Lighting.Ambient = Color3.new(args[1],args[2],args[3])
	Lighting.OutdoorAmbient = Color3.new(args[1],args[2],args[3])
end)

addcmd('day',{},function(args, speaker)
	Lighting.ClockTime = 14
end)

addcmd('night',{},function(args, speaker)
	Lighting.ClockTime = 0
end)

addcmd('nofog',{},function(args, speaker)
	Lighting.FogEnd = 100000
	for i,v in pairs(Lighting:GetDescendants()) do
		if v:IsA("Atmosphere") then
			v:Destroy()
		end
	end
end)

addcmd('brightness',{},function(args, speaker)
	Lighting.Brightness = args[1]
end)

addcmd('globalshadows',{'gshadows'},function(args, speaker)
	Lighting.GlobalShadows = true
end)

addcmd('unglobalshadows',{'nogshadows','ungshadows','noglobalshadows'},function(args, speaker)
	Lighting.GlobalShadows = false
end)

origsettings = {abt = Lighting.Ambient, oabt = Lighting.OutdoorAmbient, brt = Lighting.Brightness, time = Lighting.ClockTime, fe = Lighting.FogEnd, fs = Lighting.FogStart, gs = Lighting.GlobalShadows}

addcmd('restorelighting',{'rlighting'},function(args, speaker)
	Lighting.Ambient = origsettings.abt
	Lighting.OutdoorAmbient = origsettings.oabt
	Lighting.Brightness = origsettings.brt
	Lighting.ClockTime = origsettings.time
	Lighting.FogEnd = origsettings.fe
	Lighting.FogStart = origsettings.fs
	Lighting.GlobalShadows = origsettings.gs
end)

addcmd('stun',{'platformstand'},function(args, speaker)
	speaker.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
end)

addcmd('unstun',{'nostun','unplatformstand','noplatformstand'},function(args, speaker)
	speaker.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
end)

addcmd('norotate',{'noautorotate'},function(args, speaker)
	speaker.Character:FindFirstChildOfClass('Humanoid').AutoRotate  = false
end)

addcmd('unnorotate',{'autorotate'},function(args, speaker)
	speaker.Character:FindFirstChildOfClass('Humanoid').AutoRotate  = true
end)

addcmd('enablestate',{},function(args, speaker)
	local x = args[1]
	if not tonumber(x) then
		local x = Enum.HumanoidStateType[args[1]]
	end
	speaker.Character:FindFirstChildOfClass("Humanoid"):SetStateEnabled(x, true)
end)

addcmd('disablestate',{},function(args, speaker)
	local x = args[1]
	if not tonumber(x) then
		local x = Enum.HumanoidStateType[args[1]]
	end
	speaker.Character:FindFirstChildOfClass("Humanoid"):SetStateEnabled(x, false)
end)

addcmd('drophats',{'drophat'},function(args, speaker)
	if speaker.Character then
		for _,v in pairs(speaker.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
			v.Parent = workspace
		end
	end
end)

addcmd('deletehats',{'nohats','rhats'},function(args, speaker)
	for i,v in next, speaker.Character:GetDescendants() do
		if v:IsA("Accessory") then
			for i,p in next, v:GetDescendants() do
				if p:IsA("Weld") then
					p:Destroy()
				end
			end
		end
	end
end)

addcmd('droptools',{'droptool'},function(args, speaker)
	for i,v in pairs(Players.LocalPlayer.Backpack:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = Players.LocalPlayer.Character
		end
	end
	wait()
	for i,v in pairs(Players.LocalPlayer.Character:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = workspace
		end
	end
end)

addcmd('droppabletools',{},function(args, speaker)
	if speaker.Character then
		for _,obj in pairs(speaker.Character:GetChildren()) do
			if obj:IsA("Tool") then
				obj.CanBeDropped = true
			end
		end
	end
	if speaker:FindFirstChildOfClass("Backpack") then
		for _,obj in pairs(speaker:FindFirstChildOfClass("Backpack"):GetChildren()) do
			if obj:IsA("Tool") then
				obj.CanBeDropped = true
			end
		end
	end
end)

local currentToolSize = ""
local currentGripPos = ""
addcmd('reach',{},function(args, speaker)
	execCmd('unreach')
	wait()
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Tool") then
			if args[1] then
				currentToolSize = v.Handle.Size
				currentGripPos = v.GripPos
				local a = Instance.new("SelectionBox")
				a.Name = "SelectionBoxCreated"
				a.Parent = v.Handle
				a.Adornee = v.Handle
				v.Handle.Massless = true
				v.Handle.Size = Vector3.new(0.5,0.5,args[1])
				v.GripPos = Vector3.new(0,0,0)
				speaker.Character:FindFirstChildOfClass('Humanoid'):UnequipTools()
			else
				currentToolSize = v.Handle.Size
				currentGripPos = v.GripPos
				local a = Instance.new("SelectionBox")
				a.Name = "SelectionBoxCreated"
				a.Parent = v.Handle
				a.Adornee = v.Handle
				v.Handle.Massless = true
				v.Handle.Size = Vector3.new(0.5,0.5,60)
				v.GripPos = Vector3.new(0,0,0)
				speaker.Character:FindFirstChildOfClass('Humanoid'):UnequipTools()
			end
		end
	end
end)

addcmd("boxreach", {}, function(args, speaker)
	execCmd("unreach")
	wait()
	for i, v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Tool") then
			local size = tonumber(args[1]) or 60
			currentToolSize = v.Handle.Size
			currentGripPos = v.GripPos
			local a = Instance.new("SelectionBox")
			a.Name = "SelectionBoxCreated"
			a.Parent = v.Handle
			a.Adornee = v.Handle
			v.Handle.Massless = true
			v.Handle.Size = Vector3.new(size, size, size)
			v.GripPos = Vector3.new(0, 0, 0)
			speaker.Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
		end
	end
end)

addcmd('unreach',{'noreach','unboxreach'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Tool") then
			v.Handle.Size = currentToolSize
			v.GripPos = currentGripPos
			v.Handle.SelectionBoxCreated:Destroy()
		end
	end
end)

addcmd('grippos',{},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Tool") then
			v.Parent = speaker:FindFirstChildOfClass("Backpack")
			v.GripPos = Vector3.new(args[1],args[2],args[3])
			v.Parent = speaker.Character
		end
	end
end)

addcmd('usetools', {}, function(args, speaker)
	local Backpack = speaker:FindFirstChildOfClass("Backpack")
	local amount = tonumber(args[1]) or 1
	local delay_ = tonumber(args[2]) or false
	for _, v in ipairs(Backpack:GetChildren()) do
		v.Parent = speaker.Character
		task.spawn(function()
			for _ = 1, amount do
				v:Activate()
				if delay_ then
					wait(delay_)
				end
			end
			v.Parent = Backpack
		end)
	end
end)

addcmd("logs", {}, function(args, speaker)
	logsEnabled = true
	jLogsEnabled = true
	Toggle.Text = "Enabled"
	Toggle_2.Text = "Enabled"
	logs:TweenPosition(UDim2.new(0, 0, 1, -265), "InOut", "Quart", 0.3, true, nil)
end)

addcmd("chatlogs", {"clogs"}, function(args, speaker)
	logsEnabled = true
	join.Visible = false
	chat.Visible = true
	table.remove(shade3, table.find(shade3, selectChat))
	table.remove(shade2, table.find(shade2, selectJoin))
	table.insert(shade2, selectChat)
	table.insert(shade3, selectJoin)
	selectJoin.BackgroundColor3 = currentShade3
	selectChat.BackgroundColor3 = currentShade2
	Toggle.Text = "Enabled"
	logs:TweenPosition(UDim2.new(0, 0, 1, -265), "InOut", "Quart", 0.3, true, nil)
end)

addcmd("joinlogs", {"jlogs"}, function(args, speaker)
	jLogsEnabled = true
	chat.Visible = false
	join.Visible = true	
	table.remove(shade3, table.find(shade3, selectJoin))
	table.remove(shade2, table.find(shade2, selectChat))
	table.insert(shade2, selectJoin)
	table.insert(shade3, selectChat)
	selectChat.BackgroundColor3 = currentShade3
	selectJoin.BackgroundColor3 = currentShade2
	Toggle_2.Text = "Enabled"
	logs:TweenPosition(UDim2.new(0, 0, 1, -265), "InOut", "Quart", 0.3, true, nil)
end)

addcmd("chatlogswebhook", {"logswebhook"}, function(args, speaker)
	if not httprequest then
		return notify("Incompatible Exploit", "Your exploit does not support this command (missing request)")
	end
	logsWebhook = args[1] or nil
	updatesaves()
end)

flinging = false
addcmd('fling',{},function(args, speaker)
	flinging = false
	for _, child in pairs(speaker.Character:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
		end
	end
	execCmd('noclip')
	wait(.1)
	local bambam = Instance.new("BodyAngularVelocity")
	bambam.Name = randomString()
	bambam.Parent = getRoot(speaker.Character)
	bambam.AngularVelocity = Vector3.new(0,99999,0)
	bambam.MaxTorque = Vector3.new(0,math.huge,0)
	bambam.P = math.huge
	local Char = speaker.Character:GetChildren()
	for i, v in next, Char do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Massless = true
			v.Velocity = Vector3.new(0, 0, 0)
		end
	end
	flinging = true
	local function flingDiedF()
		execCmd('unfling')
	end
	flingDied = speaker.Character:FindFirstChildOfClass('Humanoid').Died:Connect(flingDiedF)
	repeat
		bambam.AngularVelocity = Vector3.new(0,99999,0)
		wait(.2)
		bambam.AngularVelocity = Vector3.new(0,0,0)
		wait(.1)
	until flinging == false
end)

addcmd('unfling',{'nofling'},function(args, speaker)
	execCmd('clip')
	if flingDied then
		flingDied:Disconnect()
	end
	flinging = false
	wait(.1)
	local speakerChar = speaker.Character
	if not speakerChar or not getRoot(speakerChar) then return end
	for i,v in pairs(getRoot(speakerChar):GetChildren()) do
		if v.ClassName == 'BodyAngularVelocity' then
			v:Destroy()
		end
	end
	for _, child in pairs(speakerChar:GetDescendants()) do
		if child.ClassName == "Part" or child.ClassName == "MeshPart" then
			child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
		end
	end
end)

addcmd('togglefling',{},function(args, speaker)
	if flinging then
		execCmd('unfling')
	else
		execCmd('fling')
	end
end)

addcmd("flyfling", {}, function(args, speaker)
	execCmd("unvehiclefly\\unwalkfling")
	task.wait()
	vehicleflyspeed = tonumber(args[1]) or vehicleflyspeed
	execCmd("vehiclefly\\walkfling")
end)

addcmd("unflyfling", {}, function(args, speaker)
	execCmd("unvehiclefly\\unwalkfling\\breakvelocity")
end)

addcmd("toggleflyfling", {}, function(args, speaker)
	execCmd(flinging and "unflyfling" or "flyfling")
end)

walkflinging = false
addcmd("walkfling", {"jbfling", "jailbreakfling", "jb fling", "jailbreak fling"}, function(args, speaker)
	execCmd("unwalkfling")
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			execCmd("unwalkfling")
		end)
	end

	execCmd("noclip nonotify")
	walkflinging = true
	repeat RunService.Heartbeat:Wait()
		local character = speaker.Character
		local root = getRoot(character)
		local vel, movel = nil, 0.1

		while not (character and character.Parent and root and root.Parent) do
			RunService.Heartbeat:Wait()
			character = speaker.Character
			root = getRoot(character)
		end

		vel = root.Velocity
		root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)

		RunService.RenderStepped:Wait()
		if character and character.Parent and root and root.Parent then
			root.Velocity = vel
		end

		RunService.Stepped:Wait()
		if character and character.Parent and root and root.Parent then
			root.Velocity = vel + Vector3.new(0, movel, 0)
			movel = movel * -1
		end
	until walkflinging == false
end)

addcmd("unwalkfling", {"nowalkfling"}, function(args, speaker)
	walkflinging = false
	execCmd("unnoclip nonotify")
end)

addcmd("togglewalkfling", {}, function(args, speaker)
	execCmd(walkflinging and "unwalkfling" or "walkfling")
end)

addcmd('invisfling',{},function(args, speaker)
	local ch = speaker.Character
	ch:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	local prt=Instance.new("Model")
	prt.Parent = speaker.Character
	local z1 = Instance.new("Part")
	z1.Name="Torso"
	z1.CanCollide = false
	z1.Anchored = true
	local z2 = Instance.new("Part")
	z2.Name="Head"
	z2.Parent = prt
	z2.Anchored = true
	z2.CanCollide = false
	local z3 =Instance.new("Humanoid")
	z3.Name="Humanoid"
	z3.Parent = prt
	z1.Position = Vector3.new(0,9999,0)
	speaker.Character=prt
	wait(3)
	speaker.Character=ch
	wait(3)
	local Hum = Instance.new("Humanoid")
	z2:Clone()
	Hum.Parent = speaker.Character
	local root =  getRoot(speaker.Character)
	for i,v in pairs(speaker.Character:GetChildren()) do
		if v ~= root and  v.Name ~= "Humanoid" then
			v:Destroy()
		end
	end
	root.Transparency = 0
	root.Color = Color3.new(1, 1, 1)
	local invisflingStepped
	invisflingStepped = RunService.Stepped:Connect(function()
		if speaker.Character and getRoot(speaker.Character) then
			getRoot(speaker.Character).CanCollide = false
		else
			invisflingStepped:Disconnect()
		end
	end)
	sFLY()
	workspace.CurrentCamera.CameraSubject = root
	local bambam = Instance.new("BodyThrust")
	bambam.Parent = getRoot(speaker.Character)
	bambam.Force = Vector3.new(99999,99999*10,99999)
	bambam.Location = getRoot(speaker.Character).Position
end)

addcmd("antifling", {}, function(args, speaker)
	if antifling then
		antifling:Disconnect()
		antifling = nil
	end
	antifling = RunService.Stepped:Connect(function()
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= speaker and player.Character then
				for _, v in pairs(player.Character:GetDescendants()) do
					if v:IsA("BasePart") then
						v.CanCollide = false
					end
				end
			end
		end
	end)
end)

addcmd("unantifling", {}, function(args, speaker)
	if antifling then
		antifling:Disconnect()
		antifling = nil
	end
end)

addcmd("toggleantifling", {}, function(args, speaker)
	execCmd(antifling and "unantifling" or "antifling")
end)

function attach(speaker,target)
	if tools(speaker) then
		local char = speaker.Character
		local tchar = target.Character
		local hum = speaker.Character:FindFirstChildOfClass("Humanoid")
		local hrp = getRoot(speaker.Character)
		local hrp2 = getRoot(target.Character)
		hum.Name = "1"
		local newHum = hum:Clone()
		newHum.Parent = char
		newHum.Name = "Humanoid"
		wait()
		hum:Destroy()
		workspace.CurrentCamera.CameraSubject = char
		newHum.DisplayDistanceType = "None"
		local tool = speaker:FindFirstChildOfClass("Backpack"):FindFirstChildOfClass("Tool") or speaker.Character:FindFirstChildOfClass("Tool")
		tool.Parent = char
		hrp.CFrame = hrp2.CFrame * CFrame.new(0, 0, 0) * CFrame.new(math.random(-100, 100)/200,math.random(-100, 100)/200,math.random(-100, 100)/200)
		local n = 0
		repeat
			wait(.1)
			n = n + 1
			hrp.CFrame = hrp2.CFrame
		until (tool.Parent ~= char or not hrp or not hrp2 or not hrp.Parent or not hrp2.Parent or n > 250) and n > 2
	else
		notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end

function kill(speaker,target,fast)
	if tools(speaker) then
		if target ~= nil then
			local NormPos = getRoot(speaker.Character).CFrame
			if not fast then
				refresh(speaker)
				wait()
				repeat wait() until speaker.Character ~= nil and getRoot(speaker.Character)
				wait(0.3)
			end
			local hrp = getRoot(speaker.Character)
			attach(speaker,target)
			repeat
				wait()
				hrp.CFrame = CFrame.new(999999, workspace.FallenPartsDestroyHeight + 5,999999)
			until not getRoot(target.Character) or not getRoot(speaker.Character)
			local char = speaker.CharacterAdded:Wait()
			local humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			while not humanoid:IsA("Humanoid") do
				humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			end
			humanoid.RootPart.CFrame = NormPos
		end
	else
		-- Toolless Fling Fallback
		if target ~= nil and target.Character then
			local char = speaker.Character
			local hrp = getRoot(char)
			local targetChar = target.Character
			local targetHRP = getRoot(targetChar)
			
			if not hrp or not targetHRP then return end
			
			notify("Flinging (No Tool)", "Flinging " .. target.Name .. " without a tool...")
			execCmd('noclip')
			wait(.1)
			local originalCFrame = hrp.CFrame
			local bt = Instance.new("BodyThrust", hrp)
			bt.Force = Vector3.new(99999, 99999, 99999)
			local bav = Instance.new("BodyAngularVelocity", hrp)
			bav.AngularVelocity = Vector3.new(0, 99999, 0)
			bav.MaxTorque = Vector3.new(9e9, 9e9, 9e9)

			-- Character Physics Setup
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Massless = true
					part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
					part.CanCollide = false
				end
			end
			hrp.CanCollide = true

			local startTime = tick()
			local flingConn
			flingConn = RunService.Heartbeat:Connect(function()
				local tChar = target.Character
				local tHrp = tChar and getRoot(tChar)
				
				if not tHrp or not hrp.Parent or (tick() - startTime > 3.5) then -- Increased limit slightly
					flingConn:Disconnect()
					if bt then bt:Destroy() end
					if bav then bav:Destroy() end
					
					-- Reset Physics
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Massless = false
							part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
							part.CanCollide = true
						end
					end
					
					local stabilizeStart = tick()
					local stabilizeConn
					stabilizeConn = RunService.Heartbeat:Connect(function()
						if tick() - stabilizeStart > 1.5 or not hrp.Parent then
							stabilizeConn:Disconnect()
							return
						end
						hrp.Velocity = Vector3.new(0,0,0)
						hrp.RotVelocity = Vector3.new(0,0,0)
						hrp.CFrame = originalCFrame
					end)
					return
				end
				
				local success, err = pcall(function()
					local ping = 0.1
					pcall(function()
						ping = statsService.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
					end)
					
					local targetVelocity = tHrp.AssemblyLinearVelocity or tHrp.Velocity or Vector3.new(0,0,0)
					local leadFactor = 1.45 -- Balanced lead
					local prediction = targetVelocity * (ping * leadFactor + (1/50))
					
					-- Prevent extreme spikes
					if prediction.Magnitude > 15 then
						prediction = prediction.Unit * 15
					end
					
					local finalPos = tHrp.Position + prediction + Vector3.new(0, -0.5, 0) -- Slight low-angle hit
					
					-- High-performance physics impulse (Safe but deadly)
					local chaos = Vector3.new(1500000, 1500000, 1500000)
					hrp.CFrame = CFrame.new(finalPos) * CFrame.Angles(math.rad(math.random(0,360)),math.rad(math.random(0,360)),math.rad(math.random(0,360)))
					hrp.Velocity = chaos
					hrp.RotVelocity = chaos
				end)
				
				if not success then
					flingConn:Disconnect()
				end
			end)
		end
	end
end

addcmd("handlekill", {"hkill"}, function(args, speaker)
	if not firetouchinterest then
		return notify("Incompatible Exploit", "Your exploit does not support this command (missing firetouchinterest)")
	end
	if not speaker.Character then return end
	local tool = speaker.Character:FindFirstChildWhichIsA("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	if not handle then
		return notify("Handle Kill", "You need to hold a \"Tool\" that does damage on touch. For example a common Sword tool.")
	end
	local range = tonumber(args[2]) or math.huge
	if range ~= math.huge then notify("Handle Kill", ("Started!\nRadius: %s"):format(tostring(range):upper())) end

	while task.wait() and speaker.Character and tool.Parent and tool.Parent == speaker.Character do
		for _, plr in next, getPlayer(args[1], speaker) do
			plr = Players[plr]
			if plr ~= speaker and plr.Character then
				local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
				local root = hum and getRoot(plr.Character)

				if root and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead and speaker:DistanceFromCharacter(root.Position) <= range then
					firetouchinterest(handle, root, 1)
					firetouchinterest(handle, root, 0)
				end
			end
		end
	end

	notify("Handle Kill", "Stopped!")
end)

tpwalkStack = 0
addcmd("teleportwalk", {"tpwalk"}, function(args, speaker)
    pcall(function() tpwalking:Disconnect() end)

    local character = speaker.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local speed = (args[1] and isNumber(args[1])) and tonumber(args[1]) or 1

    if parseBoolean(args[2]) then
        tpwalkStack = tpwalkStack + speed
    end

    tpwalking = RunService.Heartbeat:Connect(function(delta)
        if not (character and humanoid and humanoid.Parent) then
            tpwalking:Disconnect()
            return
        end

        if humanoid.MoveDirection.Magnitude > 0 then
            character:TranslateBy(humanoid.MoveDirection * (speed + tpwalkStack) * delta * 10)
        end
    end)
end)

addcmd("unteleportwalk", {"untpwalk"}, function(args, speaker)
    tpwalkStack = 0
    tpwalking:Disconnect()
end)

function bring(speaker,target,fast)
	if tools(speaker) then
		if target ~= nil then
			local NormPos = getRoot(speaker.Character).CFrame
			if not fast then
				refresh(speaker)
				wait()
				repeat wait() until speaker.Character ~= nil and getRoot(speaker.Character)
				wait(0.3)
			end
			local hrp = getRoot(speaker.Character)
			attach(speaker,target)
			repeat
				wait()
				hrp.CFrame = NormPos
			until not getRoot(target.Character) or not getRoot(speaker.Character)
			local char = speaker.CharacterAdded:Wait()
			local humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			while not humanoid:IsA("Humanoid") do
				humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			end
			humanoid.RootPart.CFrame = NormPos
		end
	else
		notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end

function teleport(speaker,target,target2,fast)
	if tools(speaker) then
		if target ~= nil then
			local NormPos = getRoot(speaker.Character).CFrame
			if not fast then
				refresh(speaker)
				wait()
				repeat wait() until speaker.Character ~= nil and getRoot(speaker.Character)
				wait(0.3)
			end
			local hrp = getRoot(speaker.Character)
			local hrp2 = getRoot(target2.Character)
			attach(speaker,target)
			repeat
				wait()
				hrp.CFrame = hrp2.CFrame
			until not getRoot(target.Character) or not getRoot(speaker.Character)
			wait(1)
			local char = speaker.CharacterAdded:Wait()
			local humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			while not humanoid:IsA("Humanoid") do
				humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			end
			humanoid.RootPart.CFrame = NormPos
		end
	else
		notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end

addcmd('spin',{},function(args, speaker)
	local spinSpeed = 20
	if args[1] and isNumber(args[1]) then
		spinSpeed = args[1]
	end
	for i,v in pairs(getRoot(speaker.Character):GetChildren()) do
		if v.Name == "Spinning" then
			v:Destroy()
		end
	end
	local Spin = Instance.new("BodyAngularVelocity")
	Spin.Name = "Spinning"
	Spin.Parent = getRoot(speaker.Character)
	Spin.MaxTorque = Vector3.new(0, math.huge, 0)
	Spin.AngularVelocity = Vector3.new(0,spinSpeed,0)
end)

addcmd('unspin',{},function(args, speaker)
	for i,v in pairs(getRoot(speaker.Character):GetChildren()) do
		if v.Name == "Spinning" then
			v:Destroy()
		end
	end
end)

xrayEnabled = false
function xray()
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") and not v.Parent.Parent:FindFirstChildWhichIsA("Humanoid") then
			v.LocalTransparencyModifier = xrayEnabled and 0.5 or 0
		end
	end
end

addcmd("xray", {}, function(args, speaker)
	xrayEnabled = true
	xray()
end)

addcmd("unxray", {"noxray"}, function(args, speaker)
	xrayEnabled = false
	xray()
end)

addcmd("togglexray", {}, function(args, speaker)
	xrayEnabled = not xrayEnabled
	xray()
end)

addcmd("loopxray", {}, function(args, speaker)
	pcall(function() xrayLoop:Disconnect() end)
	xrayLoop = RunService.RenderStepped:Connect(function()
		xrayEnabled = true
		xray()
	end)
end)

addcmd("unloopxray", {}, function(args, speaker)
	pcall(function() xrayLoop:Disconnect() end)
	xrayEnabled = false
	xray()
end)

local walltpTouch = nil
addcmd('walltp',{},function(args, speaker)
	local torso
	if r15(speaker) then
		torso = speaker.Character.UpperTorso
	else
		torso = speaker.Character.Torso
	end
	local function touchedFunc(hit)
		local Root = getRoot(speaker.Character)
		if hit:IsA("BasePart") and hit.Position.Y > Root.Position.Y - speaker.Character:FindFirstChildOfClass('Humanoid').HipHeight then
			local hitP = getRoot(hit.Parent)
			if hitP ~= nil then
				Root.CFrame = hit.CFrame * CFrame.new(Root.CFrame.lookVector.X,hitP.Size.Z/2 + speaker.Character:FindFirstChildOfClass('Humanoid').HipHeight,Root.CFrame.lookVector.Z)
			elseif hitP == nil then
				Root.CFrame = hit.CFrame * CFrame.new(Root.CFrame.lookVector.X,hit.Size.Y/2 + speaker.Character:FindFirstChildOfClass('Humanoid').HipHeight,Root.CFrame.lookVector.Z)
			end
		end
	end
	walltpTouch = torso.Touched:Connect(touchedFunc)
end)

addcmd('unwalltp',{'nowalltp'},function(args, speaker)
	if walltpTouch then
		walltpTouch:Disconnect()
	end
end)

autoclicking = false
addcmd('autoclick',{},function(args, speaker)
	if mouse1press and mouse1release then
		execCmd('unautoclick')
		wait()
		local clickDelay = 0.1
		local releaseDelay = 0.1
		if args[1] and isNumber(args[1]) then clickDelay = args[1] end
		if args[2] and isNumber(args[2]) then releaseDelay = args[2] end
		autoclicking = true
		cancelAutoClick = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
			if not gameProcessedEvent then
				if (input.KeyCode == Enum.KeyCode.Backspace and UserInputService:IsKeyDown(Enum.KeyCode.Equals)) or (input.KeyCode == Enum.KeyCode.Equals and UserInputService:IsKeyDown(Enum.KeyCode.Backspace)) then
					autoclicking = false
					cancelAutoClick:Disconnect()
				end
			end
		end)
		notify('Auto Clicker',"Press [backspace] and [=] at the same time to stop")
		repeat wait(clickDelay)
			mouse1press()
			wait(releaseDelay)
			mouse1release()
		until autoclicking == false
	else
		notify('Auto Clicker',"Your exploit doesn't have the ability to use the autoclick")
	end
end)

addcmd('unautoclick',{'noautoclick'},function(args, speaker)
	autoclicking = false
	if cancelAutoClick then cancelAutoClick:Disconnect() end
end)

addcmd('mousesensitivity',{'ms'},function(args, speaker)
	UserInputService.MouseDeltaSensitivity = args[1]
end)

local nameBox = nil
local nbSelection = nil
addcmd('hovername',{},function(args, speaker)
	execCmd('unhovername')
	wait()
	nameBox = Instance.new("TextLabel")
	nameBox.Name = randomString()
	nameBox.Parent = ScaledHolder
	nameBox.BackgroundTransparency = 1
	nameBox.Size = UDim2.new(0,200,0,30)
	nameBox.Font = Enum.Font.Code
	nameBox.TextSize = 16
	nameBox.Text = ""
	nameBox.TextColor3 = Color3.new(1, 1, 1)
	nameBox.TextStrokeTransparency = 0
	nameBox.TextXAlignment = Enum.TextXAlignment.Left
	nameBox.ZIndex = 10
	nbSelection = Instance.new('SelectionBox')
	nbSelection.Name = randomString()
	nbSelection.LineThickness = 0.03
	nbSelection.Color3 = Color3.new(1, 1, 1)
	local function updateNameBox()
		local t
		local target = IYMouse.Target

		if target then
			local humanoid = target.Parent:FindFirstChildOfClass("Humanoid") or target.Parent.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				t = humanoid.Parent
			end
		end

		if t ~= nil then
			local x = IYMouse.X
			local y = IYMouse.Y
			local xP
			local yP
			if IYMouse.X > 200 then
				xP = x - 205
				nameBox.TextXAlignment = Enum.TextXAlignment.Right
			else
				xP = x + 25
				nameBox.TextXAlignment = Enum.TextXAlignment.Left
			end
			nameBox.Position = UDim2.new(0, xP, 0, y)
			nameBox.Text = t.Name
			nameBox.Visible = true
			nbSelection.Parent = t
			nbSelection.Adornee = t
		else
			nameBox.Visible = false
			nbSelection.Parent = nil
			nbSelection.Adornee = nil
		end
	end
	nbUpdateFunc = IYMouse.Move:Connect(updateNameBox)
end)

addcmd('unhovername',{'nohovername'},function(args, speaker)
	if nbUpdateFunc then
		nbUpdateFunc:Disconnect()
		nameBox:Destroy()
		nbSelection:Destroy()
	end
end)

addcmd('headsize',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		if Players[v] ~= speaker and Players[v].Character:FindFirstChild('Head') then
			local sizeArg = tonumber(args[2])
			local Size = Vector3.new(sizeArg,sizeArg,sizeArg)
			local Head = Players[v].Character:FindFirstChild('Head')
			if Head:IsA("BasePart") then
				Head.CanCollide = false
				if not args[2] or sizeArg == 1 then
					Head.Size = Vector3.new(2,1,1)
				else
					Head.Size = Size
				end
			end
		end
	end
end)

addcmd('hitbox',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local transparency = args[3] and tonumber(args[3]) or 0.4
	for i,v in pairs(players) do
		if Players[v] ~= speaker and getRoot(Players[v].Character) then
			local sizeArg = tonumber(args[2])
			local Size = Vector3.new(sizeArg,sizeArg,sizeArg)
			local Root = getRoot(Players[v].Character)
			if Root:IsA("BasePart") then
				Root.CanCollide = false
				if not args[2] or sizeArg == 1 then
					Root.Size = Vector3.new(2,1,1)
					Root.Transparency = transparency
				else
					Root.Size = Size
					Root.Transparency = transparency
				end
			end
		end
	end
end)

addcmd('stareat',{'stare'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		if stareLoop then
			stareLoop:Disconnect()
		end
		if not getRoot(Players.LocalPlayer.Character) and getRoot(Players[v].Character) then return end
		local function stareFunc()
			if Players.LocalPlayer.Character.PrimaryPart and Players:FindFirstChild(v) and Players[v].Character ~= nil and getRoot(Players[v].Character) then
				local chrPos=Players.LocalPlayer.Character.PrimaryPart.Position
				local tPos=getRoot(Players[v].Character).Position
				local modTPos=Vector3.new(tPos.X,chrPos.Y,tPos.Z)
				local newCF=CFrame.new(chrPos,modTPos)
				Players.LocalPlayer.Character:SetPrimaryPartCFrame(newCF)
			elseif not Players:FindFirstChild(v) then
				stareLoop:Disconnect()
			end
		end

		stareLoop = RunService.RenderStepped:Connect(stareFunc)
	end
end)

addcmd('unstareat',{'unstare','nostare','nostareat'},function(args, speaker)
	if stareLoop then
		stareLoop:Disconnect()
	end
end)

RolewatchData = {Group = 0, Role = "", Leave = false}
RolewatchConnection = Players.PlayerAdded:Connect(function(player)
	if RolewatchData.Group == 0 then return end
	if player:IsInGroup(RolewatchData.Group) then
		if tostring(player:GetRoleInGroup(RolewatchData.Group)):lower() == RolewatchData.Role:lower() then
			if RolewatchData.Leave == true then
				Players.LocalPlayer:Kick("\n\nRolewatch\nPlayer \"" .. tostring(player.Name) .. "\" has joined with the Role \"" .. RolewatchData.Role .. "\"\n")
			else
				notify("Rolewatch", "Player \"" .. tostring(player.Name) .. "\" has joined with the Role \"" .. RolewatchData.Role .. "\"")
			end
		end
	end
end)

addcmd("rolewatch", {}, function(args, speaker)
	local groupId = tonumber(args[1] or 0)
	local roleName = args[2] and tostring(getstring(2, args))
	if groupId and roleName then
		RolewatchData.Group = groupId
		RolewatchData.Role = roleName
		notify("Rolewatch", "Watching Group ID \"" .. tostring(groupId) .. "\" for Role \"" .. roleName .. "\"")
	end
end)

addcmd("rolewatchstop", {}, function(args, speaker)
	RolewatchData.Group = 0
	RolewatchData.Role = ""
	RolewatchData.Leave = false
	notify("Rolewatch", "Disabled")
end)

addcmd("rolewatchleave", {"unrolewatch"}, function(args, speaker)
	RolewatchData.Leave = not RolewatchData.Leave
	notify("Rolewatch", RolewatchData.Leave and "Leave has been Enabled" or "Leave has been Disabled")
end)

staffRoles = {"mod", "admin", "staff", "dev", "founder", "owner", "supervis", "manager", "management", "executive", "president", "chairman", "chairwoman", "chairperson", "director"}

getStaffRole = function(player)
	local playerRole = player:GetRoleInGroup(game.CreatorId)
	local result = {Role = playerRole, Staff = false}
	if player:IsInGroup(1200769) then
		result.Role = "Roblox Employee"
		result.Staff = true
	end
	for _, role in pairs(staffRoles) do
		if string.find(string.lower(playerRole), role) then
			result.Staff = true
		end
	end
	return result
end

addcmd("staffwatch", {}, function(args, speaker)
	if staffwatchjoin then
		staffwatchjoin:Disconnect()
	end
	if game.CreatorType == Enum.CreatorType.Group then
		local found = {}
		staffwatchjoin = Players.PlayerAdded:Connect(function(player)
			local result = getStaffRole(player)
			if result.Staff then
				notify("Staffwatch", formatUsername(player) .. " is a " .. result.Role)
			end
		end)
		for _, player in pairs(Players:GetPlayers()) do
			local result = getStaffRole(player)
			if result.Staff then
				table.insert(found, formatUsername(player) .. " is a " .. result.Role)
			end
		end
		if #found > 0 then
			notify("Staffwatch", table.concat(found, ",\n"))
		else
			notify("Staffwatch", "Enabled")
		end
	else
		notify("Staffwatch", "Game is not owned by a Group")
	end
end)

addcmd("unstaffwatch", {}, function(args, speaker)
	if staffwatchjoin then
		staffwatchjoin:Disconnect()
	end
	notify("Staffwatch", "Disabled")
end)

local function playerGroups()
    local players = Players:GetPlayers()
    local graph = {}
    local seen = {}
    local groups = {}

    for _, p in ipairs(players) do
        graph[p] = {}
    end

    for i = 1, #players do
        for j = i + 1, #players do
            local p1 = players[i]
            local p2 = players[j]

            local success, result = pcall(function()
                return p1:IsFriendsWithAsync(p2.UserId)
            end)

            if success and result then
                table.insert(graph[p1], p2)
                table.insert(graph[p2], p1)
            end
        end
    end

    local function dfs(player, group)
        seen[player] = true
        table.insert(group, player)

        for _, possible in ipairs(graph[player]) do
            if not seen[possible] then
                dfs(possible, group)
            end
        end
    end

    for _, p in ipairs(players) do
        if not seen[p] then
            local group = {}
            dfs(p, group)
            table.insert(groups, group)
        end
    end

    return groups
end

addcmd("findfriendgroups", {}, function(args, speaker)
    notify("Checking Players", "This might take a while (slow function)")

    local groups = playerGroups()
    local playerList = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)

    local result = ""
    local index = 1
    local found = 0

    for _, group in ipairs(groups) do
        if #group == 1 then continue end
        local names = {}
        for _, player in ipairs(group) do
            table.insert(names, playerList and player.DisplayName or player.Name)
        end
        result = result .. index .. ". " .. table.concat(names, ", ") .. "\n"
        index = index + 1
        found = found + 1
    end

    createPopup("Friend Groups", found == 0 and "None" or result)
end)

addcmd('removeterrain',{'rterrain','noterrain'},function(args, speaker)
	workspace:FindFirstChildOfClass('Terrain'):Clear()
end)

addcmd('clearnilinstances',{'nonilinstances','cni'},function(args, speaker)
	if getnilinstances then
		for i,v in pairs(getnilinstances()) do
			v:Destroy()
		end
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing getnilinstances)')
	end
end)

addcmd('destroyheight',{'dh'},function(args, speaker)
	local dh = args[1] or -500
	if isNumber(dh) then
		workspace.FallenPartsDestroyHeight = dh
	end
end)

OrgDestroyHeight = workspace.FallenPartsDestroyHeight
addcmd("antivoid", {}, function(args, speaker)
	execCmd("unantivoid nonotify")
	task.wait()
	antivoidloop = RunService.Stepped:Connect(function()
		local root = getRoot(speaker.Character)
		if root and root.Position.Y <= OrgDestroyHeight + 25 then
			root.Velocity = root.Velocity + Vector3.new(0, 250, 0)
		end
	end)
	if args[1] ~= "nonotify" then notify("antivoid", "Enabled") end
end)

addcmd("unantivoid", {"noantivoid"}, function(args, speaker)
	pcall(function() antivoidloop:Disconnect() end)
	antivoidloop = nil
	if args[1] ~= "nonotify" then notify("antivoid", "Disabled") end
end)

antivoidWasEnabled = false
addcmd("fakeout", {}, function(args, speaker)
	local root = getRoot(speaker.Character)
	local oldpos = root.CFrame
	if antivoidloop then
		execCmd("unantivoid nonotify")
		antivoidWasEnabled = true
	end
	workspace.FallenPartsDestroyHeight = 0/1/0
	root.CFrame = CFrame.new(Vector3.new(0, OrgDestroyHeight - 25, 0))
	task.wait(1)
	root.CFrame = oldpos
	workspace.FallenPartsDestroyHeight = OrgDestroyHeight
	if antivoidWasEnabled then
		execCmd("antivoid nonotify")
		antivoidWasEnabled = false
	end
end)

addcmd("trip", {}, function(args, speaker)
	local humanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
	local root = speaker.Character and getRoot(speaker.Character)
	if humanoid and root then
		humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
		root.Velocity = root.CFrame.LookVector * 30
	end
end)

addcmd("removeads", {"adblock"}, function(args, speaker)
	while wait() do
		pcall(function()
			for i, v in pairs(workspace:GetDescendants()) do
				if v:IsA("PackageLink") then
					if v.Parent:FindFirstChild("ADpart") then
						v.Parent:Destroy()
					end
					if v.Parent:FindFirstChild("AdGuiAdornee") then
						v.Parent.Parent:Destroy()
					end
				end
			end
		end)
	end
end)

addcmd("scare", {"spook"}, function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local oldpos = nil

	for _, v in pairs(players) do
		local root = speaker.Character and getRoot(speaker.Character)
		local target = Players[v]
		local targetRoot = target and target.Character and getRoot(target.Character)

		if root and targetRoot and target ~= speaker then
			oldpos = root.CFrame
			root.CFrame = targetRoot.CFrame + targetRoot.CFrame.lookVector * 2
			root.CFrame = CFrame.new(root.Position, targetRoot.Position)
			task.wait(0.5)
			root.CFrame = oldpos
		end
	end
end)

addcmd("alignmentkeys", {}, function(args, speaker)
	alignmentKeys = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Comma then workspace.CurrentCamera:PanUnits(-1) end
		if input.KeyCode == Enum.KeyCode.Period then workspace.CurrentCamera:PanUnits(1) end
	end)
	alignmentKeysEmotes = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end)

addcmd("unalignmentkeys", {"noalignmentkeys"}, function(args, speaker)
	if type(alignmentKeysEmotes) == "boolean" then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, alignmentKeysEmotes)
	end
	alignmentKeys:Disconnect()
end)

addcmd("ctrllock", {}, function(args, speaker)
	local mouseLockController = speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("MouseLockController")
	local boundKeys = mouseLockController:FindFirstChild("BoundKeys")

	if boundKeys then
		boundKeys.Value = "LeftControl"
	else
		boundKeys = Instance.new("StringValue")
		boundKeys.Name = "BoundKeys"
		boundKeys.Value = "LeftControl"
		boundKeys.Parent = mouseLockController
	end
end)

addcmd("unctrllock", {}, function(args, speaker)
	local mouseLockController = speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("MouseLockController")
	local boundKeys = mouseLockController:FindFirstChild("BoundKeys")

	if boundKeys then
		boundKeys.Value = "LeftShift"
	else
		boundKeys = Instance.new("StringValue")
		boundKeys.Name = "BoundKeys"
		boundKeys.Value = "LeftShift"
		boundKeys.Parent = mouseLockController
	end
end)

addcmd("listento", {}, function(args, speaker)
	execCmd("unlistento")
	if not args[1] then return end

	local player = Players:FindFirstChild(getPlayer(args[1], speaker)[1])
	local root = player and player.Character and getRoot(player.Character)

	if root then
		SoundService:SetListener(Enum.ListenerType.ObjectPosition, root)
		listentoChar = player.CharacterAdded:Connect(function()
			repeat task.wait() until Players[player.Name].Character ~= nil and getRoot(Players[player.Name].Character)
			SoundService:SetListener(Enum.ListenerType.ObjectPosition, getRoot(Players[player.Name].Character))
		end)
	end
end)

addcmd("unlistento", {}, function(args, speaker)
	SoundService:SetListener(Enum.ListenerType.Camera)
	listentoChar:Disconnect()
end)

addcmd("jerk", {}, function(args, speaker)
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	local backpack = speaker:FindFirstChildWhichIsA("Backpack")
	if not humanoid or not backpack then return end

	local tool = Instance.new("Tool")
	tool.Name = "Jerk Off"
	tool.ToolTip = "in the stripped club. straight up \"jorking it\" . and by \"it\" , haha, well. let's justr say. My peanits."
	tool.RequiresHandle = false
	tool.Parent = backpack

	local jorkin = false
	local track = nil

	local function stopTomfoolery()
		jorkin = false
		if track then
			track:Stop()
			track = nil
		end
	end

	tool.Equipped:Connect(function() jorkin = true end)
	tool.Unequipped:Connect(stopTomfoolery)
	humanoid.Died:Connect(stopTomfoolery)

	while task.wait() do
		if not jorkin then continue end

		local isR15 = r15(speaker)
		if not track then
			local anim = Instance.new("Animation")
			anim.AnimationId = not isR15 and "rbxassetid://72042024" or "rbxassetid://698251653"
			track = humanoid:LoadAnimation(anim)
		end

		track:Play()
		track:AdjustSpeed(isR15 and 0.7 or 0.65)
		track.TimePosition = 0.6
		task.wait(0.1)
		while track and track.TimePosition < (not isR15 and 0.65 or 0.7) do task.wait(0.1) end
		if track then
			track:Stop()
			track = nil
		end
	end
end)

addcmd("guiscale", {}, function(args, speaker)
	if args[1] and isNumber(args[1]) then
		local scale = tonumber(args[1])
		if scale % 1 == 0 then scale = scale / 100 end
		-- me when i divide and it explodes
		if scale == 0.01 then scale = 1 end
		if scale == 0.02 then scale = 2 end

		if scale >= 0.4 and scale <= 2 then
			guiScale = scale
		end
	else
		guiScale = defaultGuiScale
	end

	Scale.Scale = math.max(Holder.AbsoluteSize.X / 1920, guiScale)
	updatesaves()
end)

addcmd("muteallvoices", {"muteallvcs"}, function(args, speaker)
	Services.VoiceChatInternal:SubscribePauseAll(true)
end)

addcmd("unmuteallvoices", {"unmuteallvcs"}, function(args, speaker)
	Services.VoiceChatInternal:SubscribePauseAll(false)
end)

addcmd("mutevc", {}, function(args, speaker)
	for _, plr in getPlayer(args[1], speaker) do
		if Players[plr] == speaker then continue end
		Services.VoiceChatInternal:SubscribePause(Players[plr].UserId, true)
	end
end)

addcmd("unmutevc", {}, function(args, speaker)
	for _, plr in getPlayer(args[1], speaker) do
		if Players[plr] == speaker then continue end
		Services.VoiceChatInternal:SubscribePause(Players[plr].UserId, false)
	end
end)

addcmd("phonebook", {"call"}, function(args, speaker)
	local success, canInvite = pcall(function()
		return SocialService:CanSendCallInviteAsync(speaker)
	end)
	if success and canInvite then
		SocialService:PromptPhoneBook(speaker, "")
	else
		notify("Phonebook", "It seems you're not able to call anyone. Sorry!")
	end
end)

local freezingua = nil
frozenParts = {}
addcmd('freezeunanchored',{'freezeua'},function(args, speaker)
	local badnames = {
		"Head",
		"UpperTorso",
		"LowerTorso",
		"RightUpperArm",
		"LeftUpperArm",
		"RightLowerArm",
		"LeftLowerArm",
		"RightHand",
		"LeftHand",
		"RightUpperLeg",
		"LeftUpperLeg",
		"RightLowerLeg",
		"LeftLowerLeg",
		"RightFoot",
		"LeftFoot",
		"Torso",
		"Right Arm",
		"Left Arm",
		"Right Leg",
		"Left Leg",
		"HumanoidRootPart"
	}
	local function FREEZENOOB(v)
		if v:IsA("BasePart" or "UnionOperation") and v.Anchored == false then
			local BADD = false
			for i = 1,#badnames do
				if v.Name == badnames[i] then
					BADD = true
				end
			end
			if speaker.Character and v:IsDescendantOf(speaker.Character) then
				BADD = true
			end
			if BADD == false then
				for i,c in pairs(v:GetChildren()) do
					if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
						c:Destroy()
					end
				end
				local bodypos = Instance.new("BodyPosition")
				bodypos.Parent = v
				bodypos.Position = v.Position
				bodypos.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
				local bodygyro = Instance.new("BodyGyro")
				bodygyro.Parent = v
				bodygyro.CFrame = v.CFrame
				bodygyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
				if not table.find(frozenParts,v) then
					table.insert(frozenParts,v)
				end
			end
		end
	end
	for i,v in pairs(workspace:GetDescendants()) do
		FREEZENOOB(v)
	end
	freezingua = workspace.DescendantAdded:Connect(FREEZENOOB)
end)

addcmd('thawunanchored',{'thawua','unfreezeunanchored','unfreezeua'},function(args, speaker)
	if freezingua then
		freezingua:Disconnect()
	end
	for i,v in pairs(frozenParts) do
		for i,c in pairs(v:GetChildren()) do
			if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
				c:Destroy()
			end
		end
	end
	frozenParts = {}
end)

addcmd('tpunanchored',{'tpua'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local Forces = {}
		for _,part in pairs(workspace:GetDescendants()) do
			if Players[v].Character:FindFirstChild('Head') and part:IsA("BasePart" or "UnionOperation" or "Model") and part.Anchored == false and not part:IsDescendantOf(speaker.Character) and part.Name == "Torso" == false and part.Name == "Head" == false and part.Name == "Right Arm" == false and part.Name == "Left Arm" == false and part.Name == "Right Leg" == false and part.Name == "Left Leg" == false and part.Name == "HumanoidRootPart" == false then
				for i,c in pairs(part:GetChildren()) do
					if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
						c:Destroy()
					end
				end
				local ForceInstance = Instance.new("BodyPosition")
				ForceInstance.Parent = part
				ForceInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				table.insert(Forces, ForceInstance)
				if not table.find(frozenParts,part) then
					table.insert(frozenParts,part)
				end
			end
		end
		for i,c in pairs(Forces) do
			c.Position = Players[v].Character.Head.Position
		end
	end
end)

keycodeMap = {
	["0"] = 0x30,
	["1"] = 0x31,
	["2"] = 0x32,
	["3"] = 0x33,
	["4"] = 0x34,
	["5"] = 0x35,
	["6"] = 0x36,
	["7"] = 0x37,
	["8"] = 0x38,
	["9"] = 0x39,
	["a"] = 0x41,
	["b"] = 0x42,
	["c"] = 0x43,
	["d"] = 0x44,
	["e"] = 0x45,
	["f"] = 0x46,
	["g"] = 0x47,
	["h"] = 0x48,
	["i"] = 0x49,
	["j"] = 0x4A,
	["k"] = 0x4B,
	["l"] = 0x4C,
	["m"] = 0x4D,
	["n"] = 0x4E,
	["o"] = 0x4F,
	["p"] = 0x50,
	["q"] = 0x51,
	["r"] = 0x52,
	["s"] = 0x53,
	["t"] = 0x54,
	["u"] = 0x55,
	["v"] = 0x56,
	["w"] = 0x57,
	["x"] = 0x58,
	["y"] = 0x59,
	["z"] = 0x5A,
	["enter"] = 0x0D,
	["shift"] = 0x10,
	["ctrl"] = 0x11,
	["alt"] = 0x12,
	["pause"] = 0x13,
	["capslock"] = 0x14,
	["spacebar"] = 0x20,
	["space"] = 0x20,
	["pageup"] = 0x21,
	["pagedown"] = 0x22,
	["end"] = 0x23,
	["home"] = 0x24,
	["left"] = 0x25,
	["up"] = 0x26,
	["right"] = 0x27,
	["down"] = 0x28,
	["insert"] = 0x2D,
	["delete"] = 0x2E,
	["f1"] = 0x70,
	["f2"] = 0x71,
	["f3"] = 0x72,
	["f4"] = 0x73,
	["f5"] = 0x74,
	["f6"] = 0x75,
	["f7"] = 0x76,
	["f8"] = 0x77,
	["f9"] = 0x78,
	["f10"] = 0x79,
	["f11"] = 0x7A,
	["f12"] = 0x7B,
}
autoKeyPressing = false
cancelAutoKeyPress = nil

addcmd('autokeypress',{'keypress'},function(args, speaker)
	if keypress and keyrelease and args[1] then
		local code = keycodeMap[args[1]:lower()]
		if not code then notify('Auto Key Press',"Invalid key") return end
		execCmd('unautokeypress')
		wait()
		local clickDelay = 0.1
		local releaseDelay = 0.1
		if args[2] and isNumber(args[2]) then clickDelay = args[2] end
		if args[3] and isNumber(args[3]) then releaseDelay = args[3] end
		autoKeyPressing = true
		cancelAutoKeyPress = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
			if not gameProcessedEvent then
				if (input.KeyCode == Enum.KeyCode.Backspace and UserInputService:IsKeyDown(Enum.KeyCode.Equals)) or (input.KeyCode == Enum.KeyCode.Equals and UserInputService:IsKeyDown(Enum.KeyCode.Backspace)) then
					autoKeyPressing = false
					cancelAutoKeyPress:Disconnect()
				end
			end
		end)
		notify('Auto Key Press',"Press [backspace] and [=] at the same time to stop")
		repeat wait(clickDelay)
			keypress(code)
			wait(releaseDelay)
			keyrelease(code)
		until autoKeyPressing == false
		if cancelAutoKeyPress then cancelAutoKeyPress:Disconnect() keyrelease(code) end
	else
		notify('Auto Key Press',"Your exploit doesn't have the ability to use auto key press")
	end
end)

addcmd('unautokeypress',{'noautokeypress','unkeypress','nokeypress'},function(args, speaker)
	autoKeyPressing = false
	if cancelAutoKeyPress then cancelAutoKeyPress:Disconnect() end
end)

addcmd('addplugin',{'plugin'},function(args, speaker)
	addPlugin(getstring(1, args))
end)

addcmd('removeplugin',{'deleteplugin'},function(args, speaker)
	deletePlugin(getstring(1, args))
end)

addcmd('reloadplugin',{},function(args, speaker)
	local pluginName = getstring(1, args)
	deletePlugin(pluginName)
	wait(1)
	addPlugin(pluginName)
end)

addcmd("addallplugins", {"loadallplugins"}, function(args, speaker)
	if not listfiles or not isfolder then
		notify("Incompatible Exploit", "Your exploit does not support this command (missing listfiles/isfolder)")
		return
	end

	for _, filePath in ipairs(listfiles("")) do
		local fileName = filePath:match("([^/\\]+%.iy)$")

		if fileName and
			fileName:lower() ~= "iy_fe.iy" and
			not isfolder(fileName) and
			not table.find(PluginsTable, fileName)
		then
			addPlugin(fileName)
		end
	end
end)

addcmd('removecmd',{'deletecmd'},function(args, speaker)
	removecmd(args[1])
end)

addcmd("debug", {}, function(args, speaker)
    local opt = parseBoolean(args[1], true)
    _G.IY_DEBUG = opt
    notify("debug", tostring(opt), 1)
end)

if IsOnMobile then
	local QuickCapture = Instance.new("TextButton")
	local UICorner = Instance.new("UICorner")
	QuickCapture.Name = randomString()
	QuickCapture.Parent = PARENT
	QuickCapture.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
	QuickCapture.BackgroundTransparency = 0.14
	QuickCapture.Position = UDim2.new(0.489, 0, 0, 0)
	QuickCapture.Size = UDim2.new(0, 32, 0, 33)
	QuickCapture.Font = Enum.Font.SourceSansBold
	QuickCapture.Text = "IY"
	QuickCapture.TextColor3 = Color3.fromRGB(255, 255, 255)
	QuickCapture.TextSize = 20
	QuickCapture.TextWrapped = true
	QuickCapture.ZIndex = 10
	QuickCapture.Draggable = true
	UICorner.Name = randomString()
	UICorner.CornerRadius = UDim.new(0.5, 0)
	UICorner.Parent = QuickCapture
	QuickCapture.MouseButton1Click:Connect(function()
		Cmdbar:CaptureFocus()
		maximizeHolder()
	end)
	table.insert(shade1, QuickCapture)
	table.insert(text1, QuickCapture)
end

pcall(function() Scale.Scale = math.max(Holder.AbsoluteSize.X / 1920, guiScale) end)
Scale.Parent = ScaledHolder
ScaledHolder.Size = UDim2.fromScale(1 / Scale.Scale, 1 / Scale.Scale)
Scale:GetPropertyChangedSignal("Scale"):Connect(function()
	ScaledHolder.Size = UDim2.fromScale(1 / Scale.Scale, 1 / Scale.Scale)
	for _, v in ScaledHolder:GetDescendants() do
		if v:IsA("GuiObject") and v.Visible then
			v.Visible = false
			v.Visible = true
		end
	end
end)

updateColors(currentShade1,shade1)
updateColors(currentShade2,shade2)
updateColors(currentShade3,shade3)
updateColors(currentText1,text1)
updateColors(currentText2,text2)
updateColors(currentScroll,scroll)

if PluginsTable ~= nil or PluginsTable ~= {} then
	FindPlugins(PluginsTable)
end

-- Events
eventEditor.RegisterEvent("OnExecute")
eventEditor.RegisterEvent("OnSpawn",{
	{Type="Player",Name="Player Filter ($1)"}
})
eventEditor.RegisterEvent("OnDied",{
	{Type="Player",Name="Player Filter ($1)"}
})
eventEditor.RegisterEvent("OnDamage",{
	{Type="Player",Name="Player Filter ($1)"},
	{Type="Number",Name="Below Health ($2)"}
})
eventEditor.RegisterEvent("OnKilled",{
	{Type="Player",Name="Victim Player ($1)"},
	{Type="Player",Name="Killer Player ($2)",Default = 1}
})
eventEditor.RegisterEvent("OnJoin",{
	{Type="Player",Name="Player Filter ($1)",Default = 1}
})
eventEditor.RegisterEvent("OnLeave",{
	{Type="Player",Name="Player Filter ($1)",Default = 1}
})
eventEditor.RegisterEvent("OnChatted",{
	{Type="Player",Name="Player Filter ($1)",Default = 1},
	{Type="String",Name="Message Filter ($2)"}
})

function hookCharEvents(plr,instant)
	task.spawn(function()
		local char = plr.Character
		if not char then return end

		local humanoid = char:WaitForChild("Humanoid",10)
		if not humanoid then return end

		local oldHealth = humanoid.Health
		humanoid.HealthChanged:Connect(function(health)
			local change = math.abs(oldHealth - health)
			if oldHealth > health then
				eventEditor.FireEvent("OnDamage",plr.Name,tonumber(health))
			end
			oldHealth = health
		end)

		humanoid.Died:Connect(function()
			eventEditor.FireEvent("OnDied",plr.Name)

			local killedBy = humanoid:FindFirstChild("creator")
			if killedBy and killedBy.Value and killedBy.Value.Parent then
				eventEditor.FireEvent("OnKilled",plr.Name,killedBy.Name)
			end
		end)
	end)
end

Players.PlayerAdded:Connect(function(plr)
	eventEditor.FireEvent("OnJoin",plr.Name)
	if isLegacyChat then plr.Chatted:Connect(function(msg) eventEditor.FireEvent("OnChatted",tostring(plr),msg) end) end
	plr.CharacterAdded:Connect(function() eventEditor.FireEvent("OnSpawn",tostring(plr)) hookCharEvents(plr) end)
	JoinLog(plr)
	if isLegacyChat then ChatLog(plr) end
	if ESPenabled then
		repeat wait(1) until plr.Character and getRoot(plr.Character)
		ESP(plr)
	end
	if CHMSenabled then
		repeat wait(1) until plr.Character and getRoot(plr.Character)
		CHMS(plr)
	end
end)

if not isLegacyChat then
	TextChatService.MessageReceived:Connect(function(message)
		if message.TextSource then
			local player = Players:GetPlayerByUserId(message.TextSource.UserId)
			if not player then return end

			if logsEnabled == true then
				CreateLabel(player.Name, message.Text)
			end
			if player.UserId == Players.LocalPlayer.UserId then
				do_exec(message.Text, Players.LocalPlayer)
			end
			eventEditor.FireEvent("OnChatted", player.Name, message.Text)
			sendChatWebhook(player, message.Text)
		end
	end)
end

for _,plr in pairs(Players:GetPlayers()) do
	pcall(function()
		plr.CharacterAdded:Connect(function() eventEditor.FireEvent("OnSpawn",tostring(plr)) hookCharEvents(plr) end)
		hookCharEvents(plr)
	end)
end

if spawnCmds and #spawnCmds > 0 then
	for i,v in pairs(spawnCmds) do
		eventEditor.AddCmd("OnSpawn",{v.COMMAND or "",{0},v.DELAY or 0})
	end
	updatesaves()
end

if loadedEventData then eventEditor.LoadData(loadedEventData) end
eventEditor.Refresh()

eventEditor.FireEvent("OnExecute")

if aliases and #aliases > 0 then
	local cmdMap = {}
	for i,v in pairs(cmds) do
		cmdMap[v.NAME:lower()] = v
		for _,alias in pairs(v.ALIAS) do
			cmdMap[alias:lower()] = v
		end
	end
	for i = 1, #aliases do
		local cmd = string.lower(aliases[i].CMD)
		local alias = string.lower(aliases[i].ALIAS)
		if cmdMap[cmd] then
			customAlias[alias] = cmdMap[cmd]
		end
	end
	refreshaliases()
end

IYMouse.Move:Connect(checkTT)

CaptureService.CaptureBegan:Connect(function()
	PARENT.Enabled = false
end)

CaptureService.CaptureEnded:Connect(function()
	task.delay(0.1, function()
		PARENT.Enabled = true
	end)
end)

	minimizeHolder()

end

-- SIRIUS: Finalize and run headless background tasks
task.spawn(function()
	task.wait(4) -- Increased delay to ensure IY loaded its UI fully before hiding
	if not getgenv()._iyLoaded and not getgenv()._iyLoading and getgenv().Bundled_IY_Execute then
		getgenv()._iyLoading = true
		local ok, err = pcall(function() getgenv().Bundled_IY_Execute() end)
		if ok then
			getgenv()._iyLoaded = true
			-- Hide IY multiple times or after delay to ensure it doesn't pop up after teleport
			task.spawn(function()
				for i = 1, 5 do
					if getgenv().execCmd then pcall(getgenv().execCmd, "hide") end
					task.wait(2)
				end
			end)
			if getgenv().queueNotification then
				getgenv().queueNotification("Infinite Yield", "IY commands ready. Use ';' to open the command bar.", 9134780101)
			end
		else
			if getgenv().queueNotification then
				getgenv().queueNotification("IY Warning", "Auto-load failed: "..tostring(err)..". Try the IY button manually.", 4370336704)
			end
		end
		getgenv()._iyLoading = false
	end
end)
