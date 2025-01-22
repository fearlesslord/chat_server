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
Then enter your username

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

 - ###  Send a Private Message
```bash  
/private_msg <username> <message>
```

Example:
```bash
 /private_msg username2 Hi, how are you?
 ```

## How to test private messaging:

### 1. Start the Server:
```bash
chat_server:start().
```

### 2. Start Two Clients 
```bash
chat_client:start().
```
Enter username: user1

- Start the second client:
```bash
chat_client:start().
```
Enter username: user2.

### 3. Send a Private Message:
- From user1, send a private message to user2
```bash
/private_msg user2 hi
```

Expected output on user2
```bash
[Private] user1 -> user2: hi
```

If you send a private message to a non-existent user you will receive:
```bash
Error: User user2 not found. Please check the username or ensure they are online.
```
_________________________________________

- ### Create a private room.
```bash  
/create_private_room <room_name> 
```
Example:
```bash  
/create_private_room private_room
```

- ### Invite a user to a private room.
```bash  
/invite_to_private_room <room_name> <username> - Invite a user to a private room.
```
Example:
```bash  
/invite_to_private_room private_room user2
```

- ### Join a private room (if invited).
```bash  
/join_private_room <room_name>      - Join a private room (if invited).
```  
Example:
```bash  
/join_private_room private_room
```

## 4. Test Multiple TCP Connections
### To test multiple concurrent chat clients, simply open additional terminals and repeat Step 3. Each new shell can run the client