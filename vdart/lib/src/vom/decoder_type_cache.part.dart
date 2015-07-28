part of vom;

// The decoder type cache reads a stream of vom type messages and creates
// a cache of the decoded types, built from the vom message bytes.
class _DecoderTypeCache {
  // Map from type id (read off the type stream) to types.
  final Map<int, vdl.VdlType> _typeDefinitions = new Map<int, vdl.VdlType>();

  // Type definitions where the types have not yet been fully built.
  // (Waiting to receive unknown type id definitions)
  final Map<int, _PartialVdlType> _partialDefinitions = new Map<int, _PartialVdlType>();

  // Lookup requests wait on incoming type definitions through the waiters map.
  // The map (from type id to completer) enables returning a response when
  // the incoming definition is ultimately received.
  final Map<int, Completer<vdl.VdlType>> _waiters = new Map<int, Completer<vdl.VdlType>>();

  // Future that resolves if all messages on the stream have been read.
  Future get finishedReading => _finishedReading;
  Future _finishedReading;

  _DecoderTypeCache(Stream<VomTypeMessage> typeStream) {
    _finishedReading = typeStream.forEach(_handleTypeMessage);
  }

  vdl.VdlType _lookupBuiltin(int typeId) {
    switch(typeId) {
      case 1: // bool
        return vdl.VdlTypes.Bool;
      case 2: // byte
        return vdl.VdlTypes.Byte;
      case 3: // string
        return vdl.VdlTypes.String;
      case 4: // uint16
        return vdl.VdlTypes.Uint16;
      case 5: // uint32
        return vdl.VdlTypes.Uint32;
      case 6: // uint64
        return vdl.VdlTypes.Uint64;
      case 7: // int16
        return vdl.VdlTypes.Int16;
      case 8: // int32
        return vdl.VdlTypes.Int32;
      case 9: // int64
        return vdl.VdlTypes.Int64;
      case 10: // float32
        return vdl.VdlTypes.Float32;
      case 11: // float64
        return vdl.VdlTypes.Float64;
      case 12: // complex64
        return vdl.VdlTypes.Complex64;
      case 13: // complex128
        return vdl.VdlTypes.Complex128;
      case 14: // type object
        return vdl.VdlTypes.TypeObject;
      case 15: // any
        return vdl.VdlTypes.Any;
      case 39: // byte list
        return (new vdl.VdlPendingType()
        ..kind = vdl.VdlKind.List
        ..elem = vdl.VdlTypes.Byte).build();
      case 40: // string list
        return (new vdl.VdlPendingType()
        ..kind = vdl.VdlKind.List
        ..elem = vdl.VdlTypes.String).build();
      default:
        return null;
    }
  }

  vdl.VdlType _lookup(int typeId) {
    var builtIn = _lookupBuiltin(typeId);
    if (builtIn != null) {
      return builtIn;
    }
    return _typeDefinitions[typeId];
  }

  Future<vdl.VdlType> operator[](int typeId) async {
    vdl.VdlType type = _lookup(typeId);
    if (type != null) {
      return type;
    }

    // Type is not immediately available. Get a future that will resolve when
    // the type becomes available. Signaled from _signalWaiters().
    if (!_waiters.containsKey(typeId)) {
      _waiters[typeId] = new Completer<vdl.VdlType>();
    }
    return  _waiters[typeId].future;
  }

  // Signal that a type has been received and resolve any pending futures
  // that were waiting for the type.
  void _signalWaiters(int typeId) {
    Completer<vdl.VdlType> completer = _waiters.remove(typeId);
    if (completer == null) {
      return;
    }
    assert(_lookup(typeId) != null);
    completer.complete(_lookup(typeId));
  }

  // Handle incoming type message by building the VdlType or
  // storing it in _partialDefinitions if it is not yet ready.
  void _handleTypeMessage(VomTypeMessage msg) {
    _defineNewPartialType(msg);
    _buildAnyBuildableTypes();
  }

  // Define a new partial type based on the message and put it in
  // the partial definitions list.
  void _defineNewPartialType(VomTypeMessage msg) {
    _PartialVdlType partial = _TypeDefinitionDecoder.decodeType(
      msg.wireDefType, msg.wireDefBytes);
    int typeId = msg.newTypeId;
    if (_typeDefinitions.containsKey(typeId) ||
      _partialDefinitions.containsKey(typeId)) {
      throw new VomDecodeException('Multiple type defintions with id ${typeId} on vom string. '
        'Only a single definition permitted per id.');
    }
    _partialDefinitions[typeId] = partial;
  }

  Map<int, _PartialVdlType> _readyToBeBuilt() {
    var dependents = new quiver_collection.SetMultimap<int, int>();
    _partialDefinitions.forEach((int typeId, _PartialVdlType partial) {
      if (partial.keyId != null) {
        dependents.add(partial.keyId, typeId);
      }
      if (partial.elemId != null) {
        dependents.add(partial.elemId, typeId);
      }
      if (partial.fields != null) {
        for (var field in partial.fields) {
          dependents.add(field.typeId, typeId);
        }
      }
    });

    Map<int, _PartialVdlType> maybeReady  =
      new Map<int, _PartialVdlType>.from(_partialDefinitions);


    // Iteratively remove types where dependencies have not been received.
    List<int> toRemove = null;
    Set<int> toProcess = new Set.from(_partialDefinitions.keys);
    void _flagToRemoveIfDependencyMissing(int typeId, int dependId) {
      if (dependId == null) {
        // field not relevant (e.g. elemId field in set)
        return;
      }
      if (_lookup(dependId) != null) {
        // dependency is defined
        return;
      }
      if (!maybeReady.containsKey(dependId)) {
        // dependency is missing from the set of partial types
        assert(typeId != null);
        toRemove.add(typeId);
      }
    }
    while(toRemove == null || toRemove.length > 0) {
      toRemove = new List<int>();
      toProcess.forEach((int newTypeId) {
        var partial = maybeReady[newTypeId];
        _flagToRemoveIfDependencyMissing(newTypeId, partial.elemId);
        _flagToRemoveIfDependencyMissing(newTypeId, partial.keyId);
        if (partial.fields != null) {
          for (var field in partial.fields) {
            _flagToRemoveIfDependencyMissing(newTypeId, field.typeId);
          }
        }
      });
      toProcess = new Set<int>();
      toRemove.forEach((int idToRemove) {
        toProcess.addAll(dependents[idToRemove]);
        maybeReady.remove(idToRemove);
      });
    }

    return maybeReady;
  }

  // Go through the partial definitions list and build types if we have
  // complete information for them.
  void _buildAnyBuildableTypes() {
    var ready = _readyToBeBuilt();
    ready.forEach((int newTypeId, _PartialVdlType partial) {
      if (_lookup(newTypeId) == null) {
        // Not already built (as an example, it could be built if this type was an element
        // of another type).
        _buildType(newTypeId, partial, ready);
      }
    });
  }

  // Builds a partial type into a VdlType
  void _buildType(int newTypeId, _PartialVdlType partial, Map<int, _PartialVdlType> readyToBeBuilt) {
    Map<int, vdl.VdlPendingType> newPendingTypes =
      _preallocateNewTypes(newTypeId, partial, readyToBeBuilt);

    vdl.TypeBase _lookupBuiltType(int typeId) {
      var t = _lookup(typeId);
      if (t != null) {
        return t;
      }
      t = newPendingTypes[typeId];
      assert(t != null);
      return t;
    }

    // Set fields on the pending types.
    newPendingTypes.forEach((newTypeId, pending) {
      var partial = readyToBeBuilt[newTypeId];

      if (partial.baseId != null) {
        assert(partial.labels == null);
        assert(partial.elemId == null);
        assert(partial.keyId == null);
        assert(partial.len == null);
        assert(partial.fields == null);

        pending.kind = _lookupBuiltType(partial.baseId).kind;
        pending.name = partial.name;
        return;
      }

      pending.kind = partial.kind;
      pending.name = partial.name;
      pending.labels = partial.labels;
      pending.len = partial.len;
      if (partial.elemId != null) {
        pending.elem = _lookupBuiltType(partial.elemId);
      }
      if (partial.keyId != null) {
        pending.key = _lookupBuiltType(partial.keyId);
      }
      if (partial.fields != null) {
        pending.fields = new List<vdl.VdlPendingField>();
        for (var parField in partial.fields) {
          var pendField = new vdl.VdlPendingField(parField.name,
            _lookupBuiltType(parField.typeId));
          pending.fields.add(pendField);
        }
      }
    });

    // Now build all of the types!
    newPendingTypes.forEach((newTypeId, pending) {
      _typeDefinitions[newTypeId] = pending.build();
    });

    // Signal cache accesses waiting for the type.
    newPendingTypes.forEach((newTypeId, pending) {
      _signalWaiters(newTypeId);
    });
  }

  // Allocate empty VdlPendingTypes for all children of the provided partial
  // type. This is allows us to recurse and reference types that have not been
  // created immediately.
  Map<int, vdl.VdlPendingType> _preallocateNewTypes(int newTypeId, _PartialVdlType partial, Map<int, _PartialVdlType> readyToBeBuilt) {
    var newPendingTypes = new Map<int, vdl.VdlPendingType>();

    var processQueue = new Queue<collection.Pair<int, _PartialVdlType>>();
    processQueue.addLast(new collection.Pair<int, _PartialVdlType>(newTypeId, partial));

    void _addIfNew(int typeId) {
      if (typeId == null || _lookup(typeId) != null) {
        return;
      }
      if (!newPendingTypes.containsKey(typeId)) {
        _PartialVdlType partial = readyToBeBuilt[typeId];
        assert(partial != null);
        processQueue.add(new collection.Pair<int, _PartialVdlType>(typeId, partial));
      }
    }

    while (processQueue.isNotEmpty) {
      var pair = processQueue.removeFirst();
      int typeId = pair.key;
      _PartialVdlType partial = pair.value;
      newPendingTypes[typeId] = new vdl.VdlPendingType();

      _addIfNew(partial.elemId);
      _addIfNew(partial.keyId);
      if (partial.fields != null) {
        for (var field in partial.fields) {
          _addIfNew(field.typeId);
        }
      }
    }

    return newPendingTypes;
  }
}
