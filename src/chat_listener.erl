-module(chat_listener).
-define(TCP_OPTIONS, [binary, {packet, 2}, {active, false}, {reuseaddr, true}]).
%% ====================================================================
%% API functions
%% ====================================================================
-export([listen/2]).

listen(Port, DictPid) ->
		% create a listener on a listening socket
		{ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
	
		% create an accept loop that waits for connections on this listening socket
		spawn_link(fun() -> accept(LSocket, DictPid) end),
		io:format("Listening on socket=~p~n", [LSocket]).
		
% loop accepts incoming connection, and then creates a new
	% process to handle the incoming packet
accept(LSocket, DictPid) ->
	{ok, Socket} = gen_tcp:accept(LSocket),
	Pid = spawn(fun() ->
					io:format("Connection accepted~n", []),
					loop(Socket, DictPid)
				end),
	gen_tcp:controlling_process(Socket, Pid),
	accept(LSocket, DictPid).

% this handler func will take the data, figure out which action needs done
% format it appropriately, and then call a send function to whoever
loop(Sock, DictPid) ->
	
	% in order to use this {tcp, socket, data} syntax, must be temp set to active
	inet:setopts(Sock, [{active, once}]),
	
	%define the format of connection data that accept will handle
	receive
		{tcp, Socket, Data} ->
			
			% figure out the data and what action needs done, and then 
			% send this info to the client dictionary to finish
			ProcessedData = process_data(Socket, Data, DictPid),
			
			% echo this back to the sender
			send_message(Socket, ProcessedData), 
			
			%repeat!
			loop(Socket, DictPid);
		
		% handling for if socket is closed
		{tcp_closed, Socket} ->
				io:format("~p left.~n", [Socket]);
		
		%handling for if there's an error
		{tcp_error, Socket, Reason} ->
				io:format("Error on socket ~p, Reason: ~p~n", [Socket, Reason])
		end.

%assumes the data will be sent as binary - possible add checking for stringss
% these handle all of the client actions, just sending a message to the group,
% or sending a message to an individual
process_data(Socket, Data, DictPid) ->
    case binary_to_term(Data) of
        %% Join the chat
        {join, Username} ->
            DictPid ! {add_new_client, Socket, Username},
            io:format("~p joined the chat.~n", [Username]),
            send_message(Socket, {ok, "Welcome!"});

        %% Create a room
        {create_room, RoomName} ->
            DictPid ! {create_room, RoomName, self(), Socket},
            receive
                {ok, Response} -> send_message(Socket, {ok, Response});
                {error, Reason} -> send_message(Socket, {error, Reason})
            end;

        %% Destroy a room
        {destroy_room, RoomName} ->
            DictPid ! {destroy_room, RoomName, self(), Socket},
            receive
                {ok, Response} -> send_message(Socket, {ok, Response});
                {error, Reason} -> send_message(Socket, {error, Reason})
            end;

        %% List all rooms
        {list_rooms} ->
            DictPid ! {list_rooms, self()},
            receive
                {ok, RoomNames} -> send_message(Socket, {ok, RoomNames})
            end;

        %% Join a room
        {join_room, RoomName} ->
            DictPid ! {join_room, RoomName, self(), Socket},
            receive
                {ok, Response} -> send_message(Socket, {ok, Response});
                {error, Reason} -> send_message(Socket, {error, Reason})
            end;

        %% Leave a room
        {leave_room, RoomName} ->
            DictPid ! {leave_room, RoomName, self(), Socket},
            receive
                {ok, Response} -> send_message(Socket, {ok, Response});
                {error, Reason} -> send_message(Socket, {error, Reason})
            end;

		%% Send a message to all users in the same room
		{broadcast, Message} ->
			DictPid ! {broadcast_to_room, Socket, Message},
			send_message(Socket, {ok, "Message broadcasted to your room"});

        %% Invalid command
        _ ->
            send_message(Socket, {error, "Invalid command"})
    end.

	send_message(Socket, Message) ->
		gen_tcp:send(Socket, term_to_binary(Message)).