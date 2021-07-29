local camera_ = camera;
camera = gettable("game.camera")
hide()
turnTo(-90)

local cameraYOffset = 30;
local x, y, z, elevation;
local hasFocus = false;

registerCloneEvent(function(name)
    hide()
    setActorValue("name", name)
end)
clone("myself", "bottomLeftPos")
clone("myself", "topLeftPos")
clone("myself", "topRightPos")
clone("myself", "bottomRightPos")

function camera.setCamera(dist, angle, facing)
    camera_(dist, angle, facing);
end

-- @param x_, y_: in relative coordinate
function camera.Lookat(x_, y_, duration)
    local min = game.minPos
    local max = game.maxPos
    local width, height = max[1] - min[1], max[3] - min[3]
    elevation = max[2];
    local cx = min[1] +x_;
    local cz =  min[3] + y_;
    local cy = elevation;
    x, y, z = cx, cy+cameraYOffset, cz-height*0.7
    if(not duration or duration==0) then
        moveTo(x, y, z)
    else
        runForActor("myself", function()
            local sx, sy, sz = getPos()
            move(x-sx, y-sy, z-sz, duration or 1)
        end)
    end
end

function camera.Reset()
    --hide()
    local min = game.minPos
    local max = game.maxPos
    local width, height = max[1] - min[1], max[3] - min[3]
    camera.Lookat(width/2, height/2)
    camera.setCamera(12, 45, -90)
    cmd("/renderdist 200")
    cmd("/fog 150")
    cmd("/lod off")
    cmd("/fov")
    cmd("/property -scene MinPopUpDistance 160")
    cmd("/hide player")
    cmd("/togglefly @a on")
    cmd("/addrule Player PickingDist 150")
    cmd("/clearbag")
    if(game.isDev) then
        camera.showRegionBoarder()    
    end
end

function camera.showRegionBoarder()
    local min = game.minPos
    local max = game.maxPos
    run(function()
        wait(1)
        runForActor("bottomLeftPos", function()
            show()
            moveTo(min[1], min[2]+1, min[3])
            turnTo(-45)
        end)
        runForActor("topRightPos", function()
            show()
            moveTo(max[1], max[2]+1, max[3])
            turnTo(180-45)
        end)
        runForActor("topLeftPos", function()
            show()
            moveTo(min[1], min[2]+1, max[3])
            turnTo(45)
        end)
        runForActor("bottomRightPos", function()
            show()
            moveTo(max[1], max[2]+1, min[3])
            turnTo(-180+45)
        end)
    end)    
end

function camera.SetFocus()
    becomeAgent("@p")
    camera.Reset()
    hasFocus = true;
    cmd("/mode game")
    cmd("/clearbag")
    cmd("/hide desktop") 
    GameLogic.GameMode:SetViewMode(false);
end

function camera.RestoreFocus()
    camera.setCamera(12, 45, -90)
    game.levelhelper.goHome()
    cmd("/clearbag")
    cmd("/fov")
    cmd("/show player")
    cmd("/togglefly @a off")
    if(not GameLogic.IsReadOnly()) then
        cmd("/mode edit")
    end
    cmd("/show desktop")
    hasFocus = false;
end


function camera.ZoomXY(x, y, duration)
    becomeAgent("@p")
    local x, y, z = game.xyToGlobal(x, y)
    local sx, sy, sz = getPos()
    move(x-sx, y-sy, z-sz, duration or 1)
end

function camera.ZoomIn()
    becomeAgent("@p")
    local x, y, z = getPos()
    y = math.max(y - elevation, 10) * 0.8 + elevation
    setPos(x, y, z)
end

-- @param distance: should be larger than 8
function camera.Zoom(distance)
    becomeAgent("@p")
    local x, y, z = getPos()
    y = math.max(distance, 8) + elevation
    setPos(x, y, z)
end

function camera.ZoomOut()
    becomeAgent("@p")
    local x, y, z = getPos()
    y = math.max(10, math.min(y - elevation, cameraYOffset) * 1.2) + elevation
    setPos(x, y, z)    
end

function camera.ToStandardView(duration)
    local min = game.minPos
    local max = game.maxPos
    local width, height = max[1] - min[1], max[3] - min[3]
    camera.Lookat(width/2, height/2, duration)
    camera.setCamera(12, 45, -90)
end

function camera.moveToMouseCursor()
    local x, y, z, blockid = mousePickBlock()
    if(x and z) then
        becomeAgent("@p")
        local sx, sy, sz = getPos()
        move(x-sx, y+1-sy, z-sz, 0.5)
    end
end

-- public method: 
function camera.moveTo(x, z, duration)
    if(x and z) then
        local x, y, z = game.xyToGlobal(x, z)
        if(x) then
            runForActor("myself", function()
                becomeAgent("@p")
                local sx, sy, sz = getPos()
                move(x-sx, y+1-sy, z-sz, duration or 0.5)
            end)
        end
    end
end

registerKeyPressedEvent("e", function(msg)
    -- disable e key
end)
registerKeyPressedEvent("b", function(msg)
    -- disable b key
end)


registerKeyPressedEvent("mouse_buttons", function(event)
    if(getActorValue("name") ~= "camera" or not game.getLevel()) then
        return
    end
    if(event:buttons() == 1 and event.isDoubleClick) then
        camera.moveToMouseCursor()
    end
end)

registerKeyPressedEvent("x", function(msg)
    -- x key to zoom at current cursor position
    if(getActorValue("name") ~= "camera" or not game.getLevel()) then
        return
    end
    camera.ToStandardView()
end)
