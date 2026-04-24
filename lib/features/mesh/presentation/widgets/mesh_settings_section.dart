import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/mesh_status.dart';
import '../bloc/mesh_status_bloc.dart';

/// Phase 1e — Mesh Network section in Settings.
///
/// Displays running status + peer count, a toggle for offline-fallback,
/// and a deep link to the debug screen.
class MeshSettingsSection extends StatefulWidget {
  const MeshSettingsSection({super.key});

  @override
  State<MeshSettingsSection> createState() => _MeshSettingsSectionState();
}

class _MeshSettingsSectionState extends State<MeshSettingsSection> {
  static const _prefKey = 'mesh.offlineFallback';

  bool _offlineFallback = true;

  Box<String>? get _box {
    try {
      return Hive.box<String>('mesh_keys');
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    final raw = _box?.get(_prefKey);
    if (raw != null) {
      _offlineFallback = raw == 'true';
    }
  }

  Future<void> _toggle(bool v) async {
    await _box?.put(_prefKey, v ? 'true' : 'false');
    setState(() => _offlineFallback = v);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: BlocBuilder<MeshStatusBloc, MeshStatus>(
          bloc: sl<MeshStatusBloc>(),
          builder: (context, meshState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      meshState.running
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: meshState.running ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meshState.running ? 'Active' : 'Inactive',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${meshState.peerCount} peers visible nearby',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Divider(height: 24),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use mesh offline'),
                  subtitle: const Text(
                    'When the server is unreachable, send messages via nearby peers.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _offlineFallback,
                  onChanged: _toggle,
                ),
                const Divider(height: 8),
                if (AppConfig.isDev)
                  TextButton(
                    onPressed: () =>
                        context.push('${RouteConstants.settings}/mesh-debug'),
                    child: const Text('View debug'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
