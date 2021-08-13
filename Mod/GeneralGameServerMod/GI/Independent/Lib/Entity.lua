--[[
Title: Entity
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Entity = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Entity.lua");
------------------------------------------------------------
]]

local Entity = inherit(__Entity__, module("Entity"));

local __all_block_index_entity__ = {};
local __all_entity__ = {};
local __all_name_entity__ = {};

local MOVE_ANIM_ID = 5;
local STOP_MOVE_ANIM_ID = 0;

Entity:Property("DestroyBeCollided", false, "IsDestroyBeCollided");   -- 被碰撞销毁
Entity:Property("AttackBeCollided", false, "IsAttackBeCollided");     -- 被碰撞攻击
Entity:Property("Biped", false, "IsBiped");                           -- 是否是两栖动物
Entity:Property("GoodsChangeCallBack");                               -- 物品变化回调
Entity:Property("ClickCallBack");                                     -- 物品变化回调
Entity:Property("PositionChangeCallBack");                            -- 位置变化回调
Entity:Property("DestroyCallBack");                                   -- 消失回调
Entity:Property("Code");                                              -- 实体代码
Entity:Property("CodeXmlText");                                       -- 实体代码的XML Text
Entity:Property("MainPlayer", false, "IsMainPlayer");                 -- 是否是主玩家
Entity:Property("Focus", false, "IsFocus");                           -- 是否聚焦
Entity:Property("Speed", 1);                                          -- 移动速度
Entity:Property("CanMotion", true, "IsCanMotion");                    -- 是否可以移动
Entity:Property("HasBloold", true, "IsHasBlood");                     -- 是否有血量
Entity:Property("Blood", 100);                                        -- 血量
Entity:Property("TotalBlood", 100);                                   -- 总血量
Entity:Property("CheckTerrain", true, "IsCheckTerrain");              -- 是否需要检测地形
Entity:Property("VisibleRadius", 1);                                  -- 可视半径
Entity:Property("CanVisible", true, "IsCanVisible");                  -- 是否可见
Entity:Property("CanBeCollided", true, "IsCanBeCollided");            -- 是否可被碰撞
Entity:Property("AutoAttack", false, "IsAutoAttack");                 -- 是否自动攻击
Entity:Property("DefaultSkill");                                      -- 实体默认技能

local NID = 0;
function Entity:ctor()
    NID = NID + 1;
    self.__nid__ = NID;
    self.__key__ = string.format("NPC_%s", self.__nid__);
    self.__name__ = self.__key__;
    self.__scope__ = NewScope();                   -- 响应式变量 
    self.__skills__ = {};                          -- 技能集
    self.__goods__ = {};                           -- 物品集
    self.__types__ = {};                           -- 实体类型   0 -- 实体类型  1 -- 可攻击类型  2  -- 被攻击类型  3 -- 不可攻击类型   4 -- 可以碰撞  5 - 不可以碰撞  6 可以被碰撞  7 不可以被碰撞

    __all_entity__[self.__key__] = self;
    __all_name_entity__[self.__name__] = self;
end

function Entity:Init(opts)
    opts = opts or {};

    opts.name = opts.name or "NPC";
    self:SetName(opts.name);

    if (opts.opacity) then self:SetOpacity(opts.opacity) end
    -- 获取主玩家位置
    local bx, by, bz = GetPlayer():GetBlockPos();
    self:SetBlockPos(opts.bx or bx or 0, opts.by or by or 0, opts.bz or bz or 0);
    self:SetAssetFile(opts.assetfile or "character/CC/02human/actor/actor.x");
    self:CreateInnerObject(self:GetMainAssetPath(), true, 0, 1, self:GetSkin());
	self:RefreshClientModel();
    self:Attach();

    __AddEntity__(self);

    self:SetSkipPicking(false);
    self:SetPhysicsRadius(opts.physicsRadius or 0.5);
    self:SetPhysicsHeight(opts.physicsHeight or 2);
    self:SetBiped(opts.biped);
    self:SetDestroyBeCollided(opts.destroyBeCollided);
    if (opts.checkTerrain == false) then self:SetCheckTerrain(false) end
    if (opts.canVisible == false) then self:SetCanVisible(false) end 
    if (opts.canBeCollided == false) then self:SetCanBeCollided(false) end 
    if (opts.hasBloold == false) then self:SetHasBloold(false) end 
    if (opts.speed) then self:SetSpeed(opts.speed) end
    self:SetVisibleRadius(opts.visibleRadius or 1);
    self:SetAutoAttack(opts.isAutoAttack);
    self:SetDefaultSkill(opts.defaultSkill);
    if (opts.types) then self.__types__ = opts.types end 
    if (opts.goods) then 
        for _, goods_config in pairs(opts.goods) do
            self:AddGoods(CreateGoods(goods_config));
        end
    end

    return self;
end

function Entity:FrameMoveRidding()
end

function Entity:FrameMove()
end

function Entity:GetKey()
    return self.__key__;
end

function Entity:GetEntityByKey(key)
    return __all_entity__[key];
end

function Entity:SetName(name) 
    if (self.__name__) then __all_name_entity__[self.__name__] = nil end

    self.__name__ = name;
    self.__scope__:Set("username", name);

    if (self.__name__) then __all_name_entity__[self.__name__] = self end
end

function Entity:GetName() 
    return self.__name__;
end

function Entity:GetEntityByName(name)
    return __all_name_entity__[name];
end

function Entity:SetAssetFile(assetfile)
    if (assetfile and string.match(assetfile, "^@")) then
        assetfile = string.gsub(assetfile, "@", GetWorldDirectory());
        assetfile = ToCanonicalFilePath(assetfile);
    end
    self:SetMainAssetPath(assetfile);
    self:RefreshClientModel();
end

function Entity:SetPosition(x, y, z)
    Entity._super.SetPosition(self, x, y, z);
    self:UpdatePosition();
end

function Entity:SetBlockPos(bx, by, bz)
    Entity._super.SetBlockPos(self, bx, by, bz);
    self:UpdatePosition();
end

function Entity:SetBlockPosition(pos)
    local x, y, z = string.match(pos, "(%d+)[,%s]+(%d+)[,%s]+(%d+)");
    if (not x or not y or not z) then return end
    local bx, by, bz = tonumber(x), tonumber(y), tonumber(z);
    self:SetBlockPos(bx, by, bz);
end


function Entity:GetBlockIndex()
    local bx, by, bz = self:GetBlockPos();
    return ConvertToBlockIndex(bx, by, bz);
end

function Entity:OnPositionChange()
    local callback = self:GetPositionChangeCallBack();
    if (type(callback) == "function") then callback() end
end

function Entity:UpdatePosition()
    if (self:IsFocus()) then SetCameraLookAtPos(self:GetPosition()) end
    self:OnPositionChange();

    local new_block_index = self:GetBlockIndex();
    local old_block_index = self.__block_index__;
    if (old_block_index and __all_block_index_entity__[old_block_index]) then
        __all_block_index_entity__[old_block_index][self] = nil;
        if (not next(__all_block_index_entity__[old_block_index])) then __all_block_index_entity__[old_block_index] = nil end
    end
    __all_block_index_entity__[new_block_index] = __all_block_index_entity__[new_block_index] or {};
    __all_block_index_entity__[new_block_index][self] = self;

    -- 不精准碰撞
    if (old_block_index == new_block_index) then return end 
    self.__block_index__ = new_block_index;
    self:CheckEntityCollision();
    self:CheckEntityVisible();
end

function Entity:GetTickCountPerSecond()
    return __get_loop_tick_count__() * self:GetSpeed(); -- 可以乘以倍数
end

function Entity:GetStepDistance()
    return 0.06 * self:GetSpeed();                      -- 获取步长
end

function Entity:IsStandInPosition(x, y, z)
    if (not self:IsCheckTerrain()) then return true end 
    
    local bx, by, bz = ConvertToBlockPosition(x, y + 0.1, z);
    local cur_bx, cur_by, cur_bz = self:GetBlockPos();
    if (bx == cur_bx and by == cur_by and bz == cur_bz) then return true end 

    local block = GetBlock(bx, by, bz);
    -- 存在方块档
    if (block and block.obstruction) then return false end 
    block = GetBlock(bx, by - 1, bz);
    -- 下方无实心方块
    if (not block or not block.obstruction) then return false end 
    return true;
end

function Entity:IsStandInBlockPosition(bx, by, bz)
    return self:IsStandInPosition(ConvertToRealPosition(bx, by, bz));
end 

function Entity:GetDistanceOffsetXY(distance)
    local facing = self:GetFacing();
    return math.cos(facing) * distance, -math.sin(facing) * distance;
end

-- 向前行走, duration 存在则通过时间计算步数, 否则通过单位步长计算步数
function Entity:MoveForward(dist, duration, bEnableAnim)
    if (not self:IsCanMotion()) then return end 

    local facing = self:GetFacing();
    local distance = (dist or 1) * __BlockSize__;
    local dx, dy, dz = math.cos(facing) * distance, 0, -math.sin(facing) * distance;
    local x, y, z = self:GetPosition();
    local stepCount = duration and math.ceil(duration * self:GetTickCountPerSecond()) or math.floor(distance / self:GetStepDistance());
    bEnableAnim = if_else(bEnableAnim == nil or bEnableAnim, true, false);
    if (bEnableAnim) then self:SetAnimId(5) end
    while(stepCount > 0) do
        if (self:IsDestory()) then return end 
        local stepX, stepY, stepZ = dx / stepCount, dy / stepCount, dz / stepCount;
        x, y, z = x + stepX, y + stepY, z + stepZ;
        if (self:IsStandInPosition(x, y, z)) then
            self:SetPosition(x, y, z);
        else 
            stepCount = 1;   -- 停止前进
        end
        stepCount = stepCount - 1;
        dx, dy, dz = dx - stepX, dy - stepY, dz - stepZ;
        if (self:IsCanMotion()) then
            sleep();
        else
            break;
        end
    end
    
    if (bEnableAnim) then self:SetAnimId(0) end
end

-- 像目标移动
function Entity:MoveEntity(entity)
    self:TurnEntity(entity);
    self:MoveForward(self:GetStepDistance());
end

-- 深度优先智能寻路
function Entity:GetDepthSearchPaths(tbx, tby, tbz)
    local paths = {};
    local bx, by, bz = self:GetBlockPos();
    local function DepthSearch(bx, by, bz)
        if (bx == tbx and bz == tbz) then return true end 
        local dx,  dz = tbx > bx and 1 or (tbx == bx and 0 or -1), tbz > bz and 1 or (tbz == bz and 0 or -1);
        
        local _bx, _by, _bz = bx + dx, by, bz + dz;
        if (dx ~= 0 and dz ~= 0 and self:IsStandInBlockPosition(_bx, _by, _bz)) then
            if (DepthSearch(_bx, _by, _bz)) then 
                paths[#paths + 1] = ConvertToBlockIndex(_bx, _by, _bz);
                return true;
            end
        end

        _bx, _by, _bz = bx, by, bz + dz;
        if (dz ~= 0 and self:IsStandInBlockPosition(_bx, _by, _bz)) then
            if (DepthSearch(_bx, _by, _bz)) then 
                paths[#paths + 1] = ConvertToBlockIndex(_bx, _by, _bz);
                return true;
            end
        end

        _bx, _by, _bz = bx + dx, by, bz;
        if (dx ~= 0 and self:IsStandInBlockPosition(_bx, _by, _bz)) then
            if (DepthSearch(_bx, _by, _bz)) then 
                paths[#paths + 1] = ConvertToBlockIndex(_bx, _by, _bz);
                return true;
            end
        end

        -- 回退
        _bx, _by, _bz = bx, by, bz - dz;
        if (dz ~= 0 and self:IsStandInBlockPosition(_bx, _by, _bz)) then
            if (DepthSearch(_bx, _by, _bz)) then 
                paths[#paths + 1] = ConvertToBlockIndex(_bx, _by, _bz);
                return true;
            end
        end

        _bx, _by, _bz = bx - dx, by, bz;
        if (dx ~= 0 and self:IsStandInBlockPosition(_bx, _by, _bz)) then
            if (DepthSearch(_bx, _by, _bz)) then 
                paths[#paths + 1] = ConvertToBlockIndex(_bx, _by, _bz);
                return true;
            end
        end

        return false;
    end

    if (DepthSearch(bx, by, bz)) then
        local size = #paths;
        for i = 1, math.floor(size / 2) do
            paths[i], paths[size - i + 1] = paths[size - i + 1], paths[i];
        end
        return paths;
    end
    -- 简化寻路方式
  
    return paths;    
end

-- 贪心模式路径
function Entity:GetGreedyPaths(tbx, tby, tbz)
    local paths = {};
    local bx, by, bz = self:GetBlockPos();
    -- paths[#paths + 1] = ConvertToBlockIndex(bx, by, bz);
    while(true) do
        -- if (bx == tbx and by == tby and bz == tbz) then break end 
        if (bx == tbx and bz == tbz) then break end 
        local dx, dy, dz = tbx > bx and 1 or (tbx == bx and 0 or -1), 0, tbz > bz and 1 or (tbz == bz and 0 or -1);
        if (self:IsStandInBlockPosition(bx + dx, by, bz + dz)) then
            bx, by, bz = bx + dx, by, bz + dz;
            paths[#paths + 1] = ConvertToBlockIndex(bx, by, bz);
        elseif (dx ~= 0 and self:IsStandInBlockPosition(bx + dx, by, bz)) then
            bx, by, bz = bx + dx, by, bz;
            paths[#paths + 1] = ConvertToBlockIndex(bx, by, bz);
        elseif (dz ~= 0 and self:IsStandInBlockPosition(bx, by, bz + dz)) then
            bx, by, bz = bx, by, bz + dz;
            paths[#paths + 1] = ConvertToBlockIndex(bx, by, bz);
        else 
            break;
        end
    end
    return paths;
end

function Entity:MoveXYZ(bx, by, bz, bEnableAnim, bEnableDepthSearch)
    local paths = bEnableDepthSearch and self:GetDepthSearchPaths(bx, by, bz) or self:GetGreedyPaths(bx, by, bz);
    self:SetAnimId(5);
    bEnableAnim = if_else(bEnableAnim == nil or bEnableAnim, true, false);
    if (bEnableAnim) then self:SetAnimId(5) end
    for _, blockIndex in ipairs(paths) do
        local x, y, z = ConvertToRealPosition(ConvertToBlockPositionFromBlockIndex(blockIndex));
        self:Move(x, y, z);
    end
    if (bEnableAnim) then self:SetAnimId(0) end
end

function Entity:Move(tx, ty, tz, bEnableAnim)
    if (not self:IsCanMotion()) then return end 
    bEnableAnim = if_else(bEnableAnim == nil or bEnableAnim, true, false);
    if (bEnableAnim) then self:SetAnimId(5) end
    while (true) do
        local x, y, z = self:GetPosition();
        local dx, dy, dz = math.abs(tx - x), math.abs(ty - y), math.abs(tz - z);
        -- local max = math.max(math.max(dx, dy), dz);
        -- 不考虑垂直方向 sy == 0 
        local max = math.max(math.max(dx, 0), dz);
        local stepDistance = self:GetStepDistance(); 
        local stepCount = math.ceil(max / stepDistance);
        local sx, sy, sz = (tx - x) / stepCount, (ty - y) / stepCount, (tz - z) / stepCount;
        if (stepCount == 1) then
            x, y, z = tx, ty, tz;
        else
            x, y, z = x + sx, y + sy, z + sz;
        end
        self:SetFacing(GetFacingFromOffset(sx, sy, sz));
        if (self:IsStandInPosition(x, y, z)) then
            self:SetPosition(x, y, z);
        elseif (math.abs(sx) >= stepDistance and self:IsStandInPosition(x - sx, y, z)) then
            self:SetPosition(x - sz, y, z);
        elseif (math.abs(sz) >= stepDistance and self:IsStandInPosition(x, y, z - sz)) then
            self:SetPosition(x, y, z - sz);
        else
            break;  -- 无路可走
        end
        if (self:IsCanMotion()) then sleep() end  
        if (not self:IsCanMotion() or stepCount <= 1) then break end 
    end
    if (bEnableAnim) then self:SetAnimId(0) end
end

function Entity:Stop()
    self:SetCanMotion(false);
end

function Entity:IsDestory()
    return self.__is_destory__;
end

function Entity:Destroy()
    if (self.__is_destory__) then return end
    self.__is_destory__ = true;

    local callback = self:GetDestroyCallBack();
    if (type(callback) == "function") then callback() end

    self:CloseHeadOnDisplay();

    __all_entity__[self.__key__] = nil;
    if (self.__name__) then __all_name_entity__[self.__name__] = nil end

    Entity._super.Destroy(self);

    if (self.__block_index__ and __all_block_index_entity__[self.__block_index__]) then
        __all_block_index_entity__[self.__block_index__][self] = nil;
        if (not next(__all_block_index_entity__[self.__block_index__])) then __all_block_index_entity__[self.__block_index__] = nil end
    end

    for _, goods in pairs(self.__goods__) do goods:Destroy() end 

    __RemoveEntity__(self);
end

function Entity:SetAnimId(animId)
    if (not self:GetInnerObject()) then return end
    self:GetInnerObject():SetField("AnimID", animId or 0);
end

function Entity:Turn(degree)
    self:SetFacingDelta(degree * math.pi / 180);
end

function Entity:TurnEntity(entity)
    local tx, ty, tz = entity:GetPosition();
    local x, y, z = self:GetPosition();
    self:SetFacing(GetFacingFromOffset(tx - x, ty - y, tz - z));
end

function Entity:TurnLeft(degree)
    return self:Turn(-degree);
end

function Entity:TurnRight(degree)
    return self:Turn(degree);
end

function Entity:TurnTo(degree)
    self:SetFacing(mathlib.ToStandardAngle(degree * math.pi / 180));
end

function Entity:GetGoodsByName(name)
    if (type(name) == "table") then return name end
    for _, goods in pairs(self.__goods__) do
        if (goods:GetGoodsName() == name) then return goods end 
    end
end

function Entity:AddGoods(goods)
    -- 从全局物品中取
    local gsid = goods:GetGoodsID();
    if (self.__goods__[gsid] and goods:IsCanStack()) then
        goods:SetStackCount(self.__goods__[gsid]:GetStackCount() + goods:GetStackCount());
    end 
    self.__goods__[gsid] = goods;
    self:OnGoodsChange();
end

function Entity:RemoveGoods(goods)
    self.__goods__[goods:GetGoodsID()] = nil;
    self:OnGoodsChange();
end

function Entity:HasGoods(goods)
    local gsid = type(goods) == "string" and goods or goods:GetGoodsID();
    return self.__goods__[gsid] ~= nil;
end

function Entity:OnGoodsChange()
    local callback = self:GetGoodsChangeCallBack();
    if (type(callback) == "function") then
        callback();
    end
end

function Entity:GetAllGoods()
    return self.__goods__;
end

local __temp_goods_list__ = {};
function Entity:GetGoodsList()
    local size = #__temp_goods_list__;
    for i = 1, size do __temp_goods_list__[i] = nil end
    local index = 0;
    for _, goods in pairs(self.__goods__) do
        index = index + 1;
        __temp_goods_list__[index] = goods;
    end
    return __temp_goods_list__;
end

function Entity:GetAllEntity()
    return __all_entity__;
end

function Entity:CanCollideWith(entity)
    return self:IsBiped();
end

function Entity:CanBeCollidedWith(entity)
    return true;
end

function Entity:CheckEntityCollision()
    if (not self:IsBiped()) then return end 

    local aabb = self:GetCollisionAABB();
    for _, entity in ipairs(__GetEntityList__()) do
        local entity_aabb = entity:GetCollisionAABB();
        if (aabb and entity_aabb and entity ~= self and self:IsCanBeCollided() and entity:IsCanBeCollided() and aabb:Intersect(entity_aabb)) then
            -- 主动碰撞
            if (self:CanCollideWith(entity)) then
                self:CollideWithEntity(entity);
            end
            -- 被碰撞
            if (entity:CanBeCollidedWith(self)) then
                entity:BeCollidedWithEntity(self);
            end
        end
    end
end

function Entity:OnCollidedWithEntity(entity)
    for _, goods in ipairs(self:GetGoodsList()) do
        goods:Activate(self, entity);
    end

    if (self:IsDestroyBeCollided()) then
        self:Destroy();
    end
end

function Entity:BeCollidedWithEntity(entity)
    self:OnCollidedWithEntity(entity);
end

function Entity:CollideWithEntity(entity)
    self:OnCollidedWithEntity(entity);
end

function Entity:DistanceTo(tbx, tby, tbz)
    local bx, by, bz = self:GetBlockPos();
    local dx, dy, dz = math.abs(tbx - bx), math.abs(tby - by), math.abs(tbz - bz);
    return math.max(math.max(dx, dy), dz);
end

function Entity:DistanceToEntity(entity)
    local tbx, tby, tbz = entity:GetBlockPos();
    return self:DistanceTo(tbx, tby, tbz);
end

function Entity:IsVisibleEntity(entity)
    return self:DistanceToEntity(entity) <= self:GetVisibleRadius();
end

function Entity:CheckEntityVisible()
    if (not self:IsBiped()) then return end 
    for _, entity in ipairs(__GetEntityList__()) do
        if (self ~= entity) then
            if (self:IsVisibleEntity(entity)) then
                self:VisibleWithEntity(entity);
                entity:BeVisibledWithEntity(self);
            end

            if (entity:IsVisibleEntity(self)) then
                entity:VisibleWithEntity(self);
                self:BeVisibledWithEntity(entity);
            end
        end
    end
end

function Entity:IsInnerAttackRangeEntity(entity)
    if (not self:GetSkill()) then return end
    local skillAABB = self:GetSkill():GetSkillAABB(self);
    local entityAABB = entity:GetCollisionAABB();
    return skillAABB:Intersect(entityAABB);
end

function Entity:AutoAttackEntity(entity)
    self:SetCanVisible(false);
    while (not entity:IsDestory() and self:IsVisibleEntity(entity)) do
        if (self:IsInnerAttackRangeEntity(entity)) then
            self:SetAnimId(0);
            sleep(self:GetSkill():GetNextActivateTimeStamp());
            self:Attack(entity);
        else 
            local paths = self:GetGreedyPaths(entity:GetBlockPos());
            -- 无路可走退出
            if (#paths == 0) then break end
            local bx, by, bz = ConvertToBlockPositionFromBlockIndex(paths[1]);
            local x, y, z = ConvertToRealPosition(bx, by, bz);
            self:SetAnimId(MOVE_ANIM_ID);
            self:Move(x, y, z, false);
        end
    end
    self:SetAnimId(0);
    self:SetCanVisible(true);
end

function Entity:VisibleWithEntity(entity)
    if (not self:IsCanVisible()) then return end
    if (self:IsAutoAttack() and self:GetSkill() and self:IsAttackEntity(entity)) then
        __run__(function() self:AutoAttackEntity(entity) end);
    end
end

function Entity:BeVisibledWithEntity(entity)
end

function Entity:SetCurrentBlood(blood)
    if (not self:IsHasBlood()) then return end
    self:SetBlood(blood);
    self.__scope__:Set("blood_strip_percentage", self:GetBlood() * 100 / self:GetTotalBlood());
    if (blood < 100 and blood > 0) then self:ShowHeadOnDisplay() end 
    if (blood <= 0) then self:Destroy() end 
end

function Entity:GetCurrentBlood()
    return self:GetBlood();
end

function Entity:IncrementBlood(blood)
    self:SetCurrentBlood(self:GetBlood() + blood);
end

function Entity:IsShowHeadOnDisplay()
    return self.__head_on_displayer_ui__ ~= nil;
end

function Entity:ShowHeadOnDisplay(G, params)
    if (self.__head_on_displayer_ui__) then self.__head_on_displayer_ui__:CloseWindow() end

    G = G or {};
    G.GlobalScope = self.__scope__;

    params = params or {};
    params.__is_3d_ui__ = true;
    params.__3d_object__ = self:GetInnerObject();
    params.__offset_y__ = params.__offset_y__ or 2.8;
    params.__offset_z__ = params.__offset_z__ or 0.05;
    params.__facing__ = 0;
    params.width = params.width or 160;
    params.height = params.height or 100;
    params.x = params.x or (-params.width / 2);
    params.parent = GetRootUIObject();
    params.template = params.template or [[
<template style="width: 100%; height: 100%;">
    <div style="color:#ffffff; font-size: 20px; text-align: center;">{{username}}</div>
    <div style="display: flex; justify-content: center; margin-top: 10px;"><progress style="background-color: #FF0000; height: 8px;" color="#00FF00" v-bind:percentage=blood_strip_percentage></progress></div>
</template>
    ]]
    self.__scope__:Set("username", self:GetName());
    self.__scope__:Set("blood_strip_percentage", self:GetBlood() * 100 / self:GetTotalBlood());
    self.__head_on_displayer_ui__ = ShowWindow(G, params);

    return self.__head_on_displayer_ui__;
end

function Entity:CloseHeadOnDisplay()
    if (self.__head_on_displayer_ui__) then self.__head_on_displayer_ui__:CloseWindow() end
end

function Entity:OnClick()
    local callback = self:GetClickCallBack();
    if (type(callback) == "function") then callback() end
end

function Entity:Build(blockId, blockData)
    local x, y, z = self:GetBlockPos();
    local facing = self:getFacing() / 180 * math.pi;
    x = x + math.floor(math.cos(facing)+0.5);
    z = z - math.floor(math.sin(facing)+0.5);
    
    SetBlock(x, y - 1, z, blockId, blockData);
end

function Entity:AddSkill(skill)
    self.__skills__[skill:GetName()] = skill;
end

function Entity:GetSkill(skillName)
    return skillName and self.__skills__[skillName] or self:GetDefaultSkill();
end

function Entity:SetTypeValue(typ, val)
    self.__types__[typ] = val;
end

function Entity:GetTypes()
    return self.__types__;
end

function Entity:IsAttackedEntity(entity)
    for type_name, type_value in pairs(entity:GetTypes()) do
        if (type_value == 0 and self.__types__[type_name]  == 2) then return true end
    end
    return false;
end

function Entity:IsAttackEntity(entity)
    for type_name, type_value in pairs(entity:GetTypes()) do
        if (type_value == 0 and self.__types__[type_name] == 1) then return true end
    end
    return false;
end

function Entity:Attack(target_entity, skillName)
    if (target_entity) then
        self:TurnEntity(target_entity);
    end

    local skill = self:GetSkill(skillName);
    if (not skill) then return end 
    skill:Activate(self, target_entity);

    if (target_entity) then
        target_entity:Attacked(self);
    end
end

-- 被攻击
function Entity:Attacked(target_entity)
end

local __api_list__ = {
    "SetName",
    "SetPosition",
    "SetBlockPosition",
    "SetAssetFile",
    "SetPhysicsRadius",
    "SetPhysicsHeight",
    "SetAnimId",
    "MoveForward",
    "Turn",
    "TurnLeft",
    "TurnRight",
    "TurnTo",
    "AddGoods",
    "RemoveGoods",
    "HasGoods",
    "SetGoodsChangeCallBack",
    "SetFocus",
    "SetBiped",
    "TurnEntity",
    "Build",
};

function Entity:Run(func, G)
    -- 构建全局环境
    G = G or {};

    for _, funcname in ipairs(__api_list__) do
        G[funcname] = function(...) return (self[funcname])(self, ...) end
    end

    setmetatable(G, {__index = _G});

    -- 设置代码环境
    setfenv(func, G);

    -- 并行执行
    run(func);
end

function Entity:RunCode(code, G)
    local code_func, errormsg = loadstring(code, "loadstring:RunCode");
    if (errmsg) then return warn("invalid code", code) end
    return self:Run(code_func, G);
end

-- blockly api
for _, funcname in ipairs(__api_list__) do
    _G["Entity" .. funcname] = function(name, ...)
        local entity = Entity:GetEntityByName(name);
        return entity and (entity[funcname])(entity, ...);
    end
end
