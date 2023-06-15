-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- // Variables
local ResX, ResY = 160, 90

local ScreenObject = workspace:WaitForChild("Screen")
local ScreenPlayer = ScreenObject:WaitForChild("ScreenPlayer")
local StarterGui = ScreenPlayer:WaitForChild("StarterGui")
local VideoPlayerGui = ScreenPlayer:WaitForChild("VideoPlayer")

-- // Events
local MovieFunction = ReplicatedStorage.Remotes.MovieFunction
local MovieEvent = ReplicatedStorage.Remotes.MovieEvent

-- // Modules
local ImageRenderer = require(script.ImageRenderer)
local GreedyCanvas = require(script.GreedyCanvas)


local MovieReceiver = {}
MovieReceiver.ActiveCanvas = false
MovieReceiver.ActiveMovie = false

MovieReceiver.Init = function()
	MovieReceiver.ActiveCanvas = GreedyCanvas.new(ResX, ResY)
	MovieReceiver.ActiveCanvas:SetParent(VideoPlayerGui.VideoFrame)
end

MovieReceiver.Init()

-- // Movies
local Movie = {}
Movie.__index = Movie

function Movie.new(MovieName, CurrentMap, NextMap)
	local instance = setmetatable({}, Movie)
	instance.MovieName = MovieName

	instance.ElapsedTime = 0

	instance.CurrentMap = CurrentMap or false
	instance.NextMap = NextMap or false	
	instance.ReachedBuffer = false

	instance.Update = false
	instance.TracedFPS = 0
	instance.TracedSpeed = os.clock()

	instance.Debug = false

	return instance
end

function Movie:Pause()

end

function Movie:Buffer()

end

function Movie:Resume()

end

function Movie:Run()
	-- // Code keeps track and makes sure it only updates in 60fps
	if not (self.TracedFPS >= 60) then self.TracedFPS += 1 end
	if (os.clock() - self.TracedSpeed) >= 1 then self.TracedSpeed = os.clock() if self.Debug then print(self.TracedFPS) end  self.TracedFPS = 0 end
	if self.TracedFPS >= 60 then return end

	-- // Check if the  current bit map has ended then load the next bitmap and ask for a new next up map
	self.ElapsedTime = math.clamp(self.ElapsedTime + 1, 1, #self.CurrentMap[1])
	ImageRenderer.RenderVideoImage(MovieReceiver.ActiveCanvas, self.CurrentMap[1][self.ElapsedTime], ResX, ResY)

	self.CurrentMap[1][self.ElapsedTime] = ""

	if self.ElapsedTime >= #self.CurrentMap[1] then
		if self.ReachedBuffer then return end
		self.ReachedBuffer = true

		if self.NextMap then	-- // If a new map exists it'll load it onto the new current map
			table.clear(self.CurrentMap)
			self.CurrentMap = nil

			self.CurrentMap = self.NextMap
			self.ElapsedTime = 0
			self.ReachedBuffer = false
			self.NextMap = false

			MovieEvent:FireServer("RequestNewMap")			
		else  -- // If no new map exists it'll wait until a new map exits and load a buffer screen

		end
	end
end

function Movie:Clear()

end

-- // Init

RunService.Heartbeat:Connect(function()
	if MovieReceiver.ActiveMovie then
		MovieReceiver.ActiveMovie:Run()
	end
end)

MovieEvent.OnClientEvent:Connect(function(Callback, ...)
	if Callback == "StartMovie" then
		if MovieReceiver.ActiveMovie then
			MovieReceiver.ActiveMovie:Clear()
		end

		MovieReceiver.ActiveMovie = Movie.new(unpack({...}))
	elseif Callback == "UpdatedNextMap" then
		if MovieReceiver.ActiveMovie then
			MovieReceiver.ActiveMovie.NextMap = unpack({...})
		end
	end
end)

return MovieReceiver
