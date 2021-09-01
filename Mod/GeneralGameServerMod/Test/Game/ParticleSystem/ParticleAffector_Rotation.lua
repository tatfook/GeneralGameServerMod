NPL.load("./Math.lua");
local ParticleAffector = NPL.load("./ParticleAffector.lua");
local System = NPL.load("./ParticleSystem.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Affector=commonlib.inherit(ParticleAffector, NPL.export());
Affector.mType="Rotator";
function Affector:ctor()
  self.mRotationSpeedRangeStart=0;
  self.mRotationSpeedRangeEnd=0;
  self.mRotationRangeStart=0;
  self.mRotationRangeEnd=0;
end

function Affector:delete()
end

function Affector:_initParticle(particle)
  particle:setRotation(self.mRotationRangeStart+math.random()*(self.mRotationRangeEnd-self.mRotationRangeStart))
  particle:setRotationSpeed(self.mRotationSpeedRangeStart+math.random()*(self.mRotationSpeedRangeEnd-self.mRotationSpeedRangeStart))
end

function Affector:_affectParticles(scene,timeElapsed)  
  local ds=timeElapsed;
  local NewRotation;
  for _,particle in pairs(scene.mActiveParticles) do
    NewRotation=particle:getRotation()+ds*particle:getRotationSpeed();
    particle:setRotation(NewRotation);
  end
end

function Affector:setRotationSpeedRange(startValue,endValue)
  self.mRotationSpeedRangeStart=startValue;
  self.mRotationSpeedRangeEnd=endValue;
end

function Affector:getRotationSpeedRange()
  return self.mRotationSpeedRangeStart,self.mRotationSpeedRangeEnd;
end

function Affector:setRotationRange(startValue,endValue)
  self.mRotationRangeStart=startValue;
  self.mRotationRangeEnd=endValue;
end

function Affector:getRotationRange()
  return self.mRotationRangeStart,self.mRotationRangeEnd;
end

local Factory={}
function Factory.create()
  return Affector:new();
end
ParticleAffector.RotatorFactory = Factory;

System.singleton().addAffectorFactory(Affector.mType,Factory);