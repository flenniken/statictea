import std/unittest
import std/strUtils
import std/strformat
import messages
import warnings

{. hint: & "hello" .}

func countLetter(message: string, letter: char): int =
  ## Count the number of times letter is used in the given string.
  for ch in message:
    if ch == letter:
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

  test "getWarning 0":
    let warning = getWarning("starting", 0, wSuccess)
    check warning == "starting(0): w0: Success."

  test "getWarning":
    let warning = getWarning("starting", 5, wNoFilename, p1="server")
    check warning == "starting(5): w133: No server filename."

  test "getWarning-file-line":
    let warning = getWarning("tea.html", 23, wNoFilename, p1="server")
    check warning == "tea.html(23): w133: No server filename."

  test "getWarning-one-p":
    let warning = getWarning("tea.html", 23, wUnknownArg, "missing")
    check warning == "tea.html(23): w2: Unknown argument: missing."

  test "warningsList":
    for message in Messages:
      if not isUpperAscii(message[0]):
        echo "The following message does not start with a capital letter."
        echo message
        check isUpperAscii(message[0]) == true
      if not (message[^1] == '.' or message[^1] == '?' ):
        echo "The following message does not end with a period or question mark."
        echo message
        check message[^1] == '.'
      let count = message.countLetter('$')
      if count > 2:
        echo "The message has too many $ characters."
        echo message
        check count <= 2
