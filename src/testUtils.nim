import streams
import strutils
import options

when defined(test):

  proc theLines*(stream: Stream): seq[string] =
    ## Read all the lines in the stream.
    stream.setPosition(0)
    for line in stream.lines():
      result.add line

  proc theLines*(filename: string): seq[string] =
    ## Read all the lines in the file.
    for line in lines(filename):
      result.add line

  proc createFile*(filename: string, content: string) =
    var file = open(filename, fmWrite)
    file.write(content)
    file.close()

  template notReturn*(boolProc: untyped) =
    if not boolProc:
      return false

  proc expectedItem*[T](name: string, item: T, expectedItem: T): bool =
    ## Compare the item with the expected item and show them when
    ## different. Return true when they are the same.

    if item == expectedItem:
      result = true
    else:
      echo "$1" % name
      echo "     got: $1" % $item
      echo "expected: $1" % $expectedItem
      result = false


  proc expectedItems*[T](name: string, items: seq[T], expectedItems: seq[T]): bool =
    ## Compare the items with the expected items and show them when
    ## different. Return true when they are the same.

    if items == expectedItems:
      result = true
    else:
      if items.len != expectedItems.len:
        echo "~~~~~~~~~~ $1 ~~~~~~~~~~~:" % name
        for item in items:
          echo $item
        echo "~~~~~~ expected $1 ~~~~~~:" % name
        for item in expectedItems:
          echo $item
      else:
        echo "~~~~~~~~~~ $1 ~~~~~~~~~~~:" % name
        for ix in 0 ..< items.len:
          if items[ix] == expectedItems[ix]:
            echo "$1: same" % [$ix]
          else:
            echo "$1:      got: $2" % [$ix, $items[ix]]
            echo "$1: expected: $2" % [$ix, $expectedItems[ix]]
      result = false

  proc startPointer*(start: Natural): string =
    ## Return the number of spaces and symbols to point at the line
    ## start value.
    if start > 100:
      result.add("$1" % $start)
    else:
      for ix in 0..<start:
        result.add(' ')
      result.add("^$1" % $start)

  proc testSome*[T](valueO: Option[T], eValueO: Option[T],
      statement: string, start: Natural): bool =

    if valueO == eValueO:
      return true

    echo "Did not get the expected value."
    echo "     got: $1" % $valueO
    echo "expected: $1" % $eValueO
    echo "statement: $1" % statement
    echo "    start: $1" % startPointer(start)
