--[[
Title: Request
Author(s):  wxa
Date: 2021-06-23
Desc: Request
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Http/Request.lua");
------------------------------------------------------------
]]

local Util = NPL.load("./Util.lua");

local Request = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Request:Property("Headers");
Request:Property("Params");
Request:Property("Nid");
Request:Property("Path");
Request:Property("Method");
Request:Property("ContentType");

local function string_lower(str)
	return type(str) == "string" and string.lower(str) or nil;
end
function Request:ctor()
end

function Request:Init(msg)
    local headers = {};
    for key, value in pairs(msg) do headers[string_lower(key)] = value end 
	-- echo(headers, true)
	self.__msg__ = msg;
    self:SetHeaders(headers);
    self:SetNid(headers.tid or headers.nid);
    self:SetPath(string.gsub(headers.url, '?.*$', ''));
    self:SetMethod(string_lower(headers.method));
    self:SetContentType(string_lower(headers["content-type"]));
    
    -- 解析参数
    self:ParseParams();

    return self;
end

function Request:GetUrl()
    return self:GetHeaders().url;
end

function Request:GetBody()
    return self:GetHeaders().body;
end

function Request:GetPeerName()
	return NPL.GetIP(self:GetNid());
end

function Request:GetHeader(field)
	return self:GetHeaders()[field] or self.__msg__[field];
end

function Request:ParseParams()
	local urlArgStr = string.match(self:GetUrl(), "?(.+)$")

	if (urlArgStr) then
		self:SetParams(Util:ParseUrlArgs(urlArgStr));
	else
		self:SetParams(self:ParsePostData());
	end
end

function Request:ParsePostData()
	local params = {};
	local body = self:GetBody();
	local contentType = self:GetContentType();

	if (not contentType or not body or body == "") then return params end

	local input_type_lower = string_lower(contentType)
	if (string.find(input_type_lower, "x-www-form-urlencoded")) then
		params = Util:ParseUrlArgs(body)
	elseif (string.find(input_type_lower, "multipart/form-data")) then
		params = Util:ParseMultipartData(body, input_type, params, true);
	elseif (string.find(input_type_lower, "application/json")) then
		params = Util:FromJson(body) 
	else
		params = Util:ParseUrlArgs(body)
	end

    return params;
end






