Treesome
========

Treesome is binary tree-based tiling layout for Awesome 3.
Similarily to tmux, it can split focused window vertically or horizontally.

The project is still in development with most of the
problems recorded in github issue tracker.


Use
---

1. Clone repository to your awesome directory

    `git clone http://github.com/RobSis/treesome.git ~/.config/awesome/treesome`

2. Add this line to rc.lua after other require functions.

    `require("treesome")`

   and add the layout 'treesome' (without apostrophes) to your layout table.

3. Restart and you're done.

By default, direction of split is decided based on the dimensions of focused client.
If you want you to force the direction of the split, map some keys like this:

```
    awful.key({ modkey }, "v", treesome.vertical),
    awful.key({ modkey }, "h", treesome.horizontal)
```


Licence
-------
GPLv2.
