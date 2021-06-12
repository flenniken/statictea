## This module contains the StaticTea functions and supporting types.
## The StaticTea language functions start with "fun", for example, the
## "funCmp" function implements the StaticTea "cmp" function.

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
import os
import algorithm

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

func cmpString*(a, b: string, insensitive: bool = false): int =
  ## Compares two utf8 strings a and b.  When a equals b return 0,
  ## when a is greater than b return 1 and when a is less than b
  ## return -1. Optionally ignore case.
  var i = 0
  var j = 0
  var ar, br: Rune
  var ret: int
  while i < a.len and j < b.len:
    fastRuneAt(a, i, ar)
    fastRuneAt(b, j, br)
    if insensitive:
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

func funCmp*(parameters: seq[Value]): FunResult =
  ## Compare two values. Returns -1 for less, 0 for equal and 1 for
  ## @:greater than.  The values are either int, float or string (both the
  ## @:same type) The default compares strings case sensitive.
  ## @:
  ## @:Compare numbers:
  ## @:
  ## @:* p1: number
  ## @:* p2: number
  ## @:* return: -1, 0, 1
  ## @:
  ## @:Compare strings:
  ## @:
  ## @:* p1: string
  ## @:* p2: string
  ## @:* p3: optional: 1 for case insensitive
  ## @:* return: -1, 0, 1
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cmp(7, 9) => -1
  ## @:cmp(8, 8) => 0
  ## @:cmp(9, 2) => 1
  ## @:
  ## @:cmp("coffee", "tea") => -1
  ## @:cmp("tea", "tea") => 0
  ## @:cmp("Tea", "tea") => 1
  ## @:cmp("Tea", "tea", 1) => 0
  ## @:~~~~

  # Check there are 2 or 3 parameters.
  if parameters.len() < 2 or parameters.len() > 3:
    return newFunResultWarn(wTwoOrThreeParameters)

  # Check the two values are the same kind.
  let value1 = parameters[0]
  let value2 = parameters[1]
  if value1.kind != value2.kind:
    return newFunResultWarn(wNotSameKind)

  # Check the two values are int, float or string.
  case value1.kind
  of vkInt, vkFloat, vkString:
    discard
  else:
    return newFunResultWarn(wIntFloatString)

  # Get the optional case insensitive and check it is 0 or 1.
  var insensitive = false
  if parameters.len() == 3:
    let value3 = parameters[2]
    if value3.kind != vkInt:
        return newFunResultWarn(wNotZeroOne, 2)
    case value3.intv:
    of 0:
      insensitive = false
    of 1:
      insensitive = true
    else:
      return newFunResultWarn(wNotZeroOne, 2)

  let ret = cmpBaseValues(value1, value2, insensitive)
  result = newFunResult(newValue(ret))

func funConcat*(parameters: seq[Value]): FunResult =
  ## Concatentate two or more strings.
  ## @:
  ## @:* p1: string
  ## @:* p2: string
  ## @:* ...
  ## @:* pn: string
  ## @:* return: string
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:concat("tea", " time") => "tea time"
  ## @:concat("a", "b", "c", "d") => "abcd"
  ## @:~~~~
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
  ## Length of a string, list or dictionary. For strings it returns
  ## @:the number of characters, not bytes. For lists and dictionaries
  ## @:it return the number of elements.
  ## @:
  ## @:* p1: string, list or dict
  ## @:* return: int
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:len("tea") => 3
  ## @:len(list(4, 1)) => 2
  ## @:len(dict('a', 4)) => 1
  ## @:~~~~
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
  ## Get a value from a list or dictionary.  You can specify a default
  ## @:value to return when the value doesn't exist, if you don't, a
  ## @:warning is generated when the element doesn't exist.
  ## @:
  ## @:Note: for dictionary lookup you can use dot notation for many
  ## @:cases.
  ## @:
  ## @:Dictionary case:
  ## @:
  ## @:* p1: dictionary
  ## @:* p2: key string
  ## @:* p3: optional default value returned when key is missing
  ## @:* return: value
  ## @:
  ## @:List case:
  ## @:
  ## @:* p1: list
  ## @:* p2: index of item
  ## @:* p3: optional default value returned when index is too big
  ## @:* return: value
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d = dict("tea", "Earl Grey")
  ## @:get(d, 'tea') => "Earl Grey"
  ## @:get(d, 'coffee', 'Tea') => "Tea"
  ## @:
  ## @:l = list(4, 'a', 10)
  ## @:get(l, 2) => 10
  ## @:get(l, 3, 99) => 99
  ## @:
  ## @:d = dict("tea", "Earl Grey")
  ## @:d.tea => "Earl Grey"
  ## @:~~~~

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
  ## Return a value based on a condition.
  ## @:
  ## @:* p1: int condition
  ## @:* p2: true case: the value returned when condition is 1
  ## @:* p3: else case: the value returned when condition is not 1.
  ## @:* return: p2 or p3
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:if(1, 'tea', 'beer') => "tea"
  ## @:if(0, 'tea', 'beer') => "beer"
  ## @:if(4, 'tea', 'beer') => "beer"
  ## @:~~~~

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
  ## Add two or more numbers.  The parameters must be all integers or
  ## @:all floats.  A warning is generated on overflow.
  ## @:
  ## @:Integer case:
  ## @:
  ## @:* p1: int
  ## @:* p2: int
  ## @:* ...
  ## @:* pn: int
  ## @:* return: int
  ## @:
  ## @:Float case:
  ## @:
  ## @:* p1: float
  ## @:* p2: float
  ## @:* ...
  ## @:* pn: float
  ## @:* return: float
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:add(1, 2) => 3
  ## @:add(1, 2, 3) => 6
  ## @:
  ## @:add(1.5, 2.3) => 3.8
  ## @:add(1.1, 2.2, 3.3) => 6.6
  ## @:~~~~

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
  ## Determine whether a key exists in a dictionary.
  ## @:
  ## @:* p1: dictionary
  ## @:* p2: key string
  ## @:* return: 0 or 1
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d = dict("tea", "Earl")
  ## @:exists(d, "tea") => 1
  ## @:exists(d, "coffee") => 0
  ## @:~~~~

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
  ## Return a value from multiple choices. It takes a main condition,
  ## @:any number of case pairs then an optional else value.
  ## @:
  ## @:The first parameter of a case pair is the condition and the
  ## @:second is the return value when that condition matches the main
  ## @:condition. The function compares the conditions left to right and
  ## @:returns the first match.
  ## @:
  ## @:When none of the cases match the main condition, the "else"
  ## @:value is returned. If none match and the else is missing, a
  ## @:warning is generated and the statement is skipped. The conditions
  ## @:must be integers or strings. The return values can be any type.
  ## @:
  ## @:* p1: the main condition value
  ## @:* p2: the first case condition
  ## @:* p3: the first case value
  ## @:* ...
  ## @:* pn-2: the last case condition
  ## @:* pn-1: the last case value
  ## @:* pn: the optional "else" value returned when nothing matches
  ## @:* return: any value
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:case(8, 8, "tea", "water") => "tea"
  ## @:case(8, 3, "tea", "water") => "water"
  ## @:case(8,
  ## @:  1, "tea", +
  ## @:  2, "water", +
  ## @:  3, "wine", +
  ## @:  "beer") => "beer"
  ## @:~~~~

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
  ## Compare two StaticTea version numbers. Returns -1 for less, 0 for
  ## @:equal and 1 for greater than.
  ## @:
  ## @:StaticTea uses @|@|Semantic Versioning]@|https@@://semver.org/]]
  ## @:with the added restriction that each version component has one
  ## @:to three digits (no letters).
  ## @:
  ## @:* p1: version number string
  ## @:* p2: version number string
  ## @:* return: -1, 0, 1
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cmpVersion("1.2.5", "1.1.8") => -1
  ## @:cmpVersion("1.2.5", "1.3.0") => 1
  ## @:cmpVersion("1.2.5", "1.2.5") => 1
  ## @:~~~~

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
  ## Create a float from an int or an int number string.
  ## @:
  ## @:* p1: int or int string
  ## @:* return: float
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:float(2) => 2.0
  ## @:float("33") => 33.0
  ## @:~~~~

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
  ## Create an int from a float or a float number string.
  ## @:
  ## @:* p1: float or float number string
  ## @:* p2: optional round option. "round" is the default.
  ## @:* return: int
  ## @:
  ## @:Round options:
  ## @:
  ## @:* "round" - nearest integer
  ## @:* "floor" - integer below (to the left on number line)
  ## @:* "ceiling" - integer above (to the right on number line)
  ## @:* "truncate" - remove decimals
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:int("2") => 2
  ## @:int("2.34") => 2
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
  ## Find the position of a substring in a string.  When the substring
  ## @:is not found you can return a default value.  A warning is
  ## @:generated when the substring is missing and you don't specify a
  ## @:default value.
  ## @:
  ## @:
  ## @:* p1: string
  ## @:* p2: substring
  ## @:* p3: optional default value
  ## @:* return: the index of substring or p3
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

func funSubstr*(parameters: seq[Value]): FunResult =
  ## Extract a substring from a string by its position. You pass the
  ## @:string, the substring's start index then its end index+1.
  ## @:The end index is optional and defaults to the end of the
  ## @:string.
  ## @:
  ## @:The range is half-open which includes the start position but not
  ## @:the end position. For example, [3, 7) includes 3, 4, 5, 6. The
  ## @:end minus the start is equal to the length of the substring.
  ## @:
  ## @:* p1: string
  ## @:* p2: start index
  ## @:* p3: optional: end index (one past end)
  ## @:* return: string
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:substr("Earl Grey", 0, 4) => "Earl"
  ## @:substr("Earl Grey", 5) => => "Grey"
  ## @:~~~~

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
  ## @:the second parameter is the number of times to duplicate it.
  ## @:
  ## @:* p1: string to duplicate
  ## @:* p2: number of times to repeat
  ## @:* return: string
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:dup("=", 3) => "==="
  ## @:substr("abc", 2) => "abcabc"
  ## @:~~~~

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
  ## Create a dictionary from a list of key, value pairs.  The keys
  ## @:must be strings and the values can be any type.
  ## @:
  ## @:* p1: key string
  ## @:* p2: value
  ## @:* ...
  ## @:* pn-1: key string
  ## @:* pn: value
  ## @:* return: dict
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:dict("a", 5) => {"a": 5}
  ## @:dict("a", 5, "b", 33, "c", 0) =>
  ## @:  {"a": 5, "b": 33, "c": 0}
  ## @:~~~~

  var dict = newVarsDict()
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
  ## Create a list of values.
  ## @:
  ## @:* p1: value
  ## @:* p2: value
  ## @:* p3: value
  ## @:* ...
  ## @:* pn: value
  ## @:* return: list
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:list() => []
  ## @:list(1) => [1]
  ## @:list(1, 2, 3) => [1, 2, 3]
  ## @:list("a", 5, "b") => ["a", 5, "b"]
  ## @:~~~~

  result = newFunResult(newValue(parameters))

func funReplace*(parameters: seq[Value]): FunResult =
  ## Replace a substring by its position.  You specify the substring
  ## @:position and the string to take its place.  You can use it to
  ## @:insert and append to a string as well.
  ## @:
  ## @:* p1: string
  ## @:* p2: start index of substring
  ## @:* p3: length of substring
  ## @:* p4: replacement substring
  ## @:* return: string
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:replace("Earl Grey", 5, 4, "of Sandwich")
  ## @:  => "Earl of Sandwich"
  ## @:replace("123", 0, 0, "abcd") => abcd123
  ## @:replace("123", 0, 1, "abcd") => abcd23
  ## @:replace("123", 0, 2, "abcd") => abcd3
  ## @:replace("123", 0, 3, "abcd") => abcd
  ## @:replace("123", 3, 0, "abcd") => 123abcd
  ## @:replace("123", 2, 1, "abcd") => 12abcd
  ## @:replace("123", 1, 2, "abcd") => 1abcd
  ## @:replace("123", 0, 3, "abcd") => abcd
  ## @:replace("123", 1, 0, "abcd") => 1abcd23
  ## @:replace("123", 1, 1, "abcd") => 1abcd3
  ## @:replace("123", 1, 2, "abcd") => 1abcd
  ## @:replace("", 0, 0, "abcd") => abcd
  ## @:replace("", 0, 0, "abc") => abc
  ## @:replace("", 0, 0, "ab") => ab
  ## @:replace("", 0, 0, "a") => a
  ## @:replace("", 0, 0, "") =>
  ## @:replace("123", 0, 0, "") => 123
  ## @:replace("123", 0, 1, "") => 23
  ## @:replace("123", 0, 2, "") => 3
  ## @:replace("123", 0, 3, "") =>
  ## @:~~~~

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
#   ## match.
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

# todo: add another parameter for regex flags.
func funReplaceRe*(parameters: seq[Value]): FunResult =
  ## Replace multiple parts of a string using regular expressions.
  ## @:
  ## @:You specify one or more pairs of a regex patterns and its string
  ## @:replacement. The pairs can be specified as parameters to the
  ## @:function or they can be part of a list.
  ## @:
  ## @:Muliple parameters case:
  ## @:
  ## @:* p1: string to replace
  ## @:* p2: pattern 1
  ## @:* p3: replacement string 1
  ## @:* p4: optional: pattern 2
  ## @:* p5: optional: replacement string 2
  ## @:* ...
  ## @:* pn-1: optional: pattern n
  ## @:* pn: optional: replacement string n
  ## @:* return: string
  ## @:
  ## @:List case:
  ## @:
  ## @:* p1: string to replace
  ## @:* p2: list of pattern and replacement pairs
  ## @:* return: string
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:replaceRe("abcdefabc", "abc", "456")
  ## @:  => "456def456"
  ## @:replaceRe("abcdefabc", "abc", "456", "def", "")
  ## @:  => "456456"
  ## @:l = list("abc", "456", "def", "")
  ## @:replaceRe("abcdefabc", l))
  ## @:  => "456456"
  ## @:~~~~
  ## @:
  ## @:For developing and debugging regular expressions see the
  ## @:website: https@@://regex101.com/

  if parameters.len < 2:
    result = newFunResultWarn(wTwoOrMoreParameters)
    return
  if parameters[0].kind != vkString:
    return newFunResultWarn(wExpectedString, 0)
  let str = parameters[0].stringv

  var theList: seq[Value]
  if parameters.len == 2:
    if parameters[1].kind != vkList:
      return newFunResultWarn(wExpectedList, 1)
    theList = parameters[1].listv
  else:
    theList = parameters[1..parameters.len-1]

  if theList.len mod 2 != 0:
    return newFunResultWarn(wMissingReplacement, 0)
  for ix, value in theList:
    if value.kind != vkString:
      return newFunResultWarn(wExpectedString, ix+1)

  var subs: seq[tuple[pattern: Regex, repl: string]]
  for ix in countUp(0, theList.len-1, 2):
    subs.add((re(theList[ix].stringv), theList[ix+1].stringv))

  let resultString = multiReplace(str, subs)
  result = newFunResult(newValue(resultString))

func funPath*(parameters: seq[Value]): FunResult =
  ## Split a file path into pieces. Return a dictionary with the
  ## @:filename, basename, extension and directory.
  ## @:
  ## @:You pass a path string and the optional path separator. When no
  ## @:separator, the current system separator is used.
  ## @:
  ## @:* p1: path string
  ## @:* p2: optional separator string, "/" or "\\".
  ## @:* return: dict
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:path("src/runFunction.nim") => {
  ## @:  "filename": "runFunction.nim",
  ## @:  "basename": "runFunction",
  ## @:  "ext": ".nim",
  ## @:  "dir": "src/",
  ## @:}
  ## @:
  ## @:path("src\\runFunction.nim", "\\") => {
  ## @:  "filename": "runFunction.nim",
  ## @:  "basename": "runFunction",
  ## @:  "ext": ".nim",
  ## @:  "dir": "src\\",
  ## @:}
  ## @:~~~~

  if parameters.len < 1 or parameters.len > 2:
    return newFunResultWarn(wOneOrTwoParameters, 0)

  if parameters[0].kind != vkString:
    return newFunResultWarn(wExpectedString, 0)
  let path = parameters[0].stringv

  var separator: char
  if parameters.len > 1:
    let p1 = parameters[1]
    if p1.kind != vkString:
      return newFunResultWarn(wExpectedString, 1)
    case p1.stringv
    of "/":
      separator = '/'
    of "\\":
      separator = '\\'
    else:
      return newFunResultWarn(wExpectedSeparator, 1)
  else:
    separator = os.DirSep

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

  var dict = newVarsDict()
  dict["filename"] = newValue(filename)
  dict["basename"] = newValue(basename)
  dict["ext"] = newValue(ext)
  dict["dir"] = newValue(dir)

  result = newFunResult(newValue(dict))

func funLower*(parameters: seq[Value]): FunResult =
  ## Lowercase a string.
  ## @:
  ## @:* p1: string
  ## @:* return: lowercase string
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:lower("Tea") => "tea"
  ## @:~~~~

  if parameters.len() != 1:
    return newFunResultWarn(wOneParameter)

  if parameters[0].kind != vkString:
    return newFunResultWarn(wExpectedString, 0)

  let str = parameters[0].stringv
  result = newFunResult(newValue(toLower(str)))

func funKeys*(parameters: seq[Value]): FunResult =
  ## Create a list from the keys in a dictionary.
  ## @:
  ## @:* p1: dictionary
  ## @:* return: list
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d = dict("a", 1, "b", 2, "c", 3)
  ## @:keys(d) => ["a", "b", "c"]
  ## @:values(d) => ["apple", 2, 3]
  ## @:~~~~

  if parameters.len() != 1:
    return newFunResultWarn(wOneParameter)

  if parameters[0].kind != vkDict:
    return newFunResultWarn(wExpectedDictionary, 0)

  let dict = parameters[0].dictv
  var theList: seq[string]
  for key, value in dict.pairs():
    theList.add(key)

  result = newFunResult(newValue(theList))

func funValues*(parameters: seq[Value]): FunResult =
  ## Create a list of the values in the specified dictionary.
  ## @:
  ## @:* p1: dictionary
  ## @:* return: list
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d = dict("a", "apple", "b", 2, "c", 3)
  ## @:keys(d) => ["a", "b", "c"]
  ## @:values(d) => ["apple", 2, 3]
  ## @:~~~~

  if parameters.len() != 1:
    return newFunResultWarn(wOneParameter)

  if parameters[0].kind != vkDict:
    return newFunResultWarn(wExpectedDictionary, 0)

  let dict = parameters[0].dictv
  var theList: seq[Value]
  for key, value in dict.pairs():
    theList.add(value)

  result = newFunResult(newValue(theList))

func funSort*(parameters: seq[Value]): FunResult =
  ## Sort a list of values of the same type.
  ## @:
  ## @:When sorting strings you have the option to compare case
  ## @:sensitive or insensitive.
  ## @:
  ## @:When sorting lists the lists are compared by their first
  ## @:element. The first elements must exist, be the same type and be
  ## @:an int, float or string. You have the option of comparing strings
  ## @:case insensitive.
  ## @:
  ## @:Dictionaries are compared by the value of one of their keys.  The
  ## @:key values must exist, be the same type and be an int, float or
  ## @:string. You have the option of comparing strings case
  ## @:insensitive.
  ## @:
  ## @:int, float case:
  ## @:
  ## @:* p1: list of ints or list of floats
  ## @:* p2: optional: "ascending", "descending"
  ## @:* return: sorted list
  ## @:
  ## @:string or list case:
  ## @:
  ## @:* p1: list of strings or list of lists
  ## @:* p2: optional: "ascending", "descending"
  ## @:* p3: optional: default "sensitive", "insensitive"
  ## @:* return: sorted list
  ## @:
  ## @:dictionary case:
  ## @:
  ## @:* p1: list of dictionaries
  ## @:* p2: "ascending", "descending"
  ## @:* p3: "sensitive", "insensitive"
  ## @:* p4: key string
  ## @:* return: sorted list
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:l = list(4, 3, 5, 5, 2, 4)
  ## @:sort(l) => [2, 3, 4, 4, 5, 5]
  ## @:sort(l, "descending") => [5, 5, 4, 4, 3, 2]
  ## @:
  ## @:strs = list('T', 'e', 'a')
  ## @:sort(strs) => ['T', 'a', 'e']
  ## @:sort(strs, "ascending", "sensitive") => ['T', 'a', 'e']
  ## @:sort(strs, "ascending", "insensitive") => ['a', 'e', 'T']
  ## @:
  ## @:l1 = list(4, 3, 1)
  ## @:l2 = list(2, 3, 0)
  ## @:listOfList = list(l1, l2)
  ## @:sort(listOfList) => [l2, l1]
  ## @:
  ## @:d1 = dict('name', 'Earl Gray', 'weight', 1.2)
  ## @:d2 = dict('name', 'Tea Pot', 'weight', 3.5)
  ## @:dicts = list(d1, d2)
  ## @:sort(dicts, "ascending", "sensitive", 'weight') => [d1, d2]
  ## @:sort(dicts, "descending", "sensitive", 'name') => [d2, d1]
  ## @:~~~~

  if parameters.len() < 1 or parameters.len() > 4:
    return newFunResultWarn(wOneToFourParameters)

  if parameters[0].kind != vkList:
    return newFunResultWarn(wExpectedList, 0)
  let list = parameters[0].listv

  if list.len == 0:
    return newFunResult(newEmptyListValue())
  let listKind = list[0].kind

  var sortOrder = Ascending
  if parameters.len() >= 2:
    if parameters[1].kind != vkString:
      return newFunResultWarn(wExpectedSortOrder, 1)
    case parameters[1].stringv:
      of "ascending":
        sortOrder = Ascending
      of "descending":
        sortOrder = Descending
      else:
        return newFunResultWarn(wExpectedSortOrder, 1)

  var insensitive = false
  if parameters.len() >= 3:
    if parameters[2].kind != vkString:
      return newFunResultWarn(wExpectedSensitivity, 2)
    case parameters[2].stringv:
      of "sensitive":
        insensitive = false
      of "insensitive":
        insensitive = true
      else:
        return newFunResultWarn(wExpectedSensitivity, 2)

  var key = ""
  if listKind == vkDict:
    if parameters.len() < 4:
      return newFunResultWarn(wExpectedKey, 3)
    key = parameters[3].stringv

  # Get the type of the first item.
  let firstItem = list[0]
  var firstListValueKind = vkString
  var firstKeyValueKind = vkString
  if listKind == vkDict:
    if not (key in firstItem.dictv):
      return newFunResultWarn(wDictKeyMissing, 0)
    firstKeyValueKind = firstItem.dictv[key].kind
  elif listKind == vkList:
    if firstItem.listv.len == 0:
      return newFunResultWarn(wSubListsEmpty, 0)
    firstListValueKind = firstItem.listv[0].kind

  # Verify the all the values are the same type.
  for value in list:
    if value.kind != listKind:
      return newFunResultWarn(wNotSameKind, 0)
    case listKind:
      of vkList:
        if value.listv.len == 0:
          # A sublist is empty.
          return newFunResultWarn(wSubListsEmpty, 0)
        if value.listv[0].kind != firstListValueKind:
          # The first item in the sublists are different types.
          return newFunResultWarn(wSubListsDiffTypes, 0)
      of vkDict:
        if not (key in value.dictv):
          # A dictionary is missing the sort key.
          return newFunResultWarn(wDictKeyMissing, 0)
        var keyValue = value.dictv[key]
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
      result = cmpBaseValues(a.listv[0], b.listv[0], insensitive)
    of vkDict:
      result = cmpBaseValues(a.dictv[key], b.dictv[key], insensitive)

  let newList = sorted(list, sortCmpValues, sortOrder)
  result = newFunResult(newValue(newList))

# todo: pass a list of names to githubAnchor and return a list of anchor names.

func funGithubAnchor*(parameters: seq[Value]): FunResult =
  ## Create a Github markdown anchor name given a heading name.  If
  ## @:you have duplicate heading names, the anchor name returned only
  ## @:works for the first. Use it for Github markdown internal links.
  ## @:
  ## @:* p1: heading name
  ## @:* return: anchor name
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:githubAnchor("MyHeading") => "myheading"
  ## @:githubAnchor("Eary Gray") => "eary-gray"
  ## @:githubAnchor("$Eary-Gray#") => "eary-gray"
  ## @:
  ## @:$$ : anchor = githubAnchor(entry.name)
  ## @:* {type}@|{entry.name}](#{anchor}) &mdash; {short}
  ## @:...
  ## @:# {entry.name}
  ## @:~~~~

  # You can test how well it matches github's algorithm by
  # inspecting the html code it generates.  Inspect the headings.
  #
  # The code that creates the anchors is here:
  # https://github.com/jch/html-pipeline/blob/master/lib/html/pipeline/toc_filter.rb

  if parameters.len() != 1:
    return newFunResultWarn(wOneParameter)

  if parameters[0].kind != vkString:
    return newFunResultWarn(wExpectedString)
  var name = parameters[0].stringv

  # Rules:
  # * lowercase letters
  # * change whitespace to hyphens
  # * allow ascii digits or hyphens
  # * drop other characters

  var anchorRunes = newSeq[Rune]()
  for rune in runes(name):
    if isAlpha(rune): # letters
      anchorRunes.add(toLower(rune))
    elif isWhiteSpace(rune):
      anchorRunes.add(toRunes("-")[0])
    elif rune.uint32 < 128: # ascii
      let ch = toUTF8(rune)[0]
      if isDigit(ch) or ch == '-':
        anchorRunes.add(rune)

  let anchorName = $anchorRunes
  result = newFunResult(newValue(anchorName))

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
    ("path", funPath),
    ("lower", funLower),
    ("keys", funKeys),
    ("values", funValues),
    ("sort", funSort),
    ("githubAnchor", funGithubAnchor),
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
