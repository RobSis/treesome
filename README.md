Treesome
========

Treesome is binary tree-based tiling layout for Awesome 3.4 and latter.
Similarily to tmux, it can split focused window vertically or horizontally.

The project is still in development with most of the
problems recorded in github issue tracker.


Use
---

1. Clone repository to your awesome directory

    `git clone http://github.com/RobSis/treesome.git ~/.config/awesome/treesome`

2. Add this line to rc.lua after other require functions.

    `local treesome = require("treesome")`

   and add the layout 'treesome' (without apostrophes) to your layout table.

4. Restart and you're done.

### Optional steps

1. By default, direction of split is decided based on the dimensions of focused
   client. If you want you to force the direction of the split, map some keys
   like this:

```
    awful.key({ modkey }, "v", treesome.vertical),
    awful.key({ modkey }, "h", treesome.horizontal)
```


Screenshots
-----------

![treesome in action](http://i.imgur.com/W6B7XnD.png)


Licence
-------
GPLv2.
