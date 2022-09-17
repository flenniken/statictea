## This module contains the StaticTea functions and supporting types.
## The StaticTea language functions start with "fun", for example, the
## "funCmp" function implements the StaticTea "cmp" function.

import std/options
import std/tables
import std/strutils
import std/math
import std/os
import std/algorithm
import messages
import warnings
import vartypes
import regexes
import parseNumber
import matches
import unicodes
import signatures
import replacement
import opresultwarn

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

func numberStringToNum(numString: string): FunResult =
  ## Convert the number string to a float or int, if possible.

  var matchesO = matchNumberNotCached(numString, 0)
  if not matchesO.isSome:
    # Expected number string.
    return newFunResultWarn(wExpectedNumberString)
  let decimalPoint = matchesO.getGroup()

  if decimalPoint == ".":
    # Float number string to float.
    let floatAndLengthO = parseNumber.parseFloat(numString)
    if floatAndLengthO.isSome:
      result = newFunResult(newValue(floatAndLengthO.get().number))
    else:
      # Expected number string.
      result = newFunResultWarn(wExpectedNumberString)
  else:
    # Int number string to int.
    let intAndLengthO = parseInteger(numString)
    if intAndLengthO.isSome:
      result = newFunResult(newValue(intAndLengthO.get().number))
    else:
      # Expected number string.
      result = newFunResultWarn(wExpectedNumberString)

func funCmp_iii*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Compare two ints. Returns -1 for less, 0 for equal and 1 for
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

func funCmp_ffi*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Compare two floats. Returns -1 for less, 0 for
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

func funCmp_bbi*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Compare two bools. Returns -1 for less, 0 for equal and 1 for
  ## @: greater than with true > false.
  ## @:
  ## @:~~~
  ## @:cmp(a: bool, b: bool) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:cmp(true, true) => 0
  ## @:cmp(false, false) => 0
  ## @:cmp(true, false) => 1
  ## @:cmp(false, true) => -1
  ## @:~~~~

  tMapParameters("bbi")
  let a = map["a"].boolv
  let b = map["b"].boolv
  result = newFunResult(newValue(cmp(a, b)))

func funCmp_ssobi*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Compare two strings. Returns -1 for less, 0 for equal and 1 for
  ## @:greater than.
  ## @:
  ## @:You have the option to compare case insensitive. Case sensitive
  ## @:is the default.
  ## @:
  ## @:~~~
  ## @:cmp(a: string, b: string, optional insensitive: bool) int
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

  tMapParameters("ssobi")
  let a = map["a"].stringv
  let b = map["b"].stringv

  # Get the optional case insensitive.
  var insensitive = false
  if "c" in map:
    insensitive = map["c"].boolv

  let ret = cmpString(a, b, insensitive)
  result = newFunResult(newValue(ret))

func funcConcat_sss*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Concatentate two strings. See join for more that two arguments.
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

  tMapParameters("sss")
  var a = map["a"].stringv
  let b = map["b"].stringv
  result = newFunResult(newValue(a & b))

func funLen_si*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("si")
  let str = map["a"].stringv
  result = newFunResult(newValue(stringLen(str)))

func funLen_li*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("li")
  let list = map["a"].listv
  result = newFunResult(newValue(list.len))

func funLen_di*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("di")
  let dict = map["a"].dictv
  result = newFunResult(newValue(dict.len))

func funGet_lioaa*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Get a list value by its index.  If the index is invalid, the
  ## @:default value is returned when specified, else a warning is
  ## @:generated. You can use negative index values. Index -1 gets the
  ## @:last element. It is short hand for len - 1. Index -2 is len - 2,
  ## @:etc.
  ## @:
  ## @:~~~
  ## @:get(list: list, index: int, optional default: any) any
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

  tMapParameters("lioaa")
  let list = map["a"].listv
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

func funGet_dsoaa*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Get a dictionary value by its key.  If the key doesn't exist, the
  ## @:default value is returned if specified, else a warning is
  ## @:generated.
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
  ## @:get(d, "tea") => "Earl Grey"
  ## @:get(d, "coffee", "Tea") => "Tea"
  ## @:~~~~
  ## @:
  ## @:Using dot notation:
  ## @:~~~
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
    # The dictionary does not have an item with key $1.
    result = newFunResultWarn(wMissingDictItem, 1, key)

func funIf0_iaoaa*(variables: Variables, parameters: seq[Value]): FunResult =
  ## If the condition is 0, return the second parameter, else return
  ## the third parameter. Return 0 for the else case when there is no
  ## third parameter. You can use any type for the condition, strings,
  ## lists and dictionaries use their length.
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
  ## @:[[#if-functions][If Functions]]
  ## @:
  ## @:~~~
  ## @:if0(condition: any, then: any, optional else: any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:if0(0, "tea", "beer") => tea
  ## @:if0(1, "tea", "beer") => beer
  ## @:if0(4, "tea", "beer") => beer
  ## @:if0("", "tea", "beer") => tea
  ## @:if0("abc", "tea", "beer") => beer
  ## @:if0([], "tea", "beer") => tea
  ## @:if0([1,2], "tea", "beer") => beer
  ## @:if0(dict(), "tea", "beer") => tea
  ## @:if0(dict("a",1), "tea", "beer") => beer
  ## @:if0(false, "tea", "beer") => tea
  ## @:if0(true, "tea", "beer") => beer
  ## @:~~~~
  ## @:
  ## @:No third parameter examples:
  ## @:
  ## @:~~~
  ## @:if0(0, "tea") => tea
  ## @:if0(4, "tea") => 0
  ## @:~~~~
  ## @:
  ## @:You don't have to assign the result of an if0 function which is
  ## @:useful when using a warn or return function for its side effects.
  ## @:
  ## @:~~~
  ## @:c = 0
  ## @:if0(c, warn("got zero value"))
  ## @:~~~~

  # Note: the if functions are handled in runCommand as a special
  # case. This code is not run. It is here for the function list and
  # documentation.

  tMapParameters("iaoaa")
  let condition = map["a"].intv
  let thenCase = map["b"]

  if condition == 0:
    result = newFunResult(thenCase)
  elif "c" in map:
    result = newFunResult(map["c"])
  else:
    result = newFunResult(newValue(0))

{.push overflowChecks: on, floatChecks: on.}

func funIf_baoaa*(variables: Variables, parameters: seq[Value]): FunResult =
  ## If the condition is true, return the second parameter, else return
  ## the third parameter. Return 0 for the else case when there is no
  ## third parameter.
  ## @:
  ## @:The if functions are special in a couple of ways, see
  ## @:[[#if-functions][If Functions]]
  ## @:
  ## @:~~~
  ## @:if(condition: bool, then: any, optional else: any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:if(true, "tea", "beer") => tea
  ## @:if(false, "tea", "beer") => beer
  ## @:~~~~
  ## @:
  ## @:No third parameter examples:
  ## @:
  ## @:~~~
  ## @:if(true, "tea") => tea
  ## @:if(false, "tea") => 0
  ## @:~~~~
  ## @:
  ## @:You don't have to assign the result of an if function which is
  ## @:useful when using a warn or return function for its side effects.
  ## @:
  ## @:~~~
  ## @:c = true
  ## @:if(c, warn("c is true"))
  ## @:~~~~

  # Note: the if functions are handled in runCommand as a special
  # case. This code is not run. It is here for the function list and
  # documentation.

  tMapParameters("baoaa")
  let condition = map["a"].boolv
  let thenCase = map["b"]

  if condition:
    result = newFunResult(thenCase)
  elif "c" in map:
    result = newFunResult(map["c"])
  else:
    result = newFunResult(newValue(0))

{.push overflowChecks: on, floatChecks: on.}

func funAdd_iii*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Add two integers. A warning is generated on overflow.
  ## @:
  ## @:~~~
  ## @:add(a: int, b: int)) int
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:add(1, 2) => 3
  ## @:add(3, -2) => 1
  ## @:add(-2, -5) => -7
  ## @:~~~~

  tMapParameters("iii")
  let a = map["a"].intv
  let b = map["b"].intv
  try:
    result = newFunResult(newValue(a + b))
  except:
    result = newFunResultWarn(wOverflow)

func funAdd_fff*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("fff")
  let a = map["a"].floatv
  let b = map["b"].floatv
  try:
    result = newFunResult(newValue(a + b))
  except:
    # Overflow or underflow.
    result = newFunResultWarn(wOverflow)

{.pop.}

func funExists_dsb*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("dsb")
  let dictionary = map["a"].dictv
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

  let caseList = cases.listv
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

func funCase_iloaa*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Compare integer cases and return the matching value.  It takes a
  ## @:main integer condition, a list of case pairs and an optional
  ## @:value when none of the cases match.
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
  ## @:case(condition: int, pairs: list, optional default: any) any
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

  tMapParameters("iloaa")
  result = getCase(map)

func funCase_sloaa*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Compare string cases and return the matching value.  It takes a
  ## @:main string condition, a list of case pairs and an optional
  ## @:value when none of the cases match.
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
  ## @:case(condition: string, pairs: list, optional default: any) any
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

  tMapParameters("sloaa")
  result = getCase(map)

func parseVersion*(version: string): Option[(int, int, int)] =
  ## Parse a StaticTea version number and return its three components.
  let matchesO = matchVersionNotCached(version, 0)
  if not matchesO.isSome:
    return
  let (g1, g2, g3) = matchesO.get3Groups()
  var g1IntAndLengthO = parseInteger(g1)
  var g2IntAndLengthO = parseInteger(g2)
  var g3IntAndLengthO = parseInteger(g3)
  result = some((int(g1IntAndLengthO.get().number), int(g2IntAndLengthO.get().number), int(g3IntAndLengthO.get().number)))

func funCmpVersion_ssi*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Compare two StaticTea version numbers. Returns -1 for less, 0 for
  ## @:equal and 1 for greater than.
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

  tMapParameters("ssi")

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

func funFloat_if*(variables: Variables, parameters: seq[Value]): FunResult =
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
  tMapParameters("if")
  let num = map["a"].intv
  result = newFunResult(newValue(float(num)))

func funFloat_sf*(variables: Variables, parameters: seq[Value]): FunResult =
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
  tMapParameters("sf")
  let numString = map["a"].stringv

  let funResult = numberStringToNum(numString)
  if funResult.kind == frWarning:
    return funResult

  if funResult.value.kind == vkFloat:
    result = funResult
  else:
    result = newFunResult(newValue(float(funResult.value.intv)))

func funFloat_saa*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Create a float from a number string. If the string is not a
  ## number, return the default.
  ## @:
  ## @:~~~
  ## @:float(numString: string, default: any) any
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:float("2") => 2.0
  ## @:float("notnum", "nan") => nan
  ## @:~~~~
  tMapParameters("saa")
  let numString = map["a"].stringv

  result = numberStringToNum(numString)
  if result.kind == frWarning and result.warningData.warning == wExpectedNumberString:
    # Return the default.
    return newFunResult(map["b"])

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

func funInt_fosi*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Create an int from a float.
  ## @:
  ## @:~~~
  ## @:int(num: float, optional roundOption: string) int
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

  tMapParameters("fosi")
  let num = map["a"].floatv

  result = convertFloatToInt(num, map)

func funInt_sosi*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Create an int from a number string.
  ## @:
  ## @:~~~
  ## @:int(numString: string, optional roundOption: string) int
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

  tMapParameters("sosi")
  let numString = map["a"].stringv

  let funResult = numberStringToNum(numString)
  if funResult.kind == frWarning:
    return funResult

  if funResult.value.kind == vkFloat:
    result = convertFloatToInt(funResult.value.floatv, map)
  else:
    result = funResult

func funInt_ssaa*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Create an int from a number string. If the string is not a number,
  ## return the default value.
  ## @:
  ## @:~~~
  ## @:int(numString: string, roundOption: string, default: any) any
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

  tMapParameters("ssaa")
  let numString = map["a"].stringv

  result = numberStringToNum(numString)
  if result.kind == frWarning and result.warningData.warning == wExpectedNumberString:
    # Return the default.
    return newFunResult(map["c"])

  if result.value.kind == vkFloat:
    result = convertFloatToInt(result.value.floatv, map)

func funBool_ib*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Create an bool from an int. A 0 is false and all other values are true.
  ## @:
  ## @:~~~
  ## @:bool(num: int) bool
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:bool(0) => false
  ## @:bool(1) => true
  ## @:bool(2) => true
  ## @:bool(3) => true
  ## @:bool(-1) => true
  ## @:~~~~

  tMapParameters("ib")
  let num = map["a"].intv
  let b = if num == 0: false else: true
  result = newFunResult(newValue(b))

func funFind_ssoaa*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Find the position of a substring in a string.  When the substring
  ## @:is not found, return an optional default value.  A warning is
  ## @:generated when the substring is missing and you don't specify a
  ## @:default value.
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
      # The substring was not found and no default argument.
      result = newFunResultWarn(wSubstringNotFound, 1)
  else:
    result = newFunResult(newValue(pos))

func funSlice_siois*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Extract a substring from a string by its position and length. You
  ## @:pass the string, the substring's start index and its length.  The
  ## @:length is optional. When not specified, the slice returns the
  ## @:characters from the start to the end of the string.
  ## @:
  ## @:The start index and length are by unicode characters not bytes.
  ## @:
  ## @:~~~
  ## @:slice(str: string, start: int, optional length: int) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:slice("Earl Grey", 1, 3) => "arl"
  ## @:slice("Earl Grey", 6) => "rey"
  ## @:slice("añyóng", 0, 3) => "añy"
  ## @:~~~~

  tMapParameters("siois")

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

func funDup_sis*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Duplicate a string x times.  The result is a new string built by
  ## @:concatenating the string to itself the specified number of times.
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

  tMapParameters("sis")

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

func funDict_old*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Create a dictionary from a list of key, value pairs.  The keys
  ## @:must be strings and the values can be any type.
  ## @:
  ## @:~~~
  ## @:dict(pairs: optional list) dict
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:dict() => {}
  ## @:dict(list("a", 5)) => {"a": 5}
  ## @:dict(list("a", 5, "b", 33, "c", 0)) =>
  ## @:  {"a": 5, "b": 33, "c": 0}
  ## @:~~~~

  tMapParameters("old")

  var dict = newVarsDict()

  if "a" in map:
    let pairs = map["a"].listv
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

  result = newFunResult(newValue(dict))

func funList*(variables: Variables, parameters: seq[Value]): FunResult =
  ## You create a list with the list function or with brackets.
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

  result = newFunResult(newValue(parameters))

func funReplace_siiss*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Replace a substring specified by its position and length with
  ## another string.  You can use the function to insert and append to
  ## @:a string as well.
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


  tMapParameters("siiss")

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
  let list = map["b"].listv

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

func funReplaceRe_sls*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("sls")
  let list = map["b"].listv
  if list.len mod 2 != 0:
    # Specify arguments in pairs.
    return newFunResultWarn(wPairParameters, 1)
  for ix, value in list:
    if value.kind != vkString:
      # The argument must be a string.
      return newFunResultWarn(wExpectedString, ix)

  replaceReMap(map)

func funPath_sosd*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Split a file path into its component pieces. Return a dictionary
  ## @:with the filename, basename, extension and directory.
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
      # Expected / or \\.
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

func funLower_ss*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("ss")
  let str = map["a"].stringv
  result = newFunResult(newValue(toLower(str)))

func funKeys_dl*(variables: Variables, parameters: seq[Value]): FunResult =
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

  var list: seq[string]
  for key, value in dict.pairs():
    list.add(key)

  result = newFunResult(newValue(list))

func funValues_dl*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("dl")
  let dict = map["a"].dictv

  var list: seq[Value]
  for key, value in dict.pairs():
    list.add(value)

  result = newFunResult(newValue(list))

func generalSort(map: VarsDict): FunResult =
  ## Sort a list of values of the same type.

  let list = map["a"].listv

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
    if not (key in firstItem.dictv):
      # A dictionary is missing the sort key.
      return newFunResultWarn(wDictKeyMissing, 0)
    firstKeyValueKind = firstItem.dictv[key].kind
  elif listKind == vkList:
    if firstItem.listv.len == 0:
      # A sublist is empty.
      return newFunResultWarn(wSubListsEmpty, 0)
    firstListValueKind = firstItem.listv[0].kind

  # Verify the all the values are the same type.
  for value in list:
    if value.kind != listKind:
      # The two arguments are not the same type.
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
    of vkBool:
      # Sort as if true is 1 and false is 0.
      if a == b:
        result = 0
      elif a.boolv == true:
        result = 1
      else:
        result = -1
    of vkFunc:
      result = 0

  let newList = sorted(list, sortCmpValues, sortOrder)
  result = newFunResult(newValue(newList))

func funSort_lsosl*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Sort a list of values of the same type.  The values are ints,
  ## @:floats, strings or bools. Bools are sorted as if true is 1 and
  ## @:false is 0.
  ## @:
  ## @:You specify the sort order, "ascending" or "descending".
  ## @:
  ## @:You have the option of sorting strings case "insensitive". Case
  ## @:"sensitive" is the default.
  ## @:
  ## @:~~~
  ## @:sort(values: list, order: string, optional insensitive: string) list
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

  tMapParameters("lsosl")
  result = generalSort(map)

func funSort_lssil*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Sort a list of lists.
  ## @:
  ## @:You specify the sort order, "ascending" or "descending".
  ## @:
  ## @:You specify how to sort strings either case "sensitive" or
  ## @:"insensitive".
  ## @:
  ## @:You specify which index to compare by.  The compare index value
  ## @:must exist in each list, be the same type and be an int, float,
  ## @:string or bool. Bools are sorts as if true is 1 and false is 0.
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

  tMapParameters("lssil")
  result = generalSort(map)

func funSort_lsssl*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Sort a list of dictionaries.
  ## @:
  ## @:You specify the sort order, "ascending" or "descending".
  ## @:
  ## @:You specify how to sort strings either case "sensitive" or
  ## @:"insensitive".
  ## @:
  ## @:You specify the compare key.  The key value must exist in
  ## @:each dictionary, be the same type and be an int, float, bool or
  ## @:string. Bools are sorts as if true is 1 and false is 0.
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

  tMapParameters("lsssl")
  result = generalSort(map)

func funGithubAnchor_ss*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Create a Github anchor name from a heading name. Use it for
  ## @:Github markdown internal links. If you have duplicate heading
  ## @:names, the anchor name returned only works for the
  ## @:first. Punctuation characters are removed so you can get
  ## @:duplicates in some cases.
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
  ## @:* {type}@{{entry.name}](#{anchor}) &mdash; {short}
  ## @:...
  ## @:# {entry.name}
  ## @:~~~~

  tMapParameters("ss")

  let name = map["a"].stringv
  let anchorName = githubAnchor(name)
  result = newFunResult(newValue(anchorName))

func funGithubAnchor_ll*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Create Github anchor names from heading names. Use it for Github
  ## @:markdown internal links. It handles duplicate heading names.
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

  tMapParameters("ll")

  let list = map["a"].listv

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

func funType_as*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return the parameter type, one of: int, float, string, list,
  ## dict or bool.
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
  ## @:~~~~

  tMapParameters("as")
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
  for value in map["a"].listv:
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

func funJoinPath_loss*(variables: Variables, parameters: seq[Value]): FunResult =
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
  ## @:joinPath(components: list, optional separator: string) string
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

  tMapParameters("loss")
  result = joinPathList(map)

func funJoin_lsois*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Join a list of strings with a separator.  An optional parameter
  ## determines whether you skip empty strings or not. You can use an
  ## empty separator to concatenate the arguments.
  ## @:
  ## @:~~~
  ## @:join(strs: list, sep: string, optional skipEmpty: int) string
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
  ## @:join(["a", "", "c"], "|", 1) => "a|c"
  ## @:~~~~

  tMapParameters("lsois")

  let listv = map["a"].listv
  let sep = map["b"].stringv
  var skipEmpty = false
  if "c" in map and map["c"].intv == 1:
    skipEmpty = true
  var ret: string
  if listv.len == 0:
    return newFunResult(newValue(""))
  if listv.len > 0:
    ret.add(listv[0].stringv)
  for value in listv[1 .. listv.len - 1]:
    if value.kind != vkString:
      # The join list items must be strings.
      return newFunResultWarn(wJoinListString, 0)
    let str = value.stringv
    if skipEmpty and str.len == 0:
      continue
    ret.add(sep)
    ret.add(str)
  result = newFunResult(newValue(ret))

func funWarn_ss*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return a warning message and skip the current statement.
  ## @:
  ## @:~~~
  ## @:warn(message: string) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:if0(c, warn("message is 0"))
  ## @:b = if0(c, warn("c is not 0"), "")
  ## @:~~~~

  tMapParameters("ss")

  let message = map["a"].stringv
  result = newFunResultWarn(wUserMessage, 0, message)

func funReturn_ss*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return the given value and control command looping. A return in a
  ## @:statement causes the command to stop processing the current
  ## @:statement and following statements in the command. You can
  ## @:control whether the replacement block is output or not.
  ## @:
  ## @:* "stop" -- stop processing the command
  ## @:* "skip" -- skip this replacement block and continue with the next
  ## @:* "" -- output the replacement block and continue
  ## @:
  ## @:~~~
  ## @:return(value: string) string
  ## @:~~~~
  ## @:
  ## @:Examples:
  ## @:
  ## @:~~~
  ## @:if0(c, return("stop"))
  ## @:if0(c, return("skip"))
  ## @:if0(c, return(""))
  ## @:~~~~

  tMapParameters("ss")
  result = newFunResult(map["a"])

func funString_aoss*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Convert the variable to a string.
  ## @:
  ## @:~~~
  ## @:string(var: any, optional stype: string) string
  ## @:~~~~
  ## @:
  ## @:The default stype is "rb". This type is used in replacement blocks.
  ## @:
  ## @:stypes:
  ## @:* json -- returns JSON
  ## @:* rb -- returns JSON except strings are not quoted (replacement block)
  ## @:* dn -- Dot name format where leaf elements are JSON (dot names)
  ## @:
  ## @:Examples:
  ## @:
  ## @:json type:
  ## @:~~~
  ## @:string(5, "json") => "5"
  ## @:string("str", "json") => "str"
  ## @:
  ## @:a = [1, 2, 3]
  ## @:d = ["a", 1, "b", 2, "c", 3]
  ## @:string(a, "json") => [1,2,3]
  ## @:string(d, "json") => {"a":1,"b":2,"c":3}
  ## @:~~~~
  ## @:
  ## @:rb:
  ## @:~~~
  ## @:string("str", "rb") => str
  ## @:string("str") => str
  ## @:~~~~
  ## @:
  ## @:dot-names:
  ## @:~~~
  ## @:string(d, "dn") =>
  ## @:a = 1
  ## @:b = 2
  ## @:c = 3
  ## @:~~~~

  tMapParameters("aoss")
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
      str = dotNameRep(value.dictv)
    else:
      str = valueToString(value)
  else:
    # Invalid string type, expected rb, json or dot-names.
    return newFunResultWarn(wInvalidStringType, 1)

  result = newFunResult(newValue(str))

func funString_sds*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Convert the dictionary variable to dot names.
  ## @:
  ## @:~~~
  ## @:string(dictName: string: d: dict) string
  ## @:~~~~
  ## @:
  ## @:Example:
  ## @:
  ## @:~~~
  ## @:d = {"x",1,"y":"tea","z":{"a":8}}
  ## @:string("teas", d) =>
  ## @:
  ## @:teas.x = 1
  ## @:teas.y = "tea"
  ## @:teas.z.a = 8
  ## @:~~~~

  tMapParameters("sds")
  let name = map["a"].stringv
  let dict = map["b"].dictv
  let str = dotNameRep(dict, name)
  result = newFunResult(newValue(str))

func funFormat_ss*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("ss")
  let str = map["a"].stringv
  let stringOr = formatString(variables, str)
  if stringOr.isMessage:
    return newFunResultWarn(stringOr.message)

  result = newFunResult(newValue(stringOr.value))

func funStartsWith_ssb*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("ssb")
  let str = map["a"].stringv
  let prefix = map["b"].stringv
  result = newFunResult(newValue(startsWith(str, prefix)))

func funNot_bb*(variables: Variables, parameters: seq[Value]): FunResult =
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

  tMapParameters("bb")
  let cond = map["a"].boolv
  result = newFunResult(newValue(not(cond)))

func funAnd_bbb*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Boolean and with short circuit. If the first argument is false,
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
  tMapParameters("bbb")
  let a = map["a"].boolv
  let b = map["b"].boolv
  let cond = a and b
  result = newFunResult(newValue(cond))

func funOr_bbb*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Boolean or with short circuit. If the first argument is true,
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
  tMapParameters("bbb")
  let a = map["a"].boolv
  let b = map["b"].boolv
  let cond = a or b
  result = newFunResult(newValue(cond))

func funEq_iib*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a equals b.
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
  tMapParameters("iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a == b
  result = newFunResult(newValue(cond))

func funEq_ffb*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a equals b.
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
  tMapParameters("ffb")
  let a = map["a"].floatv
  let b = map["b"].floatv
  let cond = a == b
  result = newFunResult(newValue(cond))

func funEq_ssb*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a equals b.
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
  tMapParameters("ssb")
  let a = map["a"].stringv
  let b = map["b"].stringv
  let cond = a == b
  result = newFunResult(newValue(cond))

func funNe_iib*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a does not equal b.
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
  tMapParameters("iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a != b
  result = newFunResult(newValue(cond))

func funNe_ffb*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a does not equal b.
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
  tMapParameters("ffb")
  let a = map["a"].floatv
  let b = map["b"].floatv
  let cond = a != b
  result = newFunResult(newValue(cond))

func funNe_ssb*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a does not equal b.
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
  tMapParameters("ssb")
  let a = map["a"].stringv
  let b = map["b"].stringv
  let cond = a != b
  result = newFunResult(newValue(cond))

func funGt_iib*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a is greater than b.
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
  tMapParameters("iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a > b
  result = newFunResult(newValue(cond))

func funGt_ffb*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a is greater than b.
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
  tMapParameters("ffb")
  let a = map["a"].floatv
  let b = map["b"].floatv
  let cond = a > b
  result = newFunResult(newValue(cond))

func funGte_iib*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a is greater than or equal to b.
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
  tMapParameters("iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a >= b
  result = newFunResult(newValue(cond))

func funGte_ffb*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a is greater than to equal to b.
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
  tMapParameters("ffb")
  let a = map["a"].stringv
  let b = map["b"].stringv
  let cond = a >= b
  result = newFunResult(newValue(cond))

func funLt_iib*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a is less than b.
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
  tMapParameters("iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a < b
  result = newFunResult(newValue(cond))

func funLt_ffb*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a is less than b.
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
  tMapParameters("ffb")
  let a = map["a"].floatv
  let b = map["b"].floatv
  let cond = a > b
  result = newFunResult(newValue(cond))

func funLte_iib*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a is less than or equal to b.
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
  tMapParameters("iib")
  let a = map["a"].intv
  let b = map["b"].intv
  let cond = a <= b
  result = newFunResult(newValue(cond))

func funLte_ffb*(variables: Variables, parameters: seq[Value]): FunResult =
  ## Return true when the a is less than or equal to b.
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
  tMapParameters("ffb")
  let a = map["a"].floatv
  let b = map["b"].floatv
  let cond = a <= b
  result = newFunResult(newValue(cond))

const
  # Sorted list of built in functions.
  functionsList* = [
    ("add", funAdd_fff, "fff"),
    ("add", funAdd_iii, "iii"),
    ("and", funAnd_bbb, "bbb"),
    ("bool", funBool_ib, "ib"),
    ("case", funCase_iloaa, "iloaa"),
    ("case", funCase_sloaa, "sloaa"),
    ("cmp", funCmp_bbi, "bbi"),
    ("cmp", funCmp_ffi, "ffi"),
    ("cmp", funCmp_iii, "iii"),
    ("cmp", funCmp_ssobi, "ssobi"),
    ("cmpVersion", funCmpVersion_ssi, "ssi"),
    ("concat", funcConcat_sss, "sss"),
    ("dict", funDict_old, "old"),
    ("dup", funDup_sis, "sis"),
    ("eq", funEq_ffb, "ffb"),
    ("eq", funEq_iib, "iib"),
    ("eq", funEq_ssb, "ssb"),
    ("exists", funExists_dsb, "dsb"),
    ("find", funFind_ssoaa, "ssoaa"),
    ("float", funFloat_if, "if"),
    ("float", funFloat_saa, "saa"),
    ("float", funFloat_sf, "sf"),
    ("format", funFormat_ss, "ss"),
    ("get", funGet_dsoaa, "dsoaa"),
    ("get", funGet_lioaa, "lioaa"),
    ("githubAnchor", funGithubAnchor_ll, "ll"),
    ("githubAnchor", funGithubAnchor_ss, "ss"),
    ("gt", funGt_ffb, "ffb"),
    ("gt", funGt_iib, "iib"),
    ("gte", funGte_ffb, "ffb"),
    ("gte", funGte_iib, "iib"),
    ("if", funIf_baoaa, "baoaa"),
    ("if0", funIf0_iaoaa, "iaoaa"),
    ("int", funInt_fosi, "fosi"),
    ("int", funInt_sosi, "sosi"),
    ("int", funInt_ssaa, "ssaa"),
    ("join", funJoin_lsois, "lsois"),
    ("joinPath", funJoinPath_loss, "loss"),
    ("keys", funKeys_dl, "dl"),
    ("len", funLen_di, "di"),
    ("len", funLen_li, "li"),
    ("len", funLen_si, "si"),
    ("list", funList, "..."),
    ("lower", funLower_ss, "ss"),
    ("lt", funLt_ffb, "ffb"),
    ("lt", funLt_iib, "iib"),
    ("lte", funLte_ffb, "ffb"),
    ("lte", funLte_iib, "iib"),
    ("ne", funNe_ffb, "ffb"),
    ("ne", funNe_iib, "iib"),
    ("ne", funNe_ssb, "ssb"),
    ("not", funNot_bb, "bb"),
    ("or", funOr_bbb, "bbb"),
    ("path", funPath_sosd, "sosd"),
    ("replace", funReplace_siiss, "siiss"),
    ("replaceRe", funReplaceRe_sls, "sls"),
    ("return", funReturn_ss, "ss"),
    ("slice", funSlice_siois, "siois"),
    ("sort", funSort_lsosl, "lsosl"),
    ("sort", funSort_lssil, "lssil"),
    ("sort", funSort_lsssl, "lsssl"),
    ("startsWith", funStartsWith_ssb, "ssb"),
    ("string", funString_aoss, "aoss"),
    ("string", funString_sds, "sds"),
    ("type", funType_as, "as"),
    ("values", funValues_dl, "dl"),
    ("warn", funWarn_ss, "ss"),
  ]

proc getBestFunction*(funcValue: Value, arguments: seq[Value]): ValueOr =
  ## Given a function variable or a list of function variables and a
  ## list of arguments, return the one that best matches the
  ## arguments.  If none of the signatures match, return the one that
  ## matched the most parameters going left to right.

  if funcValue.kind == vkFunc:
    return newValueOr(funcValue)

  if funcValue.kind != vkList:
    # You cannot call the variable because it's not a function or a list of functions.
    let warningData = newWarningData(wNotFunction)
    return newValueOr(warningData)
  let funcList = funcValue.listv

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

      let paramsO = signatureCodeToParams(funcValue.funcv.signatureCode)
      let funResult = mapParameters(paramsO.get(), arguments)
      if funResult.kind != frWarning:
        # All arguments match the parameters, return the function.
        return newValueOr(funcValue)
      if funResult.parameter > maxDistance:
        maxDistance = funResult.parameter
        maxFuncValue = funcValue
    # Return the function that made if farthest through its
    # parameters.
    result = newValueOr(maxFuncValue)

proc createFuncDictionary*(): Value =
  ## Create the f dictionary from the built in functions.

  # An f dictionary item's key is the name of a function. Its value is a list
  # of func values with that name.

  assert(functionsList.len > 0)
  var varsDict = newVarsDict()

  # The functionsList is sorted by name then signature code.

  var funcList = newEmptyListValue()
  var lastName = ""
  for (name, functionPtr, signatureCode) in functionsList:
    let function = newFunc(name, functionPtr, signatureCode)
    let funcValue = newValue(function)
    if name == lastName:
      funcList.listv.add(funcValue)
    else:
      if lastName != "":
        varsDict[lastName] = funcList
      funcList = newEmptyListValue()
      funcList.listv.add(funcValue)
      lastName = name

  if funcList.listv.len > 0:
    varsDict[lastName] = funcList

  result = newValue(varsDict)
