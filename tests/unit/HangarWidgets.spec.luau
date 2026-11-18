local Widgets = require(game.StarterPlayer.StarterPlayerScripts.FlyFightPaper.HangarWidgets)
local Suite = require(script.Parent.Parent.fixtures.Suite)
local Spec = {}

function Spec.run()
	local result, test = Suite.new()
	test("refreshing a selection preserves the book, scroller and pressed card", function()
		local parent = Instance.new("Frame")
		local ui = Widgets.new()
		local function draw(selected)
			ui.begin()
			local book = ui.instance(parent, "BinderSide", "Frame")
			local list = ui.instance(book, "Looks", "ScrollingFrame")
			local card = ui.button(list, "shark_jet", "", "", 0, 0, 262, 120, 0, function() end)
			local status = ui.words(card, "Status", selected and "Trying it on" or "Owned", 24, 72, 204, 34, 30)
			if selected then ui.instance(card, "Selection", "Frame") end
			ui.finish()
			return book, list, card, status
		end
		local book, list, card, status = draw(false)
		local changedBook, changedList, changedCard, changedStatus = draw(true)
		assert(book == changedBook and list == changedList and card == changedCard)
		assert(status == changedStatus and status.Text == "Trying it on" and card:FindFirstChild("Selection"))
		draw(false)
		assert(status.Text == "Owned" and not card:FindFirstChild("Selection"))
		parent:Destroy()
	end)
	return result
end

return Spec
