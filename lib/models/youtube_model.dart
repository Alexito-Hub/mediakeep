/// Models for YouTube videos
class YouTubeInfo {
  final String? id;
  final String? title;
  final String? desc;
  final String? thumb;
  final String? preview;
  final String? link;
  final String? service;
  final String? status;
  final String? message;

  YouTubeInfo({
    this.id,
    this.title,
    this.desc,
    this.thumb,
    this.preview,
    this.link,
    this.service,
    this.status,
    this.message,
  });

  factory YouTubeInfo.fromJson(Map<String, dynamic> json) {
    return YouTubeInfo(
      id: json['id'],
      title: json['title'],
      desc: json['desc'],
      thumb: json['thumb'],
      preview: json['preview'],
      link: json['link'],
      service: json['service'],
      status: json['status'],
      message: json['message'],
    );
  }
}

class YouTubeChannel {
  final String? name;
  final String? user;
  final String? id;
  final String? avatar;
  final bool verified;
  final String? site;
  final String? bio;
  final String? category;
  final String? internal;
  final String? country;
  final String? joined;

  YouTubeChannel({
    this.name,
    this.user,
    this.id,
    this.avatar,
    this.verified = false,
    this.site,
    this.bio,
    this.category,
    this.internal,
    this.country,
    this.joined,
  });

  factory YouTubeChannel.fromJson(Map<String, dynamic> json) {
    return YouTubeChannel(
      name: json['name'],
      user: json['user'],
      id: json['id'],
      avatar: json['avatar'],
      verified: json['verified'] ?? false,
      site: json['site'],
      bio: json['bio'],
      category: json['category'] is String ? json['category'] : null,
      internal: json['internal'],
      country: json['country'],
      joined: json['joined'],
    );
  }
}

class YouTubeStats {
  final String? views;
  final String? vids;
  final String? subs;
  final String? following;
  final String? likes;
  final String? comments;
  final String? favorites;
  final String? shares;
  final String? downloads;

  YouTubeStats({
    this.views,
    this.vids,
    this.subs,
    this.following,
    this.likes,
    this.comments,
    this.favorites,
    this.shares,
    this.downloads,
  });

  factory YouTubeStats.fromJson(Map<String, dynamic> json) {
    return YouTubeStats(
      views: json['views'] is String ? json['views'] : null,
      vids: json['vids'] is String ? json['vids'] : null,
      subs: json['subs'] is String ? json['subs'] : null,
      following: json['following'] is String ? json['following'] : null,
      likes: json['likes'] is String ? json['likes'] : null,
      comments: json['comments'] is String ? json['comments'] : null,
      favorites: json['favorites'] is String ? json['favorites'] : null,
      shares: json['shares'] is String ? json['shares'] : null,
      downloads: json['downloads'] is String ? json['downloads'] : null,
    );
  }
}

class YouTubeFormat {
  final String? quality;
  final String? res;
  final String? size;
  final String? format;
  final String? duration;
  final String? url;

  YouTubeFormat({
    this.quality,
    this.res,
    this.size,
    this.format,
    this.duration,
    this.url,
  });

  factory YouTubeFormat.fromJson(Map<String, dynamic> json) {
    return YouTubeFormat(
      quality: json['quality'],
      res: json['res'],
      size: json['size'],
      format: json['format'],
      duration: json['duration'],
      url: json['url'],
    );
  }
}

class YouTubeData {
  final YouTubeInfo info;
  final YouTubeChannel channel;
  final YouTubeStats stats;
  final List<YouTubeFormat> videos;
  final List<YouTubeFormat> audios;

  YouTubeData({
    required this.info,
    required this.channel,
    required this.stats,
    required this.videos,
    required this.audios,
  });

  factory YouTubeData.fromJson(Map<String, dynamic> json) {
    return YouTubeData(
      info: YouTubeInfo.fromJson(json['info'] ?? {}),
      channel: YouTubeChannel.fromJson(json['channel'] ?? {}),
      stats: YouTubeStats.fromJson(json['stats'] ?? {}),
      videos: (json['videos'] as List<dynamic>? ?? [])
          .map((v) => YouTubeFormat.fromJson(v))
          .toList(),
      audios: (json['audios'] as List<dynamic>? ?? [])
          .map((a) => YouTubeFormat.fromJson(a))
          .toList(),
    );
  }
}
