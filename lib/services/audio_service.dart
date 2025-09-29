import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  static Future<void> _playAsset(String relativePath,
      {double volume = 1.0}) async {
    try {
      final player = AudioPlayer();
      await player.setVolume(volume);
      // Start playing and dispose when finished
      unawaited(player.play(AssetSource(relativePath)));
      // Dispose once completed
      player.onPlayerComplete.first.then((_) => player.dispose());
    } catch (_) {
      // Fallback to a simple system sound if asset missing or any error
      SystemSound.play(SystemSoundType.alert);
    }
  }

  static Future<void> playSpinStart() async {
    // Optional whoosh; replace with your own file under assets/audio/
    return _playAsset('audio/spin_start.mp3', volume: 0.9);
  }

  static Future<void> playTick() async {
    // Short tick; not used continuously here (SystemSound handles ticks)
    return _playAsset('audio/tick.wav', volume: 0.5);
  }

  static Future<void> playPass() async {
    return _playAsset('audio/pass.mp3');
  }

  static Future<void> playBankrupt() async {
    return _playAsset('audio/bankrupt.mp3');
  }

  static Future<void> playPoints() async {
    return _playAsset('audio/points.mp3');
  }

  static Future<void> playWin() async {
    return _playAsset('audio/win.mp3');
  }
}
