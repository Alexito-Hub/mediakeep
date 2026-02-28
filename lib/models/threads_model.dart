/// Models for Threads posts and media
class ThreadsAuthor {
  final String username;
  final String profilePicUrl;
  final String id;
  final bool isVerified;

  ThreadsAuthor({
    required this.username,
    required this.profilePicUrl,
    required this.id,
    required this.isVerified,
  });

  factory ThreadsAuthor.fromJson(Map<String, dynamic> json) {
    return ThreadsAuthor(
      username: json['username'] ?? 'Unknown',
      profilePicUrl: json['profile_pic_url'] ?? '',
      id: json['id'] ?? '',
      isVerified: json['is_verified'] ?? false,
    );
  }
}

class ThreadsMedia {
  final String type;
  final String url;
  final int? width;
  final int? height;

  ThreadsMedia({
    required this.type,
    required this.url,
    this.width,
    this.height,
  });

  factory ThreadsMedia.fromJson(Map<String, dynamic> json) {
    return ThreadsMedia(
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      width: json['width'],
      height: json['height'],
    );
  }
}

class ThreadsData {
  final bool status;
  final String title;
  final int likes;
  final int repost;
  final int reshare;
  final int comments;
  final int creation;
  final ThreadsAuthor author;
  final List<ThreadsMedia> media;

  ThreadsData({
    required this.status,
    required this.title,
    required this.likes,
    required this.repost,
    required this.reshare,
    required this.comments,
    required this.creation,
    required this.author,
    required this.media,
  });

  factory ThreadsData.fromJson(Map<String, dynamic> json) {
    List<ThreadsMedia> mediaList = [];

    if (json['download'] != null) {
      if (json['download'] is List) {
        mediaList = (json['download'] as List)
            .map((m) => ThreadsMedia.fromJson(m))
            .toList();
      } else {
        mediaList = [ThreadsMedia.fromJson(json['download'])];
      }
    }

    return ThreadsData(
      status: json['status'] ?? false,
      title: json['title'] ?? 'Threads Post',
      likes: json['likes'] ?? 0,
      repost: json['repost'] ?? 0,
      reshare: json['reshare'] ?? 0,
      comments: json['comments'] ?? 0,
      creation: json['creation'] ?? 0,
      author: ThreadsAuthor.fromJson(json['author'] ?? {}),
      media: mediaList,
    );
  }

  bool get hasMultipleMedia => media.length > 1;
  String get creationFormatted {
    return DateTime.fromMillisecondsSinceEpoch(creation * 1000).toString();
  }
}
