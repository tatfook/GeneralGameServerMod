local UI = require("UI");

local player = GetPlayer()

local x
local y

local passThrough
local uiWindow
local lifeUi
local pointUi
local point

local map = {
    [1] = {x1 = 19188, y1 = 31, z1 = 19246, x2 = 19212, y2 = 9, z2 = 19246},
    [2] = {x1 = 19188, y1 = 31, z1 = 19262, x2 = 19212, y2 = 9, z2 = 19262},
    [3] = {x1 = 19188, y1 = 31, z1 = 19284, x2 = 19212, y2 = 9, z2 = 19284},
    [4] = {x1 = 19188, y1 = 31, z1 = 19305, x2 = 19212, y2 = 9, z2 = 19305},
    [5] = {x1 = 19188, y1 = 31, z1 = 19323, x2 = 19212, y2 = 9, z2 = 19323},
    [6] = {x1 = 19188, y1 = 31, z1 = 19345, x2 = 19212, y2 = 9, z2 = 19345}
}
local life

local maxSpeed = 80
local minSpeed = 5

local canDestroyBlock

local gaming

local speed
local controllerLength  -- 不计算中心，朝外延伸的格数（单边）

local block_good = 2101

local block_bad = 2100

local ballList = {}

local difficultyList = {
    [1] = {speed = 10, controllerLength = 4},
    [2] = {speed = 15, controllerLength = 4},
    [3] = {speed = 15, controllerLength = 3},
    [4] = {speed = 20, controllerLength = 3},
    [5] = {speed = 20, controllerLength = 2},
    [6] = {speed = 25, controllerLength = 2},
    [7] = {speed = 25, controllerLength = 1},
    [8] = {speed = 30, controllerLength = 1},
    [9] = {speed = 40, controllerLength = 1},
    [10] = {speed = 50, controllerLength = 1},
    [11] = {speed = 20, controllerLength = 0},
    [12] = {speed = 30, controllerLength = 0},
    [13] = {speed = 40, controllerLength = 0},
    [14] = {speed = 45, controllerLength = 0},
    [15] = {speed = 50, controllerLength = 0}
}
local difficulty

local board = {x1 = 19188, y1 = 31, z1 = 19228, x2 = 19212, y2 = 9, z2 = 19228}

local checked = nil

local left = 19186
local right = 19214
local top = 33

local unbreakableBlock = 97

local controllerBlockId = 174
local controllerBlockData = 0
local controllerCenter = {x = 19200, y = 5, z = 19228}

local controller = {}

local brickList = {
    [1] = {{id = 131}, {id = 2045}},
    [2] = {{id = 156}, {id = 129}},
    [3] = {{id = 2216}, {id = 92}}
}

local cameraZoom = 10

local gameIndex = 0

local goodTb = {
    {
        desc = "生成3个新的球",
        func = function()
            local verify = gameIndex
            for i = 1, 3 do
                SetTimeout(
                    300 * i,
                    function(...)
                        if gaming and verify == gameIndex then
                            local newball = createBall()
                            launchBall(newball)
                        end
                    end
                )
            end
        end
    },
    {
        desc = "减速，持续10秒",
        func = function(count)
            local verify = gameIndex
            if difficultyList[difficulty].speed - 15 > minSpeed then
                speed = difficultyList[difficulty].speed - 15
            elseif difficultyList[difficulty].speed > minSpeed then
                speed = minSpeed
            end

            SetTimeout(
                10000,
                function(...)
                    if gaming and verify == gameIndex and count == speedDownCount then
                        speed = difficultyList[difficulty].speed
                    end
                end
            )
        end
    },
    {
        desc = "挡板伸长1格，持续20秒",
        func = function()
            local verify = gameIndex
            controllerLength = controllerLength + 1
            if controllerLength > 10 then
                controllerLength = 10
            end
            setController()
            SetTimeout(
                20000,
                function()
                    if gaming and verify == gameIndex then
                        if controllerLength > 0 then
                            controllerLength = controllerLength - 1
                            setController()
                        end
                    end
                end
            )
        end
    },
    {
        desc = "可用球数+1",
        func = function()
            life = life + 1
            updateLifeUi(life)
        end
    },
    {
        desc = "穿透砖块，持续10秒",
        func = function()
            local verify = gameIndex
            passThrough = true
            SetTimeout(
                10000,
                function()
                    if gaming and verify == gameIndex then
                        passThrough = nil
                        for i = 1, #ballList do
                            ignoreCollison(ballList[i], false)
                        end
                    end
                end
            )
        end
    }
}

local badTb = {
    {
        desc = "加速，持续10秒",
        func = function(count)
            local verify = gameIndex
            if difficultyList[difficulty].speed + 15 < maxSpeed then
                speed = difficultyList[difficulty].speed + 15
            elseif difficultyList[difficulty].speed < maxSpeed then
                speed = maxSpeed
            end

            SetTimeout(
                10000,
                function(...)
                    if gaming and verify == gameIndex and count == speedUpCount then
                        speed = difficultyList[difficulty].speed
                    end
                end
            )
        end
    },
    {
        desc = "挡板缩短1格，持续10秒",
        func = function()
            if controllerLength > 1 then
                local verify = gameIndex
                controllerLength = controllerLength - 1
                setController()
                SetTimeout(
                    10000,
                    function()
                        if gaming and verify == gameIndex then
                            controllerLength = controllerLength + 1
                            setController()
                        end
                    end
                )
            end
        end
    },
    {
        desc = "无法消除砖块，持续10秒",
        func = function()
            canDestroyBlock = false
            if controllerLength > 1 then
                local verify = gameIndex
                SetTimeout(
                    10000,
                    function()
                        if gaming and verify == gameIndex then
                            canDestroyBlock = true
                        end
                    end
                )
            end
        end
    }
}

-- TODO
function SetPermission()
end

function main()
    createUi()
    testcount = 0 -- useless，just for print

    setDifficulty()
    SetPermission("edit", false)
    player:ShowHeadOnDisplay(false)
    player:SetBlockPos(19200, 14, 19215)
    cmd("/hide")
    cmd("/lookat 19200 15 19229")
    EnableAutoCamera(false)
    CameraZoomInOut(cameraZoom)
end

function createUi()
    if (true) then return end
    uiWindow = System.createWindow("uiWindow", "_ctr", 0, -100, 300, 600)
    --local background=uiWindow:createUI("Picture","background","_lt",0,0,300,600);
    --background:setBackgroundFile("gameassets_pc/textures/ui_common/messagebox.png");

    local text = uiWindow:createUI("Text", "pointUi1", "_lt", 50, 10, 180, 55)
    text:setFontSize(30)
    text:setFontColour("255 255 255")
    text:setTextFormat(0x00000001)
    text:setText("得分")
    local text = uiWindow:createUI("Text", "pointUi2", "_lt", 10, 55, 260, 50)
    text:setFontSize(50)
    text:setFontColour("255 191 0")
    text:setText("0")
    text:setTextFormat(0x00000001)
    pointUi = text

    local text = uiWindow:createUI("Text", "pointUi1", "_lt", 50, 140, 180, 55)
    text:setFontSize(30)
    text:setFontColour("255 255 255")
    text:setTextFormat(0x00000001)
    text:setText("剩余球数")
    local text = uiWindow:createUI("Text", "pointUi2", "_lt", 10, 185, 260, 50)
    text:setFontSize(50)
    text:setFontColour("255 191 0")
    text:setText("0")
    text:setTextFormat(0x00000001)
    lifeUi = text
end

function updatePointUi(point)
    if (true) then return end
    pointUi:setText(point)
end

function updateLifeUi(life)
    if (true) then return end
    lifeUi:setText(life)
end

function setDifficulty()
    gaming = nil
    UI.ShowEditWindow(
        "输入数字1~10选择难度并开始游戏",
        function(text)
            local number = tonumber(text)
            if type(number) ~= "number" or not number then
                setDifficulty()
                return
            end

            if number >= 1 and number <= #difficultyList then
                --[[			for i=1,35 do
				Delay(1000*i, function ( ... )
					local newball = createBall()
					launchBall(newball)
				end)
			end--]]
                gaming = true
                gameIndex = gameIndex + 1
                difficulty = number
                point = 0
                life = difficulty
                updatePointUi(point)
                updateLifeUi(life)
                canDestroyBlock = true
                speed = difficultyList[number].speed
                controllerLength = difficultyList[number].controllerLength
                setController()
                --[[			for i=1,#controller do
				SetBlock(controller[i].x,controller[i].y,controller[i].z,controllerBlockId,controllerBlockData)
			end--]]
                passThrough = nil
                createBall()
                clearBoard()
                loadMap()
                Tip("点击鼠标左键发球，可按键盘上的加号键(+)或减号键(-)来放大/缩小游戏画面，使游戏区域显示完整。", nil, "255 255 0");
            else
                setDifficulty()
            end
        end
    )
end

function setController()
    destroyController()
    local temp = {}
    for i = -controllerLength, controllerLength do
        table.insert(temp, {x = controllerCenter.x + i, y = controllerCenter.y, z = controllerCenter.z})
    end
    controller = temp
    for i = 1, #controller do
        if GetBlockId(controller[i].x, controller[i].y, controller[i].z) ~= unbreakableBlock then
            SetBlock(controller[i].x, controller[i].y, controller[i].z, controllerBlockId, controllerBlockData)
        end
    end
end

function clearBoard()
    for i = board.x1, board.x2 do
        for j = board.y2, board.y1 do
            SetBlock(i, j, board.z1, 0)
        end
    end
end

function loadMap()
    local random = math.random(#map)
    local temp = {}
    for i = map[random].x1, map[random].x2 do
        for j = map[random].y2, map[random].y1 do
            local id, data, _ = GetBlockFull(i, j, map[random].z1)
            table.insert(temp, {id = id, data = data})
        end
    end

    local count = 1
    for i = board.x1, board.x2 do
        for j = board.y2, board.y1 do
            SetBlock(i, j, board.z1, temp[count].id, temp[count].data)
            count = count + 1
        end
    end
end

function launchBall(ball)
    local angle
    while not angle or angle == 0 do
        angle = 45 - math.random(1, 90)
    end

    ball._x = math.sin(math.rad(angle))
    ball._y = math.cos(math.rad(angle))
    ball:SetVelocity(speed * ball._x, speed * ball._y, 0)
    ball._moving = true
end

function clear()
    SetPermission("edit", true)
    gameReset()
    cmd("/show")
    EnableAutoCamera(true)
end

function gameReset()
    destroyAllBall()
    destroyController()
    clearBoard()
end

function destroyAllBall()
    for i = 1, #ballList do
        ballList[i]:Destroy()
        ballList[i] = nil
    end
    ballList = {}
end

function destroyController()
    for i = 1, #controller do
        if GetBlockId(controller[i].x, controller[i].y, controller[i].z) ~= unbreakableBlock then
            SetBlock(controller[i].x, controller[i].y, controller[i].z, 0)
        end
    end
end

function createBall()
    ballList = ballList or {}
    local ball =
        CreateNPC(
        {
            bx = controllerCenter.x,
            by = controllerCenter.y + 1,
            bz = controllerCenter.z,
            item_id = 30001,
            facing = 0,
            can_random_move = false
        }
    )
    ball:SetGravity(0)
    ball:SetSurfaceDecay(0)
    ball:GetPhysicsObject():SetAirDecay(0)
    ball:SetModelFile("Texture/Aries/Creator/keepwork/ggs/gi/models/entities/football.fbx")

    local aabb = ball:GetCollisionAABB()
    ball._aabb = {aabb.mExtents[1], aabb.mExtents[2], aabb.mExtents[3]}
    --[[	aabb.mExtents[1] = -1
	aabb.mExtents[2] = -1
	aabb.mExtents[3] = -1--]]
    table.insert(ballList, ball)
    return ball
end

function ignoreCollison(ball, bIgnore)
    local aabb = ball:GetCollisionAABB()
    if bIgnore then
        aabb.mExtents[1] = -1
        aabb.mExtents[2] = -1
        aabb.mExtents[3] = -1
    else
        aabb.mExtents[1] = ball._aabb[1]
        aabb.mExtents[2] = ball._aabb[2]
        aabb.mExtents[3] = ball._aabb[3]
    end
end

function loop(...)
    if gaming then
        if next(ballList) then
            for i = #ballList, 1, -1 do
                if ballList[i]._moving then
                    moveBall(ballList[i])
                    checkDead(ballList[i])
                end
            end
        end
    end
end

function checkDead(ball)
    if ball then
        local x, y, z = ball:GetBlockPos()
        --cmd("/tip "..x..","..y..","..z)
        if y < controllerCenter.y - 1 then
            for i = 1, #ballList do
                if ballList[i].entityId == ball.entityId then
                    --cmd("/tip remove")
                    table.remove(ballList, i)
                    break
                end
            end
            ball:Destroy()
            if not next(ballList) then
                -- 死亡一次
                life = life - 1
                updateLifeUi(life)
                if life < 0 then
                    -- 输了
                    gaming = nil
                    gameReset()
                    MessageBox(
                        "球用完了，未完成游戏，得分[" .. point .. "]。点击确定重新开始游戏",
                        function()
                            setDifficulty()
                        end
                    )
                    return
                end
                createBall()
            end
        end

        if y > top or x < left or y > right then -- for bug
            for i = 1, #ballList do
                if ballList[i].entityId == ball.entityId then
                    --cmd("/tip remove")
                    table.remove(ballList, i)
                    break
                end
            end

            ball:Destroy()
            if not next(ballList) then
                -- bug, 无惩罚
                cmd("/tip bug了，理解万岁。")
                createBall()
            end
        end
    end
end

function findNearestBlockId(ball)
    local temp = {}
    local x, y, z = ball:GetBlockPos()
    local _x, _y, _z = ConvertToRealPosition(x, y, z)
    for i = x - 2, x + 2 do
        for j = y - 2, y + 2 do
            if not (i == x and j == y) then
                if GetBlockId(i, j, z) ~= 0 then
                    local xx, yy, zz = ConvertToRealPosition(i, j, z)
                    table.insert(
                        temp,
                        {x = i, y = j, z = z, id = GetBlockId(i, j, z), dist = math.sqrt((_x - xx) ^ 2 + (_y - yy) ^ 2)}
                    )
                end
            end
        end
    end
    if next(temp) then
        table.sort(
            temp,
            function(a, b)
                return a.dist < b.dist
            end
        )
        return GetBlockId(temp[1].x, temp[1].y, temp[1].z)
    end
    return 0
end

-- 球的运动
function moveBall(ball)
    local vx, vy, vz = ball:GetVelocity() -- 球的三个方向力

    local ballX, ballY, ballZ = ball:GetBlockPos()

    if passThrough then -- 有“穿透”buff时的逻辑
        if
            GetBlockId(ballX, ballY, ballZ) ~= 0 and GetBlockId(ballX, ballY, ballZ) ~= controllerBlockId and
                GetBlockId(ballX, ballY, ballZ) ~= unbreakableBlock
         then
            if canDestroyBlock then
                SetBlock(ballX, ballY, ballZ, 0) -- 消除可消除的方块
            end
            changePoint(100 * (1 + (difficulty - 1) / 10))
            if checkGameEnd() then
                return
            end
        end
        local nearest = findNearestBlockId(ball)
        if nearest ~= 0 and nearest ~= controllerBlockId and nearest ~= unbreakableBlock then
            ignoreCollison(ball, true)
        else
            ignoreCollison(ball, false)
        end
    else
        ignoreCollison(ball, false)
    end

    if ball.isCollidedHorizontally or ball.isCollidedVertically then -- 球的反弹，横向/纵向
        if ball.isCollidedHorizontally then
            ball.isCollidedHorizontally = false
            testcount = testcount + 1
            ball._x = -ball._x
            checkBlock(ball)
        elseif ball.isCollidedVertically then
            ball.isCollidedVertically = false
            testcount = testcount + 1
            local _x, _y, _z = checkBlock(ball)
            if not _x then
                -- 正常碰撞
                ball._y = -ball._y
            else
                -- 挡板
                local centerX, centerY, centerZ =
                    ConvertToRealPosition(controllerCenter.x, controllerCenter.y, controllerCenter.z)
                centerY = centerY - 0.3
                local ballRx, ballRy, ballRz = ball:GetPosition()
                local a = math.sqrt((centerX - ballRx) ^ 2 + (centerY - ballRy) ^ 2)
                local b = math.abs(ballRy - centerY)
                local c = ballRx - centerX
                if c ~= 0 then
                    ball._x = (a ^ 2 + c ^ 2 - b ^ 2) / (2 * a * c)
                    ball._y = math.abs((a ^ 2 + b ^ 2 - c ^ 2) / (2 * a * b))
                else
                    ball._x = 0
                    ball._y = speed
                end
            end
        end
    end
    if ball then
        ball:SetVelocity(speed * ball._x, speed * ball._y, 0) -- 重设球的运动方向
    end
end

function checkBlock(ball)
    local temp = {}
    local x, y, z = ball:GetBlockPos()
    local _x, _y, _z = ConvertToRealPosition(x, y, z)
    for i = x - 1, x + 1 do
        for j = y - 1, y + 1 do
            if not (i == x and j == y) then
                if GetBlockId(i, j, z) ~= 0 and GetBlockId(i, j, z) ~= unbreakableBlock then
                    local xx, yy, zz = ConvertToRealPosition(i, j, z)
                    table.insert(
                        temp,
                        {x = i, y = j, z = z, id = GetBlockId(i, j, z), dist = math.sqrt((_x - xx) ^ 2 + (_y - yy) ^ 2)}
                    )
                end
            end
        end
    end
    if next(temp) then
        table.sort(
            temp,
            function(a, b)
                return a.dist < b.dist
            end
        )

        if GetBlockId(temp[1].x, temp[1].y, temp[1].z) ~= controllerBlockId then
            local id = destroyOrReplace(GetBlockId(temp[1].x, temp[1].y, temp[1].z))
            SetTimeout(
                50,
                function(...)
                    if canDestroyBlock then
                        local blockId = GetBlockId(temp[1].x, temp[1].y, temp[1].z)
                        if blockId ~= 0 then
                            --[[point = point + 100*(1+difficulty/10)--]]
                            changePoint(100 * (1 + (difficulty - 1) / 10))

                            if blockId ~= block_good and GetBlockId(temp[1].x, temp[1].y, temp[1].z) ~= block_bad then
                                local random = math.random()
                                if random <= 0.15 then
                                    -- 生成一个道具
                                    local random2 = math.random()
                                    if random2 >= 0.2 then
                                        -- 好
                                        id = block_good
                                    else
                                        -- 坏
                                        id = block_bad
                                    end
                                else
                                end
                            elseif blockId == block_good then
                                good()
                            elseif blockId == block_bad then
                                bad()
                            end

                            SetBlock(temp[1].x, temp[1].y, temp[1].z, id)

                            if not checkGameEnd() then
                                if id == 0 then
                                -- 生成一个方块视为道具，再次消除则生效，问号是负面效果，叹号是正面效果。
                                end
                            end
                        end
                    end
                end
            )
        else
            --cmd("/tip return")
            return x, y, z
        end
    end
end

function changePoint(num)
    point = point + num
    updatePointUi(point)
end

function good()
    local random = math.random(#goodTb)
    cmd("/tip -color #00ff00 -message" .. math.random(9999) .. " 获得效果[" .. goodTb[random].desc .. "].")
    if random == 2 then
        speedDownCount = (speedDownCount or 0) + 1
    end
    goodTb[random].func(speedDownCount)
end

function bad()
    local random = math.random(#badTb)
    cmd("/tip -color #ff0000 -message" .. math.random(9999) .. " 获得效果[" .. badTb[random].desc .. "].")
    if random == 1 then
        speedUpCount = (speedUpCount or 0) + 1
    end
    badTb[random].func(speedUpCount)
end

function checkGameEnd()
    local count = 0
    for i = board.x1, board.x2 do
        for j = board.y2, board.y1 do
            if GetBlockId(i, j, board.z1) ~= 0 and GetBlockId(i, j, board.z1) ~= unbreakableBlock then
                count = count + 1
            end
        end
    end

    if count == 0 then
        -- 结束，新一局
        gaming = nil
        gameReset()
        changePoint(life * 1000)
        MessageBox(
            "恭喜过关，剩余球数[" .. life .. "]，得分[" .. point .. "]点击确定重新开始游戏",
            function()
                setDifficulty()
            end
        )

        return true
    end
    return false
end

function destroyOrReplace(id)
    for i = 1, #brickList do
        for j = 1, #brickList[i] do
            if brickList[i][j].id == id then
                if brickList[i][j + 1] then
                    return brickList[i][j + 1].id
                else
                    return 0
                end
            end
        end
    end
    return 0
end

RegisterEventCallBack(EventType.MOUSE_KEY, function(event)
    if event.event_type == "keyPressEvent" then
        if event.keyname == "DIK_EQUALS" or event.keyname == "DIK_ADD" then -- 镜头放大
            cameraZoom = cameraZoom * 0.9
            if (cameraZoom < 2) then
                cameraZoom = 2
            end
            CameraZoomInOut(cameraZoom)
        elseif event.keyname == "DIK_MINUS" or event.keyname == "DIK_SUBTRACT" then -- 镜头缩小
            cameraZoom = cameraZoom * 1.1
            if (cameraZoom > 30) then
                cameraZoom = 30
            end
            CameraZoomInOut(cameraZoom)
        end
    end

    if event.event_type == "mousePressEvent" and event.mouse_button == "left" and gaming then
        if ballList[1] then
            if not ballList[1]._moving then
                launchBall(ballList[1])
                event:accept()
            end
        end
    elseif event.event_type == "mouseMoveEvent" and gaming then
        local pick = MousePick()
        if (not pick) then return end 
        local x, y, z = pick.blockX, pick.blockY, pick.blockZ
        if x then
            if x <= left + controllerLength then
                x = left + controllerLength + 1
            elseif x >= right - controllerLength then
                x = right - controllerLength - 1
            end
            if x > left + controllerLength and x < right - controllerLength and x ~= controllerCenter.x then
                local lastcontrollerCenterX = controllerCenter.x
                controllerCenter.x = x
                setController()
                if ballList[1] then
                    if not ballList[1]._moving then
                        local x, y, z = ballList[1]:GetBlockPos()
                        ballList[1]:SetBlockPos(
                            x - (lastcontrollerCenterX - controllerCenter.x),
                            controllerCenter.y + 1,
                            controllerCenter.z
                        )
                    end
                end
            end
        end
    end
end)
