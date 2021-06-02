
--[[
Title: Entity
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Entity = NPL.load("Mod/GeneralGameServerMod/GI/Game/Emoji/Entity.lua");
------------------------------------------------------------
]]


local SubEntity = NPL.load("./SubEntity.lua");

local Entity = commonlib.inherit(nil, NPL.export());
function Entity:ctor()
  self.mSubEntities={};
end

function Entity:delete()
  for _,sub in pairs(self.mSubEntities) do
    sub:delete();
  end
  self.mSubEntities=nil;
end

function Entity:setEmoji(texturePath,frameInterval,maxAnimationInterval,minAnimationInterval,materialIndex)
  if not texturePath then
    if self.mSubEntities[materialIndex] then
      self.mSubEntities[materialIndex]:delete()
      self.mSubEntities[materialIndex] = nil
    end
  else
    self.mSubEntities[materialIndex] = self.mSubEntities[materialIndex] or SubEntity:new({mEntity = self,mMaterialIndex = materialIndex})
    self.mSubEntities[materialIndex]:setEmoji(texturePath,frameInterval,maxAnimationInterval,minAnimationInterval)
  end
end

function Entity:update(deltaTime)
  for _,sub in pairs(self.mSubEntities) do
    sub:update(deltaTime)
  end
end