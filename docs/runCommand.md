# runCommand.nim

Run a command and fill in the variables dictionaries.


* [runCommand.nim](../src/runCommand.nim) &mdash; Nim source code.
# Index

* const: [tripleQuotes](#triplequotes) &mdash; Triple quotes for building strings.
* const: [maxNameLength](#maxnamelength) &mdash; The maximum length of a variable or dotname.
* type: [PosOr](#posor) &mdash; A position in a string or a message.
* type: [SpecialFunction](#specialfunction) &mdash; The special functions.
* type: [SpecialFunctionOr](#specialfunctionor) &mdash; A SpecialFunction or a warning message.
* type: [Found](#found) &mdash; The line endings found.
* type: [LinesOr](#linesor) &mdash; A list of lines or a warning.
* type: [LoopControl](#loopcontrol) &mdash; Controls whether to output the current replacement block iteration and whether to stop or not.
* [newLinesOr](#newlinesor) &mdash; Return a new LinesOr object containing a warning.
* [newLinesOr](#newlinesor-1) &mdash; Return a new LinesOr object containing a warning.
* [newLinesOr](#newlinesor-2) &mdash; Return a new LinesOr object containing a list of lines.
* [newPosOr](#newposor) &mdash; Create a PosOr warning.
* [newPosOr](#newposor-1) &mdash; Create a PosOr value.
* [newSpecialFunctionOr](#newspecialfunctionor) &mdash; Create a PosOr warning.
* [newSpecialFunctionOr](#newspecialfunctionor-1) &mdash; Create a SpecialFunctionOr value.
* [`$`](#) &mdash; Return a string representation of a Statement.
* [`==`](#-1) &mdash; Return true when the two statements are equal.
* [`==`](#-2) &mdash; Return true when a equals b.
* [`!=`](#-3) &mdash; Compare whether two PosOr are not equal.
* type: [DotNameKind](#dotnamekind) &mdash; The variable name type.
* type: [DotName](#dotname) &mdash; A variable name in a statement.
* type: [DotNameOr](#dotnameor) &mdash; A DotName or a warning.
* type: [ParameterName](#parametername) &mdash; A parameter name in a statement.
* type: [ParameterNameOr](#parameternameor) &mdash; A parameter name or a warning.
* type: [RightType](#righttype) &mdash; The type of the right hand side of a statement.
* [newDotName](#newdotname) &mdash; Create a new DotName object.
* [newDotNameOr](#newdotnameor) &mdash; Create a PosOr warning.
* [newDotNameOr](#newdotnameor-1) &mdash; Create a new DotNameOr object.
* [newParameterName](#newparametername) &mdash; Create a new ParameterName object.
* [newParameterNameOr](#newparameternameor) &mdash; Create a new ParameterNameOr object.
* [newParameterNameOr](#newparameternameor-1) &mdash; Create a warning.
* [getRightType](#getrighttype) &mdash; Return the type of the right hand side of the statement at the start position.
* [getParameterNameOr](#getparameternameor) &mdash; Get a parameter name from the statement and skip trailing whitespace.
* [getDotNameOr](#getdotnameor) &mdash; Get a dot name from the statement.
* [getDotName](#getdotname) &mdash; Get a variable name (dotname) from the statement.
* [matchTripleOrPlusSign](#matchtripleorplussign) &mdash; Match the optional """ or + at the end of the line.
* [addText](#addtext) &mdash; Add the line up to the line-ending to the text string.
* [getFragmentAndPos](#getfragmentandpos) &mdash; Split up a long statement around the given position.
* [getWarnStatement](#getwarnstatement) &mdash; Return a multiline error message.
* [warnStatement](#warnstatement) &mdash; Show an invalid statement with a pointer pointing at the start of the problem.
* [warnStatement](#warnstatement-1) &mdash; Show an invalid statement with a pointer pointing at the start of the problem.
* [removeLineEnd](#removelineend) &mdash; Return a new string with the \n or \r\n removed from the end of the line.
* [yieldStatements](#yieldstatements) &mdash; Iterate through the command's statements.
* [readStatement](#readstatement) &mdash; Read the next statement from the code file reading multiple lines if needed.
* [getMultilineStr](#getmultilinestr) &mdash; Return the triple quoted string literal.
* [matchTabSpace2](#matchtabspace2) &mdash; Match one or more spaces or tabs starting at the given position.
* [getString](#getstring) &mdash; Return a literal string value and position after it.
* [getNumber](#getnumber) &mdash; Return the literal number value and position after it.
* [skipArgument](#skipargument) &mdash; Skip past the argument.
* [ifFunctions](#iffunctions) &mdash; Return the if/if0 function's value and position after.
* [bareIfAndIf0](#bareifandif0) &mdash; Handle the bare if/if0.
* [andOrFunctions](#andorfunctions) &mdash; Return the and/or function's value and the position after.
* [getArguments](#getarguments) &mdash; Get the function arguments and the position of each.
* [getFunctionValuePosSi](#getfunctionvaluepossi) &mdash; Return the function's value and the position after it.
* [runBoolOp](#runboolop) &mdash; Evaluate the bool expression and return a bool value.
* [runCompareOp](#runcompareop) &mdash; Evaluate the comparison and return a bool value.
* [getCondition](#getcondition) &mdash; Return the bool value of the condition expression and the position after it.
* [getBracketedVarValue](#getbracketedvarvalue) &mdash; Return the value of the bracketed variable and the position after the trailing whitespace.
* [listLoop](#listloop) &mdash; Make a new list from an existing list.
* [getValuePosSi](#getvaluepossi) &mdash; Return the value and position of the item that the start parameter points at which is a string, number, variable, list, or condition.
* [runBareFunction](#runbarefunction) &mdash; Handle bare function: if, if0, return, warn, log and listLoop.
* [getBracketDotName](#getbracketdotname) &mdash; Convert var[key] to a dot name.
* [runStatement](#runstatement) &mdash; Run one statement and return the variable dot name string, operator and value.
* [skipSpaces](#skipspaces) &mdash; Skip the leading spaces and tabs.
* [callUserFunction](#calluserfunction) &mdash; Run the given user function.
* [runStatementAssignVar](#runstatementassignvar) &mdash; Run a statement and assign the variable if appropriate.
* [parseSignature](#parsesignature) &mdash; Parse the signature and return the list of parameters or a message.
* [isFunctionDefinition](#isfunctiondefinition) &mdash; If the statement is the first line of a function definition, return true and fill in the return parameters.
* [defineUserFunctionAssignVar](#defineuserfunctionassignvar) &mdash; If the statement starts a function definition, define it and assign the variable.
* [runCommand](#runcommand) &mdash; Run a command and fill in the variables dictionaries.
* [runCodeFile](#runcodefile) &mdash; Run the code file and fill in the variables.
* [runCodeFiles](#runcodefiles) &mdash; Run each code file and populate the variables.

# tripleQuotes

Triple quotes for building strings.


~~~nim
tripleQuotes = "\"\"\""
~~~

# maxNameLength

The maximum length of a variable or dotname.


~~~nim
maxNameLength = 64
~~~

# PosOr

A position in a string or a message.


~~~nim
PosOr = OpResultWarn[Natural]
~~~

# SpecialFunction

The special functions.

* spNotSpecial — not a special function
* spIf — if function
* spIf0 — if0 function
* spWarn — warn function
* spLog — log function
* spReturn — return function
* spAnd — and function
* spOr — or function
* spFunc — func function
* spListLoop — list with callback function


~~~nim
SpecialFunction {.pure.} = enum
  spNotSpecial = "not-special", spIf = "if", spIf0 = "if0", spWarn = "warn",
  spLog = "log", spReturn = "return", spAnd = "and", spOr = "or",
  spFunc = "func", spListLoop = "listLoop"
~~~

# SpecialFunctionOr

A SpecialFunction or a warning message.


~~~nim
SpecialFunctionOr = OpResultWarn[SpecialFunction]
~~~

# Found

The line endings found.

* nothing = no special ending
* plus = +
* triple = """
* newline = \\n
* plus_n = +\\n
* triple_n = """\\n
* crlf = \\r\\n
* plus_crlf = +\\r\\n
* triple_crlf = """\\r\\n


~~~nim
Found = enum
  nothing, plus, triple, newline, plus_n, triple_n, crlf, plus_crlf, triple_crlf
~~~

# LinesOr

A list of lines or a warning.


~~~nim
LinesOr = OpResultWarn[seq[string]]
~~~

# LoopControl

Controls whether to output the current replacement block
iteration and whether to stop or not.

* lcStop — do not output this replacement block and stop iterating
* lcSkip — do not output this replacement block and continue with the next iteration
* lcAdd — output the replacment block and continue with the next iteration


~~~nim
LoopControl = enum
  lcStop = "stop", lcSkip = "skip", lcAdd = "add"
~~~

# newLinesOr

Return a new LinesOr object containing a warning.


~~~nim
func newLinesOr(warning: MessageId; p1: string = ""; pos = 0): LinesOr
~~~

# newLinesOr

Return a new LinesOr object containing a warning.


~~~nim
func newLinesOr(warningData: WarningData): LinesOr
~~~

# newLinesOr

Return a new LinesOr object containing a list of lines.


~~~nim
func newLinesOr(lines: seq[string]): LinesOr
~~~

# newPosOr

Create a PosOr warning.


~~~nim
func newPosOr(warning: MessageId; p1 = ""; pos = 0): PosOr
~~~

# newPosOr

Create a PosOr value.


~~~nim
func newPosOr(pos: Natural): PosOr
~~~

# newSpecialFunctionOr

Create a PosOr warning.


~~~nim
func newSpecialFunctionOr(warning: MessageId; p1 = ""; pos = 0): SpecialFunctionOr
~~~

# newSpecialFunctionOr

Create a SpecialFunctionOr value.


~~~nim
func newSpecialFunctionOr(specialFunction: SpecialFunction): SpecialFunctionOr
~~~

# `$`

Return a string representation of a Statement.


~~~nim
func `$`(s: Statement): string {.raises: [ValueError], tags: [].}
~~~

# `==`

Return true when the two statements are equal.


~~~nim
func `==`(s1: Statement; s2: Statement): bool
~~~

# `==`

Return true when a equals b.


~~~nim
func `==`(a: PosOr; b: PosOr): bool
~~~

# `!=`

Compare whether two PosOr are not equal.


~~~nim
func `!=`(a: PosOr; b: PosOr): bool
~~~

# DotNameKind

The variable name type.

vtNormal — a variable with whitespace following it
vtFunction — a variable with ( following it
vtGet — a variable with [ following it


~~~nim
DotNameKind = enum
  vnkNormal, vnkFunction, vnkGet
~~~

# DotName

A variable name in a statement.

* dotName — the dot name string
* kind — the kind of name defined by the character following the name
* pos — the position after the trailing whitespace


~~~nim
DotName = object
  dotName*: string
  kind*: DotNameKind
  pos*: Natural
~~~

# DotNameOr

A DotName or a warning.


~~~nim
DotNameOr = OpResultWarn[DotName]
~~~

# ParameterName

A parameter name in a statement.

* name — the parameter name string
* pos — the position after the trailing whitespace


~~~nim
ParameterName = object
  name*: string
  pos*: Natural
~~~

# ParameterNameOr

A parameter name or a warning.


~~~nim
ParameterNameOr = OpResultWarn[ParameterName]
~~~

# RightType

The type of the right hand side of a statement.

* rtNothing — not a valid right hand side
* rtString — a literal string starting with a quote
* rtNumber — a literal number starting with a digit or minus sign
* rtVariable — a variable starting with a-zA-Z
* rtFunction — a function variable calling a function: len(b)
* rtList — a literal list: [1, 2, 3, len(b), 5]
* rtCondition — a condition: (a < b)
* rtGet — a index into a list or dictionary: teas[2], teas["green"]


~~~nim
RightType = enum
  rtNothing, rtString, rtNumber, rtVariable, rtList, rtCondition
~~~

# newDotName

Create a new DotName object.


~~~nim
func newDotName(dotName: string; kind: DotNameKind; pos: Natural): DotName
~~~

# newDotNameOr

Create a PosOr warning.


~~~nim
func newDotNameOr(warning: MessageId; p1 = ""; pos = 0): DotNameOr
~~~

# newDotNameOr

Create a new DotNameOr object.


~~~nim
func newDotNameOr(dotName: string; kind: DotNameKind; pos: Natural): DotNameOr
~~~

# newParameterName

Create a new ParameterName object.


~~~nim
func newParameterName(name: string; pos: Natural): ParameterName
~~~

# newParameterNameOr

Create a new ParameterNameOr object.


~~~nim
func newParameterNameOr(name: string; pos: Natural): ParameterNameOr
~~~

# newParameterNameOr

Create a warning.


~~~nim
func newParameterNameOr(warning: MessageId; p1 = ""; pos = 0): ParameterNameOr
~~~

# getRightType

Return the type of the right hand side of the statement at the
start position.


~~~nim
func getRightType(statement: Statement; start: Natural): RightType
~~~

# getParameterNameOr

Get a parameter name from the statement and skip trailing
whitespace. Start points at a name.

~~~javascript
a = func(var-name : int) dict
         ^        ^
~~~


~~~nim
proc getParameterNameOr(text: string; startPos: Natural): ParameterNameOr
~~~

# getDotNameOr

Get a dot name from the statement. Start points at a name.

~~~javascript
a = var-name( 1 )
    ^         ^
a = abc # comment
    ^   ^
a = o.def.bbb # comment
    ^         ^
~~~


~~~nim
proc getDotNameOr(text: string; startPos: Natural): DotNameOr
~~~

# getDotName

Get a variable name (dotname) from the statement. Skip leading
whitespace.


~~~nim
proc getDotName(text: string; start: Natural): DotNameOr {.raises: [KeyError],
    tags: [].}
~~~

# matchTripleOrPlusSign

Match the optional """ or + at the end of the line. This tells
whether the statement continues on the next line for code files.


~~~nim
func matchTripleOrPlusSign(line: string): Found
~~~

# addText

Add the line up to the line-ending to the text string.


~~~nim
func addText(line: string; found: Found; text: var string)
~~~

# getFragmentAndPos

Split up a long statement around the given position.  Return the
statement fragment, and the position where the fragment starts in
the statement.


~~~nim
func getFragmentAndPos(statement: Statement; start: Natural): (string, Natural)
~~~

# getWarnStatement

Return a multiline error message.


~~~nim
func getWarnStatement(filename: string; statement: Statement;
                      warningData: WarningData): string {.raises: [ValueError],
    tags: [].}
~~~

# warnStatement

Show an invalid statement with a pointer pointing at the start of
the problem. Long statements are trimmed around the problem area.


~~~nim
proc warnStatement(env: var Env; statement: Statement; warningData: WarningData;
                   sourceFilename = "") {.
    raises: [ValueError, IOError, OSError], tags: [WriteIOEffect].}
~~~

# warnStatement

Show an invalid statement with a pointer pointing at the start of the problem.


~~~nim
proc warnStatement(env: var Env; statement: Statement; messageId: MessageId;
                   p1: string; pos: Natural; sourceFilename = "") {.
    raises: [ValueError, IOError, OSError], tags: [WriteIOEffect].}
~~~

# removeLineEnd

Return a new string with the \n or \r\n removed from the end of
the line.


~~~nim
func removeLineEnd(s: string): string
~~~

# yieldStatements

Iterate through the command's statements. A statement can be
blank or all whitespace. A statement doesn't end with a newline.


~~~nim
iterator yieldStatements(cmdLines: CmdLines): Statement {.raises: [KeyError],
    tags: [].}
~~~

# readStatement

Read the next statement from the code file reading multiple lines
if needed. When there is an error, show the warning and return
nothing. When no more statements, return nothing.


~~~nim
proc readStatement(env: var Env; lb: var LineBuffer): Option[Statement] {.
    raises: [IOError, OSError, ValueError, KeyError],
    tags: [ReadIOEffect, WriteIOEffect].}
~~~

# getMultilineStr

Return the triple quoted string literal. The startPos points one
past the leading triple quote.  Return the parsed
string value and the ending position one past the trailing
whitespace.


~~~nim
func getMultilineStr(text: string; start: Natural): ValuePosSiOr
~~~

# matchTabSpace2

Match one or more spaces or tabs starting at the given position.


~~~nim
proc matchTabSpace2(line: string; start: Natural = 0): Option[Matches]
~~~

# getString

Return a literal string value and position after it. The start
parameter is the index of the first quote in the statement and
the return position is after the optional trailing white space
following the last quote.

~~~javascript
var = "hello" # asdf
      ^       ^
~~~


~~~nim
func getString(str: string; start: Natural): ValuePosSiOr
~~~

# getNumber

Return the literal number value and position after it.  The start
index points at a digit or minus sign. The position includes the
trailing whitespace.


~~~nim
func getNumber(statement: Statement; start: Natural): ValuePosSiOr
~~~

# skipArgument

Skip past the argument.  startPos points at the first character
of a function argument.  Return the first non-whitespace
character after the argument or a message when there is a
problem.
~~~javascript
a = fn( 1 )
        ^ ^
          ^^
a = fn( 1 , 2 )
        ^ ^
~~~


~~~nim
func skipArgument(statement: Statement; startPos: Natural): PosOr
~~~

# ifFunctions

Return the if/if0 function's value and position after. It
conditionally runs one of its arguments and skips the
other. Start points at the first argument of the function. The
position includes the trailing whitespace after the ending ).

This handles the three parameter form with an assignment.

~~~javascript
a = if(cond, then, else)
       ^                ^
a = if(cond, then)
       ^          ^
~~~


~~~nim
proc ifFunctions(env: var Env; specialFunction: SpecialFunction;
                 statement: Statement; start: Natural; variables: Variables;
                 topLevel = false): ValuePosSiOr {.
    raises: [Exception, KeyError], tags: [RootEffect].}
~~~

# bareIfAndIf0

Handle the bare if/if0. Return the resulting value and the
position in the statement after the if.

~~~javascript
if(cond, return("stop"))
   ^                    ^
if(c, warn("c is true"))
   ^                    ^
~~~


~~~nim
proc bareIfAndIf0(env: var Env; specialFunction: SpecialFunction;
                  statement: Statement; start: Natural; variables: Variables): ValuePosSiOr {.
    raises: [Exception, KeyError], tags: [RootEffect].}
~~~

# andOrFunctions

Return the and/or function's value and the position after. The and
function stops on the first false. The or function stops on the
first true. The rest of the arguments are skipped.
Start points at the first parameter of the function. The position
includes the trailing whitespace after the ending ).


~~~nim
proc andOrFunctions(env: var Env; specialFunction: SpecialFunction;
                    statement: Statement; start: Natural; variables: Variables;
                    listCase = false): ValuePosSiOr {.
    raises: [Exception, KeyError], tags: [RootEffect].}
~~~

# getArguments

Get the function arguments and the position of each. If an
argument has a side effect, the return value and pos and side
effect is returned, else a 0 value and seNone is returned.
~~~javascript
newList = listLoop(list, callback, state)  # comment
                   ^                       ^
newList = listLoop(return(3), callback, state)  # comment
                          ^ ^
~~~


~~~nim
proc getArguments(env: var Env; statement: Statement; start: Natural;
                  variables: Variables; listCase = false;
                  arguments: var seq[Value]; argumentStarts: var seq[Natural]): ValuePosSiOr {.
    raises: [KeyError, Exception], tags: [RootEffect].}
~~~

# getFunctionValuePosSi

Return the function's value and the position after it. Start points at the
first argument of the function. The position includes the trailing
whitespace after the ending ).

~~~javascript
a = get(b, 2, c) # condition
        ^        ^
a = get(b, len("hi"), c)
               ^    ^
~~~


~~~nim
proc getFunctionValuePosSi(env: var Env; functionName: string;
                           functionPos: Natural; statement: Statement;
                           start: Natural; variables: Variables;
                           listCase = false; topLevel = false): ValuePosSiOr {.
    raises: [KeyError, Exception], tags: [RootEffect].}
~~~

# runBoolOp

Evaluate the bool expression and return a bool value.


~~~nim
func runBoolOp(left: Value; op: string; right: Value): Value
~~~

# runCompareOp

Evaluate the comparison and return a bool value.


~~~nim
func runCompareOp(left: Value; op: string; right: Value): Value
~~~

# getCondition

Return the bool value of the condition expression and the
position after it.  The start index points at the ( left
parentheses. The position includes the trailing whitespace after
the ending ).

~~~javascript
a = (5 < 3) # condition
    ^       ^
~~~


~~~nim
proc getCondition(env: var Env; statement: Statement; start: Natural;
                  variables: Variables): ValuePosSiOr {.
    raises: [KeyError, Exception], tags: [RootEffect].}
~~~

# getBracketedVarValue

Return the value of the bracketed variable and the position after
the trailing whitespace.. Start points at the the first argument.

~~~javascript
a = list[ 4 ]
          ^  ^
a = dict[ "abc" ]
          ^      ^
~~~


~~~nim
proc getBracketedVarValue(env: var Env; statement: Statement; start: Natural;
                          container: Value; variables: Variables): ValuePosSiOr {.
    raises: [Exception, KeyError], tags: [RootEffect].}
~~~

# listLoop

Make a new list from an existing list. The callback function is
called for each item in the list and determines what goes in the
new list.  See funList_lpoal in functions.nim for more
information.

Return the listLoop value and the ending position.  Start
points at the first parameter of the function. The position
includes the trailing whitespace after the ending right
parentheses.

~~~javascript
stopped = listLoop(list, new, callback, state)
                   ^                          ^
~~~


~~~nim
proc listLoop(env: var Env; specialFunction: SpecialFunction;
              statement: Statement; start: Natural; variables: Variables): ValuePosSiOr {.
    raises: [KeyError, Exception], tags: [RootEffect].}
~~~

# getValuePosSi

Return the value and position of the item that the start
parameter points at which is a string, number, variable, list, or
condition.  The position returned includes the trailing
whitespace after the item. The ending position is pointing at the
end of the statement, or at the first non-whitespace character
after the argument. A true topLevel parameter means the item
pointed to by start is the first item after the equal sign (not
an argument).

~~~javascript
a = "tea" # string
    ^     ^
a = cmp(b, c) # calling variable
    ^         ^
a = if( bool(len(b)), d, e) # if
        ^             ^
~~~


~~~nim
proc getValuePosSi(env: var Env; statement: Statement; start: Natural;
                   variables: Variables; topLevel = false): ValuePosSiOr {.
    raises: [KeyError, Exception], tags: [RootEffect].}
~~~

# runBareFunction

Handle bare function: if, if0, return, warn, log and listLoop. A
bare function does not assign a variable.

~~~javascript
if( true, warn("tea time")) # test
^                           ^
return(5)
^        ^
~~~


~~~nim
proc runBareFunction(env: var Env; statement: Statement; start: Natural;
                     variables: Variables; leftName: DotName): ValuePosSiOr {.
    raises: [KeyError, Exception], tags: [RootEffect].}
~~~

# getBracketDotName

Convert var[key] to a dot name.

~~~javascript
key = "hello"
name[key] = 20
^         ^
=> name.hello, pos

name["hello"] = 20
^             ^
~~~


~~~nim
proc getBracketDotName(env: var Env; statement: Statement; start: Natural;
                       variables: Variables; leftName: DotName): ValuePosSiOr {.
    raises: [KeyError, ValueError], tags: [].}
~~~

# runStatement

Run one statement and return the variable dot name string,
operator and value.


~~~nim
proc runStatement(env: var Env; statement: Statement; variables: Variables): VariableDataOr {.
    raises: [KeyError, Exception, ValueError], tags: [RootEffect].}
~~~

# skipSpaces

Skip the leading spaces and tabs.


~~~nim
proc skipSpaces(text: string): Natural {.raises: [KeyError], tags: [].}
~~~

# callUserFunction

Run the given user function.


~~~nim
proc callUserFunction(env: var Env; funcVar: Value; variables: Variables;
                      arguments: seq[Value]): FunResult {.
    raises: [KeyError, Exception, ValueError, IOError, OSError],
    tags: [RootEffect, WriteIOEffect, TimeEffect].}
~~~

# runStatementAssignVar

Run a statement and assign the variable if appropriate. Return
skip, stop or continue to control the loop.


~~~nim
proc runStatementAssignVar(env: var Env; statement: Statement;
                           variables: var Variables; sourceFilename: string): LoopControl {.
    raises: [KeyError, Exception, ValueError, IOError, OSError],
    tags: [RootEffect, WriteIOEffect, TimeEffect].}
~~~

# parseSignature

Parse the signature and return the list of parameters or a
message. Start points at the first parameter.

~~~javascript
cmp = func(numStr1: string, numStr2: string) int
           ^
~~~


~~~nim
proc parseSignature(dotName: string; signature: string; start: Natural): SignatureOr {.
    raises: [KeyError], tags: [].}
~~~

# isFunctionDefinition

If the statement is the first line of a function definition,
return true and fill in the return parameters.  Return quickly
when not a function definition. The retPos points at the first
non-whitespace after the "func(".


~~~nim
proc isFunctionDefinition(statement: Statement; retLeftName: var string;
                          retOperator: var Operator; retPos: var Natural): bool {.
    raises: [KeyError], tags: [].}
~~~

# defineUserFunctionAssignVar

If the statement starts a function definition, define it and
assign the variable. A true return value means the statement(s)
were processed and maybe errors output. A false means the
statement should be processed as a regular statement.


~~~nim
proc defineUserFunctionAssignVar(env: var Env; lb: var LineBuffer;
                                 statement: Statement; variables: var Variables;
                                 sourceFilename: string; codeFile: bool): bool {.
    raises: [KeyError, ValueError, IOError, OSError],
    tags: [WriteIOEffect, ReadIOEffect].}
~~~

# runCommand

Run a command and fill in the variables dictionaries.


~~~nim
proc runCommand(env: var Env; cmdLines: CmdLines; variables: var Variables): LoopControl {.
    raises: [KeyError, Exception, ValueError, IOError, OSError],
    tags: [RootEffect, WriteIOEffect, TimeEffect].}
~~~

# runCodeFile

Run the code file and fill in the variables.


~~~nim
proc runCodeFile(env: var Env; variables: var Variables; filename: string) {.
    raises: [ValueError, IOError, OSError, Exception, KeyError],
    tags: [ReadDirEffect, WriteIOEffect, ReadIOEffect, RootEffect, TimeEffect].}
~~~

# runCodeFiles

Run each code file and populate the variables.


~~~nim
proc runCodeFiles(env: var Env; variables: var Variables; codeList: seq[string]) {.
    raises: [ValueError, IOError, OSError, Exception, KeyError],
    tags: [ReadDirEffect, WriteIOEffect, ReadIOEffect, RootEffect, TimeEffect].}
~~~


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
