[StaticTea Modules](./)

# collectCommand.nim

Collect template command lines.

# Index

* [dumpCmdLines](#user-content-a0) &mdash; Write the stored command lines and the current line to the result stream and empty the stored commands.
* [collectCommand](#user-content-a1) &mdash; Read template lines and write out non-command lines.

# <a id="a0"></a>dumpCmdLines

Write the stored command lines and the current line to the result stream and empty the stored commands.

```nim
proc dumpCmdLines(resultStream: Stream; cmdLines: var seq[string];
                  cmdLineParts: var seq[LineParts]; line: string)
```


# <a id="a1"></a>collectCommand

Read template lines and write out non-command lines. When a command is found, collect its lines in the given lists, cmdLines, cmdLineParts and firstReplaceLine. When no command found, return with no lines.

```nim
proc collectCommand(env: var Env; lb: var LineBuffer;
                    prepostTable: PrepostTable; resultStream: Stream;
                    cmdLines: var seq[string]; cmdLineParts: var seq[LineParts];
                    firstReplaceLine: var string)
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
