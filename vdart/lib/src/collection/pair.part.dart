part of collection;

class Pair<K, V> {
  final K key;
  final V value;
  Pair(K key, V value) :
    key = key,
    value = value;
  String toString() => '(${key}, ${value})';
  bool operator ==(other) =>
    other is Pair &&
    key == other.key &&
    value == other.value;
  int get hashCode {
    // These values are chosen for hash code because they are the
    // standard for Java and suggested in one of the dart tutorials.
    int result = 17;
    result = 37 * result + key.hashCode;
    result = 37 * result + value.hashCode;
    return result;
  }
}