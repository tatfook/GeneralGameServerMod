NPL.load("./Math.lua");
local ParticleAffector = NPL.load("./ParticleAffector.lua");
local System = NPL.load("./ParticleSystem.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Affector=commonlib.inherit(ParticleAffector, NPL.export());
Affector.mType="Scaler";
function Affector:ctor()
  self.mScaleAdj=0;
end

function Affector:delete()
end

function Affector:_affectParticles(scene,timeElapsed)  
  local ds=self.mScaleAdj*timeElapsed;
  local NewWide,NewHigh;
  for _,particle in pairs(scene.mActiveParticles) do
    if not particle:hasOwnDimensions() then
      NewWide,NewHigh=scene:getDefaultDimensions();
    else
      NewWide,NewHigh=particle:getOwnDimensions();
    end
    NewWide=NewWide+ds;
    NewHigh=NewHigh+ds;
    particle:setDimensions(NewWide,NewHigh);
  end
end

function Affector:setAdjust(rate)
  self.mScaleAdj=rate;
end

local Factory={}
function Factory.create()
  return Affector:new();
end
ParticleAffector.ScalerFactory = Factory;

System.singleton().addAffectorFactory(Affector.mType,Factory);