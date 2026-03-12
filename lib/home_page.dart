import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:coffeetimer/parse_locale_tag.dart';
import 'package:coffeetimer/theme_color.dart';
import 'package:coffeetimer/theme_mode_number.dart';
import 'package:coffeetimer/setting_page.dart';
import 'package:coffeetimer/ad_banner_widget.dart';
import 'package:coffeetimer/ad_manager.dart';
import 'package:coffeetimer/model.dart';
import 'package:coffeetimer/loading_screen.dart';
import 'package:coffeetimer/main.dart';
import 'package:coffeetimer/const_value.dart';
import 'package:coffeetimer/water_painter.dart';
import 'package:coffeetimer/splash_particle.dart';
import 'package:coffeetimer/water_layer.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> with TickerProviderStateMixin {
  late AdManager _adManager;
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;
  //
  double videoY = 0;
  int _digitHundreds = 0;
  int _digitTens = 0;
  int _digitOnes = 0;
  int _minutes = 1;
  late Duration _duration;
  late AnimationController _animationController;
  late Animation<double> _animPercent;
  late AudioPlayer _audioPlayer;
  //
  late WaterLayer layer01;
  List<SplashParticle> particles = [];
  double _tiltAngle = 0.0;
  List<Offset> _activeDrops = [];
  late AnimationController _controller;
  StreamSubscription<AccelerometerEvent>? _subscription;
  Timer? _randomTimer;
  final Random _random = Random();
  double _screenWidth = 0.0;
  double _screenHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    _audioPlayer = AudioPlayer();
    _wakelock();
    layer01 = WaterLayer(tension: 0.005, damping: 0.98, spread: 0.4);
    _subscription = accelerometerEventStream().listen((event) {
      if (mounted) {
        setState(() => _tiltAngle = (_tiltAngle * 0.8) + (event.x / 10.0 * 0.2));
      }
    });
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_updatePhysics)..repeat();
    _scheduleNextDrop();
    //
    _minutes = Model.minute;
    if (mounted) {
      setState(() {
        _digitHundreds = _minutes ~/ 100;
        _digitTens = (_minutes % 100) ~/ 10;
        _digitOnes = _minutes % 10;
      });
    }
    //
    _duration = Duration(minutes: _minutes);
    _animationController = AnimationController(
      vsync: this,
      duration: _duration,
    );
    _animationController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        if (Model.soundEnabled && Model.soundVolume > 0) {
          final selected = finishSounds.firstWhere(
            (s) => s['key'] == Model.soundSelect,
            orElse: () => {},
          );
          if (selected.isNotEmpty) {
            _audioPlayer.setVolume(Model.soundVolume);
            _audioPlayer.play(AssetSource('sound/${selected['file']}'));
          }
        }
        if (await Vibration.hasVibrator()) {
          if (Model.vibrateEnabled) {
            Vibration.vibrate(duration: 500);
          }
        }
      }
    });
    _animPercent = Tween<double>(begin: 0, end: 100).animate(_animationController);
    //
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _randomTimer?.cancel();
    _controller.dispose();
    _animationController.dispose();
    _adManager.dispose();
    super.dispose();
  }

  void _wakelock() {
    if (Model.wakelockEnabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  double _surfaceYRatio() {
    return 0.78 + (0.57 - 0.78) * (_animPercent.value / 100.0);
  }

  void _scheduleNextDrop() {
    final int delay = 100 + _random.nextInt(600);
    _randomTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        _startDrop();
      }
      _scheduleNextDrop();
    });
  }

  void _startDrop() {
    if (!mounted) {
      return;
    }
    if (_animationController.isAnimating) {
      setState(() {
        double centerX = _screenWidth / 2;
        double rangeX = (_random.nextDouble() * 20) - 10;
        double startY = _screenHeight * 0.44;
        _activeDrops.add(Offset(centerX + rangeX, startY));
      });
    }
  }

  void _updatePhysics() {
    if (!mounted) {
      return;
    }
    layer01.updateSurfaceCache(_screenWidth, _screenHeight, _tiltAngle, _surfaceYRatio());
    setState(() {
      List<Offset> survivingDrops = [];
      const double dropSpeed = 18.0;
      double dx = -sin(_tiltAngle) * dropSpeed;
      double dy = cos(_tiltAngle) * dropSpeed;
      for (var dropPos in _activeDrops) {
        Offset nextPos = dropPos + Offset(dx, dy);
        double currentSurfaceY = layer01.getCachedY(nextPos.dx, _screenWidth);
        if (nextPos.dy >= currentSurfaceY) {
          _splash(nextPos.dx);
        } else if (nextPos.dx >= -50 && nextPos.dx <= _screenWidth + 50) {
          survivingDrops.add(nextPos);
        }
      }
      _activeDrops = survivingDrops;

      for (var p in particles) {
        double currentSurface = layer01.getCachedY(p.position.dx, _screenWidth);
        p.update(currentSurface);
      }
      particles.removeWhere((p) => p.opacity <= 0);
      layer01.updatePhysics();
    });
  }

  void _splash(double xPos) {
    layer01.splash(xPos, _screenWidth, 20.0);
    for (int i = 0; i < 2; i++) {
      particles.add(SplashParticle(
        position: Offset(xPos, layer01.getSurfaceY(xPos, _screenWidth, _screenHeight, _tiltAngle, _surfaceYRatio()) - 2),
        velocity: Offset(_random.nextDouble() * 4 - 2, -_random.nextDouble() * 5 - 2),
      ));
    }
  }

  Map<String, int> _convertProgress(double percent, int nMinutes) {
    final totalSeconds = nMinutes * 60 * (percent / 100);
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).round();
    final fraction = ((totalSeconds - totalSeconds.floor()) * 10).round();
    return {
      'minutes': minutes,
      'seconds': seconds,
      'fraction': fraction.clamp(0,9),
    };
  }

  Future<void> _onOpenSetting() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingPage()),
    );
    if (!mounted) {
      return;
    }
    if (updated == true) {
      final mainState = context.findAncestorStateOfType<MainAppState>();
      if (mainState != null) {
        mainState
          ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
          ..locale = parseLocaleTag(Model.languageCode)
          ..setState(() {});
      }
      _isFirst = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(body: LoadingScreen());
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
      _screenWidth = MediaQuery.of(context).size.width;
      _screenHeight = MediaQuery.of(context).size.height;
    }
    return Stack(
      children: [
        RepaintBoundary(
          child: SizedBox(
            width: _screenWidth,
            height: _screenHeight,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 1024,
                height: 1024,
                child: Image.asset('assets/image/coffee_back.webp', cacheWidth: 1024),
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _animationController]),
            builder: (context, _) {
              return SizedBox(
                width: _screenWidth,
                height: _screenHeight,
                child: CustomPaint(
                  painter: WaterPainter(
                    layer01,
                    _tiltAngle,
                    _activeDrops,
                    particles,
                    _surfaceYRatio(),
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),
        RepaintBoundary(
          child: SizedBox(
            width: _screenWidth,
            height: _screenHeight,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 1024,
                height: 1024,
                child: Image.asset('assets/image/coffee_front.webp', cacheWidth: 1024),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) => _buildPercentLabels(context, _screenHeight),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            foregroundColor: _themeColor.mainForeColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _onOpenSetting,
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, _) => _buildDigitTimerSet(),
                ),
              ),
            ),
          ),
          bottomNavigationBar: AdBannerWidget(adManager: _adManager),
        ),
      ],
    );
  }

  Widget _buildPercentLabels(BuildContext context, double screenHeight) {
    if (screenHeight.isNaN || screenHeight == 0) {
      return const SizedBox.shrink();
    }
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final baseBottom = screenHeight * 0.574;
    final range = screenHeight * 0.208;
    List<Widget> labels = [];
    for (int i = 0; i <= 10; i++) {
      double t = i / 10;
      double y = baseBottom + (1 - t) * range;
      labels.add(
        Positioned(
          top: y - 10,
          left: isRTL ? 10 : null,
          right: isRTL ? null : 10,
          child: Text(
            "${i * 10}%",
            style: TextStyle(
              color: _themeColor.mainAccentForeColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
    }
    return Stack(children: labels);
  }

  Widget _buildDigitTimerSet() {
    final double progressPercent = _animPercent.value;
    final Map<String, int> remain = _convertProgress(100 - progressPercent, _minutes);
    final int selectedMinutes = _digitHundreds * 100 + _digitTens * 10 + _digitOnes;
    final outlinedStyle = OutlinedButton.styleFrom(
      foregroundColor: _themeColor.mainAccentForeColor,
      side: BorderSide(color: _themeColor.mainAccentForeColor.withValues(alpha: 0.5)),
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDigitPicker(
              value: _digitHundreds,
              onSelectedItemChanged: (v) => setState(() => _digitHundreds = v),
            ),
            _buildDigitPicker(
              value: _digitTens,
              onSelectedItemChanged: (v) => setState(() => _digitTens = v),
            ),
            _buildDigitPicker(
              value: _digitOnes,
              onSelectedItemChanged: (v) => setState(() => _digitOnes = v),
            ),
          ],
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '$selectedMinutes min.',
                style: TextStyle(
                  fontSize: 16,
                  color: _themeColor.mainAccentForeColor,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 140,
                child: AnimatedOpacity(
                  opacity: 0.8,
                  duration: const Duration(milliseconds: 200),
                  child: OutlinedButton.icon(
                    style: outlinedStyle,
                    onPressed: () {
                      _minutes = selectedMinutes;
                      _duration = Duration(minutes: _minutes);
                      _animationController.duration = _duration;
                      _animationController.forward(from: 0);
                      Model.setMinute(_minutes);
                      setState(() {});
                    },
                    icon: const Icon(Icons.play_circle_fill, size: 20),
                    label: const Text('START', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 66,
                    child: AnimatedOpacity(
                      opacity: _animationController.isAnimating ? 0.8 : 0.2,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_animationController.isAnimating,
                        child: OutlinedButton(
                          style: outlinedStyle,
                          onPressed: () {
                            _animationController.stop();
                            setState(() {});
                          },
                          child: const Icon(Icons.pause_circle_outline),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 66,
                    child: AnimatedOpacity(
                      opacity: _animationController.isAnimating ? 0.2 : 0.8,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: _animationController.isAnimating,
                        child: OutlinedButton(
                          style: outlinedStyle,
                          onPressed: () {
                            _animationController.forward();
                            setState(() {});
                          },
                          child: const Icon(Icons.play_circle_outline),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPercentSign(progressPercent),
              _buildMinuteSign(remain),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigitPicker({required int value,required ValueChanged<int> onSelectedItemChanged}) {
    return SizedBox(
      width: 48,
      height: 120,
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: value),
        itemExtent: 40,
        onSelectedItemChanged: onSelectedItemChanged,
        children: List.generate(10,
          (index) => Center(
            child: Text(
              '$index',
              style: TextStyle(fontSize: 28,color: _themeColor.mainAccentForeColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPercentSign(double progressPercent) {
    return Opacity(
      opacity: Model.percentDisplayOpacity,
      child: SizedBox(
        width: double.infinity,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: progressPercent.toStringAsFixed(2),
                style: GoogleFonts.shareTechMono(
                  color: _themeColor.mainAccentForeColor,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const WidgetSpan(child: SizedBox(width: 4)),
              TextSpan(
                text: "%",
                style: GoogleFonts.shareTechMono(
                  color: _themeColor.mainAccentForeColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                )
              )
            ]
          )
        )
      )
    );
  }

  Widget _buildMinuteSign(Map<String, int> remain) {
    return Opacity(
      opacity: Model.timeDisplayOpacity,
      child: SizedBox(
        width: double.infinity,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: remain['minutes'].toString(),
                style: GoogleFonts.shareTechMono(
                  color: _themeColor.mainAccentForeColor,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ":",
                style: GoogleFonts.shareTechMono(
                  color: _themeColor.mainAccentForeColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: remain['seconds'].toString().padLeft(2, '0'),
                style: GoogleFonts.shareTechMono(
                  color: _themeColor.mainAccentForeColor,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ".${remain['fraction']}",
                style: GoogleFonts.shareTechMono(
                  color: _themeColor.mainAccentForeColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                )
              )
            ]
          )
        )
      )
    );
  }

}
