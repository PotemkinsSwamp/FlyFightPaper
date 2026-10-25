-- The menu art ids live in ReplicatedFirst (src/first/UIAssets.luau), so the loading screen can fetch them before the
-- rest of the game arrives.
return require(game:GetService("ReplicatedFirst"):WaitForChild("FlyFightPaper"):WaitForChild("UIAssets"))
