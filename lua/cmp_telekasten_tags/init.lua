local Path = require("plenary.path")
local tagutils = require("taglinks.tagutils")

local function find_all_tags(params)
  local M = require("telekasten")
  local opts = {}
  opts.cwd = M.Cfg.home
  local templateDir = Path:new(M.Cfg.templates):make_relative(M.Cfg.home)
  opts.templateDir = templateDir
  opts.rg_pcre = M.Cfg.rg_pcre
  local tag_notations = params and params.tag_notations or { "#tag", "yaml-bare" }

  local tags = {}
  for _, tag_notation in ipairs(tag_notations) do
    opts.tag_notation = tag_notation
    local results = tagutils.do_find_all_tags(opts)
    for tag, locations in pairs(results) do
      if tag:len() ~= 0 then
        local count = 0
        for _ in pairs(locations) do count = count + 1 end
        if tags[tag] ~= nil then
          count = tags[tag].count + count
        end
        tags[tag] = {
          label = tag,
          sortText = "-" .. count .. "-" .. tag,
          count = count,
          detail = count .. " uses",
          kind = 1,
        }
      end
    end
  end
  local tagList = {}
  for _, info in pairs(tags) do
    table.insert(tagList, info)
  end
  return tagList
end

local source = {}
source.new = function()
  return setmetatable({}, { __index = source })
end

---Return whether this source is available in the current context or not (optional).
---@return boolean
function source:is_available()
  return vim.o.filetype == "telekasten" or vim.o.filetype == "zettelkasten"
end

---Return the debug name of this source (optional).
---@return string
function source:get_debug_name()
  return "telekasten_tags"
end

---Return the keyword pattern for triggering completion (optional).
---If this is ommited, nvim-cmp will use a default keyword pattern. See |cmp-config.completion.keyword_pattern|.
---@return string
-- function source:get_keyword_pattern()
--   return [[\k\+]]
-- end

---Return trigger characters for triggering completion (optional).
-- function source:get_trigger_characters()
--   return { '.' }
-- end

---Invoke completion (required).
---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
function source:complete(params, callback)
  local tags = find_all_tags(params)
  if #tags > 0 then
    callback(find_all_tags(params))
  else
    callback()
  end
end

---Resolve completion item (optional). This is called right before the completion is about to be displayed.
---Useful for setting the text shown in the documentation window (`completion_item.documentation`).
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
-- function source:resolve(completion_item, callback)
--   callback(completion_item)
-- end

---Executed after the item was selected.
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:execute(completion_item, callback)
  callback(completion_item)
end

return source
