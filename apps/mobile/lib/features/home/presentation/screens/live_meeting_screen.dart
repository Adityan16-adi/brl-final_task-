import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/theme/clay_theme.dart';

/// In-meeting session chat message model
class MeetingChatMessage {
  const MeetingChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.time,
    required this.isLocal,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime time;
  final bool isLocal;
}

/// Live audio/video meeting room powered by LiveKit WebRTC.
/// Supports room connection, camera/mic toggles, camera flipping,
/// real-time hand-raising via data messages, draggable self-view,
/// participant pinning, and in-meeting live chat via data messages.
class LiveMeetingScreen extends StatefulWidget {
  const LiveMeetingScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.roomTitle,
    this.isTeacher = false,
    this.autoConnect = true,
  });

  final String serverUrl;
  final String token;
  final String roomTitle;
  final bool isTeacher;
  final bool autoConnect;

  @override
  State<LiveMeetingScreen> createState() => _LiveMeetingScreenState();
}

class _LiveMeetingScreenState extends State<LiveMeetingScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _isConnecting = true;
  String? _errorMessage;

  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _isHandRaised = false;
  bool _isScreenSharing = false;

  // Map of participant identity -> display name of raised hands
  final Map<String, String> _raisedHands = {};
  final List<Participant> _participants = [];

  // Pinned participant identity
  String? _pinnedParticipantId;

  // Floating draggable self-view coordinates (initialized dynamically)
  Offset? _selfViewPosition;

  // In-meeting chat
  final List<MeetingChatMessage> _chatMessages = [];
  final ValueNotifier<int> _chatNotifier = ValueNotifier<int>(0);
  int _unreadChatCount = 0;
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoConnect) {
      _connectToRoom();
    } else {
      _isConnecting = false;
    }
  }

  Future<void> _connectToRoom() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultVideoPublishOptions: VideoPublishOptions(simulcast: true),
        ),
      );

      _room = room;
      _listener = room.createListener();

      _listener!
        ..on<RoomConnectedEvent>((_) => _updateParticipants())
        ..on<ParticipantConnectedEvent>((_) => _updateParticipants())
        ..on<ParticipantDisconnectedEvent>((event) {
          if (event.participant.identity.isNotEmpty) {
            _raisedHands.remove(event.participant.identity);
            if (_pinnedParticipantId == event.participant.identity) {
              _pinnedParticipantId = null;
            }
          }
          _updateParticipants();
        })
        ..on<TrackSubscribedEvent>((_) => setState(() {}))
        ..on<TrackUnsubscribedEvent>((_) => setState(() {}))
        ..on<TrackMutedEvent>((_) => setState(() {}))
        ..on<TrackUnmutedEvent>((_) => setState(() {}))
        ..on<DataReceivedEvent>(_handleDataReceived)
        ..on<RoomDisconnectedEvent>((event) {
          if (mounted) {
            Navigator.of(context).maybePop();
          }
        });

      await room.connect(widget.serverUrl, widget.token);

      // Publish local camera and mic
      try {
        await room.localParticipant?.setCameraEnabled(_cameraEnabled);
        await room.localParticipant?.setMicrophoneEnabled(_micEnabled);
      } catch (e) {
        debugPrint('Media publish permission notice: $e');
      }

      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        _updateParticipants();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _handleDataReceived(DataReceivedEvent event) {
    if (event.topic == 'hand') {
      try {
        final jsonStr = utf8.decode(event.data);
        final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
        final type = payload['type'] as String?;
        final userId = payload['user'] as String? ?? event.participant?.identity;
        final userName = payload['name'] as String? ?? event.participant?.name ?? userId;

        if (type == 'lower_all') {
          setState(() {
            _raisedHands.clear();
            _isHandRaised = false;
          });
        } else if (userId != null) {
          setState(() {
            if (type == 'raise') {
              _raisedHands[userId] = (userName != null && userName.isNotEmpty) ? userName : userId;
            } else if (type == 'lower') {
              _raisedHands.remove(userId);
              if (userId == _room?.localParticipant?.identity) {
                _isHandRaised = false;
              }
            }
          });
        }
      } catch (e) {
        debugPrint('Hand data parse error: $e');
      }
    } else if (event.topic == 'chat') {
      try {
        final jsonStr = utf8.decode(event.data);
        final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
        final text = payload['text'] as String? ?? '';
        if (text.trim().isEmpty) return;

        final senderId = payload['senderId'] as String? ?? event.participant?.identity ?? '';
        // Skip duplicate message if echoed back for local sender
        if (senderId == _room?.localParticipant?.identity) return;

        final senderName = payload['senderName'] as String? ?? event.participant?.name ?? 'Participant';
        final timestampStr = payload['timestamp'] as String?;
        final time = timestampStr != null
            ? (DateTime.tryParse(timestampStr) ?? DateTime.now())
            : DateTime.now();

        if (mounted) {
          setState(() {
            _chatMessages.add(
              MeetingChatMessage(
                id: '${DateTime.now().microsecondsSinceEpoch}',
                senderId: senderId,
                senderName: senderName,
                text: text,
                time: time,
                isLocal: false,
              ),
            );
            if (!_isChatOpen) {
              _unreadChatCount++;
            }
          });
          _chatNotifier.value++;
        }
      } catch (e) {
        debugPrint('Chat data parse error: $e');
      }
    }
  }

  void _updateParticipants() {
    if (_room == null || !mounted) return;
    setState(() {
      _participants
        ..clear()
        ..addAll(_room!.remoteParticipants.values);
    });
  }

  void _togglePin(String identity) {
    setState(() {
      if (_pinnedParticipantId == identity) {
        _pinnedParticipantId = null;
      } else {
        _pinnedParticipantId = identity;
      }
    });
  }

  Future<void> _sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final local = _room?.localParticipant;
    final myId = local?.identity ?? 'local-user';
    final myName = (local?.name != null && local!.name.isNotEmpty)
        ? local.name
        : (widget.isTeacher ? 'Teacher' : 'Student');
    final now = DateTime.now();

    final payload = {
      'text': trimmed,
      'senderId': myId,
      'senderName': myName,
      'timestamp': now.toIso8601String(),
    };

    if (local != null) {
      try {
        await local.publishData(
          utf8.encode(jsonEncode(payload)),
          topic: 'chat',
          reliable: true,
        );
      } catch (e) {
        debugPrint('Chat publish error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _chatMessages.add(
          MeetingChatMessage(
            id: '${now.microsecondsSinceEpoch}',
            senderId: myId,
            senderName: 'You',
            text: trimmed,
            time: now,
            isLocal: true,
          ),
        );
      });
      _chatNotifier.value++;
    }
  }

  void _openChatSheet() {
    setState(() {
      _isChatOpen = true;
      _unreadChatCount = 0;
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _InMeetingChatSheet(
        messages: _chatMessages,
        chatNotifier: _chatNotifier,
        onSendMessage: _sendChatMessage,
        isDark: isDark,
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isChatOpen = false;
        });
      }
    });
  }

  Future<void> _toggleMic() async {
    final newState = !_micEnabled;
    setState(() => _micEnabled = newState);
    final local = _room?.localParticipant;
    if (local != null) {
      try {
        await local.setMicrophoneEnabled(newState);
      } catch (e) {
        _showSnack('Failed to toggle microphone: $e');
      }
    }
  }

  Future<void> _toggleCamera() async {
    final newState = !_cameraEnabled;
    setState(() => _cameraEnabled = newState);
    final local = _room?.localParticipant;
    if (local != null) {
      try {
        await local.setCameraEnabled(newState);
      } catch (e) {
        _showSnack('Failed to toggle camera: $e');
      }
    }
  }

  Future<void> _flipCamera() async {
    final local = _room?.localParticipant;
    if (local == null) {
      _showSnack('Camera flip not available: no active participant.');
      return;
    }
    try {
      for (final pub in local.videoTrackPublications) {
        final track = pub.track;
        if (track is LocalVideoTrack && track.currentOptions is CameraCaptureOptions) {
          final currentPos = (track.currentOptions as CameraCaptureOptions).cameraPosition;
          final nextPos = currentPos == CameraPosition.front ? CameraPosition.back : CameraPosition.front;
          await track.setCameraPosition(nextPos);
          if (mounted) {
            _showSnack('Switched camera to ${nextPos.name}');
          }
          return;
        }
      }
      _showSnack('Camera flip not available on current track.');
    } catch (e) {
      debugPrint('Flip camera error: $e');
      _showSnack('Camera flip error: $e');
    }
  }

  Future<void> _toggleRaiseHand() async {
    final newRaised = !_isHandRaised;
    final local = _room?.localParticipant;
    final myId = local?.identity ?? 'local-user';
    final myName = (local?.name != null && local!.name.isNotEmpty) ? local.name : 'You';

    final payload = {
      'type': newRaised ? 'raise' : 'lower',
      'user': myId,
      'name': myName,
    };

    if (local != null) {
      try {
        await local.publishData(
          utf8.encode(jsonEncode(payload)),
          topic: 'hand',
          reliable: true,
        );
      } catch (e) {
        debugPrint('Raise hand publish error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isHandRaised = newRaised;
        if (newRaised) {
          _raisedHands[myId] = myName;
        } else {
          _raisedHands.remove(myId);
        }
      });
      _showSnack(newRaised ? 'Hand raised' : 'Hand lowered');
    }
  }

  Future<void> _lowerHandForUser(String userId) async {
    final local = _room?.localParticipant;
    final payload = {
      'type': 'lower',
      'user': userId,
    };

    try {
      await local?.publishData(
        utf8.encode(jsonEncode(payload)),
        topic: 'hand',
        reliable: true,
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _raisedHands.remove(userId);
        if (userId == local?.identity) {
          _isHandRaised = false;
        }
      });
    }
  }

  Future<void> _lowerAllHands() async {
    final local = _room?.localParticipant;
    final payload = {'type': 'lower_all'};

    try {
      await local?.publishData(
        utf8.encode(jsonEncode(payload)),
        topic: 'hand',
        reliable: true,
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _raisedHands.clear();
        _isHandRaised = false;
      });
      _showSnack('All hands lowered');
    }
  }

  Future<void> _toggleScreenShare() async {
    final local = _room?.localParticipant;
    if (local == null) return;

    try {
      final newState = !_isScreenSharing;
      await local.setScreenShareEnabled(newState);
      if (mounted) {
        setState(() => _isScreenSharing = newState);
      }
    } catch (e) {
      debugPrint('Screen share error: $e');
      if (mounted) {
        _showSnack('Screen sharing is not supported or was cancelled on this device.');
      }
    }
  }

  Future<void> _leaveRoom() async {
    try {
      await _room?.disconnect();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _chatNotifier.dispose();
    _listener?.dispose();
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0F1C) : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          widget.roomTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 10),
                const SizedBox(width: 6),
                Text(
                  '${_participants.length + 1} LIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Screen sharing banner
            if (_isScreenSharing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: ClayTokens.brightBlue,
                child: Row(
                  children: [
                    const Icon(Icons.screen_share_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'You are sharing your screen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleScreenShare,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ClayTokens.brightBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Stop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Video Grid / Content
            Expanded(
              child: Stack(
                children: [
                  _buildVideoLayout(),
                  if (widget.isTeacher && _raisedHands.isNotEmpty)
                    _buildTeacherRaisedHandsCard(),
                ],
              ),
            ),

            // Call Controls Bar
            _buildControlsBar(),
          ],
        ),
      ),
    );
  }

  /// Docked card for teachers showing raised hands with dismiss and lower-all
  Widget _buildTeacherRaisedHandsCard() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        width: 220,
        constraints: const BoxConstraints(maxHeight: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ClayTokens.pragtiOrange.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pan_tool_rounded, size: 14, color: ClayTokens.pragtiOrange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Raised Hands (${_raisedHands.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _lowerAllHands,
                  child: const Text(
                    'Lower all',
                    style: TextStyle(
                      color: ClayTokens.pragtiOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _raisedHands.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white54),
                          onPressed: () => _lowerHandForUser(entry.key),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Primary video layout:
  /// - Screen share if active
  /// - Large active/pinned participant filling most of the screen
  /// - Horizontal strip of remote participants if 2 or more remote participants
  /// - Floating draggable self-view in a corner for local user
  Widget _buildVideoLayout() {
    if (_isConnecting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Connecting to LiveKit room...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text(
                'LiveKit Room Connection Failed',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _connectToRoom,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    final localParticipant = _room?.localParticipant;

    // Check for an active screen-share track (local or remote)
    TrackPublication<Track>? screenTrackPub;
    Participant? screenSharer;

    if (localParticipant != null) {
      for (final pub in localParticipant.videoTrackPublications) {
        if (pub.source == TrackSource.screenShareVideo && pub.track != null) {
          screenTrackPub = pub;
          screenSharer = localParticipant;
          break;
        }
      }
    }
    if (screenTrackPub == null) {
      for (final p in _participants) {
        for (final pub in p.videoTrackPublications) {
          if (pub.source == TrackSource.screenShareVideo && pub.track != null) {
            screenTrackPub = pub;
            screenSharer = p;
            break;
          }
        }
        if (screenTrackPub != null) break;
      }
    }

    // Prominent tile for active screen share
    if (screenTrackPub != null && screenTrackPub.track is VideoTrack) {
      return Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ClayTokens.brightBlue.withValues(alpha: 0.6), width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoTrackRenderer(screenTrackPub.track as VideoTrack),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.screen_share_rounded, size: 14, color: ClayTokens.brightBlue),
                          const SizedBox(width: 6),
                          Text(
                            '${screenSharer?.name ?? "Shared"} (Screen)',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Participant thumbnails in a horizontal strip below
          SizedBox(
            height: 116,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                if (localParticipant != null)
                  Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 8),
                    child: _buildParticipantTile(
                      localParticipant,
                      isLocal: true,
                      label: 'You (${widget.isTeacher ? "Teacher" : "Student"})',
                      isPinned: _pinnedParticipantId == localParticipant.identity,
                      onTapPin: () => _togglePin(localParticipant.identity),
                    ),
                  ),
                ..._participants.map((p) => Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 8),
                      child: _buildParticipantTile(
                        p,
                        isLocal: false,
                        label: p.name.isNotEmpty ? p.name : p.identity,
                        isPinned: _pinnedParticipantId == p.identity,
                        onTapPin: () => _togglePin(p.identity),
                      ),
                    )),
              ],
            ),
          ),
        ],
      );
    }

    // Determine the main participant
    Participant? mainParticipant;
    bool isMainLocal = false;

    if (_pinnedParticipantId != null) {
      if (localParticipant != null && localParticipant.identity == _pinnedParticipantId) {
        mainParticipant = localParticipant;
        isMainLocal = true;
      } else {
        for (final p in _participants) {
          if (p.identity == _pinnedParticipantId) {
            mainParticipant = p;
            break;
          }
        }
      }
    }

    if (mainParticipant == null) {
      if (_participants.isNotEmpty) {
        mainParticipant = _participants.first;
        isMainLocal = false;
      } else {
        mainParticipant = localParticipant;
        isMainLocal = true;
      }
    }

    final hasRemoteParticipants = _participants.isNotEmpty;
    final showFloatingSelfView = localParticipant != null && hasRemoteParticipants && !isMainLocal;

    // Remaining remote participants to display in the horizontal strip below
    final stripParticipants = _participants
        .where((p) => p.identity != mainParticipant?.identity)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        return Stack(
          children: [
            Column(
              children: [
                // Main active/pinned participant tile filling most of the screen
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    child: mainParticipant != null
                        ? _buildParticipantTile(
                            mainParticipant,
                            isLocal: isMainLocal,
                            label: isMainLocal
                                ? 'You (${widget.isTeacher ? "Teacher" : "Student"})'
                                : (mainParticipant.name.isNotEmpty
                                    ? mainParticipant.name
                                    : mainParticipant.identity),
                            isPinned: _pinnedParticipantId == mainParticipant.identity,
                            onTapPin: () => _togglePin(mainParticipant!.identity),
                            isMainTile: true,
                          )
                        : _buildEmptyRoomPlaceholder(),
                  ),
                ),

                // Horizontal strip for 2 or more remote participants
                if (_participants.length >= 2) ...[
                  Container(
                    height: 116,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: stripParticipants.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final participant = stripParticipants[index];
                        return SizedBox(
                          width: 130,
                          child: _buildParticipantTile(
                            participant,
                            isLocal: false,
                            label: participant.name.isNotEmpty
                                ? participant.name
                                : participant.identity,
                            isPinned: _pinnedParticipantId == participant.identity,
                            onTapPin: () => _togglePin(participant.identity),
                            onTapTile: () => _togglePin(participant.identity),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),

            // Small floating draggable self-view in a corner
            if (showFloatingSelfView)
              _buildDraggableSelfView(maxWidth, maxHeight, localParticipant),
          ],
        );
      },
    );
  }

  Widget _buildEmptyRoomPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_camera_front_rounded, size: 52, color: Colors.white24),
            SizedBox(height: 12),
            Text(
              'Waiting for class session...',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Small floating self-view in a corner that can be dragged
  Widget _buildDraggableSelfView(
    double maxWidth,
    double maxHeight,
    Participant localParticipant,
  ) {
    const selfWidth = 110.0;
    const selfHeight = 145.0;

    // Default position: top right corner
    final pos = _selfViewPosition ?? Offset(maxWidth - selfWidth - 14, 14);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final maxX = (maxWidth - selfWidth - 8.0).clamp(8.0, double.infinity);
            final maxY = (maxHeight - selfHeight - 8.0).clamp(8.0, double.infinity);
            final newX = (pos.dx + details.delta.dx).clamp(8.0, maxX);
            final newY = (pos.dy + details.delta.dy).clamp(8.0, maxY);
            _selfViewPosition = Offset(newX, newY);
          });
        },
        child: Container(
          width: selfWidth,
          height: selfHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ClayTokens.brightBlue.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildParticipantTileContent(
                localParticipant,
                isLocal: true,
                label: 'You',
              ),

              // Drag indicator and pin toggle header
              Positioned(
                top: 4,
                left: 4,
                right: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.drag_indicator_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _togglePin(localParticipant.identity),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _pinnedParticipantId == localParticipant.identity
                              ? ClayTokens.brightBlue
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _pinnedParticipantId == localParticipant.identity
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom label
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!_micEnabled) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.mic_off, color: Colors.redAccent, size: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Individual participant tile with name, pin icon, camera/avatar, and hand raise badge
  Widget _buildParticipantTile(
    Participant? participant, {
    required bool isLocal,
    required String label,
    bool isPinned = false,
    bool isMainTile = false,
    VoidCallback? onTapPin,
    VoidCallback? onTapTile,
  }) {
    if (participant == null) return const SizedBox.shrink();

    final isHandUp = _raisedHands.containsKey(participant.identity);

    return GestureDetector(
      onTap: onTapTile ?? onTapPin,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPinned
                ? ClayTokens.brightBlue
                : (isHandUp ? ClayTokens.pragtiOrange : Colors.white12),
            width: (isPinned || isHandUp) ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildParticipantTileContent(participant, isLocal: isLocal, label: label),

            // Pin icon & indicator in top-left
            Positioned(
              left: 8,
              top: 8,
              child: GestureDetector(
                onTap: onTapPin,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPinned
                        ? ClayTokens.brightBlue
                        : Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        size: 13,
                        color: Colors.white,
                      ),
                      if (isPinned) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'Pinned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Hand Raised badge overlay in top right
            if (isHandUp)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: ClayTokens.pragtiOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pan_tool_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Raised',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

            // Name label overlay in bottom left
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (participant.isMuted) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.mic_off, color: Colors.redAccent, size: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantTileContent(
    Participant participant, {
    required bool isLocal,
    required String label,
  }) {
    // Check for active camera video track
    TrackPublication<Track>? videoPub;
    for (final pub in participant.videoTrackPublications) {
      if (pub.track != null && !pub.muted && pub.source != TrackSource.screenShareVideo) {
        videoPub = pub;
        break;
      }
    }

    final hasVideo = videoPub != null && videoPub.track != null && !videoPub.muted;

    if (hasVideo && videoPub.track is VideoTrack) {
      return VideoTrackRenderer(videoPub.track as VideoTrack);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: ClayTokens.navy.withValues(alpha: 0.8),
            child: Text(
              label.isNotEmpty ? label[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Camera Off',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Ergonomic call controls bar with thumb-friendly reach:
  /// Mic, Camera, Flip, Hand, Chat (with unread badge), Share, Leave
  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Microphone
              _buildControlButton(
                icon: _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                label: _micEnabled ? 'Mute' : 'Unmute',
                isActive: _micEnabled,
                activeColor: Colors.white24,
                inactiveColor: Colors.redAccent,
                onTap: _toggleMic,
              ),

              // 2. Camera
              _buildControlButton(
                icon: _cameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                label: _cameraEnabled ? 'Camera' : 'Start Cam',
                isActive: _cameraEnabled,
                activeColor: Colors.white24,
                inactiveColor: Colors.redAccent,
                onTap: _toggleCamera,
              ),

              // 3. Flip Camera
              _buildControlButton(
                icon: Icons.flip_camera_ios_rounded,
                label: 'Flip',
                isActive: false,
                activeColor: Colors.white24,
                inactiveColor: Colors.white24,
                onTap: _flipCamera,
              ),

              // 4. Raise Hand
              _buildControlButton(
                icon: Icons.pan_tool_rounded,
                label: _isHandRaised ? 'Lower' : 'Hand',
                isActive: _isHandRaised,
                activeColor: ClayTokens.pragtiOrange,
                inactiveColor: Colors.white24,
                onTap: _toggleRaiseHand,
              ),

              // 5. In-Meeting Chat with unread badge
              _buildControlButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                isActive: _isChatOpen,
                activeColor: ClayTokens.brightBlue,
                inactiveColor: Colors.white24,
                badgeCount: _unreadChatCount,
                onTap: _openChatSheet,
              ),

              // 6. Screen Share
              _buildControlButton(
                icon: _isScreenSharing ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded,
                label: _isScreenSharing ? 'Stop' : 'Share',
                isActive: _isScreenSharing,
                activeColor: ClayTokens.brightBlue,
                inactiveColor: Colors.white24,
                onTap: _toggleScreenShare,
              ),

              // 7. Leave
              _buildControlButton(
                icon: Icons.call_end_rounded,
                label: 'Leave',
                isActive: true,
                activeColor: const Color(0xFFDC2626),
                inactiveColor: const Color(0xFFDC2626),
                onTap: _leaveRoom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final bgColor = isActive ? activeColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF0F172A),
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// In-meeting live chat modal bottom sheet
class _InMeetingChatSheet extends StatefulWidget {
  const _InMeetingChatSheet({
    required this.messages,
    required this.chatNotifier,
    required this.onSendMessage,
    required this.isDark,
  });

  final List<MeetingChatMessage> messages;
  final ValueNotifier<int> chatNotifier;
  final ValueChanged<String> onSendMessage;
  final bool isDark;

  @override
  State<_InMeetingChatSheet> createState() => _InMeetingChatSheetState();
}

class _InMeetingChatSheetState extends State<_InMeetingChatSheet> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.chatNotifier.addListener(_onChatUpdate);
  }

  void _onChatUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.chatNotifier.removeListener(_onChatUpdate);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage(text);
    _textController.clear();
    setState(() {});
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : ClayTokens.navy;
    final secondaryColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.70,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ClayTokens.brightBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 18,
                    color: ClayTokens.brightBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classroom Chat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Messages only last for this live session',
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: secondaryColor),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Message list
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 44,
                            color: secondaryColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send a question or note to the whole class.',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final msg = widget.messages[index];
                      final isMe = msg.isLocal;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? ClayTokens.brightBlue
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(3),
                              bottomRight: isMe ? const Radius.circular(3) : const Radius.circular(14),
                            ),
                            border: isMe
                                ? null
                                : Border.all(
                                    color: borderColor,
                                    width: 1,
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    msg.senderName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.85)
                                          : ClayTokens.brightBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTime(msg.time),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.65)
                                          : secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: isMe ? Colors.white : textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input field
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(fontSize: 13.5, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Type a message to class...',
                        hintStyle: TextStyle(fontSize: 13, color: secondaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: ClayTokens.brightBlue,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
