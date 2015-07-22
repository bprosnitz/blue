part of vom;

// Test cases for type definition decoding.
class TypeDefTestCase{
  final VomTypeMessage msg;

  final _PartialVdlType expectedOutput;
  final Type expectedException;

  TypeDefTestCase(vdl.VdlType defType, String inputHex, this.expectedOutput) :
    expectedException = null,
    msg = new VomTypeMessage(defType, test_util.hex2Bin(inputHex));
  TypeDefTestCase.failure(vdl.VdlType defType, String inputHex, this.expectedException) :
    expectedOutput = null,
    msg = new VomTypeMessage(defType, test_util.hex2Bin(inputHex));
}

Map<String, TypeDefTestCase> createValidTestCases() {
  var testCases = new Map<String, TypeDefTestCase>();

  String wireNamedHex =
    '00' //                   Index                              0 [main.wireNamed.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireNamed.Base]
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireNamed END]
  _PartialVdlType wireNamedPt = new _PartialVdlType.namedType('aname', 88);
  testCases['named'] = new TypeDefTestCase(_WireNamed.vdlType, wireNamedHex, wireNamedPt);

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
    testCases['enum'] = new TypeDefTestCase(_WireEnum.vdlType, enumHex, enumPt);

  String arrayHex =
    '00' //                   Index                              0 [main.wireArray.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireArray.Elem]
    '58' //                   PrimValue                         88 [uint]
    '02' //                   Index                              2 [main.wireArray.Len]
    '0b' //                   PrimValue                         11 [uint]
    'e1'; //                   Control                          End [main.wireArray END]
  _PartialVdlType arrayPt = new _PartialVdlType.arrayType('aname', 88, 11);
  testCases['array'] = new TypeDefTestCase(_WireArray.vdlType, arrayHex, arrayPt);

  String listHex =
    '00' //                   Index                              0 [main.wireList.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireList.Elem]
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireList END]
  _PartialVdlType listPt = new _PartialVdlType.listType('aname', 88);
  testCases['list'] = new TypeDefTestCase(_WireList.vdlType, listHex, listPt);

  String setHex =
    '00' //                   Index                              0 [main.wireSet.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireSet.Key]
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireSet END]
  _PartialVdlType setPt = new _PartialVdlType.setType('aname', 88);
  testCases['set'] = new TypeDefTestCase(_WireSet.vdlType, setHex, setPt);

  String mapHex =
    '00' //                   Index                              0 [main.wireMap.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireMap.Key]
    '58' //                   PrimValue                         88 [uint]
    '02' //                   Index                              2 [main.wireMap.Elem]
    '63' //                   PrimValue                         99 [uint]
    'e1'; //                   Control                          End [main.wireMap END]
  _PartialVdlType mapPt = new _PartialVdlType.mapType('aname', 88, 99);
  testCases['map'] = new TypeDefTestCase(_WireMap.vdlType, mapHex, mapPt);

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
    '58' //                   PrimValue                         88 [uint]
    'e1' //                   Control                          End [main.wireField END]
    '00' //                   Index                              0 [main.wireField.Name]
    '01' //                   ByteLen                            1 [string len]
    '42' //                   PrimValue                        'B' [string]
    '01' //                   Index                              1 [main.wireField.Type]
    '63' //                   PrimValue                         99 [uint]
    'e1' //                   Control                          End [main.wireField END]
    'e1'; //                   Control                          End [main.wireStruct END]
  _PartialVdlType structPt = new _PartialVdlType.structType('aname', <_PartialVdlField>[new _PartialVdlField('A', 88), new _PartialVdlField('B', 99)]);
  testCases['struct'] = new TypeDefTestCase(_WireStruct.vdlType, unionStructHex, structPt);
  _PartialVdlType unionPt = new _PartialVdlType.unionType('aname', <_PartialVdlField>[new _PartialVdlField('A', 88), new _PartialVdlField('B', 99)]);
  testCases['union'] = new TypeDefTestCase(_WireUnion.vdlType, unionStructHex, unionPt);

  String optionalHex =
    '00' //                   Index                              0 [main.wireOptional.Name]
    '05' //                   ByteLen                            5 [string len]
    '616e616d65' //           PrimValue                    'aname' [string]
    '01' //                   Index                              1 [main.wireOptional.Elem]
    '58' //                   PrimValue                         88 [uint]
    'e1'; //                   Control                          End [main.wireOptional END]
  _PartialVdlType optionalPt = new _PartialVdlType.optionalType('aname', 88);
  testCases['optional'] = new TypeDefTestCase(_WireOptional.vdlType, optionalHex, optionalPt);

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

