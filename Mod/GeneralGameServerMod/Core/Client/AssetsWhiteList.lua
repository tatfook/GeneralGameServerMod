--[[
Title: white list assets
Author(s): wxa
Date: 2020/6/15
Desc: the main player entity on the client side. 
use the lib:
------------------------------------------------------------
local AssetsWhiteList = NPL.load("./AssetsWhiteList.lua");
AssetsWhiteList.IsInWhiteList(filename)
AssetsWhiteList.GetRandomFilename()
-------------------------------------------------------
]]
local AssetsWhiteList = NPL.export();

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

function AssetsWhiteList.IsInWhiteList(filename)
    return allAssets:contains(filename)
end

function AssetsWhiteList.GetRandomFilename()
    return allAssets[math.random(1, #allAssets)]
end