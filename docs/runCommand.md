[StaticTea Modules](/)

# runCommand.nim

Run a command.

# Index

* [getString](#user-content-a0) &mdash; Return a literal string value and match length from a statement.
* [getNumber](#user-content-a1) &mdash; Return the literal number value and match length from the statement.
* [getFunctionValue](#user-content-a2) &mdash; Collect the function parameter values then call it.
* [getVarOrFunctionValue](#user-content-a3) &mdash; Return the statement's right hand side value and the length matched.
* [runStatement](#user-content-a4) &mdash; Run one statement and assign a variable.
* [runCommand](#user-content-a5) &mdash; Run a command and fill in the variables dictionaries.

# <a id="a0"></a>getString

Return a literal string value and match length from a statement. The start parameter is the index of the first quote in the statement and the return length includes optional trailing white space after the last quote.

```nim
proc getString(env: var Env; prepostTable: PrepostTable; statement: Statement;
               start: Natural): Option[ValueAndLength]
```


# <a id="a1"></a>getNumber

Return the literal number value and match length from the statement. The start index points at a digit or minus sign.

```nim
proc getNumber(env: var Env; prepostTable: PrepostTable; statement: Statement;
               start: Natural): Option[ValueAndLength]
```


# <a id="a2"></a>getFunctionValue

Collect the function parameter values then call it. Start should be pointing at the first parameter.

```nim
proc getFunctionValue(env: var Env; prepostTable: PrepostTable;
                      function: FunctionPtr; statement: Statement;
                      start: Natural; variables: Variables): Option[
    ValueAndLength]
```


# <a id="a3"></a>getVarOrFunctionValue

Return the statement's right hand side value and the length matched. The right hand side must be a variable or a function. The right hand side starts at the index specified by start.

```nim
proc getVarOrFunctionValue(env: var Env; prepostTable: PrepostTable;
                           statement: Statement; start: Natural;
                           variables: Variables): Option[ValueAndLength]
```


# <a id="a4"></a>runStatement

Run one statement and assign a variable. Return the variable dot name string and value.

```nim
proc runStatement(env: var Env; statement: Statement;
                  prepostTable: PrepostTable; variables: var Variables): Option[
    VariableData]
```


# <a id="a5"></a>runCommand

Run a command and fill in the variables dictionaries.

```nim
proc runCommand(env: var Env; cmdLines: seq[string];
                cmdLineParts: seq[LineParts]; prepostTable: PrepostTable;
                variables: var Variables)
```



---
⦿ StaticTea markdown template for nim doc comments. ⦿
