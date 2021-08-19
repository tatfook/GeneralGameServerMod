--[[
Title: Skill
Author(s):  wxa
Date: 2021-06-01
Desc: 技能
use the lib:
------------------------------------------------------------
local Skill = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Skill.lua");
------------------------------------------------------------
]]

local Skill = inherit(ToolBase, module("Skill"));

Skill:Property("Entity");                   -- 技能拥有者
Skill:Property("Name", "normal");           -- 技能名
Skill:Property("SkillInterval", 1000);      -- 时间间隔  间隔需要大于技能时间
Skill:Property("TargetBlood", 10);          -- 目标消血量
Skill:Property("SkillTime", 500);           -- 技能释放时间
Skill:Property("AnimId", 6);                -- 技能动画ID
Skill:Property("SkillFacing");              -- 技能方向
Skill:Property("SkillDistance");            -- 技能前行距离
Skill:Property("SkillRadius", 1);           -- 技能范围   
Skill:Property("SkillHeight", 3);           -- 技能高度
Skill:Property("MoveToTargetEntity", false, "IsMoveToTargetEntity");  -- 是否移动到目标位置

function Skill:ctor()
    self.__last_activate_time__ = __get_timestamp__();
end

function Skill:Init(opts)
    opts = opts or {};

    self.__entity_config__ = opts.entity_config;
    self.__offset_x__, self.__offset_y__, self.__offset_z__ = opts.offsetX or 0, opts.offsetY or 0, opts.offsetZ or 0;

    if (opts.name) then self:SetName(opts.name) end 
    if (opts.targetBlood) then self:SetTargetBlood(opts.targetBlood) end
    if (opts.skillTime) then self:SetSkillTime(opts.skillTime) end
    if (opts.animId) then self:SetAnimId(opts.animId) end 
    if (opts.skillInterval) then self:SetSkillInterval(opts.skillInterval) end 
    if (opts.skillDistance) then self:SetSkillDistance(opts.skillDistance) end 
    if (opts.skillRadius) then self:SetSkillRadius(opts.skillRadius) end 
    if (opts.moveToTargetEntity) then self:SetMoveToTargetEntity(opts.moveToTargetEntity) end 

    return self;
end

function Skill:GetSkillAABB(source_entity)
    if(self.__aabb__) then
		local x, y, z = source_entity:GetPosition();
		self.__aabb__:SetBottomPosition(x, y, z);
	else
		self.__aabb__ = ShapeAABB:new();
		local x, y, z = source_entity:GetPosition();
		local radius = self:GetSkillRadius();
		local half_height = self:GetSkillHeight() * 0.5;
		self.__aabb__:SetCenterExtend(vector3d:new({x, y + half_height, z}), vector3d:new({radius, half_height, radius}));
	end
	return self.__aabb__;
end

function Skill:GetSkillEntity(source_entity)
    return self.__entity_config__ and CreateEntity(self.__entity_config__) or source_entity;
end

function Skill:GetNextActivateTimeStamp()
    local cur_time = __get_timestamp__();
    local interval = cur_time - self.__last_activate_time__;
    local skill_interval = self:GetSkillInterval();
    return interval < skill_interval and (skill_interval - interval) or 0;
end

function Skill:Activate(source_entity, target_entity)
    local cur_time = __get_timestamp__();
    local interval = cur_time - self.__last_activate_time__;
    if (interval < self:GetSkillInterval()) then return false end 

    self.__last_activate_time__ = cur_time;

    if (target_entity) then
        target_entity:IncrementBlood(-self:GetTargetBlood());
    end

    local skill_entity = self:GetSkillEntity(source_entity);
    local is_skill_source_entity = skill_entity == source_entity;
    local function Activate()
        if (not is_skill_source_entity) then
            local center = source_entity:GetCollisionAABB():GetCenter();
            local dx, dz = source_entity:GetDistanceOffsetXY(source_entity:GetPhysicsRadius());
            skill_entity:SetPosition(center[1] + dx, center[2] + self.__offset_y__, center[3] + dz);
            -- skill_entity:SetPosition(source_entity:GetPosition());
            skill_entity:SetFacing(source_entity:GetFacing());
        end
        -- 设置方向
        if (self:GetSkillFacing()) then skill_entity:SetFacing(self:GetSkillFacing()) end
        -- 设置动画ID
        local animId = self:GetAnimId();
        if (animId and animId ~=0 and source_entity) then source_entity:SetAnimId(animId) end
        -- 停顿动画时间
        local skillTime = self:GetSkillTime();
        if (skillTime and skillTime > 0) then sleep(skillTime) end
        -- 停止
        if (animId and animId ~= 0 and source_entity) then source_entity:SetAnimId(0) end
        
        -- 移动至目标点
        local skillDistance = self:GetSkillDistance();
        if (self:IsMoveToTargetEntity() and target_entity) then
            local tx, ty, tz = target_entity:GetPosition();
            skill_entity:Move(tx, ty, tz);
        elseif (skillDistance and skillDistance > 0) then 
            skill_entity:MoveForward(skillDistance);
        end
        -- 销毁
        if (not is_skill_source_entity) then
            skill_entity:Destroy();
        end
    end

    if (is_skill_source_entity) then
        Activate();
    else
        __run__(Activate);
    end

    return true;
end

