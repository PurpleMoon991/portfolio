-- Author Purple (@VioletElementalist)
-- // THIS CODE IS NOT MEANT FOR 3RD PARTY USE, IT'S A SHOWCASE

-- A library to smoothly change between lighting presets, useful for zones with different ambience

local Master = {}
local Lighting = game:GetService("Lighting")
local Tween = game:GetService("TweenService")

local TweenCache = {}

local ParamsByClassNames = {
	["Atmosphere"] = {
		Density = true,
		Offset = true,
		Color = true,
		Decay = true,
		Glare = true,
		Haze = true,
	},
	["ColorCorrectionEffect"] = {
		Brightness = true,
		Contrast = true,
		Enabled = true,
		Saturation = true,
		TintColor = true,
	},
	["SunRaysEffect"] = {
		Enabled = true,
		Intensity = true,
		Spread = true,
	},
	["BlurEffect"] = {
		Enabled = true,
		Size = true,
	},
	["BloomEffect"] = {
		Enabled = true,
		Intensity = true,
		Size = true,
		Threshold = true,
	},
	--["Sky"] = {
	--	CelestialBodiesShown = true,
	--	MoonAngularSize = true,
	--	MoonTextureId = true,
	--	SkyboxBk = true,
	--	SkyboxDn = true,
	--	SkyboxFt = true,
	--	SkyboxLf = true,
	--	SkyboxRt = true,
	--	SkyboxUp = true,
	--	StarCount = true,
	--	SunAngularSize = true,
	--	SunTextureId = true,
	--}
}

local LightingServiceParams = {
	Ambient = true,
	Brightness = true,
	ColorShift_Bottom = true,
	ColorShift_Top = true,
	EnvironmentDiffuseScale = true,
	EnvironmentSpecularScale = true,
	GlobalShadows = true,
	OutdoorAmbient = true,
	ClockTime = true,
	GeographicLatitude = true,
	TimeOfDay = true,
	ExposureCompensation = true,
	FogColor = true,
	FogEnd = true,
	FogStart = true,
}

local BasicTweenInfo = TweenInfo.new(.35)

local function AttemptLightingCache()
	if not Lighting:GetAttribute("Cached") then
		for LightingParam, _ in pairs(LightingServiceParams) do
			Lighting:SetAttribute(LightingParam, Lighting[LightingParam])
		end
		
		for _, Effect in pairs(Lighting:GetChildren()) do
			local FoundClassParams = ParamsByClassNames[Effect.ClassName]
			
			if FoundClassParams then
				for ParamName, _ in pairs(FoundClassParams) do
					Effect:SetAttribute(ParamName, Effect[ParamName])
				end
			end
		end
		
		Lighting:SetAttribute("Cached", true)
		warn("[Lighting Master] Cached Lighting")
	end
end

local function StopCurrentTweens()
	for _, _Tween in pairs(TweenCache) do
		_Tween:Cancel()
	end
end

function Master:SetLighting(LightingFolder: Folder, isTween: boolean)
	AttemptLightingCache()
	StopCurrentTweens()
	
	for LightingParam, _ in pairs(LightingServiceParams) do
		local FoundAttribute = LightingFolder:GetAttribute(LightingParam)

		if FoundAttribute then
			--if isTween then
			--	local _CurrentTween = Tween:Create(Lighting, BasicTweenInfo, {[`{LightingParam}`] = FoundAttribute})
			--	table.insert(TweenCache, _CurrentTween)

			--	_CurrentTween:Play()

			--	continue
			--end
			Lighting[LightingParam] = FoundAttribute
		end
	end
	
	for i, Effect in pairs(LightingFolder:GetChildren()) do
		local FoundClassParams = ParamsByClassNames[Effect.ClassName]
		
		if FoundClassParams then
			local FoundEffectInLighting = Lighting:FindFirstChildOfClass(Effect.ClassName)
			
			if not FoundEffectInLighting then
				local DecoyEffect = Effect:Clone()
				DecoyEffect.Parent = Lighting
				DecoyEffect:SetAttribute("Decoy", true)
				continue
			end
			
			for ParamName, _ in pairs(FoundClassParams) do
				if isTween then
					local _CurrentTween = Tween:Create(FoundEffectInLighting, BasicTweenInfo, {[`{ParamName}`] = Effect[ParamName]})
					table.insert(TweenCache, _CurrentTween)

					_CurrentTween:Play()

					continue
				end
				FoundEffectInLighting[ParamName] = Effect[ParamName]
			end
		end
	end
end

function Master:RestoreOriginalLighting(isTween: boolean)
	if Lighting:GetAttribute("Cached") then
		StopCurrentTweens()
		
		for LightingParam, _ in pairs(LightingServiceParams) do
			local FoundAttribute = Lighting:GetAttribute(LightingParam)
			
			if FoundAttribute then
				Lighting[LightingParam] = FoundAttribute
			end
		end
		
		for _, Effect in pairs(Lighting:GetChildren()) do
			if Effect:GetAttribute("Decoy") then
				Effect:Destroy()
				continue
			end
			
			local FoundClassParams = ParamsByClassNames[Effect.ClassName]
			
			if FoundClassParams then
				for ParamName, _ in pairs(FoundClassParams) do
					local FoundAttribute = Effect:GetAttribute(ParamName)
					
					if FoundAttribute then
						if isTween then
							local _CurrentTween = Tween:Create(Effect, BasicTweenInfo, {[`{ParamName}`] = FoundAttribute})
							table.insert(TweenCache, _CurrentTween)

							_CurrentTween:Play()

							continue
						end
						Effect[ParamName] = FoundAttribute
					end
				end
			end
		end
		
		warn("[Lighting Master] Restored Lighting")
	end
end


return Master
