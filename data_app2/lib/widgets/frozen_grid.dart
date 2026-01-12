import 'package:flutter/material.dart';

/// Vibe-coded excel-style grid. Almost works
class FrozenGrid extends StatefulWidget {
  final int rows;
  final int cols;

  const FrozenGrid({super.key, required this.rows, required this.cols});

  @override
  State<FrozenGrid> createState() => _FrozenGridState();
}

class _FrozenGridState extends State<FrozenGrid> {
  static const double cellHeight = 30;
  static const double cellWidth = 100;

  late final ScrollController hHeader;
  late final ScrollController hBody;

  late final ScrollController vFrozen;
  late final ScrollController vBody;
  @override
  void initState() {
    super.initState();

    hHeader = ScrollController();
    hBody = ScrollController();
    vFrozen = ScrollController();
    vBody = ScrollController();

    hHeader.addListener(() {
      if (hBody.hasClients && hBody.offset != hHeader.offset) {
        hBody.jumpTo(hHeader.offset);
      }
    });

    hBody.addListener(() {
      if (hHeader.hasClients && hHeader.offset != hBody.offset) {
        hHeader.jumpTo(hBody.offset);
      }
    });

    vFrozen.addListener(() {
      if (vBody.hasClients && vBody.offset != vFrozen.offset) {
        vBody.jumpTo(vFrozen.offset);
      }
    });

    vBody.addListener(() {
      if (vFrozen.hasClients && vFrozen.offset != vBody.offset) {
        vFrozen.jumpTo(vBody.offset);
      }
    });
  }

  @override
  void dispose() {
    hHeader.dispose();
    hBody.dispose();
    vFrozen.dispose();
    vBody.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── HEADER ROW ───────────────────────────────
        Row(
          children: [
            _cornerCell(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: hHeader,
                child: Row(
                  children: List.generate(widget.cols - 1, (c) {
                    return _cell(0, c + 1, header: true);
                  }),
                ),
              ),
            ),
          ],
        ),

        // ─── BODY ─────────────────────────────────────
        Expanded(
          child: Row(
            children: [
              // Frozen first column
              SizedBox(
                width: cellWidth,
                child: ListView.builder(
                  controller: vFrozen,
                  itemCount: widget.rows - 1,
                  itemBuilder: (context, r) {
                    return _cell(r + 1, 0, header: true);
                  },
                ),
              ),

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: hBody,
                  child: SizedBox(
                    width: (widget.cols - 1) * cellWidth,
                    child: ListView.builder(
                      controller: vBody,
                      itemCount: widget.rows - 1,
                      itemBuilder: (context, r) {
                        return Row(
                          children: List.generate(widget.cols - 1, (c) {
                            return _cell(r + 1, c + 1);
                          }),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cornerCell() {
    return Container(
      width: cellWidth,
      height: cellHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 70, 41, 41),
        border: Border.all(color: const Color.fromARGB(255, 69, 30, 30)),
      ),
      child: const Text(''),
    );
  }

  Widget _cell(int r, int c, {bool header = false}) {
    return Container(
      width: cellWidth,
      height: cellHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: header
            ? const Color.fromARGB(255, 42, 36, 36)
            : const Color.fromARGB(255, 141, 98, 98),
        border: Border.all(color: Colors.grey),
      ),
      child: Text('R$r C$c'),
    );
  }
}
