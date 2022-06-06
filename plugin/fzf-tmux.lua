if vim.fn.has 'nvim-0.7.0' == 0 then
  vim.api.nvim_err_writeln 'fzf-tmux requires at least nvim-0.7.0.1'
  return
end

-- make sure this file is loaded only once
if vim.g.loaded_fzf_tmux == 1 then
  return
end
vim.g.loaded_fzf_tmux = 1

---@diagnostic disable-next-line: missing-parameter
vim.g.fzf_tmux_path = vim.fn.expand '<sfile>:p:h:h'
