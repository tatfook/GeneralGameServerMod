NPL.load("./Math.lua")
local Particle = NPL.load("./Particle.lua")
local vector3d = commonlib.gettable("mathlib.vector3d")
local function debugEcho(value, pure)
    if pure then
        echo("devilwalk", value)
    else
        echo("devilwalk", "devilwalk-----------------------------------debug:ParticleEmitter.lua:" .. tostring(value))
    end
end
local Emitter = commonlib.inherit(Particle, NPL.export())
function Emitter:ctor()
    self.mParticleDirection = vector3d:new(0, 0, 0)
    self.mUp = vector3d:new(0, 0, 0)
    self.mStartTime = 0
    self.mDurationMin = 0
    self.mDurationMax = 0
    self.mDurationRemain = 0
    self.mRepeatDelayMin = 0
    self.mRepeatDelayMax = 0
    self.mRepeatDelayRemain = 0
    self.mAngle = 0
    self:setParticleDirection(1, 0, 0)
    self.mEmissionRate = 1
    self.mMaxSpeed = 1
    self.mMinSpeed = 1
    self.mMaxTTL = 5
    self.mMinTTL = 5
    self.mColourRangeStart = {1, 1, 1, 1}
    self.mColourRangeEnd = {1, 1, 1, 1}
    self.mEnabled = true
    self.mRemainder = 0
    self.mEmitted = false
    self.mParticleType = "Emitter"
end

function Emitter:delete()
end

function Emitter:copyParametersTo(emitter)
    emitter:setAngle(self.mAngle)
    emitter:setParticleColour(
        self.mColourRangeStart[1],
        self.mColourRangeStart[2],
        self.mColourRangeStart[3],
        self.mColourRangeStart[4],
        self.mColourRangeEnd[1],
        self.mColourRangeEnd[2],
        self.mColourRangeEnd[3],
        self.mColourRangeEnd[4]
    )
    emitter:setParticleDirection(self.mParticleDirection[1], self.mParticleDirection[2], self.mParticleDirection[3])
    emitter:setUp(self.mUp[1], self.mUp[2], self.mUp[3])
    emitter:setEmissionRate(self.mEmissionRate)
    emitter:setPosition(self.mPosition[1], self.mPosition[2], self.mPosition[3])
    emitter:setParticleVelocity(self.mMinSpeed, self.mMaxSpeed)
    emitter:setParticleTimeToLive(self.mMinTTL, self.mMaxTTL)
    emitter:setDuration(self.mDurationMin, self.mDurationMax)
    emitter:setRepeatDelay(self.mRepeatDelayMin, self.mRepeatDelayMax)
    emitter:setName(self.mName)
    emitter:setEmittedEmitter(self.mEmittedEmitter)
end

function Emitter:getType()
    return self.mType
end

function Emitter:setParticleDirection(x, y, z)
    self.mParticleDirection[1] = x
    self.mParticleDirection[2] = y
    self.mParticleDirection[3] = z
    self.mParticleDirection:normalize()

    self.mUp = self.mParticleDirection:perpendicular()
    self.mUp:normalize()
end

function Emitter:getParticleDirection()
    return self.mParticleDirection
end

function Emitter:setUp(x, y, z)
    self.mUp[1] = x
    self.mUp[2] = y
    self.mUp[3] = z
    self.mUp:normalize()
end

function Emitter:getUp()
    return self.mUp
end

function Emitter:setAngle(angle)
    self.mAngle = angle
end

function Emitter:getAngle()
    return self.mAngle
end

function Emitter:setParticleVelocity(minSpeed, maxSpeed)
    self.mMinSpeed = minSpeed
    self.mMaxSpeed = maxSpeed
end

function Emitter:getParticleVelocity()
    return self.mMinSpeed, self.mMaxSpeed
end

function Emitter:setEmissionRate(particlesPerSecond)
    self.mEmissionRate = particlesPerSecond
end

function Emitter:getEmissionRate()
    return self.mEmissionRate
end

function Emitter:setParticleTimeToLive(minTTL, maxTTL)
    self.mMinTTL = minTTL
    self.mMaxTTL = maxTTL
end

function Emitter:getParticleTimeToLive()
    return self.mMinTTL, self.mMaxTTL
end

function Emitter:setParticleColour(startR, startG, startB, startA, endR, endG, endB, endA)
    self.mColourRangeStart = {startR, startG, startB, startA}
    self.mColourRangeEnd = {endR, endG, endB, endA}
end

function Emitter:getParticleColour()
    return self.mColourRangeStart, self.mColourRangeEnd
end

function Emitter:getName()
    return self.mName
end

function Emitter:setName(name)
    self.mName = name
end

function Emitter:getEmittedEmitter()
    return self.mEmittedEmitter
end

function Emitter:setEmittedEmitter(name)
    self.mEmittedEmitter = name
end

function Emitter:isEmitted()
    return self.mEmitted
end

function Emitter:setEmitted(emitted)
    self.mEmitted = emitted
end

function Emitter:_getEmissionCount(timeElapsed)
    debugEcho("Emitter:getEmissionCount:not implement!!!!!")
end

function Emitter:_initParticle(particle)
    particle:resetDimensions()
end

function Emitter:setEnabled(enabled)
    self.mEnabled = enabled
    self:initDurationRepeat()
end

function Emitter:getEnabled()
    return self.mEnabled
end

function Emitter:setStartTime(startTime)
    self:setEnabled(false)
    self.mStartTime = startTime
end

function Emitter:getStartTime()
    return self.mStartTime
end

function Emitter:setDuration(minDuration, maxDuration)
    self.mDurationMin = minDuration
    self.mDurationMax = maxDuration
    self:initDurationRepeat()
end

function Emitter:getDuration()
    return self.mDurationMin, self.mDurationMax
end

function Emitter:initDurationRepeat()
    if self.mEnabled then
        if self.mDurationMin == self.mDurationMax then
            self.mDurationRemain = self.mDurationMin
        else
            self.mDurationRemain = self.mDurationMin + math.random() * (self.mDurationMax - self.mDurationMin)
        end
    else
        if self.mRepeatDelayMin == self.mRepeatDelayMax then
            self.mRepeatDelayRemain = self.mRepeatDelayMin
        else
            self.mRepeatDelayRemain =
                self.mRepeatDelayMin + math.random() * (self.mRepeatDelayMax - self.mRepeatDelayMin)
        end
    end
end

function Emitter:setRepeatDelay(minDuration, maxDuration)
    self.mRepeatDelayMin = minDuration
    self.mRepeatDelayMax = maxDuration
    self:initDurationRepeat()
end

function Emitter:getRepeatDelay()
    return self.mRepeatDelayMin, self.mRepeatDelayMax
end

function Emitter:genEmissionDirection(destVector)
    local ret
    if self.mAngle ~= 0 then
        local angle = math.random() * self.mAngle
        ret = self.mParticleDirection:randomDeviant(angle, self.mUp)
    else
        ret = self.mParticleDirection
    end
    destVector[1] = ret[1]
    destVector[2] = ret[2]
    destVector[3] = ret[3]
    debugEcho("Emitter:genEmissionDirection:destVector:")
    debugEcho(destVector, true)
end

function Emitter:genEmissionVelocity(destVector)
    local scalar
    if self.mMinSpeed ~= self.mMaxSpeed then
        scalar = self.mMinSpeed + math.random() * (self.mMaxSpeed - self.mMinSpeed)
    else
        scalar = self.mMinSpeed
    end
    local ret = destVector * scalar
    destVector[1] = ret[1]
    destVector[2] = ret[2]
    destVector[3] = ret[3]
    debugEcho("Emitter:genEmissionVelocity:destVector:")
    debugEcho(destVector, true)
end

function Emitter:genEmissionTTL()
    local ret
    if self.mMinTTL ~= self.mMaxTTL then
        ret = self.mMinTTL + math.random() * (self.mMaxTTL - self.mMinTTL)
    else
        ret = self.mMinTTL
    end
    debugEcho("Emitter:genEmissionTTL:ret:" .. tostring(ret))
    return ret
end

function Emitter:genConstantEmissionCount(timeElapsed)
    debugEcho("Emitter:genConstantEmissionCount:self:")
    debugEcho(self, true)
    if self.mEnabled then
        self.mRemainder = self.mRemainder + self.mEmissionRate * timeElapsed
        local intRequest = math.floor(self.mRemainder)
        self.mRemainder = self.mRemainder - intRequest
        if self.mDurationMax ~= 0 then
            self.mDurationRemain = self.mDurationRemain - timeElapsed
            if self.mDurationRemain <= 0 then
                self:setEnabled(false)
            end
        end
        return intRequest
    else
        if self.mRepeatDelayMax ~= 0 then
            self.mRepeatDelayRemain = self.mRepeatDelayRemain - timeElapsed
            if self.mRepeatDelayRemain <= 0 then
                self:setEnabled(true)
            end
        end
        if self.mStartTime ~= 0 then
            self.mStartTime = self.mStartTime - timeElapsed
            if self.mStartTime <= 0 then
                self:setEnabled(true)
                self.mStartTime = 0
            end
        end
        return 0
    end
end

function Emitter:genEmissionColour(destColour)
    if
        self.mColourRangeStart[1] ~= self.mColourRangeEnd[1] or self.mColourRangeStart[2] ~= self.mColourRangeEnd[2] or
            self.mColourRangeStart[3] ~= self.mColourRangeEnd[3] or
            self.mColourRangeStart[4] ~= self.mColourRangeEnd[4]
     then
        destColour[1] =
            self.mColourRangeStart[1] + math.random() * (self.mColourRangeEnd[1] - self.mColourRangeStart[1])
        destColour[2] =
            self.mColourRangeStart[2] + math.random() * (self.mColourRangeEnd[2] - self.mColourRangeStart[2])
        destColour[3] =
            self.mColourRangeStart[3] + math.random() * (self.mColourRangeEnd[3] - self.mColourRangeStart[3])
        destColour[4] =
            self.mColourRangeStart[4] + math.random() * (self.mColourRangeEnd[4] - self.mColourRangeStart[4])
    else
        destColour[1] = self.mColourRangeStart[1]
        destColour[2] = self.mColourRangeStart[2]
        destColour[3] = self.mColourRangeStart[3]
        destColour[4] = self.mColourRangeStart[4]
    end
end
