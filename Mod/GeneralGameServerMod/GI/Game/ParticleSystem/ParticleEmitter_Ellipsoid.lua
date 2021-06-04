local ParticleEmitter_Area = NPL.load("./ParticleEmitter_Area.lua");
local System = NPL.load("./ParticleSystem.lua");
NPL.load("./Math.lua");
local ParticleEmitter = NPL.load("./ParticleEmitter.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Emitter=commonlib.inherit(ParticleEmitter_Area,NPL.export());
Emitter.mType="Ellipsoid";
function Emitter:ctor()
  self:initDefaults(Emitter.mType);
end

function Emitter:delete()
end

function Emitter:_initParticle(particle)
  Emitter._super._initParticle(self,particle);
  local x,y,z;
  while true do
    x=math.random()*2-1;
    y=math.random()*2-1;
    z=math.random()*2-1;
    if x*x+y*y+z*z<=1 then
      break;
    end
  end
  local pos=self.mPosition+self.mXRange*x+self.mYRange*y+self.mZRange*z;
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
ParticleEmitter.EllipsoidFactory = Factory;
System.singleton().addEmitterFactory(Emitter.mType,Factory);