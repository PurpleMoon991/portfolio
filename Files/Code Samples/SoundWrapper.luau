-- Author Purple (@VioletElementalist)
-- // THIS CODE IS NOT MEANT FOR 3RD PARTY USE, IT'S A SHOWCASE

-- Used for playing sounds, featuring sound groups, all varieties of sound settings + sound instance optimiziation made by me

local SoundWrapper = {}
local Replicated = game:GetService("ReplicatedStorage")
local Debris = require(Replicated:WaitForChild("Libs"):WaitForChild("DebrisSystemV2"))
local SoundGroups = Replicated:FindFirstChild("SoundGroups")
local Collection = game:GetService("CollectionService")

export type SoundSettings = {
	RollOffMaxDistance: number?,
	RollOffMinDistance: number?,
	RollOffMode: Enum.RollOffMode?,
	Looped: boolean?,
	PlaybackRegion: NumberRange?,
	LoopRegion: NumberRange?,
	PlaybackSpeed: number?,
	Playing: boolean?,
	TimePosition: number?,
	Volume: number?,
	PlayOnRemove: boolean?,
}

local ParamTable = {
	"RollOffMaxDistance",
	"RollOffMinDistance",
	"RollOffMode",
	"Looped",
	"PlaybackSpeed",
	"Playing",
	"TimePosition",
	"Volume",
	"PlayOnRemove",
}

local function unpackSoundGroups()
	if not SoundGroups then
		script.SoundGroups:Clone().Parent = Replicated
		SoundGroups = Replicated.SoundGroups
	end
end

unpackSoundGroups()

function SoundWrapper:convertSounds()
	for _, SoundInstance in Collection:GetTagged("SoundInstancesToConvert") do
		local NewDecoy = Instance.new("StringValue"); NewDecoy:AddTag("SoundDecoy")
		
		for i,v in ParamTable do
			if v == "RollOffMode" then
				NewDecoy:SetAttribute(v, SoundInstance[v].Name)
				continue
			end

			NewDecoy:SetAttribute(v, SoundInstance[v])
		end
		
		NewDecoy.Name = `{SoundInstance.Name}`
		NewDecoy.Value = SoundInstance.SoundId
		NewDecoy.Parent = SoundInstance.Parent
		
		SoundInstance:Destroy()
	end
end

function SoundWrapper:PlaySound(sound: Sound | string | StringValue, soundParent: Instance, soundGroup: SoundGroup?, extraSettings: SoundSettings, shouldDebris: boolean?, instantPlayback: boolean?, customDebrisTime: number?, loopInfinitely: boolean?)	
	if sound and soundParent then
		local SoundClone --= sound:Clone()
		
		if typeof(sound) == "Instance" then
			if sound:IsA("Sound")  then
				SoundClone = sound:Clone()
			end
			
			if sound:IsA("StringValue") then
				SoundClone = Instance.new("Sound")
				SoundClone.Name = sound.Name
				SoundClone.SoundId = sound.Value
				
				for i,v in ParamTable do
					if v == "RollOffMode" and sound:GetAttribute(v) then
						SoundClone.RollOffMode = Enum.RollOffMode[sound:GetAttribute(v)]
						continue
					end
					
					if sound:GetAttribute(v) then
						SoundClone[v] = sound:GetAttribute(v)
					end
				end
				
				SoundClone:Clone().Parent = sound.Parent
				sound:Destroy()
			end
		elseif typeof(sound) == "string" then
			SoundClone = Instance.new("Sound")
			SoundClone.SoundId = sound
		end
		
		if soundGroup then
			SoundClone.SoundGroup = soundGroup
		else
			SoundClone.SoundGroup = SoundGroups.GeneralSFX
		end
		
		if extraSettings then
			if extraSettings["PlaybackRegion"] or extraSettings["LoopRegion"] then
				SoundClone.PlaybackRegionsEnabled = true
			end
			
			for SettingName, SettingValue in pairs(extraSettings) do
				SoundClone[SettingName] = SettingValue
			end
		end
		
		SoundClone.Parent = soundParent
		
		if instantPlayback ~= false then
			SoundClone:Play()
		end
		
		if loopInfinitely then -- ignores should debris n etc, just loops and returns the sound
			SoundClone.Looped = true
			return SoundClone
		end
		
		if shouldDebris ~= false then
			task.spawn(function()
				if not SoundClone.IsLoaded then
					SoundClone.Loaded:Wait() 
				end
				
				Debris.AddItem(SoundClone, customDebrisTime or SoundClone.TimeLength+1.5)
			end)
		end
		
		return SoundClone
	end
end

return SoundWrapper
