part of vdl;

String _changeCase(String str, String convertStringCase(String s)) {
  if (str == null) {
    throw new Exception('cannot change case of null string');
  }
  if (str == '') {
    return '';
  }

  var firstRuneStr = new String.fromCharCode(str.runes.first);
  var strRemainder = new String.fromCharCodes(str.runes.skip(1));

  return convertStringCase(firstRuneStr) + strRemainder;
}

String _toUpperCamelCase(String str) {
  return _changeCase(str, (s) => s.toUpperCase());
}