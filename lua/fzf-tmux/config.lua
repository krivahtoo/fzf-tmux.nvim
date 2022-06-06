local config = {
  cmd = 'fzf-tmux',
  height = '80%',
  width = '90%',
  fzf = {
    ansi = true,
    preview = true,
    multi = true,
    inline_info = true,
    prompt = 'Fzf',
    bindings = {},
  },
}

return config
