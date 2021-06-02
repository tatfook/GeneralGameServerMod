--[[
Title: SubEntity
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local SubEntity = NPL.load("Mod/GeneralGameServerMod/GI/Game/Emoji/SubEntity.lua");
------------------------------------------------------------
]]

local TextureAnimation = NPL.load("./TextureAnimation.lua")

local SubEntity = commonlib.inherit(nil, NPL.export());
function SubEntity:ctor()
  self.mTextures={}
end

function SubEntity:delete()
  if self.mAnimation then
    self.mAnimation:delete()
    self.mAnimation=nil;
  end
  if self.mEntity and self.mEntity.mEntity and self.mEntity.mEntity:GetInnerObject() then
    self.mEntity.mEntity:GetInnerObject():SetReplaceableTexture(self.mMaterialIndex,self.mEntity.mEntity:GetInnerObject():GetDefaultReplaceableTexture(self.mMaterialIndex))
  end
  self.mMaterialIndex = nil
  self.mEntity = nil
end

function SubEntity:setEmoji(texturePath,frameInterval,maxAnimationInterval,minAnimationInterval)
  if texturePath~=self.mTexturePath then
    self.mTextures={};
    if self.mAnimation then
      self.mAnimation:delete();
      self.mAnimation=nil;
    end
    self.mTexturePath = texturePath
    local texture_pathes={texturePath};
    local _,pos=string.find(self.mTexturePath,"_emoji");
    if pos and tonumber(string.sub(self.mTexturePath,pos+1,pos+1)) and tonumber(string.sub(self.mTexturePath,pos+2,pos+2)) and tonumber(string.sub(self.mTexturePath,pos+3,pos+3)) and string.sub(self.mTexturePath,pos+4,pos+4)=="." then
      local num1=tonumber(string.sub(self.mTexturePath,pos+1,pos+1));
      local num2=tonumber(string.sub(self.mTexturePath,pos+2,pos+2));
      local num3=tonumber(string.sub(self.mTexturePath,pos+3,pos+3));
      local num=num1*100+num2*10+num3;
      local file_name_head=string.sub(self.mTexturePath,1,pos);
      local file_ext=string.sub(self.mTexturePath,pos+4);
      texture_pathes={}
      for i=1,num do
        if i<10 then
          texture_pathes[#texture_pathes+1]=file_name_head.."00"..tostring(i)..file_ext;
        elseif i<100 then
          texture_pathes[#texture_pathes+1]=file_name_head.."0"..tostring(i)..file_ext;
        else
          texture_pathes[#texture_pathes+1]=file_name_head..tostring(i)..file_ext;
        end
      end
    end
    for _,texture_path in pairs(texture_pathes) do
      local tex=ParaAsset.LoadTexture("",texture_path,1);
      tex:EnableTextureAutoAnimation(false);
      self.mTextures[#self.mTextures+1]=tex;
    end
    self.mEntity.mEntity:GetInnerObject():SetReplaceableTexture(self.mMaterialIndex,self.mTextures[1])
  end
  if #self.mTextures>1 then
    self.mFrameInterval=frameInterval;
    self.mMaxAnimationInterval=maxAnimationInterval;
    self.mMinAnimationInternal=minAnimationInterval;
    self.mLastAnimationTime=0;
    self.mAnimationInterval=self.mMinAnimationInternal+math.random()*(self.mMaxAnimationInterval-self.mMinAnimationInternal);
  end
end

function SubEntity:update(deltaTime)
  if self.mAnimation then
    self.mAnimation:update(deltaTime);
    if not self.mAnimation.mInnerObject then
      self.mAnimation:delete();
      self.mAnimation=nil;
      self.mLastAnimationTime=0;
      self.mAnimationInterval=self.mMinAnimationInternal+math.random()*(self.mMaxAnimationInterval-self.mMinAnimationInternal);
    end
  end
  if #self.mTextures>1 and not self.mAnimation then
    local time=self.mLastAnimationTime+deltaTime;
    if self.mAnimationInterval<=time then  
      self.mAnimation=TextureAnimation:new({mTextures=self.mTextures,mInnerObject=self.mEntity.mEntity:GetInnerObject(),mInterval=self.mFrameInterval,mMaterialIndex=self.mMaterialIndex});
    end
    self.mLastAnimationTime=time;
  end
end