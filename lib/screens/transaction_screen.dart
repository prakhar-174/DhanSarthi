import 'package:flutter/material.dart';
import 'package:dhansarthi/models/transaction.dart';
import 'package:dhansarthi/widgets/buttons/delete_button.dart';
import 'package:dhansarthi/widgets/buttons/update_button.dart';
import 'package:dhansarthi/widgets/cards/balance_card.dart';
import 'package:dhansarthi/widgets/cards/transaction_card.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ledger_provider.dart';

class TransactionScreen extends StatefulWidget {
  final String personId;
  const TransactionScreen({super.key, required this.personId});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  List<Transaction> _sortedTransactions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ledger = Provider.of<LedgerProvider>(context);
    final person = ledger.getPersonById(widget.personId);
    if (person != null) {
      _sortedTransactions = [...person.transactions]
        ..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  void _showTransactionDialog({
    required BuildContext context,
    String? transactionId,
  }) {
    final ledger = Provider.of<LedgerProvider>(context, listen: false);
    final person = ledger.getPersonById(widget.personId);
    final isEditing = transactionId != null;
    final transaction =
        isEditing
            ? person?.transactions.firstWhere((t) => t.id == transactionId)
            : null;

    final amountController = TextEditingController(
      text: isEditing ? transaction!.amount.toString() : '',
    );
    final noteController = TextEditingController(
      text: isEditing ? transaction!.note : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Transaction Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (!isEditing) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.call_made, size: 20),
                            label: const Text('Given'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              final amount = double.tryParse(
                                amountController.text,
                              );
                              if (amount != null && amount > 0) {
                                final newTx = Transaction(
                                  amount: amount,
                                  isGiven: true,
                                  date: DateTime.now(),
                                  note: noteController.text,
                                  id: '', // id will be set in provider
                                );
                                ledger.addTransaction(widget.personId, newTx);
                                setState(() {
                                  _sortedTransactions.insert(0, newTx);
                                  _listKey.currentState?.insertItem(0);
                                });
                                Navigator.of(ctx).pop();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.call_received, size: 20),
                            label: const Text('Taken'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              final amount = double.tryParse(
                                amountController.text,
                              );
                              if (amount != null && amount > 0) {
                                final newTx = Transaction(
                                  amount: amount,
                                  isGiven: false,
                                  date: DateTime.now(),
                                  note: noteController.text,
                                  id: '', // id will be set in provider
                                );
                                ledger.addTransaction(widget.personId, newTx);
                                setState(() {
                                  _sortedTransactions.insert(0, newTx);
                                  _listKey.currentState?.insertItem(0);
                                });
                                Navigator.of(ctx).pop();
                              }
                            },
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: UpdateButton(
                            onPressed: () {
                              final updatedAmount = double.tryParse(
                                amountController.text,
                              );
                              if (updatedAmount != null && updatedAmount > 0) {
                                final oldTx = _sortedTransactions.firstWhere(
                                  (t) => t.id == transactionId,
                                );
                                final updatedTx = Transaction(
                                  amount: updatedAmount,
                                  isGiven: oldTx.isGiven,
                                  date: oldTx.date,
                                  note: noteController.text,
                                  id: oldTx.id,
                                );
                                ledger.updateTransaction(
                                  widget.personId,
                                  oldTx.id,
                                  updatedTx,
                                );
                                setState(() {
                                  final idx = _sortedTransactions.indexWhere(
                                    (t) => t.id == transactionId,
                                  );
                                  if (idx != -1)
                                    _sortedTransactions[idx] = updatedTx;
                                });
                                Navigator.of(ctx).pop();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DeleteButton(
                            onPressed: () {
                              final oldTx = _sortedTransactions.firstWhere(
                                (t) => t.id == transactionId,
                              );
                              ledger.deleteTransaction(
                                widget.personId,
                                oldTx.id,
                              );
                              setState(() {
                                final removeIndex = _sortedTransactions
                                    .indexWhere((t) => t.id == transactionId);
                                if (removeIndex != -1) {
                                  _sortedTransactions.removeAt(removeIndex);
                                  _listKey.currentState?.removeItem(
                                    removeIndex,
                                    (context, animation) => SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(1, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: TransactionCard(
                                        tx: oldTx,
                                        formattedTime: DateFormat(
                                          'hh:mm a',
                                        ).format(oldTx.date),
                                        onEdit: () {},
                                      ),
                                    ),
                                  );
                                }
                              });
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ledger = Provider.of<LedgerProvider>(context);
    final person = ledger.getPersonById(widget.personId);

    return Scaffold(
      appBar: AppBar(title: Text(person?.name ?? '')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (person != null) BalanceCard(person: person),
              const SizedBox(height: 16),
              if (person == null || person.transactions.isEmpty)
                buildEmptyTransaction()
              else
                AnimatedList(
                  key: _listKey,
                  initialItemCount: _sortedTransactions.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (ctx, i, animation) {
                    final tx = _sortedTransactions[i];
                    final formattedTime = DateFormat('hh:mm a').format(tx.date);
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: TransactionCard(
                        tx: tx,
                        formattedTime: formattedTime,
                        onEdit: () {
                          _showTransactionDialog(
                            context: context,
                            transactionId: tx.id,
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionDialog(context: context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildEmptyTransaction() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            'No Transactions Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add a transaction to get started!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
