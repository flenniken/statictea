[StaticTea Modules](/)

# args.nim

Command line arguments.

# Index

* type: [Prepost](#user-content-a0) &mdash; Prepost holds one prefix and its associated postfix.
* type: [Args](#user-content-a1) &mdash; Args holds all the command line arguments.
* [newPrepost](#user-content-a2) &mdash; Create a new prepost object from the prefix and postfix.
* [`$`](#user-content-a3) &mdash; Return a string representation of the Args object.

# <a id="a0"></a>Prepost

Prepost holds one prefix and its associated postfix.

```nim
Prepost = object
  prefix*: string
  postfix*: string

```


# <a id="a1"></a>Args

Args holds all the command line arguments.

```nim
Args = object
  help*: bool
  version*: bool
  update*: bool
  log*: bool
  serverList*: seq[string]
  sharedList*: seq[string]
  templateList*: seq[string]
  prepostList*: seq[Prepost]
  resultFilename*: string
  logFilename*: string

```


# <a id="a2"></a>newPrepost

Create a new prepost object from the prefix and postfix.

```nim
func newPrepost(prefix: string; postfix: string): Prepost
```


# <a id="a3"></a>`$`

Return a string representation of the Args object.

```nim
func `$`(args: Args): string
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
