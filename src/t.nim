## Private module for experimenting.

import re

let str = "testFunResulthere FunResult FunResult"
let pattern = r"\bFunResult\b"
let replacement = "RunResult_"

let resultString = replace(str, re(pattern), replacement)
echo resultString

