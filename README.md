rebar3_travis_plugin
=====

A rebar plugin mimicking `rebar3 do task1, task2`, adding Travis log fold marks.

Known Limitations
-----------------

- not sure how people use rebar3 + do + namespaces
- replacement for do, so do `rebar3 travis clean, compile, eunit`, *NOT* `rebar3 travis do clean, compile, eunit`
- dependency tasks covered by rebar3 itself are not folded: if you run `rebar3 travis eunit`, and this does a `compile` first, you won't get folds.

Build
-----

    $ rebar3 compile

Use
---

Add the plugin to your rebar config:

    {plugins, [
        { rebar3_travis_plugin, ".*", {git, "https://github.com/srenatus/rebar3_travis_plugin.git", {tag, "0.1.0"}}}
    ]}.

Then just replace calls to `rebar3 do` with `rebar3 travis`, for example:

    $ rebar3 travis clean, compile, eunit
