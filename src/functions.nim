## This module contains the StaticTea functions and supporting types.
## The StaticTea language functions start with "fun", for example, the
## "fun_cmp_ffi" function implements on of the StaticTea "cmp"
## functions.

import std/options
import std/tables
import std/strutils
import std/math
import std/os
import std/algorithm
import messages
import vartypes
import regexes
import parseNumber
import matches
import unicodes
import signatures
import opresult
import readjson
import variables


type
  StringOr* = OpResultWarn[string]
    ## StringOr holds a string or a warning.

  PathComponents* = object
    ## PathComponents holds the components of the file path components.
    dir: string
    filename: string
    basename: string
    ext: string

func newStringOr*(warning: MessageId, p1: string = "", pos = 0):
     StringOr =
  ## Create a new StringOr object containing a warning.
  let warningData = newWarningData(warning, p1, pos)
  result = opMessageW[string](warningData)

func newStringOr*(warningData: WarningData): StringOr =
  ## Create a new StringOr object containing a warning.
  result = opMessageW[string](warningData)

func newStringOr*(str: string): StringOr =
  ## Create a new StringOr object containing a string.
  result = opValueW[string](str)

func newPathComponents*(dir, filename, basename, ext: string): PathComponents =
  ## Create a new PathComponents object from its pieces.
  result = PathComponents(dir: dir, filename: filename, basename: basename, ext: ext)

template tMapParameters(functionName: string, signatureCode: string) =
  ## Template that checks the signatureCode against the parameters and
  ## sets the map dictionary variable.
  let signatureO = newSignatureO(functionName, signatureCode)
  let funResult = mapParameters(signatureO.get(), arguments)
  if funResult.kind == frWarning:
    return funResult
  let map {.inject.} = funResult.value.dictv.dict

func signatureDetails*(signature: Signature): Value =
  ## Convert the signature object to a dictionary value.
  var dict = newVarsDict()
  dict["optional"] = newValue(signature.optional)
  dict["name"] = newValue(signature.name)
  var paramNames = newSeq[string]()
  var paramTypes = newSeq[string]()
  for param in signature.params:
    paramNames.add($param.name)
    paramTypes.add($param.paramType)
  dict["paramNames"] = newValue(paramNames)
  dict["paramTypes"] = newValue(paramTypes)
  dict["returnType"] = newValue($signature.returnType)
  result = newValue(dict)

func functionDetails*(fs: FunctionSpec): Value =
  ## Convert the function spec to a dictionary value.
  var dict = newVarsDict()
  dict["builtIn"] = newValue(fs.builtIn)
  dict["signature"] = signatureDetails(fs.signature)
  dict["docComment"] = newValue(fs.docComment)
  dict["filename"] = newValue(fs.filename)
  dict["lineNum"] = newValue(fs.lineNum)
  dict["numLines"] = newValue(fs.numLines)
  var statementStrings = newSeq[string]()
  for statement in fs.statements:
    statementStrings.add(statement.text)
  dict["statements"] = newValue(statementStrings)
  result = newValue(dict)

func cmpBaseValues*(a, b: Value, insensitive: bool = false): int =
  ## Compares two values a and b.  When a equals b return 0, when a is
  ## greater than b return 1 and when a is less than b return -1.
  ## The values must be the same kind and either int, float or string.

  case a.kind
    of vkString:
      result = cmpString(a.stringv, b.stringv, insensitive)
    of vkInt:
      result = cmp(a.intv, b.intv)
    of vkFloat:
      result = cmp(a.floatv, b.floatv)
    else:
      result = 0

func parseNumber*(line: string, start: Natural): ValuePosSiOr =
  ## Return the literal number value and position after it.  The start
  ## index points at a digit or minus sign. The position includes the
  ## trailing whitespace.

  # Check that we have a statictea number and get the length including
  # trailing whitespace.
  var matchesO = matchNumberNotCached(line, start)
  if not matchesO.isSome:
    # Invalid number.
    return newValuePosSiOr(wNotNumber, "", start)

  # The decimal point determines whether the number is an integer or
  # float.
  let matches = matchesO.get()
  let decimalPoint = matches.getGroup()
  var valueAndPos: ValuePosSi
  if decimalPoint == ".":
    # Parse the float.
    let floatAndPosO = parseFloat(line, start)
    if not floatAndPosO.isSome:
      # The number is too big or too small.
      return newValuePosSiOr(wNumberOverFlow, "", start)
    let (number, pos) = floatAndPosO.get()
    valueAndPos = newValuePosSi(newValue(number), pos)
  else:
    # Parse the int.
    let intAndPosO = parseInteger(line, start)
    if not intAndPosO.isSome:
      # The number is too big or too small.
      return newValuePosSiOr(wNumberOverFlow, "", start)
    let (number, pos) = intAndPosO.get()
    valueAndPos = newValuePosSi(newValue(number), pos)
  # Note that we use the matches length so it includes the trailing whitespace.
  result = newValuePosSiOr(newValuePosSi(valueAndPos.value, start + matches.length))

func numberStringToNum(numString: string): FunResult =
  ## Convert the number string to a float or int, if possible.

  let valueAndPosOr = parseNumber(numString, 0)
  if valueAndPosOr.isMessage:
    # return newFunResultWarn(wExpectedNumberString)
    let messageData = valueAndPosOr.message
    return newFunResultWarn(messageData)

  result = newFunResult(valueAndPosOr.value.value)

proc formatString*(variables: Variables, text: string): StringOr =
  ## Format a string by filling in the variable placeholders with
  ## their values. Generate a warning when the variable doesn't
  ## exist. No space around the bracketed variables.
  ## @:
  ## @:~~~
  ## @:let first = "Earl"
  ## @:let last = "Grey"
  ## @:"name: {first} {last}" => "name: Earl Grey"
  ## @:~~~~
  ## @:
  ## @:To enter a left bracket use two in a row.
  ## @:
  ## @:~~~
  ## @:"{{" => "{"
  ## @:~~~~
  type
    State = enum
      ## Parsing states.
      start, bracket, variable

  var pos = 0
  var state = start
  var newStr = newStringOfCap(text.len)
  var varStart: int

  # Loop through the text one byte at a time and add to the result
  # string.
  while true:
    case state
    of start:
      if pos >= text.len:
        break # done
      let ch = text[pos]
      if ch == '{':
        state = bracket
      else:
        newStr.add(ch)
      inc(pos)
    of bracket:
      if pos >= text.len:
        # No ending bracket.
        return newStringOr(wNoEndingBracket, "", pos)
      let ch = text[pos]
      case ch
      of '{':
        # Two left brackets in a row equal one bracket.
        state = start
        newStr.add('{')
      of variableStartChars:
        state = variable
        varStart = pos
      else:
        # Invalid variable name; names start with an ascii letter.
        return newStringOr(wInvalidVarNameStart, "", pos)
      inc(pos)
    of variable:
      if pos >= text.len:
        # No ending bracket.
        return newStringOr(wNoEndingBracket, "", pos)
      let ch = text[pos]
      case ch
      of '}':
        # Replace the placeholder with the variable's string
        # representation.
        let varName = text[varStart .. pos - 1]
        var valueOr = getVariable(variables, varName, npLocal)
        if valueOr.isMessage:
          let wd = newWarningData(valueOr.message.messageId,
            valueOr.message.p1, varStart)
          return newStringOr(wd)
        let str = valueToStringRB(valueOr.value)
        newStr.add(str)
        state = start
      of variableChars:
        discard
      else:
        # Invalid variable name; names contain letters, digits or underscores.
        return newStringOr(wInvalidVarName, "", pos)
      inc(pos)

  result = newStringOr(newStr)

func fun_cmp_iii*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Compare two ints. Returns -1 for less, 0 for equal and 1 for
  ## greater than.
  ## @:
  ## @:~~~
  ## @:cmp(a: int, b: int) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cmp(7, 9) => -1
  ## @:cmp(8, 8) => 0
  ## @:cmp(9, 2) => 1
  ## @:~~~~

  tMapParameters("cmp", "iii")
  let a = map["a"].intv
  let b = map["b"].intv
  result = newFunResult(newValue(cmp(a, b)))

func fun_cmp_ffi*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Compare two floats. Returns -1 for less, 0 for equal and 1 for
  ## greater than.
  ## @:
  ## @:~~~
  ## @:cmp(a: float, b: float) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cmp(7.8, 9.1) => -1
  ## @:cmp(8.4, 8.4) => 0
  ## @:cmp(9.3, 2.2) => 1
  ## @:~~~~

  tMapParameters("cmp", "ffi")
  let a = map["a"].floatv
  let b = map["b"].floatv
  result = newFunResult(newValue(cmp(a, b)))

func fun_cmp_ssobi*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Compare two strings. Returns -1 for less, 0 for equal and 1 for
  ## greater than.
  ## @:
  ## @:You have the option to compare case insensitive. Case sensitive
  ## @:is the default.
  ## @:
  ## @:~~~
  ## @:cmp(a: string, b: string, insensitive: optional bool) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cmp("coffee", "tea") => -1
  ## @:cmp("tea", "tea") => 0
  ## @:cmp("Tea", "tea") => 1
  ## @:cmp("Tea", "tea", true) => 1
  ## @:cmp("Tea", "tea", false) => 0
  ## @:~~~~

  tMapParameters("cmp", "ssobi")
  let a = map["a"].stringv
  let b = map["b"].stringv

  # Get the optional case insensitive.
  var insensitive = false
  if "c" in map:
    insensitive = map["c"].boolv

  let ret = cmpString(a, b, insensitive)
  result = newFunResult(newValue(ret))

func fun_concat_sss*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Concatenate two strings. See the join function for more that two arguments.
  ## @:
  ## @:~~~
  ## @:concat(a: string, b: string) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:concat("tea", " time") => "tea time"
  ## @:concat("a", "b") => "ab"
  ## @:~~~~

  tMapParameters("concat", "sss")
  var a = map["a"].stringv
  let b = map["b"].stringv
  result = newFunResult(newValue(a & b))

func fun_len_si*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Number of unicode characters in a string.
  ## @:
  ## @:~~~
  ## @:len(str: string) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:len("tea") => 3
  ## @:len("añyóng") => 6
  ## @:~~~~

  tMapParameters("len", "si")
  let str = map["a"].stringv
  result = newFunResult(newValue(stringLen(str)))

func fun_len_li*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Number of elements in a list.
  ## @:
  ## @:~~~
  ## @:len(list: list) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:len(list()) => 0
  ## @:len(list(1)) => 1
  ## @:len(list(4, 5)) => 2
  ## @:~~~~

  tMapParameters("len", "li")
  let list = map["a"].listv.list
  result = newFunResult(newValue(list.len))

func fun_len_di*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Number of elements in a dictionary.
  ## @:
  ## @:~~~
  ## @:len(dictionary: dict) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:len(dict()) => 0
  ## @:len(dict("a", 4)) => 1
  ## @:len(dict("a", 4, "b", 3)) => 2
  ## @:~~~~

  tMapParameters("len", "di")
  let dict = map["a"].dictv.dict
  result = newFunResult(newValue(dict.len))

func fun_get_lioaa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Get a list value by its index.  If the index is invalid, the
  ## default value is returned when specified, else a warning is
  ## generated. You can use negative index values. Index -1 gets the
  ## last element. It is short hand for len - 1. Index -2 is len - 2,
  ## etc.
  ## @:
  ## @:~~~
  ## @:get(list: list, index: int, default: optional any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:list = list(4, "a", 10)
  ## @:get(list, 0) => 4
  ## @:get(list, 1) => "a"
  ## @:get(list, 2) => 10
  ## @:get(list, 3, 99) => 99
  ## @:get(list, -1) => 10
  ## @:get(list, -2) => "a"
  ## @:get(list, -3) => 4
  ## @:get(list, -4, 11) => 11
  ## @:~~~~

  tMapParameters("get", "lioaa")
  let list = map["a"].listv.list
  let index = map["b"].intv

  var ix: int64
  if index < 0:
    ix = list.len + index
  else:
    ix = index
  if ix >= 0 and ix < list.len:
    result = newFunResult(newValue(list[ix]))
  elif "c" in map:
    result = newFunResult(map["c"])
  else:
    # The list index $1 is out of range.
    result = newFunResultWarn(wMissingListItem, 1, $index)

func fun_get_dsoaa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Get a dictionary value by its key.  If the key doesn't exist, the
  ## default value is returned if specified, else a warning is
  ## generated.
  ## @:
  ## @:~~~
  ## @:get(dictionary: dict, key: string, default: optional any) any
  ## @:~~~~
  ## @:
  ## @:Note: For dictionary lookup you can use dot notation. It's the
  ## @:same as get without the default.
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d = dict("tea", "Earl Grey")
  ## @:get(d, "tea") => "Earl Grey"
  ## @:get(d, "coffee", "Tea") => "Tea"
  ## @:~~~~
  ## @:
  ## @:Using dot notation:
  ## @:~~~
  ## @:d = dict("tea", "Earl Grey")
  ## @:d.tea => "Earl Grey"
  ## @:~~~~

  tMapParameters("get", "dsoaa")
  let dict = map["a"].dictv.dict
  let key = map["b"].stringv

  if key in dict:
    result = newFunResult(dict[key])
  elif "c" in map:
    result = newFunResult(map["c"])
  else:
    # The dictionary does not have an item with key $1.
    result = newFunResultWarn(wMissingDictItem, 1, key)

func fun_if0_iaoaa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## If the condition is 0, return the second argument, else return
  ## the third argument.  You can use any type for the condition.  The
  ## condition is 0 for strings, lists and dictionaries when their
  ## length is 0.
  ## @:
  ## @:The condition types and what is considered 0:
  ## @:
  ## @:* bool -- false
  ## @:* int -- 0
  ## @:* float -- 0.0
  ## @:* string -- when the length of the string is 0
  ## @:* list -- when the length of the list is 0
  ## @:* dict -- when the length of the dictionary is 0
  ## @:* func -- always 0
  ## @:
  ## @:The if functions are special in a couple of ways, see
  ## @:the If Functions section.
  ## @:
  ## @:~~~
  ## @:if0(condition: any, then: any, else: any) any
  ## @:if0(condition: any, then: any)
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:a = if0(0, "tea", "beer") => tea
  ## @:a = if0(1, "tea", "beer") => beer
  ## @:a = if0(4, "tea", "beer") => beer
  ## @:a = if0("", "tea", "beer") => tea
  ## @:a = if0("abc", "tea", "beer") => beer
  ## @:a = if0([], "tea", "beer") => tea
  ## @:a = if0([1,2], "tea", "beer") => beer
  ## @:a = if0(dict(), "tea", "beer") => tea
  ## @:a = if0(dict("a",1), "tea", "beer") => beer
  ## @:a = if0(false, "tea", "beer") => tea
  ## @:a = if0(true, "tea", "beer") => beer
  ## @:~~~~
  ## @:
  ## @:You don't have to assign the result of an if0 function which is
  ## @:useful when using a warn or return function for its side effects.
  ## @:The if takes two arguments when there is no assignment.
  ## @:
  ## @:~~~
  ## @:if0(c, warn("got zero value"))
  ## @:~~~~

  # Note: the if functions are handled in runCommand as a special
  # case. This code is not run. It is here for the function list and
  # documentation.

  tMapParameters("if0", "iaoaa")
  let condition = map["a"].intv
  let thenCase = map["b"]

  if condition == 0:
    result = newFunResult(thenCase)
  elif "c" in map:
    result = newFunResult(map["c"])
  else:
    result = newFunResult(newValue(0))

{.push overflowChecks: on, floatChecks: on.}

func fun_if_baoaa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## If the condition is true, return the second argument, else return
  ## the third argument.
  ## @:
  ## @:The if functions are special in a couple of ways, see
  ## @:the If Functions section.  You usually use boolean infix
  ## @:expressions for the condition, see:
  ## @:the Boolean Expressions section.
  ## @:
  ## @:~~~
  ## @:if(condition: bool, then: any, else: optional any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:a = if(true, "tea", "beer") => tea
  ## @:b = if(false, "tea", "beer") => beer
  ## @:c = if((d < 5), "tea", "beer") => beer
  ## @:~~~~
  ## @:
  ## @:You don't have to assign the result of an if function which is
  ## @:useful when using a warn or return function for its side effects.
  ## @:The if takes two arguments when there is no assignment.
  ## @:
  ## @:~~~
  ## @:if(c, warn("c is true"))
  ## @:if(c, return("skip"))
  ## @:~~~~

  # Note: the if functions are handled in runCommand as a special
  # case. This code is not run. It is here for the function list and
  # documentation.

  tMapParameters("if", "baoaa")
  let condition = map["a"].boolv
  let thenCase = map["b"]

  if condition:
    result = newFunResult(thenCase)
  elif "c" in map:
    result = newFunResult(map["c"])
  else:
    result = newFunResult(newValue(0))

{.push overflowChecks: on, floatChecks: on.}

func fun_add_iii*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Add two integers. A warning is generated on overflow.
  ## @:
  ## @:~~~
  ## @:add(a: int, b: int) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:add(1, 2) => 3
  ## @:add(3, -2) => 1
  ## @:add(-2, -5) => -7
  ## @:~~~~

  tMapParameters("add", "iii")
  let a = map["a"].intv
  let b = map["b"].intv
  try:
    result = newFunResult(newValue(a + b))
  except:
    result = newFunResultWarn(wOverflow)

func fun_add_fff*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Add two floats. A warning is generated on overflow.
  ## @:
  ## @:~~~
  ## @:add(a: float, b: float) float
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:add(1.5, 2.3) => 3.8
  ## @:add(3.2, -2.2) => 1.0
  ## @:~~~~

  tMapParameters("add", "fff")
  let a = map["a"].floatv
  let b = map["b"].floatv
  try:
    result = newFunResult(newValue(a + b))
  except:
    # Overflow or underflow.
    result = newFunResultWarn(wOverflow)

func fun_sub_iii*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Subtract two integers. A warning is generated on overflow.
  ## @:
  ## @:~~~
  ## @:sub(a: int, b: int) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:sub(3, 1) => 2
  ## @:add(3, -2) => 5
  ## @:add(1, 5) => -4
  ## @:~~~~

  tMapParameters("sub", "iii")
  let a = map["a"].intv
  let b = map["b"].intv
  try:
    result = newFunResult(newValue(a - b))
  except:
    result = newFunResultWarn(wOverflow)

func fun_sub_fff*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Sub two floats. A warning is generated on overflow.
  ## @:
  ## @:~~~
  ## @:sub(a: float, b: float) float
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:sub(4.5, 2.3) => 2.2
  ## @:sub(1.0, 2.2) => -1.2
  ## @:~~~~

  tMapParameters("sub", "fff")
  let a = map["a"].floatv
  let b = map["b"].floatv
  try:
    result = newFunResult(newValue(a - b))
  except:
    # Overflow or underflow.
    result = newFunResultWarn(wOverflow)

{.pop.}

func fun_exists_dsb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Determine whether a key exists in a dictionary. Return true when it
  ## exists, else false.
  ## @:
  ## @:~~~
  ## @:exists(dictionary: dict, key: string) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d = dict("tea", "Earl")
  ## @:exists(d, "tea") => true
  ## @:exists(d, "coffee") => false
  ## @:~~~~

  tMapParameters("exists", "dsb")
  let dictionary = map["a"].dictv.dict
  let key = map["b"].stringv

  var ret: bool
  if key in dictionary:
    ret = true
  result = newFunResult(newValue(ret))

func getCase(map: VarsDict): FunResult =
  ## Return the matching case value or the default when none
  ## match. The map dictionary contains the parameters to the case
  ## functions.

  let mainCondition = map["a"]
  let cases = map["b"]

  let caseList = cases.listv.list
  if caseList.len mod 2 != 0:
    # Expected an even number of cases, got $1.
    return newFunResultWarn(wNotEvenCases, 1, $caseList.len)

  for ix in countUp(0, caseList.len-1, 2):
    let condition = caseList[ix]
    if mainCondition.kind != condition.kind:
      # A case condition is not the same type as the main condition.
     return newFunResultWarn(wCaseTypeMismatch)

    if condition == mainCondition:
      let value = caseList[ix+1]
      return newFunResult(value)

  # Return the else case if it exists.
  if "c" in map:
    result = newFunResult(map["c"])
  else:
    # None of the case conditions match and no else case.
    result = newFunResultWarn(wMissingElse, 2)

func fun_case_iloaa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Compare integer cases and return the matching value.  It takes a
  ## main integer condition, a list of case pairs and an optional
  ## value when none of the cases match.
  ## @:
  ## @:The first element of a case pair is the condition and the
  ## @:second is the return value when that condition matches the main
  ## @:condition. The function compares the conditions left to right and
  ## @:returns the first match.
  ## @:
  ## @:When none of the cases match the main condition, the default
  ## @:value is returned if it is specified, otherwise a warning is
  ## @:generated.  The conditions must be integers. The return values
  ## @:can be any type.
  ## @:
  ## @:~~~
  ## @:case(condition: int, pairs: list, default: optional any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cases = list(0, "tea", 1, "water", 2, "beer")
  ## @:case(0, cases) => "tea"
  ## @:case(1, cases) => "water"
  ## @:case(2, cases) => "beer"
  ## @:case(2, cases, "wine") => "beer"
  ## @:case(3, cases, "wine") => "wine"
  ## @:~~~~

  tMapParameters("case", "iloaa")
  result = getCase(map)

func fun_case_sloaa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Compare string cases and return the matching value.  It takes a
  ## main string condition, a list of case pairs and an optional
  ## value when none of the cases match.
  ## @:
  ## @:The first element of a case pair is the condition and the
  ## @:second is the return value when that condition matches the main
  ## @:condition. The function compares the conditions left to right and
  ## @:returns the first match.
  ## @:
  ## @:When none of the cases match the main condition, the default
  ## @:value is returned if it is specified, otherwise a warning is
  ## @:generated.  The conditions must be strings. The return values
  ## @:can be any type.
  ## @:
  ## @:~~~
  ## @:case(condition: string, pairs: list, default: optional any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cases = list("tea", 15, "water", 2.3, "beer", "cold")
  ## @:case("tea", cases) => 15
  ## @:case("water", cases) => 2.3
  ## @:case("beer", cases) => "cold"
  ## @:case("bunch", cases, "other") => "other"
  ## @:~~~~

  tMapParameters("case", "sloaa")
  result = getCase(map)

func parseVersion*(version: string): Option[(int, int, int)] =
  ## Parse a StaticTea version number and return its three components.
  let matchesO = matchVersionNotCached(version, 0)
  if not matchesO.isSome:
    return
  let (g1, g2, g3) = matchesO.get3Groups()
  let g1IntAndPosO = parseInteger(g1)
  let g2IntAndPosO = parseInteger(g2)
  let g3IntAndPosO = parseInteger(g3)
  result = some((int(g1IntAndPosO.get().number),
    int(g2IntAndPosO.get().number), int(g3IntAndPosO.get().number)))

func fun_cmpVersion_ssi*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Compare two StaticTea version numbers. Returns -1 for less, 0 for
  ## equal and 1 for greater than.
  ## @:
  ## @:~~~
  ## @:cmpVersion(versionA: string, versionB: string) int
  ## @:~~~~
  ## @:
  ## @:StaticTea uses @{@{https@@://semver.org/]@{Semantic Versioning]]
  ## @:with the added restriction that each version component has one
  ## @:to three digits (no letters).
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cmpVersion("1.2.5", "1.1.8") => 1
  ## @:cmpVersion("1.2.5", "1.3.0") => -1
  ## @:cmpVersion("1.2.5", "1.2.5") => 0
  ## @:~~~~

  tMapParameters("cmpVersion", "ssi")

  let versionA = map["a"].stringv
  let versionB = map["b"].stringv

  let aTupleO = parseVersion(versionA)
  if not aTupleO.isSome:
    return newFunResultWarn(wInvalidVersion, 0)
  let (oneV1, twoV1, threeV1) = aTupleO.get()

  let bTupleO = parseVersion(versionB)
  if not bTupleO.isSome:
    # Invalid StaticTea version string.
    return newFunResultWarn(wInvalidVersion, 1)
  let (oneV2, twoV2, threeV2) = bTupleO.get()

  var ret = cmp(oneV1, oneV2)
  if ret == 0:
    ret = cmp(twoV1, twoV2)
    if ret == 0:
      ret = cmp(threeV1, threeV2)

  result = newFunResult(newValue(ret))

func fun_float_if*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create a float from an int.
  ## @:
  ## @:~~~
  ## @:float(num: int) float
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:float(2) => 2.0
  ## @:float(-33) => -33.0
  ## @:~~~~
  tMapParameters("float", "if")
  let num = map["a"].intv
  result = newFunResult(newValue(float(num)))

func fun_float_sf*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create a float from a number string.
  ## @:
  ## @:~~~
  ## @:float(numString: string) float
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:float("2") => 2.0
  ## @:float("2.4") => 2.4
  ## @:float("33") => 33.0
  ## @:~~~~
  tMapParameters("float", "sf")
  let numString = map["a"].stringv

  let funResult = numberStringToNum(numString)
  if funResult.kind == frWarning:
    return funResult

  if funResult.value.kind == vkFloat:
    result = funResult
  else:
    result = newFunResult(newValue(float(funResult.value.intv)))

func fun_float_saa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create a float from a number string. If the string is not a
  ## number, return the default.
  ## @:
  ## @:~~~
  ## @:float(numString: string, default: optional any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:float("2") => 2.0
  ## @:float("notnum", "nan") => nan
  ## @:~~~~
  tMapParameters("float", "saa")
  let numString = map["a"].stringv

  result = numberStringToNum(numString)
  if result.kind == frWarning:
    if "b" in map:
      # Return the default.
      return newFunResult(map["b"])
    return result

  if result.value.kind == vkInt:
    result = newFunResult(newValue(float(result.value.intv)))

func convertFloatToInt(num: float, map: VarsDict): FunResult =
  ## Convert float to an integer. The map contains the optional round
  ## options as "b".
  if num > float(high(int64)) or num < float(low(int64)):
    # The number is too big or too small.
    return newFunResultWarn(wNumberOverFlow)

  var option: string
  if "b" in map:
    option = map["b"].stringv
  else:
    option = "round"

  var ret: int64
  case option
    of "round":
      ret = int(round(num))
    of "ceiling":
      ret = int(ceil(num))
    of "floor":
      ret = int(floor(num))
    of "truncate":
      ret = int(trunc(num))
    else:
      # Expected round, floor, ceiling or truncate.
      return newFunResultWarn(wExpectedRoundOption, 1)
  result = newFunResult(newValue(ret))

func fun_int_fosi*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create an int from a float.
  ## @:
  ## @:~~~
  ## @:int(num: float, roundOption: optional string) int
  ## @:~~~~
  ## @:
  ## @:Round options:
  ## @:
  ## @:* "round" - nearest integer, the default.
  ## @:* "floor" - integer below (to the left on number line)
  ## @:* "ceiling" - integer above (to the right on number line)
  ## @:* "truncate" - remove decimals
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:int(2.34) => 2
  ## @:int(2.34, "round") => 2
  ## @:int(-2.34, "round") => -2
  ## @:int(6.5, "round") => 7
  ## @:int(-6.5, "round") => -7
  ## @:int(4.57, "floor") => 4
  ## @:int(-4.57, "floor") => -5
  ## @:int(6.3, "ceiling") => 7
  ## @:int(-6.3, "ceiling") => -6
  ## @:int(6.3456, "truncate") => 6
  ## @:int(-6.3456, "truncate") => -6
  ## @:~~~~

  tMapParameters("int", "fosi")
  let num = map["a"].floatv

  result = convertFloatToInt(num, map)

func fun_int_sosi*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create an int from a number string.
  ## @:
  ## @:~~~
  ## @:int(numString: string, roundOption: optional string) int
  ## @:~~~~
  ## @:
  ## @:Round options:
  ## @:
  ## @:* "round" - nearest integer, the default
  ## @:* "floor" - integer below (to the left on number line)
  ## @:* "ceiling" - integer above (to the right on number line)
  ## @:* "truncate" - remove decimals
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:int("2") => 2
  ## @:int("2.34") => 2
  ## @:int("-2.34", "round") => -2
  ## @:int("6.5", "round") => 7
  ## @:int("-6.5", "round") => -7
  ## @:int("4.57", "floor") => 4
  ## @:int("-4.57", "floor") => -5
  ## @:int("6.3", "ceiling") => 7
  ## @:int("-6.3", "ceiling") => -6
  ## @:int("6.3456", "truncate") => 6
  ## @:int("-6.3456", "truncate") => -6
  ## @:~~~~

  tMapParameters("int", "sosi")
  let numString = map["a"].stringv

  let funResult = numberStringToNum(numString)
  if funResult.kind == frWarning:
    return funResult

  if funResult.value.kind == vkFloat:
    result = convertFloatToInt(funResult.value.floatv, map)
  else:
    result = funResult

func fun_int_ssaa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create an int from a number string. If the string is not a number,
  ## return the default value.
  ## @:
  ## @:~~~
  ## @:int(numString: string, roundOption: string, default: optional any) any
  ## @:~~~~
  ## @:
  ## @:Round options:
  ## @:
  ## @:* "round" - nearest integer, the default
  ## @:* "floor" - integer below (to the left on number line)
  ## @:* "ceiling" - integer above (to the right on number line)
  ## @:* "truncate" - remove decimals
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:int("2", "round", "nan") => 2
  ## @:int("notnum", "round", "nan") => nan
  ## @:~~~~

  tMapParameters("int", "ssaa")
  let numString = map["a"].stringv

  result = numberStringToNum(numString)
  if result.kind == frWarning:
    if "c" in map:
      # Return the default.
      return newFunResult(map["c"])
    return result

  if result.value.kind == vkFloat:
    result = convertFloatToInt(result.value.floatv, map)

func if0Condition*(cond: Value): bool =
  ## Convert the value to a boolean.
  result = true
  case cond.kind:
   of vkInt:
     if cond.intv == 0:
       result = false
   of vkFloat:
     if cond.floatv == 0.0:
       result = false
   of vkString:
     if cond.stringv.len == 0:
       result = false
   of vkList:
     if cond.listv.list.len == 0:
       result = false
   of vkDict:
     if cond.dictv.dict.len == 0:
       result = false
   of vkBool:
     result = cond.boolv
   of vkFunc:
     result = false

func fun_bool_ab*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create an bool from a value.
  ## @:
  ## @:~~~
  ## @:bool(value: Value) bool
  ## @:~~~~
  ## @:
  ## @:False values by variable types:
  ## @:
  ## @:* bool -- false
  ## @:* int -- 0
  ## @:* float -- 0.0
  ## @:* string -- when the length of the string is 0
  ## @:* list -- when the length of the list is 0
  ## @:* dict -- when the length of the dictionary is 0
  ## @:* func -- always false
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:bool(0) => false
  ## @:bool(0.0) => false
  ## @:bool([]) => false
  ## @:bool("") => false
  ## @:bool(dict()) => false
  ## @:
  ## @:bool(5) => true
  ## @:bool(3.3) => true
  ## @:bool([8]) => true
  ## @:bool("tea") => true
  ## @:bool(dict("tea", 2)) => true
  ## @:~~~~

  tMapParameters("bool", "ab")
  let value = map["a"]
  result = newFunResult(newValue(if0Condition(value)))

func fun_find_ssoaa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Find the position of a substring in a string.  When the substring
  ## is not found, return an optional default value.  A warning is
  ## generated when the substring is missing and you don't specify a
  ## default value.
  ## @:
  ## @:~~~
  ## @:find(str: string, substring: string, default: optional any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:       0123456789 1234567
  ## @:msg = "Tea time at 3:30."
  ## @:find(msg, "Tea") = 0
  ## @:find(msg, "time") = 4
  ## @:find(msg, "me") = 6
  ## @:find(msg, "party", -1) = -1
  ## @:find(msg, "party", len(msg)) = 17
  ## @:find(msg, "party", 0) = 0
  ## @:~~~~

  tMapParameters("find", "ssoaa")

  let str = map["a"].stringv
  let substring = map["b"].stringv

  let pos = find(str, substring)
  if pos == -1:
    if "c" in map:
      result = newFunResult(map["c"])
    else:
      # The substring was not found and no default argument.
      result = newFunResultWarn(wSubstringNotFound, 1)
  else:
    result = newFunResult(newValue(pos))

func fun_slice_siois*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Extract a substring from a string by its position and length. You
  ## pass the string, the substring's start index and its length.  The
  ## length is optional. When not specified, the slice returns the
  ## characters from the start to the end of the string.
  ## @:
  ## @:The start index and length are by unicode characters not bytes.
  ## @:
  ## @:~~~
  ## @:slice(str: string, start: int, length: optional int) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:slice("Earl Grey", 1, 3) => "arl"
  ## @:slice("Earl Grey", 6) => "rey"
  ## @:slice("añyóng", 0, 3) => "añy"
  ## @:~~~~

  tMapParameters("slice", "siois")

  let str = map["a"].stringv
  let start = int(map["b"].intv)
  var length: int
  if "c" in map:
    length = int(map["c"].intv)
    if length < 0:
      # The length must be a positive number.
      return newFunResultWarn(wNegativeLength, 2)
  else:
    length = -1

  result = slice(str, start, length)

func fun_dup_sis*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Duplicate a string x times.  The result is a new string built by
  ## concatenating the string to itself the specified number of times.
  ## @:
  ## @:~~~
  ## @:dup(pattern: string, count: int) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:dup("=", 3) => "==="
  ## @:dup("abc", 0) => ""
  ## @:dup("abc", 1) => "abc"
  ## @:dup("abc", 2) => "abcabc"
  ## @:dup("", 3) => ""
  ## @:~~~~

  tMapParameters("dup", "sis")

  let pattern = map["a"].stringv
  let count = map["b"].intv

  if count < 0:
    result = newFunResultWarn(wInvalidMaxCount, 1)
    return

  # Result must be less than 1024 characters.
  let length = count * pattern.len
  if length > 1024:
    # The resulting duplicated string must be under 1024 characters, got: $1.
    result = newFunResultWarn(wDupStringTooLong, 1, $length)
    return

  var str = newStringOfCap(length)
  for ix in countUp(1, int(count)):
    str.add(pattern)
  result = newFunResult(newValue(str))

func fun_dict_old*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create a dictionary from a list of key, value pairs.  The keys
  ## must be strings and the values can be any type.
  ## @:
  ## @:~~~
  ## @:dict(pairs: optional list) dict
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:dict() => {}
  ## @:dict(["a", 5]) => {"a": 5}
  ## @:dict(["a", 5, "b", 33, "c", 0]) =>
  ## @:  {"a": 5, "b": 33, "c": 0}
  ## @:~~~~

  tMapParameters("dict", "old")

  var dict = newVarsDict()

  if "a" in map:
    let pairs = map["a"].listv.list
    if pairs.len mod 2 != 0:
      # Dictionaries require an even number of list items.
      return newFunResultWarn(wDictRequiresEven, 0)
    for ix in countUp(0, pairs.len-2, 2):
      var key = pairs[ix]
      if key.kind != vkString:
        # The dictionary keys must be strings.
        return newFunResultWarn(wDictStringKey, 0)
      var value = pairs[ix+1]
      dict[key.stringv] = value

  # todo: should be restrict mutable to empty dicts?
  result = newFunResult(newValue(dict, mutable = Mutable.append))

func fun_list_al*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create a list of variables. You can also create a list with brackets.
  ## @:
  ## @:~~~
  ## @:list(...) list
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:a = list()
  ## @:a = list(1)
  ## @:a = list(1, 2, 3)
  ## @:a = list("a", 5, "b")
  ## @:a = []
  ## @:a = [1]
  ## @:a = [1, 2, 3]
  ## @:a = ["a", 5, "b"]
  ## @:~~~~
  result = newFunResult(newValue(arguments, mutable = Mutable.append))

func fun_listLoop_lapoab*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Fill in a container from a list and a callback function. The callback
  ## function is called for each item in the list and it decides what
  ## goes in the container.
  ## @:
  ## @:You pass a list to loop over, a container to fill in, a callback
  ## @:function, and an optional state variable. The function returns
  ## @:whether the callback stopped early or not.
  ## @:
  ## @:~~~
  ## @:listLoop(a: list, container: any, listCallback: func, state: optional any) bool
  ## @:~~~~
  ## @:
  ## @:The callback gets passed the index to the item, its value, the
  ## @:container and the state variable.  The callback looks at the
  ## @:information and adds to the container when appropriate. The
  ## @:callback returns true to stop iterating.
  ## @:
  ## @:~~~
  ## @:listCallback(ix: int, item: any, container: any, state: optional any) bool
  ## @:~~~~
  ## @:
  ## @:The following example makes a new list [6, 8] from the list
  ## @:[2,4,6,8].  The callback is called b5.
  ## @:
  ## @:~~~
  ## @:container = []
  ## @:list = [2,4,6,8]
  ## @:stopped = listLoop(list, container, b5)
  ## @:newList => [6, 8]
  ## @:~~~
  ## @:
  ## @:Below is the definition of the b5 callback function.
  ## @:
  ## @:~~~
  ## @:b5 = func(“b5(ix: int, value: int, container: list) bool”)
  ## @:  ## Collect values greater than 5.
  ## @:  container &= if( (value > 5), value)
  ## @:  return(false)
  ## @:~~~

  # Note: This function is handled in runCommand as a special
  # case. This code is not run. It is here for the function list and
  # for documentation.
  result = newFunResult(newValue(0))

func fun_replace_siiss*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Replace a substring specified by its position and length with
  ## another string.  You can use the function to insert and append to
  ## a string as well.
  ## @:
  ## @:~~~
  ## @:replace(str: string, start: int, length: int, replacement: string) string
  ## @:~~~~
  ## @:
  ## @:* str: string
  ## @:* start: substring start index
  ## @:* length: substring length
  ## @:* replacement: substring replacement
  ## @:
  ## @:Examples:
  ## @:
  ## @:Replace:
  ## @:~~~
  ## @:replace("Earl Grey", 5, 4, "of Sandwich")
  ## @:  => "Earl of Sandwich"
  ## @:replace("123", 0, 1, "abcd") => abcd23
  ## @:replace("123", 0, 2, "abcd") => abcd3
  ## @:
  ## @:replace("123", 1, 1, "abcd") => 1abcd3
  ## @:replace("123", 1, 2, "abcd") => 1abcd
  ## @:
  ## @:replace("123", 2, 1, "abcd") => 12abcd
  ## @:~~~~
  ## @:Insert:
  ## @:~~~
  ## @:replace("123", 0, 0, "abcd") => abcd123
  ## @:replace("123", 1, 0, "abcd") => 1abcd23
  ## @:replace("123", 2, 0, "abcd") => 12abcd3
  ## @:replace("123", 3, 0, "abcd") => 123abcd
  ## @:~~~~
  ## @:Append:
  ## @:~~~
  ## @:replace("123", 3, 0, "abcd") => 123abcd
  ## @:~~~~
  ## @:Delete:
  ## @:~~~
  ## @:replace("123", 0, 1, "") => 23
  ## @:replace("123", 0, 2, "") => 3
  ## @:replace("123", 0, 3, "") => ""
  ## @:
  ## @:replace("123", 1, 1, "") => 13
  ## @:replace("123", 1, 2, "") => 1
  ## @:
  ## @:replace("123", 2, 1, "") => 12
  ## @:~~~~
  ## @:Edge Cases:
  ## @:~~~
  ## @:replace("", 0, 0, "") =>
  ## @:replace("", 0, 0, "a") => a
  ## @:replace("", 0, 0, "ab") => ab
  ## @:replace("", 0, 0, "abc") => abc
  ## @:replace("", 0, 0, "abcd") => abcd
  ## @:~~~~

  tMapParameters("replace", "siiss")

  let str = map["a"].stringv
  let start = map["b"].intv
  let length = map["c"].intv
  let replacement = map["d"].stringv

  if start < 0 or start > str.len:
    # Invalid position: got $1.
    result = newFunResultWarn(wInvalidPosition, 1, $start)
    return

  if length < 0 or start + length > str.len:
    # Invalid length: $1.
    result = newFunResultWarn(wInvalidLength, 2, $length)
    return

  var newString: string
  if start > 0 and start <= str.len:
    newString = str[0 .. start - 1]
  newString = newString & replacement
  if start + length < str.len:
    newString = newString & str[start + length .. str.len - 1]

  result = newFunResult(newValue(newString))

func replaceReMap(map: VarsDict): FunResult =
  ## Replace multiple parts of a string using regular expressions.
  ## The map parameteter has the target string in a and the pairs in
  ## b.

  let str = map["a"].stringv
  let list = map["b"].listv.list

  var replacements: seq[Replacement]
  for ix in countUp(0, list.len-1, 2):
    replacements.add(newReplacement(list[ix].stringv, list[ix+1].stringv))

  var resultStringO: Option[string]
  try:
    resultStringO = replaceMany(str, replacements)
  except:
    # You cannot get the msg because it has side effects.
    # debugEcho getCurrentExceptionMsg()
    discard
  if not resultStringO.isSome:
    # The replaceMany function failed.
    return newFunResultWarn(wReplaceMany, 1)

  result = newFunResult(newValue(resultStringO.get()))

func fun_replaceRe_sls*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Replace multiple parts of a string using regular expressions.
  ## @:
  ## @:You specify one or more pairs of regex patterns and their string
  ## @:replacements.
  ## @:
  ## @:~~~
  ## @:replaceRe(str: string, pairs: list) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:list = list("abc", "456", "def", "")
  ## @:replaceRe("abcdefabc", list))
  ## @:  => "456456"
  ## @:~~~~
  ## @:
  ## @:For developing and debugging regular expressions see the
  ## @:website: https@@://regex101.com/

  tMapParameters("replaceRe", "sls")
  let list = map["b"].listv.list
  if list.len mod 2 != 0:
    # Specify arguments in pairs.
    return newFunResultWarn(wPairParameters, 1)
  for ix, value in list:
    if value.kind != vkString:
      # The argument must be a string.
      return newFunResultWarn(wExpectedString, ix)

  replaceReMap(map)

func parsePath*(path: string, separator='/'): PathComponents =
  ## Parse the given file path into its component pieces.

  var dir: string
  var filename: string
  var basename: string
  var ext: string
  let pos = rfind(path, separator)
  if pos == -1:
    filename = path
  else:
    dir = path[0 .. pos]
    if pos+1 < path.len:
      filename = path[pos+1 .. ^1]

  if filename.len > 0:
    let dotPos = rfind(filename, '.')
    if dotPos != -1:
      ext = filename[dotPos .. ^1]
      if dotPos > 0:
        basename = filename[0 .. dotPos - 1]
    else:
      basename = filename

  result = newPathComponents(dir, filename, basename, ext)

func fun_path_sosd*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Split a file path into its component pieces. Return a dictionary
  ## with the filename, basename, extension and directory.
  ## @:
  ## @:You pass a path string and the optional path separator, forward
  ## @:slash or or backslash. When no separator, the current
  ## @:system separator is used.
  ## @:
  ## @:~~~
  ## @:path(filename: string, separator: optional string) dict
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:path("src/functions.nim") => {
  ## @:  "filename": "functions.nim",
  ## @:  "basename": "functions",
  ## @:  "ext": ".nim",
  ## @:  "dir": "src/",
  ## @:}
  ## @:
  ## @:path("src\\functions.nim", "\\") => {
  ## @:  "filename": "functions.nim",
  ## @:  "basename": "functions",
  ## @:  "ext": ".nim",
  ## @:  "dir": "src\\",
  ## @:}
  ## @:~~~~

  tMapParameters("path", "sosd")
  let path = map["a"].stringv
  var separator: char
  if "b" in map:
    case map["b"].stringv
    of "/":
      separator = '/'
    of "\\":
      separator = '\\'
    else:
      # Expected / or \\.
      return newFunResultWarn(wExpectedSeparator, 1)
  else:
    separator = os.DirSep

  let components = parsePath(path, separator)

  var dict = newVarsDict()
  dict["filename"] = newValue(components.filename)
  dict["basename"] = newValue(components.basename)
  dict["ext"] = newValue(components.ext)
  dict["dir"] = newValue(components.dir)

  result = newFunResult(newValue(dict))

func fun_lower_ss*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Lowercase a string.
  ## @:
  ## @:~~~
  ## @:lower(str: string) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:lower("Tea") => "tea"
  ## @:lower("TEA") => "tea"
  ## @:lower("TEĀ") => "teā"
  ## @:~~~~

  tMapParameters("lower", "ss")
  let str = map["a"].stringv
  result = newFunResult(newValue(toLower(str)))

func fun_keys_dl*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create a list from the keys in a dictionary.
  ## @:
  ## @:~~~
  ## @:keys(dictionary: dict) list
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d = dict("a", 1, "b", 2, "c", 3)
  ## @:keys(d) => ["a", "b", "c"]
  ## @:values(d) => [1, 2, 3]
  ## @:~~~~

  tMapParameters("keys", "dl")
  let dict = map["a"].dictv.dict

  var list: seq[string]
  for key, value in dict.pairs():
    list.add(key)

  result = newFunResult(newValue(list))

func fun_values_dl*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create a list out of the values in the specified dictionary.
  ## @:
  ## @:~~~
  ## @:values(dictionary: dict) list
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d = dict("a", "apple", "b", 2, "c", 3)
  ## @:keys(d) => ["a", "b", "c"]
  ## @:values(d) => ["apple", 2, 3]
  ## @:~~~~

  tMapParameters("values", "dl")
  let dict = map["a"].dictv.dict

  var list: seq[Value]
  for key, value in dict.pairs():
    list.add(value)

  result = newFunResult(newValue(list))

func generalSort(map: VarsDict): FunResult =
  ## Sort a list of values of the same type.

  let list = map["a"].listv.list

  if list.len == 0:
    return newFunResult(newEmptyListValue())

  let listKind = list[0].kind

  var sortOrder: SortOrder
  if "b" in map:
    case map["b"].stringv:
      of "ascending":
        sortOrder = Ascending
      of "descending":
        sortOrder = Descending
      else:
        # Expected the sort order, 'ascending' or 'descending'.
        return newFunResultWarn(wExpectedSortOrder, 1)
  else:
    sortOrder = Ascending

  var insensitive = false
  if "c" in map:
    case map["c"].stringv:
      of "sensitive":
        insensitive = false
      of "insensitive":
        insensitive = true
      else:
        # Expected sensitive or unsensitive.
        return newFunResultWarn(wExpectedSensitivity, 2)

  var index = 0i64
  var key: string
  if "d" in map:
    let value = map["d"]
    case value.kind:
      of vkInt:
        index = value.intv
      of vkString:
        key = value.stringv
      else:
        discard

  # Get the type of the first item.
  let firstItem = list[0]
  var firstListValueKind = vkString
  var firstKeyValueKind = vkString
  if listKind == vkDict:
    if not (key in firstItem.dictv.dict):
      # A dictionary is missing the sort key.
      return newFunResultWarn(wDictKeyMissing, 0)
    firstKeyValueKind = firstItem.dictv.dict[key].kind
  elif listKind == vkList:
    if firstItem.listv.list.len == 0:
      # A sublist is empty.
      return newFunResultWarn(wSubListsEmpty, 0)
    firstListValueKind = firstItem.listv.list[0].kind

  # Verify the all the values are the same type.
  for value in list:
    if value.kind != listKind:
      # The two arguments are not the same type.
      return newFunResultWarn(wNotSameKind, 0)
    case listKind:
      of vkList:
        if value.listv.list.len == 0:
          # A sublist is empty.
          return newFunResultWarn(wSubListsEmpty, 0)
        if value.listv.list[0].kind != firstListValueKind:
          # The first item in the sublists are different types.
          return newFunResultWarn(wSubListsDiffTypes, 0)
      of vkDict:
        if not (key in value.dictv.dict):
          # A dictionary is missing the sort key.
          return newFunResultWarn(wDictKeyMissing, 0)
        var keyValue = value.dictv.dict[key]
        if keyValue.kind != firstKeyValueKind:
          # The sort key values are different types.
          return newFunResultWarn(wKeyValueKindDiff, 0)
      else:
        discard

  func sortCmpValues(a, b: Value): int =
    case listKind
    of vkString, vkInt, vkFloat:
      result = cmpBaseValues(a, b, insensitive)
    of vkList:
      result = cmpBaseValues(a.listv.list[0], b.listv.list[0], insensitive)
    of vkDict:
      result = cmpBaseValues(a.dictv.dict[key], b.dictv.dict[key], insensitive)
    of vkBool, vkFunc:
      result = 0

  let newList = sorted(list, sortCmpValues, sortOrder)
  result = newFunResult(newValue(newList))

func fun_sort_lsosl*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Sort a list of values of the same type.  The values are ints,
  ## floats, or strings.
  ## @:
  ## @:You specify the sort order, "ascending" or "descending".
  ## @:
  ## @:You have the option of sorting strings case "insensitive". Case
  ## @:"sensitive" is the default.
  ## @:
  ## @:~~~
  ## @:sort(values: list, order: string, insensitive: optional string) list
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:ints = list(4, 3, 5, 5, 2, 4)
  ## @:sort(list, "ascending") => [2, 3, 4, 4, 5, 5]
  ## @:sort(list, "descending") => [5, 5, 4, 4, 3, 2]
  ## @:
  ## @:floats = list(4.4, 3.1, 5.9)
  ## @:sort(floats, "ascending") => [3.1, 4.4, 5.9]
  ## @:sort(floats, "descending") => [5.9, 4.4, 3.1]
  ## @:
  ## @:strs = list("T", "e", "a")
  ## @:sort(strs, "ascending") => ["T", "a", "e"]
  ## @:sort(strs, "ascending", "sensitive") => ["T", "a", "e"]
  ## @:sort(strs, "ascending", "insensitive") => ["a", "e", "T"]
  ## @:~~~~

  tMapParameters("sort", "lsosl")
  result = generalSort(map)

func fun_sort_lssil*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Sort a list of lists.
  ## @:
  ## @:You specify the sort order, "ascending" or "descending".
  ## @:
  ## @:You specify how to sort strings either case "sensitive" or
  ## @:"insensitive".
  ## @:
  ## @:You specify which index to compare by.  The compare index value
  ## @:must exist in each list, be the same type and be an int, float,
  ## @:or string.
  ## @:
  ## @:~~~
  ## @:sort(lists: list, order: string, case: string, index: int) list
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:l1 = list(4, 3, 1)
  ## @:l2 = list(2, 3, 4)
  ## @:listOfLists = list(l1, l2)
  ## @:sort(listOfLists, "ascending", "sensitive", 0) => [l2, l1]
  ## @:sort(listOfLists, "ascending", "sensitive", 2) => [l1, l2]
  ## @:~~~~

  tMapParameters("sort", "lssil")
  result = generalSort(map)

func fun_sort_lsssl*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Sort a list of dictionaries.
  ## @:
  ## @:You specify the sort order, "ascending" or "descending".
  ## @:
  ## @:You specify how to sort strings either case "sensitive" or
  ## @:"insensitive".
  ## @:
  ## @:You specify the compare key.  The key value must exist in
  ## @:each dictionary, be the same type and be an int, float or
  ## @:string.
  ## @:
  ## @:~~~
  ## @:sort(dicts: list, order: string, case: string, key: string) list
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d1 = dict("name", "Earl Gray", "weight", 1.2)
  ## @:d2 = dict("name", "Tea Pot", "weight", 3.5)
  ## @:dicts = list(d1, d2)
  ## @:sort(dicts, "ascending", "sensitive", "weight") => [d1, d2]
  ## @:sort(dicts, "descending", "sensitive", "name") => [d2, d1]
  ## @:~~~~

  tMapParameters("sort", "lsssl")
  result = generalSort(map)

func fun_githubAnchor_ll*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Create Github anchor names from heading names. Use it for Github
  ## markdown internal links. It handles duplicate heading names.
  ## @:
  ## @:~~~
  ## @:githubAnchor(names: list) list
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:list = list("Tea", "Water", "Tea")
  ## @:githubAnchor(list) =>
  ## @:  ["tea", "water", "tea-1"]
  ## @:~~~~

  tMapParameters("githubAnchor", "ll")

  let list = map["a"].listv.list

  # Add dash num postfix to the anchor name for dups.  Names is a
  # mapping from the anchor name to the number of times it is used.
  var names = newOrderedTable[string, int]()
  var anchorNames: seq[string]
  for name in list:
    if name.kind != vkString:
      # The list values must be all strings.
      return newFunResultWarn(wNotAllStrings, 0)

    let anchorName = githubAnchor(name.stringv)
    var count: int
    if anchorName in names:
      count = names[anchorName] + 1
      anchorNames.add("$1-$2" % [anchorName, $(count-1)])
    else:
      count = 1
      anchorNames.add(anchorName)
    names[anchorName] = count

  result = newFunResult(newValue(anchorNames))

func fun_type_as*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return the parameter type, one of: int, float, string, list,
  ## dict, bool or func.
  ## @:
  ## @:~~~
  ## @:type(variable: any) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:type(2) => "int"
  ## @:type(3.14159) => "float"
  ## @:type("Tea") => "string"
  ## @:type(list(1,2)) => "list"
  ## @:type(dict("a", 1)) => "dict"
  ## @:type(true) => "bool"
  ## @:type(f.cmp[0]) => "func"
  ## @:~~~~

  tMapParameters("type", "as")
  let kind = map["a"].kind
  result = newFunResult(newValue($kind))

func joinPathList(map: VarsDict): FunResult =
  ## Join path components.

  var separator = os.DirSep
  if "b" in map:
    case map["b"].stringv:
      of "/":
        separator = '/'
      of "\\":
        separator = '\\'
      of "":
        discard
      else:
        # Expected / or \\.
        return newFunResultWarn(wExpectedSeparator, 0)

  var ret: string
  for value in map["a"].listv.list:
    var component = value.stringv
    if component == "":
      component.add(separator)
    # Add the separator between components if there isn't already
    # one between them.
    if not (ret == "" or ret.endsWith(separator) or
        component.startsWith(separator)):
      ret.add(separator)
    ret.add(component)
  result = newFunResult(newValue(ret))

func fun_joinPath_loss*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Join the path components with a path separator.
  ## @:
  ## @:You pass a list of components to join. For the second optional
  ## @:parameter you specify the separator to use, either "/", "\" or
  ## @:"". If you specify "" or leave off the parameter, the current
  ## @:platform separator is used.
  ## @:
  ## @:If the separator already exists between components, a new one
  ## @:is not added. If a component is "", the platform separator is
  ## @:used for it.
  ## @:
  ## @:~~~
  ## @:joinPath(components: list, separator: optional string) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:joinPath(["images", "tea"]) =>
  ## @:  "images/tea"
  ## @:
  ## @:joinPath(["images", "tea"], "/") =>
  ## @:  "images/tea"
  ## @:
  ## @:joinPath(["images", "tea"], "\\") =>
  ## @:  "images\\tea"
  ## @:
  ## @:joinPath(["images/", "tea"]) =>
  ## @:  "images/tea"
  ## @:
  ## @:joinPath(["", "tea"]) =>
  ## @:  "/tea"
  ## @:
  ## @:joinPath(["/", "tea"]) =>
  ## @:  "/tea"
  ## @:~~~~

  tMapParameters("joinPath", "loss")
  result = joinPathList(map)

func fun_join_lsois*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Join a list of strings with a separator.  An optional parameter
  ## determines whether you skip empty strings or not. You can use an
  ## empty separator to concatenate the arguments.
  ## @:
  ## @:~~~
  ## @:join(strs: list, sep: string, skipEmpty: optional bool) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:join(["a", "b"], ", ") => "a, b"
  ## @:join(["a", "b"], "") => "ab"
  ## @:join(["a", "b", "c"], "") => "abc"
  ## @:join(["a"], ", ") => "a"
  ## @:join([""], ", ") => ""
  ## @:join(["a", "b"], "") => "ab"
  ## @:join(["a", "", "c"], "|") => "a||c"
  ## @:join(["a", "", "c"], "|", true) => "a|c"
  ## @:~~~~

  tMapParameters("join", "lsois")

  let list = map["a"].listv.list
  let sep = map["b"].stringv
  var skipEmpty = false
  if "c" in map and map["c"].intv == 1:
    skipEmpty = true
  var ret: string
  if list.len == 0:
    return newFunResult(newValue(""))
  if list.len > 0:
    ret.add(list[0].stringv)
  for value in list[1 .. list.len - 1]:
    if value.kind != vkString:
      # The join list items must be strings.
      return newFunResultWarn(wJoinListString, 0)
    let str = value.stringv
    if skipEmpty and str.len == 0:
      continue
    ret.add(sep)
    ret.add(str)
  result = newFunResult(newValue(ret))

func fun_warn_ss*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return a warning message and skip the current statement.
  ## You can call the warn function without an assignment.
  ## @:
  ## @:~~~
  ## @:warn(message: string) string
  ## @:~~~~
  ## @:
  ## @:You can warn conditionally in a bare if statement:
  ## @:
  ## @:~~~
  ## @:if0(c, warn("message is 0"))
  ## @:~~~~
  ## @:
  ## @:You can warn unconditionally using a bare warn statement:
  ## @:
  ## @:~~~
  ## @:warn("always warn")
  ## @:~~~~

  tMapParameters("warn", "ss")

  let message = map["a"].stringv
  result = newFunResultWarn(wUserMessage, 0, message)

func fun_log_ss*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Log a message to the log file.  You can call the log function
  ## without an assignment.
  ## @:
  ## @:~~~
  ## @:log(message: string) string
  ## @:~~~~
  ## @:
  ## @:You can log conditionally in a bare if statement:
  ## @:
  ## @:~~~
  ## @:if0(c, log("log this message when c is 0"))
  ## @:~~~
  ## @:
  ## @:You can log unconditionally using a bare log statement:
  ## @:
  ## @:~~~
  ## @:log("always log")
  ## @:~~~~

  tMapParameters("log", "si")
  let message = map["a"].stringv
  result = newFunResult(newValue(message))

func fun_return_aa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return is a special function that returns the value passed in and
  ## has side effects.
  ## @:
  ## @:In a function, the return completes the function and returns
  ## @:the value of it.
  ## @:
  ## @:~~~
  ## @:return(false)
  ## @:~~~~
  ## @:
  ## @:You can also use it with a bare IF statement to conditionally
  ## @:return a function value.
  ## @:
  ## @:~~~
  ## @:if(c, return(5))
  ## @:~~~~
  ## @:
  ## @:In a template command a return controls the replacement block
  ## @:looping by returning “skip” and “stop”.
  ## @:
  ## @:~~~
  ## @:if(c, return("stop"))
  ## @:if(c, return("skip"))
  ## @:~~~~
  ## @:
  ## @:* “stop” – stops processing the command
  ## @:* “skip” – skips this replacement block and continues with the next iteration
  ## @:
  ## @:The following block command repeats 4 times but skips when
  ## t.row is 2.
  ## @:
  ## @:~~~
  ## @:$$ block t.repeat = 4
  ## @:$$ : if((t.row == 2), return(“skip”))
  ## @:{t.row}
  ## @:$$ endblock
  ## @:
  ## @:output:
  ## @:
  ## @:0
  ## @:1
  ## @:3
  ## @:~~~~

  # Check there is one argument.
  tMapParameters("return", "aa")
  discard map
  # Invalid return; use a bare return in a user function or use it in a bare if statement.
  result = newFunResultWarn(wReturnArgument, -1)

func fun_string_aoss*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Convert a variable to a string. You specify the variable and
  ## optionally the type of output you want.
  ## @:
  ## @:~~~
  ## @:string(var: any, stype: optional string) string
  ## @:~~~~
  ## @:
  ## @:The default stype is "rb" which is used for replacement blocks.
  ## @:
  ## @:stype:
  ## @:
  ## @:* json -- returns JSON
  ## @:* rb — replacement block (rb) returns JSON except strings are
  ## @:not quoted and special characters are not escaped.
  ## @:* dn -- dot name (dn) returns JSON except dictionary elements
  ## @:are printed one per line as "key = value".
  ## @:
  ## @:Examples variables:
  ## @:
  ## @:~~~
  ## @:str = "Earl Grey"
  ## @:pi = 3.14159
  ## @:one = 1
  ## @:a = [1, 2, 3]
  ## @:d = dict(["x", 1, "y", 2])
  ## @:fn = cmp[[0]
  ## @:found = true
  ## @:~~~~
  ## @:
  ## @:json:
  ## @:
  ## @:~~~
  ## @:str => "Earl Grey"
  ## @:pi => 3.14159
  ## @:one => 1
  ## @:a => [1,2,3]
  ## @:d => {"x":1,"y":2}
  ## @:fn => "cmp"
  ## @:found => true
  ## @:~~~~
  ## @:
  ## @:rb:
  ## @:
  ## @:Same as JSON except the following.
  ## @:
  ## @:~~~
  ## @:str => Earl Grey
  ## @:fn => cmp
  ## @:~~~~
  ## @:
  ## @:dn:
  ## @:
  ## @:Same as JSON except the following.
  ## @:
  ## @:~~~
  ## @:d =>
  ## @:x = 1
  ## @:y = 2
  ## @:~~~~

  tMapParameters("string", "aoss")
  let value = map["a"]
  var ctype: string
  if "b" in map:
    ctype = map["b"].stringv
  else:
    ctype = "rb"

  var str: string
  case ctype:
  of "json":
    str = valueToString(value)
  of "rb":
    str = valueToStringRB(value)
  of "dn":
    if value.kind == vkDict:
      str = dotNameRep(value.dictv.dict)
    else:
      str = valueToString(value)
  else:
    # Invalid string type, expected rb, json or dot names.
    return newFunResultWarn(wInvalidStringType, 1)

  result = newFunResult(newValue(str))

func fun_string_sds*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Convert the dictionary variable to dot names. You specify the
  ## name of the dictionary and the dict variable.
  ## @:
  ## @:~~~
  ## @:string(dictName: string: d: dict) string
  ## @:~~~~
  ## @:
  ## @:Example:
  ## @:
  ## @:~~~
  ## @:d = {"x",1, "y":"tea", "z":{"a":8}}
  ## @:string("teas", d) =>
  ## @:
  ## @:teas.x = 1
  ## @:teas.y = "tea"
  ## @:teas.z.a = 8
  ## @:~~~~
  tMapParameters("string", "sds")
  let name = map["a"].stringv
  let dict = map["b"].dictv.dict
  let str = dotNameRep(dict, name)
  result = newFunResult(newValue(str))

func fun_format_ss*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Format a string using replacement variables similar to a
  ## replacement block. To enter a left bracket use two in a row.
  ## @:
  ## @:~~~
  ## @:format(str: string) string
  ## @:~~~~
  ## @:
  ## @:Example:
  ## @:
  ## @:~~~
  ## @:let first = "Earl"
  ## @:let last = "Grey"
  ## @:str = format("name: {first} {last}")
  ## @:
  ## @:str => "name: Earl Grey"
  ## @:~~~~
  ## @:
  ## @:To enter a left bracket use two in a row.
  ## @:
  ## @:~~~
  ## @:str = format("use two {{ to get one")
  ## @:
  ## @:str => "use two { to get one"
  ## @:~~~~

  tMapParameters("format", "ss")
  let str = map["a"].stringv
  let stringOr = formatString(variables, str)
  if stringOr.isMessage:
    return newFunResultWarn(stringOr.message)

  result = newFunResult(newValue(stringOr.value))

func fun_func_sp*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Define a function.
  ## @:
  ## @:~~~
  ## @:func(signature: string) func
  ## @:~~~~
  ## @:
  ## @:Example:
  ## @:
  ## @:~~~
  ## @:mycmp = func("numStrCmp(numStr1: string, numStr2: string) int")
  ## @:  ## Compare two number strings
  ## @:  ## and return 1, 0, or -1.
  ## @:  num1 = int(numStr1)
  ## @:  num2 = int(numStr2)
  ## @:  return(cmp(num1, num2))
  ## @:~~~~
  # The func definition is handled in the runCommand module. This code
  # is called for nested calls to func and it returns a warning.
  result = newFunResultWarn(wDefineFunction)

func fun_functionDetails_pd*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return the function details in a dictionary.
  ## @:
  ## @:~~~
  ## @:functionDetails(funcVar: func) dict
  ## @:~~~~
  ## @:
  ## @:The following example defines a simple function then gets its
  ## @:function details.
  ## @:
  ## @:~~~
  ## @:mycmp = func("strNumCmp(numStr1: string, numStr2: string) int")
  ## @:  ## Compare two number strings and return 1, 0, or -1.
  ## @:  return(cmp(int(numStr1), int(numStr2)))
  ## @:
  ## @:fd = functionDetails(mycmp)
  ## @:
  ## @:fd =>
  ## @:fd.builtIn = false
  ## @:fd.signature.optional = false
  ## @:fd.signature.name = "strNumCmp"
  ## @:fd.signature.paramNames = ["numStr1","numStr2"]
  ## @:fd.signature.paramTypes = ["string","string"]
  ## @:fd.signature.returnType = "int"
  ## @:fd.docComment = "  ## Compare two number strings and return 1, 0, or -1.\\n"
  ## @:fd.filename = "testcode.tea"
  ## @:fd.lineNum = 3
  ## @:fd.numLines = 2
  ## @:fd.statements = ["  return(cmp(int(numStr1), int(numStr2)))"]
  ## @:~~~~
  tMapParameters("functionDetails", "pd")
  let functionSpec = map["a"].funcv
  let details = functionDetails(functionSpec)
  result = newFunResult(details)

func fun_startsWith_ssb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Check whether a strings starts with the given prefix. Return true
  ## when it does, else false.
  ## @:
  ## @:~~~
  ## @:startsWith(str: string, str: prefix) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:a = startsWith("abcdef", "abc")
  ## @:b = startsWith("abcdef", "abf")
  ## @:
  ## @:a => true
  ## @:b => false
  ## @:~~~~

  tMapParameters("startsWith", "ssb")
  let str = map["a"].stringv
  let prefix = map["b"].stringv
  result = newFunResult(newValue(startsWith(str, prefix)))

func fun_not_bb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Boolean not.
  ## @:
  ## @:~~~
  ## @:not(value: bool) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:not(true) => false
  ## @:not(false) => true
  ## @:~~~~

  tMapParameters("not", "bb")
  let cond = map["a"].boolv
  result = newFunResult(newValue(not(cond)))

func fun_and_bbb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Boolean AND with short circuit. If the first argument is false,
  ## the second argument is not evaluated.
  ## @:
  ## @:~~~
  ## @:and(a: bool, b: bool) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:and(true, true) => true
  ## @:and(false, true) => false
  ## @:and(true, false) => false
  ## @:and(false, false) => false
  ## @:and(false, warn("not hit")) => false
  ## @:~~~~

  # Note: this code isn't run, it's here for the docs and the function
  # list.  The the code in runCommand.nim.
  tMapParameters("and", "bbb")
  let a = map["a"].boolv
  let b = map["b"].boolv
  let cond = a and b
  result = newFunResult(newValue(cond))

func fun_or_bbb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Boolean OR with short circuit. If the first argument is true,
  ## the second argument is not evaluated.
  ## @:
  ## @:~~~
  ## @:or(a: bool, b: bool) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:or(true, true) => true
  ## @:or(false, true) => true
  ## @:or(true, false) => true
  ## @:or(false, false) => false
  ## @:or(true, warn("not hit")) => true
  ## @:~~~~

  # Note: this code isn't run, it's here for the docs and the function
  # list.  The the code in runCommand.nim.
  tMapParameters("or", "bbb")
  let a = map["a"].boolv
  let b = map["b"].boolv
  let cond = a or b
  result = newFunResult(newValue(cond))

func fun_eq_iib*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when the two ints are equal.
  ## @:
  ## @:~~~
  ## @:eq(a: int, b: int) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:eq(1, 1) => true
  ## @:eq(2, 3) => false
  ## @:~~~~
  tMapParameters("eq", "iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a == b
  result = newFunResult(newValue(cond))

func fun_eq_ffb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when two floats are equal.
  ## @:
  ## @:~~~
  ## @:eq(a: float, b: float) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:eq(1.2, 1.2) => true
  ## @:eq(1.2, 3.2) => false
  ## @:~~~~
  tMapParameters("eq", "ffb")
  let a = map["a"].floatv
  let b = map["b"].floatv
  let cond = a == b
  result = newFunResult(newValue(cond))

func fun_eq_ssb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when two strings are equal.  See cmp function for case
  ## insensitive compare.
  ## @:
  ## @:~~~
  ## @:eq(a: string, b: string) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:eq("tea", "tea") => true
  ## @:eq("1.2", "3.2") => false
  ## @:~~~~
  tMapParameters("eq", "ssb")
  let a = map["a"].stringv
  let b = map["b"].stringv
  let cond = a == b
  result = newFunResult(newValue(cond))

func fun_ne_iib*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when two ints are not equal.
  ## @:
  ## @:~~~
  ## @:ne(a: int, b: int) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:ne(1, 1) => false
  ## @:ne(2, 3) => true
  ## @:~~~~
  tMapParameters("ne", "iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a != b
  result = newFunResult(newValue(cond))

func fun_ne_ffb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when two floats are not equal.
  ## @:
  ## @:~~~
  ## @:ne(a: float, b: float) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:ne(1.2, 1.2) => false
  ## @:ne(1.2, 3.2) => true
  ## @:~~~~
  tMapParameters("ne", "ffb")
  let a = map["a"].floatv
  let b = map["b"].floatv
  let cond = a != b
  result = newFunResult(newValue(cond))

func fun_ne_ssb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when two strings are not equal.
  ## @:
  ## @:~~~
  ## @:ne(a: string, b: string) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:ne("tea", "tea") => false
  ## @:ne("earl", "grey") => true
  ## @:~~~~
  tMapParameters("ne", "ssb")
  let a = map["a"].stringv
  let b = map["b"].stringv
  let cond = a != b
  result = newFunResult(newValue(cond))

func fun_gt_iib*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when an int is greater then another int.
  ## @:
  ## @:~~~
  ## @:gt(a: int, b: int) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:gt(2, 4) => false
  ## @:gt(3, 2) => true
  ## @:~~~~
  tMapParameters("gt", "iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a > b
  result = newFunResult(newValue(cond))

func fun_gt_ffb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when one float is greater than another float.
  ## @:
  ## @:~~~
  ## @:gt(a: float, b: float) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:gt(2.8, 4.3) => false
  ## @:gt(3.1, 2.5) => true
  ## @:~~~~
  tMapParameters("gt", "ffb")
  let a = map["a"].floatv
  let b = map["b"].floatv
  let cond = a > b
  result = newFunResult(newValue(cond))

func fun_gte_iib*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when an int is greater then or equal to another int.
  ## @:
  ## @:~~~
  ## @:gte(a: int, b: int) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:gte(2, 4) => false
  ## @:gte(3, 3) => true
  ## @:~~~~
  tMapParameters("gte", "iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a >= b
  result = newFunResult(newValue(cond))

func fun_gte_ffb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when a float is greater than or equal to another float.
  ## @:
  ## @:~~~
  ## @:gte(a: float, b: float) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:gte(2.8, 4.3) => false
  ## @:gte(3.1, 3.1) => true
  ## @:~~~~
  tMapParameters("gte", "ffb")
  let a = map["a"].stringv
  let b = map["b"].stringv
  let cond = a >= b
  result = newFunResult(newValue(cond))

func fun_lt_iib*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when an int is less than another int.
  ## @:
  ## @:~~~
  ## @:lt(a: int, b: int) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:gt(2, 4) => true
  ## @:gt(3, 2) => false
  ## @:~~~~
  tMapParameters("gt", "iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a < b
  result = newFunResult(newValue(cond))

func fun_lt_ffb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when a float is less then another float.
  ## @:
  ## @:~~~
  ## @:lt(a: float, b: float) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:lt(2.8, 4.3) => true
  ## @:lt(3.1, 2.5) => false
  ## @:~~~~
  tMapParameters("lt", "ffb")
  let a = map["a"].floatv
  let b = map["b"].floatv
  let cond = a > b
  result = newFunResult(newValue(cond))

func fun_lte_iib*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when an int is less than or equal to another int.
  ## @:
  ## @:~~~
  ## @:lte(a: int, b: int) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:lte(2, 4) => true
  ## @:lte(3, 3) => true
  ## @:lte(4, 3) => false
  ## @:~~~~
  tMapParameters("lte", "iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a <= b
  result = newFunResult(newValue(cond))

func fun_lte_ffb*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Return true when a float is less than or equal to another float.
  ## @:
  ## @:~~~
  ## @:lte(a: float, b: float) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:lte(2.3, 4.4) => true
  ## @:lte(3.0, 3.0) => true
  ## @:lte(4.0, 3.0) => false
  ## @:~~~~
  tMapParameters("lte", "ffb")
  let a = map["a"].floatv
  let b = map["b"].floatv
  let cond = a <= b
  result = newFunResult(newValue(cond))

func fun_readJson_sa*(variables: Variables, arguments: seq[Value]): FunResult =
  ## Convert a JSON string to a variable.
  ## @:
  ## @:~~~
  ## @:readJson(json: string) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:a = readJson("\"tea\"") => "tea"
  ## @:b = readJson("4.5") => 4.5
  ## @:c = readJson("[1,2,3]") => [1, 2, 3]
  ## @:d = readJson("{\"a\":1, \"b\": 2}")
  ## @:  => {"a": 1, "b", 2}
  ## @:~~~~
  tMapParameters("readJson", "sa")
  let json = map["a"].stringv
  var valueOr = readJsonString(json)
  if valueOr.isMessage:
    return newFunResultWarn(valueOr.message)
  result = newFunResult(valueOr.value)

var functionsDict* = newTable[string, FunctionPtr]()
  ## Maps a built-in function name to a function pointer you can call.
functionsDict["fun_add_fff"] = fun_add_fff
functionsDict["fun_add_iii"] = fun_add_iii
functionsDict["fun_and_bbb"] = fun_and_bbb
functionsDict["fun_bool_ab"] = fun_bool_ab
functionsDict["fun_case_iloaa"] = fun_case_iloaa
functionsDict["fun_case_sloaa"] = fun_case_sloaa
functionsDict["fun_cmp_ffi"] = fun_cmp_ffi
functionsDict["fun_cmp_iii"] = fun_cmp_iii
functionsDict["fun_cmp_ssobi"] = fun_cmp_ssobi
functionsDict["fun_cmpVersion_ssi"] = fun_cmpVersion_ssi
functionsDict["fun_concat_sss"] = fun_concat_sss
functionsDict["fun_dict_old"] = fun_dict_old
functionsDict["fun_dup_sis"] = fun_dup_sis
functionsDict["fun_eq_ffb"] = fun_eq_ffb
functionsDict["fun_eq_iib"] = fun_eq_iib
functionsDict["fun_eq_ssb"] = fun_eq_ssb
functionsDict["fun_exists_dsb"] = fun_exists_dsb
functionsDict["fun_find_ssoaa"] = fun_find_ssoaa
functionsDict["fun_float_if"] = fun_float_if
functionsDict["fun_float_saa"] = fun_float_saa
functionsDict["fun_float_sf"] = fun_float_sf
functionsDict["fun_format_ss"] = fun_format_ss
functionsDict["fun_func_sp"] = fun_func_sp
functionsDict["fun_functionDetails_pd"] = fun_functionDetails_pd
functionsDict["fun_get_dsoaa"] = fun_get_dsoaa
functionsDict["fun_get_lioaa"] = fun_get_lioaa
functionsDict["fun_githubAnchor_ll"] = fun_githubAnchor_ll
functionsDict["fun_gt_ffb"] = fun_gt_ffb
functionsDict["fun_gt_iib"] = fun_gt_iib
functionsDict["fun_gte_ffb"] = fun_gte_ffb
functionsDict["fun_gte_iib"] = fun_gte_iib
functionsDict["fun_if_baoaa"] = fun_if_baoaa
functionsDict["fun_if0_iaoaa"] = fun_if0_iaoaa
functionsDict["fun_int_fosi"] = fun_int_fosi
functionsDict["fun_int_sosi"] = fun_int_sosi
functionsDict["fun_int_ssaa"] = fun_int_ssaa
functionsDict["fun_join_lsois"] = fun_join_lsois
functionsDict["fun_joinPath_loss"] = fun_joinPath_loss
functionsDict["fun_keys_dl"] = fun_keys_dl
functionsDict["fun_len_di"] = fun_len_di
functionsDict["fun_len_li"] = fun_len_li
functionsDict["fun_len_si"] = fun_len_si
functionsDict["fun_list_al"] = fun_list_al
functionsDict["fun_listLoop_lapoab"] = fun_listLoop_lapoab
functionsDict["fun_log_ss"] = fun_log_ss
functionsDict["fun_lower_ss"] = fun_lower_ss
functionsDict["fun_lt_ffb"] = fun_lt_ffb
functionsDict["fun_lt_iib"] = fun_lt_iib
functionsDict["fun_lte_ffb"] = fun_lte_ffb
functionsDict["fun_lte_iib"] = fun_lte_iib
functionsDict["fun_ne_ffb"] = fun_ne_ffb
functionsDict["fun_ne_iib"] = fun_ne_iib
functionsDict["fun_ne_ssb"] = fun_ne_ssb
functionsDict["fun_not_bb"] = fun_not_bb
functionsDict["fun_or_bbb"] = fun_or_bbb
functionsDict["fun_path_sosd"] = fun_path_sosd
functionsDict["fun_readJson_sa"] = fun_readJson_sa
functionsDict["fun_replace_siiss"] = fun_replace_siiss
functionsDict["fun_replaceRe_sls"] = fun_replaceRe_sls
functionsDict["fun_return_aa"] = fun_return_aa
functionsDict["fun_slice_siois"] = fun_slice_siois
functionsDict["fun_sort_lsosl"] = fun_sort_lsosl
functionsDict["fun_sort_lssil"] = fun_sort_lssil
functionsDict["fun_sort_lsssl"] = fun_sort_lsssl
functionsDict["fun_startsWith_ssb"] = fun_startsWith_ssb
functionsDict["fun_string_aoss"] = fun_string_aoss
functionsDict["fun_string_sds"] = fun_string_sds
functionsDict["fun_sub_iii"] = fun_sub_iii
functionsDict["fun_sub_fff"] = fun_sub_fff
functionsDict["fun_type_as"] = fun_type_as
functionsDict["fun_values_dl"] = fun_values_dl
functionsDict["fun_warn_ss"] = fun_warn_ss

type
  BuiltInInfo* = object
    ## The built-in function information.
    ## @:
    ## @:* funcName -- the function name in the nim file, e.g.: fun_add_ii
    ## @:* docComment -- the function documentation
    ## @:* numLines -- the number of function code lines
    funcName*: string
    docComment*: string
    numLines*: Natural

func newBuiltInInfo*(
    funcName: string,
    docComment: string,
    numLines: Natural
  ): BuiltInInfo =
  ## Return a BuiltInInfo object.
  result = BuiltInInfo(funcName: funcName, docComment: docComment,
    numLines: numLines)

# Include the dynamically generated functions list file.
# Define two lists: functionsList and functionStarts.
include dynamicFuncList

proc getBestFunction*(funcValue: Value, arguments: seq[Value]): ValueOr =
  ## Given a function variable or a list of function variables and a
  ## list of arguments, return the one that best matches the
  ## arguments.

  if funcValue.kind == vkFunc:
    return newValueOr(funcValue)

  if funcValue.kind != vkList:
    # You cannot call the variable because it's not a function or a list of functions.
    let warningData = newWarningData(wNotFunction)
    return newValueOr(warningData)
  let funcList = funcValue.listv.list

  if funcList.len == 1:
    # There is only one function, return it.
    let funcValue = funcList[0]
    if funcValue.kind != vkFunc:
      # You cannot call the variable because it's not a function or a list of functions.
      let warningData = newWarningData(wNotFunction)
      return newValueOr(warningData)
    result = newValueOr(funcValue)
  elif funcList.len > 1:
    # Find the function that matches the most arguments.
    var maxDistance = 0
    var maxFuncValue = funcList[0]
    for funcValue in funcList:
      if funcValue.kind != vkFunc:
        # You cannot call the variable because it's not a function or a list of functions.
        let warningData = newWarningData(wNotFunction)
        return newValueOr(warningData)

      let funResult = mapParameters(funcValue.funcv.signature, arguments)
      if funResult.kind != frWarning:
        # All arguments match the parameters, return the function.
        return newValueOr(funcValue)

      # The mapParameters function returns the first parameter that
      # doesn't match. Use that to determine the best function to
      # return.
      if funResult.parameter > maxDistance:
        maxDistance = funResult.parameter
        maxFuncValue = funcValue

    if maxDistance == 0:
      # None of the $1 function signatures matched the first argument.
      let warningData = newWarningData(wNoneMatchedFirst, $funcList.len)
      return newValueOr(warningData)

    # Return the function that made it farthest through its
    # parameters.
    result = newValueOr(maxFuncValue)

func splitFuncName*(funcName: string): (string, string) =
  ## Split a funcName like "fun_cmp_ffi" to its name and signature like:
  ## "cmp" and "ffi".
  let parts = funcName.split('_')
  assert parts.len == 3
  assert parts[0] == "fun"
  result = (parts[1], parts[2])

proc makeFuncDictionary*(): VarsDict =
  ## Create the f dictionary from the built in functions.

  # An f dictionary item's key is the name of a function. Its value is a list
  # of func values with that name.

  assert(functionsList.len > 0)
  result = newVarsDict()

  # The functionsList is sorted by name then signature code.

  var funcList = newEmptyListValue()
  var lastName = ""
  assert functionsDict.len == functionsList.len
  assert functionsDict.len == functionStarts.len

  for ix, bii in functionsList:
    let (name, signatureCode) = splitFuncName(bii.funcName)
    let signatureO = newSignatureO(name, signatureCode)

    let builtIn = true
    let filename = "functions.nim"
    var statementLines = newSeq[Statement]()
    let functionName = "fun_$1_$2" % [name, signatureCode]
    let functionPtr = functionsDict[functionName]
    let lineNum = functionStarts[ix]
    let function = newFunc(builtIn, signatureO.get(), bii.docComment, filename,
      lineNum, bii.numLines, statementLines, functionPtr)

    let funcValue = newValue(function)
    if name == lastName:
      funcList.listv.list.add(funcValue)
    else:
      if lastName != "":
        result[lastName] = funcList
      funcList = newEmptyListValue()
      funcList.listv.list.add(funcValue)
      lastName = name

  if funcList.listv.list.len > 0:
    result[lastName] = funcList

# todo: how to you make the dictionary at compile time?
let funcsVarDict* = makeFuncDictionary()
  ## The f dictionary of built-in functions.
