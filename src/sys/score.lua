local plan = require("src.sys.machPlan")
score = {}
scoreNum = 0
totalValuePoints = 0
local orderMultiplier = 1.25 -- Bonus multiplier for correct order

function score.runCalc()
    for i, item in ipairs(grabbedItems) do
        local itemType = item[1]
        local itemValue = item[2]

        totalValuePoints = totalValuePoints + itemValue

        -- Check if this item matches the plan in the correct position
        if i <= #currPlan and itemType == currPlan[i] then
            totalValuePoints = totalValuePoints * orderMultiplier
        end
    end

    -- Finally add score stuff
    scoreNum = math.floor((#grabbedItems * totalValuePoints)*100)

    totalValuePoints = 0
    grabbedItems = {}
    plan.init()
end

function score.minusScore()
    if scoreNum > 10 then
        scoreNum = scoreNum - 100
    end
end

return score
