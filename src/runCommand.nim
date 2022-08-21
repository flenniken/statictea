## Run a command and fill in the variables dictionaries.

import std/options
import std/strutils
import std/tables
import readLines
import matches
import regexes
import env
import vartypes
import messages
import warnings
import parseNumber
import variables
import funtypes
import runFunction
import readjson
import collectCommand
import opresultwarn
import unicodes

const
  # Turn on showPos for testing to graphically show the start and end
  # positions when running a statement.
  showPos = false

type
  Statement* = object
    ## A Statement object stores the statement text and where it
    ## @:starts in the template file.
    ## @:
    ## @:* lineNum -- line number, starting at 1, where the statement
    ## @:             starts.
    ## @:* start -- index where the statement starts
    ## @:* text -- the statement text.
    lineNum*: Natural
    start*: Natural
    text*: string

  ValueAndLength* = object
    ## A value and the length of the matching text in the statement.
    ## For the example statement: "var = 567 ". The value 567 starts
    ## at index 6 and the matching length is 4 because it includes the
    ## trailing space. For example "id = row(3 )" the value is 3 and
    ## the length is 2. Exit is set true by the return function to
    ## exit a command.
    value*: Value
    length*: Natural
    exit*: bool

  ValueAndLengthOr* = OpResultWarn[ValueAndLength]

proc newValueAndLength*(value: Value, length: Natural,
    exit = false): ValueAndLength =
  ## Create a newValueAndLength object.
  result = ValueAndLength(value: value, length: length)

func newValueAndLengthOr*(warning: MessageId, p1 = "", pos = 0):
    ValueAndLengthOr =
  ## Create a ValueAndLengthOr warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[ValueAndLength](warningData)

func newValueAndLengthOr*(warningData: WarningData):
    ValueAndLengthOr =
  ## Create a ValueAndLengthOr warning.
  result = opMessageW[ValueAndLength](warningData)

func newValueAndLengthOr*(value: Value, length: Natural, exit=false):
    ValueAndLengthOr =
  ## Create a ValueAndLengthOr value.
  let val = ValueAndLength(value: value, length: length, exit: exit)
  result = opValueW[ValueAndLength](val)

proc newValueAndLengthOr*(number: int | int64 | float64 | string,
    length: Natural): ValueAndLengthOr =
  result = newValueAndLengthOr(newValue(number), length)

func newValueAndLengthOr*(val: ValueAndLength):
    ValueAndLengthOr =
  ## Create a ValueAndLengthOr.
  result = opValueW[ValueAndLength](val)

func newLengthOr*(warning: MessageId, p1 = "", pos = 0):
    OpResultWarn[Natural] =
  ## Create a OpResultWarn[Natural] warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[Natural](warningData)

func newLengthOr*(pos: Natural): OpResultWarn[Natural] =
  ## Create a OpResultWarn[Natural] value.
  result = opValueW[Natural](pos)

func newStatement*(text: string, lineNum: Natural = 1,
    start: Natural = 0): Statement =
  ## Create a new statement.
  result = Statement(lineNum: lineNum, start: start, text: text)

proc startColumn*(start: Natural, symbol: string = "^"): string =
  ## Return enough spaces to point at the warning column.  Used under
  ## the statement line.
  for ix in 0..<start:
    result.add(' ')
  result.add(symbol)

func getFragmentAndPos*(statement: Statement, start: Natural):
     (string, Natural) =
  ## Return a statement fragment, and new position to show the given
  ## position.

  # Change the newlines and control characters to something readable
  # and so the fragment fixs on one line.
  let text = visibleControl(statement.text)

  var fragment: string
  var extraStart = ""
  var extraEnd = ""
  let fragmentMax = 60
  let halfFragment = fragmentMax div 2
  var startPos: int
  var endPos: int
  var pointerPos: int

  if text.len <= fragmentMax:
    fragment = text
    startPos = start
    pointerPos = start
  else:
    startPos = start.int - halfFragment
    if startPos < 0:
      startPos = 0
    else:
      extraStart = "..."

    endPos = startPos + fragmentMax
    if endPos > text.len:
      endPos = text.len
    else:
      extraEnd = "..."
    fragment = extraStart & text[startPos ..< endPos] & extraEnd
    pointerPos = start.int - startPos + extraStart.len

  assert pointerPos >= 0
  result = (fragment, Natural(pointerPos))

when showPos:
  proc showDebugPos*(statement: Statement, start: Natural, symbol: string) =
    let (fragment, pointerPos) = getFragmentAndPos(statement, start)
    echo fragment
    echo startColumn(pointerPos, symbol)

proc getWarnStatement*(filename: string, statement: Statement,
    warningData: WarningData): string =
  ## Return a multiline error message.

  let start = warningData.pos
  assert start >= 0
  let (fragment, pointerPos) = getFragmentAndPos(statement, start)

  let warning = warningData.warning
  let p1 = warningData.p1

  var message = """
$1
statement: $2
           $3""" % [
    getWarningLine(filename, statement.lineNum, warning, p1),
    fragment,
    startColumn(pointerPos)
  ]
  result = message

proc warnStatement*(env: var Env, statement: Statement,
                    warningData: WarningData, sourceFilename = "") =
  ## Show an invalid statement with a pointer pointing at the start of
  ## the problem. Long statements are trimmed around the problem area.
  var message: string
  var filename: string
  if sourceFilename == "":
    filename = env.templateFilename
  else:
    filename = sourceFilename

  if warningData.warning == wUserMessage:
    message = "$1($2): $3" % [filename,
      $statement.lineNum, warningData.p1]
  else:
    message = getWarnStatement(filename, statement, warningData)
  env.outputWarning(statement.lineNum, message)

func `==`*(s1: Statement, s2: Statement): bool =
  ## Return true when the two statements are equal.
  if s1.lineNum == s2.lineNum and s1.start == s2.start and
      s1.text == s2.text:
    result = true

func `$`*(s: Statement): string =
  ## Return a string representation of a Statement.
  result = """$1, $2: "$3"""" % [$s.lineNum, $s.start, s.text]

func get3GroupsLen(matchesO: Option[Matches]): (string,
    string, string, Natural) =
  let matches = matchesO.get()
  let (one, two, three) = matches.get3Groups()
  result = (one, two, three, matches.length)

iterator yieldStatements*(cmdLines: CmdLines): Statement =
  ## Iterate through the command's statements. Skip blank statements.

  type
    State {.pure.} = enum
      ## Finite state machine states for finding statements.
      start, double

  # Find the statements in the list of command lines.  Statements may
  # continue between them. A statement continues when there is a plus
  # sign at the end of the line.

  var text = newStringOfCap(defaultMaxLineLen)
  var lineNum: Natural
  var start: Natural
  if cmdLines.lines.len > 0:
    lineNum = cmdLines.lineParts[0].lineNum
    start = cmdLines.lineParts[0].codeStart
  var state = State.start
  for ix in 0 ..< cmdLines.lines.len:
    let line = cmdLines.lines[ix]
    let lp = cmdLines.lineParts[ix]
    for pos in lp.codeStart ..< lp.codeStart+lp.codeLen:
      let ch = line[pos]
      if state == State.start:
        if ch == '"':
          state = double
      elif state == double:
        if ch == '"':
          state = State.start
      text.add(ch)

    # A statement is terminated by the end of the line without a
    # continuation.
    if not lp.continuation:
      if notEmptyOrSpaces(text):
        yield newStatement(strip(text), lineNum, start)
      # Setup variables for the next line, if there is one.
      text.setLen(0)
      if cmdLines.lines.len > ix+1:
        lineNum = lp.lineNum + 1
        start = cmdLines.lineParts[ix+1].codeStart

  if notEmptyOrSpaces(text):
    yield newStatement(strip(text), lineNum, start)

func getMultilineStr*(text: string, start: Natural): StrAndPosOr =
  ## Return the triple quoted string literal. The startPos points one
  ## @:past the leading triple quote.  Return the parsed
  ## @:string value and the ending position one past the trailing
  ## @:whitespace.

  # a = """\ntest string"""\n
  #         ^                ^
  # a = """\n"""\n

  # todo: handle or document whether the string has to be UTF-8.

  if start >= text.len or text[start] != '\n':
    # Triple quotes must always end the line.
    return newStrAndPosOr(wTripleAtEnd, "", start)
  if start + 5 > text.len or text[text.len - 4 .. text.len - 1] != "\"\"\"\n":
    # Missing the ending triple quotes.
    return newStrAndPosOr(wMissingEndingTriple, "", text.len)

  let newStr = text[start + 1 .. text.len - 5]
  result = newStrAndPosOr(newStr, text.len)

func getString*(statement: Statement, start: Natural):
    ValueAndLengthOr =
  ## Return a literal string value and match length from a statement. The
  ## start parameter is the index of the first quote in the statement
  ## and the return length includes optional trailing white space
  ## after the last quote.

  let str = statement.text

  # Parse the json string and remove escaping.
  var strAndPosOr = parseJsonStr(str, start+1)
  if strAndPosOr.isMessage:
    return newValueAndLengthOr(strAndPosOr.message)
  let strAndPos = strAndPosOr.value

  # A triple quoted string looks like an empty string with a quote
  # following it to the parseJsonStr function.
  if strAndPos.pos < str.len and strAndPos.pos == start+2 and str[start+2] == '"':
    strAndPosOr = getMultilineStr(str, start+3)
    if strAndPosOr.isMessage:
      return newValueAndLengthOr(strAndPosOr.message)

  result = newValueAndLengthOr(newValue(strAndPosOr.value.str),
    strAndPosOr.value.pos - start)

proc getNumber*(statement: Statement, start: Natural):
    ValueAndLengthOr =
  ## Return the literal number value and match length from the
  ## statement. The start index points at a digit or minus sign. The
  ## length includes the trailing whitespace.

  # Check that we have a statictea number.
  let matchesO = matchNumber(statement.text, start)
  if not matchesO.isSome:
    # Invalid number.
    return newValueAndLengthOr(wNotNumber, "", start)

  # The decimal point determines whether the number is an integer or
  # float.
  let matches = matchesO.get()
  let decimalPoint = matches.getGroup()
  let length = matches.length
  var value: Value
  if decimalPoint == ".":
    # Parse the float.
    let floatAndLengthO = parseFloat(statement.text, start)
    if not floatAndLengthO.isSome:
      # The number is too big or too small.
      return newValueAndLengthOr(wNumberOverFlow, "", start)
    let floatAndLength = floatAndLengthO.get()
    value = newValue(floatAndLength.number)
    assert floatAndLength.length <= length
  else:
    # Parse the int.
    let intAndLengthO = parseInteger(statement.text, start)
    if not intAndLengthO.isSome:
      # The number is too big or too small.
      return newValueAndLengthOr(wNumberOverFlow, "", start)
    let intAndLength = intAndLengthO.get()
    value = newValue(intAndLength.number)
    assert intAndLength.length <= length
  result = newValueAndLengthOr(value, length)

# Forward reference to getValueAndLength since we call it recursively.
proc getValueAndLength*(statement: Statement, start: Natural, variables:
  Variables, skip: bool): ValueAndLengthOr

# Call stack:
# - runStatement
# - getValueAndLength
# - getFunctionValueAndLength
# - ifFunctions
# - getList
# - getValueAndLength

proc ifFunctions*(
    functionName: string,
    statement: Statement,
    start: Natural,
    variables: Variables,
    list=false): ValueAndLengthOr =
  ## Return the if/if0 function's value and the length. It conditionally
  ## runs one of its parameters. Start points at the first parameter
  ## of the function. The length includes the trailing whitespace
  ## after the ending ).

  # cases:
  #   a = if(cond, then, else)
  #   a = if(cond, then)
  #   if(cond, then)
  # The if function cond is a boolean, for if0 it is anything.

  # Get the condition's value.
  let vlcOr = getValueAndLength(statement, start, variables, skip=false)
  if vlcOr.isMessage or vlcOr.value.exit:
    return vlcOr
  let cond = vlcOr.value.value
  var runningLen = vlcOr.value.length

  var condition = false
  if functionName == "if":
    if cond.kind != vkBool:
      # The if condition must be a bool value, got a $1.
      return newValueAndLengthOr(wExpectedBool, $cond.kind, start)
    condition = cond.boolv
  else: # functionName == "if0"
    case cond.kind:
     of vkInt:
       if cond.intv == 0:
         condition = true
     of vkFloat:
       if cond.floatv == 0.0:
         condition = true
     of vkString:
       if cond.stringv.len == 0:
         condition = true
     of vkList:
       if cond.listv.len == 0:
         condition = true
     of vkDict:
       if cond.dictv.len == 0:
         condition = true
     of vkBool:
       condition = cond.boolv

  # Match the comma and whitespace.
  let commaO = matchSymbol(statement.text, gComma, start + runningLen)
  if not commaO.isSome:
    # Expected two or three arguments.
    return newValueAndLengthOr(wTwoOrThreeParams, "", start)
  runningLen += commaO.get().length

  # Handle the second parameter.
  var skip = (condition == false)
  let vl2Or = getValueAndLength(statement, start + runningLen, variables, skip)
  if vl2Or.isMessage or vl2Or.value.exit:
    return vl2Or
  runningLen += vl2Or.value.length

  var vl3Or: ValueAndLengthOr
  # Match the comma and whitespace.
  let cO = matchSymbol(statement.text, gComma, start + runningLen)
  if cO.isSome:
    # We got a comma so we expect a third parameter.
    runningLen += cO.get().length

    # Handle the third parameter.
    skip = (condition == true)
    vl3Or = getValueAndLength(statement, start + runningLen, variables, skip)
    if vl3Or.isMessage or vl3Or.value.exit:
      return vl3Or
    runningLen += vl3Or.value.length
  else:
    # The third parameter is optional. When it dosn't exist use 0 for
    # it.
    vl3Or = newValueAndLengthOr(newValue(0), 0)

  # Match ) and trailing whitespace.
  let parenO = matchSymbol(statement.text, gRightParentheses,
    start + runningLen)
  if not parenO.isSome:
    # Expected two or three parameters.
    return newValueAndLengthOr(wTwoOrThreeParams, "", start + runningLen)
  runningLen += parenO.get().length

  var value: Value
  if condition:
    value = vl2Or.value.value
  else:
    value = vl3Or.value.value
  result = newValueAndLengthOr(value, runningLen)

proc getFunctionValueAndLength*(
    functionName: string,
    statement: Statement,
    start: Natural,
    variables: Variables,
    list = false, skip: bool): ValueAndLengthOr =
  ## Return the function's value and the length. Start points at the
  ## first parameter of the function. The length includes the trailing
  ## whitespace after the ending ).

  var parameters: seq[Value] = @[]
  var parameterStarts: seq[Natural] = @[]
  var pos: Natural

  # If we get a right parentheses or right bracket, there are no
  # parameters.
  let symbol = if list: gRightBracket else: gRightParentheses
  let startSymbolO = matchSymbol(statement.text, symbol, start)
  if startSymbolO.isSome:
    pos = start + startSymbolO.get().length
  else:
    pos = start
    while true:
      # Get the parameter's value.
      let vlOr = getValueAndLength(statement, pos, variables, skip)
      if vlOr.isMessage or vlOr.value.exit:
        return vlOr
      parameters.add(vlOr.value.value)
      parameterStarts.add(pos)

      pos = pos + vlOr.value.length

      # Get the , or ) or ] and white space following the value.
      let commaSymbolO = matchCommaOrSymbol(statement.text, symbol, pos)
      if not commaSymbolO.isSome:
        if symbol == gRightParentheses:
          # Expected comma or right parentheses.
          return newValueAndLengthOr(wMissingCommaParen, "", pos)
        else:
          # Missing comma or right bracket.
          return newValueAndLengthOr(wMissingCommaBracket, "", pos)
      let commaSymbol = commaSymbolO.get()
      pos = pos + commaSymbol.length
      let foundSymbol = commaSymbol.getGroup()
      if (foundSymbol == ")" and symbol == gRightParentheses) or
         (foundSymbol == "]" and symbol == gRightBracket):
        break

  if skip:
    # pos-start is the length including trailing whitespace.
    return newValueAndLengthOr(newValue(0), pos-start)

  # Lookup the function.
  let functionSpecO = getFunction(functionName, parameters)
  if not isSome(functionSpecO):
    # The function does not exist: $1.
    return newValueAndLengthOr(wInvalidFunction, functionName, start)
  let functionSpec = functionSpecO.get()

  # Call the function.
  let funResult = functionSpec.functionPtr(variables, parameters)
  if funResult.kind == frWarning:
    var warningPos: int
    if funResult.parameter < parameterStarts.len:
      warningPos = parameterStarts[funResult.parameter]
    else:
      warningPos = start
    return newValueAndLengthOr(funResult.warningData.warning,
      funResult.warningData.p1, warningPos)

  var exit = if functionName == "return": true else: false
  # pos-start is the length including trailing whitespace.
  result = newValueAndLengthOr(funResult.value, pos-start, exit)

proc getList(statement: Statement, start: Natural,
    variables: Variables, skip: bool): ValueAndLengthOr =
  ## Return the literal list value and match length from the
  ## statement. The start index points at [. The length includes the
  ## trailing whitespace after the ending ].

  # Match the left bracket and whitespace.
  let startSymbolO = matchSymbol(statement.text, gLeftBracket, start)
  assert startSymbolO.isSome
  let startSymbol = startSymbolO.get()

  # Get the list.
  let funValueLengthOr = getFunctionValueAndLength("list", statement,
    start+startSymbol.length, variables, list=true, skip)
  if funValueLengthOr.isMessage or funValueLengthOr.value.exit:
    return funValueLengthOr

  let funValueLength = funValueLengthOr.value

  # Return the value and length.
  let valueAndLength = newValueAndLength(funValueLength.value,
    funValueLength.length+startSymbol.length)
  result = newValueAndLengthOr(valueAndLength)

proc getValueAndLengthWorker(statement: Statement, start: Natural, variables:
    Variables, skip: bool): ValueAndLengthOr =
  ## Get the value and length from the statement.

  # The first character determines its type.
  # * quote -- string
  # * digit or minus sign -- number
  # * a-zA-Z -- variable or function
  # * [ -- a list

  # Make sure start is pointing to something.
  if start >= statement.text.len:
    # Expected a string, number, variable, list or function.
    return newValueAndLengthOr(wInvalidRightHandSide, "", start)

  ## Branch based on the first character.
  let char = statement.text[start]
  if char == '"':
    result = getString(statement, start)
  elif char in {'0' .. '9', '-'}:
    result = getNumber(statement, start)
  elif char == '[':
    result = getList(statement, start, variables, skip)
  elif isLowerAscii(char) or isUpperAscii(char):
    # Get the name.
    let matchesO = matchDotNames(statement.text, start)
    if not matchesO.isSome:
      # Expected a string, number, variable, list or function.
      return newValueAndLengthOr(wInvalidRightHandSide, "", start)
    let (_, dotNameStr, leftParen, dotNameLen) = matchesO.get3GroupsLen()

    if leftParen == "(":
      # We have a function, run it and return its value.

      # Handle the special if functions.
      if dotNameStr in ["if", "if0"]:
        let ifOr = ifFunctions(dotNameStr, statement,
          start+dotNameLen, variables, skip)
        if ifOr.isMessage or ifOr.value.exit:
          return ifOr
        let length = dotNameLen + ifOr.value.length
        return newValueAndLengthOr(ifOr.value.value, length)

      if not skip:
        if not isFunctionName(dotNameStr):
          # The function does not exist: $1.
          return newValueAndLengthOr(wInvalidFunction, dotNameStr, start)

      let fvl = getFunctionValueAndLength(dotNameStr, statement,
        start+dotNameLen, variables, false, skip)
      if fvl.isMessage or fvl.value.exit:
        return fvl
      let length = dotNameLen+fvl.value.length
      let valueAndLength = newValueAndLength(fvl.value.value,
        length)
      return newValueAndLengthOr(valueAndLength)

    if skip:
      return newValueAndLengthOr(newValue(0), dotNameLen)

    # We have a variable.
    let valueOr = getVariable(variables, dotNameStr)
    if valueOr.isMessage:
      let warningData = newWarningData(valueOr.message.warning,
        valueOr.message.p1, start)
      return newValueAndLengthOr(warningData)
    return newValueAndLengthOr(valueOr.value, dotNameLen)
  else:
    # Expected a string, number, variable, list or function.
    return newValueAndLengthOr(wInvalidRightHandSide, "", start)

proc getValueAndLength*(statement: Statement, start: Natural, variables:
    Variables, skip: bool): ValueAndLengthOr =
  ## Return the value and length of the item that the start parameter
  ## points at which is a string, number, variable, function or list.
  ## The length returned includes the trailing whitespace after the
  ## item. So the ending position is pointing at the end of the
  ## statement, or at the first whitspace character after the item.
  ## When skip is true, the return value is 0 and functions are not
  ## executed.

  when showPos:
    showDebugPos(statement, start, "s")

  result = getValueAndLengthWorker(statement, start, variables, skip)

  when showPos:
    var pos: Natural
    if result.isMessage:
      pos = result.message.pos
    else:
      pos = start + result.value.length
    showDebugPos(statement, pos, "f")

proc runStatement*(statement: Statement, variables: Variables):
    VariableDataOr =
  ## Run one statement and return the variable dot name string,
  ## operator and value.

  # Skip blank lines and comments.
  var pos: Natural
  let spacesO = matchTabSpace(statement.text, 0)
  if not isSome(spacesO):
    pos = 0
  else:
    pos = spacesO.get().length
  if pos >= statement.text.len or statement.text[pos] == '#':
    return newVariableDataOr("", "", newValue(0))

  # Get the variable dot name string and match the surrounding white
  # space.
  let matchesO = matchDotNames(statement.text, pos)
  if not isSome(matchesO):
    # Statement does not start with a variable name.
    return newVariableDataOr(wMissingStatementVar)
  let (_, dotNameStr, leftParen, dotNameLen) = matchesO.get3GroupsLen()
  let leadingLen = dotNameLen + pos

  var vlOr: ValueAndLengthOr
  var operator = ""
  var operatorLength = 0
  var varName = ""

  if leftParen == "(" and dotNameStr in ["if0", "if"]:
    # Handle the special bare if functions.
    vlOr = ifFunctions(dotNameStr, statement, leadingLen, variables)
  else:
    # Handle normal "varName operator right" statements.
    varName = dotNameStr

    if leftParen != "":
      # Statement does not start with a variable name.
      return newVariableDataOr(wMissingStatementVar)

    # Get the equal sign or &= and the following whitespace.
    let operatorO = matchEqualSign(statement.text, leadingLen)
    if not operatorO.isSome:
      # Missing operator, = or &=.
      return newVariableDataOr(wInvalidVariable, "", leadingLen)
    let match = operatorO.get()
    operator = match.getGroup()
    operatorLength = match.length

    # Get the right hand side value and match the following whitespace.
    vlOr = getValueAndLength(statement,
      leadingLen + operatorLength, variables, false)

  if vlOr.isMessage:
    return newVariableDataOr(vlOr.message)

  # Return function exit.
  if vlOr.value.exit:
    return newVariableDataOr("", "exit", vlOr.value.value)

  # Check that there is not any unprocessed text following the value.
  let length = leadingLen + operatorLength + vlOr.value.length
  if length != statement.text.len:
    # Check for a trailing comment.
    if statement.text[length] != '#':
      # Unused text at the end of the statement.
      return newVariableDataOr(wTextAfterValue, "", length)

  # Return the variable dot name and value.
  result = newVariableDataOr(varName, operator, vlOr.value.value)

proc runCommand*(env: var Env, cmdLines: CmdLines,
    variables: var Variables): string =
  ## Run a command and fill in the variables dictionaries. Return "",
  ## @:"skip" or "stop".
  ## @:
  ## @:* "" -- output the replacement block. This is the default.
  ## @:* "skip" -- skip this replacement block but continue with the
  ## @:next.
  ## @:* "stop" -- stop processing the block.

  # Clear the local variables and set the tea vars to their initial
  # state.
  resetVariables(variables)

  # Loop over the statements and run each one.
  for statement in yieldStatements(cmdLines):

    # Run the statement and get the variable, operator and value.
    let variableDataOr = runStatement(statement, variables)
    if variableDataOr.isMessage:
      env.warnStatement(statement, variableDataOr.message)
      continue
    let variableData = variableDataOr.value

    # Return function exit.
    if variableData.operator == "exit":
      if variableData.value.kind != vkString:
        # Expected 'skip', 'stop' or '' for the block command return value.
        env.warnStatement(statement, newWarningData(wSkipStopOrEmpty))
        continue
      return variableData.value.stringv

    # A bare if without taking a return.
    if variableData.operator == "":
      continue

    # Assign the variable if possible.
    let warningDataO = assignVariable(variables,
      variableData.dotNameStr, variableData.value, variableData.operator)
    if isSome(warningDataO):
      env.warnStatement(statement, warningDataO.get())

    # If t.repeat was set to 0, we're done.
    let tea = variables["t"].dictv
    if "repeat" in tea and tea["repeat"].intv == 0:
      break

  result = ""
