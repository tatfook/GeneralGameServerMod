
--[[
Title: Emoji
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Emoji = NPL.load("Mod/GeneralGameServerMod/GI/Game/Emoji/Emoji.lua");
------------------------------------------------------------
]]

local Entity = NPL.load("./Entity.lua");

local Emoji = commonlib.inherit(nil, NPL.export());
local lInst

function Emoji.singleton()
  if not lInst then
    lInst = Emoji:new()
  end
  return lInst
end

function Emoji:ctor()
  self.mTickTimer=commonlib.Timer:new();
  self.mTickTimer:Tick();
  self.mTimer = commonlib.Timer:new({callbackFunc = function(timer)
        self:update(timer)
      end})
  self.mTimer:Change(0,0)
  self.mEntities = {}
end

function Emoji:delete()
  for _,entity in pairs(self.mEntities) do
    entity:delete()
  end
  self.mEntities=nil
  self.mTickTimer = nil
  self.mTimer:Change()
  self.mTimer = nil
  lInst = nil
end

function Emoji:update(time)
  self.mTickTimer:Tick();
  local delta=self.mTickTimer:GetDelta()*0.001;
  for _,entity in pairs(self.mEntities) do
    entity:update(delta)
  end
end

function Emoji:setEmoji(entity,texturePath,frameInterval,maxAnimationInterval,minAnimationInterval,materialIndex)
  --echo("devilwalk","Emoji:setEmoji:entity,texturePath,materialIndex:" .. tostring(entity) .. "," .. tostring(texturePath) .. "," .. tostring(materialIndex))
  if not texturePath and not materialIndex then
    local emoji_entity_index = self:_getEntityIndex(entity)
    if emoji_entity_index then
      self.mEntities[emoji_entity_index]:delete()
      table.remove(self.mEntities,emoji_entity_index)
    end
  else
    materialIndex = materialIndex or 3
    local emoji_entity = self:getEntity(entity)
    if not emoji_entity then
      emoji_entity = Entity:new({mEntity = entity,mManager = self})
      self.mEntities[#self.mEntities+1] = emoji_entity
    end
    emoji_entity:setEmoji(texturePath,frameInterval,maxAnimationInterval,minAnimationInterval,materialIndex)
    if not next(emoji_entity.mSubEntities) then
      local emoji_entity_index = self:_getEntityIndex(entity)
      self.mEntities[emoji_entity_index]:delete()
      table.remove(self.mEntities,emoji_entity_index)
    end
  end
  --[[echo("devilwalk","Emoji:setEmoji:self.mEntities:begin")
  for _,e in pairs(self.mEntities) do
    echo("devilwalk",type(e.mEntity))
    echo("devilwalk",tostring(e.mEntity))
  end
  echo("devilwalk","Emoji:setEmoji:self.mEntities:end")]]
end

function Emoji:getEntity(entity)
  if self.mEntities then
    return self.mEntities[self:_getEntityIndex(entity)]
  end
end

function Emoji:_getEntityIndex(entity)
  if self.mEntities then
    for ret,test in pairs(self.mEntities) do
      if test.mEntity==entity then
        return ret
      end
    end
  end
end