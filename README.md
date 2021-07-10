Vimwintab
=========

**A plugin that adds "IDE-like" tabs to Vim, which allows you to have regular
tabs you are used to in every window you want to.**

To find out how to use the plugin see a brief [USER GIDE].

To learn more about the plugin please refer to the Table of Contents section at the end of this file.

To see the license this plugin is distributed on go to [License].

Description
----------

In Vim, we don't really have tabs in its regular meaning. Vim tabs encompass windows, but don't show what files are opened in these windows. So, long story short, **vimwintab** plugin adds to Vim a functionality of regular tabs that you can find in many text editors. Hence the name - "Vim Windows Tabs".

Each tab represents a buffer associated with a window. Multiple windows may have the same buffer opened as a tab. At one point of time any window may have 
one current tab, with the represented buffer displayed in the window. Current tab may be switched to the left or right one, and if you try to go beyond any end of the tab bar it will wrap.

Navigation between tabs is not interconnected with the buffer list and is done via plugin's own commands. To know how to use the plugin see the [USER GUIDE].

Tabs are added to windows according to the mode the plugin operates in. There are several of those, each of them provides different detection patterns which the plugin will follow to determine if a buffer needs to be added to a tab bar.

In general, plugin is very customizable - you can determine, how it will operate, in which mode, how individual tabs will look like, etc. To know how see [Customizing the plugin].

Installation
------------

To know how to install the plugin go to [Installation] page.

Development
-----------

If you are interested in contributing to the plugin's development or have any any suggestions please refer to the [Development] and [Contacts] sections.

Table of Contents
-----------------

[USER GUIDE] [License] [Customizing the plugin] [Installation] [Development] [Contacts]
