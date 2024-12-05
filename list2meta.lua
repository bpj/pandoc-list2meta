-- DO NOT EDIT!
-- This file was automatically generated from list2meta.moon
-- See there for more readable code and comments!

local pdc = assert(pandoc, "Cannot find the pandoc library")
if not ('table' == type(pdc)) then
  error("Expected variable pandoc to be table")
end
local pdu = assert(pandoc.utils, "Cannot find the pandoc.utils library")
local bool_for = {
  ['true'] = true,
  ['false'] = false
}
local to_bool
to_bool = function(val)
  local str = pdu.stringify(val)
  local bool = bool_for[str]
  if nil == bool then
    return nil
  end
  return str, bool
end
local squish
squish = function(str)
  return str:gsub("\r?\n%s*", " ")
end
local list2meta
list2meta = function()
  return error('list2meta not yet initialized')
end
local blocks2meta
blocks2meta = function(lolob, id)
  if id == nil then
    id = 'value'
  end
  if 'Blocks' == pdu.type(lolob) then
    lolob = pdc.List({
      lolob
    })
  end
  local lt = pdu.type(lolob)
  if not ('List' == lt) then
    error("Expected " .. tostring(id) .. " to be List (of Blocks); got " .. tostring(lt))
  end
  local rv = pdc.Blocks({ })
  for i, item in ipairs(lolob) do
    local it = pdu.type(item)
    if not ('Blocks' == it) then
      error(squish("Expected " .. tostring(id) .. "[" .. tostring(i) .. "] to be list of blocks\n        or list of lists of blocks"))
    end
    rv:extend(item)
  end
  if 1 == #rv then
    local elem = rv[1]
    local _exp_0 = elem.tag
    if 'DefinitionList' == _exp_0 or 'BulletList' == _exp_0 or 'OrderedList' == _exp_0 then
      return list2meta(elem)
    elseif 'Div' == _exp_0 then
      if 1 == #elem.classes and 'nometa' == elem.classes[1] then
        print('Div', pdu.type(elem.content))
        return pdc.Blocks(elem.content)
      end
    elseif 'RawBlock' == _exp_0 then
      if 'str' == elem.format then
        return elem.text
      end
    elseif 'Para' == _exp_0 or 'Plain' == _exp_0 then
      local content = elem.content
      print(elem.tag, pdu.type(content))
      if 1 == #content then
        local child = content[1]
        local _exp_1 = child.tag
        if 'RawInline' == _exp_1 then
          local _exp_2 = child.format
          if 'str' == _exp_2 then
            return child.text
          elseif 'bool' == _exp_2 then
            local ok, bool = to_bool(child.text)
            return ok and bool or error("Cannot use [" .. tostring(child) .. "] as bool")
          end
        elseif 'Span' == _exp_1 then
          if 1 == #child.classes and 'symbol' == child.classes[1] then
            local sym = pdu.stringify(child)
            local ok, bool = to_bool(sym)
            if ok then
              return bool
            end
          end
        end
      end
      return pdc.Inlines(content)
    end
  end
  return rv
end
list2meta = function(self, id)
  if id == nil then
    id = 'value'
  end
  local etag = self.tag or pdu.type(self)
  local _exp_0 = etag
  if 'DefinitionList' == _exp_0 then
    local rv = { }
    for i, item in ipairs(self.content) do
      local term, defs
      term, defs = item[1], item[2]
      local key = pdu.stringify(term)
      rv[key] = blocks2meta(defs, tostring(id) .. "[[" .. tostring(i) .. "] " .. tostring(key) .. "]")
    end
    return rv
  elseif 'BulletList' == _exp_0 or 'OrderedList' == _exp_0 then
    local rv
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i, v in ipairs(self.content) do
        _accum_0[_len_0] = blocks2meta(v, tostring(id) .. "[" .. tostring(i) .. "]")
        _len_0 = _len_0 + 1
      end
      rv = _accum_0
    end
    return pdc.List(rv)
  end
  return error(squish("Expected " .. tostring(id) .. " to be DefinitionList,\n    BulletList or OrderedList; got " .. tostring(etag)))
end
local get_meta_list
get_meta_list = function(self, id)
  if id == nil then
    id = 'value'
  end
  if not ('Div' == self.tag) then
    return nil
  end
  if 1 == #self.classes and 'metadata' == self.classes[1] then
    local list = self.content[1]
    if 1 == #self.content and 'DefinitionList' == list.tag then
      return list
    end
    error("Expected " .. tostring(id) .. "@Div.metadata to contain just a DefinitionList")
  end
  return nil
end
Pandoc = function(self)
  if 0 == #self.blocks then
    return nil
  end
  local meta = self.meta
  local bb = pdc.Blocks({ })
  local id = "Pandoc[blocks]"
  local count = 0
  for i, block in ipairs(self.blocks) do
    local bid = tostring(id) .. "[" .. tostring(i) .. "]"
    do
      local list = get_meta_list(block, bid)
      if list then
        count = count + 1
        local mid = tostring(bid) .. ".metadata#" .. tostring(block.identifier or count)
        for k, v in pairs(list2meta(list, mid)) do
          meta[k] = v
        end
        if meta['keep-list2meta'] then
          bb[#bb + 1] = block
        end
      else
        bb[#bb + 1] = block
      end
    end
  end
  self.meta = meta
  self.blocks = bb
  return self
end
