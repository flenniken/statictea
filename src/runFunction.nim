
## This module contains the StaticTea functions and supporting types.
## The StaticTea language functions start with "fun", for example, the
## "funCmp" function implements the StaticTea "cmp" function.

import std/options
import std/tables
import std/strutils
import std/math
import std/os
import std/algorithm
import warnings
import vartypes
import regexes
import parseNumber
import matches
import unicodes
import signatures
import funtypes

# Table of the built in functions. Each function name can have
# multiple versions with different signatures.
var functions: Table[string, seq[FunctionSpec]]

func newFunctionSpec(name: string, functionPtr: FunctionPtr,
    signatureCode: string): FunctionSpec =
  ## Create a new FunctionSpec object.
  result = FunctionSpec(name: name, functionPtr: functionPtr,
                        signatureCode: signatureCode)

# todo: add a parameters argument so it is clearer how the template operates.
template tMapParameters(signatureCode: string) =
  ## Template that checks the signatureCode against the parameters and
  ## sets the map dictionary variable.
  let paramsO = signatureCodeToParams(signatureCode)
  let funResult = mapParameters(paramsO.get(), parameters)
  if funResult.kind == frWarning:
    return funResult
  let map {.inject.} = funResult.value.dictv

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

# todo: cmp: support list and dict compares? Maybe similar to how sort compares.

func funCmp_iii*(parameters: seq[Value]): FunResult =
  ## @:Compare two ints. Returns -1 for less, 0 for equal and 1 for
  ## @: greater than.
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

  tMapParameters("iii")
  let a = map["a"].intv
  let b = map["b"].intv
  result = newFunResult(newValue(cmp(a, b)))

func funCmp_ffi*(parameters: seq[Value]): FunResult =
  ## @:Compare two floats. Returns -1 for less, 0 for
  ## @:equal and 1 for greater than.
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

  tMapParameters("ffi")
  let a = map["a"].floatv
  let b = map["b"].floatv
  result = newFunResult(newValue(cmp(a, b)))

func funCmp_ssoii*(parameters: seq[Value]): FunResult =
  ## @:Compare two strings. Returns -1 for less, 0 for equal and 1 for
  ## @:greater than.
  ## @:
  ## @:You have the option to compare case insensitive. Case sensitive
  ## @:is the default.
  ## @:
  ## @:~~~
  ## @:cmp(a: string, b: string, optional insensitive: int) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cmp("coffee", "tea") => -1
  ## @:cmp("tea", "tea") => 0
  ## @:cmp("Tea", "tea") => 1
  ## @:cmp("Tea", "tea", 0) => 1
  ## @:cmp("Tea", "tea", 1) => 0
  ## @:~~~~

  tMapParameters("ssoii")
  let a = map["a"].stringv
  let b = map["b"].stringv

  # Get the optional case insensitive and check it is 0 or 1.
  var insensitive = false
  if "c" in map:
    case map["c"].intv:
    of 0:
      insensitive = false
    of 1:
      insensitive = true
    else:
      return newFunResultWarn(wNotZeroOne, 2)

  let ret = cmpString(a, b, insensitive)
  result = newFunResult(newValue(ret))

func funConcat*(parameters: seq[Value]): FunResult =
  ## Concatentate two or more strings.
  ## @:
  ## @:~~~
  ## @:concat(strs: varargs(string)) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:concat("tea", " time") => "tea time"
  ## @:concat("a", "b", "c", "d") => "abcd"
  ## @:~~~~

  tMapParameters("Ss")
  let strs = map["a"].listv
  var returnString: string
  for value in strs:
    returnString.add(value.stringv)
  result = newFunResult(newValue(returnString))

func funLen_si*(parameters: seq[Value]): FunResult =
  ## Return the length of a string in characters, not bytes.
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

  tMapParameters("si")
  let str = map["a"].stringv
  result = newFunResult(newValue(stringLen(str)))

func funLen_li*(parameters: seq[Value]): FunResult =
  ## Return the number of elements in a list.
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

  tMapParameters("li")
  let list = map["a"].listv
  result = newFunResult(newValue(list.len))

func funLen_di*(parameters: seq[Value]): FunResult =
  ## Return the number of elements in a dictionary.
  ## @:
  ## @:~~~
  ## @:len(dictionary: dict) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:len(dict()) => 0
  ## @:len(dict('a', 4)) => 1
  ## @:len(dict('a', 4, 'b', 3)) => 2
  ## @:~~~~

  tMapParameters("di")
  let dict = map["a"].dictv
  result = newFunResult(newValue(dict.len))

func funGet_lioaa*(parameters: seq[Value]): FunResult =
  ## Return a value from a list by its index.  If the index is too
  ## @:big, the default value is returned when specified, else a warning
  ## @:is generated.
  ## @:
  ## @:~~~
  ## @:get(list: list, index: int, optional default: any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:list = list(4, 'a', 10)
  ## @:get(list, 2) => 10
  ## @:get(list, 3, 99) => 99
  ## @:~~~~

  tMapParameters("lioaa")
  let list = map["a"].listv
  let index = map["b"].intv

  if index < 0:
    result = newFunResultWarn(wInvalidIndex, 1, $index)
  elif index < list.len:
    result = newFunResult(newValue(list[index]))
  elif "c" in map:
    result = newFunResult(map["c"])
  else:
    result = newFunResultWarn(wMissingListItem, 1, $index)

func funGet_dsoaa*(parameters: seq[Value]): FunResult =
  ## Return a value in a dictionary by key.  If the key doesn't
  ## @:exist, the default value is returned, if specified, else a
  ## @:warning is generated.
  ## @:
  ## @:~~~
  ## @:get(dictionary: dict, key: string, optional default: any) any
  ## @:~~~~
  ## @:
  ## @:Note: For dictionary lookup you can use dot notation. It's the
  ## @:same as get without the default.
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d = dict("tea", "Earl Grey")
  ## @:get(d, 'tea') => "Earl Grey"
  ## @:get(d, 'coffee', 'Tea') => "Tea"
  ## @:
  ## @:Using dot notation:
  ## @:d = dict("tea", "Earl Grey")
  ## @:d.tea => "Earl Grey"
  ## @:~~~~

  tMapParameters("dsoaa")
  let dict = map["a"].dictv
  let key = map["b"].stringv

  if key in dict:
    result = newFunResult(dict[key])
  elif "c" in map:
    result = newFunResult(map["c"])
  else:
    result = newFunResultWarn(wMissingDictItem, 1, key)

func funIf*(parameters: seq[Value]): FunResult =
  ## Return a value when the condition is 1 and another value when the
  ## @:condition is not 1.
  ## @:
  ## @:~~~
  ## @:if(condition: int, oneCase: any, notOne: any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:if(1, 'tea', 'beer') => "tea"
  ## @:if(0, 'tea', 'beer') => "beer"
  ## @:if(4, 'tea', 'beer') => "beer"
  ## @:~~~~

  tMapParameters("iaaa")
  let condition = map["a"].intv
  let oneCase = map["b"]
  let notOne = map["c"]

  if condition == 1:
    result = newFunResult(oneCase)
  else:
    result = newFunResult(notOne)

{.push overflowChecks: on, floatChecks: on.}

func funAdd_Ii*(parameters: seq[Value]): FunResult =
  ## Add integers. A warning is generated on overflow.
  ## @:
  ## @:~~~
  ## @:add(numbers: varargs(int)) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:add(1) => 1
  ## @:add(1, 2) => 3
  ## @:add(1, 2, 3) => 6
  ## @:~~~~

  tMapParameters("Ii")
  let list = map["a"].listv
  var total = 0i64
  try:
    for num in list:
      total = total + num.intv
    result = newFunResult(newValue(total))
  except:
    result = newFunResultWarn(wOverflow)

func funAdd_Fi*(parameters: seq[Value]): FunResult =
  ## Add floats. A warning is generated on overflow.
  ## @:
  ## @:~~~
  ## @:add(numbers: varargs(float)) float
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:add(1.5) => 1.5
  ## @:add(1.5, 2.3) => 3.8
  ## @:add(1.1, 2.2, 3.3) => 6.6
  ## @:~~~~

  tMapParameters("Fi")
  let list = map["a"].listv
  var total = 0.0
  try:
    for num in list:
      total = total + num.floatv
    result = newFunResult(newValue(total))
  except:
    result = newFunResultWarn(wOverflow)

{.pop.}

func funExists*(parameters: seq[Value]): FunResult =
  ## Determine whether a key exists in a dictionary. Return 1 when it
  ## exists, else 0.
  ## @:
  ## @:~~~
  ## @:exists(dictionary: dict, key: string) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:d = dict("tea", "Earl")
  ## @:exists(d, "tea") => 1
  ## @:exists(d, "coffee") => 0
  ## @:~~~~

  tMapParameters("dsi")
  let dictionary = map["a"].dictv
  let key = map["b"].stringv

  var ret: int
  if key in dictionary:
    ret = 1
  result = newFunResult(newValue(ret))

func getCase(map: VarsDict): FunResult =
  ## Return the matching case value or the default when none
  ## match. The map dictionary contains the parameters to the case
  ## functions.
  let mainCondition = map["a"]
  let elseCase = map["b"]
  let cases = map["c"].listv

  for ix in countUp(0, cases.len-1, 2):
    let condition = cases[ix]

    if condition == mainCondition:
      let value = cases[ix+1]
      return newFunResult(value)

  # Return the else case.
  result = newFunResult(elseCase)

# todo: add two functions using a list with a default case at the end.
# case(condition: int, pairs: list, optional default: any) any
# case(condition: string, pairs: list, optional default: any) any

func funCase_iaIAa*(parameters: seq[Value]): FunResult =
  ## Return a value from multiple choices. It takes a main condition,
  ## @:an integer, any number of case pairs and an optional else value.
  ## @:
  ## @:The first element of a case pair is the condition and the
  ## @:second is the return value when that condition matches the main
  ## @:condition. The function compares the conditions left to right and
  ## @:returns the first match.
  ## @:
  ## @:When none of the cases match the main condition, the "else"
  ## @:value is returned.  The conditions must be integers. The return
  ## @:values can be any type.
  ## @:
  ## @:~~~
  ## @:case(condition: int, elseCase: any, pairs: varargs(int, any)) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cond = 8
  ## @:case(cond, "water", 8, "tea") => "tea"
  ## @:case(cond, "water", 3, "tea") => "water"
  ## @:case(cond, "beer", +
  ## @:  1, "tea", +
  ## @:  2, "water", +
  ## @:  3, "wine") => "beer"
  ## @:~~~~

  # todo remove the else case.

  tMapParameters("iaIAa")
  result = getCase(map)

func funCase_saSAa*(parameters: seq[Value]): FunResult =
  ## Return a value from multiple choices. It takes a main condition,
  ## @:a string, any number of case pairs and an optional else value.
  ## @:
  ## @:The first element of a case pair is the condition and the
  ## @:second is the return value when that condition matches the main
  ## @:condition. The function compares the conditions left to right and
  ## @:returns the first match.
  ## @:
  ## @:When none of the cases match the main condition, the "else"
  ## @:value is returned.  The conditions must be strings. The return
  ## @:values can be any type.
  ## @:
  ## @:~~~
  ## @:case(condition: string, elseCase: any, pairs: varargs(int, any)) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cond = "tea"
  ## @:case(cond, "water", 8, "tea") => "tea"
  ## @:case(cond, "water", 3, "tea") => "water"
  ## @:case(cond, "beer", +
  ## @:  1, "tea", +
  ## @:  2, "water", +
  ## @:  3, "wine") => "beer"
  ## @:~~~~

  # todo: remove else case

  tMapParameters("saSAa")
  result = getCase(map)

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
  ## @:~~~
  ## @:cmpVersion(versionA: string, versionB: string) int
  ## @:~~~~
  ## @:
  ## @:StaticTea uses @|@|https@@://semver.org/]@|Semantic Versioning]]
  ## @:with the added restriction that each version component has one
  ## @:to three digits (no letters).
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cmpVersion("1.2.5", "1.1.8") => -1
  ## @:cmpVersion("1.2.5", "1.3.0") => 1
  ## @:cmpVersion("1.2.5", "1.2.5") => 0
  ## @:~~~~

  tMapParameters("ssi")

  let versionA = map["a"].stringv
  let versionB = map["b"].stringv

  let aTupleO = parseVersion(versionA)
  if not aTupleO.isSome:
    return newFunResultWarn(wInvalidVersion, 0)
  let (oneV1, twoV1, threeV1) = aTupleO.get()

  let bTupleO = parseVersion(versionB)
  if not bTupleO.isSome:
    return newFunResultWarn(wInvalidVersion, 1)
  let (oneV2, twoV2, threeV2) = bTupleO.get()

  var ret = cmp(oneV1, oneV2)
  if ret == 0:
    ret = cmp(twoV1, twoV2)
    if ret == 0:
      ret = cmp(threeV1, threeV2)

  result = newFunResult(newValue(ret))

func funFloat*(parameters: seq[Value]): FunResult =
  ## Create a float from an int or an int number string.
  ## @:
  ## @:~~~
  ## @:float(num: int) float
  ## @:float(numString: string) float
  ## @:~~~~
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
  ## @:~~~
  ## @:int(num: float, optional roundOption: string) int
  ## @:int(numString: string, optional roundOption: string) int
  ## @:~~~~
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
  ## Return the position of a substring in a string.  When the
  ## @:substring is not found you can return a default value.  A warning
  ## @:is generated when the substring is missing and you don't specify
  ## @:a default value.
  ## @:
  ## @:~~~
  ## @:find(str: string, substring: string, optional default: any) any
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

  tMapParameters("ssoaa")

  let str = map["a"].stringv
  let substring = map["b"].stringv

  let pos = find(str, substring)
  if pos == -1:
    if "c" in map:
      result = newFunResult(map["c"])
    else:
      result = newFunResultWarn(wSubstringNotFound, 1)
  else:
    result = newFunResult(newValue(pos))

func funSubstr*(parameters: seq[Value]): FunResult =
  ## Extract a substring from a string by its position. You pass the
  ## @:string, the substring's start index then its end index+1.
  ## @:The end index is optional and defaults to the end of the
  ## @:string+1.
  ## @:
  ## @:The range is half-open which includes the start position but not
  ## @:the end position. For example, [3, 7) includes 3, 4, 5, 6. The
  ## @:end minus the start is equal to the length of the substring.
  ## @:
  ## @:~~~
  ## @:substr(str: string, start: int, optional end: int) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:substr("Earl Grey", 0, 4) => "Earl"
  ## @:substr("Earl Grey", 5) => "Grey"
  ## @:~~~~

  tMapParameters("siois")

  let str = map["a"].stringv
  let start = map["b"].intv
  var finish: int64
  if "c" in map:
    finish = map["c"].intv
  else:
    finish = str.len

  if start < 0:
    return newFunResultWarn(wInvalidPosition, 1, $start)
  if finish > str.len:
    return newFunResultWarn(wInvalidPosition, 2, $finish)
  if finish < start:
    return newFunResultWarn(wEndLessThenStart, 2)

  result = newFunResult(newValue(str[start .. finish-1]))

func funDup*(parameters: seq[Value]): FunResult =
  ## Duplicate a string. The first parameter is the string to dup and
  ## @:the second parameter is the number of times to duplicate it.
  ## @:
  ## @:~~~
  ## @:dup(pattern: string, count: int) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:dup("=", 3) => "==="
  ## @:dup("abc", 2) => "abcabc"
  ## @:dup("", 3) => ""
  ## @:~~~~

  tMapParameters("sis")

  let pattern = map["a"].stringv
  let count = map["b"].intv

  if count < 0:
    result = newFunResultWarn(wInvalidMaxCount, 1)
    return

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
  ## @:~~~
  ## @:dict(pairs: optional varargs(string, any)) dict
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:dict() => {}
  ## @:dict("a", 5) => {"a": 5}
  ## @:dict("a", 5, "b", 33, "c", 0) =>
  ## @:  {"a": 5, "b": 33, "c": 0}
  ## @:~~~~

  tMapParameters("oSAd")

  var dict = newVarsDict()

  if "a" in map:
    let pairs = map["a"].listv
    for ix in countUp(0, pairs.len-2, 2):
      var key = pairs[ix]
      var value = pairs[ix+1]
      dict[key.stringv] = value

  result = newFunResult(newValue(dict))

func funList*(parameters: seq[Value]): FunResult =
  ## Create a list of values.
  ## @:
  ## @:~~~
  ## @:list(items: optional varargs(any)) list
  ## @:~~~~
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

  tMapParameters("siiss")

  let str = map["a"].stringv
  let start = map["b"].intv
  let length = map["c"].intv
  let replacement = map["d"].stringv

  if start < 0 or start > str.len:
    result = newFunResultWarn(wInvalidPosition, 1, $start)
    return

  if length < 0 or start + length > str.len:
    result = newFunResultWarn(wInvalidLength, 2, $length)
    return

  var newString: string
  if start > 0 and start <= str.len:
    newString = str[0 .. start - 1]
  newString = newString & replacement
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

func funReplaceRe*(parameters: seq[Value]): FunResult =
  ## Replace multiple parts of a string using regular expressions.
  ## @:
  ## @:You specify one or more pairs of a regex patterns and its string
  ## @:replacement. The pairs can be specified as parameters to the
  ## @:function or they can be part of a list.
  ## @:
  ## @:~~~
  ## @:replaceRe(str: string, pairs: varargs(string, string) string
  ## @:replaceRe(str: string, pairs: list) string
  ## @:~~~~
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
  ## @:list = list("abc", "456", "def", "")
  ## @:replaceRe("abcdefabc", list))
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

  var replacements: seq[Replacement]
  for ix in countUp(0, theList.len-1, 2):
    replacements.add(newReplacement(theList[ix].stringv, theList[ix+1].stringv))
  let resultString = replaceMany(str, replacements)

  result = newFunResult(newValue(resultString))

func funPath*(parameters: seq[Value]): FunResult =
  ## Split a file path into pieces. Return a dictionary with the
  ## @:filename, basename, extension and directory.
  ## @:
  ## @:You pass a path string and the optional path separator, forward
  ## @:slash or or backwards slash. When no separator, the current
  ## @:system separator is used.
  ## @:
  ## @:~~~
  ## @:path(filename: string, optional separator: string) dict
  ## @:~~~~
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

  tMapParameters("sosd")
  let path = map["a"].stringv

  var separator: char
  if "b" in map:
    case map["b"].stringv
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
  ## @:~~~
  ## @:lower(str: string) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:lower("Tea") => "tea"
  ## @:lower("TEA") => "tea"
  ## @:~~~~

  tMapParameters("ss")
  let str = map["a"].stringv
  result = newFunResult(newValue(toLower(str)))

func funKeys*(parameters: seq[Value]): FunResult =
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
  ## @:values(d) => ["apple", 2, 3]
  ## @:~~~~

  tMapParameters("dl")
  let dict = map["a"].dictv

  var theList: seq[string]
  for key, value in dict.pairs():
    theList.add(key)

  result = newFunResult(newValue(theList))

func funValues*(parameters: seq[Value]): FunResult =
  ## Create a list of the values in the specified dictionary.
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

  tMapParameters("dl")
  let dict = map["a"].dictv

  var theList: seq[Value]
  for key, value in dict.pairs():
    theList.add(value)

  result = newFunResult(newValue(theList))

func funSort*(parameters: seq[Value]): FunResult =
  ## Sort a list of values of the same type.
  ## @:
  ## @:You have the option of sorting ascending or descending.
  ## @:
  ## @:When sorting strings you have the option to compare case
  ## @:sensitive or insensitive.
  ## @:
  ## @:When sorting lists, you specify which index to compare by, index
  ## @:0 is the default.  The compare index value must exist in each list, be
  ## @:the same type and be an int, float or string.
  ## @:
  ## @:When sorting dictionaries, you specify which key to compare by.
  ## @:The key value must exist in each dictionary, be the same type and
  ## @:be an int, float or string.
  ## @:
  ## @:~~~
  ## @:sort(ints: list, optional order: string) list
  ## @:sort(floats: list, optional order: string) list
  ## @:sort(strings: list, order: string, optional case: string) list
  ## @:sort(lists: list, order: string, case: string, index: int) list
  ## @:sort(dicts: list, order: string, case: string, key: string) list
  ## @:~~~~
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
  ## @:list = list(4, 3, 5, 5, 2, 4)
  ## @:sort(list) => [2, 3, 4, 4, 5, 5]
  ## @:sort(list, "descending") => [5, 5, 4, 4, 3, 2]
  ## @:
  ## @:strs = list('T', 'e', 'a')
  ## @:sort(strs) => ['T', 'a', 'e']
  ## @:sort(strs, "ascending", "sensitive") => ['T', 'a', 'e']
  ## @:sort(strs, "ascending", "insensitive") => ['a', 'e', 'T']
  ## @:
  ## @:l1 = list(4, 3, 1)
  ## @:l2 = list(2, 3, 0)
  ## @:listOfLists = list(l1, l2)
  ## @:sort(listOfLists) => [l2, l1]
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

# todo: add function where you specify a list of names and it returns
# a list of anchor names.

func funGithubAnchor*(parameters: seq[Value]): FunResult =
  ## Create a Github markdown anchor name given a heading name.  If
  ## @:you have duplicate heading names, the anchor name returned only
  ## @:works for the first. Use it for Github markdown internal links.
  ## @:
  ## @:~~~
  ## @:githubAnchor(name: string) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:githubAnchor("MyHeading") => "myheading"
  ## @:githubAnchor("Eary Gray") => "eary-gray"
  ## @:githubAnchor("$Eary-Gray#") => "eary-gray"
  ## @:~~~~
  ## @:
  ## @:Example in a markdown template:
  ## @:
  ## @:~~~
  ## @:$$ : anchor = githubAnchor(entry.name)
  ## @:* {type}@|{entry.name}](#{anchor}) &mdash; {short}
  ## @:...
  ## @:# {entry.name}
  ## @:~~~~

  tMapParameters("ss")

  let name = map["a"].stringv
  let anchorName = githubAnchor(name)
  result = newFunResult(newValue(anchorName))

const
  functionsList = [
    ("len", funLen_si, "si"),
    ("len", funLen_li, "li"),
    ("len", funLen_di, "di"),
    ("concat", funConcat, "Ss"),
    ("get", funGet_lioaa, "lioaa"),
    ("get", funGet_dsoaa, "dsoaa"),
    ("cmp", funCmp_iii, "iii"),
    ("cmp", funCmp_ffi, "ffi"),
    ("cmp", funCmp_ssoii, "ssoii"),
    ("if", funIf, "iaaa"),
    ("add", funAdd_Ii, "Ii"),
    ("add", funAdd_Fi, "Fi"),
    ("exists", funExists, "dsi"),
    ("case", funCase_iaIAa, "iaIAa"),
    ("case", funCase_saSAa, "saSAa"),
    ("cmpVersion", funCmpVersion, "ssi"),
    ("int", funInt, "fosi"),
    ("int", funInt, "sosi"),
    ("float", funFloat, "if"),
    ("float", funFloat, "sf"),
    ("find", funFind, "ssoaa"),
    ("substr", funSubstr, "siois"),
    ("dup", funDup, "sis"),
    ("dict", funDict, "oSAd"),
    ("list", funList, "oAl"),
    ("replace", funReplace, "siiss"),
    ("replaceRe", funReplaceRe, "sSSs"),
    ("replaceRe", funReplaceRe, "sls"),
    ("path", funPath, "sosd"),
    ("lower", funLower, "ss"),
    ("keys", funKeys, "dl"),
    ("values", funValues, "dl"),
    ("sort", funSort, "losl"),
    ("sort", funSort, "lsosl"),
    ("sort", funSort, "lssosl"),
    ("githubAnchor", funGithubAnchor, "ss"),
  ]

func createFunctionTable*(): Table[string, seq[FunctionSpec]] =
  ## Create a table of all the built in functions.
  for (name, functionPtr, signature) in functionsList:
    var functionSpecList = result.getOrDefault(name)
    functionSpecList.add(newFunctionSpec(name, functionPtr, signature))
    result[name] = functionSpecList

proc getFunctionList*(name: string): seq[FunctionSpec] =
  ## Return the functions with the given name.

  if functions.len == 0:
    functions = createFunctionTable()

  result = functions.getOrDefault(name)

proc getFunction*(functionName: string, parameters: seq[Value]): Option[FunctionSpec] =
  ## Find the function with the given name and return a pointer to it.
  ## If there are multiple functions with the name, return the one
  ## that matches the parameters, if none match, return the first one.
  let functionSpecList = getFunctionList(functionName)
  if functionSpecList.len > 1:
    # Find the function that matches the parameters.
    for functionSpec in functionSpecList:
      let paramsO = signatureCodeToParams(functionSpec.signatureCode)
      let funResult = mapParameters(paramsO.get(), parameters)
      if funResult.kind != frWarning:
        return some(functionSpec)
    # None match, return the first function.

    # todo: return the function that made if farthest through
    # mapParameters by looking for the biggest parameter index value.
  if functionSpecList.len != 0:
    let functionSpec = functionSpecList[0]
    result = some(functionSpec)

proc isFunctionName*(functionName: string): bool =
  ## Return true the function exists.
  let functionSpecList = getFunctionList(functionName)
  if functionSpecList.len > 0:
    result = true
