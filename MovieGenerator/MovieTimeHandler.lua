-- // Services
local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- // Variables
local LocalPlayer = PlayerService.LocalPlayer
local ScreenObject = workspace:WaitForChild("Screen")
local ScreenPlayer = ScreenObject:WaitForChild("ScreenPlayer")
local StarterGui = ScreenPlayer:WaitForChild("StarterGui")
local VideoPlayerGui = ScreenPlayer:WaitForChild("VideoPlayer")

local ResX, ResY = 160, 90

-- // Modules
local ModuleFolder = ReplicatedStorage:WaitForChild("Modules")

local TweenMod = require(ModuleFolder:FindFirstChild("Tween"))
local GreedyCanvas = require(script.GreedyCanvas)
local ImageRenderer = require(script.ImageRenderer)

-- // Events
local EventsFolder = ReplicatedStorage:WaitForChild("Remotes")

local FunctionAPI = EventsFolder:FindFirstChild("FunctionAPI")
local EventAPI = EventsFolder:FindFirstChild("EventAPI")

-- Init
local modules = {}
local returnModFunc = script.Parent.ReturnMod
local function mod(name)
	if not modules[name] then
		modules[name] = returnModFunc:Invoke(name)
	end

	return modules[name]
end

local Module = {}
Module.ActiveMovie = nil

local MovieTimeHandler = {}
MovieTimeHandler.__index = MovieTimeHandler

local Canvas = GreedyCanvas.new(ResX, ResY)
Canvas:SetParent(VideoPlayerGui.VideoFrame)

function MovieTimeHandler.new(MovieName, CurrentMap, TotalFrames, FrameCount)
	local instance = setmetatable({}, MovieTimeHandler)
	instance.MovieTime = 0

	instance.CurrentTimeMap = CurrentMap
	instance.NextTimeMap = false
	instance.startTime = os.clock()
	instance.checked = false
	
	instance.TotalFrames = TotalFrames
	instance.FrameCount = FrameCount

	return instance
end

function MovieTimeHandler:PlayFrames()
	self.MovieTime = math.clamp(self.MovieTime + 1, 1, #self.CurrentTimeMap[1])
	ImageRenderer.RenderVideoImage(Canvas, self.CurrentTimeMap[1][self.MovieTime], ResX, ResY)
	
	self.CurrentTimeMap[1][self.MovieTime] = ""
	
	if self.MovieTime == #self.CurrentTimeMap[1] then
		if self.checked then return end
		self.checked = true
		
		if self.NextTimeMap then	
			-- // Load this new map into the current map and reset the movie time
			table.clear(self.CurrentTimeMap)
			self.CurrentTimeMap = nil
			
			self.CurrentTimeMap = self.NextTimeMap
			self.MovieTime = 0
			self.checked = false
			self.NextTimeMap = false
			
			if self.FrameCount >= self.TotalFrames then
				return
			end
			
			EventAPI:FireServer("UpdateTime")
		else 
			-- // Put a loading screen on the movie screen and send request to get a new next map
			if self.FrameCount >= self.TotalFrames then
				return
			end
			
			print("Buffer Loading...")
			
			repeat task.wait() until self.NextTimeMap ~= false
			
			table.clear(self.CurrentTimeMap)
			self.CurrentTimeMap = nil

			self.CurrentTimeMap = self.NextTimeMap
			self.MovieTime = 0
			self.checked = false
			self.NextTimeMap = false

			EventAPI:FireServer("UpdateTime")
		end
	end
end

function MovieTimeHandler:UpdateValue(Name, Value)
	if not self[Name] then return end
	self[Name] = Value
end

-- // Remote
EventAPI.OnClientEvent:Connect(function(Callback, ...)
	if Callback == "Play" then
		local MovieName, NewCurrentTimeMap, TotalFrames, FrameCount = unpack({...})
		Module.ActiveMovie = MovieTimeHandler.new(MovieName, NewCurrentTimeMap, TotalFrames, FrameCount)
	elseif Callback == "UpdateMap" then
		local NewNextUpmap, TotalFrames, FrameCount = unpack({...})
		Module.ActiveMovie.NextTimeMap = typeof(NewNextUpmap) == "table" and NewNextUpmap or false
		Module.ActiveMovie.TotalFrames = TotalFrames
		Module.ActiveMovie.FrameCount = FrameCount
	end
end)

task.spawn(function()
	repeat task.wait() until workspace:GetAttribute("MovieIsPlaying")
	EventAPI:FireServer("Play", "ShrekMovie")
end)

-- // Update
RunService.Heartbeat:Connect(function()
	if not Module.ActiveMovie then return end
	Module.ActiveMovie:PlayFrames()	
end)

return Module
