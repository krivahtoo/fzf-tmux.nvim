<div align="center">

# fzf :heart: tmux

![Neovim version][neovim-badge] [![Integration][integration-badge]][integration-runs]

</div>

A simple Neovim plugin to open fzf on tmux floating window.


https://user-images.githubusercontent.com/41364823/172863707-f9559d1d-ee94-4e3a-ba55-90aec1f25d9b.mp4



## Requirements

- neovim >= `0.7.0`
- tmux >= `3.2`
- fzf

## Using

For example using [`packer`][packer]:
```lua
use {
  'krivahtoo/fzf-tmux.nvim',
  requires = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('fzf-tmux').setup {}
  end
}
```

## Credits
Thanks to [m00qek lua plugin template][m00qek].

[m00qek]: https://github.com/m00qek/plugin-template.nvim
[packer]: https://github.com/wbthomason/packer.nvim
[integration-badge]: https://github.com/krivahtoo/fzf-tmux.nvim/actions/workflows/integration.yml/badge.svg
[integration-runs]: https://github.com/krivahtoo/fzf-tmux.nvim/actions/workflows/integration.yml
[neovim-badge]: https://img.shields.io/badge/Neovim-0.7-57A143?style=flat-square&logo=neovim
