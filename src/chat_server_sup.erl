%% File: src/chat_server_sup.erl
-module(chat_server_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    ServerChild = {
        chat_server_proc,
        {chat_server, start_link, []},
        permanent,
        5000,
        worker,
        [chat_server]
    },
    {ok, {{one_for_one, 0, 1}, [ServerChild]}}.
