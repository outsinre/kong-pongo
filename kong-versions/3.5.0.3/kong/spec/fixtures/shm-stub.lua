-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]


-- DICT Proxy
-- https://github.com/bsm/fakengx/blob/master/fakengx.lua

local SharedDict = {}

local function set(data, key, value)
  data[key] = {
    value = value,
    info = {expired = false}
  }
end

function SharedDict:new()
  return setmetatable({data = {}}, {__index = self})
end

function SharedDict:get(key)
  return self.data[key] and self.data[key].value, nil
end

function SharedDict:set(key, value)
  set(self.data, key, value)
  return true, nil, false
end

SharedDict.safe_set = SharedDict.set

function SharedDict:add(key, value)
  if self.data[key] ~= nil then
    return false, "exists", false
  end

  set(self.data, key, value)
  return true, nil, false
end

function SharedDict:replace(key, value)
  if self.data[key] == nil then
    return false, "not found", false
  end

  set(self.data, key, value)
  return true, nil, false
end

function SharedDict:delete(key)
  if self.data[key] ~= nil then
    self.data[key] = nil
  end
end

function SharedDict:incr(key, value, init)
  if not self.data[key] then
    if not init then
      return nil, "not found"
    else
      set(self.data, key, init)
    end
  elseif type(self.data[key]) ~= "table" then
    return nil, "not a table"
  end

  self.data[key].value = self.data[key].value + value
  return self.data[key].value, nil
end

function SharedDict:flush_all()
  for _, item in pairs(self.data) do
    item.info.expired = true
  end
end

function SharedDict:flush_expired(n)
  local data = self.data
  local flushed = 0

  for key, item in pairs(self.data) do
    if item.info.expired then
      data[key] = nil
      flushed = flushed + 1
      if n and flushed == n then
        break
      end
    end
  end

  self.data = data

  return flushed
end

function SharedDict:get_keys()
  local keys = {}
  for k, _ in pairs(self.data) do
    table.insert(keys, k)
  end

  return keys
end

local shared_mt = {
  __index = function(self, key)
    if rawget(self, key) == nil then
      self[key] = SharedDict:new()
    end
    return self[key]
  end
}

return setmetatable({}, shared_mt)
