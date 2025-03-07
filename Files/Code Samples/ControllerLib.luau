-- Author Purple (@VioletElementalist)
-- // THIS CODE IS NOT MEANT FOR 3RD PARTY USE, IT'S A SHOWCASE

-- A library used for easing controller support + easily on the fly switching hint icons between platforms

local Controller = {}
Controller.__index = Controller
local UIS = game:GetService("UserInputService")
local Collection = game:GetService("CollectionService")
local Content = game:GetService("ContentProvider")

Controller.Icons = {
	Xbox = {
		["ButtonA"] = "rbxassetid://117920160540395", -- KeyCode.ButtonA
		["ButtonB"] = "rbxassetid://125964320824793", -- KeyCode.ButtonB
		["ButtonX"] = "rbxassetid://71611418046576", -- KeyCode.ButtonX
		["ButtonY"] = "rbxassetid://134621360271435", -- KeyCode.ButtonY
		["ButtonLB"] = "rbxassetid://112616231645245", -- KeyCode.ButtonL1
		["ButtonLT"] = "rbxassetid://105119940742917", -- KeyCode.ButtonL2
		["ButtonLS"] = "rbxassetid://134624764706318", -- KeyCode.ButtonL3
		["ButtonRB"] = "rbxassetid://128795342566432", -- KeyCode.ButtonR1
		["ButtonRT"] = "rbxassetid://105330128126410", -- KeyCode.ButtonR2
		["ButtonRS"] = "rbxassetid://104621341441726", -- KeyCode.ButtonR3
		["ButtonStart"] = "rbxassetid://121503974335936", -- KeyCode.ButtonStart
		["ButtonSelect"] = "rbxassetid://110896135403748", -- KeyCode.ButtonSelect 
		
		["Thumbstick1"] = "rbxassetid://104504591238228",
		["Thumbstick2"] = "rbxassetid://138594847244649",
		["DPadUp"] = "rbxassetid://76051512288888",
		["DPadDown"] = "rbxassetid://109175761712154",
		["DPadLeft"] = "rbxassetid://106830975032999",
		["DPadRight"] = "rbxassetid://116091119947543",
	},
	PlayStation = {
		["ButtonCross"] = "rbxassetid://99494074835766", -- KeyCode.ButtonA
		["ButtonCircle"] = "rbxassetid://115976262771455", -- KeyCode.ButtonB
		["ButtonSquare"] = "rbxassetid://90962221906632", -- KeyCode.ButtonX
		["ButtonTriangle"] = "rbxassetid://138840693224027", -- KeyCode.ButtonY
		["ButtonL1"] = "rbxassetid://72613957664180", -- KeyCode.ButtonL1
		["ButtonL2"] = "rbxassetid://104934326755103", -- KeyCode.ButtonL2
		["ButtonL3"] = "rbxassetid://89371268072585", -- KeyCode.ButtonL3
		["ButtonR1"] = "rbxassetid://137656345575810", -- KeyCode.ButtonR1
		["ButtonR2"] = "rbxassetid://92318121333672", -- KeyCode.ButtonR2
		["ButtonR3"] = "rbxassetid://75963896108209", -- KeyCode.ButtonR3
		["ButtonOptions"] = "rbxassetid://128691732501806", -- KeyCode.ButtonStart

		["ButtonTouchpad"] = "rbxassetid://87827315045306", -- KeyCode.ButtonSelect 
		["ButtonShare"] = "rbxassetid://72173471256432", -- KeyCode.ButtonSelect 
		
		["Thumbstick1"] = "rbxassetid://75528437881987",
		["Thumbstick2"] = "rbxassetid://85496643591223",
		["DPadUp"] = "rbxassetid://131050189608674",
		["DPadDown"] = "rbxassetid://85047067702228",
		["DPadLeft"] = "rbxassetid://81999196060118",
		["DPadRight"] = "rbxassetid://81275925954202",
	},
}

Controller.ButtonMap = {
	Xbox = {
		[Enum.KeyCode.ButtonA.Name] = "ButtonA", -- KeyCode.ButtonA
		[Enum.KeyCode.ButtonB.Name] = "ButtonB", -- KeyCode.ButtonB
		[Enum.KeyCode.ButtonX.Name] = "ButtonX", -- KeyCode.ButtonX
		[Enum.KeyCode.ButtonY.Name] = "ButtonY", -- KeyCode.ButtonY
		[Enum.KeyCode.ButtonL1.Name] = "ButtonLB", -- KeyCode.ButtonL1
		[Enum.KeyCode.ButtonL2.Name] = "ButtonLT", -- KeyCode.ButtonL2
		[Enum.KeyCode.ButtonL3.Name] = "ButtonLS", -- KeyCode.ButtonL3
		[Enum.KeyCode.ButtonR1.Name] = "ButtonRB", -- KeyCode.ButtonR1
		[Enum.KeyCode.ButtonR2.Name] = "ButtonRT", -- KeyCode.ButtonR2
		[Enum.KeyCode.ButtonR3.Name] = "ButtonRS", -- KeyCode.ButtonR3
		[Enum.KeyCode.ButtonStart.Name] = "ButtonStart", -- KeyCode.ButtonStart
		[Enum.KeyCode.ButtonSelect.Name] = "ButtonSelect", -- KeyCode.ButtonSelect 
		[Enum.KeyCode.Thumbstick1.Name] = "Thumbstick1",
		[Enum.KeyCode.Thumbstick2.Name] = "Thumbstick2",
		[Enum.KeyCode.DPadUp.Name] = "DPadUp",
		[Enum.KeyCode.DPadDown.Name] = "DPadDown",
		[Enum.KeyCode.DPadLeft.Name] = "DPadLeft",
		[Enum.KeyCode.DPadRight.Name] = "DPadRight"
	},
	PlayStation = {
		[Enum.KeyCode.ButtonA.Name] = "ButtonCross", -- KeyCode.ButtonA
		[Enum.KeyCode.ButtonB.Name] = "ButtonCircle", -- KeyCode.ButtonB
		[Enum.KeyCode.ButtonX.Name] = "ButtonSquare", -- KeyCode.ButtonX
		[Enum.KeyCode.ButtonY.Name] = "ButtonTriangle", -- KeyCode.ButtonY
		[Enum.KeyCode.ButtonL1.Name] = "ButtonL1", -- KeyCode.ButtonL1
		[Enum.KeyCode.ButtonL2.Name] = "ButtonL2", -- KeyCode.ButtonL2
		[Enum.KeyCode.ButtonL3.Name] = "ButtonL3", -- KeyCode.ButtonL3
		[Enum.KeyCode.ButtonR1.Name] = "ButtonR1", -- KeyCode.ButtonR1
		[Enum.KeyCode.ButtonR2.Name] = "ButtonR2", -- KeyCode.ButtonR2
		[Enum.KeyCode.ButtonR3.Name] = "ButtonR3", -- KeyCode.ButtonR3
		[Enum.KeyCode.ButtonStart.Name] = "ButtonOptions", -- KeyCode.ButtonStart
		[Enum.KeyCode.ButtonSelect.Name] = "ButtonShare", -- KeyCode.ButtonSelect
		[Enum.KeyCode.Thumbstick1.Name] = "Thumbstick1",
		[Enum.KeyCode.Thumbstick2.Name] = "Thumbstick2",
		[Enum.KeyCode.DPadUp.Name] = "DPadUp",
		[Enum.KeyCode.DPadDown.Name] = "DPadDown",
		[Enum.KeyCode.DPadLeft.Name] = "DPadLeft",
		[Enum.KeyCode.DPadRight.Name] = "DPadRight"
	}
}

function Controller.new()
	local self = setmetatable({}, Controller)
	self.Maid = require(game.ReplicatedStorage.Maid).new()
	self.ActiveGamepad = nil --= self:getActiveGamepad()
	self.ControllerType = nil --= self:getConsoleType()
	self.LastInputType = nil
	self.CallbackPool = {}
	
	local function updateButtonIcons()
		for _, Button in Collection:GetTagged("ConsoleButton") do
			if Button:IsA("ImageButton") or Button:IsA("ImageLabel") then
				--print(Button, Button.Parent, Button.Parent.Parent, Button.Parent.Parent.Parent)
				--print(Button:GetAttribute("ConsoleKeyCode"), self.ButtonMap[self.ControllerType][Button:GetAttribute("ConsoleKeyCode")])
				pcall(function()
					Button.Image = self.Icons[self.ControllerType][self.ButtonMap[self.ControllerType][Button:GetAttribute("ConsoleKeyCode")]]
				end)
			end
		end
	end

	local function UpdateGamepadState()
		self.ActiveGamepad = self:getActiveGamepad()
		self.ControllerType = self:getConsoleType()
		updateButtonIcons()
		
		for _, Cb in self.CallbackPool do
			if typeof(Cb) == "function" then
				Cb(self.LastInputType == "Controller" and self.ActiveGamepad or nil, self.ControllerType)
			end
		end
		
		UIS.MouseIconEnabled = self.LastInputType ~= "Controller"
		
		if self.ActiveGamepad ~= nil then
			if not self.Maid:IsTreeAlive("GamepadInputBeganChecks")  then
				UIS.MouseIconEnabled = false
				self.Maid:GiveTreeTask("GamepadInputBeganChecks", "Main", UIS.InputBegan, function(input, gp)
					if self.ActiveGamepad == nil then return end

					local InputType = self.ButtonMap[self.ControllerType][input.KeyCode.Name] and "Controller" or "Other"

					if InputType ~= "Controller" and gp then
						return
					end

					if InputType ~= self.LastInputType then
						self.LastInputType = InputType
						UIS.MouseIconEnabled = self.LastInputType ~= "Controller"

						for _, Cb in self.CallbackPool do
							if typeof(Cb) == "function" then
								Cb(InputType == "Controller" and self.ActiveGamepad or nil, self.ControllerType)
							end
						end
					end
				end)
			end
		else
			UIS.MouseIconEnabled = true
			self.Maid:EndTree("GamepadInputBeganChecks")
		end
	end
	
	task.delay(1, function()
		UpdateGamepadState()
	end)
	
	if self.ActiveGamepad ~= nil then
		task.spawn(function()
			local toLoad = {}
			for _, Id in self.Icons[self.ControllerType] do
				table.insert(toLoad, Id)
			end
			
			Content:PreloadAsync(toLoad)
			toLoad = nil
		end)
	end

	self.Maid:GiveTask("OnButtonRegister", Collection:GetInstanceAddedSignal("ConsoleButton"), UpdateGamepadState)
	self.Maid:GiveTask("UpdateActiveGamepad", UIS.GamepadConnected, UpdateGamepadState)
	self.Maid:GiveTask("UpdateOnGamepadDisconnect", UIS.GamepadDisconnected, UpdateGamepadState)
	
	return self
end

function Controller:Dispose()
	if self.Maid then
		self.Maid:Dispose()
		self.Maid = nil
	end

	--if self.ThreadAccumulator then
	--	self.ThreadAccumulator:Dispose()
	--	self.ThreadAccumulator = nil
	--end

	for i,v in self do
		self[i] = nil
	end

	setmetatable(self, nil)
	self = nil
end

function Controller:addCallbackOnGamepadStateChanged(callback)
	table.insert(self.CallbackPool, callback)
end

function Controller:registerConsoleButton(Button: ImageButton | ImageLabel, KeyName: string)
	Button:SetAttribute("ConsoleKeyCode", KeyName)
	Button:AddTag("ConsoleButton")
end

function Controller:getConsoleType()
	local KeycodeString = UIS:GetStringForKeyCode(Enum.KeyCode.ButtonX)
	return self.Icons.PlayStation[KeycodeString] and "PlayStation" or "Xbox"
end

function Controller:getActiveGamepad()
	local activeGamepad = nil

	local connectedGamepads = UIS:GetConnectedGamepads()

	if #connectedGamepads > 0 then
		for _, gamepad in connectedGamepads do
			if activeGamepad == nil or gamepad.Value < activeGamepad.Value then
				activeGamepad = gamepad
			end
		end
	end

	return activeGamepad
end

return Controller
