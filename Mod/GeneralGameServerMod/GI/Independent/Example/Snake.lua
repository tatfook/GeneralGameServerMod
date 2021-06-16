local PlayerColorList = {
	[1] = {id = 23, name = "红"},
	[2] = {id = 96, name = "粉"},
	[3] = {id = 94, name = "橙"},
	[4] = {id = 27, name = "黄"},
	[5] = {id = 137, name = "绿"},
	[6] = {id = 20, name = "青"},
	[7] = {id = 19, name = "蓝"},
	[8] = {id = 24, name = "紫"}
}

local FoodBlockList = {
	{id = 113, points = 30}, -- 1
	{id = 114, points = 20}, -- 5
	{id = 115, points = 10}, -- 10
	{id = 116, points = 20}, -- 20
	{id = 119, points = 50}
}

-- 玩家身体颜色
local playerColor
-- 出生点坐标
local CenterX, CenterY, CenterZ = 19190, 4, 19259 -- ConvertToBlockIndex(GetHomePosition())
-- 最大玩家数量
local maxPlayerNum = #PlayerColorList -- 8
local gaming = nil
-- 主角
local player = GetPlayer()
-- 玩家身体信息表
local PlayerBody = {}
-- 地图半径（正方形）
local MapWidth, MapHeight = 60, 50;
-- 地图地板ID
local MapBlockId = 5
-- 玩家得分
local playerPoints
local PlayerMoveTickCount = 10
local PlayerMoveDirection = 2
local LastPlayerMoveDirection = 2
local CurrentMoveTickCount = 0
local PlayerBlockX, PlayerBlockY, PlayerBlockZ = player:GetBlockPos();
local CameraObjectDistance = 50;

local function BeginGame()
	gaming = true
	PlayerBody = {}
	playerPoints = 0
	playerColor = PlayerColorList[math.random(1, 8)].id
	LoadMap()
	RandomPlaceFood()
	player:SetSpeedScale(0)
	EnableAutoCamera(false)
	SetCameraObjectDistance(CameraObjectDistance)
	SetCameraLiftupAngle(90)
	SetCameraFacing(-90)
	SetBody()
	SetCameraLookAtBlockPos(CenterX, CenterY + 2, CenterZ);
	-- SwitchCameraPosition();
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

	Move()
end

function clear()
	player:SetVisible(true)
	EnableAutoCamera(true)
	player:SetSpeedScale(1)
	player:SetBlockPos(PlayerBlockX, PlayerBlockY, PlayerBlockZ)
	player:SetFocus();
	SetCameraObjectDistance(8)
	local obj = player:GetInnerObject();
	if(obj and obj.ToCharacter) then obj:ToCharacter():SetFocus() end 

	local mapHalfWidth, mapHalfHeight = MapWidth / 2, MapHeight / 2;
	for i = CenterX - mapHalfWidth, CenterX + mapHalfWidth do
		for j = CenterZ - mapHalfHeight, CenterZ + mapHalfHeight do
			SetBlock(i, CenterY, j, 62)
			SetBlock(i, CenterY + 1, j, 0)
		end
	end
end

function LoadMap()
	local mapHalfWidth, mapHalfHeight = MapWidth / 2, MapHeight / 2;
	for i = CenterX - mapHalfWidth, CenterX + mapHalfWidth do
		for j = CenterZ - mapHalfHeight, CenterZ + mapHalfHeight do
			SetBlock(i, CenterY + 1, j, 0)
			SetBlock(i, CenterY, j, MapBlockId)
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
					randomFood = FoodBlockList[5].id
				elseif randomFood < 0.03 then
					randomFood = FoodBlockList[4].id
				elseif randomFood < 0.1 then
					randomFood = FoodBlockList[3].id
				elseif randomFood < 0.25 then
					randomFood = FoodBlockList[2].id
				else
					randomFood = FoodBlockList[1].id
				end

				canPlaceFoodPosSize = 0
				local mapHalfWidth, mapHalfHeight = MapWidth / 2, MapHeight / 2;
				for i = CenterX - mapHalfWidth, CenterX + mapHalfWidth do
					for j = CenterZ - mapHalfHeight, CenterZ + mapHalfHeight do
						if (GetBlockId(i, CenterY + 1, j) == 0) then
							canPlaceFoodPosSize = canPlaceFoodPosSize + 1
							canPlaceFoodPosList[canPlaceFoodPosSize] = canPlaceFoodPosList[canPlaceFoodPosSize] or {}
							local pos = canPlaceFoodPosList[canPlaceFoodPosSize]
							pos.x, pos.y, pos.z = i, CenterY + 1, j
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

function SwitchCameraPosition()
	local head = PlayerBody[1];
	if (not head) then return end
	local size = CameraObjectDistance / 2;
	local x, y, z = head.x, head.y, head.z;
	local cameraX, cameraY, cameraZ = CenterX + math.floor((x - CenterX) / size) * size, CenterY + 2,  CenterZ + math.floor((z - CenterZ) / size) * size;
	SetCameraLookAtBlockPos(cameraX, cameraY, cameraZ);
end

function ModifyPoints(point)
	
end

function SetBody()
	local length = math.floor(playerPoints / 20) + 2
	local bodyLength = #PlayerBody
	-- 增长
	if (length > bodyLength) then
		-- 缩短
		local tail = bodyLength > 0 and PlayerBody[bodyLength] or {x = CenterX, y = CenterY + 1, z = CenterZ + 1}
		local offsetX, offsetZ = 0, -1;
		if (bodyLength > 2) then
			offsetX, offsetZ = PlayerBody[bodyLength].x - PlayerBody[bodyLength - 1].x, PlayerBody[bodyLength].z - PlayerBody[bodyLength - 1].z;
		end
		for i = 1, length - #PlayerBody do
			tail = {x = tail.x + offsetX, y = tail.y, z = tail.z + offsetZ}
			table.insert(PlayerBody, tail)
			SetBlock(tail.x, tail.y, tail.z, playerColor)
		end
	elseif length < bodyLength then
		for i = bodyLength, length + 1, -1 do
			local tail = PlayerBody[i]
			SetBlock(tail.x, tail.y, tail.z, 0)
			table.remove(PlayerBody, i)
		end
	end
end

function Move()
	CurrentMoveTickCount = CurrentMoveTickCount + 1
	if (CurrentMoveTickCount < PlayerMoveTickCount) then
		return
	end
	CurrentMoveTickCount = 0

	local head, tail = PlayerBody[1], PlayerBody[#PlayerBody]
	local x, y, z = head.x, head.y, head.z;

	if (PlayerMoveDirection == 0) then
		x = x - 1
	end
	if (PlayerMoveDirection == 1) then
		x = x + 1
	end
	if (PlayerMoveDirection == 2) then
		z = z + 1
	end
	if (PlayerMoveDirection == 3) then
		z = z - 1
	end
	LastPlayerMoveDirection = PlayerMoveDirection;

	-- 掉出场外，死亡
	local mapHalfWidth, mapHalfHeight = MapWidth / 2, MapHeight / 2;
	if (x < (CenterX - mapHalfWidth) or x > (CenterX + mapHalfWidth) or z < (CenterZ - mapHalfHeight) or z > (CenterZ + mapHalfHeight)) then
		return PlayerDead()
	end
	
	local blockId = GetBlockId(x, y, z)
	local blockFood = nil;
	if (blockId and blockId ~= 0) then
		for _, color in ipairs(PlayerColorList) do
			if (blockId == color.id) then 
				return PlayerDead()
			end
		end
	
		for _, food in ipairs(FoodBlockList) do
			if (food.id == blockId) then
				blockFood = food;
				SetBlock(x, y, z, 0)
				break
			end
		end
	end

	table.remove(PlayerBody, #PlayerBody)
	SetBlock(tail.x, tail.y, tail.z, 0)
	table.insert(PlayerBody, 1, tail)
	tail.x, tail.y, tail.z = x, y, z
	SetBlock(tail.x, tail.y, tail.z, playerColor)
	
	if (blockFood) then
		playerPoints = math.max(playerPoints + blockFood.points, 0)
		SetBody()
	end
end

function PlayerDead()
	gaming = nil
	StopAutoWalk()
	Tip("游戏结束")
end

RegisterEventCallBack(
	EventType.KEY_DOWN,
	function(event)
		local keyname = event.keyname
		if ((keyname == "DIK_A" or keyname == "DIK_LEFT") and LastPlayerMoveDirection ~= 1) then
			PlayerMoveDirection = 0
		elseif ((keyname == "DIK_D" or keyname == "DIK_RIGHT") and LastPlayerMoveDirection ~= 0) then
			PlayerMoveDirection = 1
		elseif ((keyname == "DIK_W" or keyname == "DIK_UP") and LastPlayerMoveDirection ~= 3) then
			PlayerMoveDirection = 2
		elseif ((keyname == "DIK_S" or keyname == "DIK_DOWN") and LastPlayerMoveDirection ~= 2) then
			PlayerMoveDirection = 3
		end
	end
)
