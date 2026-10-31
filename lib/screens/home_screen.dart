import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/market_list.dart';
import 'new_list_screen.dart';
import 'list_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MarketList> _allLists = [];
  final _currencyFormatPtBr = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

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
          ? const Center(child: Text('Nenhuma lista salva'))
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      // 1. O Título exibe apenas o Nome do estabelecimento de forma limpa
                      title: Text(
                        list.marketName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      // 2. O Subtítulo empilha a quantidade de produtos e a hora de criação embaixo dele
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${list.items.length} produtos adicionados',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (list.time.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                'Criada em: ${list.time}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        _currencyFormatPtBr.format(list.totalPrice),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ListDetailsScreen(marketList: list),
                          ),
                        );
                        _refreshLists();
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
