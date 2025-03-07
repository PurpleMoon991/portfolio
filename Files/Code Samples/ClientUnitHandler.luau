-- Author Purple (@VioletElementalist)
-- // THIS CODE IS NOT MEANT FOR 3RD PARTY USE, IT'S A SHOWCASE

debug.setmemorycategory("Worker_ClientUnitHandlerMain")
local module = {}

workspace:WaitForChild("Players")
workspace:WaitForChild("Map")
workspace:WaitForChild("NPC_Client_Models")
workspace:WaitForChild("GroundPlacements")
workspace:WaitForChild("AirPlacements")

local plr = game.Players.LocalPlayer
local plrGui = plr.PlayerGui
local mouse = plr:GetMouse()
local CurrentCamera = workspace.CurrentCamera

local ContentProvider = game:GetService("ContentProvider")
local http = game:GetService("HttpService")
local run = game:GetService("RunService")
local main = plrGui:WaitForChild("Main")
local slots = main:WaitForChild("Slotbar")
local UnitCard = main:WaitForChild("UnitCard2")
local UnitManager = main:WaitForChild("UnitManagerFrame_New")
local StarChallengeNew = plrGui:WaitForChild("StarGUI"):WaitForChild("StarsChallenge_New")
local replicated = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local Collection = game:GetService("CollectionService")
local Events = replicated:WaitForChild("Events")
local Debris = require(replicated.Libs.DebrisSystemV2)
local AnimModule = require(replicated.AnimModule)
local ClientLib = require(replicated.Libs.ClientStuff)
local SoundWrapper = require(replicated.Libs.SoundWrapper)
local Shapecast = require(replicated.Shapecast)
local BuffLib = require(replicated.Libs.BuffLib)
local GameVariables = replicated.GameVariables
local FastVector = require(replicated.Libs.FastVector)
local UnitCardHandler = require(replicated.Libs.UnitCardHandler)
local TweenMaid = require(replicated.Libs.TweenMaid).new()

local MobileButtonsUI = plrGui:WaitForChild("Main"):WaitForChild("MobileControlStuff")

local visualize = require(game.ReplicatedStorage.Visualize)

local GradientRegistry = _G.Registry.registry.GradientAnimations

local collection = game:GetService("CollectionService")
local excludeTable = {
	workspace.Players,
	workspace.NPC_Client_Models,
	workspace.UnitVisuals,
	workspace.UnitsPlaced,
	workspace.Map:FindFirstChild("Air Unit Hills")
}

local PATH_DEBUG = false

local function ProcessPlacementAreas(root)
	for i, v in pairs(root:GetChildren()) do

		if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
			v.Name = "PlacementArea"

			if not v:HasTag("GroundPlacements") then
				v:AddTag("GroundPlacements")
			end
		end
	end
end

ProcessPlacementAreas(workspace.AirPlacements)
ProcessPlacementAreas(workspace.GroundPlacements)

local RangeSphereRayParams = RaycastParams.new()
RangeSphereRayParams.FilterType = Enum.RaycastFilterType.Include
RangeSphereRayParams.RespectCanCollide = false
RangeSphereRayParams.IgnoreWater = true
RangeSphereRayParams.FilterDescendantsInstances = {workspace.GroundPlacements}

local PlacementRayParams = RaycastParams.new()
PlacementRayParams.FilterType = Enum.RaycastFilterType.Include
PlacementRayParams.IgnoreWater = true
PlacementRayParams.FilterDescendantsInstances = {workspace.Map, workspace.GroundPlacements, workspace.AirPlacements, workspace.UnitsPlaced}
require(script:WaitForChild("SetUnitHumStates"))()

local RarityTab = {
	["Exclusive"] = {Gradient = "Exclusive", Speed = 2.2},
	["Secret"] = {Gradient = "Secret", Speed = 1.5},
	["Mythical"] = {Gradient = "Mythical", Speed = 2},
	["Legendary"] = {Gradient = "Legendary", Speed = 1.1},
	["Epic"] = {Gradient = "Rare", Speed = 1},
	["Rare"] = {Gradient = "Rare", Speed = .8},
}

local Maid = require(replicated.Maid)
Maid = Maid.new()

local mouse = plr:GetMouse()

local defaultSize  = slots.Slot1.Size
local hoveredSize = UDim2.new(0.22, 0,1.1, 0)
local DefaultHighlight = {FillColor = Color3.fromRGB(50,100,150), FillTransparency = 0.6}
local EnemyHighlight = {FillColor = Color3.fromRGB(150,0,0), FillTransparency = 0.3}
local PlacementHighlight = {FillTransparency = 1}

local cachedUnits = {}

local ViewportLib = require(game.ReplicatedStorage.Libs.UnitSlotViewportFrame)
local UILib = require(game.ReplicatedStorage.Libs.UtilitiesUI)
local UIMotion = require(replicated.Libs.UIMotion)

local AbilityAutoUseList = {}

function module:checkForUnitOnRay()
	local origin = mouse.Origin.Position
	local direction = mouse.UnitRay.Direction*500

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = {workspace.UnitsPlaced}

	local result = workspace:Raycast(origin, direction, Params)

	if result then
		local FoundModel = ClientLib:reverseRecursiveFindModel(result.Instance)
		
		if FoundModel and FoundModel.Parent == workspace.UnitsPlaced then
			local VisualModelLink = FoundModel:FindFirstChild("VisualModelLink")
			if VisualModelLink then
				return VisualModelLink.Value
			end
		end
		
		return result.Instance
	end

	return mouse.Target
end

function module:checkForNpcOnRay()
	local origin = mouse.Origin.Position
	local direction = mouse.UnitRay.Direction*500

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = {workspace.NPC_Client_Models}

	local result = workspace:Raycast(origin, direction, Params)

	if result then
		local FoundModel = ClientLib:reverseRecursiveFindModel(result.Instance)

		if FoundModel and FoundModel.Parent == workspace.NPC_Client_Models then
			return FoundModel
		end

		return result.Instance
	end

	return mouse.Target
end

function module:GetAllyUnitsInRange(Unit)
	local CorrectDiameter = BuffLib:GetRangeScaled(Unit)  --_G.UnitUtils.GetUnitRange(Unit)

	local AllyUnitsBuffer = {}

	for _, AllyUnit in pairs(workspace.UnitsPlaced:GetChildren()) do
		if AllyUnit ~= Unit then
			local magnitudeCheck = FastVector:FastMagnitudeVec2XZ(Unit.HumanoidRootPart.Position, AllyUnit.HumanoidRootPart.Position)

			if magnitudeCheck <= CorrectDiameter then
				table.insert(AllyUnitsBuffer, AllyUnit)
			end
		end
	end

	return AllyUnitsBuffer
end

function module:GetUnitFromSlot(data, UUID)
	for i,v in pairs(data) do
		if v.UUID == UUID then
			return v
		end
	end
	
	return {}
end

function module:start()
	
	GameVariables.GameFinished.Changed:Connect(function()
		if _G.SharedTrash then
			for i,v in _G.SharedTrash do
				if v and v.Parent then
					v:Destroy()
				end
			end

			_G.SharedTrash = {}
		else
			_G.SharedTrash = {}
		end
	end)
	
	local TempFolder = workspace.Temp
	local CurrentlySelectedObjectValue = TempFolder:FindFirstChild("CurrentlySelected")
	local UnitsTagProcessor = require(replicated.Libs.UnitTagsProcessor).init()
	
	if not CurrentlySelectedObjectValue then
		local EventSelection = Instance.new("ObjectValue")
		EventSelection.Name = "CurrentlySelected"
		EventSelection.Parent = TempFolder

		CurrentlySelectedObjectValue = EventSelection
	end

	-------------------------------------
	local DataAccess = require(game.ReplicatedStorage.Libs.DataAccessAPIClient)
	local DataAPI = DataAccess:GetAPI()
	local PlrProfile = DataAPI:GetLocalProfile()
	local PlrProfileClass = DataAPI:GetLocalProfileClass()
	local HighlightLib = require(replicated.HighlightLib)
	local rot = 0
	local Registry = _G.Registry.registry
	local UnitsRegistry = Registry.Units
	
	local HapticController = require(game.ReplicatedStorage.Libs.HapticController).new()
	local ControllerLib = require(game.ReplicatedStorage.Libs.ControllerLib).new()
	
	local defaultHeight = 2.8112175464630127
	local defaultCircle = 1.3164

	local SlotButton
	local SlotIndex = 0

	
	--local Hotbar = require(replicated.Libs.HotbarLibrary).new()
	--local PlrSlotbar = PlrProfileClass:GetField("Slotbar")
	
	local LoadedIcons = {}
	
	local UnitSaveTemplate = {
		Name = "Dummy",
		Level = 1,
	}
	
	local SlotbarTemplate = {
		UUID = "",
	}
	
	local InventoryTemplate = {
		["UUID"] = {
			UnitName = "",
			Trait = "",
			Level = 0,
			Exp = 0,
			AbilityTree = {},
			StatsPotential = {},
			StatsTraining = {},
		},
	}
	
	local PlacementHighlight = {
		AbleToPlace = {
			FillTransparency = 0.6,
			OutlineTransparency = 0.6,
			FillColor = Color3.fromRGB(149, 244, 255),
		},
		UnableToPlace = {
			FillTransparency = 0.6,
			OutlineTransparency = 0.6,		
			FillColor = Color3.fromRGB(255, 0, 0),
		},
		Fade = {
			FillTransparency = 1,
			OutlineTransparency = 1,		
			FillColor = Color3.fromRGB(200, 200, 200),
		}
	}
	
	local CanPlaceColors = {
		CanPlace = Color3.fromRGB(150, 255, 255),
		CannotPlace = Color3.fromRGB(200, 0, 0),
		CanPlaceUpgraded = Color3.fromRGB(100,100,100),
		CannotPlaceUpgraded = Color3.fromRGB(125,0,0),
	}
	
	--Auto ability use handler
	--task.spawn(function()
	--	while task.wait(.2) do
	--		for i, unit in AbilityAutoUseList do
	--			if not unit then table.remove(AbilityAutoUseList, i) continue end
				
	--			local Ability = _G.Registry.registry.SpecialAbilities[unit.configuration.SpecialAbility.Value]
	--			if Ability then
	--				if _G.SpecialAbilitiesCD["CheckCD"](unit, Ability) then
	--					Events.Unit:FireServer("SpecialAbility", {unit = unit, AutoUse = true})
	--				end
	--			end
	--		end
	--	end
	--end)
	
	local Hotbar = require(replicated.Libs.HotbarLibrary).new()
	local SavedSlotbar = PlrProfileClass:GetField("Slotbar")

	local function updateSlotbarCallback()
		--SavedSlotbar = PlrProfileClass:GetField("Slotbar")
		--local unitData = PlrProfileClass:GetField("Inventory").Units

		--for _slot,_UnitData in SavedSlotbar do

		--	local _UnitName, _UUID = _UnitData.UnitName, _UnitData.UUID

		--	if _UnitName and _UnitName ~= "" then
		--		local _FoundInRegistry = UnitsRegistry[_UnitName]
		--		if _FoundInRegistry then
		--			local _UnitMisc = _FoundInRegistry.misc
		--			local _UnitConfig = _FoundInRegistry.configuration
		--			local _UnitAnims =  _FoundInRegistry.animations



		--			local trait = unitData[_UUID]
		--			if trait then
		--				trait = trait["Trait"]
		--			end

		--			--print(_UnitData, unitData)

		--			Hotbar:UpdateCharacter(tonumber(string.match(_slot,"%d")), {UUID = _UUID, UnitData = unitData[_UUID]})
		--		end
		--	end
		--	if _UnitName == "" or not _UnitName then
		--		Hotbar:UpdateCharacter(tonumber(string.match(_slot,"%d")))
		--	end
		--end
		
		SavedSlotbar = PlrProfileClass:GetField("Slotbar")
		local unitData = PlrProfileClass:GetField("Inventory").Units
		local applicableSlots = PlrProfileClass:GetField("SlotsApplicable")
		--print(applicableSlots)
		for i=1, 6 do
			local _slot = "Slot"..i
			local _UnitData = SavedSlotbar[_slot]
			if i > applicableSlots then
				Hotbar:UpdateCharacter(tonumber(string.match(_slot,"%d")), {
					Locked = true
				})
				continue
			end
			local _UnitName, _UUID = _UnitData.UnitName, _UnitData.UUID

			if _UnitName and _UnitName ~= "" then
				local _FoundInRegistry = UnitsRegistry[_UnitName]
				if _FoundInRegistry then
					local _UnitMisc = _FoundInRegistry.misc
					local _UnitConfig = _FoundInRegistry.configuration
					local _UnitAnims =  _FoundInRegistry.animations



					local trait = unitData[_UUID]
					if trait then
						trait = trait["Trait"]
					end

					--print(_UnitData, unitData)

					Hotbar:UpdateCharacter(tonumber(string.match(_slot,"%d")), {UUID = _UUID, UnitData = unitData[_UUID]})
				end
			end
			if _UnitName == "" or not _UnitName then
				Hotbar:UpdateCharacter(tonumber(string.match(_slot,"%d")), {Locked = false})
			end
		end
	end

	updateSlotbarCallback()

	PlrProfileClass:GetFieldChangedSignal("Slotbar"):Connect(updateSlotbarCallback)

	--PlrSlotbar:GetPropertyChangedSignal("Value"):Connect(updateSlotbarCallback)
	
	local Placements = {
		Ground = workspace:WaitForChild("GroundPlacements",20),
		Air = workspace:WaitForChild("AirPlacements",20)
	}
	
	mouse.TargetFilter = workspace.Temp
	
	local CurrentlyPlacing
	local CurrentSlot
	local UnitRange
	local ShowUpgradedRange
	local UnitConfig
	local Tweens = {}
	local RangeTweens = {}
	local Tasks = {}
	local CanPlace = false
	local AirPlacements = workspace.AirPlacements:GetChildren()
	local GroundPlacements = workspace.GroundPlacements:GetChildren()
	local CurrentlySelected
	local CircleIndicatorPreview
	local CurrentlySelectedVisualModel
	local LastSelected
	--local UnitCardFrame = UnitCard.UnitCard
	local CurrentCardViewport
	local BoundBoxSize
	local RangeTweenTime = .35
	
	local CurrentCircleRadius
	
	-- Placements raycast
	local direction = Vector3.new(0,-200,0)
	local PlacementRaycastParams = RaycastParams.new()
	PlacementRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	PlacementRaycastParams.FilterDescendantsInstances = {workspace.Players, workspace.Effects, workspace.Temp, workspace.NPC_Client_Models, Collection:GetTagged("PLR_TAG")}
	---
	
	local function ImmediatelyEmitSlowParticles(_base: Instance, loopThruDescendants: boolean)
		for i,v in pairs(not loopThruDescendants and _base:GetChildren() or _base:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(1)
				--v.TimeScale = 1
			end
		end
	end
	
	Maid:GiveTreeTask("UnitCard", "SpecialAbilityUseEvent", Events.SpecialAbilityUse.OnClientEvent,function(unit,Enemy)
		local Ability = _G.Registry.registry.SpecialAbilities[unit.configuration.SpecialAbility.Value]
		if Ability then
			_G.SpecialAbilitiesCD["AddCD"](unit, Ability)
			local target = Enemy and workspace.NPC_Client_Models:FindFirstChild(Enemy)
			UnitCardHandler:UpdateCard()
			Ability:onClient(unit.VisualModelLink.Value,target)
		end
	end)

	
	Maid:GiveTask("StatusEffectClient",Events.StatusEffect.OnClientEvent,function(StatusEffect, Unit, Enemies, Duration)
		local Status = _G.Registry.registry.StatusEffects[StatusEffect]
		if Status then
			Status:OnClient(Unit, Enemies, Duration)
		end
	end)

	local function SetupPlacementHighlight(RootFolder)
		if not RootFolder:FindFirstChild("PlacementHighlight") then
			script.PlacementHighlight:Clone().Parent = RootFolder
			if RootFolder.Name == "AirPlacements" then
				for i, v in RootFolder:GetChildren() do
					script.PlacementAreaBillboard:Clone().Parent = v
				end
			end
		end
	end
	
	SetupPlacementHighlight(workspace.AirPlacements)
	SetupPlacementHighlight(workspace.GroundPlacements)
	
	local function CheckIfCanPlace(origin, unitPlacementType)		
		local function internalCheck(checkObject)
			if checkObject.Name == "PlacementArea" then
				local IsGroundPlacement = checkObject.Parent == workspace.GroundPlacements
				local IsAirPlacement = checkObject.Parent == workspace.AirPlacements

				local Result = {
					Hybrid = (IsAirPlacement or IsGroundPlacement),
					Air = IsAirPlacement,
					Ground = IsGroundPlacement,
				}

				return Result[unitPlacementType]
			end
			
			if PATH_DEBUG then
				if not checkObject:HasTag("DEBUGNamed") then
					checkObject:AddTag("DEBUGNamed")
					checkObject.Name = game.HttpService:GenerateGUID(false)
				end

				print(checkObject.Name)
			end

			return false
		end
		
		origin += Vector3.new(0,BoundBoxSize.Y,0)
		
		local RaycastResults = {}
		
		
		local Origin = origin.Position
		--local Radius = 10
		for i = 1, math.pi^2, .5 do 
			
			local X = Origin.X + (CurrentCircleRadius * math.cos(i))
			local Z = Origin.Z + (CurrentCircleRadius * math.sin(i))
			table.insert(RaycastResults, workspace:Raycast(Vector3.new(X, Origin.Y, Z), direction, PlacementRayParams))
			--visualize.DirectionalVector(Vector3.new(X, Origin.Y, Z), direction)
		end
		
		table.insert(RaycastResults, workspace:Spherecast(Origin, CurrentCircleRadius, direction, PlacementRayParams))
		
		local PassedChecks = true
		
		for Side, Result in RaycastResults do
			if not internalCheck(Result.Instance) then
				--print(Result.Instance)
				PassedChecks = false
				break
			end
		end
		
		--print(PassedChecks)
		
		return PassedChecks
	end
	
	local function cleanupUnitRange()
		if UnitRange then
			UnitRange:Destroy()
			UnitRange = nil
			
			if ShowUpgradedRange then
				ShowUpgradedRange:Destroy()
				ShowUpgradedRange = nil
			end
			
			--Maid:KillTask("RotateSphere")

			for i,_Tween in pairs(RangeTweens) do
				_Tween:Cancel()
			end

			table.clear(RangeTweens)
		end
	end
	
	local function SetupRangeSphere(_range, _parent, _config)
		_range *= 2.5
		cleanupUnitRange()
		Maid:KillTask("ParticleEnabler")
		
		local Size = Vector3.new(_range,0,_range)/2

		UnitRange = replicated.Effects.UnitRange.UnitRange:Clone()
		UnitRange.Parent = _parent
		
		task.spawn(function()
			if _G.ClientSettings["ShowMaxRangeOnPlace"] and _config then
				ShowUpgradedRange = replicated.Effects.UnitRange.UnitRange:Clone()
				ShowUpgradedRange.SurfaceGui.Outline.ImageTransparency = .5
				ShowUpgradedRange.SurfaceGui.Base.ImageTransparency = .95
				ShowUpgradedRange.Parent = _parent



				local _MAX_RANGE

				--print("here0")


				if CurrentlyPlacing ~= nil then
					_MAX_RANGE = _config.Range
					
					for i = #_config.UpgradesInfo, 1, -1 do
						if _config.UpgradesInfo[i].Range then
							_MAX_RANGE = _config.UpgradesInfo[i].Range
							break
						end
					end
					
					_MAX_RANGE = BuffLib:GetInitialRangeOnPlaceCustomRange(SavedSlotbar[CurrentSlot].UUID, _MAX_RANGE)
				elseif CurrentlySelected ~= nil then
					local config = CurrentlySelected.configuration
					local currentUpg = config.CurrentUpgrade.Value
					local nextUpg = _config.UpgradesInfo[currentUpg+1]
					
					_MAX_RANGE = config.Range.Value
					
					--print("range", _MAX_RANGE)
					
					if nextUpg then 
						_MAX_RANGE = nextUpg.Range or _MAX_RANGE
						
						--print("range after", _MAX_RANGE)
						
						_MAX_RANGE *= BuffLib:CalculateAllBuffs(CurrentlySelected).AllBuffs.Range
						--print("here")
					else
						--print("returned")
						return
					end
				end
				
				_MAX_RANGE *= 2.5

				local Size2 = Vector3.new(_MAX_RANGE,0,_MAX_RANGE)/2

				local LocalTween = Tween:Create(ShowUpgradedRange, TweenInfo.new(RangeTweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Size2})
				RangeTweens[#RangeTweens+1] = LocalTween

				LocalTween:Play()
			end
		end)
		
		--UnitRange.FF.Particles.Attachment.a.Size = NumberSequence.new(Size.X/3.4713)
		--UnitRange.FF2.Particles.ring.Size = NumberSequence.new(Size.X/1.60429067919)

		local LocalTween = Tween:Create(UnitRange, TweenInfo.new(RangeTweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Size})
		--local LocalTween2 = Tween:Create(UnitRange.FF2, TweenInfo.new(RangeTweenTime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {Size = Vector3.new(Size.X,0.001,Size.Z)})

		RangeTweens[#RangeTweens+1] = LocalTween
		LocalTween:Play()
		--LocalTween2:Play()
	end
	
	local function updateRangeSpherePos(dt, _pivot,offset)
		local cast = workspace:Raycast(_pivot.Position, Vector3.new(0,-50,0), RangeSphereRayParams)

		if cast then
			_pivot = CFrame.new(cast.Position+Vector3.new(0,offset,0))--*_pivot.Rotation
		end
		
		if UnitRange then
--			print(typeof(_pivot))
			UnitRange.Position = _pivot.Position---Vector3.new(0,offset,0) ---Vector3.new(0,UnitRange.Size.Y/16,0)
			UnitRange.Orientation += Vector3.new(0, 20*dt,0)
			--UnitRange:PivotTo((_pivot)*CFrame.Angles(0,math.rad(UnitRange.Rotation.Y)+(math.pi*0.01)/25,0))
		end
		
		if ShowUpgradedRange then
			--			print(typeof(_pivot))
			ShowUpgradedRange.Position = _pivot.Position---Vector3.new(0,offset,0) ---Vector3.new(0,UnitRange.Size.Y/16,0)
			ShowUpgradedRange.Orientation += Vector3.new(0, 20*dt,0)
			--UnitRange:PivotTo((_pivot)*CFrame.Angles(0,math.rad(UnitRange.Rotation.Y)+(math.pi*0.01)/25,0))
		end	
		
	--	UnitRange.FF2.CFrame = UnitRange.FF.CFrame*CFrame.new(0,-(UnitRange.FF.Size.Y/2),0)
	end
	
	local function LoopThruWithCallback(_table, callback)
		for i,v in pairs(_table) do
			callback(i,v)
		end
	end

	local function HighlightPlacements(state, unitPlacementType)

		local AbleTo = unitPlacementType == "Air" and AirPlacements or GroundPlacements
		local UnableTo = unitPlacementType == "Air" and GroundPlacements or AirPlacements

		local function AbleCallback(i,_Placement)
			local LocalTween = Tween:Create(_Placement.Parent.PlacementHighlight, TweenInfo.new(.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In), PlacementHighlight.AbleToPlace)
			Tweens[#Tweens+1] = LocalTween
			LocalTween:Play()
			
			for i,v in Collection:GetTagged("RestrictedArea") do
				local LocalTween = Tween:Create(v, TweenInfo.new(.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = .65})
				Tweens[#Tweens+1] = LocalTween
				LocalTween:Play()
			end
			
			if _Placement.Parent.Name == "AirPlacements" and not _Placement:HasTag("NoAirDisplay") then
				local LocalTween = Tween:Create(_Placement.PlacementAreaBillboard.TextLabel, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 0})
				Tweens[#Tweens+1] = LocalTween
				LocalTween:Play()

				local LocalTween = Tween:Create(_Placement.PlacementAreaBillboard.TextLabel.UIStroke, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Transparency = 0})
				Tweens[#Tweens+1] = LocalTween
				LocalTween:Play()
			end
		end

		local function UnableCallback(i,_Placement)
			local LocalTween = Tween:Create(_Placement.Parent.PlacementHighlight, TweenInfo.new(.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In), PlacementHighlight.UnableToPlace)
			Tweens[#Tweens+1] = LocalTween
			LocalTween:Play()
			
			for i,v in Collection:GetTagged("RestrictedArea") do
				local LocalTween = Tween:Create(v, TweenInfo.new(.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = .65})
				Tweens[#Tweens+1] = LocalTween
				LocalTween:Play()
			end
			
			if _Placement.Parent.Name == "AirPlacements" and not _Placement:HasTag("NoAirDisplay") then
				local LocalTween = Tween:Create(_Placement.PlacementAreaBillboard.TextLabel, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 1})
				Tweens[#Tweens+1] = LocalTween
				LocalTween:Play()

				local LocalTween = Tween:Create(_Placement.PlacementAreaBillboard.TextLabel.UIStroke, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Transparency = 1})
				Tweens[#Tweens+1] = LocalTween
				LocalTween:Play()
			end
		end

		local function FadeCallback(i,_Placement)
			local LocalTween = Tween:Create(_Placement.Parent.PlacementHighlight, TweenInfo.new(.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), PlacementHighlight.Fade)
			Tweens[#Tweens+1] = LocalTween
			LocalTween:Play()
			
			for i,v in Collection:GetTagged("RestrictedArea") do
				local LocalTween = Tween:Create(v, TweenInfo.new(.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 1})
				Tweens[#Tweens+1] = LocalTween
				LocalTween:Play()
			end
			
			if _Placement.Parent.Name == "AirPlacements" and not _Placement:HasTag("NoAirDisplay") then
				local LocalTween = Tween:Create(_Placement.PlacementAreaBillboard.TextLabel, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 1})
				Tweens[#Tweens+1] = LocalTween
				LocalTween:Play()
				
				local LocalTween = Tween:Create(_Placement.PlacementAreaBillboard.TextLabel.UIStroke, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 1})
				Tweens[#Tweens+1] = LocalTween
				LocalTween:Play()
			end
		end


		for i,_Tween in pairs(Tweens) do
			_Tween:Cancel()
			_Tween:Destroy()
		end

		Tweens = {}
		
		if unitPlacementType == "Hybrid" then
			LoopThruWithCallback(AirPlacements, state and AbleCallback or FadeCallback)
			LoopThruWithCallback(GroundPlacements, state and AbleCallback or FadeCallback)
			return
		end

		LoopThruWithCallback(AbleTo, state and AbleCallback or FadeCallback)
		LoopThruWithCallback(UnableTo, state and UnableCallback or FadeCallback)
	end

	local function setPlaceIndicatorColor(canPlace)
		if UnitRange then
			local _CurrentColor = CanPlace and CanPlaceColors.CanPlace or CanPlaceColors.CannotPlace
		--	UnitRange.Color = _CurrentColor
			UnitRange.SurfaceGui.Base.ImageColor3 = _CurrentColor
			UnitRange.SurfaceGui.Outline.ImageColor3 = _CurrentColor
			
			if ShowUpgradedRange then
				local _CurrentColor2 = CanPlace and CanPlaceColors.CanPlaceUpgraded or CanPlaceColors.CannotPlaceUpgraded
				ShowUpgradedRange.SurfaceGui.Base.ImageColor3 = _CurrentColor2
				ShowUpgradedRange.SurfaceGui.Outline.ImageColor3 = _CurrentColor2
			end
			
			--UnitRange.FF2.Color = _CurrentColor
			--UnitRange.FF2.Particles.ring.Color = ColorSequence.new(_CurrentColor)
		end
	end
	
	local function StopPlacement()
		if CurrentlyPlacing then
			local isMobile = uis.TouchEnabled and not uis.KeyboardEnabled and not uis.MouseEnabled

			if isMobile then
				if CurrentCamera.CameraType == Enum.CameraType.Fixed then
					CurrentCamera.CameraType = Enum.CameraType.Custom
				end
				_G.Maid.shared:EndTree("MobileControlsClientUnitHandler")
				TweenMaid:GiveTask("MobilePlacesPopUp", Tween:Create(MobileButtonsUI, TweenInfo.new(.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, 2)}))
			end
			HighlightPlacements(false, UnitConfig.PlacementType)
			
			if CurrentlyPlacing then
				CurrentlyPlacing:Destroy()
			end
			
			if UnitRange then
				UnitRange:Destroy()	
			end

			if ShowUpgradedRange then
				ShowUpgradedRange:Destroy()
				ShowUpgradedRange = nil
			end
			
			if CircleIndicatorPreview then
				CircleIndicatorPreview:Destroy()
			end
			
			--if uis.KeyboardEnabled then
			--	Tween:Create(KeybingHintsUI.ContainerPC,TweenInfo.new(.2),{Position = UDim2.fromScale(-.1,.5)}):Play()
			--elseif not uis.KeyboardEnabled and uis.TouchEnabled then
			--	Maid:EndTree("MobileHintButtons")
			--	Tween:Create(KeybingHintsUI.ContainerMobile,TweenInfo.new(.2),{Position = UDim2.fromScale(-.1,.5)}):Play()	
			--end
			
			Maid:EndTree("UnitPlacementTree")
			CurrentlyPlacing = nil
			BoundBoxSize = nil
			CurrentCircleRadius = nil
			CurrentSlot = nil
			UnitConfig = nil
			UnitRange = nil
			CircleIndicatorPreview = nil
			CanPlace = false
		end
	end
	
	local PlacePos
	
	local function PlaceUnit()
		--print("heya")
		--print(CurrentlyPlacing, CanPlace)
		if CurrentlyPlacing and CanPlace then
			--print("heya2")
			
			local isMobile = uis.TouchEnabled and not uis.KeyboardEnabled and not uis.MouseEnabled
			local _CurrentPivot = isMobile and CFrame.new(PlacePos)+Vector3.new(0,1,0) or mouse.Hit+Vector3.new(0,1,0) --CurrentlyPlacing:GetPivot()
			local result = CheckIfCanPlace(_CurrentPivot, UnitConfig.PlacementType)
			
			if isMobile then
				if CurrentCamera.CameraType == Enum.CameraType.Fixed then
					CurrentCamera.CameraType = Enum.CameraType.Custom
				end
			end

			if result then
				warn("got past there?")
				Events.Unit:FireServer("Place", {slot = CurrentSlot, position = _CurrentPivot, rot = rot})
				--print(UnitConfig)
				StopPlacement()
			end

			--StopPlacement()
			return true
		elseif CurrentlyPlacing and not CanPlace then
			return true
		end

		return false
	end
	
	local function SetupPlacementSystem()
		local BindsToSlots = {
			["One"] = "Slot1",
			["Two"] = "Slot2",
			["Three"] = "Slot3",
			["Four"] = "Slot4",
			["Five"] = "Slot5",
			["Six"] = "Slot6",
		}
		
		local GCCamToggle = false
		
		local ActionCallbacks = {
			["R"] = function()
				if CurrentlyPlacing then
					rot += rot ~= 360 and 90 or -(90*3)
					SoundWrapper:PlaySound(script.Rotate, plrGui, replicated.SoundGroups.GeneralSFX)
					CurrentlyPlacing:SetAttribute("Orientation", Vector3.new(0,rot,0))
				end
			end,
			["Q"] = function()
				StopPlacement()
			end,
			["E"] = function()
				PlaceUnit()
			end,
			["H"] = function()
				if game.Players.LocalPlayer.Name == "VioletElementalist" then
					local CachedCurr = CurrentlySelected
					task.delay(3, function()
						Events.Unit:FireServer("SpecialAbility", {unit = CachedCurr})
						CachedCurr = nil
					end)
				end
			end,
			["V"] = function()
				if game.Players.LocalPlayer.Name == "VioletElementalist" then
					if not GCCamToggle then
						workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
						workspace.CurrentCamera.CFrame = workspace.GreenScreenCam.Cam1.CFrame
					else
						workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
					end
					for i,v in game.Players.LocalPlayer.PlayerGui:GetChildren() do
						if v:IsA("ScreenGui") then
							if v:GetAttribute("PreviousState") == nil then
								v:SetAttribute("PreviousState", v.Enabled)
							end
							
							if not GCCamToggle then
							--	GCCamToggle = true
								v.Enabled = false
							else
							--	GCCamToggle = false
								v.Enabled = v:GetAttribute("PreviousState")
							end
						end
					end
					
					GCCamToggle = not GCCamToggle
				end
			end,
		}
		
		local function _hideAOE()
			if CurrentlySelectedVisualModel then
				local AOE = CurrentlySelectedVisualModel:FindFirstChild("AOE")
				if AOE then
					AOE.Event:Fire("Hide")
				end
			end
		end
		
		local function _showAOE()
			if CurrentlySelectedVisualModel then
				local AOE = CurrentlySelectedVisualModel:FindFirstChild("AOE")
				if AOE then
					AOE.Event:Fire("Show")
				end
			end
		end
		
		local function _highLightSelection()
			if CurrentlySelectedVisualModel then
				local Highlight = script.SelectHighlight:Clone()
				Highlight.Parent = CurrentlySelectedVisualModel
			end
		end
		
		local function _hideSelectionHighLight()
			if CurrentlySelectedVisualModel then
				local Highlight = CurrentlySelectedVisualModel:FindFirstChild("SelectHighlight")
				if Highlight then
					Highlight:Destroy()
				end
			end
		end
		
		local function _cancelSelection()	
			--UnitCard.Visible = false
			if game.Players.LocalPlayer:HasTag("Spectating") then
				return
			end
			if not main.UnitCard2.Visible then
				if SlotButton ~= nil then
					SlotButton:SetAttribute("ControllerSelected", false)
					TweenMaid:GiveTask("TweenSlotIn"..SlotButton.Name, Tween:Create(SlotButton.KeybindButtonConsole, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(0,0)}))
					SlotIndex = 0
					SlotButton = nil
				end
			end
			
			_hideAOE()
			_hideSelectionHighLight()
			UnitCardHandler:HideMiniCard()
			UnitCardHandler:HideCard()
			
			CurrentlySelected = nil
			CurrentlySelectedVisualModel = nil
			--Maid:EndTree("UnitCardAnimate")
			--Maid:EndTree("TotalDamageListener")
			Maid:EndTree("UpgradeUpdateListener")
			Maid:EndTree("RangeBuffListener")
			Maid:EndTree("BuffedStatListener")
			Maid:KillTask("RangePosStaticUpdater")
			--Maid:KillTask("CDTask")
			--CleanupUnitCardViewport()
			cleanupUnitRange()
			
			if workspace.Temp:FindFirstChild("CurrentlySelected") then
				workspace.Temp.CurrentlySelected.Value = nil
			end
		end
		
		local MouseCallbacks = {
			["MouseButton1"] = function(UnitModel)
				---- Placing
				if game.Players.LocalPlayer:HasTag("Spectating") then
					return
				end
				
				local isMobile = uis.TouchEnabled and not uis.KeyboardEnabled and not uis.MouseEnabled
				
				if not isMobile then
					local PlaceUnitTriggered = PlaceUnit()
					if PlaceUnitTriggered then
						return
					end
				end
				---- Unit selectinon
				if not GameVariables.CanSelect.Value then _cancelSelection() return end
				local CheckUnitOnRay = self:checkForUnitOnRay()
				if not CurrentlyPlacing and UnitModel then
					CheckUnitOnRay = UnitModel.VisualModelLink.Value
				end
				if not CurrentlyPlacing and CheckUnitOnRay then
					local FoundRootModelLink = CheckUnitOnRay:FindFirstChild("RootModelLink")
					
					if FoundRootModelLink then
						if CurrentlySelected == FoundRootModelLink.Value and UnitCard.Visible then
							
							CurrentlySelected = FoundRootModelLink.Value
							CurrentlySelectedVisualModel = CurrentlySelected.VisualModelLink.Value

							_cancelSelection()
							return
						end
						
						UnitCardHandler:HideMiniCard()
						UnitCardHandler:HideCard()
						_hideSelectionHighLight()
						_hideAOE()

						CurrentlySelected = FoundRootModelLink.Value
						CurrentlySelectedVisualModel = CurrentlySelected.VisualModelLink.Value
						
						local IsOwner = CurrentlySelected:WaitForChild("configuration", 10):WaitForChild("Owner", 10).Value == plr.Name
						
						SoundWrapper:PlaySound(script.UnitClick, plrGui, replicated.SoundGroups.GeneralSFX)
						
						if IsOwner then
							UnitCardHandler:ShowCard(CurrentlySelected)
							
							local UnitConfig = UnitsRegistry[CurrentlySelected.Name]
							
							if UnitConfig then
								UnitConfig = UnitConfig.configuration
							end
							
							local CurrentlySelectedConfig = CurrentlySelected:FindFirstChild("configuration")
							local CurrentUnitPivot = CurrentlySelected:GetPivot()
							local CurrentUnitOffset = CurrentlySelectedVisualModel["Torso"].Size.Y/2 --CurrentlySelectedVisualModel["Torso"].Size.Y+CurrentlySelectedVisualModel["Left Leg"].Size.Y-- ((CurrentlySelectedVisualModel["Left Leg"].Size.Y*(1.5*3)))-.1
							
							if CurrentlySelectedObjectValue then
								if CurrentlySelectedObjectValue.Value ~= CurrentlySelected then
									CurrentlySelectedObjectValue.Value = CurrentlySelected
								end
							end
							
							_G.AOE:UpdateAOE(CurrentlySelected.configuration, CurrentlySelectedVisualModel)
							_highLightSelection()
							_showAOE()
							
							--Maid:EndTree("TotalDamageListener")
							--Maid:GiveTreeTask("TotalDamageListener", "LitenToTotalDamage", CurrentlySelectedConfig.TotalDamage.Changed, function()
							--	UnitCardFrame.TotalDamage.Text = `Total Damage: {UILib:format_int(CurrentlySelectedConfig.TotalDamage.Value)}`
							--end)
						
							Maid:EndTree("RangeBuffListener")
							Maid:GiveTreeTask("RangeBuffListener", "ListenToRangeBuff", CurrentlySelected:GetAttributeChangedSignal(`BuffedRange`), function()
								SetupRangeSphere(BuffLib:GetRangeRaw(CurrentlySelected), workspace.Temp, UnitConfig)
							end)
								
							Maid:EndTree("UpgradeUpdateListener")
							Maid:GiveTreeTask("UpgradeUpdateListener", "ListenToCurrentUpgradeChanged", CurrentlySelectedConfig.CurrentUpgrade.Changed, function()
								
								Maid:KillTask("RangePosStaticUpdater")
								
								SetupRangeSphere(BuffLib:GetRangeRaw(CurrentlySelected), workspace.Temp, UnitConfig)
								
								Maid:GiveTask("RangePosStaticUpdater", run.RenderStepped, function(dt)
									updateRangeSpherePos(dt, CurrentUnitPivot, CurrentUnitOffset)
								end)
								
								_G.AOE:UpdateAOE(CurrentlySelected.configuration, CurrentlySelectedVisualModel)
								
								--UpdateUnitCard(CurrentlySelected)
							end)

							Maid:KillTask("RangePosStaticUpdater")
							SetupRangeSphere(BuffLib:GetRangeRaw(CurrentlySelected), workspace.Temp, UnitConfig)
							Maid:GiveTask("RangePosStaticUpdater", run.RenderStepped, function(dt)
								updateRangeSpherePos(dt, CurrentUnitPivot, CurrentUnitOffset)
							end)

							--UpdateUnitCard(CurrentlySelected)
							--UnitCard.Visible = true
							return
						else
							UnitCardHandler:ShowMiniCard(CurrentlySelected, game.Players:FindFirstChild(CurrentlySelected.configuration:WaitForChild("Owner").Value))
							
							local CurrentlySelectedConfig = CurrentlySelected:FindFirstChild("configuration")
							local CurrentUnitPivot = CurrentlySelected:GetPivot()
							local CurrentUnitOffset = CurrentlySelectedVisualModel["Torso"].Size.Y/2 --CurrentlySelectedVisualModel["Torso"].Size.Y+CurrentlySelectedVisualModel["Left Leg"].Size.Y-- ((CurrentlySelectedVisualModel["Left Leg"].Size.Y*(1.5*3)))-.1

							if CurrentlySelectedObjectValue then
								if CurrentlySelectedObjectValue.Value ~= CurrentlySelected then
									CurrentlySelectedObjectValue.Value = CurrentlySelected
								end
							end

							_G.AOE:UpdateAOE(CurrentlySelected.configuration, CurrentlySelectedVisualModel)
							_highLightSelection()
							_showAOE()

							--Maid:EndTree("TotalDamageListener")
							--Maid:GiveTreeTask("TotalDamageListener", "LitenToTotalDamage", CurrentlySelectedConfig.TotalDamage.Changed, function()
							--	UnitCardFrame.TotalDamage.Text = `Total Damage: {UILib:format_int(CurrentlySelectedConfig.TotalDamage.Value)}`
							--end)

							Maid:EndTree("RangeBuffListener")
							Maid:GiveTreeTask("RangeBuffListener", "ListenToRangeBuff", CurrentlySelected:GetAttributeChangedSignal(`BuffedRange`), function()
								SetupRangeSphere(BuffLib:GetRangeRaw(CurrentlySelected), workspace.Temp, UnitConfig)
							end)

							Maid:EndTree("UpgradeUpdateListener")
							Maid:GiveTreeTask("UpgradeUpdateListener", "ListenToCurrentUpgradeChanged", CurrentlySelectedConfig.CurrentUpgrade.Changed, function()

								Maid:KillTask("RangePosStaticUpdater")

								SetupRangeSphere(BuffLib:GetRangeRaw(CurrentlySelected), workspace.Temp, UnitConfig)

								Maid:GiveTask("RangePosStaticUpdater", run.RenderStepped, function(dt)
									updateRangeSpherePos(dt, CurrentUnitPivot, CurrentUnitOffset)
								end)

								_G.AOE:UpdateAOE(CurrentlySelected.configuration, CurrentlySelectedVisualModel)

								--UpdateUnitCard(CurrentlySelected)
							end)

							Maid:KillTask("RangePosStaticUpdater")
							SetupRangeSphere(BuffLib:GetRangeRaw(CurrentlySelected), workspace.Temp, UnitConfig)
							Maid:GiveTask("RangePosStaticUpdater", run.RenderStepped, function(dt)
								updateRangeSpherePos(dt, CurrentUnitPivot, CurrentUnitOffset)
							end)
							
							Maid:GiveTreeTask("UpgradeUpdateListener", nil, CurrentlySelected.Destroying, function()
								_cancelSelection()
							end)

							--UpdateUnitCard(CurrentlySelected)
							--UnitCard.Visible = true
							return
						end
					end
				end
				
				if CurrentlySelected then
					_cancelSelection()
				end
			end,
		}
		
		script.ForceSelect.Event:Connect(function(UnitModel)
			MouseCallbacks.MouseButton1(UnitModel)
		end)
		
		script.ForceSelectFunction.OnInvoke = function(UnitModel)
			MouseCallbacks.MouseButton1(UnitModel)
		end
		
		local function StartPlacingCallback(ChosenSlot)
			if ChosenSlot then
				_cancelSelection()
				
				if ChosenSlot == CurrentSlot or SavedSlotbar[ChosenSlot].UUID == "" then
					StopPlacement()
					return
				end

				local FoundInRegistry = UnitsRegistry[SavedSlotbar[ChosenSlot].UnitName]

				if FoundInRegistry then
					local isMobile = uis.TouchEnabled and not uis.KeyboardEnabled and not uis.MouseEnabled
					
					if isMobile then
						_G.Maid.shared:EndTree("MobileControlsClientUnitHandler")
						TweenMaid:GiveTask("MobilePlacesPopUp", Tween:Create(MobileButtonsUI, TweenInfo.new(.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, 0.717)}))
						UIMotion:FullRegister(MobileButtonsUI.ContainerPC.Place, MobileButtonsUI.ContainerPC.Place.Size, {
							clickable = MobileButtonsUI.ContainerPC.Place.Clickable,
							toIncrease = MobileButtonsUI.ContainerPC.Place,
							TreeUUID = "MobileControlsClientUnitHandler",
							outlinerZIndex = 1,
							Percent = 2,
							callBack = PlaceUnit,
						})
						UIMotion:FullRegister(MobileButtonsUI.ContainerPC.Rotate, MobileButtonsUI.ContainerPC.Rotate.Size, {
							clickable = MobileButtonsUI.ContainerPC.Rotate.Clickable,
							toIncrease = MobileButtonsUI.ContainerPC.Rotate,
							TreeUUID = "MobileControlsClientUnitHandler",
							outlinerZIndex = 1,
							Percent = 2,
							callBack = ActionCallbacks.R,
						})
						UIMotion:FullRegister(MobileButtonsUI.ContainerPC.Cancel, MobileButtonsUI.ContainerPC.Cancel.Size, {
							clickable = MobileButtonsUI.ContainerPC.Cancel.Clickable,
							toIncrease = MobileButtonsUI.ContainerPC.Cancel,
							TreeUUID = "MobileControlsClientUnitHandler",
							outlinerZIndex = 1,
							Percent = 2,
							callBack = ActionCallbacks.Q,
						})
					end

					UnitConfig = FoundInRegistry.configuration

					if CurrentlyPlacing then
						CurrentlyPlacing:Destroy()
						if CircleIndicatorPreview then
							CircleIndicatorPreview:Destroy()
							CircleIndicatorPreview = nil
						end
						Maid:EndTree("UnitPlacementTree")
						cleanupUnitRange()
						CanPlace = false
					end

					PlacementRaycastParams.FilterDescendantsInstances = {workspace.Players, workspace.Effects, workspace.Temp, workspace.NPC_Client_Models, Collection:GetTagged("PLR_TAG")}

					HighlightPlacements(true, UnitConfig.PlacementType)

					local UnitModelClone = FoundInRegistry:GetModel(plr, SavedSlotbar[ChosenSlot]):Clone() --.misc.Model:Clone()
					UnitModelClone.Parent = workspace.Temp
					
					if SavedSlotbar[ChosenSlot].Shiny == true then
						UnitModelClone:AddTag("ShinyModel")
					end
					
					if FoundInRegistry.customizeVisuals then
						FoundInRegistry:customizeVisuals(plr, UnitModelClone)
					end
						
					UnitModelClone:WaitForChild("HumanoidRootPart",10)
					UnitModelClone:WaitForChild("Left Leg",10)
					
					CircleIndicatorPreview = replicated.Effects.UnitCircle.Circle:Clone()
					CircleIndicatorPreview.CFrame = UnitModelClone.HumanoidRootPart.CFrame*CFrame.new(0,-(UnitModelClone.HumanoidRootPart.Size.Y/2+UnitModelClone["Left Leg"].Size.Y)+0.05,0)
					
					local size = UnitModelClone:GetExtentsSize()

					local Height = size.Y
					
					local PM = CircleIndicatorPreview.GroundAttachment.ParticleEmitter
					local InCircle = CircleIndicatorPreview.GroundAttachment["in"]

					local PMSize = PM.Size.Keypoints[1]
					local InCircleSize = InCircle.Size.Keypoints

					local PMNewSize = NumberSequence.new(FoundInRegistry.Radius and FoundInRegistry.Radius/2*PMSize.Value or Height/defaultHeight*PMSize.Value)
					local BufferTable = {}

					for i, v in ipairs(InCircleSize) do
						BufferTable[i] = NumberSequenceKeypoint.new(v.Time, FoundInRegistry.Radius and FoundInRegistry.Radius/2*v.Value or Height/defaultHeight*v.Value,v.Envelope)
					end

					local InSizeNew = NumberSequence.new(BufferTable)

					PM.Size = PMNewSize
					InCircle.Size = InSizeNew
					
					CircleIndicatorPreview.Parent = workspace.Temp
					
					ImmediatelyEmitSlowParticles(CircleIndicatorPreview.GroundAttachment)
					UnitModelClone:PivotTo((CFrame.new(mouse.Hit.Position) * CFrame.new(0, (UnitModelClone.HumanoidRootPart.Size.Y / 2) + (UnitModelClone["Left Leg"].Size.Y), 0) * CFrame.Angles(0, math.rad(rot % 360), 0)))
					UnitModelClone:SetAttribute("Orientation", Vector3.new(0,rot,0))

					CurrentlyPlacing = UnitModelClone
					
					for i,v in pairs(CurrentlyPlacing:GetDescendants()) do
						if v:IsA("BasePart") or v:IsA("MeshPart") then
							v.CanCollide = false
							v.CanQuery = false
						end
					end
					
					BoundBoxSize = CurrentlyPlacing:GetExtentsSize()
					
					CurrentCircleRadius = FoundInRegistry.Radius and FoundInRegistry.Radius/2 or BoundBoxSize.Y/defaultHeight*defaultCircle
					
					if CurrentlyPlacing:HasTag("DoubleModel") then
						for i,v in pairs(CurrentlyPlacing:GetChildren()) do
							if v:GetAttribute("DoubleModel") then
								AnimModule.PlayAnim(replicated.Animations.Generic.Fall2, v, 1, "PlacementFall")
							end
						end
					end
					
					AnimModule.PlayAnim(replicated.Animations.Generic.Fall2, CurrentlyPlacing, 1, "PlacementFall")
					
					CurrentSlot = ChosenSlot

					SetupRangeSphere(BuffLib:GetInitialRangeOnPlace(SavedSlotbar[ChosenSlot].UUID, UnitConfig), workspace.Temp, UnitConfig)
					
					_G.AOE:CreateTempAOE(UnitConfig, UnitModelClone, SavedSlotbar[ChosenSlot].UUID)
					
					local oldCFrame = UnitModelClone.HumanoidRootPart.CFrame
					local oldRot = rot
					local oldRot2 = rot
					local rad = math.rad

					-- tweakable variables
					local tweenInfo = TweenInfo.new(.1,Enum.EasingStyle.Circular) -- the more time, the slower and smoother. 
					local offset = Vector3.new(0,(UnitModelClone.HumanoidRootPart.Size.Y / 2) + (UnitModelClone["Left Leg"].Size.Y),0) -- can be used if part needs to be raised

					local sway = 30 -- sway multiplier
					
					local isMobile = uis.TouchEnabled and not uis.KeyboardEnabled and not uis.MouseEnabled
					
					if not isMobile then
						if ControllerLib.LastInputType ~= "Controller" then
							local KeyBinds = script.KeybindsPC:Clone()
							KeyBinds.Enabled = true
							KeyBinds.Parent = UnitModelClone.HumanoidRootPart
						else
							local KeyBinds = script.KeybindsController:Clone()
							KeyBinds.Enabled = true
							KeyBinds.Parent = UnitModelClone.HumanoidRootPart
						end
					end
					
					for i, TraitName in SavedSlotbar[ChosenSlot].Traits do
						local TraitInRegistry = Registry.Traits[TraitName]

						if TraitInRegistry then
							TraitInRegistry:ApplyEffectToModel(UnitModelClone)
						end
					end
					
					if isMobile then
						if isMobile then
							if CurrentCamera.CameraType == Enum.CameraType.Custom then
								CurrentCamera.CameraType = Enum.CameraType.Fixed
							end
						end
						
						Maid:GiveTreeTask("UnitPlacementTree", "RS", run.RenderStepped, function(dt)
							local UnitPivot = CFrame.new(UnitModelClone:GetPivot().Position)
							CanPlace = CheckIfCanPlace(UnitModelClone.HumanoidRootPart.CFrame, UnitConfig.PlacementType)
							setPlaceIndicatorColor(CanPlace)
							updateRangeSpherePos(dt, UnitPivot, UnitModelClone["Torso"].Size.Y/2)--+UnitModelClone["Torso"].Size.Y) --(UnitModelClone["Left Leg"].Size.Y*(1.5*3))-.1)
							CircleIndicatorPreview.CFrame = UnitPivot*CFrame.new(0,-(UnitModelClone.HumanoidRootPart.Size.Y/2+UnitModelClone["Left Leg"].Size.Y)+0.02,0)
						end)
						
						Maid:GiveTreeTask("UnitPlacementTree", "UnitDrag", uis.TouchMoved, function(input, gp)
							if gp then return end
							if not mouse.Target then return end -- return if mouse is in the sky or smth
							local _Ray = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction*300, PlacementRayParams)

							if _Ray and _Ray.Position then
								PlacePos = _Ray.Position
								local cFrame = CFrame.new(_Ray.Position+offset)*CFrame.Angles(0,rad(rot%360),0)
								if cFrame ~= oldCFrame or oldRot ~= rot then -- If the part actually moved
									--local m = cFrame.Position - oldCFrame.Position -- magnitude (as a vector3)

									--local xAngle = (rot == 90 or rot == 270) and -m.X*sway or m.Z*sway
									--local zAngle = (rot == 90 or rot == 270) and -m.Z*sway or m.X*sway

									--local angle = CFrame.Angles(rad(xAngle),0,rad(zAngle))
									--cFrame *= angle

									Tween:Create(UnitModelClone.HumanoidRootPart,tweenInfo,{CFrame = cFrame}):Play()
									oldCFrame = cFrame
									oldRot = rot
								end
							end
						end)
						
						Maid:GiveTreeTask("UnitPlacementTree", "UnitDrag2", uis.TouchStarted, function(input, gp)
							if gp then return end
							if not mouse.Target then return end -- return if mouse is in the sky or smth
							local _Ray = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction*300, PlacementRayParams)

							if _Ray and _Ray.Position then
								PlacePos = _Ray.Position
								local cFrame = CFrame.new(_Ray.Position+offset)*CFrame.Angles(0,rad(rot%360),0)
								if cFrame ~= oldCFrame or oldRot ~= rot then -- If the part actually moved
									--local m = cFrame.Position - oldCFrame.Position -- magnitude (as a vector3)

									--local xAngle = (rot == 90 or rot == 270) and -m.X*sway or m.Z*sway
									--local zAngle = (rot == 90 or rot == 270) and -m.Z*sway or m.X*sway

									--local angle = CFrame.Angles(rad(xAngle),0,rad(zAngle))
									--cFrame *= angle

									Tween:Create(UnitModelClone.HumanoidRootPart,tweenInfo,{CFrame = cFrame}):Play()
									oldCFrame = cFrame
									oldRot = rot
								end
							end
						end)
					else
						Maid:GiveTreeTask("UnitPlacementTree", "UnitDrag", run.RenderStepped, function(dt)
							if not mouse.Target then return end -- return if mouse is in the sky or smth
							local _Ray = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction*300, PlacementRayParams)
							if _Ray and _Ray.Position then
								local cFrame = CFrame.new(_Ray.Position+offset)*CFrame.Angles(0,rad(rot%360),0)
								if cFrame ~= oldCFrame or oldRot ~= rot then -- If the part actually moved
									local m = cFrame.Position - oldCFrame.Position -- magnitude (as a vector3)

									local xAngle = (rot == 90 or rot == 270) and -m.X*sway or m.Z*sway
									local zAngle = (rot == 90 or rot == 270) and -m.Z*sway or m.X*sway

									local angle = CFrame.Angles(rad(xAngle),0,rad(zAngle))
									cFrame *= angle
									
									--print("heya")
									Tween:Create(UnitModelClone.HumanoidRootPart,tweenInfo,{CFrame = cFrame}):Play()
									--print("heya2")
									oldCFrame = cFrame
									oldRot = rot
								end
								
								local UnitPivot = CFrame.new(UnitModelClone:GetPivot().Position)
								CanPlace = CheckIfCanPlace(UnitModelClone.HumanoidRootPart.CFrame, UnitConfig.PlacementType)
								setPlaceIndicatorColor(CanPlace)
								updateRangeSpherePos(dt, UnitPivot, UnitModelClone["Torso"].Size.Y/2)--+UnitModelClone["Torso"].Size.Y) --(UnitModelClone["Left Leg"].Size.Y*(1.5*3))-.1)
								CircleIndicatorPreview.CFrame = UnitPivot*CFrame.new(0,-(UnitModelClone.HumanoidRootPart.Size.Y/2+UnitModelClone["Left Leg"].Size.Y)+0.02,0)
							end
						end)
					end
				end
			end
		end
		
	
		local function CustomizedUnitVisual(UnitAdded)
			task.spawn(function()
				local FoundDataInRegistry = UnitsRegistry[UnitAdded.Name]

				if not UnitAdded:HasTag("customized") and FoundDataInRegistry then
					local _RegistryUnitData = UnitsRegistry[UnitAdded.Name]
					local _UnitHeight = _RegistryUnitData.height
					local HeightCFrame = CFrame.new(0,0,0)

					if _UnitHeight then
						HeightCFrame = CFrame.new(0,_UnitHeight,0)
					end
					
					local Slot
					
					for i = 1,6 do
						if SavedSlotbar[`Slot{i}`].UUID == UnitAdded:GetAttribute("UUID") then
							Slot = i
						end
					end

					local ModelToCustomize = FoundDataInRegistry:GetModel(plr, SavedSlotbar[`Slot{Slot}`]):Clone() --.misc.Model:Clone()
					ModelToCustomize.Name = http:GenerateGUID(false)
					ModelToCustomize:SetAttribute("UnitName", UnitAdded.Name)
					ModelToCustomize:PivotTo(UnitAdded:GetPivot()*HeightCFrame)
					
					if UnitAdded:HasTag("Shiny") then
						ModelToCustomize:AddTag("ShinyModel")
					end
					
					local size = ModelToCustomize:GetExtentsSize()

					local Height = size.Y
					
					xpcall(function()
						local FoundHum = ModelToCustomize.Humanoid
						FoundHum.EvaluateStateMachine = false

						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
						FoundHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

						FoundHum.DisplayName = ""
						FoundHum.BreakJointsOnDeath = false
						FoundHum.AutomaticScalingEnabled = false
						FoundHum.AutoRotate = false
						FoundHum.AutoJumpEnabled = false
						FoundHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
						FoundHum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
						FoundHum.JumpPower = 0
						FoundHum.MaxHealth = 0
						FoundHum.Health = 0
						FoundHum.MaxSlopeAngle = 0
						FoundHum.NameDisplayDistance = 0
						FoundHum.NameOcclusion = Enum.NameOcclusion.OccludeAll
						FoundHum.PlatformStand = true
						FoundHum.UseJumpPower = true
						FoundHum.WalkSpeed = 0
					end, function(err)
						warn("[CLIENT UNIT HANDLER] errored somehow while setting humanoid states?", err)
					end)

					task.spawn(function()
						if UnitAdded:WaitForChild("configuration"):WaitForChild("Owner").Value == plr.Name then
							local UnitOverhead = replicated.Other.UnitOverhead:Clone()
							UnitOverhead.Adornee = ModelToCustomize:WaitForChild("Head")
							UnitOverhead.Parent = ModelToCustomize.Head

							local CircleIndicator = replicated.Effects.UnitCircle.Circle.GroundAttachment:Clone()
							CircleIndicator.CFrame = CFrame.new(0,-(UnitAdded:WaitForChild("HumanoidRootPart").Size.Y/2+UnitAdded:WaitForChild("Left Leg").Size.Y)+0.02,0)

							local PM = CircleIndicator.ParticleEmitter
							local InCircle = CircleIndicator["in"]

							local PMSize = PM.Size.Keypoints[1]
							local InCircleSize = InCircle.Size.Keypoints

							local PMNewSize = NumberSequence.new(_RegistryUnitData.Radius and _RegistryUnitData.Radius/2*PMSize.Value or Height/defaultHeight*PMSize.Value)
							local BufferTable = {}

							for i, v in ipairs(InCircleSize) do
								BufferTable[i] = NumberSequenceKeypoint.new(v.Time, _RegistryUnitData.Radius and _RegistryUnitData.Radius/2*v.Value or Height/defaultHeight*v.Value,v.Envelope)
							end

							local InSizeNew = NumberSequence.new(BufferTable)

							PM.Size = PMNewSize
							InCircle.Size = InSizeNew


							CircleIndicator.Parent = UnitAdded.PrimaryPart

							ImmediatelyEmitSlowParticles(CircleIndicator)

							local PlaceSparkles = replicated.Effects["PlaceSparkles(Mauw)"].Stars:Clone()
							PlaceSparkles.Parent = ModelToCustomize.HumanoidRootPart
							local PlaceDots = replicated.Effects["PlaceSparkles(Mauw)"].dots:Clone()
							PlaceDots.Parent = ModelToCustomize.HumanoidRootPart

							local UpgradeVFX = replicated.Effects.UpgradeVFX.UpgradeVFXPart.Upgrade:Clone()
							UpgradeVFX.Parent = ModelToCustomize.HumanoidRootPart

							PlaceSparkles:Emit(PlaceSparkles:GetAttribute("EmitCount"))
							PlaceDots:Emit(PlaceDots:GetAttribute("EmitCount"))

							SoundWrapper:PlaySound(script.Placement, ModelToCustomize, replicated.SoundGroups.GeneralSFX)

							Debris.AddItem(PlaceSparkles, 5)
						else
							local CircleIndicator = replicated.Effects.UnitCircle.CircleOther.GroundAttachment:Clone()
							CircleIndicator.CFrame = CFrame.new(0,-(UnitAdded:WaitForChild("HumanoidRootPart").Size.Y/2+UnitAdded:WaitForChild("Left Leg").Size.Y)+0.02,0)

							local PM = CircleIndicator.ParticleEmitter
							local InCircle = CircleIndicator["in"]

							local PMSize = PM.Size.Keypoints[1]
							local InCircleSize = InCircle.Size.Keypoints

							local PMNewSize = NumberSequence.new(_RegistryUnitData.Radius and _RegistryUnitData.Radius/2*PMSize.Value or Height/defaultHeight*PMSize.Value)
							local BufferTable = {}

							for i, v in ipairs(InCircleSize) do
								BufferTable[i] = NumberSequenceKeypoint.new(v.Time, _RegistryUnitData.Radius and _RegistryUnitData.Radius/2*v.Value or Height/defaultHeight*v.Value,v.Envelope)
							end

							local InSizeNew = NumberSequence.new(BufferTable)

							PM.Size = PMNewSize
							InCircle.Size = InSizeNew


							CircleIndicator.Parent = UnitAdded.PrimaryPart

							ImmediatelyEmitSlowParticles(CircleIndicator)
						end

						ModelToCustomize:AddTag("Loaded")
					end)

					local RootModelLink = Instance.new("ObjectValue")
					RootModelLink.Name = "RootModelLink"
					RootModelLink.Value = UnitAdded
					RootModelLink.Parent = ModelToCustomize

					local VisualModelLink = Instance.new("ObjectValue")
					VisualModelLink.Name = "VisualModelLink"
					VisualModelLink.Value = ModelToCustomize
					VisualModelLink.Parent = UnitAdded

					ModelToCustomize.Parent = workspace.UnitVisuals
					
					task.spawn(function()
						for i,v in {"Trait1", "Trait2", "Trait3"} do
							local TraitName = UnitAdded:GetAttribute(v)
							local TraitInRegistry = Registry.Traits[TraitName]

							if TraitInRegistry then
								TraitInRegistry:ApplyEffectToModel(ModelToCustomize)
							end
						end

						local AOE = _G.AOE:CreateAOE(FoundDataInRegistry.configuration, ModelToCustomize)
						if AOE then
							AOE.Event:Fire("Hide")
						end
					end)
					
					if ModelToCustomize:HasTag("DoubleModel") then
						for i,v in pairs(ModelToCustomize:GetChildren()) do
							if v:GetAttribute("DoubleModel") then
								AnimModule.PlayAnim(replicated.Animations.Generic.Placement1, v, 2, "")
							end
						end
					end

					AnimModule.PlayAnim(replicated.Animations.Generic.Placement1, ModelToCustomize, 2, "")
					AnimModule.PlayAnim(FoundDataInRegistry.animations.idle, ModelToCustomize, 1, "")

					FoundDataInRegistry:customizeVisuals(plr, ModelToCustomize)

					--repeat task.wait() until _G.clientGUIServices and _G.clientGUIServices.VFX
				end
			end)
		end
		
		local GamepadCallbacks = {
			["ButtonX"] = function()
				if CurrentlyPlacing then
					HapticController:SmallVibration(.3, .2)

					local PlaceUnitTriggered = PlaceUnit()
					if PlaceUnitTriggered then
						return
					end
				end

				if SlotButton ~= nil then
					StartPlacingCallback("Slot"..SlotIndex)
				end
			end,
			["ButtonY"] = function()
				if CurrentlyPlacing then
					HapticController:SmallVibration(.3, .1)
					ActionCallbacks.R()
					return
				end

				if not main.UnitCard2.Visible then
					MouseCallbacks.MouseButton1()
				end
			end,
			["ButtonB"] = function()
				if CurrentlyPlacing then
					HapticController:SmallVibration(.3, .1)
					ActionCallbacks.Q()
					return
				end
			end,
			["DPadDown"] = _cancelSelection,
		}
		
		task.spawn(function()
			for i,_unit in pairs(workspace.UnitsPlaced:GetChildren()) do
				CustomizedUnitVisual(_unit)
			end
		end)
		
		Maid:GiveTask("UnitVisualSetup", workspace.UnitsPlaced.ChildAdded, function(UnitAdded)
			CustomizedUnitVisual(UnitAdded)
		end)
		
		Maid:GiveTask("DestroyUnitVisual", workspace.UnitsPlaced.ChildRemoved, function(UnitRemoved)
			local FoundUnitVisual = UnitRemoved.VisualModelLink.Value
			
			if FoundUnitVisual then
				if workspace.Temp:FindFirstChild(FoundUnitVisual.Name) then
					workspace.Temp[FoundUnitVisual.Name]:Destroy()
				end
				
				FoundUnitVisual:Destroy()
				_cancelSelection()
			end
		end)
		
		local tapCount = 0
		
		uis.InputBegan:Connect(function(input, gameprocessed)
			if gameprocessed then return end
			if game.Players.LocalPlayer:HasTag("Spectating") then
				return
			end
			
			local ChosenSlot = BindsToSlots[input.KeyCode.Name]
			local ActionCallback = ActionCallbacks[input.KeyCode.Name]
			local MouseCallback = MouseCallbacks[input.UserInputType.Name]
			local GamepadCallback = GamepadCallbacks[input.KeyCode.Name]
			
			--if input.UserInputType == Enum.UserInputType.Touch then
			--	tapCount += 1
				
			--	if tapCount >= 2 then
			--		tapCount = 0
			--		MouseCallbacks.MouseButton1()
			--	end
			--end
			if input.UserInputType == Enum.UserInputType.Touch then
				MouseCallbacks.MouseButton1()
			end
			
			if ActionCallback then
				ActionCallback()
			end
			
			if MouseCallback then
				MouseCallback()
			end
			
			if GamepadCallback then
				GamepadCallback()
			end
			
			if ChosenSlot then
				StartPlacingCallback(ChosenSlot)
			end
		end)
		
		local LBSize = slots.SlotbarConsoleLeft.Size
		local RBSize = slots.SlotbarConsoleRight.Size
		
		ControllerLib:registerConsoleButton(slots.SlotbarConsoleLeft.ImageButton, Enum.KeyCode.ButtonL1.Name)
		ControllerLib:registerConsoleButton(slots.SlotbarConsoleRight.ImageButton, Enum.KeyCode.ButtonR1.Name)
		ControllerLib:registerConsoleButton(UnitManager.Clickable.KeybindButtonConsole, Enum.KeyCode.DPadRight.Name)
		ControllerLib:registerConsoleButton(StarChallengeNew.Clickable.KeybindButtonConsole, Enum.KeyCode.DPadLeft.Name)
		ControllerLib:registerConsoleButton(script.KeybindsController.KeybindHints.ContainerController.X.Key, Enum.KeyCode.ButtonX.Name)
		ControllerLib:registerConsoleButton(script.KeybindsController.KeybindHints.ContainerController.B.Key, Enum.KeyCode.ButtonB.Name)
		ControllerLib:registerConsoleButton(script.KeybindsController.KeybindHints.ContainerController.Y.Key, Enum.KeyCode.ButtonY.Name)
		
		if ControllerLib:getActiveGamepad() ~= nil then
			UnitManager.Clickable.KeybindButton.Visible = false
			UnitManager.Clickable.KeybindButtonConsole.Visible = true
			StarChallengeNew.Clickable.KeybindButton.Visible = false
			StarChallengeNew.Clickable.KeybindButtonConsole.Visible = true

			UIMotion:FullRegister(slots.SlotbarConsoleLeft, LBSize, {
				toIncrease = slots.SlotbarConsoleLeft,
				Percent = 15,
				clickable = slots.SlotbarConsoleLeft.ImageButton,
				BindKey = Enum.KeyCode.ButtonL1,
				TreeUUID = "ControllerSlotbarBinds",
				cooldown = .1,
				callBack = function()
					if SlotButton ~= nil then
						SlotButton:SetAttribute("ControllerSelected", false)
						TweenMaid:GiveTask("TweenSlotIn"..SlotButton.Name, Tween:Create(SlotButton.KeybindButtonConsole, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(0,0)}))
					end

					SlotIndex = SlotIndex <= 1 and 6 or SlotIndex-1

					SlotButton = slots[`Slot{SlotIndex}`]
					SlotButton:SetAttribute("ControllerSelected", true)
					TweenMaid:GiveTask("TweenSlotOut"..SlotButton.Name, Tween:Create(SlotButton.KeybindButtonConsole, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(.412, .472)}))
				end,
			}, {
				SupressClickCircle = true,
			})
			UIMotion:FullRegister(slots.SlotbarConsoleRight, RBSize, {
				toIncrease = slots.SlotbarConsoleRight,
				Percent = 15,
				clickable = slots.SlotbarConsoleRight.ImageButton,
				BindKey = Enum.KeyCode.ButtonR1,
				TreeUUID = "ControllerSlotbarBinds",
				cooldown = .1,
				callBack = function()
					if SlotButton ~= nil then
						SlotButton:SetAttribute("ControllerSelected", false)
						TweenMaid:GiveTask("TweenSlotIn"..SlotButton.Name, Tween:Create(SlotButton.KeybindButtonConsole, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(0,0)}))
					end

					SlotIndex = SlotIndex >= 6 and 1 or SlotIndex+1

					SlotButton = slots[`Slot{SlotIndex}`]

					SlotButton:SetAttribute("ControllerSelected", true)

					TweenMaid:GiveTask("TweenSlotOut"..SlotButton.Name, Tween:Create(SlotButton.KeybindButtonConsole, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(.412, .472)}))
				end,
			}, {
				SupressClickCircle = true,
			})

			--{0.412, 0},{0.472, 0}

			TweenMaid:GiveTask("TweenLB", Tween:Create(slots.SlotbarConsoleLeft, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(LBSize.X.Scale, LBSize.Y.Scale)}))
			TweenMaid:GiveTask("TweenRB", Tween:Create(slots.SlotbarConsoleRight, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(RBSize.X.Scale, RBSize.Y.Scale)}))
		end
		
		ControllerLib:addCallbackOnGamepadStateChanged(function(gamepad, gamepadType)
			_G.Maid.shared:EndTree("ControllerSlotbarBinds")
			
			if gamepad == nil then
				TweenMaid:GiveTask("TweenLB", Tween:Create(slots.SlotbarConsoleLeft, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(0, 0)}))
				TweenMaid:GiveTask("TweenRB", Tween:Create(slots.SlotbarConsoleRight, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(0, 0)}))
				UnitManager.Clickable.KeybindButton.Visible = true
				UnitManager.Clickable.KeybindButtonConsole.Visible = false
				StarChallengeNew.Clickable.KeybindButton.Visible = true
				StarChallengeNew.Clickable.KeybindButtonConsole.Visible = false
				return
			end
			
			UnitManager.Clickable.KeybindButton.Visible = false
			UnitManager.Clickable.KeybindButtonConsole.Visible = true
			StarChallengeNew.Clickable.KeybindButton.Visible = false
			StarChallengeNew.Clickable.KeybindButtonConsole.Visible = true

			UIMotion:FullRegister(slots.SlotbarConsoleLeft, LBSize, {
				toIncrease = slots.SlotbarConsoleLeft,
				Percent = 15,
				clickable = slots.SlotbarConsoleLeft.ImageButton,
				BindKey = Enum.KeyCode.ButtonL1,
				TreeUUID = "ControllerSlotbarBinds",
				cooldown = .1,
				callBack = function()
					if SlotButton ~= nil then
						SlotButton:SetAttribute("ControllerSelected", false)
						TweenMaid:GiveTask("TweenSlotIn"..SlotButton.Name, Tween:Create(SlotButton.KeybindButtonConsole, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(0,0)}))
					end

					SlotIndex = SlotIndex <= 1 and 6 or SlotIndex-1

					SlotButton = slots[`Slot{SlotIndex}`]
					SlotButton:SetAttribute("ControllerSelected", true)
					TweenMaid:GiveTask("TweenSlotOut"..SlotButton.Name, Tween:Create(SlotButton.KeybindButtonConsole, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(.412, .472)}))
				end,
			}, {
				SupressClickCircle = true,
			})
			UIMotion:FullRegister(slots.SlotbarConsoleRight, RBSize, {
				toIncrease = slots.SlotbarConsoleRight,
				Percent = 15,
				clickable = slots.SlotbarConsoleRight.ImageButton,
				BindKey = Enum.KeyCode.ButtonR1,
				TreeUUID = "ControllerSlotbarBinds",
				cooldown = .1,
				callBack = function()
					if SlotButton ~= nil then
						SlotButton:SetAttribute("ControllerSelected", false)
						TweenMaid:GiveTask("TweenSlotIn"..SlotButton.Name, Tween:Create(SlotButton.KeybindButtonConsole, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(0,0)}))
					end

					SlotIndex = SlotIndex >= 6 and 1 or SlotIndex+1

					SlotButton = slots[`Slot{SlotIndex}`]

					SlotButton:SetAttribute("ControllerSelected", true)

					TweenMaid:GiveTask("TweenSlotOut"..SlotButton.Name, Tween:Create(SlotButton.KeybindButtonConsole, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(.412, .472)}))
				end,
			}, {
				SupressClickCircle = true,
			})

			--{0.412, 0},{0.472, 0}

			TweenMaid:GiveTask("TweenLB", Tween:Create(slots.SlotbarConsoleLeft, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(LBSize.X.Scale, LBSize.Y.Scale)}))
			TweenMaid:GiveTask("TweenRB", Tween:Create(slots.SlotbarConsoleRight, TweenInfo.new(.1, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(RBSize.X.Scale, RBSize.Y.Scale)}))
		end)
		
		task.delay(.5, function()
			for i, SlotIcon in slots:GetChildren() do
				if SlotIcon:HasTag("SlotbarSlot") then
					ControllerLib:registerConsoleButton(SlotIcon.KeybindButtonConsole, Enum.KeyCode.ButtonX.Name)
					SlotIcon.Active = true
					UIMotion:RegisterClick(SlotIcon, SlotIcon.Size, {
						clickable = SlotIcon.Clickable,
						TreeUUID = "SelectUnitsByIcon",
						callBack = function()
							StartPlacingCallback(SlotIcon.Name)

						end,
					})
				end
			end
		end)
	end
	
	SetupPlacementSystem()
	return "Loaded"
end

return module
