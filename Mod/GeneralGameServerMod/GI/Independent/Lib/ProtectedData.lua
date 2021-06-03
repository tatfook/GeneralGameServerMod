--[[
    local ProtectedData = require("ProtectedData")
    local data = {
        level = 1,
        exp = 2,
        props = {
            str = 1,
            dex = 2,
            int = 3,
        }
    }
    local pd = ProtectedData:new(data, pubkey);

    pd.level = 3
    pd.exp = 4
    pd.props.str = 3,
    pd.props.dex = 2,
    pd.props.int = 1,
]]

local ProtectedDataDummy = module("ProtectedData");
local ProtectedData = {};

setmetatable(ProtectedDataDummy, {
__index = ProtectedData, 
__newindex =function (tbl, key, value)
end})

local header = string.format("_%s",string.char(16,4));

local function encode(value ,key)
    local type = type(value)
    if type == "number" then 
        local key = key % 10 + 75;
        local function cal(f,...)
            if f then 
                return f + key, cal(...);
            else
                return 
            end
        end

        return header.. string.char(cal(tostring(value):byte(1, -1)));
    else
        return value;
    end
end

local function decode(value, key)
    local type = type(value)
    if type == "string" then 
        local str = value:match(string.format("^%s(.+)", header));
        if str then
            local key = key %10 + 75;
            local function cal(f,...)
                if f then 
                    return f - key, cal(...)
                else
                    return;
                end
            end

            return tonumber(string.char(cal(str:byte(1,-1))));
        else
            return value;
        end 
    else
        return value;
    end
end

local function checkAndEncode(value, pubkey)
    local vt = type(value);
    if vt == "table" then 
        if value.__class == "pd" then 
            return value.__data;
        else
            return ProtectedData.serialize(value, pubkey);
        end
    else
        return  encode(value,  pubkey)
    end
end


function ProtectedData:new(data, pubkey)
    ProtectedData.serialize(data, pubkey);
    local o = {};


    local functionlist = {
        foreach = function (_,callback)
            for k,v in pairs(data) do 
                callback(k,o[k]);
            end
        end,
        empty = function ()
            return next(data) == nil;
        end,
        clone = function ()
            local newdata = {}
            local function clone(tbl)
                if type(tbl) == "table" then 
                    local newdata = {}
                    for k,v in pairs(tbl) do 
                        newdata[k] = clone(v);
                    end
                    return newdata;
                else
                    return tbl;
                end
            end

            newdata = clone(data);
            return newdata, ProtectedData:new(newdata, pubkey);
        end,
        size = function ()
            return #data;
        end,
        pairs = function ()
            local iter;
            return function ()
                iter = next(data,iter);
                if not iter then 
                    return 
                else
                    return iter, o[iter]; 
                end
            end
        end,
        ipairs = function ()
            local index = 0;
            local count = #data;
            return function ()
                index = index + 1;
                if index <= count then 
                    return index, o[index];
                else
                    return 
                end
            end
        end,
        remove = function (_, index)
            table.remove(data, index);
        end,
        insert = function (_, index,value)
            if value == nil then 
                table.insert(data,checkAndEncode(index,pubkey) );
            else
                table.insert(data,index, checkAndEncode(value,pubkey));
            end
        end,
        sort = function (_, cmp)
            local function getvalue(v)
                if type(v) == "table" then 
                    return ProtectedData:new(v, pubkey);
                else
                    return decode(v, pubkey)
                end
            end
            table.sort(data, function (a,b)
                return cmp(getvalue(a), getvalue(b));
            end)
        end,
        __data = data,
        __class = "pd",
    }

    setmetatable(o, {
        __index = function (tbl, key)
            if functionlist[key] then 
                return functionlist[key]
            elseif ProtectedData[key] then 
                return ProtectedData[key];
            else
                local vt = type (data[key]);
                if vt == "table" then 
                    return ProtectedData:new(data[key], pubkey);
                else
                    return decode(data[key], pubkey);
                end
            end
        end,
        __newindex = function (tbl, key ,value)
            if ProtectedData[key] or functionlist[key] then 
            else
                data[key] = checkAndEncode( value, pubkey);
            end
        end
    })
    return o;
end

function ProtectedData.serialize(data, key)
    for k,v in pairs(data) do 
        local vt = type(v);
       
        if vt == "table" then 
            ProtectedData.serialize(v, key);
        else
            data[k] = encode(v, key);
        end
    end
    return data;
end

function ProtectedData.unserialize(data, key)
    if not key then return end;

    for k,v in pairs(data)do 
        local vt = type(v)
        if vt == "table" then 
            ProtectedData.unserialize(v, key);
        else
            data[k] = decode(v, key);
        end
    end
    return data;
end
