-- Author Purple (@VioletElementalist)
-- // THIS CODE IS NOT MEANT FOR 3RD PARTY USE, IT'S A SHOWCASE

-- Sample of front-end, a neat cards selection animated using Spring
-- Hoarcekat was used as a storybook

local module = {}

local green = {
	script.UIGradientGreen.Color.Keypoints[1].Value,
	script.UIGradientGreen.Color.Keypoints[2].Value
}

local red = {
	script.UIGradient.Color.Keypoints[1].Value,
	script.UIGradient.Color.Keypoints[2].Value
}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local Events = Replicated.Events

local UIMotion2 = require(Replicated.Libs.UIMotionV2)

function module:AnimateGradient(gradient, dt, colors)
	local num_colors = #colors
	local color_length = 1 / num_colors
	local period = 2 
	local progress = (tick() % period) / period 
	local newColors = {}
	local wrapColor = false

	for i = 1, num_colors + 1 do 
		local color = colors[i] or colors[i-num_colors]
		local position = progress + (i-1)/num_colors 

		if position > 1 then position = position - 1 end 
		if position == 0 or position == 1 then wrapColor = true end 

		table.insert(newColors, ColorSequenceKeypoint.new(position, color))
	end

	if not wrapColor then 
		local indexProgress = ((1 - progress) / color_length) + 1
		local col1 = colors[math.floor(indexProgress)]
		local col2 = colors[math.ceil(indexProgress)] or colors[1]
		local finalCol = col1:Lerp(col2, indexProgress % 1) 

		table.insert(newColors, ColorSequenceKeypoint.new(0, finalCol))
		table.insert(newColors, ColorSequenceKeypoint.new(1, finalCol))
	end

	table.sort(newColors, function(a, b)
		return a.Time < b.Time
	end)
	newColors[1]= ColorSequenceKeypoint.new(0, newColors[1].Value) 
	newColors[#newColors]= ColorSequenceKeypoint.new(1, newColors[#newColors].Value) 

	gradient.Color = ColorSequence.new(newColors)
end

function module:PromptSkip()
	local Players = game:GetService("Players")
	local Player = Players.LocalPlayer
	local PlayerGui = Player:WaitForChild("PlayerGui", 120)
	local Maid = require(game.ReplicatedStorage.Maid).new()
	local GetVotePool = Events.RequestCurrentVotePool
	
	local Gui = script.Skip:Clone()
	Gui.Parent = PlayerGui.Waves
	
	local VotedNo = false

	local GroupOutTween = TweenService:Create(Gui, TweenInfo.new(1, Enum.EasingStyle.Sine), {GroupTransparency = 0})
	local GroupInTween = TweenService:Create(Gui, TweenInfo.new(.35, Enum.EasingStyle.Sine), {GroupTransparency = 1})

	local BaseFrame = Gui.Base

	local InTween = TweenService:Create(BaseFrame, TweenInfo.new(.25, Enum.EasingStyle.Sine), {Position = UDim2.new(0.5, 0, 0.5, 0)})
	local OutTween = TweenService:Create(BaseFrame, TweenInfo.new(.25, Enum.EasingStyle.Sine), {Position = UDim2.new(5, 0, 0.5, 0)})

	GroupOutTween:Play()
	InTween:Play()

	Maid:GiveTask("AnimateGameWaiting", RunService.RenderStepped, function(dt)
		module:AnimateGradient(BaseFrame.UIGradient, dt, red)
		module:AnimateGradient(BaseFrame.Yes.UIGradient, dt, green)
		module:AnimateGradient(BaseFrame.No.UIGradient, dt, red)
		module:AnimateGradient(BaseFrame.Frame.UIGradient, dt, red)
		module:AnimateGradient(BaseFrame.Voted.UIGradient, dt, red)
	end):onTaskEnd(function()
		GroupInTween:Play()
		GroupInTween.Completed:Wait()
		Gui:Destroy()
		--OutTween:Play()
	end)
	
	BaseFrame.Count.Text = `{0}/{#Players:GetPlayers()}`
	
	local function CountVotes(data)
		if typeof(data) == "string" and data == "SkipEnd" then
			UIMotion2:EndRegisterTask("SkipWaveVoting", "SkipWaveVotingYesButton")
			UIMotion2:EndRegisterTask("SkipWaveVoting", "SkipWaveVotingNoButton")
			
			task.delay(1, function()
				if Maid.Dispose then
					Maid:Dispose()
				end
			end)
			return
		end
		
		if typeof(data) == "table" then
			local Voted = data or GetVotePool:InvokeServer()
			local VotedCount = #Voted
			local ExpectedVotes = #Players:GetPlayers()

			BaseFrame.Count.Text = `{#Voted}/{ExpectedVotes}`

			for _, VoteValue in pairs(Voted) do
				if not BaseFrame.Frame:FindFirstChild(VoteValue.Name) then
					task.spawn(function()

						local FoundCachedThumbnail = Replicated.PlrThumbnailsCache:FindFirstChild(VoteValue.Name)

						local BaseSize = script.Box.Size	
						local NewBox = script.Box:Clone()
						NewBox.Name = VoteValue.Name
						NewBox.Size = UDim2.new(0,0,0,0)
						NewBox.Icon.Image = FoundCachedThumbnail and FoundCachedThumbnail.Image or Players:GetUserThumbnailAsync(Players:FindFirstChild(VoteValue.Name).UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
						NewBox.Parent = BaseFrame.Frame

						TweenService:Create(NewBox, TweenInfo.new(.15, Enum.EasingStyle.Sine), {Size = BaseSize}):Play()
					end)
				end
			end
			
			for _, VoteBox in pairs(BaseFrame.Frame:GetChildren()) do
				if VoteBox:IsA("ImageLabel") then
					if VoteBox:HasTag("Destroying") then
						continue
					end
					
					if not table.find(Voted, Players:FindFirstChild(VoteBox.Name)) then
						local FadeInTween = TweenService:Create(VoteBox, TweenInfo.new(.15, Enum.EasingStyle.Sine), {Size = UDim2.new(0,0,0,0)})
						FadeInTween:Play()
						
						VoteBox:AddTag("Destroying")
						
						Maid:GiveTask(`FadeIn_{VoteBox.Name}`, FadeInTween.Completed, function()
							VoteBox:Destroy()
							Maid:KillTask(`FadeIn_{VoteBox.Name}`)
						end)
					end
				end
			end

			--if VotedCount > ExpectedVotes then
			--	task.delay(1.5, function()
			--		Maid:Dispose()
			--	end)
			--end
		end
	end

	CountVotes()

	Maid:GiveTask("VoteListener", Events.SkipWave.OnClientEvent, CountVotes)
	
	UIMotion2:EndRegisterTask("SkipWaveVoting", "SkipWaveVotingYesButton")
	UIMotion2:EndRegisterTask("SkipWaveVoting", "SkipWaveVotingNoButton")
	
	UIMotion2:FullRegister(BaseFrame.Yes, BaseFrame.Yes.Size, {
		UUID = "SkipWaveVotingYesButton",
		TreeUUID = "SkipWaveVoting",
		UIElement = BaseFrame.Yes,
		callBack = function()
			if not VotedNo then
				Replicated.Events.SkipWave:FireServer(true)
			end
		end,
	})
	
	UIMotion2:FullRegister(BaseFrame.No, BaseFrame.No.Size, {
		UUID = "SkipWaveVotingNoButton",
		TreeUUID = "SkipWaveVoting",
		UIElement = BaseFrame.No,
		callBack = function()
			UIMotion2:EndRegisterTask("SkipWaveVoting", "SkipWaveVotingYesButton")
			UIMotion2:EndRegisterTask("SkipWaveVoting", "SkipWaveVotingNoButton")
			VotedNo = true
			Replicated.Events.SkipWave:FireServer()
			if Maid.Dispose then
				Maid:Dispose()
			end
		end,
	})

	
	return Maid
end

return module
