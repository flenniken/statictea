import tables
import vartypes

type
  MapDictKind* = enum
    pkContinue,
    pkBreak,
    pkKeyValue

  MapDict* = object
    case kind*: MapDictKind
    of pkKeyValue:
      key*: string
      value*: Value
    of pkContinue:
      discard
    of pkBreak:
      discard

  MapDictCallback* = proc (ix: int, value: Value, state: VarsDict): MapDict
    ## Procedure called by list2Dict for each item in the list.
    ##



proc newMapDictKeyValue(key: string, value: Value): MapDict =
  result = MapDict(kind: pkKeyValue, key: key, value: value)

proc newMapDictContinue(): MapDict =
  result = MapDict(kind: pkContinue)

proc newMapDictBreak(): MapDict =
  result = MapDict(kind: pkBreak)

# callback = fun(ix, value, state)
# ret = case(cmp(value, 4), 1, value, "continue")

proc valuesOver4(ix: int, value: Value, state: VarsDict): MapDict =
  ## Return the value when it is greater than 4.
  if value.kind == vkInt and value.intv > 4:
    result = newMapDictKeyValue($value.intv, value)
  else:
    result = newMapDictContinue()

# list2Dict
# dict2Dict
# list2List
# dict2List

proc list2Dict(list: seq[Value], mapDictCallback: MapDictCallback,
    state: VarsDict = newVarsDict()): VarsDict =
  ## Loop through a list to produce a dictionary.
  var newDict = newVarsDict()
  for ix, value in list:
    var mapDict = mapDictCallback(ix, value, state)
    case mapDict.kind:
      of pkContinue:
        continue
      of pkBreak:
        break
      of pkKeyValue:
        newDict[mapDict.key] = mapDict.value
  result = newDict

when isMainModule:
  var state: VarsDict
  var list = @[
    newValue(1),
    newValue(3),
    newValue(5),
    newValue(7),
    newValue(9)
  ]
  var newDict = list2Dict(list, valuesOver4, state)
  echo $newDict
