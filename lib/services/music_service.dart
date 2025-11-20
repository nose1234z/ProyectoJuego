import 'package:audioplayers/audioplayers.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentTrack;
  bool _isEnabled = true;

  Future<void> playMenu() async {
    await _playTrack('music/menu.mp3');
  }

  Future<void> playShop() async {
    await _playTrack('music/shop.mp3');
  }

  Future<void> playLevel(int level) async {
    String track;
    switch (level) {
      case 1:
        track = 'music/nivel1.mp3';
        break;
      case 2:
        track = 'music/nivel2.mp3';
        break;
      case 3:
      case 4:
        track = 'music/nivel3.mp3';
        break;
      default:
        track = 'music/nivel1.mp3';
    }
    await _playTrack(track);
  }

  Future<void> _playTrack(String track) async {
    if (!_isEnabled) return;

    if (_currentTrack == track && _audioPlayer.state == PlayerState.playing) {
      return; // Ya está sonando esta pista
    }

    _currentTrack = track;
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.5);
    await _audioPlayer.play(AssetSource(track));
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentTrack = null;
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
