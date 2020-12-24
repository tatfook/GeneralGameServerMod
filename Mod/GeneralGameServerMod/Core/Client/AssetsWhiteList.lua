--[[
Title: white list assets
Author(s): wxa
Date: 2020/6/15
Desc: the main player entity on the client side. 
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/AssetsWhiteList.lua");
local AssetsWhiteList = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.AssetsWhiteList");
AssetsWhiteList.IsInWhiteList(filename)
AssetsWhiteList.GetRandomFilename()
-------------------------------------------------------
]]
local AssetsWhiteList = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.AssetsWhiteList");

local  allAssets = commonlib.UnorderedArraySet:new();

allAssets:add("character/CC/02human/paperman/boy01.x")
allAssets:add("character/CC/02human/paperman/boy02.x")
allAssets:add("character/CC/02human/paperman/boy03.x")
allAssets:add("character/CC/02human/paperman/boy04.x")
allAssets:add("character/CC/02human/paperman/boy05.x")
allAssets:add("character/CC/02human/paperman/boy06.x")
allAssets:add("character/CC/02human/paperman/boy07.x")
allAssets:add("character/CC/02human/paperman/girl01.x")
allAssets:add("character/CC/02human/paperman/girl02.x")
allAssets:add("character/CC/02human/paperman/girl03.x")
allAssets:add("character/CC/02human/paperman/girl04.x")
allAssets:add("character/CC/02human/paperman/girl05.x")
allAssets:add("character/v3/Elf/Female/ElfFemale.xml")
allAssets:add("character/CC/02human/paperman/Male_teacher.x")
allAssets:add("character/CC/artwar/movie/school42.x")
allAssets:add("character/CC/artwar/movie/boy_ground_service.x")
allAssets:add("character/CC/artwar/movie/boy_worker_1.x")
allAssets:add("character/CC/artwar/movie/girl_ground_service.x")
allAssets:add("character/CC/artwar/movie/girl_staff_bank.x")
allAssets:add("character/CC/artwar/movie/girl_host.x")
allAssets:add("character/CC/02human/paperman/xiaolong.x")

function AssetsWhiteList.IsInWhiteList(filename)
    return allAssets:contains(filename)
end

function AssetsWhiteList.GetRandomFilename()
    return allAssets[math.random(1, #allAssets)]
end

-- 获取默认模型
function AssetsWhiteList.GetDefaultFilename()
    return "character/CC/02human/paperman/boy01.x";
end

-- 获取所有支持模型列表
function AssetsWhiteList.GetAllAssets()
    return allAssets;
end

-- 添加模型
function AssetsWhiteList.AddAsset(filename)
    allAssets:add(filename);
end

-- 移除模型
function AssetsWhiteList.RemoveAsset(filename)
    allAssets:removeByValue(filename);
end
