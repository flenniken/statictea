import unittest
import warnings
import streams
import testUtils
import strUtils

suite "Test warnings.nim":

  test "getWarning":
    let warning = getWarning("starting", 0, wNoFilename, p1="server", p2="s")
    check warning == "starting(0): w0: No server filename. Use s=filename."

  test "getWarning-file-line":
    let warning = getWarning("tea.html", 23, wNoFilename, p1="server", p2="s")
    check warning == "tea.html(23): w0: No server filename. Use s=filename."

  test "getWarning-one-p":
    let warning = getWarning("tea.html", 23, wUnknownArg, "missing")
    check warning == "tea.html(23): w2: Unknown argument: missing."

  test "warning":
    var stream = newStringStream()
    defer: stream.close()
    warning(stream, "tea.html", 23, wUnknownArg, "missing")
    let lines = stream.theLines()
    check lines.len == 1
    check lines[0] == "tea.html(23): w2: Unknown argument: missing."

  test "warningsList":
    for message in warningsList:
      if not isUpperAscii(message[0]):
        echo "The following message does not start with a capital letter."
        echo message
        check isUpperAscii(message[0]) == true
      if not (message[^1] == '.'):
        echo "The following message does not end with a period."
        echo message
        check message[^1] == '.'
