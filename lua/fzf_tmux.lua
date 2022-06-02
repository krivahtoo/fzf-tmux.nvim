local util = require 'fzf_tmux.util'

local fzf_tmux = {}

local function with_defaults(options)
  return {
    name = options.name or 'John Doe',
  }
end

-- This function is supposed to be called explicitly by users to configure this
-- plugin
function fzf_tmux.setup(options)
  -- avoid setting global values outside of this function. Global state
  -- mutations are hard to debug and test, so having them in a single
  -- function/module makes it easier to reason about all possible changes
  fzf_tmux.options = with_defaults(options)

  -- do here any startup your plugin needs, like creating commands and
  -- mappings that depend on values passed in options
  vim.api.nvim_create_user_command('MyPluginGreet', fzf_tmux.greet, {})
end

function fzf_tmux.is_configured()
  return fzf_tmux.options ~= nil
end

-- This is a function that will be used outside this plugin code.
-- Think of it as a public API
function fzf_tmux.greet()
  if not fzf_tmux.is_configured() then
    return
  end

  -- try to keep all the heavy logic on pure functions/modules that do not
  -- depend on Neovim APIs. This makes them easy to test
  local greeting = util.greeting(fzf_tmux.options.name)
  print(greeting)
end

-- Another function that belongs to the public API. This one does not depend on
-- user configuration
function fzf_tmux.generic_greet()
  print 'Hello, unnamed friend!'
end

fzf_tmux.options = nil
return fzf_tmux
