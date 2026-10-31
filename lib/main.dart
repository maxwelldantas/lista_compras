import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minhas Compras',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- MODELOS DE DADOS ---

class ShoppingItem {
  final String name;
  final double price;
  final int quantity;

  ShoppingItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'quantity': quantity,
  };
  factory ShoppingItem.fromMap(Map<String, dynamic> map) => ShoppingItem(
    name: map['name'],
    price: (map['price'] as num).toDouble(),
    quantity: map['quantity'],
  );
}

class MarketList {
  final int? id;
  final String marketName;
  final String date;
  final List<ShoppingItem> items;

  MarketList({
    this.id,
    required this.marketName,
    required this.date,
    required this.items,
  });

  double get totalPrice =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'marketName': marketName,
    'date': date,
    'itemsJson': json.encode(items.map((i) => i.toMap()).toList()),
  };

  factory MarketList.fromMap(Map<String, dynamic> map) {
    final List<dynamic> decoded = json.decode(map['itemsJson']);
    return MarketList(
      id: map['id'],
      marketName: map['marketName'],
      date: map['date'],
      items: decoded.map((i) => ShoppingItem.fromMap(i)).toList(),
    );
  }
}

// --- GERENCIADOR DO BANCO DE DADOS SQLITE ---

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'shopping_lists';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'shopping.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          marketName TEXT,
          date TEXT,
          itemsJson TEXT
        )
      ''');
      },
    );
  }

  static Future<int> insertList(MarketList list) async {
    final db = await database;
    return await db.insert(tableName, list.toMap());
  }

  static Future<List<MarketList>> getAllLists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'id DESC',
    );
    return maps.map((map) => MarketList.fromMap(map)).toList();
  }
}

// --- TELA PRINCIPAL ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MarketList> _allLists = [];

  @override
  void initState() {
    super.initState();
    _refreshLists();
  }

  Future<void> _refreshLists() async {
    final data = await DatabaseHelper.getAllLists();
    setState(() {
      _allLists = data;
    });
  }

  Map<String, List<MarketList>> _getGroupedLists() {
    Map<String, List<MarketList>> grouped = {};
    for (var list in _allLists) {
      grouped.putIfAbsent(list.date, () => []).add(list);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedLists = _getGroupedLists();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Compras 🛒'),
        backgroundColor: Colors.green.shade100,
      ),
      body: _allLists.isEmpty
          ? const Center(child: Text('Nenhuma lista salva no banco SQLite.'))
          : ListView.builder(
              itemCount: groupedLists.keys.length,
              itemBuilder: (context, index) {
                String date = groupedLists.keys.elementAt(index);
                List<MarketList> listsOnDate = groupedLists[date]!;

                return ExpansionTile(
                  title: Text(
                    '📅 Compras de: $date',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  initiallyExpanded: true,
                  children: listsOnDate.map((list) {
                    return ListTile(
                      title: Text(
                        list.marketName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${list.items.length} produtos adicionados',
                      ),
                      trailing: Text(
                        'R\$ ${list.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ListDetailsScreen(marketList: list),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewListScreen()),
          );
          if (result != null && result is MarketList) {
            await DatabaseHelper.insertList(result);
            _refreshLists();
          }
        },
        label: const Text('Nova lista'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green.shade200,
      ),
    );
  }
}

// --- TELA DE CADASTRO DE NOVA LISTA ---

class NewListScreen extends StatefulWidget {
  const NewListScreen({super.key});

  @override
  State<NewListScreen> createState() => _NewListScreenState();
}

class _NewListScreenState extends State<NewListScreen> {
  final TextEditingController _marketController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  DateTime _selectedDate = DateTime.now();
  final List<ShoppingItem> _itemsToAdd = [];

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double get _currentSubtotal =>
      _itemsToAdd.fold(0, (sum, item) => sum + (item.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar nova lista')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _marketController,
              decoration: const InputDecoration(
                labelText: 'Nome do estabelecimento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Data selecionada: ${_formatDate(_selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Alterar data'),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'Adicionar produto à lista:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Produto',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Preço (R\$)',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Qtd',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_box,
                    color: Colors.green,
                    size: 36,
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final price =
                        double.tryParse(
                          _priceController.text.replaceAll(',', '.'),
                        ) ??
                        0.0;
                    final qty = int.tryParse(_quantityController.text) ?? 1;

                    if (name.isNotEmpty) {
                      setState(() {
                        _itemsToAdd.add(
                          ShoppingItem(name: name, price: price, quantity: qty),
                        );
                        _nameController.clear();
                        _priceController.clear();
                        _quantityController.text = '1';
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _itemsToAdd.length,
                itemBuilder: (context, index) {
                  final item = _itemsToAdd[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        'R\$ ${item.price.toStringAsFixed(2)} x ${item.quantity}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'R\$ ${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _itemsToAdd.removeAt(index)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              color: Colors.green.shade50,
              child: Text(
                'Soma total dos produtos: R\$ ${_currentSubtotal.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade200,
                ),
                onPressed:
                    (_marketController.text.trim().isEmpty ||
                        _itemsToAdd.isEmpty)
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                          MarketList(
                            marketName: _marketController.text.trim(),
                            date: _formatDate(_selectedDate),
                            items: _itemsToAdd,
                          ),
                        );
                      },
                child: const Text(
                  'Salvar lista',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TELA DE DETALHES ---
class ListDetailsScreen extends StatelessWidget {
  final MarketList marketList;
  const ListDetailsScreen({super.key, required this.marketList});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              marketList.marketName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Data: ${marketList.date}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: marketList.items.length,
              itemBuilder: (context, index) {
                final item = marketList.items[index];
                return ListTile(
                  leading: const Icon(
                    Icons.shopping_basket,
                    color: Colors.green,
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Preço: R\$ ${item.price.toStringAsFixed(2)}  |  Qtd: ${item.quantity}',
                  ),
                  trailing: Text(
                    'R\$ ${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VALOR TOTAL DA LISTA:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'R\$ ${marketList.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
