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
 Enter in rebar3 shell with command "rebar3 shell" and then
```bash
   chat_server:start().
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
## List of commands:
- ### Create a Room
Command: 
```bash  
/create_room <room_name> 
```

Example:
```bash
 /create_room room1 
 ```

- ###  Destroy a Room
Command: 
```bash  
/destroy_room <room_name>
```

Example:
```bash
 /destroy_room room1
 ```


- ### List All Rooms
Command: 
```bash  
/list_rooms
```

- ### Join a Room
Command: 
```bash  
/join_room <room_name>
```

Example:
```bash
 /join_room room1
 ```

- ### Leave a Room
Command: 
```bash  
/leave_room <room_name>
```

Example:
```bash
 /leave_room room1
 ```

- ###  Send a message to all users that have joiner to room
First you need to join to room and then send a message with command: 
```bash  
/msg <message>
```

Example:
```bash
 /msg Hello, everyone!
 ```


## 4. Test Multiple TCP Connections
### To test multiple concurrent chat clients, simply open additional terminals and repeat Step 3. Each new shell can run the client