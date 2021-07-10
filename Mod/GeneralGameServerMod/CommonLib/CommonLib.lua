--[[
Title: CommonLib
Author(s):  wxa
Date: 2020-06-12
Desc: 公共函数库
use the lib:
------------------------------------------------------------
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/HttpFiles.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
NPL.load("(gl)script/ide/AudioEngine/AudioEngine.lua");
NPL.load("(gl)script/ide/OpenFileDialog.lua");

local AudioEngine = commonlib.gettable("AudioEngine");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local HttpFiles = commonlib.gettable("MyCompany.Aries.Game.Common.HttpFiles");

local List = NPL.load("./List.lua");
local Table = NPL.load("./Table.lua");
local EventEmitter = NPL.load("./EventEmitter.lua");

local __event_emitter__ = EventEmitter:new();

local CommonLib = NPL.export();

_G.CommonLib = CommonLib;

CommonLib.List = List;
CommonLib.Table = Table;
CommonLib.EventEmitter = EventEmitter;

function CommonLib.PlayVoiceText(text, speed, lang, callback)
    local function finish(...) 
        if (type(callback) == "function") then callback(...) end 
    end
    
    if (not text or text == "") then return finish(0) end

    speed = speed or 5;
    lang = lang or "zh";

    local url = format("https://tts.baidu.com/text2audio?per=1&lan=%s&ie=UTF-8&spd=%d&text=%s", lang, speed, commonlib.Encoding.url_encode(text));
    HttpFiles.GetHttpFilePath(url, function(err, diskfilename) 
        if (not diskfilename) then return finish(0) end
        local sound_name = diskfilename:match("[^/\\]+$");
        SoundManager:PlaySound(sound_name, diskfilename);
        local sound = AudioEngine.CreateGet(sound_name);
        local total_time = tonumber(sound:GetSource().TotalAudioTime);
        finish(math.floor(total_time * 1000));
    end)
end


local temp_keys = {};
function CommonLib.ClearTable(t)
    local size = 0;
    for key in pairs(t) do
        size = size + 1;
        temp_keys[size] = key;
    end

    for i = 1, size do
        t[temp_keys[i]] = nil;
    end
end


function CommonLib.ToCanonicalFilePath(filename, platform)
    platform = platform or System.os.GetPlatform();

	if(platform == "win32") then
        filename = string.gsub(filename, "/+", "\\");
		filename = string.gsub(filename, "\\+", "\\");
	else
		filename = string.gsub(filename, "\\+", "/");
        filename = string.gsub(filename, "/+", "/");
	end
	
    return filename;
end

local TextureFilters = {
    {"全部文件(*.png,*.jpg)",  "*.png;*.jpg"},
    {"png(*.png)",  "*.png"},
    {"jpg(*.jpg)",  "*.jpg"},
};
function CommonLib.OpenTextureFileDialog(filters, title, directory)
    local install_directory = ParaIO.GetCurDirectory(0);
    local world_directory = ParaWorld.GetWorldDirectory();
    local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32(filters or TextureFilters,  title or "", directory or world_directory);

    if (not filename) then return filename end
    
    if (string.sub(world_directory, 1, string.len(install_directory)) ~= install_directory) then world_directory = install_directory .. world_directory end
    install_directory = CommonLib.ToCanonicalFilePath(install_directory);
    world_directory = CommonLib.ToCanonicalFilePath(world_directory);

    if (string.sub(filename, 1, string.len(world_directory)) == world_directory) then
        filename = "@" .. string.sub(filename, string.len(world_directory) + 1);
    elseif (string.sub(filename, 1, string.len(install_directory)) == install_directory) then
        filename = string.sub(filename, string.len(install_directory) + 1);
    end

    return filename;
end

-- 获取文件内容
function CommonLib.GetFileText(filename)
    local file = ParaIO.open(filename , "rb");
	if(file:IsValid()) then
		local text = file:GetText(0, -1);
		file:close();
		return text;
    else
        file:close();
	end	
end

-- 计算文本MD5值
function CommonLib.MD5(text)
    return ParaMisc.md5(text or "");
end

-- 获取文件MD5
function CommonLib.GetFileMD5(filename)
    return ParaMisc.md5(CommonLib.GetFileText(filename) or "");
end

-- 获取世界路径
function CommonLib.GetWorldDirectory()
    local install_directory = ParaIO.GetCurDirectory(0);
    local world_directory = ParaWorld.GetWorldDirectory();
    local index = string.find(world_directory, install_directory, 1, true);
    if (index == 1) then return world_directory end
    return CommonLib.ToCanonicalFilePath(install_directory .. "/" .. world_directory);
end

-- 添加接口文件
local PublicFileNo = 500;
local PublicFiles = {};
function CommonLib.AddPublicFile(filename, id)
    if (PublicFiles[filename]) then return end
    PublicFiles[filename] = filename;
    if (not id) then id, PublicFileNo = PublicFileNo, PublicFileNo + 1 end
    -- print("AddPublicFile:", filename, id)
    NPL.AddPublicFile(filename, id);
end

-- 添加地址
local __nids__ = {};
function CommonLib.AddNPLRuntimeAddress(ip, port)
    ip = tostring(ip or "127.0.0.1");
	port = tostring(port or "9000");
	local nid = string.format("%s_%s", ip, port);
    if (not __nids__[nid]) then  
        NPL.AddNPLRuntimeAddress({host = ip, port = port, nid = nid});
        __nids__[nid] = nid;
    end 
    return nid;
end

-- 网络事件
commonlib.setfield("__CommonLib__", CommonLib);
NPL.RegisterEvent(0, "_n_Connections_network", ";__CommonLib__.__OnNetworkEvent__();");
function CommonLib.OnNetworkEvent(callback)
    __event_emitter__:RegisterEventCallBack("__OnNetworkEvent__", callback);
end
function CommonLib.__OnNetworkEvent__()
    __event_emitter__:TriggerEventCallBack("__OnNetworkEvent__", msg);
end
-- NPL_OK = 0, 
-- NPL_Error, 
-- NPL_ConnectionNotEstablished,
-- NPL_QueueIsFull,
-- NPL_StreamError,
-- NPL_RuntimeState_NotExist,
-- NPL_FailedToLoadFile,
-- NPL_RuntimeState_NotReady,
-- NPL_FileAccessDenied,
-- NPL_ConnectionEstablished,
-- NPL_UnableToResolveName,
-- NPL_ConnectionTimeout,
-- NPL_ConnectionDisconnected,
-- NPL_ConnectionAborted,
-- NPL_Command,
-- NPL_WrongProtocol

function CommonLib.IsServerStarted()
    return NPL.GetAttributeObject():GetField("IsServerStarted", false);
end

function CommonLib.GetServerPort()
    return NPL.GetAttributeObject():GetField("HostIP");
end

function CommonLib.GetServerIp()
    return NPL.GetAttributeObject():GetField("HostPort");
end

function CommonLib.GetServerIpAndPort()
    return CommonLib.GetServerIp(), CommonLib.GetServerPort(); 
end

function CommonLib:StartNetServer(ip, port)
    if (CommonLib.IsServerStarted()) then return end
    
    local att = NPL.GetAttributeObject();
	att:SetField("TCPKeepAlive", true);
	att:SetField("KeepAlive", true);
	att:SetField("IdleTimeout", false);
	att:SetField("IdleTimeoutPeriod", 1200000);
	NPL.SetUseCompression(true, true);
	att:SetField("CompressionLevel", -1);
	att:SetField("CompressionThreshold", 1024*16);
	att:SetField("UDPIdleTimeoutPeriod", 1200000);
	att:SetField("UDPCompressionLevel", -1);
	att:SetField("UDPCompressionThreshold", 1024*16);
	__rts__:SetMsgQueueSize(500);

    NPL.StartNetServer(ip or "0.0.0.0", tostring(port or "9000"));
end