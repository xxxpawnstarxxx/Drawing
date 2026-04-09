function tprint(tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    local formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent + 1)
    else
      print(formatting .. tostring(v))
    end
  end
end

local M = {}
M.__index = M

export type ParsedSheet = {{string}}

function M.parse(sheet: string): ParsedSheet
    if not sheet or sheet == "" then
        return {{}}
    end
    
    local result: ParsedSheet = {{}}

    local i = 1
    local len = #sheet
    
    while i <= len do
        local curChar = sheet:sub(i, i)
        
        if curChar == "[" then
            i = i + 1 -- Move past the opening bracket
            
            -- Check for empty brackets []
            if i <= len and sheet:sub(i, i) == "]" then
                table.insert(result, {})
                i = i + 1 -- Move past the closing bracket
            else
                -- Parse bracketed content
                local bracketContent = {}
                
                while i <= len do
                    local char = sheet:sub(i, i)
                    
                    if char == "]" then
                        table.insert(result, bracketContent)
                        i = i + 1 -- Move past the closing bracket
                        break
                    end
                    
                    table.insert(bracketContent, char)
                    i = i + 1
                end
            end
        elseif curChar == " " then
            table.insert(result, {})
            i = i + 1
        else
            -- Regular character
            table.insert(result, { curChar })
            i = i + 1
        end
    end
    
    return result
end

return M
