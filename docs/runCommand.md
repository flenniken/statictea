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
* type: [VariableNameKind](#variablenamekind) &mdash; The variable name type.
* type: [VariableName](#variablename) &mdash; A variable name in a statement.
* type: [VariableNameOr](#variablenameor) &mdash; 
* type: [RightType](#righttype) &mdash; The type of the right hand side of a statement.
* [newVariableName](#newvariablename) &mdash; Create a new VariableName object.
* [newVariableNameOr](#newvariablenameor) &mdash; Create a PosOr warning.
* [newVariableNameOr](#newvariablenameor-1) &mdash; Create a new VariableNameOr object.
* [getRightType](#getrighttype) &mdash; Return the type of the right hand side of the statement at the start position.
* [getVariableNameOr](#getvariablenameor) &mdash; Get a variable name from the statement.
* [getVariableName](#getvariablename) &mdash; Get a variable name from the statement.
* [matchTripleOrPlusSign](#matchtripleorplussign) &mdash; Match the optional """ or + at the end of the line.
* [addText](#addtext) &mdash; Add the line up to the line-ending to the text string.
* [getFragmentAndPos](#getfragmentandpos) &mdash; Split up a long statement around the given position.
* [getWarnStatement](#getwarnstatement) &mdash; Return a multiline error message.
* [warnStatement](#warnstatement) &mdash; Show an invalid statement with a pointer pointing at the start of the problem.
* [warnStatement](#warnstatement-1) &mdash; 
* [removeLineEnd](#removelineend) &mdash; Return a new string with the n or rn removed from the end of the line.
* [yieldStatements](#yieldstatements) &mdash; Iterate through the command's statements.
* [readStatement](#readstatement) &mdash; Read the next statement from the code file reading multiple lines if needed.
* [getMultilineStr](#getmultilinestr) &mdash; Return the triple quoted string literal.
* [getString](#getstring) &mdash; Return a literal string value and position after it.
* [getNumber](#getnumber) &mdash; Return the literal number value and position after it.
* [skipArgument](#skipargument) &mdash; Skip past the argument.
* [ifFunctions](#iffunctions) &mdash; Return the if/if0 function's value and position after.
* [bareIfAndIf0](#bareifandif0) &mdash; Handle the bare if/if0.
* [andOrFunctions](#andorfunctions) &mdash; Return the and/or function's value and the position after.
* [getArguments](#getarguments) &mdash; Get the function arguments and the position of each.
* [getFunctionValueAndPos](#getfunctionvalueandpos) &mdash; Return the function's value and the position after it.
* [runBoolOp](#runboolop) &mdash; Evaluate the bool expression and return a bool value.
* [runCompareOp](#runcompareop) &mdash; Evaluate the comparison and return a bool value.
* [getCondition](#getcondition) &mdash; Return the bool value of the condition expression and the position after it.
* [getBracketedVarValue](#getbracketedvarvalue) &mdash; Return the value of the bracketed variable and the position after the trailing whitespace.
* [listLoop](#listloop) &mdash; Make a new list from an existing list.
* [getValueAndPos](#getvalueandpos) &mdash; Return the value and position of the item that the start parameter points at which is a string, number, variable, list, or condition.
* [runBareFunction](#runbarefunction) &mdash; Handle bare function: if, if0, return, warn and log.
* [runStatement](#runstatement) &mdash; Run one statement and return the variable dot name string, operator and value.
* [skipSpaces](#skipspaces) &mdash; 
* [callUserFunction](#calluserfunction) &mdash; Run the given user function.
* [runStatementAssignVar](#runstatementassignvar) &mdash; Run a statement and assign the variable if appropriate.
* [parseSignature](#parsesignature) &mdash; Parse the signature and return the list of parameters or a message.
* [isFunctionDefinition](#isfunctiondefinition) &mdash; If the statement is the first line of a function definition, return true and fill in the return parameters.
* [processFunctionSignature](#processfunctionsignature) &mdash; Process the function definition line starting at the signature string.
* [defineUserFunctionAssignVar](#defineuserfunctionassignvar) &mdash; If the statement starts a function definition, define it and assign the variable.
* [runCommand](#runcommand) &mdash; Run a command and fill in the variables dictionaries.
* [runCodeFile](#runcodefile) &mdash; Run the code file and fill in the variables.
* [runCodeFiles](#runcodefiles) &mdash; Run each code file and populate the variables.

# tripleQuotes

Triple quotes for building strings.

```nim
tripleQuotes = "\"\"\""
```

# maxNameLength

The maximum length of a variable or dotname.

```nim
maxNameLength = 64
```

# PosOr

A position in a string or a message.

```nim
PosOr = OpResultWarn[Natural]
```

# SpecialFunction

The special functions.

* spNotSpecial -- not a special function
* spIf -- if function
* spIf0 -- if0 function
* spWarn -- warn function
* spLog -- log function
* spReturn -- return function
* spAnd -- and function
* spOr -- or function
* spFunc -- func function
* spListLoop -- list with callback function

```nim
SpecialFunction
```

# SpecialFunctionOr

A SpecialFunction or a warning message.

```nim
SpecialFunctionOr = OpResultWarn[SpecialFunction]
```

# Found

The line endings found.

* nothing = no special ending
* plus = +
* triple = """
* newline = \n
* plus_n = +\n
* triple_n = """\n
* crlf = \r\n
* plus_crlf = +\r\n
* triple_crlf = """\r\n

```nim
Found = enum
  nothing, plus, triple, newline, plus_n, triple_n, crlf, plus_crlf, triple_crlf
```

# LinesOr

A list of lines or a warning.

```nim
LinesOr = OpResultWarn[seq[string]]
```

# LoopControl

Controls whether to output the current replacement block iteration and whether to stop or not.

* lcStop -- do not output this replacement block and stop iterating
* lcSkip -- do not output this replacement block and continue with the next iteration
* lcAdd -- output the replacment block and continue with the next iteration

```nim
LoopControl = enum
  lcStop = "stop", lcSkip = "skip", lcAdd = "add"
```

# newLinesOr

Return a new LinesOr object containing a warning.

```nim
func newLinesOr(warning: MessageId; p1: string = ""; pos = 0): LinesOr
```

# newLinesOr

Return a new LinesOr object containing a warning.

```nim
func newLinesOr(warningData: WarningData): LinesOr
```

# newLinesOr

Return a new LinesOr object containing a list of lines.

```nim
func newLinesOr(lines: seq[string]): LinesOr
```

# newPosOr

Create a PosOr warning.

```nim
func newPosOr(warning: MessageId; p1 = ""; pos = 0): PosOr
```

# newPosOr

Create a PosOr value.

```nim
func newPosOr(pos: Natural): PosOr
```

# newSpecialFunctionOr

Create a PosOr warning.

```nim
func newSpecialFunctionOr(warning: MessageId; p1 = ""; pos = 0): SpecialFunctionOr
```

# newSpecialFunctionOr

Create a SpecialFunctionOr value.

```nim
func newSpecialFunctionOr(specialFunction: SpecialFunction): SpecialFunctionOr
```

# `$`

Return a string representation of a Statement.

```nim
func `$`(s: Statement): string
```

# `==`

Return true when the two statements are equal.

```nim
func `==`(s1: Statement; s2: Statement): bool
```

# `==`

Return true when a equals b.

```nim
func `==`(a: PosOr; b: PosOr): bool
```

# `!=`

Compare whether two PosOr are not equal.

```nim
func `!=`(a: PosOr; b: PosOr): bool
```

# VariableNameKind

The variable name type.

vtNormal -- a variable with whitespace following it
vtFunction -- a variable with ( following it
vtGet -- a variable with [ following it

```nim
VariableNameKind = enum
  vnkNormal, vnkFunction, vnkGet
```

# VariableName

A variable name in a statement.

* dotName -- the dot name string
* kind -- the kind of name defined by the character following the name
* pos -- the position after the trailing whitespace

```nim
VariableName = object
  dotName*: string
  kind*: VariableNameKind
  pos*: Natural

```

# VariableNameOr



```nim
VariableNameOr = OpResultWarn[VariableName]
```

# RightType

The type of the right hand side of a statement.

rtNothing -- not a valid right hand side
rtString -- a literal string starting with a quote
rtNumber -- a literal number starting with a digit or minus sign
rtVariable -- a variable starting with a-zA-Z
rtFunction -- a function variable calling a function: len(b)
rtList -- a literal list: [1, 2, 3, len(b), 5]
rtCondition -- a condition: (a < b)
rtGet -- a index into a list or dictionary: teas[2], teas["green"]

```nim
RightType = enum
  rtNothing, rtString, rtNumber, rtVariable, rtList, rtCondition
```

# newVariableName

Create a new VariableName object.

```nim
func newVariableName(dotName: string; kind: VariableNameKind; pos: Natural): VariableName
```

# newVariableNameOr

Create a PosOr warning.

```nim
func newVariableNameOr(warning: MessageId; p1 = ""; pos = 0): VariableNameOr
```

# newVariableNameOr

Create a new VariableNameOr object.

```nim
func newVariableNameOr(dotName: string; kind: VariableNameKind; pos: Natural): VariableNameOr
```

# getRightType

Return the type of the right hand side of the statement at the start position.

```nim
func getRightType(statement: Statement; start: Natural): RightType
```

# getVariableNameOr

Get a variable name from the statement. Start points at a name.

~~~
a = var-name( 1 )
    ^         ^
a = abc # comment
    ^   ^
a = o.def.bbb # comment
    ^         ^
~~~

```nim
proc getVariableNameOr(text: string; startPos: Natural): VariableNameOr
```

# getVariableName

Get a variable name from the statement. Skip leading whitespace.

```nim
proc getVariableName(text: string; start: Natural): VariableNameOr
```

# matchTripleOrPlusSign

Match the optional """ or + at the end of the line. This tells whether the statement continues on the next line for code files.

```nim
func matchTripleOrPlusSign(line: string): Found
```

# addText

Add the line up to the line-ending to the text string.

```nim
func addText(line: string; found: Found; text: var string)
```

# getFragmentAndPos

Split up a long statement around the given position.  Return the statement fragment, and the position where the fragment starts in the statement.

```nim
func getFragmentAndPos(statement: Statement; start: Natural): (string, Natural)
```

# getWarnStatement

Return a multiline error message.

```nim
func getWarnStatement(filename: string; statement: Statement;
                      warningData: WarningData): string
```

# warnStatement

Show an invalid statement with a pointer pointing at the start of the problem. Long statements are trimmed around the problem area.

```nim
proc warnStatement(env: var Env; statement: Statement; warningData: WarningData;
                   sourceFilename = "")
```

# warnStatement



```nim
proc warnStatement(env: var Env; statement: Statement; messageId: MessageId;
                   p1: string; pos: Natural; sourceFilename = "")
```

# removeLineEnd

Return a new string with the n or rn removed from the end of the line.

```nim
func removeLineEnd(s: string): string
```

# yieldStatements

Iterate through the command's statements. A statement can be blank or all whitespace.

```nim
iterator yieldStatements(cmdLines: CmdLines): Statement
```

# readStatement

Read the next statement from the code file reading multiple lines if needed.

```nim
proc readStatement(env: var Env; lb: var LineBuffer): Option[Statement]
```

# getMultilineStr

Return the triple quoted string literal. The startPos points one
past the leading triple quote.  Return the parsed
string value and the ending position one past the trailing
whitespace.

```nim
func getMultilineStr(text: string; start: Natural): ValueAndPosOr
```

# getString

Return a literal string value and position after it. The start parameter is the index of the first quote in the statement and the return position is after the optional trailing white space following the last quote.

```nim
func getString(statement: Statement; start: Natural): ValueAndPosOr
```

# getNumber

Return the literal number value and position after it.  The start index points at a digit or minus sign. The position includes the trailing whitespace.

```nim
func getNumber(statement: Statement; start: Natural): ValueAndPosOr
```

# skipArgument

Skip past the argument.  startPos points at the first character of a function argument.  Return the first non-whitespace character after the argument or a message when there is a problem.
~~~
a = fn( 1 )
        ^ ^
          ^^
a = fn( 1 , 2 )
        ^ ^
~~~

```nim
func skipArgument(statement: Statement; startPos: Natural): PosOr
```

# ifFunctions

Return the if/if0 function's value and position after. It conditionally runs one of its arguments and skips the other. Start points at the first argument of the function. The position includes the trailing whitespace after the ending ).

This handles the three parameter form with an assignment.

~~~
a = if(cond, then, else)
       ^                ^
~~~

```nim
proc ifFunctions(env: var Env; specialFunction: SpecialFunction;
                 statement: Statement; start: Natural; variables: Variables): ValueAndPosOr
```

# bareIfAndIf0

Handle the bare if/if0. Return the resulting value and the position in the statement after the if.

~~~
if(cond, return("stop"))
   ^                    ^
if(c, warn("c is true"))
   ^                    ^
~~~

```nim
proc bareIfAndIf0(env: var Env; specialFunction: SpecialFunction;
                  statement: Statement; start: Natural; variables: Variables): ValueAndPosOr
```

# andOrFunctions

Return the and/or function's value and the position after. The and function stops on the first false. The or function stops on the first true. The rest of the arguments are skipped. Start points at the first parameter of the function. The position includes the trailing whitespace after the ending ).

```nim
proc andOrFunctions(env: var Env; specialFunction: SpecialFunction;
                    statement: Statement; start: Natural; variables: Variables;
                    list = false): ValueAndPosOr
```

# getArguments

Get the function arguments and the position of each. If an argument has a side effect, the return value and pos and side effect is returned, else a 0 value and seNone is returned.
~~~
newList = listLoop(list, callback, state)  # comment
                   ^                       ^
newList = listLoop(return(3), callback, state)  # comment
                          ^ ^
~~~

```nim
proc getArguments(env: var Env; statement: Statement; start: Natural;
                  variables: Variables; list = false; arguments: var seq[Value];
                  argumentStarts: var seq[Natural]): ValueAndPosOr
```

# getFunctionValueAndPos

Return the function's value and the position after it. Start points at the first argument of the function. The position includes the trailing whitespace after the ending ).

~~~
a = get(b, 2, c) # condition
        ^        ^
a = get(b, len("hi"), c)
               ^    ^
~~~

```nim
proc getFunctionValueAndPos(env: var Env; functionName: string;
                            functionPos: Natural; statement: Statement;
                            start: Natural; variables: Variables; list = false): ValueAndPosOr
```

# runBoolOp

Evaluate the bool expression and return a bool value.

```nim
func runBoolOp(left: Value; op: string; right: Value): Value
```

# runCompareOp

Evaluate the comparison and return a bool value.

```nim
func runCompareOp(left: Value; op: string; right: Value): Value
```

# getCondition

Return the bool value of the condition expression and the position after it.  The start index points at the ( left parentheses. The position includes the trailing whitespace after the ending ).

~~~
a = (5 < 3) # condition
    ^       ^
~~~

```nim
proc getCondition(env: var Env; statement: Statement; start: Natural;
                  variables: Variables): ValueAndPosOr
```

# getBracketedVarValue

Return the value of the bracketed variable and the position after the trailing whitespace.. Start points at the the first argument.

~~~
a = list[ 4 ]
          ^  ^
a = dict[ "abc" ]
          ^      ^
~~~

```nim
proc getBracketedVarValue(env: var Env; statement: Statement; start: Natural;
                          container: Value; variables: Variables): ValueAndPosOr
```

# listLoop

Make a new list from an existing list. The callback function is called for each item in the list and determines what goes in the new list.  See funList_lpoal in functions.nim for more information.

Return the listLoop value and the ending position.  Start
points at the first parameter of the function. The position
includes the trailing whitespace after the ending right
parentheses.

~~~
stopped = listLoop(list, new, callback, state)
                   ^                          ^
~~~

```nim
proc listLoop(env: var Env; specialFunction: SpecialFunction;
              statement: Statement; start: Natural; variables: Variables;
              list = false): ValueAndPosOr
```

# getValueAndPos

Return the value and position of the item that the start parameter points at which is a string, number, variable, list, or condition. The position returned includes the trailing whitespace after the item. So the ending position is pointing at the end of the statement, or at the first non-whitespace character after the item.

~~~
a = "tea" # string
    ^     ^
a = 123.5 # number
    ^     ^
a = t.row # variable
    ^     ^
a = [1, 2, 3] # list
    ^         ^
a = (c < 10) # condition
    ^        ^
a = cmp(b, c) # calling variable
    ^         ^
a = if( (b < c), d, e) # if
    ^                  ^
a = if( bool(len(b)), d, e) # if
    ^                       ^
        ^             ^
             ^     ^
                 ^^
                      ^  ^
                         ^  ^
~~~

```nim
proc getValueAndPos(env: var Env; statement: Statement; start: Natural;
                    variables: Variables): ValueAndPosOr
```

# runBareFunction

Handle bare function: if, if0, return, warn and log. A bare function does not assign a variable.

~~~
if( true, warn("tea time")) # test
^                           ^
return(5)
^        ^
~~~

```nim
proc runBareFunction(env: var Env; statement: Statement; start: Natural;
                     variables: Variables; leftName: VariableName): ValueAndPosOr
```

# runStatement

Run one statement and return the variable dot name string, operator and value.

```nim
proc runStatement(env: var Env; statement: Statement; variables: Variables): VariableDataOr
```

# skipSpaces



```nim
proc skipSpaces(text: string): Natural
```

# callUserFunction

Run the given user function.

```nim
proc callUserFunction(env: var Env; funcVar: Value; variables: Variables;
                      arguments: seq[Value]): FunResult
```

# runStatementAssignVar

Run a statement and assign the variable if appropriate. Return skip, stop or continue to control the loop.

```nim
proc runStatementAssignVar(env: var Env; statement: Statement;
                           variables: var Variables; sourceFilename: string;
                           codeLocation: CodeLocation): LoopControl
```

# parseSignature

Parse the signature and return the list of parameters or a message.

Example signatures:
~~~
cmp(numStr1: string, numStr2: string) int
get(group: list, ix: int, optional any) any
~~~

```nim
proc parseSignature(signature: string): SignatureOr
```

# isFunctionDefinition

If the statement is the first line of a function definition, return true and fill in the return parameters.  Return quickly when not a function definition. The retPos points at the first non-whitespace after the "func(".

```nim
proc isFunctionDefinition(statement: Statement; retLeftName: var string;
                          retOperator: var Operator; retPos: var Natural): bool
```

# processFunctionSignature

Process the function definition line starting at the signature string. The start parameter points at the first non-whitespace character after "func(".

Example:
mycmp = func("numStrCmp(numStr1: string, numStr2: string) int")
             ^ start

```nim
proc processFunctionSignature(statement: Statement; start: Natural): SignatureOr
```

# defineUserFunctionAssignVar

If the statement starts a function definition, define it and assign the variable. A true return value means the statement(s) were processed and maybe errors output. A false means the statement should be processed as a regular statement.

```nim
proc defineUserFunctionAssignVar(env: var Env; lb: var LineBuffer;
                                 statement: Statement; variables: var Variables;
                                 sourceFilename: string; codeFile: bool): bool
```

# runCommand

Run a command and fill in the variables dictionaries.

```nim
proc runCommand(env: var Env; cmdLines: CmdLines; variables: var Variables;
                codeLocation: CodeLocation): LoopControl
```

# runCodeFile

Run the code file and fill in the variables.

```nim
proc runCodeFile(env: var Env; variables: var Variables; filename: string)
```

# runCodeFiles

Run each code file and populate the variables.

```nim
proc runCodeFiles(env: var Env; variables: var Variables; codeList: seq[string])
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
