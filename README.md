# ob-raku

Org Babel functions for Raku evaluation.

## Installation

1. Download ob-raku.el and put it somewhere in your load path.
2. Add raku to the list of languages Babel can load:
```emacs-lisp
(org-babel-do-load-languages
	'org-babel-load-languages
	'((raku . t)))
```

## Caveats

* Sessions are not supported yet.
* Putting a `MAIN()` in won't automatically execute.
* Maybe other stuff?
