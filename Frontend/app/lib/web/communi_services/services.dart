import 'dart:async';

import 'package:app/constant/Server_Database.dart';
import 'package:get/get.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

class SignalRService extends GetxService {
  HubConnection? connection;

  bool IsSignalRConnected = false;
  bool IsSignalRConnecting = false;

  // Reactive online-user list for ChatScreen.
  final RxSet<int> OnlineUserNumbers = <int>{}.obs;

  // Call signaling is pushed here so MessageScreenGetx can listen.
  final StreamController<Map<String, dynamic>> CallEvents =
  StreamController<Map<String, dynamic>>.broadcast();

  void _emitCall(String type, dynamic payload) {
    try {
      if (payload is Map) {
        CallEvents.add({...Map<String, dynamic>.from(payload), 'type': type});
      }
    } catch (e) {
      print('Emit call event error: $e');
    }
  }

  Future<void> ConnectSignalR({required String User_JwtToken}) async {
    try {
      if (User_JwtToken.trim().isEmpty) {
        print('SignalR: JWT token is missing.');
        return;
      }

      if (IsSignalRConnected || IsSignalRConnecting) {
        print('SignalR is already connected or connecting.');
        return;
      }

      IsSignalRConnecting = true;

      connection = HubConnectionBuilder()
          .withUrl(
            Backend_Server_Url+'chatHub',
            options: HttpConnectionOptions(
              accessTokenFactory: () async => User_JwtToken,
            ),
          )
          .withAutomaticReconnect()
          .build();

      // Register events BEFORE starting the connection.
      ListenForOnlineUsers();
      ListenForChatMessages();
      ListenForVideoCalls();

      connection!.onclose(({error}) {
        try {
          IsSignalRConnected = false;
          IsSignalRConnecting = false;
          OnlineUserNumbers.clear();

          print('SignalR connection closed: $error');
        } catch (e) {
          print('SignalR onclose callback error: $e');
        }
      });

      connection!.onreconnecting(({error}) {
        try {
          IsSignalRConnected = false;
          print('SignalR reconnecting: $error');
        } catch (e) {
          print('SignalR reconnect callback error: $e');
        }
      });

      connection!.onreconnected(({connectionId}) {
        try {
          IsSignalRConnected = true;
          IsSignalRConnecting = false;

          print('SignalR reconnected: $connectionId');
          // The server runs OnConnectedAsync again for the new connection.
        } catch (e) {
          print('SignalR reconnected callback error: $e');
        }
      });

      await connection!.start();

      IsSignalRConnected = true;
      print('SignalR connected successfully.');
    } catch (e) {
      IsSignalRConnected = false;
      print('SignalR connection error: $e');

      try {
        await connection?.stop();
      } catch (stopError) {
        print('SignalR cleanup error: $stopError');
      }

      connection = null;
    } finally {
      IsSignalRConnecting = false;
    }
  }

  // ONLINE / OFFLINE EVENTS

  void ListenForOnlineUsers() {
    try {
      connection?.on('OnlineUsers', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;

          final data = arguments[0];

          if (data is List) {
            final Set<int> parsedUsers = {};

            for (final item in data) {
              final userNumber = int.tryParse(item.toString());

              if (userNumber != null) {
                parsedUsers.add(userNumber);
              }
            }

            OnlineUserNumbers.assignAll(parsedUsers);
            print('Online users: $OnlineUserNumbers');
          }
        } catch (e) {
          print('OnlineUsers event error: $e');
        }
      });

      connection?.on('UserOnline', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;

          final userNumber = int.tryParse(arguments[0].toString());

          if (userNumber != null) {
            OnlineUserNumbers.add(userNumber);
          }

          print('User online: $userNumber');
        } catch (e) {
          print('UserOnline event error: $e');
        }
      });

      connection?.on('UserOffline', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;

          final userNumber = int.tryParse(arguments[0].toString());

          if (userNumber != null) {
            OnlineUserNumbers.remove(userNumber);
          }

          print('User offline: $userNumber');
        } catch (e) {
          print('UserOffline event error: $e');
        }
      });
    } catch (e) {
      print('Online listener setup error: $e');
    }
  }

  // REAL-TIME CHAT EVENT

  void ListenForChatMessages() {
    try {
      connection?.on('ReceiveMessage', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;

          print('Real-time message received: ${arguments[0]}');

          // ChatMessageScreen will consume this event later.
        } catch (e) {
          print('ReceiveMessage event error: $e');
        }
      });
    } catch (e) {
      print('Chat listener setup error: $e');
    }
  }

  // VIDEO CALL SIGNALING EVENTS

  void ListenForVideoCalls() {
    try {
      connection?.on('IncomingCall', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;
          _emitCall('IncomingCall', arguments[0]);
        } catch (e) {
          print('IncomingCall event error: $e');
        }
      });

      connection?.on('CallAnswer', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;
          _emitCall('CallAnswer', arguments[0]);
        } catch (e) {
          print('CallAnswer event error: $e');
        }
      });

      connection?.on('IceCandidate', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;
          _emitCall('IceCandidate', arguments[0]);
        } catch (e) {
          print('IceCandidate event error: $e');
        }
      });

      connection?.on('CallEnded', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;
          _emitCall('CallEnded', arguments[0]);
        } catch (e) {
          print('CallEnded event error: $e');
        }
      });
    } catch (e) {
      print('Video call listener setup error: $e');
    }
  }



  // Send a real-time notification AFTER your REST API saves the message.
  Future<void> NotifyNewMessage({
    required int ReceiverNumber,
    required int ChatId,
    required String Message,
    required String StoreAt,
  }) async {
    try {
      if (!IsSignalRConnected || connection == null) {
        print('Cannot notify recipient: SignalR is disconnected.');
        return;
      }

      await connection!.invoke(
        'NotifyNewMessage',
        args: [ReceiverNumber, ChatId, Message, StoreAt],
      );
    } catch (e) {
      print('SignalR message notification error: $e');
    }
  }

  // VIDEO SIGNALING METHODS

  Future<void> SendCallOffer({
    required int ReceiverNumber,
    required String CallId,
    required Map<String, dynamic> Offer,
  }) async {
    try {
      if (!IsSignalRConnected || connection == null) return;

      await connection!.invoke(
        'SendCallOffer',
        args: [ReceiverNumber, CallId, Offer],
      );
    } catch (e) {
      print('Send call offer error: $e');
    }
  }

  Future<void> SendCallAnswer({
    required int ReceiverNumber,
    required String CallId,
    required Map<String, dynamic> Answer,
  }) async {
    try {
      if (!IsSignalRConnected || connection == null) return;

      await connection!.invoke(
        'SendCallAnswer',
        args: [ReceiverNumber, CallId, Answer],
      );
    } catch (e) {
      print('Send call answer error: $e');
    }
  }

  Future<void> SendIceCandidate({
    required int ReceiverNumber,
    required String CallId,
    required Map<String, dynamic> Candidate,
  }) async {
    try {
      if (!IsSignalRConnected || connection == null) return;

      await connection!.invoke(
        'SendIceCandidate',
        args: [ReceiverNumber, CallId, Candidate],
      );
    } catch (e) {
      print('Send ICE candidate error: $e');
    }
  }

  Future<void> EndVideoCall({
    required int ReceiverNumber,
    required String CallId,
  }) async {
    try {
      if (!IsSignalRConnected || connection == null) return;

      await connection!.invoke('EndVideoCall', args: [ReceiverNumber, CallId]);
    } catch (e) {
      print('End video call error: $e');
    }
  }

  Future<void> DisconnectSignalR() async {
    try {
      final currentConnection = connection;

      connection = null;
      IsSignalRConnected = false;
      IsSignalRConnecting = false;
      OnlineUserNumbers.clear();

      if (currentConnection != null) {
        await currentConnection.stop();
      }

      print('SignalR disconnected.');
    } catch (e) {
      print('SignalR disconnect error: $e');
    } finally {
      IsSignalRConnected = false;
      IsSignalRConnecting = false;
    }
  }
}
