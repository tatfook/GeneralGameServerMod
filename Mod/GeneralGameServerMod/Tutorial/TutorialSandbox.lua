--[[
Author: wxa
Date: 2020-10-26
Desc: 新手引导API 
-----------------------------------------------
local TutorialSandbox = NPL.load("Mod/GeneralGameServerMod/Tutorial/TutorialSandbox.lua");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/SceneContextManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeAPI.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/CameraController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
local CameraController = commonlib.gettable("MyCompany.Aries.Game.CameraController")
local CodeAPI = commonlib.gettable("MyCompany.Aries.Game.Code.CodeAPI");
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local BlockStrategy = NPL.load("./BlockStrategy.lua", IsDevEnv);
local TutorialContext = NPL.load("./TutorialContext.lua", IsDevEnv);
local Http = NPL.load("Mod/GeneralGameServerMod/UI/Window/Api/Http.lua", IsDevEnv);
local Promise = NPL.load("Mod/GeneralGameServerMod/UI/Window/Api/Promise.lua", IsDevEnv);
local Date = NPL.load("Mod/GeneralGameServerMod/UI/Window/Api/Date.lua");
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
-- local Page = NPL.load("./Page/Page.lua", IsDevEnv);

local TutorialSandbox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local ShareData = {};                                                    -- 共享数据, 不会被重置
TutorialSandbox:Property("Context");                                     -- 新手上下文环境
TutorialSandbox:Property("LastContext");                                 -- 上次上下文环境
TutorialSandbox:Property("LeftClickToDestroyBlockStrategy");             -- 配置左击删除方块策略
TutorialSandbox:Property("RightClickToCreateBlockStrategy");             -- 配置右击创建方块策略
TutorialSandbox:Property("ClickStrategy");                               -- 点击策略
TutorialSandbox:Property("Step", 0);                                     -- 第几步
TutorialSandbox:Property("KeepworkAPI");                                 -- keepwork API

function TutorialSandbox:ctor()
    self.CodeAPI = CodeAPI:new()

    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");

    -- 全局变量导出
    self.Http = Http;
    self.Promise = Promise;
    self.Date = Date;
    
    self:SetKeepworkAPI(Http:new():Init({
        baseURL = "https://api.keepwork.com/core/v0/",
        headers = {
            ["content-type"] = "application/json", 
        },
        transformRequest = function(request)
            request.headers["Authorization"] = string.format("Bearer %s", commonlib.getfield("System.User.keepworktoken"));
        end
    }));

    GameLogic.GetFilters():add_filter("ggs_net_data", function(_, data, client)
        if (type(self.netdataCallBack) == "function") then self.netdataCallBack(data, client) end
    end);
end

-- 发送网络数据
function TutorialSandbox:SendNetData(data)
    local dataHandler = AppGeneralGameClient:GetClientDataHandler();
    if (not dataHandler) then return false end
    dataHandler:SendData(data);
    return true;
end

-- 注册网络数据回调
function TutorialSandbox:RegisterNetDataCallBack(callback)
    self.netdataCallBack = callback;
end

-- 重置教学环境
function TutorialSandbox:Reset()
    self.isReseted = true;

    self:SetContext(TutorialContext:new():Init(self));
    self:SetLastContext(SceneContextManager:GetCurrentContext());
    self:SetLeftClickToDestroyBlockStrategy({});
    self:SetRightClickToCreateBlockStrategy({});
    self:SetClickStrategy({});
    self:SetStep(0);
    self.stepTasks = {};                   -- 每步任务
    self.loadItems = {};                   -- 代码方块加载表
    self.allLoadFinishCallback = nil;      -- 全部加载完成回调
    self.pages = {};                       -- UI 窗口集

    self.keyPressEvent = {};

    GameLogic.GetCodeGlobal():GetCurrentGlobals()["TutorialSandbox"] = self;

    self.oldCanJumpInWater = GameLogic.options.CanJumpInWater;
    self.oldCanJump = GameLogic.options.CanJump;
    self.oldCanJumpInAir = GameLogic.options.oldCanJumpInAir;

    GameLogic.options.CanJumpInWater = true;
    GameLogic.options.CanJump = true;
    GameLogic.options.CanJumpInAir = true;

    self.OnWorldLoadedCallBack = nil;
    self.OnWorldUnloadedCallBack = nil;
    self:ActiveTutorialContext();
end

-- 恢复默认环境
function TutorialSandbox:Restore()
    if (not self.isReseted) then return end
    self.isReseted = false;

    GameLogic.options.CanJumpInWater = self.oldCanJumpInWater;
    GameLogic.options.CanJump = self.oldCanJump;
    GameLogic.options.oldCanJumpInAir = self.oldCanJumpInAir;
    
    self:DeactiveTutorialContext()
end

-- 获取共享数据
function TutorialSandbox:GetShareData()
    return ShareData;
end

-- 显示窗口
function TutorialSandbox:ShowWindow(G, params, isNew)
    local page = Page.Show(G, params, isNew);
    if (page) then table.insert(self.pages, page) end
    return page;
end

-- 注册世界加载事件回调
function TutorialSandbox:RegisterWorldLoadedCallBack(callback)
    self.OnWorldLoadedCallBack = callback;
end

-- 注册世界退出事件回调
function TutorialSandbox:RegisterWorldUnloadedCallBack(callback)
    self.OnWorldUnloadedCallBack = callback;
end

function TutorialSandbox:OnWorldLoaded()
    -- self:Reset();
    if (type(self.OnWorldLoadedCallBack) == "function") then self.OnWorldLoadedCallBack() end
end

function TutorialSandbox:OnWorldUnloaded()
    if (type(self.OnWorldUnloadedCallBack) == "function") then self.OnWorldUnloadedCallBack() end

    if (not self.isReseted) then return end
    for _, page in ipairs(self.pages) do page:CloseWindow() end

    self:Restore();
end

function TutorialSandbox:SetCanFly(bFly)
    if (not bFly) then self:GetPlayer():ToggleFly(false) end
    self:GetContext():SetCanFly(bFly);
end

function TutorialSandbox:SetCanJump(bJump)
    self:GetContext():SetCanJump(bJump);
end

function TutorialSandbox:SetLoadItems(loadItems, callback)
    for _, item in ipairs(loadItems) do
        self.loadItems[item] = false;
    end
    self.allLoadFinishCallback = callback;
end

function TutorialSandbox:FinishLoadItem(item)
    self.loadItems[item] = true;
    for item, loaded in pairs(self.loadItems) do
        if (not loaded) then return false end
    end

    if (type(self.allLoadFinishCallback) == "function") then
        self.allLoadFinishCallback();
    end

    return true;
end

-- 下一步
function TutorialSandbox:NextStep(isExecStepTask, ...)
    self:GoStep(self:GetStep() + 1, isExecStepTask, ...);
end

-- 调转至第几步
function TutorialSandbox:GoStep(step, isExecStepTask, ...)
    if (type(step) ~= "number") then return end
    self:SetStep(step);
    if (isExecStepTask) then
        local task = self.stepTasks[self:GetStep()];
        if (type(task) == "function") then
            return task(...);     
        end
    end
end

-- 设置步任务
function TutorialSandbox:SetStepTask(step, task)
    self.stepTasks[step] = task;
end

-- 获取Page
function TutorialSandbox:GetPage()
    return Page;
end

-- 获取玩家
function TutorialSandbox:GetPlayer()
    return EntityManager.GetPlayer();
end

-- 获取玩家库存
function TutorialSandbox:GetPlayerInventory()
    return self:GetPlayer().inventory;
end

-- 设置玩家移速
function TutorialSandbox:SetPlayerSpeedScale(speed)
    local player = EntityManager:GetFocus();
    if(not player) then return end
    player:SetSpeedScale(speed);
end

-- 获取玩家移速
function TutorialSandbox:GetPlayerSpeedScale()
    local player = EntityManager:GetFocus();
    return player and player:GetSpeedScale();
end

-- 获取玩家块位置
function TutorialSandbox:GetPlayerBlockPos()
    return self:GetPlayer():GetBlockPos();
end

-- 设置玩家块位置
function TutorialSandbox:SetPlayerBlockPos(bx, by, bz)
    return self:GetPlayer():SetBlockPos(bx, by, bz);
end

-- 获取坐标通过块位置
function TutorialSandbox:GetPosByBlockPos(bx, by, bz)
    local x, y, z = BlockEngine:real(bx, by, bz);
    y = y - BlockEngine.half_blocksize;
    return x, y, z;
    -- return BlockEngine:ConvertToRealPosition_float(bx, by, bz);
end

-- 左击清除方块策略
function TutorialSandbox:AddLeftClickToDestroyBlockStrategy(strategy)
    strategy.mouseKeyState = 1;
    return self:AddClickStrategy(strategy);
end

-- 移除清除策略
function TutorialSandbox:RemoveLeftClickToDestroyBlockStrategy(strategy)
    self:RemoveClickStrategy(strategy);
end

-- 右击添加方块策略
function TutorialSandbox:AddRightClickToCreateBlockStrategy(strategy)
    strategy.mouseKeyState = 2;
    return self:AddClickStrategy(strategy);
end

-- 移除创建策略
function TutorialSandbox:RemoveRightClickToCreateBlockStrategy(strategy)
    self:RemoveClickStrategy(strategy);
end

-- 添加点击策略
function TutorialSandbox:AddClickStrategy(strategy)
    strategy = BlockStrategy:new():Init(strategy);
    self:GetClickStrategy()[strategy] = strategy;
    return strategy;
end

-- 移除点击策略
function TutorialSandbox:RemoveClickStrategy(strategy)
    self:GetClickStrategy()[strategy] = nil;
end

-- 是否可以点击
function TutorialSandbox:IsCanClick(data)
    local strategy = self:GetClickStrategy();
    for _, item in pairs(strategy) do 
        if (item:IsMatch(data)) then return true end
    end
    return false;
end

-- 激活教学上下文
function TutorialSandbox:ActiveTutorialContext()
    -- local context = SceneContextManager:GetCurrentContext();
    -- if (context == self:GetContext()) then return end
    -- self:SetLastContext(context);
    self:GetContext():activate();
end

-- 激活旧上下文
function TutorialSandbox:DeactiveTutorialContext()
    -- if (self:GetLastContext()) then 
    --     self:GetLastContext():activate();
    -- else
    --     GameLogic.ActivateDefaultContext();
    -- end
    GameLogic.ActivateDefaultContext();
end

-- 获取玩家右手中方块
function TutorialSandbox:GetBlockInRightHand()
    return self:GetPlayer():GetBlockInRightHand();
end

-- 设置玩家右手中方块
function TutorialSandbox:SetBlockInRightHand(blockid_or_item_stack)
    return self:GetPlayer():SetBlockInRightHand(blockid_or_item_stack);
end

-- 是否可以点击3D场景
function TutorialSandbox:SetCanClickScene(bCan)
    return self:GetContext():SetCanClickScene(bCan);
end

-- 注册按键事件
function TutorialSandbox:RegisterKeyPressedEvent(func, name)
    if (type(func) ~= "function") then return end
    self.keyPressEvent[name or func] = func;
end

-- 触发按键事件
function TutorialSandbox:OnKeyPressEvent(event)
    local accept = false;
    for _, func in pairs(self.keyPressEvent) do
        accept = accept or func(event);
    end
    return accept;
end

-- 是否使能右键拖拽视角
function TutorialSandbox:SetParaCameraEnableMouseRightButton(bEnable)
    ParaCamera.GetAttributeObject():SetField("EnableMouseRightButton", bEnable);
end

-- 设置相机
function TutorialSandbox:SetCamera(dist, pitch, facing)
    self.CodeAPI.camera(dist, pitch, facing);
end

-- 获取相机
function TutorialSandbox:GetCamera()
    local att = ParaCamera.GetAttributeObject();
    local dist = att:GetField("CameraObjectDistance");
    local pitch = att:GetField("CameraLiftupAngle") * 180 / math.pi;
    local facing = att:GetField("CameraRotY") * 180 / math.pi;
    return dist, pitch, facing;
end

-- 设置相机模式  ThirdPersonFreeLooking = 0, FirstPerson = 1, ThirdPersonLookCamera = 2,
-- 禁止人物随鼠标转向可以设置模式为1或2 
function TutorialSandbox:SetCameraMode(mode)
    local cameraMode = if_else(mode == 2, CameraController.ThirdPersonLookCamera, if_else(mode == 1, CameraController.FirstPerson, CameraController.ThirdPersonFreeLooking));
    CameraController:SetMode(cameraMode);
end

-- 进入主世界
function TutorialSandbox:EnterMainWorld()
    ParaWorldLoginAdapter:EnterWorld();
end

-- 获取用户信息
function TutorialSandbox:GetUserInfo()
    return KeepWorkItemManager.GetProfile();
end

-- 获取系统用户
function TutorialSandbox:GetSystemUser()
    return System.User;
end

-- 获取系统消息框
function TutorialSandbox:GetSystemMessageBox()
    return _guihelper.MessageBox;
end

-- 获取当前时间的毫秒数
function TutorialSandbox:GetTimeStamp()
    return ParaGlobal.timeGetTime();
end

-- 选择块
function TutorialSandbox:SelectBlock(x, y, z, groupindex)
    ParaTerrain.SelectBlock(x, y, z, true, groupindex or 6);
end

-- 取消选择块
function TutorialSandbox:DeselectBlock(x, y, z, groupindex)
    ParaTerrain.SelectBlock(x, y, z, false, groupindex or 6);
end

-- 取消所有选择块
function TutorialSandbox:DeselectAllBlock(groupindex)
    ParaTerrain.DeselectAllBlock(groupindex or 6);
end

-- 文件是否存在
function TutorialSandbox:IsExistFile(filename)
    filename = ParaWorld.GetWorldDirectory() .. filename;

    local file = ParaIO.open(filename, "r");
    if (file:IsValid()) then
        file:close();
        return true;
    end

    return false;
end

-- 是否启用键盘鼠标
function TutorialSandbox:SetKeyboardMouse(bEnableKeyboard, bEnableMouse)
    ParaScene.GetAttributeObject():SetField("BlockInput", not bEnableMouse);
    ParaCamera.GetAttributeObject():SetField("BlockInput", not bEnableKeyboard);
end

-- 初始化成单列模式
TutorialSandbox:InitSingleton();