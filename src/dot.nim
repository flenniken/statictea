## Parse dot files.

import std/options
import std/strutils

type
  Dependency* = object
    left*: string
    right*: string

proc `$`*(dep: Dependency): string =
  ## Return a string representation of a Dependency.
  result = """$1 -> "$2";""" % [dep.left, dep.right]

proc `==`*(dep1: Dependency, dep2: Dependency): bool =
  ## Return true when two deps are equal.
  if dep1.left == dep2.left and
     dep1.right == dep2.right:
    return true
  return false

func newDependency*(left: string, right: string): Dependency =
  result = Dependency(left: left, right: right)

proc parseDotLine*(line: string): Option[Dependency] =
  ## Parse a dot line and return the left and right values, a
  ## Dependency object.

  # You cannot import re in nimble.

  var pos2 = 0
  var left: string
  if line.len == 0 or line[0] != '"':
    # in 1.4.2
    # tempFile -> "random";
    let pos = find(line, " ")
    if pos == -1:
     return
    if pos <= 0:
     return
    left = line[0 .. pos - 1]
    pos2 = find(line, "-> \"", pos)
  else:
    # in 1.6.2
    # "tempFile" -> "random";
    let pos = find(line, "\"", 1)
    if pos == -1:
      return
    if pos <= 0:
      return
    left = line[1 .. pos - 1]
    pos2 = find(line, "-> \"", pos)
  if pos2 == -1:
    return
  let startPos = pos2 + 4
  if startPos >= line.len:
    return
  let endPos = find(line, "\";", startPos)
  if endPos == -1:
    return
  if endPos - 1 < startPos:
    return
  let right = line[startPos .. endPos - 1]
  result = some(newDependency(left, right))
