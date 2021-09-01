--[[
Title: BlockFBX
Author(s):  wxa
Date: 2021-06-01
Desc: FBX 方块
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/GI/Game/Blocks/BlockFBX.lua");
local BlockFBX = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockFBX");
------------------------------------------------------------
]]

local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");

local block = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.block"), commonlib.gettable("MyCompany.Aries.Game.blocks.BlockFBX"));

block_types.RegisterBlockClass("BlockFBX", block);

-- update a block's custom model according to user data. this function is called whenever the block data changes or on load. 
function block:UpdateModel(blockX, blockY, blockZ, blockData)
	if(self.customModel and self.models) then
		-- create a model at block center with custom direction and model type according to nearby models. 
		local best_model = self:GetBestModel(blockX, blockY, blockZ, blockData);
		if(best_model) then
			if(best_model.assetfile) then
				self:PreloadAsset();

				local asset_obj = best_model:GetAssetObject();
				local hasPhysics = not self.obstruction;

				local x, y, z = BlockEngine:real(blockX, blockY, blockZ);
				local obj = ParaScene.GetObject(x, y, z, 0.01);
				if(obj:IsValid()) then
					ParaScene.Delete(obj);
				end

				local obj;
				local file_name=string.sub(best_model.assetfile,1,string.find(best_model.assetfile,".x")).."fbx";
				asset_obj = ParaAsset.LoadParaX("", file_name);
				obj = ParaScene.CreateCharacter("", asset_obj, "", true , 1 , 0 , 1);
				self.mAttachObject=obj;
			
				obj:SetPosition(x,y,z);
				obj:SetField("progress", 1);
				-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
				obj:SetAttribute(128, true);
				-- OBJ_SKIP_PICKING = 0x1<<15:
				obj:SetAttribute(0x8000, true);
				-- making it non-persistent, since we will use the block onload callback to load any custom model. 
				obj:SetField("persistent", false); 
				obj:SetFacing(best_model.facing or 0);
				obj:SetScale(BlockEngine.blocksize);
				obj:SetField("RenderDistance", 160);
				local tex = self:GetTextureObj(best_model.texture_index);
				if(tex) then
					obj:SetReplaceableTexture(2, tex);
				end
				ParaScene.Attach(obj);
				if(best_model.id_data and blockData~=best_model.id_data) then
					ParaTerrain.SetBlockUserDataByIdx(blockX, blockY, blockZ, best_model.id_data);
				end
			end
		end
	end
end

function block:OnBlockRemoved(blockX, blockY, blockZ, last_id, last_data)
  if self.mAttachObject then
		ParaScene.Delete(self.mAttachObject);
  end
end

