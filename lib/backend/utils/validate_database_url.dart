bool validateXataUrl(String url) {
  try {
    Uri uri = Uri.parse(url);

    // Check the scheme, host, and path
    if (uri.scheme != 'https' || uri.host.split('.').length != 4 || uri.pathSegments.length != 2) {
      return false;
    }

    // Validate the host format: [username].[region].xata.sh
    final hostParts = uri.host.split('.');
    final username = hostParts[0];
    final region = hostParts[1];
    final domain = hostParts[2];
    final tld = hostParts[3];

    if (domain != 'xata' || tld != 'sh') {
      return false;
    }

    // Validate the path: /db/[dbname]:[tablename]
    if (uri.pathSegments[0] != 'db') {
      return false;
    }

    final dbTable = uri.pathSegments[1].split(':');
    if (dbTable.length != 2) {
      return false;
    }

    final dbname = dbTable[0];
    final tablename = dbTable[1];

    // Check if all parts contain valid characters
    final validPattern = RegExp(r'^[a-zA-Z0-9\-]+$');
    return validPattern.hasMatch(username) &&
        validPattern.hasMatch(region) &&
        validPattern.hasMatch(dbname) &&
        validPattern.hasMatch(tablename);
  } catch (e) {
    return false;
  }
}
