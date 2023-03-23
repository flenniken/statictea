## Private module for experimenting.

import std/terminal
import std/strformat


var file = open("term.txt", fmWrite)
for color in low(ForegroundColor) .. high(ForegroundColor):
  file.styledWrite(color, fmt"{color} some text" & "\n")
file.close()

echo "-------"
let content = readFile("term.txt")
echo content
