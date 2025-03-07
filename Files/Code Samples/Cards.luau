-- Author Purple (@VioletElementalist)
-- // THIS CODE IS NOT MEANT FOR 3RD PARTY USE, IT'S A SHOWCASE

-- Sample of front-end, a neat cards selection animated using Spring
-- Hoarcekat was used as a storybook

local module = {}

--[[
	{
		[1] = {
			Type = "Buff",
			Description = "All units range increases",
			Title = "Range",
			TopStat = "+15% more range",
			DownStat = "",
		},
		[2] = {
			Type = "Debuff",
			Description = "All units range increases",
			Title = "Enemy Speed",
			TopStat = "+25% enemy speed",
			DownStat = "+1.5x event tokens",
		},
	}
]]

local VoteHandler = require(game.ReplicatedStorage.Libs.VoteHandler)

function module:CreateCard(Data, index)
	local CardBase:ImageButton = Data.Type == "Buff" and script.BuffCard:Clone() or Data.Type == "Debuff" and script.DebuffCard:Clone() --or Data.Type == "Chaos" and ""
	CardBase.Page.Description.Text = Data.Description
	CardBase.Page.Title.Text = Data.Title
	
	CardBase.Page.Stats.Top.Stat.Text = Data.TopStat or ""
	CardBase.Page.Stats.Down.Stat.Text = Data.DownStat or ""
	
	CardBase.Page.Icon.Image = Data.Icon or ""
	
	VoteHandler:ListenToVote("ModCardVote", function()
		CardBase.Page.Select.Amount.Text = VoteHandler:GetVotes("ModCardVote")[`Card {index}`]
	end)
	
	return CardBase, Data.ClientCallback or nil
end

function module:Show(Cards: {any})
	local TweenService = game:GetService("TweenService")
	local Maid = require(game.ReplicatedStorage.Maid).new()
	local Spring = require(game.ReplicatedStorage.Libs.Spring)
	local PlayerGui = game.Players.LocalPlayer.PlayerGui

	local pool = {}
	local CurrSizes = {}
	local OrigSizes = {}
	local CurrChoosenCard = nil

	local function onCardSelected(CardID)
		local ChoosenCard = pool[CardID]
		local GoalSize = UDim2.fromScale(.18, 1)
		if CurrChoosenCard == CardID then return end
		CurrChoosenCard = CardID
		Spring.target(ChoosenCard, 3, 8, {
			Size = UDim2.fromScale(OrigSizes[CardID].X.Scale*1.15, OrigSizes[CardID].Y.Scale*1.15)
		})
		CurrSizes[CardID] = UDim2.fromScale(OrigSizes[CardID].X.Scale*1.15, OrigSizes[CardID].Y.Scale*1.15)

		for i = #pool, 1, -1 do
			if i ~= CardID then
				local Card = pool[i]
				Spring.target(Card, .5, 2, {
					Size = UDim2.fromScale(OrigSizes[i].X.Scale*.85, OrigSizes[i].Y.Scale*.85)
				})
				CurrSizes[i] = UDim2.fromScale(OrigSizes[i].X.Scale*.85, OrigSizes[i].Y.Scale*.85)
			end
		end
	end

	local Darken = script.Canvas:Clone()
	Darken.Parent = PlayerGui.Modifiers
	local Frame = script.ChooseCard:Clone()
	Frame.Parent = PlayerGui.Modifiers
	
	Spring.target(Darken, 1, 2, {
		GroupTransparency = 0
	})

	Spring.target(Frame.TimerBar, 2, 5, {
		Position = UDim2.fromScale(.5, .825)
	})

	Spring.target(Frame.Title, 2, 5, {
		Position = UDim2.fromScale(.5, .155)
	})	
	task.spawn(function()
		task.wait(.65)

		task.delay(.025, function()
			Spring.target(Frame.List, 2, 5, {
				Position = UDim2.fromScale(.5, .5),
				Rotation = 0,
			})
		end)

		for i = 1, #Cards do
			local Card, ClientCallback = module:CreateCard(Cards[i], i)
			Card.Parent = Frame.List
			local GoalSize = Card.Size
			
			table.insert(CurrSizes, Card.Size)
			table.insert(OrigSizes, Card.Size)

			Card.Size = UDim2.fromScale(0, 0)

			Spring.target(Card, 2, 5, {
				Size = CurrSizes[i]
			})

			task.delay(.2, function()
				Spring.target(Card.Page.Icon, .2, 5, {
					Rotation = 0
				})
				Spring.target(Card.Page.Image, .2, 5, {
					Rotation = 0
				})
				Spring.target(Card.Page.Description, .275, 2, {
					Rotation = 0
				})
				Spring.target(Card.Page.Title, .275, 2, {
					Rotation = 0
				})
			end)

			Maid:GiveTreeTask("Card"..i, nil, Card.MouseEnter, function()
				Spring.target(Card, 3, 8, {
					Size = UDim2.fromScale(CurrSizes[i].X.Scale*1.05, CurrSizes[i].Y.Scale*1.05)
				})
			end)

			Maid:GiveTreeTask("Card"..i, nil, Card.MouseLeave, function()
				Spring.target(Card, 3, 8, {
					Size = CurrSizes[i]
				})
			end)

			Maid:GiveTreeTask("Card"..i, nil, Card.Activated, function()
				onCardSelected(i)
				if ClientCallback then
					ClientCallback()
				else
					print("No client call back on card "..i.."?")
				end
			end)

			table.insert(pool, Card)
			task.wait(.085)
		end
	end)
	
	Maid:GiveTask(nil, game["Run Service"].RenderStepped, function()
		local Vote = game.ReplicatedStorage.Votes:FindFirstChild("ModCardVote")
		
		if Vote then
			local SecondsLeft = Vote.VoteTimer.Value
			TweenService:Create(Frame.TimerBar.XPBarProgress, TweenInfo.new(.1,Enum.EasingStyle.Linear), {Size = UDim2.fromScale(SecondsLeft/(Vote.VoteEndTime.Value-Vote.VoteStartTime.Value), 1)}):Play()
			Frame.TimerBar.XPBarAmount.Text = `Time Remaining: {SecondsLeft}s`
		end
	end)
	
	local function onVoteEnd()
		Spring.target(Darken, 1, 2, {
			GroupTransparency = 1
		})
		
		Spring.target(Frame.TimerBar, 1, 2, {
			Position = UDim2.fromScale(.5, 2)
		})

		Spring.target(Frame.Title, 1, 2, {
			Position = UDim2.fromScale(.5, -1)
		})

		Spring.target(Frame.List, .5, 2, {
			Position = UDim2.fromScale(1.5, .5),
			Rotation = 15,
		})

		Maid:Dispose()
		
		task.delay(2, function()
			Darken:Destroy()
			Frame:Destroy()
		end)
	end
	
	return onVoteEnd
end

return module
