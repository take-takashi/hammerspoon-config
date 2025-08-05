-- logger.lua

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
  filePath = nil,
  maxSize = 1024 * 1024, -- 1MB
  maxBackups = 5, -- Number of old log files to keep
  format = '{timestamp} [{level}] {name}: {message}',
}

function Logger.getLogger(name, options)
  if instances[name] then
    return instances[name]
  end

  local newLogger = {}
  setmetatable(newLogger, Logger)

  newLogger.name = name
  newLogger.options = vim.tbl_extend('force', defaultOptions, options or {})
  newLogger.level = levels[newLogger.options.level] or levels.INFO
  newLogger.hsLogger = hs.logger.new(name, 'debug') -- hs.loggerを内部で使用

  instances[name] = newLogger
  return newLogger
end

function Logger:log(level, message)
  local requiredLevel = levels[level]
  if self.level < requiredLevel then
    return
  end

  local timestamp = os.date('%Y-%m-%d %H:%M:%S')
  local formattedMessage = self.options.format
  formattedMessage = formattedMessage:gsub('{timestamp}', timestamp)
  formattedMessage = formattedMessage:gsub('{level}', level)
  formattedMessage = formattedMessage:gsub('{name}', self.name)
  formattedMessage = formattedMessage:gsub('{message}', message)

  -- Log to Hammerspoon console
  if level == 'ERROR' then
    self.hsLogger.e(formattedMessage)
  elseif level == 'WARN' then
    self.hsLogger.w(formattedMessage)
  elseif level == 'INFO' then
    self.hsLogger.i(formattedMessage)
  elseif level == 'DEV' then
    -- hs.logger doesn't have a 'dev' level, so we can map it to 'debug'
    self.hsLogger.d(formattedMessage)
  end

  -- Log to file if filePath is configured
  if self.options.filePath then
    -- Log rotation
    local size = hs.fs.attributes(self.options.filePath, 'size')
    if size and size > self.options.maxSize then
      local timestamp = os.date('%Y%m%d%H%M%S')
      local newPath = self.options.filePath:gsub('(.*)(\..*)

    -- Write to file
    local file = io.open(self.options.filePath, 'a')
    if file then
      file:write(formattedMessage .. '\n')
      file:close()
    end
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

return Logger
, '%1-' .. timestamp .. '%2')
      if newPath == self.options.filePath then -- No extension
        newPath = self.options.filePath .. '-' .. timestamp
      end
      os.rename(self.options.filePath, newPath)

      -- Clean up old backups
      if self.options.maxBackups > 0 then
        local dir = hs.fs.dirname(self.options.filePath)
        local basename = hs.fs.basename(self.options.filePath):gsub('(\..*)
    end

    -- Write to file
    local file = io.open(self.options.filePath, 'a')
    if file then
      file:write(formattedMessage .. '\n')
      file:close()
    end
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

return Logger
, '')
        local ext = hs.fs.basename(self.options.filePath):match('(\..*)
    end

    -- Write to file
    local file = io.open(self.options.filePath, 'a')
    if file then
      file:write(formattedMessage .. '\n')
      file:close()
    end
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

return Logger
) or ''

        local pattern = dir .. '/' .. basename .. '-*' .. ext
        local backups = hs.fs.glob(pattern)
        
        if #backups > self.options.maxBackups then
          table.sort(backups)
          for i = 1, #backups - self.options.maxBackups do
            os.remove(backups[i])
          end
        end
      end
    end

    -- Write to file
    local file = io.open(self.options.filePath, 'a')
    if file then
      file:write(formattedMessage .. '\n')
      file:close()
    end
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

return Logger
