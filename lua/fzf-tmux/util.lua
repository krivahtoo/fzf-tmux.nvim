local M = {}

function M.greeting(name)
  return 'Hello ' .. name
end

function M.build_args(opts)
  local args = {}
  for k, v in pairs(opts) do
    if v then
      table.insert(args, k)
      if v ~= true then
        table.insert(args, v)
      end
    end
  end
  return args
end

return M
