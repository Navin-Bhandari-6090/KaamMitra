import 'dart:async';
import 'dart:math' as math;

import 'package:app/constant/Server_Database.dart';
import 'package:get/get.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

// =============================================================================
// SIGNALR SERVICE (permanent, one per app)
//  - connects once after login and reconnects by itself with back-off
//  - pushes chat events to ChatEvents and call events to CallEvents
//  - every method the old screens used is still here
// =============================================================================
class SignalRService extends GetxService {
  HubConnection? connection;

  bool IsSignalRConnected = false;
  bool IsSignalRConnecting = false;

  // Reactive mirror of IsSignalRConnected (screens listen to this).
  final RxBool IsConnectedRx = false.obs;

  // Reactive online-user list.
  final RxSet<int> OnlineUserNumbers = <int>{}.obs;

  // Call signaling.
  final StreamController<Map<String, dynamic>> CallEvents =
  StreamController<Map<String, dynamic>>.broadcast();

  // Chat events. 'type' is one of:
  //   ReceiveMessage    a full message pushed by the server
  //   MessagesRead      the other person read my messages
  //   ConversationRead  I read a chat (from another tab / device)
  //   Reconnected       the connection is up (again): refetch what was missed
  final StreamController<Map<String, dynamic>> ChatEvents =
  StreamController<Map<String, dynamic>>.broadcast();

  String _jwt = '';
  bool _manualClose = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;

  void _setConnected(bool value) {
    IsSignalRConnected = value;
    if (IsConnectedRx.value != value) IsConnectedRx.value = value;
  }

  void _emitCall(String type, dynamic payload) {
    try {
      if (payload is Map) {
        CallEvents.add({...Map<String, dynamic>.from(payload), 'type': type});
      }
    } catch (e) {
      // print('Emit call event error: $e');
    }
  }

  void _emitChat(String type, dynamic payload) {
    try {
      final Map<String, dynamic> data = payload is Map
          ? Map<String, dynamic>.from(payload)
          : <String, dynamic>{};
      ChatEvents.add({...data, 'type': type});
    } catch (e) {
      // print('Emit chat event error: $e');
    }
  }

  // Retry after 2, 4, 8, 15, then every 30 seconds, until connected.
  void _scheduleReconnect() {
    try {
      if (_manualClose || _jwt.isEmpty) return;
      if (_retryTimer?.isActive == true) return;

      const List<int> delays = [2, 4, 8, 15, 30];
      final int seconds = delays[math.min(_retryAttempt, delays.length - 1)];
      _retryAttempt++;

      _retryTimer = Timer(Duration(seconds: seconds), () {
        if (_manualClose) return;
        ConnectSignalR(User_JwtToken: _jwt);
      });
    } catch (e) {
      // print('SignalR schedule reconnect error: $e');
    }
  }

  Future<void> ConnectSignalR({required String User_JwtToken}) async {
    try {
      if (User_JwtToken.trim().isEmpty) {
        // print('SignalR: JWT token is missing.');
        return;
      }

      _jwt = User_JwtToken;
      _manualClose = false;

      if (IsSignalRConnected || IsSignalRConnecting) {
        // print('SignalR is already connected or connecting.');
        return;
      }

      IsSignalRConnecting = true;
      _retryTimer?.cancel();

      final HubConnection hub = HubConnectionBuilder()
          .withUrl(
        Backend_Server_Url + 'chatHub',
        options: HttpConnectionOptions(
          accessTokenFactory: () async => _jwt,
        ),
      )
          .withAutomaticReconnect()
          .build();

      connection = hub;

      // Register events BEFORE starting the connection.
      ListenForOnlineUsers();
      ListenForChatMessages();
      ListenForVideoCalls();

      hub.onclose(({error}) {
        try {
          // Ignore callbacks of an old, already replaced connection.
          if (!identical(connection, hub)) return;

          _setConnected(false);
          IsSignalRConnecting = false;
          OnlineUserNumbers.clear();
          connection = null;

          // print('SignalR connection closed: $error');
          _scheduleReconnect();
        } catch (e) {
          // print('SignalR onclose callback error: $e');
        }
      });

      hub.onreconnecting(({error}) {
        try {
          _setConnected(false);
          // print('SignalR reconnecting: $error');
        } catch (e) {
          // print('SignalR reconnecting callback error: $e');
        }
      });

      hub.onreconnected(({connectionId}) {
        try {
          _setConnected(true);
          IsSignalRConnecting = false;
          _retryAttempt = 0;

          // print('SignalR reconnected: $connectionId');
          // Messages may have arrived while disconnected.
          _emitChat('Reconnected', null);
        } catch (e) {
          // print('SignalR reconnected callback error: $e');
        }
      });

      await hub.start();

      _setConnected(true);
      _retryAttempt = 0;

      // Every successful connect asks the screens to refetch once. That also
      // covers messages that arrived between the first page load and now.
      _emitChat('Reconnected', null);

      // print('SignalR connected successfully.');
    } catch (e) {
      // print('SignalR connection error: $e');
      _setConnected(false);

      try {
        await connection?.stop();
      } catch (stopError) {
        // print('SignalR cleanup error: $stopError');
      }

      connection = null;
      _scheduleReconnect();
    } finally {
      IsSignalRConnecting = false;
    }
  }

  // ---------------------------------------------------------------------------
  // ONLINE / OFFLINE EVENTS
  // ---------------------------------------------------------------------------
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
              if (userNumber != null) parsedUsers.add(userNumber);
            }

            OnlineUserNumbers.assignAll(parsedUsers);
          }
        } catch (e) {
          // print('OnlineUsers event error: $e');
        }
      });

      connection?.on('UserOnline', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;

          final userNumber = int.tryParse(arguments[0].toString());
          if (userNumber != null) OnlineUserNumbers.add(userNumber);
        } catch (e) {
          // print('UserOnline event error: $e');
        }
      });

      connection?.on('UserOffline', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;

          final userNumber = int.tryParse(arguments[0].toString());
          if (userNumber != null) OnlineUserNumbers.remove(userNumber);
        } catch (e) {
          // print('UserOffline event error: $e');
        }
      });
    } catch (e) {
      // print('Online listener setup error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // REAL-TIME CHAT EVENTS
  // ---------------------------------------------------------------------------
  void ListenForChatMessages() {
    try {
      connection?.on('ReceiveMessage', (arguments) {
        try {
          final dynamic payload =
          (arguments != null && arguments.isNotEmpty) ? arguments[0] : null;
          _emitChat('ReceiveMessage', payload);
        } catch (e) {
          // print('ReceiveMessage event error: $e');
        }
      });

      connection?.on('MessagesRead', (arguments) {
        try {
          final dynamic payload =
          (arguments != null && arguments.isNotEmpty) ? arguments[0] : null;
          _emitChat('MessagesRead', payload);
        } catch (e) {
          // print('MessagesRead event error: $e');
        }
      });

      connection?.on('ConversationRead', (arguments) {
        try {
          final dynamic payload =
          (arguments != null && arguments.isNotEmpty) ? arguments[0] : null;
          _emitChat('ConversationRead', payload);
        } catch (e) {
          // print('ConversationRead event error: $e');
        }
      });
    } catch (e) {
      // print('Chat listener setup error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // VIDEO CALL SIGNALING EVENTS
  // ---------------------------------------------------------------------------
  void ListenForVideoCalls() {
    try {
      connection?.on('IncomingCall', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;
          _emitCall('IncomingCall', arguments[0]);
        } catch (e) {
          // print('IncomingCall event error: $e');
        }
      });

      connection?.on('CallAnswer', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;
          _emitCall('CallAnswer', arguments[0]);
        } catch (e) {
          // print('CallAnswer event error: $e');
        }
      });

      connection?.on('IceCandidate', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;
          _emitCall('IceCandidate', arguments[0]);
        } catch (e) {
          // print('IceCandidate event error: $e');
        }
      });

      connection?.on('CallEnded', (arguments) {
        try {
          if (arguments == null || arguments.isEmpty) return;
          _emitCall('CallEnded', arguments[0]);
        } catch (e) {
          // print('CallEnded event error: $e');
        }
      });
    } catch (e) {
      // print('Video call listener setup error: $e');
    }
  }

  // OLD flow (REST saves, then this notifies). Kept only for the old message
  // screen. The new screens send through the REST "send" endpoint instead.
  Future<void> NotifyNewMessage({
    required int ReceiverNumber,
    required int ChatId,
    required String Message,
    required String StoreAt,
  }) async {
    try {
      if (!IsSignalRConnected || connection == null) {
        // print('Cannot notify recipient: SignalR is disconnected.');
        return;
      }

      await connection!.invoke(
        'NotifyNewMessage',
        args: [ReceiverNumber, ChatId, Message, StoreAt],
      );
    } catch (e) {
      // print('SignalR message notification error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // VIDEO SIGNALING METHODS
  // ---------------------------------------------------------------------------
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
      // print('Send call offer error: $e');
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
      // print('Send call answer error: $e');
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
      // print('Send ICE candidate error: $e');
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
      // print('End video call error: $e');
    }
  }

  // Call on logout: stops the connection and the automatic reconnect.
  Future<void> DisconnectSignalR() async {
    try {
      _manualClose = true;
      _retryTimer?.cancel();
      _retryAttempt = 0;
      _jwt = '';

      final currentConnection = connection;

      connection = null;
      _setConnected(false);
      IsSignalRConnecting = false;
      OnlineUserNumbers.clear();

      if (currentConnection != null) {
        await currentConnection.stop();
      }

      // print('SignalR disconnected.');
    } catch (e) {
      // print('SignalR disconnect error: $e');
    } finally {
      _setConnected(false);
      IsSignalRConnecting = false;
    }
  }
}