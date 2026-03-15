import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const GameTrackerApp());
}

class GameTrackerApp extends StatelessWidget {
  const GameTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 110, 130, 139),
        ),
        useMaterial3: true,
      ),
      home: const GameListScreen(),
    );
  }
}

class Game {
  String title;
  String developer;
  double rating;
  String notes;

  Game({
    required this.title,
    required this.developer,
    required this.rating,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'developer': developer,
    'rating': rating,
    'notes': notes,
  };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
    title: json['title'],
    developer: json['developer'],
    rating: json['rating'].toDouble(),
    notes: json['notes'],
  );
}

// Hlavní obrazovka
class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  List<Game> _games = [];

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  File get _localFile => File('games_data.json');

  Future<void> _loadGames() async {
    try {
      if (await _localFile.exists()) {
        final content = await _localFile.readAsString();
        final List<dynamic> jsonData = json.decode(content);
        setState(() {
          _games = jsonData.map((item) => Game.fromJson(item)).toList();
        });
      }
    } catch (e) {
      debugPrint("Chyba při načítání: $e");
    }
  }

  Future<void> _saveGames() async {
    final String encodedData = json.encode(
      _games.map((g) => g.toJson()).toList(),
    );
    await _localFile.writeAsString(encodedData);
  }

  void _deleteGame(int index) {
    setState(() {
      _games.removeAt(index);
    });
    _saveGames();
  }

  // Změna barev při rating
  Color _getRatingColor(double rating) {
    if (rating >= 8) return Colors.green.shade600;
    if (rating >= 5) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Future<void> _navigateToForm({Game? game, int? index}) async {
    final result = await Navigator.push<Game>(
      context,
      MaterialPageRoute(builder: (context) => GameFormScreen(game: game)),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _games[index] = result;
        } else {
          _games.add(result);
        }
      });
      _saveGames();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje Herní Knihovna'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _games.isEmpty
          ? const Center(child: Text('Zatím tu žádné hry nejsou.'))
          : ListView.builder(
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRatingColor(game.rating),
                      child: Text(
                        game.rating.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      game.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${game.developer}\n${game.notes}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                          onPressed: () =>
                              _navigateToForm(game: game, index: index),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDelete(index, game.title),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(int index, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat hru?'),
        content: Text('Opravdu chcete odstranit hru $title?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () {
              _deleteGame(index);
              Navigator.pop(context);
            },
            child: const Text('Smazat', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Formulář
class GameFormScreen extends StatefulWidget {
  final Game? game;
  const GameFormScreen({super.key, this.game});

  @override
  State<GameFormScreen> createState() => _GameFormScreenState();
}

class _GameFormScreenState extends State<GameFormScreen> {
  late TextEditingController _titleController;
  late TextEditingController _devController;
  late TextEditingController _notesController;
  late double _rating;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.game?.title ?? '');
    _devController = TextEditingController(text: widget.game?.developer ?? '');
    _notesController = TextEditingController(text: widget.game?.notes ?? '');
    _rating = widget.game?.rating ?? 5.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game == null ? 'Nová hra' : 'Upravit hru'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Název'),
            ),
            TextField(
              controller: _devController,
              decoration: const InputDecoration(labelText: 'Vývojář'),
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Poznámky'),
            ),
            const SizedBox(height: 20),
            Text(
              'Hodnocení: ${_rating.toInt()}/10',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _rating >= 8
                    ? Colors.green.shade700
                    : (_rating >= 5
                          ? Colors.orange.shade700
                          : Colors.red.shade700),
              ),
            ),
            Slider(
              value: _rating,
              min: 0,
              max: 10,
              activeColor: _rating >= 8
                  ? Colors.green
                  : (_rating >= 5 ? Colors.orange : Colors.red),
              divisions: 10,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  Navigator.pop(
                    context,
                    Game(
                      title: _titleController.text,
                      developer: _devController.text,
                      rating: _rating,
                      notes: _notesController.text,
                    ),
                  );
                }
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }
}
