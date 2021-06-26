--[[
Title: Util
Author(s):  wxa
Date: 2021-06-23
Desc: Util
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Http/Util.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/os/GetUrl.lua")
NPL.load("(gl)script/ide/Encoding.lua")
NPL.load('script/ide/Json.lua')
NPL.load("(gl)script/ide/System/Encoding/jwt.lua")

local Encoding = commonlib.gettable("commonlib.Encoding");
local jwt = commonlib.gettable("System.Encoding.jwt")

local Util = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

-- Decode an URL-encoded string (see RFC 2396)
function Util:DecodeUrl(str)
	if not str then return nil end
	str = string.gsub (str, "+", " ")
	str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
	str = string.gsub (str, "\r\n", "\n")
	return str
end

-- URL-encode a string (see RFC 2396)
function Util:EncodeUrl(str)
	if not str then return nil end
	str = string.gsub (str, "\n", "\r\n")
	str = string.gsub (str, "([^%w ])", function (c) return string.format ("%%%02X", string.byte(c)) end)
	str = string.gsub (str, " ", "+")
	return str
end

-- Encodes a string into its escaped hexadecimal representation
-- @param s:  binary string to be encoded
-- @return escaped representation of string binary
function Util:Escape(s)
    return string.gsub(s, "([^A-Za-z0-9_])", function(c) return string.format("%%%02x", string.byte(c)) end)
end

-- Encodes a string into its escaped hexadecimal representation
-- @param s: binary string to be encoded
-- @return escaped representation of string binary
function Util:Unescape(s)
    return string.gsub(s, "%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
end

-- Parses a string into variables to be stored in an array.
-- @param str: url query string such as "a=1&b&c=3"
-- @return the url params table returned. 
function Util:ParseUrlArgs(str, params)
	params = params or {};
	if(not str) then
		return params;
	end
	for param in string.gmatch (str, "([^&]+)") do
		local k,v = string.match (param, "(.*)=(.*)")
		if(k) then
			k = self:DecodeUrl (k)
			v = self:DecodeUrl (v)
		else
			k, v = param, "";
		end
		if k ~= nil then
			if params[k] == nil then
				params[k] = v
			elseif type (params[k]) == "table" then
				table.insert (params[k], v)
			else
				params[k] = {params[k], v}
			end
		end
	end
	return params;
end

function Util:ToJson(t)
	return commonlib.Json.Encode(t)
end

function Util:FromJson(s)
	return commonlib.Json.Decode(s)
end

function Util:EncodeJwt(payload, secret, expire)
	secret = secret or "keepwork"
	return jwt.encode(payload, secret, "HS256", expire)
end

function Util:DecodeJwt(token, secret)
	secret = secret or "keepwork"
	return jwt.decode(token, secret)
end

function Util:EncodeBase64(text)
	return ParaMisc.base64(text)
end

function Util:DecodeBase64(text)
	return ParaMisc.unbase64(text)
end

function Util:MD5(msg)
	return ParaMisc.md5(msg)
end

function Util:GetUrl(params, callback)
	local method = params.method or "GET"

	if string.upper(method) == "GET" then
		params.qs = params.data
	else
		params.form = params.data
		if params.json == nil then
			params.json = true
		end
	end

	local _, data = System.os.GetUrl(params)
	data.status_code = data.rcode
	return data
end

function Util:IsExistFile(filename)
	local file = io.open(filename, "rb");
	if (file) then file:close() end
	return file ~= nil;
end

function Util:GetFileList(directory, recursive)
	local list = {};
	local function GetFileList(directory, recursive)
		for filename in lfs.dir(directory) do
			if (filename ~= "." and filename ~= "..") then
				local filepath = directory .. "/" .. filename;
				local fileattr = lfs.attributes(filepath);
				if (fileattr.mode == "directory") then
					if (recursive) then GetFileList(filepath, recursive) end
				else
					table.insert(list, #list + 1, filepath);
				end
			end
		end
	end
	GetFileList(directory, nil, recursive);
	return list;
end

-- 获取当前日期
function Util:GetDate()
	return os.date("%Y-%m-%d")
end

function Util:GetTime()
	return os.date("%H:%M:%S")
end

function Util:GetDateTime()
	return os.date("%Y-%m-%d %H:%M:%S")
end

-- 是否是静态资源
function Util:IsFilePath(url)
	local path = url:match("([^?]+)")
	local ext = path:match('^.+%.([a-zA-Z0-9]+)$')
	if (not ext) then return false end
	return true
end

-- ========================================== 解析POST数据=================================================
local function get_boundary(content_type)
	local boundary = string.match(content_type, "boundary%=(.-)$")
	return "--" .. tostring(boundary)
end

local function insert_field(tab, name, value, overwrite)
	if (overwrite or not tab[name]) then
		tab[name] = value
	else
		local t = type(tab[name])
		if t == "table" then
			table.insert(tab[name], value)
		else
			tab[name] = { tab[name], value }
		end
	end
end

local function break_headers(header_data)
	local headers = {}
	for type, val in string.gmatch(header_data, '([^%c%s:]+):%s+([^\n]+)') do
		type = lower(type)
		headers[type] = val
	end
	return headers
end

local function read_field_headers(input, pos)
	local EOH = "\r?\n\r?\n"
	local s, e = string.find(input, EOH, pos)
	if s then
		return break_headers(string.sub(input, pos, s-1)), e+1
	else 
		return nil, pos 
	end
end

local function split_filename(path)
	local name_patt = "[/\\]?([^/\\]+)$"
	return (string.match(path, name_patt))
end

local function get_field_names(headers)
	local disp_header = headers["content-disposition"] or ""
	local attrs = {}
	for attr, val in string.gmatch(disp_header, ';%s*([^%s=]+)="(.-)"') do
		attrs[attr] = val
	end
	return attrs.name, attrs.filename and split_filename(attrs.filename)
end

local function read_field_contents(input, boundary, pos)
	local boundaryline = "\n" .. boundary
	local s, e = string.find(input, boundaryline, pos, true)
	if s then
		if(input:byte(s-1) == 13) then  -- '\r' == 0x0d == 13
			s = s - 1
		end
		return string.sub(input, pos, s-1), s-pos, e+1
	else 
		return nil, 0, pos 
	end
end

local function file_value(file_contents, file_name, file_size, headers)
	local value = { contents = file_contents, name = file_name,	size = file_size }
	for h, v in pairs(headers) do
		if h ~= "content-disposition" then
			value[h] = v
		end
	end
	return value
end

local function fields(input, boundary)
	local state, _ = { }

	_, state.pos = string.find(input, boundary, 1, true)
	if(not state.pos) then
		return function() end;
	end
	state.pos = state.pos + 1
	return function (state, _)
		local headers, name, file_name, value, size
		headers, state.pos = read_field_headers(input, state.pos)
		if headers then
			name, file_name = get_field_names(headers)
			if file_name then
				value, size, state.pos = read_field_contents(input, boundary, state.pos)
				value = file_value(value, file_name, size, headers)
			else
				value, size, state.pos = read_field_contents(input, boundary, state.pos)
			end
		end
		return name, value
	end, state
end

-- @param input: input string
-- @param input_type: the content type containing the boundary text. 
-- @param tab: table of key value pairs, if nil a new table is created and returned. 
-- @return table of key value pairs
function Util:ParseMultipartData(input, input_type, tab, overwrite)
	tab = tab or {}
	local boundary = get_boundary(input_type);
	if(boundary) then
		for name, value in fields(input, boundary) do
			insert_field(tab, name, value, overwrite)
		end
	end
	return tab;
end