import 'package:test/test.dart';

import '../../lib/src/glob/glob.dart';

class TestCase {
  final String pattern;
  final String name;
  final bool shouldMatch;
  TestCase(this.pattern, this.name, this.shouldMatch);
}

Matcher throwsBadPatternException = throwsA(
    new isInstanceOf<BadPatternException>());

void main() {
  group('Glob constructor', () {
    test('new Glob with empty pattern', () {
      Glob g = new Glob.parse('');
      expect(g.length, isZero);
      expect(g.restricted, isFalse);
      expect(g.recursive, isFalse);
    });

    test('new Glob with invalid pattern', () {
      attemptConstruct() {
        return new Glob.parse('/invalid');
      }
      expect(attemptConstruct, throwsBadPatternException);
    });

    test('new Glob with valid pattern', () {
      Glob g = new Glob.parse('foo/bar/x*/...');
      expect(g.length, equals(3));
      expect(g.restricted, isFalse);
      expect(g.recursive, isTrue);
    });
  });

  group('matchInitialSegment', () {
    // These test cases are taken from
    // $V23_ROOT/release/go/src/v.io/v23/glob/glob_test.go

    // TODO(nlacasse): Is there a better way to do this?  This just looks
    // silly.
    List<TestCase> testCases = [
      new TestCase('...', '', true),
      new TestCase('***', '', true),
      new TestCase('...', 'a', true),
      new TestCase('***', 'a', true),
      new TestCase('a', '', false),
      new TestCase('a', 'a', true),
      new TestCase('a', 'a*', false),
      new TestCase('a', 'b', false),
      new TestCase('a*', 'a', true),
      new TestCase('a*', 'a*', true),
      new TestCase('a*', 'b', false),
      new TestCase('a*b', 'ab', true),
      new TestCase('a*b', 'afoob', true),
      new TestCase('a\\*', 'a', false),
      new TestCase('a\\*', 'a*', true),
      new TestCase('\\\\', '\\', true),
      new TestCase('?', '?', true),
      new TestCase('?', 'a', true),
      new TestCase('?', '', false),
      new TestCase('*?', '', false),
      new TestCase('*?', 'a', true),
      new TestCase('*?', 'ab', true),
      new TestCase('*?', 'abv', true),
      new TestCase('[abc]', 'a', true),
      new TestCase('[abc]', 'b', true),
      new TestCase('[abc]', 'c', true),
      new TestCase('[abc]', 'd', false),
      new TestCase('[a-c]', 'a', true),
      new TestCase('[a-c]', 'b', true),
      new TestCase('[a-c]', 'c', true),
      new TestCase('[a-c]', 'd', false),
      new TestCase('\\[abc]', 'a', false),
      new TestCase('\\[abc]', '[abc]', true),
      new TestCase('a/*', 'a', true),
      new TestCase('a/*', 'b', false),
      new TestCase('a/...', 'a', true),
      new TestCase('a/...', 'b', false)
    ];

    testCases.forEach((tc) {
      String desc = 'pattern: "${tc.pattern}", name: "${tc.name}", shouldMatch: ${tc.shouldMatch}';
      test(desc, () {
        Glob g = new Glob.parse(tc.pattern);
        Glob got = g.matchInitialSegment(tc.name);
        expect(got, tc.shouldMatch ? isNotNull : isNull);
      });
    });
  });
}
