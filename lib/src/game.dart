import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'grid.dart';

enum PlayerSign {
  x,
  o,
}

class Game extends ChangeNotifier {
  Game({
    required int size,
    required this.players,
  })  : assert(size > 0),
        assert(players.isNotEmpty),
        assert(
          players.map((player) => player.sign).toSet().length == players.length,
          'every Player must have a unique PlayerSign',
        ),
        _grid = Grid(columnCount: size, rowCount: size),
        _currentPlayer = players.first;

  late final Grid<Player> grid = Grid.unmodifiableView(_grid);
  final Grid<Player> _grid;

  final List<Player> players;

  bool get isFinished => _isFinished;
  bool _isFinished = false;

  Player get currentPlayer => _currentPlayer;
  Player _currentPlayer;

  bool? get isDraw => _isDraw;
  bool? _isDraw;

  Player? get winner => _winner;
  Player? _winner;

  bool get isRunning => _isRunning;
  var _isRunning = false;

  var _stoppedRunning = Completer<void>();

  Future<void> start() async {
    if (_isFinished) {
      throw StateError('Game is already finished.');
    }

    if (_isRunning) {
      throw StateError('Game is already running.');
    }
    _isRunning = true;
    _stoppedRunning = Completer();

    while (!_isFinished && _isRunning) {
      _grid[await _currentPlayer.chooseCell(grid)] = _currentPlayer;
      _winner = _findWinner();
      _isFinished = _winner != null || grid.isFull;
      // ignore: invariant_booleans
      if (_isFinished) {
        _isDraw = _winner == null;
        notifyListeners();
        break;
      } else {
        _currentPlayer =
            players.firstWhere((player) => player != _currentPlayer);
      }
      notifyListeners();
    }

    _stoppedRunning.complete();
  }

  Future<void> stop() async {
    if (!_isRunning) {
      throw StateError('Game is not running.');
    }
    _isRunning = false;

    await _stoppedRunning.future;
  }

  Player? _findWinner() =>
      grid.allLinesValues.map(_findWinnerInLine).whereNotNull().firstOrNull;

  Player? _findWinnerInLine(Iterable<Player?> line) {
    Player? winner;

    for (final player in line) {
      if (player == null) {
        return null;
      }

      winner ??= player;

      if (winner.sign != player.sign) {
        return null;
      }
    }

    return winner;
  }
}

typedef CellEntry = MapEntry<GridAddress, Player?>;
typedef Line = Iterable<CellEntry>;
typedef LinePredicate = bool Function(Line line);

/// Returns wether [cell] is occupied.
bool cellIsUnoccupied(CellEntry cell) => cell.value == null;

/// Returns the number of occupied cells in [line].
int lineOccupationRank(Line line) => line.where(cellIsUnoccupied).length;

/// Returns a [LinePredicate] which returns whether a [Line] can be completed
/// in one or more moves by [player].
LinePredicate lineIsWinnableBy(Player player) => (line) {
      var hasUnoccupiedCell = false;

      for (final entry in line) {
        final otherPlayer = entry.value;

        if (otherPlayer == null) {
          hasUnoccupiedCell = true;
        }

        if (otherPlayer != player) {
          return false;
        }
      }

      return hasUnoccupiedCell;
    };

/// Returns a [LinePredicate] which returns whether a [Line] can be completed in
/// one move by a [Player] other than [player].
LinePredicate lineIsCompletableByOther(Player player) => (line) {
      Player? winner;
      var hasUnoccupiedCell = false;

      for (final cell in line) {
        final currentPlayer = cell.value;

        // Check that at most one cell is unoccupied.
        if (currentPlayer == null) {
          if (hasUnoccupiedCell) {
            return false;
          }
          hasUnoccupiedCell = true;
          continue;
        }

        if (winner == null) {
          winner = currentPlayer;

          // Check that winner is a player other than excludedPlayer.
          if (winner == player) {
            return false;
          }
        }

        // Check that only winner occupies this line.
        if (winner != currentPlayer) {
          return false;
        }
      }

      return hasUnoccupiedCell;
    };

abstract class Player {
  PlayerSign get sign;

  Future<GridAddress> chooseCell(Grid<Player> grid);
}

typedef _BotRule = GridAddress? Function(Player bot, Grid<Player> grid);

class Bot extends Player {
  Bot({required this.sign});

  static final _random = Random();

  @override
  final PlayerSign sign;

  @override
  Future<GridAddress> chooseCell(Grid<Player> grid) async {
    GridAddress? address;

    for (final rule in _rules) {
      address = rule(this, grid);
      if (address != null) {
        break;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));

    return address!;
  }

  static final _rules = <_BotRule>[
    _preventOtherPlayerFromWinning,
    _extendWinnableLine,
    _randomlyChooseCell,
  ];

  static GridAddress? _preventOtherPlayerFromWinning(
    Player bot,
    Grid<Player> grid,
  ) =>
      grid.allLinesEntries
          .firstWhereOrNull(lineIsCompletableByOther(bot))
          ?.firstWhere(cellIsUnoccupied)
          .key;

  static GridAddress? _extendWinnableLine(Player bot, Grid<Player> grid) {
    final winnableLines =
        grid.allLinesEntries.where(lineIsWinnableBy(bot)).toList()
          // Sort so that line with the most occupied cells is first.
          ..sortBy<num>(lineOccupationRank);

    final bestLine = winnableLines.firstOrNull;

    if (bestLine != null) {
      final unoccupiedCells = bestLine.where(cellIsUnoccupied).toList();
      return unoccupiedCells[_random.nextInt(unoccupiedCells.length)].key;
    }

    return null;
  }

  static GridAddress? _randomlyChooseCell(Player bot, Grid<Player> grid) {
    final emptyAddresses = grid.emptyAddresses.toList();
    return emptyAddresses[_random.nextInt(emptyAddresses.length)];
  }
}
