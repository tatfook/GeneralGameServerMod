NPL.load("./Math.lua");
local ParticleAffector = NPL.load("./ParticleAffector.lua");
local System = NPL.load("./ParticleSystem.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Affector=commonlib.inherit(ParticleAffector, NPL.export());
Affector.mType="LinearForce";
function Affector:ctor()
  self.mForceApplication="add";
  self.mForceVector=vector3d:new(0,1,0);
end

function Affector:delete()
end

function Affector:_affectParticles(scene,timeElapsed)  
  local scaledVector=vector3d:new(0,0,0);
  if self.mForceApplication=="add" then
    scaledVector=self.mForceVector*timeElapsed;
  end
  for _,particle in pairs(scene.mActiveParticles) do
    local dir;
    if self.mForceApplication=="add" then
      dir=particle:getDirection()+scaledVector;
    else
      dir=(particle:getDirection()+self.mForceVector)*0.5;
    end
    particle:setDirection(dir[1],dir[2],dir[3]);
  end
end

function Affector:setForceVector(x,y,z)
  self.mForceVector[1]=x;
  self.mForceVector[2]=y;
  self.mForceVector[3]=z;
end

function Affector:setForceApplication(fa)
  self.mForceApplication=fa;
end

local Factory={}
function Factory.create()
  return Affector:new();
end
ParticleAffector.LinearForceFactory = Factory;
System.singleton().addAffectorFactory(Affector.mType,Factory);