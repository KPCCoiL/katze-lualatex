local Command = {}
Command.__index = Command

function Command.new(name, allow_par, args, default, body)
  local self = setmetatable({}, Command)
  self.name = name:match("^%s*(.-)%s*$")
  self.args = args
  self.default = default
  self.body = body
  self.allow_par = allow_par
  return self
end

function Command:to_json()
  local template = [[
  "%s": {
    "name": "%s",
    "allow_par": %s,
    "args": %d,
    "has_optional": %s,
    "opt_default": "%s",
    "body": "%s"
  }
]]
  local has_opt
  if self.default ~= nil then
    has_opt = "true"
  else
    has_opt = "false"
  end
  local default = self.default or ""
  local function double_backslash(str)
    return str:gsub([[\]], [[\\]])
  end
  return template:format(
    double_backslash(self.name),
    double_backslash(self.name),
    self.allow_par,
    self.args,
    has_opt,
    double_backslash(default),
    double_backslash(self.body))
end


local Katze = {}
Katze.__index = Katze

function Katze.new()
  local self = setmetatable({}, Katze)
  self.commands = {}
  return self
end

function Katze:show_error(message)
  local template = "Katze: %s"
  error(template:format(message))
end

function Katze:show_warning(message)
  local template = [[\PackageWarning{Katze: %s}]]
  tex.print(template:format(message))
end

function Katze:register(name, allow_par, args, default, body)
  local is_new = self.commands[name] == nil
  self.commands[name] = Command.new(name, allow_par, args, default, body)
  return is_new
end

function Katze:new_command(name, allow_par, args, default, body)
  local is_new = self:register(name, allow_par, args, default, body)
  if not is_new then
    local message = [[\newkatzecommand{%s}: command %s already defined]]
    self:show_error(message:format(name, name))
  end
end

function Katze:renew_command(name, allow_par, args, default, body)
  local is_new = self:register(name, allow_par, args, default, body)
  if is_new then
    local message = [[\renewkatzecommand{%s}: command %s not defined]]
    self:show_error(message:format(name, name))
  end
end

function Katze:send_commands(addr, port)
  local socket = require('socket')
  local client = socket.connect(addr, port)
  if client == nil then
    self:show_warning("Failed to connect to server. Katze macros on Nyaovim won't be updated.")
    return
  end
  client:send('{\n')
  local first = true
  for name, command in pairs(self.commands) do
    if not first then
      client:send(',')
    end
    first = false
    client:send(command:to_json())
  end
  client:send('}\n')
  client:close()
end

return Katze
