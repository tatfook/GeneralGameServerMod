--[[
NPL.load("(gl)script/Truck/Game/Entity/PlayerManager.lua");
local PlayerManager = commonlib.gettable("Mod.Truck.Game.Entity.PlayerManager");
]]

local PlayerManager = commonlib.gettable("Mod.Truck.Game.Entity.PlayerManager");

NPL.load("(gl)script/Truck/Network/YcEntityPlayerMPClient.lua");
local YcEntityPlayerMPClient = commonlib.gettable("Mod.Truck.Network.YcEntityPlayerMPClient");

NPL.load("(gl)script/Truck/Network/YcEntityPlayerMPOther.lua");
local YcEntityPlayerMPOther = commonlib.gettable("Mod.Truck.Network.YcEntityPlayerMPOther");
NPL.load("(gl)script/Truck/Network/YcProfile.lua");
local YcProfile = commonlib.gettable("Mod.Truck.Network.YcProfile");
    NPL.load("(gl)script/Truck/Utility/CommonUtility.lua");
    local CommonUtility = commonlib.gettable("Mod.Truck.Utility.CommonUtility");
NPL.load("(gl)script/Truck/Game/MultiPlayer/GamingRoomInfo.lua");
local GamingRoomInfo = commonlib.gettable("Mod.Truck.Game.MultiPlayer.GamingRoomInfo");

local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local HeadonUtility = NPL.load("script/Truck/Game/HeadonObject/HeadonUtility.lua");


local playerMain = nil;
local players = {};
function PlayerManager.createMain(id, name, world)
	if (playerMain) then
		commonlib.log("warning: playermain is existed.("..id..")\n")
		PlayerManager.destroyPlayer(id)
		--return playerMain;
	end
	playerMain = YcEntityPlayerMPClient:new();
	playerMain:init(world, id);
	playerMain:Attach();

	EntityManager.SetFocus(playerMain);

	players[id] = playerMain;

	HeadonUtility.initHeadonObjects(playerMain);
	HeadonUtility.setName(playerMain, name)
  
	return playerMain;
end

function PlayerManager.getMain()
	return playerMain;
end

function PlayerManager.createPlayer(id, name, avatar_id, world)
	local player = PlayerManager.getPlayer(id);
	if (player) then
		commonlib.log("error: player (id: " .. id ..",name: ".. name.. ") is existed("..id..")\n");
		return player;
	end
	
	player = YcEntityPlayerMPOther:new():init(world, name, id);
	player:SetCharacterAsset(avatar_id);
	--bind to entitymanager
	player:Attach();

	players[id] = player;
  
	HeadonUtility.initHeadonObjects(player);
	HeadonUtility.setName(player, name)

	commonlib.log("Player: create player, id = "..tostring(id).." name = "..name.."\n")
	return player;
end

function PlayerManager.getPlayer(id)
	return players[id];
end

function PlayerManager.destroyPlayer(id)
	local player = PlayerManager.getPlayer(id)
	if (not player)	then 
		commonlib.log("warning: player is not existed when destroy ("..id..")\n")
		return 
	end;
	if (playerMain == player) then
		EntityManager.SetFocus(nil);
		playerMain = nil

	end;
	--unbind from entityManager
	player:Detach();
	player:Destroy();

	commonlib.log("Player: destroy player, id = "..tostring(id).."\n")

	players[id] = nil;
end

function PlayerManager.destroyAll()
	local id, p ;
	for id, p in pairs(players) do
		PlayerManager.destroyPlayer(id);
	end
end
