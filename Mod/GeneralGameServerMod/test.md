

diff tool

1. 遍历raw文件和entity文件  
2. 如果raw相同 entity不同, 加载raw(loadregion 512*x + 256 0 512 * z + 256) 只比较entity 
3. 如果raw不同 先比较chunk (return ParaTerrain.GetMapChunkData(self.Coords:GetChunkX(), self.Coords:GetChunkZ(), bIncludeInit, verticalSectionFilter (0xff 返回整高度256));) 