-- Author Purple (@VioletElementalist)
-- // THIS CODE IS NOT MEANT FOR 3RD PARTY USE, IT'S A SHOWCASE

local Haptic = {}
Haptic.__index = Haptic

local UIS = game:GetService("UserInputService")
local HapticService = game:GetService("HapticService")

function Haptic.new()
	local self = setmetatable({}, Haptic)
	self.CurrentVibration = {}
	self.ThreadAccumulator = require(game.ReplicatedStorage.Libs.ThreadAccumulator).new()
	self.Maid = require(game.ReplicatedStorage.Maid).new()
	self.ActiveGamepad = self:getActiveGamepad()
	
	local function UpdateGamepadState()
		self.ActiveGamepad = self:getActiveGamepad()
	end
	
	self.Maid:GiveTask("UpdateActiveGamepad", UIS.GamepadConnected, UpdateGamepadState)
	self.Maid:GiveTask("UpdateOnGamepadDisconnect", UIS.GamepadDisconnected, UpdateGamepadState)
	
	return self
end

function Haptic:Dispose()
	self:StopVibration("All")
	
	if self.Maid then
		self.Maid:Dispose()
		self.Maid = nil
	end
	
	if self.ThreadAccumulator then
		self.ThreadAccumulator:Dispose()
		self.ThreadAccumulator = nil
	end
	
	for i,v in self do
		self[i] = nil
	end
	
	setmetatable(self, nil)
	self = nil
end

function Haptic:IsMotorAvailable(motor: "Small" | "Large")
	return HapticService:IsMotorSupported(self.ActiveGamepad, Enum.VibrationMotor[motor])
end

function Haptic:getActiveGamepad()
	local activeGamepad = nil

	local connectedGamepads = UIS:GetConnectedGamepads()

	if #connectedGamepads > 0 then
		for _, gamepad in connectedGamepads do
			if activeGamepad == nil or gamepad.Value < activeGamepad.Value then
				activeGamepad = gamepad
			end
		end
	end

	if activeGamepad ~= nil then
		if not self.CurrentVibration[activeGamepad] then
			self.CurrentVibration[activeGamepad] = {}
		end
	else
		self:StopVibration("All")
	end

	return activeGamepad
end

function Haptic:LargeVibration(intensity: number, duration: number)	
	self.ThreadAccumulator:KillThread("Large")
	
	if self.ActiveGamepad then
		if self:IsMotorAvailable("Large") then
			local CurrentIntensity = math.clamp(intensity, 0, 1)

			HapticService:SetMotor(self.ActiveGamepad, Enum.VibrationMotor.Large, CurrentIntensity)
			self.CurrentVibration[self.ActiveGamepad]["Large"] = CurrentIntensity

			self.ThreadAccumulator:AddThread("Large", task.delay(duration or 1, function()
				HapticService:SetMotor(self.ActiveGamepad, Enum.VibrationMotor.Large, 0)
				self.CurrentVibration[self.ActiveGamepad]["Large"] = 0
			end))
			return
		end

		self:AttemptToVibrateFallbackMotor("Large", intensity, duration)
	end
end

function Haptic:AttemptToVibrateFallbackMotor(motor: "Small" | "Large", intensity: number, duration: number)
	if self.ActiveGamepad then
		if motor == "Large" then
			if self:IsMotorAvailable("Small") then
				self:SmallVibration(intensity*2, duration)
			end
			return
		end

		if motor == "Small" then
			if self:IsMotorAvailable("Large") then
				self:LargeVibration(intensity/2, duration)
			end
			return
		end
	end
end

function Haptic:SmallVibration(intensity: number, duration: number)
	self.ThreadAccumulator:KillThread("Small")

	if self.ActiveGamepad then
		if self:IsMotorAvailable("Small") then
			local CurrentIntensity = math.clamp(intensity, 0, 1)
			HapticService:SetMotor(self.ActiveGamepad, Enum.VibrationMotor.Small, CurrentIntensity)
			self.CurrentVibration[self.ActiveGamepad]["Small"] = CurrentIntensity

			self.ThreadAccumulator:AddThread("Small", task.delay(duration or 1, function()
				HapticService:SetMotor(self.ActiveGamepad, Enum.VibrationMotor.Small, 0)
				self.CurrentVibration[self.ActiveGamepad]["Small"] = 0
			end))
			return
		end

		self:AttemptToVibrateFallbackMotor("Small", intensity, duration)
	end
end

function Haptic:StopVibration(motor: "Small" | "Large" | "All")
	if motor == "All" and self.ActiveGamepad then
		self.ThreadAccumulator:KillThread("Small")
		self.ThreadAccumulator:KillThread("Large")
		
		HapticService:SetMotor(self.ActiveGamepad, Enum.VibrationMotor["Small"], 0)
		HapticService:SetMotor(self.ActiveGamepad, Enum.VibrationMotor["Large"], 0)
		self.CurrentVibration[self.ActiveGamepad]["Small"] = 0
		self.CurrentVibration[self.ActiveGamepad]["Large"] = 0
		return
	end
	
	self.ThreadAccumulator:KillThread(motor)
	
	if self.ActiveGamepad then
		HapticService:SetMotor(self.ActiveGamepad, Enum.VibrationMotor[motor], 0)
	end
end

return Haptic
