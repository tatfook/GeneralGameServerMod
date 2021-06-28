--[[
Title: PlayerAPI
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local PlayerAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/PlayerAPI.lua");
------------------------------------------------------------
]]

local EntityItem = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityItem");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local PlayerAPI = NPL.export();

local __username__ = nil;
local __nickname__ = nil;

local function GetUserInfo()
    return KeepWorkItemManager.GetProfile();
end

local function GetUserId()
    return GetUserInfo().id or 0;
end

local function GetUserName()
    if (__username__) then return __username__ end

    __username__ = GetUserInfo().username;
    if (not __username__ or __username__ == "") then
        __username__ = string.format("User_%s", ParaGlobal.timeGetTime());  -- 可能重名
    end
    
    return __username__;
end

local function SetUserName(username)
    __username__ = username;
end

local function GetNickName()
    return __nickname__ or GetUserInfo().nickname;
end

local function SetNickName(nickname)
    __nickname__ = nickname;
end

local function GetSchoolName()
    local school = GetUserInfo().school;
    return school and school.name;
end

local function GetPlayer(name)
    return EntityManager.GetPlayer(name);
end

local function GetPlayerInventory()
    local player = GetPlayer();
    return player and player.inventory;
end

local function GetHandToolIndex()
    local inventory = GetPlayerInventory();
    if (not inventory) then return end		
    return inventory:GetHandToolIndex()
end

local function SetHandToolIndex(...)
    local inventory = GetPlayerInventory();
    if (not inventory) then return end		
    return inventory:SetHandToolIndex(...);
end

local function CreateItemStack(id, count, serverdata)
    return ItemStack:new():Init(id, count or 1, serverdata);
end

local function SetItemStackInHand(itemStack)
    local inventory = GetPlayerInventory();
    if (not inventory) then return end		
    return inventory:SetBlockInRightHand(itemStack);
end

local function GetItemStackInHand()
    local inventory = GetPlayerInventory();
    if (not inventory) then return end		
    return inventory:GetBlockInRightHand();
end
    
local function SetItemStackToScene(itemStack, bx, by, bz)
    local throwed_item_lifetime = 60;
    local x, y, z = BlockEngine:ConvertToRealPosition_float(bx,by,bz);
    local entity = EntityItem:new():Init(x, y, z, itemStack, throwed_item_lifetime);
    -- 添加至场景
    entity:Attach();
    -- TESTING
    entity:AddVelocity(0,5,0);
end
    
local function GetItemStackFromInventory(index)
    local inventory = GetPlayerInventory();
    if (not inventory) then return end		
    return inventory:GetItem(index);
end

local function SetItemStackToInventory(index, itemstack)
    local inventory = GetPlayerInventory();
    if (not inventory) then return end		
    inventory:SetItemByBagPos(index, itemstack.id, itemstack.count, itemstack);
end

local function RemoveItemFromInventory(index, count)
    local inventory = GetPlayerInventory();
    if (not inventory) then return end		
    inventory:RemoveItem(index, count);
end

setmetatable(PlayerAPI, {__call = function(_, CodeEnv)
    CodeEnv.GetUserId = GetUserId;
    CodeEnv.GetUserName = GetUserName;
    CodeEnv.SetUserName = SetUserName;
    CodeEnv.GetNickName = GetNickName;
    CodeEnv.SetNickName = SetNickName;
    CodeEnv.GetSchoolName = GetSchoolName;
    CodeEnv.GetPlayer = GetPlayer;
    
    CodeEnv.GetPlayerEntityId = function() return EntityManager.GetPlayer().entityId end
    CodeEnv.IsInWater = function() return GameLogic.GetPlayerController():IsInWater() end
	CodeEnv.IsInAir = function() return GameLogic.GetPlayerController():IsInAir() end
    CodeEnv.SetPlayerVisible = function (visible) EntityManager.GetPlayer():SetVisible(visible) end

    CodeEnv.GetPlayerInventory = GetPlayerInventory;
    CodeEnv.GetHandToolIndex = GetHandToolIndex;
    CodeEnv.SetHandToolIndex = SetHandToolIndex;
    CodeEnv.CreateItemStack = CreateItemStack;
    CodeEnv.SetItemStackInHand = SetItemStackInHand;
    CodeEnv.GetItemStackInHand = GetItemStackInHand;
    CodeEnv.SetItemStackToScene = SetItemStackToScene;
    CodeEnv.GetItemStackFromInventory = GetItemStackFromInventory;
    CodeEnv.SetItemStackToInventory = SetItemStackToInventory;
    CodeEnv.RemoveItemFromInventory = RemoveItemFromInventory;
end});
