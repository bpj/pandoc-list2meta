-- Save some typing
pdc = assert pandoc, "Cannot find the pandoc library"
unless 'table' == type pdc
  error "Expected variable pandoc to be table"
pdu = assert pandoc.utils, "Cannot find the pandoc.utils library"
-- pdt = assert pandoc.text, "Cannot get the pandoc.text library"
-- jsn = assert pandoc.json, "Cannot get the pandoc.json library"

-- "Convert" a string to a boolean
-- `ok, res = to_bool(val)`
-- Returns:
-- -  If `val` is a boolean or otherwise stringifies to "true" or "false":
--    -   The stringification (which is true)
--        and a `true` or `false` boolean.
-- -  Otherwise:
--    -   `nil` (which is false)
bool_for =
  'true': true
  'false': false
to_bool = (val) ->
  str  = pdu.stringify val
  bool = bool_for[str]
  return nil if nil == bool
  return str, bool

-- Replace line-breaks + optional whitespace
-- with a single space (for messages)
squish = (str) -> str\gsub "\r?\n%s*", " "

-- -- `tag|type|nil, type|nil = kind_of(val<any> [, ...])`
-- --  Returns:
-- --  -   If there is only one argument:
-- --      -   If type of `val` is Inline or a Block:
-- --          -   `val.tag<str>, val_type<str>`
-- --      -   Else:
-- --          -   `nil`
-- --  -   If there are varargs:
-- --      -   For the first vararg which is equal to the tag or type of `val`:
-- --          -   `vararg, val_type<str>`
-- --              including `nil, val_type<str>` if a vararg is `nil` and `val` isn't
-- --              an Inline or Block, so always inspect the
-- --              the second retval if any vararg can be `nil`!
-- --      -   If no vararg is equal to the tag or type of `val`:
-- --          -   `nil`
-- kind_of = (val, ...) ->
--   vtype = pdu.type val
--   local vtag
--   if 'Block' == vtype or 'Inline' == vtype
--     vtag = val.tag
--   tag = pack ...
--   for i=1,#tag
--     if tag[i] == vtag or tag[i] == vtype
--       return tag[i], vtype
--   if vtag
--     return vtag, vtype
--   return nil

-- Converts a list *element* to metadata.
-- Will be initialized to something useful below
list2meta = -> error 'list2meta not yet initialized'

-- Converts a (list of) Blocks<list> to metadata value
-- `meta_val = blocks2meta(list_of_list_of_blocks, id="value")`
blocks2meta = (lolob, id='value') ->
  -- Make sure we have a list "of Blocks" if arg is a Blocks
  lolob = pdc.List{lolob} if 'Blocks' == pdu.type lolob
  -- Make sure lolob is a List
  lt = pdu.type lolob
  unless 'List' == lt
    error "Expected #{id} to be List (of Blocks); got #{lt}"
  -- Collect return value(s) here
  rv = pdc.Blocks{}
  for i, item in ipairs lolob
    -- item type
    it = pdu.type item
    unless 'Blocks' == it
      error squish"Expected #{id}[#{i}] to be list of blocks
        or list of lists of blocks"
    -- It's ok so merge it with the retvals
    rv\extend item
  -- Special case if there only is one retval
  if 1 == #rv
    elem = rv[1]
    switch elem.tag
      when 'DefinitionList', 'BulletList', 'OrderedList'
        return list2meta elem
      when 'Div'
        -- If it is a div with only class `nometa`
        --  Return contents as a "new" list of blocks
        if 1 == #elem.classes and 'nometa' == elem.classes[1]
          print 'Div', pdu.type elem.content
          return pdc.Blocks elem.content
      when 'RawBlock'
        -- Return as raw string if "format" is "str"
        return elem.text if 'str' == elem.format
      when 'Para', 'Plain'
        -- Retval depends on what contents are
        content = elem.content
        print elem.tag, pdu.type content
        -- If there is only one child in content
        if 1 == #content
          child = content[1]
          switch child.tag
            when 'RawInline'
              -- Retval depends on "format"
              switch child.format
                when 'str'
                  -- Return as raw string
                  return child.text
                when 'bool'
                  -- Return boolean if text "looks like a boolean", error if not
                  ok, bool = to_bool(child.text)
                  return ok and bool or
                    error "Cannot use [#{child}] as bool"
            when 'Span'
              -- If span has only one child itself
              -- and its first class is "symbol"
              if 1 == #child.classes and 'symbol' == child.classes[1]
                sym = pdu.stringify child
                -- Return a bool if the "symbol" stringifies
                -- to "true" or "false"
                ok, bool = to_bool(sym)
                return bool if ok
        -- Para|Plain is none of those special cases:
        -- return contents as "new" list of Inlines
        return pdc.Inlines content
  -- Multiple retvals (list of Blocks): return that list
  return rv

-- Converts a list *element* to metadata:
--  -   DefinitionList to table (meta mapping)
--  -   BulletList or OrderedList to List (meta list)
--
--  of `table`s, `List`s, `Inlines`, `Blocks`,
--  `string`s and `boolean`s recursively.
-- (Was forward declared above)
list2meta = (id='value') =>
  -- The tag or type of the value
  etag = @.tag or pdu.type @
  switch etag
    when 'DefinitionList' -- mapping
      rv = {} -- collect retvals here
      for i, item in ipairs @.content
        {term, defs} = item
        key = pdu.stringify term
        rv[key] = blocks2meta defs, "#{id}[[#{i}] #{key}]"
      return rv
    when 'BulletList', 'OrderedList' -- list
      rv = [blocks2meta(v, "#{id}[#{i}]") for i,v in ipairs @.content]
      return pdc.List rv
  -- If is none of the above
  error squish"Expected #{id} to be DefinitionList,
    BulletList or OrderedList; got #{etag}"
   
-- If the value is a Div "tagged" `.metadata`
-- whose only child is a DefinitionList return that list.
-- If it is a Div so tagged but the child(ren) nonconforming error.
-- Otherwise return nil.
get_meta_list = (id='value') =>
  return nil unless 'Div' == @.tag
  if 1 == #@.classes and 'metadata' == @.classes[1]
    list = @.content[1]
    return list if 1 == #@.content and 'DefinitionList' == list.tag
    error "Expected #{id}@Div.metadata to contain just a DefinitionList"
  return nil
   
-- The main "filter function" works on the whole document
export Pandoc = =>
  -- Do nothing if "body" is empty
  return nil if 0 == #@.blocks
  meta = @.meta -- get document metadata
  -- Collect "body" blocks we are going to keep here.
  bb = pdc.Blocks{}
  id = "Pandoc[blocks]"
  count = 0 -- counts the number of meta lists
  -- Loop over top level document body elements
  for i, block in ipairs @.blocks
    bid = "#{id}[#{i}]" -- block id
    if list = get_meta_list block, bid
      count += 1 -- increment count
      -- meta list id: block id + `.metadata#<id>`
      -- where `<id>` is the identifier of the block or the count.
      mid = "#{bid}.metadata##{block.identifier or count}"
      -- Convert list to meta table
      -- and assign values to their respective metadata keys
      meta[k] = v for k, v in pairs list2meta list, mid
      -- should we keep meta lists in the "body"?
      bb[#bb+1] = block if meta['keep-list2meta']
    else -- if not a meta list always keep it in the body
      bb[#bb+1] = block
  -- (Re)insert the possibly modified document metadata
  @.meta = meta
  -- Insert the kept "body" blocks
  @.blocks = bb
  -- Return the possibly modified document
  return @
        
-- Vim: set ft=moon et tw=0 sw=2 ts=2 sts=2 cms=--\ %s:
