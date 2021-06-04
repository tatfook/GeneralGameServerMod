local EntityController = NPL.export();
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local AnimationController = NPL.load("script/Truck/Game/Input/AnimationController.lua");
NPL.load("(gl)script/Truck/Game/UI/UIManager.lua");
local UIManager= commonlib.gettable("Mod.Truck.Game.UI.UIManager");

local current = nil;
local move_angle = nil;
local State;
State = {
    enter = function ()end,
    leave = function ()end,
    input = function ()end,
    new = function (self, name)
        local o = {name = name};
        setmetatable(o, {__index = State});
        return o;
    end
};
local FSM;
FSM = {
    curState = nil,
    createState = function (self, name)
        local state = State:new(name);
        self.states[name] = state;
        return state;
    end,
    input = function (self, ...)
        local next =  self.curState:input(...);
        if next and self.states[next] then 
            local s = self.states[next];
            self.curState:leave(s.name, ...);
            s:enter(self.curState.name, ...);
            self.curState = s;
        else
            
        end
    end,
    new  = function (self)
        local o = {states = {}}
        setmetatable(o, {__index = FSM});
        return o
    end,
    clear = function (self)
        self.states = {}
    end
};


local fsm = FSM:new();
local isKeyboardEnabled = true;

local isKeyDown = function (...)
    return isKeyboardEnabled and ParaUI.IsKeyPressed(...)
end 

local isFalling = function ()
    local obj = current:GetInnerObject()
    if not obj then return false end;
    local vs = obj:GetField("VerticalSpeed", -10);
    return vs <= -1 ; -- it will be -0.x when climbing
end

local isInWater = function (entity)
    local function isWater(x,y,z)
        local block = BlockEngine:GetBlock(x, y, z);
        if(block and block.material:isLiquid()) then
            return true;
        end
    end

    local x, y, z = entity:GetBlockPos()
    return  isWater(x,y + 1, z);
end

local playAnim = function (id, update, extend, upper)
    AnimationController.play(id,update, extend, upper);
end

local move = function (checkonly, next)
    local obj = current:GetInnerObject();
    if not obj then 
        return 
    end
    local char = obj:ToCharacter();
    local attr = ParaCamera.GetAttributeObject();
    if attr:GetField("BlockInput", true) then
        local stop = false;
        local facing = obj:GetFacing();
        if isKeyDown(DIK_SCANCODE.DIK_A) or isKeyDown(DIK_SCANCODE.DIK_LEFT) then 
            facing = -math.pi/2
            stop = true
        elseif isKeyDown(DIK_SCANCODE.DIK_D ) or isKeyDown(DIK_SCANCODE.DIK_RIGHT)then
            facing = math.pi/2
            stop = true
        elseif isKeyDown(DIK_SCANCODE.DIK_W) or isKeyDown(DIK_SCANCODE.DIK_UP) then 
            facing = 0;
            stop = true
        elseif isKeyDown(DIK_SCANCODE.DIK_S) or isKeyDown(DIK_SCANCODE.DIK_DOWN) then 
            facing = math.pi
            stop = true
        end
        
        if stop and not checkonly then 
            obj:SetFacing(facing)
            char:AddAction(action_table.ActionSymbols.S_WALK_FORWORD, facing);
        end 
        return stop;
    else
        local stop = false;
        if isKeyDown(DIK_SCANCODE.DIK_A) or isKeyDown(DIK_SCANCODE.DIK_LEFT) then 
            if not checkonly then
                char:AddAction(action_table.ActionSymbols.S_WALK_LEFT);
            end
            stop = true;
        elseif isKeyDown(DIK_SCANCODE.DIK_D ) or isKeyDown(DIK_SCANCODE.DIK_RIGHT)then
            if not checkonly then 
                char:AddAction(action_table.ActionSymbols.S_WALK_RIGHT);
            end
            stop = true;
        end

        if isKeyDown(DIK_SCANCODE.DIK_W) or isKeyDown(DIK_SCANCODE.DIK_UP) then 
            if not checkonly then
                if (move_angle) then 
                    char:AddAction(action_table.ActionSymbols.S_WALK_FORWORD,move_angle);
                else -- in c++, it will process move_angle including nil value 
                    char:AddAction(action_table.ActionSymbols.S_WALK_FORWORD);
                end
            end
            return true
        elseif isKeyDown(DIK_SCANCODE.DIK_S) or isKeyDown(DIK_SCANCODE.DIK_DOWN) then 
            if not checkonly then
                char:AddAction(action_table.ActionSymbols.S_WALK_BACKWORD);
            end
            return true;
        end
        return stop;
    end
end

function EntityController.setFocus(e)
    current = e;
    AnimationController.setFocus(e);
    if e then 
        EntityController.init(e);
        local obj = e:GetInnerObject()
        if obj.ToCharacter then 
            local char = obj:ToCharacter();
            char:EnableAutoAnimation(false);
        end
        local attr = ParaCamera.GetAttributeObject();
        attr:SetField("EnableKeyboard", false);
    end
end

function EntityController.getFocus()
    return current;
end

function EntityController.setAngle(ang)
    move_angle = ang;
end

function EntityController.enableKeyboard(enable)
    isKeyboardEnabled = enable
end

function EntityController.go(name, ...)
    if not current then 
        return 
    end

    fsm:input(name, ...)
end

function EntityController.check(name)
    if not current then 
        return 
    end
    return fsm.curState.name == name; 
end

function EntityController.update(deltaTime)
    if not current or not isKeyboardEnabled then 
        return 
    end
    fsm:input();
end

function EntityController.init(entity)
    fsm:clear();
    local obj = entity:GetInnerObject();
    if not obj.ToCharacter then return end;
    local char = obj:ToCharacter();
    
    obj:SetAttribute(0x8000, true) -- skip picking



    local idle = fsm:createState("idle");
    idle.enter = function ()
        if  entity:IsFlying() then 
            entity:ToggleFly(false)
            ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", 0);
        end

        char:Stop();
        playAnim("stand")
    end
    idle.input = function (self, next)
        if next == "die" then 
            return "die"
        elseif isFalling() then -- it will be -0.x when climbing
            return "fall"
        -- elseif isInWater(entity) then  
        --     return "swimidle"
        elseif next == "animate" then 
            return "animate"
        
        elseif move(true,next) then
            return "run";
        elseif next == "jump" then 
            return "jump"
        elseif next == "flyidle" then 
            return "flyidle";
        elseif next == "autorun" then 
            return "autorun";
        end
    end

    local run = fsm:createState("run");
    run.input = function (self, next)
        local stop = true;

        if next == "die" then 
            return "die"
        elseif isFalling() then
            return "fall"
        elseif next == "jump" then 
            return "jump"
        elseif next == "flyidle" then 
            return "flyidle";
        elseif next == "animate" then 
            return "animate"
        elseif not move(false) then 
            return "idle"
        else
            playAnim("run" , true)
        end
    end

    local autorun = fsm:createState("autorun");
    autorun.enter = function (self, pre, cur, facing)
        self.facing = tonumber(facing)
    end
    autorun.input = function (self, next)
        local stop = true;

        if next == "die" then 
            return "die"
        elseif isFalling() then
            return "fall"
        elseif next == "jump" then 
            return "jump"
        elseif next == "flyidle" then 
            return "flyidle";
        elseif next == "animate" then 
            return "animate"
        elseif next == "idle" then 
            return "idle"
        else
            local facing = self.facing or Direction.GetFacingFromCamera();
            obj:SetFacing(facing);
            char:AddAction(action_table.ActionSymbols.S_WALK_FORWORD, facing);
            playAnim("run" , true)
        end
    end

    local jump = fsm:createState("jump")
    jump.enter = function (self)
        char:AddAction(action_table.ActionSymbols.S_JUMP_START, entity.jump_up_speed or GameLogic.options.jump_up_speed);
        playAnim("jump")
        self.skiponeframe = true;
    end
    jump.input = function (self, next)
        local obj = current:GetInnerObject()
        local vs = obj:GetField("VerticalSpeed", -10);

        if vs <= 0.01 and not self.skiponeframe then 
            return "fall"
        elseif next == "die" then 
            return "die"
        end
        self.skiponeframe = false;

        if move() then
            return ;
        end

    end

    local fall = fsm:createState("fall")
    fall.enter = function ()
        playAnim("fall")
    end
    fall.input = function (self,next)
        local speed = obj:GetField("VerticalSpeed", -10);
        if speed >= 0 then 
            return "idle"
        elseif isInWater(entity) then  
            return "swimidle"
        elseif next == "flyidle" then 
            return "flyidle"
        elseif move() then
            return ;
        end        
        
    end

    local flyidle = fsm:createState("flyidle")
    flyidle.enter = function (self, pre)
        if not entity:IsFlying() then 
            entity:ToggleFly(true)
            ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", GameLogic.options.MaxAllowedYShift or 0);
        end
        playAnim("flyidle")
    end
    flyidle.leave = function (self, next)
        if next ~= "fly" and entity:IsFlying() then 
            entity:ToggleFly(false)
            ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", 0);
        end
    end
    flyidle.input = function (self,next)
        if next == "fall" then 
            return "fall"; 
        elseif next == "die" then 
            return "die"            
        elseif isKeyDown(DIK_SCANCODE.DIK_SPACE) then
            char:AddAction(action_table.ActionSymbols.S_JUMP_START, entity.jump_up_speed or GameLogic.options.jump_up_speed);
        elseif move(true) then 
            return "fly"
        end
    end

    local fly = fsm:createState("fly")
    fly.enter = function ()
        if not entity:IsFlying() then 
            entity:ToggleFly(true)
            ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", GameLogic.options.MaxAllowedYShift or 0);
        end
        playAnim("fly")
    end
    fly.leave = function (self, next)
        if next ~= "flyidle" and entity:IsFlying() then 
            entity:ToggleFly(false)
            ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", 0);
        end
    end
    fly.input = function (self,next)
        if next == "fall" then 
            return "fall"; 
        elseif next == "die" then 
            return "die"
        elseif  move() then
            return 
        end
        return "flyidle"
        
    end

    local swimidle = fsm:createState("swimidle")
    swimidle.enter = function (self )
        obj:SetDensity(0);
        obj:SetField("CanFly", true);
        obj:SetField("AlwaysFlying", true);

        ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", GameLogic.options.MaxAllowedYShift or 0);    
        playAnim("swimidle")
    end
    swimidle.leave = function (self)
        obj:SetDensity(GameLogic.options.NormalDensity);
        obj:SetField("CanFly", false);
        obj:SetField("AlwaysFlying", false);

        ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", 0);    
    end
    swimidle.input = function (self,next)
        if not isInWater(entity) then 
            return "fall";
        elseif next == "die" then 
            return "die"            
        elseif next == "flyidle" then 
            return "flyidle";
        elseif  move(true) then 
            return "swim"
        end

    end

    local swim = fsm:createState("swim")
    swim.enter = function (self )
        obj:SetDensity(0);
        obj:SetField("CanFly", true);
        obj:SetField("AlwaysFlying", true);

        ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", GameLogic.options.MaxAllowedYShift or 0);    
        playAnim("swim",true)
    end
    swim.leave = function (self)
        obj:SetDensity(GameLogic.options.NormalDensity);
        obj:SetField("CanFly", false);
        obj:SetField("AlwaysFlying", false);

        ParaCamera.GetAttributeObject():SetField("MaxAllowedYShift", 0);    
    end
    swim.input = function (self, next)
        if not isInWater(entity) then 
            return "fall";
        elseif next == "die" then 
            return "die"            
        elseif next == "flyidle" then 
            return "flyidle";
        elseif  move() then 
            return 
        end

        return "swimidle"
    end

    local die = fsm:createState("die")
    die.enter = function (self)
        playAnim("die");
    end
    die.input = function (self, next)
        if next == "revive" then 
            return "revive"
        end
    end 

    local revive = fsm:createState("revive")
    revive.enter = function (self)
        playAnim("stand")
    end

    revive.input = function ()
        return "idle"
    end

    local animate = fsm:createState("animate")
    animate.enter = function (self,pre,next, id, moveable)
        self.fsm = FSM:new();
        local attack = self.fsm:createState("attack")
        attack.enter = function (self)
            playAnim("attack", nil,nil, true);
        end
        attack.leave = function (self)
            playAnim(nil, nil,nil, true);
        end
        attack.input = function (self, next)
            if next == "reload" then 
                return "reload"
            elseif next == "jump" then
                return "jump"
            elseif move() then
                playAnim("run", true)
            else
                playAnim("stand");
            end
        end 

        local reload = self.fsm:createState("reload")
        reload.enter = function (self)
            playAnim("reload", nil,nil, true);
        end
        reload.leave = function (self)
            playAnim(nil, nil,nil, true);
        end
        reload.input = function (self, next)
            if move() then
                playAnim("run", true)
            else
                playAnim("stand");
            end
        end 

        local cur = self.fsm.states[id];
        if cur then 
            self.fsm.curState = cur;
            cur:enter();
        end
    end
    animate.leave = function (self)
        if self.fsm.curState then
            self.fsm.curState:leave();
        end
    end
    animate.input = function (self, next, ...)
        if next == "die" then 
            return "die"   
        elseif next == "idle" then 
            return "idle"
        elseif self.moveable  then 
            if move() then
                playAnim("run", true)
            else
                playAnim(self.animid,true);
            end
            return ;
        elseif self.fsm.curState then
            return self.fsm:input(next, ...)
        end

    end 

    fsm.curState = idle;
    idle:enter();
end

local timestamp = os.time();
local timer = commonlib.Timer:new({callbackFunc = function ()
    EntityController.update();
end})

timer:Change(1,1)