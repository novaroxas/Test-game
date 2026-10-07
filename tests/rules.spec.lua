local Rules = dofile("src/shared/Rules.lua")
local Config = dofile("src/shared/Config.lua")
local cases = 0
local function check(condition, message)
    assert(condition, message)
    cases = cases + 1
end
local expected = {
    Rock = { Rock = 0, Paper = 2, Scissors = 1 },
    Paper = { Rock = 1, Paper = 0, Scissors = 2 },
    Scissors = { Rock = 2, Paper = 1, Scissors = 0 },
}
for first, opponents in pairs(expected) do
    for second, winner in pairs(opponents) do
        check(Rules.winner(first, second) == winner, first .. " vs " .. second)
    end
end
for _, choice in ipairs(Config.Choices) do
    check(Rules.isChoice(choice), "valid choice")
    check(Rules.winner(nil, choice) == 2, "first player times out")
    check(Rules.winner(choice, nil) == 1, "second player times out")
end
for _, invalid in ipairs({ "rock", "Lizard", "", 3, {}, true }) do
    check(not Rules.isChoice(invalid), "reject invalid input")
end
check(not Rules.isChoice(nil), "reject nil")
check(Rules.winner(nil, nil) == 0, "both time out")
check(Rules.winner("invalid", "Rock") == 2, "malformed choice forfeits")
check(Rules.matchWinner({ 2, 2 }, 3) == nil, "unfinished match")
check(Rules.matchWinner({ 3, 2 }, 3) == 1, "first reaches three")
check(Rules.matchWinner({ 1, 3 }, 3) == 2, "second reaches three")
print("Rules: " .. cases .. " assertions passed")
