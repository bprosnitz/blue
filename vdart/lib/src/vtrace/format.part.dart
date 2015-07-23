part of vtrace;

class Node implements Comparable<Node> {
  SpanRecord span;
  final List<Node> children;

  Node._internal() : children = new List<Node>() {
  }

  factory Node(TraceRecord record) {
    Node root = null;
    DateTime earliestTime = null;
    Map<UniqueId, Node> nodes = new Map<UniqueId, Node>();

    record.spans.forEach((span) {
      if (earliestTime == null || span.start.isBefore(earliestTime)) {
        earliestTime = span.start;
      }
      Node n = nodes[span.id];
      if (n == null) {
        n = new Node._internal();
        nodes[span.id] = n;
      }
      n.span = span;
      if (span.parent == record.id) {
        root = n;
      } else {
        Node p = nodes[span.parent];
        if (p == null) {
          // Put a placeholder parent that can be filled in later.
          p = new Node._internal();
          nodes[span.parent] = p;
        }
        p.children.add(n);
      }
    });

    List<Node> missing = new List<Node>();
    // Sort all the children and annotations in a span by time order.
    nodes.forEach((UniqueId id, Node n) {
      n.children.sort();
      if (n.span != null) {
        if (n.span.annotations != null) {
          n.span.annotations.sort((a1, a2) {
            return a1.when.compareTo(a2.when);
          });
        }
      } else {
        // This means that this id was some node's parent but we
        // didn't see the entry.
        n.span = new SpanRecord(null, null, 'Missing Data', null, null, null);
        missing.add(n);
      }
    });

    if (root == null) {
      root = new Node._internal();
      root.span = new SpanRecord(null, null, 'Missing Root Span', earliestTime, null, null);
    }

    root.children.addAll(missing);
    return root;
  }

  int compareTo(Node other) => span.start.compareTo(other.span.start);

  void format(StringBuffer res, String indentation, DateTime traceStart) {
    // The following code is basically the equivalent of:
    // sprintf('%sSpan - %s [id: %x parent: %x] (%s, %s)',
    //         identation, name, id, parent, start - traceStart,
    //         end - traceStart);
    res.write(indentation);
    if (span.name == '') {
      res.writeln('Trace - 0x${hexId(span.parent, 16)} (' +
            '${printTime(span.start)}, ${printTime(span.end)})');
    } else {
      res.writeln('Span - ${span.name} [id: ${hexId(span.id)} ' +
                  'parent ${hexId(span.parent)}] ' +
                  '(${printDuration(span.start, traceStart)}, ' +
                  '${printDuration(span.end, traceStart)})');
    }

    // Now add the annotations.
    String nextIndent = indentation + '    ';
    if (span.annotations != null) {
      span.annotations.forEach((Annotation a) {
        res.writeln('${nextIndent}@${printDuration(a.when, traceStart)} ${a.message}');
      });
    }

    // Now add the child spans.
    children.forEach((Node n) {
      n.format(res, nextIndent, traceStart);
    });
  }
}

String hexId(UniqueId id, [int bytes=4]) {
  if (id == null) {
    return '0' * (bytes * 2);
  }
  return _toHexString(new Uint8List.fromList(id.val.skip(16-bytes).toList()));
}

String printTime(DateTime t) {
  if (t == null) {
    return '??';
  }
  return t.toString();
}

String printDuration(DateTime curr, DateTime from) {
  if (curr == null || from == null) {
    return '??';
  }
  return '${curr.difference(from).inSeconds}s';
}
String _toHexString(Uint8List l) {
  return l.map((e) => e.toRadixString(16).padLeft(2,'0')).join();
}
