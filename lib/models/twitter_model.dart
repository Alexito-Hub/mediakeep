/// Models for Twitter/X media
class TwitterVariant {
  final String? resolution;
  final String? url;

  TwitterVariant({this.resolution, this.url});

  factory TwitterVariant.fromJson(Map<String, dynamic> json) {
    return TwitterVariant(resolution: json['resolution'], url: json['url']);
  }
}

class TwitterMedia {
  final String? type;
  final String? thumbnail;
  final List<TwitterVariant>? variants;
  final String? url;

  TwitterMedia({this.type, this.thumbnail, this.variants, this.url});

  factory TwitterMedia.fromJson(Map<String, dynamic> json) {
    return TwitterMedia(
      type: json['type'],
      thumbnail: json['thumbnail'],
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((v) => TwitterVariant.fromJson(v))
          .toList(),
      url: json['url'],
    );
  }
}

class TwitterData {
  final String? title;
  final List<TwitterMedia>? media;

  TwitterData({this.title, this.media});

  factory TwitterData.fromJson(Map<String, dynamic> json) {
    return TwitterData(
      title: json['title'],
      media: (json['media'] as List<dynamic>? ?? [])
          .map((m) => TwitterMedia.fromJson(m))
          .toList(),
    );
  }
}
