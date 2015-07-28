part of vdl;

class VdlTypes {
  static final VdlType Any = _createPrimitiveType(VdlKind.Any);
  static final VdlType Optional = _createPrimitiveType(VdlKind.Optional);
  static final VdlType Bool = _createPrimitiveType(VdlKind.Bool);
  static final VdlType Byte = _createPrimitiveType(VdlKind.Byte);
  static final VdlType Uint16 = _createPrimitiveType(VdlKind.Uint16);
  static final VdlType Uint32 = _createPrimitiveType(VdlKind.Uint32);
  static final VdlType Uint64 = _createPrimitiveType(VdlKind.Uint64);
  static final VdlType Int16 = _createPrimitiveType(VdlKind.Int16);
  static final VdlType Int32 = _createPrimitiveType(VdlKind.Int32);
  static final VdlType Int64 = _createPrimitiveType(VdlKind.Int64);
  static final VdlType Float32 = _createPrimitiveType(VdlKind.Float32);
  static final VdlType Float64 = _createPrimitiveType(VdlKind.Float64);
  static final VdlType Complex64 = _createPrimitiveType(VdlKind.Complex64);
  static final VdlType Complex128 = _createPrimitiveType(VdlKind.Complex128);
  static final VdlType String = _createPrimitiveType(VdlKind.String);
  static final VdlType TypeObject = _createPrimitiveType(VdlKind.TypeObject);

  static VdlType _createPrimitiveType(VdlKind kind) =>
    (new VdlPendingType()..kind = kind).build();
}