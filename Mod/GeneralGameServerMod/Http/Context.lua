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

function Context:GetPath()
    return self:GetRequest():GetPath();
end

function Context:GetMethod()
    return self:GetRequest():GetMethod();
end

function Context:GetParams()
    return self:GetRequest():GetParams();
end

function Context:Send(...)
    return self:GetResponse():Send(...);
end
