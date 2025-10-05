import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import '../services/user_service.dart';

enum LogicDifficulty { easy, medium, hard }

class LogicPuzzle {
  final String id;
  final LogicDifficulty difficulty;
  final List<String> inputs; // e.g., ['A','B']
  final String description; // human readable description of circuit
  final bool Function(Map<String, bool> values) evaluate; // returns output

  const LogicPuzzle({
    required this.id,
    required this.difficulty,
    required this.inputs,
    required this.description,
    required this.evaluate,
  });
}

class LogicGatesPuzzleScreen extends StatefulWidget {
  final UserProfile profile;

  const LogicGatesPuzzleScreen({super.key, required this.profile});

  @override
  State<LogicGatesPuzzleScreen> createState() => _LogicGatesPuzzleScreenState();
}

class _LogicGatesPuzzleScreenState extends State<LogicGatesPuzzleScreen> with TickerProviderStateMixin {
  late List<LogicPuzzle> _puzzles;
  int _level = 1; // game level index
  int _roundInLevel = 1; // 1..5 questions per level
  int _score = 0;
  // int _streak = 0; // streak-based rewards removed
  bool _showInfo = true;
  bool _isTimed = false;
  int _timeLeft = 30;
  Ticker? _ticker;
  Map<String, bool> _values = {};
  final Random _random = Random();
  late Map<LogicDifficulty, List<LogicPuzzle>> _shuffledByTier;
  final Set<String> _usedPuzzleIds = <String>{};
  LogicPuzzle? _activePuzzle;

  // Small helpers
  bool _xor2(bool a, bool b) => (a && !b) || (!a && b);
  bool _xnor2(bool a, bool b) => (a && b) || (!a && !b);
  int _trueCount(Iterable<bool> list) => list.where((e) => e).length;

  List<LogicPuzzle> _dedupeByDescription(List<LogicPuzzle> list) {
    final Set<String> seen = <String>{};
    final List<LogicPuzzle> result = <LogicPuzzle>[];
    for (final p in list) {
      if (!seen.contains(p.description)) {
        seen.add(p.description);
        result.add(p);
      }
    }
    return result;
  }

  // Kapı tanımları (TR)
  final Map<String, String> _gateDefinitionsTr = const {
    'AND': 'Her iki giriş de açık olursa çıkış açık.',
    'OR': 'Girişlerden en az biri açık olursa çıkış açık.',
    'NOT': 'Giriş terslenir (açık → kapalı, kapalı → açık).',
    'XOR': 'Girişler farklıysa çıkış açık (biri açık biri kapalı).',
    'NAND': "AND'in tersi; iki giriş de açıkken çıkış kapalı, diğer durumlarda açık.",
    'XNOR': "XOR'un tersi; girişler aynıysa çıkış açık.",
    'NOR': "OR'un tersi; en az bir giriş açıkken çıkış kapalı, her ikisi kapalıysa açık.",
  };

  List<String> _getGateDefinitionsFor(String description) {
    final String upper = description.toUpperCase();
    final List<String> order = ['XNOR', 'NAND', 'XOR', 'NOR', 'AND', 'OR', 'NOT'];
    final List<String> results = [];
    for (final gate in order) {
      final regex = RegExp('\\b$gate\\b');
      if (regex.hasMatch(upper)) {
        final def = _gateDefinitionsTr[gate];
        if (def != null) {
          results.add('$gate: $def');
        }
      }
    }
    return results;
  }

  bool _isAdvancedGate(LogicPuzzle p) {
    final d = p.description.toUpperCase();
    return d.contains('XOR') || d.contains('XNOR') || d.contains('NAND');
  }

  @override
  void initState() {
    super.initState();
    _puzzles = _buildPuzzles();
    _prepareSessionOrder();
    _loadPuzzleState();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _prepareSessionOrder() {
    final easy = _dedupeByDescription(_puzzles.where((p) => p.difficulty == LogicDifficulty.easy).toList());
    final medium = _dedupeByDescription(_puzzles.where((p) => p.difficulty == LogicDifficulty.medium).toList());
    final hard = _dedupeByDescription(_puzzles.where((p) => p.difficulty == LogicDifficulty.hard).toList());
    easy.shuffle(_random);
    medium.shuffle(_random);
    hard.shuffle(_random);
    _shuffledByTier = {
      LogicDifficulty.easy: easy,
      LogicDifficulty.medium: medium,
      LogicDifficulty.hard: hard,
    };
  }

  List<LogicPuzzle> _buildPuzzles() {
    return [
      // Easy (2-3 gates conceptually)
      LogicPuzzle(
        id: 'E1',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = A AND B',
        evaluate: (v) => (v['A'] ?? false) && (v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E2',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = A OR B',
        evaluate: (v) => (v['A'] ?? false) || (v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E3',
        difficulty: LogicDifficulty.easy,
        inputs: ['A'],
        description: 'Çıkış = NOT A',
        evaluate: (v) => !(v['A'] ?? false),
      ),
      LogicPuzzle(
        id: 'E4',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = NAND(A, B)',
        evaluate: (v) => !((v['A'] ?? false) && (v['B'] ?? false)),
      ),
      LogicPuzzle(
        id: 'E5',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = NOR(A, B)',
        evaluate: (v) => !((v['A'] ?? false) || (v['B'] ?? false)),
      ),
      LogicPuzzle(
        id: 'E6',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = A XOR B',
        evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E7',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = A XNOR B',
        evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E8',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = A AND (NOT B)',
        evaluate: (v) => (v['A'] ?? false) && !(v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E9',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = (NOT A) AND B',
        evaluate: (v) => !(v['A'] ?? false) && (v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E10',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = A OR (NOT B)',
        evaluate: (v) => (v['A'] ?? false) || !(v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E11',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = (NOT A) OR B',
        evaluate: (v) => !(v['A'] ?? false) || (v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E12',
        difficulty: LogicDifficulty.easy,
        inputs: ['B'],
        description: 'Çıkış = NOT B',
        evaluate: (v) => !(v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E13',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = NOT(A XOR B)',
        evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E14',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = NOT A AND NOT B',
        evaluate: (v) => !(v['A'] ?? false) && !(v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'E15',
        difficulty: LogicDifficulty.easy,
        inputs: ['A'],
        description: 'Çıkış = A',
        evaluate: (v) => (v['A'] ?? false),
      ),
      // E16 kaldırıldı: kimlik denkliği (A) kafa karıştırıyordu

      // Medium (4-5 gates equivalent)
      LogicPuzzle(
        id: 'M1',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A AND B) OR C',
        evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || (v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'M2',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A OR B) AND (NOT C)',
        evaluate: (v) => ((v['A'] ?? false) || (v['B'] ?? false)) && !(v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'M3',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = NOT(A AND (B OR C))',
        evaluate: (v) => !((v['A'] ?? false) && ((v['B'] ?? false) || (v['C'] ?? false))),
      ),
      LogicPuzzle(
        id: 'M4',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A AND NOT B) OR C',
        evaluate: (v) => ((v['A'] ?? false) && !(v['B'] ?? false)) || (v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'M5',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (NOT A AND B) OR (A AND NOT C)',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          return ((!a && b) || (a && !c));
        },
      ),
      LogicPuzzle(
        id: 'M6',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = A XOR B XOR C (tek sayıda açık)',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          final ones = _trueCount([a, b, c]);
          return ones % 2 == 1;
        },
      ),
      LogicPuzzle(
        id: 'M7',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A AND B) OR (A AND C) OR (B AND C)',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          return (a && b) || (a && c) || (b && c);
        },
      ),
      LogicPuzzle(
        id: 'M8',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A XOR B XOR C) AND NOT (A AND B AND C)',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          return (a && !b && !c) || (!a && b && !c) || (!a && !b && c);
        },
      ),
      LogicPuzzle(
        id: 'M9',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (NOT A AND NOT B) OR C',
        evaluate: (v) => (!(v['A'] ?? false) && !(v['B'] ?? false)) || (v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'M10',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = A OR (B AND NOT C)',
        evaluate: (v) => (v['A'] ?? false) || ((v['B'] ?? false) && !(v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'M11',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (NOT A) OR (B AND C)',
        evaluate: (v) => !(v['A'] ?? false) || ((v['B'] ?? false) && (v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'M12',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = A AND (NOT B OR C)',
        evaluate: (v) => (v['A'] ?? false) && (!(v['B'] ?? false) || (v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'M13',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (NOT A) AND (NOT B OR C)',
        evaluate: (v) => !(v['A'] ?? false) && (!(v['B'] ?? false) || (v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'M14',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A XOR B) AND (NOT C)',
        evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false) && !(v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'M15',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A AND NOT C) OR (B AND NOT C)',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          return (a && !c) || (b && !c);
        },
      ),
      LogicPuzzle(
        id: 'M16',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = NOT(A XOR B) OR C',
        evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false) || (v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'M17',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A OR B) XOR C',
        evaluate: (v) {
          final or = (v['A'] ?? false) || (v['B'] ?? false);
          final c = v['C'] ?? false;
          return _xor2(or, c);
        },
      ),
      LogicPuzzle(
        id: 'M18',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A AND B) XOR C',
        evaluate: (v) {
          final and = (v['A'] ?? false) && (v['B'] ?? false);
          final c = v['C'] ?? false;
          return _xor2(and, c);
        },
      ),

      // Hard (with decoys + timer)
      LogicPuzzle(
        id: 'H1',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = NOT((A OR C) AND (B XOR C))',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          final xor = _xor2(b, c);
          return !((a || c) && xor);
        },
      ),
      LogicPuzzle(
        id: 'H2',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (NOT A AND B) OR (A AND NOT C)',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          return ((!a && b) || (a && !c));
        },
      ),
      LogicPuzzle(
        id: 'H3',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = NOT((A AND B) OR (A AND C) OR (B AND C))',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          return !((a && b) || (a && c) || (b && c));
        },
      ),
      LogicPuzzle(
        id: 'H4',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A OR B OR C) AND NOT(A AND B AND C)',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          final any = a || b || c;
          final all = a && b && c;
          return any && !all;
        },
      ),
      LogicPuzzle(
        id: 'H5',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A AND B AND NOT C) OR (A AND C AND NOT B) OR (B AND C AND NOT A))',
        evaluate: (v) {
          final a = v['A'] ?? false;
          final b = v['B'] ?? false;
          final c = v['C'] ?? false;
          return _trueCount([a, b, c]) == 2;
        },
      ),
      LogicPuzzle(
        id: 'H6',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = NOT(A XOR B) XOR C',
        evaluate: (v) {
          final xnor = _xnor2(v['A'] ?? false, v['B'] ?? false);
          final c = v['C'] ?? false;
          return _xor2(xnor, c);
        },
      ),
      LogicPuzzle(
        id: 'H7',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = NOT((A XOR B) AND (B XOR C))',
        evaluate: (v) {
          final axb = _xor2(v['A'] ?? false, v['B'] ?? false);
          final bxc = _xor2(v['B'] ?? false, v['C'] ?? false);
          return !(axb && bxc);
        },
      ),
      LogicPuzzle(
        id: 'H8',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A AND (NOT B)) XOR (B AND (NOT C))',
        evaluate: (v) {
          final left = (v['A'] ?? false) && !(v['B'] ?? false);
          final right = (v['B'] ?? false) && !(v['C'] ?? false);
          return _xor2(left, right);
        },
      ),
      LogicPuzzle(
        id: 'H9',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = NOT(A AND NOT(B XOR C))',
        evaluate: (v) {
          final bxc = _xor2(v['B'] ?? false, v['C'] ?? false);
          final a = v['A'] ?? false;
          return !(a && !bxc);
        },
      ),
      LogicPuzzle(
        id: 'H10',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A NAND B) AND (B XOR C)',
        evaluate: (v) {
          final nand = !((v['A'] ?? false) && (v['B'] ?? false));
          final bxc = _xor2(v['B'] ?? false, v['C'] ?? false);
          return nand && bxc;
        },
      ),
      LogicPuzzle(
        id: 'H11',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = (A XNOR B) AND (NOT C)',
        evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false) && !(v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'H12',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = NOT((A OR B) AND (B OR C))',
        evaluate: (v) {
          final left = (v['A'] ?? false) || (v['B'] ?? false);
          final right = (v['B'] ?? false) || (v['C'] ?? false);
          return !(left && right);
        },
      ),
      ..._userPuzzles(),
      ..._userPuzzles2(),
      ..._userPuzzles3(),
      ..._userPuzzles4(),
    ];
  }

  List<LogicPuzzle> _userPuzzles() {
    return [
      // Set 1
      LogicPuzzle(
        id: 'U1',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = (A AND B)',
        evaluate: (v) => (v['A'] ?? false) && (v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'U2',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = (A OR B)',
        evaluate: (v) => (v['A'] ?? false) || (v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'U3',
        difficulty: LogicDifficulty.easy,
        inputs: ['A'],
        description: 'Çıkış = (NOT A)',
        evaluate: (v) => !(v['A'] ?? false),
      ),
      LogicPuzzle(
        id: 'U4',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B'],
        description: 'Çıkış = (A XOR B)',
        evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'U5',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A AND B) OR (NOT C))',
        evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || !(v['C'] ?? false),
      ),

      // Set 2
      LogicPuzzle(
        id: 'U6',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B'],
        description: 'Çıkış = (A NOR B)',
        evaluate: (v) => !((v['A'] ?? false) || (v['B'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U7',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B'],
        description: 'Çıkış = (A NAND B)',
        evaluate: (v) => !((v['A'] ?? false) && (v['B'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U8',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A OR B) AND C)',
        evaluate: (v) => (((v['A'] ?? false) || (v['B'] ?? false)) && (v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U9',
        difficulty: LogicDifficulty.easy,
        inputs: ['A', 'B'],
        description: 'Çıkış = ((NOT A) OR B)',
        evaluate: (v) => (!(v['A'] ?? false) || (v['B'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U10',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A XOR B) AND (NOT C))',
        evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false) && !(v['C'] ?? false),
      ),

      // Set 3
      LogicPuzzle(
        id: 'U11',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A AND B) AND C)',
        evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false) && (v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U12',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A OR B) OR C)',
        evaluate: (v) => ((v['A'] ?? false) || (v['B'] ?? false) || (v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U13',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B'],
        description: 'Çıkış = ((NOT A) AND (NOT B))',
        evaluate: (v) => (!(v['A'] ?? false) && !(v['B'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U14',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B'],
        description: 'Çıkış = (A XNOR B)',
        evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'U15',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A AND (NOT B)) OR C)',
        evaluate: (v) => ((v['A'] ?? false) && !(v['B'] ?? false)) || (v['C'] ?? false),
      ),

      // Set 4
      LogicPuzzle(
        id: 'U16',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A OR B) AND (NOT C))',
        evaluate: (v) => (((v['A'] ?? false) || (v['B'] ?? false)) && !(v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U17',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A AND (NOT B)) AND C)',
        evaluate: (v) => ((v['A'] ?? false) && !(v['B'] ?? false) && (v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U18',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B'],
        description: 'Çıkış = ((NOT A) OR (NOT B))',
        evaluate: (v) => (!(v['A'] ?? false) || !(v['B'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U19',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A NAND B) OR C)',
        evaluate: (v) => (!((v['A'] ?? false) && (v['B'] ?? false))) || (v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'U20',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A XOR B) OR (NOT C))',
        evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false) || !(v['C'] ?? false),
      ),

      // Set 5
      LogicPuzzle(
        id: 'U21',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A AND B) OR (B AND C))',
        evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || ((v['B'] ?? false) && (v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U22',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A OR B) AND (B OR C))',
        evaluate: (v) => (((v['A'] ?? false) || (v['B'] ?? false)) && ((v['B'] ?? false) || (v['C'] ?? false))),
      ),
      LogicPuzzle(
        id: 'U23',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'C'],
        description: 'Çıkış = ((NOT A) AND C)',
        evaluate: (v) => (!(v['A'] ?? false) && (v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U24',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A NOR B) AND (NOT C))',
        evaluate: (v) => (!((v['A'] ?? false) || (v['B'] ?? false)) && !(v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U25',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A XNOR B) OR C)',
        evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false) || (v['C'] ?? false),
      ),

      // Set 6
      LogicPuzzle(
        id: 'U26',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A AND (NOT C)) OR B)',
        evaluate: (v) => ((v['A'] ?? false) && !(v['C'] ?? false)) || (v['B'] ?? false),
      ),
      LogicPuzzle(
        id: 'U27',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A OR (NOT B)) AND C)',
        evaluate: (v) => (((v['A'] ?? false) || !(v['B'] ?? false)) && (v['C'] ?? false)),
      ),
      LogicPuzzle(
        id: 'U28',
        difficulty: LogicDifficulty.medium,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((NOT A) OR (B AND C))',
        evaluate: (v) => (!(v['A'] ?? false) || ((v['B'] ?? false) && (v['C'] ?? false))),
      ),
      LogicPuzzle(
        id: 'U29',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A XOR B) AND (B XOR C))',
        evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false) && _xor2(v['B'] ?? false, v['C'] ?? false),
      ),
      LogicPuzzle(
        id: 'U30',
        difficulty: LogicDifficulty.hard,
        inputs: ['A', 'B', 'C'],
        description: 'Çıkış = ((A NAND B) AND (A OR C))',
        evaluate: (v) => (!((v['A'] ?? false) && (v['B'] ?? false))) && ((v['A'] ?? false) || (v['C'] ?? false)),
      ),
    ];
  }

  List<LogicPuzzle> _userPuzzles2() {
    return [
      // Set 7
      LogicPuzzle(
          id: 'U31',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) AND (NOT C))',
          evaluate: (v) => (v['A'] ?? false) && (v['B'] ?? false) && !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U32',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR B) OR (NOT C))',
          evaluate: (v) => (v['A'] ?? false) || (v['B'] ?? false) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U33',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((NOT A) AND (B OR C))',
          evaluate: (v) => !(v['A'] ?? false) && ((v['B'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U34',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A NAND C) OR B)',
          evaluate: (v) => (!((v['A'] ?? false) && (v['C'] ?? false))) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U35',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XOR B) XOR C)',
          evaluate: (v) => _xor2(_xor2(v['A'] ?? false, v['B'] ?? false), v['C'] ?? false)),

      // Set 8
      LogicPuzzle(
          id: 'U36',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND (NOT B)) OR (B AND C))',
          evaluate: (v) => ((v['A'] ?? false) && !(v['B'] ?? false)) || ((v['B'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U37',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR (NOT B)) AND (A OR C))',
          evaluate: (v) => (((v['A'] ?? false) || !(v['B'] ?? false)) && ((v['A'] ?? false) || (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U38',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = ((NOT A) OR (NOT C))',
          evaluate: (v) => (!(v['A'] ?? false) || !(v['C'] ?? false))),
      LogicPuzzle(
          id: 'U39',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A NOR B) OR (B NOR C))',
          evaluate: (v) => (!((v['A'] ?? false) || (v['B'] ?? false))) || (!((v['B'] ?? false) || (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U40',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XNOR B) AND (NOT C))',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false) && !(v['C'] ?? false)),

      // Set 9
      LogicPuzzle(
          id: 'U41',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) OR (C AND (NOT A)))',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || ((v['C'] ?? false) && !(v['A'] ?? false))),
      LogicPuzzle(
          id: 'U42',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR C) AND (B OR (NOT A)))',
          evaluate: (v) => (((v['A'] ?? false) || (v['C'] ?? false)) && ((v['B'] ?? false) || !(v['A'] ?? false)))),
      LogicPuzzle(
          id: 'U43',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((NOT B) AND (C OR A))',
          evaluate: (v) => !(v['B'] ?? false) && ((v['C'] ?? false) || (v['A'] ?? false))),
      LogicPuzzle(
          id: 'U44',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A NAND B) AND (B NAND C))',
          evaluate: (v) => (!((v['A'] ?? false) && (v['B'] ?? false))) && (!((v['B'] ?? false) && (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U45',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XOR C) OR (B AND C))',
          evaluate: (v) => _xor2(v['A'] ?? false, v['C'] ?? false) || ((v['B'] ?? false) && (v['C'] ?? false))),

      // Set 10
      LogicPuzzle(
          id: 'U46',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = ((A AND B) OR (NOT B))',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U47',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR (NOT C)) AND B)',
          evaluate: (v) => (((v['A'] ?? false) || !(v['C'] ?? false)) && (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U48',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((NOT A) AND (B XOR C))',
          evaluate: (v) => !(v['A'] ?? false) && _xor2(v['B'] ?? false, v['C'] ?? false)),
      LogicPuzzle(
          id: 'U49',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A NAND C) OR (NOT B))',
          evaluate: (v) => (!((v['A'] ?? false) && (v['C'] ?? false))) || !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U50',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XNOR B) AND C)',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false) && (v['C'] ?? false)),

      // Set 11
      LogicPuzzle(
          id: 'U51',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND (NOT B)) OR (C AND A))',
          evaluate: (v) => ((v['A'] ?? false) && !(v['B'] ?? false)) || ((v['C'] ?? false) && (v['A'] ?? false))),
      LogicPuzzle(
          id: 'U52',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = ((A OR B) AND (NOT A))',
          evaluate: (v) => ((v['A'] ?? false) || (v['B'] ?? false)) && !(v['A'] ?? false)),
      LogicPuzzle(
          id: 'U53',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((NOT C) OR (A AND B))',
          evaluate: (v) => !(v['C'] ?? false) || ((v['A'] ?? false) && (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U54',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A NOR C) AND (NOT B))',
          evaluate: (v) => (!((v['A'] ?? false) || (v['C'] ?? false))) && !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U55',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XOR B) AND (A XOR C))',
          evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false) && _xor2(v['A'] ?? false, v['C'] ?? false)),

      // Set 12
      LogicPuzzle(
          id: 'U56',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A AND B AND C)',
          evaluate: (v) => (v['A'] ?? false) && (v['B'] ?? false) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U57',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR B OR C)',
          evaluate: (v) => (v['A'] ?? false) || (v['B'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U58',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((NOT A) OR (NOT B) OR (NOT C))',
          evaluate: (v) => !(v['A'] ?? false) || !(v['B'] ?? false) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U59',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A NAND B) OR (C NAND A))',
          evaluate: (v) => (!((v['A'] ?? false) && (v['B'] ?? false))) || (!((v['C'] ?? false) && (v['A'] ?? false)))),
      LogicPuzzle(
          id: 'U60',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XNOR C) OR (B AND C))',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['C'] ?? false) || ((v['B'] ?? false) && (v['C'] ?? false))),

      // Set 13
      LogicPuzzle(
          id: 'U61',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A AND (B OR C))',
          evaluate: (v) => (v['A'] ?? false) && ((v['B'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U62',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR (B AND C))',
          evaluate: (v) => (v['A'] ?? false) || ((v['B'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U63',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT (A AND B))',
          evaluate: (v) => !((v['A'] ?? false) && (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U64',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A XOR (B OR C))',
          evaluate: (v) => _xor2(v['A'] ?? false, ((v['B'] ?? false) || (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U65',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) OR (A AND C))',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || ((v['A'] ?? false) && (v['C'] ?? false))),

      // Set 14
      LogicPuzzle(
          id: 'U66',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((NOT A) AND (B OR C))',
          evaluate: (v) => !(v['A'] ?? false) && ((v['B'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U67',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR (NOT (B AND C)))',
          evaluate: (v) => (v['A'] ?? false) || !((v['B'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U68',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A XNOR (B XOR C))',
          evaluate: (v) => _xnor2(v['A'] ?? false, _xor2(v['B'] ?? false, v['C'] ?? false))),
      LogicPuzzle(
          id: 'U69',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = ((A OR B) AND (NOT (A AND B)))',
          evaluate: (v) => ((v['A'] ?? false) || (v['B'] ?? false)) && !((v['A'] ?? false) && (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U70',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((NOT A) OR (B AND (NOT C)))',
          evaluate: (v) => !(v['A'] ?? false) || ((v['B'] ?? false) && !(v['C'] ?? false))),

      // Set 15
      LogicPuzzle(
          id: 'U71',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) XOR C)',
          evaluate: (v) => _xor2(((v['A'] ?? false) && (v['B'] ?? false)), v['C'] ?? false)),
      LogicPuzzle(
          id: 'U72',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A NAND (B OR C))',
          evaluate: (v) => !((v['A'] ?? false) && ((v['B'] ?? false) || (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U73',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR B OR (NOT C)) AND (A OR (NOT B)))',
          evaluate: (v) => (((v['A'] ?? false) || (v['B'] ?? false) || !(v['C'] ?? false)) &&
              ((v['A'] ?? false) || !(v['B'] ?? false)))),
      LogicPuzzle(
          id: 'U74',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND (B XNOR C)) OR (NOT B))',
          evaluate: (v) => ((v['A'] ?? false) && _xnor2(v['B'] ?? false, v['C'] ?? false)) || !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U75',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XOR B) OR (C NAND A))',
          evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false) || !((v['C'] ?? false) && (v['A'] ?? false))),

      // Set 16 (Orta-Kolay)
      LogicPuzzle(
          id: 'U76',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A AND B)',
          evaluate: (v) => (v['A'] ?? false) && (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U77',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A OR C)',
          evaluate: (v) => (v['A'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U78',
          difficulty: LogicDifficulty.easy,
          inputs: ['B'],
          description: 'Çıkış = (NOT B)',
          evaluate: (v) => !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U79',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A XOR B)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false)),
      LogicPuzzle(
          id: 'U80',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) OR C)',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || (v['C'] ?? false)),

      // Set 17 (Orta-Kolay)
      LogicPuzzle(
          id: 'U81',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A NAND B)',
          evaluate: (v) => !((v['A'] ?? false) && (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U82',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A NOR C)',
          evaluate: (v) => !((v['A'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U83',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A AND (NOT B))',
          evaluate: (v) => (v['A'] ?? false) && !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U84',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A OR (NOT C))',
          evaluate: (v) => (v['A'] ?? false) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U85',
          difficulty: LogicDifficulty.medium,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B XOR C)',
          evaluate: (v) => _xor2(v['B'] ?? false, v['C'] ?? false)),

      // Set 18 (Orta-Kolay)
      LogicPuzzle(
          id: 'U86',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A AND C)',
          evaluate: (v) => (v['A'] ?? false) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U87',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A OR B)',
          evaluate: (v) => (v['A'] ?? false) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U88',
          difficulty: LogicDifficulty.easy,
          inputs: ['A'],
          description: 'Çıkış = (NOT A)',
          evaluate: (v) => !(v['A'] ?? false)),
      LogicPuzzle(
          id: 'U89',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XOR B) AND C)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U90',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A NAND C) OR B)',
          evaluate: (v) => (!((v['A'] ?? false) && (v['C'] ?? false))) || (v['B'] ?? false)),
    ];
  }

  List<LogicPuzzle> _userPuzzles3() {
    return [
      // Set 19 (U91..U95)
      LogicPuzzle(
          id: 'U91',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A AND (NOT B))',
          evaluate: (v) => (v['A'] ?? false) && !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U92',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A OR C)',
          evaluate: (v) => (v['A'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U93',
          difficulty: LogicDifficulty.medium,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B NAND C)',
          evaluate: (v) => !((v['B'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U94',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A NOR B)',
          evaluate: (v) => !((v['A'] ?? false) || (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U95',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A XOR C)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['C'] ?? false)),

      // Set 20 (U96..U100)
      LogicPuzzle(
          id: 'U96',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) OR C)',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U97',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR B) AND (NOT C))',
          evaluate: (v) => (((v['A'] ?? false) || (v['B'] ?? false)) && !(v['C'] ?? false))),
      LogicPuzzle(
          id: 'U98',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT A OR B)',
          evaluate: (v) => !(v['A'] ?? false) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U99',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A XNOR B)',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false)),
      LogicPuzzle(
          id: 'U100',
          difficulty: LogicDifficulty.easy,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B AND (NOT C))',
          evaluate: (v) => (v['B'] ?? false) && !(v['C'] ?? false)),

      // Set 21 (U101..U105)
      LogicPuzzle(
          id: 'U101',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A OR (NOT B))',
          evaluate: (v) => (v['A'] ?? false) || !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U102',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A AND C)',
          evaluate: (v) => (v['A'] ?? false) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U103',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR B OR C)',
          evaluate: (v) => (v['A'] ?? false) || (v['B'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U104',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A XOR (NOT C))',
          evaluate: (v) => _xor2(v['A'] ?? false, !(v['C'] ?? false))),
      LogicPuzzle(
          id: 'U105',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A NAND (NOT B))',
          evaluate: (v) => !((v['A'] ?? false) && !(v['B'] ?? false))),

      // Set 22 (U106..U110)
      LogicPuzzle(
          id: 'U106',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) OR (NOT C))',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U107',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR B) AND (C OR NOT A))',
          evaluate: (v) => (((v['A'] ?? false) || (v['B'] ?? false)) && ((v['C'] ?? false) || !(v['A'] ?? false)))),
      LogicPuzzle(
          id: 'U108',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XOR B) OR C)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U109',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((NOT A AND B) OR (C AND A))',
          evaluate: (v) => (!(v['A'] ?? false) && (v['B'] ?? false)) || ((v['C'] ?? false) && (v['A'] ?? false))),
      LogicPuzzle(
          id: 'U110',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A NOR B) AND C)',
          evaluate: (v) => (!((v['A'] ?? false) || (v['B'] ?? false))) && (v['C'] ?? false)),

      // Set 23 (U111..U115)
      LogicPuzzle(
          id: 'U111',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND NOT B) OR (B AND C))',
          evaluate: (v) => ((v['A'] ?? false) && !(v['B'] ?? false)) || ((v['B'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U112',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR NOT C) AND (B OR C))',
          evaluate: (v) => (((v['A'] ?? false) || !(v['C'] ?? false)) && ((v['B'] ?? false) || (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U113',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XNOR B) OR (NOT C))',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U114',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((NOT A OR B) AND (A OR C))',
          evaluate: (v) => ((!(v['A'] ?? false) || (v['B'] ?? false)) && ((v['A'] ?? false) || (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U115',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XOR C) AND (B OR NOT A))',
          evaluate: (v) => _xor2(v['A'] ?? false, v['C'] ?? false) && ((v['B'] ?? false) || !(v['A'] ?? false))),

      // Set 24 (U116..U120)
      LogicPuzzle(
          id: 'U116',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) XOR C)',
          evaluate: (v) => _xor2(((v['A'] ?? false) && (v['B'] ?? false)), v['C'] ?? false)),
      LogicPuzzle(
          id: 'U117',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR (B AND NOT C))',
          evaluate: (v) => (v['A'] ?? false) || ((v['B'] ?? false) && !(v['C'] ?? false))),
      LogicPuzzle(
          id: 'U118',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((NOT A OR B) XOR C)',
          evaluate: (v) => _xor2((!(v['A'] ?? false) || (v['B'] ?? false)), v['C'] ?? false)),
      LogicPuzzle(
          id: 'U119',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND NOT B) OR (B XOR C))',
          evaluate: (v) => ((v['A'] ?? false) && !(v['B'] ?? false)) || _xor2(v['B'] ?? false, v['C'] ?? false)),
      LogicPuzzle(
          id: 'U120',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A NOR C) OR (B AND NOT A))',
          evaluate: (v) => (!((v['A'] ?? false) || (v['C'] ?? false))) || ((v['B'] ?? false) && !(v['A'] ?? false))),

      // Set 25 (U121..U125)
      LogicPuzzle(
          id: 'U121',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A AND NOT B)',
          evaluate: (v) => (v['A'] ?? false) && !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U122',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A OR C)',
          evaluate: (v) => (v['A'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U123',
          difficulty: LogicDifficulty.medium,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B XOR C)',
          evaluate: (v) => _xor2(v['B'] ?? false, v['C'] ?? false)),
      LogicPuzzle(
          id: 'U124',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A NAND B)',
          evaluate: (v) => !((v['A'] ?? false) && (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U125',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A NOR C)',
          evaluate: (v) => !((v['A'] ?? false) || (v['C'] ?? false))),

      // Set 26 (U126..U130)
      LogicPuzzle(
          id: 'U126',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) OR C)',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U127',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT A OR B)',
          evaluate: (v) => !(v['A'] ?? false) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U128',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A XOR C)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['C'] ?? false)),
      LogicPuzzle(
          id: 'U129',
          difficulty: LogicDifficulty.easy,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B AND NOT C)',
          evaluate: (v) => (v['B'] ?? false) && !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U130',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A XNOR B)',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false)),

      // Set 27 (U131..U133)
      LogicPuzzle(
          id: 'U131',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A OR NOT B)',
          evaluate: (v) => (v['A'] ?? false) || !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U132',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A AND C)',
          evaluate: (v) => (v['A'] ?? false) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U133',
          difficulty: LogicDifficulty.easy,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B OR C)',
          evaluate: (v) => (v['B'] ?? false) || (v['C'] ?? false)),

      // Soru 134..135 (from trailing lines)
      LogicPuzzle(
          id: 'U134',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT A AND B)',
          evaluate: (v) => !(v['A'] ?? false) && (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U135',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XOR B) OR C)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false) || (v['C'] ?? false)),

      // Set 28 (U136..U140)
      LogicPuzzle(
          id: 'U136',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A AND B)',
          evaluate: (v) => (v['A'] ?? false) && (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U137',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A OR NOT C)',
          evaluate: (v) => (v['A'] ?? false) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U138',
          difficulty: LogicDifficulty.medium,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B XOR C)',
          evaluate: (v) => _xor2(v['B'] ?? false, v['C'] ?? false)),
      LogicPuzzle(
          id: 'U139',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A NAND C)',
          evaluate: (v) => !((v['A'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U140',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT B OR A)',
          evaluate: (v) => !(v['B'] ?? false) || (v['A'] ?? false)),

      // Set 29 (U141..U145)
      LogicPuzzle(
          id: 'U141',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A AND NOT C)',
          evaluate: (v) => (v['A'] ?? false) && !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U142',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A OR B)',
          evaluate: (v) => (v['A'] ?? false) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U143',
          difficulty: LogicDifficulty.medium,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B NOR C)',
          evaluate: (v) => !((v['B'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U144',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A XOR B)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false)),
      LogicPuzzle(
          id: 'U145',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A XNOR C)',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['C'] ?? false)),

      // Set 30 (U146..U150)
      LogicPuzzle(
          id: 'U146',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT A AND B)',
          evaluate: (v) => !(v['A'] ?? false) && (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U147',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A OR C)',
          evaluate: (v) => (v['A'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U148',
          difficulty: LogicDifficulty.easy,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B AND C)',
          evaluate: (v) => (v['B'] ?? false) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U149',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A XOR NOT B)',
          evaluate: (v) => _xor2(v['A'] ?? false, !(v['B'] ?? false))),
      LogicPuzzle(
          id: 'U150',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A NOR B)',
          evaluate: (v) => !((v['A'] ?? false) || (v['B'] ?? false))),
    ];
  }

  List<LogicPuzzle> _userPuzzles4() {
    return [
      // Mantık Kapısı Soruları (U151..U375)
      LogicPuzzle(
          id: 'U151',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A AND NOT B)',
          evaluate: (v) => (v['A'] ?? false) && !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U152',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A OR C)',
          evaluate: (v) => (v['A'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U153',
          difficulty: LogicDifficulty.medium,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B XOR C)',
          evaluate: (v) => _xor2(v['B'] ?? false, v['C'] ?? false)),
      LogicPuzzle(
          id: 'U154',
          difficulty: LogicDifficulty.easy,
          inputs: ['A'],
          description: 'Çıkış = (NOT A)',
          evaluate: (v) => !(v['A'] ?? false)),
      LogicPuzzle(
          id: 'U155',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A NAND B)',
          evaluate: (v) => !((v['A'] ?? false) && (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U156',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A NOR C)',
          evaluate: (v) => !((v['A'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U157',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A AND B OR C)',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U158',
          difficulty: LogicDifficulty.easy,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B OR NOT C)',
          evaluate: (v) => (v['B'] ?? false) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U159',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A XOR B)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false)),
      LogicPuzzle(
          id: 'U160',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A XNOR C)',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['C'] ?? false)),
      LogicPuzzle(
          id: 'U161',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT B OR A)',
          evaluate: (v) => !(v['B'] ?? false) || (v['A'] ?? false)),
      LogicPuzzle(
          id: 'U162',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A AND C)',
          evaluate: (v) => (v['A'] ?? false) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U163',
          difficulty: LogicDifficulty.easy,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B OR C)',
          evaluate: (v) => (v['B'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U164',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT A AND B)',
          evaluate: (v) => !(v['A'] ?? false) && (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U165',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A XOR B OR C)',
          evaluate: (v) => _xor2(v['A'] ?? false, (v['B'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U166',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A NAND C)',
          evaluate: (v) => !((v['A'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U167',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A OR B)',
          evaluate: (v) => (v['A'] ?? false) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U168',
          difficulty: LogicDifficulty.medium,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B NOR C)',
          evaluate: (v) => !((v['B'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U169',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A AND NOT C)',
          evaluate: (v) => (v['A'] ?? false) && !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U170',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT A OR B)',
          evaluate: (v) => !(v['A'] ?? false) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U171',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A XOR C)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['C'] ?? false)),
      LogicPuzzle(
          id: 'U172',
          difficulty: LogicDifficulty.easy,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B AND NOT C)',
          evaluate: (v) => (v['B'] ?? false) && !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U173',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A XNOR B)',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false)),
      LogicPuzzle(
          id: 'U174',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A OR NOT B)',
          evaluate: (v) => (v['A'] ?? false) || !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U175',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A AND C OR B)',
          evaluate: (v) => ((v['A'] ?? false) && (v['C'] ?? false)) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U176',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (B XOR C AND A)',
          evaluate: (v) => _xor2(v['B'] ?? false, v['C'] ?? false) && (v['A'] ?? false)),
      LogicPuzzle(
          id: 'U177',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT A AND NOT B)',
          evaluate: (v) => !(v['A'] ?? false) && !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U178',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR B OR C)',
          evaluate: (v) => (v['A'] ?? false) || (v['B'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U179',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A AND B AND NOT C)',
          evaluate: (v) => (v['A'] ?? false) && (v['B'] ?? false) && !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U180',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (B OR NOT A)',
          evaluate: (v) => (v['B'] ?? false) || !(v['A'] ?? false)),
      LogicPuzzle(
          id: 'U181',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A XOR NOT B)',
          evaluate: (v) => _xor2(v['A'] ?? false, !(v['B'] ?? false))),
      LogicPuzzle(
          id: 'U182',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A NAND B OR C)',
          evaluate: (v) => (!((v['A'] ?? false) && (v['B'] ?? false))) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U183',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A AND NOT B OR C)',
          evaluate: (v) => ((v['A'] ?? false) && !(v['B'] ?? false)) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U184',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (NOT A OR B AND C)',
          evaluate: (v) => !(v['A'] ?? false) || ((v['B'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U185',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A XOR B AND NOT C)',
          evaluate: (v) => _xor2(v['A'] ?? false, (v['B'] ?? false) && !(v['C'] ?? false))),
      LogicPuzzle(
          id: 'U186',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A NOR B OR C)',
          evaluate: (v) => (!((v['A'] ?? false) || (v['B'] ?? false))) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U187',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A AND B OR NOT C)',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U188',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (B XOR C OR A)',
          evaluate: (v) => _xor2(v['B'] ?? false, v['C'] ?? false) || (v['A'] ?? false)),
      LogicPuzzle(
          id: 'U189',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (NOT A AND C OR B)',
          evaluate: (v) => (!(v['A'] ?? false) && (v['C'] ?? false)) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U190',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR B AND NOT C)',
          evaluate: (v) => (v['A'] ?? false) || ((v['B'] ?? false) && !(v['C'] ?? false))),
      LogicPuzzle(
          id: 'U191',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A XNOR C AND B)',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['C'] ?? false) && (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U192',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (NOT B OR A AND C)',
          evaluate: (v) => !(v['B'] ?? false) || ((v['A'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U193',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A AND NOT C OR B)',
          evaluate: (v) => ((v['A'] ?? false) && !(v['C'] ?? false)) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U194',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (B NAND C OR A)',
          evaluate: (v) => (!((v['B'] ?? false) && (v['C'] ?? false))) || (v['A'] ?? false)),
      LogicPuzzle(
          id: 'U195',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A AND B)',
          evaluate: (v) => (v['A'] ?? false) && (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U196',
          difficulty: LogicDifficulty.easy,
          inputs: ['X', 'Y'],
          description: 'Çıkış = (X OR Y)',
          evaluate: (v) => (v['X'] ?? false) || (v['Y'] ?? false)),
      LogicPuzzle(
          id: 'U197',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q'],
          description: 'Çıkış = (P XOR Q)',
          evaluate: (v) => _xor2(v['P'] ?? false, v['Q'] ?? false)),
      LogicPuzzle(
          id: 'U198',
          difficulty: LogicDifficulty.easy,
          inputs: ['C'],
          description: 'Çıkış = (NOT C)',
          evaluate: (v) => !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U199',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N'],
          description: 'Çıkış = (M NAND N)',
          evaluate: (v) => !((v['M'] ?? false) && (v['N'] ?? false))),
      LogicPuzzle(
          id: 'U200',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A OR NOT B)',
          evaluate: (v) => (v['A'] ?? false) || !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U201',
          difficulty: LogicDifficulty.easy,
          inputs: ['X', 'Z'],
          description: 'Çıkış = (X AND NOT Z)',
          evaluate: (v) => (v['X'] ?? false) && !(v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U202',
          difficulty: LogicDifficulty.easy,
          inputs: ['P', 'Q'],
          description: 'Çıkış = (P OR (NOT Q))',
          evaluate: (v) => (v['P'] ?? false) || !(v['Q'] ?? false)),
      LogicPuzzle(
          id: 'U203',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'O'],
          description: 'Çıkış = (M XOR O)',
          evaluate: (v) => _xor2(v['M'] ?? false, v['O'] ?? false)),
      LogicPuzzle(
          id: 'U204',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A NOR C)',
          evaluate: (v) => !((v['A'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U205',
          difficulty: LogicDifficulty.easy,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B OR C)',
          evaluate: (v) => (v['B'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U206',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Z'],
          description: 'Çıkış = (X XOR Z)',
          evaluate: (v) => _xor2(v['X'] ?? false, v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U207',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q'],
          description: 'Çıkış = (P NAND Q)',
          evaluate: (v) => !((v['P'] ?? false) && (v['Q'] ?? false))),
      LogicPuzzle(
          id: 'U208',
          difficulty: LogicDifficulty.easy,
          inputs: ['M', 'N'],
          description: 'Çıkış = (M OR N)',
          evaluate: (v) => (v['M'] ?? false) || (v['N'] ?? false)),
      LogicPuzzle(
          id: 'U209',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (NOT A AND C)',
          evaluate: (v) => !(v['A'] ?? false) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U210',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = (X OR (Y AND Z))',
          evaluate: (v) => (v['X'] ?? false) || ((v['Y'] ?? false) && (v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U211',
          difficulty: LogicDifficulty.easy,
          inputs: ['P', 'R'],
          description: 'Çıkış = (P AND (NOT R))',
          evaluate: (v) => (v['P'] ?? false) && !(v['R'] ?? false)),
      LogicPuzzle(
          id: 'U212',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M NOR (N OR O))',
          evaluate: (v) => !((v['M'] ?? false) || (v['N'] ?? false) || (v['O'] ?? false))),
      LogicPuzzle(
          id: 'U213',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR B) AND C)',
          evaluate: (v) => ((v['A'] ?? false) || (v['B'] ?? false)) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U214',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X NAND Y) OR Z)',
          evaluate: (v) => (!((v['X'] ?? false) && (v['Y'] ?? false))) || (v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U215',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((P OR R) AND Q)',
          evaluate: (v) => ((v['P'] ?? false) || (v['R'] ?? false)) && (v['Q'] ?? false)),
      LogicPuzzle(
          id: 'U216',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M AND N) XOR O)',
          evaluate: (v) => _xor2(((v['M'] ?? false) && (v['N'] ?? false)), (v['O'] ?? false))),
      LogicPuzzle(
          id: 'U217',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A XNOR B)',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false)),
      LogicPuzzle(
          id: 'U218',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Z'],
          description: 'Çıkış = (X NOR Z)',
          evaluate: (v) => !((v['X'] ?? false) || (v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U219',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((P AND Q) OR NOT R)',
          evaluate: (v) => ((v['P'] ?? false) && (v['Q'] ?? false)) || !(v['R'] ?? false)),
      LogicPuzzle(
          id: 'U220',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M XOR N) AND O)',
          evaluate: (v) => (_xor2(v['M'] ?? false, v['N'] ?? false)) && (v['O'] ?? false)),
      LogicPuzzle(
          id: 'U221',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT A OR B)',
          evaluate: (v) => !(v['A'] ?? false) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U222',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = (X AND (Y OR Z))',
          evaluate: (v) => (v['X'] ?? false) && ((v['Y'] ?? false) || (v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U223',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((P OR NOT Q) AND R)',
          evaluate: (v) => ((v['P'] ?? false) || !(v['Q'] ?? false)) && (v['R'] ?? false)),
      LogicPuzzle(
          id: 'U224',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M OR O) NAND N)',
          evaluate: (v) => !(((v['M'] ?? false) || (v['O'] ?? false)) && (v['N'] ?? false))),
      LogicPuzzle(
          id: 'U225',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) OR C)',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U226',
          difficulty: LogicDifficulty.hard,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X OR NOT Z) XOR Y)',
          evaluate: (v) => _xor2(((v['X'] ?? false) || !(v['Z'] ?? false)), (v['Y'] ?? false))),
      LogicPuzzle(
          id: 'U227',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((P NAND Q) OR R)',
          evaluate: (v) => (!((v['P'] ?? false) && (v['Q'] ?? false))) || (v['R'] ?? false)),
      LogicPuzzle(
          id: 'U228',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M AND (N OR NOT O))',
          evaluate: (v) => (v['M'] ?? false) && ((v['N'] ?? false) || !(v['O'] ?? false))),
      LogicPuzzle(
          id: 'U229',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT (A OR B))',
          evaluate: (v) => !((v['A'] ?? false) || (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U230',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X XOR Y) AND Z)',
          evaluate: (v) => (_xor2(v['X'] ?? false, v['Y'] ?? false)) && (v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U231',
          difficulty: LogicDifficulty.hard,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = (P NOR (Q AND R))',
          evaluate: (v) => !((v['P'] ?? false) || ((v['Q'] ?? false) && (v['R'] ?? false)))),
      LogicPuzzle(
          id: 'U232',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M OR N) XOR O)',
          evaluate: (v) => _xor2(((v['M'] ?? false) || (v['N'] ?? false)), (v['O'] ?? false))),
      LogicPuzzle(
          id: 'U233',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A AND (NOT C))',
          evaluate: (v) => (v['A'] ?? false) && !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U234',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X OR Y) NAND Z)',
          evaluate: (v) => !(((v['X'] ?? false) || (v['Y'] ?? false)) && (v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U235',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((P XOR Q) OR R)',
          evaluate: (v) => (_xor2(v['P'] ?? false, v['Q'] ?? false)) || (v['R'] ?? false)),
      LogicPuzzle(
          id: 'U236',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M AND (N NAND O))',
          evaluate: (v) => (v['M'] ?? false) && (!((v['N'] ?? false) && (v['O'] ?? false)))),
      LogicPuzzle(
          id: 'U237',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR (B XOR C))',
          evaluate: (v) => (v['A'] ?? false) || (_xor2(v['B'] ?? false, v['C'] ?? false))),
      LogicPuzzle(
          id: 'U238',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Z'],
          description: 'Çıkış = (NOT (X AND Z))',
          evaluate: (v) => !((v['X'] ?? false) && (v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U239',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = (P AND (Q OR R))',
          evaluate: (v) => (v['P'] ?? false) && ((v['Q'] ?? false) || (v['R'] ?? false))),
      LogicPuzzle(
          id: 'U240',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M XOR N) OR (O AND M))',
          evaluate: (v) => (_xor2(v['M'] ?? false, v['N'] ?? false)) || ((v['O'] ?? false) && (v['M'] ?? false))),
      LogicPuzzle(
          id: 'U286',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A AND C)',
          evaluate: (v) => (v['A'] ?? false) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U287',
          difficulty: LogicDifficulty.easy,
          inputs: ['X', 'Z'],
          description: 'Çıkış = (X OR NOT Z)',
          evaluate: (v) => (v['X'] ?? false) || !(v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U288',
          difficulty: LogicDifficulty.easy,
          inputs: ['P', 'Q'],
          description: 'Çıkış = (P AND Q)',
          evaluate: (v) => (v['P'] ?? false) && (v['Q'] ?? false)),
      LogicPuzzle(
          id: 'U289',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'O'],
          description: 'Çıkış = (M XOR O)',
          evaluate: (v) => _xor2(v['M'] ?? false, v['O'] ?? false)),
      LogicPuzzle(
          id: 'U290',
          difficulty: LogicDifficulty.easy,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B OR (NOT C))',
          evaluate: (v) => (v['B'] ?? false) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U291',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y'],
          description: 'Çıkış = (X NAND Y)',
          evaluate: (v) => !((v['X'] ?? false) && (v['Y'] ?? false))),
      LogicPuzzle(
          id: 'U292',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'R', 'Q'],
          description: 'Çıkış = ((P OR R) AND NOT Q)',
          evaluate: (v) => ((v['P'] ?? false) || (v['R'] ?? false)) && !(v['Q'] ?? false)),
      LogicPuzzle(
          id: 'U293',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N'],
          description: 'Çıkış = (M NOR N)',
          evaluate: (v) => !((v['M'] ?? false) || (v['N'] ?? false))),
      LogicPuzzle(
          id: 'U294',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A XOR B) OR C)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['B'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U295',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y'],
          description: 'Çıkış = (NOT (X AND Y))',
          evaluate: (v) => !((v['X'] ?? false) && (v['Y'] ?? false))),
      LogicPuzzle(
          id: 'U296',
          difficulty: LogicDifficulty.easy,
          inputs: ['Q', 'R'],
          description: 'Çıkış = (Q OR R)',
          evaluate: (v) => (v['Q'] ?? false) || (v['R'] ?? false)),
      LogicPuzzle(
          id: 'U297',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M AND NOT N) OR O)',
          evaluate: (v) => ((v['M'] ?? false) && !(v['N'] ?? false)) || (v['O'] ?? false)),
      LogicPuzzle(
          id: 'U298',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'C', 'B'],
          description: 'Çıkış = ((A OR C) NAND B)',
          evaluate: (v) => !(((v['A'] ?? false) || (v['C'] ?? false)) && (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U299',
          difficulty: LogicDifficulty.hard,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = (X XOR (Y AND Z))',
          evaluate: (v) => _xor2(v['X'] ?? false, ((v['Y'] ?? false) && (v['Z'] ?? false)))),
      LogicPuzzle(
          id: 'U300',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((P AND NOT Q) OR R)',
          evaluate: (v) => ((v['P'] ?? false) && !(v['Q'] ?? false)) || (v['R'] ?? false)),
      LogicPuzzle(
          id: 'U301',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M XOR N) OR O)',
          evaluate: (v) => (_xor2(v['M'] ?? false, v['N'] ?? false)) || (v['O'] ?? false)),
      LogicPuzzle(
          id: 'U302',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A NOR B)',
          evaluate: (v) => !((v['A'] ?? false) || (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U303',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X OR Y) AND NOT Z)',
          evaluate: (v) => ((v['X'] ?? false) || (v['Y'] ?? false)) && !(v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U304',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'R'],
          description: 'Çıkış = (P NAND R)',
          evaluate: (v) => !((v['P'] ?? false) && (v['R'] ?? false))),
      LogicPuzzle(
          id: 'U305',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'O', 'N'],
          description: 'Çıkış = ((M OR O) XOR N)',
          evaluate: (v) => _xor2(((v['M'] ?? false) || (v['O'] ?? false)), (v['N'] ?? false))),
      LogicPuzzle(
          id: 'U306',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (NOT A OR C)',
          evaluate: (v) => !(v['A'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U307',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y'],
          description: 'Çıkış = (X XNOR Y)',
          evaluate: (v) => _xnor2(v['X'] ?? false, v['Y'] ?? false)),
      LogicPuzzle(
          id: 'U308',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((P OR Q) OR NOT R)',
          evaluate: (v) => (v['P'] ?? false) || (v['Q'] ?? false) || !(v['R'] ?? false)),
      LogicPuzzle(
          id: 'U309',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M AND N) NAND O)',
          evaluate: (v) => !(((v['M'] ?? false) && (v['N'] ?? false)) && (v['O'] ?? false))),
      LogicPuzzle(
          id: 'U310',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A XOR (NOT C))',
          evaluate: (v) => _xor2(v['A'] ?? false, !(v['C'] ?? false))),
      LogicPuzzle(
          id: 'U311',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X OR NOT Y) AND Z)',
          evaluate: (v) => ((v['X'] ?? false) || !(v['Y'] ?? false)) && (v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U312',
          difficulty: LogicDifficulty.hard,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = (P NOR (Q OR R))',
          evaluate: (v) => !((v['P'] ?? false) || (v['Q'] ?? false) || (v['R'] ?? false))),
      LogicPuzzle(
          id: 'U313',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'O', 'N'],
          description: 'Çıkış = ((M AND O) OR N)',
          evaluate: (v) => ((v['M'] ?? false) && (v['O'] ?? false)) || (v['N'] ?? false)),
      LogicPuzzle(
          id: 'U314',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR (B AND NOT C))',
          evaluate: (v) => (v['A'] ?? false) || ((v['B'] ?? false) && !(v['C'] ?? false))),
      LogicPuzzle(
          id: 'U315',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Z'],
          description: 'Çıkış = (X XOR Z)',
          evaluate: (v) => _xor2(v['X'] ?? false, v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U316',
          difficulty: LogicDifficulty.hard,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((NOT P OR Q) NAND R)',
          evaluate: (v) => !(((!(v['P'] ?? false) || (v['Q'] ?? false)) && (v['R'] ?? false)))),
      LogicPuzzle(
          id: 'U317',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M OR N) OR NOT O)',
          evaluate: (v) => (v['M'] ?? false) || (v['N'] ?? false) || !(v['O'] ?? false)),
      LogicPuzzle(
          id: 'U318',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A NAND (B AND C))',
          evaluate: (v) => !((v['A'] ?? false) && ((v['B'] ?? false) && (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U319',
          difficulty: LogicDifficulty.hard,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = (X OR (Y XOR NOT Z))',
          evaluate: (v) => (v['X'] ?? false) || _xor2(v['Y'] ?? false, !(v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U320',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = (P AND (NOT Q OR R))',
          evaluate: (v) => (v['P'] ?? false) && ((!(v['Q'] ?? false)) || (v['R'] ?? false))),
      LogicPuzzle(
          id: 'U321',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'O', 'N'],
          description: 'Çıkış = ((M NOR O) AND N)',
          evaluate: (v) => (!((v['M'] ?? false) || (v['O'] ?? false))) && (v['N'] ?? false)),
      LogicPuzzle(
          id: 'U322',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A XNOR C)',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['C'] ?? false)),
      LogicPuzzle(
          id: 'U323',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Z', 'Y'],
          description: 'Çıkış = ((X NAND Z) OR Y)',
          evaluate: (v) => (!((v['X'] ?? false) && (v['Z'] ?? false))) || (v['Y'] ?? false)),
      LogicPuzzle(
          id: 'U324',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'R'],
          description: 'Çıkış = (P XOR (NOT R))',
          evaluate: (v) => _xor2(v['P'] ?? false, !(v['R'] ?? false))),
      LogicPuzzle(
          id: 'U325',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M AND (N OR O))',
          evaluate: (v) => (v['M'] ?? false) && ((v['N'] ?? false) || (v['O'] ?? false))),
      LogicPuzzle(
          id: 'U326',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR NOT B) AND C)',
          evaluate: (v) => ((v['A'] ?? false) || !(v['B'] ?? false)) && (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U327',
          difficulty: LogicDifficulty.hard,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X XOR Y) NAND Z)',
          evaluate: (v) => !((_xor2(v['X'] ?? false, v['Y'] ?? false)) && (v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U328',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q'],
          description: 'Çıkış = (NOT (P AND Q))',
          evaluate: (v) => !((v['P'] ?? false) && (v['Q'] ?? false))),
      LogicPuzzle(
          id: 'U329',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M OR N) XOR (NOT O))',
          evaluate: (v) => _xor2(((v['M'] ?? false) || (v['N'] ?? false)), !(v['O'] ?? false))),
      LogicPuzzle(
          id: 'U330',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) OR (NOT C))',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U241',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A OR C)',
          evaluate: (v) => (v['A'] ?? false) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U242',
          difficulty: LogicDifficulty.easy,
          inputs: ['X', 'Z'],
          description: 'Çıkış = (X AND Z)',
          evaluate: (v) => (v['X'] ?? false) && (v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U243',
          difficulty: LogicDifficulty.easy,
          inputs: ['P', 'Q'],
          description: 'Çıkış = (NOT P OR Q)',
          evaluate: (v) => !(v['P'] ?? false) || (v['Q'] ?? false)),
      LogicPuzzle(
          id: 'U244',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N'],
          description: 'Çıkış = (M XOR N)',
          evaluate: (v) => _xor2(v['M'] ?? false, v['N'] ?? false)),
      LogicPuzzle(
          id: 'U245',
          difficulty: LogicDifficulty.medium,
          inputs: ['B', 'C'],
          description: 'Çıkış = (B NAND C)',
          evaluate: (v) => !((v['B'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U246',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y'],
          description: 'Çıkış = (X NOR Y)',
          evaluate: (v) => !((v['X'] ?? false) || (v['Y'] ?? false))),
      LogicPuzzle(
          id: 'U247',
          difficulty: LogicDifficulty.easy,
          inputs: ['P', 'R'],
          description: 'Çıkış = (P OR R)',
          evaluate: (v) => (v['P'] ?? false) || (v['R'] ?? false)),
      LogicPuzzle(
          id: 'U248',
          difficulty: LogicDifficulty.easy,
          inputs: ['M', 'O'],
          description: 'Çıkış = (M AND (NOT O))',
          evaluate: (v) => (v['M'] ?? false) && !(v['O'] ?? false)),
      LogicPuzzle(
          id: 'U249',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A XOR (B OR C))',
          evaluate: (v) => _xor2(v['A'] ?? false, (v['B'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U250',
          difficulty: LogicDifficulty.easy,
          inputs: ['X', 'Z'],
          description: 'Çıkış = (X AND (NOT Z))',
          evaluate: (v) => (v['X'] ?? false) && !(v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U251',
          difficulty: LogicDifficulty.medium,
          inputs: ['Q', 'R'],
          description: 'Çıkış = (Q XOR R)',
          evaluate: (v) => _xor2(v['Q'] ?? false, v['R'] ?? false)),
      LogicPuzzle(
          id: 'U252',
          difficulty: LogicDifficulty.easy,
          inputs: ['M', 'N'],
          description: 'Çıkış = (M OR NOT N)',
          evaluate: (v) => (v['M'] ?? false) || !(v['N'] ?? false)),
      LogicPuzzle(
          id: 'U253',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) OR (NOT C))',
          evaluate: (v) => ((v['A'] ?? false) && (v['B'] ?? false)) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U254',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = (X OR (Y XOR Z))',
          evaluate: (v) => (v['X'] ?? false) || (_xor2(v['Y'] ?? false, v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U255',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((NOT P AND Q) OR R)',
          evaluate: (v) => ((!(v['P'] ?? false) && (v['Q'] ?? false)) || (v['R'] ?? false))),
      LogicPuzzle(
          id: 'U256',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M NAND (N AND O))',
          evaluate: (v) => !((v['M'] ?? false) && ((v['N'] ?? false) && (v['O'] ?? false)))),
      LogicPuzzle(
          id: 'U257',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A XNOR B)',
          evaluate: (v) => _xnor2(v['A'] ?? false, v['B'] ?? false)),
      LogicPuzzle(
          id: 'U258',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X OR Y) AND NOT Z)',
          evaluate: (v) => ((v['X'] ?? false) || (v['Y'] ?? false)) && !(v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U259',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q'],
          description: 'Çıkış = (P NOR Q)',
          evaluate: (v) => !((v['P'] ?? false) || (v['Q'] ?? false))),
      LogicPuzzle(
          id: 'U260',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'O', 'N'],
          description: 'Çıkış = ((M XOR O) OR N)',
          evaluate: (v) => (_xor2(v['M'] ?? false, v['O'] ?? false)) || (v['N'] ?? false)),
      LogicPuzzle(
          id: 'U261',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'B'],
          description: 'Çıkış = (A AND (NOT B))',
          evaluate: (v) => (v['A'] ?? false) && !(v['B'] ?? false)),
      LogicPuzzle(
          id: 'U262',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X AND Y) OR Z)',
          evaluate: (v) => ((v['X'] ?? false) && (v['Y'] ?? false)) || (v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U263',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'R'],
          description: 'Çıkış = (NOT (P OR R))',
          evaluate: (v) => !((v['P'] ?? false) || (v['R'] ?? false))),
      LogicPuzzle(
          id: 'U264',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M OR (N AND O))',
          evaluate: (v) => (v['M'] ?? false) || ((v['N'] ?? false) && (v['O'] ?? false))),
      LogicPuzzle(
          id: 'U265',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A NAND (B OR C))',
          evaluate: (v) => !((v['A'] ?? false) && ((v['B'] ?? false) || (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U266',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X XOR Y) OR NOT Z)',
          evaluate: (v) => (_xor2(v['X'] ?? false, v['Y'] ?? false)) || !(v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U267',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = (P OR (Q AND NOT R))',
          evaluate: (v) => (v['P'] ?? false) || ((v['Q'] ?? false) && !(v['R'] ?? false))),
      LogicPuzzle(
          id: 'U268',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M AND N) OR NOT O)',
          evaluate: (v) => ((v['M'] ?? false) && (v['N'] ?? false)) || !(v['O'] ?? false)),
      LogicPuzzle(
          id: 'U269',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A OR B) NAND C)',
          evaluate: (v) => !(((v['A'] ?? false) || (v['B'] ?? false)) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U270',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Z'],
          description: 'Çıkış = (X XNOR Z)',
          evaluate: (v) => _xnor2(v['X'] ?? false, v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U271',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((NOT P OR Q) AND R)',
          evaluate: (v) => ((!(v['P'] ?? false) || (v['Q'] ?? false)) && (v['R'] ?? false))),
      LogicPuzzle(
          id: 'U272',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'O'],
          description: 'Çıkış = (M NOR O)',
          evaluate: (v) => !((v['M'] ?? false) || (v['O'] ?? false))),
      LogicPuzzle(
          id: 'U273',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C', 'B'],
          description: 'Çıkış = ((A AND C) OR B)',
          evaluate: (v) => ((v['A'] ?? false) && (v['C'] ?? false)) || (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U274',
          difficulty: LogicDifficulty.easy,
          inputs: ['X', 'Y'],
          description: 'Çıkış = (X OR NOT Y)',
          evaluate: (v) => (v['X'] ?? false) || !(v['Y'] ?? false)),
      LogicPuzzle(
          id: 'U275',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = (P XOR (Q OR R))',
          evaluate: (v) => _xor2(v['P'] ?? false, (v['Q'] ?? false) || (v['R'] ?? false))),
      LogicPuzzle(
          id: 'U276',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'O', 'N'],
          description: 'Çıkış = ((M AND O) NAND N)',
          evaluate: (v) => !(((v['M'] ?? false) && (v['O'] ?? false)) && (v['N'] ?? false))),
      LogicPuzzle(
          id: 'U277',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B'],
          description: 'Çıkış = (NOT (A AND B))',
          evaluate: (v) => !((v['A'] ?? false) && (v['B'] ?? false))),
      LogicPuzzle(
          id: 'U278',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X OR Y) XOR Z)',
          evaluate: (v) => _xor2(((v['X'] ?? false) || (v['Y'] ?? false)), (v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U279',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'R', 'Q'],
          description: 'Çıkış = ((P AND R) OR Q)',
          evaluate: (v) => ((v['P'] ?? false) && (v['R'] ?? false)) || (v['Q'] ?? false)),
      LogicPuzzle(
          id: 'U280',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M XOR N) AND NOT O)',
          evaluate: (v) => (_xor2(v['M'] ?? false, v['N'] ?? false)) && !(v['O'] ?? false)),
      LogicPuzzle(
          id: 'U281',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A OR (NOT C))',
          evaluate: (v) => (v['A'] ?? false) || !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U282',
          difficulty: LogicDifficulty.hard,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = (X NAND (Y AND Z))',
          evaluate: (v) => !((v['X'] ?? false) && ((v['Y'] ?? false) && (v['Z'] ?? false)))),
      LogicPuzzle(
          id: 'U283',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q'],
          description: 'Çıkış = (P XNOR Q)',
          evaluate: (v) => _xnor2(v['P'] ?? false, v['Q'] ?? false)),
      LogicPuzzle(
          id: 'U284',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M OR N) AND (NOT O))',
          evaluate: (v) => ((v['M'] ?? false) || (v['N'] ?? false)) && !(v['O'] ?? false)),
      LogicPuzzle(
          id: 'U285',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A AND B) XOR (C))',
          evaluate: (v) => _xor2(((v['A'] ?? false) && (v['B'] ?? false)), (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U331',
          difficulty: LogicDifficulty.easy,
          inputs: ['A', 'C'],
          description: 'Çıkış = (A AND NOT C)',
          evaluate: (v) => (v['A'] ?? false) && !(v['C'] ?? false)),
      LogicPuzzle(
          id: 'U332',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = (X OR (Y AND NOT Z))',
          evaluate: (v) => (v['X'] ?? false) || ((v['Y'] ?? false) && !(v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U333',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q'],
          description: 'Çıkış = (P XOR (NOT Q))',
          evaluate: (v) => _xor2(v['P'] ?? false, !(v['Q'] ?? false))),
      LogicPuzzle(
          id: 'U334',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M OR (N AND O))',
          evaluate: (v) => (v['M'] ?? false) || ((v['N'] ?? false) && (v['O'] ?? false))),
      LogicPuzzle(
          id: 'U335',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (NOT (A OR C))',
          evaluate: (v) => !((v['A'] ?? false) || (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U336',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = (X AND (NOT Y OR Z))',
          evaluate: (v) => (v['X'] ?? false) && (!(v['Y'] ?? false) || (v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U337',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((P OR R) AND NOT Q)',
          evaluate: (v) => ((v['P'] ?? false) || (v['R'] ?? false)) && !(v['Q'] ?? false)),
      LogicPuzzle(
          id: 'U338',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M XOR (N OR NOT O))',
          evaluate: (v) => _xor2(v['M'] ?? false, (v['N'] ?? false) || !(v['O'] ?? false))),
      LogicPuzzle(
          id: 'U339',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = ((A NAND B) OR C)',
          evaluate: (v) => (!((v['A'] ?? false) && (v['B'] ?? false))) || (v['C'] ?? false)),
      LogicPuzzle(
          id: 'U340',
          difficulty: LogicDifficulty.hard,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = (X NOR (Y AND Z))',
          evaluate: (v) => !((v['X'] ?? false) || ((v['Y'] ?? false) && (v['Z'] ?? false)))),
      LogicPuzzle(
          id: 'U341',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((NOT P AND R) OR Q)',
          evaluate: (v) => ((!(v['P'] ?? false) && (v['R'] ?? false)) || (v['Q'] ?? false))),
      LogicPuzzle(
          id: 'U342',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M AND (N NOR O))',
          evaluate: (v) => (v['M'] ?? false) && !((v['N'] ?? false) || (v['O'] ?? false))),
      LogicPuzzle(
          id: 'U343',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR (B NAND C))',
          evaluate: (v) => (v['A'] ?? false) || (!((v['B'] ?? false) && (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U344',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Z', 'Y'],
          description: 'Çıkış = ((X XOR NOT Z) AND Y)',
          evaluate: (v) => _xor2(v['X'] ?? false, !(v['Z'] ?? false)) && (v['Y'] ?? false)),
      LogicPuzzle(
          id: 'U345',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = (P OR (NOT Q AND R))',
          evaluate: (v) => (v['P'] ?? false) || ((!(v['Q'] ?? false)) && (v['R'] ?? false))),
      LogicPuzzle(
          id: 'U346',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M NAND N) OR NOT O)',
          evaluate: (v) => (!((v['M'] ?? false) && (v['N'] ?? false))) || !(v['O'] ?? false)),
      LogicPuzzle(
          id: 'U347',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A XOR (B AND NOT C))',
          evaluate: (v) => _xor2(v['A'] ?? false, ((v['B'] ?? false) && !(v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U348',
          difficulty: LogicDifficulty.hard,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X OR NOT Y) NAND Z)',
          evaluate: (v) => !(((v['X'] ?? false) || !(v['Y'] ?? false)) && (v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U349',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((P AND Q) OR (NOT R))',
          evaluate: (v) => ((v['P'] ?? false) && (v['Q'] ?? false)) || !(v['R'] ?? false)),
      LogicPuzzle(
          id: 'U350',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'O', 'N'],
          description: 'Çıkış = ((M OR O) XNOR N)',
          evaluate: (v) => _xnor2(((v['M'] ?? false) || (v['O'] ?? false)), (v['N'] ?? false))),
      LogicPuzzle(
          id: 'U351',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C'],
          description: 'Çıkış = (NOT (A AND C))',
          evaluate: (v) => !((v['A'] ?? false) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U352',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Z', 'Y'],
          description: 'Çıkış = ((X OR Z) AND NOT Y)',
          evaluate: (v) => (((v['X'] ?? false) || (v['Z'] ?? false)) && !(v['Y'] ?? false))),
      LogicPuzzle(
          id: 'U353',
          difficulty: LogicDifficulty.hard,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = (P NOR (Q XOR R))',
          evaluate: (v) => !((v['P'] ?? false) || (_xor2(v['Q'] ?? false, v['R'] ?? false)))),
      LogicPuzzle(
          id: 'U354',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M AND NOT N) OR (O))',
          evaluate: (v) => ((v['M'] ?? false) && !(v['N'] ?? false)) || (v['O'] ?? false)),
      LogicPuzzle(
          id: 'U355',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A XNOR (B OR NOT C))',
          evaluate: (v) => _xnor2(v['A'] ?? false, ((v['B'] ?? false) || !(v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U356',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X NAND Y) AND Z)',
          evaluate: (v) => (!((v['X'] ?? false) && (v['Y'] ?? false))) && (v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U357',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((NOT P OR Q) XOR R)',
          evaluate: (v) => _xor2((!(v['P'] ?? false) || (v['Q'] ?? false)), (v['R'] ?? false))),
      LogicPuzzle(
          id: 'U358',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = ((M OR N) AND (NOT O))',
          evaluate: (v) => ((v['M'] ?? false) || (v['N'] ?? false)) && !(v['O'] ?? false)),
      LogicPuzzle(
          id: 'U359',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A NOR (B AND C))',
          evaluate: (v) => !((v['A'] ?? false) || ((v['B'] ?? false) && (v['C'] ?? false)))),
      LogicPuzzle(
          id: 'U360',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X OR Y) XOR NOT Z)',
          evaluate: (v) => _xor2(((v['X'] ?? false) || (v['Y'] ?? false)), !(v['Z'] ?? false))),
      LogicPuzzle(
          id: 'U361',
          difficulty: LogicDifficulty.hard,
          inputs: ['P', 'R', 'Q'],
          description: 'Çıkış = ((P AND R) NAND Q)',
          evaluate: (v) => !(((v['P'] ?? false) && (v['R'] ?? false)) && (v['Q'] ?? false))),
      LogicPuzzle(
          id: 'U362',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M OR (N XOR NOT O))',
          evaluate: (v) => (v['M'] ?? false) || (_xor2(v['N'] ?? false, !(v['O'] ?? false)))),
      LogicPuzzle(
          id: 'U363',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'C', 'B'],
          description: 'Çıkış = ((A XOR C) AND B)',
          evaluate: (v) => _xor2(v['A'] ?? false, v['C'] ?? false) && (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U364',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Z', 'Y'],
          description: 'Çıkış = (X AND (NOT Z OR Y))',
          evaluate: (v) => (v['X'] ?? false) && (!(v['Z'] ?? false) || (v['Y'] ?? false))),
      LogicPuzzle(
          id: 'U365',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = ((P NAND Q) OR (NOT R))',
          evaluate: (v) => (!((v['P'] ?? false) && (v['Q'] ?? false))) || !(v['R'] ?? false)),
      LogicPuzzle(
          id: 'U366',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M XNOR (N AND O))',
          evaluate: (v) => _xnor2(v['M'] ?? false, ((v['N'] ?? false) && (v['O'] ?? false)))),
      LogicPuzzle(
          id: 'U367',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR (NOT B AND C))',
          evaluate: (v) => (v['A'] ?? false) || ((!(v['B'] ?? false)) && (v['C'] ?? false))),
      LogicPuzzle(
          id: 'U368',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X XOR Y) OR NOT Z)',
          evaluate: (v) => (_xor2(v['X'] ?? false, v['Y'] ?? false)) || !(v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U369',
          difficulty: LogicDifficulty.hard,
          inputs: ['P', 'R', 'Q'],
          description: 'Çıkış = ((P OR R) NAND (NOT Q))',
          evaluate: (v) => !(((v['P'] ?? false) || (v['R'] ?? false)) && !(v['Q'] ?? false))),
      LogicPuzzle(
          id: 'U370',
          difficulty: LogicDifficulty.hard,
          inputs: ['M', 'N', 'O'],
          description: 'Çıkış = (M NOR (N OR NOT O))',
          evaluate: (v) => !((v['M'] ?? false) || (v['N'] ?? false) || !(v['O'] ?? false))),
      LogicPuzzle(
          id: 'U371',
          difficulty: LogicDifficulty.hard,
          inputs: ['A', 'C', 'B'],
          description: 'Çıkış = ((A NAND C) AND B)',
          evaluate: (v) => (!((v['A'] ?? false) && (v['C'] ?? false))) && (v['B'] ?? false)),
      LogicPuzzle(
          id: 'U372',
          difficulty: LogicDifficulty.medium,
          inputs: ['X', 'Y', 'Z'],
          description: 'Çıkış = ((X OR Y) AND (NOT Z))',
          evaluate: (v) => ((v['X'] ?? false) || (v['Y'] ?? false)) && !(v['Z'] ?? false)),
      LogicPuzzle(
          id: 'U373',
          difficulty: LogicDifficulty.medium,
          inputs: ['P', 'Q', 'R'],
          description: 'Çıkış = (P XOR (Q OR NOT R))',
          evaluate: (v) => _xor2(v['P'] ?? false, ((v['Q'] ?? false) || !(v['R'] ?? false)))),
      LogicPuzzle(
          id: 'U374',
          difficulty: LogicDifficulty.medium,
          inputs: ['M', 'O', 'N'],
          description: 'Çıkış = ((M AND O) OR (NOT N))',
          evaluate: (v) => ((v['M'] ?? false) && (v['O'] ?? false)) || !(v['N'] ?? false)),
      LogicPuzzle(
          id: 'U375',
          difficulty: LogicDifficulty.medium,
          inputs: ['A', 'B', 'C'],
          description: 'Çıkış = (A OR (B XNOR C))',
          evaluate: (v) => (v['A'] ?? false) || _xnor2(v['B'] ?? false, v['C'] ?? false)),
    ];
  }

  LogicDifficulty get _currentDifficulty {
    if (_roundInLevel <= 3) return LogicDifficulty.easy;
    if (_roundInLevel == 4) return LogicDifficulty.medium;
    return LogicDifficulty.hard; // _roundInLevel == 5
  }

  int _pointsForDifficulty(LogicDifficulty d) {
    switch (d) {
      case LogicDifficulty.easy:
        return 50;
      case LogicDifficulty.medium:
        return 100;
      case LogicDifficulty.hard:
        return 150;
    }
  }

  void _loadPuzzleState() {
    final tierList = _shuffledByTier[_currentDifficulty] ?? [];
    if (tierList.isEmpty) {
      _prepareSessionOrder();
    }
    // Select random puzzle with advanced rarity constraints
    LogicPuzzle pickRandom() => (_shuffledByTier[_currentDifficulty]!..shuffle(_random)).first;
    LogicPuzzle p = pickRandom();
    if (_currentDifficulty == LogicDifficulty.easy && _isAdvancedGate(p)) {
      // avoid advanced on easy
      final nonAdv = (_shuffledByTier[_currentDifficulty] ?? []).where((e) => !_isAdvancedGate(e)).toList();
      if (nonAdv.isNotEmpty) {
        nonAdv.shuffle(_random);
        p = nonAdv.first;
      }
    }
    if (_currentDifficulty == LogicDifficulty.medium) {
      final bool allowAdv = _random.nextDouble() < 0.03; // 3%
      if (!allowAdv && _isAdvancedGate(p)) {
        final nonAdv = (_shuffledByTier[_currentDifficulty] ?? []).where((e) => !_isAdvancedGate(e)).toList();
        if (nonAdv.isNotEmpty) {
          nonAdv.shuffle(_random);
          p = nonAdv.first;
        }
      }
    }
    if (_currentDifficulty == LogicDifficulty.hard) {
      final bool allowAdv = _random.nextDouble() < 0.08; // 8%
      if (!allowAdv && _isAdvancedGate(p)) {
        final nonAdv = (_shuffledByTier[_currentDifficulty] ?? []).where((e) => !_isAdvancedGate(e)).toList();
        if (nonAdv.isNotEmpty) {
          nonAdv.shuffle(_random);
          p = nonAdv.first;
        }
      }
    }
    // Avoid repeats within a 5-question session when possible
    final pool = (_shuffledByTier[_currentDifficulty] ?? []).where((e) => !_usedPuzzleIds.contains(e.id)).toList();
    if (pool.isNotEmpty) {
      pool.shuffle(_random);
      p = pool.first;
    }
    _activePuzzle = p;
    _usedPuzzleIds.add(p.id);
    _values = {for (final k in p.inputs) k: false};
    _isTimed = _currentDifficulty == LogicDifficulty.hard;
    _timeLeft = _isTimed ? 30 : 0;
    _ticker?.dispose();
    if (_isTimed) {
      _ticker = createTicker((elapsed) {
        final secs = 30 - elapsed.inSeconds;
        if (mounted) {
          setState(() => _timeLeft = secs.clamp(0, 30));
          if (_timeLeft <= 0) {
            _ticker?.stop();
            _showFailDialog(timeout: true);
          }
        }
      })
        ..start();
    }
  }

  void _startGame() {
    setState(() => _showInfo = false);
  }

  void _toggleInput(String key) {
    setState(() => _values[key] = !(_values[key] ?? false));
  }

  LogicPuzzle get _currentPuzzle {
    return _activePuzzle ?? (_shuffledByTier[_currentDifficulty]?.first ?? _puzzles.first);
  }

  void _submit() {
    final ok = _currentPuzzle.evaluate(_values);
    if (ok) {
      final pts = _pointsForDifficulty(_currentDifficulty);
      _score += pts;
      _ticker?.stop();
      _showSuccessDialog(points: pts);
    } else {
      _ticker?.stop();
      _showFailDialog();
    }
  }

  void _showSuccessDialog({required int points}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚡ Enerji Ulaştı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye: $_level'),
            Text('Kazanılan Puan: +$points'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_roundInLevel >= 5) {
                _showEndDialog();
                return;
              }
              setState(() {
                _roundInLevel++;
              });
              _loadPuzzleState();
            },
            child: const Text('Sonraki Devre'),
          ),
        ],
      ),
    );
  }

  void _showFailDialog({bool timeout = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(timeout ? '⏰ Süre Doldu' : '❌ Enerji Ulaşmadı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye: $_level'),
            Text('Skor: $_score'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Ana Menüye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _values = {for (final k in _currentPuzzle.inputs) k: false};
              });
              _loadPuzzleState();
            },
            child: const Text('Yeniden Dene'),
          ),
        ],
      ),
    );
  }

  void _showEndDialog() async {
    // Güncel profili Firestore'dan çek
    UserProfile? currentProfile;
    try {
      currentProfile = await UserService.getCurrentUserProfile();
    } catch (e) {
      print('Güncel profil çekme hatası: $e');
      currentProfile = widget.profile;
    }

    final baseProfile = currentProfile ?? widget.profile;
    final updated = baseProfile.copyWith(
      points: baseProfile.points + _score,
      totalGamePoints: (baseProfile.totalGamePoints ?? 0) + _score,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏁 Tüm Devreler Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Skor: $_score'),
            const SizedBox(height: 8),
            Text('Kayıtlı Oyun Puanı: ${(updated.totalGamePoints ?? 0)}'),
            const SizedBox(height: 8),
            const Text('Günün en hızlısı bonusu ileride eklenecek.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveProfile(updated).then((_) {
                Navigator.pop(context, updated);
              });
            },
            child: const Text('Ana Menüye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _level = 1;
                _score = 0;
                _roundInLevel = 1;
                _usedPuzzleIds.clear();
              });
              _prepareSessionOrder();
              _loadPuzzleState();
            },
            child: const Text('Yeniden Oyna'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile(UserProfile profile) async {
    try {
      print('🎮 LOGIC GATES BİTTİ - Puan kaydediliyor...');
      print('   ✨ Kazanılan Puan: $_score');
      print('   📊 Yeni Oyun Puanı: ${profile.totalGamePoints ?? 0}');

      await UserService.updateCurrentUserProfile(profile);
      print('   ✅ Firestore\'a kaydedildi!');

      await UserService.logActivity(
        activityType: 'logic_gates_completed',
        data: {
          'score': _score,
          'level': _level,
        },
      );
    } catch (e) {
      print('❌ Logic Gates profil kaydetme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showInfo ? _buildInfoPage() : _buildGameBody(),
    );
  }

  Widget _buildInfoPage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade600,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '🔌 Mantık Kapıları',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Kurallar:\n\n• Giriş anahtarlarını A/B/C aç-kapat.\n• Devredeki kapılar çıktıyı belirler.\n• Amaç: enerjiyi çıkışa ulaştır (çıktı = true).\n• Zor seviyede süre sınırlıdır.\n\nKapılar:\n• AND: Her iki giriş de açık olursa çıkış açık.\n• OR: Girişlerden en az biri açık olursa çıkış açık.\n• NOT: Giriş terslenir (açık → kapalı, kapalı → açık).\n• XOR: Girişler farklıysa çıkış açık (biri açık biri kapalı).\n• NAND: AND\'in tersi; her iki giriş de açıkken çıkış kapalı, diğer tüm durumlarda açık.\n• XNOR: XOR\'un tersi; girişler aynıysa çıkış açık.\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Puanlama:\n\n• Kolay: +50 | Orta: +100 | Zor: +150\n',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Başla', style: TextStyle(fontSize: 22)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameBody() {
    final puzzle = _currentPuzzle;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade600,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Oturum Skoru: $_score',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('Kayıtlı Oyun Puanı: ${(widget.profile.totalGamePoints ?? 0)}',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Seviye: $_level',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Skor: $_score',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (_isTimed)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child:
                              Text('Süre: $_timeLeft sn', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        puzzle.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._getGateDefinitionsFor(puzzle.description)
                          .map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '• $line',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: puzzle.inputs
                            .map(
                              (k) => FilterChip(
                                selected: _values[k] ?? false,
                                onSelected: (_) => _toggleInput(k),
                                label: Text('$k: ${(_values[k] ?? false) ? 'Açık' : 'Kapalı'}'),
                                selectedColor: Colors.lightGreen,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.bolt),
                          label: const Text('Enerjiyi Gönder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueGrey,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              '🔌 Mantık Kapıları',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
