NPL.load("./Math.lua");
local System = NPL.load("./ParticleSystem.lua");
local ParticleEmitter = NPL.load("./ParticleEmitter.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local System=commonlib.gettable("Truck.Game.ParticleSystem");
local Emitter=commonlib.inherit(ParticleEmitter, NPL.export());
function Emitter:ctor()
  self.mSize=vector3d:new(0,0,0);
  self.mXRange=vector3d:new(0,0,0);
  self.mYRange=vector3d:new(0,0,0);
  self.mZRange=vector3d:new(0,0,0);
end

function Emitter:delete()
end

function Emitter:copyParametersTo(emitter)
  Emitter._super.copyParametersTo(self,emitter);
  emitter:setSize(self.mSize[1],self.mSize[2],self.mSize[3]);
end

function Emitter:initDefaults(t)
  self.mParticleDirection=vector3d:new(0,0,1);
  self.mUp=vector3d:new(0,1,0);
  self:setSize(100,100,100);
  self.mType=t;
end

function Emitter:_getEmissionCount(timeElapsed)
  return self:genConstantEmissionCount(timeElapsed);
end

function Emitter:setDirection(x,y,z)
  Emitter._super.setDirection(self,x,y,z);
  self:genAreaAxes();
end

function Emitter:setUp(x,y,z)
  Emitter._super.setUp(self,x,y,z);
  self:genAreaAxes();
end

function Emitter:setSize(x,y,z)
  self.mSize[1]=x;
  self.mSize[2]=y;
  self.mSize[3]=z;
  self:genAreaAxes();
end

function Emitter:setSizeInAxisAlignedParentCoord(x,y,z)
  if x and y and z then
    self.mSizeInAxisAlignedParentCoord = {x,y,z}
  else
    self.mSizeInAxisAlignedParentCoord = nil
  end
  self:genAreaAxes()
end

function Emitter:getSize()
  return self.mSize;
end

function Emitter:genAreaAxes()
  if not self.mSizeInAxisAlignedParentCoord then
    local left=vector3d:new(self.mUp[1],self.mUp[2],self.mUp[3]);
    left:cross(self.mParticleDirection);
    echo("devilwalk","devilwalk----------------------------debug:ParticleEmitter_Area.lua:Emitter:genAreaAxes:left:"..tostring(left[1])..","..tostring(left[2])..","..tostring(left[3]));
    self.mXRange=left*self.mSize[1]*0.5;
    self.mYRange=self.mUp*self.mSize[2]*0.5;
    self.mZRange=self.mParticleDirection*self.mSize[3]*0.5;
  else
    self.mXRange=vector3d:new(self.mSizeInAxisAlignedParentCoord[1]*0.5,0,0);
    self.mYRange=vector3d:new(0,self.mSizeInAxisAlignedParentCoord[2]*0.5,0);
    self.mZRange=vector3d:new(0,0,self.mSizeInAxisAlignedParentCoord[3]*0.5);
  end
end