import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glopos/glopos.dart';
import 'package:provider/provider.dart';

import 'game.dart';
import 'theme.dart';

class TicTacToeApp extends StatefulWidget {
  const TicTacToeApp({Key? key}) : super(key: key);

  @override
  _TicTacToeAppState createState() => _TicTacToeAppState();
}

class _TicTacToeAppState extends State<TicTacToeApp> {
  late final _GameElement _gameElement;

  final _magnifierPosition = ValueNotifier(Offset.zero);

  @override
  void initState() {
    super.initState();

    _gameElement = _GameElement(
      createGame: _createGame,
    );
  }

  Game _createGame() => Game(
        size: 3,
        players: [
          Bot(sign: PlayerSign.o),
          Bot(sign: PlayerSign.x),
        ],
      );

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme(context),
        darkTheme: darkTheme(context),
        home: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              _gameElement.size = constraints.biggest;

              return MouseRegion(
                onHover: (event) =>
                    _magnifierPosition.value = event.localPosition,
                child: Scene(
                  elements: [_gameElement],
                  layout: LayoutSceneElement(element: _gameElement),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Window(
                        delegate: _GameViewWindowDelegate(
                          gridLineColor: Colors.indigo.shade400,
                          cellColor: Colors.red.shade400,
                          cellIconColor: Colors.grey.shade100,
                          emptyCellColor: Colors.transparent,
                        ),
                      ),
                      _AnimatedAlignedPositioned(
                        position: _magnifierPosition,
                        alignment: Alignment.center,
                        size: const Size.square(100),
                        child: const _Magnifier(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _GameElement extends LayedOutSceneElement {
  _GameElement({required this.createGame})
      : _game = createGame(),
        super(size: Size.zero);

  final Game Function() createGame;

  Game get game => _game;
  Game _game;

  bool _isResettingGame = false;

  void startGame() {
    assert(!game.isRunning);
    game.start();
  }

  void resetGame() {
    if (_isResettingGame) {
      return;
    }
    _isResettingGame = true;

    if (game.isRunning) {
      game.stop().then((_) {
        _initGame();
        _isResettingGame = false;
      });
    } else {
      _initGame();
    }
  }

  void _initGame() {
    _game = createGame();
    notifyListeners();
  }
}

class _GameViewWindowDelegate extends WindowDelegate<_GameElement> {
  _GameViewWindowDelegate({
    this.background,
    required this.gridLineColor,
    required this.cellColor,
    required this.cellIconColor,
    required this.emptyCellColor,
  });

  final Color? background;

  final Color gridLineColor;

  final Color cellColor;

  final Color cellIconColor;

  final Color emptyCellColor;

  @override
  Widget build(BuildContext context, _GameElement element) =>
      ChangeNotifierProvider.value(
        value: element.game,
        child: _GameView(
          background: background,
          gridSpacing: 6,
          gridLineColor: gridLineColor,
          cellColor: cellColor,
          cellIconColor: cellIconColor,
          emptyCellColor: emptyCellColor,
          startGame: element.startGame,
          resetGame: element.resetGame,
        ),
      );
}

class _Magnifier extends StatelessWidget {
  const _Magnifier({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ClipOval(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Window(
          clipBehavior: Clip.none,
          delegate: _GameViewWindowDelegate(
            background: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.shade200
                : Colors.grey.shade800,
            gridLineColor: Theme.of(context).colorScheme.background,
            cellColor: Colors.amber.shade500,
            cellIconColor: Colors.grey.shade800,
            emptyCellColor: Colors.amber.shade500,
          ),
        ),
      );
}

class _AnimatedAlignedPositioned extends StatelessWidget {
  const _AnimatedAlignedPositioned({
    Key? key,
    required this.position,
    required this.alignment,
    required this.size,
    required this.child,
  }) : super(key: key);

  final ValueListenable<Offset> position;
  final Alignment alignment;
  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Offset>(
        valueListenable: position,
        builder: (context, position, _) => Positioned.fromRect(
          rect: (position & size).shift(-alignment.alongSize(size)),
          child: child,
        ),
      );
}

class _GameView extends StatefulWidget {
  const _GameView({
    Key? key,
    this.background,
    required this.gridSpacing,
    required this.gridLineColor,
    required this.cellColor,
    required this.cellIconColor,
    required this.emptyCellColor,
    required this.startGame,
    required this.resetGame,
  }) : super(key: key);

  final Color? background;

  final double gridSpacing;

  final Color gridLineColor;

  final Color cellColor;

  final Color cellIconColor;

  final Color emptyCellColor;

  final VoidCallback startGame;

  final VoidCallback resetGame;

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  @override
  Widget build(BuildContext context) => Container(
        color: widget.background,
        child: Column(
          children: [
            _buildControls(),
            Expanded(
              child: Center(
                child: SizedBox.fromSize(
                  size: const Size.square(260),
                  child: _buildBoard(),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildControls() => Consumer<Game>(
        builder: (context, game, _) => ButtonBar(
          alignment: MainAxisAlignment.center,
          children: [
            if (game.isRunning || game.isFinished)
              OutlinedButton(
                onPressed: widget.resetGame,
                child: const Text('Reset'),
              )
            else
              OutlinedButton(
                onPressed: widget.startGame,
                child: const Text('Start'),
              ),
          ],
        ),
      );

  Widget _buildBoard() => Consumer<Game>(
        builder: (context, game, _) => Stack(
          children: [
            _GridLines(
              lineWidth: widget.gridSpacing,
              columns: game.grid.columnCount,
              rows: game.grid.rowCount,
              color: widget.gridLineColor,
            ),
            GridView.count(
              crossAxisCount: game.grid.columnCount,
              crossAxisSpacing: widget.gridSpacing,
              mainAxisSpacing: widget.gridSpacing,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final player in game.grid.values)
                  Center(
                    child: _GridCell(
                      sign: player?.sign,
                      color: player == null
                          ? widget.emptyCellColor
                          : widget.cellColor,
                      iconColor: widget.cellIconColor,
                    ),
                  )
              ],
            ),
          ],
        ),
      );
}

class _GridLines extends StatelessWidget {
  const _GridLines({
    Key? key,
    required this.lineWidth,
    required this.columns,
    required this.rows,
    required this.color,
  }) : super(key: key);

  final double lineWidth;

  final int columns;

  final int rows;

  final Color color;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              const Spacer(),
              for (var i = 0; i < columns - 1; i++) ...[
                _gridLine(Axis.vertical),
                const Spacer(),
              ]
            ],
          ),
          Column(
            children: [
              const Spacer(),
              for (var i = 0; i < rows - 1; i++) ...[
                _gridLine(Axis.horizontal),
                const Spacer(),
              ]
            ],
          ),
        ],
      );

  Widget _gridLine(Axis axis) => Container(
        width: axis == Axis.vertical ? lineWidth : null,
        height: axis == Axis.horizontal ? lineWidth : null,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(lineWidth / 2),
        ),
      );
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    Key? key,
    this.sign,
    required this.color,
    required this.iconColor,
  }) : super(key: key);

  final PlayerSign? sign;

  final Color color;

  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        padding: const EdgeInsets.all(10),
        child: sign == null
            ? null
            : _PlayerIcon(
                sign: sign!,
                color: iconColor,
              ),
      );
}

class _PlayerIcon extends StatelessWidget {
  const _PlayerIcon({
    Key? key,
    required this.sign,
    required this.color,
    this.lineWidth = 6,
  }) : super(key: key);

  final PlayerSign sign;

  final Color color;

  final double lineWidth;

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (sign) {
      case PlayerSign.o:
        child = Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: lineWidth,
            ),
          ),
        );
        break;
      case PlayerSign.x:
        child = Stack(
          children: [
            Center(child: Transform.rotate(angle: -pi / 4, child: _line())),
            Center(child: Transform.rotate(angle: pi / 4, child: _line())),
          ],
        );
        break;
    }

    return child;
  }

  Widget _line() => Container(
        width: lineWidth,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(lineWidth / 2),
        ),
      );
}
