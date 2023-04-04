## Time how long it takes something to run.
##
## Usage:
##
## ~~~nim
## timer = newTimer()
## # run something
## echo timer.seconds()
## ~~~

import std/times
import std/math

type
  Timer* = object
    ## Holds the start time in seconds.
    start: float

proc newTimer*(): Timer =
  ## Create a new timer and set the start time.
  result = Timer(start: cpuTime())

proc seconds*(timer: Timer, digits: Natural = 3): float =
  ## Return the elapsed seconds rounded to the specified number of
  ## digits.
  result = round(cpuTime() - timer.start, digits)
