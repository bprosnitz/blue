import 'package:test/test.dart';
import '../../lib/src/vdl/vdl.dart';
import './value_test_types.dart';

void main() {
  // Test cases that ensure VdlBase meets basic expectations.
  group('VdlBase - sanity checks', () {
    List<VdlBaseExample> examples = makeVdlBaseExamples();

    // Some subclasses must satisfy 'is' (usually by mixin).
    group('implements correct interfaces', () {
      for (VdlBaseExample example in examples) {
        test(example.testName, () {
          expect(example.testValue, new isInstanceOf<VdlBase>());
          if (example.testType.kind == VdlKind.List ||
            example.testType.kind == VdlKind.Array) {
            expect(example.testValue, new isInstanceOf<List>());
          }
          if (example.testType.kind == VdlKind.Map) {
            expect(example.testValue, new isInstanceOf<Map>());
          }
          if (example.testType.kind == VdlKind.Set) {
            expect(example.testValue, new isInstanceOf<Set>());
          }
        });
      }
    });

    // VdlBase can compute its VdlType.
    group('expected VdlType', () {
      for (VdlBaseExample example in examples) {
        test(example.testName, () {
          identical(vdlTypeOf(example.testValue), example.testType);
        });
      }
    });

    // VdlBase toString acts reasonably.
    group('expected toString', () {
      for (VdlBaseExample example in examples) {
        test(example.testName, () {
          expect(example.testValue.toString(),
            equals(example.expectedToString));
        });
      }
    });
  });

  // Kind-specific tests to check that each kind of VdlBase behaves properly.
  // TODO(alexfandrianto): Incomplete. Ideally, we'll have a test per kind.
  group('VdlList', () {
    BoolList bList = new BoolList(new List<bool>());

    test('adding', () {
      for (int i = 0; i < 10; i++) {
        bool answer = (i % 2 == 0);
        bList.add(answer);
        expect(bList.length, equals(i+1)); // check length
        expect(bList[i], equals(answer)); // check that get matches add
      }
    });
  });
  group('VdlArray', () {
    List<bool> testArray = <bool>[false, true, false];
    List<bool> reference = <bool>[false, true, false];
    BoolArray3 bArray3 = new BoolArray3(testArray);

    test('getting', () {
      expect(reference.length, equals(bArray3.length));
      for (int i = 0; i < reference.length; i++) {
        expect(reference[i], equals(bArray3[i]));
      }
    });

    test('iterating', () {
      int temp = 0;
      for (bool b in bArray3) {
        expect(reference[temp], equals(b));
        temp++;
      }
    });

    test('setting', () {
      bArray3[2] = true;
      expect(bArray3[2], isTrue);
    });

    test('length is fixed', () {
      expect(() => bArray3.length = 4,
        throwsA(new isInstanceOf<UnsupportedError>()));
    });
  });

  group('VdlList - recursive', () {
    group('direct cycle', () {
      test('builds', () {
        // Make a list that has 2 other lists inside.
        DirectCycle dcvA = new DirectCycle([]);
        DirectCycle dcvB = new DirectCycle([]);
        DirectCycle dcvC = new DirectCycle([]);
        dcvA.add(dcvB);
        dcvA.add(dcvC);

        expect(dcvA.toString(), '[[], []]');
      });
    });
    group('indirect cycle', () {
      test('builds', () {
        // Make a list (type 1) with 2 lists (type 2) inside, one of which has a
        // list (type 1) inside as well.
        IndirectCycle icvA = new IndirectCycle([]);
        IndirectCycle icvB = new IndirectCycle([]);
        IndirectCycle2 icv2A = new IndirectCycle2([]);
        IndirectCycle2 icv2B = new IndirectCycle2([]);
        icvA.add(icv2A);
        icvA.add(icv2B);
        icv2A.add(icvB);

        expect(icvA.toString(), '[[[]], []]');
      });
    });
  });

  group('VdlMap', () {
    Map<int, double> inverseMap = <int, double>{4: 0.25, 1: 1.0, -3: -0.333};

    InverseMap inverseMapValue =
      new InverseMap(inverseMap);

    test('insert + remove', () {
      expect(inverseMapValue[2], equals(null));
      inverseMapValue[2] = 0.5;
      expect(inverseMapValue[2], equals(0.5));
      double removed = inverseMapValue.remove(2);
      expect(removed, equals(0.5));
      expect(inverseMapValue[2], equals(null));
    });
  });
}

class VdlBaseExample {
  String testName;
  VdlBase testValue;
  VdlType testType;
  String expectedToString;

  VdlBaseExample(this.testName, this.testValue, this.testType,
    this.expectedToString);
}

List<VdlBaseExample> makeVdlBaseExamples() {
  List<VdlBaseExample> examples = new List<VdlBaseExample>();
  examples.add(new VdlBaseExample('empty String', new NamedString.zero(),
    VdlTypes.String, ''));
  examples.add(new VdlBaseExample('abc String', new NamedString('abc'),
    VdlTypes.String, 'abc'));
  examples.add(new VdlBaseExample('default Bool', new NamedBool.zero(),
    VdlTypes.Bool, 'false'));
  examples.add(new VdlBaseExample('129 byte', new NamedByte(129),
    VdlTypes.Byte, '129'));
  examples.add(new VdlBaseExample('ABCStruct', new ABCStruct('ABC', -4, true),
    abcStructType, '{A: ABC, B: -4, C: true}'));

  List<String> strs = <String>['aa', 'bB', 'cd'];
  examples.add(new VdlBaseExample('List<String>',
    new StringList(strs), stringListType, "[aa, bB, cd]"));


  Map<bool, VdlComplex> pointlessMap = <bool, VdlComplex>{true: new VdlComplex.zero(),
    false: new VdlComplex(3.5, -4.3)};
  examples.add(new VdlBaseExample('Map<bool, Complex64>',
    new BoolComplexMap(pointlessMap), boolComplexMapType, "{true: 0.0+0.0i, false: 3.5-4.3i}"));


  Set<int> numSet = new Set<int>();
  numSet.add(4);
  numSet.add(-2);
  examples.add(new VdlBaseExample('Set<int16>',
    new IntSet(numSet), intSetType, '{4, -2}'));

  return examples;
}