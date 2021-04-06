## Module containing StaticTea functions.

import vartypes
import options
import warnings
import tables
import unicode
import strutils
import regexes
import parseNumber
import math
import matches
import re

type
  FunctionPtr* = proc (parameters: seq[Value]): FunResult {.noSideEffect.}
    ## Signature of a statictea function. It takes any number of values
    ## and returns a value or a warning message.

  FunResultKind* = enum
    ## The kind of a FunResult object, either a value or warning.
    frValue,
    frWarning

  FunResult* = object
    ## Contains the result of calling a function, either a value or a
    ## warning.
    case kind*: FunResultKind
      of frValue:
        value*: Value       ## Return value of the function.
      of frWarning:
        parameter*: Natural ## Index of problem parameter.
        warningData*: WarningData

# A table of the built in functions.
var functions: Table[string, FunctionPtr]

func newFunResultWarn*(warning: Warning, parameter: Natural = 0,
      p1: string = "", p2: string = ""): FunResult =
  ## Return a new FunResult object. It contains a warning, the index of
  ## the problem parameter, and the two optional strings that go with
  ## the warning.
  let warningData = newWarningData(warning, p1, p2)
  result = FunResult(kind: frWarning, parameter: parameter,
                     warningData: warningData)

func newFunResult*(value: Value): FunResult =
  ## Return a new FunResult object containing a value.
  result = FunResult(kind: frValue, value: value)

func `==`*(r1: FunResult, r2: FunResult): bool =
  ## Compare two FunResult objects and return true when equal.
  if r1.kind == r2.kind:
    case r1.kind:
      of frValue:
        result = r1.value == r2.value
      else:
        if r1.warningData == r2.warningData and
           r1.parameter == r2.parameter:
          result = true

func `$`*(funResult: FunResult): string =
  ## Return a string representation of a FunResult object.
  case funResult.kind
  of frValue:
    result = $funResult.value
  else:
    result = "warning: $1: $2" % [
      $funResult.warningData, $funResult.parameter
    ]

func cmpString*(a, b: string, ignoreCase: bool = false): int =
  ## Compares two UTF-8 strings. Returns 0 when equal, 1 when a is
  ## greater than b and -1 when a less than b. Optionally Ignore case.
  var i = 0
  var j = 0
  var ar, br: Rune
  var ret: int
  while i < a.len and j < b.len:
    fastRuneAt(a, i, ar)
    fastRuneAt(b, j, br)
    if ignoreCase:
      ar = toLower(ar)
      br = toLower(br)
    ret = int(ar) - int(br)
    if ret != 0:
      break
  if ret == 0:
    ret = a.len - b.len
  if ret < 0:
    result = -1
  elif ret > 0:
    result = 1
  else:
    result = 0

func funCmp*(parameters: seq[Value]): FunResult =
  ## Compare two values.  The values are either numbers or strings
  ## (both the same type), and it returns whether the first parameter
  ## is less than, equal to or greater than the second parameter. It
  ## returns -1 for less, 0 for equal and 1 for greater than. The
  ## optional third parameter compares strings case insensitive when
  ## it is 1. Added in version 0.1.0.
  if parameters.len() < 2 or parameters.len() > 3:
    result = newFunResultWarn(wTwoOrThreeParameters)
    return
  let value1 = parameters[0]
  let value2 = parameters[1]
  if value1.kind != value2.kind:
    result = newFunResultWarn(wNotSameKind)
    return
  var ret: int
  case value1.kind
    of vkString:
      var caseInsensitive: bool
      if parameters.len() == 3:
        let value3 = parameters[2]
        if value3.kind == vkInt and value3.intv == 1:
          caseInsensitive = true
      ret = cmpString(value1.stringv, value2.stringv, caseInsensitive)
    of vkInt:
      ret = cmp(value1.intv, value2.intv)
    of vkFloat:
      ret = cmp(value1.floatv, value2.floatv)
    else:
      result = newFunResultWarn(wNotNumberOrString)
      return
  result = newFunResult(newValue(ret))

func funConcat*(parameters: seq[Value]): FunResult =
  ## Concatentate two or more strings.  Added in version 0.1.0.
  var str = ""
  if parameters.len() < 2:
    result = newFunResultWarn(wTwoOrMoreParameters)
    return
  for ix, value in parameters:
    if value.kind != vkString:
      result = newFunResultWarn(wExpectedString, ix)
      return
    str.add(value.stringv)
  result = newFunResult(newValue(str))

func funLen*(parameters: seq[Value]): FunResult =
  ## Return the len of a value. It takes one parameter and
  ## returns the number of characters in a string (not bytes), the
  ## number of elements in a list or the number of elements in a
  ## dictionary.  Added in version 0.1.0.
  if parameters.len() != 1:
    result = newFunResultWarn(wOneParameter)
    return
  var retValue: Value
  let value = parameters[0]
  case value.kind
    of vkString:
      retValue = newValue(runeLen(value.stringv))
    of vkList:
      retValue = newValue(value.listv.len)
    of vkDict:
      retValue = newValue(value.dictv.len)
    else:
      result = newFunResultWarn(wStringListDict)
      return
  result = newFunResult(retValue)

func funGet*(parameters: seq[Value]): FunResult =
  ## Return a value contained in a list or dictionary. You pass two or
  ## three parameters, the first is the dictionary or list to use, the
  ## second is the dictionary's key name or the list index, and the
  ## third optional parameter is the default value when the element
  ## doesn't exist. If you don't specify the default, a warning is
  ## generated when the element doesn't exist and the statement is
  ## skipped. Added in version 0.1.0.
  ## @:
  ## @:Get Dictionary Item:
  ## @:
  ## @:- p1: dictionary to search
  ## @:- p2: variable (key name) to find
  ## @:- p3: optional default value returned when key is missing
  ## @:
  ## @:Get List Item:
  ## @:
  ## @:- p1: list to use
  ## @:- p2: index of item in the list
  ## @:- p3: optional default value returned when index is too big

  if parameters.len() < 2 or parameters.len() > 3:
    return newFunResultWarn(wGetTakes2or3Params)

  let container = parameters[0]
  case container.kind
    of vkList:
      let p2 = parameters[1]
      if p2.kind != vkInt:
        return newFunResultWarn(wExpectedIntFor2, 1, $p2.kind)
      var index = p2.intv
      if index < 0:
        return newFunResultWarn(wInvalidIndex, 1, $index)
      if index >= container.listv.len:
        if parameters.len == 3:
          return newFunResult(parameters[2])
        return newFunResultWarn(wMissingListItem, 1, $index)
      return newFunResult(newValue(container.listv[index]))
    of vkDict:
      let p2 = parameters[1]
      if p2.kind != vkString:
        return newFunResultWarn(wExpectedStringFor2, 1, $p2.kind)
      var key = p2.stringv
      if key in container.dictv:
        return newFunResult(container.dictv[key])
      if parameters.len == 3:
        return newFunResult(newValue(parameters[2]))
      return newFunResultWarn(wMissingDictItem, 1, key)
    else:
      return newFunResultWarn(wExpectedListOrDict)

# todo: remove the if.  Use case instead.
func funIf*(parameters: seq[Value]): FunResult =
  ## You use the if function to return a value based on a condition.
  ## It has three parameters, the condition, the true case and the
  ## false case. Added in version 0.1.0.
  ## @:
  ## @:- p1: the integer condition
  ## @:- p2: true case: the value returned when condition is 1
  ## @:- p3: else case: the value returned when condition is not 1.

  if parameters.len() != 3:
    result = newFunResultWarn(wThreeParameters)
    return

  let condition = parameters[0]
  if condition.kind != vkInt:
    result = newFunResultWarn(wExpectedInteger)
    return

  if condition.intv == 1:
    result = newFunResult(parameters[1])
  else:
    result = newFunResult(parameters[2])

{.push overflowChecks: on, floatChecks: on.}

func funAdd*(parameters: seq[Value]): FunResult =
  ## Return the sum of two or more values.  The parameters must be all
  ## integers or all floats.  A warning is generated on overflow.
  ## Added in version 0.1.0.

  if parameters.len() < 2:
    result = newFunResultWarn(wTwoOrMoreParameters)
    return

  let first = parameters[0]
  if first.kind != vkInt and first.kind != vkFloat:
    result = newFunResultWarn(wAllIntOrFloat)
    return

  for ix, value in parameters[1..^1]:
    if value.kind != first.kind:
      result = newFunResultWarn(wAllIntOrFloat)
      return

    try:
      if first.kind == vkInt:
        first.intv = first.intv + value.intv
      else:
        first.floatv = first.floatv + value.floatv
    except:
      result = newFunResultWarn(wOverflow, ix)
      return

  result = newFunResult(first)

{.pop.}

func funExists*(parameters: seq[Value]): FunResult =
  ## Return 1 when a variable exists in a dictionary, else return
  ## @:0. The first parameter is the dictionary to check and the second
  ## @:parameter is the name of the variable. Added in version 0.1.0.
  ## @:
  ## @:- p1: dictionary: the dictionary containing the variable
  ## @:- p2: string: the variable name (key name) to look for

  if parameters.len() != 2:
    result = newFunResultWarn(wTwoParameters)
    return

  let container = parameters[0]
  if container.kind != vkDict:
    result = newFunResultWarn(wExpectedDictionary)
    return

  let key = parameters[1]
  if key.kind != vkString:
    result = newFunResultWarn(wExpectedString, 1)
    return

  var num: int
  if key.stringv in container.dictv:
    num = 1
  result = newFunResult(newValue(num))

func funCase*(parameters: seq[Value]): FunResult =
  ## The case function returns a value from multiple choices. It takes
  ## a main condition, any number of case pairs then an optional else
  ## value.
  ## @:
  ## @:The first parameter of a case pair is the condition and the
  ## second is the return value when that condition matches the main
  ## condition. The function compares the conditions left to right and
  ## returns the first match.
  ## @:
  ## @:When none of the cases match the main condition, the "else"
  ## value is returned. If none match and the else is missing, a
  ## warning is generated and the statement is skipped. The conditions
  ## must be integers or strings. The return values can be any type.
  ## Added in version 0.1.0.
  ## @:
  ## @:- p1: the main condition value
  ## @:- p2: the first case condition
  ## @:- p3: the first case value
  ## @:
  ## @:- ...
  ## @:
  ## @:- pn-2: the last case condition
  ## @:- pn-1: the last case value
  ## @:- pn: the optional "else" value returned when nothing matches

  # At least 3 parameters.
  if parameters.len() < 3:
    result = newFunResultWarn(wThreeOrMoreParameters)
    return

  let mainCondition = parameters[0]
  if mainCondition.kind != vkString and mainCondition.kind != vkInt:
    result = newFunResultWarn(wInvalidMainType)
    return

  # Make sure each condition is an int or string. We do this before
  # comparing to catch lurking error edge cases.
  for ix in countUp(1, parameters.len-2, 2):
    var condition = parameters[ix]
    if not [vkString, vkInt].contains(condition.kind):
      result = newFunResultWarn(wInvalidCondition, ix)
      return

  for ix in countUp(1, parameters.len-2, 2):
    var condition = parameters[ix]
    if condition.kind != mainCondition.kind:
      continue
    if condition.kind == vkString:
      if condition.stringv == mainCondition.stringv:
        return newFunResult(parameters[ix+1])
    else:
      if condition.intv == mainCondition.intv:
        return newFunResult(parameters[ix+1])

  # Possible parameter patterns:
  # m c v e
  # m c v c v e
  # m c v
  # m c v c v
  # 0 1 2 3 4 5
  # 1 2 3 4 5 6
  # Even number of parameters contains the else condition.
  # Odd doesn't have an else condition.

  if parameters.len mod 2 == 1:
    return newFunResultWarn(wMissingElse, 0)

  # Return the else case.
  result = newFunResult(parameters[parameters.len-1])

func parseVersion*(version: string): Option[(int, int, int)] =
  ## Parse a StaticTea version number and return its three components.
  let matchesO = matchVersionNotCached(version, 0)
  if not matchesO.isSome:
    return
  let (g1, g2, g3) = matchesO.get().get3Groups()
  var g1IntPosO = parseInteger(g1)
  var g2IntPosO = parseInteger(g2)
  var g3IntPosO = parseInteger(g3)
  result = some((int(g1IntPosO.get().integer), int(g2IntPosO.get().integer), int(g3IntPosO.get().integer)))

func funCmpVersion*(parameters: seq[Value]): FunResult =
  ## Compare two StaticTea type version numbers. Return whether the
  ## first parameter is less than, equal to or greater than the second
  ## parameter. It returns -1 for less, 0 for equal and 1 for greater
  ## than.
  ## @:
  ## @:StaticTea uses :linkTextBegin:Semantic Versioning:linkTextEnd:
  ## with the added restriction that each version component has one
  ## to three digits (no letters). Added in version 0.1.0.
  ## @:
  ## @: :linkTargetBegin:Semantic Versioning:linkTargetEnd://semver.org/

  if parameters.len() != 2:
    result = newFunResultWarn(wTwoParameters)
    return

  var parts: seq[(int, int, int)]
  for ix in 0 .. 1:
    if parameters[ix].kind != vkString:
      result = newFunResultWarn(wExpectedString, ix)
      return
    let tupleO = parseVersion(parameters[ix].stringv)
    if not tupleO.isSome:
      result = newFunResultWarn(wInvalidVersion, ix)
      return
    parts.add(tupleO.get())

  let (oneV1, twoV1, threeV1) = parts[0]
  let (oneV2, twoV2, threeV2) = parts[1]

  var ret = cmp(oneV1, oneV2)
  if ret == 0:
    ret = cmp(twoV1, twoV2)
    if ret == 0:
      ret = cmp(threeV1, threeV2)

  result = newFunResult(newValue(ret))

func funFloat*(parameters: seq[Value]): FunResult =
  ## Convert an int or an int number string to a float.  Added in
  ## version 0.1.0.
  ## @:
  ## @:.. note::
  ## @:  Use the format function to convert a number to a string.

  if parameters.len() != 1:
    return newFunResultWarn(wOneParameter)
  var p1 = parameters[0]
  case p1.kind
    of vkInt:
      # From int to float
      result = newFunResult(newValue(float(p1.intv)))
    of vkString:
      # From number string to float.
      var matchesO = matchNumberNotCached(p1.stringv)
      if not matchesO.isSome:
        return newFunResultWarn(wIntOrStringNumber)
      let matches = matchesO.get()
      let decimalPoint = matches.getGroup()
      if decimalPoint == ".":
        let floatPosO = parseFloat64(p1.stringv)
        if not floatPosO.isSome:
          return newFunResultWarn(wNumberOverFlow)
        result = newFunResult(newValue(floatPosO.get().number))
      else:
        let intPosO = parseInteger(p1.stringv)
        if not intPosO.isSome:
          return newFunResultWarn(wNumberOverFlow)
        result = newFunResult(newValue(float(intPosO.get().integer)))
    else:
      return newFunResultWarn(wIntOrStringNumber)

# todo: use int64 instead of BiggestInt everywhere.

func funInt*(parameters: seq[Value]): FunResult =
  ## Convert a float or a number string to an int. Added in version
  ## 0.1.0.
  ## @:
  ## @:- p1: value to convert, float or float number string
  ## @:- p2: optional round options. "round" is the default.
  ## @:
  ## @:Round options:
  ## @:
  ## @:- "round" - nearest integer
  ## @:- "floor" - integer below (to the left on number line)
  ## @:- "ceiling" - integer above (to the right on number line)
  ## @:- "truncate" - remove decimals

  if parameters.len() < 1 or parameters.len() > 2:
    return newFunResultWarn(wOneOrTwoParameters)
  var p1 = parameters[0]
  var num: float64

  case p1.kind
    of vkFloat:
      # From float to int.
      num = p1.floatv
    of vkString:
      # From number string to int.
      var matchesO = matchNumberNotCached(p1.stringv, 0)
      if not matchesO.isSome:
        return newFunResultWarn(wFloatOrStringNumber)
      let matches = matchesO.get()
      let decimalPoint = matches.getGroup()
      if decimalPoint == ".":
        # Float number string to int.
        let floatPosO = parseFloat64(p1.stringv)
        if not floatPosO.isSome:
          return newFunResultWarn(wFloatOrStringNumber)
        num = floatPosO.get().number
      else:
        # Int number string to int.
        let intPosO = parseInteger(p1.stringv)
        if not intPosO.isSome:
          return newFunResultWarn(wNumberOverFlow)
        return newFunResult(newValue(intPosO.get().integer))
    else:
      return newFunResultWarn(wFloatOrStringNumber)

  if num > float(high(int64)) or num < float(low(int64)):
    return newFunResultWarn(wNumberOverFlow)

  var option: string
  if parameters.len() == 2:
    let p2 = parameters[1]
    if p2.kind != vkString:
      return newFunResultWarn(wExpectedRoundOption, 1)
    option = p2.stringv
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
      return newFunResultWarn(wExpectedRoundOption, 1)
  result = newFunResult(newValue(ret))

func funFind*(parameters: seq[Value]): FunResult =
  ## Find a substring in a string and return its position when
  ## found. The first parameter is the string and the second is the
  ## substring. The third optional parameter is returned when the
  ## substring is not found.  A warning is generated when the
  ## substring is missing and no third parameter. Positions start at
  ## @:0. Added in version 0.1.0.
  ## @:
  ## @:.. code::
  ## @:
  ## @:  msg = "Tea time at 3:30."
  ## @:         0123456789 1234567
  ## @:  find(msg, "Tea") => 0
  ## @:  find(msg, "time") => 4
  ## @:  find(msg, "party", -1) => -1
  ## @:  find(msg, "party", len(msg)) => 17
  ## @:  find(msg, "party", 0) => 0

  if parameters.len() < 2 or parameters.len() > 3:
    result = newFunResultWarn(wTwoOrThreeParameters, 0)
    return

  for ix, parameter in parameters[0 .. 1]:
    if parameter.kind != vkString:
      result = newFunResultWarn(wExpectedString, ix)
      return

  let pos = find(parameters[0].stringv, parameters[1].stringv)
  if pos == -1:
    if parameters.len == 3:
      result = newFunResult(parameters[2])
    else:
      result = newFunResultWarn(wSubstringNotFound, 1)
  else:
    result = newFunResult(newValue(pos))

# todo: add examples for all functions.
func funSubstr*(parameters: seq[Value]): FunResult =
  ## Extract a substring from a string.  The first parameter is the
  ## string, the second is the substring's starting position and the
  ## third is one past the end. The first position is 0. The third
  ## parameter is optional and defaults to one past the end of the
  ## string. Added in version 0.1.0.
  ## @:
  ## @:This kind of positioning is called a half-open range that
  ## includes the first position but not the second. For example,
  ## [3, 7) includes 3, 4, 5, 6. The end minus the start is equal to
  ## the length of the substring.

  if parameters.len < 2 or parameters.len > 3:
    result = newFunResultWarn(wTwoOrThreeParameters)
    return

  if parameters[0].kind != vkString:
    result = newFunResultWarn(wExpectedString, 0)
    return
  let str = parameters[0].stringv

  if parameters[1].kind != vkInt:
    result = newFunResultWarn(wExpectedInteger, 1)
    return
  let start = int(parameters[1].intv)

  var finish: int
  if parameters.len == 3:
    if parameters[2].kind != vkInt:
      result = newFunResultWarn(wExpectedInteger, 2)
      return
    finish = int(parameters[2].intv)
  else:
    finish = str.len

  if start < 0:
    result = newFunResultWarn(wInvalidPosition, 1, $start)
    return
  if finish > str.len:
    result = newFunResultWarn(wInvalidPosition, 2, $finish)
    return
  if finish < start:
    result = newFunResultWarn(wEndLessThenStart, 2)
    return

  result = newFunResult(newValue(str[start .. finish-1]))

func funDup*(parameters: seq[Value]): FunResult =
  ## Duplicate a string. The first parameter is the string to dup and
  ## the second parameter is the number of times to duplicate it.
  ## Added in version 0.1.0.

  if parameters.len() != 2:
    result = newFunResultWarn(wTwoParameters)
    return

  if parameters[0].kind != vkString:
    result = newFunResultWarn(wExpectedString, 0)
    return
  let pattern = parameters[0].stringv

  if parameters[1].kind != vkInt or parameters[1].intv < 0:
    result = newFunResultWarn(wInvalidMaxCount, 1)
    return
  let count = parameters[1].intv

  # Result must be less than 1024 characters.
  let length = count * pattern.len
  if length > 1024:
    result = newFunResultWarn(wDupStringTooLong, 1, $length)
    return

  var str = newStringOfCap(length)
  for ix in countUp(1, int(count)):
    str.add(pattern)
  result = newFunResult(newValue(str))

func funDict*(parameters: seq[Value]): FunResult =
  ## Create a dictionary from a list of key, value pairs. You can
  ## specify as many pairs as you want. The keys must be strings and
  ## the values can be any type. Added in version 0.1.0.
  ## @:
  ## @:.. code::
  ## @:
  ## @:  dict("a", 5) => {"a": 5}
  ## @:  dict("a", 5, "b", 33, "c", 0) =>
  ## @:      {"a": 5, "b": 33, "c": 0}

  var dict: VarsDict
  if parameters.len == 0:
    return newFunResult(newValue(dict))

  # The parameters come in pairs.
  if parameters.len mod 2 == 1:
    return newFunResultWarn(wPairParameters, 0)

  for ix in countUp(0, parameters.len-2, 2):
    var key = parameters[ix]
    if key.kind != vkString:
      return newFunResultWarn(wExpectedString, ix)
    var value = parameters[ix+1]
    dict[key.stringv] = value

  result = newFunResult(newValue(dict))

func funList*(parameters: seq[Value]): FunResult =
  ## Create a list of values. You can specify as many variables as you
  ## want.  Added in version 0.1.0.
  ## @:
  ## @:.. code::
  ## @:
  ## @:  list(1) => [1]
  ## @:  list(1, 2, 3) => [1, 2, 3]
  ## @:  list("a", 5, "b") => ["a", 5, "b"]

  result = newFunResult(newValue(parameters))

func funReplace*(parameters: seq[Value]): FunResult =
  ## Replace a part of a string (substring) with another string.
  ## @:
  ## @:The first parameter is the string, the second is the substring's
  ## starting position, starting a 0, the third is the length of the
  ## substring and the fourth is the replacement string.
  ## @:
  ## @:.. code::
  ## @:
  ## @:  replace("Earl Grey", 5, 4, "of Sandwich")
  ## @:    => "Earl of Sandwich"
  ## @:  replace("123", 0, 0, "abcd") => abcd123
  ## @:  replace("123", 0, 1, "abcd") => abcd23
  ## @:  replace("123", 0, 2, "abcd") => abcd3
  ## @:  replace("123", 0, 3, "abcd") => abcd
  ## @:  replace("123", 3, 0, "abcd") => 123abcd
  ## @:  replace("123", 2, 1, "abcd") => 12abcd
  ## @:  replace("123", 1, 2, "abcd") => 1abcd
  ## @:  replace("123", 0, 3, "abcd") => abcd
  ## @:  replace("123", 1, 0, "abcd") => 1abcd23
  ## @:  replace("123", 1, 1, "abcd") => 1abcd3
  ## @:  replace("123", 1, 2, "abcd") => 1abcd
  ## @:  replace("", 0, 0, "abcd") => abcd
  ## @:  replace("", 0, 0, "abc") => abc
  ## @:  replace("", 0, 0, "ab") => ab
  ## @:  replace("", 0, 0, "a") => a
  ## @:  replace("", 0, 0, "") =>
  ## @:  replace("123", 0, 0, "") => 123
  ## @:  replace("123", 0, 1, "") => 23
  ## @:  replace("123", 0, 2, "") => 3
  ## @:  replace("123", 0, 3, "") =>

  if parameters.len != 4:
    result = newFunResultWarn(wExpected4Parameters)
    return

  if parameters[0].kind != vkString:
    result = newFunResultWarn(wExpectedString, 0)
    return
  let str = parameters[0].stringv

  if parameters[1].kind != vkInt:
    result = newFunResultWarn(wExpectedInteger, 1)
    return
  let start = int(parameters[1].intv)

  if start < 0 or start > str.len:
    result = newFunResultWarn(wInvalidPosition, 1, $start)
    return

  if parameters[2].kind != vkInt:
    result = newFunResultWarn(wExpectedInteger, 2)
    return
  let length = int(parameters[2].intv)

  if length < 0 or start + length > str.len:
    result = newFunResultWarn(wInvalidLength, 2, $length)
    return

  if parameters[3].kind != vkString:
    result = newFunResultWarn(wExpectedString, 3)
    return
  let replaceString = parameters[3].stringv

  var newString: string
  if start > 0 and start <= str.len:
    newString = str[0 .. start - 1]
  newString = newString & replaceString
  if start + length < str.len:
    newString = newString & str[start + length .. str.len - 1]

  result = newFunResult(newValue(newString))

# proc funMatch*(parameters: seq[Value]): FunResult =
#   ## Match a pattern in a string.
#   ##
#   ## The match function returns a dictionary with the results of the
#   ## match. Added in version 0.1.0.
#   ##
#   ## m = match(string, pattern, start, default)
#   ## m = match("Tea time", "Tea")
#   ## m = match("proc a(): FunResult =", "\bFunResult\b")
#   ## m = match("a = b99", "^([^=])\s=\s(.*)$")
#   ##
#   ## m = {
#   ##   "ix": 0,
#   ##   "str": "a = b99",
#   ##   "g0ix": 0,
#   ##   "g0str": "a",
#   ##   "g1ix": 4,
#   ##   "g1str": "b99"
#   ## }
#   ##
#   ## w = replace(str, m.ix, len(m.str), "FunResult_")

#   if parameters[0].kind != vkString:
#     result = newFunResultWarn(wExpectedString, 0)
#     return
#   let str = parameters[0].stringv

#   if parameters[1].kind != vkString:
#     result = newFunResultWarn(wExpectedString, 1)
#     return
#   let pattern = parameters[1].stringv

#   if parameters[2].kind != vkInt:
#     result = newFunResultWarn(wExpectedInteger, 2)
#     return
#   let start = int(parameters[2].intv)

#   if start < 0 or start > str.len:
#     result = newFunResultWarn(wInvalidPosition, 1, $start)
#     return

#   # let matchesO = matchPattern(str, pattern, start)
#   # check matchesO.isSome
#   #
#   # var dict: VarDic
#   #
#   # Matches = object
#   #   groups: seq[string]
#   #   length: Natural
#   #   start: Natural

# proc newMatcherDict(length: Natural, groups: varargs[string]): VarsDict =
#     result["len"] = newValue(length)
#     for ix, group in groups:
#       result["g" & $ix] = newValue(group)

func funReplaceRe*(parameters: seq[Value]): FunResult =
  ## Replace multiple parts of a string defined by regular
  ## expressions with replacement strings.
  ## @:
  ## @:The basic case uses one replacement pattern. It takes three
  ## @:parameters, the first parameter is the string to work on, the
  ## @:second is the regular expression pattern, and the fourth is the
  ## @:replacement string.
  ## @:
  ## @:In general you can have multiple sets of patterns and associated
  ## @:replacements. You add each pair of parameters at the end.
  ## @:
  ## @:.. code::
  ## @:
  ## @:  replaceRe("abcdefabc", "abc", "456")
  ## @:    => "456def456"
  ## @:  replaceRe("abcdefabc", "abc", "456", "def", "")
  ## @:    => "456456"

  if parameters.len < 3:
    result = newFunResultWarn(wThreeOrMoreParameters)
    return
  if parameters.len mod 2 != 1:
    return newFunResultWarn(wMissingReplacement, 0)

  for ix, parameter in parameters:
    if parameter.kind != vkString:
      return newFunResultWarn(wExpectedString, ix)

  var subs = newSeq[tuple[pattern: Regex, repl: string]]()
  let str = parameters[0].stringv
  for ix in countUp(1, parameters.len-1, 2):
    subs.add((re(parameters[ix].stringv), parameters[ix+1].stringv))

  let resultString = multiReplace(str, subs)

  result = newFunResult(newValue(resultString))

const
  functionsList = [
    ("len", funLen),
    ("concat", funConcat),
    ("get", funGet),
    ("cmp", funCmp),
    ("if", funIf),
    ("add", funAdd),
    ("exists", funExists),
    ("case", funCase),
    ("cmpVersion", funCmpVersion),
    ("int", funInt),
    ("float", funFloat),
    ("find", funFind),
    ("substr", funSubstr),
    ("dup", funDup),
    ("dict", funDict),
    ("list", funList),
    ("replace", funReplace),
    ("replaceRe", funReplaceRe),
  ]

proc getFunction*(functionName: string): Option[FunctionPtr] =
  ## Look up a function by its name.

  # Build a table of functions.
  if functions.len == 0:
    for item in functionsList:
      var (name, fun) = item
      functions[name] = fun

  var function = functions.getOrDefault(functionName)
  if function != nil:
    result = some(function)
