local Command = {}
Command.__index = Command

function Command.new(name, args, default, body)
  local self = setmetatable({}, Command)
  self.name = name
  self.args = args
  self.default = default
  self.body = body
  return self
end

function Command:to_json()
  local template = [[
  "%s": {
    "name": "%s",
    "args": %d,
    "has_optional": %s,
    "default": "%s",
    "body": "%s"
  },
]]
  local has_opt
  if self.default ~= nil then
    has_opt = "true"
  else
    has_opt = "false"
  end
  local default = self.default or ""
  return template:format(
    self.name,
    self.name,
    self.args,
    has_opt,
    default,
    self.body)
end


local Katze = {}
Katze.__index = Katze

function Katze.new()
  local self = setmetatable({}, Katze)
  self.commands = {}
  return self
end

--[[
function Katze:send_message(addr, port, msg)
  local connection = socket.connect(addr, port)
  print(connection:receive())
  connection:send(msg)
  for i = 1, 2 do
    local line = connection:receive()
    print('Response: ' .. line)
  end
  connection:close()
end
]]

function Katze:show_error(message)
  local template = "Katze: %s"
  error(template:format(message))
end

function Katze:show_warning(message)
  local template = [[\PackageWarning{Katze: %s}]]
  tex.print(template:format(message))
end

function Katze:register(name, args, default, body)
  local is_new = self.commands[name] == nil
  self.commands[name] = Command.new(name, args, default, body)
  return is_new
end

function Katze:new_command(name, args, default, body)
  local is_new = self:register(name, args, default, body)
  if not is_new then
    local message = [[\newkatzecommand{%s}: command %s already defined]]
    self:show_error(message:format(name, name))
  end
end

function Katze:renew_command(name, args, default, body)
  local is_new = self:register(name, args, default, body)
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
  for name, command in pairs(self.commands) do
    client:send(command:to_json())
  end
  client:send('}\n')
  client:close()
end

local default_katze = Katze.new()