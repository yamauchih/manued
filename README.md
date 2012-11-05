manued
======

Manued is a proofreading method. This is an emacs implementation.


README
======

manued Copyright 1998-2012 (C) Hitoshi Yamauchi

This is a quick reference.

1. What is manued?
------------------

Manued is a proofreading method of manuscripts. This method is
proposed by Ikuo Takeuchi in No.39 Programming symposium of Japan,
1998. (http://www.ipsj.or.jp/prosym/) Althogh manued is a media
independent proofreading method, it is especially effective for
exchanging electric texts via E-mail.

Manued web page
*  https://github.com/yamauchih/manued
*  http://www.mpi-inf.mpg.de/~hitoshi/otherprojects/manued/index.shtml

2. Installation
---------------

manued.el depends on after Emacs Version 20. The author tested
manued.el on GNU XEmacs 21.4 (patch 6) and GNU Emacs 20.7.2.

# Put the manued.el file on your emacs `load-path'.
# Add the next line to your .emacs file.
  (autoload 'manued-minor-mode "manued" "manuscript editing mode" t)

3. Starting Manued
------------------

Type M-x manued-minor-mode.

* Tutorial

There is a tutorial/English/manued.tut. Please open it by emacs.

* manued-minor-mode

(a) To enter manued-minor-mode, please type "M-x
    manued-minor-mode".

(b) Type some texts in the buffer.

(c) To insert manued swap command, put a mark and type M-x
    manued:insert-swap-command (or type C-c C-m C-s).

(d) To extract revised document in another buffer, Type
    manued:show-newer-in-manued-buffer.

(e) Others: please select a menu item. Type M-n or M-p, this
    is the search command for manued command.

4. Documentations
-----------------

More details are in the doc/ directory. Have fun!.


COPYING
=======

Copyright (C) 1998-2012 Hitoshi Yamauchi

This software is free software. There is absolutely no warranty about
this program. This software can be redistributed only under GNU
copyleft (most recently version of GNU General Public License). See
doc/manued-j/manued-j.html (In Japanese) or doc/manued-e/manued-e.html
(In English).

