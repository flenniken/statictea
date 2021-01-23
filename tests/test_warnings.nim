import unittest
import warnings
import strUtils

func countLetter(message: string, letter: char): int =
  ## Count the number of letters in the given string.
  var pos = 0
  while true:
    pos = message.find(letter, pos)
    if pos == -1:
      break
    inc(pos)
    inc(result)

suite "warnings.nim":

  test "countLetter":
    check countLetter("", '1') == 0
    check countLetter("2", '1') == 0
    check countLetter("345", '1') == 0
    check countLetter("abc4", '1') == 0
    check countLetter("1", '1') == 1
    check countLetter("12345", '2') == 1
    check countLetter("234", '2') == 1
    check countLetter("234", '4') == 1
    check countLetter("22342", '2') == 3
    check countLetter("222", '2') == 3

  test "getWarning":
    let warning = getWarning("starting", 0, wNoFilename, p1="server", p2="s")
    check warning == "starting(0): w0: No server filename. Use s=filename."

  test "getWarning-file-line":
    let warning = getWarning("tea.html", 23, wNoFilename, p1="server", p2="s")
    check warning == "tea.html(23): w0: No server filename. Use s=filename."

  test "getWarning-one-p":
    let warning = getWarning("tea.html", 23, wUnknownArg, "missing")
    check warning == "tea.html(23): w2: Unknown argument: missing."

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
      let count = message.countLetter('$')
      if count > 2:
        echo "The message has too many $ characters."
        echo message
        check count <= 2
