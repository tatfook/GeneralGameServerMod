NPL.load("(gl)script/Truck/Game/ParticleSystem/Math.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Particle=NPL.load("./Particle.lua");
local System=NPL.load("./ParticleSystem.lua");
local function debugEcho(text,pure)
  if pure then
    echo("devilwalk",text);
  else
    echo("devilwalk","devilwalk--------------------------------------debug:ParticleScene.lua:"..text);
  end
end
local function _checkParameterNotNil(func,name,value)
  if not value then
    debugEcho("devilwalk----------------------ParticleSystem:error:"..func..":"..name.." is error!!!",true);
  end
end
local Scene=commonlib.inherit(nil,commonlib.gettable("Truck.Game.ParticleSystem.Scene"));
function Scene:ctor()
  debugEcho("Scene:ctor");
  _checkParameterNotNil("Scene:ctor","self.mName",self.mName);
  self.mActiveParticles={};
  self.mFreeParticles={};
  self.mParticlePool={};
  self.mEmittedEmitterPool={};
  self.mFreeEmittedEmitters={};
  self.mActiveEmittedEmitters={};
  self.mEmitters={};
  self.mAffectors={};
  self.mSpeedFactor=1.0;
  self.mIsEmitting=true;
  self.mPoolSize=10;
  self.mEmittedEmitterPoolSize=3;
  self.mDefaultWidth=100;
  self.mDefaultHeight=100;
  self.mIterationInterval=0;
  self.mIterationIntervalSet=false;
  self.mLocalSpace=true;
  self.mEmittedEmitterPoolInitialised=false;
  
  self.mBillboardType="point";
  self.mCommonDirection=vector3d:new(0,0,1);
  self.mCommonUpVector=vector3d:new(0,1,0);
  self.mPointRendering=false;
  self.mRotationType="vertex";
  self.mAccurateFacing=false;
  
  self.mInternal=ParaScene.CreateObject("CScriptParticle",self.mName,self.mX,self.mY,self.mZ);
  ParaScene.Attach(self.mInternal);
end

function Scene:delete()
  debugEcho("Scene:delete");
  self:removeAllEmitters();
  self:removeAllEmittedEmitters();
  self:removeAllAffectors();
  for _,particle in pairs(self.mParticlePool) do
    particle:delete();
  end
  ParaScene.Attach(self.mInternal);
  ParaScene.Detach(self.mInternal);
end

function Scene:_update(timeElapsed)
  self:configureRenderer();
  self:initialiseEmittedEmitters();
  self:_expire(timeElapsed);
  self:_triggerAffectors(timeElapsed);
  self:_applyMotion(timeElapsed);

  if self.mIsEmitting then
    self:_triggerEmitters(timeElapsed);
  end
  
  if self.mLife then
    self.mLife=self.mLife-timeElapsed;
    if self.mLife<=0 then
      System.destroyScene(self);
    end
  end
  
  self.mInternal:GetAttributeObject():CallField("clear");
  for _,particle in pairs(self.mActiveParticles) do
    if particle:getParticleType()=="Visual" then
      self.mInternal:GetAttributeObject():CallField("beginParticle");
      local width=self.mDefaultWidth;
      local height=self.mDefaultHeight;
      if particle:hasOwnDimensions() then
        width,height=particle:getOwnDimensions();
      end
      self.mInternal:GetAttributeObject():SetField("mParticleWidth",width);
      self.mInternal:GetAttributeObject():SetField("mParticleHeight",height);
      self.mInternal:GetAttributeObject():SetField("mParticlePositionX",particle:getPosition()[1]);
      self.mInternal:GetAttributeObject():SetField("mParticlePositionY",particle:getPosition()[2]);
      self.mInternal:GetAttributeObject():SetField("mParticlePositionZ",particle:getPosition()[3]);
      self.mInternal:GetAttributeObject():SetField("mParticleColourR",particle:getColour()[1]);
      self.mInternal:GetAttributeObject():SetField("mParticleColourG",particle:getColour()[2]);
      self.mInternal:GetAttributeObject():SetField("mParticleColourB",particle:getColour()[3]);
      self.mInternal:GetAttributeObject():SetField("mParticleColourA",particle:getColour()[4]);
      self.mInternal:GetAttributeObject():SetField("mParticleRotation",particle:getRotation());
      self.mInternal:GetAttributeObject():SetField("mParticleUVOffsetX",particle:getUVOffset()[1]);
      self.mInternal:GetAttributeObject():SetField("mParticleUVOffsetY",particle:getUVOffset()[2]);
      self.mInternal:GetAttributeObject():SetField("mParticleUVScaleX",particle:getUVScale()[1]);
      self.mInternal:GetAttributeObject():SetField("mParticleUVScaleY",particle:getUVScale()[2]);
      self.mInternal:GetAttributeObject():CallField("endParticle");    
    end
    if self.mTexture then
      self.mInternal:GetAttributeObject():SetField("mTexture",self.mTexture);
    end
    self.mInternal:GetAttributeObject():SetField("mBillboardType",self.mBillboardType);
    self.mInternal:GetAttributeObject():SetField("mCommonDirectionX",self.mCommonDirection[1]);
    self.mInternal:GetAttributeObject():SetField("mCommonDirectionY",self.mCommonDirection[2]);
    self.mInternal:GetAttributeObject():SetField("mCommonDirectionZ",self.mCommonDirection[3]);
    self.mInternal:GetAttributeObject():SetField("mCommonUpX",self.mCommonUpVector[1]);
    self.mInternal:GetAttributeObject():SetField("mCommonUpY",self.mCommonUpVector[2]);
    self.mInternal:GetAttributeObject():SetField("mCommonUpZ",self.mCommonUpVector[3]);
    self.mInternal:GetAttributeObject():SetField("mPointRendering",self.mPointRendering);
    self.mInternal:GetAttributeObject():SetField("mRotationType",self.mRotationType);
    self.mInternal:GetAttributeObject():SetField("mAccurateFacing",self.mAccurateFacing);

    --debugEcho("Scene:_update:self:");
    --debugEcho(self,true);
  end
end

function Scene:_expire(timeElapsed)
  debugEcho("Scene:_expire");
  local i=1;
  while i<=#self.mActiveParticles do
    local particle=self.mActiveParticles[i];
    if particle:getTimeToLive()<timeElapsed then
      if particle:getParticleType()=="Visual" then
        self.mFreeParticles[#self.mFreeParticles+1]=particle;
      else
        local fee=self:findFreeEmittedEmitter(particle:getName());
        fee[#fee+1]=particle;
        self:removeFromActiveEmittedEmitters(particle);
      end
      table.remove(self.mActiveParticles,i);
    else
      particle:setTimeToLive(particle:getTimeToLive()-timeElapsed);
      i=i+1;
    end
  end
end

function Scene:_triggerEmitters(timeElapsed)
  debugEcho("Scene:_triggerEmitters");
  local requested={};
  local emittedRequested={};
  local totalRequested=0;
  local emitterCount=#self.mEmitters;
  local emittedEmitterCount=#self.mActiveEmittedEmitters;
  local emissionAllowed=#self.mFreeParticles;
  for key,emitter in pairs(self.mEmitters) do
    if not emitter:isEmitted() then
      requested[key]=emitter:_getEmissionCount(timeElapsed);
      totalRequested=totalRequested+requested[key];
    end
  end
  for key,emitter in pairs(self.mActiveEmittedEmitters) do
    emittedRequested[key]=emitter:_getEmissionCount(timeElapsed);
    totalRequested=totalRequested+emittedRequested[key];
  end
  local ratio=1.0;
  if totalRequested>emissionAllowed then
    ratio=emissionAllowed/totalRequested;
    for i=1,emitterCount do
      if requested[i] then
        requested[i]=math.floor(requested[i]*ratio);
      end
    end
    for i=1,emittedEmitterCount do
      emittedRequested[i]=math.floor(emittedRequested[i]*ratio);
    end
  end
  for key,emitter in pairs(self.mEmitters) do
    if not emitter:isEmitted() then
      self:_executeTriggerEmitters(emitter,requested[key],timeElapsed);
    end
  end
  for key,emitter in pairs(self.mActiveEmittedEmitters) do
    self:_executeTriggerEmitters(emitter,emittedRequested[key],timeElapsed);
  end
end

function Scene:_executeTriggerEmitters(emitter,requested,timeElapsed)
  local timePoint=0;
  if not requested then
    return;
  end
  debugEcho("Scene:_executeTriggerEmitters:emitter,requested:"..tostring(emitter:getName())..","..tostring(requested));
  local timeInc=timeElapsed/requested;
  for i=1,requested do
    local p;
    if emitter:getEmittedEmitter() then
      p=self:createEmitterParticle(emitter:getEmittedEmitter());
    else
      p=self:createParticle();
    end
    if not p then
      return;
    end
    emitter:_initParticle(p);
    
    local result=p:getPosition()+p:getDirection()*timePoint;
    p:setPosition(result[1],result[2],result[3]);
    
    for _,affector in pairs(self.mAffectors) do
      affector:_initParticle(p);
    end
    
    timePoint=timePoint+timeInc;
  end
end

function Scene:_applyMotion(timeElapsed)
  debugEcho("Scene:_applyMotion");
  for _,particle in pairs(self.mActiveParticles) do
    local result=particle:getPosition()+particle:getDirection()*timeElapsed;
    particle:setPosition(result[1],result[2],result[3]);
  end
end

function Scene:_triggerAffectors(timeElapsed)
  debugEcho("Scene:_triggerAffectors");
  for _,affector in pairs(self.mAffectors) do
    affector:_affectParticles(self,timeElapsed);
  end
end

function Scene:increasePool(size)
  debugEcho("Scene:increasePool:size:"..tostring(size));
  local oldSize=#self.mParticlePool;
  for i=oldSize+1,size do
    self.mParticlePool[i]=Particle:new();
  end
end

function Scene:createParticle()
  debugEcho("Scene:createParticle");
  local ret;
  if #self.mFreeParticles>0 then
    ret=self.mFreeParticles[#self.mFreeParticles];
    table.remove(self.mFreeParticles);
    self.mActiveParticles[#self.mActiveParticles+1]=ret;
  end
  return ret;
end

function Scene:createEmitterParticle(emitterName)
  debugEcho("Scene:createEmitterParticle:emitterName:"..emitterName);
  local ret;
  local fee=self:findFreeEmittedEmitter(emitterName);
  if fee and #fee>0 then
    ret=fee[#fee];
    table.remove(fee);
    self.mActiveParticles[#self.mActiveParticles+1]=ret;
    self.mActiveEmittedEmitters[#self.mActiveEmittedEmitters+1]=ret;
  end
  return ret;
end

function Scene:addEmitter(emitterType)
  local ret=System.createEmitter(emitterType,self);
  self.mEmitters[#self.mEmitters+1]=ret;
  return ret;
end

function Scene:removeEmitter(emitter)
  for key,value in pairs(self.mEmitters) do
    if value==emitter then
      table.remove(self.mEmitters,key);
      System.destroyEmitter(emitter);
      break;
    end
  end
end

function Scene:removeAllEmitters()
  for _,emitter in pairs(self.mEmitters) do
    System.destroyEmitter(emitter);
  end
  self.mEmitters={};
end

function Scene:addAffector(affectorType)
  local ret=System.createAffector(affectorType,self);
  self.mAffectors[#self.mAffectors+1]=ret;
  return ret;
end

function Scene:removeAffector(affector)
  for key,value in pairs(self.mAffectors) do
    if value==affector then
      table.remove(self.mAffectors,key);
      System.destroyAffector(affector);
      break;
    end
  end
end

function Scene:addCustomAffector(affector)
  self.mAffectors[#self.mAffectors+1]=affector;
end

function Scene:removeCustomAffector(affector)
  for key,value in pairs(self.mAffectors) do
    if value==affector then
      table.remove(self.mAffectors,key);
      break;
    end
  end
end

function Scene:removeAllAffectors()
  for _,affector in pairs(self.mAffectors) do
    System.destroyAffector(affector);
  end
  self.mAffectors={};
end

function Scene:setParticleQuota(size)
  if #self.mParticlePool<size then
    self.mPoolSize=size;
  end
end

function Scene:getParticleQuota()
  return self.mPoolSize;
end

function Scene:getEmittedEmitterQuota()
  return self.mEmittedEmitterPoolSize;
end

function Scene:setEmittedEmitterQuota(size)
  local current_size=0;
  for _,pool in pairs(self.mEmittedEmitterPool) do
    current_size=current_size+#pool;
  end
  if current_size<size then
    self.mEmittedEmitterPoolSize=size;
  end
end

function Scene:fastForward(time,interval)
  local steps=math.floor(time/interval+0.5);
  for i=1,steps do
    self:_update(interval);
  end
end

function Scene:setEmitting(v)
  self.mIsEmitting=v;
end

function Scene:getEmitting()
  return self.mIsEmitting;
end

function Scene:setSpeedFactor(speedFactor)
  self.mSpeedFactor=speedFactor;
end

function Scene:getSpeedFactor()
  return self.mSpeedFactor;
end

function Scene:setDefaultDimensions(width,height)
  self.mDefaultWidth=width;
  self.mDefaultHeight=height;
end

function Scene:getDefaultDimensions()
  return self.mDefaultWidth,self.mDefaultHeight;
end

function Scene:configureRenderer()
  debugEcho("Scene:configureRenderer");
  local currSize=#self.mParticlePool;
  if currSize<self.mPoolSize then
    self:increasePool(self.mPoolSize);
    for i=currSize+1,self.mPoolSize do
      self.mFreeParticles[#self.mFreeParticles+1]=self.mParticlePool[i];
    end
  end
end

function Scene:initialiseEmittedEmitters()
  debugEcho("Scene:initialiseEmittedEmitters");
  local currSize=0;
  if not next(self.mEmittedEmitterPool) then
    if self.mEmittedEmitterPoolInitialised then
      return;
    else
      self:initialiseEmittedEmitterPool();
    end
  else
    for _,pool in pairs(self.mEmittedEmitterPool) do
      currSize=currSize+#pool;
    end
  end
  local size=self.mEmittedEmitterPoolSize;
  if currSize<size and next(self.mEmittedEmitterPool) then
    self:increaseEmittedEmitterPool(size);
    self:addFreeEmittedEmitters();
  end
end

function Scene:initialiseEmittedEmitterPool()
  if self.mEmittedEmitterPoolInitialised then
    return;
  end
  debugEcho("Scene:initialiseEmittedEmitterPool");
  
  local eimtterInner;
  for _,emitter in pairs(self.mEmitters) do
    if emitter:getEmittedEmitter() then
      self.mEmittedEmitterPool[emitter:getEmittedEmitter()]={};
    end
    for _,emitterInner in pairs(self.mEmitters) do
      if emitter:getName() and emitter:getName()==emitterInner:getEmittedEmitter() then
        emitter:setEmitted(true);
        break;
      else
        emitter:setEmitted(false);
      end
    end
  end
  self.mEmittedEmitterPoolInitialised=true;
end

function Scene:increaseEmittedEmitterPool(size)
  if not next(self.mEmittedEmitterPool) then
    return;
  end
  debugEcho("Scene:increaseEmittedEmitterPool");
  local clonedEmitter;
  local name="";
  local e;
  local emitted_emitter_pool_size=0;
  for _,__ in pairs(self.mEmittedEmitterPool) do
    emitted_emitter_pool_size=emitted_emitter_pool_size+1;
  end
  local maxNumberOfEmitters=math.floor(size/emitted_emitter_pool_size);
  local oldSize=0;
  
  for key,pool in pairs(self.mEmittedEmitterPool) do
    name=key;
    e=pool;
    
    for _,emitter in pairs(self.mEmitters) do
      if name~="" and name==emitter:getName() then
        oldSize=#e;
        for i=oldSize+1,maxNumberOfEmitters do
          clonedEmitter=System.createEmitter(emitter:getType(),self);
          emitter:copyParametersTo(clonedEmitter);
          clonedEmitter:setEmitted(emitter:isEmitted());
          local min_duration,max_duration=clonedEmitter:getDuration();
          local min_repeat_delay,max_repeat_delay=clonedEmitter:getRepeatDelay();
          if min_duration>0 and min_repeat_delay>0 then
            clonedEmitter:setEnabled(false);
          end
          e[#e+1]=clonedEmitter;
        end
      end
    end
  end
end

function Scene:addFreeEmittedEmitters()
  if not next(self.mEmittedEmitterPool) then
    return;
  end
  debugEcho("Scene:addFreeEmittedEmitters");
  local emittedEmitters;
  local fee;
  local name="";
  
  for key,pool in pairs(self.mEmittedEmitterPool) do
    name=key;
    emittedEmitters=pool;
    fee=self:findFreeEmittedEmitter(name);
    
    if not fee then
      self.mFreeEmittedEmitters[name]={};
      fee=self:findFreeEmittedEmitter(name);
    end
    
    for _,emitter in pairs(emittedEmitters) do
      fee[#fee+1]=emitter;
    end
  end
end

function Scene:removeAllEmittedEmitters()
  for _,pool in pairs(self.mEmittedEmitterPool) do
    for _,emitter in pairs(pool) do
      System.destroyEmitter(emitter);
    end
  end
  self.mEmittedEmitterPool={};
  self.mFreeEmittedEmitters={};
  self.mActiveEmittedEmitters={};
end

function Scene:findFreeEmittedEmitter(name)
  return self.mFreeEmittedEmitters[name];
end

function Scene:removeFromActiveEmittedEmitters(emitter)
  debugEcho("Scene:removeFromActiveEmittedEmitters:emitter:");
  debugEcho(emitter,true);
  for key,test in pairs(self.mActiveEmittedEmitters) do
    if test==emitter then
      table.remove(self.mActiveEmittedEmitters,key);
      break;
    end
  end
end

function Scene:setTexture(filename)
  self.mTexture=filename;
end

function Scene:setBillboardType(billboardType)
  self.mBillboardType=billboardType;
end

function Scene:setCommonDirection(x,y,z)
  self.mCommonDirection[1]=x;
  self.mCommonDirection[2]=y;
  self.mCommonDirection[3]=z;
end

function Scene:getCommonDirection()
  return self.mCommonDirection;
end

function Scene:setCommonUp(x,y,z)
  self.mCommonUpVector[1]=x;
  self.mCommonUpVector[2]=y;
  self.mCommonUpVector[3]=z;
end

function Scene:getCommonUp()
  return self.mCommonUpVector;
end

function Scene:setPointRenderingEnabled(enable)
  self.mPointRendering=enable;
end

function Scene:setUseAccurateFacing(acc)
  self.mAccurateFacing=acc;
end

function Scene:setBillboardRotationType(rotationType)
  self.mRotationType=rotationType;
end

function Scene:setBoundRadius(radius)
  self.mInternal:SetPhysicsRadius(radius)
end