local M = {}

---@class snacks.picker.scratch.FileKey
---@field id? string unique id to filter on
---@field cwd? boolean filter by current working directory
---@field branch? boolean filter by current git branch
---@field count? boolean filter by vim.v.count1

---@class snacks.picker.scratch.Config: snacks.picker.Config
---@field filekey? snacks.picker.scratch.FileKey filter scratch buffers by filekey fields

---@class snacks.scratch.actions
---@field [string] snacks.picker.Action.spec
M.actions = {
  scratch_open = function(picker, item)
    picker:close()
    if not item then
      return
    end
    Snacks.scratch.open({ icon = item.item.icon, file = item.item.file, name = item.item.name, ft = item.item.ft })
  end,
  scratch_delete = function(picker, item)
    local current = item.file
    os.remove(current)
    os.remove(current .. ".meta")
    picker:refresh()
  end,
  scratch_new = function(picker)
    picker:close()
    Snacks.scratch.open()
  end,
}

---@param opts snacks.picker.scratch.Config
---@type snacks.picker.finder
function M.scratch(opts)
  local list = Snacks.scratch.list()
  local filekey = opts.filekey
  local filter = {} ---@type {id?:string, cwd?:string, branch?:string, count?:number}
  if filekey then
    filter.id = filekey.id
    filter.count = filekey.count and vim.v.count1 or nil
    filter.cwd = filekey.cwd and vim.fs.normalize(assert(vim.uv.cwd())) or nil
    if filekey.branch and vim.uv.fs_stat(".git") then
      local out = vim.fn.system("git branch --show-current")
      filter.branch = vim.v.shell_error == 0 and out ~= "" and vim.trim(out) or nil
    end
  end

  ---@param item snacks.scratch.File
  local function matches(item)
    if not filekey then
      return true
    end
    for key, val in pairs(filter) do
      if item[key] ~= val then
        return false
      end
    end
    return true
  end

  local items = {} ---@type snacks.picker.finder.Item[]
  for _, item in ipairs(list) do
    if matches(item) then
      items[#items + 1] = {
        file = item.file,
        item = item,
        title = item.name,
        text = Snacks.picker.util.text(item, { "name", "branch", "ft" }),
        branch = item.branch and ("branch:%s"):format(item.branch) or "",
      }
    end
  end
  return items
end

---@type snacks.picker.format
function M.format(item, picker)
  local file = item.item
  local ret = {} ---@type snacks.picker.Highlight[]
  local a = Snacks.picker.util.align
  local icon, icon_hl = file.icon, nil
  if not icon then
    icon, icon_hl = Snacks.util.icon(file.ft, "filetype")
  end
  ret[#ret + 1] = { a(icon, 3), icon_hl }
  ret[#ret + 1] = { a(file.name, 20, { truncate = true }) }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { a(item.branch, 20, { truncate = true }), "Number" }
  ret[#ret + 1] = { " " }
  ---@diagnostic disable-next-line: missing-fields
  vim.list_extend(ret, Snacks.picker.format.filename({ text = "", dir = true, file = file.cwd }, picker))
  return ret
end

return M
