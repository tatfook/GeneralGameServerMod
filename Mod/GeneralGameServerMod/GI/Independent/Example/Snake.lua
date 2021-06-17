local GGS = require("GGS");
local __username__ = GetUserName();
local __all_player__ = GGS:Get("__all_player__", {});
local __player__ = __all_player__:Get(__username__, {
	username = __username__, 
	score = 0, 
	color = 23,
});
local __ranks__ = NewScope();
local __all_player_body__ = {[__username__] = {}}
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
	{id = 113, points = 1}, -- 1
	{id = 114, points = 5}, -- 5
	{id = 115, points = 10}, -- 10
	{id = 116, points = 20}, -- 20
	{id = 119, points = 50}
}

-- 地图中心点坐标
local CenterX, CenterY, CenterZ = 19190, 4, 19259 -- ConvertToBlockIndex(GetHomePosition())
-- 是否开始游戏
local IsGaming = false
-- 主角
local player = GetPlayer()
-- 地图半径（正方形）
local MapWidth, MapHeight = 100, 100
-- 地图地板ID
local MapBlockId = 5
-- 玩家身体信息表
local PlayerBody = __all_player_body__[__username__];
-- 玩家得分
local DefaultPlayerMoveTickCount = 10
local PlayerMoveTickCount = DefaultPlayerMoveTickCount
local PlayerMoveDirection = 2
local LastPlayerMoveDirection = 2
local CurrentMoveTickCount = 0
local PlayerBlockX, PlayerBlockY, PlayerBlockZ = player:GetBlockPos()
-- 相机位置
local CameraX, CameraY, CameraZ, CameraOffsetX, CameraOffsetY, CameraOffsetZ = 0, 0, 0, 0, 0, 0

local isNeedSyncData = false;

local function BeginGame()
	IsGaming = true
	PlayerBody = {}
	__player__.color = PlayerColorList[math.random(1, 8)].id
	__player__.score = 0
	LoadMap()
	RandomPlaceFood()
	CheckBody()
	player:SetSpeedScale(0)
	EnableAutoCamera(false)
	SetCameraObjectDistance(20)
	SetCameraLiftupAngle(90)
	SetCameraFacing(-90)
	CameraX, CameraY, CameraZ = ConvertToRealPosition(CenterX, CenterY + 2, CenterZ)
	SetCameraLookAtPos(CameraX, CameraY, CameraZ)
end

function main()
	BeginGame()
	CreateRankUI()
end

function loop()
	if (not IsGaming) then return end

	CheckMove()
	CheckBody()
	CheckRanks();
end

function clear()
	EnableAutoCamera(true)
	SetCameraObjectDistance(8)
	player:SetSpeedScale(1)
	player:SetFocus()
	local obj = player:GetInnerObject()
	if (obj and obj.ToCharacter) then
		obj:ToCharacter():SetFocus()
	end

	local mapHalfWidth, mapHalfHeight = MapWidth / 2, MapHeight / 2
	for i = CenterX - mapHalfWidth, CenterX + mapHalfWidth do
		for j = CenterZ - mapHalfHeight, CenterZ + mapHalfHeight do
			SetBlock(i, CenterY, j, 62)
			SetBlock(i, CenterY + 1, j, 0)
		end
	end
end

function LoadMap()
	local mapHalfWidth, mapHalfHeight = MapWidth / 2, MapHeight / 2
	for i = CenterX - mapHalfWidth, CenterX + mapHalfWidth do
		for j = CenterZ - mapHalfHeight, CenterZ + mapHalfHeight do
			SetBlock(i, CenterY + 1, j, 0)
			SetBlock(i, CenterY, j, MapBlockId)
		end
	end
end

function RandomPlaceFood()
	local canPlaceFoodPosList = {}
	local canPlaceFoodPosSize = 0
	SetInterval(
		600,
		function()
			if IsGaming then
				local randomFood = math.random()
				if randomFood < 0.1 then
					randomFood = FoodBlockList[5].id
				elseif randomFood < 0.3 then
					randomFood = FoodBlockList[4].id
				elseif randomFood < 0.5 then
					randomFood = FoodBlockList[3].id
				elseif randomFood < 0.7 then
					randomFood = FoodBlockList[2].id
				else
					randomFood = FoodBlockList[1].id
				end

				canPlaceFoodPosSize = 0
				local mapHalfWidth, mapHalfHeight = MapWidth / 2, MapHeight / 2
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

function CheckBody()
	local length = math.floor(__player__.score / 20) + 2
	local bodyLength = #PlayerBody
	-- 增长
	if (length > bodyLength) then
		-- 缩短
		local tail = bodyLength > 0 and PlayerBody[bodyLength] or {x = CenterX, y = CenterY + 1, z = CenterZ + 1}
		local offsetX, offsetZ = 0, -1
		if (bodyLength >= 2) then
			offsetX, offsetZ =
				PlayerBody[bodyLength].x - PlayerBody[bodyLength - 1].x,
				PlayerBody[bodyLength].z - PlayerBody[bodyLength - 1].z
		end
		for i = 1, length - #PlayerBody do
			tail = {x = tail.x + offsetX, y = tail.y, z = tail.z + offsetZ}
			table.insert(PlayerBody, tail)
			SetBlock(tail.x, tail.y, tail.z, __player__.color)
		end
	elseif length < bodyLength then
		for i = bodyLength, length + 1, -1 do
			local tail = PlayerBody[i]
			SetBlock(tail.x, tail.y, tail.z, 0)
			table.remove(PlayerBody, i)
		end
	end
	PlayerMoveTickCount = math.max(1, DefaultPlayerMoveTickCount - math.floor(__player__.score / 100))
end

function CheckMove()
	CameraX, CameraY, CameraZ = CameraX + CameraOffsetX, CameraY + CameraOffsetY, CameraZ + CameraOffsetZ
	SetCameraLookAtPos(CameraX, CameraY, CameraZ)
	CurrentMoveTickCount = CurrentMoveTickCount + 1
	if (CurrentMoveTickCount < PlayerMoveTickCount) then return end
	CurrentMoveTickCount = 0

	local head, tail = PlayerBody[1], PlayerBody[#PlayerBody]
	local x, y, z = head.x, head.y, head.z

	if (PlayerMoveDirection == 0) then x = x - 1 end
	if (PlayerMoveDirection == 1) then x = x + 1 end
	if (PlayerMoveDirection == 2) then z = z + 1 end
	if (PlayerMoveDirection == 3) then z = z - 1 end

	LastPlayerMoveDirection = PlayerMoveDirection

	-- 掉出场外，死亡
	local mapHalfWidth, mapHalfHeight = MapWidth / 2, MapHeight / 2
	if (x < (CenterX - mapHalfWidth) or x > (CenterX + mapHalfWidth) or z < (CenterZ - mapHalfHeight) or z > (CenterZ + mapHalfHeight)) then return PlayerDead() end

	local blockId = GetBlockId(x, y, z)
	if (blockId and blockId ~= 0) then
		for _, color in ipairs(PlayerColorList) do
			if (blockId == color.id) then
				return PlayerDead()
			end
		end

		for _, food in ipairs(FoodBlockList) do
			if (food.id == blockId) then
				SetBlock(x, y, z, 0)
				__player__.score = __player__.score + food.points
				break
			end
		end
	end

	table.remove(PlayerBody, #PlayerBody)
	SetBlock(tail.x, tail.y, tail.z, 0)
	table.insert(PlayerBody, 1, tail)
	tail.x, tail.y, tail.z = x, y, z
	SetBlock(tail.x, tail.y, tail.z, __player__.color)

	SendPlayerBodyData();
	
	local cameraX, cameraY, cameraZ = ConvertToRealPosition(x, y + 1, z)
	CameraOffsetX, CameraOffsetY, CameraOffsetZ = (cameraX - CameraX) / PlayerMoveTickCount, 0, (cameraZ - CameraZ) / PlayerMoveTickCount
end

function PlayerDead()
	IsGaming = nil
	Tip("游戏结束")
end

-- 玩家操作处理
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

-- 定期刷新排行榜
function CheckRanks()
	for username, player in pairs(__all_player__) do
		local isUpdatePlayerScore = false;
		for _, rank in ipairs(__ranks__) do
			if (rank.username == username) then
				isUpdatePlayerScore = true;
				rank.score = player.score;
			end
		end
		if (not isUpdatePlayerScore) then
			table.insert(__ranks__, {username = username, score = player.score});
		end
	end
end

-- 同步主玩家身体数据
function SendPlayerBodyData()
	GGS:Send({username = __username__, body = PlayerBody, color = __player__.color, action = "SyncPlayerBody"});
end

-- 接收玩家身体数据
function RecvPlayerBodyData(data)
	if (data.action ~= "SyncPlayerBody") then return end 
	local oldBody = __all_player_body__[data.username] or {};
	local newBody = data.body or {};
	__all_player_body__[data.username] = newBody;
	for _, item in ipairs(oldBody) do
		SetBlock(item.x, item.y, item.z, 0);
	end
	for _, item in ipairs(newBody) do
		SetBlock(item.x, item.y, item.z, data.color);
	end
end

-- 接受网络数据
GGS:OnRecv(function(data)
	RecvPlayerBodyData(data);
end)

-- 玩家掉线处理
GGS:SetDisconnectCallBack(function(username)
	if (__username__ == username) then return end
	local body = __all_player_body__[username] or {};
	__all_player_body__[username] = nil;
	for _, item in ipairs(body) do
		SetBlock(item.x, item.y, item.z, 0);
	end
end);

-- 排行榜UI
function CreateRankUI()
	local template = [[
<template class="container">
    <div class="title">{{title}}</div>
    <div class="fields-title">
        <div v-for="field in fields" class="field field-title" v-bind:style="field.style">{{field.title}}</div>
    </div>
    <div style="width: 100%; height: 300px; overflow-y: auto;">
        <div v-for="item in data" class="fields fields-content">
            <div v-for="field in fields" class="field" v-bind:style="field.style">{{item[field.key]}}</div>
        </div>
    </div>
</template>

<script type="text/lua">
title = _G.title or "排行榜"
data = _G.data or {{username = "张三", score = 1}, {username = "李四", score = 2}, {username = "王五", score = 3}, {username = "赵六", score = 4}}
fields = _G.fields or {{title = "玩家", key = "username", style="width: 200px"}, {title = "分数", key = "score"}}
</script>

<style scoped=true>
.container {
    width: 300px;
    height: 370px;
    background: url(@/assets/commonmask.png);
}
.title {
    height: 40px;
    line-height: 40px;
    font-size: 26px;
    text-align: center;
    color: #ff0000;
}
.fields-title {
    display: flex;
    color: #ffffff;
}
.field-title {
    font-size: 22px;
}
.field {
    width: 100px;
    font-size: 20px;
	height: 30px;
	line-height: 30px;
    text-align: center;
}
.fields {
    display: flex;
    color: #ffffff;
}
.fields-content:nth-child(1) {
    color: #ff0000;
}
.fields-content:nth-child(2) {
    color: #ffff00;
}
.fields-content:nth-child(3) {
    color: #00ffff;
}
</style>
	]]
	ShowWindow({
		data = __ranks__,
	}, {
		template = template,
		alignment = "_rt",
		width = 320,
		height = 400,
	})
end
