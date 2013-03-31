Treesome
========

Treesome is binary tree-based tiling layout for Awesome 3.
Similarily to tmux, it can split focused window vertically or horizontally.


Wishlist
--------

Since the project is far from finished, here's a little
roadmap of planned features:

  * Support Resizing (by mouse)

  * Swapping clients' positions (by mouse drag)

  * Keyboard movement keys that make sense

  * Fix the damn bugs


Use
---

1. Clone repository to your awesome directory

    `git clone http://github.com/RobSis/treesome.git ~/.config/awesome/treesome`

2. Add this line to rc.lua after other require functions.

    `require("treesome")`

   and add the layout 'treesome' (without apostrophes) to your layout table.

3. Restart and you're done.

By default, direction of split is decided based on the dimensions.
If you want to choose, you can map keys to force the direction.

```
    awful.key({ modkey }, "v", treesome.vertical),
    awful.key({ modkey }, "h", treesome.horizontal)
```


Licence
-------
GPLv2.
