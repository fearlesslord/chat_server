-module(chat_listener).
-define(TCP_OPTIONS, [binary, {packet, 2}, {active, false}, {reuseaddr, true}]).

%% API
-export([listen/1]).

%% Start listening on a given port
listen(Port) ->
    {ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
    io:format("Listening on socket=~p~n", [LSocket]),
    accept(LSocket).

%% Accept new connections and spawn processes for each
accept(LSocket) ->
    {ok, Socket} = gen_tcp:accept(LSocket),
    spawn(fun() -> loop(Socket) end),
    accept(LSocket).

%% Main loop to handle incoming data
loop(Socket) ->
    inet:setopts(Socket, [{active, once}]),
    receive
        {tcp, Socket, Data} ->
            process_data(Socket, binary_to_term(Data)),
            loop(Socket);
        {tcp_closed, Socket} ->
            io:format("Client disconnected: ~p~n", [Socket]);
        {tcp_error, Socket, Reason} ->
            io:format("Socket error ~p: ~p~n", [Socket, Reason])
    end.

%% Process incoming commands
process_data(Socket, {join, Username}) ->
    UserData = #{username => Username, current_room => undefined},
    case dynamodb_client:put_item("Users", #{username => Username}, UserData) of
        ok ->
            io:format("User ~p joined the chat.~n", [Username]),
            send_message(Socket, {ok, "Welcome!"});
        {error, Reason} ->
            io:format("Error joining user ~p: ~p~n", [Username, Reason]),
            send_message(Socket, {error, Reason})
    end;

process_data(Socket, {create_room, RoomName}) ->
    RoomData = #{room_name => RoomName, creator => Socket, members => [Socket]},
    case dynamodb_client:put_item("Rooms", #{room_name => RoomName}, RoomData) of
        ok ->
            io:format("Room ~p created successfully.~n", [RoomName]),
            send_message(Socket, {ok, "Room created successfully"});
        {error, Reason} ->
            io:format("Error creating room ~p: ~p~n", [RoomName, Reason]),
            send_message(Socket, {error, Reason})
    end;

process_data(Socket, {destroy_room, RoomName}) ->
    case dynamodb_client:get_item("Rooms", #{room_name => RoomName}) of
        {ok, RoomData} ->
            case maps:get(creator, RoomData) of
                Socket ->
                    dynamodb_client:delete_item("Rooms", #{room_name => RoomName}),
                    send_message(Socket, {ok, "Room destroyed"});
                _ ->
                    send_message(Socket, {error, "Only the creator can destroy the room"})
            end;
        _ ->
            send_message(Socket, {error, "Room does not exist"})
    end;

process_data(Socket, {list_rooms}) ->
    case dynamodb_client:scan("Rooms") of
        {ok, Rooms} ->
            RoomNames = [maps:get(room_name, Room) || Room <- Rooms],
            send_message(Socket, {ok, RoomNames});
        {error, Reason} ->
            io:format("Error listing rooms: ~p~n", [Reason]),
            send_message(Socket, {error, Reason})
    end;

process_data(Socket, {join_room, RoomName}) ->
    case dynamodb_client:get_item("Rooms", #{room_name => RoomName}) of
        {ok, RoomData} ->
            Members = maps:get(members, RoomData),
            UpdatedRoomData = maps:put(members, [Socket | Members], RoomData),
            dynamodb_client:put_item("Rooms", #{room_name => RoomName}, UpdatedRoomData),
            send_message(Socket, {ok, "Joined room"});
        _ ->
            send_message(Socket, {error, "Room does not exist"})
    end;

process_data(Socket, {leave_room, RoomName}) ->
    case dynamodb_client:get_item("Rooms", #{room_name => RoomName}) of
        {ok, RoomData} ->
            Members = maps:get(members, RoomData),
            UpdatedRoomData = maps:put(members, lists:delete(Socket, Members), RoomData),
            dynamodb_client:put_item("Rooms", #{room_name => RoomName}, UpdatedRoomData),
            send_message(Socket, {ok, "Left room"});
        _ ->
            send_message(Socket, {error, "Room does not exist"})
    end;

process_data(Socket, {broadcast, Message}) ->
    case dynamodb_client:get_item("Users", #{username => Socket}) of
        {ok, #{current_room := RoomName}} when RoomName =/= undefined ->
            case dynamodb_client:get_item("Rooms", #{room_name => RoomName}) of
                {ok, RoomData} ->
                    Members = maps:get(members, RoomData),
                    FormattedMessage = io_lib:format("[~s] ~s: ~s", [RoomName, Socket, Message]),
                    lists:foreach(fun(Member) ->
                        gen_tcp:send(Member, term_to_binary(lists:flatten(FormattedMessage)))
                    end, Members),
                    send_message(Socket, {ok, "Message sent"});
                _ ->
                    send_message(Socket, {error, "Room does not exist"})
            end;
        _ ->
            send_message(Socket, {error, "You are not in a room"})
    end;

process_data(Socket, {send_to, RecipientUsername, Message}) ->
    case dynamodb_client:get_item("Users", #{username => RecipientUsername}) of
        {ok, _RecipientData} ->
            FormattedMessage = io_lib:format("[Private] ~s -> ~s: ~s", [Socket, RecipientUsername, Message]),
            gen_tcp:send(RecipientUsername, term_to_binary(lists:flatten(FormattedMessage))),
            send_message(Socket, {ok, "Private message sent"});
        _ ->
            send_message(Socket, {error, "User not found"})
    end;

process_data(Socket, _) ->
    send_message(Socket, {error, "Invalid command"}).

%% Helper function to send a response to the client
send_message(Socket, Message) ->
    gen_tcp:send(Socket, term_to_binary(Message)).
