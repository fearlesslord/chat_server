-module(chat_server_sup).
-behaviour(supervisor).

%% API
-export([start_link/0, init/1]).
-export([start_child/0]).

%% Start the supervisor
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% Initialize the supervisor
init([]) ->
    {ok, {
        {one_for_one, 5, 10},
        [] %% No children started by default
    }}.

%% Public API to start the chat server dynamically
start_child() ->
    ChildSpec = {
        chat_server,
        {chat_server, start, []},
        permanent,
        5000,
        worker,
        [chat_server]
    },
    supervisor:start_child(?MODULE, ChildSpec).