NPL.load("./Math.lua");
local ParticleAffector = NPL.load("./ParticleAffector.lua");
local System = NPL.load("./ParticleSystem.lua");
local Affector=commonlib.inherit(ParticleAffector, NPL.export());
Affector.mType="ColourFader";
function Affector:ctor()
  self.mAdj={0,0,0,0};
end

function Affector:delete()
end

function Affector:_affectParticles(scene,timeElapsed)
  local dr=self.mAdj[1]*timeElapsed;
  local dg=self.mAdj[2]*timeElapsed;
  local db=self.mAdj[3]*timeElapsed;
  local da=self.mAdj[4]*timeElapsed;
  
  for _,particle in pairs(scene.mActiveParticles) do
    self:applyAdjustWithClamp(particle:getColour(),{dr,dg,db,da});
  end
end

function Affector:setAdjust(r,g,b,a)
  self.mAdj[1]=r;
  self.mAdj[2]=g;
  self.mAdj[3]=b;
  self.mAdj[4]=a;
end

function Affector:getAdjust()
  return self.mAdj;
end

function Affector:applyAdjustWithClamp(colour,adjust)
  for i=1,4 do
    colour[i]=colour[i]+adjust[i];
    if colour[i]<0 then
      colour[i]=0;
    elseif colour[i]>1 then
      colour[i]=1;
    end
  end
end

local Factory={}
function Factory.create()
  return Affector:new();
end
ParticleAffector.ColourFaderFactory = Factory;

System.singleton().addAffectorFactory(Affector.mType,Factory);