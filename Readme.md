<a name="top">
# Koneko
</a>

Koneko is a toy project I started to understand how lexer and parser work. I'm sure I've made a lot of mistakes anyway. Also I like [NekoVM](http://nekovm.org) and I thought it would be good to have another language beside [Haxe](http://haxe.org/) that runs on NekoVM :3

The language itself is a wild mix of ideas from Forth, Factor, Joy and my own preferences. It is stack-based, imperative, interpreted programming (scripting?) language with Reverse Polish Notation.

The word "koneko" means "kitten" in japanese. :)

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

If you have a file named *Prelude.kn* in your current working directory, Koneko will load and interpret the contents of this file and add defintions from it to predefined _Prelude_ namespace. You can put there word definitions that you need the most or just find useful.

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
* `uc ( s -- s )` - converts string to uppercase (ASCII and utf-8 cyrillic only for now)
* `lc ( s -- s )` - converts string to lowercase (ASCII and utf-8 cyrillic only for now)
* `backw ( s --  s )` - reverses string
* `to-str ( s -- s )` - converts TOS to string
* `sub ( s i -- s )` - substring of string from position `i`
* `substr ( s i1 i2 -- s )` - substring of string `s` from position `i1`  with length `i2`
* `subrange (s i1 i2 -- s)` - substring of string `s` from position `i1` (including) to position `i2` (excluding)
* `string-length ( s -- i )` - returns length of string `s`
* `len? ( s -- i )` - alias for `string-length` in Prelude

[Back to top](#top)
<a name="words-chars">
### Chars (as Integers)
</a>

* `atc ( s i -- i )` - returns codepoint ('c' in 'atc') at position `i` in string `s` 
* `chr->str ( i -- s )` - converts char (int) to utf8 string
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
* `i ( v -- ? )` - evaluates value on TOS ( useful for quotes and atoms , everything else evaluatess to itself )

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
* `acitve-nss` - prints active namespaces
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

Actually these to invokations are equal:
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

Several `-e` phrases will be evaluated in the same interpreter, so you can defin a word in one `-e` block and it will be available in the following `-e` blocks.

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

Math in Koneko is just like math in every other language, in Reverse Polish Notaion. Nothing to see here. Move along.

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

Here we first check if `.sl` (stack length) is greater then 4 (which leaves boolean value of eigher -1 for `true`, or 0 for `false`), then we put the quote to evaluate `when` condition is `true`, and then call the word `when` itself.

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

`while` word expexts a quote on top of the stack, which it evaluates `while` the value on the stack after evaluation is `true` (non-zero). So the phrase itself must be conserned with exiting the loop.Also `while` can be used to create infinite loops with exit on `break`:

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

Work in progress.

[Back to top](#top)
<a name="working-with-strings">
### Char + Char = String?
</a>

Work in progress.

[Back to top](#top)
<a name="working-with-modules">
### Modules. The Why and The How
</a>

Work in progress.

