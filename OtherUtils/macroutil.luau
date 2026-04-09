local VirtualInputManager = game:GetService("VirtualInputManager")

local M = {}

type Key = string | Enum.KeyCode
type RealKey = { key: Key, needsShift: boolean }
type KeyInfo = { key: Key, triggerTime: number }

M.KEY_MAPPINGS = {
    ["0"] = Enum.KeyCode.Zero,
    ["1"] = Enum.KeyCode.One,
    ["2"] = Enum.KeyCode.Two,
    ["3"] = Enum.KeyCode.Three,
    ["4"] = Enum.KeyCode.Four,
    ["5"] = Enum.KeyCode.Five,
    ["6"] = Enum.KeyCode.Six,
    ["7"] = Enum.KeyCode.Seven,
    ["8"] = Enum.KeyCode.Eight,
    ["9"] = Enum.KeyCode.Nine,
    [" "] = Enum.KeyCode.Space,
    ["-"] = Enum.KeyCode.Minus,
    ["="] = Enum.KeyCode.Equals,
    ["["] = Enum.KeyCode.LeftBracket,
    ["]"] = Enum.KeyCode.RightBracket,
    ["\\"] = Enum.KeyCode.BackSlash,
    [";"] = Enum.KeyCode.Semicolon,
    ["'"] = Enum.KeyCode.Quote,
    [","] = Enum.KeyCode.Comma,
    ["."] = Enum.KeyCode.Period,
    ["/"] = Enum.KeyCode.Slash,
    ["`"] = Enum.KeyCode.Backquote,
}

M.SHIFT_MAPPINGS = {
    ["!"] = Enum.KeyCode.One,
    ["@"] = Enum.KeyCode.Two,
    ["#"] = Enum.KeyCode.Three,
    ["$"] = Enum.KeyCode.Four,
    ["%"] = Enum.KeyCode.Five,
    ["^"] = Enum.KeyCode.Six,
    ["&"] = Enum.KeyCode.Seven,
    ["*"] = Enum.KeyCode.Eight,
    ["("] = Enum.KeyCode.Nine,
    [")"] = Enum.KeyCode.Zero,
    ["_"] = Enum.KeyCode.Minus,
    ["+"] = Enum.KeyCode.Equals,
    ["{"] = Enum.KeyCode.LeftBracket,
    ["}"] = Enum.KeyCode.RightBracket,
    ["|"] = Enum.KeyCode.BackSlash,
    [":"] = Enum.KeyCode.Semicolon,
    ['"'] = Enum.KeyCode.Quote,
    ["<"] = Enum.KeyCode.Comma,
    [">"] = Enum.KeyCode.Period,
    ["?"] = Enum.KeyCode.Slash,
    ["~"] = Enum.KeyCode.Backquote,
}

function M:getProperKeyCode(key: string)
    if self.SHIFT_MAPPINGS[key] then
        return self.SHIFT_MAPPINGS[key], true
    end
    
    if self.KEY_MAPPINGS[key] then
        return self.KEY_MAPPINGS[key], false
    end

    if key:match("%u") then
        return Enum.KeyCode[key:upper()], true
    end

    return Enum.KeyCode[key:upper()], false
end

function M:sendKeyEvent(keyCode: Enum.KeyCode, isHeld: boolean)
    VirtualInputManager:SendKeyEvent(isHeld, keyCode, false, game)
end

function M:triggerKey(keyInfo: KeyInfo)
    local key = nil
    local needsShift = false
    
    if type(keyInfo.key) == "string" then
        key, needsShift = self:getProperKeyCode(keyInfo.key)
    else
        key = keyInfo.key
    end

    if not key then return end

    if needsShift then
        self:sendKeyEvent(Enum.KeyCode.LeftShift, true)
    end
    self:sendKeyEvent(key, true)

    task.wait(keyInfo.triggerTime)

    self:sendKeyEvent(key, false)
    if needsShift then
        self:sendKeyEvent(Enum.KeyCode.LeftShift, false)
    end
end

function M:triggerKeysSync(keys: {Key}, triggerTime: number)
    if #keys == 0 then
        return
    elseif #keys == 1 then
        self:triggerKey({ key = keys[1], triggerTime = triggerTime })
        return
    end

    local realKeys: { RealKey } = {}
    local hasShift = false
    for _, k in ipairs(keys) do
        local key = nil
        local needsShift = false
        
        if type(k) == "string" then
            key, needsShift = self:getProperKeyCode(k)
            if needsShift and not hasShift then
                hasShift = true
            end
        else
            key = k
        end

        table.insert(realKeys, { key = key, needsShift = needsShift })
    end

    for _, k in ipairs(realKeys) do
        if k.needsShift then
            self:sendKeyEvent(Enum.KeyCode.LeftShift, true)
        end

        self:sendKeyEvent(k.key, true)

        if k.needsShift then
            self:sendKeyEvent(Enum.KeyCode.LeftShift, false)
        end
    end

    task.wait(triggerTime)

    for _, k in ipairs(realKeys) do
        self:sendKeyEvent(k.key, false)
    end
    self:sendKeyEvent(Enum.KeyCode.LeftShift, false)
end

return M
