NPL.load("./Math.lua");
local ParticleAffector = NPL.load("./ParticleAffector.lua");
local System = NPL.load("./ParticleSystem.lua");
local Affector=commonlib.inherit(ParticleAffector, NPL.export());
Affector.mType="ColourFader2";
function Affector:ctor()
  self.mAdj1={0,0,0,0};
  self.mAdj2={0,0,0,0};
  self.mStateChangeVal=1;
end

function Affector:delete()
end

function Affector:_affectParticles(scene,timeElapsed)
  local dr1=self.mAdj1[1]*timeElapsed;
  local dg1=self.mAdj1[2]*timeElapsed;
  local db1=self.mAdj1[3]*timeElapsed;
  local da1=self.mAdj1[4]*timeElapsed;
  local dr2=self.mAdj2[1]*timeElapsed;
  local dg2=self.mAdj2[2]*timeElapsed;
  local db2=self.mAdj2[3]*timeElapsed;
  local da2=self.mAdj2[4]*timeElapsed;
  
  for _,particle in pairs(scene.mActiveParticles) do
    if particle:getTimeToLive()>self.mStateChangeVal then
      self:applyAdjustWithClamp(particle:getColour(),{dr1,dg1,db1,da1});
    else
      self:applyAdjustWithClamp(particle:getColour(),{dr2,dg2,db2,da2});
    end
  end
end

function Affector:setAdjust1(r,g,b,a)
  self.mAdj1[1]=r;
  self.mAdj1[2]=g;
  self.mAdj1[3]=b;
  self.mAdj1[4]=a;
end

function Affector:getAdjust1()
  return self.mAdj1;
end

function Affector:setAdjust2(r,g,b,a)
  self.mAdj2[1]=r;
  self.mAdj2[2]=g;
  self.mAdj2[3]=b;
  self.mAdj2[4]=a;
end

function Affector:getAdjust2()
  return self.mAdj2;
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
ParticleAffector.ColourFader2Factory = Factory;
System.singleton().addAffectorFactory(Affector.mType,Factory);