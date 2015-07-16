part of test_util;

class isInstanceOfType implements Matcher {
  final Type _type;
  const isInstanceOfType(Type type) :
    _type = type;

    Description describe(Description description) {
      return new StringDescription("matches type of item to supplied type");
    }

    Description describeMismatch(
      dynamic item, Description mismatchDescription, Map matchState, bool verbose) {
      mismatchDescription.add("${item} did not have expected type ${_type}");
      return mismatchDescription;
    }

    bool matches(item, Map matchState) {
      return item.runtimeType == _type;
    }
}