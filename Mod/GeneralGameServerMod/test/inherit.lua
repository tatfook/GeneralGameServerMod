
local Base = commonlib.inherit(nil, commonlib.gettable("Test.Base"));
function Base:ctor()
    LOG.debug("----------base ctor-----------");
    self.name = "Base";
end

function Base:Init()
    LOG.debug(self.name);
end

local Test = commonlib.inherit(Base, commonlib.gettable("Test.Test"));
function Test:ctor()
    LOG.debug("----------test ctor-----------");
    self.name = "Test";
end

function Test:Init()
    LOG.debug(Test._super);
    LOG.debug(self._super);
    LOG.debug(Test._super == self._super);
    Test._super:Init();
    self._super:Init();
    LOG.debug(self.name);
end   

Test:new();
-- local Test2 = commonlib.inherit(Test, commonlib.gettable("Test.Test2"))

-- function Test2:Init()
--     LOG.debug(self._super == Base);
-- end

-- Test2:new():Init();