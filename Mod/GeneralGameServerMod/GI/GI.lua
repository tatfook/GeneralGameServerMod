--[[
Title: GI
Author(s):  wxa
Date: 2021-06-01
Desc: GI 全局对象
use the lib:
------------------------------------------------------------
local GI = NPL.load("Mod/GeneralGameServerMod/GI/GI.lua");
------------------------------------------------------------
]]
-- 先加载相关脚本, 避免相关文件都需要Load 
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/Truck/Utility/UTF8String.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/PhysicsWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovable.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityItem.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNPC.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local SceneContext = NPL.load("./Independent/SceneContext.lua");
local Independent = NPL.load("./Independent/Independent.lua");
local SandBox = NPL.load("./Independent/SandBox.lua");

local GI = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

GI:Property("Context", SceneContext);
GI:Property("Independent", Independent);
GI:Property("SandBox", SandBox);

function GI:ctor()
    CommonLib.SetAliasPath("gi", "Mod/GeneralGameServerMod/GI");
end

function GI:Init()
    -- 监听世界加载完成事件
    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");

    -- GameLogic:Disconnect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    -- GameLogic:Disconnect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");
end

function GI:OnWorldLoaded()
    -- Independent:OnWorldLoaded();
    -- SandBox:OnWorldLoaded();
    self:GetContext():OnWorldLoaded();

    -- 加载世界默认启动世界目录下的 main.lua 文件
    self:GetSandBox():Start(CommonLib.ToCanonicalFilePath(CommonLib.GetWorldDirectory() .. "/main.lua"));
end

function GI:OnWorldUnloaded()
    self:GetContext():OnWorldUnloaded();
    -- SandBox:OnWorldUnloaded();
    -- Independent:OnWorldUnloaded();
end

-- 共享模式处理键盘鼠标事件
function GI:HandleMouseKeyBoardEvent(event)
    self:GetContext():HandleMouseKeyBoardEvent(event);
end

function GI:GetSandboxAPI() 
    -- if (IsDevEnv) then
    --     self:GetSandBox():Stop();
    --     local SandBox = NPL.load("./Independent/SandBox.lua", true);
    --     local SandBoxAPI = SandBox:GetAPI();
    --     self:SetSandBox(SandBox);
    --     self:SetContext(SandBoxAPI.SceneContext);
    --     return SandBoxAPI;
    -- end
    
    return SandBox:GetAPI();
end

function GI:GetCodeBlockAPI()
    -- if (IsDevEnv) then
    --     self:GetSandBox():Stop();
    --     local SandBox = NPL.load("./Independent/SandBox.lua", true);
    --     local SandBoxCodeBlockAPI = SandBox:GetCodeBlockAPI();
    --     self:SetSandBox(SandBox);
    --     self:SetContext(SandBox:GetAPI().SceneContext);
    --     return SandBoxCodeBlockAPI;
    -- end
    
    return SandBox:GetCodeBlockAPI();
end

GI:InitSingleton():Init();