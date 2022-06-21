local function is_win()
  return vim.fn.has 'win32' == 1
end

local keys = {
  -- reset
  reset = 0,

  -- misc
  bright = 1,
  dim = 2,
  underline = 4,
  blink = 5,
  reverse = 7,
  hidden = 8,

  -- foreground colors
  black = 30,
  red = 31,
  green = 32,
  yellow = 33,
  blue = 34,
  magenta = 35,
  cyan = 36,
  white = 37,

  -- background colors
  blackbg = 40,
  redbg = 41,
  greenbg = 42,
  yellowbg = 43,
  bluebg = 44,
  magentabg = 45,
  cyanbg = 46,
  whitebg = 47,
}

local function escape_number(number)
  local escape_string = string.char(27) .. '[%dm'
  return escape_string:format(number)
end

local function escape_keys(str)
  if is_win() then
    return ''
  end

  local buffer = {}
  local number
  for word in str:gmatch '%w+' do
    number = keys[word]
    assert(number, 'Unknown key: ' .. word)
    table.insert(buffer, escape_number(number))
  end

  return table.concat(buffer)
end

---@param text string
---@return string
local function replace_codes(text)
  text = string.gsub(text, '(%%{(.-)})', function(_, val)
    return escape_keys(val)
  end)
  return text
end

---@param text string
---@return string
local function parse_colors(text)
  return replace_codes('%{reset}' .. text .. '%{reset}')
end

return setmetatable({
  no_reset = replace_codes,
}, {
  __call = function(_, str)
    return parse_colors(str)
  end,
  __index = function(_, k)
    return function(str)
      return parse_colors('%{' .. k .. '}' .. str)
    end
  end,
})
