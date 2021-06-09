-- 出生点坐标
local homeX, homeY, homeZ = ConvertToBlockIndex(GetHomePosition())
local player = GetPlayer()
local rankUi_PlayerName
local rankUi_Time
local timeUi
local failUi
local rankTip
local second = 0
local rankTb = {}

local breakableBlock = {
    {id = 2118, replaceId = 2127},
    {id = 2117, replaceId = 2126},
    {id = 2116, replaceId = 2125},
    {id = 2115, replaceId = 2124},
    {id = 2114, replaceId = 2123},
    {id = 2113, replaceId = 2122},
    {id = 2112, replaceId = 2121},
    {id = 2111, replaceId = 2120},
    {id = 70, replaceId = 2119}
}
local deadBlock = {
    {id = 2218},
    {id = 224}
}
local speedUpBlock = {
    {id = 100}
}
local elasticBlock = {
    {id = 2036, height = 36}, -- height：约等于方块格数，36≈15格，30≈10格，20≈5格
    {id = 200, height = 30},
    {id = 201, height = 20}
}
local savePointBlock = {
    {id = 2101}
}
local finishBlock = {
    {id = 2100}
}

function main()
    player_newGame()
end

function player_newGame()
    second = 0
    player:SetSpeedScale(1)
    gaming = true
    savePoint = {x = homeX, y = homeY, z = homeZ}
    deadCount = 0 -- 失败次数
end

function loop()
    if gaming then
        checkBlock()
    end
end

function showMsg(text)
    cmd("/tip -color #" .. (color or "ffff00") .. " -message" .. math.random(9999) .. " " .. text)
end

function checkBlock()
    local x, y, z = player:GetBlockPos()
    local rx, ry, rz = player:GetPosition()
    local blockId1 = GetBlockId(x, y - 1, z) -- 脚下方块
    local blockId2 = GetBlockId(x, y, z) -- 下半身所在方块
    local blockId3 = GetBlockId(x, y + 1, z) -- 头部所在方块

    finish(
        blockId1,
        function()
            player:SetSpeedScale(0)
            gaming = nil
            local totalSec = second
            local min = math.floor(totalSec / 60)
            local sec = math.floor(totalSec % 60)
            local finalSec = totalSec + deadCount
            local finalMin = math.floor(finalSec / 60)
            local finalSec = math.floor(finalSec % 60)

            --SendToAll({event = "sendMsg", text = "掉落，回退1个平台。", id = player.entityId})

            local msg =
                "玩家[" ..
                player.nickname ..
                    "]通关，用时：" ..
                        min .. "分" .. sec .. "秒，失败次数：" .. deadCount .. "次，总成绩[" .. finalMin .. "分" .. finalSec .. "秒]。"

            Tip(msg)

            return
        end
    )

    dead(
        blockId1,
        blockId2,
        function()
            deadCount = deadCount + 1
            player:SetSpeedScale(0)
            gaming = nil
            Tip("游戏失败")
            return
        end
    )

    save(
        blockId1,
        function()
            if x ~= savePoint.x or y - 1 ~= savePoint.y or z ~= savePoint.z then
                savePoint = {x = x, y = y - 1, z = z}
                cmd("/tip 已存档。")
            end
            return
        end
    )

    elastic(
        blockId2,
        function(height)
            if height then
                if not jumpTime or os.clock() - jumpTime > 0.3 then
                    jumpTime = os.clock()
                    jumpcount = (jumpcount or 0) + 1
                    player:SetVelocity(0, 0, 0)
                    player:SetVelocity(0, height, 0)
                end
                return
            end
        end
    )

    speedUp(
        blockId2,
        blockId3,
        function(index, id)
            if index == 2 then
                y = y + 1
            end
            local _, data, _ = GetBlockFull(x, y, z)
            SetBlock(x, y, z, 0)
            player:SetSpeedScale(2)
            SetTimeout(
                3000,
                function()
                    player:SetSpeedScale(1)
                    SetBlock(x, y, z, id, data)
                end
            )
            return
        end
    )

    breakable(
        blockId1,
        function(id)
            if id then
                SetBlock(x, y - 1, z, id)
                SetTimeout(
                    500,
                    function()
                        SetBlock(x, y - 1, z, 0)
                        CreateBlockPieces(blockId1, x, y - 1, z, 1)
                        SetTimeout(
                            2000,
                            function()
                                SetBlock(x, y - 1, z, blockId1)
                            end
                        )
                    end
                )
                return
            end
        end
    )
end

function speedUp(blockId1, blockId2, callback)
    for k, v in pairs(speedUpBlock) do
        if v.id == blockId1 then
            callback(1, v.id)
            break
        elseif v.id == blockId2 then
            callback(2, v.id)
            break
        end
    end
end

function finish(blockId, callback)
    for k, v in pairs(finishBlock) do
        if v.id == blockId then
            callback()
            break
        end
    end
end

function dead(blockId1, blockId2, callback)
    for k, v in pairs(deadBlock) do
        if v.id == blockId1 or v.id == blockId2 then
            callback()
            break
        end
    end
end

function save(blockId, callback)
    for k, v in pairs(savePointBlock) do
        if v.id == blockId then
            callback()
            break
        end
    end
end

function elastic(blockId, callback)
    if player.onGround then
        for k, v in pairs(elasticBlock) do
            if v.id == blockId then
                callback(v.height)
                break
            end
        end
    end
end

function breakable(blockId, callback)
    for k, v in pairs(breakableBlock) do
        if v.id == blockId then
            callback(v.replaceId)
            break
        end
    end
end
