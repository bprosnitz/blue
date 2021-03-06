part of vom;

const FIRST_NEW_VOM_ID = 41;

// Test cases for type definition decoding.
class TypeDefTestCase{
  final vdl.VdlType wireDefType;
  final List<int> bytes;

  final _PartialVdlType expectedPartialType;
  final vdl.VdlType expectedFinalType;
  final Type expectedException;

  TypeDefTestCase(this.wireDefType, String inputHex, this.expectedPartialType, this.expectedFinalType) :
    expectedException = null,
    bytes = test_util.hex2Bin(inputHex);
  TypeDefTestCase.failure(this.wireDefType, String inputHex, this.expectedException) :
    expectedPartialType = null,
    expectedFinalType = null,
    bytes = test_util.hex2Bin(inputHex);
}

Map<String, TypeDefTestCase> createValidTestCases() {
  var testCases = new Map<String, TypeDefTestCase>();

  String wireNamedHex =
    '00' //                   Index                              0 [main.wireNamed.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireNamed.Base]
    '05' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireNamed END]
  _PartialVdlType wireNamedPt = new _PartialVdlType.namedType('aname', 5);
  vdl.VdlType wireNamedType = (new vdl.VdlPendingType()..name='aname'..kind=vdl.VdlKind.Uint32).build();
  testCases['named'] = new TypeDefTestCase(_WireNamed.vdlType, wireNamedHex, wireNamedPt, wireNamedType);

  String enumHex =
    '00' //                   Index                              0 [main.wireEnum.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireEnum.Labels]
    '02' //                   ValueLen                           2 [list len]
    '01' //                   ByteLen                            1 [string len]
    '41' //                   PrimValue                        'A' [string]
    '02' //                   ByteLen                            2 [string len]
    '4242' //                 PrimValue                       'BB' [string]
    'e1'; //                   Control                          End [main.wireEnum END]
    _PartialVdlType enumPt = new _PartialVdlType.enumType('aname', <String>['A', 'BB']);
    vdl.VdlType enumType = (new vdl.VdlPendingType()
      ..name = 'aname'
      ..kind = vdl.VdlKind.Enum
      ..labels = ['A', 'BB']).build();
    testCases['enum'] = new TypeDefTestCase(_WireEnum.vdlType, enumHex, enumPt, enumType);

  String arrayHex =
    '00' //                   Index                              0 [main.wireArray.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireArray.Elem]
    '05' //                   PrimValue                         5 [uint]
    '02' //                   Index                              2 [main.wireArray.Len]
    '0b' //                   PrimValue                         11 [uint]
    'e1'; //                   Control                          End [main.wireArray END]
  _PartialVdlType arrayPt = new _PartialVdlType.arrayType('aname', 5, 11);
  vdl.VdlType arrayType = (new vdl.VdlPendingType()
    ..name = 'aname'
    ..kind = vdl.VdlKind.Array
    ..elem = vdl.VdlTypes.Uint32
    ..len = 11).build();
  testCases['array'] = new TypeDefTestCase(_WireArray.vdlType, arrayHex, arrayPt, arrayType);

  String listHex =
    '00' //                   Index                              0 [main.wireList.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireList.Elem]
    '05' //                   PrimValue                         5 [uint]
    'e1'; //                   Control                          End [main.wireList END]
  _PartialVdlType listPt = new _PartialVdlType.listType('aname', 5);
  vdl.VdlType listType = (new vdl.VdlPendingType()
    ..name = 'aname'
    ..kind = vdl.VdlKind.List
    ..elem = vdl.VdlTypes.Uint32).build();
  testCases['list'] = new TypeDefTestCase(_WireList.vdlType, listHex, listPt, listType);

  String setHex =
    '00' //                   Index                              0 [main.wireSet.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireSet.Key]
    '05' //                   PrimValue                         5 [uint]
    'e1'; //                   Control                          End [main.wireSet END]
  _PartialVdlType setPt = new _PartialVdlType.setType('aname', 5);
  vdl.VdlType setType = (new vdl.VdlPendingType()
    ..name = 'aname'
    ..kind = vdl.VdlKind.Set
    ..key = vdl.VdlTypes.Uint32).build();
  testCases['set'] = new TypeDefTestCase(_WireSet.vdlType, setHex, setPt, setType);

  String mapHex =
    '00' //                   Index                              0 [main.wireMap.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireMap.Key]
    '05' //                   PrimValue                         5 [uint]
    '02' //                   Index                              2 [main.wireMap.Elem]
    '09' //                   PrimValue                         9 [uint]
    'e1'; //                   Control                          End [main.wireMap END]
  _PartialVdlType mapPt = new _PartialVdlType.mapType('aname', 5, 9);
  vdl.VdlType mapType = (new vdl.VdlPendingType()
    ..name = 'aname'
    ..kind = vdl.VdlKind.Map
    ..key = vdl.VdlTypes.Uint32
    ..elem = vdl.VdlTypes.Int64).build();
  testCases['map'] = new TypeDefTestCase(_WireMap.vdlType, mapHex, mapPt, mapType);

  String unionStructHex =
    '00' //                   Index                              0 [main.wireStruct.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireStruct.Fields]
    '02' //                   ValueLen                           2 [list len]
    '00' //                   Index                              0 [main.wireField.Name]
    '01' //                   ByteLen                            1 [string len]
    '41' //                   PrimValue                        'A' [string]
    '01' //                   Index                              1 [main.wireField.Type]
    '05' //                   PrimValue                         5 [uint]
    'e1' //                   Control                          End [main.wireField END]
    '00' //                   Index                              0 [main.wireField.Name]
    '01' //                   ByteLen                            1 [string len]
    '42' //                   PrimValue                        'B' [string]
    '01' //                   Index                              1 [main.wireField.Type]
    '09' //                   PrimValue                         9 [uint]
    'e1' //                   Control                          End [main.wireField END]
    'e1'; //                   Control                          End [main.wireStruct END]
  _PartialVdlType structPt = new _PartialVdlType.structType('aname', <_PartialVdlField>[new _PartialVdlField('A', 5), new _PartialVdlField('B', 9)]);
  vdl.VdlType structType = (new vdl.VdlPendingType()
    ..name = 'aname'
    ..kind = vdl.VdlKind.Struct
    ..fields = [
      new vdl.VdlPendingField('A', vdl.VdlTypes.Uint32),
      new vdl.VdlPendingField('B', vdl.VdlTypes.Int64)
    ]).build();
  testCases['struct'] = new TypeDefTestCase(_WireStruct.vdlType, unionStructHex, structPt, structType);
  _PartialVdlType unionPt = new _PartialVdlType.unionType('aname', <_PartialVdlField>[new _PartialVdlField('A', 5), new _PartialVdlField('B', 9)]);
  vdl.VdlType unionType = (new vdl.VdlPendingType()
    ..name = 'aname'
    ..kind = vdl.VdlKind.Union
    ..fields = [
      new vdl.VdlPendingField('A', vdl.VdlTypes.Uint32),
      new vdl.VdlPendingField('B', vdl.VdlTypes.Int64)
    ]).build();
  testCases['union'] = new TypeDefTestCase(_WireUnion.vdlType, unionStructHex, unionPt, unionType);

  String optionalHex =
    '01' //                   Index                              1 [main.wireOptional.Elem]
    '05' //                   PrimValue                         5 [uint]
    'e1'; //                   Control                          End [main.wireOptional END]
  _PartialVdlType optionalPt = new _PartialVdlType.optionalType(null, 5);
  vdl.VdlType optionalType = (new vdl.VdlPendingType()
    ..kind = vdl.VdlKind.Optional
    ..elem = vdl.VdlTypes.Uint32).build();
  testCases['optional'] = new TypeDefTestCase(_WireOptional.vdlType, optionalHex, optionalPt, optionalType);

  String directRecursionHex =
    '00' //                   Index                              0 [main.wireList.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireList.Elem]
    '29' //                   PrimValue                         FIRST_NEW_VOM_ID [uint]
    'e1'; //                   Control                          End [main.wireList END]
  assert(FIRST_NEW_VOM_ID == 41); // Otherwise the hex encoded elem shouldn't be 29.
  _PartialVdlType directRecursePt = new _PartialVdlType.listType('aname', FIRST_NEW_VOM_ID);
  var directRecursePending = new vdl.VdlPendingType()
    ..name = 'aname'
    ..kind = vdl.VdlKind.List;
  directRecursePending.elem = directRecursePending;
  vdl.VdlType directRecurseType = directRecursePending.build();
  testCases['direct recursion'] = new TypeDefTestCase(_WireList.vdlType, directRecursionHex, directRecursePt, directRecurseType);

  return testCases;
}

Map<String, TypeDefTestCase> createInvalidTestCases() {
  var testCases = new Map<String, TypeDefTestCase>();

 String invalidIndexHex =
    '00' //                   Index                              0 [main.wireNamed.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '04' //                  Bad Index!
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireNamed END]
  testCases['invalid index'] = new TypeDefTestCase.failure(_WireNamed.vdlType, invalidIndexHex, VomDecodeException);

 String validHex =
    '00' //                   Index                              0 [main.wireNamed.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireNamed.Base]
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireNamed END]
  testCases['unrecognized type'] = new TypeDefTestCase.failure(vdl.VdlTypes.Int32, validHex, UnrecognizedTypeMessageException);

  String invalidControlHex =
    '00' //                   Index                              0 [main.wireNamed.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '04' //                   Index                              1 [main.wireNamed.Base]
    '58' //                   PrimValue                         88 [uint]
    'e7'; //                  Invalid Control Byte!
  testCases['invalid control byte'] = new TypeDefTestCase.failure(_WireNamed.vdlType, invalidControlHex, VomDecodeException);

  String earlyEofHex =
    '00' //                   Index                              0 [main.wireNamed.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '04'; //                   Index                              1 [main.wireNamed.Base]
    // Early end!
  testCases['early eof'] = new TypeDefTestCase.failure(_WireNamed.vdlType, earlyEofHex, VomDecodeException);

  return testCases;
}
