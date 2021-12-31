
local Movie = inherit(ToolBase, module("Movie"));

Movie:Property("Playing", false, "IsPlaying");

function Movie:ctor()
    self.__bx__, self.__by__, self.__bz__ = 0, 0, 0;
    self.__play_count__ = 0;
end

function Movie:Init(bx, by, bz)
    self.__bx__, self.__by__, self.__bz__ = bx, by, bz;
    self:SetPlaying(false);
    return self;
end

function Movie:GetChannelName()
    return string.format("movie_%s_%s_%s_%s", self.__bx__, self.__by__, self.__bz__, self.__play_count__);
end

function Movie:Play(timeFrom, timeTo, bLoop)
    if (self:IsPlaying()) then return end 

    self:SetPlaying(true);
    self.__play_count__ = self.__play_count__ + 1;
    
    local channelName = self:GetChannelName();
    __SetMovie__(channelName, self.__bx__, self.__by__, self.__bz__);
    __PlayMovie__(channelName, timeFrom or 0, timeTo or -1, bLoop, __safe_callback__(function()
        self:Stop();
    end));
    
    while (self:IsPlaying()) do sleep() end 
end

function Movie:Stop()
    if (not self:IsPlaying()) then return end 
    self:SetPlaying(false);
    __StopMovie__(self:GetChannelName());
end

