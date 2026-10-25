import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/theme/clay_theme.dart';

/// Live audio/video meeting room powered by LiveKit WebRTC.
/// Handles room connection, local media tracks, remote participants, and media toggles.
class LiveMeetingScreen extends StatefulWidget {
  const LiveMeetingScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.roomTitle,
    this.isTeacher = false,
  });

  final String serverUrl;
  final String token;
  final String roomTitle;
  final bool isTeacher;

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

  final List<Participant> _participants = [];

  @override
  void initState() {
    super.initState();
    _connectToRoom();
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
        ..on<ParticipantDisconnectedEvent>((_) => _updateParticipants())
        ..on<TrackSubscribedEvent>((_) => setState(() {}))
        ..on<TrackUnsubscribedEvent>((_) => setState(() {}))
        ..on<TrackMutedEvent>((_) => setState(() {}))
        ..on<TrackUnmutedEvent>((_) => setState(() {}))
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

  void _updateParticipants() {
    if (_room == null || !mounted) return;
    setState(() {
      _participants
        ..clear()
        ..addAll(_room!.remoteParticipants.values);
    });
  }

  Future<void> _toggleMic() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    try {
      final newState = !_micEnabled;
      await local.setMicrophoneEnabled(newState);
      setState(() => _micEnabled = newState);
    } catch (e) {
      _showSnack('Failed to toggle microphone: $e');
    }
  }

  Future<void> _toggleCamera() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    try {
      final newState = !_cameraEnabled;
      await local.setCameraEnabled(newState);
      setState(() => _cameraEnabled = newState);
    } catch (e) {
      _showSnack('Failed to toggle camera: $e');
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        iconTheme: const IconThemeData(color: Colors.white),
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
              color: Colors.redAccent.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 10),
                const SizedBox(width: 6),
                Text(
                  '${_participants.length + 1} LIVE',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildVideoGrid(colors)),
            _buildControlsBar(colors),
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
              'Connecting to LiveKit WebRTC room...',
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

    // Video display grid: local user + remote participants
    final localParticipant = _room?.localParticipant;
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

    // Check for active video track
    TrackPublication<Track>? videoPub;
    for (final pub in participant.videoTrackPublications) {
      if (pub.track != null && !pub.muted) {
        videoPub = pub;
        break;
      }
    }

    final hasVideo = videoPub != null && videoPub.track != null && !videoPub.muted;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
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
                    radius: 28,
                    backgroundColor: ClayTokens.deepIndigo.withValues(alpha: 0.6),
                    child: Text(
                      label.isNotEmpty ? label[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Camera Off',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  ),
                ],
              ),
            ),

          // Label overlay
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
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

  Widget _buildControlsBar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Microphone Toggle
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: _micEnabled ? Colors.white24 : Colors.redAccent,
              padding: const EdgeInsets.all(14),
            ),
            onPressed: _toggleMic,
            icon: Icon(
              _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          // Camera Toggle
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: _cameraEnabled ? Colors.white24 : Colors.redAccent,
              padding: const EdgeInsets.all(14),
            ),
            onPressed: _toggleCamera,
            icon: Icon(
              _cameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          // Leave / End Call
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: _leaveRoom,
            icon: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
