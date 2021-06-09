[StaticTea Modules](/)

# readjson.nim

Read json files.

# Index

* [readJsonContent](#user-content-a0) &mdash; Read a json stream and return the variables.
* [readJsonContent](#user-content-a1) &mdash; Read a json string and return the variables.
* [readJson](#user-content-a2) &mdash; Read a json string and return the variables.
* [readJsonFiles](#user-content-a3) &mdash; Read the json files and return the variables in one dictionary.
* [readServerVariables](#user-content-a4) &mdash; Read the server json.
* [readSharedVariables](#user-content-a5) &mdash; Read the shared json.

# <a id="a0"></a>readJsonContent

Read a json stream and return the variables.  If there is an error, return a warning. The filename is used in warning messages.

```nim
proc readJsonContent(stream: Stream; filename: string = ""): ValueOrWarning
```


# <a id="a1"></a>readJsonContent

Read a json string and return the variables.  If there is an error, return a warning. The filename is used in warning messages.

```nim
proc readJsonContent(content: string; filename: string = ""): ValueOrWarning
```


# <a id="a2"></a>readJson

Read a json string and return the variables.  If there is an error, return a warning. The filename is used in warning messages.

```nim
proc readJson(filename: string): ValueOrWarning
```


# <a id="a3"></a>readJsonFiles

Read the json files and return the variables in one dictionary. The last file wins on duplicates.

```nim
proc readJsonFiles(env: var Env; filenames: seq[string]): VarsDict
```


# <a id="a4"></a>readServerVariables

Read the server json.

```nim
proc readServerVariables(env: var Env; args: Args): VarsDict
```


# <a id="a5"></a>readSharedVariables

Read the shared json.

```nim
proc readSharedVariables(env: var Env; args: Args): VarsDict
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
