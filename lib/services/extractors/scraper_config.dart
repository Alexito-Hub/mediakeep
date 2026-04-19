import 'scraper_secrets.dart';

class ScraperConfig {
  static const String youtubeProxyUrl = 'https://app.ytdown.to/proxy.php';
  static const String tiktokApiUrl = 'https://tikwm.com/api/';
  static const String twitterApiUrl = 'https://twittermedia.b-cdn.net/media';
  static const String spotifyConvertUrl = 'https://spotmate.online/convert';
  static const String spotifyHomeUrl = 'https://spotmate.online';
  static const String instagramVerifyUrl = 'https://savevid.net/api/userverify';
  static const String instagramSearchUrl =
      'https://v3.savevid.net/api/ajaxSearch';
  static const String bilibiliPlayUrl =
      'https://api.bilibili.tv/intl/gateway/web/playurl';

  static Map<String, String> defaultHeaders() {
    return <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9',
    };
  }

  static Map<String, String> tiktokHeaders() {
    return <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'Cookie': 'current_language=en',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
    };
  }

  static Map<String, String> twitterHeaders() {
    return <String, String>{
      'accept': '*/*',
      'accept-encoding': 'gzip, deflate, br',
      'accept-language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
      'origin': 'https://snaplytics.io',
      'referer': 'https://snaplytics.io/',
      'user-agent':
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/139.0.0.0 Mobile Safari/537.36',
    };
  }

  static Map<String, String> threadsHeaders() {
    return <String, String>{
      'sec-fetch-user': '?1',
      'sec-ch-ua-mobile': '?0',
      'sec-fetch-site': 'none',
      'sec-fetch-dest': 'document',
      'sec-fetch-mode': 'navigate',
      'cache-control': 'max-age=0',
      'authority': 'www.threads.net',
      'upgrade-insecure-requests': '1',
      'accept-language': 'en-GB,en;q=0.9,tr-TR;q=0.8,tr;q=0.7,en-US;q=0.6',
      'sec-ch-ua':
          '"Google Chrome";v="89", "Chromium";v="89", ";Not A Brand";v="99"',
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36',
      'accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    };
  }

  static Map<String, String> facebookHeaders() {
    return <String, String>{
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      'accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'accept-language': 'en-US,en;q=0.9',
      'sec-fetch-mode': 'navigate',
      'upgrade-insecure-requests': '1',
    };
  }

  static Map<String, String> backendHeaders() {
    final headers = defaultHeaders();
    ScraperSecrets.attachTokenIfPresent(headers);
    return headers;
  }
}
