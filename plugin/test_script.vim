"TODO Banged commands and functions.

" Know issues:
"       1) Cannot yet handle moving windows around.



" ---------- Customisable values

" modes in which plugin operates. The following modes are supported:

"   fullauto - add a buffer to a window if 
"              the buffer is entered from this window.
"   halfman  - add a buffer to a window if
"              the new buffer is created from this window.
"   fullman  - add a buffer to a window if
"              user directly asks for that.
let s:wintab_mode               = get(g:, "wintab_mode", "fullauto")

" whether need to go to newly opened tab, or
" remain at the current one. 0 - no, non-0 - yes.
let s:wintab_go_to_new_tab      = get(g:, "wintab_go_to_new_tab", 0)

" whether need to catch layout upon Vim startup.
" 0 - no, non-0 - yes.
let s:wintab_vim_startup        = get(g:, "wintab_vim_startup", 0)

" how borders of every tab would look like.
" need to be a string.
let s:wintab_tab_left_border    = get(g:, "wintab_tab_left_border",  "<<")
let s:wintab_tab_right_border   = get(g:, "wintab_tab_right_border", ">>")

" width of space between tabs.
" you can make it negative, of course, but what's the point?
let s:wintab_tab_space          = get(g:, "wintab_tab_space", 1)

" how blank tabs (that shows that there are other tabs
" to the left or right of the bar that do not fit into it)
" would look like.
let s:wintab_tab_blank          = get(g:, "wintab_tab_blank", "...")

" highlighting for different tabs
let s:wintab_tab_hi_regular     = get(g:, "wintab_tab_hi_regular",  "Pmenu")
let s:wintab_tab_hi_selected    = get(g:, "wintab_tab_hi_selected", "PmenuSel")
let s:wintab_tab_hi_blank       = get(g:, "wintab_tab_hi_blank",    "Pmenu")

" time in milliseconds when data structures will be updated
" and tabs redrawn after HandleWinResize() is called.
" cannot resize without timer as Vim updates info about some
" windows with delay so it is hard to catch with au.
let s:wintab_resize_timer       = get(g:, "wintab_resize_timer", 20)



" ---------- User Interface

function s:SetCommands()
    " Add / delete windows.
    :command -nargs=? VWTAddWindow call <SID>AddWin(<f-args>)
    :command -nargs=? VWTDelWindow call <SID>DelWin(<f-args>)

    " Add / delete bufs.
    :command -nargs=* VWTAddBufToTabBar call <SID>AddBufToTabBar(<f-args>)
    :command VWTDeleteCurTabFromBar     call <SID>DeleteCurTabFromBar()

    " Change display of tab bars.
    :command VWTShowCurTabBar call <SID>HideShowTabBar(win_getid(), function("popup_show"))
    :command VWTHideCurTabBar call <SID>HideShowTabBar(win_getid(), function("popup_hide"))

    :command VWTShowAllTabBars call <SID>HideShowAllTabBars(function("popup_show"))
    :command VWTHideAllTabBars call <SID>HideShowAllTabBars(function("popup_hide"))

    :command -nargs=? VWTToggleTabBar call <SID>ToggleTabBar(<f-args>)
    :command VWTToggleAllTabBars      call <SID>ToggleAllTabBars()

    " Move around a tab bar.
    :command VWTSlideLeft  call <SID>SlideTabsBar(win_getid(), s:wintab_slide_left)
    :command VWTSlideRight call <SID>SlideTabsBar(win_getid(), s:wintab_slide_right)
    :command VWTGoTabLeft  call <SID>MoveCurTab(win_getid(), s:wintab_slide_left)
    :command VWTGoTabRight call <SID>MoveCurTab(win_getid(), s:wintab_slide_right)

    " Change plugin values.
    :command -nargs=1 VWTChangeMode call <SID>ChangeMode(<f-args>)

    " Reset plugin.
    :command VWTReset call <SID>Reset()

    " Disable the plugin.
    :command VWTDisable call <SID>Disable()

    " Redraw tab bars.
    :command VWTRedraw  call <SID>Redraw()
endfunction
" Enable the plugin if it is disabled.
:command VWTEnable  call <SID>Enable()
eval <SID>SetCommands()



" ---------- Main Datastructures

" contains currently opened windows
let s:wins_open = {}

" contains parameters of windows
" key - winid, value - list of the parameters below.
let s:wins_info = {}
function s:InitWinsInfoValue()
    return  {   "x":    0,
            \   "y":    0,
            \   "w":    0,
            \   "h":    0, }
endfunction

" contains info about buffers associated with each window
" key - winid, value - another dict, that has bufnr as key
"                      and tabid as value
let s:wins_bufs = {}
function s:InitWinsBufsValue()
    return {}
endfunction

" contains tabs info for a given window.
" key - winid, value - another dict with the values below.
let s:wins_tabs = {}
function s:InitWinsTabsValue()
    echom "    Entering InitWinsTabsValue"
    return  {   "tabs_ids":     [], 
            \   "tabline_w":    0,
            \   "firsttab":     0,
            \   "lasttab":      -1,
            \   "firstblank":   0, 
            \   "lastblank":    0,    
            \   "curtab":       0, }
endfunction

" contains info about windows associated with each buffer
" key - bufnr, value - another dict, that has winid as key
"                      and value of 0 for each window
let s:bufs_wins = {}
function s:InitBufsWinsValue()
    return {}
endfunction



" ---------- Internal Controls

" value needed to delete closed windows from data structures.
let s:prev_win_id = -1

" values to determine direction of tab bar movements.
let s:wintab_slide_left  = -1
let s:wintab_slide_right = 1

" value to determine if the autocommands should be loaded. Set to 0 if the
" user wants to disable the plugin.
let s:wintab_load_au = 1

" non-0 if plugin is disabled. 0 if operational.
let s:wintab_plugin_disabled = 0

" ---------- In case you want to read the code

" Welcome to the code section, adventurer. Before you start,
" there are a few things I need to tell you to comfort your
" journey:
"   1) + 0 everywhere is me being paranoid about values not
"   being integers (this casts strings to ints);
"   2) Vim does not let you know the types of different
"   windows upon their creation reliably. That means that
"   when WinNew event fires, there is a chance that newly
"   created window doesn't have a correct type that you can
"   check. So windows are firstly added, and then either
"   confirmed, or deleted from datastructures;
"   3) No events to catch resize and changes of layout (say
"   switching windows), so handing that is a huge workaround. 



" ---------- General Helpers

function s:RemoveDictListItem(dict, key, item)
    echom "    RemoveDictListItem"
    if !has_key(a:dict, a:key)
        return 1
    endif

    let i_list  = a:dict[a:key]
    let idx     = index(i_list, a:item)
    if -1 == idx
        echom "Return from RDLI() - idx"
        return 2
    endif

    eval remove(i_list, idx)
    if empty(i_list)
        eval remove(a:dict, a:key)
    endif

    return 0
endfunction

function s:RemoveDictDictItem(dict, key, item)
    echom "    RemoveDictDictItem"
    if !has_key(a:dict, a:key)
        return 1
    endif

    let i_dict          = a:dict[a:key]
    if !has_key(i_dict, a:item)
        echom "Return from RemoveDictDictItem() - idx"
        return 2
    endif

    eval remove(i_dict, a:item)
    "if empty(i_dict)
    "    eval remove(a:dict, a:key)
    "endif

    return 0
endfunction

function s:ProcessExecutedCmd(matches, Callback)
    echom "    Entering ProcessExecutedCmd"
    let cmd = getcmdline()
    echom "Command is" cmd

    for m in a:matches
        if matchstr(cmd, m) != ""
            eval a:Callback()
            return 0
        endif  
    endfor

    return 1
endfunction

function s:CorrectBufAndWinTypes(bufnr, winid)
    echom "    Entering CorrectBufAndWinTypes"
    let bufnr   = a:bufnr + 0
    let winid   = a:winid + 0

    let wt      = win_gettype(winid)
    let bt      = getbufvar(bufnr, "&buftype")
    
    let wi          = getwininfo(winid)[0]
    let is_terminal = wi.terminal
    let is_quickfix = wi.quickfix
    let is_loclist  = wi.loclist
    let is_ft_qf    = 0
    if exists("#filetype")
       let ft = &filetype
       if ft ==? "qf"
           let is_ft_qf = 1
       endif
    let bufname = bufname(bufnr)
    echom "Bufname is" bufname
    
    echom "WT - " wt "BT - " bt is_terminal is_quickfix is_loclist is_ft_qf

    if wt !=? "" || bt !=? "" || is_terminal || is_quickfix || is_loclist 
                \|| is_ft_qf || !buflisted(bufnr)
        echom "Incorrect buf of win types - winid" winid ", bufnr" bufnr
        return 0
    else
        return 1
    endif
endfunction

function s:ChangeMode(how)
    let s:wins_open = {} 
    let s:wins_info = {} 
    let s:wins_bufs = {} 
    let s:wins_tabs = {} 
    let s:bufs_wins = {} 

    let s:wintab_mode               = get(a:how, "mode",            s:wintab_mode)
    let s:wintab_go_to_new_tab      = get(a:how, "new_tab",         s:wintab_go_to_new_tab)
    let s:wintab_tab_left_border    = get(a:how, "left_b",          s:wintab_tab_left_border)
    let s:wintab_tab_right_border   = get(a:how, "right_b",         s:wintab_tab_right_border)
    let s:wintab_tab_space          = get(a:how, "tab_space",       s:wintab_tab_space)
    let s:wintab_tab_blank          = get(a:how, "tab_blank",       s:wintab_tab_blank)
    let s:wintab_tab_hi_regular     = get(a:how, "tab_hi_r",        s:wintab_tab_hi_regular)
    let s:wintab_tab_hi_selected    = get(a:how, "tab_hi_s",        s:wintab_tab_hi_selected)
    let s:wintab_tab_hi_blank       = get(a:how, "tab_hi_b",        s:wintab_tab_hi_blank)
    let s:wintab_resize_timer       = get(a:how, "resize_timer",    s:wintab_resize_timer)

    eval popup_clear()    
    eval <SID>AutogroupSetter()
    eval <SID>HandleVimStartup() 
    return 0
endfunction

function s:Disable()
    unlet s:wins_open 
    unlet s:wins_info 
    unlet s:wins_bufs 
    unlet s:wins_tabs 
    unlet s:bufs_wins 

    let s:wintab_load_au = 0
    eval <SID>AutogroupSetter()
    eval <SID>DeleteCommands()
    eval popup_clear()

    let s:wintab_plugin_disabled = 1
endfunction

function s:Reset()
    call <SID>ChangeMode( {} )
endfunction

function s:Enable()
    if !s:wintab_plugin_disabled
        return
    endif

    call <SID>ChangeMode( {} )
    call <SID>SetCommands()
    let s:wintab_plugin_disabled = 0
endfunction

function s:Redraw()
    call <SID>HandleWinResize()
endfunction

function s:DeleteCommands()
    delc VWTAddWindow
    delc VWTDelWindow
    delc VWTAddBufToTabBar
    delc VWTDeleteCurTabFromBar
    delc VWTShowCurTabBar
    delc VWTHideCurTabBar
    delc VWTShowAllTabBars
    delc VWTHideAllTabBars
    delc VWTToggleTabBar
    delc VWTToggleAllTabBars     
    delc VWTSlideLeft 
    delc VWTSlideRight
    delc VWTGoTabLeft 
    delc VWTGoTabRight
    delc VWTChangeMode
    delc VWTReset
    delc VWTDisable
    delc VWTRedraw 
endfunction



" ---------- Windows

" Helpers
function s:GetWinInfo(winid)
    echom "Entering GetWinInfo"

    let winid    = a:winid + 0
    let ret      = <SID>InitWinsInfoValue()
    let winpos   = win_screenpos(winid)
    let ret["x"] = winpos[1]
    let ret["y"] = winpos[0]
    let ret["w"] = winwidth(winid)
    let ret["h"] = winheight(winid)

    return ret 
endfunction

function s:UpdateCurWinInfo()
    echom "    Entering UpdateCurWinInfo"
    let cur_win_id  = win_getid() + 0
    
    let s:wins_info[cur_win_id] = <SID>GetWinInfo(cur_win_id)
    echom "Win info is" s:wins_info[cur_win_id]
endfunction

function s:WinNrToId(index, winnr)
    echom "    Entering WinNrToId"
    let winid   = win_getid(a:winnr) + 0
    let ret     = ""
    if winid != 0
        let ret = winid 
    endif
    return ret + 0
endfunction

" Add a window
function s:HandleWinAddition(winid, where)
    let winid   = a:winid + 0
    if a:where["open"] 
        let s:wins_open[winid] = 1 
    endif
    if a:where["info"] 
        let s:wins_info[winid] = <SID>GetWinInfo(winid)
    endif
    if a:where["bufs"] 
        let s:wins_bufs[winid] = <SID>InitWinsBufsValue()
    endif
    if a:where["tabs"] 
        let s:wins_tabs[winid] = <SID>InitWinsTabsValue()
    endif
endfunction

" If the type of a window or a buffer is wrong, the window is still
" added to wins_open and wins_info structs, as the window's dimensions
" are still needed to position other tab bars correctly on the screen.
" Addition to wins_bufs and wins_tabs could be false positive as Vim
" doesn't provide a reliable way to check the window's type upon its
" creation.
function s:HandleNewWindow(winid)
    echom "    Entering HandleNewWindow"

    let winid   = a:winid + 0
    eval <SID>EchoAllWinInfo(winid)
    if has_key(s:wins_open, winid)
        echom "Window is already opened!"
        return 1
    endif

    let wi      = getwininfo(winid)[0]
    let bufnr   = wi.bufnr + 0
    let win_add_info = {"open":1, "info":1, "bufs":0, "tabs":0}
    if <SID>CorrectBufAndWinTypes(bufnr, winid)
        echom "Probably correct types."
        let win_add_info["bufs"] = 1
        let win_add_info["tabs"] = 1
    endif

    eval <SID>HandleWinAddition(winid, win_add_info)
    eval <SID>HandleWinResize() 
    return 0
endfunction

function s:AddWin(...)
    let winid = get(a:000, 0, win_getid())
    eval <SID>HandleNewWindow(winid)
endfunction

function s:HandleVimStartup()
    echom "    Entering HandleVimStartup"
    let w_list     = map(range(1, winnr('$')), function("<SID>WinNrToId")) 
    echom w_list
    let cur_win_id = win_getid() + 0
    for w in w_list
        if win_gotoid(w)
            eval <SID>HandleNewWindow(w)
            eval <SID>HandleBufAddition(winbufnr(w), w)
        endif
    endfor 
    eval win_gotoid(cur_win_id)
    let s:prev_win_id = cur_win_id
endfunction

" Delete a window
" If the plugin finds that the type of newly added window is wrong,
" it will delete such a window from wins_bufs and wins_tabs structs.
function s:HandleWinDeletion(winid, what)
    echom "    Entering HandleWinDeletion"
    let winid   = a:winid + 0
    " let w_tabs  = s:wins_tabs[winid]
    eval <SID>EchoAllWinInfo(winid)

    if a:what["bufs"]+0 && a:what["tabs"]+0 && has_key(s:wins_bufs, winid)
        let bufs_list   = s:wins_bufs[winid]
        for [b, i] in items(bufs_list)
            eval <SID>RemoveBufFromWin(b, winid)
        endfor 
        "if empty(bufs_list) && has_key(s:wins_bufs, winid)
        if has_key(s:wins_bufs, winid)
            eval remove(s:wins_bufs, winid)
        endif
        if has_key(s:wins_tabs, winid)
            eval remove(s:wins_tabs, winid)
        endif
    endif

    if a:what["open"]+0 && a:what["info"]+0 && has_key(s:wins_open, winid)
        eval remove(s:wins_open, winid)
        eval remove(s:wins_info, winid)
    endif
    
    if a:what["resize"]
        eval <SID>HandleWinResize()
    endif
endfunction

function s:DelWin(...)
    let winid = get(a:000, 0, win_getid())
    eval <SID>HandleWinDeletion(winid, 
                \ {"open":1,"info":1,"bufs":1,"tabs":1,"resize":0} )
endfunction

" This will fire after a window is added and will check if the window
" or buffer are of correct types, and delete them if not. As the window 
" is still displayed, it is not deleted from wins_bufs and wins_tabs as
" its dimensions are taken into account when tab bars at other windows are
" positioned on the screen.
function s:HandleWrongWin()
    echom "    Entering HandleWrongWin"
    let cur_win_id  = win_getid() + 0
    eval <SID>EchoAllWinInfo(cur_win_id)
    let wi          = getwininfo(cur_win_id)[0]
    let bufnr       = wi.bufnr + 0
    if has_key(s:wins_open, cur_win_id) &&
       \ !<SID>CorrectBufAndWinTypes(bufnr, cur_win_id)

        echom "Not a regular window or buffer!"
        let win_del_info = {"open":0, "info":0, "bufs":1, "tabs":1, "resize":0}
        eval <SID>HandleWinDeletion(cur_win_id, win_del_info)
        if has_key(s:bufs_wins, bufnr) && empty(s:bufs_wins[bufnr])
            eval remove(s:bufs_wins, bufnr)
        endif
        return 1
    endif
    return 0
endfunction

" Control a window

" No WinDeleted event, so simulating it with prev_win_id global variable.
" If the window with this id is no more, then delete it from structs and
" resize.
function s:HandleWinLeaving()
    echom "    Entering HandleWinLeaving"

    let need_to_resize = 0

    if s:prev_win_id != -1 && empty(getwininfo(s:prev_win_id))
       echom "Window deleted -" s:prev_win_id
       eval <SID>EchoAllWinInfo(s:prev_win_id)
       let win_del_info = {"open":1, "info":1, "bufs":1, "tabs":1, "resize":1}
       eval <SID>HandleWinDeletion(s:prev_win_id, win_del_info)
       let need_to_resize = 1
    endif
    echom "HandleWinLeaving - after if"

    let s:prev_win_id = win_getid() + 0
endfunction

" Sometimes Vim doesn't know updated dimensions of windows after some
" types of windows are deleted (after command window is closed, for example,
" dimensions are not updated timely, and after quickfix is they are updated 
" with incorrect heights. So deferring resizing until better times.
function s:HandleWinResize()
    echom "    Entering HandleWinResize"
    eval timer_start(s:wintab_resize_timer, function("<SID>ResizeUponTimer"))
endfunction

" Main resize function. It also cleans garbage info left from closed windows
" (if any).
function s:ResizeUponTimer(timer_id)
    echom "    Entering ResizeUponTimer"
    " screw the timer id, ahaha

    for [k, v] in items(s:wins_info)
        eval <SID>EchoAllWinInfo(k)
        let new_w_info = <SID>GetWinInfo(k+0)
        echom v
        echom new_w_info
        if new_w_info["w"] == -1 || new_w_info["h"] == -1
            let win_del_info = {"open":1,"info":1,"bufs":1,"tabs":1,"resize":0}
            eval <SID>HandleWinDeletion(k, win_del_info)
        elseif new_w_info != v
            echom "Lists are not the same!"
            let s:wins_info[k]  = new_w_info
            if has_key(s:wins_tabs, k)
                let w_tabs  = s:wins_tabs[k]
                let cur_t   = w_tabs["curtab"]
                let max     = len(w_tabs["tabs_ids"])-1
                let first_t = w_tabs["firsttab"]
                let blank_l = 0
                if w_tabs["firstblank"] != 0
                    let blank_l += len(s:wintab_tab_blank)
                endif
                if w_tabs["lastblank"] != 0
                    let blank_l += len(s:wintab_tab_blank)
                endif
                let cur_w   = blank_l
                let recalc  = <SID>CalculateNewFirstTab(k, cur_t, first_t, cur_w)
                let first_t = recalc[0]
                let cur_w   += recalc[1]
                let last_t  = <SID>CalculateNewLastTab(k, cur_t+1, max, cur_w)[0]
                eval <SID>HandleTabsRedraw(k, first_t, last_t)
            endif
        endif
    endfor
endfunction



" ---------- Buffers

" Adding a buffer
function s:HandleBufAddition(bufnr, winid)
    echom "    Entering HandleBufAddition"
    let bufnr = a:bufnr + 0
    let winid = a:winid + 0

    if !has_key(s:wins_open, winid)
        echom "Window" winid "is not opened."
        return 1
    endif
    eval <SID>EchoAllWinInfo(winid)
    
    if !has_key(s:wins_bufs, winid)
        echom "Window" winid "canot have associated buffers!"
        return 2
    endif

    if has_key(s:wins_bufs[winid], bufnr)
        echom "Bufnr" bufnr "is already added to" winid "win."
        return 3
    endif

    if !<SID>CorrectBufAndWinTypes(bufnr, winid) 
        return 4
    endif

    if 0 == <SID>AddBufToWin(bufnr, winid)
        eval <SID>HandleNewTab(bufnr, winid)
    else
        return 5
    endif

    return 0
endfunction

function s:AddBufToWin(bufnr, winid)
    echom "    Entering AddBufToWin"

    let bufnr = a:bufnr + 0
    let winid = a:winid + 0

    if bufnr == -1 || winid == 0
        return 1
    endif
    eval <SID>EchoAllWinInfo(winid)

    if !has_key(s:wins_bufs, winid)
        echom "New list in wins_bufs"
        let s:wins_bufs[winid] = {}
    endif

    let cur_win_buf_dict    = s:wins_bufs[winid]

    if !has_key(cur_win_buf_dict, bufnr)
        let cur_win_buf_dict[bufnr] = -1
        if !has_key(s:bufs_wins, bufnr)
            let s:bufs_wins[bufnr] = {}
        endif
        let cur_buf_win_dict        = s:bufs_wins[bufnr]
        let cur_buf_win_dict[winid] = 0
        echom cur_win_buf_dict
        echom cur_buf_win_dict
    else
        return 2
    endif

    return 0
endfunction

" If you add a buffer to a window from another window in fullauto mode,
" the current buffer of the window you are adding the buffer into will
" be added to the window you are adding the buffer from, as it is visited
" by Vim, so the event is triggered. Other modes do not have this behaviour. 
function s:AddBufToTabBar(...)
    if len(a:000) > 2
        return 1
    endif

    let winid = get(a:000, 1, win_getid())
    if !has_key(s:wins_open, winid)
        return 2
    endif

    let bufnr = get(a:000, 0, getwininfo(winid)[0].bufnr)

    eval <SID>HandleBufAddition(bufnr, winid)
endfunction

" Deleting a buffer
function s:HandleBufDeletion(bufnr, winid)
    echom "    Entering HandleBufDeletion"
    let bufnr = a:bufnr + 0
    let winid = a:winid + 0
    if bufnr == -1 || winid == 0
        return
    endif
    eval <SID>EchoAllWinInfo(winid)
   
    let w_tabs = s:wins_tabs[winid] 
    eval <SID>RemoveBufFromWin(bufnr, winid)
    echom s:wins_tabs[winid]

    let n_first = w_tabs["firsttab"]
    let n_last  = <SID>CalculateNewLastTab(winid, n_first, 
                    \ len(w_tabs["tabs_ids"])-1,0)[0]
    eval <SID>HandleTabsRedraw(winid, n_first, n_last)
endfunction

function s:RemoveBufFromWin(bufnr, winid)
    echom "    Entering RemoveBufFromWin"
    let bufnr = a:bufnr + 0
    let winid = a:winid + 0
    if bufnr == -1 || winid == 0
        return
    endif
    eval <SID>EchoAllWinInfo(winid)
    eval <SID>HandleTabDeletion(bufnr, winid)

    eval <SID>RemoveDictDictItem(s:wins_bufs, winid, bufnr)
    eval <SID>RemoveDictDictItem(s:bufs_wins, bufnr, winid)

    if has_key(s:bufs_wins, bufnr) && empty(s:bufs_wins[bufnr])
        eval remove(s:bufs_wins, bufnr)
    endif

endfunction

function s:HandleBufWipeout(bufnr)
    echom "    Entering HandleBufWipeout"
    let bufnr = a:bufnr + 0
    eval <SID>DeleteBufFromAllWins(bufnr)
endfunction

function s:DeleteBufFromAllWins(bufnr)
    echom "    Entering DeleteBufFromAllWins"
    let bufnr = a:bufnr + 0
    if bufnr == -1 || !has_key(s:bufs_wins, bufnr)
        return
    endif

    let w_dict = s:bufs_wins[bufnr]
    for [w, lala] in items(w_dict)
        eval <SID>EchoAllWinInfo(w)
        eval <SID>HandleBufDeletion(bufnr, w)    
    endfor
endfunction

" Control buffers
function s:HandleCTRLOCTRLI()
    echom "    Entering HandleCTRLOCTRLI"
    let cur_win_id  = win_getid() + 0
    let wi          = getwininfo(cur_win_id)[0]
    let bufnr       = wi.bufnr + 0
    if has_key(s:wins_bufs, cur_win_id) && 
     \ has_key(s:wins_bufs[cur_win_id], bufnr)
        echom "Buffer no" bufnr "is already added to the window" cur_win_id "."
        eval <SID>HandleCurTabChange(index(s:wins_tabs[cur_win_id]["tabs_ids"],
                    \ s:wins_bufs[cur_win_id][bufnr]), cur_win_id)
        return 1
    endif
    return 0
endfunction



" ---------- Tabs

" Helpers
" CalculateNew... functions return a list, where the first index is for a new
" position, and the second one is for a width from an anchor point till new
" position.
function s:CalculateNewFirstTab(winid, lasttab, min_first, start_cur_w)
    echom "    Entering CalculateNewFirstTab"
    let winid    = a:winid
    let w_tabs   = s:wins_tabs[winid]
    let tabs_l   = w_tabs["tabs_ids"]

    let tabs_len = len(tabs_l)
    
    if tabs_len == 0
        return
    endif

    let lasttab  = a:lasttab + 0
    let max_w    = s:wins_info[winid]["w"]

    let cur_w    = a:start_cur_w + 0
    let firsttab = lasttab
    let min_f    = a:min_first + 0
    while cur_w <= max_w && firsttab >= min_f
        echom cur_w max_w
        echom firsttab
        let cur_w    += (popup_getpos(tabs_l[firsttab]).width+s:wintab_tab_space)
        let firsttab -= 1 
    endwhile
    
    echom cur_w max_w
    echom firsttab
    let firsttab += 1
    if cur_w > max_w
        let cur_w    -= (popup_getpos(tabs_l[firsttab]).width+s:wintab_tab_space)
        let firsttab += 1
    endif
    echom firsttab
    return [firsttab, cur_w]
endfunction

function s:CalculateNewLastTab(winid, firsttab, max_last, start_cur_w)
    echom "    Entering CalculateNewLastTab"
    let winid    = a:winid
    let w_tabs   = s:wins_tabs[winid]
    let tabs_l   = w_tabs["tabs_ids"]
    let tabs_len = len(tabs_l)
    
    if tabs_len == 0
        return
    endif

    let firsttab = a:firsttab + 0
    let max_w    = s:wins_info[winid]["w"]

    let cur_w    = a:start_cur_w + 0
    let lasttab  = firsttab
    let max_l    = a:max_last + 0
    while cur_w <= max_w && lasttab <= max_l
        echom cur_w max_w
        echom lasttab
        let cur_w   += (popup_getpos(tabs_l[lasttab]).width + s:wintab_tab_space)
        let lasttab += 1 
    endwhile
    
    echom cur_w max_w
    echom lasttab
    let lasttab -= 1
    if cur_w > max_w
        let cur_w   -= (popup_getpos(tabs_l[lasttab]).width + s:wintab_tab_space)
        let lasttab -= 1
    endif

    echom lasttab
    return [lasttab, cur_w]
endfunction

" Create and add a tab
function s:HandleNewTab(bufnr, winid)
    echom "    Entering HandleNewTab"
    let winid   = a:winid + 0
    let bufnr   = a:bufnr + 0
    let tabname = <SID>GetTabName(bufnr)
    let tabid   = <SID>CreateTab(winid, tabname)
    let w_tabs  = s:wins_tabs[winid]
    eval <SID>EchoAllWinInfo(winid)

    eval add(w_tabs["tabs_ids"], tabid)
    eval <SID>AssociateBufWithTab(bufnr, tabid, winid)

    let need_to_redraw = 0
    if <SID>PositionTab(winid, tabid)
        let w_tabs["lasttab"] += 1
    else
        eval popup_hide(tabid)
        let need_to_redraw = 1
    endif

    let n_last      = w_tabs["lasttab"]
    let n_first     = w_tabs["firsttab"]

    if s:wintab_go_to_new_tab
        let n_last      = len(w_tabs["tabs_ids"]) - 1
        let n_first     = <SID>CalculateNewFirstTab(winid, n_last, 0, 0)[0]
        let new_t_idx   = index(w_tabs["tabs_ids"], tabid)
        eval <SID>MakeTabCurrent(new_t_idx, winid)
    else
        eval <SID>HandleCurTabChange(w_tabs["curtab"], winid)
        let need_to_redraw = 0
    endif
   
    echom n_first n_last 
    if need_to_redraw
        eval <SID>HandleTabsRedraw(winid, n_first, n_last)
    endif
endfunction

function s:GetTabName(bufnr)
    let bufname = fnamemodify(bufname(a:bufnr + 0), ":t")
    if bufname ==? ""
        let bufname = "unnamed"
    endif
    let tabname = s:wintab_tab_left_border . 
                \ bufname . 
                \ s:wintab_tab_right_border

    return tabname
endfunction

function s:HandleBufNameChange()
    let winid   = win_getid() + 0
    let wi      = getwininfo(winid)[0]
    let bufnr   = wi.bufnr + 0
    let w_tabs  = s:wins_tabs[winid]
    let tabid   = s:wins_bufs[winid][bufnr]
    let newname = <SID>GetTabName(bufnr)

    eval popup_settext(tabid, newname)

    let n_first = w_tabs["firsttab"]
    let n_last  = <SID>CalculateNewLastTab(winid,n_first,
                \ len(w_tabs["tabs_ids"])-1,0)[0]

    eval <SID>HandleTabsRedraw(winid, n_first, n_last)
endfunction

function s:CreateTab(winid, text)
    echom "    Entering CreateTab"
    return popup_create(a:text, {})
endfunction

function s:AssociateBufWithTab(bufnr, tabid, winid)
    echom "    Entering  AssociateBufWithTab"
    let bufnr = a:bufnr + 0
    let tabid = a:tabid + 0
    let winid = a:winid + 0
    eval <SID>EchoAllWinInfo(winid)

    if !has_key(s:wins_bufs, winid)
        echom "Cannot associate - winid" winid "cannot be found."
        return 1
    endif
    let b_dict = s:wins_bufs[winid]

    if has_key(b_dict, bufnr) && b_dict[bufnr] != -1
        echom "Cannot associate - bufnr" bufnr " is already associated."
        return 2
    endif
    let b_dict[bufnr] = tabid
    return 0
endfunction

" Delete a tab
function s:HandleTabDeletion(bufnr, winid)
    echom "    Entering HandleTabDeletion"

    let bufnr  = a:bufnr + 0
    let winid  = a:winid + 0
    eval <SID>EchoAllWinInfo(winid)

    if !has_key(s:wins_bufs, winid)
        echom "Cannot delete tab - winid" winid "cannot be found."
        return 1
    endif
    let b_dict = s:wins_bufs[winid]

    if !has_key(b_dict, bufnr)
        echom "Connot delete tab - bufnr" bufnr "cannot be found."
        return 2
    endif
    let tabid   = b_dict[bufnr]

    let w_tabs  = s:wins_tabs[winid]
    let tabs_l  = w_tabs["tabs_ids"]
    let p_idx   = index(tabs_l, tabid)
    if p_idx < w_tabs["firsttab"] 
        let w_tabs["firsttab"] -= 1
    endif
    if p_idx < w_tabs["lasttab"] || w_tabs["lasttab"] == len(tabs_l)-1
        let w_tabs["lasttab"]  -= 1 
    endif

    eval remove(w_tabs["tabs_ids"], p_idx)
    eval popup_close(tabid) 
    return 0
endfunction

function s:DeleteCurTabFromBar()
    let winid   = win_getid() + 0
    let wi      = getwininfo(winid)[0]
    let bufnr   = wi.bufnr + 0
    
    if !has_key(s:wins_tabs, winid)
        return
    endif

    let w_tabs  = s:wins_tabs[winid]
    let tabs_l  = w_tabs["tabs_ids"]
    let tabid   = s:wins_bufs[winid][bufnr]
    let tabidx  = index(tabs_l, tabid)
    
    eval <SID>RemoveBufFromWin(bufnr, winid)

    if len(tabs_l) == 0
        let w_tabs["lasttab"]   = -1
        let w_tabs["curtab"]    = 0
        let w_tabs["tabline_w"] = 0
        return
    endif

    let new_cur_tab = tabidx
    while new_cur_tab >= len(tabs_l)
        let new_cur_tab -= 1
    endwhile

    let w_tabs["curtab"] = new_cur_tab        
    eval <SID>HandleCurTabChange(new_cur_tab, winid)
    eval popup_close(tabid)

    let n_first = w_tabs["firsttab"]
    let n_last  = <SID>CalculateNewLastTab(winid, n_first, len(tabs_l)-1, 0)[0]
    eval <SID>HandleTabsRedraw(winid, n_first, n_last)
endfunction

" Visualize tabs
function s:HandleTabsRedraw(winid, firsttab, lasttab)
    echom "    Entering HandleTabsRedraw"
    let winid = a:winid+0
    eval <SID>EchoAllWinInfo(winid)
    eval <SID>HandleTabBlanks(winid, a:firsttab+0, a:lasttab+0)
    eval <SID>RedrawTabsBar  (winid, a:firsttab+0, a:lasttab+0) 
endfunction

function s:PositionTab(winid, tabid)
    echom "    Entering PositionTab"
    let return_code = 1
    let winid       = a:winid + 0
    let tabid       = a:tabid + 0
    let wi          = <SID>GetWinInfo(winid)
    let w_tabs      = s:wins_tabs[winid]
    let tlw         = w_tabs["tabline_w"]
    let bufnamelen  = popup_getpos(tabid).width 
    echom "Wininfo is" wi
    eval <SID>EchoAllWinInfo(winid)

    if tlw + bufnamelen > wi["w"]
        let return_code = 0
    else
        let offset = 1
        eval popup_move(a:tabid, 
                \ { "line": wi["y"] + wi["h"] - offset, 
                \   "col": tlw + wi["x"]})
        eval popup_show(tabid)
        let w_tabs["tabline_w"] += (bufnamelen + s:wintab_tab_space)
    endif

    return return_code
endfunction

function s:RedrawTabsBar(winid, newfirsttab, newlasttab)
    echom "    Entering RedrawTabsBar"
    let winid           = a:winid + 0
    let w_tabs          = s:wins_tabs[winid]
    let tabs_l          = w_tabs["tabs_ids"]
    let w_tabs["tabline_w"]  = 0

    if len(tabs_l) == 0
       return
    endif

    eval <SID>EchoAllWinInfo(winid)

    echom s:wins_tabs[winid]

    eval <SID>RedrawBlanks(winid, "f")

    let idx = a:newfirsttab
    while idx > w_tabs["firsttab"]
        eval popup_hide(tabs_l[w_tabs["firsttab"]])
        let w_tabs["firsttab"] += 1 
    endwhile
    let w_tabs["firsttab"] = idx
    while idx <= a:newlasttab
        let cur_tab = tabs_l[idx]
        if !<SID>PositionTab(winid, cur_tab)
            let idx += 1
            break
        endif
        let idx += 1
    endwhile
    let real_new_lasttab = idx - 1
    let end_of_while = w_tabs["lasttab"]
    if end_of_while > len(tabs_l) - 1 
        let end_of_while = len(tabs_l) - 1
    endif
    while idx <= end_of_while
        eval popup_hide(tabs_l[idx])
        let idx += 1
    endwhile
    let w_tabs["lasttab"] = real_new_lasttab

    eval <SID>RedrawBlanks(winid, "l")
endfunction

function s:RedrawBlanks(winid, what_blank)
    let winid   = a:winid + 0
    let w_tabs  = s:wins_tabs[winid] 
    let tabs_l  = w_tabs["tabs_ids"]
    eval <SID>EchoAllWinInfo(winid)

    if w_tabs["firstblank"]+0 && a:what_blank ==? "f"
        eval <SID>PositionTab(winid, w_tabs["firstblank"])
    endif

    if w_tabs["lastblank"]+0  && a:what_blank ==? "l"
        let max_w = <SID>GetWinInfo(winid)["w"] 
        let free_width = max_w - w_tabs["tabline_w"]
        while free_width < strchars(s:wintab_tab_blank)
            let tab_to_hide   = tabs_l[w_tabs["lasttab"]]
            let p_w             = popup_getpos(tab_to_hide)["width"]
            eval popup_hide(tab_to_hide)
            let w_tabs["lasttab"]   -= 1
            let w_tabs["tabline_w"] -= (p_w + s:wintab_tab_space)
            let free_width           = max_w - w_tabs["tabline_w"]
        endwhile
        eval <SID>PositionTab(winid, w_tabs["lastblank"])
    endif
endfunction

function s:HandleTabBlanks(winid, firsttab, lasttab)
    echom "    Entering HandleTabBlanks"
    let winid   = a:winid + 0
    let tabs_l  = s:wins_tabs[winid]["tabs_ids"]
    eval <SID>EchoAllWinInfo(winid)

    if len(tabs_l) == 0
        return
    endif

    let head = 0
    let tail = 0
    
    if a:firsttab+0 == 0
        let head = 1
    endif
    
    if a:lasttab+0 == len(tabs_l) - 1
        let tail = 1
    endif

    if head + tail
        eval <SID>DeleteTabBlanks(winid, head, tail)
    endif

    eval <SID>AddTabBlanks(winid, !head, !tail)
endfunction

function s:AddTabBlanks(winid, head, tail)
    echom "    Entering AddTabBlanks"
    let winid  = a:winid + 0
    let w_tabs = s:wins_tabs[winid]
    eval <SID>EchoAllWinInfo(winid)

    if a:head+0 && !w_tabs["firstblank"]
        echom "Creating fisrtblank"
        let w_tabs["firstblank"] = <SID>CreateTab(winid, s:wintab_tab_blank)
        eval popup_setoptions(w_tabs["firstblank"], 
                \ {"highlight": s:wintab_tab_hi_blank})
    endif

    if a:tail+0 && !w_tabs["lastblank"]
        echom "Creating lastblank"
        let w_tabs["lastblank"]  = <SID>CreateTab(winid, s:wintab_tab_blank)
        eval popup_setoptions(w_tabs["lastblank"], 
                \ {"highlight": s:wintab_tab_hi_blank})
    endif
endfunction

function s:DeleteTabBlanks(winid, head, tail)
    echom "    Entering DeleteTabBlanks"
    let winid  = a:winid + 0
    let w_tabs = s:wins_tabs[winid]
    eval <SID>EchoAllWinInfo(winid)

    if a:head+0 && w_tabs["firstblank"]
        echom "Deleting fisrtblank"
        eval popup_close(w_tabs["firstblank"])
        let w_tabs["firstblank"] = 0
    endif 

    if a:tail+0 && w_tabs["lastblank"]
        echom "Deleting lastblank"
        eval popup_close(w_tabs["lastblank"])
        let w_tabs["lastblank"] = 0
    endif 
endfunction

function s:SlideTabsBar(winid, direction)
    echom "    Entering SlideTabsBar"
    let winid       = a:winid + 0
    let w_tabs      = s:wins_tabs[winid]
    let newfirsttab = w_tabs["firsttab"] + a:direction
    let newlasttab  = w_tabs["lasttab"]  + a:direction
    eval <SID>EchoAllWinInfo(winid)

    if newfirsttab >= 0 && newlasttab < len(w_tabs["tabs_ids"])
        eval <SID>HandleTabsRedraw(winid, newfirsttab, newlasttab)
    endif
endfunction

function s:MoveCurTab(winid, where)
    echom "    Entering MoveCurTab"
    let winid       = a:winid + 0
    eval <SID>EchoAllWinInfo(winid)
    let w_tabs      = s:wins_tabs[winid]
    let tabs_l      = w_tabs["tabs_ids"]
    let cur_t       = w_tabs["curtab"]
    let new_cur_t   = cur_t + a:where

    if new_cur_t < 0
        eval <SID>HandleCurTabChange(len(tabs_l)-1, winid)
    elseif new_cur_t >= len(tabs_l)
        eval <SID>HandleCurTabChange(0, winid)
    else
        eval <SID>HandleCurTabChange(new_cur_t, winid)
    endif

endfunction

function s:HandleCurTabChange(new_cur_tab_idx, winid)
    echom "    Entering HandleCurTabChange"
    let ncti    = a:new_cur_tab_idx + 0
    let winid   = a:winid + 0
    eval <SID>EchoAllWinInfo(winid)
    let w_tabs  = s:wins_tabs[winid]
    let tabs_l  = w_tabs["tabs_ids"]
    let n_first = w_tabs["firsttab"]
    let n_last  = w_tabs["lasttab"] 

    if ncti < w_tabs["firsttab"]
        let n_first = ncti
        let n_last  = <SID>CalculateNewLastTab(winid, n_first, len(tabs_l)-1,0)[0]
        echom n_first n_last
        eval <SID>HandleTabsRedraw(winid, n_first, n_last)
    elseif ncti > w_tabs["lasttab"]
        let n_last  = ncti 
        let n_first = <SID>CalculateNewFirstTab(winid, n_last, 0, 0)[0]
        echom n_first n_last
        eval <SID>HandleTabsRedraw(winid, n_first, n_last)
    endif

    eval <SID>MakeTabCurrent(ncti, winid)    

    let cur_tab_id = tabs_l[ncti] 
    let bufs = s:wins_bufs[winid] 
    for [k,v] in items(bufs)
        if v == cur_tab_id
            eval execute("buffer" . k)
            break
        endif
    endfor
endfunction

function s:MakeTabCurrent(new_cur_tab_idx, winid)
    echom "    Entering MakeTabCurrent"
    let ncti    = a:new_cur_tab_idx + 0
    let winid   = a:winid + 0
    eval <SID>EchoAllWinInfo(winid)
    let w_tabs  = s:wins_tabs[winid]
    let tabs_l  = w_tabs["tabs_ids"]
  
    eval popup_setoptions(tabs_l[w_tabs["curtab"]], 
                \ {"highlight": s:wintab_tab_hi_regular})
    eval popup_setoptions(tabs_l[ncti], 
                \ {"highlight": s:wintab_tab_hi_selected})

    let w_tabs["curtab"] = ncti
endfunction

function s:HideShowTabBar(winid, Callback)
    let winid   = a:winid + 0
    let w_tabs  = s:wins_tabs[winid]
    let tabs_l  = w_tabs["tabs_ids"]
    let idx     = w_tabs["firsttab"]
    let last    = w_tabs["lasttab"]
    
    let wi      = s:wins_info[winid]
    if wi["h"] <= 0 && wi["w"] <= 0
        return 1
    endif

    while idx <= last
        eval a:Callback(tabs_l[idx])
        let idx += 1
    endwhile
endfunction

function s:HideShowAllTabBars(Callback)
    for [k, v] in items(s:wins_tabs)
        eval <SID>HideShowTabBar(k, a:Callback)
    endfor 
endfunction

function s:ToggleTabBar(...)
    let winid = get(a:000, 0, win_getid())    
    if !has_key(s:wins_open, winid) || !has_key(s:wins_tabs, winid)
        echom "Window" winid "is not opened or cannot have any tabs."
        return 1
    endif
    
    let w_tabs   = s:wins_tabs[winid] 
    let tabid    = w_tabs["tabs_ids"][w_tabs["curtab"]]
    let callback = "popup_show" 
    if popup_getpos(tabid)["visible"]
        let callback = "popup_hide" 
    endif
    
    eval <SID>HideShowTabBar(winid, function(callback))
endfunction

function s:ToggleAllTabBars()
    for [k,v] in items(s:wins_tabs)
        eval <SID>ToggleTabBar(k)
    endfor 
endfunction



" ---------- Autocommands

function s:AutogroupSetter()
    augroup wintabaugroup
        autocmd!
        
        if !s:wintab_load_au
            let s:wintab_load_au = 1
            return
        endif

        " Catching initial layout upon Vim startup.
        if s:wintab_vim_startup
            autocmd VimEnter
                        \ * call <SID>HandleVimStartup()
        endif

        " Adding windows into dicts.
        if s:wintab_mode ==? "fullauto" || s:wintab_mode ==? "halfman"
            autocmd WinNew
                        \ * call <SID>HandleNewWindow(win_getid())
        endif

        " Catching wrong windows and buffers.
        autocmd TerminalOpen,CmdWinEnter,FileType,BufEnter
                    \ * call <SID>HandleWrongWin()

        " Simulating WinDeletion event. 
        autocmd WinEnter
                    \ * call <SID>HandleWinLeaving()
        autocmd CmdWinLeave
                    \ * call <SID>HandleWinDeletion(win_getid(),
                    \       {"open":1, "info":1, "bufs":1, "tabs":1, "resize":1}) |

        " Windows resized.
        autocmd CmdwinLeave,CmdlineLeave
                    \ * call <SID>ProcessExecutedCmd(["res[ize]"],
                    \ function("<SID>HandleWinResize"))
        autocmd CmdwinLeave,CmdlineLeave
                    \ * call <SID>ProcessExecutedCmd(["clo[se]", "q[uit]", "hid[e]"],
                    \ function("<SID>HandleWinResize"))
        autocmd OptionSet 
                    \ window,winheight,winwidth call <SID>HandleWinResize()
        autocmd VimResized
                    \ * call <SID>HandleWinResize()
        
        " Adding buffers.
        if s:wintab_mode ==? "fullauto"
            autocmd BufEnter
                        \ * call <SID>HandleBufAddition (expand('<abuf>'), 
                        \                           win_getid())
        elseif s:wintab_mode ==? "halfman"
            autocmd BufNew
                        \ * call <SID>HandleBufAddition (expand('<abuf>'), 
                        \                           win_getid())
        endif
       
        " Handling jumping from one buffer to another. 
        autocmd BufEnter
                    \ * call <SID>HandleCTRLOCTRLI()

        " Deleting buffers.
        autocmd BufUnload 
                    \ * call <SID>HandleBufWipeout(expand('<abuf>'))

        " Renaming buffers.
        autocmd BufFilePost
                    \ * call <SID>HandleBufNameChange()
    augroup END
endfunction
call <SID>AutogroupSetter()



" ---------- Debug

function s:EchoAllWinsInfo()
    echom "    Entering EchoAllWinsInfo"
    for w in items(s:wins_info)
        echom w
    endfor
endfunction

function s:EchoAllWinsBufs()
    echom "    Entering EchoAllWinsBufs"
    for w in items(s:wins_bufs)
        echom w
    endfor
endfunction

function s:EchoAllBufsWins()
    echom "    Entering EchoAllBufsWins"
    for w in items(s:bufs_wins)
        echom w
    endfor
endfunction

function s:EchoTabsInfo()
    echom "    Entering EchoTabsInfo"
    for [w, i] in items(s:wins_bufs)
        echom "For winid" w ": "
        echom "    Buffers are" s:wins_bufs[w]
        echom "    Tabs are" s:wins_tabs[w] 
    endfor
endfunction

function s:EchoAllWinInfo(winid)
    echom "    Entering EchoAllWinInfo"
    let winid = a:winid
    echom "Winid is" winid
    if has_key(s:wins_open, winid)
        echom "wins_open -" s:wins_open[winid]
    endif
    if has_key(s:wins_bufs, winid)
        echom "wins_bufs -" s:wins_bufs[winid]
    endif
    if has_key(s:wins_tabs, winid)
        echom "wins_tabs -" s:wins_tabs[winid]
    endif
    if has_key(s:wins_info, winid)
        echom "wins_info -" s:wins_info[winid]
    endif
endfunction

function s:DebugInfo()
    eval <SID>EchoAllWinsInfo()
    eval <SID>EchoAllWinsBufs()
    eval <SID>EchoAllBufsWins()
    eval <SID>EchoTabsInfo()
endfunction


nnoremap <leader>\ :call <SID>UpdateCurWinInfo()<cr>
nnoremap <leader>= :call <SID>EchoAllWinsInfo()<cr>
nnoremap <leader>+ :call <SID>DebugInfo()<cr> 

nnoremap <leader>0 :call <SID>HideShowTabBar(win_getid(), function("popup_hide"))
nnoremap <leader>) :call <SID>HideShowTabBar(win_getid(), function("popup_show"))

nnoremap <leader>9 :call <SID>HideShowAllTabBars(function("popup_hide"))
nnoremap <leader>( :call <SID>HideShowAllTabBars(function("popup_show"))

nnoremap <leader>ml :VWTGoTabLeft<cr>
nnoremap <leader>mr :VWTGoTabRight<cr>
nnoremap <leader>wa :VWTAddWindow<cr>
nnoremap <leader>wd :VWTDelWindow<cr>
nnoremap <leader>ta :VWTAddBufToTabBar<cr>
nnoremap <leader>td :VWTDeleteCurTabFromBar<cr>
