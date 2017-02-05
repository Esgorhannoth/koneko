<a name="top">
# Koneko
</a>

Koneko is a toy project I started to understand how lexer and parser work. I'm sure I've made a lot of mistakes anyway. Also I like [NekoVM](http://nekovm.org) and I thought it would be good to have another language beside [Haxe](http://haxe.org/) that runs on NekoVM :3

The language itself is a wild mix of ideas from Forth, Factor, Joy and my own preferences. It is stack-based, imperative, interpreted programming (scripting?) language with Reverse Polish Notation.

The word "koneko" means "kitten" in Japanese. :)

## Table of contents

* [Building](#building)
* [Basics](#basics)
* [Interpreter](#interpreter)
* [Quotations](#quotations)
* [Word definitions](#definitions)
* [Namespaces](#namespaces)
* [All the words in the world are not enough](#words)
  * [Stack](#words-stack)
  * [Temporary stack](#words-temp-stack)
  * [Math](#words-math)
  * [String](#words-strings)
  * [Chars (as Integers)](#words-chars)
  * [Definitions](#words-definitions)
  * [Quotations](#words-quotations)
  * [Loops and branches](#words-loops-branches)
  * [Namespaces](#words-namespaces)
  * [Quitting](#words-quitting)
  * [Connections to real world](#words-real-world)
  * [Modules](#words-modules)
  * [Miscellaneous](#words-misc)
* [Koneko and how to use it](#koneko-use)
  * [Command line arguments](#cli-args)
  * [Working with the Stack](#working-with-the-stack)
  * [Temporary stack](#temporary-stack)
  * [Math in Koneko](#math-in-koneko)
  * [Quotes and you](#quotes-and-you)
  * [Working with loops and branches](#working-with-loops-and-branches)
  * [Space full of names](#working-with-namespaces)
  * [Char + Char = String?](#working-with-strings)
  * [Modules. The Why and The How](#working-with-modules)


<a name="building">
## Building
</a>

You will need Haxe 3.4 to build Koneko. It may build with earlier versions, but I have not tested it.

To build Koneko just run in shell:
```bash
$ cd somewhere-you-remember
$ git clone https://github.com/Esgorhannoth/koneko
$ cd koneko
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

[Back to top](#top)
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



[Back to top](#top)
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

[Back to top](#top)
<a name="quotations">
## Quotations
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


[Back to top](#top)
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


[Back to top](#top)
<a name="namespaces">
## Namespaces
</a>

Some words are just so good that we want to use them over and over. Like `open`. We can open a file, a socket, a door in a game. Naturally we want this `open` to behave differently, but we do not want the word to check what was passed to it via stack. Enter namespaces.

There are two namespaces that you'll have no matter what: _Builtin_ and _Main_. Builtin has all the words that are defined and written in Haxe. You cannot redefined words in Builtin namespace, but you can shadow them. Main is namespace created by the interpreter for you to define your own words and generally play around.

If you have a file named *Prelude.kn* in your current working directory, Koneko will load and interpret the contents of this file and add definitions from it to predefined _Prelude_ namespace. You can put there word definitions that you need the most or just find useful.

We'll see how to work with namespaces when we learn some new words.


[Back to top](#top)
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

[Back to top](#top)
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

[Back to top](#top)
<a name="words-temp-stack">
### Temporary stack
</a>

* `>t` - transfer value from main stack to temporary stack
* `<t` - transfer value from temporary stack to main stack
* `.t` - show contents of temporary stack
* `.tl` - puts number of items in temporary stack on top of main stack


[Back to top](#top)
<a name="words-math">
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

[Back to top](#top)
<a name="words-strings">
## Strings
</a>

* `at ( s i -- s )` - returns character at position `i`
* `uc ( s -- s )` - converts string to uppercase (ASCII and utf-8 Cyrillic only for now)
* `lc ( s -- s )` - converts string to lowercase (ASCII and utf-8 Cyrillic only for now)
* `backw ( s --  s )` - reverses string
* `to-str ( s -- s )` - converts TOS to string
* `sub ( s i -- s )` - substring of string from position `i`
* `substr ( s i1 i2 -- s )` - substring of string `s` from position `i1` with length `i2`
* `subrange (s i1 i2 -- s)` - substring of string `s` from position `i1` to position `i2` (both included)
* `string-length ( s -- i )` - returns length of string `s`
* `len? ( s -- i )` - alias for `string-length` in Prelude

[Back to top](#top)
<a name="words-chars">
### Chars (as Integers)
</a>

* `atc ( s i -- i )` - returns codepoint ('c' in 'atc') at position `i` in string `s` 
* `chr->str ( i -- s )` - converts char (int) to utf8 string
* `str->chars ( s -- q(i) )` - converts utf8 string to list (quote) of chars (ints)
* `chars->str ( q(i) -- s )` - converts list (quote) of chars to utf8 string
* `emit ( i -- )` - print character

[Back to top](#top)
<a name="words-definitions">
### Definitions
</a>

* `:`, `is!` - define new word, e.g. [ some words in quote ] : new-word
* `is` - careful definition, won't define word if it is already defined
* `def? ( q(a) -- bool )` - returns true (-1) if word in quote is defined, false (0) otherwise. There must be only one atom in quote!
* `see ( q(a+) -- )` - prints source code of words in quote, e.g. [ say len? ] see
* `undef ( q(a+) )` - undefines (erases from vocabulary) atoms listed in quote, e.g. [ say ] undef

[Back to top](#top)
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
* `i ( v -- ? )` - evaluates value on TOS ( useful for quotes and atoms , everything else evaluates to itself )

[Back to top](#top)
<a name="words-loops-branches">
### Loops and branches
</a>

* `if` - conditional evaluation: `bool [then branch] [else branch] if`
* `when` - like `if` without `else-branch`: `bool [then branch] when`
* `unless` - like `when` but with boolean condition negated: `bool [then branch] unless` is the same as `bool not [then branch] when` (in Prelude)
* `while ( q -- ??)` - repeats words in quote while TOS equals boolean `true`, i.e. the last instruction in quote must put or modify boolean value on TOS which is then consumed by`while`
* `break` - stops evaluation of current quote (e.g. inside a `while` loop). On top level inside a file stops evaluation of file, on top level in interpreter stops evaluation of words behind `break`
* `each ( q q -- ?? )` -  expects two quotes on the stack, first with values, second being phrase to apply to each value in the first quote. Result depends on words in the second quote. (in Prelude)

[Back to top](#top)
<a name="words-namespaces">
### Namespaces
</a>

* `ns ( s -- )` - switches current namespace to `s`
* `ns? ( -- s )` - puts current namespace on TOS
* `ns-def? ( s -- bool )` - returns `true` if namespace `s` is defined (has words in the vocabulary)
* `ns-words ( s --  )` - prints all words that namespace `s` has
* `words` - prints words in current namespace
* `using ( q(s+) )` - makes listed namespaces "active", so that you do not have to type namespace before word
* `active-nss` - prints active namespaces
* `all-words` - prints all words in all namespaces

[Back to top](#top)
<a name="words-quitting">
### (Rage)Quitting
</a>

* `bye` - exits interpreter or finishes evaluation of a file
* `quit/with ( i -- )` - quits with `i` error code

[Back to top](#top)
<a name="words-real-world">
### Connections to real world
</a>

* `args` - puts on stack a quote with command line args (as strings)
* `read-line` - reads user input and places it on TOS
* `print ( v -- )` - prints the value of TOS
* `sleep ( i -- )` - holds execution for `i` number of seconds
* `import ( s -- )` - loads `.kn` file and evaluates it

[Back to top](#top)
<a name="words-modules">
### Modules
</a>
* `load ( s -- )` - loads neko bytecode-compiled file '`s`.n' and adds words in it into vocabulary

[Back to top](#top)
<a name="words-misc">
### Miscellaneous
</a>
*  `type? ( 1 -- s )` - puts on stack string representation of TOS value. Types start with "!" like "!String"


[Back to top](#top)
<a name="koneko-use">
## Koneko and how to use it
</a>

In later examples I assume that you have one of this aliases:
```bash
$ alias koneko='neko path-to-koneko-dir/bin/koneko.n'
$ alias koneko='rlwrap neko path-to-koneko-dir/bin/koneko.n'
```

[Back to top](#top)
<a name="cli-args">
### Command line arguments
</a>

If you start Koneko with no args whatsoever, it will launch REPL (Read-Eval-Print-Loop) - a simple interactive shell to try some ideas and have some experiments.

If you provide filename(s), then they will be interpreted in order. **But be warned**, that they will be interpreted by the same interpreter, so words defined in the first file will be available in the second etc.

Actually these two invocations are equal:
```bash
$ koneko file1.kn file2.kn test.kn
$ koneko -f file1.kn --load file2.kn -f test.kn
```

Otherwise these flags are available:
`-f|--load <filename>` - eval file and exit
`-e|--eval 'koneko source'` - eval this line and exit
`-E|--Eval 'koneko source'` - eval this line in fresh interpreter and exit
`-n|--no-prelude` - do not load `Prelude.kn`
`-i|--repl` - start REPL after evaluation of all other flags

All flags preload `Prelude.kn` file from current working directory, if present. You can specify `-n` flag to prevent this.

Several `-e` phrases will be evaluated in the same interpreter, so you can define a word in one `-e` block and it will be available in the following `-e` blocks.

```bash
$ koneko -e '["*" print] is star ["\n" print] is nl' -f some-other-file.kn -e '[star] 5 times nl'
*****
$ _
```

`-E` flag, on the other hand, will start a new interpreter for each block.

```bash
$ koneko -E '["-" print] is dash' -f never-mind.kn -E '[dash] 5 times'
No such word "dash"
No such word "dash"
No such word "dash"
No such word "dash"
No such word "dash"
$ _
```

By default REPL will only start if no arguments are given, but with `-i` flag it will start anyway after evaluation of all files and `-e|-E` blocks. All defined words and namespaces from evaluated files and `-e` blocks will be available in the REPL.


[Back to top](#top)
<a name="working-with-the-stack">
### Working with the Stack
</a>

Being a Forth inspired language, Koneko uses neither variables nor "function parameters" - it uses the stack to hold and pass values around. (Of course nothing can stop you from defining a "const" namespace and creating words that hold just values in it. Hint, hint.)

Stack has this useful property that only the top item is available. To get to other items, you'll have to first remove the top item. Or have you?

Of course not. There are some basic stack-shuffling words, that allow you access to items other then the top.

One of them is `swap`. `swap` exchanges positions of two topmost items on the stack so that this next-to-top item is available for manipulation.

```forth
> 1 2 .s
<2> 1 2
> swap .s
<2> 2 1
```

`over` allows you to access this next-to-top item in other manner. It copies (`dup`licates, in a moment) next-to-top item *over* the top item and makes it available.

```forth
> 3 14 15 .s
<3> 3 14 15
> over .s
<4> 3 14 15 14
```

Actually `over` is just a case of more general `pick` word. `pick` gets integer number N from the stack and then `pick`s this Nth item from the stack. Index is 0-based, so `0 pick` will `pick` the top of the stack, `1 pick` will pick the item next-to-top (just like `over`), etc. Of course if there are not enough items to pick from, `Stack Underflow` will be thrown.

Almost all words in Koneko consume the item they get from the stack. So if you want to use one item for several words, you'll have to `dup` it several times.

```forth
> "Red Queen" .s
<1> "Red Queen"
> say
Red Queen
> len?
ERROR: Stack Underflow
```

Here `say` consumed the string and left `len?` with nothing to count. Let's correct this.

```forth
> "Red Queen" .s
<1> "Red Queen"
> dup say
Red Queen
> len? say
9
> _
```

Now that's better. By the way this `.s` word, as you have guessed, shows the stack (useful for debugging). There's also `.sl` (stack length) word, that puts on stack its length (useful for assertions).

Sometimes we do not need the item on top anymore, for whatever reason, and want it to disappear. Just `drop` it.

```forth
> .s
<1> "No one wants me anymore :("
> drop .s
<0>
> _
```

If you want to change your life and start over, then `clear-stack`.

```forth
> .s
<5> 'we' 'are' 3 'happy little' 'flies'
> clear-stack ( I do not need you all anymore )
> .s
<0>
> _
```

After all this cruelties let's finally look at two strange words: `rot` and `-rot`. They have nothing to do with rotting. All they do is just rotating three topmost stack elements. Better explained by example:

```forth
> 1 2 3 .s
<3> 1 2 3
> rot .s
<3> 2 3 1
> clear-stack
> 'diamond' 'dirt' 'leaves' .s
<3> "diamond" "dirt" "leaves"
> [rot] is dig
> ['Now I finally have the ' print print "!" say] is loot-and-be-rich
> dig .s
<3> "dirt" "leaves" "diamond"
> loot-and-be-rich
Now I finally have the diamond!
> _
```

Basically `rot` takes third item on the stack and puts it on top. `-rot` does exactly the opposite.

```forth
> 1 2 3 .s
<3> 1 2 3
> -rot
<3> 3 1 2
> [-rot] is hide
> 'dirt' 'leaves' 'diamond' .s
<6> 3 1 2 "dirt" "leaves" "diamond"
> hide .s
<6> 3 1 2 "diamond" "dirt" "leaves"
> "Now no one will ever find it." say
Now no one will ever find it.
> _
```

[Back to top](#top)
<a name="temporary-stack">
### Temporary stack
</a>

Temporary stack plays part of the role *return stack* plays in Forth. Sometimes Forth programmers use return stack to hold temporary values, while the mess with the main stack (data stack). Because Koneko words quite differently with words, return stack is not needed for "returning" but the idea of holding some values temporarily somewhere convenient is too good to pass. So here it is - temporary stack.

There are just a few words that work with it. `>t` to move top of the main stack to the temporary stack, `<t` to move it back, `.t` to print contents of the temporary stack (debugging) and `.tl` to put number of items in the temporary stack on top of the main stack. There is no word to clear drop or clear this stack, but if you ever need them, they are easily defined:

```forth
> [<t drop] is .tdrop
> [ [<t drop .tl] while ] is .tclear
```

[Back to top](#top)
<a name="math-in-koneko">
### Math in Koneko
</a>

Math in Koneko is just like math in every other language, in Reverse Polish Notation. Nothing to see here. Move along.

```forth
> 24 42 + say
66
> 44 4 - say
40
> 44 4 / say
11
> 30 3 * say
90
> 2 2 2 + * say
8
> 2 2 2 * + say
6
> 5.8 floor say
5
> 5.2 ceil say
6
> 5.4 round say
5
> 5.5 round say
6
> [ 20 random 1 + say ] is d20
> d20
4
> d20
18
> [ 20 random 1 + ] is! d20
> [ d20 dup say 18 >= ['Critical!' say] when ] 5 times
20
Critical!
12
20
Critical!
16
12
```

[Back to top](#top)
<a name="quotes-and-you">
### Quotes and you
</a>

"To be or not to be?" - that is a quote. The interpreter follows some simple rules while determining what to do with the input.

1. Is it a number/string? Put on stack.
2. Is it a known word? Eval it.
3. Throw error and run around waving hands otherwise.

But sometimes we need to put a word (or even a whole phrase) on the stack without it being actually evaluated (at least for now). Quotes come to the rescue. A quoted word/phrase will just sit on the stack waiting to be evaluated or passed as an argument to another word. For example, all branching and looping (more on them [later](#working-with-loops-and-branches)) constructions use quotes to determine what to do after the condition is met.

```forth
> ["=" print] 5 times
=====> true ['yay!' say] when
yay!
> _
```

To evaluate a quote sitting on top of the stack, use `i` word:

```forth
> ["99 bottles of beer sitting on the stack" say]
> .s
["99 bottles of beer sitting on the stack" say]
> i
99 bottles of beer sitting on the stack
> _
```

As quotes are not evaluated when they are put on the stack, you can put yet undefined words inside, potentially creating recursive words. This is how factorial may be defined:

```forth
> [ dup 1 - dup 0 = [drop] [fact *] if ] is fact
> 5 fact .
120 > _
```

Here we start with the number we want to get factorial of. Then we `dup`licate it to get next number. Then we check if this next number is zero. For the comparison not to consume the number that we still need we `dup`licate it too just before `0 =` phrase. Then `if` construction follows which expects `true`/`false` value, quote to evaluate on `true` and quote to evaluate on `false` in order. If the next number we get is zero, we just `drop` it and thus exit recursion. If it is not zero, `fact` calls itself again and then multiplies its own result with the number on top of the stack.

Calling sequence looks like that. Here Parentheses show how quotes are evaluated.

```forth
3 fact
3 2 (fact *)
3 2 1 ((fact *) *)
3 2 1 0 (((drop) *) *)
3 2 1 ((*) *)
3 2 (*)
6
```

Quotes have quite a handful of words that work on them. First of all there are 4 mnemonic words that add or remove elements of quotes: `>q`, `<q`, `q<`, `q>`. They visually remind you of what goes where and in what order. E.g. `>q` says that a value is pushed to the start of the quote, so the word expects to fined a value and a quote to push this value into on the stack.

```forth
> 5 [ 1 2 ] .s
<2> 5 [1 2]
> >q .s
<1> [5 1 2]

> clear-stack
> [ 1 2 ] 6 .s
<2> [1 2] 6
> q< .s
<1> [1 2 6]
```

`<q` and `q>` expect only quote to get value from - either from the start or from the end.

```forth
> [1 2 3] <q .s
<2> [2 3] 1

> clear-stack
> [1 2 3] q> .s
<2> [1 2] 3
```

You can get the length of a quote with `ql` word. As almost all Koneko words it consumes the value it is used on, so if you want to keep the quote, `dup`licate it first.

```forth
> [1 2 3 4] .s
<1> [1 2 3 4]
> dup ql .s
<2> [1 2 3 4] 4
> drop .s ql .s
<1> [1 2 3 4]
<1> 4
> _
```

You can create new quotes from the values on the stack with the word `quote`. It expects an integer number on the stack and then consumes this number of values from the stack, forming a new quote of them. If there are not enough values on the stack, Stack Underflow error is thrown and now values are consumed.

```forth
> 'Wolf' 'Pirky' 'Parky' 'Porky' .s
<4> 'Wolf' 'Pirky' 'Parky' 'Porky'
> 3 quote .s
<2> 'Wolf' ['Pirky' 'Parky' 'Porky']
> _
```

Of course you can `unquote` a list of values into values themselves.

```forth
> 1 5 range .s
<1> [1 2 3 4 5]
> unquote
<5> 1 2 3 4 5
> _
```

Quotes can also be `reverse`d and `concat`enated.

```forth
> ['Pigs' 'Little' 'Three'] reverse .s
<1> ['Three' 'Little' "Pigs"]
> ['Wolf'] .s
<2> ['Three' 'Little' "Pigs"] ['Wolf']
> concat
<1> ['Three' 'Little' "Pigs" 'Wolf']
> (oops) q> swap .s
<2> ['Wolf'] ['Three' 'Little' "Pigs"]
> _
```

[Back to top](#top)
<a name="working-with-loops-and-branches">
### Working with loops and branches
</a>

Branching in Koneko looks more like Joy, than Forth. Condition goes first, then one or two branches depending on word.

```forth
> .s
<0>
> .sl 4 > ['Busy stack!' say] when
> 1 2 3 4 5 .s
<5> 1 2 3 4 5
> .sl 4 > ['Busy stack!' say] when
Busy stack!
> _
```

Here we first check if `.sl` (stack length) is greater then 4 (which leaves boolean value of either -1 for `true`, or 0 for `false`), then we put the quote to evaluate `when` condition is `true`, and then call the word `when` itself.

`if` is similar to `when`, but has an *else* branch: `<cond -1|0> [then-branch] [else-branch] if`.

```Forth
> [false] is courage-of-men-failed?
> courage-of-men-failed? ['Good bye, Frodo'] ['It is not this day!'] if say
It is not this day!
> _
```

Loops allow you to repeat something the same thing over and over again while some condition is met. And unlike insanity things really can change while the loop is repeating.

Koneko has these basic looping words with some more in supplied *Prelude.kn* file:

```forth
> 5 [ dup say 1 - dup ] while
> [ "They're taking the hobbits to Isengard!" say ] 10000 times
```

`while` word expects a quote on top of the stack, which it evaluates `while` the value on the stack after evaluation is `true` (non-zero). So the phrase itself must be concerned with exiting the loop.Also `while` can be used to create infinite loops with exit on `break`:

```forth
> [ read-line dup 'quit' = [break] when say true ] while
```

This loop will echo what user typed until user types `quit`. That last `true` is needed for `while` as it checks the value on the stack after each iteration. Without `true` `while` will consume whatever is left on stack or throw Stack Underflow error it there's nothing to take.

`times` is useful, when you know how many times you need to repeat something. Its use is quite obvious. It takes a quote to repeat and number of times to repeat.

*Prelude.kn* has some more looping constructs. Namely `unless` and `each`. `unless` is just `when` with negated boolean condition. `each` is experimental and takes two quotes, first being the list of values and second being the phrase to repeat for each value.

```forth
> it-rains? [skate take outside go] unless
> [ 1 2 3 4 ] [ 1 + say ] each
2
3
4
5
> _
```

**Note**: With current implementation of `each` it is important that the elements are consumed one by one with each iteration of the phrase. Under the hood `each` just `unquote`s the list of values and repeats the phrase the number of `times` equal to the length of the list.


[Back to top](#top)
<a name="working-with-namespaces">
### Space full of names
</a>

As you already know, namespaces allow us to use the same string of characters for different actual words. Every time you start Koneko, you have at least two namespaces.

One, `Builtin`, is always available and you cannot remove or otherwise modify words in it. Words in `Builtin` namespace are actually written in Haxe.

The other available namespace is called `Main` by default. It's the namespace you define new words in Koneko. You can create many more namespaces and are not bound to use this `Main` namespace.

If you have a file named `Prelude.kn` in current working directory and have not instructed Koneko not to load it, it will be interpreted and words in it added to the interpreter in `Prelude` namespace.

Now let's learn what else you can do with namespaces. First of all, we need to know what namespace we are in now. This is done with `ns?` word. It puts current namespace name on top of the stack:

```forth
> ns? .
"Main" > _
```

To check if a namespace is defined at all, use `ns-def?` word:

```forth
> "Main" ns-def? .
0 > 'Builtin' ns-def? .
-1 > _
```

Here `Main` is undefined because we have not defined any words in it yet. Let's correct this:

```forth
> ns? .
"Main" > [ '!!' + ] is louder
> 'Now we have it' louder say
Now we have it!!
> 'Main' ns-def? .
-1 > _
```

That's better. Now let's create our own namespace for the first time. Namespaces are created (or switched) with `ns` word, which expects a string on the stack:

```forth
> 'fst' ns
> ns? .
"fst" > 'fst' ns-def? .
0 > [ '?' + ] is as-question
> 'fst' ns-def? .
-1 > _
```

To get a list of all words in current namespace use the word `words`. Use `ns-words` to get all words in any other namespace. It expects a string with namespace on top of the stack:

```forth
> (suppose we're still inside "fst" namespace) words
<ns:fst>   as-question
> 'Main' ns-words
<ns:Main>   louder
> _
```

There naturally arises a problem, that you can only use words that are in 'Builtin', 'Prelude' (if loaded) and current namespaces. Suppose we have a situation like this:

```forth
> ( words' implementation is not important here )
> 'file' ns
> [ name exists? create ] is new-file
> 'io' ns
> [ new-file copy-string] is write
> 'string to write' 'filename' write
No such word "new-file"
```

`new-file` is unreachable because while we are in `io` namespace, we have access only to `io`, `Prelude` and `Builtin` in this order. To use a word that is not in one of these namespaces, you must specify the namespace before the word with a colon:

```forth
> 'io' ns
> [ file:new-file copy-string ] is! write
```

But it is bad for two reasons: it's cumbersome and it couples `io:write` with `file:new-file`, so we cannot hot-swap `new-file` definition from e.g. another module. Luckily you can specify several namespaces to be used simultaneously with word `using`. Like this:

```forth
> ['file' 'io'] using
> 'file' ns [ name exists? create ] is new-file
> 'io' ns [ new-file copy-string ] is write
> 'string to write' 'filename' write
> _
```

What happens here is that we make both `file` and `io` namespaces active, and when interpreter does not fine `new-file` in current namespace (`io`), it searches for it in other active namespaces, right to left. Also you can specify just one namespace for `using` if need be. In that case just use a string, not a quote:

```forth
> 'Main' using 'Main' ns ns? .
"Main" > _
```

We switched to "Main" namespaces so that it's words are available after we stop using other namespaces.

There's a handy word that shows which namespaces are active now - `active-nss`:

```forth
> 'io' ns ( current NS is 'io' )
> ['file' 'io'] using
> active-nss
< using:  file  io >
> 'Main' using active-nss ( using 'Main', but 'io' is still our current NS, so it's listed )
< using:  Main io >
> 'Main' ns active-nss
< using:  Main >
```


[Back to top](#top)
<a name="working-with-strings">
### Char + Char = String?
</a>

Strings in Koneko use UTF-8 encoding. All words that use indices, index by codepoints, not individual bytes. String length show the number of visible glyphs too.

Core language supports quite a few words for working with strings. We'll start with `string-length` that has `Prelude` alias `len?`:

```forth
> 'I never asked for this' len? say
22
> "Параграф'78" len? say ( eight Cyrillic glyphs, an apostrophe, two digits, total eleven glyphs )
11
> _
```

You can switch letter case with `uc` for upper case and `lc` for lower case. Currently it works only for *ASCII* (codepoints 65-90, 97-122) and *Cyrillic* (codepoints 1025, 1040-1103, 1105) subsets of UTF-8:

```forth
> "big brown bear" uc say
BIG BROWN BEAR
> 'SMALL WORLD' lc say
small world
> "Нет судьбы кроме той, что мы творим сами" uc say ( there is no fate but what we make for ourselves )
НЕТ СУДЬБЫ КРОМЕ ТОЙ, ЧТО МЫ ТВОРИМ САМИ
```

If you need to loop through a string in reverse order, you can reverse a string with `backw`. Not a great name, I know.

```forth
> "idnalrednoW ni ecilA" backw say
Alice in Wonderland
> "седуч енартс в асилА" backw say
Алиса в стране чудес
```

You san `print` or `say` any value on the stack, but if you ever need a string representation of the value, you can use `to-str` word:

```forth
> [ 1 2 3 ] say
<Quote>
> [ 1 2 3 ] to-str say
[1 2 3]
```

To get a glyph at specific position in the string, use `at`. It expects a string and an integer on the stack. Indexing is 0-based:

```forth
> "Nothing is true" 3 at say
h
> "Шоколад" 0 at say
Ш
> "four" 5 at say
ERROR: Index out of bounds
```

There are three words to work with substrings: `sub`, `substr` and `subrange`. `sub` is the easiest to use, it just expects a string and a starting index (0-based) on the stack:

```forth
> "don't do it!" 6 sub say
do it!
```

You can think of the index as the number of symbols to drop from the start of the string.

`substr` is like `sub`, but it also expects the number of letters to take. If this number is greater than the length of the whole string, `substr` will work like `sub`, i.e. just return the letters from the starting position specified.

```forth
> 'four' 1 2 substr say
ou
> 'four' 1 23 substr say
our
```

Both index and length can be negative. For index it means that indexing is done from the end (-1 being the last letter), for length it means leftwards direction. Some examples are due;

```forth
> '123456789' 1 negate 1 substr say
9
> '123456789' 2 negate 1 substr say
8
> '123456789' 2 negate 2 substr say
89
> '123456789' 2 negate 2 negate substr say
78
> '123456789' 2 negate 4 negate substr say
5678
```

`subrange`, as the name implies, takes a string, a starting position index and an ending position index (both included). One or both indices can be negative. In that case the negative index is calculated from the end of the string (-1 being the last letter of the string). If starting index is greater than ending index, they are swapped.

```forth
> '123456789' 0 0 subrange say
1
> '123456789' 0 3 subrange say
1234
> '123456789' 1 0 subrange say
12
> '123456789' 3 0 subrange say
1234
> '123456789' 1 negate 0 subrange say
123456789
> '123456789' 1 negate 4 subrange say
56789
> '123456789' 2 negate 4 negate subrange say
678
```

Koneko allows working with individual characters as integer codepoints.

`atc` allows to get codepoint at specified index (0-based). `chr->str` converts integer codepoint on top of the stack to UTF-8 glyph. `chars->str` converts a list (quote) of integer codepoints to UTF-8 string and `str->chars` does it in reverse. `emit` prints integer codepoint as UTF-8 character.

```forth
> "Машина" 2 atc say
1096
> emit
ш> _
> "Машина" str->chars dup dup .
[1052 1072 1096 1080 1085 1072] > _
> [emit] each
Машина> _
> chars->str say
Машина
> _
```

[Back to top](#top)
<a name="working-with-modules">
### Modules. The Why and The How
</a>

Modules in Koneko allow adding functionality without recompiling the main interpreter. Under the hood a module is just a Haxe `.hx` file with a predefined class name `KonekoMod` and some static methods, that provide this additional functionality. The skeleton class looks like this:

```haxe
package koneko;


import koneko.Helpers as H;
import koneko.Typedefs;
// other needed imports here

// You are not bound to use koneko.Helpers, of course
// Actually you do not even need to import Typedefs, because
// the only thing used from the file is this typedef:

// typedef Voc = Map<String, Stack->StackItem>;

// But you'll still need Koneko sources for using other classes
// like Stack or StackItem



class KonekoMod {
  // we do not need to do anything special on initialization
  public function new() {}

  // this field provides the namespace for the exported words
  static var Namespace = "fs";

  // this method is called when the module is loaded
  // to actually get module's namespace
  public inline function get_namespace() {
    return Namespace;
  }

  // this method is called when the module is loaded
  // to get new words from the module
  public function get_words(): Voc // just for testing now
  {
    // create a new vocabulary (defined in Typedefs)
    var words = new Voc();
    // add words and corresponding functions to it
    // e.g.
    words.set("exists?", exists);
    words.set("exist?", exists);
    // 0.o seems that without calling .keys() this method is not created in neko bytecode at all
    // so just call it
    words.keys();
    return words;
  }

  // sample function
  public static function exists(s:Stack): StackItem {
    H.assert_has_one(s);
    var name = H.unwrap_string( s.pop() );
    if( FileSystem.exists(name) )
      s.push( IntSI( -1 ) ); // true
    else
      s.push( IntSI( 0 ) );  // false
    return Noop;
  }
}
```


All functions inside a module must accept Stack and return StackItem (most of the time just `Noop`)

To build a Koneko module do not specify `-main` flag to haxe:

```bash
$ haxe koneko.ModFileName -neko <load-name>.n
```

Some clarification is needed I guess: **All** files with modules must have KonekoMod class, otherwise NekoVM loader won't find it. But you still can save it with different, meaningful name, like FileSystemMod.hx. This name (with koneko package) you give to `haxe` on the command line. `load-name` is the name that is used by `load`.

E.g. you have a KonekoMod class, that works with sockets. You save it in file named 'SocketsMod.hx' and build it like this:

```bash
$ haxe koneko.SocketsMod -neko sockets.n
```

Then you `load` it in the interpreter:

```forth
> 'sockets' load
> _
```


