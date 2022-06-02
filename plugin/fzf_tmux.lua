if vim.fn.has 'nvim-0.7.0' == 0 then
  vim.api.nvim_err_writeln 'fzf_tmux requires at least nvim-0.7.0.1'
  return
end

-- make sure this file is loaded only once
if vim.g.loaded_fzf_tmux == 1 then
  return
end
vim.g.loaded_fzf_tmux = 1

-- create any global command that does not depend on user setup
-- usually it is better to define most commands/mappings in the setup function
-- Be careful to not overuse this file!
local fzf_tmux = require 'fzf_tmux'

vim.api.nvim_create_user_command('MyPluginGenericGreet', fzf_tmux.generic_greet, {})
