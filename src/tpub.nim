## The tpub macro pragma makes private routines public for testing.
## This allows you to test private procedures in external test
## files. When the test option is off, the macros do nothing.

import macros

macro tpub*(x: untyped): untyped =
  ## Exports a procedure or function when in test mode so it can be
  ## tested in an external module.
  ## blank
  ## indent2 proc myProcToTest(value:int): string {.tpub.} =
  expectKind(x, RoutineNodes)
  when defined(test):
    x.name = newTree(nnkPostfix, ident"*", name(x))
  result = x

macro tpubType*(x: untyped): untyped =
  ## Exports a type when in test mode so it can be tested in an
  ## external module.
  ## blank
  ## Here is an example that makes the type "SectionInfo" public in
  ## test mode:
  ## blank
  ## indent2 import tpub
  ## indent2 tpubType:
  ## indent2   type
  ## indent2     SectionInfo = object
  ## indent2       name*: string
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
