rebar3_travis_plugin
====================

A rebar plugin mimicking `rebar3 do task1, task2`, adding [Travis CI](https://travis-ci.org) log fold marks.

Known Limitations
-----------------

- This is meant as a replacement for do, so you'd use `rebar3 travis clean, compile, eunit`, *NOT* `rebar3 travis do clean, compile, eunit` (the latter will only give you one fold, for `do`).
- Dependency tasks covered by rebar3 itself are not folded: if you run `rebar3 travis eunit`, and this does a `compile` first, you won't get folds.
- Duplicate tasks don't create unique folds: `rebar3 travis clean, clean, clean` will give you three identical fold marks.

Build
-----

    $ rebar3 compile

Use
---

Add the plugin to your rebar config:

    {plugins, [
        { rebar3_travis_plugin, {git, "https://github.com/srenatus/rebar3_travis_plugin.git", {branch, "master"}}}
    ]}.

Then just replace calls to `rebar3 do` with `rebar3 travis`, for example:

    $ env TRAVIS=1 rebar3 travis clean, compile, eunit

Note that jobs executed on Travis always have this environment variable set.
