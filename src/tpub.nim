## The tpub macro pragma makes private routines public for testing.
## This allows you to test private procedures in external test
## files. When the test option is off, the macros do nothing.

import std/macros

macro tpub*(x: untyped): untyped =
  ## Exports a procedure or function when in test mode so it can be
  ## @:tested in an external module.
  ## @:
  ## @:Here is an example that makes myProcToTest public in
  ## @:test mode:
  ## @:
  ## @:~~~
  ## @:proc myProcToTest(value:int): string {.tpub.} =
  ## @:~~~~
  expectKind(x, RoutineNodes)
  when defined(test):
    x.name = newTree(nnkPostfix, ident"*", name(x))
  result = x

macro tpubType*(x: untyped): untyped =
  ## Exports a type when in test mode so it can be tested in an
  ## @:external module.
  ## @:
  ## @:Here is an example that makes the type "SectionInfo" public in
  ## @:test mode:
  ## @:
  ## @:~~~
  ## @:import tpub
  ## @:tpubType:
  ## @:  type
  ## @:    SectionInfo = object
  ## @:      name*: string
  ## @:~~~~
  # echo "treeRepr = ", treeRepr(x)
  when defined(test):
    if x.kind == nnkStmtList:
      if x[0].kind == nnkTypeSection or x[0].kind == nnkConstSection:
        for n in x[0].children:
          if n.kind == nnkTypeDef or n.kind == nnkConstDef:
            if n[0].kind == nnkIdent:
              n[0] = newTree(nnkPostfix, ident"*", n[0])
  # echo "after:"
  # echo "treeRepr = ", treeRepr(x)
  result = x
