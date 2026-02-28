/// Models for Spotify tracks and artists
class SpotifyArtist {
  final String name;
  final String type;
  final String id;

  SpotifyArtist({required this.name, required this.type, required this.id});

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    return SpotifyArtist(
      name: json['name'] ?? 'Unknown Artist',
      type: json['type'] ?? 'artist',
      id: json['id'] ?? '',
    );
  }
}

class SpotifyData {
  final String id;
  final String title;
  final int duration;
  final String popularity;
  final String thumbnail;
  final String date;
  final List<SpotifyArtist> artists;
  final String url;
  final String download;
  final String? previewUrl;

  SpotifyData({
    required this.id,
    required this.title,
    required this.duration,
    required this.popularity,
    required this.thumbnail,
    required this.date,
    required this.artists,
    required this.url,
    required this.download,
    this.previewUrl,
  });

  factory SpotifyData.fromJson(Map<String, dynamic> json) {
    return SpotifyData(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Track',
      duration: json['duration'] ?? 0,
      popularity: json['popularity'] ?? '0%',
      thumbnail: json['thumbnail'] ?? '',
      date: json['date'] ?? '',
      artists: json['artist'] != null
          ? (json['artist'] as List)
                .map((a) => SpotifyArtist.fromJson(a))
                .toList()
          : [],
      url: json['url'] ?? '',
      download: json['download'] ?? '',
      previewUrl: json['preview'],
    );
  }

  String get durationFormatted {
    final seconds = (duration / 1000).round();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String get artistNames => artists.map((a) => a.name).join(', ');
}
