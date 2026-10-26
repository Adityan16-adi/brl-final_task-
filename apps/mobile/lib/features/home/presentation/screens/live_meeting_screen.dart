import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/theme/clay_theme.dart';

/// Live audio/video meeting room powered by LiveKit WebRTC.
/// Supports room connection, camera/mic toggles, camera flipping,
/// real-time hand-raising via data messages, and screen sharing.
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
    HapticFeedback.lightImpact();
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
    _listener?.dispose();
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
                  _buildVideoGrid(colors),
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

  Widget _buildVideoGrid(ColorScheme colors) {
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

    // Check local
    if (localParticipant != null) {
      for (final pub in localParticipant.videoTrackPublications) {
        if (pub.source == TrackSource.screenShareVideo && pub.track != null) {
          screenTrackPub = pub;
          screenSharer = localParticipant;
          break;
        }
      }
    }
    // Check remote if not found
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

    // If there is an active screen share, make it the prominent tile!
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
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                if (localParticipant != null)
                  Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 8),
                    child: _buildParticipantTile(
                      localParticipant,
                      isLocal: true,
                      label: 'You (${widget.isTeacher ? "Teacher" : "Student"})',
                    ),
                  ),
                ..._participants.map((p) => Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 8),
                      child: _buildParticipantTile(
                        p,
                        isLocal: false,
                        label: p.name.isNotEmpty ? p.name : p.identity,
                      ),
                    )),
              ],
            ),
          ),
        ],
      );
    }

    final totalCount = (_participants.length) + (localParticipant != null ? 1 : 0);

    if (totalCount <= 1) {
      // Just local participant
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildParticipantTile(
              localParticipant,
              isLocal: true,
              label: 'You (${widget.isTeacher ? "Teacher" : "Student"})',
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == 0 && localParticipant != null) {
          return _buildParticipantTile(
            localParticipant,
            isLocal: true,
            label: 'You (${widget.isTeacher ? "Teacher" : "Student"})',
          );
        }
        final remote = _participants[index - (localParticipant != null ? 1 : 0)];
        return _buildParticipantTile(
          remote,
          isLocal: false,
          label: remote.name.isNotEmpty ? remote.name : remote.identity,
        );
      },
    );
  }

  Widget _buildParticipantTile(
    Participant? participant, {
    required bool isLocal,
    required String label,
  }) {
    if (participant == null) return const SizedBox.shrink();

    // Check for active camera video track
    TrackPublication<Track>? videoPub;
    for (final pub in participant.videoTrackPublications) {
      if (pub.track != null && !pub.muted && pub.source != TrackSource.screenShareVideo) {
        videoPub = pub;
        break;
      }
    }

    final hasVideo = videoPub != null && videoPub.track != null && !videoPub.muted;
    final isHandUp = _raisedHands.containsKey(participant.identity);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHandUp ? ClayTokens.pragtiOrange : Colors.white12,
          width: isHandUp ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasVideo && videoPub.track is VideoTrack)
            VideoTrackRenderer(videoPub.track as VideoTrack)
          else
            Center(
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

          // Label overlay in bottom left
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
    );
  }

  /// Full 6-button call controls bar: Mic, Camera, Flip, Raise Hand, Share Screen, Leave
  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

          // 5. Screen Share
          _buildControlButton(
            icon: _isScreenSharing ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded,
            label: _isScreenSharing ? 'Stop' : 'Share',
            isActive: _isScreenSharing,
            activeColor: ClayTokens.brightBlue,
            inactiveColor: Colors.white24,
            onTap: _toggleScreenShare,
          ),

          // 6. Leave
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
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    final bgColor = isActive ? activeColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
