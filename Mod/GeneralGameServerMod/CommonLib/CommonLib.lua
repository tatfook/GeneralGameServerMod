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
