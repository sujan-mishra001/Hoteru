
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dautari_adda/features/pos/data/order_workflow_service.dart';
import 'package:dautari_adda/features/pos/data/pos_models.dart';
import 'package:dautari_adda/features/pos/data/table_service.dart';
import 'package:dautari_adda/features/pos/presentation/screens/menu_screen.dart';

class OrderWorkflowScreen extends StatefulWidget {
  const OrderWorkflowScreen({super.key});

  @override
  State<OrderWorkflowScreen> createState() => _OrderWorkflowScreenState();
}

class _OrderWorkflowScreenState extends State<OrderWorkflowScreen> {
  final TableService _tableService = TableService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Table'),
      ),
      body: FutureBuilder<List<PosTable>>(
        future: _tableService.getTables(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tables found.'));
          }

          final tables = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return GestureDetector(
                onTap: () {
                  Provider.of<OrderWorkflowService>(context, listen: false)
                      .selectTable(table);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MenuScreen(tableNumber: table.id),
                    ),
                  );
                },
                child: Card(
                  child: Center(
                    child: Text(table.tableId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
