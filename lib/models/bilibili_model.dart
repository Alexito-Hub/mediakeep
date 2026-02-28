/// Models for Bilibili videos
class BilibiliInfo {
  final String? aid;
  final String? title;
  final String? desc;
  final String? type;
  final String? cover;
  final String? duration;

  BilibiliInfo({
    this.aid,
    this.title,
    this.desc,
    this.type,
    this.cover,
    this.duration,
  });

  factory BilibiliInfo.fromJson(Map<String, dynamic> json) {
    return BilibiliInfo(
      aid: json['aid'],
      title: json['title'],
      desc: json['desc'],
      type: json['type'],
      cover: json['cover'],
      duration: json['duration'],
    );
  }
}

class BilibiliStats {
  final String? views;
  final String? likes;
  final String? coins;
  final String? favorites;
  final String? shares;
  final String? comments;
  final String? danmaku;

  BilibiliStats({
    this.views,
    this.likes,
    this.coins,
    this.favorites,
    this.shares,
    this.comments,
    this.danmaku,
  });

  factory BilibiliStats.fromJson(Map<String, dynamic> json) {
    return BilibiliStats(
      views: json['views'],
      likes: json['likes'],
      coins: json['coins'],
      favorites: json['favorites'],
      shares: json['shares'],
      comments: json['comments'],
      danmaku: json['danmaku'],
    );
  }
}

class BilibiliFormat {
  final String? desc;
  final int? quality;
  final String? format;
  final String? url;
  final List<String>? backup;

  BilibiliFormat({this.desc, this.quality, this.format, this.url, this.backup});

  factory BilibiliFormat.fromJson(Map<String, dynamic> json) {
    return BilibiliFormat(
      desc: json['desc'],
      quality: json['quality'],
      format: json['format'],
      url: json['url'],
      backup: json['backup'] != null ? List<String>.from(json['backup']) : null,
    );
  }
}

class BilibiliData {
  final BilibiliInfo info;
  final BilibiliStats stats;
  final List<BilibiliFormat> videos;
  final List<BilibiliFormat> audios;

  BilibiliData({
    required this.info,
    required this.stats,
    required this.videos,
    required this.audios,
  });

  factory BilibiliData.fromJson(Map<String, dynamic> json) {
    return BilibiliData(
      info: BilibiliInfo.fromJson(json['info'] ?? {}),
      stats: BilibiliStats.fromJson(json['stats'] ?? {}),
      videos: (json['videos'] as List<dynamic>? ?? [])
          .map((v) => BilibiliFormat.fromJson(v))
          .toList(),
      audios: (json['audios'] as List<dynamic>? ?? [])
          .map((a) => BilibiliFormat.fromJson(a))
          .toList(),
    );
  }
}
