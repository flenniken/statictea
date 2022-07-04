## Compare lines of text.

import std/strutils
import std/os
import opresult
import unicodes

type
  OpResultStr*[T] = OpResult[T, string]
    ## On success return T, otherwise return a message telling what went wrong.

func opValueStr*[T](value: T): OpResultStr[T] =
  ## Return an OpResultStr with a value.
  result = OpResult[T, string](kind: orValue, value: value)

func opMessageStr*[T](message: string): OpResultStr[T] =
  ## Return an OpResultStr with a message why the value cannot be returned.
  result = OpResult[T, string](kind: orMessage, message: message)

func splitNewLines*(content: string): seq[string] =
  ## Split lines and keep the line endings. Works with \n and \r\n
  ## type endings.
  if content.len == 0:
    return
  var start = 0
  for pos in 0 ..< content.len:
    let ch = content[pos]
    if ch == '\n':
      result.add(content[start .. pos])
      start = pos+1
  if start < content.len:
    result.add(content[start ..< content.len])

proc readFileContent(filename: string): OpResultStr[string] =
  ## Read the file and return the content as a string.
  try:
    let content = readFile(filename)
    result = opValueStr[string](content)
  except:
    result = opMessageStr[string](getCurrentExceptionMsg())

proc linesSideBySide*(gotContent: string, expectedContent: string): string =
  ## Show the two sets of lines side by side.

  if gotContent == "" and expectedContent == "":
     return "both empty"

  let got = splitNewLines(gotContent)
  let expected = splitNewLines(expectedContent)

  var show = visibleControl

  var lines: seq[string]
  for ix in countUp(0, max(got.len, expected.len)-1):
    var gLine = ""
    if ix < got.len:
      gLine = $got[ix]

    var eLine = ""
    if ix < expected.len:
      eLine = $expected[ix]

    var lineNum = $(ix+1)
    if eLine == gLine:
      # lines.add("$1     same: $2" % [dup(" ", lineNum.len), show(eLine)])
      lines.add("$1     same: $2" % [$lineNum, show(eLine)])
    else:
      lines.add("$1      got: $2" % [lineNum, show(gLine)])
      lines.add("$1 expected: $2" % [lineNum, show(eLine)])

  result = lines.join("\n")

proc compareFiles*(gotFilename: string, expectedFilename: string): OpResultStr[string] =
  ## Compare two files and return the differences. When they are equal
  ## return "".

  let (_, gotBasename) = splitPath(gotFilename)
  let (_, expBasename) = splitPath(expectedFilename)

  # Read the "got" file.
  var gotContent: string
  if gotBasename == "empty":
    gotContent = ""
  else:
    let gotContentOp = readFileContent(gotFilename)
    if gotContentOp.isMessage:
      return opMessageStr[string]("Error: " & gotContentOp.message)
    gotContent = gotContentOp.value

  # Read the "expected" file.
  var expectedContent: string
  if expBasename == "empty":
    expectedContent = ""
  else:
    let expectedContentOp = readFileContent(expectedFilename)
    if expectedContentOp.isMessage:
      return opMessageStr[string]("Error: " & expectedContentOp.message)
    expectedContent = expectedContentOp.value

  #  ⤶ ⤷ ⤴ ⤵
  # ⬉ ⬈ ⬊ ⬋
  let topBorder    = "───────────────────⤵\n"
  let bottomBorder = "───────────────────⤴"


# Difference: result.expected != result.txt
#             result.expected is empty
# result.txt───────────────────⤵
# Log the replacement block.
# Log the replacement block containing a variable.
# Log the replacement block two times.
# Log the nextline replacement block.
# Log the replace command's replacement block.
# ───────────────────⤴


  # If the files are different, show the differences.
  var message: string
  if gotContent != expectedContent:
    let (_, gotBasename) = splitPath(gotFilename)
    let (_, expBasename) = splitPath(expectedFilename)

    if gotContent == "" or expectedContent == "":
      if gotContent == "":
        message = """

Difference: $1 != $2
            $1 is empty
$2$3$4$5
""" % [gotBasename, expBasename, topBorder, expectedContent, bottomBorder]

      else:

        message = """

Difference: $1 != $2
            $2 is empty
$1$3$4$5
""" % [gotBasename, expBasename, topBorder, gotContent, bottomBorder]

    else:
      message = """

Difference: $1 (got) != $2 (expected)
$3
""" % [gotBasename, expBasename, linesSideBySide(gotContent, expectedContent)]

  return opValueStr[string](message)
