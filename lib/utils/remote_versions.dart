import 'dart:convert';
import 'package:http/http.dart' as http;

class GithubContent {
  final String name;
  final String? downloadUrl;
  final String version;

  GithubContent({
    required this.name,
    required this.downloadUrl,
    required this.version,
  });

  factory GithubContent.fromJson(Map<String, dynamic> json) {
    final version = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(json['name'])?.group(1) ?? '0.0.0';

    return GithubContent(
      name: json['name'],
      downloadUrl: json['download_url'],
      version: version,
    );
  }
}

Future<GithubContent> getLatestVersion(String owner, String repo, String path) async {
  final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');

  try {
    final response = await http.get(url, headers: {
      'Accept': 'application/vnd.github.v3+json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> contents = json.decode(response.body);

      if (contents.isEmpty) {
        throw Exception('No files found in the specified path');
      }

      // Convert all items to GithubContent objects
      final List<GithubContent> files = contents
          .map((item) => GithubContent.fromJson(item))
          .where((file) => file.name.endsWith('.apk')) // Filter APK files
          .toList();

      // Sort by version number
      files.sort((a, b) {
        final List<int> versionA = a.version.split('.').map(int.parse).toList();
        final List<int> versionB = b.version.split('.').map(int.parse).toList();

        for (int i = 0; i < versionA.length; i++) {
          if (versionA[i] != versionB[i]) {
            return versionB[i].compareTo(versionA[i]); // Descending order
          }
        }
        return 0;
      });

      return files.first; // Return the latest version
    } else {
      throw Exception('Failed to load repository contents: ${response.statusCode}');
    }
  } catch (e, s) {
    throw Exception('Error fetching latest version: $e $s');
  }
}
