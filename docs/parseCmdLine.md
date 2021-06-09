[StaticTea Modules](/)

# parseCmdLine.nim

Parse a template command line. We have two types of command lines,
CmdLine and CommandLine.

* CmdLine -- is a command line in a StaticTea template.
* CommandLine -- is a line at a terminal for system commands.

# Index

* type: [LineParts](#user-content-a0) &mdash; LineParts holds parsed components of a line.
* [parseCmdLine](#user-content-a1) &mdash; Parse the line and return its parts when it is a command.

# <a id="a0"></a>LineParts

LineParts holds parsed components of a line.

```nim
LineParts = object
  prefix*: string
  command*: string
  middleStart*: Natural
  middleLen*: Natural
  continuation*: bool
  postfix*: string
  ending*: string
  lineNum*: Natural

```


# <a id="a1"></a>parseCmdLine

Parse the line and return its parts when it is a command. Return quickly when not a command line.

```nim
proc parseCmdLine(env: var Env; prepostTable: PrepostTable; line: string;
                  lineNum: Natural): Option[LineParts]
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
