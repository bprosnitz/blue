part of vom;

/// Decodes structs that represent type definitions.
class _TypeDefinitionDecoder {
  /// Decode bytes into the corresponding type definition.
  /// wireDefType is the type of the WireType used to define type.
  static _PartialVdlType decodeType(vdl.VdlType wireDefType, List<int> bytes) {
    _ByteBufferReader bufReader = new _ByteBufferReader(bytes);
    _LowLevelVomReader reader = new _LowLevelVomReader(bufReader);

    if (wireDefType == _WireNamed.vdlType) {
      int ni = nextIndex(reader);
      String name;
      int baseId;
      while (ni != null) {
        switch(ni) {
          case 0:
            name = reader.readString();
            break;
          case 1:
            baseId = reader.readUint();
            break;
          default:
            throw new VomDecodeException('unrecognized field index $ni for WireNamed type definition');
        }
        ni = nextIndex(reader);
      }
      return new _PartialVdlType.namedType(name, baseId);
    } else if (wireDefType == _WireEnum.vdlType) {
      int ni = nextIndex(reader);
      String name;
      List<String> labels;
      while (ni != null) {
        switch(ni) {
          case 0:
            name = reader.readString();
            break;
          case 1:
            int len = reader.readUint();
            labels = new List<String>(len);
            for (int i = 0; i < len; i++) {
              labels[i] = reader.readString();
            }
            break;
          default:
            throw new VomDecodeException('unrecognized field index $ni for WireEnum type definition');
        }
        ni = nextIndex(reader);
      }
      return new _PartialVdlType.enumType(name, labels);
    } else if (wireDefType == _WireArray.vdlType) {
      int ni = nextIndex(reader);
      String name;
      int elemId;
      int len;
      while (ni != null) {
        switch(ni) {
          case 0:
            name = reader.readString();
            break;
          case 1:
            elemId = reader.readUint();
            break;
          case 2:
            len = reader.readUint();
            break;
          default:
            throw new VomDecodeException('unrecognized field index $ni for WireArray type definition');
        }
        ni = nextIndex(reader);
      }
      return new _PartialVdlType.arrayType(name, elemId, len);
    } else if (wireDefType == _WireList.vdlType) {
      int ni = nextIndex(reader);
      String name;
      int elemId;
      while (ni != null) {
        switch(ni) {
          case 0:
            name = reader.readString();
            break;
          case 1:
            elemId = reader.readUint();
            break;
          default:
            throw new VomDecodeException('unrecognized field index $ni for WireList type definition');
        }
        ni = nextIndex(reader);
      }
      return new _PartialVdlType.listType(name, elemId);
    } else if (wireDefType == _WireSet.vdlType) {
      int ni = nextIndex(reader);
      String name;
      int keyId;
      while (ni != null) {
        switch(ni) {
          case 0:
            name = reader.readString();
            break;
          case 1:
            keyId = reader.readUint();
            break;
          default:
            throw new VomDecodeException('unrecognized field index $ni for WireSet type definition');
        }
        ni = nextIndex(reader);
      }
      return new _PartialVdlType.setType(name, keyId);
    } else if (wireDefType == _WireMap.vdlType) {
      int ni = nextIndex(reader);
      String name;
      int keyId;
      int elemId;
      while (ni != null) {
        switch(ni) {
          case 0:
            name = reader.readString();
            break;
          case 1:
            keyId = reader.readUint();
            break;
          case 2:
            elemId = reader.readUint();
            break;
          default:
            throw new VomDecodeException('unrecognized field index $ni for WireMap type definition');
        }
        ni = nextIndex(reader);
      }
      return new _PartialVdlType.mapType(name, keyId, elemId);
    } else if (wireDefType == _WireStruct.vdlType || wireDefType == _WireUnion.vdlType) {
      int ni = nextIndex(reader);
      String name;
      List<_PartialVdlField> fields;
      while (ni != null) {
        switch(ni) {
          case 0:
            name = reader.readString();
            break;
          case 1:
            int len = reader.readUint();
            fields = new List<_PartialVdlField>(len);
            for (int i = 0; i < len; i++) {
              String name;
              int typeId;
              int si = nextIndex(reader);
              while (si != null) {
                switch (si) {
                  case 0:
                    name = reader.readString();
                    break;
                  case 1:
                    typeId = reader.readUint();
                    break;
                  default:
                    throw new VomDecodeException('unrecognized field index $si in field definition in WireStruct');
                }
                fields[i] = new _PartialVdlField(name, typeId);
                si = nextIndex(reader);
              }
            }
            break;
          default:
            throw new VomDecodeException('unrecognized field index $ni for WireSet type definition');
        }
        ni = nextIndex(reader);
      }
      if (wireDefType == _WireStruct.vdlType) {
        return new _PartialVdlType.structType(name, fields);
       } else {
        return new _PartialVdlType.unionType(name, fields);
       }
    } else if (wireDefType == _WireOptional.vdlType) {
      int ni = nextIndex(reader);
      String name;
      int elemId;
      while (ni != null) {
        switch(ni) {
          case 0:
            name = reader.readString();
            break;
          case 1:
            elemId = reader.readUint();
            break;
          default:
            throw new VomDecodeException('unrecognized field index $ni for WireOptional type definition');
        }
        ni = nextIndex(reader);
      }
      return new _PartialVdlType.optionalType(name, elemId);
    } else {
      throw new UnrecognizedTypeMessageException(wireDefType);
    }
  }

  static int nextIndex(_LowLevelVomReader reader) {
    if (_isEndOfStructFields(reader)) {
      return null;
    }
    return reader.readUint();
  }



  static bool _isEndOfStructFields(_LowLevelVomReader reader)  {
    int cb = reader.tryReadControlByte();

    if (cb == null) {
      return false;
    }

    switch (cb) {
      case _WireCtrlEnd:
        return true;
      default:
        throw new VomDecodeException('received unexpected control byte ${cb} while decoding type definition');
    }
  }
}

class UnrecognizedTypeMessageException {
  vdl.VdlType _type;
  UnrecognizedTypeMessageException(this._type);
  String toString() => 'received type message of unexpected type ${_type}';
}
