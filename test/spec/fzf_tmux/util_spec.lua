local util = require 'fzf_tmux.util'

describe('greeting', function()
  it('works!', function()
    assert.combinators.match('Hello Gabo', util.greeting 'Gabo')
  end)
end)
