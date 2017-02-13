-module(rebar3_travis_plugin_prv).

%% Heavily based on rebar_prv_do.erl of rebar3

-export([init/1, do/1, format_error/1]).

-define(PROVIDER, travis).
-define(DEPS, []).

%% ===================================================================
%% Public API
%% ===================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    State1 = rebar_state:add_provider(State, providers:create([{name, ?PROVIDER},
                                                               {module, ?MODULE},
                                                               {bare, true},
                                                               {deps, ?DEPS},
                                                               {example, "rebar3 travis <task1>, <task2>, ..."},
                                                               {short_desc, "Provider for running multiple tasks in a sequence with travis fold markers."},
                                                               {desc, "Higher order provider for running multiple tasks in a sequence with travis fold markers."},
                                                               {opts, []}
                                                              ])),
    {ok, State1}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    case rebar_utils:args_to_tasks(rebar_state:command_args(State)) of
        [] ->
            AllProviders = rebar_state:providers(State),
            Namespace = rebar_state:namespace(State),
            Providers = providers:get_providers_by_namespace(Namespace, AllProviders),
            providers:help(Providers),
            {ok, State};
        Tasks ->
            do_tasks(Tasks, State)
    end.

do_tasks([], State) ->
    {ok, State};
do_tasks([{TaskStr, Args}|Tail], State) ->
    Task = list_to_atom(TaskStr),
    State1 = rebar_state:set(State, task, Task),
    State2 = rebar_state:command_args(State1, Args),
    Namespace = rebar_state:namespace(State2),
    case Namespace of
        default ->
            %% The first task we hit might be a namespace!
            case maybe_namespace(State2, Task, Args) of
                {ok, FinalState} when Tail =:= [] ->
                    {ok, FinalState};
                {ok, _} ->
                    do_tasks(Tail, State);
                {error, Reason} ->
                    {error, Reason}
            end;
        _ ->
            %% We're already in a non-default namespace, check the
            %% task directly.
            case wrap_process_command(State2, Task) of
                {ok, FinalState} when Tail =:= [] ->
                    {ok, FinalState};
                {ok, _} ->
                    do_tasks(Tail, State);
                {error, Reason} ->
                    {error, Reason}
            end
    end.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

maybe_namespace(State, Task, Args) ->
    case rebar_core:process_namespace(State, Task) of
        {ok, State2, Task} ->
            %% The task exists after all.
            wrap_process_command(State2, Task);
        {ok, State2, do} when Args =/= [] ->
            %% We are in 'do' so we can't apply it directly.
            [NewTaskStr | NewArgs] = Args,
            NewTask = list_to_atom(NewTaskStr),
            State3 = rebar_state:command_args(State2, NewArgs),
            wrap_process_command(State3, NewTask);
        {ok, _, _} ->
            %% No arguments to consider as a command. Woops.
            {error, io_lib:format("Command ~p not found", [Task])};
        {error, Reason} ->
            {error, Reason}
    end.

wrap_process_command(State, Task) ->
    travis_start(Task),
    Ret = rebar_core:process_command(State, Task),
    travis_end(Task),
    Ret.

travis_start(Str) ->
    travis_fold("start", Str, os:getenv("TRAVIS")).

travis_end(Str) ->
    travis_fold("end", Str, os:getenv("TRAVIS")).

travis_fold(_, _, false) ->
    ok;
travis_fold(Evt, Task,  _) ->
    io:format("travis_fold:~s:rebar3_~s~n", [Evt, Task]).
