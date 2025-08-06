-- logger.lua (Simplified for debugging)

local Logger = {}
Logger.__index = Logger

local instances = {}

-- Log levels
local levels = {
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  DEV = 4,
}

-- Default options
local defaultOptions = {
  level = 'INFO',
  format = '{timestamp} [{level}] {name}: {message}',
}

-- Helper function to merge tables
local function merge_tables(base, override)
    local new_table = {}
    for k, v in pairs(base) do
        new_table[k] = v
    end
    if override then
        for k, v in pairs(override) do
            new_table[k] = v
        end
    end
    return new_table
end

function Logger:new(name, options)
  if instances[name] then
    return instances[name]
  end

  local newLogger = {}
  setmetatable(newLogger, Logger)

  newLogger.name = name
  newLogger.options = merge_tables(defaultOptions, options or {})
  newLogger.level = levels[newLogger.options.level] or levels.INFO
  newLogger.hsLogger = hs.logger.new(name, 'debug') -- hs.loggerを内部で使用

  instances[name] = newLogger
  return newLogger
end

function Logger:log(level, message)
  local requiredLevel = levels[level]
  if self.level > requiredLevel then
    return
  end

  local timestamp = os.date('%Y-%m-%d %H:%M:%S')
  local formattedMessage = self.options.format
  formattedMessage = formattedMessage:gsub('{timestamp}', timestamp)
  formattedMessage = formattedMessage:gsub('{level}', level)
  formattedMessage = formattedMessage:gsub('{name}', self.name)
  formattedMessage = formattedMessage:gsub('{message}', tostring(message))

  -- Log to Hammerspoon console
  if level == 'ERROR' then
    self.hsLogger.e(formattedMessage)
  elseif level == 'WARN' then
    self.hsLogger.w(formattedMessage)
  elseif level == 'INFO' then
    self.hsLogger.i(formattedMessage)
  elseif level == 'DEV' then
    self.hsLogger.d(formattedMessage)
  end
end

function Logger:info(message)
  self:log('INFO', message)
end

function Logger:warn(message)
  self:log('WARN', message)
end

function Logger:error(message)
  self:log('ERROR', message)
end

function Logger:dev(message)
  self:log('DEV', message)
end

-- 他のモジュールから呼び出せるように、newメソッドを持つテーブルを返す
return {
    new = function(name, options)
        return Logger:new(name, options)
    end
}
