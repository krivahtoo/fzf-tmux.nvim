local Job = require 'plenary.job'
local util = require 'fzf-tmux.util'
local config = require 'fzf-tmux.config'
local colors = require 'fzf-tmux.colors'

local M = {}

---@param options table
local function with_defaults(options)
  local opts = vim.tbl_deep_extend('force', config, options)
  return opts
end

---@param placeholder string|nil
local function get_preview_cmd(placeholder)
  local ph = placeholder or '{}'
  local bin_dir = vim.g.fzf_tmux_path or ''
  if bin_dir == '' then
    return ''
  end
  return string.format('%s/bin/preview.sh %s', bin_dir, ph)
end

---@class Buffer
---@field bufnr number
---@field flag string
---@field info table
--
---@class BufferFilterOptions
---@field all boolean
---@field sort_lastused boolean

---@param opts BufferFilterOptions
---@return Buffer[]
local function filter_buffers(opts)
  local buffers = {}
  local currbuf = vim.api.nvim_get_current_buf()
  local buflist = vim.api.nvim_list_bufs()
  local prevbuf = vim.fn.bufnr '#'
  for _, bufnr in ipairs(buflist) do
    local info = vim.fn.getbufinfo(bufnr)[1]
    if info.listed == 1 or opts.all then
      local flag = (bufnr == currbuf and '%') or (bufnr == prevbuf and '#') or ' '

      local buffer = {
        bufnr = bufnr,
        flag = flag,
        info = info,
      }

      table.insert(buffers, buffer)
    end
  end
  if opts.sort_lastused then
    table.sort(buffers, function(a, b)
      return a.info.lastused > b.info.lastused
    end)
  end
  return buffers
end

--- Run the fzf command
---@param options table
---@param callback fun(result: string[])
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
      writer = vim.tbl_islist(opts.source) and opts.source or Job:new(opts.source),
    })
    :start()
end

---@param options table
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
  vim.api.nvim_create_user_command('GFiles', function(opts)
    M.files {
      fargs = opts.fargs,
      command = 'git',
      args = { 'ls-files' },
    }
  end, {
    nargs = '*',
    bang = true,
    desc = 'Search git files',
  })
  vim.api.nvim_create_user_command('History', function(opts)
    M.files {
      fargs = opts.fargs,
      source = vim.v.oldfiles,
    }
  end, {
    nargs = '*',
    desc = 'Search history files',
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
  vim.api.nvim_create_user_command('Buffers', function(opts)
    M.buffers { all = opts.bang }
  end, {
    nargs = '?',
    bang = true,
    desc = 'Search all files in the current directory',
  })
end

---@return boolean
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
  local source = opts.source or {
    command = opts.command,
    args = args,
  }
  M._run({
    source = source,
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
        ['-0'] = true,
        ['-d'] = ':',
        ['--preview-window'] = '60%,+{2}/2',
      },
    },
    source = {
      command = opts.command,
      args = args,
      on_stderr = function(err)
        vim.notify(err, 'error', { title = 'fzf-tmux' })
      end,
      on_exit = function(_, code)
        if code == 1 then
          vim.notify('No matches found', 'warn', { title = 'fzf-tmux' })
        elseif code == 2 then
          vim.notify('Grep program exited with error code 2', 'error', { title = 'fzf-tmux' })
        end
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

---@param opts BufferFilterOptions
function M.buffers(opts)
  if not M.is_configured() then
    vim.api.nvim_err_writeln 'fzf-tmux.nvim: you should first call setup() to load the plugin'
    return
  end
  ---@type BufferFilterOptions
  local options = vim.tbl_extend('keep', opts, { sort_lastused = true })

  local header = ''
  local source = {}
  for _, buf in ipairs(filter_buffers(options)) do
    local curr_bufnr = vim.api.nvim_get_current_buf()
    local linenr = buf.info.lnum or 0
    local name = buf.bufnr == curr_bufnr
        and colors.blue(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf.bufnr), ':p:~:.'))
      or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf.bufnr), ':p:~:.')
    local flag = buf.flag == '#' and colors.magenta(buf.flag) or buf.flag
    local target = buf.bufnr ~= curr_bufnr and name .. ':' .. linenr .. ':' or ''
    local modified = vim.fn.getbufvar(buf.bufnr, '&modified') == 1 and colors.green ' ' or ''
    local readonly = vim.fn.getbufvar(buf.bufnr, '&readonly') == 1 and colors.red ' ' or ''
    local str = string.format('[%s] %s\t%s\t%s\t%s', colors.yellow(buf.bufnr), flag, name, modified, readonly)
    str = buf.bufnr ~= curr_bufnr and target .. '\t' .. linenr .. '\t' .. str or str
    if buf.bufnr == curr_bufnr then
      header = str
    else
      table.insert(source, str)
    end
  end
  M._run({
    source = source,
    fzf = {
      multi = false,
      prompt = 'Buf',
      raw = {
        ['-d'] = '\t',
        ['--header'] = header ~= '' and header or false,
        ['--tabstop'] = '2',
        ['--nth'] = '2',
        ['--with-nth'] = '3..',
        ['--preview-window'] = '60%,+{2}/2',
      },
    },
  }, function(result)
    for _, line in ipairs(result) do
      local id = string.match(line, '%[(%d+)%]')
      local cmd = string.format(':buffer %s', id)
      vim.defer_fn(function()
        vim.cmd(cmd)
      end, 0)
    end
  end)
end

M.options = nil
return M
