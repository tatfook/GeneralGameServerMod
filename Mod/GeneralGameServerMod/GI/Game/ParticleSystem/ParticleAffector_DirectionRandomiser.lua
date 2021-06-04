local ParticleAffector = NPL.load("./ParticleAffector.lua");
local System = NPL.load("./ParticleSystem.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Affector=commonlib.inherit(ParticleAffector, NPL.export());
Affector.mType="DirectionRandomiser";
function Affector:ctor()
  self.mRandomness=1;
  self.mScope=1;
  self.mKeepVelocity=false;
end

function Affector:delete()
end

function Affector:_affectParticles(scene,timeElapsed)  
  local length=0;
  for _,particle in pairs(scene.mActiveParticles) do
    if self.mScope>math.random() then
      if not particle:getDirection():compare(vector3d:new(0,0,0)) then
        if self.mKeepVelocity then
          length=particle:getDirection():length();
        end
        local dir=particle:getDirection()+vector3d:new((math.random()*self.mRandomness*2-self.mRandomness)*timeElapsed
          ,(math.random()*self.mRandomness*2-self.mRandomness)*timeElapsed
          ,(math.random()*self.mRandomness*2-self.mRandomness)*timeElapsed
        );
        if self.mKeepVelocity then
          dir=dir*length/dir:length();
        end
        particle:setDirection(dir[1],dir[2],dir[3]);
      end
    end
  end
end

function Affector:setRandomness(force)
  self.mRandomness=force;
end

function Affector:setScope(scope)
  self.mScope=scope;
end

function Affector:setKeepVelocity(keepVelocity)
  self.mKeepVelocity=keepVelocity;
end

local Factory={}
function Factory.create()
  return Affector:new();
end
ParticleAffector.DirectionRandomiserFactory = Factory;
System.singleton().addAffectorFactory(Affector.mType,Factory);