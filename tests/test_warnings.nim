import unittest
import warnings
import streams
import testUtils
import strUtils

suite "Test warnings.nim":

  test "getWarning":
    let warning = getWarning("starting", 0, warnNoFilename, p1="server", p2="s")
    check warning == "starting(0): w0: No server filename. Use s=filename."

  test "getWarning-file-line":
    let warning = getWarning("tea.html", 23, warnNoFilename, p1="server", p2="s")
    check warning == "tea.html(23): w0: No server filename. Use s=filename."

  test "getWarning-one-p":
    let warning = getWarning("tea.html", 23, warnUnknownArg, "missing")
    check warning == "tea.html(23): w2: Unknown argument: missing."

  test "warning":
    var stream = newStringStream()
    defer: stream.close()
    warning(stream, "tea.html", 23, warnUnknownArg, "missing")
    let lines = stream.readLines()
    check lines.len == 1
    check lines[0] == "tea.html(23): w2: Unknown argument: missing."

  test "warningsList":
    for message in warningsList:
      # Verify messages start with a capital letter.
      check isUpperAscii(message[0]) == true
      # Verfiy messages end with a period.
      check message[^1] == '.'
