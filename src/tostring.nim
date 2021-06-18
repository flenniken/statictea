import std/strutils
import std/tables
import std/json
import warnings
import vartypes

# Recursive prototype.
func valueToString*(value: Value): string

func dictToString*(value: Value): string =
  ## Return a string representation of a dict Value in JSON format.
  result.add("{")
  var insideLines: seq[string]
  for k, v in value.dictv.pairs:
    insideLines.add("$1:$2" % [escapeJson(k), valueToString(v)])
  result.add(insideLines.join(","))
  result.add("}")

func listToString*(value: Value): string =
  ## Return a string representation of a list Value in JSON format.
  result.add("[")
  var insideLines: seq[string]
  for item in value.listv:
    insideLines.add(valueToString(item))
  result.add(insideLines.join(","))
  result.add("]")

func valueToString*(value: Value): string =
  ## Return a string representation of a Value in JSON format.
  case value.kind:
    of vkDict:
      result.add(dictToString(value))
    of vkList:
      result.add(listToString(value))
    of vkString:
      result.add(escapeJson(value.stringv))
    of vkInt:
      result.add($value.intv)
    of vkFloat:
      result.add($value.floatv)

func `$`*(value: Value): string =
  ## Return a string representation of a Value.
  result = valueToString(value)

func shortValueToString*(value: Value): string =
  ## Return a string representation of Value. This is used to convert
  ## values to strings in replacement blocks.
  case value.kind
  of vkString:
    result = value.stringv
  of vkInt:
    result = $value.intv
  of vkFloat:
    result = $value.floatv
  of vkDict:
    if value.dictv.len == 0:
      result = "{}"
    else:
      result = "{...}"
  of vkList:
    if value.listv.len == 0:
      result = "[]"
    else:
      result = "[...]"

proc `$`*(varsDict: VarsDict): string =
  ## Return a string representation of a VarsDict.
  result = valueToString(newValue(varsDict))

func `$`*(vw: ValueOrWarning): string =
  ## Return a string representation of a ValueOrWarning object.
  if vw.kind == vwValue:
    result = $vw.value
  else:
    result = $vw.warningData
