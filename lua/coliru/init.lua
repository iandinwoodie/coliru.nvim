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
  --return string.format("curl %s -d '%s'", url, json)
  return string.format(
      "curl %s --data-binary @%s --output %s", url, request_file, response_file)
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
    print(response)
  end

  local job_id = vim.fn.jobstart(request, {on_exit = event_slot})
  vim.fn.jobwait({job_id})
end

return coliru
