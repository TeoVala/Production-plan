plan = {}

currPlan = {}
planItemsStatus = {}

function plan.load()
    if #currPlan <= 0 then
        plan.init()
    end
end

function plan.init()
    for i = 1, 3 do
        currPlan[i] = math.random(1, 5)
    end

    for i, itemId in ipairs(currPlan) do
        planItemsStatus[i] = { itemId, false }
    end
end

return plan
