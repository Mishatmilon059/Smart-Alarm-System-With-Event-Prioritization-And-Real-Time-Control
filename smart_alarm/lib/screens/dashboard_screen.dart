import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_data.dart';
import '../models/event_log.dart';
import '../services/blynk_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final BlynkService _blynkService = BlynkService();
  SensorData? _sensorData;
  bool _isOnline = false;
  bool _isResetting = false;
  Timer? _pollTimer;
  final List<EventLog> _events = [];


  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _resetPressController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _resetPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _addEvent('Dashboard initialized', EventType.success);
    _fetchData();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchData());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    _resetPressController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _blynkService.fetchSensorData();
      final oldData = _sensorData;
      setState(() {
        _sensorData = data;
        _isOnline = true;
      });

      // Log state changes
      if (oldData != null) {
        if (data.flameSensor && !oldData.flameSensor) {
          _addEvent('🔥 Fire sensor triggered!', EventType.alert);
        } else if (!data.flameSensor && oldData.flameSensor) {
          _addEvent('Fire sensor cleared', EventType.success);
        }
        if (data.pirMotion && !oldData.pirMotion) {
          _addEvent('Motion detected', EventType.alert);
        } else if (!data.pirMotion && oldData.pirMotion) {
          _addEvent('Motion cleared', EventType.info);
        }
        if (data.doorSensor && !oldData.doorSensor) {
          _addEvent('Door opened', EventType.alert);
        } else if (!data.doorSensor && oldData.doorSensor) {
          _addEvent('Door closed', EventType.info);
        }
      }
    } catch (e) {
      setState(() => _isOnline = false);
    }
  }

  void _addEvent(String message, EventType type) {
    setState(() {
      _events.insert(
        0,
        EventLog(message: message, timestamp: DateTime.now(), type: type),
      );
      if (_events.length > 20) _events.removeLast();
    });
  }

  Future<void> _onResetPressed() async {
    setState(() => _isResetting = true);
    _addEvent('Reset command sent', EventType.info);
    final success = await _blynkService.sendReset();
    if (success) {
      _addEvent('System reset successful', EventType.success);
    } else {
      _addEvent('Reset failed!', EventType.alert);
    }
    setState(() => _isResetting = false);
    // Refresh after reset
    await Future.delayed(const Duration(milliseconds: 500));
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final data = _sensorData;
    final hasFireAlert = data?.hasFireAlert ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradients
          _buildBackgroundGradients(hasFireAlert),
          // Main content
          CustomScrollView(
            slivers: [
              // Top App Bar
              _buildTopAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero Status
                    _buildHeroStatus(data),
                    const SizedBox(height: 24),
                    // Sensor Grid
                    _buildFireSensorCard(data),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildMotionSensorCard(data)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDoorSensorCard(data)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 3D Physical Reset Switch
                    _buildResetButton(),
                    const SizedBox(height: 24),
                    // Event Stream
                    _buildEventStream(),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
            ],
          ),
          // Bottom Nav Bar
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  // ─── Background Gradients ───
  Widget _buildBackgroundGradients(bool isAlert) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  (isAlert ? AppColors.alertRed : AppColors.primary)
                      .withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.tertiary.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Top App Bar ───
  SliverAppBar _buildTopAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 60,
      title: Text(
        'SMART ALARM SYSTEM',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          color: AppColors.primary,
        ),
      ),
      actions: [
        // Theme toggle button
        IconButton(
          icon: Icon(
            AppColors.isDark ? Icons.light_mode : Icons.dark_mode,
            color: AppColors.slateText,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              AppColors.isDark = !AppColors.isDark;
            });
          },
        ),
        // Online/Offline badge
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOnline ? AppColors.primary : AppColors.alertRed,
                  boxShadow: [
                    BoxShadow(
                      color: (_isOnline ? AppColors.primary : AppColors.alertRed)
                          .withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isOnline ? 'ONLINE' : 'OFFLINE',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: _isOnline ? AppColors.primary : AppColors.alertRed,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.wifi, color: AppColors.slateText, size: 20),
        const SizedBox(width: 16),
      ],
    );
  }

  // ─── Hero Status ───
  Widget _buildHeroStatus(SensorData? data) {
    final status = data?.systemStatus ?? 'CONNECTING...';
    final description = data?.statusDescription ?? 'Waiting for sensor data...';
    final hasAlert = data?.hasAlert ?? false;
    final hasFireAlert = data?.hasFireAlert ?? false;

    final now = DateTime.now().toUtc().add(const Duration(hours: 6));
    int hour12 = now.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr =
        '${hour12.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $amPm';

    Color statusColor;
    if (hasFireAlert) {
      statusColor = AppColors.alertRed;
    } else if (hasAlert) {
      statusColor = AppColors.tertiary;
    } else {
      statusColor = AppColors.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: statusColor,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.3,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LAST UPDATED',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.slateText,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: AppColors.onSurface,
                    ),
                    children: [
                      TextSpan(text: timeStr),
                      TextSpan(
                        text: ' BDT',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Fire Sensor Card (Large Alert) ───
  Widget _buildFireSensorCard(SensorData? data) {
    final isAlert = data?.flameSensor ?? false;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        final shadowRadius = isAlert ? 15 + (pulseValue * 20) : 0.0;
        final shadowOpacity = isAlert ? 0.4 - (pulseValue * 0.3) : 0.0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: isAlert ? AppColors.alertRed : AppColors.primary.withValues(alpha: 0.3),
                width: 4,
              ),
            ),
            boxShadow: isAlert
                ? [
                    BoxShadow(
                      color: AppColors.alertRed.withValues(alpha: shadowOpacity),
                      blurRadius: shadowRadius,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Background fire icon
                    if (isAlert)
                      Positioned(
                        bottom: -20,
                        right: -20,
                        child: Icon(
                          Icons.local_fire_department,
                          size: 140,
                          color: AppColors.alertRed.withValues(alpha: 0.08),
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fire Sensor',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAlert
                                    ? AppColors.alertRed
                                    : AppColors.primary,
                              ),
                              child: Icon(
                                isAlert ? Icons.warning : Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isAlert
                                ? AppColors.alertRed.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAlert
                                  ? AppColors.alertRed.withValues(alpha: 0.4)
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isAlert ? 'FIRE DETECTED' : 'NO FIRE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: isAlert
                                  ? AppColors.alertRed
                                  : AppColors.primary,
                            ),
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
      },
    );
  }

  // ─── Motion Sensor Card ───
  Widget _buildMotionSensorCard(SensorData? data) {
    final isAlert = data?.pirMotion ?? false;
    return _buildSmallSensorCard(
      name: 'Motion Sensor',
      icon: Icons.sensors,
      statusText: isAlert ? 'Motion Detected' : 'No Motion',
      isAlert: isAlert,
      borderColor: isAlert
          ? AppColors.alertRed.withValues(alpha: 0.6)
          : AppColors.primary.withValues(alpha: 0.3),
    );
  }

  // ─── Door Sensor Card ───
  Widget _buildDoorSensorCard(SensorData? data) {
    final isAlert = data?.doorSensor ?? false;
    return _buildSmallSensorCard(
      name: 'Door Sensor',
      icon: Icons.door_front_door,
      statusText: isAlert ? 'Door Open' : 'Closed',
      isAlert: isAlert,
      borderColor: isAlert
          ? Colors.orange.withValues(alpha: 0.6)
          : AppColors.primary.withValues(alpha: 0.3),
    );
  }

  Widget _buildSmallSensorCard({
    required String name,
    required IconData icon,
    required String statusText,
    required bool isAlert,
    required Color borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: borderColor, size: 22),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAlert
                          ? AppColors.alertRed
                          : borderColor.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    statusText.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isAlert ? AppColors.alertRed : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Event Stream ───
  Widget _buildEventStream() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EVENT STREAM',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'REAL-TIME',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slateText,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_events.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No events yet...',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.slateText,
                    ),
                  ),
                )
              else
                ...List.generate(
                  _events.length > 5 ? 5 : _events.length,
                  (i) {
                    final event = _events[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: i < (_events.length > 5 ? 4 : _events.length - 1)
                          ? BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                      AppColors.outlineVariant.withValues(alpha: 0.15),
                                ),
                              ),
                            )
                          : null,
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: event.dotColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              event.message,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            event.timeString,
                            style: GoogleFonts.robotoMono(
                              fontSize: 11,
                              color: AppColors.slateText,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 3D Physical Reset Switch ───
  Widget _buildResetButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              // Section title
              Text(
                'SYSTEM OVERRIDE AUTHORIZATION',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: AppColors.tertiary,
                ),
              ),
              const SizedBox(height: 28),
              // The 3D physical switch button
              GestureDetector(
                onTapDown: _isResetting ? null : (_) {
                  _resetPressController.forward();
                },
                onTapUp: _isResetting ? null : (_) {
                  _resetPressController.reverse();
                  _onResetPressed();
                },
                onTapCancel: () {
                  _resetPressController.reverse();
                },
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, _) {
                    return AnimatedBuilder(
                      animation: _resetPressController,
                      builder: (context, child) {
                        final pressVal = _resetPressController.value;
                        final translateY = pressVal * 8.0;
                        final bottomShadow = 10.0 * (1.0 - pressVal);
                        final blurShadow = 30.0 * (1.0 - pressVal * 0.6);
                        return Transform.translate(
                          offset: Offset(0, translateY),
                          child: Container(
                            width: 200,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1A1A1B),
                                  Color(0xFF0E0E0F),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              boxShadow: [
                                // Bottom "depth" shadow (the 3D effect)
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(0, bottomShadow),
                                  blurRadius: 0,
                                ),
                                // Ambient shadow
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  offset: Offset(0, bottomShadow + 5),
                                  blurRadius: blurShadow,
                                ),
                                // Top highlight (inset emulation)
                                BoxShadow(
                                  color: Colors.white.withValues(
                                      alpha: 0.1 * (1.0 - pressVal)),
                                  offset: const Offset(0, -1),
                                  blurRadius: 1,
                                ),
                                // Purple glow when pressed
                                BoxShadow(
                                  color: AppColors.tertiary.withValues(
                                      alpha: pressVal * 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Inner purple border
                                Positioned.fill(
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: AppColors.tertiary.withValues(
                                            alpha: 0.3 +
                                                _glowController.value * 0.15),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                // Button content
                                Center(
                                  child: _isResetting
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.tertiary,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.power_settings_new,
                                              color: pressVal > 0.5
                                                  ? AppColors.alertRed
                                                  : AppColors.tertiary,
                                              size: 22,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'PRESS TO RESET',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 3,
                                                color: pressVal > 0.5
                                                    ? AppColors.alertRed
                                                    : Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    color: (pressVal > 0.5
                                                            ? AppColors.alertRed
                                                            : AppColors
                                                                .tertiary)
                                                        .withValues(
                                                            alpha: 0.5),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Status LED indicators (toggle based on reset state)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusLED(
                    'ACTIVE',
                    !_isResetting ? AppColors.alertRed : AppColors.slateText.withValues(alpha: 0.3),
                    !_isResetting,
                  ),
                  const SizedBox(width: 32),
                  _buildStatusLED(
                    'OVERRIDE',
                    _isResetting ? AppColors.primary : AppColors.slateText.withValues(alpha: 0.3),
                    _isResetting,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLED(String label, Color color, bool pulsing) {
    return Column(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: pulsing
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.8),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: AppColors.slateText,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ─── Bottom Nav Bar ───
  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield,
                  size: 24,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  'DASHBOARD',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Utility to use AnimationController with builder pattern
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
