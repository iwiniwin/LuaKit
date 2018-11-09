require("_load")


-- dump("zzzzzzzzzzz")

-- require("pattern.TemplatePattern")

-- https://blog.csdn.net/u012723995/article/details/40455357
-- 模块加载 性能分析 面向对象 组件 事件系统 数据观察追踪 回退系统 MVC

function class(super, autoConstructSuper)
  local classType = {};
  classType.autoConstructSuper = autoConstructSuper or (autoConstructSuper == nil);

  if super then
    classType.super = super;
    local mt = getmetatable(super);
    setmetatable(classType, { __index = super; __newindex = mt and mt.__newindex;});
  else
    classType.setDelegate = function(self,delegate)
      self.m_delegate = delegate;
    end
  end

  return classType;
end


local A = class()

local X = {}
-- setmetatable(A, {__newindex = X})

local B = class(A)

-- local C = class(A)
A.test = "5555"

B.test = "lll"

-- dump(X)


-- B.class_name = "sss"

print(B.test)

