<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. StaticTea</a>
<ul>
<li><a href="#sec-1-1">1.1. A template processor and language.</a></li>
<li><a href="#sec-1-2">1.2. Basics</a></li>
<li><a href="#sec-1-3">1.3. Commands</a>
<ul>
<li><a href="#sec-1-3-1">1.3.1. Nextline Command</a></li>
<li><a href="#sec-1-3-2">1.3.2. Block Command</a></li>
<li><a href="#sec-1-3-3">1.3.3. Replace Command</a></li>
<li><a href="#sec-1-3-4">1.3.4. Comment Command</a></li>
</ul>
</li>
<li><a href="#sec-1-4">1.4. Types</a>
<ul>
<li><a href="#sec-1-4-1">1.4.1. Strings</a></li>
<li><a href="#sec-1-4-2">1.4.2. Numbers</a></li>
<li><a href="#sec-1-4-3">1.4.3. Variables</a></li>
<li><a href="#sec-1-4-4">1.4.4. System Variables</a></li>
<li><a href="#sec-1-4-5">1.4.5. System Functions</a></li>
</ul>
</li>
<li><a href="#sec-1-5">1.5. Template Prefix Postfix</a></li>
<li><a href="#sec-1-6">1.6. Json Files</a></li>
<li><a href="#sec-1-7">1.7. Warnings and Defaults</a></li>
<li><a href="#sec-1-8">1.8. Run StaticTea</a>
<ul>
<li><a href="#sec-1-8-1">1.8.1. Options</a></li>
</ul>
</li>
<li><a href="#sec-1-9">1.9. Template Specification</a></li>
<li><a href="#sec-1-10">1.10. Tea References in Examples.</a></li>
<li><a href="#sec-1-11">1.11. <span class="todo TODO">TODO</span> Output to standard out when the result option is missing.</a></li>
<li><a href="#sec-1-12">1.12. <span class="todo TODO">TODO</span> Access items in the namespace with a dot, i.e.:</a></li>
<li><a href="#sec-1-13">1.13. <span class="todo TODO">TODO</span> Use standard in when the template parameter is called stdin.</a></li>
<li><a href="#sec-1-14">1.14. <span class="todo TODO">TODO</span> Errors on the command line use line(0) to standard out.</a></li>
<li><a href="#sec-1-15">1.15. <span class="todo TODO">TODO</span> Set error code</a></li>
</ul>
</li>
</ul>
</div>
</div>

# StaticTea<a id="sec-1" name="sec-1"></a>

## A template processor and language.<a id="sec-1-1" name="sec-1-1"></a>

StaticTea combines a template with data to produce a result.

Example template:

    <!--$ nextline -->
    hello {name}

The associated json data:

    {"name": "world"}

The result:

    hello world

## Basics<a id="sec-1-2" name="sec-1-2"></a>

You specify each template command on one line. The command
applies to the current line, next line or next block of
lines (the replacement block) depending on the command.

You use variables in brackets to mark locations in the
replacement block for replacement. These variables typically get
replaced by their associated json value.

You can use two types of json files, a server json file and
shared json file.  The server json comes from the server and does
not contain any presentation markup. The shared json, maintained
by the template builder, contains shared presentation markup.

Since the template commands are encoded as comments, the template
file looks like a native file and you can view, edit, validate,
etc. the file with its normal tools. You develop templates as if
they were static pages.

## Commands<a id="sec-1-3" name="sec-1-3"></a>

StaticTea has four commands:

-   nextline — make substitutions in the next line
-   block — make substitutions in the next block of lines
-   replace — replace a block of lines
-   \# — comment

You add statements to commands to control how it behaves.

### Nextline Command<a id="sec-1-3-1" name="sec-1-3-1"></a>

The nextline command tells the template system that the next line
in the file has variable content.

The content comes from text in the line and variables wrapped
with brackets.

In the following example there is some text and two variables, the
drink and drinkType variables.

template:

    <!--$ nextline -->
    Drink {drink} -- {drinkType} is my favorite.

json:

    {
      "drink": "tea",
      "drinkType": "Earl Grey""
    }

result:

    Drink tea -- Earl Grey is my favorite.

### Block Command<a id="sec-1-3-2" name="sec-1-3-2"></a>

The block command targets multiple lines for replacement. The
block starts after the command and continues until another block
line is found. It behaves like the nextline command except with
multiple lines.

The content comes from text in the block and variables wrapped
with brackets.

In the following example the block has two lines. The block
contains three replacement variables, weekday, name and time.

template:

    <!--$ block -->
    Join our tea party on {weekday} at
    {name}'s house at {time}.
    <!-- block -->

json:

    {
      "weekday": "Friday",
      "name": "John",
      "time": "5:00 pm"
    }

result:

    Join our tea party on Friday at
    John's house at 5:00 pm.

### Replace Command<a id="sec-1-3-3" name="sec-1-3-3"></a>

The replace command replaces the replacement block with a
variable's value. You set the block content by assigning the
t.content variable.

The lines in the block mirror the variable so you can
test the template as if it was a static file.

The command is useful for sharing common template lines between
templates and it has the special property that you can update the
replacement block to keep it in sync with the variable.

The following example shares a common header between templates.

template:

    <!--$ replace t.content=s.header -->
    <!--$ replace -->

json:

    {
      "header": "<!doctype html>\n<html lang="en">\n"
    }

result:

    <!doctype html>
    <html lang="en">

The above example doesn’t work as a static template because the
template is missing the header lines.

You can fix this by adding the header lines inside the replace
block. The inside lines do not appear in the result, just the
data from the json variable.

template:

    <!--$ replace t.content=s.header -->
    <!doctype html>
    <html lang="en">
    <!--$ replace -—>

The template replacement block may get out of sync with the
variable.  You can update the replacement block to match the
variable with the update option.

The following example updates the mytea.html template's
replacement blocks to match their variables in the shared.json
file:

    statictea --update --shared shared.json --template mytea.html

### Comment Command<a id="sec-1-3-4" name="sec-1-3-4"></a>

You can comment templates.  Comments are line based and use the #
character. They do not appear in the result.

template:

    <!--$# This is a comment. -->
    <!--$ # This is a comment. -->
    hello again

result:

    hello again

## Types<a id="sec-1-4" name="sec-1-4"></a>

### Strings<a id="sec-1-4-1" name="sec-1-4-1"></a>

You define a string using single or double quotes. You use
strings in command statements.

example strings:

    "this is a string"
    "what's up?"
    'using single quote'

example usage:

    <!--$ nextline message=t.if(admin, 'Earl Grey' 'Jasmine') -->
    <h2>{message}</h2>

json:

    {
      "admin": 0
    }

result:

    <h2>Earl Grey</h2>

### Numbers<a id="sec-1-4-2" name="sec-1-4-2"></a>

You can use ordinal numbers in statements.

1.  TODO are numbers needed?

        0, 1, 2, 3,...

### Variables<a id="sec-1-4-3" name="sec-1-4-3"></a>

You assign variables to system variables to control how the
command works and you use variables in the replacement block as
content.

The json files contain variables.  The keys are the variable
names and their value becomes part of the template when they are
used. Internally two json namespace exists, one for the shared
json and one for the server json.  You access the shared json
with "s." and the server with no prefix.

StaticTea has a number of system variables. You access them in
the t namespace, by using the prefix "t.".

You can define new variables on the command's line. These
variables are local to the block and take precedence over the
json variables.

You can define any number of variables that will fit on the
line. You can put them on the end block if needed.

The variables are processed from left to right, so the last one
takes precedence when there are duplicates.

example variables:

    t.row
    serverVar
    s.name


When StaticTea detects a problem, a warning message is written to
standard error and processing continues. All issues are handled,
usually by skipping the problem.

It’s good style to change your template or json so no messages
get output.

StaticTea returns success (0) when no message get output, else it
returns 1.

The warning message show the line number of the problem
happened. Every message has a unique number.

example messages:

-   template.html(45): w0001: email variable is missing from server.json.
-   template.html(45): w0002: The command line's postfix is missing.
-   template.html(45): w0003: The command line doesn't have a valid
    command.
-   template.html(45): w0004: unknown system variable t.asdf.
-   template.html(45): w0005: server json file not found: asdf
-   template.html(45): w0006: unable to parse server.json

### System Variables<a id="sec-1-4-4" name="sec-1-4-4"></a>

You primarily use the system variables on a command line to
control what the command does.

System variables:

-   t.list - repeats the block for each item in a list.
-   t.maxLines - the max number of lines in the block.
-   t.result - defines whether the block goes to the result file,
    standard out or nowhere.
-   t.content - defines what goes in the replace block.

1.  List Variable

    The list variable controls how many times the command's block
    repeats. You assign it with your list variable and the block
    repeats for each item in a list. The default is "" which means no
    repeat.
    
    For the following example, the list statement says to use
    email<sub>list</sub> key. The result has two lines.
    
    template:
    
        <!--$ nextline _list = email_list -->
        Mail support at {email}.
    
    json:
    
        {
        "email_list": [
            {"email": "steve@flenniken.net"},
            {"email": "webmaster@google.com"}
          ]
        }
    
    result:
    
        Mail support at steve@flenniken.net.
        Mail support at webmaster@google.com.

2.  t.list example

    The following example builds a select list of cars where one car is selected.
    
    template:
    
        <h4>Car List</h3>
        <select>
        <!--$ nextline t.list=car_list current=t.if( selected 'selected="selected"') -->
          <option{current}>{car}</option>
        </select>
    
    json:
    
        {
        "car_list": [
            {"car": "vwbug"},
            {"car": "corvete"},
            {"car": "mazda"},
            {"car": "ford pickup"},
            {"car": "BMW", "selected": 1},
            {"car": "Honda"}
          ]
        }
    
    result:
    
        <h3>Car List</h3>
        <select>
          <option>vwbug</option>
          <option>corvete</option>
          <option>mazda</option>
          <option>ford pickup</option>
          <option selected="selected">BMW</option>
          <option>Honda</option>
        </select>

3.  Max Lines Variable

    -   t.maxLines - you assign the maxLines variable when the block
        has more then 10 lines (the default). The number of lines in
        the block is limited to this value.
    
    StaticTea reads lines looking for the terminating line a block or
    replace command. By default if the terminator is not found in 10
    lines, the 10 lines are used for the block and a warning is
    output.  You can specify other values with the \_max<sub>lines</sub>
    variable.
    
        <!--$ block _max_lines=20 -->

4.  Result Variable

    -   t.result - you assign the result variable to determine where
        the command's result goes, either the result file, standard out
        or nowhere.
    
    The system result variable determines where the result goes.  By
    default it goes to the result file. You can also direct it to
    standard out or skip it.
    
    Result variable options:
    
    -   "resultFile" - send the replacement block to the file (default)
    -   "skip" - skip the block
    -   "stderr" - send the block to standard error
    
    The skip case is good for building test lists.  The stderr case
    is good for communicating that the json data is unexpected.
    
    When you view the following template fragment in a browser it
    shows one item in the list.
    
    template:
    
        <h3>Tea</h3>
        <ul>
        <!--$ nextline t.list = teaList -->
          <li>{tea}</li>
        </ul>
    
    To create a static page that has more products for better testing
    you could use the skip option like this:
    
    template:
    
        <h3>Tea</h3>
        <ul>
        <!--$ nextline t.list = teaList -->
          <li>{tea}</li>
        <!--$ block t.result = 'skip' -->
          <li>Black</li>
          <li>Green</li>
          <li>Oolong</li>
          <li>Sencha</li>
          <li>Herbal</li>
        <!--$ block -->
        </ul>
    
    json:
    
        {
          "teaList": [
            {"tea": "Chamomile"},
            {"tea": "Chrysanthemum"},
            {"tea": "White"},
            {"tea": "Puer"}
          ]
        }
    
    result:
    
        <h3>Tea</h3>
        <ul>
          <li>Chamomile</li>
          <li>Chrysanthemum</li>
          <li>White</li>
          <li>Puer</li>
        </ul>

5.  Content Variable

    -   t.content - you assign the content variable to your variable
        when you want it to replace the whole replace block. The
        default is "". The content variable only applies to the replace
        command.
    
    The content variable defines what goes in the replace block.

### System Functions<a id="sec-1-4-5" name="sec-1-4-5"></a>

There are three built in system functions:

-   t.row
-   t.if
-   t.version

Functions take different numbers of parameters. If you call with
one parameters, you can drop the parentheses.

These are equivalent:

    email = t.row(0)
    email = t.row 0

1.  Row Function

    The special row function contains the row of the current list. You control the start number.
    
    -   row — starts at 0
    -   \_row 0 — starts at 0
    -   \_row 1 — starts at 1
    -   \_row N — starts at N where N is some ordinal number.
    
    Here is an example using the row variable.
    
    template:
    
        <!--$ nextline t.list=car_list -->
        <li>{t.row 1}. {car}</li>
    
    json:
    
        {
          "car_list": [
            {"car": "Tesla"},
            {"car": "Ford"}
          ]
        }
    
    result:
    
        <li>1. Tesla</li>
        <li>2. Ford </li>

2.  If Function

    You can use an if statement in a template.
    
    The general form of the if statement has three variable
    parameters.  If the first variable is true, the second variable
    is returned, else the third variable is returned.
    
    You can drop the third and second parameters and there are
    defaults for each case.
    
    When you drop both, 0 or 1 is returned. The following example
    uses the template system to show what happens when you drop the
    t.if parameters.
    
    template:
    
        <--$ block var1=t.if(cond0 dog cat) var2=t.if(cond0 dog) var3=t.if(cond0) -->
        
        t.if({cond0} dog cat) -> {var1}
        t.if({cond0} dog)     -> {var2}
        t.if({cond0})         -> {var3}
        
        t.if({cond1} dog cat) -> {var4}
        t.if({cond1} dog)     -> {var5}
        t.if({cond1})         -> {var6}
        
        <--$ block var4=t.if(cond0 dog cat) var5=t.if(cond0 dog) var6=t.if(cond0) -->
    
    json:
    
        {
          "cond0": 0,
          "cond1": 1,
          "dog": "dog",
          "cat": "cat",
        }
    
    result:
    
        t.if(0 dog cat) -> cat
        t.if(0 dog)      -> 0
        t.if(0)          -> 0
        
        t.if(1 dog cat) -> dog
        t.if(1 dog)      -> dog
        t.if(1)          -> 0
    
    
    You can use the statictea command as a filter and pipe template
    lines to it and see the result output on the screen.
    
    You can try out the examples in the document by copy and pasting
    into a posix terminal window.
    
    The examples use the Here Document feature to easily create
    multi-line templates. The following shows a simple Here Document
    that pipes three lines, to the wc command which reports the
    number of lines.
    
    Here is an example you can copy and paste into your terminal. It
    creates a template.txt file containing two lines, then it creates
    the server.json file containing one line, then it runs statictea
    using those files.
    
        cat <<EOF >template.txt
        <!--$ nextline -->
        hello {name}
        EOF
        
        cat <<EOF >server.json
        {"name": "world"}
        EOF
        
        statictea --template template.txt --server server.json
    
    If you copy and paste those lines to your terminal, it will look
    like:
    
        $ cat <<EOF >template.txt
        > <!--$ nextline -->
        > hello {name}
        > EOF
        $
        $ cat <<EOF >server.json
        > {"name": "world"}
        > EOF
        $
        $ statictea --template template.txt --server server.json
        hello world
    
    The following example uses statictea as a filter and pipes to it the
    template.txt file created in the last example:
    
        cat template.txt | statictea --template stdin --server server.json
        
        hello world

3.  Version Function

    You use the version function to verify that the version of
    StaticTea code you are running works with your template and to
    get the current version string.
    
    The version function take to parameters, the minimum version and
    the maximum version, both are optional.
    
    If the current version is below the minimum or above the maximum,
    the function outputs a message to standard out.
    
    You can use the function multiple times for fine grain checking.
    
    Below is typical useage:
    
    template:
    
        <--$ nextline version=t.version("1.2.3", "3.4.5") -->
        <-- StaticTea current version is: {version}. -->
    
    result:
    
        <-- StaticTea current version is: 1.9.0. -->
    
    If the current version is not between the min and max, a message
    is output to standard error.  Example messages:
    
    stdout:
    
        template(line): the current version 4.0.2 is greater than the maximum
        allowed verion of 3.4.5.
        
        template(line): the current version 1.0.0 is less than the minumum
        allowed verion of 1.2.3.

## Template Prefix Postfix<a id="sec-1-5" name="sec-1-5"></a>

You specify the template commands as comments for the type of
result file. This allows you to edit the template using its
native editor.  For example, you can edit an html template with
an html editor.

Comment syntax varies depending on the type of template file and
sometimes depending on the location within the file. StaticTea
supports several varieties and you can specify others.

You want to distinguish StaticTea commands from normal
comments. The convention is to add a $ as the last character of
the prefix and only use $ with StaticTea commands and space for
normal comments.

-   \`<!&#x2013;$ &#x2026; &#x2013;>\` for html
-   \`/\*&#x2013;$&#x2026; &#x2013;\*/\` for javascript in html
-   \`&lt;!&#x2013;$&#x2026; &#x2013;&gt;\` for textarea elements

You can define other comment types on the command line using the
prepost option one or more times.

You separate the prefix from the postfix with a space and the
postfix is optional.

examples:

    statictea--prepost "@$" "|"
    statictea--prepost "[comment$" "]"
    statictea--prepost "#$"

## Json Files<a id="sec-1-6" name="sec-1-6"></a>

There are two types of json files the server json and the shared
json.

The server json comes from the server and doesn’t contain any
presentation data.

The share json is used by the template builder to share common
template lines and it contains presentation data.

The server json file is included with the "-server" option.  Its
variables are referenced with the json key names.

The shared json file is specified with the "—shared" option. Its
variables are referenced with the "s." namespace.

You can specify multiple files of both types. Internally there is
one dictionary for the server and one for the shared. The files
get added from left to right so the last duplicate variable wins.

## Warnings and Defaults<a id="sec-1-7" name="sec-1-7"></a>

When StaticTea encounters an error, it outputs a message to
standard error and continues.  It skips the element with the
problem using some default.

For example, if a variable in a block is used but it doesn't
exist, the variable remains as is and a message is output telling
the line and variable missing.

Note: when a variable is missing, empty or not a string, it is
treated as a empty string.

When the postfix is missing, the line command is still used, but
a warning message is output.

## Run StaticTea<a id="sec-1-8" name="sec-1-8"></a>

You run StaticTea from the command line. The example below shows
a typical invocation. You specify four file parameters, the
server json, the shared json the template and the result.

    statictea --server server.json --shared shared.json --template template.html --result result.html

-   Warning messages go to standard error.
-   If you don't specify the result parameter, the result goes to

standard out.
-   It you specify "stdin" for the template, the template comes
    from stdin.

### Options<a id="sec-1-8-1" name="sec-1-8-1"></a>

The StaticTea command line options:

-   help - show the usage and options.
-   version -outputs the version number to standard out and exits.
-   server - the server json file. You can specify multiple files.
-   shared - the shared json file. You can specify multiple files.
-   update - update the template replace blocks.

## Template Specification<a id="sec-1-9" name="sec-1-9"></a>

    template = [line]*
    line = prefix os commands os postfix
    s = [" " | tab]+
    os = [" " | tab]*
    
    commands = nextline | block | comment | skip | shared
    
    skip = .*
    comment = "#" .*
    nextline = "nextline" [s variable ]*
    block = "block" [s variable ]*
    shared = "shared" [s variable]+
    
    list = "_list" os "=" os right_side
    
    variable = "{" os name os "}"
    
    name = key | row
    row = "_row" [0-9]+
    key =  ["_shared" s] [a-zA-Z]+[a-zA-Z0-9_]*
    
    
    replace = key os "=" os right_side
    right_side = name | string | if
    
    string = "_string(" .* ")"
     if = "_if" s name s name s name

    nextline {email}
    nextline {_row 78}
    nextline {_shared header}
    nextline {email = "hello"}
    nextline {email = steve_email}
    nextline {email = _if admin one two}

## Tea References in Examples.<a id="sec-1-10" name="sec-1-10"></a>

Use pictures too. teapot, Japanese tea hut

## TODO Output to standard out when the result option is missing.<a id="sec-1-11" name="sec-1-11"></a>

## TODO Access items in the namespace with a dot, i.e.:<a id="sec-1-12" name="sec-1-12"></a>

t.list, t.maxLines, etc

## TODO Use standard in when the template parameter is called stdin.<a id="sec-1-13" name="sec-1-13"></a>

## TODO Errors on the command line use line(0) to standard out.<a id="sec-1-14" name="sec-1-14"></a>

## TODO Set error code<a id="sec-1-15" name="sec-1-15"></a>