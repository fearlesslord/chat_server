# Chat Server

## Description

- **Name**: `chat_server`
- **Objective**: Accept multiple TCP/IP client connections at the same time
- **Version**: OTP 25 (as per challenge requirement).

## Prerequisites

- Erlang/OTP (version 25 or later recommended)
- rebar3 (https://rebar3.org)

## Build Instructions

### 1. **Clone the Repository**
```bash
   git clone https://github.com/fearlesslord/chat_server.git
   cd chat_server
   rebar3 compile
```
### 2. **Start the Chat Server**
 Enter a rebar3 shell
```bash
   rebar3 shell --config config/server.config
```
## 3. **Start the Chat Client**
### Open a new terminal (leave the server running in the first one).
```bash
   rebar3 shell
``` 
###  Run the client:
```bash 
   chat_client:start().
```

## 4. Test Multiple TCP Connections
### To test multiple concurrent chat clients, simply open additional terminals and repeat Step 3. Each new shell can run the client