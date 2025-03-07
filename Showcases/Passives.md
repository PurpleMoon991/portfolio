(Over 70% of passives from this list were made by me)

https://github.com/user-attachments/assets/1db2cea6-f05b-4f96-8fef-845190295ac6

(Code Sample)

```lua
-- Author Purple (@VioletElementalist)
-- // THIS CODE IS NOT MEANT FOR 3RD PARTY USE, IT'S A SHOWCASE

local replicated = game:GetService("ReplicatedStorage")
local Enums = require(replicated.Libs.Enums)
local Passive = setmetatable({}, {__index = require(replicated.Registry.PassiveBaseMethods)}) :: Enums.PassiveStructure

Passive.configuration = {
	PassiveName = "Ultimate-Class Devil King",
	PassiveDescription = "All `Rook Pieces` are covered in Red Aura and gain +0.5% DMG (Upto 25%) for every enemy killed by Rise or any of current Rise's `Rook Pieces`. After 6 Completed Waves from Placement, all Rooks have their SPA Decreased by 15% and RNG Increased by 25%",
	TagName = "RiasRookEvo",
	MaxPassiveStacks = 50,
	PercentPerStack = 0.005,
} 

Passive.callbacks = {
	onUnitsInRange = function(self, Unit: Model)
		local Allies = _G.UnitHandler:GetAllyUnitsInRange(Unit)
		local IUUID = Unit:GetAttribute("IUUID")
		local GameVariables = game.ReplicatedStorage.GameVariables
		
		for _, Ally: Model in Allies do
			if not Ally:HasTag(Passive.configuration.TagName) then
				Ally:SetAttribute(`{Passive.configuration.TagName}Id`, Unit:GetAttribute("IUUID"))
				Ally:AddTag(Passive.configuration.TagName)
				
				if Unit:GetAttribute("ReachedWave6Rias") == true and not Ally:HasTag("6thWaveBuff") then
					Ally:AddTag("6thWaveBuff")
					Ally:SetAttribute("PermanentAttackSpeedMulti", Ally:GetAttribute("PermanentAttackSpeedMulti")-.15)
					Ally:SetAttribute("PermanentRangeMulti", Ally:GetAttribute("PermanentRangeMulti")+.25)
				end
			end
		end
	end,
	
	onWave = function(self, Unit: Model)
		local GameVariables = game.ReplicatedStorage.GameVariables
		local Collection = game:GetService("CollectionService")
		local IUUID = Unit:GetAttribute("IUUID")
		local Stacks = Unit:GetAttribute(`{Passive.configuration.TagName}Waves`) or 0
		
		local function applyBuff()
			for _, Rook in Collection:GetTagged(Passive.configuration.TagName) do
				if Rook:GetAttribute(`{Passive.configuration.TagName}Id`) == IUUID and not Rook:HasTag("6thWaveBuff") then
					Rook:AddTag("6thWaveBuff")
					Rook:SetAttribute("PermanentAttackSpeedMulti", Rook:GetAttribute("PermanentAttackSpeedMulti")-.15)
					Rook:SetAttribute("PermanentRangeMulti", Rook:GetAttribute("PermanentRangeMulti")+.25)
				end
			end
		end
		
		if not Unit:GetAttribute("ReachedWave6Rias")  then
			if Stacks >= 5 then
				Unit:SetAttribute(`{Passive.configuration.TagName}Waves`, 6)
				Unit:SetAttribute("ReachedWave6Rias", true)
				applyBuff()
			else
				Unit:SetAttribute(`{Passive.configuration.TagName}Waves`, Stacks+1)
			end
			return
		end
	end,
	
	onRemove = function(self, Unit: Model)
		local IUUID = Unit:GetAttribute("IUUID")
		
		for _, Ally in workspace.UnitsPlaced:GetChildren() do
			if Ally:HasTag(Passive.configuration.TagName) and Ally:GetAttribute(`{Passive.configuration.TagName}Id`) == IUUID then
				Ally:SetAttribute(`{Passive.configuration.TagName}Id`, nil)
				Ally:RemoveTag(Passive.configuration.TagName)
				
				local Stacks = Ally:GetAttribute(`{Passive.configuration.TagName}Stacks`) or 0
				Ally:SetAttribute("PermanentDamageMulti", Ally:GetAttribute("PermanentDamageMulti")-(Passive.configuration.PercentPerStack*Stacks))
				Ally:SetAttribute(`{Passive.configuration.TagName}Stacks`, nil)
				
				if Ally:HasTag("6thWaveBuff") then
					Ally:RemoveTag("6thWaveBuff")
					Ally:SetAttribute("PermanentAttackSpeedMulti", Ally:GetAttribute("PermanentAttackSpeedMulti")+.15)
					Ally:SetAttribute("PermanentRangeMulti", Ally:GetAttribute("PermanentRangeMulti")-.25)
				end
			end
		end
	end,
	
	onAnyKill = function(self, Unit: Model, Killer: Model, Enemy: {any}?)
		local Collection = game:GetService("CollectionService")
		local IUUID = Unit:GetAttribute("IUUID")
		
		if Killer == Unit or Killer:HasTag(Passive.configuration.TagName) and Killer:GetAttribute(`{Passive.configuration.TagName}Id`) == IUUID then
			for _, Rook in Collection:GetTagged(Passive.configuration.TagName) do
				if Rook:GetAttribute(`{Passive.configuration.TagName}Id`) == IUUID then
					local Stacks = Rook:GetAttribute(`{Passive.configuration.TagName}Stacks`) or 0

					if Stacks < Passive.configuration.MaxPassiveStacks then
						Rook:SetAttribute(`{Passive.configuration.TagName}Stacks`, Stacks+1)
						Rook:SetAttribute("PermanentDamageMulti", Rook:GetAttribute("PermanentDamageMulti")+Passive.configuration.PercentPerStack)
					end
				end
			end
		end
	end,
}

return Passive

```
