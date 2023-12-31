import std/unittest
import std/tables
import std/strutils
import repl
import variables
import sharedtestcode
import functions
import version
import comparelines
import unicodes
import vartypes

proc testHandleReplLine(
    line: string,
    eStop = false,
    eOut: string = "",
    eLog: string = "",
    eErr: string = "",
    variables: Variables = nil,
  ): bool =

  var env = openEnvTest("_handleReplLine.log")

  # Set up variables when not passed in.
  var vars = variables
  if vars == nil:
    vars = startVariables(funcs = funcsVarDict)

  let stop = handleReplLine(env, vars, line)

  let eOutLines = splitNewLines(eOut)
  let eLogLines = splitNewLines(eLog)
  let eErrLines = splitNewLines(eErr)
  result = env.readCloseDeleteCompare(eLogLines, eErrLines, eOutLines)

  if not gotExpected($stop, $eStop):
    result = false

proc testListInColumns(names: seq[string], width: Natural, expected: string): bool =
  let got = listInColumns(names, width)
  if got == expected:
    return true
  for line in names:
    echo line
  if expected == "":
    echo "width = " & $width
    echo "123456789 123456789 123456789"
    echo "---got:"
    for gotLine in splitNewLines(got):
      echo visibleControl(gotLine, spacesToo = true)
    echo "---"
    echo "---got2:"
    echo got
    echo "---"
  else:
    echo linesSideBySide(got, expected, spacesToo = true)
  return false

suite "repl.nim":

  test "handle repl line":
    check testHandleReplLine("", false)
    check testHandleReplLine(" ", false)
    check testHandleReplLine("", false)
    check testHandleReplLine("\t", false)
    check testHandleReplLine("q", true)
    check testHandleReplLine("q   ", true)

  test "help text":
    let eOut = """
Enter statements or commands at the prompt.

Available commands:

* h — this help text
* p — print a variable like in a replacement block
* pd — print a dictionary as dot names
* pf - print function names, signatures or docs, e.g. f, f.cmp, f.cmp[0]
* plc - print a list in columns
* plv - print a list vertical, one element per line
* v — print the number of variables in the one letter dictionaries
* q — quit (ctrl-d too)
"""
    check testHandleReplLine("h", false, eOut)
    check testHandleReplLine("h   ", false, eOut)

  test "show variables":
    let numFunctionKeys = funcsVarDict.len
    let eOut = "f={$1} g={} l={} o={} s={} t={3} u={}\n" % $numFunctionKeys
    check testHandleReplLine("v", false, eOut)
    check testHandleReplLine("v  ", false, eOut)

  test "invalid syntax":
    let eErr = """
repl.tea(1): w34: Missing operator, = or &=.
statement: q asdf
             ^
"""
    check testHandleReplLine("q asdf", false, eErr = eErr)

  test "p t.row":
    check testHandleReplLine("p t.row", false, "0\n")

  test "p t.version":
    check testHandleReplLine("p t.version", false, staticteaVersion & "\n")

  test "p s":
    check testHandleReplLine("p s", false, "{}\n")

  test "pd t":
    let eOut = """
t.args = {}
t.row = 0
t.version = "0.1.3"
"""
    check testHandleReplLine("pd t", false, eOut = eOut)

  test "pd dict(...)":
    let eErr = """
pd dict("a": 1", "b": 2)
           ^
Expected comma or right parentheses.
"""
    check testHandleReplLine("""pd dict("a": 1", "b": 2)""", false, eErr = eErr)

  test "pd dict(...)":
    let eOut = """
a = 1
b = 2
"""
    check testHandleReplLine("""pd dict(["a", 1, "b", 2])""", false, eOut = eOut)

  test "pd t.row":
    let eErr = """
pd t.row
   ^
The variable is not a dictionary.
"""
    check testHandleReplLine("""pd t.row""", false, eErr = eErr)

  test "pabc t.version":
    let eErr = """
repl.tea(1): w34: Missing operator, = or &=.
statement: pabc t.version
                ^
"""
    check testHandleReplLine("pabc t.version", false, eErr = eErr)

  test "plv list(...)":
    let eOut = """
1
2
3
4
"""
    check testHandleReplLine("""plv list(1, 2, 3, 4)""", false, eOut = eOut)

  test "plc list(...)":
    let eOut = """
1  9   17  25  33  41  49  57  65  73  81  89  97
2  10  18  26  34  42  50  58  66  74  82  90  98
3  11  19  27  35  43  51  59  67  75  83  91  99
4  12  20  28  36  44  52  60  68  76  84  92  100
5  13  21  29  37  45  53  61  69  77  85  93
6  14  22  30  38  46  54  62  70  78  86  94
7  15  23  31  39  47  55  63  71  79  87  95
8  16  24  32  40  48  56  64  72  80  88  96
"""
    var variables = startVariables(funcs = funcsVarDict)
    var seq = newSeq[int]()
    for num in 1 .. 100:
      seq.add(num)
    discard assignVariable(variables, "l.alist", newValue(seq))
    check testHandleReplLine("""plc alist""", false, eOut = eOut, variables = variables)

  test "run statement":
    check testHandleReplLine("a = 5", false)

  test "run function statement":
    check testHandleReplLine("""v = len("tea")""", false)

  test "run error statement":
    let eErr = """
repl.tea(1): w139: No ending double quote.
statement: v = len("tea)
                        ^
"""
    check testHandleReplLine("""v = len("tea)""", false, eErr = eErr)

  test "run error extra":
    let eErr = """
repl.tea(1): w31: Unused text at the end of the statement.
statement: v = len("tea") abc
                          ^
"""
    check testHandleReplLine("""v = len("tea") abc""", false, eErr = eErr)

  test "junk at end":
    let eErr = """
repl.tea(1): w31: Unused text at the end of the statement.
statement: a = 5 asdf
                 ^
"""
    check testHandleReplLine("a = 5 asdf", false, eErr = eErr)

  test """p len("a")""":
    let eOut = """
1
"""
    check testHandleReplLine("""p len("a")""", false, eOut = eOut)

  test """p f.cmp[0]""":
    let eOut = """
cmp
"""
    check testHandleReplLine("""p f.cmp[0]""", false, eOut = eOut)

  test """p f.cmp""":
    let eOut = """
["cmp","cmp","cmp"]
"""
    check testHandleReplLine("""p f.cmp""", false, eOut = eOut)

  test "p len  abc":
    let eErr = """
p len("a")  abc
            ^
Unused text at the end of the statement.
"""
    check testHandleReplLine("""p len("a")  abc""", false, eErr = eErr)

  test "p missing":
    let eErr = """
p missing
  ^
The variable 'missing' does not exist.
"""
    check testHandleReplLine("p missing", false, eErr = eErr)

  test "ph f.cmp":
    let eOut = """
0:  cmp = func(a: float, b: float) int
1:  cmp = func(a: int, b: int) int
2:  cmp = func(a: string, b: string, c: optional bool) int
"""
    check testHandleReplLine("pf f.cmp", eOut = eOut)

  test "ph list not functions":
    let eErr = """
pf alist
   ^
The variable is not a function variable.
"""
    var variables = startVariables(funcs = funcsVarDict)
    discard assignVariable(variables, "l.alist", newValue([1,2,3]))
    check testHandleReplLine("pf alist", eErr = eErr, variables = variables)

  test "pf f or function":
    let eErr = """
pf t
   ^
Specify u, f or a function variable.
"""
    check testHandleReplLine("pf t", eErr = eErr)

  test "listInColumns":
    let names = splitLines"""
o
tw
thr
four
fives
sevenn"""

    let expected = """
o   thr   fives
tw  four  sevenn"""
    check testListInColumns(names, 16, expected)

  test "listInColumns empty":
    let abc = splitLines("")
    check abc.len == 1

    check testListInColumns(newSeq[string](), 16, "")

  test "listInColumns o":
    let names = @["o"]
    let expected = "o"
    check testListInColumns(names, 16, expected)

  test "listInColumns 1 2":
    let names = @["1", "2"]
    let expected = "1  2"
    check testListInColumns(names, 16, expected)

  test "listInColumns longername":
    let names = @["longername", "2"]
    let expected = """
longername  2"""
    check testListInColumns(names, 16, expected)

  test "listInColumns 4 items":
    let names = splitLines"""
o
abc
de
r
t"""
    let expected = """
o    de  t
abc  r"""
    check testListInColumns(names, 12, expected)

  test "listInColumns 4":
    let names = splitLines"""
o
abc
de
123456789 12
r
t"""
    let expected = """
o
abc
de
123456789 12
r
t"""
    check testListInColumns(names, 12, expected)

  test "twocolumns":
    let names = splitLines"""
longnamehere
asdfasfdfa
column1
foasdf
fives
ab
cd
ef
gh
i
j
k"""

    let expected = """
longnamehere  cd
asdfasfdfa    ef
column1       gh
foasdf        i
fives         j
ab            k"""
    check testListInColumns(names, 16, expected)

  test "one column":
    let names = splitLines"""
123456789
asdfasfdfa
column1dd"""

    let expected = """
123456789
asdfasfdfa
column1dd"""
    check testListInColumns(names, 6, expected)

  test "stringToReplCommand":
    check stringToReplCommand("h") == h_cmd
    check stringToReplCommand("p") == p_cmd
    check stringToReplCommand("v") == v_cmd
    check stringToReplCommand("q") == q_cmd
    check stringToReplCommand("pd") == pd_cmd
    check stringToReplCommand("plc") == plc_cmd
    check stringToReplCommand("plv") == plv_cmd
    check stringToReplCommand("pf") == pf_cmd
    check stringToReplCommand("print") == not_cmd
