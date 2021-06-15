local colorMap = {
	[1] = {id = 23, name = "红"},
	[2] = {id = 96, name = "粉"},
	[3] = {id = 94, name = "橙"},
	[4] = {id = 27, name = "黄"},
	[5] = {id = 137, name = "绿"},
	[6] = {id = 20, name = "青"},
	[7] = {id = 19, name = "蓝"},
	[8] = {id = 24, name = "紫"}
}

local foodBlock = {
	{id = 113, points = 1},
	{id = 114, points = 5},
	{id = 115, points = 10},
	{id = 116, points = 20},
	{id = 119, points = 50}
}

-- 玩家身体颜色
local playerColor
-- 出生点坐标
local homeX, homeY, homeZ = 19190, 4, 19259 -- ConvertToBlockIndex(GetHomePosition())
local homeBlockId = GetBlockId(homeX, homeY, homeZ)
-- 最大玩家数量
local maxPlayerNum = #colorMap -- 8
-- 默认速度
local gameSpeed = 1.2
-- 玩家速度
local playerSpeed = gameSpeed
-- 按空格计数
local keyPressCount = 0
-- 游戏是否在进行
local gaming = nil
-- 记录玩家各类信息
local playerInfo = {}
-- 主角
local player = GetPlayer()
-- 玩家列表，服务器用
local playerList
-- 玩家身体信息表
local playerBody = {}
-- 地图半径（正方形）
local mapRadius = 50
-- 地图地板ID
local mapBlockId = 5
-- 玩家得分
local playerPoints

local function BeginGame()
	gaming = true
	playerSpeed = gameSpeed
	playerBody = {}
	playerPoints = 0
	playerColor = colorMap[math.random(1, 8)].id
	player:SetBlockPos(homeX, homeY + 1, homeZ)
	LoadMap()
	RandomPlaceFood()
	player:SetSpeedScale(playerSpeed)
	player:SetVisible(false);
	SetBody()
end

function main()
	cmd("/addrule Player CanJump false")
	cmd("/addrule Player AllowRunning false")
	BeginGame()
end

function loop()
	if (not gaming) then
		return
	end

	AutoWalk()
	CheckEat()
	CheckMove()
end

function clear()
	player:SetVisible(true);
	for i = homeX - mapRadius, homeX + mapRadius do
		for j = homeZ - mapRadius, homeZ + mapRadius do
			SetBlock(i, homeY, j, homeBlockId)
		end
	end
end

function LoadMap()
	for i = homeX - mapRadius, homeX + mapRadius do
		for j = homeZ - mapRadius, homeZ + mapRadius do
			SetBlock(i, homeY + 1, j, 0);
			SetBlock(i, homeY, j, mapBlockId)
		end
	end
end

function AutoWalk()
	-- player:BeginTouchMove()
	-- player:TouchMove(GetDirection2DFromCamera())
	-- player:SetFacing(GetFacingFromCamera())
end

function StopAutoWalk()
	-- player:EndTouchMove()
end

function RandomPlaceFood()
	local canPlaceFoodPosList = {}
	local canPlaceFoodPosSize = 0
	SetInterval(
		600,
		function()
			if gaming and playerColor then
				local randomFood = math.random()
				if randomFood < 0.01 then
					randomFood = foodBlock[5].id
				elseif randomFood < 0.03 then
					randomFood = foodBlock[4].id
				elseif randomFood < 0.1 then
					randomFood = foodBlock[3].id
				elseif randomFood < 0.25 then
					randomFood = foodBlock[2].id
				else
					randomFood = foodBlock[1].id
				end

				canPlaceFoodPosSize = 0
				for i = homeX - mapRadius, homeX + mapRadius do
					for j = homeZ - mapRadius, homeZ + mapRadius do
						if (GetBlockId(i, homeY + 1, j) == 0) then
							canPlaceFoodPosSize = canPlaceFoodPosSize + 1
							canPlaceFoodPosList[canPlaceFoodPosSize] = canPlaceFoodPosList[canPlaceFoodPosSize] or {}
							local pos = canPlaceFoodPosList[canPlaceFoodPosSize]
							pos.x, pos.y, pos.z = i, homeY + 1, j
						end
					end
				end

				if canPlaceFoodPosSize > 0 then
					local posIndex = math.random(1, canPlaceFoodPosSize)
					local pos = canPlaceFoodPosList[posIndex]
					SetBlock(pos.x, pos.y, pos.z, randomFood)
				end
			end
		end
	)
end

function CheckEat()
	local x, y, z = player:GetBlockPos()
	for i = 1, #foodBlock do
		if foodBlock[i].id == GetBlockId(x, y, z) then
			SetBlock(x, y, z, 0)
			ModifyPoints(foodBlock[i].points)
			break
		end
	end
end

function ModifyPoints(point)
	playerPoints = math.max(playerPoints + point, 0)
	playerSpeed = math.max(gameSpeed - playerPoints / 1500, 0.65)
	player:SetSpeedScale(playerSpeed)
	SetBody()
end

function SetBody()
	local length = math.floor(playerPoints / 20) + 2;
	local x, y, z = player:GetBlockPos()
	local bodyLength = #playerBody
	-- 增长
	if (length > bodyLength) then
		-- 缩短
		local tail = bodyLength > 0 and playerBody[bodyLength] or {x = x, y = y, z = z}
		for i = 1, length - #playerBody do
			tail = {x = tail.x, y = tail.y, z = tail.z + 1}
			table.insert(playerBody, tail)
			SetBlock(tail.x, tail.y, tail.z, playerColor)
		end
	elseif length < bodyLength then
		for i = bodyLength, length + 1, -1 do
			local tail = playerBody[i]
			SetBlock(tail.x, tail.y, tail.z, 0)
			table.remove(playerBody, i)
		end
	end
end

function CheckMove()
	local x, y, z = player:GetBlockPos();
	local blockId = GetBlockId(x, y, z);

	-- 掉出场外，死亡
	if x < (homeX - mapRadius) or x > (homeX + mapRadius) or z < (homeZ - mapRadius) or z > (homeZ + mapRadius) then
		PlayerDead()
		return
	end
	-- 踩到了其他玩家的身体，死亡
	if blockId ~= 0 and blockId ~= playerColor then
		PlayerDead()
		return
	end

	local head, size = playerBody[1], #playerBody;
	while (head and (head.x ~= x  or head.z ~= z)) do
		local tail = playerBody[size];
		table.remove(playerBody, size);
		SetBlock(tail.x, tail.y, tail.z, 0);
		tail.x, tail.y, tail.z = head.x, head.y, head.z;
		head = tail;
		table.insert(playerBody, 1, head);
		if (head.x ~= x) then
			head.x = head.x + (x > head.x and 1 or -1);
		else
			head.z = head.z + (z > head.z and 1 or -1);
		end
		SetBlock(head.x, head.y, head.z, playerColor);
	end
end

function PlayerDead()
	gaming = nil
	StopAutoWalk()
	Tip("游戏结束")
end
