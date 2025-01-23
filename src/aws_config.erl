-module(aws_config).

-export([get_aws_options/0]).

%% Return AWS configuration options
get_aws_options() ->
    case os:getenv("ENVIRONMENT") of
        "production" ->
            #{aws_access_key_id => "prod_access_key",
              aws_secret_access_key => "prod_secret_key",
              aws_region => "us-east-1",
              ddb_host => "dynamodb.us-east-1.amazonaws.com",
              ddb_scheme => "https",
              ddb_port => 443};
        _ ->
            %% Default to local development
            #{aws_access_key_id => "local_access_key",
              aws_secret_access_key => "local_secret_key",
              aws_region => "us-east-1",
              ddb_host => "localhost",
              ddb_scheme => "http",
              ddb_port => 8000}
    end.