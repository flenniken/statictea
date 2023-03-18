stf file, version 0.1.0

# Built-in Functions

Show built-in functions.

### File cmd.sh command

~~~
$statictea \
  -o shared.tea \
  -t tmpl.txt \
  -r result \
  >stdout 2>stderr
~~~


### File tmpl.txt

~~~
$$ block t.repeat = len(o.signatures)
$$ : signature = o.signatures[t.row]
{signature}
$$ endblock
~~~

### File shared.tea

Make a list of the functions and their signatures.

~~~
addFuncVar = func(ix: int, funcVar: func, funcList: list) bool
  ## Add the function variable to the function list.
  funcList &= funcVar
  return(false)

addAllVars = func(ix: int, key: string, funcList: list, addFuncVar: func) bool
  ## Add all the func variables to the function list.
  listLoop(f[key], funcList, addFuncVar)
  return(false)

# Create a list of all the f dictionary function variables.
funcList = []
listLoop(keys(f), funcList, addAllVars, addFuncVar)

make-param = func(ix: int, name: string, params: list, signature: dict) bool
  ## Add the function name and type to the params list.
  type = signature.paramTypes[ix]
  entry = format("{name}: {type}")
  params &= entry
  return(false)

signature-string = func(signature: dict, make-param: func) string
  ## Return a signature string given a signature dictionary.
  params = []
  listLoop(signature.paramNames, params, make-param, signature)
  paramStr = join(params, ", ")
  return(format("{signature.name}({paramStr}) {signature.returnType}"))

make-signature = func(ix: int, funcVar: func, newList: list, state: dict) bool
  ## Add the function variable's signature string to the new list.

  # Look up the function's details.
  fd = functionDetails(funcVar)

  signature = l.state.signature-string(fd.signature, state.make-param)
  newList &= signature
  return(false)

# Create a list of function signatures.
o.signatures = []
state = dict()
state.signature-string = signature-string
state.make-param = make-param
listLoop(funcList, o.signatures, make-signature, state)
~~~

### File result.expected

~~~
add(a: float, b: float) float
add(a: int, b: int) int
anchors(a: list, b: string) list
and(a: bool, b: bool) bool
bool(a: any) bool
case(a: int, b: list, c: any) any
case(a: string, b: list, c: any) any
cmp(a: float, b: float) int
cmp(a: int, b: int) int
cmp(a: string, b: string, c: bool) int
cmpVersion(a: string, b: string) int
concat(a: string, b: string) string
dict(a: list) dict
dup(a: string, b: int) string
eq(a: float, b: float) bool
eq(a: int, b: int) bool
eq(a: string, b: string) bool
exists(a: dict, b: string) bool
find(a: string, b: string, c: any) any
float(a: int) float
float(a: string, b: any) any
float(a: string) float
format(a: string) string
func(a: string) func
functionDetails(a: func) dict
get(a: dict, b: string, c: any) any
get(a: list, b: int, c: any) any
gt(a: float, b: float) bool
gt(a: int, b: int) bool
gte(a: float, b: float) bool
gte(a: int, b: int) bool
highlight(a: string) list
html(a: string, b: string) string
if0(a: int, b: any, c: any) any
if(a: bool, b: any, c: any) any
int(a: float, b: string) int
int(a: string, b: string) int
int(a: string, b: string, c: any) any
join(a: list, b: string, c: int) string
joinPath(a: list, b: string) string
keys(a: dict) list
len(a: dict) int
len(a: list) int
len(a: string) int
list(a: any) list
listLoop(a: list, b: any, c: func, d: any) bool
log(a: string) string
lower(a: string) string
lt(a: float, b: float) bool
lt(a: int, b: int) bool
lte(a: float, b: float) bool
lte(a: int, b: int) bool
markdownLite(a: string) list
ne(a: float, b: float) bool
ne(a: int, b: int) bool
ne(a: string, b: string) bool
not(a: bool) bool
or(a: bool, b: bool) bool
path(a: string, b: string) dict
readJson(a: string) any
replace(a: string, b: int, c: int, d: string) string
replaceRe(a: string, b: list) string
return(a: any) any
slice(a: string, b: int, c: int) string
sort(a: list, b: string, c: string) list
sort(a: list, b: string, c: string, d: int) list
sort(a: list, b: string, c: string, d: string) list
startsWith(a: string, b: string) bool
string(a: any, b: string) string
string(a: string, b: dict) string
sub(a: float, b: float) float
sub(a: int, b: int) int
type(a: any) string
values(a: dict) list
warn(a: string) string
~~~

### File stdout.expected

~~~
~~~

### File stderr.expected

~~~
~~~

### Expected result == result.expected
### Expected stdout == stdout.expected
### Expected stderr == stderr.expected
