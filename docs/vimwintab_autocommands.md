Vimwintab autocommands
======================

[Go back to main] [Go back to development]

Please note that this page is for people interested in developing the plugin. Go to the [USER GUIDE] to find information on how to use it, or [Customization] on changing the plugin's behaviour.

Please refer to [functions] page to see what triggered functions are doing exactly.


Events
------

There are several events that the plugin is listening to and that are powering the plugin's work. For usability purposes they are broken down into groups by what they are trying to catch.

* Vim start-up.
If `g:wintab_vim_startup` is non-0, `VimEnter` event will trigger `HandleVimStartup()` function. 

* Noticing new windows.
If `g:wintab_mode` is "fullauto" or `g:wintab_mode`, `WinNew` event will will trigger `HandleNewWindow()` function with argument taken from `win_getid()`.

* Catching wrong windows and buffers.
This events - `TerminalOpen` ,`CmdWinEnter`, `FileType` ,`BufEnter` will trigger  `HandleWrongWin()` function.

* Simulating "WinDeletion" event.
 `WinEnter` will trigger `HandleWinLeaving()` function and `CmdWinLeave` - `HandleWinDeletion()` one with full dict as an argument. `CmdWinLeave` is here because Vim cannot detect leaving command-window normally.

* Catching windows being resized.
Vim is giving no uniformed way of seeing when windows were resized. These events are trying to do the job:

`CmdwinLeave`, `CmdlineLeave` are here to process command typed by the user and see if they are ones of the following - "res[ize]", "clo[se]", "q[uit]", "hid[e]", `OptionSet` - to see when "window", "winheight", "winwidth" options are set, `VimResized` - when Vim itself is resized. Huge workaround, I know. Know any other ways?
        
 * Adding buffers.
  If `g:wintab_mode` is "fullauto", 'BufEnter', and if "halfman" - `BufNew` are triggering `HandleBufAddition()` with "<abuf> as buffer name and `win_getid()` as window id.
       
* Handling jumping from one buffer to another (CTRL-I CTRL-O).
`BufEnter` triggers `HandleCTRLOCTRLI()`. Is here for the case when the mode is not "fullauto".

* Deleting buffers.
`BufUnload` triggers `HandleBufWipeout()` with "<abuf>" as an argument.

 * Renaming buffers.
`BufFilePost` triggers `HandleBufNameChange()`. 


All the autocommand settings are put into `AutogroupSetter()` function, which is called once from the plugin's script body, and sometimes from other functions if plugin's behaviour should be changed.
