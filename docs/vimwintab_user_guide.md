Vimwintab User Guide
====================

[Go back to main page]

This is a user guide to the **Vimwintab** Vim plugin.

Table of contents
-----------------

* Basic description;
* Modes;
* Adding/deleting windows/buffers;
* Navigating a tab bar;
* Turning the plugin on/off, dealing with issues;
* Customization.


Basic description
-----------------

This is simple - you have windows that display files. These files are added to a tab bar. Each window has a tab bar that shows the files opened in that window. You can [navigate] through the tabs on each tab bar without thinking much about the buffers. Each tab bar has a current tab, that is shown in the window.

Yes, technically all the buffers are still in place, of course, but you don't need to use the buffer list to [navigate]. You can say that you don't need to know buffers' numbers to jump between them conveniently, but that depends on how you use the plugin, more about that in [Adding window and buffers] section of this guide.

Some parts of the plugin can be [customized] to make your usage of it more pleasant. You can either set variables in you vimrc, or change them during execution of the plugin.

Modes
-----

The plugin can operate in several modes. They are:
* fullauto;
* halfman;
* fullman.

If in `fullauto` mode, the plugin will add a new buffer to a window each time this buffer is firstly visited from this window. That is, every time you enter a buffer that is not yet in the window, it is added to this window. Typically, if you are using the plugin in this mode you don't really need to bother about adding to tabs by yourself.

`halfman` mode is almost the same as fullauto one, but a buffer is added to a tab bar only when this buffer is created. The is, when there is a new buffer, it is added to a current window. You can still add this buffer to other windows manually. 

`fullman` mode is here if you don't want the plugin to interfere much into your workflow - buffers are not added to tab bars automatically at all, neither upon entrance, nor on creation - you need to [add] them manually. Besides that, the plugin will not account any opened windows - you will need to [tell] the plugin to notice the window before to add a buffer to its tab bar.

To change the mode, define `g:wintab_mode` variable in your vimrc file and initialize it to one of the buffers' names above.

Adding/deleting windows/buffers
--------------------------

Beside letting the plugin to handle windows and buffers automatically, you can also do some manipulations with them manually. The plugin provides a set of Ex commands for interacting with windows and buffers.

`:VWTAddWindow`<br>
You can run it without any arguments - in such a case the current widnow will be taken into account by the plugin. You can also provide a window id as a single argument.

`:VWTDelWindow`<br>
To make the plugin forget about the window, delete its tab bar and not let the plugin to add tabs to this window. Arguments work the some at with VWTDelWindow.

After a window is noticed by the plugin, you can add a buffer to this window, making this buffer a tab of this window.

`:VWTAddBufToTabBar`<br>
It adds a buffer to a bar. It takes 0 to 2 arguments. First arguments will be interpreted as a buffer number, the second one - as window id. If one or all argument are absent, the values of the current window and its shown buffer will be taken.

`:VWTDeleteCurTabFromBar`<br>
This command deletes a current buffer from a current window. That's it. This buffer can still be in other windows' tab bars.

One important note on Vim startup - you can tell the plugin to notice windows and their current buffers when Vim starts up. To do this, define `g:wintab_vim_startup` variable in your vimrc file and initialize it to non-0 value. 

You can go to the new tab when it is added, or stay at the current one. To change this behaviour define `g:wintab_go_to_new_tab` in your vimrc file and initialize it to non-0.

Navigating a tab bar
--------------------

You can navigate any tab bar in a way tab bars are usually navigated.

`:VWTGoTabLeft`
`:VWTGoTabRight`<br>
This two functions will move a current tab of a bar to the left or right, accordingly. If you are trying to move beyond the bar, the current tab will wrap, going to the other side of the bar.

`:VWTSlideLeft`
`:VWTSlideRight`<br>
These two functions will slide the tab bar to the left or right accordingly. Useful, for example, if you want to see what tabs you have opened (and that cannot fit into the bar) without moving a current tab.

`:VWTShowCurTabBar`
`:VWTHideCurTabBar`<br>

`:VWTShowAllTabBars`
`:VWTHideAllTabBars`<br>

`:VWTToggleTabBar`
`:VWTToggleAllTabBars`<br>
These set of function allows to hide/show a current tab bar, all the bars at currently displayed windows, or toggle them.

`:VWTChangeMode'<br>
This one will set customizable parameters to the values provided in an argument dictionary. If the dict is empty then it will set the values to the default ones, taken into account parameters set by you in your vimrc. The command also readds windows and buffers. The possible items you can provide in a dict are the following (for values of this items see [Customization]):<br>
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

Turning the plugin on/off, dealing with issues
----------------------------------------------

`:VWTEnable` `:VWTDisable`<br>
Enables plugin if that was disabled, disables it if you don't want it to operate. Please note that disabling the plugin this way doesn't "un-source" the plugin's script.

This also is useful if the plugin starts misbehaving.

`:VWTReset`<br>
Resets the plugin to the default options and does what the plagin usually does upon Vim startup.

`:VWTRedraw`
Redraws visible tabs. Useful if the plugin didn't catch a change in layout.

Customization
-------------

How plugin is operates can be determined either by setting plugin parameters in your vimrc file, or using VWTChangeMode command. See [Customization] page for more info on customization.
