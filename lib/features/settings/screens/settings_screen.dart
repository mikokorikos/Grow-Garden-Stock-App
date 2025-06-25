import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
import 'package:grow_garden_tracker/presentation/bloc/stock/stock_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  final _service = FlutterBackgroundService();
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;
  bool _isServiceRunning = false;
  
  // Timer para verificación periódica de permisos
  Timer? _permissionCheckTimer;

  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _batteryStatus = PermissionStatus.denied;
  PermissionStatus _systemAlertStatus = PermissionStatus.denied;
  PermissionStatus _exactAlarmStatus = PermissionStatus.denied;

  bool _areAllPermissionsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    listenToServiceChanges();
    _checkAllPermissions();
    // Verificación periódica cada 2 segundos cuando la app está en primer plano
    _startPeriodicPermissionCheck();
  }

  // Inicia la verificación periódica de permisos
  void _startPeriodicPermissionCheck() {
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkAllPermissions();
      }
    });
  }

  // Para la verificación periódica
  void _stopPeriodicPermissionCheck() {
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint("App resumed, checking permissions and starting periodic check.");
        _checkAllPermissions();
        _startPeriodicPermissionCheck();
        break;
      case AppLifecycleState.paused:
        debugPrint("App paused, stopping periodic check.");
        _stopPeriodicPermissionCheck();
        break;
      case AppLifecycleState.inactive:
        debugPrint("App inactive.");
        break;
      case AppLifecycleState.detached:
        debugPrint("App detached.");
        _stopPeriodicPermissionCheck();
        break;
      case AppLifecycleState.hidden:
        debugPrint("App hidden.");
        _stopPeriodicPermissionCheck();
        break;
    }
  }

  Future<void> _checkAllPermissions() async {
    try {
      // Verificar cada permiso individualmente con un pequeño delay
      final notifStatus = await Permission.notification.status;
      await Future.delayed(const Duration(milliseconds: 100));
      
      final battStatus = await Permission.ignoreBatteryOptimizations.status;
      await Future.delayed(const Duration(milliseconds: 100));
      
      PermissionStatus systemAlertStatus = PermissionStatus.granted; // iOS default
      PermissionStatus exactAlarmStatus = PermissionStatus.granted; // iOS default
      if (Platform.isAndroid) {
        systemAlertStatus = await Permission.systemAlertWindow.status;
        await Future.delayed(const Duration(milliseconds: 100));
        exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      }

      if (!mounted) return;

      // Solo actualizar el estado si hay cambios
      bool hasChanges = false;
      if (_notificationStatus != notifStatus ||
          _batteryStatus != battStatus ||
          _systemAlertStatus != systemAlertStatus ||
          _exactAlarmStatus != exactAlarmStatus) {
        hasChanges = true;
      }

      if (hasChanges) {
        setState(() {
          _notificationStatus = notifStatus;
          _batteryStatus = battStatus;
          _systemAlertStatus = systemAlertStatus;
          _exactAlarmStatus = exactAlarmStatus;

          if (Platform.isAndroid) {
            _areAllPermissionsGranted = notifStatus.isGranted &&
                battStatus.isGranted &&
                systemAlertStatus.isGranted &&
                exactAlarmStatus.isGranted;
          } else {
            _areAllPermissionsGranted = notifStatus.isGranted && battStatus.isGranted;
          }
        });
        
        debugPrint("Permissions updated - Notification: $notifStatus, Battery: $battStatus, SystemAlert: $systemAlertStatus, ExactAlarm: $exactAlarmStatus");
        debugPrint("All permissions granted: $_areAllPermissionsGranted");
      }
    } catch (e) {
      debugPrint("Error checking permissions: $e");
    }
  }

  void listenToServiceChanges() {
    checkServiceStatus();
    _serviceSubscription = _service.on('service_started').listen((event) {
      if (mounted) setState(() => _isServiceRunning = true);
    });
    _service.on('service_stopped').listen((event) {
      if (mounted) setState(() => _isServiceRunning = false);
    });
  }

  Future<void> checkServiceStatus() async {
    final running = await _service.isRunning();
    if (mounted) {
      setState(() {
        _isServiceRunning = running;
      });
    }
  }

  Future<void> _handleServiceToggle(bool value) async {
    if (value) {
      await _checkAllPermissions();
      if (_areAllPermissionsGranted) {
        final sniperList = await SniperRepository().loadSniperList();
        await _service.startService();
        _service.invoke('updateSniperList', {'sniper_list': sniperList});
        context.read<StockBloc>().add(ListenToStockUpdates());
        setState(() => _isServiceRunning = true);
      } else {
        _showPermissionsNeededDialog();
      }
    } else {
      _service.invoke("stopService");
      context.read<StockBloc>().add(StopListeningToStockUpdates());
      setState(() => _isServiceRunning = false);
    }
  }

  void _showPermissionsNeededDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Permisos Requeridos'),
        content: const Text(
            'Para garantizar el funcionamiento 24/7 y las alarmas, todos los permisos deben estar "Concedidos". Por favor, actívalos para poder iniciar el servicio.'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Entendido'),
              onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Future<void> _handlePermissionTap(Permission permission) async {
    try {
      final currentStatus = await permission.status;
      debugPrint("Current permission status for $permission: $currentStatus");

      if (currentStatus.isPermanentlyDenied || 
          permission == Permission.systemAlertWindow ||
          permission == Permission.scheduleExactAlarm ||
          permission == Permission.ignoreBatteryOptimizations) {
        // Estos permisos requieren ir a configuración
        debugPrint("Opening app settings for $permission");
        await openAppSettings();
      } else if (currentStatus.isDenied) {
        // Solicitar el permiso directamente
        debugPrint("Requesting permission for $permission");
        final newStatus = await permission.request();
        debugPrint("Permission result for $permission: $newStatus");
        
        // Verificar inmediatamente después de la solicitud
        await Future.delayed(const Duration(milliseconds: 500));
        await _checkAllPermissions();
      }
    } catch (e) {
      debugPrint("Error handling permission tap: $e");
    }
  }

  // Método para forzar verificación manual
  Future<void> _forcePermissionCheck() async {
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Ajustes del Sniper'),
        // Agregar botón de refresh para verificar permisos manualmente
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _forcePermissionCheck,
        ),
      ),
      child: ListView(
        children: [
          const SizedBox(height: 20),
          CupertinoListSection.insetGrouped(
            header: const Text('ESTADO DEL SERVICIO'),
            children: [
              CupertinoListTile(
                title: Text(
                  _isServiceRunning ? 'Servicio Activo' : 'Servicio Inactivo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isServiceRunning
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemRed),
                ),
                subtitle: Text(_areAllPermissionsGranted
                    ? 'Activa para buscar stock 24/7.'
                    : 'Se requieren todos los permisos.'),
                trailing: Transform.scale(
                  scale: 0.9,
                  child: CupertinoSwitch(
                    value: _isServiceRunning,
                    onChanged: _areAllPermissionsGranted || _isServiceRunning
                        ? (value) => _handleServiceToggle(value)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          CupertinoListSection.insetGrouped(
            header: const Text('PERMISOS REQUERIDOS'),
            footer: const Text(
                'Para un monitoreo sin fallos, se recomienda "Bloquear" la app en la vista de aplicaciones recientes de tu teléfono. Toca el botón ↻ arriba para verificar permisos manualmente.'),
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
              if (Platform.isAndroid)
                _buildPermissionTile(
                  title: 'Mostrar sobre otras apps',
                  subtitle: 'Permite que la alarma se muestre sobre otras aplicaciones.',
                  status: _systemAlertStatus,
                  onTap: () => _handlePermissionTap(Permission.systemAlertWindow),
                ),
              if (Platform.isAndroid)
                _buildPermissionTile(
                  title: 'Alarmas y Recordatorios',
                  subtitle: 'Requerido para alarmas de pantalla completa en Android 12+.',
                  status: _exactAlarmStatus,
                  onTap: () => _handlePermissionTap(Permission.scheduleExactAlarm),
                ),
            ],
          ),
          CupertinoListSection.insetGrouped(
              header: const Text('IMPORTANTE'),
              children: [
                CupertinoListTile(
                  title: const Text('Añadir Sonido de Alarma (Opcional)'),
                  subtitle: const Text(
                      'Para un sonido de alarma personalizado, agrega un archivo "alarm_sound.wav" en la carpeta "android/app/src/main/res/raw".'),
                  leading: const Icon(CupertinoIcons.speaker_2_fill),
                )
              ])
        ],
      ),
    );
  }

  CupertinoListTile _buildPermissionTile({
    required String title,
    required String subtitle,
    required PermissionStatus status,
    required VoidCallback onTap,
  }) {
    final bool isGranted = status.isGranted;
    return CupertinoListTile(
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isGranted ? 'Concedido' : 'Denegado',
              style: TextStyle(
                  color: isGranted
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemRed)),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.right_chevron,
              color: CupertinoColors.systemGrey2),
        ],
      ),
      onTap: onTap,
    );
  }
}