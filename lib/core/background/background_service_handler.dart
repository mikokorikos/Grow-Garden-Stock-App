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
  
  // Usamos un Timer para la verificación periódica, inspirado en tu solución,
  // para máxima robustez.
  Timer? _permissionCheckTimer;

  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _batteryStatus = PermissionStatus.denied;
  PermissionStatus _exactAlarmStatus = PermissionStatus.denied;

  bool _areAllPermissionsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    listenToServiceChanges();
    _checkAllPermissions();
    _startPeriodicPermissionCheck(); // Inicia la verificación periódica
  }

  void _startPeriodicPermissionCheck() {
    // Si ya existe un timer, lo cancelamos para no tener múltiples timers.
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
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
    final statuses = await [
      Permission.notification.status,
      Permission.ignoreBatteryOptimizations.status,
      if (Platform.isAndroid) Permission.scheduleExactAlarm.status,
    ].wait;

    if (!mounted) return;
    
    final notifStatus = statuses[0];
    final battStatus = statuses[1];
    final alarmStatus = Platform.isAndroid ? statuses[2] : PermissionStatus.granted;

    // Solo actualizamos el estado si algo ha cambiado para evitar reconstrucciones innecesarias.
    if (_notificationStatus != notifStatus ||
        _batteryStatus != battStatus ||
        _exactAlarmStatus != alarmStatus) {
      setState(() {
        _notificationStatus = notifStatus;
        _batteryStatus = battStatus;
        _exactAlarmStatus = alarmStatus;

        _areAllPermissionsGranted = notifStatus.isGranted &&
            battStatus.isGranted &&
            (Platform.isAndroid ? alarmStatus.isGranted : true);
            
        debugPrint("Permissions updated - All granted: $_areAllPermissionsGranted");
      });
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
    if (mounted) setState(() => _isServiceRunning = running);
  }

  Future<void> _handleServiceToggle(bool value) async {
    if (value) {
      await _checkAllPermissions();
      if (_areAllPermissionsGranted) {
        final sniperList = await SniperRepository().loadSniperList();
        await _service.startService();
        _service.invoke('updateSniperList', {'sniper_list': sniperList});
        context.read<StockBloc>().add(ListenToStockUpdates());
        if(mounted) setState(() => _isServiceRunning = true);
      } else {
        _showPermissionsNeededDialog();
      }
    } else {
      _service.invoke("stopService");
      context.read<StockBloc>().add(StopListeningToStockUpdates());
       if(mounted) setState(() => _isServiceRunning = false);
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
    final status = await permission.status;
    if (status.isPermanentlyDenied ||
        permission == Permission.scheduleExactAlarm ||
        permission == Permission.ignoreBatteryOptimizations) {
      await openAppSettings();
    } else {
      await permission.request();
      await _checkAllPermissions();
    }
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
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _checkAllPermissions,
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
                'Para un monitoreo sin fallos, se recomienda "Bloquear" la app en la vista de aplicaciones recientes de tu teléfono.'),
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
                  title: 'Alarmas y Recordatorios',
                  subtitle: 'Permite que la alarma se muestre sobre otras apps.',
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
