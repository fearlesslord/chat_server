%%-----------------------------------------------------------------------------
%% File: chat_server.erl
%% Description: An Erlang/OTP server accepting multiple TCP connections.
%%-----------------------------------------------------------------------------
-module(chat_server).
-behaviour(gen_server).

%% External API
-export([start_link/0, stop/0]).

%% gen_server Callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(DEFAULT_PORT, 4040).

%%=============================================================================
%% Public API
%%=============================================================================
%% Starts the gen_server under a registered name (chat_server).
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Ask the gen_server to stop.
stop() ->
    gen_server:call(?MODULE, stop).

%%=============================================================================
%% gen_server callbacks
%%=============================================================================
init([]) ->
    %% Open a listening socket on DEFAULT_PORT
    {ok, ListenSocket} = gen_tcp:listen(?DEFAULT_PORT, [
        binary,
        {packet, 0},
        {reuseaddr, true},
        {active, false}
    ]),
    io:format("~p listening on port ~p~n", [?MODULE, ?DEFAULT_PORT]),

    %% Trigger the first accept in handle_info/2 by sending 'accept'
    self() ! accept,

    %% Return the ListenSocket as the gen_server's state
    {ok, ListenSocket}.

handle_call(stop, _From, ListenSocket) ->
    %% On 'stop' call, terminate the server gracefully
    {stop, normal, ok, ListenSocket};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(accept, ListenSocket) ->
    %% Accept a new client; on success, spawn a dedicated handler
    case gen_tcp:accept(ListenSocket) of
        {ok, ClientSocket} ->
            spawn(fun() -> handle_client(ClientSocket) end),
            %% Trigger another accept for the next client
            self() ! accept;
        {error, Reason} ->
            io:format("~p accept error: ~p~n", [?MODULE, Reason])
    end,
    {noreply, ListenSocket};

handle_info(_Info, State) ->
    %% Ignore any other messages
    {noreply, State}.

terminate(_Reason, ListenSocket) ->
    io:format("~p shutting down~n", [?MODULE]),
    gen_tcp:close(ListenSocket),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%=============================================================================
%% Client Handling (runs outside gen_server in separate spawned processes)
%%=============================================================================
handle_client(Socket) ->
    gen_tcp:send(Socket, <<"Enter your name: ">>),
    case gen_tcp:recv(Socket, 0) of
        {ok, NameBin} ->
            Name = fix_line_breaks(NameBin),
            io:format("User ~s connected~n", [Name]),
            chat_loop(Socket, Name);
        {error, closed} ->
            io:format("Client socket closed unexpectedly~n", [])
    end.

chat_loop(Socket, Name) ->
    WelcomeMsg = io_lib:format("Welcome, ~s! Type your messages below.~n", [Name]),
    gen_tcp:send(Socket, list_to_binary(WelcomeMsg)),
    receive_messages(Socket, Name).

receive_messages(Socket, Name) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Data} ->
            Msg = fix_line_breaks(Data),
            io:format("[~s] says: ~s~n", [Name, Msg]),

            %% Echo message back (optional):
            Echo = io_lib:format("You said: ~s~n", [Msg]),
            gen_tcp:send(Socket, list_to_binary(Echo)),

            %% Continue receiving more messages
            receive_messages(Socket, Name);

        {error, closed} ->
            io:format("User ~s disconnected~n", [Name]),
            ok
    end.

%% Utility: remove trailing \r or \n
fix_line_breaks(Data) ->
    string:trim(binary_to_list(Data)).
