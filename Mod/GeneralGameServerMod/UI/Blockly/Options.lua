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
    local actors = GameLogic.GetCodeGlobal().actors;
    local actor_options = {};
    local size = #actor_options;
    local index = 1;
    for key in pairs(actors) do
        actor_options[index] = {key, key};
        index = index + 1;
    end
    for i = index, size do
        actor_options[i] = nil;
    end
    return actor_options;
end

local actor_bone_options = {};
local function GetActorBoneOptions()
    local codeblock = CodeBlockWindow.GetCodeBlock();
    local codeEnv = codeblock and codeblock:GetCodeEnv();
    local actor = codeEnv and codeEnv.actor;
    local bones = actor and actor:GetBonesVariable():GetVariables();
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

Options.actorBoneNameOptions = GetActorBoneOptions;

Options.actorProperties = function()
    return {
        { L"名字", "name" },
        { L"物理半径", "physicsRadius" },
        { L"物理高度", "physicsHeight" },
        { L"是否有物理", "isBlocker" },
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
        
        { L"父角色", "parent" },
        { L"父角色位移", "parentOffset" },
        { L"父角色旋转", "parentRot" },

        { L"初始化参数", "initParams" },
        { L"自定义数据", "userData" },
    }
end

Options.keyEventNames = function() 
    return {
        { L"空格", "space" },{ L"左", "left" },{ L"右", "right" },{ L"上", "up" },{ L"下", "down" }, { "ESC", "escape" },
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
        { L"ogg文件", "filename.ogg" },
        { L"wav文件", "filename.wav" },
        { L"mp3文件", "filename.mp3" },
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

Options.isTouchingOptions = function() 
    return {
        { L"方块", "block" },
        { L"附近玩家", "@a" },
        { L"某个方块id", "62" },
        { L"某个角色名", "" },
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