
local entities = GameLogic.EntityManager.FindEntities({category = "all", type = "LiveModel"});

for _, entity in pairs(entities) do
    local filename = entity:GetModelFile();

    if (filename == "blocktemplates/shuakaji1.bmax" or filename == "blocktemplates/shuakaji2.bmax") then
        entity:SetOnHoverEvent("onhoverPOS");
    elseif (filename == "blocktemplates/yhk.bmax") then
        entity:SetOnEndDragEvent("ondragendPosCard");
    elseif (filename == "blocktemplates/cd.bmax") then 
        entity:SetOnClickEvent("clicked_music");
    elseif (filename == "blocktemplates/lajitong.bmax") then
        entity:SetOnMountEvent("mounted_trashcan");
    elseif (filename == "blocktemplates/dianqimen.bmax") then 
        entity:SetOnClickEvent("click_rotate");
        entity:SetStaticTag("ry_90");
    elseif (filename == "blocktemplates/pingbang_off.bmax" or 
        filename == "blocktemplates/pingbang_on.bmax" or 
        filename == "blocktemplates/tv_off.bmax" or 
        filename == "blocktemplates/tv_on.bmax") then 
        entity:SetOnClickEvent("click_switch_model");
    end
end

-- 挂载删除
-- 配置挂载点事件名: mounted_trashcan
registerBroadcastEvent("mounted_trashcan", function(msg)
    msg = commonlib.LoadTableFromString(msg)
    local mountedEntity = GameLogic.EntityManager.GetEntity(msg.mountedEntityName)
    if(mountedEntity) then
        mountedEntity:Destroy()
    end
end);


-- 点击播放音乐
-- 配置点击事件名: clicked_music
local filenames = {
    "Audio/Haqi/AriesRegionBGMusics/Area_NewYear.ogg",
    "Audio/Haqi/AriesRegionBGMusics/Area_Christmas.ogg",
    "1",
}
registerBroadcastEvent("clicked_music", function(msg)
    msg = commonlib.LoadTableFromString(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local bx, by, bz = entity:GetBlockPos()
        local lightblockId = 270 -- invisible light block 
        local filename;
        if(entity.tag == "" or not entity.tag) then
            filename = filenames[1]
        else
            for i, file in ipairs(filenames) do
                if(file == entity.tag) then
                    filename = filenames[i+1]
                    break
                end
            end
        end
        entity.tag = filename
        if (filename == filenames[#filenames]) then
            -- off
            setBlock(bx, by, bz, 0)
        else
            -- on
            setBlock(bx, by, bz, lightblockId)
        end
        playMusic(filename);
    end
end)

-- 点击点亮
registerBroadcastEvent("clicked_light", function(msg)
    msg = commonlib.LoadTableFromString(msg)
    local entity = GameLogic.EntityManager.GetEntity(msg.name)
    if(entity) then
        local bx, by, bz = entity:GetBlockPos()
        local id = getBlock(bx, by, bz)
        local lightblockId = 270 -- invisible light block 
        if(entity.tag == "on") then
            entity.tag = nil
            if(id == lightblockId) then
                setBlock(bx, by, bz, 0)
            end
        else
            if(not id or id == 0 or id == lightblockId) then
                entity.tag = "on"
                setBlock(bx, by, bz, lightblockId)
            end
        end
    end
end)

-- 刷卡机(shuakaji)配置悬浮事件名:  ondragendPosCard
registerBroadcastEvent("onhoverPOS", function(msg)
    msg = commonlib.LoadTableFromString(msg);
    local entity = GameLogic.EntityManager.GetEntity(msg.name);
    local hoverEntity = GameLogic.EntityManager.GetEntity(msg.hoverEntityName);
    if (not entity or not hoverEntity) then return end 
    local filename = hoverEntity:GetModelFile();
    if (filename ~= "blocktemplates/yhk.bmax") then return end 
    entity:SetModelFile("blocktemplates/shuakaji2.bmax");
    hoverEntity:SetTag(msg.name);
end)

--  银行卡(yhk)配置拖拽结束事件名:  ondragendPosCard
registerBroadcastEvent("ondragendPosCard", function(msg)
    msg = commonlib.LoadTableFromString(msg);
    local entity = GameLogic.EntityManager.GetEntity(msg.name);
    if (not entity) then return end 
    local tag = entity:GetTag();
    local hoverentity = GameLogic.EntityManager.GetEntity(tag or "");
    if (not hoverentity) then return end 
    local filename = hoverentity:GetModelFile();
    if (filename == "blocktemplates/shuakaji2.bmax") then
        hoverentity:SetModelFile("blocktemplates/shuakaji1.bmax");
        entity:SetTag(nil);
    end
end)