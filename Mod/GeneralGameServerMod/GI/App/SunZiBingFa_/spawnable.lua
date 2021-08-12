
local spawnable = inherit(nil, "game.units.spawnable")
spawnable.className = "spawnable"

spawnable.animIdAttack = 6;
spawnable.health = 100;
spawnable.maxHealth = 100;
spawnable.icon = "textures/soldier_han.png#0 0 80 80"
spawnable.maxSpeed = 2;
spawnable.team = "qi";
spawnable.visibleRange = 5;
spawnable.attackDamage = 7;
spawnable.attackRange = 2;
spawnable.attackCD = 0.5; -- cool down
spawnable.behavior = nil; -- Scampers, AttacksNearest, Defend, RunsAway
spawnable.physicsRadius = 0.25
spawnable.has_torch = false
spawnable.isFreeSpace = false; -- whether it takes up space in a block


function spawnable:init(name)
    self.name = name or (self.className..game.nextName());
    
    local obj = game.getEntity(self.name)
    if(obj) then
        echo("warn: duplicated name created for "..self.name)
        return obj;
    end
    --只有创建actor的时候才会执行。而且还要调用才可以，实际需要重写inherit方法
    game.registerActorClass(self.className)

    clone(self.className, self)
    repeat 
        self:wait() 
    until(self.status == "ready")
    self.actor = getActor(self.name);
    self.actor.tag = self;
    self:setPos(-1,-1)
    
    runForActor(self.name, function()
        setActorValue("walkSpeed", self.maxSpeed)
        setActorValue("physicsRadius", self.physicsRadius)
    end) 

    return self;
end

function spawnable:setTypeName(typeName)
    -- body
    self.typeName = typeName
end

function spawnable:getTypeName( ... )
   return self.typeName
end

function spawnable:setMaxHealth(maxHealth)
    self.maxHealth = maxHealth
    self.health = self.maxHealth
end

function spawnable:setAttackDamage(damage)
    self.attackDamage = damage
end
function spawnable:setAttackRange(range)
    self.attackRange = range
end
function spawnable:setAttackCD(seconds)
    self.attackCD = seconds
end

function spawnable:setGroupId(id)
    runForActor(self.name, function()
        setActorValue("groupId", id)
    end)
end

function spawnable:setAssetFile(filename)
    runForActor(self.name, function()
        setActorValue("assetfile", filename)
    end)
end

-- entities in different team can attack each other
-- @teamname: "", "han", "chu". "" means neutral
function spawnable:setTeam(teamname)
    self.team = teamname
    if(teamname == "wei" and self.icon=="textures/soldier_han.png#0 0 80 80") then
        self.icon="textures/soldier_chu.png#0 0 80 80"
    elseif(teamname == "qi" and self.icon=="textures/soldier_chu.png#0 0 80 80") then
        self.icon ="textures/soldier_han.png#0 0 80 80"
    end
    return self;
end

function spawnable:setPhysicsRadius(radius)
    self.physicsRadius = radius;
    runForActor(self.name, function()
            setActorValue("physicsRadius", self.physicsRadius)
    end) 
end

function spawnable:getIcon()
    return self.icon    
end

function spawnable:setIcon(icon)
    self.icon = icon
end

function spawnable:showInfo()
    game.ui.desktop.info.setPlayer(self.name)
    local x, y = self:getPos()
    game.copyXYToClipboard(x, y)
    self:wait();
end

-- use setDead() instead of delete in most cases
function spawnable:delete()
    self:setMoveTarget(nil, nil)
    self:setPos(-1,-1);
    self:killTimer();
    runForActor(self.name, function()
        game.removeEntity(self)
        delete();
    end)       
end

function spawnable:facingFromDirection(dx, dy)
    if(dx~=0 or dy~=0) then
        local dist = math.sqrt(dx*dx+dy*dy)
        local angle = math.acos(dx/dist);
        if(dy>0) then
            angle = -angle
        end
        return angle*180/math.pi
    else
        return self:getFacing()
    end
end

function spawnable:stop()
    self:anim(0)
end

function spawnable:hasReachedTarget()
    if(self.targetX) then
        local cx, cy = self:getPos()
        return (cx == self.targetX and cy == self.targetY)
    end
end

-- select one of the 9 nearby blocks that we can walk on and closest to x, y position. 
function spawnable:getNextMoveTarget(x, y)
    local cx, cy = self:getPos()    
    local dx, dy = x - cx, y-cy
    if(dx~=0 or dy~=0) then
        local adx, ady = math.abs(dx), math.abs(dy)
        local offsetX = (dx > 0 and 1) or ((dx < 0) and -1) or 0;
        local offsetY = (dy > 0 and 1) or ((dy < 0) and -1) or 0;
        
        if(adx > ady)then
            if(game.canStandOn(cx + offsetX, cy)) then
                return cx + offsetX, cy
            elseif(game.canStandOn(cx + offsetX, cy + offsetY) and game.canStandOn(cx, cy + offsetY)) then
                return cx + offsetX, cy + offsetY
            elseif(game.canStandOn(cx, cy + offsetY)) then
                return cx, cy + offsetY
            end
        elseif(adx == ady)then
            if(game.canStandOn(cx + offsetX, cy + offsetY) and (game.canStandOn(cx + offsetX, cy) or game.canStandOn(cx, cy + offsetY))) then
                return cx + offsetX, cy + offsetY
            elseif(game.canStandOn(cx + offsetX, cy)) then
                return cx + offsetX, cy
            elseif(game.canStandOn(cx, cy + offsetY)) then
                return cx, cy + offsetY
            end
        else
            if(game.canStandOn(cx, cy + offsetY)) then
                return cx, cy + offsetY
            elseif(game.canStandOn(cx + offsetX, cy + offsetY) and game.canStandOn(cx + offsetX, cy)) then
                return cx + offsetX, cy + offsetY
            elseif(game.canStandOn(cx + offsetX, cy)) then
                return cx + offsetX, cy
            end
        end
    else
        return x, y;
    end
end

function spawnable:setMoveTarget(tx, ty)
    if(not self.isFreeSpace and (self.targetX~=tx or self.targetY~=ty)) then
        if(self.targetX) then
            game.deleteMoveTarget(self.targetX, self.targetY, self)
        end
        if(tx) then
            game.addMoveTarget(tx, ty, self);
        end
        self.targetX, self.targetY = tx, ty;
    end
end

function spawnable:moveStep(x, y, step)
    game.waitForNextStep();
    game.trace.mark()
    x, y = math.floor(x+0.5), math.floor(y+0.5)
    
    self.isMoving = true;
    local walkSpeed = self.maxSpeed;
    runForActor(self.name, function()
        walkSpeed = getActorValue("walkSpeed");
    end)
    
    local oldX, oldY = self:getPos()
    local dx, dy = x - oldX, y - oldY    
    if (dx ~= 0 or dy ~= 0) then
        local totalTicks = math.floor(math.sqrt(dx^2 + dy^2) * step / walkSpeed * game.ticksPerSecond)
        totalTicks = math.floor(totalTicks/game.stepTicks+0.5) * game.stepTicks;
        if(totalTicks > 0) then
            local angle = self:facingFromDirection(dx, dy);
            self:turnTo(angle, -1);
            self:anim(5);
            
            local fromX, fromY, fromZ = getPos(self.name)
            local i = 0;
            while (i < totalTicks) do
                local ticks = game.waitForNextTick()
                i = math.min(i + ticks, totalTicks);
                setPos(fromX + dx*step*i/totalTicks, fromY, fromZ+dy*step*i/totalTicks, self.name)
            end
        end
    end
    
    self.isMoving = false;
    self:anim(0)
    game.waitForNextStep();
end

function spawnable:moveDirectly(x, y, duration)
    game.waitForNextStep();
    game.trace.mark()
    x, y = math.floor(x+0.5), math.floor(y+0.5)
    
    self.isMoving = true;
    
    local oldX, oldY = self:getPos()
    local dx, dy = x - oldX, y - oldY
    if (dx ~= 0 or dy ~= 0) then
        local totalTicks = duration * game.ticksPerSecond;
        totalTicks = math.floor(totalTicks/game.stepTicks+0.5) * game.stepTicks;
        if(totalTicks > 0) then
            local angle = self:facingFromDirection(dx, dy);
            self:turnTo(angle, -1);
            self:anim(5);
            
            local fromX, fromY, fromZ = getPos(self.name)
            local i = 0;
            while (i < totalTicks) do
                local ticks = game.waitForNextTick()
                i = math.min(i + ticks, totalTicks);
                setPos(fromX + dx*i/totalTicks, fromY, fromZ+dy*i/totalTicks, self.name)
            end
        end
    end
    
    self.isMoving = false;
    self:anim(0)
    game.waitForNextStep();
end

function spawnable:moveXY(x, y, secondsToWait)
    game.waitForNextStep();
    game.trace.mark()
    x, y = math.floor(x+0.5), math.floor(y+0.5)
    
    self.isMoving = true;
    local walkSpeed = self.maxSpeed;
    runForActor(self.name, function()
        walkSpeed = getActorValue("walkSpeed");
    end)
    
    local fromTicks = game.curTick;
    local maxDurationTicks = 999999;
    local reachedPosition = false;
    if (secondsToWait and secondsToWait > 0) then
        maxDurationTicks = secondsToWait * game.ticksPerSecond;
    end
    
    while(game.isStepTick()) do
        local tx, ty = self:getNextMoveTarget(x, y)
        if(not tx) then
            break;
        end
        local moveTarget = game.getMoveTarget(tx, ty)
        if(moveTarget == self) then
            break;
        end
        if (self.isDead) then
            break;
        end
        if(self.isFreeSpace or not moveTarget) then
            local oldX, oldY = self:getPos()
            self:setMoveTarget(tx, ty)
            
            
            local dx, dy = tx-oldX, ty-oldY
            if(dx~=0 or dy~=0) then
                
                local angle = self:facingFromDirection(dx, dy)
                --echo({self.name, game.curTick, "111"})
                self:turnTo(angle, -1)
                --echo({self.name, game.curTick, "222"})
                local totalTicks = math.floor(math.sqrt(dx^2 + dy^2) / walkSpeed * game.ticksPerSecond)
                totalTicks = math.floor(totalTicks/game.stepTicks+0.5) * game.stepTicks
                if(totalTicks > 0) then
                    local fromX, fromY, fromZ = getPos(self.name)
                    local i = 0;
                    
                    self:anim(5)
                    while( i < totalTicks) do
                        local ticks = game.waitForNextTick()
                        i = math.min(i + ticks, totalTicks);
                        setPos(fromX + dx*i/totalTicks, fromY, fromZ+dy*i/totalTicks, self.name)
                    end
                else
                    self:setPos(tx, ty);
                    game.waitForNextStep(true);
                end
            else
                self:setPos(tx, ty);
                game.waitForNextStep(true);
            end
        end    
        if(tx == x and ty==y) then
            reachedPosition = true
            break;
        end
        if(moveTarget and not self.isFreeSpace) then
            -- if the object at the move target is moving, we will wait until it stops
            while (true) do
                game.waitForNextStep(true);
                moveTarget = game.getMoveTarget(tx, ty)
                if(not moveTarget or not moveTarget.isMoving) then
                    break
                end
                if((game.curTick - fromTicks) > maxDurationTicks) then
                    break;
                end
            end
            if(moveTarget) then
                reachedPosition = true
                break
            end
        end
        if((game.curTick - fromTicks) >= maxDurationTicks) then
            break;
        end
    end
    self.isMoving = false;
    if(reachedPosition) then
        self:anim(0)
    end
    game.waitForNextStep();
end


function spawnable:moveUp()
    local oldX, oldY = self:getPos()
    self:moveXY(oldX, oldY+1)    
end

function spawnable:moveDown()
    local oldX, oldY = self:getPos()
    self:moveXY(oldX, oldY-1)   
end

function spawnable:moveLeft()
    local oldX, oldY = self:getPos()
    self:moveXY(oldX-1, oldY)   
end

function spawnable:moveRight()
    local oldX, oldY = self:getPos()
    self:moveXY(oldX+1, oldY)   
end

-- @param distance: default to 1 block
function spawnable:moveForward(distance)
    distance = distance or 1;
    local oldX, oldY = self:getPos() 
    local facing = self:getFacing() *math.pi /180;
    local x = oldX + math.cos(facing) * distance;
    local y = oldY - math.sin(facing) * distance;
    self:moveXY(x, y)
    self:wait(game.stepSeconds * 5);
end

-- @param angle: angle or target
function spawnable:turnTo(angle, duration)
    if(type(angle)  == "number") then
        self.actor:SetFacing(angle/180*math.pi)
    elseif(type(angle)  == "table" and angle.getPos) then
        local tx, ty = angle:getPos()
        local x, y = self:getPos();
        angle = self:facingFromDirection(tx-x, ty-y)
        self:turnTo(angle)
    end
    if(duration and duration > 0) then
        self:wait(duration)
    end
end

function spawnable:turnLeft()
    self:turnTo((math.floor(self:getFacing()/90 + 0.5)  - 1)*90)
    game.waitForNextStep();
end

function spawnable:turnRight()
    self:turnTo((math.floor(self:getFacing()/90 + 0.5) +1)*90)
    game.waitForNextStep();
end

-- @param offset: optional height offset, default to 0
function spawnable:setPos(x,y, offset)
    self:setMoveTarget(x,y)
    local x_, y_, z_ = game.xyToGlobal(x+0.5,y+0.5)
    y_ = y_ + (offset or 0)
    setPos(x_, y_, z_, self.name)
end

function spawnable:getPosReal()
    local x, y, z = getPos(self.name)
    x, y = game.globalToXY(x or 0, y or 0, z or 0)
    return x, y;
end

function spawnable:getPos()
    local x, y, z = getPos(self.name)
    x, y = game.globalToXY(x or 0, y or 0, z or 0)
    return math.floor(x), math.floor(y)
end


function spawnable:getFacing()
    return getFacing(self.name)
end

function spawnable:distanceTo(target)
    local x, y = self:getPos()
    local x1, y1 = target:getPos();
    if(x == x1 and y == y1) then
        return 0
    else
        return math.sqrt((x-x1)^2+(y-y1)^2)
    end
end

function spawnable:distanceToXY(x1, y1)
    local x, y = self:getPos()
    if(x == x1 and y == y1) then
        return 0
    else
        return math.sqrt((x-x1)^2+(y-y1)^2)
    end
end

-- same as buildXY, except that we will build in front of the player
function spawnable:build(buildType)
    local x, y = self:getPos()
    local facing = self:getFacing() / 180 * 3.14
    x = x + math.floor(math.cos(facing)+0.5)
    y = y - math.floor(math.sin(facing)+0.5)
    self:buildXY(buildType, x,y)
end

function spawnable:buildXY(buildType, x,y)
    game.trace.mark()
    local oldX, oldY = self:getPos()    
    if(x~=oldX or y~=oldY) then
        local dx, dy = x-oldX, y-oldY
        tx, ty = x, y;
        if(dx > 0) then
            tx = x - 1
        elseif(dx < 0) then
            tx = x + 1
        end
        if(dy > 0) then
            ty = y - 1
        elseif(dy < 0) then
            ty = y + 1
        end
        self:moveXY(tx,ty)
    end
    local cx,cy = self:getPos();
    if(cx~=x or cy~=y and math.abs(cx-x)<=1 and math.abs(cy-y)<=1) then
        local p = game.build(buildType, x,y);
        if(type(p) == "table") then
            p:setTeam(self.team);
        end
        self:stop()
    end
    self:wait();
end

function spawnable:wait(seconds)
    if(game.isLoading and not seconds) then
        wait();
        return
    end
    if(seconds and seconds >= 1) then
        game.trace.mark()
    end
    local totalSteps = math.floor((seconds or 0) * game.ticksPerSecond / game.stepTicks + 0.1)
    for i = 1, math.max(totalSteps, 1) do
        game.waitForNextStep(true)
    end
end

function spawnable:say(text, seconds)
    game.broadcast.send(self.name, text);
    runForActor(self.name, function()
        say(text)
        self:wait(seconds)
        say("")
    end)
end

function spawnable:onReceive(callback)
    game.broadcast.onReceive(callback);
end

function spawnable:anim(name, duration)
    local entity = self.actor:GetEntity();
    if(entity) then
        entity:EnableAnimation(true);
        entity:SetAnimation(name)
        if (duration) then
            self:wait(duration);
        end
    end
end

function spawnable:setVisibleRange(range)
    self.visibleRange = range
end

function spawnable:setDead()
    -- self:anim(0, 4)
    self:setMoveTarget(nil, nil)
    self.isDead = true
    if(self.headon) then
        self.headon:CloseWindow();
    end
    if(self.torch) then
        self.torch:setDead()
    end
    self:killTimer();
    runForActor(self.name, function()
        hide()
        self:setPos(-1,-1)
    end)   
    --self:wait()
end

function spawnable:takeDamage(amount, from)
    if(self.isDead) then
        return
    end
    
    local h = self.health - amount
    self.health = math.max(0, h)
    self.health = math.min(self.maxHealth, h)

    if(self.health <= 0) then
        game.goals.defeat(self)
        self:setDead()
    elseif(not self.headon) then
        runForActor(self.name, function()
            self.headon = window([[
<div style="margin-left:-20px;width:40px;margin-top:-20px">
    <div style="position:relative;">
        <pe:progressbar style="width:40px;height:5px;" Minimum="0" Maximum="100" value='<%=math.floor(self.health/self.maxHealth*100) %>'   getter="value" />  
    </div>
</div>
]],"headon", 0, 0, 300, 100, nil, {self = self})
        end)
        
    end
    playSound("break")
    self:wait()
end

-- should not be called from scripting interface
function spawnable:doAttack_(target)
    self:turnTo(target, -1)
    target:takeDamage(self.attackDamage, self)
    self:anim(self.animIdAttack, self.attackCD)
    self:anim(0)
end

-- target: if nil, we will attack nearest visible enemy
function spawnable:attack(target)
    if self.isDead then return end
    self:show();
    game.trace.mark()
    
    if(type(target) == "string") then
        target = game.getEntity(target);
        if(not target) then
            self:wait()
            return
        end
    end
    if(not target) then
        target = self:findNearestEnemy();
        if(target) then
            local dist = self:distanceTo(target);
            self:turnTo(target)
            if(dist <= self.attackRange) then
                self:doAttack_(target)
            end
        end
    elseif(target and self~=target and not self:isFriendOf(target) and not target.isDead) then
        while(true) do
            local dist = self:distanceTo(target);
            if(dist <= self.visibleRange) then
                self:turnTo(target)
                if(dist <= self.attackRange) then
                    self:doAttack_(target)
                    break;
                else
                    local distance  = dist -self.attackRange
                    if distance > 4 then
                        distance    = math.floor(distance/2)
                    elseif distance > 3 then
                        distance    = distance - 1
                    else
                        distance    = 1
                    end
                    distance        = math.ceil(distance)
                    self:moveForward(distance)
                end
            else
                break;
            end
        end
    end
    self:wait()
end

function spawnable:hide()
    if(not self.hidden) then
        self.hidden = true;
        runForActor(self.name, function()
            setActorValue("opacity",  0.3);
        end)
    end
end

function spawnable:show()
    if(self.hidden) then
        self.hidden = false;
        runForActor(self.name, function()
            setActorValue("opacity",  1);
        end)
    end    
end

function spawnable:rush()
end

function spawnable:fire()
end

function spawnable:shield()
end

function spawnable:canSee(target)
    return (target and not target.isDead and not target.hidden and 
        self:distanceTo(target) <= self.visibleRange)
end

function spawnable:canSearch()
    return true
end
function spawnable:findAll()
    local actors = self.actor:FindActorsByRadius(math.floor(self.visibleRange), 1)
    local entities = {};
    for i=1, #actors do
        local actor = actors[i]
        if(actor.tag and self:canSee(actor.tag) and actor.tag:canSearch()) then
            entities[#entities+1] = actor.tag
        end
    end
    self:wait()
    return entities;
end

function spawnable:isTypeOf(className)
    return self.className == className;
end

function spawnable:getType()
    return self.className
end

function spawnable:isFriendOf(target)
    if(target and self.team == target.team) then
        return true;
    end
end

-- please note if self.team is nil, it is neural which is not enemy to anyone
function spawnable:isEnemyOf(target)
    if(self.team ~= target.team and self.team~="" and target.team~="") then
        return true;
    end
end

-- @param entities: if nil, we will search for all entities in visible range
function spawnable:findByType(name, entities)
    entities = entities or self:findAll();
    local list = {};
    for i = 1, #entities do
        if(entities[i]:isTypeOf(name)) then
            list[#list+1] = entities[i];
        end
    end
    return list; 
end

function spawnable:findByTypeArray(nameArray , entities)
    entities     = entities or self:findAll();
    local map   = {}
    for i,v in ipairs(nameArray) do
        map[v]  = true
    end
    local list  = {}
    for i,v in pairs(entities) do
        local typeName  = v:getType()
        if map[typeName] and (not v.isDead) and (not v.isOnHand) then
            table.insert(list , v)
        end
    end

    return list
end

function spawnable:findEnemies()
    local entities = self:findAll();
    local list = {};
    for i = 1, #entities do
        if(entities[i]:isEnemyOf(self) and not entities[i]:isTypeOf("door")) then
            list[#list+1] = entities[i];
        end
    end
    return list; 
end
function spawnable:findEnemiesExceptFence()
    local entities = self:findAll();
    local list = {};
    for i = 1, #entities do
        if(entities[i]:isEnemyOf(self) and not entities[i]:isTypeOf("item") and not entities[i]:isTypeOf("door") )then
            list[#list+1] = entities[i];
        end
    end
    return list; 
end
function spawnable:findFriends()
    local entities = self:findAll();
    local list = {};
    for i = 1, #entities do
    --except fence
        if(entities[i]:isFriendOf(self) and not entities[i]:isTypeOf("item")) then
            list[#list+1] = entities[i];
        end
    end
    return list; 
end

-- @param entities: if nil, we will search for all entities in visible range
function spawnable:findNearest(entities)
    entities = entities or self:findAll();
    local list = {};
    local nearestEntity, minDist = nil, 999999;
    for i = 1, #entities do
        local entity = entities[i]
        if entity~=self and (not entity.isDead) then
            local dist = self:distanceTo(entity)
            if(dist < minDist) then
                minDist = dist;
                nearestEntity = entity;
            end
        end
    end
    return nearestEntity; 
end
-- return nil or enemy with out fence
function spawnable:findNearestEnemyExceptFence()
    return self:findNearest(self:findEnemiesExceptFence())
end
-- return nil or friend
function spawnable:findNearestFriend()
    return self:findNearest(self:findFriends())
end

-- return nil or enemy
function spawnable:findNearestEnemy()
    return self:findNearest(self:findEnemies())
end

-- return nil or item
function spawnable:findNearestItem(typeArrayData)
    local typeArray     = typeArrayData  or {'item' , 'book' , 'trap' , 'fireTrap' , 'collectable', 'herb'}
    if type(typeArray) ~= 'table' then
        return 
    end
    return self:findNearest(self:findByTypeArray(typeArray))
end

function spawnable:negotiate()
end

function spawnable:warcry()
end

function spawnable:sneer()
end

function spawnable:isReady(skill)
end

function spawnable:startTimer()
    if(not self.timerInterval) then
        self.timerInterval = 1;
        run(function()
            while (self.timerInterval) do
                self:wait(self.timerInterval)
                if(self.timerInterval) then
                    local deltaTime
                    local curTime = getTimer()
                    if(self.lastTickTime) then
                        deltaTime =  curTime - self.lastTickTime
                    else
                        deltaTime = self.timerInterval
                    end
                    self.lastTickTime = curTime;
                    self:onTick(deltaTime);
                end
            end
        end)
    end
end

function spawnable:killTimer()
    self.timerInterval = nil
    self.lastTickTime = nil
end

-- virtual function:called per second
function spawnable:onTick(deltaTime)
    if(self.has_torch and self.torchLife) then
        self.torchLife = self.torchLife - deltaTime
        if(self.torchLife <= 0) then
            self.torch:setDead()
            self.torch = nil;
            self.has_torch = false;
            self:killTimer()
        end
    end
end

function spawnable:catchTorch(torch)
    self.has_torch = true
    self.torchLife = torch and torch.duration;
    if(not self.torch) then
        self.torch = game.spawnXY("torchInHand", -1, -1);
        self.torch:attachTo(self);
    end
    if(self.torchLife and self.torchLife>0) then
        self:startTimer()
    end
end



function spawnable:catchHerb(herb)
    if self.has_herb then
        return
    end
    
    self.has_herb = true
    if(not self.herb) then
        self.herb = game.spawnXY("herbInHand", -1, -1)
        self.herb.isOnHand  = true
        self.herb.hp = herb.hp
        self.herb.effectDist = herb.effectDist
        self.herb:attachTo(self)
    end
end


function spawnable:useHerb(target)
    if(type(target) == "string") then
        target = game.getEntity(target);
        if(not target) then
            self:wait()
            return
        end
    end
    if not self:canUseHerb(target) then
        return
    end
    if self:distanceTo(target) <= 5 then
        target:takeDamage(-self.herb.hp, self)
    else
        tip("需要走近一点，才能对目标使用")
        return
    end
    
    
    self.has_herb = false
    self.herb:setDead()
    self.herb = nil
    
    -- todo health increase effect anim
end

function spawnable:canUseHerb(target)
    if not self.has_herb then
        return false
    end

    if not self.herb then
        return false
    end
    
    if self:distanceTo(target) > self.herb.effectDist then
        return false
    end
    
    return true
end


