local ParticleEmitter_Area = NPL.load("./ParticleEmitter_Area.lua");
local System = NPL.load("./ParticleSystem.lua");
NPL.load("./Math.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local vector2d = commonlib.gettable("mathlib.vector2d");
local Emitter=commonlib.inherit(ParticleEmitter_Area, NPL.export());
Emitter.mType="Ring";
function Emitter:ctor()
  self:initDefaults(Emitter.mType);
  self.mInnerSize=vector2d:new(0.5,0.5)
end

function Emitter:delete()
end

function Emitter:copyParametersTo(emitter)
  Emitter._super.copyParametersTo(self,emitter);
  emitter:setInnerSize(self.mInnerSize[1],self.mInnerSize[2]);
end

function Emitter:_initParticle(particle)
  Emitter._super._initParticle(self,particle);
  
  local a,b,x,y,z;
  local alpha=math.random()*3.1415926*2;
  
  a=self.mInnerSize[1]+math.random()*(1-self.mInnerSize[1]);
  b=self.mInnerSize[2]+math.random()*(1-self.mInnerSize[2]);
  
  x=a*math.sin(alpha);
  y=b*math.cos(alpha);
  z=math.random()*2-1;
  
  local pos=self.mPosition+self.mXRange*x+self.mYRange*y+self.mZRange*z;
  particle:setPosition(pos[1],pos[2],pos[3]);
  self:genEmissionColour(particle:getColour());
  self:genEmissionDirection(particle:getDirection());
  self:genEmissionVelocity(particle:getDirection());
  particle:setTimeToLive(self:genEmissionTTL());
  particle:setTotalTimeToLive(particle:getTimeToLive());
end

function Emitter:setInnerSize(x,y,...)
  self.mInnerSize[1]=x;
  self.mInnerSize[2]=y;
end

local ParticleEmitter = NPL.load("./ParticleEmitter.lua");
local Factory={};
function Factory.create()
  return Emitter:new();
end
ParticleEmitter.RingFactory = Factory;

System.singleton().addEmitterFactory(Emitter.mType,Factory);