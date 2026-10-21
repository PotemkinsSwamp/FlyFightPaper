-- Uploaded menu art (Roblox image ids). Sources: assets/ui/<screen>/; concept: assets/references/ui-concepts/.
-- An empty id draws nothing, so a missing piece shows as a gap rather than an error.
return {
	mainmenu = {
		bg = { "rbxassetid://86213401449162", "rbxassetid://139161444944451", "rbxassetid://70484091614246", "rbxassetid://92701816112270" }, -- background split into 2x2 tiles (top-left, top-right, bottom-left, bottom-right)
		title = "rbxassetid://103734128810118",
		strip = { yellow = "rbxassetid://81270758839816", blue = "rbxassetid://127387145271610", green = "rbxassetid://102293582971435", red = "rbxassetid://84891639571797" },
		card = "rbxassetid://89622531819348",
		drawing1 = "rbxassetid://87353912097125",
		drawing2 = "rbxassetid://84778693355255",
		photo = "rbxassetid://83093020395376",
		plane = "rbxassetid://118655728797714",
	},
	settings = {
		bg = { "rbxassetid://104052162768654", "rbxassetid://111560859395578", "rbxassetid://138034606283227", "rbxassetid://131649016886064" },
		ruler = "rbxassetid://112102301676610",
		pencil = "rbxassetid://131402918337135",
		tag = "rbxassetid://94679570912477",
		sticker = { red = "rbxassetid://95167817947211", blue = "rbxassetid://136617162696979", green = "rbxassetid://72275865664553",
			yellow = "rbxassetid://139451901251339", purple = "rbxassetid://108439521706833", white = "rbxassetid://136096845362532" },
		check = "rbxassetid://135193433305930",
		tabOff = "rbxassetid://94076303094566",
		tabOn = "rbxassetid://112038756025991",
		tabGreen = "rbxassetid://116159439019263",
		crosshairCard = "rbxassetid://94736097855757",
	},
	hangar = {
		bg = { "rbxassetid://79778639138066", "rbxassetid://132568400298663", "rbxassetid://76022165880333", "rbxassetid://101332652907481" },
		tab = "rbxassetid://115834678067841",
		tabSelected = "rbxassetid://79324501369328",
		card = "rbxassetid://84312204714104",
		cardSelected = "rbxassetid://118872852149517",
		preview = "rbxassetid://80540963066312",
		statsSheet = "rbxassetid://124702004184836",
		statRow = { red = "rbxassetid://74166245364488", blue = "rbxassetid://83398318100494", green = "rbxassetid://70725847047003", yellow = "rbxassetid://133852297040442" },
		bar = { red = "rbxassetid://125915066273285", blue = "rbxassetid://78667835427454", green = "rbxassetid://100029801723584", orange = "rbxassetid://101578956565177", empty = "rbxassetid://88470216324199" },
		slot = "rbxassetid://92798158654184",
		slotSelected = "rbxassetid://88893390484207",
		buttonGreen = "rbxassetid://83467354769758",
		-- The folder alone, see-through around it, for the in-game hangar menu (assets/ui/deskhangar/).
		folder = { "rbxassetid://90477686865340", "rbxassetid://106131906433035", "rbxassetid://99506492567038", "rbxassetid://74385525106617" },
	},
	-- Hangar cubby shelf and Customize binder (assets/ui/hangarshelf/; concepts hangar-shelf-screen, hangar-customize-b).
	-- Uploaded 2026-10-21; white pieces (shelfTab, indexTab, statLabel, statBox, statBoxEmpty) are tinted in the game.
	hangarShelf = {
		bg = { "rbxassetid://133397690165754", "rbxassetid://105639322311566", "rbxassetid://115182631090136", "rbxassetid://116475380443993" },
		cubbyBack = "rbxassetid://103396781406593", cubbyFront = "rbxassetid://91837232661923",
		endLeft = "rbxassetid://77250322353606", endRight = "rbxassetid://70512922987121",
		outline = "rbxassetid://107004369377864", shelfTab = "rbxassetid://130611353722432",
		binderLeft = "rbxassetid://113985177433175", binderRight = "rbxassetid://110535459444634",
		indexTab = "rbxassetid://76160948676401", buttonOrange = "rbxassetid://126851776000245",
		statsPaper = "rbxassetid://109589083209118", statLabel = "rbxassetid://92620076840621",
		statBox = "rbxassetid://80213400784355", statBoxEmpty = "rbxassetid://138489607891947",
	},
	results = {
		bg = { "rbxassetid://115001392503048", "rbxassetid://96562871734090", "rbxassetid://87591984146456", "rbxassetid://83555563405703" },
		goldStar = "rbxassetid://120331771075457",
		rowHighlight = "rbxassetid://137797402914609",
		strip = { blue = "rbxassetid://129866047095335", pink = "rbxassetid://82556466719896", green = "rbxassetid://78583732906300" },
		unlockCard = "rbxassetid://113216079197527",
		xpCard = "rbxassetid://76765257093865",
		xpFrame = "rbxassetid://87963878165241",
		xpFill = "rbxassetid://86284438244594",
	},
	-- The Hangar Range (assets/ui/range/; concept range-stage-view-2). Uploaded by Alan 2026-10-19; stage placed by RangeStage.
	range = {
		backdrop = "rbxassetid://94046304178728", board = "rbxassetid://97516109717403", bushes = "rbxassetid://134471401038099",
		curtainSide = "rbxassetid://116963270764119", lamp = "rbxassetid://110133720046199", ledge = "rbxassetid://83361502931301",
		scoreCard = "rbxassetid://74344471965466", scrap = "rbxassetid://99061707185371", selected = "rbxassetid://77346158317983",
		stripBlue = "rbxassetid://131414222716997", stripGreen = "rbxassetid://100375019576740", stripPurple = "rbxassetid://120263472105237",
		stripRed = "rbxassetid://119370059843524", stripYellow = "rbxassetid://140725343009257", tag = "rbxassetid://122262745222580",
		targetBlue0 = "rbxassetid://100466545549362", targetBlue1 = "rbxassetid://128566339922684", targetBlue2 = "rbxassetid://87900694765128",
		targetBlue3 = "rbxassetid://71108629384860", targetBlueHalfBack = "rbxassetid://87721412385746", targetBlueHalfFront = "rbxassetid://103402635695263",
		targetRed0 = "rbxassetid://126437968441823", targetRed1 = "rbxassetid://137592640177793", targetRed2 = "rbxassetid://84568946527791",
		targetRed3 = "rbxassetid://88905940775675", targetRedHalfBack = "rbxassetid://84780552790739", targetRedHalfFront = "rbxassetid://76528143101157",
		title = "rbxassetid://80054477461939", townArch = "rbxassetid://119197903146535", townClock = "rbxassetid://102556615538053",
		townRowA = "rbxassetid://96402057689663", townRowB = "rbxassetid://116332950561387", townRowC = "rbxassetid://74758506901640",
		townStepped = "rbxassetid://123872596852658", townTwin = "rbxassetid://96182028767221",
		-- The row-picker plates (Alan approved the assembled preview 2026-10-19).
		pickerClose = "rbxassetid://116543412917354", pickerMedium = "rbxassetid://84215014991333", pickerLong = "rbxassetid://113259560270392",
		pickerAll = "rbxassetid://110076308959196", pickerStand = "rbxassetid://140191552193282",
	},
	-- The Training board (assets/ui/trainingboard/; concept training-board-c). Uploaded by Alan 2026-10-19.
	trainingboard = {
		bg = { "rbxassetid://91520224114176", "rbxassetid://121622096406913", "rbxassetid://99839578988261", "rbxassetid://139377949748377" },
		title = "rbxassetid://127148292972405", paperFlight = "rbxassetid://73124461274469", paperCombat = "rbxassetid://77127618909836",
		paperHangar = "rbxassetid://71935281954018", paperRange = "rbxassetid://96038284662893",
		stripGreen = "rbxassetid://116436557781990", stripRed = "rbxassetid://105160400934566", tick = "rbxassetid://91100704633557",
	},
	ingame = {
		clipboard = "rbxassetid://131222070269430",
		stickyNote = "rbxassetid://97874141587630",
		indexCard = "rbxassetid://127869005862718",
		tapeLabel = "rbxassetid://72074243508272",
	},
	-- Flight HUD pieces (assets/ui/hud/; concepts hud-concept-1/2). White pieces are tinted in the game.
	hud = {
		notebook = "rbxassetid://110123970547575",
		incoming = "rbxassetid://76239099114989",
		scribble = "rbxassetid://105921512119910",
		arrow = "rbxassetid://93844659261583",
		ring = "rbxassetid://114300284068045",
		bracket = "rbxassetid://133288006521198",
		keyBox = "rbxassetid://116389741682536",
		slip = "rbxassetid://99725754287779",
		pinRed = "rbxassetid://118269057146968",
		pinBlue = "rbxassetid://96658237976750",
	},
	-- Tutorial "look here" pieces (assets/ui/tutorial/; concept ui-concepts/attention-*.png), already coloured.
	tutorial = {
		frameBox = "rbxassetid://131513208633678",
		frameRing = "rbxassetid://70377535387263",
		burst = "rbxassetid://136087187968614",
		tag = "rbxassetid://129673420830598",
		arrow = "rbxassetid://128216360516580",
		dash = "rbxassetid://98525696595946",
	},
	-- Hidden paper targets (assets/ui/targets/; concept mode-concepts/paper-targets.png), keyed by design name.
	targets = {
		broccoli = "rbxassetid://108546335442787",
		homework = "rbxassetid://88512104511264",
		["alarm-clock"] = "rbxassetid://84701674941062",
		bath = "rbxassetid://90423529121981",
		["dentist-chair"] = "rbxassetid://97152656695637",
		spider = "rbxassetid://125477512745397",
		vacuum = "rbxassetid://140040954684836",
		spinach = "rbxassetid://122359271557135",
	},
}
