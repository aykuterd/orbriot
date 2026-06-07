import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

/// Tüm oyun seslerini yöneten servis.
/// HomeBinding'de permanent olarak kaydedilir.
class SoundService extends GetxService {
  static const int _poolSize = 8;

  static const List<String> _bgmPlaylist = [
    'music1.mp3',
    'music2.mp3',
    'music3.mp3',
    'music4.mp3',
  ];

  // BGM varsayılan ses düzeyi — SettingsController tarafından üzerine yazılır
  static const double _defaultBgmVolume = 0.35;

  late final List<AudioPlayer> _pool;
  late final AudioPlayer _bgmPlayer;
  int _poolIndex = 0;

  int _currentTrack = 0;
  bool _bgmActive = false;

  bool _sfxEnabled = true;
  bool _bgmEnabled = true;
  double _sfxVolume = 1.0;

  // Aynı anda çok fazla ses üst üste binmesin diye throttle
  DateTime? _lastWallBounce;
  DateTime? _lastBrickHit;
  static const _wallBounceThrottle = Duration(milliseconds: 100);
  static const _brickHitThrottle   = Duration(milliseconds: 60);

  Future<SoundService> init() async {
    _pool = List.generate(_poolSize, (_) => AudioPlayer());
    _bgmPlayer = AudioPlayer();
    await _bgmPlayer.setVolume(_defaultBgmVolume);
    // Parça bitince bir sonrakine geç
    _bgmPlayer.onPlayerComplete.listen((_) {
      if (_bgmActive) _playNextTrack();
    });
    return this;
  }

  // ── Dahili ───────────────────────────────────────────────────────────────

  void _play(String file) {
    if (!_sfxEnabled) return;
    final player = _pool[_poolIndex % _poolSize];
    _poolIndex++;
    // iOS'ta mevcut AVPlayerItem'ı önce temizle; aksi hâlde
    // setUpPlayerItemStatusObservation continuation sızıyor.
    player.stop().then((_) async {
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('sound_effects/$file'));
    });
  }

  bool _throttled(DateTime? last, Duration limit) {
    if (last == null) return false;
    return DateTime.now().difference(last) < limit;
  }

  Future<void> _playNextTrack() async {
    _currentTrack = (_currentTrack + 1) % _bgmPlaylist.length;
    await _bgmPlayer.play(AssetSource('music/${_bgmPlaylist[_currentTrack]}'));
  }

  // ── SFX ──────────────────────────────────────────────────────────────────

  void playWallBounce() {
    if (_throttled(_lastWallBounce, _wallBounceThrottle)) return;
    _lastWallBounce = DateTime.now();
    _play('ball_bounce_wall.mp3');
  }

  void playBrickBounce() {
    if (_throttled(_lastBrickHit, _brickHitThrottle)) return;
    _lastBrickHit = DateTime.now();
    _play('ball_bounce_brick.mp3');
  }

  void playMinusBall()         => _play('shield_hit.mp3');
  void playBrickBreak()        => _play('brick_break.mp3');
  void playBombExplode()       => _play('bomb_explode.mp3');
  void playLaserFire()         => _play('laser_fire.mp3');
  void playChainTrigger()      => _play('chain_trigger.mp3');
  void playShieldHit()         => _play('shield_hit.mp3');
  void playMultiplierCollect() => _play('multiplier_collect.mp3');
  void playGemCollect()        => _play('gem_collect.mp3');
  void playGameOver()          => _play('game_over.mp3');
  void playLevelUp()           => _play('level_up.mp3');
  void playUpgradeBuy()        => _play('upgrade_buy.mp3');
  void playBallLaunch()        => _play('ball_launch.mp3');

  // ── Ayarlar ───────────────────────────────────────────────────────────────

  void setSfxEnabled(bool v) => _sfxEnabled = v;

  void setBgmEnabled(bool v) {
    _bgmEnabled = v;
    if (!v) {
      _bgmPlayer.pause();
    } else if (_bgmActive) {
      _bgmPlayer.resume();
    }
  }

  void setSfxVolume(double v) => _sfxVolume = v;

  Future<void> setBgmVolume(double v) => _bgmPlayer.setVolume(v);

  // ── BGM ──────────────────────────────────────────────────────────────────

  Future<void> startBgm() async {
    if (!_bgmEnabled) return;
    try {
      _bgmActive = true;
      _currentTrack = 0;
      await _bgmPlayer.play(AssetSource('music/${_bgmPlaylist[_currentTrack]}'));
    } catch (_) {
      // Dosya yoksa sessizce devam et
    }
  }

  Future<void> pauseBgm() => _bgmPlayer.pause();

  Future<void> resumeBgm() => _bgmPlayer.resume();

  Future<void> stopBgm() async {
    _bgmActive = false;
    await _bgmPlayer.stop();
  }

  // ── Temizlik ──────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _bgmActive = false;
    for (final p in _pool) {
      p.dispose();
    }
    _bgmPlayer.dispose();
    super.onClose();
  }
}
