Vimwintab functions
===================

[Go back to main] [Go back to development] 

This is a list of functions provided by the plugin, grouped by its functionality, with a little description for each of them.

Please, note that this page is here to describe technical details of the plugin - you are not supposed to call these from outside of the script file itself. Please refer to [USER INTERFACE] section to see how you can interact with the plugin as a user, and [Customization] to see how to change the plugin's behaviour.


Initializers for datastructures
-------------------------------

**InitWinsInfoValue()**<br>
Initializes a value of wins_info dict.

**InitWinsBufsValue()**<br>
Initializes a value of wins_bufs dict.

**InitWinsTabsValue()**<br>
Initializes a value of wins_tabs dict.

**InitBufsWinsValue()**<br>
Initializes a value of bufs_wins dict.


Helpers
-------

**RemoveDictListItem(dict, key, item)**<br>
**RemoveDictDictItem(dict, key, item)**<br>
Removes an item of a dict, which is itself a dict or a list.

**ProcessExecutedCmd(matches, Callback)**<br>
Calls a Callback if [matches] matches last executed command.

**CorrectBufAndWinTypes(bufnr, winid)**<br>
Returns non-0 if [bufnr] and [winid] are of correct buffer and window. 0 otherwise.

**ChangeMode(how)**<br>
Changes custom values. Accepts a dict with 0 or any of the following keys: <br>
&emsp;    "mode"<br>
&emsp;    "new_tab"<br>
&emsp;    "left_b"<br>
&emsp;    "right_b"<br>
&emsp;    "tab_space"<br>
&emsp;    "tab_blank"<br>
&emsp;    "tab_hi_r"<br>
&emsp;    "tab_hi_s"<br>
&emsp;    "tab_hi_b"<br>
&emsp;    "resize_timer"<br>

**Disable()**<br>
Disables the plugin by unleting the main dictionaries and deleting commands and autocommands.

**Reset()**<br>
Calls ChangeMode( {} ).

**Enable()**<br>
Enables plugin if it was disabled earlier. Do the opposite of what `Disable()` does.

`Redraw()`<br>
Calls `HandleWinResize()` to redraw tab bars.

**DeleteCommands()**<br>
Deletes all the commands but `:VWTEnable`.


Windows
-------

**GetWinInfo(winid)**<br>
Gets a dict with the following keys, corresponding to the information about the window win [winid] id:<br>
&emsp;    "x" - x position of the top left angle<br>
&emsp;    "y" - y position of the top left angle<br>
&emsp;    "w" - window width<br>
&emsp;    "h" - window height<br>

**UpdateCurWinInfo()**<br>
Updates current window's info.

**WinNrToId(index, winnr)**<br>
Translates window's number into it's id. [index] is ignored.

**HandleWinAddition(winid, where)**<br>
Populates structs with initial values for a new window.

**HandleNewWindow(winid)**<br>
Main function for adding a new window into structs. 
*NOTE* - sometimes Vim cannot determine types of windows and buffers 
timely, so added window is not guaranteed to have a correct type - 
see *HandleWrongWin()*.

**AddWin(...)**<br>
Used to add exact window to structs. An argument can be a desired winid, 
current window if no arguments provided.

**HandleVimStartup()**<br>
Populates structs upon Vim startup, if not disabled with *g:wintab_go_to_new_tab*.

**HandleWinDeletion(winid, what)**<br>
Deletes the window with [winid] from structs. [what] is a dict with the following keys:
    "info"      - delete from corresponding struct.
    "open"      - delete from corresponding struct
    "bufs"      - delete from corresponding struct
    "tabs"      - delete from corresponding struct
    "resize"    - updates windows' info and redraws tab bars.

**DelWin(...)**<br>
Deletes windows completely, without resize. A single argument could be a winid of the window, current window id is used if no arguments are provided.

**HandleWrongWin()**<br>
Deletes a window if it is found to be of a wrong type (or its' buffer is of a wrong type).

**HandleWinLeaving()**<br>
Deletes a previously visited window if it is no more.

**HandleWinResize()**<br>
Main resize function. It also cleans garbage info left from closed windows.

**ResizeUponTimer(timer_id)**<br>
Function called by *HandleWinResize()*.


Buffers
-------

**HandleBufAddition(bufnr, winid)**<br>
Associates the buffer with [bufnr] with the window with [winid] and puts a tab to a bar.

**AddBufToWin(bufnr, winid)**<br>
Adds the buffer with [bufnr] to the window's [winid] structs.

**AddBufToTabBar(...)**<br>
Adds exact buffer to the exact struct. First argument could be the buffer's number, second - the window's winid. Values of the current ones are taken if one or all the arguments are missing.

**HandleBufDeletion(bufnr, winid)**<br>
Deletes the buffer with [bufnr] wrom the window with [winid], redraws the window's tab bar.

**RemoveBufFromWin(bufnr, winid)**<br>
Removes the buffer [bufnr] wrom the relevant structs.

**HandleBufWipeout(bufnr)**<br>
Deletes the buffer with [bufnr] from everywhere.

**DeleteBufFromAllWins(bufnr)**<br>
Deletes the buffer with [bufnr] from everywhere.

**HandleCTRLOCTRLI()**<br>
Handles jumping to another buffer.


Tabs
----

**CalculateNewFirstTab(winid, lasttab, min_first, start_cur_w)**<br>
**CalculateNewLastTab(winid, firsttab, max_last, start_cur_w)**<br>
Return a list, where the first index is for a new values, and second is for a width taken by tabs between the new one and the anchor point.

**HandleNewTab(bufnr, winid)**<br>
When the buffer with [bufnr] is added to structs, adds a correspondent tab to structs and to [winid] window's bar.

**GetTabName(bufnr)**<br>
Get a name for a buffer with [bufnr].

**HandleBufNameChange()**<br>
Changes a name of a buffer being renamed, e.g. with file or saveas commands.

**CreateTab(winid, text)**<br>
Creates a tab with [text] in windows with [winid].

**AssociateBufWithTab(bufnr, tabid, winid)**<br>
Associates buffer with [bufnr] with tab with [tabid] on the window with [winid].

**HandleTabDeletion(bufnr, winid)**<br>
Deletes the tab associated with a buffer with [bufnr] in the window with [winid] from structs.

**DeleteCurTabFromBar()**<br>
Deletes the current tab from the current window's tab bar and relevant structs.

**HandleTabsRedraw(winid, firsttab, lasttab)**<br>
Handles tab blanks and redraws the tab bar. See *RedrawTabsBar()*.

**PositionTab(winid, tabid)**<br>
Positions a tab with [tabid] correctly on the window with [winid] or returns 0 if all the free space in the bar is taken by other tabs.

**RedrawTabsBar(winid, newfirsttab, newlasttab)**<br>
Redraws a tab bar of the window with [winid], from [firsttab] until [lasttab] or the last tab that fits into the bar being redrawn.

**RedrawBlanks(winid, what_blank)**<br>
Redraws either "f" - first or "l" - last blanks of [what_blank] in the window with [winid].

**HandleTabBlanks(winid, firsttab, lasttab)**<br>
Determines if blanks should be added or deleted in the window with [winid], if the bar takes space from [firsttab] until [lasttab].

**AddTabBlanks(winid, head, tail)**<br>
Add first - [head] or last - [tail] blank to the bar of the window with [winid].

**DeleteTabBlanks(winid, head, tail)**<br>
Deletes first - [head] or last - [tail] blank from the bar of the window with [winid].

**SlideTabsBar(winid, direction)**<br>
Slides the bar of the window with [winid] to the left or right [direction], determined with negative or positive value.

**MoveCurTab(winid, where)**<br>
Moves the current tab of the window's with [winid] bar to the left or right [direction]. See *SlideTabsBar*.

**HandleCurTabChange(new_cur_tab_idx, winid)**<br>
Changes the current tab of the window with [winid] to the [new_cur_tab_idx] and changes the current buffer to the correspondent one.

**MakeTabCurrent(new_cur_tab_idx, winid)**<br>
Changes the current tab, see *HandleCurTabChange*.

**HideShowTabBar(winid, Callback)**<br>
[Callback] is either "popup_show" or "popup_hide".

**HideShowAllTabBars(Callback)**<br>
[Callback] is either "popup_show" or "popup_hide".

**ToggleTabBar(...)**<br>
An argument is ether window's id, or absent, in which case the current window's id is taken.

**ToggleAllTabBars()**<br>
As ToggleTabBar but for all bars.

**AutogroupSetter()**<br>
Resets autogroup. Useful when *ChangeMode* was called.


Debug
-----

**EchoAllWinsInfo()**<br>
**EchoAllWinsBufs()**<br>
**EchoAllBufsWins()**<br>
**EchoTabsInfo()**<br>
**EchoAllWinInfo(winid)**<br>
**DebugInfo()**<br>
Debug functions that print info about different structs.
