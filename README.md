Treesome
========

Treesome is binary tree-based tiling layout for Awesome 3.4 and latter.
Similarly to tmux, it can split focused window either vertically or horizontally.

The project is still in the development. Feel free to fork/contribute!


Use
---

1. Clone repository to your awesome directory

    `git clone http://github.com/RobSis/treesome.git ~/.config/awesome/treesome`

2. Add this line to your rc.lua below other require calls.

    `local treesome = require("treesome")`

3. And finally add the layout `treesome` to your layout table.

```
    local layouts = {
        ...
        treesome
    }
```

4. Restart and you're done.


### Optional steps

1. By default, direction of split is decided based on the dimensions of focused
   client. If you want you to force the direction of the split, bind keys to
   `treesome.vertical` and `treesome.horizontal` functions. For example:

```
    awful.key({ modkey }, "v", treesome.vertical),
    awful.key({ modkey }, "h", treesome.horizontal)
```


Screenshots
-----------

![treesome in action](http://i.imgur.com/W6B7XnD.png)


Licence
-------

[GPL 2.0](http://www.gnu.org/licenses/gpl-2.0.html)
