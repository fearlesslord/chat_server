-module(chat_server_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    case application:get_env(chat_server, start_server, false) of
        true ->
            %% DON’T directly start chat_server here
            %% chat_server:start_link(),  <-- remove this line

            {ok, _Pid} = supervisor:start_link(chat_server_sup, []),
            {ok, self()};
        false ->
            io:format("Client mode: Server not started.~n"),
            {ok, self()}
    end.

stop(_State) ->
    io:format("Application stopped.~n"),
    ok.
