-- public API for game interface
local game = gettable("game")
local entities = gettable("game.entities")
-- whether it is dev mode, in dev mode, all levels are unlocked, and user code is NOT saved
game.isDev = false
game.food = 0
game.codeEntity = nil;
game.curTick = 0;

local curLevel;

-- @param classType: "hero"
function game.spawnXY(classType, x, y, name)
    local classT = game.units[classType.."Class"] or game.units[classType]
    if(classT) then
        local obj = classT:new():init(name)
        obj:setPos(x,y)
        entities[obj.name] = obj;
        return obj;
    end
end

-- @param classType: "hero"
function game.spawnXYGroup(classType, x, y, name, count)
    local classT = game.units[classType.."Class"] or game.units[classType]
    if(classT) then
        local obj = game.units.group:new():init(name, count, classType)
        obj:setPos(x,y)
        return obj;
    end
end


-- coordinates are always relative to min
-- @param min: {x,y,z} 
-- @param max: {x,y,z} 
function game.setRegion(min, max)
    game.minPos = min;
    game.maxPos = max;
    
    cmd("/property UseAsyncLoadWorld false")
    cmd(format("/loadregion %d %d %d 200", min[1], min[2], min[3]))
    cmd("/property UseAsyncLoadWorld true")
end
game.setRegion({19268,5,19205}, {19268+46,5,19205+64})

function game.xyToGlobal(x, y)
    return game.minPos[1] + x,   game.minPos[2],  game.minPos[3] + y
end

function game.globalToXY(x, y, z)
    return x - game.minPos[1] ,   z - game.minPos[3]
end

-- call this at the start of the game
function game.start(chapter)
    local curChapter = chapter;
    if (not curChapter) then
        if (curLevel) then
            curChapter = curLevel.chapter;
        else
            curChapter = 1;
        end
    end
    
    game.camera.RestoreFocus()
    game.unloadLevel()
    game.cleanup()
    --game.config.load()
    game.ui.desktop.close()
    game.ui.worldmap.show(curChapter)
end

function game.unloadLevel()
    if(curLevel) then
        local level = curLevel;
        curLevel = nil
        if(level.sceneFile) then
            local min = game.minPos;
            cmd("/loadtemplate", format("-r -nohistory %d %d %d %s", min[1], min[2], min[3], level.sceneFile));
        end
    end
    game.codeblock = nil;
    if(game.codeEntity) then
        game.codeEntity:CloseEditor();
        game.codeEntity = nil;
    end
    game.broadcast.reset()
end


-- load a given level
-- @param bResetCode: true to reset code to default content
function game.loadLevel(level, bResetCode)
    if(level and level.pos) then
        local entity = getBlockEntity(level.pos[1],level.pos[2],level.pos[3])
        if(entity) then
            game.ui.desktop.close();
            -- this will disable editing when playing a cut scene movie
            cmd("/mode game") 
            cmd("/hide desktop") 
            game.unloadLevel()
            curLevel = level
            game.config.lastLoadedLevelName = nil;
            game.timeSpeed = 1;
            game.resume();
            GameLogic:CodeWarLoadLevel();
            
            if(level.mapRegion) then
                local min = level.mapRegion.min
                local max = {min[1] + level.mapRegion.size[1], min[2], min[3]+level.mapRegion.size[2]}
                game.setRegion(min, max);
            end
            if(level.sceneFile) then
                local min = game.minPos;
                cmd("/loadtemplate", format("-nohistory %d %d %d %s", min[1], min[2], min[3], level.sceneFile));
            end
            
            game.codeEntity = entity;
            if(bResetCode) then
                game.resetCode("");
            end
            game.isResetCode = bResetCode;
            local setupCodeEntity = getBlockEntity(level.pos[1]+1,level.pos[2],level.pos[3]+2)
            if(setupCodeEntity) then
                setupCodeEntity:Restart()
            else
                game.startCoding();
            end
        end
    end
end

function game.stopCoding()
    if(game.codeblock) then
        -- game.codeblock:StopAll()
        -- game.setCodeBlock(game.codeblock)
        game.isStopCoding = true;
        game.curTick = 0;
        game.codeblock:RestartAll();
    end
end

function game.openCodeEditor()
    local level = game.getLevel();    
    if(level) then
        local entity = getBlockEntity(level.pos[1],level.pos[2],level.pos[3])
        if(entity) then
            entity:OpenEditor()
        end
    end
end
    
function game.startCoding()
    local level = game.getLevel();    
    if(level) then
        local entity = getBlockEntity(level.pos[1],level.pos[2],level.pos[3])
        if(entity) then
            entity:OpenEditor()
            game.ui.desktop.show()
            --game.ui.goals.show()
            game.camera.SetFocus()
            game.curTick = 0;
            entity:Restart();
        end
    end
end

function game.getLevel()
    return curLevel;
end
function game.playMusic()
    cmd("/music -channel1 "..curLevel.bgm)
    cmd("/music -channel2 "..curLevel.sound1)
end



local game = gettable("game")
local entities = gettable("game.entities")
local actorClassMap    = gettable("game.actorClassMap")
game.events = {}
game.blocks = {};
local nextId = 0;

function game.hwtPrint( ... )
    --print(...)
end

function game.nextName()
    nextId = nextId + 1
    return tostring(nextId)
end

function game.cleanup()
    for name, entity in pairs(entities) do
        entity:delete()
    end
    -- clear entities
    local k = next(entities)
    while k ~= nil do
        entities[k] = nil
        k = next(entities)
    end
    nextId = 0
    game.goals.clear()
    game.food = 0;
    -- clear built blocks if any
    for i, b in ipairs(game.blocks) do
        setBlock(b[1], b[2], b[3], 0)
    end
    game.blocks = {}
    game.moveTargets = {};
    game.broadcast.reset();
end

function game.registerActorClass( actorName)
    game.hwtPrint("registerActorClass",actorName)
    actorClassMap[actorName]    = true
end

function game.getActor( actorName)
    return actorClassMap[actorName]
end

function game.removeEntity(entity)
    entities[entity.name] = nil;
end

function game.getEntity(name)
    return entities[name]
end

function game.getUnitCountByTeam(team)
    local count = 0;
    for name, entity in pairs(entities) do
        if(not entity.isDead and entity.team == team) then
            count = count + 1;
        end
    end
    return count;
end

-- this function must be called in user code block
function game.setCodeBlock(codeblock)
    if(game.codeblock and game.codeblock~=codeblock) then
        game.codeblock:StopAll()
    end
    game.cleanup()
    -- we will wait nearby code blocks to load level before continue user code
    wait(0.2)
    
    local level = game.getLevel()
    if(level) then
        game.config.isFirstTimeLoadLevel = (game.config.lastLoadedLevelName ~= level.name)
        game.config.lastLoadedLevelName = level.name;
    end
    
    game.codeblock = codeblock;
    game.trace.setCodeBlock(codeblock);
    if(game.isResetCode) then
        game.isResetCode = nil;
        local code = game.fireEvent("resetcode")
        if(code) then
            game.resetCode(code)
        end
    else
        local code = game.fireEvent("resetcode")  or "";
        code = string.gsub(code, "\r\n", "");
        code = string.gsub(code, "\n", "");
        code = string.gsub(code, " ", "");
        if (game.codeEntity) then
            local npl = game.codeEntity:GetNPLCode() or "";
            npl = string.gsub(npl, "\r\n", "");
            npl = string.gsub(npl, "\n", "");
            npl = string.gsub(npl, " ", "");
            if (code == npl) then
                local recordCode = game.config.getLevelClientData(level);
                if (recordCode) then
                    game.resetCode(recordCode);
                end
            end
        end
    end
    game.camera.Reset();
    game.camera.SetFocus()
    game.isLoading = true
    game.fireEvent("loadlevel")
    game.isLoading = false
    
    -- tricky: we shall run empty code if user pressed game.isStopCoding
    if(game.isStopCoding) then
        game.isStopCoding = nil;
        terminate()
    end
end

-- set a global variable to be used in the current user code block
function game.setGlobal(name, value)
    if(game.codeblock and name) then
        local env = game.codeblock:GetCodeEnv()
        if(env) then
            env[name] = value
        end
    end    
end

-- @param eventName: such as "loadlevel"
function game.on(eventName, func)
    game.events[eventName] = func;    
end

function game.fireEvent(eventName, ...)
   local func = game.events[eventName] 
   if(func) then
        return func(...)
   end
end

function game.onLoadLevel(func)
    game.on("loadlevel", func)
end

function game.onResetCode(func)
    game.on("resetcode", func)
end

function game.setPassCode(code)
    local level = game.getLevel()
    if(level) then
        level.passCode = code;
    end
end

-- this function is used in editor block to reset code to initial state
function game.resetCode(code)
    if(code and game.codeEntity) then
        game.codeEntity:SetNPLCode(code);
        game.codeEntity:SetBlocklyXMLCode(nil);
        game.codeEntity:remotelyUpdated();
    end
end

function game.entityToSpawnable(entity)
    if(entity and entity.GetActor) then
        local actor = entity:GetActor()
        if(actor) then
            return actor.tag;
        end
    end
end

-- return blockId for the floor, otherwise nil. it may also return -1 if there is entities beneath it
function game.hasFloor(x, y, offset)
    local sx, sy, sz =  game.xyToGlobal(x, y);
    sy = sy-1+(offset or 0)
    local blockId = getBlock(sx, sy, sz) or 0;
    if(blockId == 0 or blockId == 75 or blockId == 76) then
        local entities = GameLogic.EntityManager.GetEntitiesInBlock(sx, sy, sz)
        if (entities and next(entities)) then
            for entity, _ in pairs(entities) do
                local obj = game.entityToSpawnable(entity)
                if(obj and obj.className == "item") then
                    return -1, obj;
                end
            end
        end
        return false;
    else
        return blockId;
    end
end

-- @param offset: default to 0
function game.isFreeSpace(x, y, offset, bCheckMoveTarget)
    if(bCheckMoveTarget and game.getMoveTarget(x, y)) then
        return false;
    end
    local sx, sy, sz =  game.xyToGlobal(x, y);
    sy = sy + (offset or 0)
    local blockId = getBlock(sx, sy, sz) or 0;    
    if(blockId == 0) then
        local entities = GameLogic.EntityManager.GetEntitiesInBlock(sx, sy, sz)
        if (entities and next(entities)) then
            for entity, _ in pairs(entities) do
                local obj = game.entityToSpawnable(entity)
                if(obj and (obj.typeName == "fence" or obj.className == "fence")) then
                    return false
                end
            end
        end
        return true;
    elseif (blockId == 22 or blockId == 254 or blockId == 164 or blockId == 132 or (blockId >= 113 and blockId <= 116)) then
        return true;
    else
        -- check for other transparent blocks?
    end
end

function game.canStandOn(x, y, offset)
    if(game.isFreeSpace(x, y, offset)) then
        if(game.hasFloor(x, y, offset)) then
            return true;
        end
    end
end

--return entities
function game.getEntitiesByPos(x,y,offset)
    local sx, sy, sz =  game.xyToGlobal(x, y);
    sy = sy+(offset or 0)
    local entities = GameLogic.EntityManager.GetEntitiesInBlock(sx, sy, sz)
    local objs = {}
    if (entities and next(entities)) then
        for entity, _ in pairs(entities) do
            local obj = game.entityToSpawnable(entity)
            if(obj) then
                table.insert(objs,obj)
            end
        end        
    end
    return objs
end

-- types of objects to build 
local buildTypesToId = {
    bridge = 126 ,-- {class = "bridge",  maxHealth=50, offsetZ = -1},
    -- newBridge = {class = "item",  maxHealth=50,  offsetZ = -1}
    -- we will destroy items in the block or the floor block
    air = 0, 
    fence = {class = "item",  maxHealth=50, assetfile="model/blockworld/Fence/Fence_Cross.x", icon="textures/fence.png" , typeName = 'fence'},
}

-- it will first build floor if not exists, and then build on top of the floor
-- @return true or the object created. 
function game.build(buildType, x,y)
    if(x>=0 and x<=100 and y>=0 and y<=100) then
        buildType = buildTypesToId[buildType or ""] or buildType;
        if(type(buildType) == "number") then
            local sx, sy, sz =  game.xyToGlobal(x, y);
            local isDestroyBridge   = false
            if(buildType == 0) then
                local id, entity = game.hasFloor(x, y, 1)
                if entity and entity.getTypeName and (entity:getTypeName() == 'fence') then
                    entity:delete();
                    local goals     = game.goals
                    goals.updateGoalProgress( goals.goalType.defeatFence,1)
                    --此处添加栅栏的目标
                else
                    id, entity = game.hasFloor(x, y)
                    if id == 126 then
                        isDestroyBridge =true
                    end
                    if(entity) and (id)  then
                        sy = sy-1
                        entity:delete();
                    end
                    
                    if (id) then
                        sy = sy - 1
                    end
                end
            else
                if(not game.hasFloor(x, y)) then
                    sy = sy-1
                else
                    return false
                end
                -- can not build when there is entities in it. 
                local entities = GameLogic.EntityManager.GetEntitiesInBlock(sx, sy, sz)
                if (entities and next(entities)) then
                    return false;
                end
            end
            if isDestroyBridge then 
                local goals     = game.goals
                goals.updateGoalProgress( goals.goalType.defeatBridge,1)
            end
            setBlock(sx, sy, sz,  buildType)
            game.blocks[#game.blocks+1] = {sx, sy, sz, buildType};
            return true;
        elseif(type(buildType) == "table") then
            local v =  buildType;
            local p;
            if v.num and v.num >1 then
                p = game.spawnXYGroup(v.class, x, y, nil, v.num):setTeam(v.team)
            else
                p =  game.spawnXY(v.class, x, y, nil):setTeam(v.team)
            end
            if v.offsetZ then
                p:setPos(x,y,v.offsetZ)
            end
            
            if(v.assetfile) then
                p:setAssetFile(v.assetfile);
            end
            if(v.icon) then
                p:setIcon(v.icon);
            end
            if(v.maxHealth) then
                p:setMaxHealth(v.maxHealth);
            end
            if v.facing then
                p:turnTo(v.facing)
            end
            if v.typeName and p.setTypeName then
                p:setTypeName(v.typeName)
            end
            return p;
        end
    end
end


-- @param entities: if nil, we will search for all entities in visible range
function game.findNearest(entities, x, y)
    entities = entities or self.entities;
    local nearestEntity, minDist = nil, 999999;
    for _, entity in pairs(entities) do
        if(not entity.isDead) then
            local dist = entity:distanceToXY(x,y)
            if(dist < minDist) then
                minDist = dist;
                nearestEntity = entity;
            end
        end
    end
    return nearestEntity; 
end

-- @param entities: if nil, we will search for all entities in the game
function game.findByType(name, entities)
    entities = entities or self.entities;
    local list = {};
    for i = 1, #entities do
        if(entities[i]:aa(name)) then
            list[#list+1] = entities[i];
        end
    end
    return list; 
end

function game.findByTeam(team)
    local count = 0;
    local list = {};
    for name, entity in pairs(entities) do
        if(not entity.isDead and entity.team == team) then
            list[#list+1] = entity;
        end
    end
    return list;
end

function game.copyXYToClipboard(x,y)
    if(x and y) then
        local text = format("%d, %d", x, y);
        cmd("/copytoclipboard", text)
        tip(text.." 已经复制到裁剪版")
    end
end

function game.isRunning()
    if(game.codeblock) then
        return game.codeblock:IsLoaded();
    end
end

-- get the object that wants to move into the target position
function game.getMoveTarget(x, y)
    return game.moveTargets[x*10000+y];
end

function game.addMoveTarget(x, y, obj)
    game.moveTargets[x*10000+y] = obj;
end

function game.deleteMoveTarget(x, y, obj)
    if(game.moveTargets[x*10000+y] == obj) then
        game.moveTargets[x*10000+y] = nil;
    end
end

function game.wait(seconds)
    local totalSteps = math.floor((seconds or 0) * game.ticksPerSecond / game.stepTicks + 0.1)
    for i = 1, math.max(totalSteps, 1) do
        game.waitForNextStep(true)
    end
end