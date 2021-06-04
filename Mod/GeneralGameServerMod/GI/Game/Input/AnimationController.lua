local AnimationController = NPL.export() 
NPL.load("(gl)script/Truck/Config/Config.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local Config = commonlib.gettable("Mod.Truck.Config");
local animConfig = Config.Animations;
local FileCaches = NPL.load("script/Truck/Utility/FileCaches.lua")


local current = nil;
local curStyle = "normal"
local lastAnimation;
local play;

function AnimationController.setFocus(entity)
    current = entity;
    if entity then 
        AnimationController.init(entity);
    else
        play = nil;
        lastAnimation = nil;
    end
end

function AnimationController.play( ...)
    if not current then return end;
    play( ...);    
end

function AnimationController.getCurrentAnimation(upper)
    if not current then 
        return 
    end
    if upper then 
        return current:GetInnerObject():GetField("UpperAnimID", -1);
    else
        return current:GetInnerObject():GetField("AnimID", 0);
    end
end

function AnimationController.setAnimationStyle(style)
    curStyle = style or "normal";
    if current then 
        play(lastAnimation);
    end
end

function AnimationController.init(entity)
    curStyle = "normal"
    local obj = entity:GetInnerObject();
    if not obj.ToCharacter then 
        play = function ()end;
        return 
    end;
    local char = obj:ToCharacter();
    play = function (animname, update, extend, upper)
        lastAnimation = animname
        local style = curStyle or "normal"
        local anim = animConfig[style]:get(1)[animname];
        if not anim then
            anim = animConfig.normal:get(1)[animname];
        end
        anim = tonumber(anim or "-1");
        if anim ~= -1 and not char:HasAnimation(anim)  then 
            LOG.std(nil, "error", "AnimationController", string.format("animation %s ('%s') is not existed",anim, animname));
        end
        if upper then 
            obj:SetField("UpperAnimID", (anim));
        else
            char:PlayAnimation((anim), update or false, extend or false);
        end
    end
end

