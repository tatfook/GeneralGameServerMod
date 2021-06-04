NPL.load("./Math.lua");
local ParticleAffector = NPL.load("./ParticleAffector.lua");
local System = NPL.load("./ParticleSystem.lua");
local Affector=commonlib.inherit(ParticleAffector, NPL.export());
Affector.mType="ColourInterpolator";
function Affector:ctor()
  self.mColourAdj={};
  self.mTimeAdj={};
  for i=1,6 do
    self.mColourAdj[i]={0.5,0.5,0.5,0.5};
    self.mTimeAdj[i]=1;
  end
end

function Affector:delete()
end

function Affector:_affectParticles(scene,timeElapsed)
  for _,particle in pairs(scene.mActiveParticles) do
    local life_time=particle:getTotalTimeToLive();
    local particle_time=1-(particle:getTimeToLive()/life_time);
    if particle_time<=self.mTimeAdj[1] then
      particle:setColour(self.mColourAdj[1]);
    elseif particle_time>=self.mTimeAdj[6] then
      particle:setColour(self.mColourAdj[6]);
    else
      for i=1,5 do
        if particle_time>=self.mTimeAdj[i] and particle_time<self.mTimeAdj[i+1] then
          particle_time=particle_time-self.mTimeAdj[i];
          particle_time=particle_time/(self.mTimeAdj[i+1]-self.mTimeAdj[i]);
          particle:setColour(self.mColourAdj[i+1][1]*particle_time+self.mColourAdj[i][1]*(1-particle_time)
            ,self.mColourAdj[i+1][2]*particle_time+self.mColourAdj[i][2]*(1-particle_time)
            ,self.mColourAdj[i+1][3]*particle_time+self.mColourAdj[i][3]*(1-particle_time)
            ,self.mColourAdj[i+1][4]*particle_time+self.mColourAdj[i][4]*(1-particle_time)
          );
          break;
        end
      end
    end
  end
end

function Affector:setColourAdjust(index,r,g,b,a)
  self.mColourAdj[index][1]=r;
  self.mColourAdj[index][2]=g;
  self.mColourAdj[index][3]=b;
  self.mColourAdj[index][4]=a;
end

function Affector:setTimeAdjust(index,time)
  self.mTimeAdj[index]=time;
end

local Factory={}
function Factory.create()
  return Affector:new();
end
ParticleAffector.ColourInterpolatorFactory = Factory;
System.singleton().addAffectorFactory(Affector.mType,Factory);