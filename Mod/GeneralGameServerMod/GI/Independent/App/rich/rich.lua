local EntityWatcher = require("EntityWatcher")
local Globals = require("Globals")
local MiniGameUISystem = InitMiniGameUISystem()
local DEBUG=true
-----------------------------------------------------------------------------------------Common Function--------------------------------------------------------------------------------
local function assert(boolean, message)
    if not boolean then
        echo(
            "devilwalk",
            "devilwalk----------------------------------------------------------------assert failed!!!!:message:" ..
                tostring(message)
        )
    end
end
local function getDebugStack()
    if DEBUG then
        return debug.stack(nil,true)
    end
end
local function clone(from)
    local ret
    if type(from) == "table" then
        ret = {}
        for key, value in pairs(from) do
            ret[key] = clone(value)
        end
    else
        ret = from
    end
    return ret
end
local function new(class, parameters)
    local new_table = {}
    setmetatable(new_table, {__index = class})
    for key, value in pairs(class) do
        new_table[key] = clone(value)
    end
    local list = {}
    local dst = new_table
    while dst do
        list[#list + 1] = dst
        dst = dst._super
    end
    for i = #list, 1, -1 do
        list[i].construction(new_table, parameters)
    end
    return new_table
end
local function delete(inst)
    if inst then
        local list = {}
        local dst = inst
        while dst do
            list[#list + 1] = dst
            dst = dst._super
        end
        for i = 1, #list do
            list[i].destruction(inst)
        end
    end
end
local function inherit(class)
    local new_table = {}
    setmetatable(new_table, {__index = class})
    for key, value in pairs(class) do
        new_table[key] = clone(value)
    end
    new_table._super = class
    return new_table
end
local function lineStrings(text)
    local ret = {}
    local line = ""
    for i = 1, string.len(text) do
        local char = string.sub(text, i, i)
        if char == "\n" then
            ret[#ret + 1] = line
            line = ""
        elseif char == "\r" then
        else
            line = line .. char
        end
    end
    if line ~= "\n" and line ~= "" then
        ret[#ret + 1] = line
    end
    return ret
end
local function vec2Equal(vec1, vec2)
    return vec1[1] == vec2[1] and vec1[2] == vec2[2]
end
local function vec3Equal(vec1, vec2)
    return vec1[1] == vec2[1] and vec1[2] == vec2[2] and vec1[3] == vec2[3]
end
local gOriginBlockIDs = {}
local function setBlock(x, y, z, blockID)
    local key = tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
    if not gOriginBlockIDs[key] then
        gOriginBlockIDs[key] = GetBlockId(x, y, z)
    end
    SetBlock(x, y, z, blockID)
end
local function restoreBlock(x, y, z)
    local key = tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
    if gOriginBlockIDs[key] then
        SetBlock(x, y, z, gOriginBlockIDs[key])
    end
end
-----------------------------------------------------------------------------------------Library-----------------------------------------------------------------------------------
Command = {}
CommandQueue = {}
Property = {}
PropertyGroup = {}
EntitySyncer = {}
EntitySyncerManager = {}
-----------------------------------------------------------------------------------------Command-----------------------------------------------------------------------------------
Command.EState = {Unstart = 0, Executing = 1, Finish = 2}
function Command:construction(parameter)
    -- echo("devilwalk", "devilwalk--------------------------------------------debug:Command:construction:parameter:")
    -- echo("devilwalk", parameter)
    self.mDebug = parameter.mDebug
    self.mState = Command.EState.Unstart
    self.mTimeOutProcess = parameter.mTimeOutProcess
end

function Command:destruction()
end

function Command:execute()
    self.mState = Command.EState.Executing
    echo("devilwalk", "devilwalk--------------------------------------------debug:Command:execute:self.mDebug:")
    echo("devilwalk", self.mDebug)
end

function Command:frameMove()
    if self.mState == Command.EState.Unstart then
        self:execute()
    elseif self.mState == Command.EState.Executing then
        self:executing()
    elseif self.mState == Command.EState.Finish then
        self:finish()
        return true
    end
end

function Command:executing()
    self.mExecutingTime = self.mExecutingTime or 0
    if self.mExecutingTime > 1000 then
        if self.mTimeOutProcess then
            self:mTimeOutProcess(self)
        else
            echo(
                "devilwalk",
                "devilwalk--------------------------------------------debug:Command:executing time out:self.mDebug:"
            )
            echo("devilwalk", self.mDebug)
        end
    end
    self.mExecutingTime = self.mExecutingTime + 1
end

function Command:finish()
    echo("devilwalk", "devilwalk--------------------------------------------debug:Command:finish:self.mDebug:")
    echo("devilwalk", self.mDebug)
end

function Command:stop()
    -- echo("devilwalk", "devilwalk--------------------------------------------debug:Command:stop:self.mDebug:")
    -- echo("devilwalk",self.mDebug)
end

function Command:restore()
    -- echo("devilwalk", "devilwalk--------------------------------------------debug:Command:restore:self.mDebug:")
    -- echo("devilwalk",self.mDebug)
end
-----------------------------------------------------------------------------------------CommandQueue-----------------------------------------------------------------------------------
function CommandQueue:construction()
    self.mCommands = {}
end

function CommandQueue:destruction()
    if self.mCommands and #self.mCommands > 0 then
        for _, command in pairs(self.mCommands) do
            echo(
                "devilwalk",
                "devilwalk--------------------------------------------warning:CommandQueue:delete:command:" ..
                    tostring(command.mDebug)
            )
        end
    end
    self.mCommands = nil
end

function CommandQueue:update()
    if self.mCommands[1] then
        local ret = self.mCommands[1]:frameMove()
        if ret then
            table.remove(self.mCommands, 1)
        end
    end
end

function CommandQueue:post(cmd)
    echo("devilwalk", "CommandQueue:post:")
    echo("devilwalk", cmd.mDebug)
    self.mCommands[#self.mCommands + 1] = cmd
end

function CommandQueue:empty()
    return #self.mCommands == 0
end
-----------------------------------------------------------------------------------------Property-----------------------------------------------------------------------------------------
function Property:construction()
    self.mCommandQueue = new(CommandQueue)
    self.mCache = {}
    self.mCommandRead = {}
    self.mCommandWrite = {}
end

function Property:destruction()
    delete(self.mCommandQueue)
    if self.mPropertyListeners then
        for property, listeners in pairs(self.mPropertyListeners) do
            GlobalProperty.removeListener(self:_getLockKey(property), self)
        end
    end
end

function Property:update()
    self.mCommandQueue:update()
end

function Property:lockRead(property, callback)
    GlobalProperty.lockRead(
        self:_getLockKey(property),
        function(value)
            self.mCache[property] = value
            callback(value)
        end
    )
end

function Property:unlockRead(property)
    GlobalProperty.unlockRead(self:_getLockKey(property))
end

function Property:lockWrite(property, callback)
    GlobalProperty.lockWrite(
        self:_getLockKey(property),
        function(value)
            self.mCache[property] = value
            callback(value)
        end
    )
end

function Property:unlockWrite(property)
    GlobalProperty.unlockWrite(self:_getLockKey(property))
end

function Property:write(property, value, callback)
    self.mCache[property] = value
    GlobalProperty.write(self:_getLockKey(property), value, callback)
end

function Property:safeWrite(property, value, callback)
    self.mCache[property] = value
    GlobalProperty.lockAndWrite(self:_getLockKey(property), value, callback)
end

function Property:safeRead(property, callback)
    self:lockRead(
        property,
        function(value)
            self:unlockRead(property)
            callback(value)
        end
    )
end

function Property:read(property, callback)
    GlobalProperty.read(
        self:_getLockKey(property),
        function(value)
            self.mCache[property] = value
            callback(value)
        end
    )
end

function Property:readUntil(property,callback)
    self:read(property,function(value)
        if value then
            callback(value)
        else
            self:readUntil(property,callback)
        end
    end)
end

function Property:commandRead(property)
    -- self.mCommandQueue:post(
    --     new(
    --         Command_Callback,
    --         {
    --             mDebug = "Property:commandRead:" .. property,
    --             mExecuteCallback = function(command)
    --                 self:safeRead(
    --                     property,
    --                     function()
    --                         command.mState = Command.EState.Finish
    --                     end
    --                 )
    --             end
    --         }
    --     )
    -- )
    self.mCommandRead[property] = self.mCommandRead[property] or 0
    self.mCommandRead[property] = self.mCommandRead[property] + 1
    self:safeRead(
        property,
        function()
            self.mCommandRead[property] = self.mCommandRead[property] - 1
            if self.mCommandRead[property]==0 then
                self.mCommandRead[property]=nil
            end
        end
    )
end

function Property:commandWrite(property, value)
    -- self.mCommandQueue:post(
    --     new(
    --         Command_Callback,
    --         {
    --             mDebug = "Property:commandWrite:" .. property,
    --             mExecuteCallback = function(command)
    --                 self:safeWrite(
    --                     property,
    --                     value,
    --                     function()
    --                         command.mState = Command.EState.Finish
    --                     end
    --                 )
    --             end
    --         }
    --     )
    -- )
    self.mCommandWrite[property] = self.mCommandWrite[property] or 0
    self.mCommandWrite[property] = self.mCommandWrite[property] + 1
    self:safeWrite(
        property,
        value,
        function()
            self.mCommandWrite[property] = self.mCommandWrite[property] - 1
            if self.mCommandWrite[property] then
                self.mCommandWrite[property]=nil
            end
        end
    )
end

function Property:commandFinish(callback,timeOutCallback)
    self.mCommandQueue:post(
        new(
            Command_Callback,
            {
                mDebug = "Property:commandFinish",
                mTimeOutProcess = function()
                    echo(
                        "devilwalk",
                        "Property:commandFinish:time out--------------------------------------------------------------"
                    )
                    echo("devilwalk","self.mCommandRead")
                    echo("devilwalk", self.mCommandRead)
                    echo("devilwalk","self.mCommandWrite")
                    echo("devilwalk", self.mCommandWrite)
                    if timeOutCallback then
                        timeOutCallback()
                    end
                end,
                mExecutingCallback = function(command)
                    if not next(self.mCommandRead) and not next(self.mCommandWrite) then
                        callback()
                        command.mState = Command.EState.Finish
                    end
                end
            }
        )
    )
end

function Property:cache()
    return self.mCache
end

function Property:addPropertyListener(property, callbackKey, callback, parameter)
    callbackKey = tostring(callbackKey)
    self.mPropertyListeners = self.mPropertyListeners or {}
    if not self.mPropertyListeners[property] then
        GlobalProperty.addListener(
            self:_getLockKey(property),
            self,
            function(_, value, preValue)
                self.mCache[property] = value
                self:notifyProperty(property, value, preValue)
            end
        )
    end
    self.mPropertyListeners[property] = self.mPropertyListeners[property] or {}
    self.mPropertyListeners[property][callbackKey] = {mCallback = callback, mParameter = parameter}

    self:read(
        property,
        function(value)
            if value then
                callback(parameter, value, value)
            end
        end
    )
end

function Property:removePropertyListener(property, callbackKey)
    callbackKey = tostring(callbackKey)
    if self.mPropertyListeners and self.mPropertyListeners[property] then
        self.mPropertyListeners[property][callbackKey] = nil
    end
end

function Property:notifyProperty(property, value, preValue)
    -- echo("devilwalk", "Property:notifyProperty:property:" .. property)
    -- echo("devilwalk", value)
    if self.mPropertyListeners and self.mPropertyListeners[property] then
        for _, listener in pairs(self.mPropertyListeners[property]) do
            listener.mCallback(listener.mParameter, value, preValue)
        end
    end
end
-----------------------------------------------------------------------------------------Property Group-----------------------------------------------------------------------------------
function PropertyGroup:construction()
    self.mProperties = {}
end

function PropertyGroup:destruction()
end

function PropertyGroup:commandRead(propertyInstance, propertyName)
    propertyInstance:commandRead(propertyName)
    self.mProperties[tostring(propertyInstance)] = true
end

function PropertyGroup:commandWrite(propertyInstance, propertyName, propertyValue)
    propertyInstance:commandWrite(propertyName, propertyValue)
    self.mProperties[tostring(propertyInstance)] = true
end

function PropertyGroup:commandFinish(callback)
    local function _finish(propertyInstance)
        self.mProperties[tostring(propertyInstance)] = nil
        if not next(self.mProperties) then
            callback()
        end
    end
    for property_instance, _ in pairs(self.mProperties) do
        property_instance:commandFinish(
            function()
                _finish(property_instance)
            end
        )
    end
end
-----------------------------------------------------------------------------------------Entity Syncer----------------------------------------------------------------------------------------
function EntitySyncer:construction(parameter)
    if parameter.mEntityID then
        self.mEntityID = parameter.mEntityID
    else
        self.mEntityID = parameter.mEntity.entityId
    end
    self.mCommandQueue = new(CommandQueue)
end

function EntitySyncer:destruction()
end

function EntitySyncer:getEntity()
    return GetEntityById(self.mEntityID)
end

function EntitySyncer:update()
    self.mCommandQueue:update()
end

function EntitySyncer:setDisplayName(name, colour)
    self:broadcast("DisplayName", {mName = name, mColour = colour})
end

function EntitySyncer:setLocalDisplayNameColour(colour)
    self.mLocalDisplayNameColour = colour
    if self:getEntity() then
        self:getEntity():UpdateDisplayName(nil, self.mLocalDisplayNameColour)
    end
end

function EntitySyncer:broadcast(key, value)
    Host.broadcast(
        {mKey = "EntitySyncer", mEntityID = self:getEntity().entityId, mParameter = {mKey = key, mValue = value}}
    )
end

function EntitySyncer:receive(parameter)
    if not self:getEntity() then
        local parameter_clone = clone(parameter)
        self.mCommandQueue:post(
            new(
                Command_Callback,
                {
                    mDebug = "EntitySyncer:receive:mEntityID:" .. tostring(self.mEntityID),
                    mExecutingCallback = function(command)
                        if self:getEntity() then
                            self:receive(parameter_clone)
                            command.mState = Command.EState.Finish
                        end
                    end
                }
            )
        )
    else
        if parameter.mKey == "DisplayName" then
            -- echo("devilwalk","EntitySyncer:receive:DisplayName:"..parameter.mValue)
            self:getEntity():UpdateDisplayName(
                parameter.mValue.mName,
                self.mLocalDisplayNameColour or parameter.mValue.mColour
            )
        end
    end
end
-----------------------------------------------------------------------------------------Entity Syncer Manager----------------------------------------------------------------------------------------
function EntitySyncerManager.singleton()
    if not EntitySyncerManager.mInstance then
        EntitySyncerManager.mInstance = new(EntitySyncerManager)
    end
    return EntitySyncerManager.mInstance
end
function EntitySyncerManager:construction()
    self.mEntities = {}
    Client.addListener("EntitySyncer", self)
end

function EntitySyncerManager:destruction()
    Client.removeListener("EntitySyncer", self)
end

function EntitySyncerManager:update()
    for _, entity in pairs(self.mEntities) do
        entity:update()
    end
end

function EntitySyncerManager:receive(parameter)
    local entity = self.mEntities[parameter.mEntityID]
    if not entity then
        entity = new(EntitySyncer, {mEntityID = parameter.mEntityID})
        self.mEntities[parameter.mEntityID] = entity
    end
    entity:receive(parameter.mParameter)
end

function EntitySyncerManager:attach(entity)
    if not self.mEntities[entity.entityId] then
        self.mEntities[entity.entityId] = new(EntitySyncer, {mEntity = entity})
    end
end

function EntitySyncerManager:get(entity)
    self:attach(entity)
    return self.mEntities[entity.entityId]
end

function EntitySyncerManager:getByEntityID(entityID)
    return self.mEntities[entityID]
end
-----------------------------------------------------------------------------------------Table Define-----------------------------------------------------------------------------------
InputManager = {}
Host = {}
Client = {}
GlobalProperty = {}

Player = {}
PlayerManager = {}
Game = inherit(Property)
GameTerrain = {}
GameHost = {}
GameClient = {}
GameConfig = {}
GameConfig.mRoleBlockIDs = {
    2111,
    2112,
    2113,
    2114,
    2115,
    2116,
    2117,
    2118,
    2119,
    2120,
    2121,
    2122,
    2123,
    2124,
    2125,
    2126
}
GameConfig.mRoleEntityResources = {
    {hash="FsahwZt0kz9W3aGyk9kSvhgeodbK",pid="165",ext="bmax",},
    {hash="FtX-dI8bph8eztlGvHtp3cMuRaRY",pid="166",ext="bmax",},
    {hash="FjiL_8L-yV5E7Y2sadHBRNZWyXH7",pid="167",ext="bmax",},
    {hash="Fhsr2_gxFvjWBns63dggyjtc0mWe",pid="168",ext="bmax",},
    {hash="FgxBHWvBCT95Ji2ZD30rgmsL7zFZ",pid="169",ext="bmax",},
    {hash="Fi4WYH97lHrT49iL4_tJahfBDhYu",pid="170",ext="bmax",},
    {hash="FjXJVbpcn7Rkmipo40JxHYG5imGZ",pid="171",ext="bmax",},
    {hash="FoK0-GticePKpbg5pczBpvbq6pXq",pid="172",ext="bmax",},
    {hash="FhX96IBtzxnFU2_gmyG8bK6aYp6v",pid="173",ext="bmax",},
    {hash="FrRs24ob8EdX1Ti0umB-GxIshyex",pid="174",ext="bmax",},
    {hash="FnUHXSSbaNrCrkkfRBGZrpefqTn0",pid="175",ext="bmax",},
    {hash="Fp2auyIX1Dejhzp-HYDOWqIZ-yAz",pid="176",ext="bmax",},
    {hash="FpxXcK9RqI1K8ppZ9ViDmVxkTgGJ",pid="177",ext="bmax",},
    {hash="FhpW4p95MPcRpxQSYTi2jk03Nwxq",pid="178",ext="bmax",},
    {hash="FtLYB_w8xbwoMI20JjsVA97rQHfR",pid="179",ext="bmax",},
    {hash="FtI4QrzU38bR9mEQby405NwBoxiP",pid="180",ext="bmax",}
}
GameConfig.mRoleEntityScales = {
    1,
    2,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    1,
    1,
    1,
    1,
    1,
    1
}
GameConfig.mRoleImageResources = {
    {hash="FgoPZuJkUV-DWjFcFfM5U9jxLnu5",pid="145",ext="png",},
    {hash="FuKMtX_1tCxtPwrkKi3hr_nwuL13",pid="146",ext="png",},
    {hash="FkWRFCC3KBJGP28-PvuveaAp_QGX",pid="148",ext="png",},
    {hash="FuTRPmcFFRRs3MmYsp2YvUNs3uTW",pid="147",ext="png",},
    {hash="FsofYGFbI3r5_lE6qjPsKLfPBiHS",pid="149",ext="png",},
    {hash="Fndg9HBhBp48XWXJ8l9uFtwNzUhT",pid="150",ext="png",},
    {hash="Fmf4BakNEpT5QPySVSW-RkSb1LZ1",pid="151",ext="png",},
    {hash="Fke9vwAvhtpdx2lITHvQHivIW8z-",pid="152",ext="png",},
    {hash="FsIjNpWUdKK3DDc1eqZtyqotS2yY",pid="153",ext="png",},
    {hash="Fh60EP1UKinrNNw4gA6Hx6MyvkvQ",pid="154",ext="png",},
    {hash="Fv-mPUgFMwKhu8VwrqbzpfIN8xn0",pid="155",ext="png",},
    {hash="Fn3eSRkhPgw3IMQbSibFBYtZwovx",pid="156",ext="png",},
    {hash="Fm1vPJZgQoUy_m29UaWVIj2vUj2h",pid="157",ext="png",},
    {hash="Fmo70xOl2ZJ7witVE889hbL1_CNP",pid="158",ext="png",},
    {hash="FpJBy5qUIe0ugjQDSn4mXKCMzAK9",pid="159",ext="png",},
    {hash="Fk1JZjJNpZ3Qg6RUjAiv5mSMyrAv",pid="160",ext="png",}
}
GameConfig.mConfigBlockID = 211
GameConfig.mWalkBlockIDs = {}
GameConfig.mWalkBlockIDs.mRoadBlockID = 13
GameConfig.mWalkBlockIDs.mPointBlockID_10 = 56
GameConfig.mWalkBlockIDs.mPointBlockID_20 = 5
GameConfig.mWalkBlockIDs.mPointBlockID_30 = 53
GameConfig.mWalkBlockIDs.mPointBlockID_40 = 2079
GameConfig.mWalkBlockIDs.mPointBlockID_50 = 28
GameConfig.mWalkBlockIDs.mBankBlockID = 58
GameConfig.mWalkBlockIDs.mShopBlockID = 2107
GameConfig.mWalkBlockIDs.mTicketBlockID = 145
GameConfig.mWalkBlockIDs.mHospital = 57
GameConfig.mWalkBlockIDs.mPrison = 51
GameConfig.mWalkBlockIDs.mDestiny = 4
GameConfig.mWalkBlockIDs.mChance = 12
GameConfig.mWalkBlockIDs.mStation = 16
GameConfig.mNPCResources = {
    {hash="FurFY6DD4jPZtEfTABFdmRQ4zKkx",pid="4721",ext="FBX",},
    {hash="FgXCmRq_r_j99H_vf2WVcUpb3u5_",pid="4722",ext="FBX",},
    {hash="Ft0rOVBBvbnAeUXRfYP-aSzW2KMb",pid="4727",ext="FBX",},
    {hash="FvEkQxBsulgkyvMijgiBihtdjN_j",pid="4724",ext="FBX",},
    {hash="FpSy0Tl-sv7pgVfnN30eF1Gkq7xg",pid="4734",ext="FBX",},
    {hash="FgMZalPlHD93uRpqiqM1iU7k7Nq3",pid="4728",ext="FBX",},
    {hash="FsAh457caEpreZhwEuItu4ung5pY",pid="4730",ext="FBX",},
    {hash="Figm-HpRjb6Nn9KBl1RhfBNpsyNl",pid="4731",ext="FBX",},
    {hash="Fis57d-M2Hg1utGNYVpUNYq0ViGd",pid="4726",ext="FBX",},
    {hash="Fotyvu_hKr8HokgO_j_vyWNNsAEG",pid="4732",ext="FBX",},
    {hash="FgEhoMZLbqsiG_Hqp9WBa5vztr87",pid="191",ext="FBX",},
    {hash="FqYSVXPGXnxGp2BW_WM4Bs15WiH-",pid="4733",ext="FBX",}
}
-- GameConfig.mNPCTypes = {"小福神", "小财神", "福神", "财神", "小穷神", "小衰神", "穷神", "衰神", "恶魔", "天使", "狗", "土地神"}
GameConfig.mNPCTypes = {}
GameConfig.mNPCEntityScales = {
    0.5,
    0.5,
    0.15,
    0.15,
    0.5,
    0.5,
    0.25,
    0.25,
    0.15,
    0.25,
    0.5,
    0.5,
}
GameConfig.mNPCAttachDay = 3
GameConfig.mCards = {
    {mType = "遥控色子", mResource = {hash="Fvu9ZRAaApTWJdGhAer9_7IKatw5",pid="193",ext="png",}, mPrice = 40},
    {mType = "转向卡", mResource = {hash="FrG6u1GujHnmpUC_OvoUiq_gsysu",pid="194",ext="png",}, mPrice = 30},
    {mType = "障碍卡", mResource = {hash="FvNsCy4oKGGYWiJtfZCDuF6HaBOc",pid="195",ext="png",}, mModelResource={hash="FvSbqF-LKEZCTcYGACnp8clJj95I",pid="275",ext="bmax",}, mPrice = 30},
    {mType = "机车卡", mResource = {hash="Fk0nvPCglAs24JP5Vf2fdY_ejFLA",pid="196",ext="png",}, mPrice = 100},
    {mType = "汽车卡", mResource = {hash="FrYH5bKFvHWWaHEL7dA8g7YRqRz2",pid="197",ext="png",}, mPrice = 200},
    {mType = "抢夺卡", mResource = {hash="FiqU6_F2IkrqfjSxEt04YLpvKnvF",pid="198",ext="png",}, mPrice = 40},
    {mType = "请神卡", mResource = {hash="Fsu2Fo7YllhRTxdaUwx-16wfyHPJ",pid="199",ext="png",}, mPrice = 40},
    {mType = "送神卡", mResource = {hash="Fl6dAbi0tOKEAYlCCIW9-dVHNck3",pid="200",ext="png",}, mPrice = 40},
    {mType = "地雷卡", mResource = {hash="FvIiypPcyd_3nTuCMSSDkZAopqRY",pid="201",ext="png",},mModelResource={hash="FkNbZpdyP5VyZ64yE8RqYncJoSMH",pid="276",ext="bmax",}, mPrice = 30},
    {mType = "定时炸弹", mResource = {hash="Fvdn4KtzKsXP4yNwItY73Dt6bjKF",pid="202",ext="png",}, mModelResource={hash="Fky2dIc5vyMLNCDyg2Q6pePJhDkN",pid="277",ext="bmax",},mPrice = 30},
    {mType = "陷害卡", mResource = {hash="FiEAg8AxeEX6IiwVCnA9DAWzuVNZ",pid="203",ext="png",}, mPrice = 60},
    {mType = "查税卡", mResource = {hash="FksHXeoBsgSrKF8gBZcIBITgPzR_",pid="204",ext="png",}, mPrice = 60},
    {mType = "怪兽卡", mResource = {hash="Ft6SoYAHVOCSJbGdTWzpMvYt_3pG",pid="205",ext="png",}, mPrice = 80},
    {mType = "拆屋卡", mResource = {hash="FvoXEli4DJCdNYWACX43NV7KtAb9",pid="206",ext="png",}, mPrice = 40},
    {mType = "均富卡", mResource = {hash="FnpRiGiAGAN5FrSHFepnJhJK16yP",pid="207",ext="png",}, mPrice = 200},
    {mType = "均贫卡", mResource = {hash="FgaUArW0Z32GSyrNlmDha24NZNSG",pid="208",ext="png",}, mPrice = 200},
    -- {mType = "封印卡", mResource = {ext = "png", pid = "84"}, mPrice = 100},
    {mType = "飞弹卡", mResource = {hash="FjJO_-_5NCXyf6VU2MIOvP9mLMjy",pid="210",ext="png",},mModelResource={hash="FrwJ2e5GdVX8aMghRov5waetE7WV",pid="278",ext="bmax",}, mPrice = 200},
    {mType = "核子炸弹", mResource = {hash="FiB6FqLb3RikSzhMvA4XtJbnPZxB",pid="211",ext="png",},mModelResource={hash="FoEKxJMfIE578YsNWWEQSOOibdpq",pid="279",ext="bmax",}, mPrice = 400},
    {mType = "冬眠卡", mResource = {hash="FsRu0Jr4bVJugY5gwlrZVFbfjIeJ",pid="212",ext="png",}, mPrice = 100},
    -- {mType = "嫁祸卡", mResource = {ext = "png", pid = "89"}, mPrice = 60},
    {mType = "路霸卡", mResource = {hash="FmW3h7Jufpfdsf3_KJMBBkOkX7wi",pid="213",ext="png",}, mPrice = 80},
    {mType = "泡泡卡", mResource = {hash="Fq5YrKaatzym1XpIcFY_EinrVXqG",pid="215",ext="png",}, mPrice = 60},
    {mType = "机器娃娃", mResource = {hash="FpiO4akFciUHaDTmfcEFIMwxo25-",pid="217",ext="png",},mModelResource={hash="Fpwm_tO5WWTM7KdZODWtX-GTr5FB",pid="280",ext="bmax",}, mPrice = 40},
    {mType = "建房卡", mResource = {hash="FmPym4ala5rdV1oCc3MmWTxE8qqu",pid="218",ext="png",}, mPrice = 40},
    {mType = "查封卡", mResource = {hash="FuW-JnQx1Ny7AlpWODVYS3-oTa7w",pid="222",ext="png",}, mPrice = 40},
    {mType = "换房卡", mResource = {hash="FsUibbXHWA77pFOcoicXHYV2gGAn",pid="219",ext="png",}, mPrice = 60},
    {mType = "购地卡", mResource = {hash="FlATMOJ5KJLANEHaDLAbE_UCf-Zt",pid="220",ext="png",}, mPrice = 60},
    {mType = "天使卡", mResource = {hash="FoW3cqzb5iRBhSGsN2H5NVoBNq7z",pid="221",ext="png",}, mPrice = 80},
    -- {mType = "涨价卡", mResource = {ext = "png", pid = "98"}, mPrice = 60},
    {mType = "乌龟卡", mResource = {hash="Fvb1BVTiwzHiLxKseyG6yi4TiZ0V",pid="216",ext="png",}, mPrice = 80},
    {mType = "停留卡", mResource = {hash="FgMN1LWQaqjG5a4PePkFMx1Dmhvv",pid="224",ext="png",}, mPrice = 40},
    {mType = "换位卡", mResource = {hash="FoV0TmBUE1txZU5PK-qg6t96uMPB",pid="225",ext="png",}, mPrice = 40}
    -- {mType = "竹蜻蜓", mResource = {ext = "png", pid = "101"}, mPrice = 80}
}
GameConfig.mMaxCard = 20
GameConfig.mTicketCount = 36
GameConfig.mTicketPrice = 1000
GameConfig.mTerrainNormalMaxLevel = 5
GameConfig.mTerrainSupermarketMaxLevel = 2
GameConfig.mTerrainNormalEntityResource = {
    {hash="Fjcixrvuo3bUOQkZN4RjbVFXT8Qk",pid="228",ext="bmax",},
    {hash="FmMD0h5f16-9YlbNnIqjyGndPE1H",pid="229",ext="bmax",},
    {hash="FmWPPy7K8dYvHGK0WW0PRmOw1G8u",pid="230",ext="bmax",},
    {hash="FmV0wr6ud4nJU83mmyDui4j5o5zP",pid="231",ext="bmax",},
    {{hash="Frzxd81NcIkRo2_1id4qQkRsqhm7",pid="4812",ext="bmax",}, {hash="Fu1GHd8iod1G541RWcJarqbGq1fE",pid="4813",ext="bmax",}}
}
GameConfig.mTerrainSupermarketEntityResource = {hash="FtiUd187A5vwvj1mGXAdZHhbulOM",pid="234",ext="bmax",}
GameConfig.mTicketBouns = 10000
GameConfig.mSuccessCondition = {
    "金钱最多",
    -- "点券最多",
    "土地最多"
}
GameConfig.mDestinies = {
    {hash="FtHdMGqCZbKkAdrK_BtFJ686-W3t",pid="235",ext="png",},
    {hash="Fj253xkinbDo6_4QqzOMz_ovI0hm",pid="236",ext="png",},
    {hash="FreZBp1xI2tgp_oaJjFG2Sa_IC9f",pid="237",ext="png",},
    {hash="FvouIYT484exl-IKpx8TxHEw47qF",pid="238",ext="png",},
    {hash="Fqk2Xi4R1mh9p8n9HE9RfWi_i3s_",pid="239",ext="png",},
    {hash="FrmxUn0jzaZH8hDCPLEUIPCP4iqh",pid="240",ext="png",},
    {hash="Fqdh_BAkYv58VNtpXHmXW8k2BSof",pid="241",ext="png",},
    {hash="FnL_JesoDe1n9n1JtU1tl--hbZrk",pid="242",ext="png",},
    {hash="FhSjzsjLB1rPQE2lg5au6oSCOu_5",pid="243",ext="png",},
    {hash="FsNlTUb6xHKjHhZb-owhb-swRIZc",pid="244",ext="png",},
    {hash="FtYJIYbcv89yXOeM0j4BPfnzV7k7",pid="245",ext="png",},
    {hash="FsPiFf0eR7B8isDzsNb7jceE6_cd",pid="246",ext="png",},
    {hash="Fvz6fDzPe-ntWUlRwG8JAn9EUPcJ",pid="247",ext="png",},
    {hash="FrwaF7u4zclkT-qrzJbjqHbuUsQ-",pid="248",ext="png",},
    {hash="FosPzFy7dHizzdt9m_0m7uTDDU6J",pid="249",ext="png",},
    {hash="FnbZnZQuiJBVu_0urmSj6u9MK0Lm",pid="250",ext="png",},
    {hash="FhlYBMENkmOYCkLBIJwCKM0Y2PCU",pid="251",ext="png",},
    {hash="Fh93l7T-KljE4qgBACuIqvZWckn5",pid="252",ext="png",},
    {hash="FiOnSboYhA1oAIvJElPHz6MIugAN",pid="253",ext="png",},
    {hash="FioLfIgmQSgHd3tHHBY572-9xsBs",pid="254",ext="png",}
}
GameConfig.mChances = {
    {ext="png",hash="Fn475ucLcLKZ7EgjwcaRIG-XGPM7",name="01",pid="381933",},
    {ext="png",hash="Fg_c-ICGBTtD_gsoiW71JxGENrNA",name="02",pid="381934",},
    {ext="png",hash="FizD5U_vpqS1wyUfcrcajCrgp89L",name="03",pid="381935",},
    {ext="png",hash="FhRRFzels1VyHa-RiDW45QnrofTj",name="04",pid="381936",},
    {ext="png",hash="FvUu74eOUgQR14c7C9pg9gPdDLhe",name="05",pid="381937",},
    {ext="png",hash="Fim60owjfcngA1aNO5ZVSVZMfao_",name="06",pid="381938",},
    {ext="png",hash="Fi6-aDmgDfNG_opQgCJGdAlA2WCw",name="07",pid="381939",},
    {ext="png",hash="FuDlYgYoR1wV9hT3WoPDnCd-hVZ8",name="08",pid="381940",},
    {ext="png",hash="FlXsIc8kNZDPanFO6k7vot4-EgFl",name="09",pid="381941",},
    {ext="png",hash="Fv8hMD1Tl7z884574By5aMc_xeQI",name="10",pid="381942",},
    {ext="png",hash="Fr_qs0SOVCbluo-dt5YSXtOyn4nb",name="11",pid="381943",},
    {ext="png",hash="FmZhCHA9SqAn8EIp--uMpRfrOSja",name="12",pid="381944",},
    {ext="png",hash="FhlkXOFeEe8vMSCYuPLFU06aKPz6",name="13",pid="381945",},
    {ext="png",hash="Fq1r2YpyNS1SEt4-9W2DFYE9AHG4",name="14",pid="381946",},
    {ext="png",hash="FvuUxBq0CyA_4OH9EclMphxeRykW",name="15",pid="381947",}
}
GameConfig.getCardByType=function(cardType)
    for _,card in pairs(GameConfig.mCards) do
        if card.mType==cardType then
            return card
        end
    end
end
GameConfig.mThinkTime = 30000
if DEBUG then
    GameConfig.mThinkTime=0
end
GamePlayer = inherit(Property)
GamePlayerHost = {}
GamePlayerClient = {}
GameManagerHost = {}
GameManagerClient = {}
GameUI = {}
GameCompute = {}

Command_Callback = inherit(Command)
Command_UpdatePropertyCacheHost = inherit(Command)
Command_UpdatePropertyCacheClient = inherit(Command)
Command_MoveClient = inherit(Command)
Command_StepClient = inherit(Command)
Command_CheckRoadClient = inherit(Command)
Command_CheckTerrainClient = inherit(Command)
-----------------------------------------------------------------------------------------Game Compute-----------------------------------------------------------------------------------------
function GameCompute.computeTerrainBuyPrice(config, info)
    local level = 1
    if info and info.mLevel then
        level = info.mLevel
    end
    return config.mPrice * level
end

function GameCompute.computeTerrainUpPrice(config, info)
    -- body
    local level = 1
    if info and info.mLevel then
        level = info.mLevel
    end
    return config.mPrice * level
end

function GameCompute.computeTerrainSpend(config, info)
    if info.mType == "连锁超市" then
        return math.floor(config.mSpend * 2.5)
    else
        local level = 1
        if info and info.mLevel then
            level = info.mLevel
        end
        return config.mSpend * level
    end
end

function GameCompute.computeTerrainUpSpend(config, info)
    local level = 1
    if info and info.mLevel then
        level = info.mLevel
    end
    return config.mSpend * (level + 1)
end

function GameCompute.computeMonthDays(month)
    if month == 1 or month == 3 or month == 5 or month == 7 or month == 8 or month == 10 or month == 12 then
        return 31
    elseif month == 2 then
        return 28
    else
        return 30
    end
end

function GameCompute.computeWeekDay(month, day)
    --1月1日礼拜一
    local days_count = 0
    for i = 1, month - 1 do
        days_count = days_count + GameCompute.computeMonthDays(i)
    end
    days_count = days_count + day
    local delta_days_count = days_count - 1
    while delta_days_count >= 7 do
        delta_days_count = delta_days_count - 7
    end
    local week_day = delta_days_count + 1
    return week_day
end

function GameCompute.computeNextMonth(month)
    local ret = month + 1
    while ret > 12 do
        ret = ret - 12
    end
    return ret
end

function GameCompute.computeTomorrow(month, day)
    local month_days = GameCompute.computeMonthDays(month)
    if day < month_days then
        return {mMonth = month, mDay = day + 1}
    else
        return {mMonth = GameCompute.computeNextMonth(month), mDay = 1}
    end
end

function GameCompute.convertDirection123(dir)
    if "x" == dir then
        return {1, 0, 0}
    elseif "-x" == dir then
        return {-1, 0, 0}
    elseif "z" == dir then
        return {0, 0, 1}
    elseif "-z" == dir then
        return {0, 0, -1}
    end
end

function GameCompute.convertDirection321(dir)
    local ret
    if dir[1] == 1 then
        ret = "x"
    elseif dir[1] == -1 then
        ret = "-x"
    elseif dir[3] == 1 then
        ret = "z"
    else
        ret = "-z"
    end
    return ret
end

function GameCompute.computeLeftDirection(dirDesc)
    -- body
    if dirDesc == "x" then
        return "z"
    elseif dirDesc == "-x" then
        return "-z"
    elseif dirDesc == "z" then
        return "-x"
    elseif dirDesc == "-z" then
        return "x"
    end
end

function GameCompute.computeRightDirection(dirDesc)
    if dirDesc == "x" then
        return "-z"
    elseif dirDesc == "-x" then
        return "z"
    elseif dirDesc == "z" then
        return "x"
    elseif dirDesc == "-z" then
        return "-x"
    end
end

function GameCompute.computePlayerDirection(pos, dir, excepts)
    local ret
    local random_dirs = {}
    local dirs = {}
    if dir then
        dirs = {
            dir,
            GameCompute.convertDirection123(GameCompute.computeLeftDirection(GameCompute.convertDirection321(dir))),
            GameCompute.convertDirection123(GameCompute.computeRightDirection(GameCompute.convertDirection321(dir)))
        }
    else
        dirs = {{1, 0, 0}, {-1, 0, 0}, {0, 0, 1}, {0, 0, -1}}
    end
    if excepts then
        for k, temp in pairs(dirs) do
            for _, except in pairs(excepts) do
                if temp[1] == except[1] and temp[2] == except[2] and temp[3] == except[3] then
                    dirs[k] = nil
                end
            end
        end
    end
    for _, temp in pairs(dirs) do
        local next_pos = {pos[1] + temp[1], pos[2] + temp[2], pos[3] + temp[3]}
        local next_block_id, next_block_data, next_entity_data = GetBlockFull(next_pos[1], next_pos[2], next_pos[3])
        if GameConfig.canMove(next_block_id) then
            random_dirs[#random_dirs + 1] = temp
        end
    end
    if 0 == #random_dirs then
        random_dirs[1] = {-dir[1], -dir[2], -dir[3]}
    end
    ret = GameCompute.convertDirection321(random_dirs[math.random(1, #random_dirs)])
    echo("devilwalk", "GameCompute.computePlayerDirection:ret:" .. tostring(ret))
    return ret
end

-----------------------------------------------------------------------------------------Game UI-----------------------------------------------------------------------------------------
function GameUI.messageBox(text, img)
    if GameUI.mMessageBox then
        GameUI.mMessageBoxMessageQueue = GameUI.mMessageBoxMessageQueue or {}
        GameUI.mMessageBoxMessageQueue[#GameUI.mMessageBoxMessageQueue + 1] = text
        return
    end
    GameUI.mMessageBox = MiniGameUISystem.createWindow("RichMan/GameUI/MessageBox", "_ct", 0, 0, 600, 400)
    GameUI.mMessageBox:setZOrder(500)
    local background =
        GameUI.mMessageBox:createUI("Picture", "RichMan/GameUI/MessageBox/Picture", "_lt", 0, 0, 600, 400)
    background:setBackgroundResource(255,0,0,0,0,"Fk2ztiR-hKdBug6TWtytWvAGu3mr")
    if img then
        local image =
            GameUI.mMessageBox:createUI(
            "Picture",
            "RichMan/GameUI/MessageBox/Picture/Image",
            "_lt",
            50,
            100,
            500,
            200,
            background
        )
        image:setBackgroundResource(img.pid,0,0,0,0,img.hash)
    end
    local info = GameUI.mMessageBox:createUI("Text", "RichMan/GameUI/MessageBox/Text", "_lt", 0, 0, 600, 90, background)
    info:setTextFormat(5)
    info:setFontSize(25)
    info:setText(text)
    info:setFontColour("255 255 255")
    local button =
        GameUI.mMessageBox:createUI("Button", "RichMan/GameUI/MessageBox/Button", "_lt", 250, 300, 100, 100, background)
    button:setBackgroundResource(257,0,0,0,0,"FtFq7Cxh7NP2JrWjJX2zUPdWFwJ7")
    button:addEventFunction(
        "onclick",
        function()
            MiniGameUISystem.destroyWindow(GameUI.mMessageBox)
            GameUI.mMessageBox = nil
            if GameUI.mMessageBoxMessageQueue and GameUI.mMessageBoxMessageQueue[1] then
                local new_text = GameUI.mMessageBoxMessageQueue[1]
                table.remove(GameUI.mMessageBoxMessageQueue, 1)
                GameUI.messageBox(new_text)
            end
        end
    )
end

function GameUI.yesOrNo(text, yesCallback, noCallback)
    if GameUI.mYesOrNo then
        MiniGameUISystem.destroyWindow(GameUI.mYesOrNo)
    end
    GameUI.mYesOrNo = MiniGameUISystem.createWindow("RichMan/GameUI/YesOrNo", "_ct", 0, 0, 600, 400)
    GameUI.mYesOrNo:setZOrder(400)
    local background = GameUI.mYesOrNo:createUI("Picture", "RichMan/GameUI/YesOrNo/Picture", "_lt", 0, 0, 600, 400)
    background:setBackgroundResource(255,0,0,0,0,"FioFJRbQmv2kI-oAMqpUKwTVe5ZG")
    local info = GameUI.mYesOrNo:createUI("Text", "RichMan/GameUI/YesOrNo/Text", "_lt", 0, 0, 600, 270, background)
    info:setTextFormat(5)
    info:setFontSize(45)
    info:setText(text)
    info:setFontColour("255 255 255")
    local button_yes =
        GameUI.mYesOrNo:createUI("Button", "RichMan/GameUI/YesOrNo/Button/Yes", "_lt", 200, 300, 100, 50, background)
    button_yes:setFontSize(25)
    button_yes:setBackgroundResource(258,0,0,0,0,"FsDME5crdZJOkcnSw7vIx6MMncrY")
    button_yes:addEventFunction(
        "onclick",
        function()
            MiniGameUISystem.destroyWindow(GameUI.mYesOrNo)
            GameUI.mYesOrNo = nil
            if yesCallback then
                yesCallback()
            end
        end
    )
    local button_no =
        GameUI.mYesOrNo:createUI("Button", "RichMan/GameUI/YesOrNo/Button/No", "_lt", 400, 300, 100, 50, background)
    button_no:setFontSize(25)
    button_no:setBackgroundResource(259,0,0,0,0,"FuANimWrOhUgBl-GgrqeQuc1YuRn")
    button_no:addEventFunction(
        "onclick",
        function()
            MiniGameUISystem.destroyWindow(GameUI.mYesOrNo)
            GameUI.mYesOrNo = nil
            if noCallback then
                noCallback()
            end
        end
    )
end

function GameUI.selectWindow(items)
    if GameUI.mSelectWindow then
        MiniGameUISystem.destroyWindow(GameUI.mSelectWindow)
    end
    GameUI.mSelectWindow = MiniGameUISystem.createWindow("RichMan/GameUI/SelectWindow", "_ct", 0, 0, 200, 100*(#items+1))
    GameUI.mSelectWindow:setZOrder(400)
    local background = GameUI.mSelectWindow:createUI("Picture", "RichMan/GameUI/SelectWindow/Picture", "_lt", 0, 0, 200, 100*(#items+1))
    background:setBackgroundResource(5202,0,0,0,0,"Fvxjaw_34CImCJpL90I1z6uM4Bn3")
    for i,item in pairs(items) do
        local button=GameUI.mSelectWindow:createUI("Button", "RichMan/GameUI/SelectWindow/Button/"..tostring(i), "_lt", 50, 100*i, 100, 100, background)
        button:setFontSize(25)
        if item.mResource then
            button:setBackgroundResource(item.mResource.pid,0,0,0,0,item.mResource.hash)
        end
        if item.mText then
            button:setText(item.mText)
        end
        if item.mOnClick then
            button:addEventFunction(
                "onclick",
                function()
                    MiniGameUISystem.destroyWindow(GameUI.mSelectWindow)
                    GameUI.mSelectWindow = nil
                    item.mOnClick()
                end
            )
        end
    end
end

function GameUI.showEditWindow(index,closeCallback)
    if not index then
        if GameUI.mEditWindow then
            MiniGameUISystem.destroyWindow(GameUI.mEditWindow)
            GameUI.mEditWindow=nil
            return
        end
    end
    local guide_pictures={{hash="FjeKo8_vAzZbp4F4Vc0So3lfSrOu",pid="4227",ext="png",}
    ,{hash="Fuc6R0eEJh7wdhu-xQuDvmLqkNGe",pid="4228",ext="png",}
    ,{hash="FrwnBJztDpbtZTwa5d_7wTXytgb2",pid="4229",ext="png",}
,{hash="FnxB62tj9ijg3nEVWWGUQqNnxork",pid="4230",ext="png",}}
    index=math.min(index,#guide_pictures)
    index=math.max(1,index)
    if not GameUI.mEditWindow then
        GameUI.mEditWindow=MiniGameUISystem.createWindow("RichMan/GameUI/EditWindow", "_ct", 0, 0, 1920, 1080)
        GameUI.mEditWindow:setZOrder(400)
        local background = GameUI.mEditWindow:createUI("Picture", "RichMan/GameUI/EditWindow/Picture", "_lt", 0, 0, 1920, 1080)
        local button_pre = GameUI.mEditWindow:createUI("Button", "RichMan/GameUI/EditWindow/Button/Pre", "_lt", 80, 500, 80, 80, background)
        local button_next = GameUI.mEditWindow:createUI("Button", "RichMan/GameUI/EditWindow/Button/Next", "_lt", 1760, 500, 80, 80, background)
        local button_close = GameUI.mEditWindow:createUI("Button", "RichMan/GameUI/EditWindow/Button/Close", "_lt", 1840, 0, 80, 80, background)
        button_close:setBackgroundResource(270,0,0,0,0,"Fks3BQ5iCMkO8SJmgr1JSgqj0wDP")
        button_close:addEventFunction("onclick",function()
            GameUI.showEditWindow()
            if closeCallback then
                closeCallback()
            end
        end)
    end
    local background = GameUI.mEditWindow:getUI("RichMan/GameUI/EditWindow/Picture")
    background:setBackgroundResource(guide_pictures[index].pid,0,0,0,0,guide_pictures[index].hash)
    local button_pre = GameUI.mEditWindow:getUI("RichMan/GameUI/EditWindow/Button/Pre")
    if index>1 then
        button_pre:setBackgroundResource(264,0,0,0,0,"FlyblQgTdd13iZG3KWa0ti_S7CM2")
        button_pre:addEventFunction("onclick",function()
            GameUI.showEditWindow(index-1,closeCallback)
        end)
    else
        button_pre:setBackgroundFile("")
        button_pre:addEventFunction("onclick",function()end)
    end
    local button_next = GameUI.mEditWindow:getUI("RichMan/GameUI/EditWindow/Button/Next")
    if index<#guide_pictures then
        button_next:setBackgroundResource(265,0,0,0,0,"Fo7EBOINk8hR50ly8pqi9I9S27fC")
        button_next:addEventFunction("onclick",function()
            GameUI.showEditWindow(index+1,closeCallback)
        end)
    else
        button_next:setBackgroundFile("")
        button_next:addEventFunction("onclick",function()end)
    end
end

function GameUI.showPrepareWindow(text)
    if not text then
        if GameUI.mPrepare then
            MiniGameUISystem.destroyWindow(GameUI.mPrepare)
            GameUI.mPrepare = nil
        end
    else
        if not GameUI.mPrepare then
            GameUI.mPrepare = MiniGameUISystem.createWindow("RichMan/GameUI/Prepare", "_lt", 0, 150, 1920, 100)
            local background =
                GameUI.mPrepare:createUI("Picture", "RichMan/GameUI/Prepare/Picture", "_lt", 0, 0, 1920, 100)
            background:setBackgroundResource(260,0,0,0,0,"FnQFSBZWAQIe7Ph3PLOai0J0n3AE")
            local info =
                GameUI.mPrepare:createUI("Text", "RichMan/GameUI/Prepare/Text", "_lt", 0, 0, 1920, 100, background)
            info:setTextFormat(5)
            info:setFontSize(30)
            info:setText(text)
            info:setFontColour("255 255 255")
        end
        GameUI.mPrepare:getUI("RichMan/GameUI/Prepare/Text"):setText(text)
    end
end

function GameUI.showBasicWindow(player)
    local week_day_texts = {"一", "二", "三", "四", "五", "六", "日"}
    if not GameUI.mBasicInfoWindowUp then
        local base_info_window_up = MiniGameUISystem.createWindow("RichMan/GameUI/BaseInfoUp", "_lt", 0, 0, 1920, 150)
        base_info_window_up:setZOrder(100)
        local picture_money =
            base_info_window_up:createUI("Picture", "RichMan/GameUI/BaseInfoUp/Picture_Money", "_lt", 20, 20, 300, 100)
        picture_money:setBackgroundResource(5200,0,0,0,0,"FqfG0jNh8zZivJKhww46wGv-iNOZ")
        local money_text =
            base_info_window_up:createUI(
            "Text",
            "RichMan/GameUI/BaseInfoUp/Text_Money",
            "_lt",
            110,
            0,
            190,
            100,
            picture_money
        )
        money_text:setTextFormat(5)
        money_text:setFontSize(25)
        money_text:setFontColour("255 255 255")

        local picture_money_store =
            base_info_window_up:createUI(
            "Picture",
            "RichMan/GameUI/BaseInfoUp/Picture_MoneyStore",
            "_lt",
            520,
            20,
            300,
            100
        )
        picture_money_store:setBackgroundResource(5199,0,0,0,0,"FttjVU7zLUxZwHYK3Qjt48n1oUpX")
        local money_store_text =
            base_info_window_up:createUI(
            "Text",
            "RichMan/GameUI/BaseInfoUp/Text_MoneyStore",
            "_lt",
            110,
            0,
            190,
            100,
            picture_money_store
        )
        money_store_text:setTextFormat(5)
        money_store_text:setFontSize(25)
        money_store_text:setFontColour("255 255 255")

        local picture_point =
            base_info_window_up:createUI("Picture", "RichMan/GameUI/BaseInfoUp/Picture_Point", "_lt", 920, 20, 300, 100)
        picture_point:setBackgroundResource(5198,0,0,0,0,"FkLQM1-Ve0QjIYnTm1OkyOA09UAk")
        local point_text =
            base_info_window_up:createUI(
            "Text",
            "RichMan/GameUI/BaseInfoUp/Text_Point",
            "_lt",
            110,
            0,
            190,
            100,
            picture_point
        )
        point_text:setTextFormat(5)
        point_text:setFontSize(25)
        point_text:setFontColour("255 255 255")

        GameUI.mBasicInfoWindowUp = base_info_window_up

        player:getProperty():addPropertyListener(
            "mMoney",
            "GameUI.showBasicWindow",
            function(_, value)
                money_text:setText(tostring(value))
            end
        )
        player:getProperty():addPropertyListener(
            "mMoneyStore",
            "GameUI.showBasicWindow",
            function(_, value)
                money_store_text:setText(tostring(value))
            end
        )
        player:getProperty():addPropertyListener(
            "mPoint",
            "GameUI.showBasicWindow",
            function(_, value)
                point_text:setText(tostring(value))
            end
        )
    end
    if not GameUI.mBasicInfoWindowDown then
        local base_info_window_down =
            MiniGameUISystem.createWindow("RichMan/GameUI/BaseInfoDown", "_lb", 0, 0, 1920, 330)
        base_info_window_down:setZOrder(100)
        local picture_player =
            base_info_window_down:createUI(
            "Picture",
            "RichMan/GameUI/BaseInfoDown/Picture/Player",
            "_lt",
            0,
            0,
            300,
            300
        )
        player:getProperty():addPropertyListener(
            "mResource",
            "GameUI.showBasicWindow",
            function(_, value)
                picture_player:setBackgroundResource(GameConfig.mRoleImageResources[value].pid,0,0,0,0,GameConfig.mRoleImageResources[value].hash)
            end
        )
        local month_picture =
            base_info_window_down:createUI(
            "Picture",
            "RichMan/GameUI/BaseInfoDown/Picture/Month",
            "_lt",
            0,
            300,
            100,
            30
        )
        local month_text =
            base_info_window_down:createUI(
            "Text",
            "RichMan/GameUI/BaseInfoDown/Picture/Month",
            "_lt",
            0,
            0,
            100,
            30,
            month_picture
        )
        month_text:setTextFormat(5)
        month_text:setFontSize(20)
        local day_picture =
            base_info_window_down:createUI(
            "Picture",
            "RichMan/GameUI/BaseInfoDown/Picture/Day",
            "_lt",
            100,
            300,
            100,
            30
        )
        local day_text =
            base_info_window_down:createUI(
            "Text",
            "RichMan/GameUI/BaseInfoDown/Picture/Day",
            "_lt",
            0,
            0,
            100,
            30,
            day_picture
        )
        day_text:setTextFormat(5)
        day_text:setFontSize(20)
        local week_pickture =
            base_info_window_down:createUI(
            "Picture",
            "RichMan/GameUI/BaseInfoDown/Picture/Week",
            "_lt",
            200,
            300,
            100,
            30
        )
        local week_text =
            base_info_window_down:createUI(
            "Text",
            "RichMan/GameUI/BaseInfoDown/Picture/Week",
            "_lt",
            0,
            0,
            100,
            30,
            week_pickture
        )
        week_text:setTextFormat(5)
        week_text:setFontSize(20)
        player.mGame:getProperty():addPropertyListener(
            "mDay",
            "GameUI.showBasicWindow",
            function(_, value)
                echo(
                    "devilwalk",
                    "GameUI.showBasicWindow:Day:" .. tostring(value.mMonth) .. "," .. tostring(value.mDay)
                )
                month_text:setText(tostring(value.mMonth) .. "月")
                day_text:setText(tostring(value.mDay) .. "日")
                week_text:setText("星期" .. week_day_texts[GameCompute.computeWeekDay(value.mMonth, value.mDay)])
            end
        )
        local picture_card_bar =
            base_info_window_down:createUI(
            "Picture",
            "RichMan/GameUI/BaseInfoDown/Picture_CardBar",
            "_lt",
            350,
            130,
            1500,
            200
        )
        picture_card_bar:setBackgroundResource(260,0,0,0,0,"FnQFSBZWAQIe7Ph3PLOai0J0n3AE")
        local function _refreshCardWindow(cards)
            if GameUI.mCardWindow then
                MiniGameUISystem.destroyWindow(GameUI.mCardWindow)
                GameUI.mCardWindow = nil
            end
            GameUI.mCardWindow = MiniGameUISystem.createWindow("RichMan/GameUI/Card", "_lb", 400, 20, 1400, 180)
            GameUI.mCardWindow:setZOrder(101)
            if cards then
                for i = 1, 10 do
                    local card = cards[i]
                    if not card then
                        break
                    end
                    local card_button =
                        GameUI.mCardWindow:createUI(
                        "Button",
                        "RichMan/GameUI/Card/Button/" .. tostring(i),
                        "_lt",
                        (i - 1) * 140,
                        10,
                        100,
                        180
                    )
                    --echo("devilwalk", "--------------------------------------------------------" .. card)
                    card_button:setBackgroundResource(GameConfig.mCards[card].mResource.pid,0,0,0,0,GameConfig.mCards[card].mResource.hash)
                    card_button:addEventFunction(
                        "onclick",
                        function()
                            if not GameUI.mCurrentUI then
                                player:useCard(card)
                            end
                        end
                    )
                end
            end
        end
        local button_card_bar_left =
            base_info_window_down:createUI(
            "Button",
            "RichMan/GameUI/BaseInfoDown/Button/CardBarLeft",
            "_lt",
            15,
            90,
            35,
            35,
            picture_card_bar
        )
        button_card_bar_left:setBackgroundResource(264,0,0,0,0,"FlyblQgTdd13iZG3KWa0ti_S7CM2")
        button_card_bar_left:addEventFunction(
            "onclick",
            function()
                GameUI.mCardWindowOffset = GameUI.mCardWindowOffset or 0
                GameUI.mCardWindowOffset = math.max(0, GameUI.mCardWindowOffset - 1)
                if #player:getPropertyCache().mCards >= 10 then
                    while #player:getPropertyCache().mCards - GameUI.mCardWindowOffset < 10 do
                        GameUI.mCardWindowOffset = GameUI.mCardWindowOffset - 1
                    end
                end
                local cards = {}
                for i = 1 + GameUI.mCardWindowOffset, #player:getPropertyCache().mCards do
                    cards[#cards + 1] = player:getPropertyCache().mCards[i]
                    if #cards >= 10 then
                        break
                    end
                end
                _refreshCardWindow(cards)
            end
        )
        player:getProperty():addPropertyListener(
            "mCards",
            "GameUI.showBasicWindow",
            function(_, value)
                _refreshCardWindow(value)
            end
        )
        local button_card_bar_right =
            base_info_window_down:createUI(
            "Button",
            "RichMan/GameUI/BaseInfoDown/Button/CardBarRight",
            "_lt",
            1450,
            90,
            35,
            35,
            picture_card_bar
        )
        button_card_bar_right:setBackgroundResource(265,0,0,0,0,"Fo7EBOINk8hR50ly8pqi9I9S27fC")
        button_card_bar_right:addEventFunction(
            "onclick",
            function()
                GameUI.mCardWindowOffset = GameUI.mCardWindowOffset or 0
                GameUI.mCardWindowOffset = GameUI.mCardWindowOffset + 1
                if #player:getPropertyCache().mCards >= 10 then
                    while #player:getPropertyCache().mCards - GameUI.mCardWindowOffset < 10 do
                        GameUI.mCardWindowOffset = GameUI.mCardWindowOffset - 1
                    end
                else
                    GameUI.mCardWindowOffset = 0
                end
                local cards = {}
                for i = 1 + GameUI.mCardWindowOffset, #player:getPropertyCache().mCards do
                    cards[#cards + 1] = player:getPropertyCache().mCards[i]
                    if #cards >= 10 then
                        break
                    end
                end
                _refreshCardWindow(cards)
            end
        )
        GameUI.mBasicInfoWindowDown = base_info_window_down
    end
end

function GameUI.closeBasicWindow(player)
    if GameUI.mBasicInfoWindowUp then
        player:getProperty():removePropertyListener("mMoney", "GameUI.showBasicWindow")
        player:getProperty():removePropertyListener("mMoneyStore", "GameUI.showBasicWindow")
        player:getProperty():removePropertyListener("mPoint", "GameUI.showBasicWindow")
        MiniGameUISystem.destroyWindow(GameUI.mBasicInfoWindowUp)
        GameUI.mBasicInfoWindowUp = nil
    end
    if GameUI.mBasicInfoWindowDown then
        player:getProperty():removePropertyListener("mResource", "GameUI.showBasicWindow")
        player:getGame():getProperty():removePropertyListener("mDay", "GameUI.showBasicWindow")
        MiniGameUISystem.destroyWindow(GameUI.mBasicInfoWindowDown)
        GameUI.mBasicInfoWindowDown = nil
    end
    if GameUI.mCardWindow then
        player:getProperty():removePropertyListener("mCards", "GameUI.showBasicWindow")
        MiniGameUISystem.destroyWindow(GameUI.mCardWindow)
        GameUI.mCardWindow = nil
    end
end

function GameUI.showOperatorWindow(move, callback)
    GameUI.closeOperatorWindow()
    GameUI.closeMoveCountWindow()
    GameUI.mOperatorWindowMove = move
    GameUI.mOperatorWindowCallback = callback
    GameUI.mOperatorWindow = MiniGameUISystem.createWindow("RichMan/GameUI/Operator", "_ctb", 0, -350, 100, 120)
    if GameUI.mOperatorWindowFirstMoveClicked == nil then
        GameUI.mOperatorWindowFirstMoveClicked = move > 1
    end
    if GameUI.mOperatorWindowSecondMoveClicked == nil then
        GameUI.mOperatorWindowSecondMoveClicked = move > 1
    end
    if GameUI.mOperatorWindowThirdMoveClicked == nil then
        GameUI.mOperatorWindowThirdMoveClicked = move > 2
    end
    if move > 1 then
        local first_btn =
            GameUI.mOperatorWindow:createUI("Button", "RichMan/GameUI/Operator/Button/FirstMove", "_lt", 0, 0, 20, 20)
        if GameUI.mOperatorWindowFirstMoveClicked then
            first_btn:setBackgroundResource(266,0,0,0,0,"Fs5Ac_yyFAVd8FBHsSSX1ETmZebC")
        end
        first_btn:addEventFunction(
            "onclick",
            function()
                GameUI.mOperatorWindowFirstMoveClicked = not GameUI.mOperatorWindowFirstMoveClicked
                if GameUI.mOperatorWindowFirstMoveClicked then
                    first_btn:setBackgroundResource(266,0,0,0,0,"Fs5Ac_yyFAVd8FBHsSSX1ETmZebC")
                else
                    first_btn:setBackgroundFile()
                end
                GameUI.refreshOperatorWindow()
            end
        )
        local second_btn =
            GameUI.mOperatorWindow:createUI("Button", "RichMan/GameUI/Operator/Button/SecondMove", "_lt", 40, 0, 20, 20)
        if GameUI.mOperatorWindowSecondMoveClicked then
            second_btn:setBackgroundResource(266,0,0,0,0,"Fs5Ac_yyFAVd8FBHsSSX1ETmZebC")
        end
        second_btn:addEventFunction(
            "onclick",
            function()
                GameUI.mOperatorWindowSecondMoveClicked = not GameUI.mOperatorWindowSecondMoveClicked
                if GameUI.mOperatorWindowSecondMoveClicked then
                    second_btn:setBackgroundResource(266,0,0,0,0,"Fs5Ac_yyFAVd8FBHsSSX1ETmZebC")
                else
                    second_btn:setBackgroundFile()
                end
                GameUI.refreshOperatorWindow()
            end
        )
    end
    if move > 2 then
        local third_btn =
            GameUI.mOperatorWindow:createUI("Button", "RichMan/GameUI/Operator/Button/ThirdMove", "_lt", 80, 0, 20, 20)
        if GameUI.mOperatorWindowThirdMoveClicked then
            third_btn:setBackgroundResource(266,0,0,0,0,"Fs5Ac_yyFAVd8FBHsSSX1ETmZebC")
        end
        third_btn:addEventFunction(
            "onclick",
            function()
                GameUI.mOperatorWindowThirdMoveClicked = not GameUI.mOperatorWindowThirdMoveClicked
                if GameUI.mOperatorWindowThirdMoveClicked then
                    third_btn:setBackgroundResource(266,0,0,0,0,"Fs5Ac_yyFAVd8FBHsSSX1ETmZebC")
                else
                    third_btn:setBackgroundFile()
                end
                GameUI.refreshOperatorWindow()
            end
        )
    end
    local ok_btn =
        GameUI.mOperatorWindow:createUI("Button", "RichMan/GameUI/Operator/Button/OK", "_lt", 0, 20, 100, 100)
    ok_btn:setBackgroundResource(266,0,0,0,0,"Fs5Ac_yyFAVd8FBHsSSX1ETmZebC")
    ok_btn:addEventFunction(
        "onclick",
        function()
            local result = 0
            local current_move = move
            if move > 1 then
                current_move = 0
                -- echo(
                --     "devilwalk",
                --     "GameUI.showOperatorWindow:GameUI.mOperatorWindowFirstMoveClicked:" ..
                --         tostring(GameUI.mOperatorWindowFirstMoveClicked)
                -- )
                -- echo(
                --     "devilwalk",
                --     "GameUI.showOperatorWindow:GameUI.mOperatorWindowSecondMoveClicked:" ..
                --         tostring(GameUI.mOperatorWindowSecondMoveClicked)
                -- )
                -- echo(
                --     "devilwalk",
                --     "GameUI.showOperatorWindow:GameUI.mOperatorWindowThirdMoveClicked:" ..
                --         tostring(GameUI.mOperatorWindowThirdMoveClicked)
                -- )
                if GameUI.mOperatorWindowFirstMoveClicked then
                    current_move = current_move + 1
                end
                if GameUI.mOperatorWindowSecondMoveClicked then
                    current_move = current_move + 1
                end
                if GameUI.mOperatorWindowThirdMoveClicked then
                    current_move = current_move + 1
                end
                current_move = math.max(1, current_move)
            end
            for i = 1, current_move do
                result = result + math.random(1, 6)
            end
            GameUI.mOperatorWindowCallback(result)
        end
    )
end

function GameUI.closeOperatorWindow()
    if GameUI.mOperatorWindow then
        MiniGameUISystem.destroyWindow(GameUI.mOperatorWindow)
    end
    GameUI.mOperatorWindow = nil
    GameUI.mOperatorWindowCallback = nil
    GameUI.mOperatorWindowMove = nil
end

function GameUI.hideOperatorWindow()
    if GameUI.mOperatorWindow then
        MiniGameUISystem.destroyWindow(GameUI.mOperatorWindow)
    end
    GameUI.mOperatorWindow = nil
end

function GameUI.refreshOperatorWindow(move)
    local save_move = GameUI.mOperatorWindowMove
    local save_callback = GameUI.mOperatorWindowCallback
    GameUI.showOperatorWindow(move or save_move, save_callback)
end

function GameUI.onOperatorWindowCallback()
    GameUI.mOperatorWindowCallback()
end

function GameUI.showMoveCountWindow(move)
    GameUI.closeOperatorWindow()
    if not GameUI.mMoveCountWindow then
        GameUI.mMoveCountWindow = MiniGameUISystem.createWindow("RichMan/GameUI/MoveCount", "_ctb", 0, -300, 100, 100)
        local text = GameUI.mMoveCountWindow:createUI("Text", "RichMan/GameUI/MoveCount/Text", "_lt", 0, 0, 100, 100)
        text:setTextFormat(1)
        text:setFontSize(80)
    end
    GameUI.mMoveCountWindow:getUI("RichMan/GameUI/MoveCount/Text"):setText(tostring(move or ""))
end

function GameUI.closeMoveCountWindow()
    if GameUI.mMoveCountWindow then
        MiniGameUISystem.destroyWindow(GameUI.mMoveCountWindow)
        GameUI.mMoveCountWindow = nil
    end
end

function GameUI.showTerrainLevelUpWindow(config, info, callback)
    GameUI.closeTerrainLevelUpWindow()
    GameUI.mTerrainLevelUp = MiniGameUISystem.createWindow("RichMan/GameUI/TerrainLevelUp", "_ct", 0, 0, 600, 400)
    local background =
        GameUI.mTerrainLevelUp:createUI("Picture", "RichMan/GameUI/TerrainLevelUp/Picture", "_lt", 0, 0, 600, 400)
    background:setBackgroundResource(5218,0,0,0,0,"FqAChjy7RJpJRXdV54j3ZN8azII6")
    local text_level = GameUI.mTerrainLevelUp:createUI("Text", "RichMan/GameUI/TerrainLevelUp/TextLevel", "_lt", 350, 50, 250, 40, background)
    text_level:setTextFormat(5)
    text_level:setFontSize(25)
    text_level:setFontColour("255 255 255")
    text_level:setText(tostring(info.mLevel))
    local text_price = GameUI.mTerrainLevelUp:createUI("Text", "RichMan/GameUI/TerrainLevelUp/TextPrice", "_lt", 350, 130, 250, 40, background)
    text_price:setTextFormat(5)
    text_price:setFontSize(25)
    text_price:setFontColour("255 255 255")
    text_price:setText(tostring(GameCompute.computeTerrainUpPrice(config, info)))
    local text_cost = GameUI.mTerrainLevelUp:createUI("Text", "RichMan/GameUI/TerrainLevelUp/TextCost", "_lt", 350, 210, 250, 40, background)
    text_cost:setTextFormat(5)
    text_cost:setFontSize(25)
    text_cost:setFontColour("255 255 255")
    text_cost:setText(tostring(GameCompute.computeTerrainUpSpend(config, info)))

    if info.mLevel == 1 then
        local button_normal =
            GameUI.mTerrainLevelUp:createUI(
            "Button",
            "RichMan/GameUI/TerrainLevelUp/Button/Normal",
            "_lt",
            100,
            300,
            100,
            100,
            background
        )
        button_normal:setFontSize(50)
        button_normal:setBackgroundResource(5216,0,0,0,0,"FhAe0ilQL1JNYHg4vzzm4sVvp3f-")
        button_normal:addEventFunction(
            "onclick",
            function()
                callback("normal")
                GameUI.closeTerrainLevelUpWindow()
            end
        )
        local button_supermarket =
            GameUI.mTerrainLevelUp:createUI(
            "Button",
            "RichMan/GameUI/TerrainLevelUp/Button/Supermarket",
            "_lt",
            250,
            300,
            100,
            100,
            background
        )
        button_supermarket:setFontSize(50)
        button_supermarket:setBackgroundResource(5217,0,0,0,0,"FgJs-e9vdy9t6h5k5enj8VWfbW3Q")
        button_supermarket:addEventFunction(
            "onclick",
            function()
                callback("supermarket")
                GameUI.closeTerrainLevelUpWindow()
            end
        )
    else
        local button_yes =
            GameUI.mTerrainLevelUp:createUI(
            "Button",
            "RichMan/GameUI/TerrainLevelUp/Button/OK",
            "_lt",
            100,
            300,
            100,
            100,
            background
        )
        button_yes:setFontSize(50)
        button_yes:setBackgroundResource(5211,0,0,0,0,"FpF7KvPVCTdbal67kwq70FwdAZaQ")
        button_yes:addEventFunction(
            "onclick",
            function()
                callback("ok")
                GameUI.closeTerrainLevelUpWindow()
            end
        )
    end
    local button_cancel =
        GameUI.mTerrainLevelUp:createUI(
        "Button",
        "RichMan/GameUI/TerrainLevelUp/Button/Cancel",
        "_lt",
        400,
        300,
        100,
        100,
        background
    )
    button_cancel:setFontSize(50)
    button_cancel:setBackgroundResource(5212,0,0,0,0,"FoLYTvUXLMg8sMUDxuxhxc2haNyF")
    button_cancel:addEventFunction(
        "onclick",
        function()
            callback("cancel")
            GameUI.closeTerrainLevelUpWindow()
        end
    )
end

function GameUI.closeTerrainLevelUpWindow()
    if GameUI.mTerrainLevelUp then
        MiniGameUISystem.destroyWindow(GameUI.mTerrainLevelUp)
        GameUI.mTerrainLevelUp = nil
    end
end

function GameUI.showBankWindow(callback)
    GameUI.closeBankWindow()
    GameUI.mBank = MiniGameUISystem.createWindow("RichMan/GameUI/Bank", "_ct", 0, 0, 600, 400)
    local background = GameUI.mBank:createUI("Picture", "RichMan/GameUI/Bank/Picture", "_lt", 0, 0, 600, 400)
    background:setBackgroundResource(255,0,0,0,0,"Fk2ztiR-hKdBug6TWtytWvAGu3mr")
    local text_info = GameUI.mBank:createUI("Text", "RichMan/GameUI/Bank/Text_Info", "_lt", 0, 10, 600, 90, background)
    text_info:setFontSize(45)
    text_info:setTextFormat(1)
    text_info:setFontColour("255 255 255")
    text_info:setText("请选择您需要办理的业务~")
    local button_store =
        GameUI.mBank:createUI("Button", "RichMan/GameUI/Bank/Button_Store", "_lt", 0, 150, 300, 50, background)
    button_store:setFontSize(50)
    button_store:setBackgroundResource(5209,0,0,0,0,"FiQQvSLyn7JNDaEKpFi4_nnHuHwy")
    button_store:addEventFunction(
        "onclick",
        function()
            GameUI.mBankInfo = GameUI.mBankInfo or {}
            GameUI.mBankInfo.mType = "存款"
            text_info:setText("当前您选择的是存款业务")
            text_info:setFontColour("255 255 255")
        end
    )
    local button_get =
        GameUI.mBank:createUI("Button", "RichMan/GameUI/Bank/Button_Get", "_lt", 300, 150, 300, 50, background)
    button_get:setFontSize(50)
    button_get:setBackgroundResource(5210,0,0,0,0,"FmlOoJBy7mlaLtNdBx2pXluOcknq")
    button_get:addEventFunction(
        "onclick",
        function()
            GameUI.mBankInfo = GameUI.mBankInfo or {}
            GameUI.mBankInfo.mType = "取款"
            text_info:setText("当前您选择的是取款业务")
            text_info:setFontColour("255 255 255")
        end
    )
    -- local button_borrow = GameUI.mBank:createUI("Button", "RichMan/GameUI/Bank/Button_Borrow", "_lt", 0, 200, 300, 50, background)
    -- button_borrow:setFontSize(50)
    -- button_borrow:setText("申请贷款")
    -- button_borrow:setBackgroundResource(934)
    -- button_borrow:addEventFunction(
    --     "onclick",
    --     function()
    --         GameUI.mBankInfo = GameUI.mBankInfo or {}
    --         GameUI.mBankInfo.mType = "申请贷款"
    --         text_info:setText("当前您选择的是申请贷款业务")
    --     end
    -- )
    -- local button_return = GameUI.mBank:createUI("Button", "RichMan/GameUI/Bank/Button_Return", "_lt", 300, 200, 300, 50, background)
    -- button_return:setFontSize(50)
    -- button_return:setText("偿还贷款")
    -- button_return:setBackgroundResource(934)
    -- button_return:addEventFunction(
    --     "onclick",
    --     function()
    --         GameUI.mBankInfo = GameUI.mBankInfo or {}
    --         GameUI.mBankInfo.mType = "偿还贷款"
    --         text_info:setText("当前您选择的是偿还贷款业务")
    --     end
    -- )
    local text_money = GameUI.mBank:createUI("Text", "RichMan/GameUI/Bank/Text/Money", "_lt", 0, 220, 300, 50)
    text_money:setFontSize(45)
    text_money:setTextFormat(1)
    text_money:setText("请输入金额:")
    text_money:setFontColour("255 255 255")
    local edit = GameUI.mBank:createUI("Edit", "RichMan/GameUI/Edit", "_lt", 300, 220, 300, 50)
    edit:setFontSize(50)
    local button_yes =
        GameUI.mBank:createUI("Button", "RichMan/GameUI/Bank/Button/OK", "_lt", 100, 300, 100, 100, background)
    button_yes:setFontSize(50)
    button_yes:setBackgroundResource(258,0,0,0,0,"FsDME5crdZJOkcnSw7vIx6MMncrY")
    button_yes:addEventFunction(
        "onclick",
        function()
            local money = tonumber(edit:getText())
            if money then
                local result = callback("ok", money)
                if not result or result.mResult then
                    GameUI.closeBankWindow()
                else
                    text_info:setText("操作失败，原因:" .. result.mDescription)
                end
            else
                text_info:setText("操作失败，原因:输入有误")
                edit:setText("")
            end
        end
    )

    local button_cancel =
        GameUI.mBank:createUI("Button", "RichMan/GameUI/Bank/Button/Cancel", "_lt", 300, 300, 100, 100, background)
    button_cancel:setFontSize(50)
    button_cancel:setBackgroundResource(5212,0,0,0,0,"FoLYTvUXLMg8sMUDxuxhxc2haNyF")
    button_cancel:addEventFunction(
        "onclick",
        function()
            callback("cancel")
            GameUI.closeBankWindow()
        end
    )
end

function GameUI.closeBankWindow()
    if GameUI.mBank then
        MiniGameUISystem.destroyWindow(GameUI.mBank)
        GameUI.mBank = nil
    end
end

function GameUI.showShopWindow(sellCards, sellCardCallback, buyCardCallback, closeCallback)
    assert(not GameUI.mShop, "GameUI.showShopWindow")
    GameUI.mShopMode = GameUI.mShopMode or "Buy"
    GameUI.mShopSellCards = sellCards or {}
    GameUI.mShopSellCardCallback = sellCardCallback
    GameUI.mShopBuyCardCallback = buyCardCallback
    GameUI.mShopCloseCallback = closeCallback
    GameUI.mShop = MiniGameUISystem.createWindow("RichMan/GameUI/Shop", "_ct", 0, 0, 800, 600)
    GameUI.mShop:setZOrder(101)
    local background = GameUI.mShop:createUI("Picture", "RichMan/GameUI/Shop/Picture", "_lt", 0, 0, 800, 600)
    background:setBackgroundResource(267,0,0,0,0,"FgtQvU_2QAwjcQDcTBo6jPPtj-Ag")
    local buy_button =
        GameUI.mShop:createUI("Button", "RichMan/GameUI/Shop/Button/Buy", "_lt", 20, 55, 100, 50, background)
    buy_button:setBackgroundResource(268,0,0,0,0,"FoQesT2Pkz-wx8V4qlIAPfOGK36K")
    buy_button:addEventFunction(
        "onclick",
        function()
            GameUI.mShopMode = "Buy"
            GameUI.refreshShopWindow()
        end
    )
    local sell_button =
        GameUI.mShop:createUI("Button", "RichMan/GameUI/Shop/Button/Sell", "_lt", 140, 55, 100, 50, background)
    sell_button:setBackgroundResource(269,0,0,0,0,"FqdjX6BSqjIP5bsLKcejIoo3Hxcv")
    sell_button:addEventFunction(
        "onclick",
        function()
            GameUI.mShopMode = "Sell"
            GameUI.refreshShopWindow()
        end
    )
    local card_container =
        GameUI.mShop:createUI("Picture", "RichMan/GameUI/Shop/CardContainer", "_lt", 30, 120, 700, 450, background)
    card_container:setBackgroundFile("")
    if GameUI.mShopMode == "Buy" then
        local cards = {}
        for i = 1, 24 do
            cards[#cards + 1] = math.random(1, #GameConfig.mCards)
        end
        cards = GameUI.mShopBuyCards or cards
        for x = 0, 7 do
            for y = 0, 2 do
                local card_index = y * 8 + x + 1
                if card_index > #cards then
                    break
                end
                local card_button =
                    GameUI.mShop:createUI(
                    "Button",
                    "RichMan/GameUI/Shop/Button/CardBuy" .. tostring(card_index),
                    "_lt",
                    x * 94,
                    y * 159,
                    85,
                    150,
                    card_container
                )
                card_button:setBackgroundResource(GameConfig.mCards[cards[card_index]].mResource.pid,0,0,0,0,GameConfig.mCards[cards[card_index]].mResource.hash)
                card_button:addEventFunction(
                    "onclick",
                    function()
                        GameUI.yesOrNo(
                            "买入卡片：" ..
                                GameConfig.mCards[cards[card_index]].mType ..
                                    "，您将消费点券：" .. tostring(GameConfig.mCards[cards[card_index]].mPrice) .. "确定吗？",
                            function()
                                local buy_card = cards[card_index]
                                local buy_ret = buyCardCallback(buy_card)
                                if buy_ret.mResult then
                                    table.remove(cards, card_index)
                                    GameUI.mShopBuyCards = cards
                                    GameUI.refreshShopWindow()
                                else
                                    GameUI.messageBox(buy_ret.mDescription)
                                end
                            end
                        )
                    end
                )
            end
        end
        GameUI.mShopBuyCards = cards
    elseif GameUI.mShopMode == "Sell" then
        for x = 0, 7 do
            for y = 0, 2 do
                local card_index = y * 8 + x + 1
                if GameUI.mShopSellCards[card_index] then
                    local card_button =
                        GameUI.mShop:createUI(
                        "Button",
                        "RichMan/GameUI/Shop/Button/CardSell" .. tostring(card_index),
                        "_lt",
                        x * 94,
                        y * 159,
                        85,
                        150,
                        card_container
                    )
                    card_button:setBackgroundResource(
                        GameConfig.mCards[GameUI.mShopSellCards[card_index]].mResource.pid
                    )
                    card_button:addEventFunction(
                        "onclick",
                        function()
                            GameUI.yesOrNo(
                                "卖出卡片：" ..
                                    GameConfig.mCards[GameUI.mShopSellCards[card_index]].mType ..
                                        "，您将获得点券：" ..
                                            tostring(GameConfig.mCards[GameUI.mShopSellCards[card_index]].mPrice / 2) ..
                                                "确定吗？",
                                function()
                                    local sell_card = GameUI.mShopSellCards[card_index]
                                    table.remove(GameUI.mShopSellCards, card_index)
                                    sellCardCallback(sell_card)
                                    GameUI.refreshShopWindow()
                                end
                            )
                        end
                    )
                end
            end
        end
    end
    local close_button =
        GameUI.mShop:createUI("Button", "RichMan/GameUI/Shop/Button/Close", "_lt", 750, 10, 30, 30, background)
    close_button:setBackgroundResource(270,0,0,0,0,"Fks3BQ5iCMkO8SJmgr1JSgqj0wDP")
    close_button:addEventFunction(
        "onclick",
        function()
            GameUI.closeShopWindow()
            if closeCallback then
                closeCallback()
            end
        end
    )
    GameUI.mCurrentUI = GameUI.mShop
end

function GameUI.closeShopWindow()
    if GameUI.mShop then
        MiniGameUISystem.destroyWindow(GameUI.mShop)
        GameUI.mShop = nil
        GameUI.mShopMode = nil
        GameUI.mShopBuyCards = nil
        GameUI.mShopSellCards = nil
        GameUI.mShopSellCardCallback = nil
        GameUI.mShopBuyCardCallback = nil
        GameUI.mShopCloseCallback = nil
        GameUI.mCurrentUI = nil
    end
end

function GameUI.refreshShopWindow()
    if GameUI.mShop then
        local mode = GameUI.mShopMode
        local buy_cards = GameUI.mShopBuyCards
        local sell_cards = GameUI.mShopSellCards
        local sell_card_callback = GameUI.mShopSellCardCallback
        local buy_card_callback = GameUI.mShopBuyCardCallback
        local close_callback = GameUI.mShopCloseCallback
        GameUI.closeShopWindow()
        GameUI.mShopMode = mode
        GameUI.mShopBuyCards = buy_cards
        GameUI.showShopWindow(sell_cards, sell_card_callback, buy_card_callback, close_callback)
    end
end

function GameUI.showGetCardWindow(cards, callback)
    GameUI.closeGetCardWindow()
    if not cards then
        return
    end
    GameUI.mGetCard = MiniGameUISystem.createWindow("RichMan/GameUI/GetCard", "_ct", 0, 0, 600, 400)
    local background = GameUI.mGetCard:createUI("Picture", "RichMan/GameUI/GetCard/Picture", "_lt", 0, 0, 600, 400)
    background:setBackgroundResource(260,0,0,0,0,"FnQFSBZWAQIe7Ph3PLOai0J0n3AE")
    local card_container =
        GameUI.mGetCard:createUI(
        "Picture",
        "RichMan/GameUI/GetCard/Picture/CardContainer",
        "_lt",
        25,
        40,
        550,
        350,
        background
    )
    card_container:setBackgroundFile("")
    for y = 0, 2 do
        for x = 0, 7 do
            local index = y * 8 + x + 1
            if index > #cards then
                return
            end
            local button =
                GameUI.mGetCard:createUI(
                "Button",
                "RichMan/GameUI/GetCard/Button/" .. tostring(index),
                "_lt",
                x * 66,
                y * 116,
                65,
                115,
                card_container
            )
            button:setBackgroundResource(GameConfig.mCards[cards[index]].mResource.pid,0,0,0,0,GameConfig.mCards[cards[index]].mResource.hash)
            button:addEventFunction(
                "onclick",
                function()
                    GameUI.closeGetCardWindow()
                    callback(index)
                end
            )
        end
    end
end

function GameUI.closeGetCardWindow()
    if GameUI.mGetCard then
        MiniGameUISystem.destroyWindow(GameUI.mGetCard)
        GameUI.mGetCard = nil
    end
end

function GameUI.showTicketWindow(lastTickets, ownTickets, callback)
    GameUI.closeTicketWindow()
    GameUI.mTicket = MiniGameUISystem.createWindow("RichMan/GameUI/Ticket", "_ct", 0, 0, 600, 400)
    local background_0 =
        GameUI.mTicket:createUI("Picture", "RichMan/GameUI/Ticket/Picture/Background0", "_lt", 0, 0, 600, 400)
    background_0:setBackgroundResource(255,0,0,0,0,"Fk2ztiR-hKdBug6TWtytWvAGu3mr")
    local background_1 =
        GameUI.mTicket:createUI(
        "Picture",
        "RichMan/GameUI/Ticket/Picture/Background1",
        "_lt",
        25,
        25,
        550,
        370,
        background_0
    )
    background_1:setBackgroundResource(271,0,0,0,0,"FoqubzENayFXXDRZKl89vDySbA_n")
    local background =
        GameUI.mTicket:createUI(
        "Picture",
        "RichMan/GameUI/Ticket/Picture/Background",
        "_lt",
        0,
        70,
        550,
        300,
        background_1
    )
    background:setBackgroundFile("")
    for y = 0, 3 do
        for x = 0, 8 do
            local index = y * 9 + x + 1
            local is_last
            for _, last in pairs(lastTickets) do
                if index == last then
                    is_last = true
                    break
                end
            end
            if is_last then
                local button =
                    GameUI.mTicket:createUI(
                    "Button",
                    "RichMan/GameUI/Ticket/Button/" .. tostring(index),
                    "_lt",
                    x * 61,
                    y * 75,
                    60,
                    74,
                    background
                )
                button:setText(tostring(index))
                button:setBackgroundFile("")
                button:setFontColour("255 255 255")
                button:setFontSize("25")
                button:addEventFunction(
                    "onclick",
                    function()
                        GameUI.yesOrNo(
                            "购买彩票：" .. tostring(index) .. "吗？",
                            function()
                                GameUI.closeTicketWindow()
                                if callback then
                                    callback(index)
                                end
                            end
                        )
                    end
                )
            else
                local text =
                    GameUI.mTicket:createUI(
                    "Text",
                    "RichMan/GameUI/Ticket/Text/" .. tostring(index),
                    "_lt",
                    x * 61,
                    y * 75,
                    60,
                    74,
                    background
                )
                text:setTextFormat(5)
                text:setText(tostring(index))
                text:setFontColour("255 255 255")
                local is_own
                if ownTickets then
                    for _, last in pairs(ownTickets) do
                        if index == last then
                            is_own = true
                            break
                        end
                    end
                end
                local picture =
                    GameUI.mTicket:createUI(
                    "Picture",
                    "RichMan/GameUI/Ticket/Picture/" .. tostring(index) .. "/State",
                    "_lt",
                    0,
                    0,
                    60,
                    74,
                    text
                )
                if is_own then
                    picture:setBackgroundResource(272,0,0,0,0,"Fv_SifLWjxigI1irXKOnfr1X5d_p")
                else
                    picture:setBackgroundResource(273,0,0,0,0,"FnoXrU0XvdK3LNFADLp43VTNujli")
                end
            end
        end
    end
    local close_button =
        GameUI.mTicket:createUI("Button", "RichMan/GameUI/Ticket/Button/Close", "_lt", 550, 20, 30, 30, background_0)
    close_button:setBackgroundResource(270,0,0,0,0,"Fks3BQ5iCMkO8SJmgr1JSgqj0wDP")
    close_button:addEventFunction(
        "onclick",
        function()
            GameUI.closeTicketWindow()
            if callback then
                callback()
            end
        end
    )
end

function GameUI.closeTicketWindow()
    if GameUI.mTicket then
        MiniGameUISystem.destroyWindow(GameUI.mTicket)
        GameUI.mTicket = nil
    end
end
-----------------------------------------------------------------------------------------Player-----------------------------------------------------------------------------------------
function Player:construction(parameter)
    self.mEntityWatcher = parameter.mEntityWatcher
    self.mEntity = GetEntityById(self.mEntityWatcher.id)
end

function Player:destruction()
end
-----------------------------------------------------------------------------------------Game Player-----------------------------------------------------------------------------------------
function GamePlayer:construction(parameter)
    self.mPlayerID = parameter.mPlayerID
end

function GamePlayer:destruction()
end

function GamePlayer:getPlayer()
    return PlayerManager.getPlayer(self.mPlayerID)
end

function GamePlayer:_getLockKey(property)
    return "GamePlayer/" .. tostring(self.mPlayerID) .. "/" .. property
end

function GamePlayer:costMoney(money, callback)
    local real_cost = money
    if self:cache().mMoney + self:cache().mMoneyStore < money then
        real_cost = self:cache().mMoney + self:cache().mMoneyStore
        money = real_cost
    end
    if self:cache().mMoney >= money then
        self:cache().mMoney = self:cache().mMoney - money
        money = 0
    else
        money = money - self:cache().mMoney
        self:cache().mMoney = 0
    end
    self:cache().mMoneyStore = self:cache().mMoneyStore - money
    self:commandWrite("mMoney", self:cache().mMoney)
    self:commandWrite("mMoneyStore", self:cache().mMoneyStore)
    if callback then
        self:commandFinish(callback)
    end
    return real_cost
end

-----------------------------------------------------------------------------------------Game Player Host-----------------------------------------------------------------------------------------
function GamePlayerHost:construction(parameter)
    self.mDebug = "GamePlayerHost"
    self.mGame = parameter.mGame
    self.mPlayer = new(GamePlayer, parameter)
    self.mPlayer:safeWrite("mMoney", parameter.mMoney)
    self.mPlayer:safeWrite("mMove", parameter.mMove)
    self.mPlayer:safeWrite("mPosition", parameter.mPosition)
    self.mPlayer:safeWrite(
        "mDirection",
        GameCompute.convertDirection123(GameCompute.computePlayerDirection(parameter.mPosition))
    )
    self.mPlayer:safeWrite("mPoint", parameter.mPoint)
    self.mPlayer:safeWrite("mMoneyStore", parameter.mMoneyStore)
    self.mPlayer:safeWrite("mCards", parameter.mCards)
    self.mPlayer:safeWrite("mOnline", true)
    self.mPlayer:safeWrite("mFail")
    self.mPlayer:safeWrite("mBlockID", parameter.mBlockID)
    self.mPlayer:safeWrite("mResource", parameter.mResource)
    self.mResource = parameter.mResource
    self.mEntity =
        CreateNPC(
        {
            name = "GameNPC/" .. tostring(self.mPlayer.mPlayerID),
            bx = parameter.mPosition[1],
            by = parameter.mPosition[2] + 1,
            bz = parameter.mPosition[3],
            facing = 0,
            can_random_move = false,
            item_id = 10062,
            is_dummy = true,
            is_persistent = false
        }
    )
    if self.mResource then
        self.mEntity:setModelFromResource(GameConfig.mRoleEntityResources[self.mResource])
        self.mEntity:SetScaling(GameConfig.mRoleEntityScales[self.mResource])
    end
    EntitySyncerManager.singleton():get(self.mEntity):setDisplayName(
        GetEntityById(self.mPlayer.mPlayerID).nickname,
        "255 255 0"
    )
    if self.mPlayer.mPlayerID == GetPlayerId() then
        EntitySyncerManager.singleton():get(self.mEntity):setLocalDisplayNameColour("255 0 0")
    end
    self.mPlayer:safeWrite("mEntityID", self.mEntity.entityId)
    self.mCommandQueue = new(CommandQueue)

    Host.addListener("GamePlayer", self)

    self.mPlayer:addPropertyListener(
        "mDirection",
        self,
        function(_, value)
            -- echo("devilwalk", "GamePlayerHost:construction:mDirection Change:value:")
            -- echo("devilwalk", value)
            if 1 == value[1] then
                self.mEntity:SetFacing(0)
            elseif -1 == value[1] then
                self.mEntity:SetFacing(3.14)
            elseif 1 == value[3] then
                self.mEntity:SetFacing(-1.57)
            elseif -1 == value[3] then
                self.mEntity:SetFacing(1.57)
            end
        end
    )
    self.mPlayer:addPropertyListener(
        "mPosition",
        self,
        function(_, value)
            -- echo("devilwalk", "GamePlayerHost:construction:mPosition Change:value:")
            -- echo("devilwalk", value)
            self.mEntity:SetBlockPos(value[1], value[2] + 1, value[3])
        end
    )
    self.mPlayer:addPropertyListener(
        "mFail",
        self,
        function(_, value)
            self.mGame:playerFail(self.mPlayer.mPlayerID)
        end
    )
    self.mPlayer:addPropertyListener(
        "mStay",
        self,
        function(_, value)
            if value then
                if self.mEntity then
                    self.mEntity:SetDead(true)
                    self.mEntity = nil
                    self.mPlayer:safeWrite("mEntityID")
                end
            else
                if not self.mEntity then
                    self.mEntity =
                        CreateNPC(
                        {
                            name = "GameNPC/" .. tostring(self.mPlayer.mPlayerID),
                            bx = self.mPlayer:cache().mPosition[1],
                            by = self.mPlayer:cache().mPosition[2] + 1,
                            bz = self.mPlayer:cache().mPosition[3],
                            facing = 0,
                            can_random_move = false,
                            item_id = 10062,
                            is_dummy = true,
                            is_persistent = false
                        }
                    )
                    if self.mResource then
                        self.mEntity:setModelFromResource(GameConfig.mRoleEntityResources[self.mResource])
                        self.mEntity:SetScaling(GameConfig.mRoleEntityScales[self.mResource])
                    end
                    EntitySyncerManager.singleton():get(self.mEntity):setDisplayName(
                        GetEntityById(self.mPlayer.mPlayerID).nickname,
                        "255 255 0"
                    )
                    if self.mPlayer.mPlayerID == GetPlayerId() then
                        EntitySyncerManager.singleton():get(self.mEntity):setLocalDisplayNameColour("255 0 0")
                    end
                    self.mPlayer:safeWrite("mEntityID", self.mEntity.entityId)
                    self.mPlayer:safeWrite("mDirection", self.mPlayer:cache().mDirection)
                end
            end
        end
    )
    local function _updateDisplayName()
        echo("devilwalk", "_updateDisplayName:self.mPlayer:cache():")
        echo("devilwalk", self.mPlayer:cache())
        local display_name = GetEntityById(self.mPlayer.mPlayerID).nickname
        if self.mPlayer:cache().mAttachNPC then
            display_name =
                display_name ..
                "(" ..
                    GameConfig.mNPCTypes[self.mPlayer:cache().mAttachNPC.mType] ..
                        "附身,还有" .. tostring(self.mPlayer:cache().mAttachNPC.mDay) .. "天)"
        end
        if self.mPlayer:cache().mAttachItem then
            if self.mPlayer:cache().mAttachItem.mType == "定时炸弹" then
                display_name = display_name .. "(炸弹还有" .. self.mPlayer:cache().mAttachItem.mStep .. "步爆炸)"
            end
        end
        if self.mEntity then
            EntitySyncerManager.singleton():get(self.mEntity):setDisplayName(display_name, "255 255 0")
            if self.mPlayer.mPlayerID == GetPlayerId() then
                EntitySyncerManager.singleton():get(self.mEntity):setLocalDisplayNameColour("255 0 0")
            end
        end
    end
    self.mPlayer:addPropertyListener("mAttachNPC", self, _updateDisplayName)
    self.mPlayer:addPropertyListener("mAttachItem", self, _updateDisplayName)
end

function GamePlayerHost:destruction()
    if self.mTerrains then
        for key, terrain in pairs(self.mTerrains) do
            local x, y, z = terrain.mEntity:GetBlockPos()
            terrain.mEntity:SetDead(true)
        end
    end
    if self.mEntity then
        self.mEntity:SetDead(true)
    end
    delete(self.mPlayer)
    Host.removeListener("GamePlayer", self)
end

function GamePlayerHost:update()
    self.mCommandQueue:update()
    self.mPlayer:update()
end

function GamePlayerHost:getPlayer()
    return self.mPlayer:getPlayer()
end

function GamePlayerHost:getGame()
    return self.mGame
end

function GamePlayerHost:getProperty()
    return self.mPlayer
end

function GamePlayerHost:updatePropertyCache(callback)
    echo("devilwalk", "GamePlayerHost:updatePropertyCache:" .. tostring(self.mPlayer.mPlayerID))
    self.mPlayer.mCache = {}
    self.mPlayer:commandRead("mMoney")
    self.mPlayer:commandRead("mMove")
    self.mPlayer:commandRead("mPosition")
    self.mPlayer:commandRead("mDirection")
    self.mPlayer:commandRead("mPoint")
    self.mPlayer:commandRead("mMoneyStore")
    self.mPlayer:commandRead("mCards")
    self.mPlayer:commandRead("mOnline")
    self.mPlayer:commandRead("mEntityID")
    self.mPlayer:commandRead("mAttachNPC")
    self.mPlayer:commandRead("mFail")
    self.mPlayer:commandRead("mBlockID")
    self.mPlayer:commandRead("mStay")
    self.mPlayer:commandRead("mSleepDay")
    self.mPlayer:commandRead("mTickets")
    self.mPlayer:commandRead("mResource")
    self.mPlayer:commandRead("mAttachItem")
    self.mPlayer:commandRead("mInvincible")
    self.mPlayer:commandRead("mStep")
    self.mPlayer:commandRead("mStop")
    self.mPlayer:commandRead("mBankStop")
    self.mPlayer:commandFinish(
        function()
            if not self.mPlayer:cache().mDirection then
                local dir =
                    GameCompute.convertDirection123(GameCompute.computePlayerDirection(self.mPlayer:cache().mPosition))
                self.mPlayer:safeWrite("mDirection", dir, callback)
            else
                callback()
            end
        end,
        function()
            echo("devilwalk","GamePlayerHost:updatePropertyCache:time out")
        end
    )
end

function GamePlayerHost:getPropertyCache()
    return self.mPlayer:cache()
end

function GamePlayerHost:move(destPosition, finishCallback)
    self:updatePropertyCache(
        function()
            self.mCommandQueue:post(
                new(
                    Command_Callback,
                    {
                        mDebug = "GamePlayerHost:move",
                        mExecuteCallback = function(command)
                            self.mEntity:SetDummy(false)
                            self.mEntity:MoveTo(destPosition[1], destPosition[2] + 1, destPosition[3])
                        end,
                        mExecutingCallback = function(command)
                            if not self.mEntity:HasTarget() then
                                self.mEntity:SetDummy(true)
                                finishCallback()
                                command.mState = Command.EState.Finish
                            end
                        end
                    }
                )
            )
        end
    )
end

function GamePlayerHost:sendToClient(message, parameter)
    -- body
    Host.sendTo(self.mPlayer.mPlayerID, {mKey = "GamePlayer", mMessage = message, mParameter = parameter})
end

function GamePlayerHost:receive(parameter)
    -- echo("devilwalk", "GamePlayerHost:receive:parameter:")
    -- echo("devilwalk", self.mPlayer)
    if parameter._from == self.mPlayer.mPlayerID then
        if parameter.mMessage == "Move" then
            self:move(
                parameter.mParameter.mPosition,
                function()
                    self:sendToClient("Move_Response")
                end
            )
        elseif parameter.mMessage == "UseCard" then
            if parameter.mParameter.mCardType == "机器娃娃" then
                self:updatePropertyCache(
                    function()
                        self.mCommandQueue:post(
                            new(
                                Command_Callback,
                                {
                                    mDebug = "Command_Callback/"..parameter.mParameter.mCardType,
                                    mExecuteCallback = function(command)
                                        command.mCommandQueue = new(CommandQueue)
                                        command.mEntity =
                                            CreateNPC(
                                            {
                                                name = parameter.mParameter.mCardType,
                                                bx = self.mPlayer:cache().mPosition[1],
                                                by = self.mPlayer:cache().mPosition[2] + 1,
                                                bz = self.mPlayer:cache().mPosition[3],
                                                facing = 0,
                                                can_random_move = false,
                                                item_id = 10062,
                                                is_dummy = false,
                                                is_persistent = false
                                            }
                                        )
                                        command.mEntity:setModelFromResource(GameConfig.getCardByType(parameter.mParameter.mCardType).mModelResource)
                                        local pos = clone(self.mPlayer:cache().mPosition)
                                        local dir = clone(self.mPlayer:cache().mDirection)
                                        for i = 1, 15 do
                                            local next_pos = {pos[1] + dir[1], pos[2] + dir[2], pos[3] + dir[3]}
                                            local next_dir =
                                                GameCompute.convertDirection123(
                                                GameCompute.computePlayerDirection(pos, dir)
                                            )
                                            command.mCommandQueue:post(
                                                new(
                                                    Command_Callback,
                                                    {
                                                        mDebug = "Command_Callback/"..parameter.mParameter.mCardType.."/Step" .. tostring(i),
                                                        mExecuteCallback = function(commandStep)
                                                            command.mEntity:MoveTo(
                                                                next_pos[1],
                                                                next_pos[2] + 1,
                                                                next_pos[3]
                                                            )
                                                        end,
                                                        mExecutingCallback = function(commandStep)
                                                            if not command.mEntity:HasTarget() then
                                                                self.mGame:getProperty():safeWrite(
                                                                    self.mGame:getProperty():getRoadInfoPropertyName(
                                                                        next_pos
                                                                    ),
                                                                    {}
                                                                )
                                                                self.mGame:updateRoad(next_pos)
                                                                commandStep.mState = Command.EState.Finish
                                                            end
                                                        end
                                                    }
                                                )
                                            )
                                            pos = clone(next_pos)
                                            dir = clone(next_dir)
                                        end
                                    end,
                                    mExecutingCallback = function(command)
                                        command.mCommandQueue:update()
                                        if command.mCommandQueue:empty() then
                                            command.mEntity:SetDead(true)
                                            self:sendToClient("UseCard_Response")
                                            command.mState = Command.EState.Finish
                                        end
                                    end
                                }
                            )
                        )
                    end
                )
            end
        end
    end
end
-----------------------------------------------------------------------------------------Game Player Client-----------------------------------------------------------------------------------------
function GamePlayerClient:construction(parameter)
    self.mDebug = "GamePlayerClient"
    self.mGame = parameter.mGame
    self.mPlayer = new(GamePlayer, parameter)
    self.mCommandQueue = new(CommandQueue)
    if self.mPlayer.mPlayerID == GetPlayerId() then
        self.mPlayer:addPropertyListener(
            "mEntityID",
            self,
            function(_, value)
                if value then
                    EntitySyncerManager.singleton():getByEntityID(value):setLocalDisplayNameColour("255 0 0")
                end
            end
        )
        Client.addListener("GamePlayer", self)
    end
end

function GamePlayerClient:destruction()
    delete(self.mPlayer)
    delete(self.mCommandQueue)
    if self.mPlayer.mPlayerID == GetPlayerId() then
        Client.removeListener("GamePlayer", self)
    end
end

function GamePlayerClient:update()
    self.mCommandQueue:update()
    self.mPlayer:update()
end

function GamePlayerClient:getGame()
    return self.mGame
end

function GamePlayerClient:getProperty()
    return self.mPlayer
end

function GamePlayerClient:updatePropertyCache(callback)
    echo("devilwalk", "GamePlayerClient:updatePropertyCache:" .. tostring(self.mPlayer.mPlayerID))
    self.mPlayer.mCache = {}
    self.mPlayer:commandRead("mMoney")
    self.mPlayer:commandRead("mMove")
    self.mPlayer:commandRead("mPosition")
    self.mPlayer:commandRead("mDirection")
    self.mPlayer:commandRead("mPoint")
    self.mPlayer:commandRead("mMoneyStore")
    self.mPlayer:commandRead("mCards")
    self.mPlayer:commandRead("mOnline")
    self.mPlayer:commandRead("mEntityID")
    self.mPlayer:commandRead("mAttachNPC")
    self.mPlayer:commandRead("mFail")
    self.mPlayer:commandRead("mBlockID")
    self.mPlayer:commandRead("mStay")
    self.mPlayer:commandRead("mSleepDay")
    self.mPlayer:commandRead("mTickets")
    self.mPlayer:commandRead("mResource")
    self.mPlayer:commandRead("mAttachItem")
    self.mPlayer:commandRead("mInvincible")
    self.mPlayer:commandRead("mStep")
    self.mPlayer:commandRead("mStop")
    self.mPlayer:commandRead("mBankStop")
    self.mPlayer:commandFinish(
        function()
            if not self.mPlayer:cache().mDirection then
                local dir =
                    GameCompute.convertDirection123(GameCompute.computePlayerDirection(self.mPlayer:cache().mPosition))
                self.mPlayer:safeWrite("mDirection", dir, callback)
            else
                callback()
            end
        end,
        function()
            echo("devilwalk","GamePlayerClient:updatePropertyCache:time out")
        end
    )
end

function GamePlayerClient:getPropertyCache()
    return self.mPlayer:cache()
end

function GamePlayerClient:useCard(card)
    local card_type = GameConfig.mCards[card].mType
    -- echo("devilwalk","GamePlayerClient:useCard:card_type:"..card_type)
    self.mGame:getProperty():read(
        "mCurrentRunPlayer",
        function(value)
            if value == self.mPlayer.mPlayerID then
                if self.mCurrentUseCard then
                    GameUI.messageBox("请先完成卡片：" .. GameConfig.mCards[self.mCurrentUseCard].mType .. "的使用")
                    return
                end
                for i, c in pairs(self:getPropertyCache().mCards) do
                    if card == c then
                        table.remove(self:getPropertyCache().mCards, i)
                        break
                    end
                end
                self.mPlayer:safeWrite("mCards", self:getPropertyCache().mCards)
                GameUI.hideOperatorWindow()
                self.mCurrentUseCard = card
                if card_type == "遥控色子" then
                    MiniGameUISystem.editWindow(
                        "请输入想要走的步数(1-6):",
                        function(value)
                            local step_count = math.max(1, math.min(tonumber(value) or 1, 6))
                            self.mCommandQueue:post(
                                new(
                                    Command_MoveClient,
                                    {
                                        mPlayer = self,
                                        mStep = step_count
                                    }
                                )
                            )
                            self.mCommandQueue:post(new(Command_UpdatePropertyCacheClient, {mGame = self.mGame}))
                            self.mCommandQueue:post(
                                new(
                                    Command_CheckRoadClient,
                                    {
                                        mPlayer = self,
                                        mGame = self.mGame
                                    }
                                )
                            )
                            self.mCommandQueue:post(
                                new(
                                    Command_CheckTerrainClient,
                                    {
                                        mPlayer = self,
                                        mGame = self.mGame
                                    }
                                )
                            )
                            self.mCommandQueue:post(
                                new(
                                    Command_Callback,
                                    {
                                        mExecuteCallback = function(command)
                                            self.mCurrentUseCard = nil
                                            self.mGame:sendToHost("NextPlayer")
                                            command.mState = Command.EState.Finish
                                        end
                                    }
                                )
                            )
                        end
                    )
                elseif
                    card_type == "转向卡" or card_type == "障碍卡" or card_type == "地雷卡" or card_type == "定时炸弹" or
                        card_type == "抢夺卡" or
                        card_type == "换位卡" or
                        card_type == "陷害卡" or
                        card_type == "查税卡" or
                        card_type == "乌龟卡" or
                        card_type == "停留卡" or
                        card_type == "均贫卡" or
                        card_type == "拆屋卡" or
                        card_type == "建房卡" or
                        card_type == "怪兽卡" or
                        card_type == "换房卡" or
                        card_type == "飞弹卡" or
                        card_type == "核子炸弹"
                 then
                    self.mCommandQueue:post(
                        new(
                            Command_Callback,
                            {
                                mDebug = "Command_Callback/" .. card_type,
                                mExecuteCallback = function(command)
                                    if
                                        card_type == "障碍卡" or card_type == "地雷卡" or card_type == "定时炸弹" or
                                            card_type == "飞弹卡" or
                                            card_type == "核子炸弹"
                                     then
                                        command.mEntity =
                                            CreateNPC(
                                            {
                                                bx = self:getPropertyCache().mPosition[1],
                                                by = self:getPropertyCache().mPosition[2] + 1,
                                                bz = self:getPropertyCache().mPosition[3],
                                                facing = 0,
                                                can_random_move = false,
                                                item_id = 10062,
                                                is_dummy = true,
                                                is_persistent = false
                                            }
                                        )
                                        if card_type == "障碍卡" then
                                            command.mEntity:setModelFromResource(GameConfig.mCards[card].mModelResource)
                                        elseif card_type == "地雷卡" then
                                            command.mEntity:setModelFromResource(GameConfig.mCards[card].mModelResource)
                                        elseif card_type == "定时炸弹" then
                                            command.mEntity:setModelFromResource(GameConfig.mCards[card].mModelResource)
                                        elseif card_type == "飞弹卡" then
                                            command.mEntity:setModelFromResource(GameConfig.mCards[card].mModelResource)
                                        elseif card_type == "核子炸弹" then
                                            command.mEntity:setModelFromResource(GameConfig.mCards[card].mModelResource)
                                        end
                                        if card_type == "障碍卡" or card_type == "地雷卡" or card_type == "定时炸弹" then
                                            GameUI.showPrepareWindow(
                                                "当前使用的是：" .. card_type .. "，请将相应的物品放置在道路上（左键放置，右键取消）"
                                            )
                                        elseif card_type == "飞弹卡" then
                                            GameUI.showPrepareWindow(
                                                "当前使用的是：" .. card_type .. "，请将相应的物品放置在方块上（左键放置，右键取消），爆炸范围3x3"
                                            )
                                        elseif card_type == "核子炸弹" then
                                            GameUI.showPrepareWindow(
                                                "当前使用的是：" .. card_type .. "，请将相应的物品放置在方块上（左键放置，右键取消），爆炸范围7x7"
                                            )
                                        end
                                    elseif
                                        card_type == "转向卡" or card_type == "抢夺卡" or card_type == "换位卡" or
                                            card_type == "陷害卡" or
                                            card_type == "查税卡" or
                                            card_type == "乌龟卡" or
                                            card_type == "停留卡" or
                                            card_type == "均贫卡"
                                     then
                                        GameUI.showPrepareWindow("当前使用的是：" .. card_type .. "，请选择使用对象（左键选择，右键取消）")
                                    elseif
                                        card_type == "拆屋卡" or card_type == "建房卡" or card_type == "怪兽卡" or
                                            card_type == "换房卡"
                                     then
                                        GameUI.showPrepareWindow("当前使用的是：" .. card_type .. "，请选择使用地块（左键选择，右键取消）")
                                    end
                                    InputManager.addListener(
                                        card_type,
                                        function(parameter, event)
                                            if event.event_type == "mouseMoveEvent" then
                                                if command.mEntity then
                                                    local pick_result = Pick(false, true, true, false, false)
                                                    if pick_result and pick_result.blockX then
                                                        command.mEntity:SetBlockPos(
                                                            pick_result.blockX,
                                                            pick_result.blockY + 1,
                                                            pick_result.blockZ
                                                        )
                                                    end
                                                end
                                            elseif
                                                event.event_type == "mouseReleaseEvent" and event.mouse_button == "left"
                                             then
                                                local pick_result = Pick(false, true, true, false, true)
                                                if pick_result then
                                                    if pick_result.entity then
                                                        local pick_game_player
                                                        for _, player in pairs(self.mGame.mPlayers) do
                                                            if
                                                                player:getPropertyCache().mEntityID ==
                                                                    pick_result.entity.entityId
                                                             then
                                                                pick_game_player = player
                                                                break
                                                            end
                                                        end
                                                        if pick_game_player then
                                                            if card_type == "转向卡" then
                                                                local orgin_dir =
                                                                    clone(
                                                                    pick_game_player:getPropertyCache().mDirection
                                                                )
                                                                pick_game_player:getPropertyCache().mDirection[1] =
                                                                    -pick_game_player:getPropertyCache().mDirection[1]
                                                                pick_game_player:getPropertyCache().mDirection[2] =
                                                                    -pick_game_player:getPropertyCache().mDirection[2]
                                                                pick_game_player:getPropertyCache().mDirection[3] =
                                                                    -pick_game_player:getPropertyCache().mDirection[3]
                                                                pick_game_player:getPropertyCache().mDirection =
                                                                    GameCompute.convertDirection123(
                                                                    GameCompute.computePlayerDirection(
                                                                        pick_game_player:getPropertyCache().mPosition,
                                                                        pick_game_player:getPropertyCache().mDirection,
                                                                        {orgin_dir}
                                                                    )
                                                                )
                                                                pick_game_player:getProperty():safeWrite(
                                                                    "mDirection",
                                                                    pick_game_player:getPropertyCache().mDirection,
                                                                    function()
                                                                        self.mGame:sendToClient(
                                                                            pick_game_player:getProperty().mPlayerID,
                                                                            "MessageBox",
                                                                            GetEntityById(self.mPlayer.mPlayerID).nickname ..
                                                                                "对你使用了" .. card_type
                                                                        )
                                                                        GameUI.refreshOperatorWindow()
                                                                        GameUI.showPrepareWindow()
                                                                        self.mCurrentUseCard = nil
                                                                        command.mState = Command.EState.Finish
                                                                    end
                                                                )
                                                                InputManager.removeListener(card_type)
                                                            elseif card_type == "抢夺卡" then
                                                                if pick_game_player ~= self then
                                                                    if not pick_game_player:getPropertyCache().mCards or not next(pick_game_player:getPropertyCache().mCards) then
                                                                        GameUI.messageBox("对方没有卡片")
                                                                        GameUI.refreshOperatorWindow()
                                                                        GameUI.showPrepareWindow()
                                                                        InputManager.removeListener(card_type)
                                                                        self.mCurrentUseCard = nil
                                                                        command.mState = Command.EState.Finish
                                                                    else
                                                                        GameUI.showGetCardWindow(
                                                                            pick_game_player:getPropertyCache().mCards,
                                                                            function(cardIndex)
                                                                                if cardIndex then
                                                                                    local get_card =
                                                                                        pick_game_player:getPropertyCache().mCards[
                                                                                        cardIndex
                                                                                    ]
                                                                                    self:getPropertyCache().mCards[
                                                                                            #self:getPropertyCache().mCards +
                                                                                                1
                                                                                        ] = get_card
                                                                                    self.mPlayer:safeWrite(
                                                                                        "mCards",
                                                                                        self:getPropertyCache().mCards
                                                                                    )
                                                                                    table.remove(
                                                                                        pick_game_player:getPropertyCache().mCards,
                                                                                        cardIndex
                                                                                    )
                                                                                    pick_game_player:getProperty():safeWrite(
                                                                                        "mCards",
                                                                                        pick_game_player:getPropertyCache().mCards,
                                                                                        function()
                                                                                            self.mGame:sendToClient(
                                                                                                pick_game_player:getProperty(

                                                                                                ).mPlayerID,
                                                                                                "MessageBox",
                                                                                                GetEntityById(
                                                                                                    self.mPlayer.mPlayerID
                                                                                                ).nickname ..
                                                                                                    "抢走了你的" ..
                                                                                                        GameConfig.mCards[
                                                                                                            get_card
                                                                                                        ].mType
                                                                                            )
                                                                                        end
                                                                                    )
                                                                                end
                                                                                GameUI.refreshOperatorWindow()
                                                                                GameUI.showPrepareWindow()
                                                                                InputManager.removeListener(card_type)
                                                                                self.mCurrentUseCard = nil
                                                                                command.mState = Command.EState.Finish
                                                                            end
                                                                        )
                                                                    end
                                                                else
                                                                    GameUI.messageBox("不能对自己使用")
                                                                end
                                                            elseif card_type == "换位卡" then
                                                                if pick_game_player ~= self then
                                                                    local my_next_pos =
                                                                        clone(
                                                                        pick_game_player:getPropertyCache().mPosition
                                                                    )
                                                                    local my_next_dir =
                                                                        clone(
                                                                        pick_game_player:getPropertyCache().mDirection
                                                                    )
                                                                    local it_next_pos =
                                                                        clone(self.mPlayer:cache().mPosition)
                                                                    local it_next_dir =
                                                                        clone(self.mPlayer:cache().mDirection)
                                                                    self.mPlayer:safeWrite("mPosition", my_next_pos)
                                                                    self.mPlayer:safeWrite("mDirection", my_next_dir)
                                                                    pick_game_player:getProperty():safeWrite(
                                                                        "mPosition",
                                                                        it_next_pos
                                                                    )
                                                                    pick_game_player:getProperty():safeWrite(
                                                                        "mDirection",
                                                                        it_next_dir
                                                                    )
                                                                    GameUI.refreshOperatorWindow()
                                                                    GameUI.showPrepareWindow()
                                                                    InputManager.removeListener(card_type)
                                                                    self.mCurrentUseCard = nil
                                                                    command.mState = Command.EState.Finish
                                                                else
                                                                    GameUI.messageBox("不能对自己使用")
                                                                end
                                                            elseif card_type == "陷害卡" then
                                                                pick_game_player:getProperty():safeWrite(
                                                                    "mStay",
                                                                    {mType = "监狱", mDay = 3}
                                                                )
                                                                self.mGame:sendToClient(
                                                                    pick_game_player:getProperty().mPlayerID,
                                                                    "MessageBox",
                                                                    GetEntityById(self.mPlayer.mPlayerID).nickname ..
                                                                        "对你使用了" .. card_type
                                                                )
                                                                command.mState = Command.EState.Finish
                                                                GameUI.refreshOperatorWindow()
                                                                GameUI.showPrepareWindow()
                                                                self.mCurrentUseCard = nil
                                                                InputManager.removeListener(card_type)
                                                            elseif card_type == "查税卡" then
                                                                if pick_game_player ~= self then
                                                                    local get_money =
                                                                        math.floor(
                                                                        pick_game_player:getPropertyCache().mMoney * 0.1
                                                                    )
                                                                    pick_game_player:getProperty():safeWrite(
                                                                        "mMoney",
                                                                        pick_game_player:getPropertyCache().mMoney -
                                                                            get_money
                                                                    )
                                                                    self:getProperty():safeWrite(
                                                                        "mMoney",
                                                                        self:getPropertyCache().mMoney + get_money
                                                                    )
                                                                    GameUI.messageBox(
                                                                        "缴获" ..
                                                                            GetEntityById(
                                                                                pick_game_player:getProperty().mPlayerID
                                                                            ).nickname ..
                                                                                "税款" .. tostring(get_money)
                                                                    )
                                                                    self.mGame:sendToClient(
                                                                        pick_game_player:getProperty().mPlayerID,
                                                                        "MessageBox",
                                                                        GetEntityById(self.mPlayer.mPlayerID).nickname ..
                                                                            "对你使用了" .. card_type
                                                                    )
                                                                    GameUI.refreshOperatorWindow()
                                                                    GameUI.showPrepareWindow()
                                                                    self.mCurrentUseCard = nil
                                                                    InputManager.removeListener(card_type)
                                                                    command.mState = Command.EState.Finish
                                                                else
                                                                    GameUI.messageBox("不能对自己使用")
                                                                end
                                                            elseif card_type == "乌龟卡" then
                                                                pick_game_player:getProperty():safeWrite(
                                                                    "mStep",
                                                                    {mDay = 3}
                                                                )
                                                                self.mGame:sendToClient(
                                                                    pick_game_player:getProperty().mPlayerID,
                                                                    "MessageBox",
                                                                    GetEntityById(self.mPlayer.mPlayerID).nickname ..
                                                                        "对你使用了" .. card_type
                                                                )
                                                                GameUI.refreshOperatorWindow()
                                                                GameUI.showPrepareWindow()
                                                                self.mCurrentUseCard = nil
                                                                InputManager.removeListener(card_type)
                                                                command.mState = Command.EState.Finish
                                                            elseif card_type == "停留卡" then
                                                                pick_game_player:getProperty():safeWrite(
                                                                    "mStop",
                                                                    {mDay = 1}
                                                                )
                                                                self.mGame:sendToClient(
                                                                    pick_game_player:getProperty().mPlayerID,
                                                                    "MessageBox",
                                                                    GetEntityById(self.mPlayer.mPlayerID).nickname ..
                                                                        "对你使用了" .. card_type
                                                                )
                                                                GameUI.refreshOperatorWindow()
                                                                GameUI.showPrepareWindow()
                                                                self.mCurrentUseCard = nil
                                                                InputManager.removeListener(card_type)
                                                                command.mState = Command.EState.Finish
                                                            elseif card_type == "均贫卡" then
                                                                if pick_game_player ~= self then
                                                                    local all_money = self:getPropertyCache().mMoney
                                                                    all_money =
                                                                        all_money +
                                                                        pick_game_player:getPropertyCache().mMoney
                                                                    local per_money = math.floor(all_money / 2)
                                                                    pick_game_player:getProperty():safeWrite(
                                                                        "mMoney",
                                                                        per_money
                                                                    )
                                                                    self:getProperty():safeWrite("mMoney", per_money)
                                                                    self.mGame:sendToClient(
                                                                        pick_game_player:getProperty().mPlayerID,
                                                                        "MessageBox",
                                                                        GetEntityById(self.mPlayer.mPlayerID).nickname ..
                                                                            "对你使用了" .. card_type
                                                                    )
                                                                    GameUI.refreshOperatorWindow()
                                                                    GameUI.showPrepareWindow()
                                                                    self.mCurrentUseCard = nil
                                                                    InputManager.removeListener(card_type)
                                                                    command.mState = Command.EState.Finish
                                                                else
                                                                    GameUI.messageBox("不能对自己使用")
                                                                end
                                                            end
                                                        end
                                                    end
                                                    if pick_result.blockX then
                                                        if
                                                            card_type == "障碍卡" or card_type == "地雷卡" or
                                                                card_type == "定时炸弹"
                                                         then
                                                            if
                                                                GameConfig.canMove(
                                                                    GetBlockId(
                                                                        pick_result.blockX,
                                                                        pick_result.blockY,
                                                                        pick_result.blockZ
                                                                    )
                                                                )
                                                             then
                                                                local key =
                                                                    self.mGame:getProperty():getRoadInfoPropertyName(
                                                                    {
                                                                        pick_result.blockX,
                                                                        pick_result.blockY,
                                                                        pick_result.blockZ
                                                                    }
                                                                )
                                                                self.mGame:getProperty():lockWrite(
                                                                    key,
                                                                    function(value)
                                                                        if
                                                                            value and
                                                                                (value.mBlock or value.mNPC or
                                                                                    value.mItem)
                                                                         then
                                                                            self.mGame:getProperty():unlockWrite(key)
                                                                        else
                                                                            value = value or {}
                                                                            if card_type == "障碍卡" then
                                                                                value.mBlock = true
                                                                            elseif card_type == "地雷卡" then
                                                                                value.mItem = "地雷"
                                                                            elseif card_type == "定时炸弹" then
                                                                                value.mItem = "定时炸弹"
                                                                            end
                                                                            self.mGame:getProperty():write(
                                                                                key,
                                                                                value,
                                                                                function()
                                                                                    self.mGame:sendToHost(
                                                                                        "UpdateRoad",
                                                                                        {
                                                                                            mPosition = {
                                                                                                pick_result.blockX,
                                                                                                pick_result.blockY,
                                                                                                pick_result.blockZ
                                                                                            }
                                                                                        }
                                                                                    )
                                                                                    GameUI.refreshOperatorWindow()
                                                                                    GameUI.showPrepareWindow()
                                                                                    self.mCurrentUseCard = nil
                                                                                    command.mState =
                                                                                        Command.EState.Finish
                                                                                end
                                                                            )
                                                                            command.mEntity:SetDead(true)
                                                                            command.mEntity = nil
                                                                            InputManager.removeListener(card_type)
                                                                        end
                                                                    end
                                                                )
                                                            end
                                                        elseif
                                                            card_type == "拆屋卡" or card_type == "建房卡" or
                                                                card_type == "怪兽卡" or
                                                                card_type == "换房卡"
                                                         then
                                                            local pick_pos = {
                                                                pick_result.blockX,
                                                                pick_result.blockY,
                                                                pick_result.blockZ
                                                            }
                                                            if self.mGame:getTerrain():getTerrain(pick_pos) then
                                                                local terrain_property_name =
                                                                    self.mGame:getProperty():getTerrainInfoPropertyName(
                                                                    pick_pos
                                                                )
                                                                self.mGame:getProperty():lockWrite(
                                                                    terrain_property_name,
                                                                    function(terrainProperty)
                                                                        terrainProperty =
                                                                            terrainProperty or {mLevel = 1}
                                                                        if card_type == "拆屋卡" then
                                                                            terrainProperty.mLevel =
                                                                                math.max(1, terrainProperty.mLevel - 1)
                                                                        elseif card_type == "建房卡" then
                                                                            if
                                                                                not terrainProperty.mType or
                                                                                    terrainProperty.mType == "住宅"
                                                                             then
                                                                                terrainProperty.mType = "住宅"
                                                                                terrainProperty.mLevel =
                                                                                    math.min(
                                                                                    GameConfig.mTerrainNormalMaxLevel,
                                                                                    terrainProperty.mLevel + 1
                                                                                )
                                                                            end
                                                                        elseif card_type == "怪兽卡" then
                                                                            terrainProperty.mLevel = 1
                                                                            terrainProperty.mType = nil
                                                                        elseif card_type == "换房卡" then
                                                                            local change_terrain =
                                                                                self.mGame:getTerrain():getTerrainByRoadPosition(
                                                                                self.mPlayer:cache().mPosition
                                                                            )
                                                                            local changed_terrain_property_name =
                                                                                self.mGame:getProperty():getTerrainInfoPropertyName(
                                                                                change_terrain.mPosition
                                                                            )
                                                                            self.mGame:getProperty():lockWrite(
                                                                                changed_terrain_property_name,
                                                                                function(changeTerrainProperty)
                                                                                    changeTerrainProperty =
                                                                                        changeTerrainProperty or
                                                                                        {mLevel = 1}
                                                                                    local save_property1 =
                                                                                        clone(changeTerrainProperty)
                                                                                    local save_property2 =
                                                                                        clone(terrainProperty)
                                                                                    self.mGame:getProperty():write(
                                                                                        changed_terrain_property_name,
                                                                                        save_property2
                                                                                    )
                                                                                    self.mGame:sendToHost(
                                                                                        "UpdateTerrain",
                                                                                        {
                                                                                            mPosition = change_terrain.mPosition
                                                                                        }
                                                                                    )
                                                                                    self.mGame:getProperty():safeWrite(
                                                                                        terrain_property_name,
                                                                                        save_property1
                                                                                    )
                                                                                    self.mGame:sendToHost(
                                                                                        "UpdateTerrain",
                                                                                        {
                                                                                            mPosition = pick_pos
                                                                                        }
                                                                                    )
                                                                                end
                                                                            )
                                                                        end
                                                                        self.mGame:getProperty():write(
                                                                            terrain_property_name,
                                                                            terrainProperty
                                                                        )
                                                                        self.mGame:sendToHost(
                                                                            "UpdateTerrain",
                                                                            {mPosition = pick_pos}
                                                                        )
                                                                    end
                                                                )
                                                                GameUI.refreshOperatorWindow()
                                                                GameUI.showPrepareWindow()
                                                                self.mCurrentUseCard = nil
                                                                InputManager.removeListener(card_type)
                                                                command.mState = Command.EState.Finish
                                                            end
                                                        elseif card_type == "飞弹卡" or card_type == "核子炸弹" then
                                                            local range = 1
                                                            if card_type == "飞弹卡" then
                                                                range = 1
                                                            elseif card_type == "核子炸弹" then
                                                                range = 3
                                                            end
                                                            self.mGame:boom(
                                                                {
                                                                    pick_result.blockX,
                                                                    pick_result.blockY,
                                                                    pick_result.blockZ
                                                                },
                                                                range
                                                            )
                                                            command.mEntity:SetDead(true)
                                                            command.mEntity = nil
                                                            if self.mPlayer:cache().mStay then
                                                                GameUI.onOperatorWindowCallback()
                                                            else
                                                                GameUI.refreshOperatorWindow()
                                                            end
                                                            GameUI.showPrepareWindow()
                                                            self.mCurrentUseCard = nil
                                                            InputManager.removeListener(card_type)
                                                            command.mState = Command.EState.Finish
                                                        end
                                                    end
                                                end
                                            elseif
                                                event.event_type == "mouseReleaseEvent" and
                                                    event.mouse_button == "right"
                                             then
                                                if command.mEntity then
                                                    command.mEntity:SetDead(true)
                                                    command.mEntity = nil
                                                end
                                                GameUI.refreshOperatorWindow()
                                                InputManager.removeListener(card_type)
                                                self.mCurrentUseCard = nil
                                                self:getPropertyCache().mCards[#self:getPropertyCache().mCards + 1] =
                                                    card
                                                self.mPlayer:safeWrite("mCards", self:getPropertyCache().mCards)
                                                GameUI.showPrepareWindow()
                                                command.mState = Command.EState.Finish
                                            end
                                        end
                                    )
                                end
                            }
                        )
                    )
                else
                    self.mCommandQueue:post(
                        new(
                            Command_Callback,
                            {
                                mDebug = "Command_Callback/" .. card_type,
                                mExecuteCallback = function(command)
                                    if card_type == "机车卡" or card_type == "汽车卡" then
                                        local move = 2
                                        if card_type == "汽车卡" then
                                            move = 3
                                        end
                                        self.mPlayer:safeWrite("mMove", move)
                                        self.mCurrentUseCard = nil
                                        GameUI.refreshOperatorWindow(move)
                                        command.mState = Command.EState.Finish
                                    elseif card_type == "请神卡" then
                                        self.mGame:getTerrain():getRoadCache(
                                            function(roadInfos, roadProperties)
                                                local distance = 999999999999
                                                local road_info
                                                local road_cache
                                                for k, road in pairs(roadProperties) do
                                                    if road.mNPC and GameConfig.mNPCTypes[road.mNPC] ~= "狗" then
                                                        local info = roadInfos[k]
                                                        local dst =
                                                            (self:getPropertyCache().mPosition[1] - info.mPosition[1]) *
                                                            (self:getPropertyCache().mPosition[1] - info.mPosition[1]) +
                                                            (self:getPropertyCache().mPosition[3] - info.mPosition[3]) *
                                                                (self:getPropertyCache().mPosition[3] -
                                                                    info.mPosition[3])
                                                        if distance > dst then
                                                            distance = dst
                                                            road_cache = road
                                                            road_info = info
                                                        end
                                                    end
                                                end
                                                if road_cache and road_info then
                                                    self:attachNPC(road_cache.mNPC, GameConfig.mNPCAttachDay)
                                                    road_cache.mNPC = nil
                                                    self.mGame:getProperty():safeWrite(
                                                        self.mGame:getProperty():getRoadInfoPropertyName(
                                                            road_info.mPosition
                                                        ),
                                                        road_cache
                                                    )
                                                    self.mGame:sendToHost(
                                                        "UpdateRoad",
                                                        {
                                                            mPosition = road_info.mPosition
                                                        }
                                                    )
                                                end
                                                self.mCurrentUseCard = nil
                                                GameUI.refreshOperatorWindow()
                                                command.mState = Command.EState.Finish
                                            end
                                        )
                                    elseif card_type == "送神卡" then
                                        if self:getPropertyCache().mAttachNPC then
                                            GameUI.messageBox(
                                                GameConfig.mNPCTypes[self:getPropertyCache().mAttachNPC.mType] ..
                                                    "离开了......"
                                            )
                                            self.mPlayer:safeWrite("mAttachNPC")
                                        end
                                        self.mCurrentUseCard = nil
                                        GameUI.refreshOperatorWindow()
                                        command.mState = Command.EState.Finish
                                    elseif card_type == "均富卡" then
                                        local all_money = 0
                                        local player_count = 0
                                        for _, player in pairs(self.mGame.mPlayers) do
                                            all_money = all_money + player:getPropertyCache().mMoney
                                            player_count = player_count + 1
                                        end
                                        local per_money = math.floor(all_money / player_count)
                                        for _, player in pairs(self.mGame.mPlayers) do
                                            player:getProperty():safeWrite("mMoney", per_money)
                                        end
                                        self.mCurrentUseCard = nil
                                        GameUI.refreshOperatorWindow()
                                        command.mState = Command.EState.Finish
                                    elseif card_type == "冬眠卡" then
                                        for _, player in pairs(self.mGame.mPlayers) do
                                            if player ~= self then
                                                player:getProperty():safeWrite("mSleepDay", 5)
                                            end
                                        end
                                        self.mCurrentUseCard = nil
                                        GameUI.refreshOperatorWindow()
                                        command.mState = Command.EState.Finish
                                    elseif card_type == "机器娃娃" then
                                        self:requestToHost(
                                            "UseCard",
                                            {mCardType = card_type},
                                            function()
                                                self.mCurrentUseCard = nil
                                                GameUI.refreshOperatorWindow()
                                                command.mState = Command.EState.Finish
                                            end
                                        )
                                    elseif card_type == "泡泡卡" then
                                        self.mPlayer:safeWrite("mInvincible", {mDay = 5})
                                        self.mCurrentUseCard = nil
                                        GameUI.refreshOperatorWindow()
                                        command.mState = Command.EState.Finish
                                    elseif card_type == "路霸卡" or card_type == "查封卡" or card_type == "天使卡" then
                                        local current_terrain =
                                            self.mGame.mTerrain:getTerrainByRoadPosition(self.mPlayer:cache().mPosition)
                                        if current_terrain then
                                            local terrains = {current_terrain}
                                            if current_terrain.mConfig.mName then
                                                terrains =
                                                    self.mGame.mTerrain:getTerrainsByName(current_terrain.mConfig.mName)
                                            end
                                            for _, terrain in pairs(terrains) do
                                                local terrain_property_name =
                                                    self.mGame:getProperty():getTerrainInfoPropertyName(
                                                    terrain.mPosition
                                                )
                                                self.mGame:getProperty():lockWrite(
                                                    terrain_property_name,
                                                    function(terrainProperty)
                                                        terrainProperty = terrainProperty or {mLevel = 1}
                                                        if card_type == "路霸卡" then
                                                            terrainProperty.mFakeOwner = {
                                                                mPlayerID = self.mPlayer.mPlayerID,
                                                                mDay = 5
                                                            }
                                                        elseif card_type == "查封卡" then
                                                            terrainProperty.mInvalidate = {mDay = 5}
                                                        elseif card_type == "天使卡" then
                                                            if terrainProperty.mType ~= "连锁超市" then
                                                                terrainProperty.mLevel =
                                                                    math.min(
                                                                    GameConfig.mTerrainNormalMaxLevel,
                                                                    terrainProperty.mLevel + 1
                                                                )
                                                            end
                                                        end
                                                        self.mGame:getProperty():write(
                                                            terrain_property_name,
                                                            terrainProperty
                                                        )
                                                        self.mGame:sendToHost(
                                                            "UpdateTerrain",
                                                            {mPosition = terrain.mPosition}
                                                        )
                                                    end
                                                )
                                            end
                                        end
                                        self.mCurrentUseCard = nil
                                        GameUI.refreshOperatorWindow()
                                        command.mState = Command.EState.Finish
                                    elseif card_type == "购地卡" then
                                        local current_terrain =
                                            self.mGame.mTerrain:getTerrainByRoadPosition(self.mPlayer:cache().mPosition)
                                        if current_terrain then
                                            local terrain_property_name =
                                                self.mGame:getProperty():getTerrainInfoPropertyName(
                                                current_terrain.mPosition
                                            )
                                            self.mGame:getProperty():lockWrite(
                                                terrain_property_name,
                                                function(terrainProperty)
                                                    terrainProperty = terrainProperty or {mLevel = 1}
                                                    local spend =
                                                        GameCompute.computeTerrainBuyPrice(
                                                        current_terrain.mConfig,
                                                        terrainProperty
                                                    )
                                                    if self.mPlayer:cache().mMoney >= spend then
                                                        self.mPlayer:safeWrite(
                                                            "mMoney",
                                                            self.mPlayer:cache().mMoney - spend
                                                        )
                                                        if terrainProperty.mOwnerPlayerID then
                                                            local owner_player =
                                                                self.mGame:getPlayer(terrainProperty.mOwnerPlayerID)
                                                            owner_player:getProperty():safeWrite(
                                                                "mMoneyStore",
                                                                owner_player:getPropertyCache().mMoneyStore + spend
                                                            )
                                                        end
                                                        terrainProperty.mOwnerPlayerID = self.mPlayer.mPlayerID
                                                        self.mGame:getProperty():write(
                                                            terrain_property_name,
                                                            terrainProperty
                                                        )
                                                        self.mGame:sendToHost(
                                                            "UpdateTerrain",
                                                            {mPosition = current_terrain.mPosition}
                                                        )
                                                    else
                                                        self.mGame:getProperty():unlockWrite(terrain_property_name)
                                                        GameUI.messageBox("现金不足，购地失败")
                                                    end
                                                    self.mCurrentUseCard = nil
                                                    GameUI.refreshOperatorWindow()
                                                    command.mState = Command.EState.Finish
                                                end
                                            )
                                        else
                                            self.mCurrentUseCard = nil
                                            GameUI.refreshOperatorWindow()
                                            command.mState = Command.EState.Finish
                                        end
                                    else
                                        GameUI.messageBox("开发未完成.....")
                                        command.mState = Command.EState.Finish
                                    end
                                end
                            }
                        )
                    )
                end
                self.mCommandQueue:post(new(Command_UpdatePropertyCacheClient, {mGame = self.mGame}))
            end
        end
    )
end

function GamePlayerClient:attachNPC(npc, day)
    local message = GameConfig.mNPCTypes[npc] .. "附身"
    if GameConfig.mNPCTypes[npc] == "小财神" then
        local money = math.random(1, 999)
        message = message .. "，得到金钱:" .. tostring(money)
        self:getProperty():safeWrite("mMoney", self:getPropertyCache().mMoney + money)
    elseif GameConfig.mNPCTypes[npc] == "财神" then
        local money = math.random(1, 9999)
        message = message .. "，得到金钱:" .. tostring(money)
        self:getProperty():safeWrite("mMoney", self:getPropertyCache().mMoney + money)
    elseif GameConfig.mNPCTypes[npc] == "小穷神" then
        local money = math.random(1, 999)
        message = message .. "，失去金钱:" .. tostring(money)
        self.mPlayer:costMoney(money)
        self:checkFail()
    elseif GameConfig.mNPCTypes[npc] == "穷神" then
        local money = math.random(1, 9999)
        message = message .. "，失去金钱：" .. tostring(money)
        self.mPlayer:costMoney(money)
        self:checkFail()
    elseif GameConfig.mNPCTypes[npc] == "小衰神" then
        if self:getPropertyCache().mCards and #self:getPropertyCache().mCards >= 1 then
            local card_index = math.random(1, #self:getPropertyCache().mCards)
            local card = self:getPropertyCache().mCards[card_index]
            message = message .. "，失去卡片：" .. tostring(GameConfig.mCards[card].mType)
            table.remove(self:getPropertyCache().mCards, card_index)
            self:getProperty():safeWrite("mCards", self:getPropertyCache().mCards)
        end
    elseif GameConfig.mNPCTypes[npc] == "衰神" then
        if self:getPropertyCache().mCards then
            local cards = {}
            for i = 1, 2 do
                if #self:getPropertyCache().mCards >= 1 then
                    local card_index = math.random(1, #self:getPropertyCache().mCards)
                    cards[#cards + 1] = GameConfig.mCards[self:getPropertyCache().mCards[card_index]].mType
                    table.remove(self:getPropertyCache().mCards, card_index)
                end
            end
            if #cards > 0 then
                message = message .. "，失去卡片：" .. cards[1]
                if cards[2] then
                    message = message .. "，" .. cards[2]
                end
                self:getProperty():safeWrite("mCards", self:getPropertyCache().mCards)
            end
        end
    elseif GameConfig.mNPCTypes[npc] == "小福神" then
        self:getPropertyCache().mCards = self:getPropertyCache().mCards or {}
        if #self:getPropertyCache().mCards < GameConfig.mMaxCard then
            local card = math.random(1, #GameConfig.mCards)
            message = message .. "，获得卡片：" .. GameConfig.mCards[card].mType
            self:getPropertyCache().mCards[#self:getPropertyCache().mCards + 1] = card
            self:getProperty():safeWrite("mCards", self:getPropertyCache().mCards)
        end
    elseif GameConfig.mNPCTypes[npc] == "福神" then
        self:getPropertyCache().mCards = self:getPropertyCache().mCards or {}
        if #self:getPropertyCache().mCards < GameConfig.mMaxCard then
            local card = math.random(1, #GameConfig.mCards)
            self:getPropertyCache().mCards[#self:getPropertyCache().mCards + 1] = card
            message = message .. "，获得卡片：" .. GameConfig.mCards[card].mType
        end
        if #self:getPropertyCache().mCards < GameConfig.mMaxCard then
            local card = math.random(1, #GameConfig.mCards)
            self:getPropertyCache().mCards[#self:getPropertyCache().mCards + 1] = card
            message = message .. "，" .. GameConfig.mCards[card].mType
        end
        self:getProperty():safeWrite("mCards", self:getPropertyCache().mCards)
    elseif GameConfig.mNPCTypes[npc] == "狗" then
        if self:getPropertyCache().mMove == 1 then
            day = 2
            npc = nil
            message = "被狗咬了，住院" .. tostring(day) .. "天..."
            self:getProperty():safeWrite("mStay", {mType = "医院", mDay = day})
        else
            npc = nil
            day = nil
            message = nil
        end
    elseif GameConfig.mNPCTypes[npc] == "土地神" then
        message = message .. "，侵占土地"
    end
    if message then
        GameUI.messageBox(message)
    end
    if npc then
        self:getProperty():safeWrite("mAttachNPC", {mType = npc, mDay = day})
    end
end

function GamePlayerClient:prepare()
    if self:checkFail() then
        return
    end
    if self:getPropertyCache().mAttachNPC then
        if 0 > self:getPropertyCache().mAttachNPC.mDay then
            GameUI.messageBox(GameConfig.mNPCTypes[self:getPropertyCache().mAttachNPC.mType] .. "离开了......")
            self.mPlayer:safeWrite("mAttachNPC")
        else
            GameUI.messageBox(
                GameConfig.mNPCTypes[self:getPropertyCache().mAttachNPC.mType] ..
                    "距离开还有" .. tostring(self:getPropertyCache().mAttachNPC.mDay) .. "天......"
            )
        end
    end
    if self:getPropertyCache().mSleepDay then
        if self:getPropertyCache().mSleepDay > 0 then
            GameUI.messageBox("睡觉中，还有" .. tostring(self:getPropertyCache().mSleepDay) .. "天")
        else
            self.mPlayer:safeWrite("mSleepDay")
        end
    end
    if self:getPropertyCache().mStay then
        if self:getPropertyCache().mStay.mDay > 0 then
            GameUI.messageBox(
                "在" ..
                    self:getPropertyCache().mStay.mType .. "，还有" .. tostring(self:getPropertyCache().mStay.mDay) .. "天"
            )
        else
            self.mPlayer:safeWrite("mStay")
        end
    end
    if self.mPlayer:cache().mInvincible then
        if self:getPropertyCache().mInvincible.mDay > 0 then
            GameUI.messageBox("无敌效果还有" .. tostring(self:getPropertyCache().mInvincible.mDay) .. "天")
        else
            self.mPlayer:safeWrite("mInvincible")
        end
    end
    if self.mPlayer:cache().mStep then
        if self:getPropertyCache().mStep.mDay <= 0 then
            self.mPlayer:safeWrite("mStep")
        end
    end
    if self.mPlayer:cache().mStop then
        if self:getPropertyCache().mStop.mDay <= 0 then
            self.mPlayer:safeWrite("mStop")
        end
    end
    if self.mPlayer:cache().mBankStop then
        if self:getPropertyCache().mBankStop.mDay <= 0 then
            self.mPlayer:safeWrite("mBankStop")
        end
    end
end

function GamePlayerClient:post()
    if self:getPropertyCache().mAttachNPC then
        self:getPropertyCache().mAttachNPC.mDay = self:getPropertyCache().mAttachNPC.mDay - 1
        self.mPlayer:safeWrite("mAttachNPC", self:getPropertyCache().mAttachNPC)
    end
    if self:getPropertyCache().mSleepDay then
        local last_day = self:getPropertyCache().mSleepDay - 1
        self.mPlayer:safeWrite("mSleepDay", last_day)
    end
    if self:getPropertyCache().mStay then
        self:getPropertyCache().mStay.mDay = self:getPropertyCache().mStay.mDay - 1
        self.mPlayer:safeWrite("mStay", self:getPropertyCache().mStay)
    end
    if self.mPlayer:cache().mInvincible then
        self:getPropertyCache().mInvincible.mDay = self:getPropertyCache().mInvincible.mDay - 1
        self.mPlayer:safeWrite("mInvincible", self:getPropertyCache().mInvincible)
    end
    if self.mPlayer:cache().mStep then
        self:getPropertyCache().mStep.mDay = self:getPropertyCache().mStep.mDay - 1
        self.mPlayer:safeWrite("mStep", self:getPropertyCache().mStep)
    end
    if self.mPlayer:cache().mStop then
        self:getPropertyCache().mStop.mDay = self:getPropertyCache().mStop.mDay - 1
        self.mPlayer:safeWrite("mStop", self:getPropertyCache().mStop)
    end
    if self.mPlayer:cache().mBankStop then
        self:getPropertyCache().mBankStop.mDay = self:getPropertyCache().mBankStop.mDay - 1
        self.mPlayer:safeWrite("mBankStop", self:getPropertyCache().mBankStop)
    end
end

function GamePlayerClient:checkFail()
    assert(
        self:getPropertyCache().mMoney >= 0 and self:getPropertyCache().mMoneyStore >= 0,
        "GamePlayerClient:checkFail"
    )
    if self:getPropertyCache().mMoney <= 0 and self:getPropertyCache().mMoneyStore <= 0 then
        self.mPlayer:safeWrite("mFail", true)
        return true
    end
end

function GamePlayerClient:sendToHost(message, parameter)
    assert(self.mPlayer.mPlayerID == GetPlayerId(), "GamePlayerClient:sendToHost")
    Client.sendToHost("GamePlayer", {mMessage = message, mParameter = parameter})
end

function GamePlayerClient:requestToHost(message, parameter, callback)
    assert(self.mPlayer.mPlayerID == GetPlayerId(), "GamePlayerClient:requestToHost")
    self.mResponseCallback = self.mResponseCallback or {}
    self.mResponseCallback[message] = callback
    self:sendToHost(message, parameter)
end

function GamePlayerClient:receive(parameter)
    assert(self.mPlayer.mPlayerID == GetPlayerId(), "GamePlayerClient:receive")
    local is_responese, _ = string.find(parameter.mMessage, "_Response")
    if is_responese then
        local message = string.sub(parameter.mMessage, 1, is_responese - 1)
        if self.mResponseCallback[message] then
            self.mResponseCallback[message](parameter.mParameter)
            self.mResponseCallback[message] = nil
        end
    elseif parameter.mMessage == "Winner" then
        GameUI.messageBox("您获胜了，恭喜恭喜......")
    elseif parameter.mMessage == "Restart" then
        GameManagerClient.singleton():clear()
        GameManagerClient.singleton():start()
    end
end
-----------------------------------------------------------------------------------------Player Manager-----------------------------------------------------------------------------------------
function PlayerManager.initialize()
    PlayerManager.onPlayerIn(EntityWatcher.get(GetPlayerId()))
    EntityWatcher.on(
        "create",
        function(inst)
            PlayerManager.onPlayerIn(inst)
            if PlayerManager.mHideAll then
                PlayerManager.hideAll()
            end
        end
    )
end

function PlayerManager.onPlayerIn(entityWatcher)
    local player = new(Player, {mEntityWatcher = entityWatcher})
    PlayerManager.mPlayers = PlayerManager.mPlayers or {}
    PlayerManager.mPlayers[entityWatcher.id] = player
    PlayerManager.notify("PlayerIn", {mPlayerID = entityWatcher.id})
end

function PlayerManager.getPlayer(id)
    id = id or GetPlayerId()
    return PlayerManager.mPlayers[id]
end

function PlayerManager.update()
    for id, player in pairs(PlayerManager.mPlayers) do
        if not GetEntityById(id) then
            PlayerManager.notify("PlayerRemoved", {mPlayerID = id})
            PlayerManager.mPlayers[id] = nil
        end
    end
end

function PlayerManager.showAll()
    PlayerManager.mHideAll = nil
    for _, player in pairs(PlayerManager.mPlayers) do
        player.mEntity:SetVisible(true)
        player.mEntity:ShowHeadOnDisplay(true)
    end
end

function PlayerManager.hideAll()
    PlayerManager.mHideAll = true
    for _, player in pairs(PlayerManager.mPlayers) do
        player.mEntity:ShowHeadOnDisplay(false)
        player.mEntity:SetVisible(false)
    end
end

function PlayerManager.clear()
end

function PlayerManager.addEventListener(eventType, key, callback, parameter)
    PlayerManager.mEventListeners = PlayerManager.mEventListeners or {}
    PlayerManager.mEventListeners[eventType] = PlayerManager.mEventListeners[eventType] or {}
    PlayerManager.mEventListeners[eventType][key] = {mCallback = callback, mParameter = parameter}
end

function PlayerManager.removeEventListener(eventType, key)
    PlayerManager.mEventListeners = PlayerManager.mEventListeners or {}
    PlayerManager.mEventListeners[eventType] = PlayerManager.mEventListeners[eventType] or {}
    PlayerManager.mEventListeners[eventType][key] = nil
end

function PlayerManager.notify(eventType, parameter)
    if PlayerManager.mEventListeners and PlayerManager.mEventListeners[eventType] then
        local listeners = PlayerManager.mEventListeners[eventType]
        for key, listener in pairs(listeners) do
            listener.mCallback(listener.mParameter, parameter)
        end
    end
end
-----------------------------------------------------------------------------------------Game Config-----------------------------------------------------------------------------------------
function GameConfig.getPoint(blockID)
    point_key = "mPointBlockID_"
    for key, value in pairs(GameConfig.mWalkBlockIDs) do
        local start, last = string.find(key, point_key)
        if last and blockID == value then
            return tonumber(string.sub(key, last + 1))
        end
    end
end

function GameConfig.getConfigBlockPosition(x, y, z)
    local ret
    local poses = {{x + 1, y, z}, {x - 1, y, z}, {x, y, z + 1}, {x, y, z - 1}}
    for _, pos in pairs(poses) do
        local block_id, block_data, entity_data = GetBlockFull(pos[1], pos[2], pos[3])
        --check config text
        if block_id == GameConfig.mConfigBlockID then
            ret = ret or {}
            ret[#ret + 1] = pos
        end
    end
    return ret
end

function GameConfig.getGameConfig(x, y, z)
    local ret = {}
    local block_id, block_data, entity_data = GetBlockFull(x, y, z)
    local config_text = entity_data[1][1][1]
    local line_config_text = lineStrings(config_text)
    local init_money = 0
    local init_move = 1
    local init_money_store = 0
    local init_point = 0
    local player_count = 1
    for _, line_text in pairs(line_config_text) do
        local start_pos, end_pos = string.find(line_text, "初始金钱:")
        if start_pos then
            init_money = string.sub(line_text, end_pos + 1)
            init_money = tonumber(init_money)
        end
        local start_pos, end_pos = string.find(line_text, "初始移动:")
        if start_pos then
            init_move = string.sub(line_text, end_pos + 1)
            init_move = tonumber(init_move)
        end
        local start_pos, end_pos = string.find(line_text, "初始存款:")
        if start_pos then
            init_money_store = string.sub(line_text, end_pos + 1)
            init_money_store = tonumber(init_money_store)
        end
        local start_pos, end_pos = string.find(line_text, "初始点券:")
        if start_pos then
            init_point = string.sub(line_text, end_pos + 1)
            init_point = tonumber(init_point)
        end
        local start_pos, end_pos = string.find(line_text, "玩家数:")
        if start_pos then
            player_count = string.sub(line_text, end_pos + 1)
            player_count = tonumber(player_count)
        end
        local start_pos, end_pos = string.find(line_text, "初始金钱：")
        if start_pos then
            init_money = string.sub(line_text, end_pos + 1)
            init_money = tonumber(init_money)
        end
        local start_pos, end_pos = string.find(line_text, "初始移动：")
        if start_pos then
            init_move = string.sub(line_text, end_pos + 1)
            init_move = tonumber(init_move)
        end
        local start_pos, end_pos = string.find(line_text, "初始存款：")
        if start_pos then
            init_money_store = string.sub(line_text, end_pos + 1)
            init_money_store = tonumber(init_money_store)
        end
        local start_pos, end_pos = string.find(line_text, "初始点券：")
        if start_pos then
            init_point = string.sub(line_text, end_pos + 1)
            init_point = tonumber(init_point)
        end
        local start_pos, end_pos = string.find(line_text, "玩家数：")
        if start_pos then
            player_count = string.sub(line_text, end_pos + 1)
            player_count = tonumber(player_count)
        end
    end
    -- echo("devilwalk", "GameConfig.getGameConfig:line_config_text")
    -- echo("devilwalk", line_config_text)

    ret.mInitMoney = init_money
    ret.mInitMove = init_move
    ret.mInitMoneyStore = init_money_store
    ret.mInitPoint = init_point
    ret.mPlayerCount = player_count
    return ret
end

function GameConfig.getTerrainConfig(x, y, z)
    GameConfig.mTerrainConfigs = GameConfig.mTerrainConfigs or {}
    local key = tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
    if not GameConfig.mTerrainConfigs[key] then
        local block_id, block_data, entity_data = GetBlockFull(x, y, z)
        --echo("devilwalk",entity_data)
        if not entity_data or not entity_data[1] or not entity_data[1][1] or not entity_data[1][1][1] then
            return
        end
        local config_text = entity_data[1][1][1]
        local line_config_text = lineStrings(config_text)
        local price
        local spend
        local level
        local name
        local group
        for _, line_text in pairs(line_config_text) do
            local start_pos, end_pos = string.find(line_text, "价格:")
            if start_pos then
                price = string.sub(line_text, end_pos + 1)
                price = tonumber(price)
            end
            local start_pos, end_pos = string.find(line_text, "消费:")
            if start_pos then
                spend = string.sub(line_text, end_pos + 1)
                spend = tonumber(spend)
            end
            local start_pos, end_pos = string.find(line_text, "等级:")
            if start_pos then
                level = string.sub(line_text, end_pos + 1)
                level = tonumber(level)
            end
            local start_pos, end_pos = string.find(line_text, "地名:")
            if start_pos then
                name = string.sub(line_text, end_pos + 1)
            end
            local start_pos, end_pos = string.find(line_text, "站名:")
            if start_pos then
                name = string.sub(line_text, end_pos + 1)
            end
            local start_pos, end_pos = string.find(line_text, "世站名:")
            if start_pos then
                name = string.sub(line_text, end_pos + 1)
            end
            local start_pos, end_pos = string.find(line_text, "组名:")
            if start_pos then
                group = string.sub(line_text, end_pos + 1)
            end

            local start_pos, end_pos = string.find(line_text, "价格：")
            if start_pos then
                price = string.sub(line_text, end_pos + 1)
                price = tonumber(price)
            end
            local start_pos, end_pos = string.find(line_text, "消费：")
            if start_pos then
                spend = string.sub(line_text, end_pos + 1)
                spend = tonumber(spend)
            end
            local start_pos, end_pos = string.find(line_text, "等级：")
            if start_pos then
                level = string.sub(line_text, end_pos + 1)
                level = tonumber(level)
            end
            local start_pos, end_pos = string.find(line_text, "地名：")
            if start_pos then
                name = string.sub(line_text, end_pos + 1)
            end
            local start_pos, end_pos = string.find(line_text, "站名：")
            if start_pos then
                name = string.sub(line_text, end_pos + 1)
            end
            local start_pos, end_pos = string.find(line_text, "世站名：")
            if start_pos then
                name = string.sub(line_text, end_pos + 1)
            end
            local start_pos, end_pos = string.find(line_text, "组名：")
            if start_pos then
                group = string.sub(line_text, end_pos + 1)
            end
        end

        if price and spend then
            local ret = {}
            ret.mPrice = price
            ret.mSpend = spend
            ret.mLevel = level
            ret.mName = name
            ret.mGroup = group
            GameConfig.mTerrainConfigs[key] = ret
        end
    end
    return GameConfig.mTerrainConfigs[key]
end

function GameConfig.canMove(blockID)
    for _, id in pairs(GameConfig.mWalkBlockIDs) do
        if id == blockID then
            return true
        end
    end
    return false
end
-----------------------------------------------------------------------------------------Game Terrain-----------------------------------------------------------------------------------------
function GameTerrain:construction(parameter)
    self.mHomePosition = parameter.mHomePosition
    self.mProperty = parameter.mProperty
    self:parse(self.mHomePosition)
    self.mTerrainGroups = {}
    for _, terrain in pairs(self.mTerrains) do
        if terrain.mConfig.mGroup then
            self.mTerrainGroups[terrain.mConfig.mGroup] = self.mTerrainGroups[terrain.mConfig.mGroup] or {}
            local group = self.mTerrainGroups[terrain.mConfig.mGroup]
            group[#group + 1] = terrain
        end
    end
end

function GameTerrain:destruction()
end

function GameTerrain:parse(pos)
    local block_id = GetBlockId(pos[1], pos[2], pos[3])
    self.mTerrains = self.mTerrains or {}
    self.mRoads = self.mRoads or {}
    local key = tostring(pos[1]) .. "," .. tostring(pos[2]) .. "," .. tostring(pos[3])
    if GameConfig.canMove(block_id) then
        if self.mRoads[key] then
            return
        end
        self.mRoads[key] = {mPosition = pos, mBlockID = block_id}
        local dirs = {{1, 0, 0}, {-1, 0, 0}, {0, 0, 1}, {0, 0, -1}}
        for _, dir in pairs(dirs) do
            local next_pos = {pos[1] + dir[1], pos[2] + dir[2], pos[3] + dir[3]}
            self:parse(next_pos)
        end
        local config_poses = GameConfig.getConfigBlockPosition(pos[1], pos[2] + 3, pos[3])
        if config_poses then
            for _, config_pos in pairs(config_poses) do
                local terrain_config = GameConfig.getTerrainConfig(config_pos[1], config_pos[2], config_pos[3])
                if terrain_config then
                    local terrain_pos = {config_pos[1], config_pos[2] - 3, config_pos[3]}
                    self.mTerrains[
                            tostring(terrain_pos[1]) ..
                                "," .. tostring(terrain_pos[2]) .. "," .. tostring(terrain_pos[3])
                        ] = {
                        mRoadPosition = pos,
                        mPosition = terrain_pos,
                        mConfig = terrain_config
                    }
                end
            end
        end
    end
end

function GameTerrain:getTerrain(pos)
    local key = tostring(pos[1]) .. "," .. tostring(pos[2]) .. "," .. tostring(pos[3])
    return self.mTerrains[key]
end

function GameTerrain:getTerrainsByName(name)
    local ret
    for _, terrain in pairs(self.mTerrains) do
        if terrain.mConfig.mName == name then
            ret = ret or {}
            ret[#ret + 1] = terrain
        end
    end
    return ret
end

function GameTerrain:getTerrainByRoadPosition(pos)
    local ret
    for _, terrain in pairs(self.mTerrains) do
        if vec3Equal(terrain.mRoadPosition, pos) then
            ret = terrain
            break
        end
    end
    return ret
end

function GameTerrain:getTerrains()
    return self.mTerrains
end

function GameTerrain:getRoad(pos)
    local key = tostring(pos[1]) .. "," .. tostring(pos[2]) .. "," .. tostring(pos[3])
    return self.mRoads[key]
end

function GameTerrain:getRoads()
    return self.mRoads
end

function GameTerrain:getTerrainCache(callback)
    for _, terrain in pairs(self.mTerrains) do
        self.mProperty:commandRead(self.mProperty:getTerrainInfoPropertyName(terrain.mPosition))
    end
    self.mProperty:commandFinish(
        function()
            local infos = {}
            local caches = {}
            for _, terrain in pairs(self.mTerrains) do
                infos[#infos + 1] = terrain
                caches[#caches + 1] =
                    self.mProperty:cache()[self.mProperty:getTerrainInfoPropertyName(terrain.mPosition)]
            end
            callback(infos, caches)
        end
    )
end

function GameTerrain:getRoadCache(callback)
    for _, terrain in pairs(self.mRoads) do
        self.mProperty:commandRead(self.mProperty:getRoadInfoPropertyName(terrain.mPosition))
    end
    self.mProperty:commandFinish(
        function()
            local infos = {}
            local caches = {}
            for _, terrain in pairs(self.mRoads) do
                infos[#infos + 1] = terrain
                caches[#caches + 1] = self.mProperty:cache()[self.mProperty:getRoadInfoPropertyName(terrain.mPosition)]
            end
            callback(infos, caches)
        end
    )
end
-----------------------------------------------------------------------------------------Game-----------------------------------------------------------------------------------------
function Game:construction(parameter)
end

function Game:destruction()
end

function Game:getTerrainInfoPropertyName(pos)
    return "mTerrainInfo/" .. tostring(pos[1]) .. "," .. tostring(pos[2]) .. "," .. tostring(pos[3])
end

function Game:getRoadInfoPropertyName(pos)
    return "mRoadInfo/" .. tostring(pos[1]) .. "," .. tostring(pos[2]) .. "," .. tostring(pos[3])
end

function Game:_getLockKey(property)
    return "Game/" .. property
end
-----------------------------------------------------------------------------------------Game Host-----------------------------------------------------------------------------------------
function GameHost:construction(parameter)
    self.mGameConfig = parameter.mConfig
    echo("devilwalk", "GameHost:construction:self.mGameConfig:")
    echo("devilwalk", self.mGameConfig)
    self.mGame = new(Game)
    local x, y, z = GetHomePosition()
    x, y, z = ConvertToBlockIndex(x, y + 0.5, z)
    y = y - 1
    self.mHomePosition = {x, y, z}
    self.mGame:safeWrite("mHomePosition", self.mHomePosition)
    local last_tickets = {}
    for i = 1, GameConfig.mTicketCount do
        last_tickets[#last_tickets + 1] = i
    end
    self.mGame:safeWrite("mLastTickets", last_tickets)
    self.mGame:safeWrite("mTicketBouns", GameConfig.mTicketBouns)
    self.mCommandQueue = new(CommandQueue)
    Host.addListener("Game", self)

    PlayerManager.addEventListener(
        "PlayerRemoved",
        "GameHost",
        function(inst, parameter)
            self.mGame:read(
                "mCurrentRunPlayer",
                function(value)
                    if self.mPlayers[parameter.mPlayerID] then
                        local current_run_player = value
                        if current_run_player == parameter.mPlayerID then
                            inst:nextPlayer(parameter.mPlayerID)
                        end
                        self.mPlayers[parameter.mPlayerID]:getProperty():safeWrite("mOnline", false)
                    end
                end
            )
        end,
        self
    )

    self.mTerrain = new(GameTerrain, {mHomePosition = self.mHomePosition, mProperty = self.mGame})
    local terrains = self.mTerrain:getTerrains()
    for _, terrain_info in pairs(terrains) do
        self:updateTerrain(terrain_info.mPosition)
    end

    self.mDayRefreshes = {}
    self.mDayRefreshes["GameTimeOverTest"] = {
        mFunction = function()
            local now_days = self.mGame:cache().mDay.mDay
            for i = 1, self.mGame:cache().mDay.mMonth do
                now_days = now_days + GameCompute.computeMonthDays(i)
            end
            local first_days = self.mGame:cache().mFirstDay.mDay
            for i = 1, self.mGame:cache().mFirstDay.mMonth do
                first_days = first_days + GameCompute.computeMonthDays(i)
            end
            if now_days - first_days >= self.mGameConfig.mGameMonth * 30 then
                self:selectWinner()
            end
        end
    }

    echo("devilwalk", "GameHost:construction:self.mHomePosition:")
    echo("devilwalk", self.mHomePosition)
end

function GameHost:destruction()
    if self.mPlayers then
        for _, player in pairs(self.mPlayers) do
            delete(player)
        end
    end
    if self.mTerrainInfos then
        for _, terrain_info in pairs(self.mTerrainInfos) do
            local terrain_property_name = self.mGame:getTerrainInfoPropertyName(terrain_info.mPosition)
            self.mGame:safeWrite(terrain_property_name)
            self:restoreTerrain(terrain_info.mPosition)
            if terrain_info.mTerrainEntityDown then
                terrain_info.mTerrainEntityDown:SetDead(true)
            end
            if terrain_info.mTerrainEntityUp then
                terrain_info.mTerrainEntityUp:SetDead(true)
            end
        end
    end
    if self.mRoadInfos then
        for _, terrain_info in pairs(self.mRoadInfos) do
            local terrain_property_name = self.mGame:getRoadInfoPropertyName(terrain_info.mPosition)
            self.mGame:safeWrite(terrain_property_name)
            for _, entity in pairs(terrain_info.mEntities) do
                entity:SetDead(true)
            end
        end
    end
    PlayerManager.removeEventListener("PlayerRemoved", "Game")
    Host.removeListener("Game", self)
end

function GameHost:update()
    self.mCommandQueue:update()
    self.mGame:update()
    if self.mPlayers then
        for _, player in pairs(self.mPlayers) do
            player:update()
        end
    end
    if self.mDeleteThis then
        GameManagerHost.singleton():clear()
    end
end

function GameHost:getProperty()
    return self.mGame
end

function GameHost:getTerrain()
    return self.mTerrain
end

function GameHost:isStart()
    return self.mStarted
end

function GameHost:start()
    echo("devilwalk", "GameHost:start")
    self.mStarted = true
    self.mGame:safeWrite(
        "mDay",
        {mMonth = math.random(1, 12), mDay = math.random(1, 28)},
        function()
            self.mGame:safeWrite("mFirstDay", self.mGame:cache().mDay)
            self:nextPlayer()
        end
    )
end

function GameHost:addPlayer(playerID)
    echo("devilwalk", "GameHost:addPlayer:playerID:" .. tostring(playerID))
    self.mPlayers = self.mPlayers or {}
    local cards = {}
    -- for i = 1, 3 do
    --     cards[i] = i
    -- end
    local roads = {}
    for _, road in pairs(self.mTerrain:getRoads()) do
        roads[#roads + 1] = road
    end
    self.mPlayers[playerID] =
        self.mPlayers[playerID] or
        new(
            GamePlayerHost,
            {
                mPlayerID = playerID,
                mGame = self,
                mResource = self:_getNextRoleResource(),
                mPosition = roads[math.random(1, #roads)].mPosition,
                mMoney = self.mGameConfig.mMoney,
                mMove = 1,
                mMoneyStore = self.mGameConfig.mMoneyStore,
                mPoint = self.mGameConfig.mPoint,
                mCards = cards
            }
        )
end

function GameHost:getPlayer(playerID)
    playerID = playerID or GetPlayerId()
    return self.mPlayers[playerID]
end

function GameHost:updatePropertyCache(callback)
    self.mGame.mCache = {}
    local player_checks = {}
    local player_checked
    local function _check()
        if player_checked then
            self.mGame:commandRead("mDay")
            self.mGame:commandRead("mLastTickets")
            self.mGame:commandRead("mTicketBouns")
            self.mGame:commandRead("mFirstDay")
            self.mGame:commandFinish(
                function()
                    echo("devilwalk", "GameHost:updatePropertyCache:finish")
                    callback()
                end
            )
        end
    end
    local function _checkPlayer()
        if self.mPlayers then
            for key, player in pairs(self.mPlayers) do
                if not player_checks[key] then
                    return
                end
            end
        end
        echo("devilwalk", "GameHost:updatePropertyCache:player finish")
        player_checked = true
        _check()
    end
    if self.mPlayers then
        for key, player in pairs(self.mPlayers) do
            player:updatePropertyCache(
                function()
                    player_checks[key] = true
                    _checkPlayer()
                end
            )
        end
    else
        player_checked = true
    end
end

function GameHost:sendToClient(playerID, message, parameter)
    Host.sendTo(playerID, {mKey = "Game", mMessage = message, mParameter = parameter})
end

function GameHost:requestToClient(playerID, message, parameter, callbackKey, callback)
    self.mResponseCallback = self.mResponseCallback or {}
    self.mResponseCallback[callbackKey] = callback
    self:sendToClient(playerID, message, parameter)
end

function GameHost:broadcast(message, parameter)
    Host.broadcast({mKey = "Game", mMessage = message, mParameter = parameter})
end

function GameHost:nextPlayer(currentPlayerID)
    self.mCommandQueue:post(new(Command_UpdatePropertyCacheHost, {mGame = self}))
    self.mCommandQueue:post(
        new(
            Command_Callback,
            {
                mDebug = "Command_Callback/NextPlayer",
                mExecuteCallback = function(command)
                    local left_players = {}
                    for id, player in pairs(self.mPlayers) do
                        if player:getPropertyCache().mOnline and not player:getPropertyCache().mFail then
                            left_players[#left_players + 1] = player
                        end
                    end
                    -- echo("devilwalk", "GameHost:nextPlayer:need_restart:" .. tostring(need_restart))
                    if #left_players > 1 then
                        -- echo(
                        --     "devilwalk",
                        --     "GameHost:nextPlayer:" .. GetEntityById(next_player:getProperty().mPlayerID).nickname
                        -- )
                        local find = false
                        local next_player
                        for id, player in pairs(self.mPlayers) do
                            if player:getPropertyCache().mOnline and not player:getPropertyCache().mFail and find then
                                next_player = player
                                break
                            end
                            if id == currentPlayerID then
                                find = true
                            end
                        end
                        if not next_player then
                            self:nextDay()
                            for id, player in pairs(self.mPlayers) do
                                if player:getPropertyCache().mOnline and not player:getPropertyCache().mFail then
                                    next_player = player
                                    break
                                end
                            end
                        end
                        self.mGame:safeWrite("mCurrentRunPlayer", next_player:getProperty().mPlayerID)
                    else
                        left_players[1]:sendToClient("Winner")
                        for id, player in pairs(self.mPlayers) do
                            player:sendToClient("Restart")
                        end
                        self.mGame:safeWrite("mCurrentRunPlayer")
                        self.mDeleteThis = true
                    end
                    command.mState = Command.EState.Finish
                end
            }
        )
    )
end

function GameHost:nextDay()
    self.mGame:read(
        "mDay",
        function(today)
            self:dayRefresh()
            local week_day = GameCompute.computeWeekDay(today.mMonth, today.mDay)
            if week_day == 1 then
                self:weekRefresh()
            end
            if today.mDay == 1 then
                self:monthRefresh()
            end
            self.mGame:safeWrite("mDay", GameCompute.computeTomorrow(today.mMonth, today.mDay))
        end
    )
end

function GameHost:selectWinner()
    local left_players = {}
    for id, player in pairs(self.mPlayers) do
        if player:getPropertyCache().mOnline and not player:getPropertyCache().mFail then
            left_players[#left_players + 1] = player
        end
    end
    local winner
    for _, player in pairs(left_players) do
        if not winner then
            winner = player
        else
            if self.mGameConfig.mSuccessCondition == 1 then
                if
                    winner:getPropertyCache().mMoney + winner:getPropertyCache().mMoneyStore <
                        player:getPropertyCache().mMoney + player:getPropertyCache().mMoneyStore
                 then
                    winner = player
                end
            -- elseif self.mGameConfig.mSuccessCondition == 2 then
            --     if winner:getPropertyCache().mPoint < player:getPropertyCache().mPoint then
            --         winner = player
            --     end
            elseif self.mGameConfig.mSuccessCondition == 2 then
                local terrain_count = 0
                local winner_terrain_count = 0
                for _, terrain in pairs(self.mTerrainInfos) do
                    if terrain.mPropertyCache.mOwnerPlayerID == winner:getProperty().mPlayerID then
                        winner_terrain_count = winner_terrain_count + 1
                    end
                    if terrain.mPropertyCache.mOwnerPlayerID == player:getProperty().mPlayerID then
                        terrain_count = terrain_count + 1
                    end
                end
                if winner_terrain_count < terrain_count then
                    winner = player
                end
            end
        end
    end
    winner:sendToClient("Winner")
    for id, player in pairs(self.mPlayers) do
        player:sendToClient("Restart")
    end
    self.mGame:safeWrite("mCurrentRunPlayer")
    GameManagerHost.singleton():clear()
end

function GameHost:receive(parameter)
    --echo("devilwalk", "GameHost:receive:parameter:")
    --echo("devilwalk", parameter)
    local is_responese, _ = string.find(parameter.mMessage, "_Response")
    if is_responese then
        local message = string.sub(parameter.mMessage, 1, is_responese - 1)
        if self.mResponseCallback[message] then
            self.mResponseCallback[message](parameter.mParameter)
            self.mResponseCallback[message] = nil
        end
    elseif parameter.mMessage == "NextPlayer" then
        self:nextPlayer(parameter._from)
    elseif parameter.mMessage == "UpdateTerrain" then
        self:updateTerrain(parameter.mParameter.mPosition)
    elseif parameter.mMessage == "UpdateRoad" then
        self:updateRoad(parameter.mParameter.mPosition)
    end
end

function GameHost:_getNextRoleResource()
    if not self.mRoleResources then
        self.mRoleResources = {}
        for i = 1, #GameConfig.mRoleEntityResources do
            self.mRoleResources[#self.mRoleResources + 1] = i
        end
    end
    if #self.mRoleResources > 0 then
        local index = math.random(1, #self.mRoleResources)
        local ret = self.mRoleResources[index]
        table.remove(self.mRoleResources, index)
        return ret
    end
end

function GameHost:updateTerrain(pos)
    local terrain_property_name = self.mGame:getTerrainInfoPropertyName(pos)
    self:getProperty():read(
        terrain_property_name,
        function(terrainProperty)
            local terrain_key = tostring(pos[1]) .. "," .. tostring(pos[2]) .. "," .. tostring(pos[3])
            local terrain_config = self.mTerrain:getTerrain(pos).mConfig
            self.mTerrainInfos = self.mTerrainInfos or {}
            self.mTerrainInfos[terrain_key] = self.mTerrainInfos[terrain_key] or {}
            local terrain_info = self.mTerrainInfos[terrain_key]
            terrain_info.mPropertyCache = terrainProperty
            terrain_info.mPosition = pos
            terrainProperty = terrainProperty or {mLevel = 1}
            if terrainProperty.mOwnerPlayerID then
                local player = self.mPlayers[terrainProperty.mOwnerPlayerID]
                setBlock(pos[1], pos[2], pos[3], GameConfig.mRoleBlockIDs[player.mResource])
            end
            if terrainProperty.mFakeOwner then
                local day_refresh_key = "Terrain/" .. terrain_key .. "/FakeOwner"
                self.mDayRefreshes[day_refresh_key] = {}
                local t = self.mDayRefreshes[day_refresh_key]
                t.mFunction = function()
                    self:getProperty():lockWrite(
                        terrain_property_name,
                        function(value)
                            value.mFakeOwner.mDay = value.mFakeOwner.mDay - 1
                            if value.mFakeOwner.mDay <= 0 then
                                value.mFakeOwner = nil
                                self.mDayRefreshes[day_refresh_key] = nil
                            end
                            self:getProperty():write(terrain_property_name, value)
                        end
                    )
                end
            end
            if terrainProperty.mInvalidate then
                self.mDayRefreshes = self.mDayRefreshes or {}
                local day_refresh_key = "Terrain/" .. terrain_key .. "/Invalidate"
                self.mDayRefreshes[day_refresh_key] = {}
                local t = self.mDayRefreshes[day_refresh_key]
                t.mFunction = function()
                    self:getProperty():lockWrite(
                        terrain_property_name,
                        function(value)
                            value.mInvalidate.mDay = value.mInvalidate.mDay - 1
                            if value.mInvalidate.mDay <= 0 then
                                value.mInvalidate = nil
                                self.mDayRefreshes[day_refresh_key] = nil
                            end
                            self:getProperty():write(terrain_property_name, value)
                        end
                    )
                end
            end

            local billboard_infos = {}
            billboard_infos["地名:"] = terrain_config.mName
            if terrainProperty.mOwnerPlayerID and GetEntityById(terrainProperty.mOwnerPlayerID) then
                billboard_infos["拥有者:"] = GetEntityById(terrainProperty.mOwnerPlayerID).nickname
            end
            if terrainProperty.mLevel or terrain_config.mLevel then
                billboard_infos["等级:"] = tostring(terrainProperty.mLevel or terrain_config.mLevel)
            end
            if not terrainProperty.mOwnerPlayerID then
                billboard_infos["价格:"] = tostring(GameCompute.computeTerrainBuyPrice(terrain_config, terrainProperty))
            end
            billboard_infos["消费:"] = tostring(GameCompute.computeTerrainSpend(terrain_config, terrainProperty))
            local block_id, block_data, entity_data = GetBlockFull(pos[1], pos[2] + 3, pos[3])
            local new_entity_data = clone(entity_data)
            local config_text = ""
            local billboard_line_indices = {"地名:", "拥有者:", "价格:", "消费:", "等级:"}
            for _, billboard_line_index in pairs(billboard_line_indices) do
                if billboard_infos[billboard_line_index] then
                    config_text = config_text .. billboard_line_index .. billboard_infos[billboard_line_index] .. "\n"
                end
            end
            new_entity_data[1][1][1] = config_text
            SetBlock(pos[1], pos[2] + 3, pos[3], block_id, block_data, nil, new_entity_data)

            local level = terrainProperty.mLevel or terrain_config.mLevel
            if terrain_info.mTerrainEntityDown then
                terrain_info.mTerrainEntityDown:SetDead(true)
                terrain_info.mTerrainEntityDown = nil
            end
            if terrain_info.mTerrainEntityUp then
                terrain_info.mTerrainEntityUp:SetDead(true)
                terrain_info.mTerrainEntityUp = nil
            end
            SetBlock(pos[1], pos[2] + 1, pos[3], 0)
            terrain_info.mTerrainEntityDown =
                CreateNPC(
                {
                    bx = pos[1],
                    by = pos[2] + 1,
                    bz = pos[3],
                    facing = 0,
                    can_random_move = false,
                    item_id = 10062,
                    is_dummy = true
                }
            )
            if level <= 4 then
                if terrain_info.mType and terrain_info.mType == "连锁超市" then
                    terrain_info.mTerrainEntityDown:setModelFromResource(GameConfig.mTerrainSupermarketEntityResource)
                else
                    terrain_info.mTerrainEntityDown:setModelFromResource(GameConfig.mTerrainNormalEntityResource[level])
                end
            else
                terrain_info.mTerrainEntityDown:setModelFromResource(GameConfig.mTerrainNormalEntityResource[level][1])
                terrain_info.mTerrainEntityUp =
                    CreateNPC(
                    {
                        bx = pos[1],
                        by = pos[2] + 2,
                        bz = pos[3],
                        facing = 0,
                        can_random_move = false,
                        item_id = 10062,
                        is_dummy = true
                    }
                )
                terrain_info.mTerrainEntityUp:setModelFromResource(GameConfig.mTerrainNormalEntityResource[level][2])
            end
        end
    )
end

function GameHost:restoreTerrain(pos)
    local terrain_config = self.mTerrain:getTerrain(pos).mConfig
    local billboard_infos = {}
    billboard_infos["地名:"] = terrain_config.mName
    billboard_infos["等级:"] = tostring(terrain_config.mLevel)
    billboard_infos["价格:"] = tostring(terrain_config.mPrice)
    billboard_infos["消费:"] = tostring(terrain_config.mSpend)
    local block_id, block_data, entity_data = GetBlockFull(pos[1], pos[2] + 3, pos[3])
    local new_entity_data = clone(entity_data)
    local config_text = ""
    local billboard_line_indices = {"地名:", "拥有者:", "价格:", "消费:", "等级:"}
    for _, billboard_line_index in pairs(billboard_line_indices) do
        if billboard_infos[billboard_line_index] then
            config_text = config_text .. billboard_line_index .. billboard_infos[billboard_line_index] .. "\n"
        end
    end
    new_entity_data[1][1][1] = config_text
    SetBlock(pos[1], pos[2] + 3, pos[3], block_id, block_data, nil, new_entity_data)
    restoreBlock(pos[1], pos[2], pos[3])
end

function GameHost:updateRoad(pos)
    local terrain_property_name = self.mGame:getRoadInfoPropertyName(pos)
    self.mGame:read(
        terrain_property_name,
        function(terrainProperty)
            terrainProperty = terrainProperty or {}
            local terrain_key = tostring(pos[1]) .. "," .. tostring(pos[2]) .. "," .. tostring(pos[3])
            self.mRoadInfos = self.mRoadInfos or {}
            self.mRoadInfos[terrain_key] = self.mRoadInfos[terrain_key] or {mEntities = {}}
            local terrain_info = self.mRoadInfos[terrain_key]
            terrain_info.mPosition = pos
            if terrainProperty.mBlock and not terrain_info.mEntities.mBlock then
                terrain_info.mEntities.mBlock =
                    CreateNPC(
                    {
                        bx = pos[1],
                        by = pos[2] + 1,
                        bz = pos[3],
                        facing = 0,
                        can_random_move = false,
                        item_id = 10062,
                        is_dummy = true,
                        is_persistent = false
                    }
                )
                terrain_info.mEntities.mBlock:setModelFromResource(GameConfig.getCardByType("障碍卡").mModelResource)
            elseif not terrainProperty.mBlock and terrain_info.mEntities.mBlock then
                terrain_info.mEntities.mBlock:SetDead(true)
                terrain_info.mEntities.mBlock = nil
            elseif terrainProperty.mNPC and not terrain_info.mEntities.mNPC then
                terrain_info.mEntities.mNPC =
                    CreateNPC(
                    {
                        bx = pos[1],
                        by = pos[2] + 1,
                        bz = pos[3],
                        facing = 0,
                        can_random_move = false,
                        item_id = 10062,
                        is_dummy = true,
                        is_persistent = false
                    }
                )
                terrain_info.mEntities.mNPC:setModelFromResource(GameConfig.mNPCResources[terrainProperty.mNPC])
                terrain_info.mEntities.mNPC:SetScaling(GameConfig.mNPCEntityScales[terrainProperty.mNPC])
                EntitySyncerManager.singleton():get(terrain_info.mEntities.mNPC):setDisplayName(
                    GameConfig.mNPCTypes[terrainProperty.mNPC],
                    "0 0 255"
                )
            elseif not terrainProperty.mNPC and terrain_info.mEntities.mNPC then
                terrain_info.mEntities.mNPC:SetDead(true)
                terrain_info.mEntities.mNPC = nil
            elseif terrainProperty.mItem and not terrain_info.mEntities.mItem then
                terrain_info.mEntities.mItem =
                    CreateNPC(
                    {
                        bx = pos[1],
                        by = pos[2] + 1,
                        bz = pos[3],
                        facing = 0,
                        can_random_move = false,
                        item_id = 10062,
                        is_dummy = true,
                        is_persistent = false
                    }
                )
                if terrainProperty.mItem == "地雷" then
                    terrain_info.mEntities.mItem:setModelFromResource(GameConfig.getCardByType("地雷卡").mModelResource)
                elseif terrainProperty.mItem == "定时炸弹" then
                    terrain_info.mEntities.mItem:setModelFromResource(GameConfig.getCardByType("定时炸弹").mModelResource)
                end
            elseif not terrainProperty.mItem and terrain_info.mEntities.mItem then
                terrain_info.mEntities.mItem:SetDead(true)
                terrain_info.mEntities.mItem = nil
            end
        end
    )
end

function GameHost:dayRefresh()
    --self:weekRefresh()
    --self:monthRefresh()
    if self.mDayRefreshes then
        for _, day_refresh in pairs(self.mDayRefreshes) do
            day_refresh.mFunction(day_refresh.mParameter)
        end
    end
end

function GameHost:weekRefresh()
    for _, road in pairs(self.mTerrain.mRoads) do
        local road_property_name = self.mGame:getRoadInfoPropertyName(road.mPosition)
        self.mGame:read(
            road_property_name,
            function(roadProperty)
                roadProperty = roadProperty or {}
                local has_npc = nil
                -- local has_npc = math.random() < 0.1
                if has_npc then
                    roadProperty.mNPC = math.random(1, #GameConfig.mNPCTypes)
                else
                    roadProperty.mNPC = nil
                end
                self.mGame:safeWrite(road_property_name, roadProperty)
                self:updateRoad(road.mPosition)
            end
        )
    end
end

function GameHost:monthRefresh()
    self:updatePropertyCache(
        function()
            if self.mPlayers then
                local best_ticket = math.random(1, GameConfig.mTicketCount)
                local ticket_bouns = self.mGame:cache().mTicketBouns
                local ticket_players = {}
                for _, player in pairs(self.mPlayers) do
                    if player:getPropertyCache().mTickets then
                        for _, ticket in pairs(player:getPropertyCache().mTickets) do
                            if ticket == best_ticket then
                                ticket_players[#ticket_players + 1] = player
                                break
                            end
                        end
                        player:getProperty():safeWrite("mTickets")
                    end
                    player:getProperty():safeWrite(
                        "mMoneyStore",
                        math.ceil(player:getPropertyCache().mMoneyStore * 1.1)
                    )
                end
                local message = "彩票开奖，中奖号码：" .. tostring(best_ticket)
                if #ticket_players > 0 then
                    self.mGame:safeWrite("mTicketBouns", GameConfig.mTicketBouns)
                    local ticket_bouns_pre_player = math.floor(ticket_bouns / #ticket_players)
                    message = message .. "，中奖金额：" .. tostring(ticket_bouns_pre_player) .. "中奖者："
                    for k, player in pairs(ticket_players) do
                        player:getProperty():safeWrite(
                            "mMoneyStore",
                            player:getPropertyCache().mMoneyStore + ticket_bouns_pre_player
                        )
                        message = message .. GetEntityById(player:getProperty().mPlayerID).nickname
                        if k < #ticket_players then
                            message = message .. "，"
                        end
                    end
                else
                    self.mGame:safeWrite("mTicketBouns", ticket_bouns + GameConfig.mTicketBouns)
                    message = message .. "总金额：" .. tostring(ticket_bouns) .. "，无人中奖"
                end
                self:broadcast("MessageBox", message)
            end
        end
    )
end

function GameHost:playerFail(playerID)
    self.mGame:read(
        "mCurrentRunPlayer",
        function(value)
            if playerID == value then
                self:nextPlayer(value)
            end
        end
    )
end
-----------------------------------------------------------------------------------------Game Client-----------------------------------------------------------------------------------------
function GameClient:construction(parameter)
    self.mGame = new(Game)
    self.mCommandQueue = new(CommandQueue)
    self.mPlayers = {}
    self.mGame:readUntil(
        "mHomePosition",
        function(value)
            self.mHomePosition = value
            echo("devilwalk", "GameClient:construction:self.mHomePosition:")
            echo("devilwalk", self.mHomePosition)

            if parameter.mPlayers then
                for _, player_id in pairs(parameter.mPlayers) do
                    self:addPlayer(player_id)
                end
            end

            self.mTerrain = new(GameTerrain, {mHomePosition = self.mHomePosition, mProperty = self.mGame})

            self.mGame:addPropertyListener(
                "mCurrentRunPlayer",
                self,
                function(_, value)
                    echo("devilwalk", "GameClient:construction:mCurrentRunPlayer:value")
                    echo("devilwalk", value)
                    if value then
                        self:onRunningPlayerChange(value)
                    end
                end
            )

            --echo("devilwalk", "GameClient:construction:self")
            --echo("devilwalk", self)
            Client.addListener("Game", self)
            GameUI.showBasicWindow(self:getPlayer())
            GameUI.showPrepareWindow("等待其他玩家......")
        end
    )
end

function GameClient:destruction()
    --EnableAutoCamera(true)
    GameUI.closeBasicWindow(self:getPlayer())
    if self.mPlayers then
        for _, player in pairs(self.mPlayers) do
            delete(player)
        end
    end
    self.mPlayers = nil
    delete(self.mGame)
    self.mGame = nil
    delete(self.mCommandQueue)
    self.mCommandQueue = nil

    Client.removeListener("Game", self)
end

function GameClient:update()
    self.mCommandQueue:update()
    self.mGame:update()
    if self.mPlayers then
        for _, player in pairs(self.mPlayers) do
            player:update()
        end
    end
end

function GameClient:getProperty()
    return self.mGame
end

function GameClient:getTerrain()
    return self.mTerrain
end

function GameClient:addPlayer(playerID)
    echo("devilwalk", "GameClient:addPlayer:playerID:" .. tostring(playerID))
    self.mPlayers = self.mPlayers or {}
    self.mPlayers[playerID] =
        new(
        GamePlayerClient,
        {
            mPlayerID = playerID,
            mGame = self,
            mPosition = self.mHomePosition
        }
    )
end

function GameClient:getPlayer(playerID)
    playerID = playerID or GetPlayerId()
    return self.mPlayers[playerID]
end

function GameClient:updatePropertyCache(callback)
    self.mGame.mCache = {}
    local player_checks = {}
    local player_checked
    local function _check()
        if player_checked then
            self.mGame:commandRead("mDay")
            self.mGame:commandRead("mLastTickets")
            self.mGame:commandRead("mTicketBouns")
            self.mGame:commandRead("mFirstDay")
            self.mGame:commandFinish(
                function()
                    echo("devilwalk", "GameClient:updatePropertyCache:finish")
                    callback()
                end
            )
        end
    end
    local function _checkPlayer()
        if self.mPlayers then
            for key, player in pairs(self.mPlayers) do
                if not player_checks[key] then
                    return
                end
            end
        end
        echo("devilwalk", "GameClient:updatePropertyCache:player finish")
        player_checked = true
        _check()
    end
    if self.mPlayers then
        for key, player in pairs(self.mPlayers) do
            player:updatePropertyCache(
                function()
                    player_checks[key] = true
                    _checkPlayer()
                end
            )
        end
    else
        player_checked = true
    end
end

function GameClient:onRunningPlayerChange(playerID)
    if playerID == self:getPlayer():getProperty().mPlayerID then
        GameUI.showPrepareWindow()
        self.mCommandQueue:post(new(Command_UpdatePropertyCacheClient, {mGame = self}))
        self.mCommandQueue:post(
            new(
                Command_Callback,
                {
                    mDebug = "Prepare",
                    mExecuteCallback = function(command)
                        command.mState = Command.EState.Finish
                        self:getPlayer():prepare()
                    end
                }
            )
        )
        self.mCommandQueue:post(
            new(
                Command_Callback,
                {
                    mDebug = "Command_Callback/Running",
                    mExecuteCallback = function(command)
                        command.mState = Command.EState.Finish
                        if self:getPlayer():getPropertyCache().mFail then
                            return
                        end
                        if self:getPlayer():getPropertyCache().mStay or self:getPlayer():getPropertyCache().mSleepDay then
                            self.mCommandQueue:post(
                                new(
                                    Command_Callback,
                                    {
                                        mDebug = "Command_Callback/Post",
                                        mExecuteCallback = function(command)
                                            command.mState = Command.EState.Finish
                                            self:getPlayer():post()
                                        end
                                    }
                                )
                            )
                            self.mCommandQueue:post(
                                new(
                                    Command_Callback,
                                    {
                                        mExecuteCallback = function(command)
                                            self:sendToHost("NextPlayer")
                                            command.mState = Command.EState.Finish
                                        end
                                    }
                                )
                            )
                            return
                        end
                        GameUI.showOperatorWindow(
                            self:getPlayer():getPropertyCache().mMove,
                            function(move)
                                -- move = 1
                                GameUI.closeOperatorWindow()
                                if
                                    not self:getPlayer():getPropertyCache().mStay and
                                        not self:getPlayer():getPropertyCache().mSleepDay
                                 then
                                    if self:getPlayer():getPropertyCache().mStep then
                                        move = 1
                                    end
                                    if not self:getPlayer():getPropertyCache().mStop then
                                        self.mCommandQueue:post(
                                            new(
                                                Command_MoveClient,
                                                {
                                                    mPlayer = self:getPlayer(),
                                                    mStep = move
                                                }
                                            )
                                        )
                                        self.mCommandQueue:post(new(Command_UpdatePropertyCacheClient, {mGame = self}))
                                    end
                                    self.mCommandQueue:post(
                                        new(
                                            Command_CheckRoadClient,
                                            {
                                                mGame = self,
                                                mPlayer = self:getPlayer()
                                            }
                                        )
                                    )
                                    self.mCommandQueue:post(
                                        new(
                                            Command_CheckTerrainClient,
                                            {
                                                mGame = self,
                                                mPlayer = self:getPlayer()
                                            }
                                        )
                                    )
                                end
                                self.mCommandQueue:post(
                                    new(
                                        Command_Callback,
                                        {
                                            mDebug = "Command_Callback/Post",
                                            mExecuteCallback = function(command)
                                                command.mState = Command.EState.Finish
                                                self:getPlayer():post()
                                            end
                                        }
                                    )
                                )
                                self.mCommandQueue:post(
                                    new(
                                        Command_Callback,
                                        {
                                            mExecuteCallback = function(command)
                                                self:sendToHost("NextPlayer")
                                                command.mState = Command.EState.Finish
                                            end
                                        }
                                    )
                                )
                            end
                        )
                    end
                }
            )
        )
    else
        if self:getPlayer():getPropertyCache() and self:getPlayer():getPropertyCache().mFail then
            GameUI.showPrepareWindow("游戏失败，等待游戏重新开始......")
        else
            GameUI.showPrepareWindow(GetEntityById(playerID).nickname .. "正在操作,请等待......")
        end
    end
end

function GameClient:boom(boomPos, range)
    for x = -range, range do
        for z = -range, range do
            local pos = {
                boomPos[1] + x,
                boomPos[2],
                boomPos[3] + z
            }
            if self:getTerrain():getTerrain(pos) then
                local terrain_property_name = self:getProperty():getTerrainInfoPropertyName(pos)
                self:getProperty():lockWrite(
                    terrain_property_name,
                    function(terrainProperty)
                        terrainProperty = terrainProperty or {mLevel = 1}
                        terrainProperty.mLevel = 1
                        self:getProperty():write(terrain_property_name, terrainProperty)
                        self:sendToHost(
                            "UpdateTerrain",
                            {
                                mPosition = pos
                            }
                        )
                    end
                )
            end
            if self:getTerrain():getRoad(pos) then
                local road_property_name = self:getProperty():getRoadInfoPropertyName(pos)
                self:getProperty():lockWrite(
                    road_property_name,
                    function(roadProperty)
                        roadProperty = {}
                        self:getProperty():write(road_property_name, roadProperty)
                        self:sendToHost(
                            "UpdateRoad",
                            {
                                mPosition = pos
                            }
                        )
                    end
                )
                for _, player in pairs(self.mPlayers) do
                    if vec3Equal(player:getPropertyCache().mPosition, pos) then
                        if not player:getPropertyCache().mInvincible then
                            player:getProperty():safeWrite("mMove", 1)
                            player:getProperty():safeWrite("mStay", {mType = "医院", mDay = 5})
                        end
                    end
                end
            end
        end
    end
end

function GameClient:sendToHost(message, parameter)
    Client.sendToHost("Game", {mMessage = message, mParameter = parameter})
end

function GameClient:requestToHost(message, parameter, callback)
    self.mResponseCallback = self.mResponseCallback or {}
    self.mResponseCallback[message] = callback
    self:sendToHost(message, parameter)
end

function GameClient:sendToClient(playerID, message, parameter)
    Client.sendToClient(playerID, "Game", {mMessage = message, mParameter = parameter})
end

function GameClient:receive(parameter)
    --echo("devilwalk", "GameClient:receive:parameter:")
    --echo("devilwalk", parameter)
    local is_responese, _ = string.find(parameter.mMessage, "_Response")
    if is_responese then
        local message = string.sub(parameter.mMessage, 1, is_responese - 1)
        if self.mResponseCallback[message] then
            self.mResponseCallback[message](parameter.mParameter)
            self.mResponseCallback[message] = nil
        end
    elseif parameter.mMessage == "MessageBox" then
        GameUI.messageBox(parameter.mParameter)
    end
end
-----------------------------------------------------------------------------------------Game Manager Host-----------------------------------------------------------------------------------------
function GameManagerHost.singleton()
    GameManagerHost.mInstance = GameManagerHost.mInstance or new(GameManagerHost)
    return GameManagerHost.mInstance
end

function GameManagerHost:construction(parameter)
    self.mCommandQueue = new(CommandQueue)
    self.mProperty = new(Property)
    self.mProperty._getLockKey = function(inst, propertyName)
        return "GameManager/" .. propertyName
    end
    Host.addListener("GameManager", self)
end

function GameManagerHost:destruction()
    delete(self.mCommandQueue)
end

function GameManagerHost:showEnterGameWindow()
    self.mConfig = {}
    self.mCommandQueue:post(
        new(
            Command_Callback,
            {
                mDebug = "GameManagerHost:showEnterGameWindow/ConfigMoney",
                mTimeOutProcess = function()end,
                mExecuteCallback = function(command)
                    local window =
                        MiniGameUISystem.createWindow(
                        "RichMan/GameManagerHost/ConfigMoney",
                        "_ct",
                        0,
                        0,
                        600,
                        400
                    )
                    local background =
                        window:createUI(
                        "Picture",
                        "RichMan/GameManagerHost/ConfigMoney/Background",
                        "_lt",
                        0,
                        0,
                        600,
                        400
                    )
                    background:setBackgroundResource(255,0,0,0,0,"Fk2ztiR-hKdBug6TWtytWvAGu3mr")
                    local title =
                        window:createUI(
                        "Text",
                        "RichMan/GameManagerHost/ConfigMoney/Title",
                        "_lt",
                        0,
                        0,
                        600,
                        100,
                        background
                    )
                    title:setText("设置现金")
                    title:setTextFormat(5)
                    title:setFontSize(50)
                    title:setFontColour("255 255 255")
                    for y = 0, 4 do
                        for x = 0, 5 do
                            local index = y * 6 + x + 1
                            local button =
                                window:createUI(
                                "Button",
                                "RichMan/GameManagerHost/ConfigMoney/Button" .. tostring(index),
                                "_lt",
                                100 * x,
                                60 * y + 100,
                                100,
                                60,
                                background
                            )
                            button:setText(tostring(index) .. "千")
                            button:setFontSize(25)
                            button:setFontColour("255 255 255")
                            button:setBackgroundResource(5214,0,0,0,0,"FlXGYD9FxaKQC5M8W5hcFzeXMEns")
                            button:addEventFunction(
                                "onclick",
                                function()
                                    GameUI.yesOrNo(
                                        "现金设置为：" .. tostring(index) .. "千，可以吗？",
                                        function()
                                            MiniGameUISystem.destroyWindow(window)
                                            self.mConfig.mMoney = index * 1000
                                            command.mState = Command.EState.Finish
                                        end
                                    )
                                end
                            )
                        end
                    end
                end
            }
        )
    )
    self.mCommandQueue:post(
        new(
            Command_Callback,
            {
                mDebug = "GameManagerHost:start/ConfigMoneyStore",
                mTimeOutProcess = function()end,
                mExecuteCallback = function(command)
                    local window =
                        MiniGameUISystem.createWindow(
                        "RichMan/GameManagerHost/ConfigMoneyStore",
                        "_ct",
                        0,
                        0,
                        600,
                        400
                    )
                    local background =
                        window:createUI(
                        "Picture",
                        "RichMan/GameManagerHost/ConfigMoneyStore/Background",
                        "_lt",
                        0,
                        0,
                        600,
                        400
                    )
                    background:setBackgroundResource(255,0,0,0,0,"Fk2ztiR-hKdBug6TWtytWvAGu3mr")
                    local title =
                        window:createUI(
                        "Text",
                        "RichMan/GameManagerHost/ConfigMoneyStore/Title",
                        "_lt",
                        0,
                        0,
                        600,
                        100,
                        background
                    )
                    title:setText("设置存款")
                    title:setTextFormat(5)
                    title:setFontSize(50)
                    title:setFontColour("255 255 255")
                    for y = 0, 4 do
                        for x = 0, 5 do
                            local index = y * 6 + x + 1
                            local button =
                                window:createUI(
                                "Button",
                                "RichMan/GameManagerHost/ConfigMoneyStore/Button" .. tostring(index),
                                "_lt",
                                100 * x,
                                60 * y + 100,
                                100,
                                60,
                                background
                            )
                            button:setText(tostring(index) .. "千")
                            button:setFontColour("255 255 255")
                            button:setFontSize(25)
                            button:setBackgroundResource(5214,0,0,0,0,"FlXGYD9FxaKQC5M8W5hcFzeXMEns")
                            button:addEventFunction(
                                "onclick",
                                function()
                                    GameUI.yesOrNo(
                                        "存款设置为：" .. tostring(index) .. "千，可以吗？",
                                        function()
                                            MiniGameUISystem.destroyWindow(window)
                                            self.mConfig.mMoneyStore = index * 1000
                                            command.mState = Command.EState.Finish
                                        end
                                    )
                                end
                            )
                        end
                    end
                end
            }
        )
    )
    -- self.mCommandQueue:post(
    --     new(
    --         Command_Callback,
    --         {
    --             mDebug = "GameManagerHost:start/ConfigPoint",
    --             mTimeOutProcess = function()end,
    --             mExecuteCallback = function(command)
    --                 local window =
    --                     MiniGameUISystem.createWindow(
    --                     "RichMan/GameManagerHost/ConfigPoint",
    --                     "_ct",
    --                     0,
    --                     0,
    --                     600,
    --                     400
    --                 )
    --                 local background =
    --                     window:createUI(
    --                     "Picture",
    --                     "RichMan/GameManagerHost/ConfigPoint/Background",
    --                     "_lt",
    --                     0,
    --                     0,
    --                     600,
    --                     400
    --                 )
    --                 background:setBackgroundResource(255,0,0,0,0,"Fk2ztiR-hKdBug6TWtytWvAGu3mr")
    --                 local title =
    --                     window:createUI(
    --                     "Text",
    --                     "RichMan/GameManagerHost/ConfigPoint/Title",
    --                     "_lt",
    --                     0,
    --                     0,
    --                     600,
    --                     100,
    --                     background
    --                 )
    --                 title:setText("设置点券")
    --                 title:setTextFormat(5)
    --                 title:setFontSize(50)
    --                 title:setFontColour("255 255 255")
    --                 for y = 0, 4 do
    --                     for x = 0, 5 do
    --                         local index = y * 6 + x + 1
    --                         local button =
    --                             window:createUI(
    --                             "Button",
    --                             "RichMan/GameManagerHost/ConfigPoint/Button" .. tostring(index),
    --                             "_lt",
    --                             100 * x,
    --                             60 * y + 100,
    --                             100,
    --                             60,
    --                             background
    --                         )
    --                         local money = index * 10
    --                         button:setText(tostring(money))
    --                         button:setFontColour("255 255 255")
    --                         button:setFontSize(25)
    --                         button:setBackgroundResource(5214,0,0,0,0,"FlXGYD9FxaKQC5M8W5hcFzeXMEns")
    --                         button:addEventFunction(
    --                             "onclick",
    --                             function()
    --                                 GameUI.yesOrNo(
    --                                     "点券设置为：" .. tostring(money) .. "，可以吗？",
    --                                     function()
    --                                         MiniGameUISystem.destroyWindow(window)
    --                                         self.mConfig.mPoint = money
    --                                         command.mState = Command.EState.Finish
    --                                     end
    --                                 )
    --                             end
    --                         )
    --                     end
    --                 end
    --             end
    --         }
    --     )
    -- )
    self.mCommandQueue:post(
        new(
            Command_Callback,
            {
                mDebug = "GameManagerHost:start/ConfigTime",
                mTimeOutProcess = function()end,
                mExecuteCallback = function(command)
                    local window =
                        MiniGameUISystem.createWindow(
                        "RichMan/GameManagerHost/ConfigTime",
                        "_ct",
                        0,
                        0,
                        600,
                        400
                    )
                    local background =
                        window:createUI(
                        "Picture",
                        "RichMan/GameManagerHost/ConfigTime/Background",
                        "_lt",
                        0,
                        0,
                        600,
                        400
                    )
                    background:setBackgroundResource(255,0,0,0,0,"Fk2ztiR-hKdBug6TWtytWvAGu3mr")
                    local title =
                        window:createUI(
                        "Text",
                        "RichMan/GameManagerHost/ConfigTime/Title",
                        "_lt",
                        0,
                        0,
                        600,
                        100,
                        background
                    )
                    title:setText("设置游戏时长")
                    title:setTextFormat(5)
                    title:setFontSize(50)
                    title:setFontColour("255 255 255")
                    for y = 0, 4 do
                        for x = 0, 5 do
                            local index = y * 6 + x + 1
                            local button =
                                window:createUI(
                                "Button",
                                "RichMan/GameManagerHost/ConfigTime/Button" .. tostring(index),
                                "_lt",
                                100 * x,
                                60 * y + 100,
                                100,
                                60,
                                background
                            )
                            button:setText(tostring(index) .. "个月")
                            button:setFontColour("255 255 255")
                            button:setFontSize(25)
                            button:setBackgroundResource(5214,0,0,0,0,"FlXGYD9FxaKQC5M8W5hcFzeXMEns")
                            button:addEventFunction(
                                "onclick",
                                function()
                                    GameUI.yesOrNo(
                                        "游戏时长设置为：" .. tostring(index) .. "个月" .. "，可以吗？",
                                        function()
                                            MiniGameUISystem.destroyWindow(window)
                                            self.mConfig.mGameMonth = index
                                            command.mState = Command.EState.Finish
                                        end
                                    )
                                end
                            )
                        end
                    end
                end
            }
        )
    )
    self.mCommandQueue:post(
        new(
            Command_Callback,
            {
                mDebug = "GameManagerHost:start/ConfigSuccessCondition",
                mTimeOutProcess = function()end,
                mExecuteCallback = function(command)
                    local window =
                        MiniGameUISystem.createWindow(
                        "RichMan/GameManagerHost/ConfigSuccessCondition",
                        "_ct",
                        0,
                        0,
                        600,
                        400
                    )
                    local background =
                        window:createUI(
                        "Picture",
                        "RichMan/GameManagerHost/ConfigSuccessCondition/Background",
                        "_lt",
                        0,
                        0,
                        600,
                        400
                    )
                    background:setBackgroundResource(255,0,0,0,0,"Fk2ztiR-hKdBug6TWtytWvAGu3mr")
                    local title =
                        window:createUI(
                        "Text",
                        "RichMan/GameManagerHost/ConfigSuccessCondition/Title",
                        "_lt",
                        0,
                        0,
                        600,
                        100,
                        background
                    )
                    title:setText("设置胜利条件")
                    title:setTextFormat(5)
                    title:setFontSize(50)
                    title:setFontColour("255 255 255")
                    for y = 0, 1 do
                        for x = 0, 1 do
                            local index = y * 2 + x + 1
                            if GameConfig.mSuccessCondition[index] then
                                local button =
                                    window:createUI(
                                    "Button",
                                    "RichMan/GameManagerHost/ConfigSuccessCondition/Button" .. tostring(index),
                                    "_lt",
                                    300 * x,
                                    150 * y + 100,
                                    300,
                                    150,
                                    background
                                )
                                button:setText(GameConfig.mSuccessCondition[index])
                                button:setFontColour("255 255 255")
                                button:setFontSize(25)
                                button:setBackgroundResource(5214,0,0,0,0,"FlXGYD9FxaKQC5M8W5hcFzeXMEns")
                                button:addEventFunction(
                                    "onclick",
                                    function()
                                        GameUI.yesOrNo(
                                            "胜利条件设置为：" .. GameConfig.mSuccessCondition[index] .. "，可以吗？",
                                            function()
                                                MiniGameUISystem.destroyWindow(window)
                                                self.mConfig.mSuccessCondition = index
                                                command.mState = Command.EState.Finish
                                            end
                                        )
                                    end
                                )
                            end
                        end
                    end
                end
            }
        )
    )
    self.mCommandQueue:post(
        new(
            Command_Callback,
            {
                mDebug = "GameManagerHost:start/StartGame",
                mTimeOutProcess=function()end,
                mExecuteCallback = function(command)
                    PlayerManager.addEventListener(
                        "PlayerRemoved",
                        "GameManagerHost",
                        function(inst, parameter)
                            for i=1,#self.mPreparePlayers do
                                if self.mPreparePlayers[i]==parameter.mPlayerID then
                                    table.remove(self.mPreparePlayers,i)
                                end
                            end
                            for i=1,16 do
                                if self.mPreparePlayers[i] then
                                    self.mProperty:safeWrite(
                                        "mPreparedPlayer" .. tostring(i),
                                        {mPlayerID = self.mPreparePlayers[i]}
                                    )
                                else
                                    self.mProperty:safeWrite(
                                        "mPreparedPlayer" .. tostring(i)
                                    )
                                end
                            end
                        end)
                end,
                mExecutingCallback = function(command)
                        if #self.mPreparePlayers>1 then
                            if not command.mWindow then
                                local window = MiniGameUISystem.createWindow("RichMan/GameManagerHost/StartGame", "_lb", 0, 0, 400, 200)
                                window:setZOrder(100)
                                local button = window:createUI("Button", "RichMan/GameManagerHost/StartGame/Button", "_lt", 0, 0, 400, 200)
                                button:setBackgroundResource(5201,0,0,0,0,"FjaRxQKxYThEohplprIpaPym1DS-")
                                button:addEventFunction(
                                    "onclick",
                                    function()
                                        self.mGame = self.mGame or new(GameHost, {mConfig = self.mConfig})
                                        for i = 1, #self.mPreparePlayers do
                                            self.mGame:addPlayer(self.mPreparePlayers[i])
                                        end
                                        for i = 1, #self.mPreparePlayers do
                                            self:sendToClient(self.mPreparePlayers[i], "Start", {mPlayers = self.mPreparePlayers})
                                        end
                                        self.mGame:start()
                                        self.mPreparePlayers = nil
                                        MiniGameUISystem.destroyWindow(command.mWindow)
                                        command.mWindow=nil
                                        command.mState = Command.EState.Finish
                                        PlayerManager.removeEventListener("PlayerRemoved","GameManagerHost")
                                    end
                                )
                                command.mWindow=window
                            end
                        else
                            if command.mWindow then
                                MiniGameUISystem.destroyWindow(command.mWindow)
                                command.mWindow=nil
                            end
                        end
                    end
            }
        )
    )
end

function GameManagerHost:update()
    if self.mGame then
        self.mGame:update()
    end
    self.mCommandQueue:update();
end

function GameManagerHost:clear()
    delete(self.mGame)
    self.mGame = nil
end

function GameManagerHost:sendToClient(playerID, message, parameter)
    Host.sendTo(playerID, {mKey = "GameManager", mMessage = message, mParameter = parameter})
end

function GameManagerHost:broadcast(message, parameter)
    Host.broadcast({mKey = "GameManager", mMessage = message, mParameter = parameter})
end

function GameManagerHost:receive(parameter)
    -- body
    if parameter.mMessage == "Start" then
        if not self.mPreparePlayers or #self.mPreparePlayers == 0 then
            self:showEnterGameWindow()
        end
        self.mPreparePlayers = self.mPreparePlayers or {}
        self.mPreparePlayers[#self.mPreparePlayers + 1] = parameter._from
        self.mProperty:safeWrite(
            "mPreparedPlayer" .. tostring(#self.mPreparePlayers),
            {mPlayerID = parameter._from}
        )
        self:sendToClient(parameter._from, "Start_Response", {mResult = true})
    end
end
-----------------------------------------------------------------------------------------Game Manager Client-----------------------------------------------------------------------------------------
function GameManagerClient.singleton()
    GameManagerClient.mInstance = GameManagerClient.mInstance or new(GameManagerClient)
    return GameManagerClient.mInstance
end

function GameManagerClient:construction(parameter)
    self.mCommandQueue = new(CommandQueue)
    self.mProperty = new(Property)
    self.mProperty._getLockKey = function(inst, propertyName)
        return "GameManager/" .. propertyName
    end
    Client.addListener("GameManager", self)
end

function GameManagerClient:showPrepareWindow()
    local window = MiniGameUISystem.createWindow("RichMan/GameManagerClient/PreparedPlayers", "_ct", 0, 0, 600, 800)
    local background =
        window:createUI("Picture", "RichMan/GameManagerClient/PreparedPlayers/Background", "_lt", 0, 0, 600, 800)
    background:setBackgroundResource(255,0,0,0,0,"FioFJRbQmv2kI-oAMqpUKwTVe5ZG")
    local title =
        window:createUI("Text", "RichMan/GameManagerClient/PreparedPlayers/Title", "_lt", 0, 0, 600, 150, background)
    title:setText("已准备玩家")
    title:setTextFormat(5)
    title:setFontSize(50)
    title:setFontColour("255 255 255")
    for i = 0, 15 do
        local index = i + 1
        -- local picture_player =
        --     window:createUI(
        --     "Picture",
        --     "RichMan/GameManagerClient/PreparedPlayers/Picture/Player" .. tostring(index),
        --     "_lt",
        --     0,
        --     i * 39 + 180,
        --     600,
        --     35,
        --     background
        -- )
        local text_player =
            window:createUI(
            "Text",
            "RichMan/GameManagerClient/PreparedPlayers/Button/Player" .. tostring(index),
            "_lt",
            0,
            i * 39 + 180,
            600,
            35,
            background
        )
        text_player:setTextFormat(5)
        text_player:setFontSize(30)
        text_player:setFontColour("0 255 0")
        self.mProperty:addPropertyListener(
            "mPreparedPlayer" .. tostring(index),
            self,
            function(_, value)
                if value then
                    text_player:setText(
                        tostring(index) ..
                            "." ..
                                GetEntityById(value.mPlayerID).nickname
                    )
                else
                    text_player:setText("")
                end
            end
        )
    end
    self.mPrepareWindow = window
end

function GameManagerClient:closePrepareWindow()
    for i = 0, 15 do
        self.mProperty:removePropertyListener("mPreparedPlayer" .. tostring(index), self)
    end
    MiniGameUISystem.destroyWindow(self.mPrepareWindow)
    self.mPrepareWindow = nil
end

function GameManagerClient:start()
    GameUI.showPrepareWindow()
    GameUI.selectWindow({
        {mResource={hash="FkR332123X5Um-zT2B0",pid="3333",ext="png",name="5203"},mOnClick=function()
            self.mCommandQueue:post(
                new(
                    Command_Callback,
                    {
                        mExecuteCallback = function(command)
                            self:requestToHost(
                                "Start",
                                {mConfig = self.mConfig},
                                function(parameter)
                                    self.mConfig = nil
                                    if parameter.mResult then
                                        self:showPrepareWindow()
                                    else
                                        GameUI.messageBox(parameter.mDescription)
                                    end
                                    command.mState = Command.EState.Finish
                                end
                            )
                        end
                    }
                )
            )
        end},
        {mResource={hash="FvQNEDUd5Gv9fP078NZNj8TWDrA5",pid="5204",ext="png",},mOnClick=function()end},
        {mResource={hash="FktdwsegLdb7IJXR8mZj-j5_RNEQ",pid="5205",ext="png",},mOnClick=function()
            GameUI.showEditWindow(1,function()
                self:start()
            end)
        end}
    })
end

function GameManagerClient:update()
    self.mCommandQueue:update()
    if self.mGame then
        self.mGame:update()
    end
end

function GameManagerClient:clear()
    delete(self.mGame)
    self.mGame = nil
end

function GameManagerClient:sendToHost(message, parameter)
    Client.sendToHost("GameManager", {mMessage = message, mParameter = parameter})
end

function GameManagerClient:requestToHost(message, parameter, callback)
    self.mResponseCallback = self.mResponseCallback or {}
    self.mResponseCallback[message] = callback
    self:sendToHost(message, parameter)
end

function GameManagerClient:receive(parameter, host)
    local is_responese, _ = string.find(parameter.mMessage, "_Response")
    if is_responese then
        local message = string.sub(parameter.mMessage, 1, is_responese - 1)
        if self.mResponseCallback[message] then
            self.mResponseCallback[message](parameter.mParameter)
            self.mResponseCallback[message] = nil
        end
    elseif parameter.mMessage == "Start" then
        self:closePrepareWindow()
        self.mGame = self.mGame or new(GameClient, {mPlayers = parameter.mParameter.mPlayers})
    end
end
-----------------------------------------------------------------------------------------Command Callback-----------------------------------------------------------------------------------------
function Command_Callback:construction(parameter)
    -- echo(
    --     "devilwalk",
    --     "devilwalk--------------------------------------------debug:Command_Callback:construction:parameter:"
    -- )
    -- echo("devilwalk", parameter)
    self.mExecuteCallback = parameter.mExecuteCallback
    self.mExecutingCallback = parameter.mExecutingCallback
    self.mFinishCallback = parameter.mFinishCallback
end

function Command_Callback:execute()
    Command_Callback._super.execute(self)
    if self.mExecuteCallback then
        self.mExecuteCallback(self)
    end
end

function Command_Callback:executing()
    Command_Callback._super.executing(self)
    if self.mExecutingCallback then
        self.mExecutingCallback(self)
    end
end

function Command_Callback:finish()
    Command_Callback._super.finish(self)
    if self.mFinishCallback then
        self.mFinishCallback(self)
    end
end
-----------------------------------------------------------------------------------------Command UpdatePropertyCacheClient Host-----------------------------------------------------------------------------------------
function Command_UpdatePropertyCacheHost:construction(parameter)
    self.mGame = parameter.mGame
    self.mDebug = "Command_UpdatePropertyCacheHost"
end
function Command_UpdatePropertyCacheHost:execute()
    Command_UpdatePropertyCacheHost._super.execute(self)
    self.mGame:updatePropertyCache(
        function()
            echo("devilwalk", "Command_UpdatePropertyCacheHost:execute:caches:")
            for _, player in pairs(self.mGame.mPlayers) do
                echo("devilwalk", player:getPropertyCache())
            end
            echo("devilwalk", self.mGame:getProperty():cache())
            self.mState = Command.EState.Finish
        end
    )
end
-----------------------------------------------------------------------------------------Command UpdatePropertyCacheClient Client-----------------------------------------------------------------------------------------
function Command_UpdatePropertyCacheClient:construction(parameter)
    -- echo(
    --     "devilwalk",
    --     "devilwalk--------------------------------------------debug:Command_UpdatePropertyCacheClient:construction:parameter:"
    -- )
    -- echo("devilwalk", parameter)
    self.mGame = parameter.mGame
    self.mDebug = "Command_UpdatePropertyCacheClient"
end

function Command_UpdatePropertyCacheClient:execute()
    Command_UpdatePropertyCacheClient._super.execute(self)
    self.mGame:updatePropertyCache(
        function()
            self.mState = Command.EState.Finish
        end
    )
end
-----------------------------------------------------------------------------------------Command Move Client-----------------------------------------------------------------------------------------
function Command_MoveClient:construction(parameter)
    -- echo(
    --     "devilwalk",
    --     "devilwalk--------------------------------------------debug:Command_MoveClient:construction:parameter:"
    -- )
    -- echo("devilwalk", parameter)
    self.mPlayer = parameter.mPlayer
    self.mStep = parameter.mStep
    self.mDebug = "Command_MoveClient"
    self.mCommandQueue = new(CommandQueue)
end

function Command_MoveClient:execute()
    Command_MoveClient._super.execute(self)
    self.mCommandQueue:post(
        new(Command_StepClient, {mPlayer = self.mPlayer, mStep = self.mStep, mCommandQueue = self.mCommandQueue})
    )
end

function Command_MoveClient:executing()
    self.mCommandQueue:update()
    if self.mCommandQueue:empty() then
        GameUI.showMoveCountWindow()
        self.mState = Command.EState.Finish
    end
end
-----------------------------------------------------------------------------------------Command Step Client-----------------------------------------------------------------------------------------
function Command_StepClient:construction(parameter)
    self.mPlayer = parameter.mPlayer
    self.mStep = parameter.mStep
    self.mCommandQueue = parameter.mCommandQueue
    self.mDebug = "Command_StepClient/" .. tostring(self.mStep)
end

function Command_StepClient:destruction()
end

function Command_StepClient:execute()
    Command_StepClient._super.execute(self)
    GameUI.showMoveCountWindow(self.mStep)
    local pos = self.mPlayer:getPropertyCache().mPosition
    local dir = self.mPlayer:getPropertyCache().mDirection
    local next_pos = {
        pos[1] + dir[1],
        pos[2] + dir[2],
        pos[3] + dir[3]
    }
    local next_dir = GameCompute.convertDirection123(GameCompute.computePlayerDirection(next_pos, dir))
    self.mPlayer:requestToHost(
        "Move",
        {mPosition = next_pos},
        function()
            self.mPlayer:getProperty():safeWrite("mPosition", next_pos)
            self.mPlayer:getProperty():safeWrite("mDirection", next_dir)
            if self.mPlayer:getPropertyCache().mAttachItem then
                --check step
                if self.mPlayer:getPropertyCache().mAttachItem.mStep then
                    self.mPlayer:getPropertyCache().mAttachItem.mStep =
                        self.mPlayer:getPropertyCache().mAttachItem.mStep - 1
                    if self.mPlayer:getPropertyCache().mAttachItem.mStep <= 0 then
                        if self.mPlayer:getPropertyCache().mAttachItem.mType == "定时炸弹" then
                            self.mPlayer:getProperty():safeWrite("mAttachItem")
                            self.mPlayer:getGame():boom(next_pos, 1)
                            self.mState = Command.EState.Finish
                            return
                        end
                    else
                        self.mPlayer:getProperty():safeWrite("mAttachItem", self.mPlayer:getPropertyCache().mAttachItem)
                    end
                end
                --set to other player
                if self.mPlayer:getPropertyCache().mAttachItem.mType == "定时炸弹" then
                    for _, player in pairs(self.mPlayer:getGame().mPlayers) do
                        if player ~= self.mPlayer and vec3Equal(player:getPropertyCache().mPosition, next_pos) then
                            player:getProperty():safeWrite("mAttachItem", self.mPlayer:getPropertyCache().mAttachItem)
                            self.mPlayer:getProperty():safeWrite("mAttachItem")
                            break
                        end
                    end
                end
            end
            local road_property_name = self.mPlayer:getGame():getProperty():getRoadInfoPropertyName(next_pos)
            self.mPlayer:getGame():getProperty():safeRead(
                road_property_name,
                function(roadProperty)
                    if not roadProperty or not roadProperty.mBlock then
                        local next_step = self.mStep - 1
                        if next_step > 0 then
                            self.mCommandQueue:post(
                                new(
                                    Command_StepClient,
                                    {mPlayer = self.mPlayer, mStep = next_step, mCommandQueue = self.mCommandQueue}
                                )
                            )
                        end
                    end
                    self.mState = Command.EState.Finish
                end
            )
        end
    )
end
-----------------------------------------------------------------------------------------Command Check Road Client-----------------------------------------------------------------------------------------
function Command_CheckRoadClient:construction(parameter)
    self.mGame = parameter.mGame
    self.mPlayer = parameter.mPlayer
    self.mDebug = "Command_CheckRoadClient"
    self.mTimeOutProcess = function()end
end
function Command_CheckRoadClient:execute()
    Command_CheckRoadClient._super.execute(self)
    local road_property_name =
        self.mGame:getProperty():getRoadInfoPropertyName(self.mPlayer:getPropertyCache().mPosition)
    self.mGame:getProperty():lockWrite(
        road_property_name,
        function(roadProperty)
            if roadProperty then
                roadProperty.mBlock = nil
                if roadProperty.mNPC then
                    local attach_npc = roadProperty.mNPC
                    local attach_day = GameConfig.mNPCAttachDay
                    self.mPlayer:attachNPC(attach_npc, attach_day)
                    roadProperty.mNPC = nil
                end
                if roadProperty.mItem then
                    if roadProperty.mItem == "地雷" then
                        self.mPlayer:getGame():boom(self.mPlayer:getPropertyCache().mPosition, 1)
                    elseif roadProperty.mItem == "定时炸弹" then
                        self.mPlayer:getProperty():safeWrite("mAttachItem", {mType = "定时炸弹", mStep = 30})
                    end
                    roadProperty.mItem = nil
                end
            end
            if roadProperty then
                self.mGame:getProperty():write(road_property_name, roadProperty)
                self.mGame:sendToHost("UpdateRoad", {mPosition = self.mPlayer:getPropertyCache().mPosition})
            else
                self.mGame:getProperty():unlockWrite(road_property_name)
            end
        end
    )
    local block_id =
        GetBlockId(
        self.mPlayer:getPropertyCache().mPosition[1],
        self.mPlayer:getPropertyCache().mPosition[2],
        self.mPlayer:getPropertyCache().mPosition[3]
    )
    if GameConfig.getPoint(block_id) then
        self.mPlayer:getProperty():safeWrite(
            "mPoint",
            self.mPlayer:getPropertyCache().mPoint + GameConfig.getPoint(block_id)
        )
        GameUI.messageBox("获得点券：" .. tostring(GameConfig.getPoint(block_id)))
        self.mState = Command.EState.Finish
    elseif block_id == GameConfig.mWalkBlockIDs.mBankBlockID then
        if self.mPlayer:getPropertyCache().mBankStop then
            GameUI.messageBox("银行拒绝往来")
            self.mState = Command.EState.Finish
        else
            GameUI.showBankWindow(
                function(btnType, value)
                    if btnType == "ok" then
                        if GameUI.mBankInfo.mType == "存款" then
                            if self.mPlayer:getPropertyCache().mMoney >= value then
                                self.mPlayer:getProperty():safeWrite(
                                    "mMoneyStore",
                                    self.mPlayer:getPropertyCache().mMoneyStore + value
                                )
                                self.mPlayer:getProperty():safeWrite(
                                    "mMoney",
                                    self.mPlayer:getPropertyCache().mMoney - value
                                )
                            else
                                return {mResult = false, mDescription = "现金不足"}
                            end
                        elseif GameUI.mBankInfo.mType == "取款" then
                            if self.mPlayer:getPropertyCache().mMoneyStore >= value then
                                self.mPlayer:getProperty():safeWrite(
                                    "mMoneyStore",
                                    self.mPlayer:getPropertyCache().mMoneyStore - value
                                )
                                self.mPlayer:getProperty():safeWrite(
                                    "mMoney",
                                    self.mPlayer:getPropertyCache().mMoney + value
                                )
                            else
                                return {mResult = false, mDescription = "存款不足"}
                            end
                        end
                    end
                    self.mState = Command.EState.Finish
                end
            )
        end
    elseif block_id == GameConfig.mWalkBlockIDs.mShopBlockID then
        GameUI.showShopWindow(
            self.mPlayer:getPropertyCache().mCards,
            function(card)
                for k, test in pairs(self.mPlayer:getPropertyCache().mCards) do
                    if test == card then
                        table.remove(self.mPlayer:getPropertyCache().mCards, k)
                        break
                    end
                end
                self.mPlayer:getProperty():safeWrite("mCards", self.mPlayer:getPropertyCache().mCards)
                self.mPlayer:getProperty():safeWrite(
                    "mPoint",
                    self.mPlayer:getPropertyCache().mPoint + GameConfig.mCards[card].mPrice / 2
                )
            end,
            function(card)
                if self.mPlayer:getPropertyCache().mPoint < GameConfig.mCards[card].mPrice then
                    return {mResult = false, mDescription = "点券不足"}
                end
                self.mPlayer:getPropertyCache().mCards = self.mPlayer:getPropertyCache().mCards or {}
                if #self.mPlayer:getPropertyCache().mCards >= GameConfig.mMaxCard then
                    return {mResult = false, mDescription = "卡片数量超过限制"}
                end
                self.mPlayer:getPropertyCache().mCards[#self.mPlayer:getPropertyCache().mCards + 1] = card
                self.mPlayer:getProperty():safeWrite("mCards", self.mPlayer:getPropertyCache().mCards)
                self.mPlayer:getProperty():safeWrite(
                    "mPoint",
                    self.mPlayer:getPropertyCache().mPoint - GameConfig.mCards[card].mPrice
                )
                return {mResult = true}
            end,
            function()
                self.mState = Command.EState.Finish
            end
        )
    elseif block_id == GameConfig.mWalkBlockIDs.mTicketBlockID then
        GameUI.showTicketWindow(
            self.mPlayer:getGame():getProperty():cache().mLastTickets,
            self.mPlayer:getPropertyCache().mTickets,
            function(ticket)
                if ticket then
                    if self.mPlayer:getPropertyCache().mMoney >= GameConfig.mTicketPrice then
                        local tickets = self.mPlayer:getPropertyCache().mTickets or {}
                        tickets[#tickets + 1] = ticket
                        self.mPlayer:getProperty():safeWrite("mTickets", tickets)
                        self.mPlayer:getProperty():safeWrite(
                            "mMoney",
                            self.mPlayer:getPropertyCache().mMoney - GameConfig.mTicketPrice
                        )
                        for k, t in pairs(self.mPlayer:getGame():getProperty():cache().mLastTickets) do
                            if t == ticket then
                                table.remove(self.mPlayer:getGame():getProperty():cache().mLastTickets, k)
                                break
                            end
                        end
                        self.mPlayer:getGame():getProperty():safeWrite(
                            "mLastTickets",
                            self.mPlayer:getGame():getProperty():cache().mLastTickets
                        )
                    else
                        GameUI.messageBox("现金不足......")
                    end
                end
                self.mState = Command.EState.Finish
            end
        )
    -- elseif block_id == GameConfig.mWalkBlockIDs.mStation then
    --                         self.mCommandQueue:post(new(Command_UpdatePropertyCacheClient, {mGame = self.mGame}))
    --                         self.mCommandQueue:post(
    --                             new(
    --                                 Command_CheckRoadClient,
    --                                 {
    --                                     mPlayer = self,
    --                                     mGame = self.mGame
    --                                 }
    --                             )
    --                         )
    --                         self.mCommandQueue:post(
    --                             new(
    --                                 Command_CheckTerrainClient,
    --                                 {
    --                                     mPlayer = self,
    --                                     mGame = self.mGame
    --                                 }
    --                             )
    --                         )
    --                         self.mCommandQueue:post(
    --                             new(
    --                                 Command_Callback,
    --                                 {
    --                                     mExecuteCallback = function(command)
    --                                         self.mCurrentUseCard = nil
    --                                         self.mGame:sendToHost("NextPlayer")
    --                                         command.mState = Command.EState.Finish
    --                                     end
    --                                 }
    --                             )
    --                         )
    --                     end
    --                 )
    --     self.mState = Command.EState.Finish                            
    elseif block_id == GameConfig.mWalkBlockIDs.mDestiny then
        local destiny_index = math.random(1, #GameConfig.mDestinies)
        local message_text = tostring(destiny_index)
        if destiny_index == 1 then
            local lost_money = math.random(500, 1000)
            message_text = "被盗损失" .. tostring(lost_money) .. "元"
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
        elseif destiny_index == 2 then
            local lost_money = math.random(10000, 50000)
            message_text = "遭遇电信诈骗损失" .. tostring(lost_money) .. "元"
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
        elseif destiny_index == 3 then
            local day = math.random(1, 3)
            message_text = "出国旅游" .. tostring(day) .. "天"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "旅游", mDay = day})
        elseif destiny_index == 4 then
            local lost_money = math.random(100, 500)
            message_text = "闯红灯罚款" .. tostring(lost_money) .. "元"
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
        elseif destiny_index == 5 then
            local day = math.random(1, 2)
            message_text = "掉进水沟住院" .. tostring(day) .. "天"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "医院", mDay = day})
        elseif destiny_index == 6 then
            local day = math.random(3, 5)
            message_text = "贩卖大麻坐牢" .. tostring(day) .. "天"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "监狱", mDay = day})
        elseif destiny_index == 7 then
            local lost_money = math.random(5000, 20000)
            message_text = "遭遇P2P诈骗损失" .. tostring(lost_money) .. "元"
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
        elseif destiny_index == 8 then
            local money = math.random(100, 1000)
            message_text = "捡到" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif destiny_index == 9 then
            message_text = "龙卷风袭击某地区"
            local terrains = {}
            for _, terrain in pairs(self.mPlayer:getGame():getTerrain():getTerrains()) do
                terrains[#terrains + 1] = terrain
            end
            local terrain = terrains[math.random(1, #terrains)]
            local terrain_property_name =
                self.mPlayer:getGame():getProperty():getTerrainInfoPropertyName(terrain.mPosition)
            self.mPlayer:getGame():getProperty():lockWrite(
                terrain_property_name,
                function(terrainProperty)
                    terrainProperty = terrainProperty or {mLevel = 1}
                    terrainProperty.mLevel = 1
                    self.mPlayer:getGame():getProperty():write(terrain_property_name, terrainProperty)
                end
            )
        elseif destiny_index == 10 then
            local lost_money = math.random(100, 500)
            message_text = "乱倒垃圾罚款" .. tostring(lost_money) .. "元"
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
        elseif destiny_index == 11 then
            message_text = "强制拆除一栋房屋"
            local terrains = {}
            for _, terrain in pairs(self.mPlayer:getGame():getTerrain():getTerrains()) do
                terrains[#terrains + 1] = terrain
            end
            local terrain = terrains[math.random(1, #terrains)]
            local terrain_property_name =
                self.mPlayer:getGame():getProperty():getTerrainInfoPropertyName(terrain.mPosition)
            self.mPlayer:getGame():getProperty():lockWrite(
                terrain_property_name,
                function(terrainProperty)
                    terrainProperty = terrainProperty or {mLevel = 1}
                    terrainProperty.mLevel = 1
                    self.mPlayer:getGame():getProperty():write(terrain_property_name, terrainProperty)
                end
            )
        elseif destiny_index == 12 then
            local lost_money = math.random(1000, 5000)
            message_text = "强制购买保险花费" .. tostring(lost_money) .. "元"
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
        elseif destiny_index == 13 then
            local lost_money = math.random(1000, 1001)
            message_text = "请所有人吃大餐花费" .. tostring(lost_money) .. "元"
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
        elseif destiny_index == 14 then
            local lost_money = math.random(5000, 10000)
            message_text = "人头被冒贷失去" .. tostring(lost_money) .. "元"
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
        elseif destiny_index == 15 then
            message_text = "外星人攻打地球"
            local terrains = {}
            for _, terrain in pairs(self.mPlayer:getGame():getTerrain():getTerrains()) do
                terrains[#terrains + 1] = terrain
            end
            local terrain = terrains[math.random(1, #terrains)]
            local terrain_property_name =
                self.mPlayer:getGame():getProperty():getTerrainInfoPropertyName(terrain.mPosition)
            self.mPlayer:getGame():getProperty():lockWrite(
                terrain_property_name,
                function(terrainProperty)
                    terrainProperty = terrainProperty or {mLevel = 1}
                    terrainProperty.mLevel = 1
                    self.mPlayer:getGame():getProperty():write(terrain_property_name, terrainProperty)
                end
            )
        elseif destiny_index == 16 then
            -- message_text = "向所有人收取一张卡片"
            -- local cards = {}
            -- for _, player in pairs(self.mPlayer:getGame().mPlayers) do
            --     if player ~= self.mPlayer and player:getPropertyCache().mCards and #player:getPropertyCache().mCards > 0 then
            --         local index = math.random(1, #player:getPropertyCache().mCards)
            --         cards[#cards + 1] = player:getPropertyCache().mCards[index]
            --         table.remove(player:getPropertyCache().mCards, index)
            --         player:getProperty():safeWrite("mCards", player:getPropertyCache().mCards)
            --     end
            -- end
            -- self.mPlayer:getPropertyCache().mCards = self.mPlayer:getPropertyCache().mCards or {}
            -- for _, card in pairs(cards) do
            --     self.mPlayer:getPropertyCache().mCards[#self.mPlayer:getPropertyCache().mCards + 1] = card
            -- end
            -- self.mPlayer:getProperty():safeWrite("mCards", self.mPlayer:getPropertyCache().mCards)
        local lost_money = math.random(10000, 50000)
            message_text = "遭遇套路贷款损失" .. tostring(lost_money) .. "元"
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
        elseif destiny_index == 17 then
            local day = math.random(10, 30)
            if self.mPlayer:getPropertyCache().mBankStop then
                day=day+self.mPlayer:getPropertyCache().mBankStop.mDay
            end
            message_text = "银行拒绝往来" .. tostring(day) .. "天"
            self.mPlayer:getProperty():safeWrite(
                "mBankStop",
                {mDay = day}
            )
        elseif destiny_index == 18 then
            local day = math.random(1, 2)
            message_text = "有伤风化拘留" .. tostring(day) .. "天"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "监狱", mDay = day})
        elseif destiny_index == 19 then
            local day = math.random(1, 5)
            message_text = "走私坐牢" .. tostring(day) .. "天"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "监狱", mDay = day})
        elseif destiny_index == 20 then
            local day = math.random(1, 2)
            message_text = "醉酒大闹警局坐牢" .. tostring(day) .. "天"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "监狱", mDay = day})
        end
        GameUI.messageBox(message_text, GameConfig.mDestinies[destiny_index])
        self.mState = Command.EState.Finish
    elseif block_id == GameConfig.mWalkBlockIDs.mChance then
        local chance_index = math.random(1, #GameConfig.mChances)
        local message_text = tostring(chance_index)
        if chance_index == 1 then
            local money = math.random(50, 2000)
            message_text = "小树林交易获得" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif chance_index == 2 then
            local day = math.random(2, 5)
            local money = math.random(500, 1000)
            message_text = "前往越南相亲" .. tostring(day) .. "天" .. "获得" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "旅游", mDay = day})
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif chance_index == 3 then
            local money = math.random(1000, 5000)
            message_text = "倒卖房产获利" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif chance_index == 4 then
            local day = math.random(7, 10)
            local money = math.random(10000, 50000)
            message_text = "出售肾脏住院" .. tostring(day) .. "天" .. "获得" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "医院", mDay = day})
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif chance_index == 5 then
            local money = math.random(100, 2000)
            message_text = "股市暴涨获利" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif chance_index == 6 then
            local money = math.random(1, 10)
            message_text = "政府奖励垃圾分类先进分子" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif chance_index == 7 then
            local money = math.random(100, 500)
            message_text = "领取保险金" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif chance_index == 8 then
            local money = math.random(1000, 5000)
            message_text = "拯救地球获得" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif chance_index == 9 then
            local lost_money = math.random(1000, 5000)
            message_text = "结婚发红包" .. tostring(lost_money) .. "元"
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
        elseif chance_index == 10 then
            message_text = "花" .. tostring(lost_money) .. "元邀请咩霸打了一个响指"
            local lost_money = math.random(8888)
            self.mPlayer:getProperty():costMoney(lost_money)
            self.mPlayer:checkFail()
            local terrains = {}
            for _, terrain in pairs(self.mPlayer:getGame():getTerrain():getTerrains()) do
                terrains[#terrains + 1] = terrain
            end
            local terrain = terrains[math.random(1, #terrains)]
            local terrain_property_name =
                self.mPlayer:getGame():getProperty():getTerrainInfoPropertyName(terrain.mPosition)
            self.mPlayer:getGame():getProperty():lockWrite(
                terrain_property_name,
                function(terrainProperty)
                    terrainProperty = terrainProperty or {mLevel = 1}
                    terrainProperty.mLevel = 1
                    self.mPlayer:getGame():getProperty():write(terrain_property_name, terrainProperty)
                end
            )
        elseif chance_index == 11 then
            local money = math.random(100, 500)
            message_text = "集齐五福获得" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)            
        elseif chance_index == 12 then
            local money = math.random(100, 500)
            message_text = "新发明专利获得" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)   
        elseif chance_index == 13 then
            local day = math.random(5, 7)
            local money = math.random(1000, 5000)
            message_text = "推销伪劣保健品拘留" .. tostring(day) .. "天" .. "获利" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "监狱", mDay = day})
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif chance_index == 14 then
            local day = math.random(5, 7)
            local money = math.random(1000, 5000)
            message_text = "盗挖古墓拘留" .. tostring(day) .. "天" .. "获利" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "监狱", mDay = day})
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        elseif chance_index == 15 then
            local day = math.random(3, 5)
            local money = math.random(100, 500)
            message_text = "见义勇为负伤住院" .. tostring(day) .. "天" .. "获得奖金" .. tostring(money) .. "元"
            self.mPlayer:getProperty():safeWrite("mStay", {mType = "医院", mDay = day})
            self.mPlayer:getProperty():safeWrite("mMoney", self.mPlayer:getPropertyCache().mMoney + money)
        end
        GameUI.messageBox(message_text, GameConfig.mChances[chance_index])
        self.mState = Command.EState.Finish
    else
        self.mState = Command.EState.Finish
    end
end
-----------------------------------------------------------------------------------------Command Check Terrain Client-----------------------------------------------------------------------------------------
function Command_CheckTerrainClient:construction(parameter)
    -- echo(
    --     "devilwalk",
    --     "devilwalk--------------------------------------------debug:Command_CheckTerrainClient:construction:parameter:"
    -- )
    -- echo("devilwalk", parameter)
    self.mGame = parameter.mGame
    self.mPlayer = parameter.mPlayer
    self.mDebug = "Command_CheckTerrainClient"
    self.mTimeOutProcess = function()
    end
    self.mCommandQueue = new(CommandQueue)
end

function Command_CheckTerrainClient:execute()
    Command_CheckTerrainClient._super.execute(self)
    local config_poses =
        GameConfig.getConfigBlockPosition(
        self.mPlayer:getPropertyCache().mPosition[1],
        self.mPlayer:getPropertyCache().mPosition[2] + 3,
        self.mPlayer:getPropertyCache().mPosition[3]
    )
    local current_terrain =
        self.mPlayer:getGame():getTerrain():getTerrainByRoadPosition(self.mPlayer:getPropertyCache().mPosition)
    if current_terrain then
        local terrain_pos = current_terrain.mPosition
        local terrain_config = current_terrain.mConfig
        echo("devilwalk", "Command_CheckTerrainClient:execute:terrain_config:")
        echo("devilwalk", terrain_config)
        local function _finish(command)
            self.mGame:getProperty():commandFinish(
                function()
                    self.mPlayer:getProperty():commandFinish(
                        function()
                            command.mState = Command.EState.Finish
                        end
                    )
                end
            )
        end
        if terrain_config then
            self.mCommandQueue:post(
                new(
                    Command_Callback,
                    {
                        mDebug = "Command_CheckTerrainClient/Checking",
                        mTimeOutProcess = function()
                        end,
                        mExecuteCallback = function(command)
                            local terrain_property_name =
                                self.mGame:getProperty():getTerrainInfoPropertyName(terrain_pos)
                            self.mGame:getProperty():read(
                                terrain_property_name,
                                function(terrainInfo)
                                    -- body
                                    echo("devilwalk", "Command_CheckTerrainClient:execute:terrainInfo:")
                                    echo("devilwalk", terrainInfo)
                                    terrainInfo = terrainInfo or {mLevel = terrain_config.mLevel}
                                    if terrainInfo and terrainInfo.mOwnerPlayerID then --has owner
                                        if terrainInfo.mOwnerPlayerID == self.mPlayer:getProperty().mPlayerID then --level up
                                            local max_level = 2
                                            if terrainInfo.mType == "住宅" then
                                                max_level = GameConfig.mTerrainNormalMaxLevel
                                            elseif terrainInfo.mType == "连锁超市" then
                                                max_level = GameConfig.mTerrainSupermarketMaxLevel
                                            end
                                            local function _checkGoodNPC()
                                                if
                                                    max_level > terrainInfo.mLevel and
                                                        self.mPlayer:getPropertyCache().mAttachNPC and
                                                        (GameConfig.mNPCTypes[
                                                            self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                        ] == "福神" or
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "小福神")
                                                 then
                                                    terrainInfo.mLevel = terrainInfo.mLevel + 1
                                                    GameUI.messageBox(
                                                        GameConfig.mNPCTypes[
                                                            self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                        ] .. "附身，免费加盖房屋"
                                                    )
                                                    self.mGame:getProperty():commandWrite(
                                                        terrain_property_name,
                                                        terrainInfo
                                                    )
                                                    self.mGame:sendToHost(
                                                        "UpdateTerrain",
                                                        {
                                                            mPosition = {
                                                                terrain_pos[1],
                                                                terrain_pos[2],
                                                                terrain_pos[3]
                                                            }
                                                        }
                                                    )
                                                end
                                            end
                                            local price = GameCompute.computeTerrainUpPrice(terrain_config, terrainInfo)
                                            if self.mPlayer:getPropertyCache().mMoney >= price then
                                                if max_level > terrainInfo.mLevel then
                                                    GameUI.showTerrainLevelUpWindow(
                                                        terrain_config,
                                                        terrainInfo,
                                                        function(whichButton)
                                                            if whichButton == "ok" then
                                                                self.mPlayer:getPropertyCache().mMoney =
                                                                    self.mPlayer:getPropertyCache().mMoney - price
                                                                self.mPlayer:getProperty():commandWrite(
                                                                    "mMoney",
                                                                    self.mPlayer:getPropertyCache().mMoney
                                                                )
                                                                local sucessed = true
                                                                if
                                                                    self.mPlayer:getPropertyCache().mAttachNPC and
                                                                        GameConfig.mNPCTypes[
                                                                            self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                                        ] == "衰神"
                                                                 then
                                                                    sucessed = false
                                                                    GameUI.messageBox("衰神附身，投资失败......")
                                                                elseif
                                                                    self.mPlayer:getPropertyCache().mAttachNPC and
                                                                        GameConfig.mNPCTypes[
                                                                            self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                                        ] == "小衰神"
                                                                 then
                                                                    sucessed = math.random() < 0.5
                                                                    if not sucessed then
                                                                        GameUI.messageBox("小衰神附身，投资失败......")
                                                                    end
                                                                end
                                                                if sucessed then
                                                                    terrainInfo.mLevel = terrainInfo.mLevel + 1
                                                                    self.mGame:getProperty():commandWrite(
                                                                        terrain_property_name,
                                                                        terrainInfo
                                                                    )
                                                                    self.mGame:sendToHost(
                                                                        "UpdateTerrain",
                                                                        {
                                                                            mPosition = {
                                                                                terrain_pos[1],
                                                                                terrain_pos[2],
                                                                                terrain_pos[3]
                                                                            }
                                                                        }
                                                                    )
                                                                end
                                                            elseif whichButton == "cancel" then
                                                            elseif whichButton == "normal" then
                                                                terrainInfo.mLevel = terrainInfo.mLevel + 1
                                                                terrainInfo.mType = "住宅"
                                                                max_level = GameConfig.mTerrainNormalMaxLevel
                                                                self.mGame:getProperty():commandWrite(
                                                                    terrain_property_name,
                                                                    terrainInfo
                                                                )
                                                                self.mGame:sendToHost(
                                                                    "UpdateTerrain",
                                                                    {
                                                                        mPosition = {
                                                                            terrain_pos[1],
                                                                            terrain_pos[2],
                                                                            terrain_pos[3]
                                                                        }
                                                                    }
                                                                )
                                                            elseif whichButton == "supermarket" then
                                                                terrainInfo.mLevel = terrainInfo.mLevel + 1
                                                                terrainInfo.mType = "连锁超市"
                                                                max_level = GameConfig.mTerrainSupermarketMaxLevel
                                                                self.mGame:getProperty():commandWrite(
                                                                    terrain_property_name,
                                                                    terrainInfo
                                                                )
                                                                self.mGame:sendToHost(
                                                                    "UpdateTerrain",
                                                                    {
                                                                        mPosition = {
                                                                            terrain_pos[1],
                                                                            terrain_pos[2],
                                                                            terrain_pos[3]
                                                                        }
                                                                    }
                                                                )
                                                            end
                                                            _checkGoodNPC()
                                                            _finish(command)
                                                        end
                                                    )
                                                else
                                                    _finish(command)
                                                end
                                            else
                                                _checkGoodNPC()
                                                _finish(command)
                                            end
                                        elseif not terrainInfo.mInvalidate then --spend money
                                            local terrains = {self.mGame:getTerrain():getTerrain(terrain_pos)}
                                            if
                                                (not terrainInfo.mType or terrainInfo.mType == "住宅") and
                                                    terrain_config.mName
                                             then
                                                terrains =
                                                    self.mGame:getTerrain():getTerrainsByName(terrain_config.mName)
                                            elseif terrainInfo.mType == "连锁超市" then
                                                terrains = self.mGame:getTerrain():getTerrains()
                                            end
                                            for _, terrain in pairs(terrains) do
                                                local key =
                                                    self.mGame:getProperty():getTerrainInfoPropertyName(
                                                    terrain.mPosition
                                                )
                                                self.mGame:getProperty():commandRead(key)
                                            end
                                            self.mGame:getProperty():commandFinish(
                                                function()
                                                    local total_spend = 0
                                                    for _, terrain in pairs(terrains) do
                                                        local key =
                                                            self.mGame:getProperty():getTerrainInfoPropertyName(
                                                            terrain.mPosition
                                                        )
                                                        local value = self.mGame:getProperty():cache()[key]
                                                        if
                                                            value and value.mOwnerPlayerID == terrainInfo.mOwnerPlayerID and
                                                                (terrainInfo.mType == value.mType or
                                                                    (not terrainInfo.mType and value.mType == "住宅") or
                                                                    (not value.mType and terrainInfo.mType == "住宅"))
                                                         then
                                                            local spend =
                                                                GameCompute.computeTerrainSpend(terrain.mConfig, value)
                                                            total_spend = total_spend + spend
                                                        end
                                                    end
                                                    if self.mPlayer:getPropertyCache().mAttachNPC then
                                                        if
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "小穷神"
                                                         then
                                                            total_spend = math.floor(total_spend * 1.5)
                                                            GameUI.messageBox("小穷神附身，过路费提高50%......")
                                                        elseif
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "穷神"
                                                         then
                                                            total_spend = total_spend * 2
                                                            GameUI.messageBox("小穷神附身，过路费翻倍......")
                                                        elseif
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "小财神"
                                                         then
                                                            total_spend = math.floor(total_spend * 0.5)
                                                            GameUI.messageBox("小财神附身，过路费减半......")
                                                        elseif
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "财神"
                                                         then
                                                            total_spend = 0
                                                            GameUI.messageBox("财神附身，过路费全免......")
                                                        end
                                                    end
                                                    GameUI.messageBox(
                                                        "您将支付给土地拥有者：" ..
                                                            GetEntityById(terrainInfo.mOwnerPlayerID).nickname ..
                                                                "过路费：" .. tostring(total_spend)
                                                    )
                                                    total_spend = self.mPlayer:getProperty():costMoney(total_spend)
                                                    local owner_player =
                                                        self.mGame:getPlayer(terrainInfo.mOwnerPlayerID)
                                                    if terrainInfo.mFakeOwner then
                                                        owner_player =
                                                            self.mGame:getPlayer(terrainInfo.mFakeOwner.mPlayerID)
                                                    end
                                                    owner_player:getProperty():commandWrite(
                                                        "mMoneyStore",
                                                        owner_player:getPropertyCache().mMoneyStore + total_spend
                                                    )
                                                    self.mPlayer:checkFail()
                                                    if self.mPlayer:getPropertyCache().mAttachNPC then
                                                        if
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "土地神"
                                                         then
                                                            GameUI.messageBox("土地神附身，侵占土地......")
                                                            terrainInfo.mOwnerPlayerID =
                                                                self.mPlayer:getProperty().mPlayerID
                                                            self.mGame:getProperty():safeWrite(
                                                                terrain_property_name,
                                                                terrainInfo
                                                            )
                                                            self.mGame:sendToHost(
                                                                "UpdateTerrain",
                                                                {
                                                                    mPosition = {
                                                                        terrain_pos[1],
                                                                        terrain_pos[2],
                                                                        terrain_pos[3]
                                                                    }
                                                                }
                                                            )
                                                        end
                                                    end
                                                    _finish(command)
                                                end
                                            )
                                        else
                                            _finish(command)
                                        end
                                    else --no owner
                                        local price = GameCompute.computeTerrainBuyPrice(terrain_config, terrainInfo)
                                        if self.mPlayer:getPropertyCache().mMoney >= price then
                                            local spend = GameCompute.computeTerrainSpend(terrain_config, terrainInfo)
                                            GameUI.yesOrNo(
                                                "当前土地价格:" ..
                                                    tostring(
                                                        GameCompute.computeTerrainBuyPrice(terrain_config, terrainInfo)
                                                    ) ..
                                                        "\n" ..
                                                            "消费:" ..
                                                                tostring(
                                                                    GameCompute.computeTerrainSpend(
                                                                        terrain_config,
                                                                        terrainInfo
                                                                    )
                                                                ) ..
                                                                    "，是否购买？",
                                                function()
                                                    -- body
                                                    local sucessed = true
                                                    if
                                                        self.mPlayer:getPropertyCache().mAttachNPC and
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "福神"
                                                     then
                                                        GameUI.messageBox("福神附身，免费买地......")
                                                        price = 0
                                                    elseif
                                                        self.mPlayer:getPropertyCache().mAttachNPC and
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "小福神"
                                                     then
                                                        GameUI.messageBox("小福神附身，买地半价......")
                                                        price = math.floor(price * 0.5)
                                                    end
                                                    self.mPlayer:getPropertyCache().mMoney =
                                                        self.mPlayer:getPropertyCache().mMoney - price
                                                    self.mPlayer:getProperty():commandWrite(
                                                        "mMoney",
                                                        self.mPlayer:getPropertyCache().mMoney
                                                    )
                                                    if
                                                        self.mPlayer:getPropertyCache().mAttachNPC and
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "衰神"
                                                     then
                                                        sucessed = false
                                                        GameUI.messageBox("衰神附身，投资失败......")
                                                    elseif
                                                        self.mPlayer:getPropertyCache().mAttachNPC and
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "小衰神"
                                                     then
                                                        sucessed = math.random() < 0.5
                                                        if not sucessed then
                                                            GameUI.messageBox("小衰神附身，投资失败......")
                                                        end
                                                    end
                                                    if sucessed then
                                                        terrainInfo = terrainInfo or {mLevel = 1}
                                                        terrainInfo.mOwnerPlayerID =
                                                            self.mPlayer:getProperty().mPlayerID
                                                        self.mGame:getProperty():commandWrite(
                                                            terrain_property_name,
                                                            terrainInfo
                                                        )
                                                        self.mGame:sendToHost(
                                                            "UpdateTerrain",
                                                            {
                                                                mPosition = {
                                                                    terrain_pos[1],
                                                                    terrain_pos[2],
                                                                    terrain_pos[3]
                                                                }
                                                            }
                                                        )
                                                    end
                                                    _finish(command)
                                                end,
                                                function()
                                                    if self.mPlayer:getPropertyCache().mAttachNPC then
                                                        if
                                                            GameConfig.mNPCTypes[
                                                                self.mPlayer:getPropertyCache().mAttachNPC.mType
                                                            ] == "土地神"
                                                         then
                                                            GameUI.messageBox("土地神附身，侵占土地......")
                                                            terrainInfo = terrainInfo or {mLevel = 1}
                                                            terrainInfo.mOwnerPlayerID =
                                                                self.mPlayer:getProperty().mPlayerID
                                                            self.mGame:getProperty():safeWrite(
                                                                terrain_property_name,
                                                                terrainInfo
                                                            )
                                                            self.mGame:sendToHost(
                                                                "UpdateTerrain",
                                                                {
                                                                    mPosition = {
                                                                        terrain_pos[1],
                                                                        terrain_pos[2],
                                                                        terrain_pos[3]
                                                                    }
                                                                }
                                                            )
                                                        end
                                                    end
                                                    _finish(command)
                                                end
                                            )
                                        else
                                            _finish(command)
                                        end
                                    end
                                end
                            )
                        end
                    }
                )
            )
            if self.mPlayer:getPropertyCache().mAttachNPC then
                self.mCommandQueue:post(
                    new(
                        Command_Callback,
                        {
                            mDebug = "Command_CheckTerrainClient/PostCheck",
                            mExecuteCallback = function(command)
                                local terrain_property_name =
                                    self.mGame:getProperty():getTerrainInfoPropertyName(terrain_pos)
                                self.mGame:getProperty():lockWrite(
                                    terrain_property_name,
                                    function(terrainProperty)
                                        -- echo("devilwalk",terrainProperty)
                                        terrainProperty = terrainProperty or {mLevel = 1}
                                        if
                                            GameConfig.mNPCTypes[self.mPlayer:getPropertyCache().mAttachNPC.mType] ==
                                                "天使"
                                         then
                                            local max_level
                                            if terrainProperty.mType == "住宅" then
                                                max_level = GameConfig.mTerrainNormalMaxLevel
                                            elseif terrainProperty.mType == "连锁超市" then
                                                max_level = GameConfig.mTerrainSupermarketMaxLevel
                                            else
                                                max_level = GameConfig.mTerrainNormalMaxLevel
                                                terrainProperty.mType = "住宅"
                                            end
                                            if terrainProperty.mLevel < max_level then
                                                GameUI.messageBox("天使附身，加盖房屋......")
                                                terrainProperty.mLevel = terrainProperty.mLevel + 1
                                            end
                                        elseif
                                            GameConfig.mNPCTypes[self.mPlayer:getPropertyCache().mAttachNPC.mType] ==
                                                "恶魔"
                                         then
                                            terrainProperty.mLevel = math.max(1, terrainProperty.mLevel - 1)
                                            if terrainProperty.mLevel == 1 then
                                                terrainProperty.mType = nil
                                            end
                                            GameUI.messageBox("恶魔附身，破坏房屋......")
                                        end
                                        self.mGame:getProperty():write(terrain_property_name, terrainProperty)
                                        self.mGame:sendToHost(
                                            "UpdateTerrain",
                                            {
                                                mPosition = {
                                                    terrain_pos[1],
                                                    terrain_pos[2],
                                                    terrain_pos[3]
                                                }
                                            }
                                        )
                                        _finish(command)
                                    end
                                )
                            end
                        }
                    )
                )
            end
        end
    end
end

function Command_CheckTerrainClient:executing()
    self.mCommandQueue:update()
    if self.mCommandQueue:empty() then
        self.mState = Command.EState.Finish
    end
end
-----------------------------------------------------------------------------------------Host-----------------------------------------------------------------------------------------
function Host.addListener(key, listener)
    local listenerKey = tostring(listener)
    Host.mListeners = Host.mListeners or {}
    Host.mListeners[key] = Host.mListeners[key] or {}
    Host.mListeners[key][listenerKey] = listener
end

function Host.removeListener(key, listener)
    local listenerKey = tostring(listener)
    Host.mListeners[key][listenerKey] = nil
end

function Host.receive(parameter)
    if Host.mListeners then
        local listeners = Host.mListeners[parameter.mKey]
        if listeners then
            for _, listener in pairs(listeners) do
                listener:receive(parameter)
            end
        end
    end
end

function Host.sendTo(clientPlayerID, parameter)
    SendTo(clientPlayerID, parameter)
end

function Host.broadcast(parameter, exceptSelf)
    SendTo(nil, parameter)
    if not exceptSelf then
        receiveMsg(parameter)
    end
end

-----------------------------------------------------------------------------------------Client-----------------------------------------------------------------------------------------
function Client.addListener(key, listener)
    local listenerKey = tostring(listener)
    Client.mListeners = Client.mListeners or {}
    Client.mListeners[key] = Client.mListeners[key] or {}
    Client.mListeners[key][listenerKey] = listener
end

function Client.removeListener(key, listener)
    local listenerKey = tostring(listener)
    Client.mListeners[key][listenerKey] = nil
end

function Client.receive(parameter)
    if Client.mListeners then
        if parameter.mKey then
            local listeners = Client.mListeners[parameter.mKey]
            if listeners then
                for _, listener in pairs(listeners) do
                    listener:receive(parameter)
                end
            end
        elseif parameter.mMessage == "clear" then
            clear()
        end
    end
end

function Client.sendToHost(key, parameter)
    local new_parameter = clone(parameter)
    new_parameter.mKey = key
    new_parameter.mTo = "Host"
    SendTo("host", new_parameter)
end

function Client.sendToClient(playerID, key, parameter)
    local new_parameter = clone(parameter)
    new_parameter.mKey = key
    new_parameter.mTo = playerID
    if playerID == GetPlayerId() then
        Client.receive(new_parameter)
    else
        SendTo("host", new_parameter)
    end
end

function Client.broadcast(key, parameter)
    local new_parameter = clone(parameter)
    new_parameter.mKey = key
    new_parameter.mTo = "All"
    SendTo("host", new_parameter)
end
-----------------------------------------------------------------------------------------GlobalProperty-----------------------------------------------------------------------------------------
function GlobalProperty.initialize()
    GlobalProperty.mCommandList = {}
    Host.addListener("GlobalProperty", GlobalProperty)
    Client.addListener("GlobalProperty", GlobalProperty)
end

function GlobalProperty.update()
    for index, command in pairs(GlobalProperty.mCommandList) do
        local ret = command:frameMove()
        if ret then
            table.remove(GlobalProperty.mCommandList, index)
            break
        end
    end
end

function GlobalProperty.clear()
end

function GlobalProperty.lockWrite(key, callback)
    callback=callback or function()end
    GlobalProperty.mResponseCallback =
        GlobalProperty.mResponseCallback or {LockWrite = {}, LockRead = {}, Write = {}, Read = {}, LockAndWrite = {}}
    assert(GlobalProperty.mResponseCallback["LockWrite"][key] == nil, "GlobalProperty.lockWrite:key:" .. key)
    GlobalProperty.mResponseCallback["LockWrite"][key] = {callback}
    Client.sendToHost("GlobalProperty", {mMessage = "LockWrite", mParameter = {mKey = key,mDebug=getDebugStack()}})
end
--must be locked
function GlobalProperty.write(key, value, callback)
    callback=callback or function()end
    GlobalProperty.mResponseCallback =
        GlobalProperty.mResponseCallback or {LockWrite = {}, LockRead = {}, Write = {}, Read = {}, LockAndWrite = {}}
    assert(GlobalProperty.mResponseCallback["Write"][key] == nil, "GlobalProperty.Write:key:" .. key)
    GlobalProperty.mResponseCallback["Write"][key] = {callback}
    Client.sendToHost("GlobalProperty", {mMessage = "Write", mParameter = {mKey = key, mValue = value,mDebug=getDebugStack()}})
end

function GlobalProperty.unlockWrite(key)
    Client.sendToHost("GlobalProperty", {mMessage = "UnlockWrite", mParameter = {mKey = key,mDebug=getDebugStack()}})
end

function GlobalProperty.lockRead(key, callback)
    callback=callback or function()end
    GlobalProperty.mResponseCallback =
        GlobalProperty.mResponseCallback or {LockWrite = {}, LockRead = {}, Write = {}, Read = {}, LockAndWrite = {}}
    GlobalProperty.mResponseCallback["LockRead"][key] = GlobalProperty.mResponseCallback["LockRead"][key] or {}
    GlobalProperty.mResponseCallback["LockRead"][key][#GlobalProperty.mResponseCallback["LockRead"][key]+1] = callback
    Client.sendToHost("GlobalProperty", {mMessage = "LockRead", mParameter = {mKey = key,mDebug=getDebugStack()}})
end

function GlobalProperty.unlockRead(key)
    Client.sendToHost("GlobalProperty", {mMessage = "UnlockRead", mParameter = {mKey = key,mDebug=getDebugStack()}})
end

function GlobalProperty.read(key, callback)
    callback=callback or function()end
    GlobalProperty.mResponseCallback =
        GlobalProperty.mResponseCallback or {LockWrite = {}, LockRead = {}, Write = {}, Read = {}, LockAndWrite = {}}
    GlobalProperty.mResponseCallback["Read"][key] = GlobalProperty.mResponseCallback["Read"][key] or {}
    local callbacks = GlobalProperty.mResponseCallback["Read"][key]
    callbacks[#callbacks + 1] = callback
    Client.sendToHost("GlobalProperty", {mMessage = "Read", mParameter = {mKey = key,mDebug=getDebugStack()}})
end

function GlobalProperty.lockAndWrite(key, value, callback)
    callback=callback or function()end
    GlobalProperty.mResponseCallback =
        GlobalProperty.mResponseCallback or {LockWrite = {}, LockRead = {}, Write = {}, Read = {}, LockAndWrite = {}}
    assert(GlobalProperty.mResponseCallback["LockAndWrite"][key] == nil, "GlobalProperty.LockAndWrite:key:" .. key)
    GlobalProperty.mResponseCallback["LockAndWrite"][key] = {callback}
    Client.sendToHost("GlobalProperty", {mMessage = "LockAndWrite", mParameter = {mKey = key, mValue = value,mDebug=getDebugStack()}})
end

function GlobalProperty.addListener(key, listenerKey, callback, parameter)
    listenerKey = tostring(listenerKey)
    GlobalProperty.mListeners = GlobalProperty.mListeners or {}
    GlobalProperty.mListeners[key] = GlobalProperty.mListeners[key] or {}
    GlobalProperty.mListeners[key][listenerKey] = {mCallback = callback, mParameter = parameter}

    GlobalProperty.read(
        key,
        function(value)
            if value then
                callback(parameter, value, value)
            end
        end
    )
end

function GlobalProperty.removeListener(key, listenerKey)
    listenerKey = tostring(listenerKey)
    if GlobalProperty.mListeners and GlobalProperty.mListeners[key] then
        GlobalProperty.mListeners[key][listenerKey] = nil
    end
end

function GlobalProperty.notify(key, value, preValue)
    if GlobalProperty.mListeners and GlobalProperty.mListeners[key] then
        for listener_key, callback in pairs(GlobalProperty.mListeners[key]) do
            callback.mCallback(callback.mParameter, value, preValue)
        end
    end
end

function GlobalProperty:receive(parameter)
    local is_responese, _ = string.find(parameter.mMessage, "_Response")
    if is_responese then
        local message = string.sub(parameter.mMessage, 1, is_responese - 1)
        if
            GlobalProperty.mResponseCallback and GlobalProperty.mResponseCallback[message] and
                GlobalProperty.mResponseCallback[message][parameter.mParameter.mKey]
         then
            local callbacks = GlobalProperty.mResponseCallback[message][parameter.mParameter.mKey]
            local callback = callbacks[1]
            if not callback then
                echo("devilwalk","---------------------------------------------------------------------------------")
                echo("devilwalk",parameter)
            end
            table.remove(callbacks,1)
            if not next(callbacks) then
                GlobalProperty.mResponseCallback[message][parameter.mParameter.mKey] = nil
            end
            callback(parameter.mParameter.mValue)
        end
    else
        GlobalProperty.mProperties = GlobalProperty.mProperties or {}
        GlobalProperty.mProperties[parameter.mParameter.mKey] =
            GlobalProperty.mProperties[parameter.mParameter.mKey] or {}
        if parameter.mMessage == "LockWrite" then -- host
            if GlobalProperty._canWrite(parameter.mParameter.mKey) then
                GlobalProperty._lockWrite(parameter.mParameter.mKey, parameter._from,parameter.mParameter.mDebug)
                Host.sendTo(
                    parameter._from,
                    {
                        mMessage = "LockWrite_Response",
                        mKey = "GlobalProperty",
                        mParameter = {
                            mKey = parameter.mParameter.mKey,
                            mValue = GlobalProperty.mProperties[parameter.mParameter.mKey].mValue
                        }
                    }
                )
            else
                GlobalProperty.mCommandList[#GlobalProperty.mCommandList + 1] =
                    new(
                    Command_Callback,
                    {
                        mDebug = GetEntityById(parameter._from).nickname .. ":LockWrite:" .. parameter.mParameter.mKey,
                        mExecutingCallback = function(command)
                            if GlobalProperty._canWrite(parameter.mParameter.mKey) then
                                GlobalProperty._lockWrite(parameter.mParameter.mKey, parameter._from,parameter.mParameter.mDebug)
                                Host.sendTo(
                                    parameter._from,
                                    {
                                        mMessage = "LockWrite_Response",
                                        mKey = "GlobalProperty",
                                        mParameter = {
                                            mKey = parameter.mParameter.mKey,
                                            mValue = GlobalProperty.mProperties[parameter.mParameter.mKey].mValue
                                        }
                                    }
                                )
                                command.mState = Command.EState.Finish
                            end
                        end,
                        mTimeOutProcess = function(command)
                            echo("devilwalk", "GlobalProperty write lock time out:" .. command.mDebug)
                            echo("devilwalk", parameter.mParameter.mDebug)
                            if
                                GlobalProperty.mProperties[parameter.mParameter.mKey]
                             then
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked then
                                    echo(
                                        "devilwalk",
                                        GetEntityById(GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked.mPlayerID).nickname ..
                                            " write locked"
                                    )
                                end
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked then
                                    for _,info in pairs(GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked) do
                                        echo(
                                            "devilwalk",
                                            GetEntityById(info.mPlayerID).nickname ..
                                                " read locked"
                                        )
                                    end
                                end
                                echo("devilwalk",GlobalProperty.mProperties[parameter.mParameter.mKey])
                            end
                        end
                    }
                )
            end
        elseif parameter.mMessage == "UnlockWrite" then -- host
            GlobalProperty._unlockWrite(parameter.mParameter.mKey, parameter._from)
        elseif parameter.mMessage == "Write" then -- host
            GlobalProperty._write(parameter.mParameter.mKey, parameter.mParameter.mValue, parameter._from)
            Host.sendTo(
                parameter._from,
                {
                    mMessage = "Write_Response",
                    mKey = "GlobalProperty",
                    mParameter = {
                        mKey = parameter.mParameter.mKey,
                        mValue = parameter.mParameter.mValue
                    }
                }
            )
        elseif parameter.mMessage == "LockRead" then -- host
            if GlobalProperty._canRead(parameter.mParameter.mKey) then
                GlobalProperty._lockRead(parameter.mParameter.mKey, parameter._from, parameter.mParameter.mDebug)
                Host.sendTo(
                    parameter._from,
                    {
                        mMessage = "LockRead_Response",
                        mKey = "GlobalProperty",
                        mParameter = {
                            mKey = parameter.mParameter.mKey,
                            mValue = GlobalProperty.mProperties[parameter.mParameter.mKey].mValue
                        }
                    }
                )
            else
                GlobalProperty.mCommandList[#GlobalProperty.mCommandList + 1] =
                    new(
                    Command_Callback,
                    {
                        mDebug = tostring(parameter._from) .. ":LockRead:" .. parameter.mParameter.mKey,
                        mExecutingCallback = function(command)
                            if GlobalProperty._canRead(parameter.mParameter.mKey) then
                                GlobalProperty._lockRead(parameter.mParameter.mKey, parameter._from, parameter.mParameter.mDebug)
                                Host.sendTo(
                                    parameter._from,
                                    {
                                        mMessage = "LockRead_Response",
                                        mKey = "GlobalProperty",
                                        mParameter = {
                                            mKey = parameter.mParameter.mKey,
                                            mValue = GlobalProperty.mProperties[parameter.mParameter.mKey].mValue
                                        }
                                    }
                                )
                                command.mState = Command.EState.Finish
                            end
                        end,
                        mTimeOutProcess = function(command)
                            echo("devilwalk", "GlobalProperty read lock time out:" .. command.mDebug)
                            echo("devilwalk", parameter.mParameter.mDebug)
                            if
                                GlobalProperty.mProperties[parameter.mParameter.mKey]
                             then
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked then
                                    echo(
                                        "devilwalk",
                                        GetEntityById(GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked.mPlayerID).nickname ..
                                            " write locked"
                                    )
                                end
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked then
                                    for _,info in pairs(GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked) do
                                        echo(
                                            "devilwalk",
                                            GetEntityById(info.mPlayerID).nickname ..
                                                " read locked"
                                        )
                                    end
                                end
                                echo("devilwalk",GlobalProperty.mProperties[parameter.mParameter.mKey])
                            end
                        end
                    }
                )
            end
        elseif parameter.mMessage == "UnlockRead" then -- host
            GlobalProperty._unlockRead(parameter.mParameter.mKey, parameter._from)
        elseif parameter.mMessage == "Read" then -- host
            Host.sendTo(
                parameter._from,
                {
                    mMessage = "Read_Response",
                    mKey = "GlobalProperty",
                    mParameter = {
                        mKey = parameter.mParameter.mKey,
                        mValue = GlobalProperty.mProperties[parameter.mParameter.mKey].mValue
                    }
                }
            )
        elseif parameter.mMessage == "LockAndWrite" then -- host
            if GlobalProperty._canWrite(parameter.mParameter.mKey) then
                GlobalProperty._lockWrite(parameter.mParameter.mKey, parameter._from,parameter.mParameter.mDebug)
                GlobalProperty._write(parameter.mParameter.mKey, parameter.mParameter.mValue, parameter._from)
                Host.sendTo(
                    parameter._from,
                    {
                        mMessage = "LockAndWrite_Response",
                        mKey = "GlobalProperty",
                        mParameter = {
                            mKey = parameter.mParameter.mKey,
                            mValue = parameter.mParameter.mValue
                        }
                    }
                )
            else
                GlobalProperty.mCommandList[#GlobalProperty.mCommandList + 1] =
                    new(
                    Command_Callback,
                    {
                        mDebug = GetEntityById(parameter._from).nickname ..
                            ":LockAndWrite:" .. parameter.mParameter.mKey,
                        mExecutingCallback = function(command)
                            if GlobalProperty._canWrite(parameter.mParameter.mKey) then
                                GlobalProperty._lockWrite(parameter.mParameter.mKey, parameter._from,parameter.mParameter.mDebug)
                                GlobalProperty._write(
                                    parameter.mParameter.mKey,
                                    parameter.mParameter.mValue,
                                    parameter._from
                                )
                                Host.sendTo(
                                    parameter._from,
                                    {
                                        mMessage = "LockAndWrite_Response",
                                        mKey = "GlobalProperty",
                                        mParameter = {
                                            mKey = parameter.mParameter.mKey,
                                            mValue = parameter.mParameter.mValue
                                        }
                                    }
                                )
                                command.mState = Command.EState.Finish
                            end
                        end,
                        mTimeOutProcess = function(command)
                            echo("devilwalk", "GlobalProperty write lock time out:" .. command.mDebug)
                            echo("devilwalk", parameter.mParameter.mDebug)
                            if
                                GlobalProperty.mProperties[parameter.mParameter.mKey]
                             then
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked then
                                    echo(
                                        "devilwalk",
                                        GetEntityById(GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked.mPlayerID).nickname ..
                                            " write locked"
                                    )
                                end
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked then
                                    for _,info in pairs(GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked) do
                                        echo(
                                            "devilwalk",
                                            GetEntityById(info.mPlayerID).nickname ..
                                                " read locked"
                                        )
                                    end
                                end
                                echo("devilwalk",GlobalProperty.mProperties[parameter.mParameter.mKey])
                            end
                        end
                    }
                )
            end
        elseif parameter.mMessage == "PropertyChange" then -- client
            GlobalProperty.notify(
                parameter.mParameter.mKey,
                parameter.mParameter.mValue,
                parameter.mParameter.mPreValue
            )
        end
    end
end

function GlobalProperty._lockWrite(key, playerID, debugInfo)
    assert(
        GlobalProperty.mProperties[key].mWriteLocked == nil,
        "GlobalProperty._lockWrite:GlobalProperty.mProperties[key].mWriteLocked ~= nil"
    )
    assert(
        GlobalProperty.mProperties[key].mReadLocked == nil or #GlobalProperty.mProperties[key].mReadLocked == 0,
        "GlobalProperty._lockWrite:GlobalProperty.mProperties[key].mReadLocked ~= 0 and GlobalProperty.mProperties[key].mReadLocked ~= nil"
    )
    -- echo("devilwalk", "GlobalProperty._lockWrite:key,playerID:" .. tostring(key) .. "," .. tostring(playerID))
    GlobalProperty.mProperties[key].mWriteLocked = {mPlayerID = playerID,mDebug = debugInfo}
    -- GlobalProperty._lockRead(key, playerID)
end

function GlobalProperty._unlockWrite(key, playerID)
    assert(
        GlobalProperty.mProperties[key].mWriteLocked and GlobalProperty.mProperties[key].mWriteLocked.mPlayerID == playerID,
        "GlobalProperty._unlockWrite:GlobalProperty.mProperties[key].mWriteLocked ~= playerID"
    )
    -- echo("devilwalk", "GlobalProperty._unlockWrite:key,playerID:" .. tostring(key) .. "," .. tostring(playerID))
    GlobalProperty.mProperties[key].mWriteLocked = nil
    -- GlobalProperty._unlockRead(key, playerID)
end

function GlobalProperty._write(key, value, playerID)
    assert(
        GlobalProperty.mProperties[key].mWriteLocked and GlobalProperty.mProperties[key].mWriteLocked.mPlayerID == playerID,
        "GlobalProperty._write:GlobalProperty.mProperties[key].mWriteLocked ~= playerID"
    )
    -- echo("devilwalk", "GlobalProperty._write:key,playerID,value:" .. tostring(key) .. "," .. tostring(playerID))
    -- echo("devilwalk", value)
    local pre_value = GlobalProperty.mProperties[key].mValue
    GlobalProperty.mProperties[key].mValue = value
    GlobalProperty._unlockWrite(key, playerID)
    Host.broadcast(
        {
            mMessage = "PropertyChange",
            mKey = "GlobalProperty",
            mParameter = {mKey = key, mValue = value, mPreValue = pre_value, mPlayerID = playerID}
        }
    )
end

function GlobalProperty._lockRead(key, playerID, debugInfo)
    --echo("devilwalk", "GlobalProperty._lockRead:key,playerID:" .. tostring(key) .. "," .. tostring(playerID))
    GlobalProperty.mProperties[key].mReadLocked = GlobalProperty.mProperties[key].mReadLocked or {}
    GlobalProperty.mProperties[key].mReadLocked[#GlobalProperty.mProperties[key].mReadLocked+1] = {mPlayerID=playerID,mDebug=debugInfo}
end

function GlobalProperty._unlockRead(key, playerID)
    --echo("devilwalk", "GlobalProperty._unlockRead:key,playerID:" .. tostring(key) .. "," .. tostring(playerID))
    local unlocked
    for i=#GlobalProperty.mProperties[key].mReadLocked,1,-1 do
        if GlobalProperty.mProperties[key].mReadLocked[i].mPlayerID==playerID then
            table.remove(GlobalProperty.mProperties[key].mReadLocked,i)
            unlocked=true
            break
        end
    end
    assert(unlocked,"GlobalProperty._unlockRead:key:"..key..",playerID:"..tostring(playerID))
end

function GlobalProperty._canWrite(key)
    -- echo("devilwalk", "GlobalProperty._canWrite:key:" .. tostring(key))
    -- echo("devilwalk", GlobalProperty.mProperties)
    return not GlobalProperty.mProperties[key].mWriteLocked and
        (not GlobalProperty.mProperties[key].mReadLocked or #GlobalProperty.mProperties[key].mReadLocked == 0)
end

function GlobalProperty._canRead(key)
    -- return GlobalProperty._canWrite(key)
    return not GlobalProperty.mProperties[key].mWriteLocked
end
-----------------------------------------------------------------------------------------Input Manager-----------------------------------------------------------------------------------------
function InputManager.addListener(key, callback, parameter)
    InputManager.mListeners = InputManager.mListeners or {}
    InputManager.mListeners[key] = {mCallback = callback, mParameter = parameter}
end

function InputManager.removeListener(key)
    InputManager.mListeners[key] = nil
end

function InputManager.notify(event)
    if InputManager.mListeners then
        for _, listener in pairs(InputManager.mListeners) do
            listener.mCallback(listener.mParameter, event)
        end
    end
end
-----------------------------------------------------------------------------------------App-----------------------------------------------------------------------------------------
local App = {}
function App.start()
    App.mRunning = true
    GlobalProperty.initialize()
    GameManagerHost.singleton()
    GameManagerClient.singleton():start()
    EntitySyncerManager.singleton()
end

function App.update()
    GlobalProperty.update()
    GameManagerHost.singleton():update()
    GameManagerClient.singleton():update()
    EntitySyncerManager.singleton():update()
end

function App.stop()
    App.mRunning = false
    GameManagerClient.singleton():clear()
    GameManagerHost.singleton():clear()
    MiniGameUISystem.shutdown()
end

function App.receiveMsg(parameter)
    if App.mRunning then
        if parameter.mKey ~= "GlobalProperty" then
            echo("devilwalk", "App.receiveMsg:parameter:")
            echo("devilwalk", parameter)
        end
        if parameter.mTo then
            if parameter.mTo == "Host" then
                Host.receive(parameter)
            elseif parameter.mTo == "All" then
                parameter.mTo = nil
                parameter.mFrom = parameter._from
                Host.broadcast(parameter)
            else
                local to = parameter.mTo
                parameter.mTo = nil
                parameter.mFrom = parameter._from
                Host.sendTo(to, parameter)
            end
        else
            Client.receive(parameter)
        end
    end
end

function App.handleInput(event)
    InputManager.notify(event)
end
-----------------------------------------------------------------------------------------main-----------------------------------------------------------------------------------------
function main()
    PlayerManager.initialize()
    PlayerManager.hideAll()
    App.start()
    SetPermission("triggerBlock", false)
    SetPermission("editEntity", false)
end

function update()
    PlayerManager.update()
    App.update()
end

function clear()
    PlayerManager.showAll()
    PlayerManager.clear()
    App.stop()

    Host.broadcast({mMessage = "clear"}, true)
    SetPermission("triggerBlock", true)
    SetPermission("editEntity", true)
end

function handleInput(event)
    App.handleInput(event)
end

function receiveMsg(parameter)
    App.receiveMsg(parameter)
end

-- function receiveTriggerEvent(entity, x, y, z)
--     for i = -1, 1 do
--         for j = -1, 1 do
--             local test_x = Game.mHomePosition[1] + i
--             local test_z = Game.mHomePosition[3] + j
--             if test_x == x and Game.mHomePosition[2] == y and test_z == z then
--                 GameManager.start()
--                 break
--             end
--         end
--     end
-- end
