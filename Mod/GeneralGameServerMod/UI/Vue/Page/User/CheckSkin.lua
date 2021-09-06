--[[
	Title: CheckSkin
	Author(s): cf
	Date: 2021/7/19
	Desc: 玩学课堂选择页
	Use Lib:
        local CheckSkin = NPL.load("(gl)Mod/GeneralGameServerMod/UI/Vue/Page/User/CheckSkin.lua");
        CheckSkin.Show();
        CheckSkin.Hide();
--]]

local CheckSkin = NPL.export();
local page;
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
CustomCharItems:Init()

CheckSkin.SKIN_ITEM_TYPE = {
	FREE = "0",
	VIP = "1",
	ONLY_BEANS_CAN_PURCHASE = "2",
	ACTIVITY_GOOD = "3",
	-- 套装部件
	SUIT_PART = "5"
}

-- 知识豆购买的皮肤数据在serverData字段
CheckSkin.ONLY_BEANS_CAN_PURCHASE_GSID = 17;
CheckSkin.BEAN_GSID = 998;

CheckSkin.DS = {
	-- percent; remainingdays; price; processBarVal; itemType; icon
	items = {},
	totalPrice = 0,
}

-- { itemId:int, category:string, price:int, startAt:DateString }
CheckSkin.ServerDataClother = nil;
CheckSkin.closeFunc = nil;
CheckSkin.CloseWithoutChange = nil;
-- default skin, head;eye;month;
CheckSkin.DEFAULT_SKIN = "80001;81018;88014;";

function CheckSkin.OnInit()
	commonlib.echo("OnInit");
	page = document:GetPageCtrl();
end

function CheckSkin.Show(closeFunc, skin, CloseWithoutChange) 
	CheckSkin.closeFunc = closeFunc;
	CheckSkin.CloseWithoutChange = CloseWithoutChange;
	CheckSkin.InitData(skin);
end;

function CheckSkin.ShowPage()
	local params = {
		url = "Mod/GeneralGameServerMod/UI/Vue/Page/User/CheckSkin.html",
		name = "CheckSkin.Show", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		zorder = 0,
		-- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -956/2,
		y = -675/2,
		width = 956,
		height = 675,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CheckSkin.GetCheckInfoFromSkin(items, callback)
	keepwork.user.getCheckInfoFromSkin({
		clothes = items,
		totalPrice = totalPrice
	}, callback)
end

--- @param skin string: curSkin 试穿skin
function CheckSkin.InitData(skin)

	if (skin:match("^%d+#")) then
		skin = CustomCharItems:SkinStringToItemIds(skin);
	end
	LOG.std(nil, 'info', 'curSkin', skin);
	LOG.std(nil, 'info', 'CheckSkin.GetClothesOfServerData()', CheckSkin.GetClothesOfServerData());
	
	KeepWorkItemManager.GetUserInfoExtraSkinFromDataBase(function (skin)
		LOG.std(nil, 'info', 'GetUserInfoExtraSkinFromDataBase', skin);
	end)
	
	-- init data
	CheckSkin.DS.items = {};
	CheckSkin.DS.totalPrice = 0;
	local itemIds = commonlib.split(skin, ";");
	local DEFAULT_HEAD_SKIN = "80001";

	if (itemIds and #itemIds > 0) then
		local items = {};
		for _, id in ipairs(itemIds) do
			local data = CustomCharItems:GetItemById(id);
			local val = {
				id = id,
				icon = data.icon,
				type = data.type,
				price = data.price or "0",
				name = data.name,
				category = data.category,
			}

			if(id ~= DEFAULT_HEAD_SKIN) then
				table.insert( items, val )
			end
		end

		LOG.std(nil, 'info', 'items', items);
		local req = commonlib.map(items, function (item)
			return {
				category = item.category,
				itemId = item.id,
				price = item.price,
			}
		end)
		LOG.std(nil, 'info', 'req', req);

		-- 获取结算清单明细
		CheckSkin.GetCheckInfoFromSkin(req, function (code, msg, data)
			LOG.std(nil, 'info', 'code', code);
			LOG.std(nil, 'info', 'msg', msg);
			LOG.std(nil, 'info', 'data', data);

			if code == 200 then
				local clothes = data.clothes;
				local isVip = KeepWorkItemManager.IsVip()
				local isDefaultSkin = skin == CheckSkin.DEFAULT_SKIN
				local diffSkins = CheckSkin.DiffFromSkin(skin, originSkin)

				CheckSkin.DS.items = commonlib.map(clothes, function (item)
					local data = CustomCharItems:GetItemById(tostring(item.itemId));
					local val = {
						-- 需要支付的价格
						price = item.payPrice,
						remainingdays = item.durability,
						itemId = item.itemId,
						category = data.category,
						icon = data.icon,
						type = data.type,
						name = data.name,
					}
					-- 设置文案
					if(data.type == CheckSkin.SKIN_ITEM_TYPE.FREE) then
						val.price = "免费使用"
					end
					if(data.type == CheckSkin.SKIN_ITEM_TYPE.SUIT_PART) then
						if(CheckSkin.IsUserOwnedThisSuitPartTypeSkin(item.itemId)) then
							val.price = "免费使用"
						else
							val.price = "仅VIP可用"
						end
					end
					if(data.type == CheckSkin.SKIN_ITEM_TYPE.VIP) then
						val.price = "仅VIP可用"
					end
					if(data.type == CheckSkin.SKIN_ITEM_TYPE.ACTIVITY_GOOD) then
						if (data.gsid and not KeepWorkItemManager.HasGSItem(data.gsid)) then
							val.price = "需活动获得"
						else
							val.price = "免费使用"
						end;
					end

					if(data.type == CheckSkin.SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE) then
						-- 总金额
						CheckSkin.DS.totalPrice = CheckSkin.DS.totalPrice+item.payPrice
					end

					return val;
				end);
		
				-- 没有替换 & VIP 则直接关闭
				if(diffSkins == "" or isVip or isDefaultSkin or (CheckSkin.DS.totalPrice == 0)) then
					CheckSkin.closeFunc()
				else
					CheckSkin.ShowPage()
					CheckSkin.Update()
				end;
			else
				GameLogic.AddBBS('channel', '系统异常', 2000)
			end
		end)
	else
		-- 切换套装时
		CheckSkin.closeFunc()
	end
end

function CheckSkin.DiffFromSkin(curSkin, oriSkin)
	local curItemIds = commonlib.split(curSkin, ";");
	local oriItemIds = commonlib.split(oriSkin, ";");
	local skin = "";
	local map = {};
	LOG.std(nil, 'info', 'curItemIds', curItemIds);
	LOG.std(nil, 'info', 'oriItemIds', oriItemIds);

	for _, oriId in ipairs(oriItemIds) do
		map[oriId] = 1;
	end

	for _, curId in ipairs(curItemIds) do
		if(not map[curId]) then
			skin = skin..curId..";"
		end
	end

	return skin;
end

--- @return table: 获取需要知识豆购买类型的skin
function CheckSkin.GetClothesOfServerData()
	local bOwn, id, bagId, copies, item = KeepWorkItemManager.HasGSItem(CheckSkin.ONLY_BEANS_CAN_PURCHASE_GSID);

	LOG.std(nil, 'info', 'GetClothesOfServerData', item);
	if(item and item.serverData) then
		return item.serverData.clothes
	end

	return nil;
end

function CheckSkin.Purchase()
	local items = {};
	for _, v in ipairs(CheckSkin.DS.items) do
		if(v.type == CheckSkin.SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE) then
			table.insert(items, {
				category = v.category,
				itemId = v.itemId,
				price = v.price
			});
		end
	end;

	LOG.std(nil, 'info', 'CheckSkin.Purchase_items', items);
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(CheckSkin.BEAN_GSID)
	local myBean = copies or 0;
	local totalPrice = CheckSkin.DS.totalPrice;

	if(myBean < totalPrice) then
		_guihelper.MessageBox("知识豆不足, 无法购买~", function ()
			CheckSkin.Close()
			CheckSkin.closeFunc();
		end);
		return;
	end

	if(#items > 0) then
		keepwork.user.buySkinUsingBean({
			clothes = items,
			totalPrice = totalPrice
		},	function(code, msg, data)
			LOG.std(nil, 'info', 'code', code);
			LOG.std(nil, 'info', 'msg', msg);
			LOG.std(nil, 'info', 'data', data);
	
			-- 购买成功 更新皮肤
			if code == 200 then
				-- refresh user goods
				KeepWorkItemManager.LoadItems(nil, CheckSkin.closeFunc)
				CheckSkin.Close()
			else
				_guihelper.MessageBox("系统异常", CheckSkin.Close);
				CheckSkin.closeFunc();
			end
		end)
	else
		CheckSkin.closeFunc()
		CheckSkin.Close()
	end
end

function CheckSkin.Update()
	if(page) then
		page:Refresh(0)
	end

	local rightContainer = page:GetNode("item_gridview");
	pe_gridview.SetDataSource(
		rightContainer, 
		page.name, 
		CheckSkin.DS.items);
	pe_gridview.DataBind(rightContainer, page.name, false);
end

-- 非VIP的情况，删除未拥有的skin
function CheckSkin.RemoveAllUnvalidItems(skin)
	LOG.std(nil, 'info', 'removeAllUnvalidItems');
	LOG.std(nil, 'info', 'before skin', skin);
	local currentSkin = skin;
	local itemIds = commonlib.split(skin, ";");
	-- get user goods
	local clothes = CheckSkin.GetClothesOfServerData() or {};
	LOG.std(nil, 'info', 'user clothes', clothes);

	if (itemIds and #itemIds > 0) then
		for _, id in ipairs(itemIds) do
			local data = CustomCharItems:GetItemById(id);
			if (data) then
				-- 活动商品
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.ACTIVITY_GOOD) then
					if(not KeepWorkItemManager.HasGSItem(data.gsid)) then
						currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
					end;
				end;

				-- 免费
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.FREE) then
					--
				end;

				-- 套装部件
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.SUIT_PART) then
					-- 先查询拥有套装，再查询拥有套装下的皮肤，--
					if(not CheckSkin.IsUserOwnedThisSuitPartTypeSkin(id)) then
						currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
					end
				end;

				-- VIP可用
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.VIP) then
					currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
				end;

				-- 知识豆可购买类型
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE) then
					-- 用户是否拥有该皮肤
					local serverDataSkin = commonlib.find(clothes, function (item)
						return item.itemId == tonumber(id)
					end);
					LOG.std(nil, 'info', 'serverDataSkin', serverDataSkin);
					LOG.std(nil, 'info', 'data id', id);

					if(not serverDataSkin) then
						currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
					end;
				end;
			end
		end
	end

	LOG.std(nil, 'info', 'after skin', currentSkin);
	return currentSkin;
end

-- 套装部件的特殊处理
function CheckSkin.IsUserOwnedThisSuitPartTypeSkin(id)
	local AllAssets = CheckSkin.GetAllAssets()
	local ownedAsset = commonlib.filter(AllAssets, function (item)
		return item.owned
	end);

	for index, value in ipairs(ownedAsset) do
		-- 判断是否套装部件
		local skinStringIds = CustomCharItems.ReplaceableAvatars[value.modelUrl]
		if(skinStringIds) then
			local itemIds = commonlib.split(skinStringIds, ";");
			LOG.std(nil, 'info', 'itemIds', itemIds);
			for index, skinId in ipairs(itemIds) do
				if(skinId == tostring(id)) then
					return true;
				end
			end
		end
	end
	
	return false;
end

--- 清除未拥有的活动商品
function CheckSkin.RemoveActivityItems(skin)
	LOG.std(nil, 'info', 'removeActivityItems');
	LOG.std(nil, 'info', 'before skin', skin);
	local currentSkin = skin;
	local itemIds = commonlib.split(skin, ";");
	
	if (itemIds and #itemIds > 0) then
		for _, id in ipairs(itemIds) do
			local data = CustomCharItems:GetItemById(id);
			if (data 
				and (data.type == CheckSkin.SKIN_ITEM_TYPE.ACTIVITY_GOOD)
				and data.gsid
				-- 未拥有
				and (not KeepWorkItemManager.HasGSItem(data.gsid))
			) then
				currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
			end
		end
	end

	LOG.std(nil, 'info', 'after skin', currentSkin);
	return currentSkin;
end

function CheckSkin.Close()
	if(page) then
		page:CloseWindow(0);
	end
end

function CheckSkin.ShowVip()
    local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
    VipPage.ShowPage("ChangeAvatarSkin", "尽享精彩形象");
end 

function CheckSkin.ClosePage()
	CheckSkin.Close();
	CheckSkin.CloseWithoutChange()
end