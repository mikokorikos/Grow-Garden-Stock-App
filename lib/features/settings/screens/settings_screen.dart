import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grow_garden_tracker/core/database/sniper_repository.dart';
import 'package:grow_garden_tracker/presentation/bloc/stock/stock_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;
  bool _isServiceRunning = false;
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _batteryStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    listenToServiceChanges();
    checkAllPermissions();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkAllPermissions();
      checkServiceStatus().then((_) {
        if (_isServiceRunning) {
          _syncSniperListWithService();
        }
      });
    }
  }

  void listenToServiceChanges() {
    final service = FlutterBackgroundService();
    checkServiceStatus();
    _serviceSubscription = service.on('service_started').listen((event) {
       if (mounted) setState(() => _isServiceRunning = true);
    });
  }

  Future<void> checkServiceStatus() async {
    final running = await FlutterBackgroundService().isRunning();
    if (mounted) {
      setState(() {
        _isServiceRunning = running;
      });
    }
  }

  Future<void> _syncSniperListWithService() async {
    final sniperList = await SniperRepository().loadSniperList();
    FlutterBackgroundService().invoke('updateSniperList', {'sniper_list': sniperList});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleServiceToggle() async {
    final service = FlutterBackgroundService();
    final stockBloc = context.read<StockBloc>(); // Obtén la instancia del BLoC
    
    if (_isServiceRunning) {
      service.invoke("stopService");
      // Notifica al BLoC que debe dejar de escuchar.
      stockBloc.add(StopListeningToStockUpdates());
      setState(() => _isServiceRunning = false);
    } else {
      final allPermissionsGranted = await _requestAllPermissions();
      if (allPermissionsGranted) {
        await service.startService();
        await _syncSniperListWithService();

        // Notifica al BLoC que debe empezar a escuchar de nuevo.
        stockBloc.add(ListenToStockUpdates());

      } else {
        _showPermissionsNeededDialog();
      }
    }
  }
  
  Future<void> checkAllPermissions() async {
    final notifStatus = await Permission.notification.status;
    final battStatus = await Permission.ignoreBatteryOptimizations.status;
    if (mounted) {
      setState(() {
        _notificationStatus = notifStatus;
        _batteryStatus = battStatus;
      });
    }
  }

  Future<bool> _requestAllPermissions() async {
    if (await Permission.notification.isDenied) await Permission.notification.request();
    if (await Permission.ignoreBatteryOptimizations.isDenied) await Permission.ignoreBatteryOptimizations.request();
    await checkAllPermissions();
    return _notificationStatus.isGranted && _batteryStatus.isGranted;
  }

  void _showPermissionsNeededDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Permisos Requeridos'),
        content: const Text('Para garantizar el funcionamiento 24/7, el permiso de Notificaciones y de Optimización de Batería debe estar "Concedido".'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
          CupertinoDialogAction(isDefaultAction: true, child: const Text('Ir a Ajustes'), onPressed: () { openAppSettings(); Navigator.of(context).pop(); }),
        ],
      ),
    );
  }
  
  Future<void> _handlePermissionTap(Permission permission) async {
    if (await permission.isPermanentlyDenied || await permission.isRestricted) {
      openAppSettings();
    } else {
      await permission.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ajustes del Sniper'),
      ),
      child: ListView(
        children: [
          const SizedBox(height: 20),
          CupertinoListSection.insetGrouped(
            header: const Text('ESTADO DEL SERVICIO'),
            children: [
              CupertinoListTile(
                title: Text(_isServiceRunning ? 'Servicio Activo' : 'Servicio Inactivo', style: TextStyle(fontWeight: FontWeight.bold, color: _isServiceRunning ? CupertinoColors.activeGreen : CupertinoColors.systemRed)),
                subtitle: const Text('Activa para buscar stock 24/7.'),
                trailing: CupertinoSwitch(value: _isServiceRunning, onChanged: (value) => _handleServiceToggle()),
              ),
            ],
          ),
          CupertinoListSection.insetGrouped(
            header: const Text('PERMISOS REQUERIDOS'),
            footer: const Text('Para un monitoreo sin fallos, se recomienda "Proteger" o "Bloquear" la app en la vista de aplicaciones recientes de tu teléfono.'),
            children: [
              _buildPermissionTile(title: 'Notificaciones', subtitle: 'Muestra la notificación permanente del servicio.', status: _notificationStatus, onTap: () => _handlePermissionTap(Permission.notification)),
              _buildPermissionTile(title: 'Optimización de Batería', subtitle: 'Evita que el sistema detenga la app.', status: _batteryStatus, onTap: () => _handlePermissionTap(Permission.ignoreBatteryOptimizations)),
            ],
          ),
        ],
      ),
    );
  }

  CupertinoListTile _buildPermissionTile({required String title, required String subtitle, required PermissionStatus status, required VoidCallback onTap}) {
    final bool isGranted = status.isGranted;
    return CupertinoListTile(
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isGranted ? 'Concedido' : 'Denegado', style: TextStyle(color: isGranted ? CupertinoColors.activeGreen : CupertinoColors.systemGrey)),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey2),
        ],
      ),
      onTap: onTap,
    );
  }
}