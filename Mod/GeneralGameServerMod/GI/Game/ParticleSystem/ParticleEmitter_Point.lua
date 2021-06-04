
local System=NPL.load("./ParticleEmitter.lua");
local ParticleEmitter = NPL.load("./ParticleEmitter.lua");

local Emitter=commonlib.inherit(ParticleEmitter, NPL.export());
Emitter.mType="Point";
function Emitter:ctor()
end

function Emitter:delete()
end

function Emitter:_initParticle(particle)
  Emitter._super._initParticle(self,particle);
  particle:setPosition(self:getPosition()[1],self:getPosition()[2],self:getPosition()[3]);
  self:genEmissionColour(particle:getColour());
  self:genEmissionDirection(particle:getDirection());
  self:genEmissionVelocity(particle:getDirection());
  particle:setTimeToLive(self:genEmissionTTL());
  particle:setTotalTimeToLive(particle:getTimeToLive());
end

function Emitter:_getEmissionCount(timeElapsed)
  return self:genConstantEmissionCount(timeElapsed);
end

local Factory={}
function Factory.create()
  return Emitter:new();
end
ParticleEmitter.PointFactory = Factory;

System.singleton().addEmitterFactory(Emitter.mType,Factory);