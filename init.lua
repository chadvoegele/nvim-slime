local M = {}

M.state = {
  target_pane = nil
}

M.set_target_pane = function (pane)
  M.state.target_pane = pane
end

local CONSTANTS = {
  visual = 'visual',
  visual_line = 'visual_line',
  visual_block = 'visual_block'
}

-- list_panes_text is output of 'tmux list-panes -a'
local get_current_tmux_pane_id = function (list_panes_text, tmux_pane_id)
  local tmux_pane_pattern = string.gsub(tmux_pane_id, '%%', '%%%%')  -- escape nightmare
  for l in string.gmatch(list_panes_text, '[^\n]+') do
    if string.find(l, tmux_pane_pattern) then
      local pane_id = string.sub(l, 0, string.find(l, ' ')-1)
      local sessid, winid, paneid = string.match(pane_id, '(.+):(%d+).(%d+):')
      return sessid, winid, paneid
    end
  end
end

-- Guess is other pane in current window.
local guess_target_pane = function ()
  local proc = assert(io.popen('tmux list-panes -a'))
  local pane_text = proc:read('*a')
  proc:close()

  local tmux_pane_env = os.getenv('TMUX_PANE')
  if not tmux_pane_env then
    return
  end

  local sessid, winid, paneid = get_current_tmux_pane_id(pane_text, tmux_pane_env)
  local guessed_target_pane = sessid..':'..winid..'.'..math.floor(1-paneid)
  return guessed_target_pane
end

local get_target_pane = function ()
  if M.state.target_pane then
    return M.state.target_pane
  end

  local guessed_target_pane = guess_target_pane()
  M.set_target_pane(guessed_target_pane)
  return guessed_target_pane
end

local get_buffer_lines = function (start_line, end_line)
  local buffer = vim.api.nvim_get_current_buf()
  local buffer_lines = vim.api.nvim_buf_get_lines(buffer, start_line-1, end_line, true)
  return buffer_lines
end

local vim_api_ext = {
  visualmode = function ()
    return vim.api.nvim_eval('visualmode()')
  end,
  get_filetype = function ()
    return vim.api.nvim_eval('&filetype')
  end
}

local map_visual_mode = function (visual_mode_char)
  if visual_mode_char == 'v' then
    return CONSTANTS.visual
  elseif visual_mode_char == 'V' then
    return CONSTANTS.visual_line
  elseif visual_mode_char == string.char(22) then   -- 22 is code for ^V, i.e. visual block mode
    return CONSTANTS.visual_block
  end
end

local get_last_visual_mode = function ()
  local last_visual_mode_char = vim_api_ext.visualmode()
  local last_visual_mode = map_visual_mode(last_visual_mode_char)
  return last_visual_mode
end


local join_table = function (table, sep)
  local sep = sep or '\n'
  local result = ''
  for k,v in pairs(table) do
    result = result..v..sep
  end
  return result
end

local get_selected_text = function (visual_mode)
  local visual_mode = visual_mode or get_last_visual_mode()
  local buffer = vim.api.nvim_get_current_buf()
  local sel_start, sel_end = vim.api.nvim_buf_get_mark(buffer, '<'), vim.api.nvim_buf_get_mark(buffer, '>')
  local sel_start_line, sel_end_line = sel_start[1], sel_end[1]
  local sel_start_column, sel_end_column = sel_start[2], sel_end[2]
  local lines = get_buffer_lines(sel_start_line, sel_end_line)
  if visual_mode == CONSTANTS.visual then
    lines[1] = lines[1]:sub(sel_start_column+1)
    lines[#lines] = lines[#lines]:sub(1, sel_start_line == sel_end_line and sel_end_column-sel_start_column+1 or sel_end_column+1)
  elseif visual_mode == CONSTANTS.visual_block then
    for k,v in pairs(lines) do
      lines[k] = lines[k]:sub(sel_start_column+1, sel_end_column+1)
    end
  end
  local selection = join_table(lines)
  return selection
end

local escape = function (text)
  return text:gsub('"', '\\"'):gsub('[$]', '\\$')
end

local run_commands = function (commands)
  for _,command in ipairs(commands) do
    cmdexit = os.execute(command)
    if not cmdexit then
      return
    end
  end
end

M.paste = {}
M.paste.text = function (text)
  local text = text or get_selected_text()
  local escaped_text = escape(text)
  local commands = {
    'tmux set-buffer -b vimslime -- "'..tostring(escaped_text)..'"',
    'tmux paste-buffer -d -b vimslime -t '..tostring(get_target_pane())
  }
  run_commands(commands)
end

M.paste.python = function (text)
  local text = text or get_selected_text()
  M.paste.text('%cpaste\n')
  M.paste.text(tostring(text)..'\n')
  M.paste.text('--\n')
end

return M
