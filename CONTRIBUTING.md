Send pull requests at <https://github.com/weakish/shattr>.

Coding style
------------

### Prefer `if . then . else .` to `. then . else .`

We feel `A then B else C` is confusing.

Readers may think `A then B else C` is `A ? B : C` in other languages, but they are **not the same**:

1. `A then B else C` is actually `(A then B) else C`:

	 * `A then B` evaluates to `B` if `A` is not `null`, otherwise evaluates to `null`.
	 * `X else Y` evaluates to `X` if `X` is not `null`, otherwise evaluates to `Y`.

2. Thus the type of `B` is `T given T satisfies Object`, i.e. requires to not be `null`.

I think `if (A) then B else C` is much cleaner.

### Only use `i++` to increase `i`.

`y=i++` and `y=++i` is really confusing to me.

So I prefer to only uses `i++` to increase `i`, e.g. in a while loop.
I think a meaningful evaluated value of `i++` should be `void`
if the a programming language allows `++`.

Same applies to `i--` and `--i`.

### Prefer functions to classes

We prefer to declare classes for new types (or type aliases).

### Pay attention to compiler warnings

[Some warnings][4285] are false positive, though.

[4285]: https://github.com/ceylon/ceylon/issues/4285#issuecomment-156661485

### Other

If you disagree the above, file an issue.

Send pull requests to add new coding style.

Please do not add formatting style, e.g. `use two spaces to indent`.
Formatting style dose not affect AST and thus is unlikely to affect readability of code,
and can be auto adjusted via `ceylon format` or other tools.
