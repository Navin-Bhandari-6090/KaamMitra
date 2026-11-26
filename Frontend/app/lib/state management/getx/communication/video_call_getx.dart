import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:permission_handler/permission_handler.dart';

// Adjust these paths to your project.
import '../../../constant/variable.dart' show Toast;
import '../../../web/common method/communicationcommonmethod.dart';
import '../../../web/communi_services/services.dart';
import '../../../web/communication/chat/chat_screen.dart';
import '../../../web/communication/chat/video_call.dart';
import 'chat_screen_getx.dart';

const Color _kDanger = Color(0xFFEF4444);

enum CallStage { idle, calling, incoming, connecting, connected }

// =============================================================================
// VIDEO CALL GETX: ONE permanent service for the whole app.
//
// It listens to the SignalR call signals for ANY caller, so an incoming call
// rings on every screen, and a call keeps running when the user leaves the
// chat. The call window is drawn in the app's Navigator overlay (see
// VideoCallPage in video_call.dart), so no screen has to host it.
//
//   VideoCallGetx.Ensure()            get (or create) the service
//   startCall(otherNumber:, name:)    call someone
//   acceptCall() / declineCall()      answer an incoming call
//   endCall()                         hang up (also called on logout)
//
// One call at a time. A second incoming call is answered with "busy".
// Needs GetMaterialApp (the app already uses Get.dialog / Get.back).
// =============================================================================
class VideoCallGetx extends GetxController {
  static VideoCallGetx Ensure() {
    return Get.isRegistered<VideoCallGetx>()
        ? Get.find<VideoCallGetx>()
        : Get.put(VideoCallGetx(), permanent: true);
  }

  // How long a call rings before it is given up (both sides).
  static const int RingSeconds = 45;

  // ---------------- CALL STATE ----------------
  final Rx<CallStage> callStage = CallStage.idle.obs;
  final RxBool micOn = true.obs;
  final RxBool camOn = true.obs;
  final RxBool speakerOn = true.obs;
  final RxInt callSeconds = 0.obs;
  final RxString callError = ''.obs;
  final RxBool remoteVideoReady = false.obs;

  // The other person of the current call.
  final RxInt peerNumber = 0.obs;
  final RxString peerName = ''.obs;
  final RxString peerPhoto = ''.obs; // raw path

  // True while a system dialog (permission) must be visible above the call UI.
  final RxBool overlayHidden = false.obs;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  late final Future<void> _renderersReady = _initRenderers();

  SignalRService? _signal;
  StreamSubscription<Map<String, dynamic>>? _callSub;
  final List<Worker> _workers = <Worker>[];
  MediaStream? _localStream;
  RTCPeerConnection? _pc;
  String? _callId;
  Map<String, dynamic>? _pendingOffer;
  Timer? _callTimer;
  Timer? _ringTimer;
  OverlayEntry? _entry;

  // True from the tap on "call" until the call state has changed.
  bool _busy = false;

  // True while the "accept" tap is being handled (permission dialog open).
  bool _accepting = false;

  // Remote ICE candidates that arrive before the remote description is set.
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  bool _remoteDescSet = false;

  // Local ICE candidates that are gathered before the offer or answer is sent.
  final List<RTCIceCandidate> _pendingLocalCandidates = [];
  bool _canSendCandidates = false;

  int get _peer => peerNumber.value;

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

    // Shows the call window when a call starts / rings, removes it at the end.
    _workers.add(ever(callStage, (_) => _syncOverlay()));
  }

  @override
  void onClose() {
    try {
      endCall();
      _removeOverlay();
      _callSub?.cancel();
      _callTimer?.cancel();
      _ringTimer?.cancel();
      for (final Worker w in _workers) {
        w.dispose();
      }
      _workers.clear();
      localRenderer.dispose();
      remoteRenderer.dispose();
    } catch (e) {
      // print('VideoCallGetx onClose error: $e');
    }
    super.onClose();
  }

  // Call logs are switched off. Remove the // to see them in the console.
  void _log(String msg) {
    // debugPrint('[CALL] $msg');
  }

  // Shows a short message to the user (toast) and keeps it in callError.
  void _notify(String message) {
    try {
      callError.value = message;
      Toast.Toastmsg(message);
    } catch (e) {
      _log('notify ERROR: $e');
    }
  }

  void _bindSignal() {
    try {
      final SignalRService s = Get.isRegistered<SignalRService>()
          ? Get.find<SignalRService>()
          : Get.put(SignalRService(), permanent: true);
      _signal = s;

      _callSub = s.CallEvents.stream.listen(
            (event) => _onCallEvent(event),
        onError: (e) => _log('Call event stream error: $e'),
      );

      // Connection lost while ringing: give up. (A running call keeps its
      // media connection, which does not need SignalR.)
      _workers.add(ever(s.IsConnectedRx, (bool connected) {
        if (connected) return;

        final CallStage stage = callStage.value;
        if (stage == CallStage.calling || stage == CallStage.incoming) {
          _fail('Connection lost.');
        }
      }));
    } catch (e) {
      // print('VideoCallGetx bind error: $e');
    }
  }

  // ===========================================================================
  // CALL WINDOW (Navigator overlay: above every screen)
  // ===========================================================================
  void _syncOverlay() {
    try {
      if (callStage.value == CallStage.idle) {
        _removeOverlay();
      } else {
        _insertOverlay();
      }
    } catch (e) {
      _log('syncOverlay ERROR: $e');
    }
  }

  void _insertOverlay() {
    if (_entry != null) return;

    final OverlayState? overlay = Get.key.currentState?.overlay;

    if (overlay == null) {
      // No place to draw the call window: give the call up.
      Future.microtask(() => _fail('Could not show the call window.'));
      return;
    }

    final OverlayEntry entry = OverlayEntry(
      builder: (context) => const VideoCallPage(),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  void _removeOverlay() {
    try {
      _entry?.remove();
    } catch (e) {
      _log('removeOverlay ERROR: $e');
    }
    _entry = null;
  }

  // ===========================================================================
  // PERMISSIONS
  // Asks every time a call starts or is accepted, until both are granted.
  // The call window is hidden while a permission dialog is shown, because the
  // dialog would otherwise appear below it.
  // ===========================================================================
  Future<bool> _ensureCallPermissions() async {
    try {
      // On web the browser shows its own prompt inside getUserMedia.
      if (kIsWeb) return true;

      overlayHidden.value = true;
      try {
        while (true) {
          final Map<Permission, PermissionStatus> s =
          await [Permission.camera, Permission.microphone].request();

          final PermissionStatus? cam = s[Permission.camera];
          final PermissionStatus? mic = s[Permission.microphone];
          _log('Permission camera=$cam microphone=$mic');

          if (cam?.isGranted == true && mic?.isGranted == true) return true;

          final bool blocked = cam?.isPermanentlyDenied == true ||
              mic?.isPermanentlyDenied == true ||
              cam?.isRestricted == true ||
              mic?.isRestricted == true;

          if (blocked) {
            // The system will no longer show its prompt: send the user to
            // settings instead.
            final bool open = await confirmAction(
              title: 'Allow camera and microphone',
              message: 'Video calls need camera and microphone access. '
                  'Open settings and turn both on.',
              confirmText: 'Open settings',
            );
            if (open) await openAppSettings();
            return false;
          }

          // Denied this time only: explain and ask again.
          final bool retry = await confirmAction(
            title: 'Permission needed',
            message: 'Camera and microphone are required for video calls.',
            confirmText: 'Allow',
          );
          if (!retry) return false;
        }
      } finally {
        overlayHidden.value = false;
      }
    } catch (e) {
      _log('Permission flow ERROR: $e');
      return false;
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

  // Tries to open the camera and microphone once.
  // Returns null on success, or a readable reason on failure.
  Future<String?> _tryOpenMedia() async {
    try {
      await _renderersReady;

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      });

      localRenderer.srcObject = _localStream;
      _applyTrackStates();
      _log('getUserMedia OK');
      return null;
    } catch (e) {
      _log('getUserMedia FAILED: $e');
      _localStream = null;

      final String t = '$e'.toLowerCase();

      if (t.contains('notallowed') ||
          t.contains('permission') ||
          t.contains('denied') ||
          t.contains('dismissed')) {
        return kIsWeb
            ? 'Camera and microphone access is blocked. In the browser address '
            'bar, click the camera or lock icon, choose Allow for camera and '
            'microphone, then press Try again.'
            : 'Camera and microphone are required for video calls. '
            'Allow both, then press Try again.';
      }

      if (t.contains('notfound') || t.contains('devicesnotfound')) {
        return 'No camera or microphone was found on this device. '
            'Connect one, then press Try again.';
      }

      if (t.contains('notreadable') ||
          t.contains('trackstart') ||
          t.contains('in use')) {
        return 'The camera or microphone is being used by another app or tab. '
            'Close it, then press Try again.';
      }

      return kIsWeb
          ? 'Could not open the camera or microphone. Video calls need a '
          'secure (https) connection. Press Try again.'
          : 'Could not open the camera or microphone. Press Try again.';
    }
  }

  // Opens the camera and microphone BEFORE the call state changes.
  // If they are not allowed it asks again, every time, until the user allows
  // or cancels. Returns true when the media is open (_localStream is set).
  Future<bool> _acquireLocalMedia() async {
    try {
      if (_localStream != null) return true;

      // Mobile apps: ask the system first (web uses the browser prompt below).
      if (!kIsWeb) {
        if (!await _ensureCallPermissions()) return false;
      }

      while (true) {
        final String? problem = await _tryOpenMedia();
        if (problem == null) return true;

        // The call window (if any) is hidden so the dialog is not covered.
        overlayHidden.value = true;
        bool retry = false;
        try {
          retry = await confirmAction(
            title: 'Camera and microphone needed',
            message: problem,
            confirmText: 'Try again',
          );
        } finally {
          overlayHidden.value = false;
        }

        if (!retry) return false;
      }
    } catch (e) {
      _log('acquireLocalMedia ERROR: $e');
      return false;
    }
  }

  // Stops the camera and microphone (used when a call did not start).
  void _releaseLocalMedia() {
    try {
      _localStream?.getTracks().forEach((t) => t.stop());
      _localStream?.dispose();
    } catch (e) {
      _log('releaseLocalMedia ERROR: $e');
    }
    _localStream = null;

    try {
      localRenderer.srcObject = null;
    } catch (e) {
      _log('releaseLocalMedia renderer ERROR: $e');
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
      ReceiverNumber: _peer,
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
  // RING TIMER
  // ===========================================================================
  void _startRingTimer() {
    _ringTimer?.cancel();
    _ringTimer = Timer(const Duration(seconds: RingSeconds), _onRingTimeout);
  }

  void _onRingTimeout() {
    try {
      final CallStage stage = callStage.value;

      if (stage == CallStage.calling) {
        _fail('No answer.');
      } else if (stage == CallStage.incoming) {
        final String who = peerName.value;
        _cleanup();
        _notify('Missed video call from $who.');
      }
    } catch (e) {
      _log('ring timeout ERROR: $e');
    }
  }

  // ===========================================================================
  // CALL ACTIONS
  // ===========================================================================

  // Caller: open camera + microphone (asking until allowed), then create the
  // offer and send it.
  Future<void> startCall({
    required int otherNumber,
    required String name,
    String photo = '',
  }) async {
    try {
      if (callStage.value != CallStage.idle || _busy) return;
      if (otherNumber <= 0) return;

      _busy = true;

      final String shownName =
      name.trim().isEmpty ? 'User $otherNumber' : name.trim();

      if (_signal == null || !_signal!.IsSignalRConnected) {
        _notify('You are offline. Check your connection.');
        _log('startCall blocked: SignalR not connected');
        return;
      }

      if (!_signal!.OnlineUserNumbers.contains(otherNumber)) {
        _notify('$shownName is offline. Try again when they are online.');
        _log('startCall blocked: user $otherNumber is offline');
        return;
      }

      callError.value = '';

      // Camera and microphone first. If they are not allowed it asks again,
      // every time, until the user allows or cancels. No call window yet.
      if (!await _acquireLocalMedia()) {
        _notify('Camera and microphone are required for video calls.');
        return;
      }

      // Another call may have started while we were asking.
      if (callStage.value != CallStage.idle) {
        _releaseLocalMedia();
        return;
      }

      peerNumber.value = otherNumber;
      peerName.value = shownName;
      peerPhoto.value = photo;

      _callId = '${DateTime.now().millisecondsSinceEpoch}_${_myNumber()}';
      callStage.value = CallStage.calling;
      _startRingTimer();
      _log('=== START CALL to user $otherNumber, callId=$_callId ===');

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
      if (callStage.value != CallStage.idle) {
        _fail('Could not start the call.');
      } else {
        _releaseLocalMedia();
      }
    } finally {
      _busy = false;
    }
  }


  // My own user number (only used to build a unique call id).
  int _myNumber() {
    try {
      if (Get.isRegistered<ChatScreenController>()) {
        return Get.find<ChatScreenController>().MyNumber;
      }
    } catch (e) {
      _log('myNumber ERROR: $e');
    }
    return 0;
  }

  // Callee: open camera + microphone (asking until allowed), then apply the
  // offer, create the answer and send it. While permission is missing the
  // incoming screen stays, so the user can try again or decline.
  Future<void> acceptCall() async {
    try {
      if (callStage.value != CallStage.incoming || _pendingOffer == null) {
        return;
      }
      if (_accepting) return;
      _accepting = true;

      try {
        // Asked every time until allowed. The call is NOT ended if refused.
        if (!await _acquireLocalMedia()) {
          _notify(
            'Camera and microphone are required to accept the call. '
                'Press Accept to try again, or Decline.',
          );
          return;
        }

        // The caller may have hung up while the dialog was open.
        if (callStage.value != CallStage.incoming || _pendingOffer == null) {
          _releaseLocalMedia();
          return;
        }

        _log('=== ACCEPT CALL from user $_peer, callId=$_callId ===');
        _ringTimer?.cancel();
        callStage.value = CallStage.connecting;

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
          ReceiverNumber: _peer,
          CallId: _callId!,
          Answer: {'sdp': answer.sdp, 'type': answer.type},
        );
        _log('Answer SENT to user $_peer');

        _flushLocalCandidates();
      } finally {
        _accepting = false;
      }
    } catch (e) {
      _log('acceptCall ERROR: $e');
      if (callStage.value != CallStage.idle) {
        _fail('Could not accept the call.');
      }
    }
  }

  void declineCall() {
    try {
      if (callStage.value != CallStage.incoming) return;
      final String? id = _callId;
      if (id != null) {
        _signal?.EndVideoCall(ReceiverNumber: _peer, CallId: id);
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
        _signal?.EndVideoCall(ReceiverNumber: _peer, CallId: id);
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
      if (from <= 0) return;

      final String type = '${e['type']}';
      final String callId = '${e['callId']}';
      _log('Signal received: $type from $from (callId=$callId)');

      if (type == 'IncomingCall') {
        _onIncoming(from, e);
        return;
      }

      // Every other signal belongs to the call that is running right now.
      if (callStage.value == CallStage.idle ||
          callId != _callId ||
          from != _peer) {
        return;
      }

      if (type == 'CallAnswer') {
        _onAnswer(e);
      } else if (type == 'IceCandidate') {
        _onRemoteCandidate(e);
      } else if (type == 'CallEnded') {
        _log('Remote user ended the call');
        _onRemoteEnded();
      }
    } catch (err) {
      _log('_onCallEvent ERROR: $err');
    }
  }

  void _onIncoming(int from, Map<String, dynamic> e) {
    final String callId = '${e['callId']}';
    if (callId.isEmpty || callId == 'null') return;

    // Already in a call (or starting one): tell the caller we are busy.
    if (callStage.value != CallStage.idle || _busy) {
      if (callId != _callId) {
        _signal?.EndVideoCall(ReceiverNumber: from, CallId: callId);
        _log('Incoming call from $from refused: busy');
      }
      return;
    }

    final dynamic offer = e['offer'];
    if (offer is! Map) return;

    callError.value = '';
    _callId = callId;
    _pendingOffer = Map<String, dynamic>.from(offer);

    peerNumber.value = from;
    peerName.value = 'User $from';
    peerPhoto.value = '';

    callStage.value = CallStage.incoming;
    _startRingTimer();
    _log('Incoming call from user $from, callId=$_callId');

    // Fills in the real name and photo (the call window already shows).
    _resolvePeer(from);
  }

  // The other side hung up, declined, or is busy.
  void _onRemoteEnded() {
    final CallStage was = callStage.value;
    final String who = peerName.value;

    _cleanup();

    if (was == CallStage.calling) {
      _notify('$who is busy or declined the call.');
    } else if (was == CallStage.incoming) {
      _notify('Missed video call from $who.');
    }
  }

  // Looks up the caller's name and photo: from my chats, or by user id.
  Future<void> _resolvePeer(int number) async {
    try {
      String name = '';
      String photo = '';

      if (Get.isRegistered<ChatScreenController>()) {
        final ChatScreenController chats = Get.find<ChatScreenController>();
        final MsgConversation? c = chats.Find(number);

        if (c != null) {
          name = c.name;
          photo = c.photo;
        } else if (chats.Jwt.isNotEmpty) {
          final MsgListResult r = await MsgSearchUsers(
            jwt: chats.Jwt,
            query: '$number',
            page: 1,
            pageSize: 10,
          );

          for (final MsgConversation u in r.items) {
            if (u.userNumber == number) {
              name = u.name;
              photo = u.photo;
              break;
            }
          }
        }
      }

      // The call may have ended (or changed) while we looked.
      if (peerNumber.value != number || callStage.value == CallStage.idle) {
        return;
      }

      if (name.isNotEmpty) peerName.value = name;
      peerPhoto.value = photo;
    } catch (e) {
      _log('resolvePeer ERROR: $e');
    }
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

      _ringTimer?.cancel();
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

      _ringTimer?.cancel();
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
      _notify(message);

      final String? id = _callId;
      if (id != null && callStage.value != CallStage.idle) {
        _signal?.EndVideoCall(ReceiverNumber: _peer, CallId: id);
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
      _ringTimer?.cancel();
      _ringTimer = null;
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
      overlayHidden.value = false;

      // Last: this also removes the call window.
      callStage.value = CallStage.idle;

      peerNumber.value = 0;
      peerName.value = '';
      peerPhoto.value = '';

      _log('Call resources released');
    } catch (e) {
      _log('_cleanup ERROR: $e');
    }
  }
}

// =============================================================================
// CONFIRMATION (also used by the permission flow)
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
    // print('confirmAction error: $e');
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
        child: SingleChildScrollView(
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
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ChatText,
                        side: const BorderSide(color: ChatBorder),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor:
                        destructive ? Colors.white : ChatBackground,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}