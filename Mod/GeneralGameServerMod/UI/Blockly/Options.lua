--[[
Title: Options
Author(s): wxa
Date: 2020/6/30
Desc: Const
use the lib:
-------------------------------------------------------
local Options = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Options.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");

local Options = NPL.export();

local actor_options = {};
local function GetActorNameOptions()
    if (not GameLogic.EntityManager) then return actor_options end
    
    local actor_options = {};
    local size = #actor_options;
    local index = 1;
    local entities = GameLogic.EntityManager.FindEntities({category="b", type="EntityCode"});
    if(entities and #entities>0) then
        for _, entity in ipairs(entities) do
            local key = entity:GetFilename();
            if (key and key ~= "") then
                actor_options[index] = {key, key};
                index = index + 1;
            end
        end
    end
    -- local actors = GameLogic.GetCodeGlobal().actors;
    -- for key in pairs(actors) do
    --     actor_options[index] = {key, key};
    --     index = index + 1;
    -- end
    for i = index, size do
        actor_options[i] = nil;
    end
    return actor_options;
end
Options.ActorNameOptions = GetActorNameOptions;

local actor_bone_options = {};
local function GetActorBoneOptions()
    local codeblock = CodeBlockWindow.GetCodeBlock();
    local codeEnv = codeblock and codeblock:GetCodeEnv();
    local actor = codeEnv and codeEnv.actor;
    local variable = type(actor) == "table" and type(actor.GetBonesVariable) == "function" and actor:GetBonesVariable() or nil;
    local bones = type(variable) == "table" and type(variable.GetVariables) == "function" and variable:GetVariables() or nil;
    local index, size = 1, #actor_bone_options;
    if (bones) then
        for key in pairs(bones) do
            actor_bone_options[index] = {key, key};
            index = index + 1;
        end
    end
    for i = index, size do
        actor_bone_options[i] = nil;
    end
    return actor_bone_options;
end


local variable_options = {};
Options.variable_options_callback = function()
    local options = GameLogic.GetCodeGlobal():GetCurrentGlobals();
    local index, size = 1, #variable_options;
    for key in pairs(options) do
        variable_options[index] = {key, key};
        index = index + 1;
    end
    for i = index, size do
        variable_options[i] = nil;
    end
    return variable_options;
end

Options.targetNameType = function()
    local actor_options = GetActorNameOptions();
    table.insert(actor_options, 1, {L"最近的玩家", "@p"});
    table.insert(actor_options, 1, {L"摄影机", "camera"});
    table.insert(actor_options, 1, {L"鼠标", "mouse-pointer"});
    return actor_options;
end

Options.becomeAgentOptions = function()
    local actor_options = GetActorNameOptions();
    table.insert(actor_options, 1, {L"当前玩家", "@p"});
    return actor_options;
end

Options.actorNames = function()
    local actor_options = GetActorNameOptions();
    table.insert(actor_options, 1, {L"此角色", "myself"});
    return actor_options;
end

Options.focus_list = function()
    local actor_options = GetActorNameOptions();
    table.insert(actor_options, 1, {L"此角色", "myself"});
    table.insert(actor_options, 1, {L"主角", "player"});
    return actor_options;
end

Options.isTouchingOptions = function() 
    local actor_options = GetActorNameOptions();
    table.insert(actor_options, 1, { L"某个方块id", "-1" });
    table.insert(actor_options, 1, { L"附近玩家", "@a" });
    table.insert(actor_options, 1, { L"方块", "block" });
    return actor_options;
end

Options.actorBoneNameOptions = GetActorBoneOptions;

Options.actorProperties = function()
    return {
        { L"名字", "name" },
        { L"物理半径", "physicsRadius" },
        { L"物理高度", "physicsHeight" },
        { L"是否有物理", "isBlocker" },
        { L"开启LOD", "isLodEnabled" },
        { L"组Id", "groupId" },
        { L"感知半径", "sentientRadius" },
        { "x", "x" },
        { "y", "y" },
        { "z", "z" },
        { L"时间", "time" },
        { L"朝向", "facing" },
        { L"行走速度", "walkSpeed" },
        { L"俯仰角度", "pitch" },
        { L"翻滾角度", "roll" },
        { L"颜色", "color" },
        { L"透明度", "opacity" },
        { L"选中特效", "selectionEffect" },
        { L"文字", "text" },
        { L"是否为化身", "isAgent" },
        { L"模型文件", "assetfile" },
        { L"绘图代码", "rendercode" },
        { L"Z排序", "zorder" },
        { L"电影方块的位置", "movieblockpos" },
        { L"电影角色", "movieactor" },
        { L"电影播放速度", "playSpeed" },
        { L"广告牌效果", "billboarded" },
        { L"是否投影", "shadowCaster" },
        { L"是否联机同步", "isServerEntity" },

        { L"禁用物理仿真", "dummy" },
        { L"重力加速度", "gravity" },
        { L"速度", "velocity" },
        { L"增加速度", "addVelocity" },
        { L"摩擦系数", "surfaceDecay" },
        { L"空气阻力", "airDecay" },
        { L"相对位置播放", "isRelativePlay" },
        { L"播放时忽略皮肤", "isIgnoreSkinAnim"},
         
        { L"父角色", "parent" },
        { L"父角色位移", "parentOffset" },
        { L"父角色旋转", "parentRot" },

        { L"初始化参数", "initParams" },
        { L"自定义数据", "userData" },
    }
end

Options.keyEventNames = function() 
    return {
        { L"空格", "space" },{ L"任意", "any" },{ L"左", "left" },{ L"右", "right" },{ L"上", "up" },{ L"下", "down" }, { "ESC", "escape" },
        {"a","a"},{"b","b"},{"c","c"},{"d","d"},{"e","e"},{"f","f"},{"g","g"},{"h","h"},
        {"i","i"},{"j","j"},{"k","k"},{"l","l"},{"m","m"},{"n","n"},{"o","o"},{"p","p"},
        {"q","q"},{"r","r"},{"s","s"},{"t","t"},{"u","u"},{"v","v"},{"w","w"},{"x","x"},
        {"y","y"},{"z","z"},
        {"1","1"},{"2","2"},{"3","3"},{"4","4"},{"5","5"},{"6","6"},{"7","7"},{"8","8"},{"9","9"},{"0","0"},
        {"f1","f1"},{"f2","f2"},{"f3","f3"},{"f4","f4"},{"f5","f5"},{"f6","f6"},{"f7","f7"},{"f8","f8"},{"f9","f9"},{"f10","f10"},{"f11","f11"},{"f12","f12"},
        { L"回车", "return" },{ "-", "minus" },{ "+", "equal" },{ "back", "back" },{ "tab", "tab" },
        { "lctrl", "lcontrol" },{ "lshift", "lshift" },{ "lalt", "lmenu" },
        {"num0","numpad0"},{"num1","numpad1"},{"num2","numpad2"},{"num3","numpad3"},{"num4","numpad4"},{"num5","numpad5"},{"num6","numpad6"},{"num7","numpad7"},{"num8","numpad8"},{"num9","numpad9"},
        {L"鼠标滚轮","mouse_wheel"},{L"鼠标按钮","mouse_buttons"}
    }
end

Options.agentEventTypes = function()
    return {
        { L"TryCreate", "TryCreate" },
        { L"OnSelect", "OnSelect" },
        { L"OnDeSelect", "OnDeSelect" },
        { L"GetIcon", "GetIcon" },
        { L"GetTooltip", "GetTooltip" },
        { L"OnClickInHand", "OnClickInHand" },
    }
end

Options.networkEventTypes = function()
    return {
        { L"ps_用户加入", "ps_user_joined" },
        { L"ps_用户离开", "ps_user_left" },
        { L"ps_服务器启动", "ps_server_started" },
        { L"ps_服务器关闭", "ps_server_shutdown" },
        { L"用户加入", "connect" },
    }
end

Options.cmdExamples = function()
    return {
        { L"/tip", "/tip" },
        { L"改变时间[-1,1]", "/time"},
        { L"加载世界:项目id", "/loadworld"},
        { L"设置真实光影[1|2|3]", "/shader"},
        { L"设置光源颜色[0,2] [0,2] [0,2]", "/light"},
        { L"设置太阳颜色[0,2] [0,2] [0,2]", "/sun"},
        { L"发送事件HelloEvent", "/sendevent HelloEvent {data=1}" },
        { L"添加规则:Lever可放在Glowstone上", "/addrule Block CanPlace Lever Glowstone" },
        { L"添加规则:Glowstone可被删除", "/addrule Block CanDestroy Glowstone true" },
        { L"添加规则:人物自动爬坡", "/addrule Player AutoWalkupBlock false" },
        { L"添加规则:人物可跳跃", "/addrule Player CanJump true" },
        { L"添加规则:人物摄取距离为5米", "/addrule Player PickingDist 5" },
        { L"添加规则:人物可在空中继续跳跃", "/addrule Player CanJumpInAir true" },
        { L"添加规则:人物可飞行", "/addrule Player CanFly true" },
        { L"添加规则:人物在水中可跳跃", "/addrule Player CanJumpInWater true" },
        { L"添加规则:人物跳起的速度", "/addrule Player JumpUpSpeed 5" },
        { L"添加规则:人物可跑步", "/addrule Player AllowRunning false" },
        { L"设置最小人物出现距离", "/property -scene MinPopUpDistance 100"},
        { L"设置最大人物多边形数目", "/property -scene MaxCharTriangles 500000"},
        { L"禁用自动人物细节", "/lod off"},
        { L"关闭自动等待", "/autowait false"},
        { L"隐藏物品栏", "/hide quickselectbar"},
        { L"显示物品栏", "/show quickselectbar"},
    }
end

Options.WindowAlignmentOptions = function()
    return {
        { L"左上", "_lt" },
        { L"左下", "_lb" },
        { L"居中", "_ct" },
        { L"居中上", "_ctt" },
        { L"居中下", "_ctb" },
        { L"居中左", "_ctl" },
        { L"居中右", "_ctr" },
        { L"右上", "_rt" },
        { L"右下", "_rb" },
        { L"中间上", "_mt" },
        { L"中间左", "_ml" },
        { L"中间右", "_mr" },
        { L"中间下", "_mb" },
        { L"全屏", "_fi" },
        { L"全局"..":"..L"左上", "global_lt" },
        { L"全局"..":"..L"居中", "global_ct" },
        { L"人物头顶", "headon" },
        { L"人物头顶".."3D", "headon3D" },
    }
end

Options.playNoteTypes = function()
    return {
        { "1", "1" },{ "2", "2" },{ "3", "3" },{ "4", "4" },{ "5", "5" },{ "6", "6" },{ "7", "7" },
        { "c", "c" },{ "d", "d" },{ "e", "e" },{ "f", "f" },{ "g", "g" },{ "a", "a" },{ "b", "b" },
        { "c'", "c'" },{ "d'", "d'" },{ "e'", "e'" },{ "f'", "f'" },{ "g'", "g'" },{ "a'", "a'" },{ "b'", "b'" },
        { "c''", "c''" },{ "d''", "d''" },{ "e''", "e''" },{ "f''", "f''" },{ "g''", "g''" },{ "a''", "a''" },{ "b''", "b''" },
    }
end

Options.playMusicFileTypes = function()
    return {
        { "1", "1" },
        { "2", "2" },
        { "3", "3" },
        { "4", "4" },
        { "5", "5" },
        
        {"黑暗森林", "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg"},
        {"黑暗森林海", "Audio/Haqi/AriesRegionBGMusics/ambDarkForestSea.ogg"},
        {"黑暗平原", "Audio/Haqi/AriesRegionBGMusics/ambDarkPlain.ogg"},
        {"荒漠", "Audio/Haqi/AriesRegionBGMusics/ambDesert.ogg"},
        {"森林1", "Audio/Haqi/AriesRegionBGMusics/ambForest.ogg"},
        {"草原", "Audio/Haqi/AriesRegionBGMusics/ambGrassland.ogg"},
        {"海洋", "Audio/Haqi/AriesRegionBGMusics/ambOcean.ogg"},
        {"嘉年华1", "Audio/Haqi/AriesRegionBGMusics/Area_Carnival.ogg"},
        {"圣诞节", "Audio/Haqi/AriesRegionBGMusics/Area_Christmas.ogg"},
        {"火洞1", "Audio/Haqi/AriesRegionBGMusics/Area_FireCavern.ogg"},
        {"森林2", "Audio/Haqi/AriesRegionBGMusics/Area_Forest.ogg"},
        {"新年", "Audio/Haqi/AriesRegionBGMusics/Area_NewYear.ogg"},
        {"下雪", "Audio/Haqi/AriesRegionBGMusics/Area_Snow.ogg"},
        {"阳光海滩1", "Audio/Haqi/AriesRegionBGMusics/Area_SunnyBeach.ogg"},
        {"城镇", "Audio/Haqi/AriesRegionBGMusics/Area_Town.ogg"},
        {"音乐盒-来自舞者", "Audio/Haqi/Homeland/MusicBox_FromDancer.ogg"},
        {"并行世界", "Audio/Haqi/keepwork/common/bigworld_bgm.ogg"},
        {"开场引导音", "Audio/Haqi/keepwork/common/guide_bgm.ogg"},
        {"登录音效", "Audio/Haqi/keepwork/common/login_bgm.ogg"},
        {"小游戏音效", "Audio/Haqi/keepwork/common/minigame_bgm.ogg"},
        {"单机音效", "Audio/Haqi/keepwork/common/offline_bgm.ogg"},  
        {"行星环绕音效", "Audio/Haqi/keepwork/common/planet_bgm.ogg"},

        -- { L"ogg文件", "filename.ogg" },
        -- { L"wav文件", "filename.wav" },
        -- { L"mp3文件", "filename.mp3" },
    }
end

Options.playSoundFileTypes = function()
    return {
        { L"击碎", "break" },
        { L"ogg文件", "filename.ogg" },
        { L"wav文件", "filename.wav" },
        { L"mp3文件", "filename.mp3" },
        { L"开箱", "chestclosed" },
        { L"关箱", "chestopen" },
        { L"开门", "door_open" },
        { L"关门", "door_close" },
        { L"点击", "click" },
        { L"激活", "trigger" },
        { L"溅射", "splash" },
        { L"水", "water" },
        { L"吃", "eat1" },
        { L"爆炸", "explode1" },
        { L"升级", "levelup" },
        { L"弹出", "pop" },
        { L"掉下", "fallbig1" },
        { L"火", "fire" },
        { L"弓箭", "bow" },
        { L"呼吸", "breath" },
    }
end

Options.isKeyPressedOptions = function()
    return {
        { L"空格", "space" },{ L"左", "left" },{ L"右", "right" },{ L"上", "up" },{ L"下", "down" },{ "ESC", "escape" },
        {"a","a"},{"b","b"},{"c","c"},{"d","d"},{"e","e"},{"f","f"},{"g","g"},{"h","h"},
        {"i","i"},{"j","j"},{"k","k"},{"l","l"},{"m","m"},{"n","n"},{"o","o"},{"p","p"},
        {"q","q"},{"r","r"},{"s","s"},{"t","t"},{"u","u"},{"v","v"},{"w","w"},{"x","x"},
        {"y","y"},{"z","z"},
        {"1","1"},{"2","2"},{"3","3"},{"4","4"},{"5","5"},{"6","6"},{"7","7"},{"8","8"},{"9","9"},{"0","0"},
        {"f1","f1"},{"f2","f2"},{"f3","f3"},{"f4","f4"},{"f5","f5"},{"f6","f6"},{"f7","f7"},{"f8","f8"},{"f9","f9"},{"f10","f10"},{"f11","f11"},{"f12","f12"},
        { L"回车", "return" },{ "-", "minus" },{ "+", "equal" },{ "back", "back" },{ "tab", "tab" },
        { "lctrl", "lcontrol" },{ "lshift", "lshift" },{ "lalt", "lmenu" },
        {"num0","numpad0"},{"num1","numpad1"},{"num2","numpad2"},{"num3","numpad3"},{"num4","numpad4"},{"num5","numpad5"},{"num6","numpad6"},{"num7","numpad7"},{"num8","numpad8"},{"num9","numpad9"},
    }
end

Options.gameModeOptions = function()
    return {
        { L"游戏模式", "game" },{ L"编辑模式", "edit" },
    }
end
