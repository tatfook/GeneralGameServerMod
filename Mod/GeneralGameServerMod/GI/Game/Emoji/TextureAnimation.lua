--[[
Title: TextureAnimation
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local TextureAnimation = NPL.load("Mod/GeneralGameServerMod/GI/Game/Emoji/TextureAnimation.lua");
------------------------------------------------------------
]]

local TextureAnimation=commonlib.inherit(nil, NPL.export());

function TextureAnimation:ctor()
  self.mAnimationCurrentFrameIndex=0;
  self.mLastAnimationFrameTime=0;
end

function TextureAnimation:delete()
  if self.mInnerObject then
    self.mInnerObject:SetReplaceableTexture(self.mMaterialIndex,self.mTextures[1]);
    self.mInnerObject=nil;
  end
  self.mTextures=nil;
  self.mAnimationCurrentFrameIndex=nil;
  self.mLastAnimationFrameTime=nil;
end

function TextureAnimation:update(deltaTime)
  if not self.mInnerObject then
    return
  end
  local time=self.mLastAnimationFrameTime+deltaTime;
  if self.mInterval<=time then        
    local next_frame_index=self.mAnimationCurrentFrameIndex+1;
    time=0;
    if next_frame_index>=#self.mTextures then
      return self:delete();
    else
      self.mAnimationCurrentFrameIndex=next_frame_index;
      self.mInnerObject:SetReplaceableTexture(self.mMaterialIndex,self.mTextures[self.mAnimationCurrentFrameIndex+1])
    end
  end
  self.mLastAnimationFrameTime=time;
end