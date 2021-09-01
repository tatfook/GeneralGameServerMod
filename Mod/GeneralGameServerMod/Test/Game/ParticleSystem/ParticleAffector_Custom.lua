NPL.load("./Math.lua");
local ParticleAffector = NPL.load("./ParticleAffector.lua");
local System = NPL.load("./ParticleSystem.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Affector=commonlib.inherit(ParticleAffector, NPL.export());
Affector.mType="Custom";
function Affector:ctor()
end

function Affector:delete()
end

function Affector:_initParticle(particle)
    if self.init then
        self:init(particle);
    end
end

function Affector:_affectParticles(scene,timeElapsed)  
    if self.framemove then 
        self:framemove(scene.mActiveParticles, timeElapsed);
    end
end

function Affector:setMethod(init, framemove)
    self.init = init;
    self.framemove = framemove;
end

local Factory={}
function Factory.create()
  return Affector:new();
end
ParticleAffector.CustomFactory = Factory;
System.singleton().addAffectorFactory(Affector.mType,Factory);