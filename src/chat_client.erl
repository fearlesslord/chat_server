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
    %% Display the available commands
    display_commands(),
    %% Start the message receive loop in a separate process
    spawn(chat_client, recv_loop, [Socket]),
    %% Enter the main input loop
    run(Socket, Username).

%% Interactive message loop
run(Socket, Username) ->
    Input = string:strip(io:get_line(""), right, $\n),
    case string:tokens(Input, " ") of
        ["/private_msg", RecipientUsername | Rest] ->
            Message = string:join(Rest, " "),
            io:format("Sending private message to ~p: ~p~n", [RecipientUsername, Message]),
            chat_client:send(Socket, {send_to, RecipientUsername, Message}),
            run(Socket, Username);

        ["/exit"] ->
            disconnect(Socket);

        ["/msg" | Rest] ->
            Message = string:join(Rest, " "),
            io:format("Sending message to the room: ~p~n", [Message]),
            chat_client:send(Socket, {broadcast, Message}),
            run(Socket, Username);

        ["/create_room", RoomName] ->
            io:format("Requested to create room: ~p~n", [RoomName]),
            chat_client:send(Socket, {create_room, RoomName}),
            run(Socket, Username);

        ["/create_private_room", RoomName] ->
            io:format("Requested to create private room: ~p~n", [RoomName]),
            chat_client:send(Socket, {create_private_room, RoomName}),
            run(Socket, Username);

        ["/invite_to_private_room", RoomName, InviteeUsername] ->
            io:format("Inviting ~p to private room ~p~n", [InviteeUsername, RoomName]),
            chat_client:send(Socket, {invite_to_private_room, RoomName, InviteeUsername}),
            run(Socket, Username);

        ["/destroy_room", RoomName] ->
            io:format("Requested to destroy room: ~p~n", [RoomName]),
            chat_client:send(Socket, {destroy_room, RoomName}),
            run(Socket, Username);

        ["/list_rooms"] ->
            io:format("Requested to list all rooms.~n"),
            chat_client:send(Socket, {list_rooms}),
            run(Socket, Username);

        ["/join_room", RoomName] ->
            io:format("Requested to join room: ~p~n", [RoomName]),
            chat_client:send(Socket, {join_room, RoomName}),
            run(Socket, Username);

        ["/join_private_room", RoomName] ->
            io:format("Requested to join private room: ~p~n", [RoomName]),
            chat_client:send(Socket, {join_private_room, RoomName}),
            run(Socket, Username);

        ["/leave_room", RoomName] ->
            io:format("Requested to leave room: ~p~n", [RoomName]),
            chat_client:send(Socket, {leave_room, RoomName}),
            run(Socket, Username);

        _ ->
            io:format("Invalid command. Use the commands listed below.~n"),
            display_commands(),
            run(Socket, Username)
    end.


%% Dedicated message receive loop (runs in a single process)
recv_loop(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Bin} ->
            Message = binary_to_term(Bin),
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

%% Display the available commands
display_commands() ->
    io:format("Available commands:\n"),
    io:format("  /msg <message>                      - Send a message to the current room.\n"),
    io:format("  /create_room <room_name>            - Create a public room.\n"),
    io:format("  /create_private_room <room_name>    - Create a private room.\n"),
    io:format("  /invite_to_private_room <room_name> <username> - Invite a user to a private room.\n"),
    io:format("  /destroy_room <room_name>           - Destroy a room you created.\n"),
    io:format("  /list_rooms                         - List all visible rooms.\n"),
    io:format("  /join_room <room_name>              - Join a public room.\n"),
    io:format("  /join_private_room <room_name>      - Join a private room (if invited).\n"),
    io:format("  /leave_room <room_name>             - Leave the current room.\n"),
    io:format("  /private_msg <username> <message>   - Send a private message to a user.\n"),
    io:format("  /exit                               - Exit the chat application.\n\n").

