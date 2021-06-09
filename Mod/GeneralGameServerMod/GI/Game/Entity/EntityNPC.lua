--[[
Title: EntityNPC
Author(s):  wxa
Date: 2021-06-01
Desc: 定制 entity
use the lib:
------------------------------------------------------------
local EntityNPC = NPL.load("Mod/GeneralGameServerMod/GI/Game/Entity/EntityNPC.lua");
------------------------------------------------------------
]]

local EntityNPC = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC"), NPL.export());