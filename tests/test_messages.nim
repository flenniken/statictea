import std/unittest
import std/strutils
import messages

# {. hint: & "my special hint" .}

func countLetter(message: string, letter: char): int =
  ## Count the number of times letter is used in the given string.
  for ch in message:
    if ch == letter:
      inc(result)

suite "messages.nim":

  test "starts at 0":
    check low(MessageId) == wSuccess
    check ord(low(MessageId)) == 0

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

  test "getWarningLine 0":
    let warning = getWarningLine("starting", 0, wSuccess)
    check warning == "starting(0): w0: Success."

  test "getWarningLine":
    let warning = getWarningLine("starting", 5, wNoFilename, p1="server")
    check warning == "starting(5): w133: No server filename."

  test "getWarningLine-file-line":
    let warning = getWarningLine("tea.html", 23, wNoFilename, p1="server")
    check warning == "tea.html(23): w133: No server filename."

  test "getWarningLine-one-p":
    let warning = getWarningLine("tea.html", 23, wUnknownArg, "missing")
    check warning == "tea.html(23): w2: Unknown argument: missing."

  test "string rep":
    let warning = newWarningData(wUnknownArg, "p1", 5)
    check $warning == """wUnknownArg p1="p1" pos=5"""

  test "warningsList":
    check Messages.len > 0
    for ix, message in Messages:
      if message == "$1" or message == "":
        continue
      if not isUpperAscii(message[0]):
        echo "The following message does not start with a capital letter."
        echo message
        check isUpperAscii(message[0]) == true
      if not (message[^1] == '.' or message[^1] == '?'):
        echo "The following message does not end with a period or question mark."
        echo "$1" % $ix
        echo message
        check message[^1] == '.'
      let count = message.countLetter('$')
      if count > 1:
        echo "The message has too many $ characters."
        echo message
        check count <= 1
