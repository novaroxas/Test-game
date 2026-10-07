local Rules = {}
local beats = { Rock = "Scissors", Paper = "Rock", Scissors = "Paper" }

function Rules.isChoice(choice)
    return type(choice) == "string" and beats[choice] ~= nil
end

-- Returns 1 or 2 for the winner; 0 for a tie. Missing choices forfeit.
function Rules.winner(first, second)
    local a, b = Rules.isChoice(first), Rules.isChoice(second)
    if not a and not b then return 0 end
    if not a then return 2 end
    if not b then return 1 end
    if first == second then return 0 end
    return beats[first] == second and 1 or 2
end

function Rules.matchWinner(scores, target)
    if scores[1] >= target then return 1 end
    if scores[2] >= target then return 2 end
    return nil
end

return Rules
