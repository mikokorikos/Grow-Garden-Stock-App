import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Importar Material para Colors
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
import 'package:grow_garden_tracker/core/theme/app_theme.dart';
import 'package:grow_garden_tracker/presentation/bloc/stock/stock_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _service = FlutterBackgroundService();
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;
  bool _isServiceRunning = false;

  Timer? _permissionCheckTimer;

  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _batteryStatus = PermissionStatus.denied;
  PermissionStatus _systemAlertStatus = PermissionStatus.granted; // Default para iOS
  PermissionStatus _exactAlarmStatus = PermissionStatus.granted; // Default para iOS

  bool _areAllPermissionsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    listenToServiceChanges();
    _checkAllPermissions();
    _startPeriodicPermissionCheck();
  }

  void _startPeriodicPermissionCheck() {
    _permissionCheckTimer?.cancel(); // Cancelar timer anterior si existe
    _permissionCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkAllPermissions();
      }
    });
  }

  void _stopPeriodicPermissionCheck() {
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint("App resumed, checking permissions and starting periodic check.");
      _checkAllPermissions();
      _startPeriodicPermissionCheck();
    } else if (state == AppLifecycleState.paused) {
      debugPrint("App paused, stopping periodic check.");
      _stopPeriodicPermissionCheck();
    }
  }

  Future<void> _checkAllPermissions() async {
    final notifStatus = await Permission.notification.status;
    final battStatus = await Permission.ignoreBatteryOptimizations.status;
    PermissionStatus systemAlert = _systemAlertStatus;
    PermissionStatus exactAlarm = _exactAlarmStatus;

    if (Platform.isAndroid) {
      systemAlert = await Permission.systemAlertWindow.status;
      exactAlarm = await Permission.scheduleExactAlarm.status;
    }

    if (!mounted) return;

    bool newAllPermissionsGranted;
    if (Platform.isAndroid) {
      newAllPermissionsGranted = notifStatus.isGranted &&
          battStatus.isGranted &&
          systemAlert.isGranted &&
          exactAlarm.isGranted;
    } else {
      newAllPermissionsGranted = notifStatus.isGranted /*&& battStatus.isGranted*/; // Battery Opt no es usualmente manejable en iOS así.
    }

    // Solo actualizar si hay cambios para evitar rebuilds innecesarios
    if (notifStatus != _notificationStatus ||
        battStatus != _batteryStatus ||
        systemAlert != _systemAlertStatus ||
        exactAlarm != _exactAlarmStatus ||
        newAllPermissionsGranted != _areAllPermissionsGranted) {
      setState(() {
        _notificationStatus = notifStatus;
        _batteryStatus = battStatus;
        _systemAlertStatus = systemAlert;
        _exactAlarmStatus = exactAlarm;
        _areAllPermissionsGranted = newAllPermissionsGranted;
      });
      debugPrint(
          "Permissions updated - Notif: $notifStatus, Batt: $battStatus, AlertWin: $systemAlert, ExactAlarm: $exactAlarm. AllGranted: $_areAllPermissionsGranted");
    }
  }

  void listenToServiceChanges() {
    checkServiceStatus();
    _serviceSubscription =
        _service.on('service_changed').listen((event) { // Escuchar un evento más genérico
      if (mounted && event != null) {
         final bool running = event['is_running'] ?? false;
         if(_isServiceRunning != running) {
            setState(() => _isServiceRunning = running);
         }
      }
    });
  }

  Future<void> checkServiceStatus() async {
    final running = await _service.isRunning();
    if (mounted && _isServiceRunning != running) {
      setState(() {
        _isServiceRunning = running;
      });
    }
  }

  Future<void> _handleServiceToggle(bool value) async {
    HapticFeedback.lightImpact();
    if (value) {
      await _checkAllPermissions(); // Re-verificar por si acaso
      if (_areAllPermissionsGranted) {
        final sniperList = await SniperRepository().loadSniperList();
        await _service.startService();
        _service.invoke('updateSniperList', {'sniper_list': sniperList});
        context.read<StockBloc>().add(ListenToStockUpdates());
        // El estado _isServiceRunning se actualizará por el listener
      } else {
        _showPermissionsNeededDialog();
         // Forzar el switch a apagado si no se concedieron permisos
        if(mounted) setState(() => _isServiceRunning = false);
      }
    } else {
      _service.invoke("stopService");
      context.read<StockBloc>().add(StopListeningToStockUpdates());
      // El estado _isServiceRunning se actualizará por el listener
    }
  }

  void _showPermissionsNeededDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Permisos Requeridos', style: AppTheme.headlineStyle.copyWith(fontSize: 18)),
        content: Text(
            'Para garantizar el funcionamiento 24/7 y las alarmas, todos los permisos deben estar "Concedidos". Por favor, actívalos para poder iniciar el servicio.', style: AppTheme.bodyTextStyle.copyWith(fontSize: 14)),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Entendido', style: TextStyle(color: AppTheme.primaryAppColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              }),
        ],
      ),
    );
  }

  Future<void> _handlePermissionTap(Permission permission) async {
    HapticFeedback.lightImpact();
    final currentStatus = await permission.status;
    if (currentStatus.isPermanentlyDenied ||
        [Permission.systemAlertWindow, Permission.scheduleExactAlarm, Permission.ignoreBatteryOptimizations].contains(permission)) {
      await openAppSettings();
    } else if (currentStatus.isDenied) {
      await permission.request();
    }
    // Después de interactuar con el permiso (solicitar o ir a settings),
    // esperamos un poco y luego re-verificamos todos.
    await Future.delayed(const Duration(milliseconds: 300));
    _checkAllPermissions();

  }

  Future<void> _forcePermissionCheck() async {
    HapticFeedback.mediumImpact();
    debugPrint("Force checking permissions...");
    await _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceSubscription?.cancel();
    _stopPeriodicPermissionCheck();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = AppTheme.cupertinoTheme;
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.lightScaffoldBackgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Ajustes del Sniper', style: cupertinoTheme.textTheme?.navTitleTextStyle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh_thick, size: 24), // Icono más visible
          onPressed: _forcePermissionCheck,
        ),
      ),
      child: ListView( // Usar ListView para mejor scroll y estructura
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          const SizedBox(height: 20),
          _buildServiceStatusSection(cupertinoTheme),
          _buildPermissionsSection(cupertinoTheme),
          _buildImportantInfoSection(cupertinoTheme),
        ],
      ),
    );
  }

  Widget _buildServiceStatusSection(CupertinoThemeData cupertinoTheme) {
    return CupertinoListSection.insetGrouped(
      backgroundColor: Colors.transparent,
      header: Text('ESTADO DEL SERVICIO', style: cupertinoTheme.textTheme?.textStyle?.copyWith(color: AppTheme.darkTextColor.withOpacity(0.6))),
      children: [
        CupertinoListTile(
          backgroundColor: AppTheme.glassBackgroundColor.withOpacity(0.7),
          title: Text(
            _isServiceRunning ? 'Servicio Activo' : 'Servicio Inactivo',
            style: AppTheme.bodyTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: _isServiceRunning
                    ? AppTheme.electricBlue // Usar color vibrante
                    : CupertinoColors.systemRed),
          ),
          subtitle: Text(
              _areAllPermissionsGranted || _isServiceRunning
                  ? 'Activa para buscar stock 24/7.'
                  : 'Se requieren todos los permisos.',
              style: AppTheme.captionTextStyle),
          trailing: CupertinoSwitch(
            value: _isServiceRunning,
            activeColor: AppTheme.primaryAppColor,
            onChanged: (value) => _handleServiceToggle(value),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection(CupertinoThemeData cupertinoTheme) {
    return CupertinoListSection.insetGrouped(
      backgroundColor: Colors.transparent,
      header: Text('PERMISOS REQUERIDOS', style: cupertinoTheme.textTheme?.textStyle?.copyWith(color: AppTheme.darkTextColor.withOpacity(0.6))),
      footer: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
            'Para un monitoreo sin fallos, se recomienda "Bloquear" la app en la vista de aplicaciones recientes de tu teléfono. Toca el botón ↻ arriba para verificar permisos manualmente.',
            style: AppTheme.captionTextStyle.copyWith(fontSize: 12.5)),
      ),
      children: [
        _buildPermissionTile(
          title: 'Notificaciones',
          subtitle: 'Muestra la notificación del servicio y las alarmas.',
          status: _notificationStatus,
          onTap: () => _handlePermissionTap(Permission.notification),
        ),
        _buildPermissionTile(
          title: 'Optimización de Batería',
          subtitle: 'Evita que el sistema detenga la app en segundo plano.',
          status: _batteryStatus,
          onTap: () => _handlePermissionTap(Permission.ignoreBatteryOptimizations),
        ),
        if (Platform.isAndroid) ...[
          _buildPermissionTile(
            title: 'Mostrar sobre otras apps',
            subtitle:
                'Permite que la alarma se muestre sobre otras aplicaciones.',
            status: _systemAlertStatus,
            onTap: () => _handlePermissionTap(Permission.systemAlertWindow),
          ),
          _buildPermissionTile(
            title: 'Alarmas y Recordatorios',
            subtitle:
                'Requerido para alarmas de pantalla completa en Android 12+.',
            status: _exactAlarmStatus,
            onTap: () => _handlePermissionTap(Permission.scheduleExactAlarm),
          ),
        ]
      ],
    );
  }

  Widget _buildImportantInfoSection(CupertinoThemeData cupertinoTheme) {
     return CupertinoListSection.insetGrouped(
        backgroundColor: Colors.transparent,
        header: Text('IMPORTANTE', style: cupertinoTheme.textTheme?.textStyle?.copyWith(color: AppTheme.darkTextColor.withOpacity(0.6))),
        children: [
          CupertinoListTile(
            backgroundColor: AppTheme.glassBackgroundColor.withOpacity(0.7),
            title: Text('Añadir Sonido de Alarma (Opcional)', style: AppTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.w500)),
            subtitle: Text(
                'Para un sonido de alarma personalizado, agrega un archivo "alarm_sound.wav" en la carpeta "android/app/src/main/res/raw".', style: AppTheme.captionTextStyle),
            leading: Icon(CupertinoIcons.speaker_2_fill, color: AppTheme.primaryAppColor.withOpacity(0.8)),
          )
        ]);
  }

  CupertinoListTile _buildPermissionTile({
    required String title,
    required String subtitle,
    required PermissionStatus status,
    required VoidCallback onTap,
  }) {
    final bool isGranted = status.isGranted;
    return CupertinoListTile(
      backgroundColor: AppTheme.glassBackgroundColor.withOpacity(0.7),
      title: Text(title, style: AppTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: AppTheme.captionTextStyle, maxLines: 2),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isGranted ? 'Concedido' : 'Denegado',
            style: AppTheme.captionTextStyle.copyWith(
                color: isGranted
                    ? AppTheme.electricBlue // Usar color vibrante
                    : CupertinoColors.systemRed,
                fontWeight: isGranted ? FontWeight.w600 : FontWeight.normal),
          ),
          const SizedBox(width: 8),
          Icon(CupertinoIcons.right_chevron,
              color: CupertinoColors.systemGrey2.withOpacity(0.7), size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}