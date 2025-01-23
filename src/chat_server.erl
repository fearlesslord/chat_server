-module(chat_server).

%% API functions
-export([start/0, start/1, stop/1]).

%% Start the server
start() -> start(8080).
start(Port) ->
    io:format("Starting up chat server...~n"),
    
    %% Fetch configuration from aws_config
    Config = aws_config:get_aws_options(),    

    %% Apply the configuration using application:set_env
    application:set_env(erlcloud, aws_access_key_id, maps:get(aws_access_key_id, Config)),
    application:set_env(erlcloud, aws_secret_access_key, maps:get(aws_secret_access_key, Config)),
    application:set_env(erlcloud, aws_region, maps:get(aws_region, Config)),
    application:set_env(erlcloud, ddb_host, maps:get(ddb_host, Config)),
    application:set_env(erlcloud, ddb_scheme, maps:get(ddb_scheme, Config)),
    application:set_env(erlcloud, ddb_port, maps:get(ddb_port, Config)),
    
    application:set_env(erlcloud, ssl_opts, [{verify, verify_none}]),
    application:set_env(erlcloud, log_level, debug),
    application:ensure_all_started(lhttpc),
    application:ensure_all_started(erlcloud),

    dynamodb_client:ensure_tables_exist(),
    chat_listener:listen(Port).


%% Stop the server
stop(Socket) ->
    io:format("Shutting down server on socket ~p~n", [Socket]),
    gen_tcp:close(Socket).

