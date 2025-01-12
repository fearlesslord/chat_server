%%-----------------------------------------------------------------------------
%% File: chat_client.erl
%% Description: Simple Erlang-based client for our chat_server.
%%-----------------------------------------------------------------------------
-module(chat_client).

-export([start/0, start/2]).

%%-----------------------------------------------------------------------------
%% 1) start/0: starts client with default host/port
%% 2) start/2: allows overriding host/port
%%-----------------------------------------------------------------------------

-define(DEFAULT_HOST, "localhost").
-define(DEFAULT_PORT, 4040).

%%--------------------------------------------------------------------
%% Public API
%%--------------------------------------------------------------------
%% Starts the chat client connecting to DEFAULT_HOST:DEFAULT_PORT.
start() ->
    start(?DEFAULT_HOST, ?DEFAULT_PORT).

%% Starts the chat client with a specified Host and Port.
start(Host, Port) ->
    io:format("Connecting to server at ~s:~p ...~n", [Host, Port]),
    case gen_tcp:connect(Host, Port, [binary, {active, false}]) of
        {ok, Socket} ->
            io:format("Connected. Type your messages below.~n", []),
            client_loop(Socket);
        {error, Reason} ->
            io:format("Failed to connect: ~p~n", [Reason]),
            {error, Reason}
    end.

%%--------------------------------------------------------------------
%% Internal Functions
%%--------------------------------------------------------------------

%% client_loop(Socket):
%% 1. Receive data from server (non-blocking approach).
%% 2. Prompt user for input.
%% 3. Send to server.
%% 4. Repeat until server closes or user quits.
client_loop(Socket) ->
    %% Step 1: Check for incoming data from server
    receive_server_data(Socket),

    %% Step 2: Prompt user in Erlang shell for next message
    Input = io:get_line("You> "),
    case Input of
        eof ->
            %% If user sends Ctrl+D (EOF), we exit
            io:format("Goodbye~n", []),
            gen_tcp:close(Socket),
            ok;
        _ ->
            %% Otherwise, we send the user’s text to the server
            gen_tcp:send(Socket, list_to_binary(Input)),
            %% Step 3: continue loop
            client_loop(Socket)
    end.

%% receive_server_data(Socket):
%% Try to read any data waiting on the socket. 
%% We give a short timeout so the client_loop can keep prompting the user.
receive_server_data(Socket) ->
    case gen_tcp:recv(Socket, 0, 100) of
        {ok, Data} ->
            io:format("Server: ~s", [Data]);
        {error, timeout} ->
            %% No data arrived within 100ms, do nothing
            ok;
        {error, closed} ->
            io:format("Server closed connection.~n", []),
            gen_tcp:close(Socket),
            %% Exit the client loop
            erlang:exit(normal)
    end.
