/// Data models for TikTok media
class TikTokData {
  final String id;
  final String title;
  final String cover;
  final Author author;
  final Music? music;
  final MediaInfo media;
  final int playCount;
  final int diggCount;
  final int commentCount;
  final int shareCount;

  TikTokData({
    required this.id,
    required this.title,
    required this.cover,
    required this.author,
    this.music,
    required this.media,
    required this.playCount,
    required this.diggCount,
    required this.commentCount,
    required this.shareCount,
  });

  factory TikTokData.fromJson(Map<String, dynamic> json) {
    return TikTokData(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sin título',
      cover: json['cover'] ?? '',
      author: Author.fromJson(json['author'] ?? {}),
      music: json['music'] != null ? Music.fromJson(json['music']) : null,
      media: MediaInfo.fromJson(json['media'] ?? {}),
      playCount: json['views_count'] ?? 0,
      diggCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
    );
  }
}

class Author {
  final String nickname;
  final String avatar;

  Author({required this.nickname, required this.avatar});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      nickname: json['nickname'] ?? 'Desconocido',
      avatar: json['avatar'] ?? '',
    );
  }
}

class Music {
  final String title;
  final String playUrl;
  final String author;

  Music({required this.title, required this.playUrl, required this.author});

  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      title: json['title'] ?? 'Sonido original',
      playUrl: json['play'] ?? '',
      author: json['author'] ?? '',
    );
  }
}

class MediaInfo {
  final String type;
  final List<String> images;
  final VideoSource? noWatermark;
  final VideoSource? watermark;

  MediaInfo({
    required this.type,
    required this.images,
    this.noWatermark,
    this.watermark,
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      type: json['type'] ?? 'video',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      noWatermark: json['nowatermark'] != null && json['nowatermark'] is Map
          ? VideoSource.fromJson(json['nowatermark'])
          : null,
      watermark: json['watermark'] != null && json['watermark'] is Map
          ? VideoSource.fromJson(json['watermark'])
          : null,
    );
  }
}

class VideoSource {
  final String play;
  final String? hdPlay;
  final int size;

  VideoSource({required this.play, this.hdPlay, required this.size});

  factory VideoSource.fromJson(Map<String, dynamic> json) {
    return VideoSource(
      play: json['play'] ?? '',
      hdPlay: json['hd'] != null ? json['hd']['play'] : null,
      size: json['size'] ?? 0,
    );
  }
}
