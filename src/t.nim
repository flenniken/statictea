## Private module for experimenting.

type
  FunctionPtr* = proc (num: int): int {.noSideEffect.}

func add2(num: int): int =
  result = num + 2

proc add3(num: int): int =
  result = num + 3

let pa: FunctionPtr = add2
let pb: FunctionPtr = add3

echo $pa(1)
echo $pb(1)

