# Koneko

Koneko is a toy project I started to understand how lexer and parser work. I'm sure I've made a lot of mistakes anyway. Also I like [NekoVM](http://nekovm.org) and I thought it would be good to have another language beside [Haxe](http://haxe.org/) that runs on NekoVM :)

The language itself is a wild mix of ideas from Forth, Factor, Joy and my own preferences. It is stack-based, imperative, interpreted programming (scripting?) language with Reverse Polish Notation.

The word "koneko" means "kitten" in japanese. :)

## Building

You will need Haxe 3.4 to build Koneko. It may build with earlier versions, but I have not tested it.

To build Koneko just run in shell:
```bash
$ cd somewhere-you-remember
$ git clone https://github.com/Esgorhannoth/koneko
# cd koneko
$ haxe build.hxml
```

This will create bin/ directory with koneko.n executable Neko bytecode and some additional modules there.

To run the REPL:
```bash
$ neko bin/koneko.n
```
or if you have _rlwrap_:
```bash
$ rlwrap neko bin/koneko.n
```
for better line-editing experience.

<a name="basics">
## Basics
</a>

As in most(all?) Forth-like languages the basics are really simple. You either put value on the stack, or execute a word that operates on values on the stack. Koneko supports these basic types:

* Integer
* Float
* String (utf-8)

There are some words for working with "characters" (utf-8 codepoints), but they are represented as Integers anyway.

Comparison operations work on "boolean" values. A "boolean" value in Koneko is an Integer with zero meaning `false` and any other number either positive or negative meaning `true`. Builtin words return `-1` for `true` by convention (-1 in signed 8-bit integer binary form looks like `1111 1111`).

Everything else is treated as a word. Neither integers nor floats can have minus before them. To use negative numbers, use word `negate`. So all of these are valid Koneko words:
```forth
-1
1+
,,
%$@#!
some-long-word
и-кириллица-тоже
Hello,世界
```
By the way, Koneko is *case-sensitive*.

The only rule is that a word cannot contain parentheses, braces or brackets ( No '()', '[]', '{}' ). Also it is not advisable to include colons in words, because it can mess with [Namespace](#namespaces) recognition.



<a name="interpreter">
## Interpreter
</a>

After you have launched the interpreter it will show you input prompt:
```
> _
```

I have not figured out how to make input multi-line, so at least for now all your word definitions must sit on one line.

### Sample session
```forth
> 1 2 3 + + say<CR>
6
> 'Batman' 'and' 'Robin' + + .s<CR>
<1> "BatmanandRobin"
> print<CR>
BatmanandRobin > <CR>
> ( this is a comment )<CR>
> _
```

<a name="quotations">
## Qutations
</a>

Sometimes we need not evaluate a word right now. We can put the word (or several words) on stack in "quotes".
```forth
> "Wild Wild Guest" say
Wild Wild Guest
> ["Wild Wild Guest" say]
> .s
<1> ["Wild Wild Guest" say]
```

Words quoted like this can be passed around to other words and maybe evaluated later. To evaluate a quote on top of stack (TOS), use `i` word.
```forth
> ['Something beautiful' say] .s
<1> ['Something beautiful' say]
> i
Something beautiful
> _
```

There are words that create and modify quotes. They even can be used for simple metaprogramming (though I guess it won't be so simple with all this stack shuffling)


<a name="definitions">
## Word definitions
</a>

You can create new words with one of three words: `:`, `is`, and `is!`. `:` and `is` are actually equivalent - they (re)define a word no matter what. `is` is more careful, it won't redefine a word if it is already defined.

```forth
> [print '\n' print] is say
> 'Some like it hot' say
Some like it hot
> [ 2 / ] is 2/
> 6 2/ .
3 > [ len? 80 swap - 2/ say ] is centered
> 'this text is centered on 80-char width terminal' centered
```
`.` word just prints TOS. `len?` is Prelude alias for `string-length` and `swap` exchanges two values on top of the stack. It's a good time to see other predefined words, by the way. But first let's learn about namespaces.


<a name="namespaces">
## Namespaces
</a>

Some words are just so good that we want to use them over and over. Like `open`. We can open a file, a socket, a door in a game. Naturally we want this `open` to behave differently, but we do not want the word to check what was passed to it via stack. Enter namespaces.

There are two namespaces that you'll have no matter what: _Builtin_ and _Main_. Builtin has all the words that are defined and written in Haxe. You cannot redefined words in Builtin namespace, but you can shadow them. Main is namespace created by the interpreter for you to define your own words and generally play around.

If you have a file named *Prelude.kn* in your current working directory, Koneko will load and interpret the contents of this file and add defintions from it to predefined _Prelude_ namespace. You can put there word definitions that you need the most or just find useful.

We'll see how to work with namespaces when we learn some new words.


<a name="words">
## All the words in the world are not enough
</a>

This section is quite long and contains the list of predefined words and a short explanation for each of them. Where appropriate stack effect comments will show up.

Legend:

* I - Integer
* F - Float
* S - String
* Q - Quote
* A - Atom (internal name for a string of characters that represent a Koneko word)
* number or V - any Value (I, F, S, A or Q). Same number means same value.
* TOS - Top Of Stack
* NOS - Next On Stack

<a name="words-stack">
### Stack
</a>

* `dup ( 1 -- 1 1 )` - duplicates TOS
* `swap ( 1 2 --  2 1 )` - swaps two topmost stack items.
* `rot ( 1 2 3 -- 2 3 1 )` - puts third on stack item on top
* `-rot ( 1 2 3 -- 3 1 2 )` - puts TOS item on third position from top
* `drop ( 1 2 -- 1 )` - removes TOS
* `over ( 1 2 -- 1 2 1 )` - duplicates NOS and puts is on top
* `pick ( i -- 1 )` - picks nth item from top of stack, 0-based indexing, TOS = 0, NOS = 1 etc.
* `clear-stack` - purges all values from stack
* `.s` - shows stack contents (mainly for debugging and interactive development)
* `.sl` - returns number of items in stack
* `.` - prints TOS

* `2dup ( 1 2 --  1 2 1 2 )` - duplicates both NOS and TOS (in Prelude)
* `2swap ( 1 2 3 4 -- 3 4 1 2 )` - swaps two pairs of values
* `2over ( 1 2 3 4 -- 1 2 3 4 1 2 )` - like `over`, but for a pair of values

<a name="words-temp-stack">
### Temporary stack
</a>

* `>t` - transfer value from main stack to temporary stack
* `<t` - transfer value from temporary stack to main stack
* `.t` - show contents of temporary stack
* `.tl` - puts number of items in temporary stack on top of main stack


<a name="words-temp-stack">
### Math
</a>

* `+` - adds two numbers or two strings
* `-` - subtracts TOS from NOS
* `*` - multiplication
* `div` - integer division
* `/`   - float division
* `negate` - negates TOS
* `round ( f -- i )` - rounds a Float number ( 2.4 -> 2, 2.5 -> 3 )
* `ceil ( f -- i )`  - rounds a Float number to nearest higher Integer ( 2.2 -> 3 )
* `floor ( f -- i )` - rounds a Float number to nearest lower Integer ( 2.8 -> 2 )
* `=`, `!=`, `>`, `<`, `>=`, `<=` - comparison
* `and`, `or`, `xor`, `not` - boolean operations
* `random ( i -- i )` - puts on stack a random Integer between zero and TOS (including, excluding) or `[0...x)`
* `rnd` - puts on stack a random Float number between 0 including and 1 excluding 

<a name="words-strings">
## Strings
</a>

* `at ( s i -- s )` - returns character at position `i`
* `uc ( s -- s )` - converts string to uppercase (ASCII and utf-8 cyrillic only for now)
* `lc ( s -- s )` - converts string to lowercase (ASCII and utf-8 cyrillic only for now)
* `backw ( s --  s )` - reverses string
* `to-str ( s -- s )` - converts TOS to string
* `sub ( s i -- s )` - substring of string from position `i`
* `substr ( s i1 i2 -- s )` - substring of string `s` from position `i1`  with length `i2`
* `subrange (s i1 i2 -- s)` - substring of string `s` from position `i1` (including) to position `i2` (excluding)
* `string-length ( s -- i )` - returns length of string `s`
* `len? ( s -- i )` - alias for `string-length` in Prelude

<a name="words-chars">
### Chars (as Integers)
</a>

* `atc ( s i -- i )` - returns codepoint ('c' in 'atc') at position `i` in string `s` 
* `chr->str ( i -- s )` - converts char (int) to utf8 string
* `chars->str ( q(i) -- s )` - converts list (quote) of chars to utf8 string
* `emit ( i -- )` - print character

<a name="words-definitions">
### Definitions
</a>

* `:`, `is!` - define new word, e.g. [ some words in quote ] : new-word
* `is` - careful definition, won't define word if it is already defined
* `def? ( q(a) -- bool )` - returns true (-1) if word in quote is defined, false (0) otherwise. There must be only one atom in quote!
* `see ( q(a+) -- )` - prints source code of words in quote, e.g. [ say len? ] see
* `undef ( q(a+) )` - undefines (erases from vocabulary) atoms listed in quote, e.g. [ say ] undef

<a name="words-quotations">
### Quotations
</a>

`>q`, `q<`, `<q`, `q>` - are kind of mnemonics: push to start of quote, push to end of quote, get from start of quote, get from end of quote

* `quote ( i -- q(v+) )` - turns `i` values on stack into quote, e.g. 1 2 3 3 quote -> [1 2 3]
* `unquote ( q -- 1..n )` - turns quote on stack to sequence of values on stack: [1 2 3] -> 1 2 3
* `>q ( v q -- q )` - unshift value to start of quote (prepend)
* `q< ( q v -- q )` - push value to back of quote
* `<q ( q -- q i )` - shift value from start of quote
* `q> ( q -- q i )` - pop value from back of quote
* `reverse ( q -- q )` - reverses values in quote, e.g. [ 1 2 3 ] -> [ 3 2 1 ]
* `concat ( q q -- q )` - concatenates two quotes, e.g. [ 1 2 ] [ 3 4 ] -> [ 1 2 3 4 ]
* `i ( v -- ? )` - evaluates value on TOS ( useful for quotes and atoms , everything else evaluatess to itself )

<a name="words-loops-branches">
### Loops and branches
</a>

* `if` - conditional evaluation: `bool [then branch] [else branch] if`
* `when` - like `if` without `else-branch`: `bool [then branch] when`
* `unless` - like `when` but with boolean condition negated: `bool [then branch] unless` is the same as `bool not [then branch] when`
* `while ( q -- ??)` - repeats words in quote while TOS equals boolean `true`, i.e. the last instruction in quote must put or modify boolean value on TOS which is then consumed by`while`
* `break` - stops evaluation of current quote (e.g. inside a `while` loop). On top level inside a file stops evaluation of file, on top level in interpreter stops evaluation of words behind `break`

<a name="words-namespaces">
### Namespaces
</a>

* `ns ( s -- )` - switches current namespace to `s`
* `ns? ( -- s )` - puts current namespace on TOS
* `ns-def? ( s -- bool )` - returns `true` if namespace `s` is defined (has words in the vocabulary)
* `ns-words ( s --  )` - prints all words that namespace `s` has
* `words` - prints words in current namespace
* `using ( q(s+) )` - makes listed namespaces "active", so that you do not have to type namespace before word
* `acitve-nss` - prints active namespaces
* `all-words` - prints all words in all namespaces

<a name="words-quitting">
### (Rage)Quitting
</a>

* `bye` - exits interpreter or finishes evaluation of a file
* `quit/with ( i -- )` - quits with `i` error code

<a name="words-real-world">
### Connections to real world
</a>

* `args` - puts on stack a quote with command line args (as strings)
* `read-line` - reads user input and places it on TOS
* `print ( v -- )` - prints the value of TOS
* `sleep ( i -- )` - holds execution for `i` number of seconds

<a name="words-modules">
### Modules
</a>
* `load ( s -- )` - loads neko bytecode-compiled file '`s`.n' and adds words in it into vocabulary

<a name="words-misc">
### Miscellaneous
</a>
*  `type? ( 1 -- s )` - puts on stack string representation of TOS value. Types start with "!" like "!String"


<a name="koneko-use">
## Koneko and how to use it
</a>

To be continued.
