local ParticleEmitter_Ellipsoid = NPL.load("./ParticleEmitter_Ellipsoid.lua");
NPL.load("./Math.lua");
local System=NPL.load("./ParticleEmitter.lua");
local ParticleEmitter = NPL.load("./ParticleEmitter.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Emitter=commonlib.inherit(ParticleEmitter_Ellipsoid, NPL.export());
Emitter.mType="HollowEllipsoid";
function Emitter:ctor()
  self:initDefaults(Emitter.mType);
  self.mInnerSize=vector3d:new(0.5,0.5,0.5);
end

function Emitter:delete()
end

function Emitter:copyParametersTo(emitter)
  Emitter._super.copyParametersTo(self,emitter);
  emitter:setInnerSize(self.mInnerSize[1],self.mInnerSize[2],self.mInnerSize[3]);
end

function Emitter:_initParticle(particle)
  particle:resetDimensions();
  
  local a,b,c,x,y,z;
  
  local alpha=math.random()*3.1415926*2;
  local beta=math.random()*3.1415926;
  
  a=self.mInnerSize[1]+math.random()*(1.0-self.mInnerSize[1]);
  b=self.mInnerSize[2]+math.random()*(1.0-self.mInnerSize[2]);
  c=self.mInnerSize[3]+math.random()*(1.0-self.mInnerSize[3]);
  
  local sinbeta=math.sin(beta);
  x=a*math.cos(alpha)*sinbeta;
  y=b*math.sin(alpha)*sinbeta;
  z=c*math.cos(beta);
  
  local pos=self.mPosition+self.mXRange*x+self.mYRange*y+self.mZRange*z;
  particle:setPosition(pos[1],pos[2],pos[3]);
  self:genEmissionColour(particle:getColour());
  self:genEmissionDirection(particle:getDirection());
  self:genEmissionVelocity(particle:getDirection());
  particle:setTimeToLive(self:genEmissionTTL());
  particle:setTotalTimeToLive(particle:getTimeToLive());
end

function Emitter:setInnerSize(x,y,z)
  self.mInnerSize[1]=x;
  self.mInnerSize[2]=y;
  self.mInnerSize[3]=z;
end

function Emitter:getInnerSize()
  return self.mInnerSize;
end

local Factory={}
function Factory.create()
  return Emitter:new();
end
ParticleEmitter.HollowEllipsoidFactory = Factory;
System.singleton().addEmitterFactory(Emitter.mType,Factory);