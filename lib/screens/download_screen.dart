import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tiktok_model.dart';
import '../models/facebook_model.dart';
import '../models/spotify_model.dart';
import '../models/threads_model.dart';
import '../models/youtube_model.dart';
import '../models/bilibili_model.dart';
import '../models/instagram_model.dart';
import '../models/twitter_model.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/permission_service.dart';
import '../../services/adblock_detector.dart';
import '../utils/platform_detector.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../utils/platform_config.dart';
import '../widgets/dialogs/share_dialog.dart';
import '../widgets/result_cards/tiktok_result_card.dart';
import '../widgets/result_cards/facebook_result_card.dart';
import '../widgets/result_cards/spotify_result_card.dart';
import '../widgets/result_cards/threads_result_card.dart';
import '../widgets/result_cards/youtube_result_card.dart';
import '../widgets/result_cards/bilibili_result_card.dart';
import '../widgets/result_cards/instagram_result_card.dart';
import '../widgets/result_cards/twitter_result_card.dart';
import '../widgets/common/shimmer_widget.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'active_downloads_screen.dart';
import '../services/history_service.dart';
import '../services/ad_manager.dart';
import '../widgets/ad_banner.dart';
import 'auth_screen.dart';
import 'media_preview_screen.dart';

/// Main download screen
class DownloadScreen extends StatefulWidget {
  final String? initialUrl;
  const DownloadScreen({super.key, this.initialUrl});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _platform;
  bool _loading = false;
  TikTokData? _tiktokData;
  FacebookData? _facebookData;
  SpotifyData? _spotifyData;
  ThreadsData? _threadsData;
  YouTubeData? _youtubeData;
  BilibiliData? _bilibiliData;
  InstagramData? _instagramData;
  TwitterData? _twitterData;
  Timer? _debounceTimer;
  StreamSubscription? _intentDataStreamSubscription;
  bool _hasReceivedSharedContent = false;

  bool _isDownloading = false;

  // banner state moved to AdBanner widget; no longer needed here

  @override
  void initState() {
    super.initState();
    // Request all permissions on startup
    PermissionService.requestAllPermissions();

    _controller.addListener(_detectPlatform);
    _initSharing();

    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _controller.text = widget.initialUrl!;
      _hasReceivedSharedContent = true;
      Future.delayed(AppConstants.autoFetchDelay, () {
        if (mounted) _fetchMedia();
      });
    } else {
      Future.delayed(AppConstants.autoPasteDelay, () {
        if (!_hasReceivedSharedContent && !kIsWeb) {
          _pasteFromClipboard();
        }
      });
    }
  }

  void _initSharing() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      ReceiveSharingIntent.instance.getInitialMedia().then((
        List<SharedMediaFile> value,
      ) {
        if (value.isNotEmpty) {
          _handleSharedMedia(value);
        }
      });

      _intentDataStreamSubscription = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen(
            (List<SharedMediaFile> value) {
              if (value.isNotEmpty) {
                _handleSharedMedia(value);
              }
            },
            onError: (err) {
              debugPrint('Error receiving shared text: $err');
            },
          );
    }
  }

  void _handleSharedMedia(List<SharedMediaFile> sharedMedia) {
    _hasReceivedSharedContent = true;
    String? sharedText;
    for (var media in sharedMedia) {
      if (media.path.isNotEmpty) {
        sharedText = media.path;
        break;
      }
    }
    if (sharedText != null && sharedText.isNotEmpty) {
      _handleSharedText(sharedText);
    }
  }

  void _handleSharedText(String sharedText) {
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final match = urlPattern.firstMatch(sharedText);
    final url = match?.group(0) ?? sharedText;

    setState(() {
      _controller.text = url;
    });

    _focusNode.unfocus();

    Future.delayed(AppConstants.autoFetchDelay, () {
      if (mounted && _controller.text.isNotEmpty) {
        _fetchMedia();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _intentDataStreamSubscription?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _detectPlatform() {
    final detected = PlatformDetector.detectPlatform(_controller.text.trim());
    _debounceTimer?.cancel();

    if (_platform != detected) {
      setState(() => _platform = detected);
    }

    if (detected != null && _controller.text.trim().isNotEmpty) {
      _debounceTimer = Timer(AppConstants.debounceDelay, () {
        if (mounted && _platform == detected && !_loading) {
          _fetchMedia();
        }
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        _controller.text = data.text!;
        _focusNode.unfocus();
      } else {
        _showToast('El portapapeles está vacío');
      }
    } catch (e) {
      debugPrint('Error al acceder al portapapeles: $e');
    }
  }

  Future<void> _fetchMedia() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      _showError('Por favor ingresa un enlace.');
      return;
    }

    if (_platform == null) {
      return _showError(
        'Enlace no soportado. Usa TikTok, Facebook, Spotify o Threads.',
      );
    }

    setState(() {
      _loading = true;
      _tiktokData = null;
      _facebookData = null;
      _spotifyData = null;
      _threadsData = null;
      _isDownloading = false;
    });

    try {
      // 🚀 AdBlock Check para Web 🚀
      if (kIsWeb) {
        final isAdBlockActive = await AdBlockDetector.hasAdBlock();
        if (isAdBlockActive) {
          final isPrem = await AdManager.isPremium();
          if (!isPrem) {
            _showError(
              '¡AdBlock Detectado! MediaKeep es gratuito gracias a los anuncios. Por favor, desactiva tu bloqueador de anuncios para continuar.',
            );
            setState(() {
              _loading = false;
            });
            return;
          }
        }
      }

      // 1) Verify API status limits natively
      await ApiService.getSubscriptionStatus();
      if (!mounted) return;

      final response = await ApiService.fetchMedia(
        url: url,
        platform: _platform!,
      );

      if (response.success && response.data != null) {
        final parsedData = ApiService.parseResponseData(
          response.data!,
          response.platform!,
        );

        switch (response.platform) {
          case 'tiktok':
            _tiktokData = parsedData as TikTokData;
            break;
          case 'facebook':
            _facebookData = parsedData as FacebookData;
            break;
          case 'spotify':
            _spotifyData = parsedData as SpotifyData;
            break;
          case 'threads':
            _threadsData = parsedData as ThreadsData;
            break;
          case 'youtube':
            _youtubeData = parsedData as YouTubeData;
            break;
          case 'bilibili':
            _bilibiliData = parsedData as BilibiliData;
            break;
          case 'instagram':
            _instagramData = parsedData as InstagramData;
            break;
          case 'twitter':
            _twitterData = parsedData as TwitterData;
            break;
        }
      } else {
        if (response.limitReached) {
          _showLimitReachedModal(response.errorMessage ?? 'Límite alcanzado');
        } else {
          _showError(response.errorMessage ?? 'Error desconocido');
        }
      }
    } catch (e) {
      _showError('Ocurrió un error inesperado al parsear los datos.');
      debugPrint('Error: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _startDownload(String url, String type) async {
    if (kIsWeb) {
      _launchUrl(url);
      _showToast('Descarga iniciada en el navegador');
      return;
    }

    if (_isDownloading) {
      // Already downloading — show snackbar to check active downloads page
      _showToast('Ya hay una descarga en curso. Revisa las descargas activas.');
      return;
    }

    final hasPermission = await PermissionService.requestStoragePermissions();
    if (!hasPermission) {
      _showError(
        'Se requieren permisos de almacenamiento para guardar el archivo.',
      );
      return;
    }

    final sourceUrl = _controller.text.trim();
    if (await HistoryService.isContentAlreadyDownloaded(sourceUrl: sourceUrl)) {
      _showError('Este contenido ya fue descargado previamente.');
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    // Show immediate feedback — download runs in background, UI is NOT blocked
    _showToast('Descargando en segundo plano...');

    final String downloadTitle = [
      _platform == 'tiktok' ? 'TikTok' : _platform?.toUpperCase() ?? 'Media',
      _tiktokData?.title ??
          _facebookData?.title ??
          _youtubeData?.info.title ??
          _spotifyData?.title ??
          _bilibiliData?.info.title ??
          _twitterData?.title ??
          _threadsData?.title ??
          'Video Descargado',
    ].join(' | ');

    // Run download without awaiting (non-blocking)
    DownloadService.startDownload(
          url: url,
          type: type,
          platform: _platform ?? 'unknown',
          title: downloadTitle,
          sourceUrl: sourceUrl,
          onProgress: (progress, status) {
            // Progress updates from FlutterDownloader come via port callbacks
            // We only update the _isDownloading flag, not block navigation
          },
        )
        .then((result) {
          if (!mounted) return;
          setState(() => _isDownloading = false);

          if (result.success) {
            _showToast(
              '✓ Guardado en MediaKeep/${result.subfolder}',
              isSuccess: true,
            );

            // Native notification (Android)
            try {
              const notifChannel = MethodChannel(
                'com.mediakeep.aur/notifications',
              );
              notifChannel.invokeMethod('showDownloadNotification', {
                'filename': result.fileName ?? 'archivo',
                'filepath': result.filePath ?? '',
                'title': downloadTitle,
              });
            } catch (e) {
              debugPrint('Error showing notification: $e');
            }

            if (mounted) {
              showShareDialog(
                context: context,
                filePath: result.filePath!,
                fileName: result.fileName!,
                fileType: type,
                onError: _showError,
              );
            }
            AdManager.showInterstitialAd();
          } else {
            _showError(result.errorMessage ?? 'Error en la descarga');
          }
        })
        .catchError((e) {
          if (mounted) setState(() => _isDownloading = false);
          _showError('Error inesperado en la descarga.');
        });
  }

  void _showToast(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              color: isSuccess
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onInverseSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSuccess
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showLimitReachedModal(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline_rounded, size: 48),
        title: const Text('Límite Alcanzado'),
        content: Text(message),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          if (!kIsWeb)
            FilledButton.icon(
              icon: const Icon(Icons.play_circle_outline_rounded),
              onPressed: () {
                Navigator.pop(ctx);
                _showToast('Cargando anuncio... un momento');
                AdManager.showRewardedAd((amount) async {
                  _showToast(
                    '¡Premio obtenido! Desbloqueando descarga...',
                    isSuccess: true,
                  );
                  // Call backend to grant +X requests based on AdMob reward configuration
                  final response = await ApiService.grantRewardRequest(
                    amount.toInt(),
                  );
                  if (response) {
                    _showToast(
                      '¡Descarga extra obtenida, intenta de nuevo!',
                      isSuccess: true,
                    );
                  } else {
                    _showError(
                      'No se pudo otorgar la descarga extra. Intenta más tarde.',
                    );
                  }
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
              label: const Text('Ver Anuncio (+1 Descarga)'),
            ),
          FilledButton.icon(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
            label: const Text('Crear cuenta / Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError('No se pudo abrir el enlace');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gradient removed for cleaner UI as per user request

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Media Keep'),
        actions: [
          // Active downloads badge
          if (_isDownloading)
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.downloading_rounded),
                  tooltip: 'Descargas activas',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActiveDownloadsScreen(),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Historial',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (Responsive.isMobile(context)) {
            return _buildMobileBody();
          }
          return _buildWideBody();
        },
      ),
      bottomNavigationBar: _buildAdBanner(),
    );
  }

  // ─── Layout Builders ─────────────────────────────────────────────────────

  /// Mobile layout: single scrollable column (original behavior).
  Widget _buildMobileBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SafeArea(
        child: Padding(
          padding: Responsive.getContentPadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  _buildInputCard(true),
                  const SizedBox(height: 20),
                  if (_loading)
                    const ShimmerResultCard()
                  else if (!_hasResult())
                    _buildEmptyState(true)
                  else
                    _buildResultCard(true),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tablet / Desktop layout: 2-column Row.
  /// Left panel: input + result card (flexible).
  /// Right panel: recent history sidebar (fixed 320px).
  Widget _buildWideBody() {
    final isDesktop = Responsive.isDesktop(context);
    final sidebarWidth = isDesktop ? 360.0 : 300.0;

    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: main input + result ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: Responsive.getContentPadding(context),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      children: [
                        _buildInputCard(true),
                        const SizedBox(height: 20),
                        if (_loading)
                          const ShimmerResultCard()
                        else if (!_hasResult())
                          _buildEmptyState(true)
                        else
                          _buildResultCard(true),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── Divider ────────────────────────────────────────────────────
          VerticalDivider(
            width: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          // ── Right: history sidebar  ────────────────────────────────────
          RepaintBoundary(
            child: SizedBox(width: sidebarWidth, child: _buildHistorySidebar()),
          ),
        ],
      ),
    );
  }

  bool _hasResult() {
    return _tiktokData != null ||
        _facebookData != null ||
        _spotifyData != null ||
        _threadsData != null ||
        _youtubeData != null ||
        _bilibiliData != null ||
        _instagramData != null ||
        _twitterData != null;
  }

  /// Compact history sidebar shown on tablet/desktop,
  /// displays the 8 most recent downloads without navigating.
  Widget _buildHistorySidebar() {
    return FutureBuilder(
      future: HistoryService.getHistory(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                'Recientes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            if (items.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Sin descargas aún',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: items.take(20).length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildSidebarHistoryTile(item);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildSidebarHistoryTile(dynamic item) {
    IconData icon;
    Color color;
    switch (item.type) {
      case 'video':
        icon = Icons.movie_creation_rounded;
        color = Colors.redAccent;
        break;
      case 'audio':
        icon = Icons.music_note_rounded;
        color = Colors.greenAccent.shade700;
        break;
      default:
        icon = Icons.image_rounded;
        color = Colors.blueAccent;
    }

    return RepaintBoundary(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          item.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          item.platformName ?? item.platform,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: () {
          AdManager.showInterstitialAd();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MediaPreviewScreen(
                filePath: item.filePath,
                fileName: item.fileName,
                fileType: item.type,
                platform: item.platformName,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget? _buildAdBanner() => const AdBanner();

  Widget _buildInputCard(bool isDark) {
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).shadowColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Dynamic platform indicator - shows only detected platform
            if (_platform != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PlatformConfigs.getColor(
                    _platform!,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PlatformConfigs.getColor(
                      _platform!,
                    ).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PlatformConfigs.getIcon(_platform!),
                      color: PlatformConfigs.getColor(_platform!),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      PlatformConfigs.getDisplayName(_platform!),
                      style: TextStyle(
                        color: PlatformConfigs.getColor(_platform!),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Show hint when no platform detected
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '8 plataformas disponibles',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Pega el enlace aquí...',
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.link),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _controller.clear();
                          _platform = null;
                          _tiktokData = null;
                        }),
                      )
                    : IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: _pasteFromClipboard,
                        tooltip: 'Pegar',
                      ),
              ),
              onChanged: (_) => _detectPlatform(),
              onSubmitted: (_) => _fetchMedia(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _loading ? null : _fetchMedia,
                icon: const Icon(Icons.download_rounded),
                label: const Text(
                  'Descargar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(
            Icons.cloud_download_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Listo para descargar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Copia un enlace de tus redes favoritas y pégalo arriba',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(bool isDark) {
    Widget card;
    if (_tiktokData != null) {
      card = TikTokResultCard(data: _tiktokData!, onDownload: _startDownload);
    } else if (_facebookData != null) {
      card = FacebookResultCard(
        data: _facebookData!,
        onDownload: _startDownload,
      );
    } else if (_spotifyData != null) {
      card = SpotifyResultCard(data: _spotifyData!, onDownload: _startDownload);
    } else if (_threadsData != null) {
      card = ThreadsResultCard(data: _threadsData!, onDownload: _startDownload);
    } else if (_youtubeData != null) {
      card = YouTubeResultCard(data: _youtubeData!, onDownload: _startDownload);
    } else if (_bilibiliData != null) {
      card = BilibiliResultCard(
        data: _bilibiliData!,
        onDownload: _startDownload,
      );
    } else if (_instagramData != null) {
      card = InstagramResultCard(
        data: _instagramData!,
        onDownload: _startDownload,
      );
    } else if (_twitterData != null) {
      card = TwitterResultCard(data: _twitterData!, onDownload: _startDownload);
    } else {
      return const SizedBox.shrink();
    }
    // RepaintBoundary prevents the result card from repainting when the ad
    // banner or other unrelated widgets rebuild (e.g. on timer-based ad refresh).
    return RepaintBoundary(child: card);
  }
}
