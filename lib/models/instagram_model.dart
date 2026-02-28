/// Models for Instagram media
class InstagramOption {
  final String res;
  final String url;

  InstagramOption({required this.res, required this.url});

  factory InstagramOption.fromJson(Map<String, dynamic> json) {
    return InstagramOption(res: json['res'] ?? '', url: json['url'] ?? '');
  }
}

class InstagramMedia {
  final String? thumb;
  final List<InstagramOption> options;
  final String? download;

  InstagramMedia({this.thumb, required this.options, this.download});

  factory InstagramMedia.fromJson(Map<String, dynamic> json) {
    return InstagramMedia(
      thumb: json['thumb'],
      options: (json['options'] as List<dynamic>? ?? [])
          .map((o) => InstagramOption.fromJson(o))
          .toList(),
      download: json['download'],
    );
  }
}

class InstagramData {
  final List<InstagramMedia> media;

  InstagramData({required this.media});

  factory InstagramData.fromJson(Map<String, dynamic> json) {
    return InstagramData(
      media: (json['media'] as List<dynamic>? ?? [])
          .map((m) => InstagramMedia.fromJson(m))
          .toList(),
    );
  }
}
