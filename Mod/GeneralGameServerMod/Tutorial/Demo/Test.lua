
--[[
Author: wxa
Date: 2020-10-26
Desc: 冬令营开幕式 
-----------------------------------------------
local Test = NPL.load("Mod/GeneralGameServerMod/Tutorial/Demo/Test.lua");

-----------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");

-- http://qiniu-public-dev.keepwork.com/wxacode_bindUser_1246_Z32UC3Bol.jpg


FileDownloader:new():Init("test", "http://qiniu-public-dev.keepwork.com/wxacode_bindUser_1246_Z32UC3Bol.jpg", "temp/test.jpg", function(bSucceed, filename) echo(filename) end, "access plus 0");