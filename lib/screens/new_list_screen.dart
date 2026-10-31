import 'package:flutter/material.dart';
import '../models/market_list.dart';
import '../models/shopping_item.dart';

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
