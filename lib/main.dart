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
  String status;
  DateTime dateAdded;

  Game({
    required this.title,
    required this.developer,
    required this.rating,
    required this.notes,
    required this.status,
    required this.dateAdded,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'developer': developer,
    'rating': rating,
    'notes': notes,
    'status': status,
    'dateAdded': dateAdded.toIso8601String(),
  };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
    title: json['title'],
    developer: json['developer'],
    rating: json['rating'].toDouble(),
    notes: json['notes'],
    status: json['status'] ?? 'Chystám se',
    dateAdded: DateTime.parse(
      json['dateAdded'] ?? DateTime.now().toIso8601String(),
    ),
  );
}

Color getRatingColor(double rating) {
  if (rating >= 9) return Colors.green.shade900;
  if (rating >= 7) return Colors.green.shade500;
  if (rating >= 5) return Colors.orange.shade500;
  if (rating >= 3) return Colors.deepOrange.shade400;
  return Colors.red.shade700;
}

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  List<Game> _allGames = [];
  List<Game> _filteredGames = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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
          _allGames = jsonData.map((item) => Game.fromJson(item)).toList();
          _filteredGames = _allGames;
        });
      }
    } catch (e) {
      debugPrint("Chyba při načítání: $e");
    }
  }

  Future<void> _saveGames() async {
    final String encodedData = json.encode(
      _allGames.map((g) => g.toJson()).toList(),
    );
    await _localFile.writeAsString(encodedData);
  }

  void _filterGames(String query) {
    setState(() {
      _filteredGames = _allGames
          .where(
            (game) => game.title.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  void _sortGames(String criteria) {
    setState(() {
      if (criteria == 'rating') {
        _allGames.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (criteria == 'title') {
        _allGames.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      } else if (criteria == 'date') {
        _allGames.sort(
          (a, b) => b.dateAdded.compareTo(a.dateAdded),
        );
      }
      _filteredGames = List.from(_allGames);
    });
    _saveGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Hledat hru...',
                  border: InputBorder.none,
                ),
                onChanged: _filterGames,
              )
            : const Text('Moje Herní Knihovna'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredGames = _allGames;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: _sortGames,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rating',
                child: Text('Seřadit podle hodnocení'),
              ),
              const PopupMenuItem(
                value: 'title',
                child: Text('Seřadit abecedně'),
              ),
              const PopupMenuItem(
                value: 'date',
                child: Text('Seřadit podle data přidání'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: _filteredGames.isEmpty
          ? const Center(child: Text('Žádné hry nenalezeny.'))
          : ListView.builder(
              itemCount: _filteredGames.length,
              itemBuilder: (context, index) {
                final game = _filteredGames[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: getRatingColor(game.rating),
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
                    subtitle: Text(
                      '${game.developer} • ${game.status}\n${game.notes}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blueGrey,
                            size: 20,
                          ),
                          onPressed: () => _navigateToForm(
                            game: game,
                            index: _allGames.indexOf(game),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => _confirmDelete(
                            _allGames.indexOf(game),
                            game.title,
                          ),
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

  Future<void> _navigateToForm({Game? game, int? index}) async {
    final result = await Navigator.push<Game>(
      context,
      MaterialPageRoute(builder: (context) => GameFormScreen(game: game)),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _allGames[index] = result;
        } else {
          _allGames.add(result);
        }
        _filteredGames = _allGames;
      });
      _saveGames();
    }
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
              setState(() {
                _allGames.removeAt(index);
                _filteredGames = _allGames;
              });
              _saveGames();
              Navigator.pop(context);
            },
            child: const Text('Smazat', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

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
  late String _status;
  final List<String> _statusOptions = [
    'Chystám se',
    'Hraju',
    'Dohráno',
    'Odloženo',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.game?.title ?? '');
    _devController = TextEditingController(text: widget.game?.developer ?? '');
    _notesController = TextEditingController(text: widget.game?.notes ?? '');
    _rating = widget.game?.rating ?? 5.0;
    _status = widget.game?.status ?? 'Chystám se';
  }

  @override
  Widget build(BuildContext context) {
    final Color currentRatingColor = getRatingColor(_rating);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game == null ? 'Nová hra' : 'Upravit hru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Název hry'),
            ),
            TextField(
              controller: _devController,
              decoration: const InputDecoration(labelText: 'Vývojář'),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Stav hraní'),
              items: _statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _status = val!),
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Poznámky'),
            ),
            const SizedBox(height: 30),
            Text(
              'Hodnocení: ${_rating.toInt()}/10',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: currentRatingColor,
              ),
            ),
            Slider(
              value: _rating,
              min: 0,
              max: 10,
              activeColor: currentRatingColor,
              divisions: 10,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 50),
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
                      status: _status,
                      dateAdded:
                          widget.game?.dateAdded ?? DateTime.now(),
                    ),
                  );
                }
              },
              child: const Text('Uložit hru'),
            ),
          ],
        ),
      ),
    );
  }
}