local vimslime = {}

vimslime.state = {
  target_pane = nil
}

vimslime.set_target_pane = function (pane)
  vimslime.state.target_pane = pane
end

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

vimslime.get_target_pane = function ()
  if vimslime.state.target_pane then
    return vimslime.state.target_pane
  end

  local guessed_target_pane = guess_target_pane()
  vimslime.set_target_pane(guessed_target_pane)
  return guessed_target_pane
end

local clamp_column_to_line = function(line, column)
  column = column >= 0 and column or 0
  column = column < #line and column or #line-1
  return column
end

local get_selected_text = function ()
  local buffer = vim.api.nvim_get_current_buf()
  local sel_start = vim.api.nvim_buf_get_mark(buffer, '<')
  local sel_start_line = sel_start[1]
  local sel_end = vim.api.nvim_buf_get_mark(buffer, '>')
  local sel_end_line = sel_end[1]
  local lines = vim.api.nvim_buf_get_lines(buffer, sel_start_line-1, sel_end_line, true)
  local sel_start_column = sel_start[2]
  local sel_end_column = sel_end[2]
  sel_start_column = clamp_column_to_line(lines[1], sel_start_column)
  sel_end_column = clamp_column_to_line(lines[#lines], sel_end_column)
  local selection = ''
  for line_i = 1, #lines do
    if line_i == 1 then
      selection = selection..(lines[1]:sub(sel_start_column+1, sel_start_line == sel_end_line and sel_end_column+1 or #lines[1]))
    elseif line_i == #lines then
      selection = selection..'\n'..(lines[#lines]:sub(0, sel_end_column))
    else
      selection = selection..'\n'..lines[line_i]
    end
  end
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

vimslime.paste = {}
vimslime.paste.text = function (text)
  local text = text or get_selected_text()
  local escaped_text = escape(text)
  local commands = {
    'tmux set-buffer -b vimslime -- "'..tostring(escaped_text)..'"',
    'tmux paste-buffer -d -b vimslime -t '..tostring(vimslime.get_target_pane())
  }
  run_commands(commands)
end

vimslime.paste.python = function (text)
  local text = text or get_selected_text()
  vimslime.paste.text('%cpaste\n')
  vimslime.paste.text(tostring(text)..'\n')
  vimslime.paste.text('--\n')
end

return vimslime
