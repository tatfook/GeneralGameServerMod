local colorMap = {
	[1] = {id = 2028, name = "红"},
	[2] = {id = 2029, name = "粉"},
	[3] = {id = 2030, name = "橙"},
	[4] = {id = 2031, name = "黄"},
	[5] = {id = 2032, name = "绿"},
	[6] = {id = 2033, name = "青"},
	[7] = {id = 2034, name = "蓝"},
	[8] = {id = 2035, name = "紫"},
}

local foodBlock = {
	{id = 113, points = 1},	
	{id = 114, points = 5},
	{id = 2041, points = 10},
	{id = 116, points = 20},
	{id = 115, points = 50},
}

-- 玩家身体颜色
local playerColor

-- 出生点坐标
local homeX,homeY,homeZ = 19190,4,19259; -- ConvertToBlockIndex(GetHomePosition())

-- 最大玩家数量
local maxPlayerNum = #colorMap -- 8

-- 默认速度
local gameSpeed = 1.2

-- 玩家速度
local playerSpeed

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
local playerBody

-- 地图半径（正方形）
local mapRadius = 50

-- 地图地板ID
local mapBlockId = 5

-- 玩家得分
local playerPoints

local speedUpTime 

-- 地图坐标
local mapTb = {}

function main()
	playerGaming = true
	mapTb = {}
	gaming = true
	playerPoints = 0
	playerBody = {}
	playerSpeed = gameSpeed
	speedUpTime = nil 
	playerColor = colorMap[math.random(1, 8)].id;
	keyPressCount = 0
    
    createMap()
    randomPlaceFood()
	player:SetBlockPos(homeX, homeY, homeZ);
    cmd("/addrule Player CanJump false")
	cmd("/addrule Player AllowRunning false")
	player:SetSpeedScale(playerSpeed)
	
end

function loop()
    if (not gaming) then return end 

	autoWalk()
	if playerGaming then
		checkEat()
		checkMove()
	end
	-- 加速后，延迟恢复速度
	resetSpeed()
end


function createMap()
	for i=homeX-mapRadius,homeX+mapRadius do
		for k=homeZ-mapRadius,homeZ+mapRadius do
			if GetBlockId(i,homeY,k) ~= mapBlockId then
				SetBlock(i,homeY,k,mapBlockId)
			end
			table.insert(mapTb,{i,homeY+1,k})
		end
	end
end

function autoWalk()
	player:EndTouchMove()
	player:TouchMove(GetDirection2DFromCamera())
	player:SetFacing(GetFacingFromCamera())
end

function autoWalk_stop()
	player:EndTouchMove()
end

function clear()
	gaming = nil
	autoWalk_stop()
	for i=1,#mapTb do
		if GetBlockId(mapTb[i][1],mapTb[i][2],mapTb[i][3]) ~= 0 then
			SetBlock(mapTb[i][1],mapTb[i][2],mapTb[i][3],0)
		end
	end
end

function randomPlaceFood()
	SetTimeout(666,function ()
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
			local canPlace = false
			for i=1,#mapTb do
				if GetBlockId(mapTb[i][1],mapTb[i][2],mapTb[i][3]) == 0 then
					canPlace = true
				end
			end

			if canPlace then
				while true do
					local randomNum = math.random(#mapTb)
					if GetBlockId(mapTb[randomNum][1],mapTb[randomNum][2],mapTb[randomNum][3]) == 0 then
						SetBlock(mapTb[randomNum][1],mapTb[randomNum][2],mapTb[randomNum][3],randomFood)
						break
					end
				end
			end
			randomPlaceFood()
		end
	end)
end

function checkEat()
	local x,y,z = player:GetBlockPos()

	for i=1,#foodBlock do
		if foodBlock[i].id == GetBlockId(x,y,z) then
			SetBlock(x,y,z,0)
			modifyPoints(foodBlock[i].points)
			break
		end
	end
end

function modifyPoints(point)
	local symbol
	if point < 0 then
		symbol = ""
	else
		symbol = "+"
	end
	playerPoints = playerPoints + point
	if playerPoints < 0 then
		playerPoints = 0
	end
	--cmd("/tip -point 当前得分："..playerPoints.."("..symbol..point..")")
	setBody()
	playerSpeed = gameSpeed - playerPoints/1500
	if playerSpeed < 0.65 then
		playerSpeed = 0.65
	end
	player:SetSpeedScale(playerSpeed)
end

function setBody()
	local length = math.floor(playerPoints/20) + 2
	local x,y,z = player:GetBlockPos()

	-- 增长
	if length > #playerBody then
		for i=1,length - #playerBody do
			table.insert(playerBody,1,{x,y,z})
			SetBlock(x,y,z,playerColor)
		end
	-- 缩短
	elseif length < #playerBody then
		local foodId = 0
		for i = 1, #foodBlock do
			if math.ceil(playerPoints/#playerBody) >= foodBlock[i].points - 1 then
				foodId = foodBlock[i].id
			end
		end
		for i=1,#playerBody - length do
			SetBlock(playerBody[#playerBody][1],playerBody[#playerBody][2],playerBody[#playerBody][3],foodId)
			table.remove(playerBody,#playerBody)
		end
	end
end

function checkMove()
	local x,y,z = player:GetBlockPos()
	-- 掉出场外，死亡
	if x < (homeX - mapRadius) or x > (homeX + mapRadius) or z < (homeZ - mapRadius) or z > (homeZ + mapRadius) then
		playerDead()
		return
	end
	-- 踩到了其他玩家的身体，死亡
	if GetBlockId(x,y,z) ~= 0 and GetBlockId(x,y,z) ~= playerColor then
		playerDead()
		return
	end
	if playerBody[1] then
		local temp = {}
		local temp2 = {}
		if x ~= playerBody[1][1] or z ~= playerBody[1][3] then
			for i=1,#playerBody do
				SetBlock(playerBody[i][1],playerBody[i][2],playerBody[i][3],0)
				if i == 1 then
					temp[1],temp[2],temp[3] = playerBody[i][1],playerBody[i][2],playerBody[i][3]
					playerBody[i] = {x,y,z}
				else
					temp2[1],temp2[2],temp2[3] = playerBody[i][1],playerBody[i][2],playerBody[i][3]
					playerBody[i][1],playerBody[i][2],playerBody[i][3] = temp[1],temp[2],temp[3]
					temp[1],temp[2],temp[3] = temp2[1],temp2[2],temp2[3]
				end
			end
			for i=1,#playerBody do
				SetBlock(playerBody[i][1],playerBody[i][2],playerBody[i][3],playerColor)
			end
		end
	end
end

function playerDead()
    gaming = nil;
	playerGaming = nil
	local foodId = 0
	if #playerBody > 0 then
		for i=1,#playerBody do
			SetBlock(playerBody[i][1],playerBody[i][2],playerBody[i][3],0)
		end
		for i = 1, #foodBlock do
			if math.ceil(playerPoints/#playerBody) >= foodBlock[i].points - 1 then
				foodId = foodBlock[i].id
			end
		end
		for i=1,#playerBody do
			SetBlock(playerBody[i][1],playerBody[i][2],playerBody[i][3],foodId)
		end
	end
	playerPoints = 0
	playerBody = {}
	playerSpeed = gameSpeed
    exit();
end

RegisterEventCallBack(EventType.MOUSE_KEY, function(event)
	if event.event_type == "keyPressEvent" then
		if event.keyname == "DIK_SPACE" then
			if playerPoints > 0 then
				speedUpTime = os.clock()
				player:SetSpeedScale(playerSpeed*2)
				keyPressCount = keyPressCount + 1
				if keyPressCount % 10 == 0 then
					modifyPoints(-math.ceil(playerPoints/20))
				end
			end
		end 
	end
end)

function resetSpeed()
	if speedUpTime then
		if os.clock() - speedUpTime   > 0.2 then
			player:SetSpeedScale(playerSpeed)
			speedUpTime = nil
		end
	end
end

