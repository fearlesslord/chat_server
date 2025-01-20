-module(chat_client).
-define(TCP_OPTIONS, [binary, {packet, 2}, {active, false}, {reuseaddr, true}]).

%% API
-export([start/0, send/2, disconnect/1]).
-export([run/2, recv_loop/1]).

%% Start the client
start() ->
    %% Prompt the user for a username
    io:format("Enter your username: "),
    Username = string:strip(io:get_line(""), right, $\n),
    %% Connect to the chat server
    {ok, Socket} = gen_tcp:connect("localhost", 8080, ?TCP_OPTIONS),
    %% Join the chat
    chat_client:send(Socket, {join, Username}),
    io:format("~p joined the chat!~n", [Username]),
    %% Start the message receive loop in a separate process (only one process per client)
    spawn(chat_client, recv_loop, [Socket]),
    run(Socket, Username).

%% Interactive message loop
run(Socket, Username) ->
    io:format("Available commands: /msg, /create_room, /destroy_room, /list_rooms, /join_room, /leave_room, /exit~n"),
    Input = string:strip(io:get_line(""), right, $\n),
    case string:tokens(Input, " ") of
        %% Exit the chat
        ["/exit"] ->
            disconnect(Socket);

        %% Send a message
        ["/msg" | Rest] ->
            %% Log user input
            Message = string:join(Rest, " "),
            io:format("Sending to server: ~p~n", [{broadcast, Message}]),
            chat_client:send(Socket, {broadcast, Message}),
            run(Socket, Username);

        %% Create a room
        ["/create_room", RoomName] ->
            chat_client:send(Socket, {create_room, RoomName}),
            io:format("Requested to create room: ~p~n", [RoomName]),
            run(Socket, Username);

        %% Destroy a room
        ["/destroy_room", RoomName] ->
            chat_client:send(Socket, {destroy_room, RoomName}),
            io:format("Requested to destroy room: ~p~n", [RoomName]),
            run(Socket, Username);

        %% List all rooms
        ["/list_rooms"] ->
            chat_client:send(Socket, {list_rooms}),
            io:format("Requested to list all rooms.~n"),
            run(Socket, Username);

        %% Join a room
        ["/join_room", RoomName] ->
            chat_client:send(Socket, {join_room, RoomName}),
            io:format("Requested to join room: ~p~n", [RoomName]),
            run(Socket, Username);

        %% Leave a room
        ["/leave_room", RoomName] ->
            chat_client:send(Socket, {leave_room, RoomName}),
            io:format("Requested to leave room: ~p~n", [RoomName]),
            run(Socket, Username);

        %% Invalid command
        _ ->
            io:format("Invalid command. Use /msg, /create_room, /destroy_room, /list_rooms, /join_room, /leave_room, or /exit.~n"),
            run(Socket, Username)
    end.

%% Dedicated message receive loop (runs in a single process)
recv_loop(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Bin} ->
            Message = binary_to_term(Bin),
            %% Log received message
            case Message of
                String when is_list(String) ->
                    io:format("~s~n", [String]);
                _ ->
                    io:format("~p~n", [Message])
            end,
            %% Continue receiving messages
            recv_loop(Socket);
        {error, closed} ->
            io:format("Connection closed by the server.~n"),
            ok;
        {error, Reason} ->
            io:format("Error in connection: ~p~n", [Reason]),
            ok
    end.

%% Send a message
send(Socket, Message) ->
    Bin = term_to_binary(Message),
    gen_tcp:send(Socket, Bin).

%% Disconnect from the chat
disconnect(Socket) ->
    io:format("Disconnecting...~n"),
    gen_tcp:close(Socket),
    halt().
