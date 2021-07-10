Vimwintab known issues
======================

[Back to main] [Back to development]

This page describes knows issues currently present in the plugin.

Here is the list of those:
* Changing the layout cannot be caught.


Changing the layout cannot be caught.
-------------------------------------

If the layout of windows is changed, like with `:h CTRL-W_H`, `:h CTRL-W_r`, etc, the plugin won't notice that. Vim doesn't provide a uniformed way of checking when windows' dimensions are changed. Workarounds are used to catch resize, but catching such changes are much trickier. 

Know solutions encompass checking windows' dimensions once for a while, after some frequent action is done, or even make a separate custom processor/filter of every key pressed by the user (Vim doesn't provide a uniformed way catching keystrokes). All of them seem to be way too computationally consuming.

The way the plugin tackles the problem now is by letting the user to redraw the bars with `:VWTRedraw`. 
