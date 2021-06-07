local Affector=commonlib.inherit(nil,commonlib.gettable("Truck.Game.ParticleSystem.Affector"));
function Affector:ctor()
end

function Affector:delete()
end

function Affector:_initParticle(particle)
end

function Affector:getType()
  return self.mType;
end