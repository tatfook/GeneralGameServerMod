--[[
Title: Context
Author(s):  wxa
Date: 2021-06-23
Desc: Context
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Http/Context.lua");
------------------------------------------------------------
]]

local Context = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Context:Property("Request");
Context:Property("Response");

function Context:Init(request, response)
    self:SetRequest(request);
    self:SetResponse(response);

    return self;
end

function Context:GetUrl()
    return self:GetRequest():GetUrl();
end

function Context:GetPath()
    return self:GetRequest():GetPath();
end

function Context:GetMethod()
    return self:GetRequest():GetMethod();
end

function Context:GetParams()
    return self:GetRequest():GetParams();
end

function Context:Get(field)
    return self:GetRequest():GetHeader(field);
end

function Context:Set(field, value)
    return self:GetResponse():SetHeader(field, value);
end

function Context:SetStatusCode(code)
    return self:GetResponse():SetStatusCode(code);
end

function Context:Send(...)
    return self:GetResponse():Send(...);
end

function Context:SendFile(...)
    return self:GetResponse():SendFile(...);
end

function Context:IsFinished()
    return self:GetResponse():IsFinished();
end



