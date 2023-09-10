---@meta

---@param targetEvent string?
---@return string, any ...
os.pullEvent = function(targetEvent) end

---@param type "utc"
os.epoch = function(type) end

---@param time number
os.startTimer = function(time) end

colors = {} ---@type table<string, number>

peripheral = {
    ---@param side string
    ---@return boolean
    isPresent = function(side) end,

    ---@param side string
    ---@return string
    getType = function(side) end,

    ---@param side string
    ---@return string[]
    getMethods = function(side) end,

    ---@param side string
    ---@param method string
    call = function(side, method, ...) end,

    ---@param side string
    ---@return unknown
    wrap = function(side) end,

    ---@param side string
    ---@param filter? fun(name: string, object): boolean
    ---@return unknown
    find = function(side, filter) end,

    ---@return string[]
    getNames = function() end,
}

fs = {
    ---@param path string
    ---@return boolean
    exists = function(path) end,

    ---@param path string
    ---@return boolean
    isDir = function(path) end,

    ---@param path string
    ---@return boolean
    isReadOnly = function(path) end,

    ---@param path string
    ---@return number
    getSize = function(path) end,

    ---@param path string
    ---@return number
    getFreeSpace = function(path) end,

    ---@param path string
    ---@return string | nil
    getDrive = function(path) end,

    ---@param path string
    ---@return string
    getName = function(path) end,

    ---@param path string
    ---@return string
    getDir = function(path) end,

    ---@param basePath string
    ---@param localPath string
    ---@return string
    combine = function(basePath, localPath) end,

    ---@param path string
    ---@param mode "r" | "w" | "a" | "rb" | "wb" | "ab"
    ---@return FileHandle | nil
    open = function(path, mode) end,

    ---@param path string
    ---@return string[]
    list = function(path) end,

    ---@param path string
    ---@return nil
    makeDir = function(path) end,

    ---@param fromPath string
    ---@param toPath string
    ---@return nil
    move = function(fromPath, toPath) end,

    ---@param fromPath string
    ---@param toPath string
    ---@return nil
    copy = function(fromPath, toPath) end,

    ---@param path string
    ---@return nil
    delete = function(path) end,

    ---@param wildcard string
    ---@return string[]
    find = function(wildcard) end,

    ---@param partial string
    ---@param path string
    ---@param includeFiles? boolean
    ---@param includeSlash? boolean
    ---@return string[]
    complete = function(partial, path, includeFiles, includeSlash) end,
}

---@class FileHandle
---@field close fun()
---@field read fun(): number | nil
---@field readLine fun(): string
---@field readAll fun(): string
---@field write fun(text: string | number)
---@field writeLine fun(text: string) -- Alias for write(text .. "\n")
---@field flush fun()

textutils = {
    ---@param text string
    ---@param rate number
    slowWrite = function(text, rate) end,

    ---@param text string
    ---@param rate number
    slowPrint = function(text, rate) end,

    ---@param time number
    ---@param twentyFourHour boolean
    ---@return string
    formatTime = function(time, twentyFourHour) end,

    ---@param table table | number
    ---@param table2 table | number
    ---@vararg table | number
    tabulate = function(table, table2, ...) end,

    ---@param table table | number
    ---@param table2 table | number
    ---@vararg table | number
    pagedTabulate = function(table, table2, ...) end,

    ---@param text string
    ---@param freeLines number
    ---@return number
    pagedPrint = function(text, freeLines) end,

    ---@param data table | string | number | boolean | nil
    ---@return string
    serialize = function(data) end,

    ---@param serializedData string
    ---@return unknown
    unserialize = function(serializedData) end,

    ---@param data table | string | number | boolean
    ---@param unquoteKeys boolean
    ---@return string
    serializeJSON = function(data, unquoteKeys) end,

    ---@param urlUnsafeString string
    ---@return string
    urlEncode = function(urlUnsafeString) end,

    ---@param partialName string
    ---@param environment table
    ---@return string[]
    complete = function(partialName, environment) end,
}

---@class MonitorPeripheral: Term
---@field setTextScale fun(scale: number)

---@class Term
term = {
    ---@param text string
    write = function(text) end,

    ---@param text string
    ---@param textColors string
    ---@param backgroundColors string
    blit = function(text, textColors, backgroundColors) end,

    clear = function() end,

    clearLine = function() end,

    ---@return number, number
    getCursorPos = function() end,

    ---@param x number
    ---@param y number
    setCursorPos = function(x, y) end,

    ---@param blink boolean
    setCursorBlink = function(blink) end,

    ---@return boolean
    isColor = function() end,

    ---@return number, number
    getSize = function() end,

    ---@param n number
    scroll = function(n) end,

    ---@param target table
    ---@return Term -- previous terminal object
    redirect = function(target) end,

    ---@return Term
    current = function() end,

    ---@return Term
    native = function() end,

    ---@param color number
    setTextColor = function(color) end,

    ---@return number
    getTextColor = function() end,

    ---@param color number
    setBackgroundColor = function(color) end,

    ---@return number
    getBackgroundColor = function() end,
}

bit = {
    ---@param n number
    ---@param bits number
    ---@return number
    blshift = function(n, bits) end,

    ---@param n number
    ---@param bits number
    ---@return number
    brshift = function(n, bits) end,

    ---@param n number
    ---@param bits number
    ---@return number
    blogic_rshift = function(n, bits) end,

    ---@param m number
    ---@param n number
    ---@return number
    bxor = function(m, n) end,

    ---@param m number
    ---@param n number
    ---@return number
    bor = function(m, n) end,

    ---@param m number
    ---@param n number
    ---@return number
    band = function(m, n) end,

    ---@param n number
    ---@return number
    bnot = function(n) end,
}