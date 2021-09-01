NPL.load("(gl)script/Truck/Game/ParticleSystem/ParticleScene.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua")
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser")
local Scene = commonlib.gettable("Truck.Game.ParticleSystem.Scene")
local function debugEcho(text, pure)
  if pure then
    echo("devilwalk", text)
  else
    echo("devilwalk", "devilwalk------------------------------debug:ParticleSystem.lua:" .. text)
  end
end
local function _checkParameterNotNil(func, name, value)
  if not value then
    debugEcho("devilwalk----------------------ParticleSystem:error:" .. func .. ":" .. name .. " is error!!!")
  end
end

local System = NPL.export();
function System.singleton()
  if not System.mInitialized then
    System.mScenes = {}
    System.mTimer =
      commonlib.Timer:new(
      {
        callbackFunc = function(timer)
          System.frameMove(timer)
        end
      }
    )
    System.mTimer:Change(0, 0)
    System.mTickTimer = commonlib.Timer:new()
    System.mTickTimer:Tick()
    System.mInitialized = true
  end
  return System
end

function System.shutdown()
  System.mTimer:Change()
  for _, scene in pairs(System.mScenes) do
    scene:delete()
  end
  if System.mEmitters then
    for _, emitter in pairs(System.mEmitters) do
      emitter:delete()
    end
  end
  if System.mAffectors then
    for _, affector in pairs(System.mAffectors) do
      affector:delete()
    end
  end
  System.mScenes = {}
  System.mEmitters = nil
  System.mAffectors = nil
  System.mInitialized = false
end

function System.createScene(name, x, y, z, life)
  System.mScenes = System.mScenes or {}
  if System.mScenes[name] then
    System.mScenes[name]:delete()
  end
  local ret = Scene:new({mName = name, mX = x, mY = y, mZ = z, mLife = life})
  System.mScenes[name] = ret
  return ret
end
--[[{quota=1,emit_emitter_quota=1,particle_width=1,particle_height=1,texture="",texture_resource=1,billboard_type="point",billboard_rotation_type="vertex",common_direction={1,0,0},common_up_vector={1,0,0},point_rendering=true,accurate_facing=true,
emitter_1={type="Point",angle=30,colour_range_start={0,0,0,0},colour_range_end={0,0,0,0},direction={1,0,0},up={1,0,0},emission_rate=100,position={0,0,0},velocity_min=1,velocity_max=1,time_to_live_min=1,time_to_live_max=1,duration_min=1,duration_max=1,repeat_delay_min=1,repeat_delay_max=1,name="test",emit_emitter=true,width=1,height=1,depth=1,inner_width=1,inner_height=1,inner_depth=1},
affector_1={type="LinearForce",}
}]]
function System.createSceneFromTable(t, name, x, y, z, life)
  local ret = System.createScene(name, x, y, z, life)
  if t.quota then
    ret:setParticleQuota(tonumber(t.quota))
  end
  if t.emit_emitter_quota then
    ret:getEmittedEmitterQuota(tonumber(t.emit_emitter_quota))
  end
  if t.particle_width then
    local _, height = ret:getDefaultDimensions()
    ret:setDefaultDimensions(tonumber(t.particle_width), height)
  end
  if t.particle_height then
    local width, _ = ret:getDefaultDimensions()
    ret:setDefaultDimensions(width, tonumber(t.particle_height))
  end
  if t.texture then
    ret:setTexture(t.texture)
  end
  if t.texture_resource then
    ret:setTextureResource(t.texture_resource)
  end
  if t.billboard_type then
    ret:setBillboardType(t.billboard_type)
  end
  if t.billboard_rotation_type then
    ret:setBillboardRotationType(t.billboard_rotation_type)
  end
  if t.common_direction then
    ret:setCommonDirection(t.common_direction[1], t.common_direction[2], t.common_direction[3])
  end
  if t.common_up_vector then
    ret:setCommonUp(t.common_up_vector[1], t.common_up_vector[2], t.common_up_vector[3])
  end
  if t.point_rendering then
    ret:setPointRenderingEnabled(t.point_rendering)
  end
  if t.accurate_facing then
    ret:setUseAccurateFacing(t.accurate_facing)
  end

  for key, e in pairs(t) do
    if string.find(key, "emitter_") then
      local emitter = ret:addEmitter(e.type)
      if e.angle then
        emitter:setAngle(tonumber(e.angle) / 180 * 3.1415926)
      end
      if e.colour_range_start then
        local _, end_colour = emitter:getParticleColour()
        emitter:setParticleColour(
          e.colour_range_start[1],
          e.colour_range_start[2],
          e.colour_range_start[3],
          e.colour_range_start[4],
          end_colour[1],
          end_colour[2],
          end_colour[3],
          end_colour[4]
        )
      end
      if e.colour_range_end then
        local start_colour, _ = emitter:getParticleColour()
        emitter:setParticleColour(
          start_colour[1],
          start_colour[2],
          start_colour[3],
          start_colour[4],
          e.colour_range_end[1],
          e.colour_range_end[2],
          e.colour_range_end[3],
          e.colour_range_end[4]
        )
      end
      if e.direction then
        emitter:setParticleDirection(e.direction[1], e.direction[2], e.direction[3])
      end
      if e.up then
        emitter:setUp(e.up[1], e.up[2], e.up[3])
      end
      if e.emission_rate then
        emitter:setEmissionRate(tonumber(e.emission_rate))
      end
      if e.position then
        emitter:setPosition(e.position[1], e.position[2], e.position[3])
      end
      if e.velocity_min then
        local _, max_value = emitter:getParticleVelocity()
        emitter:setParticleVelocity(tonumber(e.velocity_min), max_value)
      end
      if e.velocity_max then
        local min_value, _ = emitter:getParticleVelocity()
        emitter:setParticleVelocity(min_value, tonumber(e.velocity_max))
      end
      if e.time_to_live_min then
        local _, max_value = emitter:getParticleTimeToLive()
        emitter:setParticleTimeToLive(tonumber(e.time_to_live_min), max_value)
      end
      if e.time_to_live_max then
        local min_value, _ = emitter:getParticleTimeToLive()
        emitter:setParticleTimeToLive(min_value, tonumber(e.time_to_live_max))
      end
      if e.duration_min then
        local _, max_value = emitter:getDuration()
        emitter:setDuration(tonumber(e.duration_min), max_value)
      end
      if e.duration_max then
        local min_value, _ = emitter:getDuration()
        emitter:setDuration(min_value, tonumber(e.duration_max))
      end
      if e.repeat_delay_min then
        local _, max_value = emitter:getRepeatDelay()
        emitter:setRepeatDelay(tonumber(e.repeat_delay_min), max_value)
      end
      if e.repeat_delay_max then
        local min_value, _ = emitter:getRepeatDelay()
        emitter:setRepeatDelay(min_value, tonumber(e.repeat_delay_max))
      end
      if e.name then
        emitter:setName(e.name)
      end
      if e.emit_emitter then
        emitter:setEmittedEmitter(e.emit_emitter)
      end

      if e.width then
        local size = emitter:getSize()
        emitter:setSize(tonumber(e.width), size[2], size[3])
      end
      if e.height then
        local size = emitter:getSize()
        emitter:setSize(size[1], tonumber(e.height), size[3])
      end
      if e.depth then
        local size = emitter:getSize()
        emitter:setSize(size[1], size[2], tonumber(e.depth))
      end

      if e.inner_width then
        local size = emitter:getInnerSize()
        emitter:setInnerSize(tonumber(e.inner_width), size[2], size[3])
      end
      if e.inner_height then
        local size = emitter:getInnerSize()
        emitter:setInnerSize(size[1], tonumber(e.inner_height), size[3])
      end
      if e.inner_depth then
        local size = emitter:getInnerSize()
        emitter:setInnerSize(size[1], size[2], tonumber(e.inner_depth))
      end
    end
  end

  for key, e in pairs(t) do
    if string.find(key, "affector_") then
      local affector = ret:addAffector(e.type)
      if e.red then
        local r, g, b, a = affector:getAdjust()
        r = tonumber(e.red)
        affector:setAdjust(r, g, b, a)
      end
      if e.green then
        local r, g, b, a = affector:getAdjust()
        g = tonumber(e.green)
        affector:setAdjust(r, g, b, a)
      end
      if e.blue then
        local r, g, b, a = affector:getAdjust()
        b = tonumber(e.blue)
        affector:setAdjust(r, g, b, a)
      end
      if e.alpha then
        local r, g, b, a = affector:getAdjust()
        a = tonumber(e.alpha)
        affector:setAdjust(r, g, b, a)
      end

      if e.red1 then
        local r, g, b, a = affector:getAdjust1()
        r = tonumber(e.red1)
        affector:setAdjust1(r, g, b, a)
      end
      if e.green1 then
        local r, g, b, a = affector:getAdjust1()
        g = tonumber(e.green1)
        affector:setAdjust1(r, g, b, a)
      end
      if e.blue1 then
        local r, g, b, a = affector:getAdjust1()
        b = tonumber(e.blue1)
        affector:setAdjust1(r, g, b, a)
      end
      if e.alpha1 then
        local r, g, b, a = affector:getAdjust1()
        a = tonumber(e.alpha1)
        affector:setAdjust1(r, g, b, a)
      end
      if e.red2 then
        local r, g, b, a = affector:getAdjust2()
        r = tonumber(e.red2)
        affector:setAdjust2(r, g, b, a)
      end
      if e.green2 then
        local r, g, b, a = affector:getAdjust2()
        g = tonumber(e.green2)
        affector:setAdjust2(r, g, b, a)
      end
      if e.blue2 then
        local r, g, b, a = affector:getAdjust2()
        b = tonumber(e.blue2)
        affector:setAdjust2(r, g, b, a)
      end
      if e.alpha2 then
        local r, g, b, a = affector:getAdjust2()
        a = tonumber(e.alpha2)
        affector:setAdjust2(r, g, b, a)
      end

      if e.image then
        affector:setImageAdjust(e.image)
      end

      for i = 0, 5 do
        if e["colour" .. tostring(i)] then
          affector:setColourAdjust(
            i + 1,
            e["colour" .. tostring(i)][1],
            e["colour" .. tostring(i)][2],
            e["colour" .. tostring(i)][3],
            e["colour" .. tostring(i)][4]
          )
        end
        if e["time" .. tostring(i)] then
          affector:setTimeAdjust(i + 1, tonumber(e["time" .. tostring(i)]))
        end
      end

      if e.plane_point then
        affector:setPlanePoint(e.plane_point[1], e.plane_point[2], e.plane_point[3])
      end
      if e.plane_normal then
        affector:setPlaneNormal(e.plane_normal[1], e.plane_normal[2], e.plane_normal[3])
      end
      if e.bounce then
        affector:setBounce(tonumber(e.bounce))
      end

      if e.randomness then
        affector:setRandomness(tonumber(e.randomness))
      end
      if e.scope then
        affector:setScope(tonumber(e.scope))
      end
      if e.keep_velocity then
        affector:setKeepVelocity(tonumber(e.keep_velocity))
      end

      if e.force_vector then
        affector:setForceVector(e.force_vector[1], e.force_vector[2], e.force_vector[3])
      end
      if e.force_application then
        affector:setForceApplication(tonumber(e.force_application))
      end

      if e.rotation_speed_range_start then
        local start_value, end_value = affector:getRotationSpeedRange()
        start_value = tonumber(e.rotation_speed_range_start)
        affector:setRotationSpeedRange(start_value, end_value)
      end
      if e.rotation_speed_range_end then
        local start_value, end_value = affector:getRotationSpeedRange()
        end_value = tonumber(e.rotation_speed_range_end)
        affector:setRotationSpeedRange(start_value, end_value)
      end
      if e.rotation_range_start then
        local start_value, end_value = affector:getRotationRange()
        start_value = tonumber(e.rotation_range_start)
        affector:setRotationRange(start_value, end_value)
      end
      if e.rotation_range_end then
        local start_value, end_value = affector:getRotationRange()
        end_value = tonumber(e.rotation_range_end)
        affector:setRotationRange(start_value, end_value)
      end

      if e.rate then
        affector:setAdjust(tonumber(e.rate))
      end
    end
  end

  return ret
end

function System.createSceneScript(xmlNode, name, x, y, z, life)
  name = name or xmlNode.attr.name
  if not life and xmlNode.attr.life then
    life = tonumber(xmlNode.attr.life)
  end
  local ret = System.createScene(name, x, y, z, life)
  if xmlNode.attr.quota then
    ret:setParticleQuota(tonumber(xmlNode.attr.quota))
  end
  if xmlNode.attr.emit_emitter_quota then
    ret:getEmittedEmitterQuota(tonumber(xmlNode.attr.emit_emitter_quota))
  end
  if xmlNode.attr.particle_width then
    local _, height = ret:getDefaultDimensions()
    ret:setDefaultDimensions(tonumber(xmlNode.attr.particle_width), height)
  end
  if xmlNode.attr.particle_height then
    local width, _ = ret:getDefaultDimensions()
    ret:setDefaultDimensions(width, tonumber(xmlNode.attr.particle_height))
  end
  if xmlNode.attr.texture then
    ret:setTexture(xmlNode.attr.texture)
  end
  if xmlNode.attr.billboard_type then
    ret:setBillboardType(xmlNode.attr.billboard_type)
  end
  if xmlNode.attr.billboard_rotation_type then
    ret:setBillboardRotationType(xmlNode.attr.billboard_rotation_type)
  end
  if xmlNode.attr.common_direction then
    local x, y, z, remain
    x, remain = CmdParser.ParseNumber(xmlNode.attr.common_direction)
    y, remain = CmdParser.ParseNumber(remain)
    z, remain = CmdParser.ParseNumber(remain)
    ret:setCommonDirection(x, y, z)
  end
  if xmlNode.attr.common_up_vector then
    local x, y, z, remain
    x, remain = CmdParser.ParseNumber(xmlNode.attr.common_up_vector)
    y, remain = CmdParser.ParseNumber(remain)
    z, remain = CmdParser.ParseNumber(remain)
    ret:setCommonUp(x, y, z)
  end
  if xmlNode.attr.point_rendering then
    ret:setPointRenderingEnabled(xmlNode.attr.point_rendering == "true")
  end
  if xmlNode.attr.accurate_facing then
    ret:setUseAccurateFacing(xmlNode.attr.accurate_facing == "true")
  end

  for emitter_node in commonlib.XPath.eachNode(xmlNode, "/emitter") do
    local emitter = ret:addEmitter(emitter_node.attr.type)
    if emitter_node.attr.angle then
      emitter:setAngle(tonumber(emitter_node.attr.angle) / 180 * 3.1415926)
    end
    if emitter_node.attr.colour then
      local r, g, b, a, remain
      r, remain = CmdParser.ParseNumber(emitter_node.attr.colour)
      g, remain = CmdParser.ParseNumber(remain)
      b, remain = CmdParser.ParseNumber(remain)
      if remain then
        a, remain = CmdParser.ParseNumber(remain)
      else
        a = 1
      end
      emitter:setColour(r, g, b, a, r, g, b, a)
    end
    if emitter_node.attr.colour_range_start then
      local r, g, b, a, remain
      r, remain = CmdParser.ParseNumber(emitter_node.attr.colour_range_start)
      g, remain = CmdParser.ParseNumber(remain)
      b, remain = CmdParser.ParseNumber(remain)
      if remain then
        a, remain = CmdParser.ParseNumber(remain)
      else
        a = 1
      end
      local _, end_colour = emitter:getColour()
      emitter:setColour(r, g, b, a, end_colour[1], end_colour[2], end_colour[3], end_colour[4])
    end
    if emitter_node.attr.colour_range_end then
      local r, g, b, a, remain
      r, remain = CmdParser.ParseNumber(emitter_node.attr.colour_range_end)
      g, remain = CmdParser.ParseNumber(remain)
      b, remain = CmdParser.ParseNumber(remain)
      if remain then
        a, remain = CmdParser.ParseNumber(remain)
      else
        a = 1
      end
      local start_colour, _ = emitter:getColour()
      emitter:setColour(start_colour[1], start_colour[2], start_colour[3], start_colour[4], r, g, b, a)
    end
    if emitter_node.attr.direction then
      local x, y, z, remain
      x, remain = CmdParser.ParseNumber(emitter_node.attr.direction)
      y, remain = CmdParser.ParseNumber(remain)
      z, remain = CmdParser.ParseNumber(remain)
      emitter:setParticleDirection(x, y, z)
    end
    if emitter_node.attr.up then
      local x, y, z, remain
      x, remain = CmdParser.ParseNumber(emitter_node.attr.up)
      y, remain = CmdParser.ParseNumber(remain)
      z, remain = CmdParser.ParseNumber(remain)
      emitter:setUp(x, y, z)
    end
    if emitter_node.attr.emission_rate then
      emitter:setEmissionRate(tonumber(emitter_node.attr.emission_rate))
    end
    if emitter_node.attr.position then
      local x, y, z, remain
      x, remain = CmdParser.ParseNumber(emitter_node.attr.position)
      y, remain = CmdParser.ParseNumber(remain)
      z, remain = CmdParser.ParseNumber(remain)
      emitter:setPosition(x, y, z)
    end
    if emitter_node.attr.velocity then
      emitter:setParticleVelocity(tonumber(emitter_node.attr.velocity), tonumber(emitter_node.attr.velocity))
    end
    if emitter_node.attr.velocity_min then
      local _, max_value = emitter:getParticleVelocity()
      emitter:setParticleVelocity(tonumber(emitter_node.attr.velocity_min), max_value)
    end
    if emitter_node.attr.velocity_max then
      local min_value, _ = emitter:getParticleVelocity()
      emitter:setParticleVelocity(min_value, tonumber(emitter_node.attr.velocity_max))
    end
    if emitter_node.attr.time_to_live then
      emitter:setTimeToLive(tonumber(emitter_node.attr.time_to_live), tonumber(emitter_node.attr.time_to_live))
    end
    if emitter_node.attr.time_to_live_min then
      local _, max_value = emitter:getTimeToLive()
      emitter:setTimeToLive(tonumber(emitter_node.attr.time_to_live_min), max_value)
    end
    if emitter_node.attr.time_to_live_max then
      local min_value, _ = emitter:getTimeToLive()
      emitter:setTimeToLive(min_value, tonumber(emitter_node.attr.time_to_live_max))
    end
    if emitter_node.attr.duration then
      emitter:setDuration(tonumber(emitter_node.attr.duration), tonumber(emitter_node.attr.duration))
    end
    if emitter_node.attr.duration_min then
      local _, max_value = emitter:getDuration()
      emitter:setDuration(tonumber(emitter_node.attr.duration_min), max_value)
    end
    if emitter_node.attr.duration_max then
      local min_value, _ = emitter:getDuration()
      emitter:setDuration(min_value, tonumber(emitter_node.attr.duration_max))
    end
    if emitter_node.attr.repeat_delay then
      emitter:setRepeatDelay(tonumber(emitter_node.attr.repeat_delay), tonumber(emitter_node.attr.repeat_delay))
    end
    if emitter_node.attr.repeat_delay_min then
      local _, max_value = emitter:getRepeatDelay()
      emitter:setRepeatDelay(tonumber(emitter_node.attr.repeat_delay_min), max_value)
    end
    if emitter_node.attr.repeat_delay_max then
      local min_value, _ = emitter:getRepeatDelay()
      emitter:setRepeatDelay(min_value, tonumber(emitter_node.attr.repeat_delay_max))
    end
    if emitter_node.attr.name then
      emitter:setName(emitter_node.attr.name)
    end
    if emitter_node.attr.emit_emitter then
      emitter:setEmittedEmitter(emitter_node.attr.emit_emitter)
    end

    if emitter_node.attr.width then
      local size = emitter:getSize()
      emitter:setSize(tonumber(emitter_node.attr.width), size[2], size[3])
    end
    if emitter_node.attr.height then
      local size = emitter:getSize()
      emitter:setSize(size[1], tonumber(emitter_node.attr.height), size[3])
    end
    if emitter_node.attr.depth then
      local size = emitter:getSize()
      emitter:setSize(size[1], size[2], tonumber(emitter_node.attr.depth))
    end

    if emitter_node.attr.inner_width then
      local size = emitter:getInnerSize()
      emitter:setInnerSize(tonumber(emitter_node.attr.inner_width), size[2], size[3])
    end
    if emitter_node.attr.inner_height then
      local size = emitter:getInnerSize()
      emitter:setInnerSize(size[1], tonumber(emitter_node.attr.inner_height), size[3])
    end
    if emitter_node.attr.inner_depth then
      local size = emitter:getInnerSize()
      emitter:setInnerSize(size[1], size[2], tonumber(emitter_node.attr.inner_depth))
    end
  end

  for affector_node in commonlib.XPath.eachNode(xmlNode, "/affector") do
    local affector = ret:addAffector(affector_node.attr.type)
    if affector_node.attr.red then
      local r, g, b, a = affector:getAdjust()
      r = tonumber(affector_node.attr.red)
      affector:setAdjust(r, g, b, a)
    end
    if affector_node.attr.green then
      local r, g, b, a = affector:getAdjust()
      g = tonumber(affector_node.attr.green)
      affector:setAdjust(r, g, b, a)
    end
    if affector_node.attr.blue then
      local r, g, b, a = affector:getAdjust()
      b = tonumber(affector_node.attr.blue)
      affector:setAdjust(r, g, b, a)
    end
    if affector_node.attr.alpha then
      local r, g, b, a = affector:getAdjust()
      a = tonumber(affector_node.attr.alpha)
      affector:setAdjust(r, g, b, a)
    end

    if affector_node.attr.red1 then
      local r, g, b, a = affector:getAdjust1()
      r = tonumber(affector_node.attr.red1)
      affector:setAdjust1(r, g, b, a)
    end
    if affector_node.attr.green1 then
      local r, g, b, a = affector:getAdjust1()
      g = tonumber(affector_node.attr.green1)
      affector:setAdjust1(r, g, b, a)
    end
    if affector_node.attr.blue1 then
      local r, g, b, a = affector:getAdjust1()
      b = tonumber(affector_node.attr.blue1)
      affector:setAdjust1(r, g, b, a)
    end
    if affector_node.attr.alpha1 then
      local r, g, b, a = affector:getAdjust1()
      a = tonumber(affector_node.attr.alpha1)
      affector:setAdjust1(r, g, b, a)
    end
    if affector_node.attr.red2 then
      local r, g, b, a = affector:getAdjust2()
      r = tonumber(affector_node.attr.red2)
      affector:setAdjust2(r, g, b, a)
    end
    if affector_node.attr.green2 then
      local r, g, b, a = affector:getAdjust2()
      g = tonumber(affector_node.attr.green2)
      affector:setAdjust2(r, g, b, a)
    end
    if affector_node.attr.blue2 then
      local r, g, b, a = affector:getAdjust2()
      b = tonumber(affector_node.attr.blue2)
      affector:setAdjust2(r, g, b, a)
    end
    if affector_node.attr.alpha2 then
      local r, g, b, a = affector:getAdjust2()
      a = tonumber(affector_node.attr.alpha2)
      affector:setAdjust2(r, g, b, a)
    end

    if affector_node.attr.image then
      affector:setImageAdjust(affector_node.attr.image)
    end

    for i = 0, 5 do
      if affector_node.attr["colour" .. tostring(i)] then
        local r, g, b, a, remain
        r, remain = CmdParser.ParseNumber(affector_node.attr["colour" .. tostring(i)])
        g, remain = CmdParser.ParseNumber(remain)
        b, remain = CmdParser.ParseNumber(remain)
        if remain then
          a, remain = CmdParser.ParseNumber(remain)
        else
          a = 1
        end
        affector:setColourAdjust(i + 1, r, g, b, a)
      end
      if affector_node.attr["time" .. tostring(i)] then
        affector:setTimeAdjust(i + 1, tonumber(affector_node.attr["time" .. tostring(i)]))
      end
    end

    if affector_node.attr.plane_point then
      local x, y, z, remain
      x, remain = CmdParser.ParseNumber(affector_node.attr.plane_point)
      y, remain = CmdParser.ParseNumber(remain)
      z, remain = CmdParser.ParseNumber(remain)
      affector:setPlanePoint(x, y, z)
    end
    if affector_node.attr.plane_normal then
      local x, y, z, remain
      x, remain = CmdParser.ParseNumber(affector_node.attr.plane_normal)
      y, remain = CmdParser.ParseNumber(remain)
      z, remain = CmdParser.ParseNumber(remain)
      affector:setPlaneNormal(x, y, z)
    end
    if affector_node.attr.bounce then
      affector:setBounce(tonumber(affector_node.attr.bounce))
    end

    if affector_node.attr.randomness then
      affector:setRandomness(tonumber(affector_node.attr.randomness))
    end
    if affector_node.attr.scope then
      affector:setScope(tonumber(affector_node.attr.scope))
    end
    if affector_node.attr.keep_velocity then
      affector:setKeepVelocity(tonumber(affector_node.attr.keep_velocity))
    end

    if affector_node.attr.force_vector then
      local x, y, z, remain
      x, remain = CmdParser.ParseNumber(affector_node.attr.force_vector)
      y, remain = CmdParser.ParseNumber(remain)
      z, remain = CmdParser.ParseNumber(remain)
      affector:setForceVector(x, y, z)
    end
    if affector_node.attr.force_application then
      affector:setForceApplication(tonumber(affector_node.attr.force_application))
    end

    if affector_node.attr.rotation_speed_range_start then
      local start_value, end_value = affector:getRotationSpeedRange()
      start_value = tonumber(affector_node.attr.rotation_speed_range_start)
      affector:setRotationSpeedRange(start_value, end_value)
    end
    if affector_node.attr.rotation_speed_range_end then
      local start_value, end_value = affector:getRotationSpeedRange()
      end_value = tonumber(affector_node.attr.rotation_speed_range_end)
      affector:setRotationSpeedRange(start_value, end_value)
    end
    if affector_node.attr.rotation_range_start then
      local start_value, end_value = affector:getRotationRange()
      start_value = tonumber(affector_node.attr.rotation_range_start)
      affector:setRotationRange(start_value, end_value)
    end
    if affector_node.attr.rotation_range_end then
      local start_value, end_value = affector:getRotationRange()
      end_value = tonumber(affector_node.attr.rotation_range_end)
      affector:setRotationRange(start_value, end_value)
    end

    if affector_node.attr.rate then
      affector:setAdjust(tonumber(affector_node.attr.rate))
    end
  end

  return ret
end

function System.destroyScene(scene)
  local name = scene.mName
  scene:delete()
  System.mScenes[name] = nil
end

function System.createEmitter(emitterType, scene)
  local ret = System.mEmitterFactories[emitterType].create(scene)
  System.mEmitters = System.mEmitters or {}
  System.mEmitters[#System.mEmitters + 1] = ret
  return ret
end

function System.destroyEmitter(emitter)
  if System.mEmitters then
    for key, value in pairs(System.mEmitters) do
      if value == emitter then
        emitter:delete()
        table.remove(System.mEmitters, key)
        break
      end
    end
  end
end

function System.createAffector(affectorType, scene)
  local ret = System.mAffectorFactories[affectorType].create(scene)
  System.mAffectors = System.mAffectors or {}
  System.mAffectors[#System.mAffectors + 1] = ret
  return ret
end

function System.destroyAffector(affector)
  if System.mAffectors then
    for key, value in pairs(System.mAffectors) do
      if value == affector then
        affector:delete()
        table.remove(System.mAffectors, key)
        break
      end
    end
  end
end

function System.frameMove(timer)
  System.mTickTimer:Tick()
  local delta = System.mTickTimer:GetDelta() * 0.001
  for _, scene in pairs(System.mScenes) do
    scene:_update(delta)
  end
end

function System.addEmitterFactory(emitterType, factory)
  System.mEmitterFactories = System.mEmitterFactories or {}
  System.mEmitterFactories[emitterType] = factory
end

function System.addAffectorFactory(affectorType, factory)
  System.mAffectorFactories = System.mAffectorFactories or {}
  System.mAffectorFactories[affectorType] = factory
end

System.singleton()
