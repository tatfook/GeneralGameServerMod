NPL.load("./Math.lua");
local ParticleEmitter_Area = NPL.load("./ParticleEmitter_Area.lua");
local System = NPL.load("./ParticleSystem.lua");
local ParticleEmitter = NPL.load("./ParticleEmitter.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Emitter=commonlib.inherit(ParticleEmitter_Area, NPL.export());
Emitter.mType="Box";
function Emitter:ctor()
  self:initDefaults(Emitter.mType);
end

function Emitter:delete()
end

function Emitter:_initParticle(particle)
  Emitter._super._initParticle(self,particle);
  local xOff=self.mXRange*(math.random()*2-1);
  local yOff=self.mYRange*(math.random()*2-1);
  local zOff=self.mZRange*(math.random()*2-1);
  local pos=self.mPosition+xOff+yOff+zOff;
  particle:setPosition(pos[1],pos[2],pos[3]);
  self:genEmissionColour(particle:getColour());
  self:genEmissionDirection(particle:getDirection());
  self:genEmissionVelocity(particle:getDirection());
  particle:setTimeToLive(self:genEmissionTTL());
  particle:setTotalTimeToLive(particle:getTimeToLive());
end


local Factory={}
function Factory.create()
  return Emitter:new();
end
ParticleEmitter.BoxFactory = Factory;
System.singleton().addEmitterFactory(Emitter.mType,Factory);