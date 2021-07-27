worldmap = gettable("game.ui.worldmap")
local wnd;

function worldmap.getLevelState( ... )
    worldmap.chapter    = worldmap.chapter or 1
    levels = game.config.getLevelsInChapter(curChapter)
    local tr    = [[
    <pe:repeat value="item in levels">
        <div style='<%=format("position:relative;margin-left:%d;margin-top:%d", item.x, item.y)%>'>
            <div style="width:70px;height:70px;"> 
                <pe:if condition='<%=item.status ==game.config.Open%>' >
                    <div style="position:relative;margin-left:-27px;margin-top:-25px;width:105px;height:100px;background:url(textures/highlight.png)"></div>
                    <div name='<%=index%>' style="position:relative;margin-top:-0px;width:55px;height:62px;background:url(textures/point_unlocked.png)" onclick="worldmap.OnClickLevel" tooltip='<%=format("《%s》 知识点:%s", item.name, item.keypoints or "")%>'></div>
                </pe:if>
                <pe:if condition='<%=item.status ==game.config.Locked%>' >
                    <div name='<%=index%>' style="position:relative;margin-top:-0px;width:55px;height:62px;background:url(textures/point_locked.png)" onclick="worldmap.OnClickLevel" tooltip='<%=format("《%s》 知识点:%s", item.name, item.keypoints or "")%>'></div>
                </pe:if>
                <pe:if condition='<%=item.status ==game.config.Passed%>' >
                    <div name='<%=index%>' style="position:relative;margin-top:-0px;width:55px;height:62px;background:url(textures/point_passed.png)" onclick="worldmap.OnClickLevel" tooltip='<%=format("《%s》 知识点:%s", item.name, item.keypoints or "")%>'></div>
                </pe:if>
                <div style="position:relative;margin-top:55px;width:100px;margin-left:-25px;">
                    <div style="font-size:18px;background-color:#00000088;text-shadow:true;color:white;align:center"><%=item.name%></div>
                </div>
            </div>
        </div>
    </pe:repeat>]]
    return tr
end


function worldmap.show(chapter)
    worldmap.close()
    worldmap.chapter    = chapter
    levels = game.config.getLevelsInChapter(chapter)
    curChapter = chapter

    wnd = window([[
<div width="100%" height="100%" style="position:relative;background-color:#00000060" onclick="worldmap.dummy"/>    
<div style='<%=format("align:center;valign:center;width:1280px;height:720px;background:url(textures/%s);padding:5px", getMap(curChapter))%>'>    
    <div style="position:relative;align:center;margin-left:170px;margin-top:10px;background:url(textures/title.png#0 0 512 158);width:408px;height:126px"></div>
    <input type="button" style="align:right;margin-top:85px;position:relative;background:url(textures/close1.png);width:65px;height:71px" name="exit" tooltip="关闭" onclick="worldmap.exit" />
    <%=worldmap.getLevelState()%>


</div>
]],"_fi", 0,0,0,0)    
wnd:SetMinimumScreenSize(1280,720)
    cmd("/time 0")
    cmd("/rain 0")
    cmd("/snow 0")
    cmd("/light 1.5 1.4 1.5")
    game.levelhelper.goHome()
    cmd("/music -channel2")
    cmd("/music -channel1 music/select_map.mp3")
end

function worldmap.dummy()
end

function worldmap.OnClickLevel(index)
    local level = levels[index]
    if not level then return end
    --print("OnClickLevel" , index)
    
    game.config.isVipOrHasPermission(function (permit)
        local isShowBuyVip  = false

        if not permit then    
            if worldmap.chapter > 1 then
                isShowBuyVip    = true
            elseif worldmap.chapter == 1 and level.index > 8 then
                isShowBuyVip    = true
            end
        end
    
        if isShowBuyVip then
            GameLogic.GetFilters():apply_filters("VipNotice", true,  "vip_code_game_art_of_war", function()
                game.config.load();
                game.ui.worldmap.refresh();
                game.ui.goals.refresh();
            end);        
        else
            game.ui.instruction.show(level)
        end
    end)
end


function getMap(chapter)
    return "ch" .. tostring(chapter) .. "Map.png"
end

function worldmap.close()
    if(wnd) then
        wnd:CloseWindow();
        wnd = nil;
        game.levelhelper.goHome()
    end
end

function worldmap.exit()
    worldmap.close()
    game.ui.chapter.show()
end

function worldmap.refresh()
    --print("worldmap.refresh")
    if (wnd) then
        wnd:Refresh(0);
    end
end
    -- <pe:if condition='<%=not game.config.isVip()%>' >
    --     <div tooltip='<%=format("剩余兵法锦囊 %d/%d", game.config.getTicketCount(), game.config.getTicketMax())%>' style="position:relative;align:right;margin-right:100px;margin-top:30px;background:url(textures/ticket.png);width:80px;height:101px"></div>
    -- </pe:if>