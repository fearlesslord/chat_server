-module(dynamodb_client).

-export([ensure_tables_exist/0, put_item/3, get_item/2, delete_item/2, scan/1]).

%% Ensure required DynamoDB tables exist
ensure_tables_exist() ->
    create_table_if_not_exists("Users", [{"username", <<"S">>}], [{"username", "HASH"}], 5, 5),
    create_table_if_not_exists("Rooms", [{"room_name", <<"S">>}], [{"room_name", "HASH"}], 5, 5).

%% Create a table if it does not exist
create_table_if_not_exists(TableName, AttributeDefinitions, KeySchema, ReadCapacityUnits, WriteCapacityUnits) ->
    BinaryTableName = list_to_binary(TableName),
    case erlcloud_ddb1:describe_table(BinaryTableName) of
        {ok, _TableDetails} ->
            io:format("Table ~p already exists.~n", [TableName]),
            ok;
        {error, {<<"ResourceNotFoundException">>, _}} ->
            io:format("Table ~p does not exist. Creating it...~n", [TableName]),
            case erlcloud_ddb1:create_table(BinaryTableName, KeySchema, AttributeDefinitions, ReadCapacityUnits, WriteCapacityUnits) of
                {ok, _} ->
                    io:format("Table ~p created successfully.~n", [TableName]),
                    ok;
                {error, Reason} ->
                    io:format("Error creating table ~p: ~p~n", [TableName, Reason]),
                    {error, Reason}
            end;
        {error, Reason} ->
            io:format("Error describing table ~p: ~p~n", [TableName, Reason]),
            {error, Reason}
    end.

%% Put an item into a DynamoDB table
put_item(TableName, Key, Attributes) ->
    Item = maps:merge(Key, Attributes),
    case erlcloud_ddb1:put_item(TableName, Item) of
        {ok, _} ->
            io:format("Item inserted into table ~p: ~p~n", [TableName, Item]),
            ok;
        {error, Reason} ->
            io:format("Error inserting item into table ~p: ~p~n", [TableName, Reason]),
            {error, Reason}
    end.

%% Get an item from a DynamoDB table
get_item(TableName, Key) ->
    case erlcloud_ddb1:get_item(TableName, Key) of
        {ok, Response} ->
            Item = maps:get(item, Response, #{}),
            io:format("Retrieved item from table ~p: ~p~n", [TableName, Item]),
            {ok, Item};
        {error, Reason} ->
            io:format("Error retrieving item from table ~p: ~p~n", [TableName, Reason]),
            {error, Reason}
    end.

%% Delete an item from a DynamoDB table
delete_item(TableName, Key) ->
    case erlcloud_ddb1:delete_item(TableName, Key) of
        {ok, _} ->
            io:format("Item deleted from table ~p: ~p~n", [TableName, Key]),
            ok;
        {error, Reason} ->
            io:format("Error deleting item from table ~p: ~p~n", [TableName, Reason]),
            {error, Reason}
    end.

%% Scan a DynamoDB table for all items
scan(TableName) ->
    case erlcloud_ddb1:scan(TableName) of
        {ok, Response} ->
            Items = maps:get(items, Response, []),
            io:format("Scanned table ~p. Items: ~p~n", [TableName, Items]),
            {ok, Items};
        {error, Reason} ->
            io:format("Error scanning table ~p: ~p~n", [TableName, Reason]),
            {error, Reason}
    end.
