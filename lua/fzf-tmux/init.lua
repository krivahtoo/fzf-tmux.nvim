local Job = require 'plenary.job'
local tbl = require 'plenary.tbl'
local util = require 'fzf-tmux.util'
local config = require 'fzf-tmux.config'

local M = {}

local function with_defaults(options)
  local opts = vim.tbl_deep_extend('force', config, options)
  return opts
end

local function get_preview_cmd()
  local bin_dir = vim.g.fzf_tmux_path or ''
  if bin_dir == '' then
    return ''
  end
  return string.format('%s/bin/preview.sh {}', bin_dir)
end

function M._run(options, callback)
  if not M.is_configured() then
    vim.notify('you should first call setup() to load the plugin', 'error', { title = 'fzf-tmux' })
    return
  end
  if callback == nil then
    vim.notify('callback is required', 'error', { title = 'fzf-tmux' })
    return
  end
  local opts = vim.tbl_deep_extend('force', M.options, options)
  if opts.source == nil then
    vim.notify('no data source provided', 'error', { title = 'fzf-tmux' })
    return
  end
  local args = { '-h', opts.height, '-w', opts.width, '--' }

  if opts.fzf.ansi then
    table.insert(args, '--ansi')
  end
  if opts.fzf.prompt ~= nil then
    table.insert(args, '--prompt')
    table.insert(args, string.format('%s> ', opts.fzf.prompt))
  end
  if opts.fzf.inline_info then
    table.insert(args, '--inline-info')
  end
  if opts.fzf.multi then
    table.insert(args, '--multi')
  end
  if opts.fzf.preview then
    table.insert(args, '--preview')
    table.insert(args, get_preview_cmd())
  end

  Job
    :new({
      command = opts.cmd,
      args = args,
      on_exit = function(job, code)
        if code ~= 0 then
          if code == 2 then
            vim.notify(string.format('fzf-tmux exited with an error code %s', code), 'error', { title = 'fzf-tmux' })
          end
          return
        end
        callback(job:result())
      end,
      writer = Job:new(opts.source),
    })
    :start()
end

function M.setup(options)
  M.options = with_defaults(options)

  vim.api.nvim_create_user_command('Fzf', function(opts)
    M.files {
      args = opts['fargs'],
    }
  end, {
    desc = 'Search all files in the current directory',
  })
end

function M.is_configured()
  return M.options ~= nil
end

function M.files(opts)
  if not M.is_configured() then
    vim.api.nvim_err_writeln 'fzf-tmux.nvim: you should first call setup() to load the plugin'
    return
  end
  M._run({
    source = {
      command = 'fd',
      args = { '--type', 'file', '-H', '-I', '-E', '.git', '--strip-cwd-prefix', '--color', 'always' },
    },
  }, function(result)
    for _, line in ipairs(result) do
      local cmd = string.format(':edit %s', line)
      vim.defer_fn(function()
        vim.cmd(cmd)
      end, 0)
    end
  end)
end

M.options = nil
return M
