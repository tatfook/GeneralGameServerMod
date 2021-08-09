local goals = gettable("game.goals")
local tempKeyList   = {
    'defeatTeam',
    'survivalTime',
    'collectGrass',
    'bonusCollect',
    'defeatTarget',
    'defeatDoor',
    'defeatFence',
    'defeatBridge',
    'codeLine',
    'moveGoal'
}
local map   = {}
for i,v in ipairs(tempKeyList) do
    map[v]  = v
end
goals.goalType  = map





-- goals.textMap  = {}

-- goals.targetParamMap    = {}
-- goals.progressParamMap  = {}

-- goals.defeatTypeMap    = {} -- key type  value {targetAmount  , defeatedAmount} 
-- goals.basicTargetMap   = {}
-- goals.extraTargetMap   = {} -- 不包括 代码行数 的目标
----------------------------------------------------总接口------------------------------------------------------------

-- [[
--     param{
--         goalType
--         targetValue 
--         processValue
--         isBasic     true or false
--         targetParam    defeatTarget ,defeatTeam 时候需要传入
--         text
--     }    
-- ]]
function goals.addGoal( param )
    local goals  = goals
    local goalType  = goals.goalType
    if not type(param) == 'table' then return end
    if param.goalType == goalType.moveGoal then
        if type(param.targetParam)~= 'table' and (not param.targetParam.x) and (not param.targetParam.y) and (not param.targetParam.name) then
            game.hwtPrint("goals.addGoal addMoveGoal param not illegel")
            return
        end
        goals.addMoveGoal(param.targetParam.x, param.targetParam.y, param.targetParam.name , param.isBasic , param.text)
    elseif param.goalType == goalType.defeatTeam then
        if type(param.targetParam) ~= 'string' then 
            game.hwtPrint("goals.addGoal addDefeatGoal param targetParam need string")
            return
        end
        goals.addDefeatGoal(param.targetValue, param.targetParam , param.isBasic, param.text)

    elseif param.goalType == goalType.survivalTime then
        goals.addSurvivalGoal(param.targetValue ,param.isBasic , param.text)

    elseif param.goalType == goalType.bonusCollect then
        --可以
        goals.addCollectBonusGoal(param.targetValue , param.isBasic, param.text)

    elseif param.goalType == goalType.collectGrass then
        --可以
        goals.addCollectGoal(param.targetValue , param.isBasic, param.text)

    elseif param.goalType == goalType.codeLine then
        goals.addBonusLineCount(param.targetValue)

    elseif param.goalType == goalType.defeatTarget then
        
    elseif goalType[param.goalType] then
        goals.hasGoal = true;
        goals.addTargetList(param)
        game.ui.desktop.goals.update();
        
    else
        game.hwtPrint("goals.addGoal param.goalType not exist")
    end
end

--[[
--     param{
--         goalType
--         changeValue 
--     }    
-- ]]
function goals.updateGoalProgress( goalType , changeValue  , className )
    if not (goals.progressParamMap[goalType] or goals.progressParamMap[className]) then
        return 
    end

   if changeValue and changeValue ~= 0 then

        local tag   = (goalType == goals.goalType.defeatTarget) and  className or goalType
        local progressParamMap  = goals.progressParamMap
        progressParamMap[tag]    = progressParamMap[tag] + changeValue
        game.ui.desktop.goals.update();  
        if goals.targetParamMap[tag] <= progressParamMap[tag] then
            goals.CheckFinish()
        end
   end
end

-- [[
--     param{
--         goalType
--         text 
--         targetParam 特殊参数
--         isBasic     
--         amount
--         targetValue
--         processValue
--     }
-- ]]

function goals.addTargetList(param )
    -- body
    if param.isBasic == nil then
        param.isBasic    = true
    end
    local goalType      = param.goalType
    local info  = {}
    info['goalType']  = goalType
    info['isBasic']  = param.isBasic 

    
    
    if goalType == goals.goalType.defeatTarget then
        --info['className']   = param.targetParam
        goals.setGoalParam(param.targetParam , param.targetValue , param.processValue)
        goals.setTextByGoal(param.targetParam , param.text )
        info['className']       = param.targetParam
        goals.defeatTypeMap[param.targetParam]  = info
    else
        goals.setGoalParam(param.goalType , param.targetValue , param.processValue)
        param.isBasic        = goals.judgeTargetIsBasic(goalType , param.isBasic)
        goals.setTextByGoal(param.goalType , param.text )
        local key           = param.isBasic and 'basicTargetMap' or 'extraTargetMap'
        if not goals[key][goalType] then
            goals[key][goalType]   = info
        end
    end

end


----------------------------------------------------辅助接口------------------------------------------------------------
function goals.getWholeTextByGoal( goalType )
    local goals     = goals 
    game.hwtPrint("getWholeTextByGoal" ,goals.getTextByGoal(goalType) , goals.getProgressByGoal(goalType), goals.getTParamByGoal(goalType))
    local text  = string.format("%s : %d / %d" , goals.getTextByGoal(goalType) , goals.getProgressByGoal(goalType), goals.getTParamByGoal(goalType))
    return text
end

function goals.setGoalParam(goalType , targetValue , progressValue)
    goals.targetParamMap[goalType]   = targetValue
    goals.progressParamMap[goalType]   = progressValue or 0
end

function goals.getTParamByGoal( goalType )
    return goals.targetParamMap[goalType]
end

function goals.getProgressByGoal( goalType )
    return goals.progressParamMap[goalType]
end

function goals.setTextByGoal(key , text)
    goals.textMap[key]   = text
end

function goals.getTextByGoal( key )
    -- body
    return goals.textMap[key]
end

function goals.clear()
    local goals     = goals
    goals.hasTimerGoal  = nil ; --存在时间
    goals.moveCount=nil;
    goals.moveCountAlready = nil;

    goals.defeatTeam = nil

    goals.bonusLineCount = nil;

    goals.m_isFinished = false;
    goals.isLost = nil;
    goals.hasGoal = nil;

    goals.targetParamMap    = {}
    goals.progressParamMap  = {}

    goals.textMap          = {}    
    -- 击败目标特殊处理，基本或额外置顶处理 ， 其余都是按照第一次设定目标进行
    goals.defeatTypeMap    = {} -- key type  value {targetAmount  , defeatedAmount} 
    goals.basicTargetMap   = {}
    goals.extraTargetMap   = {} -- 不包括 代码行数 的目标
end

-- public:
function goals.setLost()
    goals.isLost = true;
    goals.m_isFinished = true;
    game.ui.desktop.lose.show();
    game.ui.desktop.goals.update();
end

-- public:
function goals.win()
    local level = game.getLevel();
    --print("goals.win" , level.state , level.index ,level)
    --print(level)
    local tag   = false
    if(level and level.index == 1 and level.chapter == 1) then
        --特殊处理试试
        tag     = true
        --level.status    = game.config.Passed
        local levelList    = game.config.getLevelsInChapter(1)
        if levelList[2] then
            levelList[2].status     = game.config.Open
        end

    end

    if(level and level.status ~= game.config.Passed) then
        local charpter  = game.config.getChapters()
        charpter[level.chapter].passed  = level.index
        --print("goals.win333333333333333333333333")
        level.status = game.config.Passed;
        game.config.exchangeLevel(level);
    end
    game.ui.desktop.win.show();
end

function goals.getBasicTargetMap( ... )
    return goals.basicTargetMap
end

function goals.getExtraTargetMap( ... )
    return goals.extraTargetMap
end

--给界面使用的
function goals.needShowGoalByType( goalType , basicOrExtra )
    local key   = basicOrExtra and 'basicTargetMap' or 'extraTargetMap'
    if goals[key][goalType] then

        return true
    else
        return false
    end
end

--包括代码函数的额外目标
function goals.hasExtraTarget()
    local hasExtra  = false
    for i,v in pairs(goals.extraTargetMap) do
        return true
    end
    return goals.bonusLineCount ~= nil
end

function goals.judgeTargetIsBasic(goalType , basicOrExtra)
    local key   = basicOrExtra and 'extraTargetMap' or 'basicTargetMap'
    if goals[key][goalType] then 
        return not basicOrExtra
    else 
        return basicOrExtra
    end
end

function goals.getBasicTargetWhole()
    local map  = {}
    for i,v in pairs(goals.basicTargetMap) do
        map[i]  = v
    end

    for i,v in pairs(goals.defeatTypeMap) do
        if v.isBasic then
            map[i]  = v
        end
    end
    return map    
end

function goals.getExtraTargetWhole()
    local map  = {}
    for i,v in pairs(goals.extraTargetMap) do
        map[i]  = v
    end
    for i,v in pairs(goals.defeatTypeMap) do
        if not v.isBasic then
            map[i]  = v
        end
    end
    return map    
end

----------------------------------------------------细的方法------------------------------------------------------------

function goals.addDefeatGoalByType( amount , className ,isBasic , text)
    goals.hasGoal   = true
    local param     = {goalType = goals.goalType.defeatTarget , targetValue = amount , targetParam = className ,isBasic = isBasic,text = text or '击杀目标'}
    goals.addTargetList(param)
    game.ui.desktop.goals.update()
end

-- there can be multiple move goals that is shown as red cross. 
function goals.addMoveGoal(x, y, name , isBasic , text)
    local goals     = goals
    goals.hasGoal = true;
    goals.moveCount = (goals.moveCount or 0) + 1;
    goals.moveCountAlready = (goals.moveCountAlready or 0);

    --做原关卡逻辑的兼容
    if isBasic == nil then isBasic = true end
    local param     = {goalType = goals.goalType.moveGoal , isBasic = isBasic, 
                    targetValue = goals.moveCount,text = text or'到达目的地'}
    goals.addTargetList(param)

    local goal = game.spawnXY("goalpoint", x, y, name)
    game.ui.desktop.goals.update();
    
    if(game.config.isFirstTimeLoadLevel) then
        game.camera.moveTo(x, y)
        goal:say("目标：移动我方到这里~", 2);
        game.camera.ToStandardView(0.5)
    end


    return goal
end

function goals.completeMoveGoal(goal)
    goals.updateGoalProgress( goals.goalType.moveGoal,1)
end

function goals.addCollectGoal(amount , isBasic, text)
    goals.hasGoal = true;
        --做原关卡逻辑的兼容
    if isBasic == nil then isBasic = true end
    local param     = {goalType = goals.goalType.collectGrass , 
    targetValue = amount,isBasic = isBasic,text = text or'收集粮草'}
    goals.addTargetList(param)

    game.ui.desktop.goals.update();
end

function goals.collect(count)
   
    game.food = game.food + count;
    goals.updateGoalProgress( goals.goalType.collectGrass,count)
end

-- 天书残卷
function goals.addCollectBonusGoal(amount , isBasic, text)
    goals.hasGoal = true;
    --做原关卡逻辑的兼容
    if isBasic == nil then isBasic = false end
    local param     = {goalType = goals.goalType.bonusCollect ,
    targetValue = amount, isBasic = isBasic ,text = text or'收集天书残卷'}
    goals.addTargetList(param)
    game.ui.desktop.goals.update();
end

-- 天书残卷
function goals.collectBonus(count)
   
    goals.updateGoalProgress( goals.goalType.bonusCollect,count)
end

-- line of code bonus
function goals.addBonusLineCount(count)
    goals.bonusLineCount = count;
end


function goals.getLineOfCodeCount()
    local loc = 0;
    if(game.codeEntity) then
        local code = game.codeEntity:GetCommand() or "";
        for line in code:gmatch("([^\r\n]+)") do
            if(line:match("^%s*%-%-") or line:match("^%s+$")) then
                -- skip comment or empty lines
            else
                loc = loc + 1;
            end
        end
    end
    return loc;
end

-- @param amount: if nil, it means all. but if this is nil, this function must be called after all enemy units are spawned
-- @param team: default to "chu"
function goals.addDefeatGoal(amount, team , isBasic, text)
    goals.hasGoal = true;
    team = team or "chu"
    goals.defeatTeam = team
    if(not amount) then
        amount = game.getUnitCountByTeam(team)
    end

    --做原关卡逻辑的兼容
    if isBasic == nil then isBasic = true end  
    local param     = {goalType = goals.goalType.defeatTeam , targetValue = amount, 
                    isBasic = isBasic ,text = text or'击败敌人' }
    goals.addTargetList(param)

    game.ui.desktop.goals.update();
    
    if(game.config.isFirstTimeLoadLevel) then
        local enemies = game.findByTeam(team)
        if(enemies and #enemies>0) then
            local firstEnemy = enemies[1]
            if(firstEnemy) then
                local x, y = firstEnemy:getPos()
                game.camera.moveTo(x, y)
                firstEnemy:say(format("目标：消灭%d个敌人单位", amount),  2);
                game.camera.ToStandardView(0.5)
            end
        end
    end
    
end

function goals.defeat(enemy)
    if(goals.defeatTeam == enemy.team) then
        goals.updateGoalProgress( goals.goalType.defeatTeam,1)        
    end
    local targetClass   = enemy.className
    if goals.defeatTypeMap[targetClass] then
        goals.updateGoalProgress( goals.goalType.defeatTarget,1 , targetClass)
    end
end

-- @param seconds: if positive it means we need to survive this seconds. 
-- if negative, it means that we must complete other quests before this time runout
function goals.addSurvivalGoal(seconds ,isBasic, text)
    goals.hasGoal = true;
    goals.hasTimerGoal  = true

    --做原关卡逻辑的兼容
    if isBasic == nil then isBasic = true end    
    local param     = {goalType = goals.goalType.survivalTime , isBasic = isBasic ,
                        targetValue = seconds,  text = text or'生存时间' }
    goals.addTargetList(param) 

    game.ui.desktop.goals.update();
    
    if(game.config.isFirstTimeLoadLevel and seconds) then
        tip(format("你需要抵抗敌人的攻击%d秒", seconds))
    end
end

run(function()
    while(true) do
        if(goals.hasTimerGoal and not goals.isFinished() and game.isRunning()) then
            goals.updateGoalProgress(goals.goalType.survivalTime , 1)
            game.wait(1)
        else
            wait(1)
        end
    end
end)

function goals.isFinished()
    return goals.m_isFinished == true;
end


----------------------------------------------------分割线------------------------------------------------------------
function goals.CheckFinish( ... )
    local goals     = goals
    if goals.m_isFinished then return end
    if not goals.hasGoal then return end
    local isFinished    = true
    local basicTargetMap    = goals.basicTargetMap
    -- 旧的判断
    for i,v in pairs(basicTargetMap) do
        local targetNum   = goals.getTParamByGoal(v.goalType) or 0
        local pNum   = goals.getProgressByGoal(v.goalType) or 0
        if targetNum > pNum then
            isFinished  = false
            break
        end
    end
    --新类别判断
    for i,v in pairs(goals.defeatTypeMap) do
        if v.isBasic then
            local targetNum   = goals.getTParamByGoal(v.className) or 0
            local pNum   = goals.getProgressByGoal(v.className) or 0
            if targetNum > pNum then
                isFinished  = false
                break
            end            
        end
    end
    if isFinished then
        goals.m_isFinished = true;
        goals.win();
    end  
end

function goals.CheckExtraFinish()
    local extraTargetMap    = goals.extraTargetMap
    -- 旧的判断
    for i,v in pairs(extraTargetMap) do
        local targetNum   = goals.getTParamByGoal(v.goalType) or 0
        local pNum   = goals.getProgressByGoal(v.goalType) or 0
        if targetNum > pNum then
            return false
        end
    end

    for i,v in pairs(goals.defeatTypeMap) do
        if not v.isBasic then
            local targetNum   = goals.getTParamByGoal(v.className) or 0
            local pNum   = goals.getProgressByGoal(v.className) or 0
            if targetNum > pNum then
                return false
            end            
        end
    end

    return true
end

-- @param nStarIndex: 1 or 2 or 3
function goals.hasGoalStar(nStarIndex)
    if(nStarIndex == 1) then
        return goals.isFinished()
    elseif(nStarIndex == 2) then
        return goals.CheckExtraFinish()
    elseif(nStarIndex == 3) then
        if(goals.hasGoalStar(2) and (not goals.bonusLineCount or goals.bonusLineCount >= goals.getLineOfCodeCount()) ) then
            return true;
        else
            return false;
        end
    else
        return false;
    end
end

goals.clear()