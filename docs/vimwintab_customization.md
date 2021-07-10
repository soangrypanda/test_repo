Vimwintab customization guide
=============================

[Go to main page] [Go to User Guide]

Table of contents
-----------------

* Description
* Variables
* Change behaviour during execution

Description
-----------

The behaviour of the plugin can be changed to your liking. There are to ways of doing it:
1) you can define global variables mentioned below in your vimrc file - that's how you can change the plugin's behaviour permanently;
2) you can also use `:VWTChangeMode` command during plugin's execution to change its behaviour on the fly. It takes a dictionary as an argument, see below what items you can use.

Variables
---------

Here is a list of variables and their possible values that you can place in your vimrc file to change the plugin's behaviour:

`g:wintab_mode`<br>
Defines a mode in which plugin operates. The following modes are supported:
* fullauto &emsp; - add a buffer to a window if the buffer is entered from this window.
* halfman &emsp;- add a buffer to a window if the new buffer is created from this window.
* fullman &emsp; - add a buffer to a window if user directly asks for that.<br>
Should be a string containing one of the modes names.

`g:wintab_go_to_new_tab`<br>
Defines whether need to go to a newly opened tab, or remain at the current one. 0 - no, non-0 - yes.

`g:wintab_vim_startup`<br>
Defines whether plugin needs to catch layout upon Vim startup. 0 - no, non-0 - yes.

`g:wintab_tab_left_border`
`g:wintab_tab_right_border`<br>
Define how borders of every tab would look like. Need to be a string.

`g:wintab_tab_space`<br>
Defines the width of space between tabs. You can make it negative, of course, but what's the point?

`g:wintab_tab_blank`<br>
Defines how blank tabs (that shows that there are other tabs to the left or right of the bar that do not fit into it) would look like.

`g:wintab_tab_hi_regular`
`g:wintab_tab_hi_selected`
`g:wintab_tab_hi_blank`<br>

Defines highlighting for different tabs. Should be a string containing the name of a highlight group.

`g:wintab_resize_timer`<br>
Defines time in milliseconds when data structures will be updated and tabs redrawn after `HandleWinResize()` is called. Cannot resize without timer as Vim updates info about some windows with delay so it is hard to catch with au.


Change behaviour during execution
---------------------------------

To change the plugin's behaviour during execution, you could call `:VWTChangeMode` command and give it a single argument, which is a dict with the following possible keys and values:<br>
&emsp;    "mode"<br>mode of the plugin<br>
&emsp;    "new_tab"<br>if should go to a newly opened tab<br>
&emsp;    "left_b"<br>how left tab border should look like<br>
&emsp;    "right_b"<br>how right tab border should look like<br>
&emsp;    "tab_space"<br>width of space between tabs<br>
&emsp;    "tab_blank"<br>how tab blanks should look like<br>
&emsp;    "tab_hi_r"<br>highlight for regular tabs<br>
&emsp;    "tab_hi_s"<br>highlight for a selected tab<br>
&emsp;    "tab_hi_b"<br>highlight for blank tabs<br>
&emsp;    "resize_timer"<br>delay before resize<br>

You can also provide it with an empty dict. 

If some items are absent then the corresponding variables will be set to defaults or your defines, which are at place when plugin started up.
