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

local CommonLib = NPL.export();

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
    {L"全部文件(*.png,*.jpg)",  "*.png;*.jpg"},
    {L"png(*.png)",  "*.png"},
    {L"jpg(*.jpg)",  "*.jpg"},
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
