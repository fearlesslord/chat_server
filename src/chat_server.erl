-module(chat_server).

%% API functions
-export([start/0, start/1, stop/1]).

%% Start the server
start() -> start(8080).
start(Port) ->
    io:format("Starting up chat server...~n"),
    %% Create a dictionary to hold all connections (usernames and sockets)
    ClientDict = dict:new(),
    %% Create a dictionary to hold room data
    RoomDict = dict:new(),
    %% Spawn a dictionary handler for inserts and lookups
    DictPid = spawn_link(fun() -> dict_handler(ClientDict, RoomDict) end),
    %% Hand over handling of listeners to listener module
    chat_listener:listen(Port, DictPid).

%% Dictionary handler for managing clients and rooms
dict_handler(ClientDict, RoomDict) ->
    receive
        %% Add a new client
		{add_new_client, Socket, Username} ->
			io:format("Adding user ~p~n", [Username]),
			NewClientDict = dict:store(Socket, #{username => Username, room => undefined}, ClientDict),
			dict_handler(NewClientDict, RoomDict);

        %% Get the socket for a username
        {get_client_socket, ReceiverPid, Username} ->
            case dict:find(Username, ClientDict) of
                {ok, Socket} ->
                    ReceiverPid ! {ok, Socket};
                error ->
                    ReceiverPid ! {error, "Client not found"}
            end,
            dict_handler(ClientDict, RoomDict);

        %% List all clients
        {get_all_clients, ReceiverPid} ->
            ClientNames = dict:fetch_keys(ClientDict),
            ReceiverPid ! {ok, ClientNames},
            dict_handler(ClientDict, RoomDict);

        %% Add a new room
		{create_room, RoomName, CreatorPid, CreatorSocket} ->
			case dict:is_key(RoomName, RoomDict) of
				true ->
					CreatorPid ! {error, "Room already exists"},
					dict_handler(ClientDict, RoomDict);
				false ->
					NewRoomDict = dict:store(RoomName, #{creator => CreatorSocket, members => lists:usort([CreatorSocket])}, RoomDict),
					CreatorPid ! {ok, "Room created"},
					dict_handler(ClientDict, NewRoomDict)
			end;

        %% Destroy a room (only the creator can destroy it)
        {destroy_room, RoomName, RequestorPid, RequestorSocket} ->
            case dict:find(RoomName, RoomDict) of
                {ok, Room} ->
                    case maps:get(creator, Room) of
                        RequestorSocket ->
                            NewRoomDict = dict:erase(RoomName, RoomDict),
                            RequestorPid ! {ok, "Room destroyed"},
                            dict_handler(ClientDict, NewRoomDict);
                        _ ->
                            RequestorPid ! {error, "Only the creator can destroy the room"},
                            dict_handler(ClientDict, RoomDict)
                    end;
                error ->
                    RequestorPid ! {error, "Room does not exist"},
                    dict_handler(ClientDict, RoomDict)
            end;

        %% List all rooms
        {list_rooms, RequestorPid} ->
            RoomNames = dict:fetch_keys(RoomDict),
            RequestorPid ! {ok, RoomNames},
            dict_handler(ClientDict, RoomDict);

        %% Join an existing room
		{join_room, RoomName, RequestorPid, RequestorSocket} ->
			case dict:find(RoomName, RoomDict) of
				{ok, Room} ->
					Members = maps:get(members, Room),
					UpdatedRoom = maps:put(members, [RequestorSocket | Members], Room),
					NewRoomDict = dict:store(RoomName, UpdatedRoom, RoomDict),
					%% Update the client's room in ClientDict
					ClientInfo = dict:fetch(RequestorSocket, ClientDict),
					UpdatedClientInfo = maps:put(room, RoomName, ClientInfo),
					UpdatedClientDict = dict:store(RequestorSocket, UpdatedClientInfo, ClientDict),
					RequestorPid ! {ok, "Joined room"},
					dict_handler(UpdatedClientDict, NewRoomDict);
				error ->
					RequestorPid ! {error, "Room does not exist"},
					dict_handler(ClientDict, RoomDict)
			end;

        %% Leave a room
        {leave_room, RoomName, RequestorPid, RequestorSocket} ->
            case dict:find(RoomName, RoomDict) of
                {ok, Room} ->
                    Members = maps:get(members, Room),
                    UpdatedRoom = maps:put(members, lists:delete(RequestorSocket, Members), Room),
                    NewRoomDict = dict:store(RoomName, UpdatedRoom, RoomDict),
                    RequestorPid ! {ok, "Left room"},
                    dict_handler(ClientDict, NewRoomDict);
                error ->
                    RequestorPid ! {error, "Room does not exist"},
                    dict_handler(ClientDict, RoomDict)
            end;

		%% Broadcast a message to all users in the room
		{broadcast_to_room, SenderSocket, Message} ->
			case dict:find(SenderSocket, ClientDict) of
				{ok, #{room := RoomName, username := Username}} when RoomName =/= undefined ->
					case dict:find(RoomName, RoomDict) of
						{ok, Room} ->
							Members = maps:get(members, Room),
							%% Ensure each socket gets the message only once
							UniqueMembers = lists:usort(Members),
							FormattedMessage = io_lib:format("[~s] ~s: ~s", [RoomName, Username, Message]),
							lists:foreach(fun(MemberSocket) ->
								gen_tcp:send(MemberSocket, term_to_binary(lists:flatten(FormattedMessage)))
							end, UniqueMembers),
							dict_handler(ClientDict, RoomDict);
						error ->
							gen_tcp:send(SenderSocket, term_to_binary({error, "Room does not exist"})),
							dict_handler(ClientDict, RoomDict)
					end;
				_ ->
					gen_tcp:send(SenderSocket, term_to_binary({error, "You are not in a room"})),
					dict_handler(ClientDict, RoomDict)
			end;

        %% Stop the server
        stop ->
            io:format("Stopping server...~n"),
            halt();

        %% Handle unexpected messages
        _ ->
            io:format("Unknown message received.~n"),
            dict_handler(ClientDict, RoomDict)
    end.

%% Stop the server
stop(Socket) ->
    io:format("Shutting down server on socket ~p~n", [Socket]),
    gen_tcp:close(Socket).

