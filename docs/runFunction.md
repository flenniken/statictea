# runFunction.nim

{modDescription}

* [runFunction.nim](../src/runFunction.nim) &mdash; Nim source code.
# Index

* [cmpBaseValues](#cmpbasevalues) &mdash; {entry.short}
* [funCmp_iii](#funcmp_iii) &mdash; {entry.short}
* [funCmp_ffi](#funcmp_ffi) &mdash; {entry.short}
* [funCmp_ssoii](#funcmp_ssoii) &mdash; {entry.short}
* [funConcat](#funconcat) &mdash; {entry.short}
* [funLen_si](#funlen_si) &mdash; {entry.short}
* [funLen_li](#funlen_li) &mdash; {entry.short}
* [funLen_di](#funlen_di) &mdash; {entry.short}
* [funGet_lioaa](#funget_lioaa) &mdash; {entry.short}
* [funGet_dsoaa](#funget_dsoaa) &mdash; {entry.short}
* [funIf](#funif) &mdash; {entry.short}
* [funAdd_Ii](#funadd_ii) &mdash; {entry.short}
* [funAdd_Fi](#funadd_fi) &mdash; {entry.short}
* [funExists](#funexists) &mdash; {entry.short}
* [funCase_iloaa](#funcase_iloaa) &mdash; {entry.short}
* [funCase_sloaa](#funcase_sloaa) &mdash; {entry.short}
* [parseVersion](#parseversion) &mdash; {entry.short}
* [funCmpVersion](#funcmpversion) &mdash; {entry.short}
* [funFloat_if](#funfloat_if) &mdash; {entry.short}
* [funFloat_sf](#funfloat_sf) &mdash; {entry.short}
* [funInt_fosi](#funint_fosi) &mdash; {entry.short}
* [funInt_sosi](#funint_sosi) &mdash; {entry.short}
* [funFind](#funfind) &mdash; {entry.short}
* [funSubstr](#funsubstr) &mdash; {entry.short}
* [funDup](#fundup) &mdash; {entry.short}
* [funDict](#fundict) &mdash; {entry.short}
* [funList](#funlist) &mdash; {entry.short}
* [funReplace](#funreplace) &mdash; {entry.short}
* [funReplaceRe_sSSs](#funreplacere_ssss) &mdash; {entry.short}
* [funReplaceRe_sls](#funreplacere_sls) &mdash; {entry.short}
* [funPath](#funpath) &mdash; {entry.short}
* [funLower](#funlower) &mdash; {entry.short}
* [funKeys](#funkeys) &mdash; {entry.short}
* [funValues](#funvalues) &mdash; {entry.short}
* [funSort_lsosl](#funsort_lsosl) &mdash; {entry.short}
* [funSort_lssil](#funsort_lssil) &mdash; {entry.short}
* [funSort_lsssl](#funsort_lsssl) &mdash; {entry.short}
* [funGithubAnchor_ss](#fungithubanchor_ss) &mdash; {entry.short}
* [funGithubAnchor_ll](#fungithubanchor_ll) &mdash; {entry.short}
* [funType_as](#funtype_as) &mdash; {entry.short}
* [funJoinPath_loss](#funjoinpath_loss) &mdash; {entry.short}
* [funJoinPath_oSs](#funjoinpath_oss) &mdash; {entry.short}
* [createFunctionTable](#createfunctiontable) &mdash; {entry.short}
* [getFunctionList](#getfunctionlist) &mdash; {entry.short}
* [getFunction](#getfunction) &mdash; {entry.short}
* [isFunctionName](#isfunctionname) &mdash; {entry.short}

# cmpBaseValues

{entry.description}

```nim
func cmpBaseValues(a, b: Value; insensitive: bool = false): int
```

# funCmp_iii

{entry.description}

```nim
func funCmp_iii(parameters: seq[Value]): FunResult
```

# funCmp_ffi

{entry.description}

```nim
func funCmp_ffi(parameters: seq[Value]): FunResult
```

# funCmp_ssoii

{entry.description}

```nim
func funCmp_ssoii(parameters: seq[Value]): FunResult
```

# funConcat

{entry.description}

```nim
func funConcat(parameters: seq[Value]): FunResult
```

# funLen_si

{entry.description}

```nim
func funLen_si(parameters: seq[Value]): FunResult
```

# funLen_li

{entry.description}

```nim
func funLen_li(parameters: seq[Value]): FunResult
```

# funLen_di

{entry.description}

```nim
func funLen_di(parameters: seq[Value]): FunResult
```

# funGet_lioaa

{entry.description}

```nim
func funGet_lioaa(parameters: seq[Value]): FunResult
```

# funGet_dsoaa

{entry.description}

```nim
func funGet_dsoaa(parameters: seq[Value]): FunResult
```

# funIf

{entry.description}

```nim
func funIf(parameters: seq[Value]): FunResult
```

# funAdd_Ii

{entry.description}

```nim
func funAdd_Ii(parameters: seq[Value]): FunResult
```

# funAdd_Fi

{entry.description}

```nim
func funAdd_Fi(parameters: seq[Value]): FunResult
```

# funExists

{entry.description}

```nim
func funExists(parameters: seq[Value]): FunResult
```

# funCase_iloaa

{entry.description}

```nim
func funCase_iloaa(parameters: seq[Value]): FunResult
```

# funCase_sloaa

{entry.description}

```nim
func funCase_sloaa(parameters: seq[Value]): FunResult
```

# parseVersion

{entry.description}

```nim
func parseVersion(version: string): Option[(int, int, int)]
```

# funCmpVersion

{entry.description}

```nim
func funCmpVersion(parameters: seq[Value]): FunResult
```

# funFloat_if

{entry.description}

```nim
func funFloat_if(parameters: seq[Value]): FunResult
```

# funFloat_sf

{entry.description}

```nim
func funFloat_sf(parameters: seq[Value]): FunResult
```

# funInt_fosi

{entry.description}

```nim
func funInt_fosi(parameters: seq[Value]): FunResult
```

# funInt_sosi

{entry.description}

```nim
func funInt_sosi(parameters: seq[Value]): FunResult
```

# funFind

{entry.description}

```nim
func funFind(parameters: seq[Value]): FunResult
```

# funSubstr

{entry.description}

```nim
func funSubstr(parameters: seq[Value]): FunResult
```

# funDup

{entry.description}

```nim
func funDup(parameters: seq[Value]): FunResult
```

# funDict

{entry.description}

```nim
func funDict(parameters: seq[Value]): FunResult
```

# funList

{entry.description}

```nim
func funList(parameters: seq[Value]): FunResult
```

# funReplace

{entry.description}

```nim
func funReplace(parameters: seq[Value]): FunResult
```

# funReplaceRe_sSSs

{entry.description}

```nim
func funReplaceRe_sSSs(parameters: seq[Value]): FunResult
```

# funReplaceRe_sls

{entry.description}

```nim
func funReplaceRe_sls(parameters: seq[Value]): FunResult
```

# funPath

{entry.description}

```nim
func funPath(parameters: seq[Value]): FunResult
```

# funLower

{entry.description}

```nim
func funLower(parameters: seq[Value]): FunResult
```

# funKeys

{entry.description}

```nim
func funKeys(parameters: seq[Value]): FunResult
```

# funValues

{entry.description}

```nim
func funValues(parameters: seq[Value]): FunResult
```

# funSort_lsosl

{entry.description}

```nim
func funSort_lsosl(parameters: seq[Value]): FunResult
```

# funSort_lssil

{entry.description}

```nim
func funSort_lssil(parameters: seq[Value]): FunResult
```

# funSort_lsssl

{entry.description}

```nim
func funSort_lsssl(parameters: seq[Value]): FunResult
```

# funGithubAnchor_ss

{entry.description}

```nim
func funGithubAnchor_ss(parameters: seq[Value]): FunResult
```

# funGithubAnchor_ll

{entry.description}

```nim
func funGithubAnchor_ll(parameters: seq[Value]): FunResult
```

# funType_as

{entry.description}

```nim
func funType_as(parameters: seq[Value]): FunResult
```

# funJoinPath_loss

{entry.description}

```nim
func funJoinPath_loss(parameters: seq[Value]): FunResult
```

# funJoinPath_oSs

{entry.description}

```nim
func funJoinPath_oSs(parameters: seq[Value]): FunResult
```

# createFunctionTable

{entry.description}

```nim
func createFunctionTable(): Table[string, seq[FunctionSpec]]
```

# getFunctionList

{entry.description}

```nim
proc getFunctionList(name: string): seq[FunctionSpec]
```

# getFunction

{entry.description}

```nim
proc getFunction(functionName: string; parameters: seq[Value]): Option[
    FunctionSpec]
```

# isFunctionName

{entry.description}

```nim
proc isFunctionName(functionName: string): bool
```


---
⦿ Markdown page generated by [StaticTea](https://github.com/flenniken/statictea/) from nim doc comments. ⦿
