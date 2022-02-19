import std/unittest
import std/options
import std/strutils
import dot
import env

proc testParseDotLine(line: string, eDep: Option[Dependency]): bool =
  let depO = parseDotLine(line)
  result = true
  if not expectedItem("parseDotLine", depO, eDep):
    result = false

suite "dot.nim":
  test "newDependency":
    let dep = newDependency("leftvalue", "rightvalue")
    check dep.left == "leftvalue"
    check dep.right == "rightvalue"
    check $dep == """leftvalue -> "rightvalue";"""

  test "Dependency compare":
    let dep = newDependency("leftvalue", "rightvalue")
    let dep2 = newDependency("leftvalue", "rightvalue")
    let dep3 = newDependency("leftvalue", "rightvalue2")
    check dep == dep2
    check dep != dep3

  test "parseDotLine empty":
    check parseDotLine("").isNone()

  test "parseDotLine":
    check testParseDotLine(""""one" -> "two";""", some(newDependency("one", "two")))
    check testParseDotLine(""""o" -> "t";""", some(newDependency("o", "t")))

  test "parseDotLine no left":
    check testParseDotLine("""-> "two";""", none(Dependency))
    check testParseDotLine(""" -> "two";""", none(Dependency))
    check testParseDotLine("""  -> "two";""", none(Dependency))

  test "parseDotLine no right":
    check testParseDotLine("""one -> "";""", none(Dependency))
    check testParseDotLine("""one -> "two"""", none(Dependency))
    check testParseDotLine("""one ->"two";""", none(Dependency))
    check testParseDotLine("""one >"two";""", none(Dependency))
    check testParseDotLine("""one -"two";""", none(Dependency))
