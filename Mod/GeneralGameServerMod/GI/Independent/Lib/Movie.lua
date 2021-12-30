
local Movie = inherit(ToolBase, module("Movie"));

Movie:Property("ChannelName");
Movie:Property("Playing", false, "IsPlaying");

function Movie:Init(bx, by, bz)
    local channelName = string.format("movie_%s_%s_%s", bx, by, bz);

    self:SetChannelName(channelName);
    self:SetPlaying(false);

    local channel = __SetMovie__(channelName, bx, by, bz);

    return self;
end

function Movie:Play(timeFrom, timeTo, bLoop)
    if (self:IsPlaying()) then return end 

    self:SetPlaying(true);
    __PlayMovie__(self:GetChannelName(), timeFrom or 0, timeTo or -1, bLoop, __safe_callback__(function()
        self:Stop();
    end));
    
    while (self:IsPlaying()) do sleep() end 
end

function Movie:Stop()
    if (not self:IsPlaying()) then return end 
    self:SetPlaying(false);
    __StopMovie__(self:GetChannelName());
end

