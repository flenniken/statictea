## Private module for experimenting.

import std/os
import std/strutils

let count = paramCount() + 1
for ix in 0 .. count - 1:
  echo "$1: $2" % [$ix, paramStr(ix)]
