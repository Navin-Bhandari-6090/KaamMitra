import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:permission_handler/permission_handler.dart';

// Adjust these paths to your project.
import '../../../models/ChatInfoModel.dart';
import '../../../web/common method/Commmon_Method.dart';
import '../../../web/communi_services/services.dart';
import '../../../web/communication/chat/chat_screen.dart';

const Color _kDanger = Color(0xFFEF4444);

enum CallStage { idle, calling, incoming, connecting, connected }

// The server stores UTC but may send it without a 'Z'. Dart would then read it
// as local time. This forces UTC, then converts to the device's local time.
DateTime? parseServerTime(String? raw) {
  try {
    final String s = (raw ?? '').trim();
    if (s.isEmpty) return null;

    final bool hasZone = s.endsWith('Z') ||
        s.endsWith('z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);

    final DateTime? parsed = DateTime.tryParse(hasZone ? s : '${s}Z');
    return parsed?.toLocal();
  } catch (e) {
    print('parseServerTime error: $e');
    return null;
  }
}

class MessageScreenGetx extends GetxController {
  MessageScreenGetx({
    required this.myNumber,
    required this.otherNumber,
    required this.otherName,
    required this.jwtToken,
  });

  final int myNumber;
  final int otherNumber;
  final String otherName;
  final String jwtToken;

  final TextEditingController textCont = TextEditingController();

  // ---------------- CHAT STATE ----------------
  final RxList<ChatInfoModel> messages = <ChatInfoModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxString draft = ''.obs;
  final RxString loadError = ''.obs;

  // ---------------- PRESENCE ----------------
  final RxBool isOnlineNow = false.obs;
  Worker? _presenceWorker;

  // ---------------- CALL STATE ----------------
  final Rx<CallStage> callStage = CallStage.idle.obs;
  final RxBool micOn = true.obs;
  final RxBool camOn = true.obs;
  final RxBool speakerOn = true.obs;
  final RxInt callSeconds = 0.obs;
  final RxString callError = ''.obs;
  final RxBool remoteVideoReady = false.obs;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  late final Future<void> _renderersReady = _initRenderers();

  SignalRService? _signal;
  StreamSubscription<Map<String, dynamic>>? _callSub;
  MediaStream? _localStream;
  RTCPeerConnection? _pc;
  String? _callId;
  Map<String, dynamic>? _pendingOffer;
  Timer? _callTimer;
  Timer? _statsTimer;

  // Remote ICE candidates that arrive before the remote description is set.
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  bool _remoteDescSet = false;

  // Local ICE candidates that are gathered before the offer or answer is sent.
  final List<RTCIceCandidate> _pendingLocalCandidates = [];
  bool _canSendCandidates = false;

  // Last byte counters per stream, used to decide if media is actually flowing.
  final Map<String, num> _lastBytes = {};

  String get callDurationText {
    final int s = callSeconds.value;
    final String m = (s ~/ 60).toString().padLeft(2, '0');
    final String r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  String get callStatusText {
    switch (callStage.value) {
      case CallStage.idle:
        return '';
      case CallStage.calling:
        return 'Calling...';
      case CallStage.incoming:
        return 'Incoming video call';
      case CallStage.connecting:
        return 'Connecting...';
      case CallStage.connected:
        return callDurationText;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _bindSignal();
    refreshMessages();
  }

  @override
  void onClose() {
    try {
      endCall();
      _callSub?.cancel();
      _presenceWorker?.dispose();
      _callTimer?.cancel();
      _statsTimer?.cancel();
      textCont.dispose();
      localRenderer.dispose();
      remoteRenderer.dispose();
    } catch (e) {
      print('MessageScreenGetx onClose error: $e');
    }
    super.onClose();
  }

  // ===========================================================================
  // LOGGING
  // All call logs start with [CALL] or [STATS], so you can filter the console.
  // ===========================================================================
  void _log(String msg) {
    debugPrint('[CALL] $msg');
  }

  // ===========================================================================
  // SIGNALR BINDING (presence + call events)
  // ===========================================================================
  void _bindSignal() {
    try {
      _signal = Get.find<SignalRService>();

      isOnlineNow.value = _signal!.OnlineUserNumbers.contains(otherNumber);
      _presenceWorker = ever(_signal!.OnlineUserNumbers, (_) {
        try {
          isOnlineNow.value = _signal!.OnlineUserNumbers.contains(otherNumber);
        } catch (e) {
          print('Presence update error: $e');
        }
      });

      _callSub = _signal!.CallEvents.stream.listen(
            (event) => _onCallEvent(event),
        onError: (e) => _log('Call event stream error: $e'),
      );
    } catch (e) {
      print('SignalR bind error: $e');
      isOnlineNow.value = false;
    }
  }

  // ===========================================================================
  // MESSAGES
  // ===========================================================================
  DateTime _timeOf(ChatInfoModel m) =>
      parseServerTime('${m.storeAt ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> refreshMessages() async {
    try {
      isLoading.value = true;
      loadError.value = '';

      await GetChatMessages(
        UserNumber: otherNumber,
        User_JwtToken: jwtToken,
      );

      // Sort by real time so the order always matches the clock.
      final List<ChatInfoModel> sorted = List<ChatInfoModel>.from(ChatInfos);
      sorted.sort((a, b) => _timeOf(a).compareTo(_timeOf(b)));
      messages.assignAll(sorted);
    } catch (e) {
      loadError.value = 'Could not load messages.';
      print('refreshMessages error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Sends without confirmation. Clears the input only when the save succeeded.
  // Requires the LastSendSucceeded flag in the chat API file.
  Future<void> requestSend() async {
    try {
      final String text = draft.value.trim();
      if (text.isEmpty || isSending.value) return;

      isSending.value = true;
      LastSendSucceeded = false;

      await AddChatMessage(
        Message: text,
        ReceiverNumber: otherNumber,
        User_JwtToken: jwtToken,
      );

      if (LastSendSucceeded) {
        textCont.clear();
        draft.value = '';
      }

      await refreshMessages();
    } catch (e) {
      print('requestSend error: $e');
    } finally {
      isSending.value = false;
    }
  }

  // ===========================================================================
  // MEDIA
  // ===========================================================================
  Future<void> _initRenderers() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();

      localRenderer.onFirstFrameRendered = () {
        _log('LOCAL video: first frame rendered on screen (camera works)');
      };
      remoteRenderer.onFirstFrameRendered = () {
        _log('REMOTE video: first frame rendered on screen (remote video works)');
      };

      _log('Renderers initialized');
    } catch (e) {
      callError.value = 'Video is not supported on this device.';
      _log('Renderer init ERROR: $e');
    }
  }

  Future<bool> _openLocalMedia() async {
    try {
      // On web, getUserMedia shows the browser's own permission prompt.
      // permission_handler is only needed on Android and iOS.
      if (!kIsWeb) {
        _log('Requesting camera and microphone permission...');
        final Map<Permission, PermissionStatus> statuses =
        await [Permission.camera, Permission.microphone].request();

        final bool camOk = statuses[Permission.camera]?.isGranted == true;
        final bool micOk = statuses[Permission.microphone]?.isGranted == true;
        _log('Permission camera=$camOk microphone=$micOk');

        if (!camOk || !micOk) return false;
      }

      _log('Calling getUserMedia (audio + video)...');
      _localStream ??= await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      });

      final List<MediaStreamTrack> audio = _localStream!.getAudioTracks();
      final List<MediaStreamTrack> video = _localStream!.getVideoTracks();
      _log('getUserMedia OK: audioTracks=${audio.length} '
          'videoTracks=${video.length}');
      for (final MediaStreamTrack t in video) {
        _log('LOCAL video track: label="${t.label}" enabled=${t.enabled}');
      }
      for (final MediaStreamTrack t in audio) {
        _log('LOCAL audio track: label="${t.label}" enabled=${t.enabled}');
      }

      localRenderer.srcObject = _localStream;
      _applyTrackStates();
      return true;
    } catch (e) {
      _log('getUserMedia FAILED: $e');
      return false;
    }
  }

  void _applyTrackStates() {
    try {
      for (final MediaStreamTrack t in _localStream?.getAudioTracks() ?? []) {
        t.enabled = micOn.value;
      }
      for (final MediaStreamTrack t in _localStream?.getVideoTracks() ?? []) {
        t.enabled = camOn.value;
      }
      _log('Track states applied: mic=${micOn.value} cam=${camOn.value}');
    } catch (e) {
      _log('Apply track state ERROR: $e');
    }
  }

  Future<void> _createPeer() async {
    _log('Creating RTCPeerConnection...');
    final RTCPeerConnection pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });
    _pc = pc;

    for (final MediaStreamTrack track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
      _log('Added LOCAL ${track.kind} track to peer connection');
    }

    pc.onIceCandidate = (RTCIceCandidate c) {
      try {
        _sendLocalCandidate(c);
      } catch (e) {
        _log('onIceCandidate ERROR: $e');
      }
    };

    pc.onIceConnectionState = (RTCIceConnectionState state) {
      _log('ICE connection state: $state');
    };

    pc.onTrack = (RTCTrackEvent event) {
      try {
        _log('onTrack: REMOTE ${event.track.kind} track received, '
            'streams=${event.streams.length}');
        if (event.streams.isNotEmpty) {
          remoteRenderer.srcObject = event.streams.first;
          remoteVideoReady.value = true;
          _log('Remote stream attached to remote renderer');
        }
      } catch (e) {
        _log('onTrack ERROR: $e');
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      try {
        _log('Peer connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _markConnected();
          _startStatsLogging();
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _fail('The connection failed. Check your network and try again.');
        }
      } catch (e) {
        _log('onConnectionState ERROR: $e');
      }
    };
  }

  // ===========================================================================
  // STREAM PROOF: logs whether bytes are really moving in each direction
  // ===========================================================================
  void _startStatsLogging() {
    _statsTimer?.cancel();
    _lastBytes.clear();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _logStats();
    });
    _log('Stats logging started (every 2s)');
  }

  Future<void> _logStats() async {
    try {
      final RTCPeerConnection? pc = _pc;
      if (pc == null) return;

      final List<StatsReport> reports = await pc.getStats();

      for (final StatsReport r in reports) {
        final String type = r.type;
        if (type != 'outbound-rtp' && type != 'inbound-rtp') continue;

        final dynamic kindRaw = r.values['kind'] ?? r.values['mediaType'];
        final String kind = '$kindRaw';
        final bool outgoing = type == 'outbound-rtp';
        final String key = '$type|$kind';

        final num bytes = num.tryParse(
          '${outgoing ? r.values['bytesSent'] : r.values['bytesReceived']}',
        ) ??
            0;
        final num packets = num.tryParse(
          '${outgoing ? r.values['packetsSent'] : r.values['packetsReceived']}',
        ) ??
            0;

        final num previous = _lastBytes[key] ?? 0;
        final num delta = bytes - previous;
        _lastBytes[key] = bytes;

        final String direction = outgoing ? 'SENDING' : 'RECEIVING';
        final String status = delta > 0 ? 'FLOWING' : 'NO DATA';

        _log('[STATS] $direction $kind: $status '
            '(+${delta}B in last 2s, total ${bytes}B, packets $packets)');
      }
    } catch (e) {
      _log('Stats ERROR: $e');
    }
  }

  // ===========================================================================
  // ICE CANDIDATE HANDLING
  // ===========================================================================

  // Local candidates are held until the offer or answer is on its way.
  // Otherwise the other side would receive them before it knows the call.
  void _sendLocalCandidate(RTCIceCandidate c) {
    if (c.candidate == null) return;

    if (!_canSendCandidates || _callId == null) {
      _pendingLocalCandidates.add(c);
      return;
    }

    _signal?.SendIceCandidate(
      ReceiverNumber: otherNumber,
      CallId: _callId!,
      Candidate: {
        'candidate': c.candidate,
        'sdpMid': c.sdpMid,
        'sdpMLineIndex': c.sdpMLineIndex,
      },
    );
  }

  void _flushLocalCandidates() {
    _canSendCandidates = true;
    final List<RTCIceCandidate> held =
    List<RTCIceCandidate>.from(_pendingLocalCandidates);
    _pendingLocalCandidates.clear();
    _log('Sending ${held.length} buffered local ICE candidates');
    for (final RTCIceCandidate c in held) {
      _sendLocalCandidate(c);
    }
  }

  Future<void> _flushRemoteCandidates() async {
    final List<RTCIceCandidate> held =
    List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();
    _log('Applying ${held.length} buffered remote ICE candidates');
    for (final RTCIceCandidate c in held) {
      await _pc?.addCandidate(c);
    }
  }

  // ===========================================================================
  // CALL ACTIONS
  // ===========================================================================

  // Caller: open camera, create offer, send it.
  Future<void> startCall() async {
    try {
      if (callStage.value != CallStage.idle) return;

      if (_signal == null || !_signal!.IsSignalRConnected) {
        callError.value = 'You are offline. Check your connection.';
        _log('startCall blocked: SignalR not connected');
        return;
      }

      callError.value = '';
      callStage.value = CallStage.calling;
      _callId = '${DateTime.now().millisecondsSinceEpoch}_$myNumber';
      _log('=== START CALL to user $otherNumber, callId=$_callId ===');

      await _renderersReady;

      final bool ok = await _openLocalMedia();
      if (!ok) {
        _fail(
          'Camera or microphone access was denied. Allow it in your browser '
              'or device settings.',
        );
        return;
      }

      await _createPeer();
      final RTCSessionDescription offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      _log('Offer created and set as local description');

      await _signal!.SendCallOffer(
        ReceiverNumber: otherNumber,
        CallId: _callId!,
        Offer: {'sdp': offer.sdp, 'type': offer.type},
      );
      _log('Offer SENT to user $otherNumber');

      _flushLocalCandidates();
    } catch (e) {
      _log('startCall ERROR: $e');
      _fail('Could not start the call.');
    }
  }

  // Callee: open camera, apply offer, create answer, send it.
  Future<void> acceptCall() async {
    try {
      if (callStage.value != CallStage.incoming || _pendingOffer == null) {
        return;
      }

      _log('=== ACCEPT CALL from user $otherNumber, callId=$_callId ===');
      callStage.value = CallStage.connecting;
      await _renderersReady;

      final bool ok = await _openLocalMedia();
      if (!ok) {
        _fail('Camera or microphone access was denied.');
        return;
      }

      await _createPeer();

      await _pc!.setRemoteDescription(RTCSessionDescription(
        _pendingOffer!['sdp'] as String?,
        _pendingOffer!['type'] as String?,
      ));
      _remoteDescSet = true;
      _log('Remote offer set');
      await _flushRemoteCandidates();

      final RTCSessionDescription answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      _log('Answer created and set as local description');

      await _signal!.SendCallAnswer(
        ReceiverNumber: otherNumber,
        CallId: _callId!,
        Answer: {'sdp': answer.sdp, 'type': answer.type},
      );
      _log('Answer SENT to user $otherNumber');

      _flushLocalCandidates();
    } catch (e) {
      _log('acceptCall ERROR: $e');
      _fail('Could not accept the call.');
    }
  }

  void declineCall() {
    try {
      if (callStage.value != CallStage.incoming) return;
      final String? id = _callId;
      if (id != null) {
        _signal?.EndVideoCall(ReceiverNumber: otherNumber, CallId: id);
      }
      _log('Call DECLINED');
      _cleanup();
    } catch (e) {
      _log('declineCall ERROR: $e');
    }
  }

  // Hang up and tell the other side.
  void endCall() {
    try {
      final String? id = _callId;
      if (id != null && callStage.value != CallStage.idle) {
        _signal?.EndVideoCall(ReceiverNumber: otherNumber, CallId: id);
      }
      if (callStage.value != CallStage.idle) _log('Call ENDED by this user');
      _cleanup();
    } catch (e) {
      _log('endCall ERROR: $e');
    }
  }

  void toggleMic() {
    try {
      micOn.toggle();
      _applyTrackStates();
    } catch (e) {
      _log('toggleMic ERROR: $e');
    }
  }

  void toggleCamera() {
    try {
      camOn.toggle();
      _applyTrackStates();
    } catch (e) {
      _log('toggleCamera ERROR: $e');
    }
  }

  // UI only for now. Speaker routing needs native audio APIs.
  void toggleSpeaker() {
    try {
      speakerOn.toggle();
    } catch (e) {
      _log('toggleSpeaker ERROR: $e');
    }
  }

  // ===========================================================================
  // INCOMING SIGNALING
  // ===========================================================================
  void _onCallEvent(Map<String, dynamic> e) {
    try {
      final int from = int.tryParse('${e['senderNumber']}') ?? 0;
      if (from != otherNumber) return; // only this conversation

      final String type = '${e['type']}';
      final String callId = '${e['callId']}';
      _log('Signal received: $type (callId=$callId)');

      if (type == 'IncomingCall') {
        _onIncoming(e);
      } else if (type == 'CallAnswer' && callId == _callId) {
        _onAnswer(e);
      } else if (type == 'IceCandidate' && callId == _callId) {
        _onRemoteCandidate(e);
      } else if (type == 'CallEnded' && callId == _callId) {
        _log('Remote user ended the call');
        _cleanup();
      }
    } catch (err) {
      _log('_onCallEvent ERROR: $err');
    }
  }

  void _onIncoming(Map<String, dynamic> e) {
    if (callStage.value != CallStage.idle) {
      // Already in a call: tell the caller we are busy.
      _signal?.EndVideoCall(
        ReceiverNumber: otherNumber,
        CallId: '${e['callId']}',
      );
      _log('Incoming call ignored: already in a call');
      return;
    }
    _callId = '${e['callId']}';
    _pendingOffer = Map<String, dynamic>.from(e['offer'] as Map);
    callStage.value = CallStage.incoming;
    _log('Incoming call from user $otherNumber, callId=$_callId');
  }

  Future<void> _onAnswer(Map<String, dynamic> e) async {
    try {
      if (_pc == null) return;
      final Map<String, dynamic> a =
      Map<String, dynamic>.from(e['answer'] as Map);

      await _pc!.setRemoteDescription(RTCSessionDescription(
        a['sdp'] as String?,
        a['type'] as String?,
      ));
      _remoteDescSet = true;
      _log('Remote answer set');
      await _flushRemoteCandidates();
      callStage.value = CallStage.connecting;
    } catch (err) {
      _log('_onAnswer ERROR: $err');
      _fail('Could not connect the call.');
    }
  }

  Future<void> _onRemoteCandidate(Map<String, dynamic> e) async {
    try {
      final Map<String, dynamic> m =
      Map<String, dynamic>.from(e['candidate'] as Map);

      final RTCIceCandidate cand = RTCIceCandidate(
        m['candidate'] as String?,
        m['sdpMid'] as String?,
        (m['sdpMLineIndex'] as num?)?.toInt(),
      );

      if (_pc == null || !_remoteDescSet) {
        _pendingRemoteCandidates.add(cand);
      } else {
        await _pc!.addCandidate(cand);
      }
    } catch (err) {
      _log('_onRemoteCandidate ERROR: $err');
    }
  }

  // ===========================================================================
  // STATE HELPERS
  // ===========================================================================
  void _markConnected() {
    try {
      if (callStage.value == CallStage.connected) return;
      callStage.value = CallStage.connected;
      callSeconds.value = 0;
      _callTimer?.cancel();
      _callTimer = Timer.periodic(
        const Duration(seconds: 1),
            (_) => callSeconds.value++,
      );
      _log('=== CALL CONNECTED ===');
    } catch (e) {
      _log('_markConnected ERROR: $e');
    }
  }

  void _fail(String message) {
    try {
      _log('Call FAILED: $message');
      callError.value = message;
      final String? id = _callId;
      if (id != null) {
        _signal?.EndVideoCall(ReceiverNumber: otherNumber, CallId: id);
      }
      _cleanup();
    } catch (e) {
      _log('_fail ERROR: $e');
    }
  }

  void _cleanup() {
    try {
      _callTimer?.cancel();
      _callTimer = null;
      _statsTimer?.cancel();
      _statsTimer = null;
      _lastBytes.clear();
      callSeconds.value = 0;

      final RTCPeerConnection? pc = _pc;
      _pc = null;
      pc?.close();

      try {
        _localStream?.getTracks().forEach((t) => t.stop());
        _localStream?.dispose();
      } catch (e) {
        _log('Stop local media ERROR: $e');
      }
      _localStream = null;

      try {
        localRenderer.srcObject = null;
        remoteRenderer.srcObject = null;
      } catch (e) {
        _log('Clear renderer ERROR: $e');
      }
      remoteVideoReady.value = false;

      _pendingRemoteCandidates.clear();
      _pendingLocalCandidates.clear();
      _canSendCandidates = false;
      _remoteDescSet = false;
      _pendingOffer = null;
      _callId = null;

      micOn.value = true;
      camOn.value = true;
      speakerOn.value = true;

      callStage.value = CallStage.idle;
      _log('Call resources released');
    } catch (e) {
      _log('_cleanup ERROR: $e');
    }
  }
}

// =============================================================================
// CONFIRMATION (use for every add / update / delete that touches the database)
// Not used for sending messages. Keep it for future delete and update actions.
// =============================================================================
Future<bool> confirmAction({
  required String title,
  required String message,
  String confirmText = 'Confirm',
  bool destructive = false,
}) async {
  try {
    final bool? result = await Get.dialog<bool>(
      MessageConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        destructive: destructive,
      ),
      barrierDismissible: true,
    );
    return result ?? false;
  } catch (e) {
    print('confirmAction error: $e');
    return false;
  }
}

class MessageConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final bool destructive;

  const MessageConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.destructive,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = destructive ? _kDanger : ChatAccent;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: ChatSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ChatBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.12),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Icon(
                  destructive
                      ? Icons.warning_amber_rounded
                      : Icons.help_outline_rounded,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: ChatText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: ChatMuted,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ChatText,
                        side: const BorderSide(color: ChatBorder),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor:
                        destructive ? Colors.white : ChatBackground,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}