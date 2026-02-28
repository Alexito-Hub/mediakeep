import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/status_service.dart';
import '../services/settings_service.dart';
import '../models/status_model.dart';
import '../utils/responsive.dart';
import '../utils/platform_config.dart';
import 'package:intl/intl.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  ServerHealth? _serverHealth;
  List<PlatformStatus> _platformStatuses = [];
  String _apiVersion = 'Cargando...';
  ThemeMode _currentTheme = ThemeMode.system;
  int _successfulPlatforms = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        StatusService.getServerHealth(),
        StatusService.getPlatformStatuses(),
        StatusService.getApiVersion(),
        SettingsService.getThemeMode(),
      ]);

      if (mounted) {
        final platforms = results[1] as List<PlatformStatus>;
        final successCount = platforms.where((p) => p.isHealthy).length;

        setState(() {
          _serverHealth = results[0] as ServerHealth?;
          _platformStatuses = platforms;
          _apiVersion = results[2] as String;
          _currentTheme = results[3] as ThemeMode;
          _successfulPlatforms = successCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudo obtener el estado del sistema.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado del Sistema'),
        actions: [
          IconButton(
            onPressed: _fetchStatus,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStatus,
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : ListView(
                padding: Responsive.getContentPadding(context),
                children: [
                  _buildHeaderBanner(theme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Configuración de la App'),
                  _buildAppSettingsCard(theme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Salud del Servidor'),
                  _buildServerHealthCard(theme, isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Estado de Plataformas'),
                  _buildInstructions(theme),
                  const SizedBox(height: 8),
                  ..._platformStatuses.map(
                    (s) => _buildPlatformTile(s, theme, isDark),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderBanner(ThemeData theme) {
    final isOperational =
        (_serverHealth?.status == 'healthy' ||
            _serverHealth?.status == 'operativo') &&
        _platformStatuses.every((p) => p.isHealthy);

    final color = isOperational ? Colors.green : Colors.orange;
    final icon = isOperational ? Icons.check_circle : Icons.warning;
    final text = isOperational
        ? 'Sistemas Operativos'
        : 'Interrupciones Detectadas';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAppSettingsCard(ThemeData theme) {
    String themeText;
    IconData themeIcon;
    Color themeColor;

    switch (_currentTheme) {
      case ThemeMode.light:
        themeText = 'Claro (Blanco)';
        themeIcon = Icons.light_mode;
        themeColor = Colors.orange;
        break;
      case ThemeMode.dark:
        themeText = 'Oscuro (Negro)';
        themeIcon = Icons.dark_mode;
        themeColor = Colors.blue;
        break;
      case ThemeMode.system:
        themeText = 'Sistema (Autom\u00e1tico)';
        themeIcon = Icons.brightness_auto;
        themeColor = Colors.purple;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(
              themeIcon,
              'Tema Actual',
              themeText,
              theme,
              valueColor: themeColor,
            ),
            const Divider(height: 24),
            _buildStatRow(
              Icons.check_circle,
              'Plataformas Operativas',
              '$_successfulPlatforms de ${_platformStatuses.length}',
              theme,
              valueColor: _successfulPlatforms == _platformStatuses.length
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerHealthCard(ThemeData theme, bool isDark) {
    if (_serverHealth == null) return const SizedBox.shrink();

    final uptimeSeconds = _serverHealth!.uptime;
    final uptimeFormatted = _formatUptime(uptimeSeconds);
    final timestampFormatted = DateFormat(
      'dd/MM/yyyy HH:mm:ss',
    ).format(_serverHealth!.timestamp);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(Icons.api, 'Versión del API', _apiVersion, theme),
            const Divider(height: 24),
            _buildStatRow(
              Icons.timer,
              'Tiempo de Actividad',
              uptimeFormatted,
              theme,
            ),
            const Divider(height: 24),
            _buildStatRow(
              Icons.access_time,
              'Último Check',
              timestampFormatted,
              theme,
            ),
            const Divider(height: 24),
            _buildStatRow(
              Icons.cloud_queue,
              'Ambiente',
              _serverHealth!.environment.toUpperCase(),
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary.withAlpha(180)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            color: valueColor,
            fontWeight: valueColor != null ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformTile(
    PlatformStatus status,
    ThemeData theme,
    bool isDark,
  ) {
    final isHealthy = status.isHealthy;
    final color = isHealthy ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        leading: _buildPlatformIcon(status.platformName, isDark),
        title: Text(
          status.platformName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Latencia: ${status.responseTime?.inMilliseconds ?? 0}ms • Código: ${status.statusCode ?? 0}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                status.status,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Validation Section
                if (status.validation != null) ...[
                  _buildValidationSection(status.validation, theme, isDark),
                  const SizedBox(height: 12),
                ],
                // Response Data Section
                if (status.responseData != null) ...[
                  _buildResponseDataSection(
                    status.responseData!,
                    theme,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                ],
                if (status.lastTestedUrl != null) ...[
                  _buildDetailRow(
                    Icons.link,
                    'URL de Prueba',
                    status.lastTestedUrl!,
                    theme,
                  ),
                  const SizedBox(height: 8),
                ],
                if (status.errorMessage != null) ...[
                  _buildDetailRow(
                    Icons.error_outline,
                    'Detalles del Error',
                    status.errorMessage!,
                    theme,
                    isError: true,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildDetailRow(
                  Icons.schedule,
                  'Tiempo de Respuesta',
                  '${status.responseTime?.inMilliseconds ?? 0}ms',
                  theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformIcon(String platformName, bool isDark) {
    final iconData = PlatformConfigs.getIcon(platformName);
    final color = PlatformConfigs.getColor(platformName);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Toca cada plataforma para ver detalles de la prueba y errores',
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme, {
    bool isError = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isError
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface.withAlpha(150),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: isError
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface.withAlpha(200),
                  fontFamily: value.contains('http') ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatUptime(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchStatus,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseDataSection(
    Map<String, dynamic> data,
    ThemeData theme,
    bool isDark,
  ) {
    // Format JSON with indentation
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.code, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Respuesta del API',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor.withAlpha(50)),
          ),
          child: SelectableText(
            jsonString,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: theme.colorScheme.onSurface.withAlpha(200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidationSection(
    dynamic validation,
    ThemeData theme,
    bool isDark,
  ) {
    final isValid = validation.isValid as bool;
    final errors = validation.errors as List<String>;
    final warnings = validation.warnings as List<String>;
    final color = isValid ? Colors.green : Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isValid ? Icons.verified : Icons.warning,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              'Validacion de Datos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(100)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                validation.summary as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
              if (errors.isNotEmpty || warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  validation.detailedMessage as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: Responsive.getContentPadding(context),
      children: [
        _buildShimmerBanner(),
        const SizedBox(height: 24),
        _buildShimmerSection('Configuracion de la App'),
        _buildShimmerCard(),
        const SizedBox(height: 24),
        _buildShimmerSection('Salud del Servidor'),
        _buildShimmerCard(),
        const SizedBox(height: 24),
        _buildShimmerSection('Estado de Plataformas'),
        const SizedBox(height: 8),
        ...[1, 2, 3, 4, 5].map((i) => _buildShimmerPlatformCard()),
      ],
    );
  }

  Widget _buildShimmerSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: _buildShimmerBox(width: 200, height: 20),
    );
  }

  Widget _buildShimmerBanner() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
      ),
      child: Row(
        children: [
          _buildShimmerBox(width: 32, height: 32, isCircle: true),
          const SizedBox(width: 16),
          Expanded(child: _buildShimmerBox(width: double.infinity, height: 24)),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      ),
      child: Column(
        children: [
          _buildShimmerRow(),
          const SizedBox(height: 12),
          _buildShimmerRow(),
        ],
      ),
    );
  }

  Widget _buildShimmerPlatformCard() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      ),
      child: Row(
        children: [
          _buildShimmerBox(width: 40, height: 40, isCircle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 120, height: 16),
                const SizedBox(height: 8),
                _buildShimmerBox(width: 180, height: 12),
              ],
            ),
          ),
          _buildShimmerBox(width: 80, height: 24, borderRadius: 20),
        ],
      ),
    );
  }

  Widget _buildShimmerRow() {
    return Row(
      children: [
        _buildShimmerBox(width: 20, height: 20),
        const SizedBox(width: 12),
        Expanded(child: _buildShimmerBox(width: 100, height: 16)),
        const SizedBox(width: 16),
        _buildShimmerBox(width: 80, height: 16),
      ],
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    bool isCircle = false,
    double borderRadius = 8,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -2.0, end: 2.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(value - 1, 0),
              end: Alignment(value + 1, 0),
              colors: isDark
                  ? [
                      Colors.grey.shade800,
                      Colors.grey.shade700,
                      Colors.grey.shade800,
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation by calling setState
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
