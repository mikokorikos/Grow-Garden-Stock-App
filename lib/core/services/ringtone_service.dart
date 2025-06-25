import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class RingtoneService {
  final FlutterRingtonePlayer _player = FlutterRingtonePlayer();
  bool _isPlaying = false; // Se cambió a privado para encapsulación

  bool get isPlaying => _isPlaying; // Getter para observar el estado si es necesario

  void play() {
    if (_isPlaying) return;
    _isPlaying = true;
    // Considerar hacer el looping configurable si es necesario en el futuro
    _player.playAlarm(asAlarm: true, looping: true);
  }

  void stop() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _player.stop();
  }
}
