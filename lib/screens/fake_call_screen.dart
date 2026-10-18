import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool _answered = false;
  int _seconds = 0;
  Timer? _callTimer;

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  void _answerCall() {
    setState(() => _answered = true);
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFF21262D),
                child: Icon(Icons.person, size: 54, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Text(
                'Mom',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _answered ? _formatDuration(_seconds) : 'Incoming call...',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  color: _answered ? Colors.greenAccent : Colors.white70,
                ),
              ),
              const Spacer(),
              if (!_answered) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline Call
                    Column(
                      children: [
                        FloatingActionButton.large(
                          heroTag: 'decline_call_btn',
                          backgroundColor: const Color(0xFFC8202F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          onPressed: () => app.dismissFakeCall(),
                          child: const Icon(Icons.call_end, size: 36),
                        ),
                        const SizedBox(height: 12),
                        const Text('Decline', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    // Accept Call
                    Column(
                      children: [
                        FloatingActionButton.large(
                          heroTag: 'accept_call_btn',
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          onPressed: _answerCall,
                          child: const Icon(Icons.call, size: 36),
                        ),
                        const SizedBox(height: 12),
                        const Text('Answer', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                // In-Call controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _inCallIcon(Icons.mic_off, 'Mute'),
                    _inCallIcon(Icons.dialpad, 'Keypad'),
                    _inCallIcon(Icons.volume_up, 'Speaker'),
                  ],
                ),
                const SizedBox(height: 40),
                FloatingActionButton.large(
                  heroTag: 'hangup_call_btn',
                  backgroundColor: const Color(0xFFC8202F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  onPressed: () => app.dismissFakeCall(),
                  child: const Icon(Icons.call_end, size: 36),
                ),
                const SizedBox(height: 12),
                const Text('End Call', style: TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inCallIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
