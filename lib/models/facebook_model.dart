/// Model for Facebook posts and media
class FacebookData {
  final String type;
  final String url;
  final String author;
  final String title;
  final String creation;
  final String? download;
  final List<String>? images;
  final String? thumbnail;
  final int? duration;

  FacebookData({
    required this.type,
    required this.url,
    required this.author,
    required this.title,
    required this.creation,
    this.download,
    this.images,
    this.thumbnail,
    this.duration,
  });

  factory FacebookData.fromJson(Map<String, dynamic> json) {
    return FacebookData(
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      author: json['author'] ?? 'Facebook User',
      title: json['title'] ?? 'Facebook Post',
      creation: json['creation'] ?? '',
      download: json['download'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      thumbnail: json['thumbnail'],
      duration: json['duration'],
    );
  }

  bool get isAlbum => images != null && images!.isNotEmpty;
  bool get isVideo => type == 'video';
  bool get isSingleImage => type == 'image' && !isAlbum;
}
