import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/market_list.dart';
import 'new_list_screen.dart';

class ListDetailsScreen extends StatefulWidget {
  final MarketList marketList;

  const ListDetailsScreen({super.key, required this.marketList});

  @override
  State<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends State<ListDetailsScreen> {
  late MarketList _currentList;

  @override
  void initState() {
    super.initState();
    _currentList = widget.marketList; // Mantém a visualização atual estável
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewListScreen(existingList: _currentList),
      ),
    );

    if (result != null && result is MarketList) {
      await DatabaseHelper.updateList(result);
      setState(() {
        _currentList = result;
      });
    }
  }

  // --- FUNÇÃO ADICIONADA PARA CONFIRMAR E EXCLUIR ---
  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lista?'),
        content: Text('Deseja realmente apagar as compras do mercado ${_currentList.marketName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && _currentList.id != null) {
      await DatabaseHelper.deleteList(_currentList.id!);
      if (mounted) {
        Navigator.pop(context); // Retorna para a HomeScreen após deletar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentList.marketName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Data: ${_currentList.date}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            tooltip: 'Editar Lista',
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color.fromARGB(255, 211, 47, 47)),
            tooltip: 'Deletar Lista',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _currentList.items.length,
              itemBuilder: (context, index) {
                final item = _currentList.items[index];
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
                      'Preço: R\$ ${item.price.toStringAsFixed(2)}  |  Qtd: ${item.quantity}'),
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
                  'R\$ ${_currentList.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
