-- // This is my own fork of BoatTween - "BoatTweenTyped", featuring many fixed issues

--[==[
	BoatTween (because TweenService2 was taken)
	by boatbomber (Zack Ovits), revised and improved by Purple (@VioletElementalist)
	© 2020-2024


	API:

	function BoatTween:Create(Object,Data)
		returns a Tween object

		Params:
		- Object
		The instance that is having it's properties tweened
		- Data
		A dictionary of the various settings of the tween
		{
			number Time = Any positive number
				How long the tween should take to complete

			string EasingStyle = Any TweenStyle from the list below
				The style that the tween follows
				(Note: Uses strings instead of Enum.EasingStyle to allow us to add styles that Roblox doesn't support)

				List of available styles:
					Linear				Quad					Cubic
					Quart				Quint					Sine
					Expo				Circ					Elastic
					Back				Bounce					Smooth
					Smoother			RidiculousWiggle		RevBack
					Spring				SoftSpring				Standard
					Sharp				Acceleration			Deceleration
					StandardProductive	EntranceProductive		ExitProductive
					StandardExpressive	EntranceExpressive		ExitExpressive
					FabricStandard		FabricAccelerate		FabricDecelerate
					UWPAccelerate		MozillaCurve

			string EasingDirection = "In" or "Out" or "InOut" or "OutIn"
				The direction for the TweenStyle to adhere to

			number DelayTime = 0 -> math.huge
				The amount of time before the tween begins playback after calling :Play() on the tween
				(Note: doesn't affect :Resume() calls)

			number RepeatCount = -1 -> math.huge
				How many times the tween should repeat with -1 being infinity
				(Note: will wait the DelayTime in between replaying)

			boolean Reverses = false or true
				Whether the tween should reverse itself after completion
				(note: Waits the DelayTime before reversing)

			table Goal = dictionary
				A dictionary where the keys are properties to tween and the values are the end goals of said properties
				You may tween any property with value of the following types:
					number				boolean					CFrame
					Color3				UDim2					UDim
					Ray					NumberRange				NumberSequenceKeypoint
					PhysicalProperties	NumberSequence			Region3
					Rect				Vector2					Vector3


			string StepType = "Stepped" or "Heartbeat" or "RenderStepped"
				The event of RunService for the tween to move on
		}

	function Tween:Play()
		Plays the tween, starting from the beginning
	function Tween:Stop()
		Stops the tween, freezing it in its current state
	function Tween:Resume()
		Plays the tween, starting from current position and time
	function TweenObject:Destroy()
		Clears connections, stops playback, destroys objects

	property Tween.Instance
		The object being tweened
	property Tween.PlaybackState
		An Enum.PlaybackState representing the Tween's current state

	event Tween.Stopped
		Fired when a Tween ends from the :Stop() function
	event Tween.Completed
		Fired when a Tween ends due to :Play() being completed
	event Tween.Resumed
		Fired when a Tween is played through the :Resume() function


--]==]

local RunService = game:GetService("RunService")
local RawTweenFunctions = require(script.TweenFunctions)
local TypeLerpers = require(script.Lerps)
local Heartbeat = RunService.Heartbeat

local BoatTween = {}

local ValidStepTypes = {
	["Heartbeat"] = true;
	["Stepped"] = true;
	["RenderStepped"] = true;
}

if not RunService:IsClient() then
	ValidStepTypes.RenderStepped = nil
end

local TweenFunctions = {
	FabricAccelerate = {
		In = RawTweenFunctions.InFabricAccelerate;
		Out = RawTweenFunctions.OutFabricAccelerate;
		InOut = RawTweenFunctions.InOutFabricAccelerate;
		OutIn = RawTweenFunctions.OutInFabricAccelerate;
	};

	UWPAccelerate = {
		In = RawTweenFunctions.InUWPAccelerate;
		Out = RawTweenFunctions.OutUWPAccelerate;
		InOut = RawTweenFunctions.InOutUWPAccelerate;
		OutIn = RawTweenFunctions.OutInUWPAccelerate;
	};

	Circ = {
		In = RawTweenFunctions.InCirc;
		Out = RawTweenFunctions.OutCirc;
		InOut = RawTweenFunctions.InOutCirc;
		OutIn = RawTweenFunctions.OutInCirc;
	};

	RevBack = {
		In = RawTweenFunctions.InRevBack;
		Out = RawTweenFunctions.OutRevBack;
		InOut = RawTweenFunctions.InOutRevBack;
		OutIn = RawTweenFunctions.OutInRevBack;
	};

	Spring = {
		In = RawTweenFunctions.InSpring;
		Out = RawTweenFunctions.OutSpring;
		InOut = RawTweenFunctions.InOutSpring;
		OutIn = RawTweenFunctions.OutInSpring;
	};

	Standard = {
		In = RawTweenFunctions.InStandard;
		Out = RawTweenFunctions.OutStandard;
		InOut = RawTweenFunctions.InOutStandard;
		OutIn = RawTweenFunctions.OutInStandard;
	};

	StandardExpressive = {
		In = RawTweenFunctions.InStandardExpressive;
		Out = RawTweenFunctions.OutStandardExpressive;
		InOut = RawTweenFunctions.InOutStandardExpressive;
		OutIn = RawTweenFunctions.OutInStandardExpressive;
	};

	Linear = {
		In = RawTweenFunctions.InLinear;
		Out = RawTweenFunctions.OutLinear;
		InOut = RawTweenFunctions.InOutLinear;
		OutIn = RawTweenFunctions.OutInLinear;
	};

	ExitProductive = {
		In = RawTweenFunctions.InExitProductive;
		Out = RawTweenFunctions.OutExitProductive;
		InOut = RawTweenFunctions.InOutExitProductive;
		OutIn = RawTweenFunctions.OutInExitProductive;
	};

	Deceleration = {
		In = RawTweenFunctions.InDeceleration;
		Out = RawTweenFunctions.OutDeceleration;
		InOut = RawTweenFunctions.InOutDeceleration;
		OutIn = RawTweenFunctions.OutInDeceleration;
	};

	Smoother = {
		In = RawTweenFunctions.InSmoother;
		Out = RawTweenFunctions.OutSmoother;
		InOut = RawTweenFunctions.InOutSmoother;
		OutIn = RawTweenFunctions.OutInSmoother;
	};

	FabricStandard = {
		In = RawTweenFunctions.InFabricStandard;
		Out = RawTweenFunctions.OutFabricStandard;
		InOut = RawTweenFunctions.InOutFabricStandard;
		OutIn = RawTweenFunctions.OutInFabricStandard;
	};

	RidiculousWiggle = {
		In = RawTweenFunctions.InRidiculousWiggle;
		Out = RawTweenFunctions.OutRidiculousWiggle;
		InOut = RawTweenFunctions.InOutRidiculousWiggle;
		OutIn = RawTweenFunctions.OutInRidiculousWiggle;
	};

	MozillaCurve = {
		In = RawTweenFunctions.InMozillaCurve;
		Out = RawTweenFunctions.OutMozillaCurve;
		InOut = RawTweenFunctions.InOutMozillaCurve;
		OutIn = RawTweenFunctions.OutInMozillaCurve;
	};

	Expo = {
		In = RawTweenFunctions.InExpo;
		Out = RawTweenFunctions.OutExpo;
		InOut = RawTweenFunctions.InOutExpo;
		OutIn = RawTweenFunctions.OutInExpo;
	};

	Sine = {
		In = RawTweenFunctions.InSine;
		Out = RawTweenFunctions.OutSine;
		InOut = RawTweenFunctions.InOutSine;
		OutIn = RawTweenFunctions.OutInSine;
	};

	Cubic = {
		In = RawTweenFunctions.InCubic;
		Out = RawTweenFunctions.OutCubic;
		InOut = RawTweenFunctions.InOutCubic;
		OutIn = RawTweenFunctions.OutInCubic;
	};

	EntranceExpressive = {
		In = RawTweenFunctions.InEntranceExpressive;
		Out = RawTweenFunctions.OutEntranceExpressive;
		InOut = RawTweenFunctions.InOutEntranceExpressive;
		OutIn = RawTweenFunctions.OutInEntranceExpressive;
	};

	Elastic = {
		In = RawTweenFunctions.InElastic;
		Out = RawTweenFunctions.OutElastic;
		InOut = RawTweenFunctions.InOutElastic;
		OutIn = RawTweenFunctions.OutInElastic;
	};

	Quint = {
		In = RawTweenFunctions.InQuint;
		Out = RawTweenFunctions.OutQuint;
		InOut = RawTweenFunctions.InOutQuint;
		OutIn = RawTweenFunctions.OutInQuint;
	};

	EntranceProductive = {
		In = RawTweenFunctions.InEntranceProductive;
		Out = RawTweenFunctions.OutEntranceProductive;
		InOut = RawTweenFunctions.InOutEntranceProductive;
		OutIn = RawTweenFunctions.OutInEntranceProductive;
	};

	Bounce = {
		In = RawTweenFunctions.InBounce;
		Out = RawTweenFunctions.OutBounce;
		InOut = RawTweenFunctions.InOutBounce;
		OutIn = RawTweenFunctions.OutInBounce;
	};

	Smooth = {
		In = RawTweenFunctions.InSmooth;
		Out = RawTweenFunctions.OutSmooth;
		InOut = RawTweenFunctions.InOutSmooth;
		OutIn = RawTweenFunctions.OutInSmooth;
	};

	Back = {
		In = RawTweenFunctions.InBack;
		Out = RawTweenFunctions.OutBack;
		InOut = RawTweenFunctions.InOutBack;
		OutIn = RawTweenFunctions.OutInBack;
	};

	Quart = {
		In = RawTweenFunctions.InQuart;
		Out = RawTweenFunctions.OutQuart;
		InOut = RawTweenFunctions.InOutQuart;
		OutIn = RawTweenFunctions.OutInQuart;
	};

	StandardProductive = {
		In = RawTweenFunctions.InStandardProductive;
		Out = RawTweenFunctions.OutStandardProductive;
		InOut = RawTweenFunctions.InOutStandardProductive;
		OutIn = RawTweenFunctions.OutInStandardProductive;
	};

	Quad = {
		In = RawTweenFunctions.InQuad;
		Out = RawTweenFunctions.OutQuad;
		InOut = RawTweenFunctions.InOutQuad;
		OutIn = RawTweenFunctions.OutInQuad;
	};

	FabricDecelerate = {
		In = RawTweenFunctions.InFabricDecelerate;
		Out = RawTweenFunctions.OutFabricDecelerate;
		InOut = RawTweenFunctions.InOutFabricDecelerate;
		OutIn = RawTweenFunctions.OutInFabricDecelerate;
	};

	Acceleration = {
		In = RawTweenFunctions.InAcceleration;
		Out = RawTweenFunctions.OutAcceleration;
		InOut = RawTweenFunctions.InOutAcceleration;
		OutIn = RawTweenFunctions.OutInAcceleration;
	};

	SoftSpring = {
		In = RawTweenFunctions.InSoftSpring;
		Out = RawTweenFunctions.OutSoftSpring;
		InOut = RawTweenFunctions.InOutSoftSpring;
		OutIn = RawTweenFunctions.OutInSoftSpring;
	};

	ExitExpressive = {
		In = RawTweenFunctions.InExitExpressive;
		Out = RawTweenFunctions.OutExitExpressive;
		InOut = RawTweenFunctions.InOutExitExpressive;
		OutIn = RawTweenFunctions.OutInExitExpressive;
	};

	Sharp = {
		In = RawTweenFunctions.InSharp;
		Out = RawTweenFunctions.OutSharp;
		InOut = RawTweenFunctions.InOutSharp;
		OutIn = RawTweenFunctions.OutInSharp;
	};
}

export type StepTypes = "Heartbeat" | "RenderStepped" | "Stepped"
export type EasingDirections = "In" | "Out" | "InOut" | "OutIn"
export type EasingStyles = "FabricAccelerate" | "UWPAccelerate" | "Circ" | "RevBack" | "Spring" | "Standard" | "StandardExpressive" | "Linear" | "ExitProductive" | "Deceleration" | "Smoother" | "FabricStandard" | "RidiculousWiggle" | "MozillaCurve" | "Expo" | "Sine" | "Cubic" | "EntranceExpressive" | "Elastic" | "Quint" | "EntranceProductive" | "Bounce" | "Smooth" | "Back" | "Quart" | "StandardProductive" | "Quad" | "FabricDecelerate" | "Acceleration" | "SoftSpring" | "ExitExpressive" | "Sharp"
export type TweenDataType = {
	Time: number?,
	EasingStyle: EasingStyles?,
	EasingDirection: EasingDirections?,

	Reverses: boolean?,
	RepeatCount: number?,
	DelayOnStart: boolean?,
	DelayTime: number?,
	
	ReverseOnDestroy: boolean?,

	StepType: StepTypes?,

	Goal: {any}?,
}

export type TweenObject = {
	["Instance"]: Instance,
	["PlaybackState"]: EnumItem,

	["Completed"]: RBXScriptSignal;
	["Resumed"]: RBXScriptSignal;
	["Stopped"]: RBXScriptSignal;
	["Destroy"]: () -> ();
	["Play"]: () -> ();
	["Stop"]: () -> ();
	["Resume"]: () -> ();
}

local MaidModule = require(game.ReplicatedStorage.Maid)
local TweenMaidModule = require(game.ReplicatedStorage.Libs.TweenMaid)
local SignalModule = require(game.ReplicatedStorage.Signal)

local function Wait(Seconds)
	Seconds = math.max(Seconds or 0.03, 0)
	local TimeRemaining = Seconds

	while TimeRemaining > 0 do
		TimeRemaining -= Heartbeat:Wait()
	end

	return Seconds - TimeRemaining
end

function BoatTween:Create(Object: Instance, Data: TweenDataType): TweenObject
	-- Validate
	if not Object or typeof(Object) ~= "Instance" then
		return warn("Invalid object to tween:", Object)
	end

	Data = type(Data) == "table" and Data or {}

	-- Define settings
	local EventStep: RBXScriptSignal = ValidStepTypes[Data.StepType] and RunService[Data.StepType] or RunService.Stepped
	local TweenFunction = TweenFunctions[Data.EasingStyle or "Quad"][Data.EasingDirection or "In"]
	local Time = math.max(type(Data.Time) == "number" and Data.Time or 1, 0.001)
	local Goal = type(Data.Goal) == "table" and Data.Goal or {}
	local DelayTime = type(Data.DelayTime) == "number" and Data.DelayTime > 0.027 and Data.DelayTime
	local DelayOnStart = typeof(Data.DelayOnStart) == "boolean" and Data.DelayOnStart
	local RepeatCount = (type(Data.RepeatCount) == "number" and math.max(Data.RepeatCount, -1) or 0) + 1
	local Maid = MaidModule.new()
	
	if DelayOnStart == nil then
		DelayOnStart = true
	end
	
	if Data.ReverseOnDestroy then
		Data.OriginalProperties = {}

		for Property, Lerper in pairs(Goal) do
			Data.OriginalProperties[Property] = Object[Property]
		end
	end
	
	local TweenData = {}
	for Property, EndValue in pairs(Goal) do
		TweenData[Property] = TypeLerpers[typeof(EndValue)](Object[Property], EndValue)
	end

	-- Create instances
	local CompletedEvent = SignalModule.new()
	local StoppedEvent = SignalModule.new()
	local ResumedEvent = SignalModule.new()
	local Dead = false

	--local PlaybackConnection
	local StartTime, _ElapsedTime = os.clock(), 0
	
	local InternalThread
	
	local TweenObject = {
		["Instance"] = Object;
		["PlaybackState"] = Enum.PlaybackState.Begin;

		["Completed"] = CompletedEvent;
		["Resumed"] = ResumedEvent;
		["Stopped"] = StoppedEvent;
	} :: TweenObject

	function TweenObject:Destroy()
		Dead = true
		TweenObject:Stop()
		
		if TweenObject then
			if Data.ReverseOnDestroy and (TweenObject.PlaybackState ~= Enum.PlaybackState.Cancelled and TweenObject.PlaybackState ~= Enum.PlaybackState.Completed and TweenObject.PlaybackState ~= Enum.PlaybackState.Begin) then
				Data.ReverseOnDestroyLayer2 = true
				Data.Goal = Data.OriginalProperties
				BoatTween:Create(Object, Data):Play()
			end
		end
		
		--CompletedEvent:Destroy()
		--StoppedEvent:Destroy()
		--ResumedEvent:Destroy()
		CompletedEvent:Fire()
		CompletedEvent:Close()
		StoppedEvent:Close()
		ResumedEvent:Close()
		Maid:Dispose()
		
		TweenObject = nil
	end

	local CurrentlyReversing = false
	local CurrentLayer = 0

	local function Play(Layer, Reverse)
		if Dead then
			Play = nil
			return
		end
		Maid:KillTask("PlaybackTask")

		Layer = Layer or 1
		if RepeatCount ~= 0 and TweenObject then
			if Layer > RepeatCount then
				TweenObject.PlaybackState = Enum.PlaybackState.Completed
				CompletedEvent:Fire()
				CurrentlyReversing = false
				CurrentLayer = 1
				--if InternalThread then
				--	coroutine.close(InternalThread)
				--	InternalThread = nil
				--end
				
				if Data.ReverseOnDestroyLayer2 then
					TweenObject:Destroy()
				end
				return
			end
		end

		CurrentLayer = Layer

		if Reverse then
			CurrentlyReversing = true
		end
		
		StartTime = os.clock() - _ElapsedTime
		Maid:GiveTask("PlaybackTask", EventStep, function()
			_ElapsedTime = os.clock() - StartTime
			if _ElapsedTime >= Time then
				if Reverse then
					for Property, Lerper in pairs(TweenData) do
						Object[Property] = Lerper(0)
					end
				else
					for Property, Lerper in pairs(TweenData) do
						Object[Property] = Lerper(1)
					end
				end
				
				Maid:KillTask("PlaybackTask")

				--if PlaybackConnection then
				--	PlaybackConnection:Disconnect()
				--	PlaybackConnection = nil
				--else
				--	if InternalThread then
				--		coroutine.close(InternalThread)
				--		InternalThread = nil
				--	end
				--	return
				--end

				if DelayTime and TweenObject then
					TweenObject.PlaybackState = Enum.PlaybackState.Delayed;
					(DelayTime < 2 and Wait or wait)(DelayTime)
				end

				if Reverse then
					_ElapsedTime = 0
					Play(Layer + 1, false)
				else
					if Data.Reverses then
						_ElapsedTime = 0
						Play(Layer, true)
					else
						_ElapsedTime = 0
						Play(Layer + 1, false)
					end
				end
			else
				local Delta = Reverse and (1 - _ElapsedTime/Time) or (_ElapsedTime/Time)
				local Position = math.clamp(TweenFunction(Delta), 0, 1)

				for Property, Lerper in pairs(TweenData) do
					Object[Property] = Lerper(Position)
				end
			end
		end)
		--PlaybackConnection = EventStep:Connect()
		
		if TweenObject then
			TweenObject.PlaybackState = Enum.PlaybackState.Playing
		end
	end

	function TweenObject:Play()
		if Dead then
			return
		end
		if DelayOnStart then
			if DelayTime then
				TweenObject.PlaybackState = Enum.PlaybackState.Delayed;
				(DelayTime < 2 and Wait or wait)(DelayTime)
			end
		end

		_ElapsedTime = 0
		Play(1, false)
	end

	function TweenObject:Stop()
		if Dead then
			return
		end
		Maid:KillTask("PlaybackTask")
		TweenObject.PlaybackState = Enum.PlaybackState.Cancelled
		StoppedEvent:Fire()
	end

	function TweenObject:Resume()
		if Dead then
			return
		end
		Play(CurrentLayer, CurrentlyReversing)
		ResumedEvent:Fire()
	end

	return TweenObject :: TweenObject
end

return BoatTween
