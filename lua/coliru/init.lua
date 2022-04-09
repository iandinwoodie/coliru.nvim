local request_file = "coliru_request.json"
local response_file = "coliru_response.json"
local languages = { cpp = 1, c = 1 }

local function build_request(src)
  local cmd = "g++-4.8 main.cpp && ./a.out"
  payload = {
      cmd = cmd,
      src = src,
  }
  local json = vim.json.encode(payload)
  local file = assert(io.open(request_file, "w"))
  file:write(json)
  io.close(file)

  local url = "http://coliru.stacked-crooked.com/compile"
  return string.format(
      "curl %s --data-binary @%s --output %s", url, request_file, response_file)
end

local function create_buf(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, lines)
  local time = os.date("*t")
  vim.api.nvim_buf_set_name(
      buf,
      string.format("%02d:%02d:%02d", time.hour, time.min, time.sec))
  return buf
end

local function display_result(lines)
  local output_buf = create_buf(lines)
  local prev_win_id = vim.fn.win_getid()
  vim.cmd("split")
  vim.cmd(("buffer " .. output_buf))
  vim.api.nvim_win_set_option(0, "number", false)
  vim.api.nvim_win_set_option(0, "relativenumber", false)
  vim.api.nvim_win_set_option(0, "spell", false)
  vim.api.nvim_win_set_option(0, "cursorline", false)
  return vim.api.nvim_set_current_win(prev_win_id)
end

local coliru = {}

function coliru.coliru()
  local ft = vim.bo.filetype
  if not languages[ft] then
    print("coliru: filetype \"%s\" not supported!", ft)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local src = vim.fn.join(lines, '\n')
  local request = build_request(src)

  local function event_slot(job_id, data, event)
    local file = io.open(response_file, "r")
    local response = file:read("*all")
    file:close()
    os.remove(request_file)
    os.remove(response_file)
    return display_result(vim.fn.split(response, '\n'))
  end

  return vim.fn.jobstart(request, {on_exit = event_slot})
end

return coliru
