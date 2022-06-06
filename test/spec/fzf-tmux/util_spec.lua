---@diagnostic disable: undefined-global
local util = require 'fzf-tmux.util'

-- Return the first index with the given value (or array len if not found).
local function indexOf(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end
  return #array
end

describe('utils', function()
  it('works!', function()
    assert.combinators.match('Hello Gabo', util.greeting 'Gabo')
  end)
  it('builds arguments correctly', function()
    local args = util.build_args {
      ['--mult'] = true,
      ['--prompt'] = 'Fzf',
      ['--command'] = false,
      ['--cmd'] = nil,
      ['--ansi'] = true,
    }
    assert(#args == 4)
    assert(args[indexOf(args, '--prompt') + 1] == 'Fzf')
  end)
end)
