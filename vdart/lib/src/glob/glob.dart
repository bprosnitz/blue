// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Library glob defines a globbing syntax and implements matching routines.
//
// Globs match a slash separated series of glob expressions.
//
//   // Patterns:
//   term ['/' term]*
//   term:
//   '*'         matches any sequence of non-Separator characters
//   '?'         matches any single non-Separator character
//   '[' [ '^' ] { character-range } ']'
//   // Character classes (must be non-empty):
//   c           matches character c (c != '*', '?', '\\', '[', '/')
//   '\\' c      matches character c
//   // Character-ranges:
//   c           matches character c (c != '\\', '-', ']')
//   '\\' c      matches character c
//   lo '-' hi   matches character c for lo <= c <= hi

library glob;

import 'dart:collection' show Queue;

// TODO(nlacasse): Make this a verror once we have them.
class BadPatternException implements Exception {
  final String pattern;
  const BadPatternException(this.pattern);
  String toString() => 'BadPatternException: $pattern';
}

// Glob represents a slash seperated path glob pattern.
class Glob {
  final Iterable<RegExp> _parts;
  final bool recursive;
  final bool restricted;

  // length is the number of path elements represented by a glob expression.
  int get length => _parts.length;

  // finished is true if the pattern cannot match anything.
  bool get finished => !recursive && (length == 0);

  // Internal named constructor.
  Glob._(this._parts, {
    this.recursive: false,
    this.restricted: false
  });

  // Glob.parse is a named constructor that parses the pattern and returns a
  // new Glob.
  factory Glob.parse(String pattern) {
    if (pattern.startsWith('/')) {
      throw new BadPatternException(pattern);
    }

    if (pattern == null || pattern.length == 0) {
      return new Glob._(new Queue());
    }

    List<String> parts = pattern.split('/');
    bool rec = false;
    bool res = false;

    if (parts.last == '...') {
      parts.removeLast();
      rec = true;
    } else if (parts.last == '***') {
      parts.removeLast();
      rec = true;
      res = true;
    }

    Queue<RegExp> partsQueue = new Queue.from(parts.map((part) {
      return _patternToRegex(part);
    }));

    return new Glob._(partsQueue, recursive: rec, restricted: res);
  }

  // matchInitialSegment will match the first part of the Glob against the
  // given string.  If no match is found, then 'null' is returned.  Otherwise,
  // a Glob object is returned which matches everything but the first segment
  // of the current Glob.
  Glob matchInitialSegment(String s) {
    if (length == 0) {
      return recursive ? this : null;
    }

    if (_parts.first.hasMatch(s)) {
      // Return a Glob that matches everything but the first part of the
      // current Glob.
      return new Glob._(_parts.skip(1),
        restricted: restricted,
        recursive: recursive
      );
    }

    return null;
  }

  // toString returns a string representation of the glob pattern.
  String toString() {
    return _parts.map((regexp) => regexp.toString()).join('/');
  }
}

// _patternToRegex turns a pattern into a regex that matches that pattern.
RegExp _patternToRegex(String pattern) {
  List<String> chars = pattern.split('');
  StringBuffer s = new StringBuffer();

  // Match must start at beginning.
  s.write('^');

  for(int i = 0; i < chars.length; i++) {
    String c = chars[i];

    if (c == '\\' && (i + 1 < chars.length)) {
      // Treat any char after '\' as a literal.
      s.write('\\${chars[i + 1]}');
      i++;
    } else if (c == '*') {
      if ((i + 1 < chars.length) && (chars[i + 1] == '*')) {
        // Two stars match anything.
        s.write('.*');
        i++;
      } else {
        // One star matches anything except '/'.
        s.write('[^/]*');
      }
    } else if (c == '?') {
      // Question mark matches a single char execpt '/'.
      s.write('[^/]');
    } else {
      // Anything else is a literal.
      s.write(c);
    }
  }

  // Match must end at the end of the string.
  s.write('\$');

  return new RegExp(s.toString());
}
