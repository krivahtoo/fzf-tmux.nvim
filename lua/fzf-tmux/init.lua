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

  if opts.fzf.raw then
    local raw_args = util.build_args(opts.fzf.raw)
    for _, v in ipairs(raw_args) do
      table.insert(args, v)
    end
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

  vim.api.nvim_create_user_command('Files', function(opts)
    M.files {
      fargs = opts.fargs,
      command = 'fd',
      args = {
        '--type',
        'file',
        '-H',
        '-I',
        '-E',
        '.git',
        '--strip-cwd-prefix',
        '--color',
        'always',
      },
    }
  end, {
    nargs = '*',
    bang = true,
    desc = 'Search all files in the current directory',
  })
  vim.api.nvim_create_user_command('Rg', function(opts)
    M.grep {
      fargs = opts.fargs,
      command = 'rg',
      args = {
        '--column',
        '--line-number',
        '--no-heading',
        '--color=always',
        '--smart-case',
      },
    }
  end, {
    nargs = '+',
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
  local args = opts.args
  if opts.fargs then
    for _, v in ipairs(opts.fargs) do
      table.insert(args, v)
    end
  end
  M._run({
    source = {
      command = opts.command,
      args = args,
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

function M.grep(opts)
  if not M.is_configured() then
    vim.api.nvim_err_writeln 'fzf-tmux.nvim: you should first call setup() to load the plugin'
    return
  end
  local args = opts.args
  if opts.fargs then
    for _, v in ipairs(opts.fargs) do
      table.insert(args, v)
    end
  end
  -- Add current path to ignore stdin
  table.insert(args, './')
  M._run({
    fzf = {
      prompt = 'Rg',
      raw = {
        ['-d'] = ':',
        ['--preview-window'] = '+{2}/2',
      },
    },
    source = {
      command = opts.command,
      args = args,
      on_stderr = function(err)
        vim.api.nvim_err_writeln(err)
      end,
    },
  }, function(result)
    if #result > 1 then
      vim.defer_fn(function()
        vim.fn.setqflist({}, 'r', { lines = result })
        vim.cmd [[copen]]
        vim.cmd [[wincmd p]]
      end, 0)
      return
    end
    local line = unpack(result)
    local f = vim.split(line, ':', { plain = true, trimempty = true })
    local cmd = string.format(':edit +%s %s', f[2], f[1])
    vim.defer_fn(function()
      vim.cmd(cmd)
    end, 0)
  end)
end

M.options = nil
return M
