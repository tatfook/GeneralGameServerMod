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

function Skill:ctor()
    self.__last_activate_time__ = __get_timestamp__();
end

function Skill:Init(opts)
    opts = opts or {};

    self.__entity_config__ = opts.entity_config;

    if (opts.name) then self:SetName(opts.name) end 
    if (opts.targetBlood) then self:SetTargetBlood(opts.targetBlood) end
    if (opts.skillTime) then self:SetSkillTime(opts.skillTime) end
    if (opts.animId) then self:SetAnimId(opts.animId) end 
    if (opts.skillInterval) then self:SetSkillInterval(opts.skillInterval) end 
    if (opts.skillDistance) then self:SetSkillDistance(opts.skillDistance) end 

    return self;
end

function Skill:GetSkilEntity()
    return self.__entity_config__ and CreateEntity(self.__entity_config__);
end

function Skill:Activate(source_entity, target_entity)
    local cur_time = __get_timestamp__();
    local interval = cur_time - self.__last_activate_time__;
    if (interval < self:GetSkillInterval()) then return end 

    self.__last_activate_time__ = cur_time;

    if (target_entity) then
        target_entity:IncrementBlood(-self:GetTargetBlood());
    end
    
    __run__(function()
        local skill_entity = self:GetSkilEntity() or source_entity;
        if (skill_entity ~= source_entity) then
            skill_entity:SetPosition(source_entity:GetPosition());
            skill_entity:SetFacing(source_entity:GetFacing());
        end
        -- 设置方向
        if (self:GetSkillFacing()) then skill_entity:SetFacing(self:GetSkillFacing()) end
        -- 设置动画ID
        local animId = self:GetAnimId();
        if (animId and animId ~= 0) then skill_entity:SetAnimId(animId) end
        -- 停顿动画时间
        local skillTime = self:GetSkillTime();
        if (skillTime and skillTime > 0) then sleep(skillTime) end
        -- 移动位置
        local skillDistance = self:GetSkillDistance();
        if (skillDistance and skillDistance > 0) then skill_entity:MoveForward(skillDistance) end 
        if (animId and animId ~= 0) then skill_entity:SetAnimId(0) end
        
        if (skill_entity ~= source_entity) then
            skill_entity:Destroy();
        end
    end);
    
    return true;
end

