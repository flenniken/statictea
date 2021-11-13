## Private module for experimenting.
import strutils
import unicode

echo "The char type is a byte."
let ch = 'r'
echo "let ch = 'r'"
echo "ord(ch) => " & $ord(ch)
echo "toHex(ord(ch)) => " & toHex(ord(ch))
echo ""

echo "rune is a unicode character stored as specific uint32."
echo ""

for codePoint in 0..\x

echo "You can make a rune from a number:"
echo "Rune(114) => " & $Rune(114) 
echo "Rune(ord(ch)) => " & $Rune(ord(ch)) 
echo ""

echo "You can make a rune from a char."
var rune = Rune(ch)
echo "Rune(ch) => " & $rune
echo ""

echo "You can get the uint32 from a rune."
var num = uint(rune)
echo "uint(rune) => " & $num
echo ""

echo "You can make a sequence of Runes from a string:"
var str = "testing"
echo """str = "$1"""" % str
var runes = toRunes(str)
echo "toRunes(str) => " & $runes
echo ""

echo "You can make a string from a sequence of runes:"
echo "$runes => " & $runes
