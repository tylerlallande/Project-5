import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'bring_item.dart';

enum BringListFilter { all, open, mine, packed }

class BringListSection extends StatefulWidget {
  const BringListSection({super.key, this.currentUser = 'Alex'});

  final String currentUser;

  @override
  State<BringListSection> createState() => _BringListSectionState();
}

class _BringListSectionState extends State<BringListSection> {
  BringListFilter _filter = BringListFilter.all;
  int _nextId = 5;
  final List<BringItem> _items = [
    const BringItem(
      id: '1',
      name: 'The gumbo',
      quantity: 1,
      category: BringItemCategory.food,
      claimedBy: 'Jordan',
      isPacked: true,
    ),
    const BringItem(
      id: '2',
      name: 'Ice & coolers',
      quantity: 2,
      category: BringItemCategory.drinks,
    ),
    const BringItem(
      id: '3',
      name: 'Game-day playlist',
      quantity: 1,
      category: BringItemCategory.other,
      claimedBy: 'Alex',
    ),
    const BringItem(
      id: '4',
      name: 'Cornhole',
      quantity: 1,
      category: BringItemCategory.games,
    ),
  ];

  List<BringItem> get _visibleItems => switch (_filter) {
    BringListFilter.all => _items,
    BringListFilter.open =>
      _items.where((item) => item.claimedBy == null).toList(),
    BringListFilter.mine =>
      _items.where((item) => item.claimedBy == widget.currentUser).toList(),
    BringListFilter.packed => _items.where((item) => item.isPacked).toList(),
  };

  int get _coveredCount =>
      _items.where((item) => item.claimedBy != null).length;
  int get _packedCount => _items.where((item) => item.isPacked).length;

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return Column(
      key: const Key('bring-list-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Who’s bringing what?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton.filled(
              key: const Key('add-bring-item'),
              tooltip: '',
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '$_coveredCount of ${_items.length} covered · $_packedCount packed',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: _items.isEmpty ? 0 : _coveredCount / _items.length,
            backgroundColor: const Color(0xFFE8E0D3),
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: BringListFilter.values.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: Key('bring-filter-${filter.name}'),
                  label: Text(_filterLabel(filter)),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (visibleItems.isEmpty)
          _EmptyFilter(filter: _filter)
        else
          Card(
            child: Column(
              children: List.generate(visibleItems.length, (index) {
                final item = visibleItems[index];
                return Column(
                  children: [
                    _BringItemTile(
                      item: item,
                      isMine: item.claimedBy == widget.currentUser,
                      onClaim: () => _claim(item),
                      onUnclaim: () => _unclaim(item),
                      onPackedChanged: (value) => _setPacked(item, value),
                    ),
                    if (index != visibleItems.length - 1)
                      const Divider(height: 1, indent: 68, endIndent: 14),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  String _filterLabel(BringListFilter filter) => switch (filter) {
    BringListFilter.all => 'All (${_items.length})',
    BringListFilter.open => 'Open',
    BringListFilter.mine => 'Mine',
    BringListFilter.packed => 'Packed',
  };

  void _claim(BringItem item) {
    _replace(item, item.copyWith(claimedBy: widget.currentUser));
  }

  void _unclaim(BringItem item) {
    _replace(item, item.copyWith(clearClaim: true, isPacked: false));
  }

  void _setPacked(BringItem item, bool value) {
    _replace(item, item.copyWith(isPacked: value));
  }

  void _replace(BringItem oldItem, BringItem newItem) {
    setState(
      () =>
          _items[_items.indexWhere((item) => item.id == oldItem.id)] = newItem,
    );
  }

  Future<void> _showAddItemDialog() async {
    var name = '';
    var quantityText = '1';
    var category = BringItemCategory.food;

    final item = await showDialog<BringItem>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add to the bring-list'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('new-item-name'),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Item name'),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('new-item-quantity'),
                      initialValue: quantityText,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      onChanged: (value) => quantityText = value,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<BringItemCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: BringItemCategory.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('save-bring-item'),
              onPressed: () {
                final cleanName = name.trim();
                final quantity = int.tryParse(quantityText.trim()) ?? 0;
                if (cleanName.isEmpty || quantity < 1) return;
                Navigator.pop(
                  context,
                  BringItem(
                    id: (_nextId++).toString(),
                    name: cleanName,
                    quantity: quantity,
                    category: category,
                  ),
                );
              },
              child: const Text('Add item'),
            ),
          ],
        ),
      ),
    );

    if (item != null && mounted) setState(() => _items.add(item));
  }
}

class _BringItemTile extends StatelessWidget {
  const _BringItemTile({
    required this.item,
    required this.isMine,
    required this.onClaim,
    required this.onUnclaim,
    required this.onPackedChanged,
  });

  final BringItem item;
  final bool isMine;
  final VoidCallback onClaim;
  final VoidCallback onUnclaim;
  final ValueChanged<bool> onPackedChanged;

  @override
  Widget build(BuildContext context) {
    final isClaimed = item.claimedBy != null;
    return Padding(
      key: Key('bring-item-${item.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF1EBF8),
            foregroundColor: AppColors.purple,
            child: Icon(item.category.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    decoration: item.isPacked
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty ${item.quantity} · ${isClaimed ? 'Claimed by ${item.claimedBy}' : 'Still up for grabs'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isClaimed)
            OutlinedButton(
              key: Key('claim-${item.id}'),
              onPressed: onClaim,
              child: const Text('Claim'),
            )
          else if (isMine)
            PopupMenuButton<String>(
              key: Key('bring-item-actions-${item.id}'),
              tooltip: '',
              onSelected: (action) {
                if (action == 'packed') onPackedChanged(!item.isPacked);
                if (action == 'unclaim') onUnclaim();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'packed',
                  child: Text(item.isPacked ? 'Mark unpacked' : 'Mark packed'),
                ),
                const PopupMenuItem(
                  value: 'unclaim',
                  child: Text('Unclaim item'),
                ),
              ],
              child: Icon(
                item.isPacked
                    ? Icons.check_circle_rounded
                    : Icons.more_vert_rounded,
                color: item.isPacked ? AppColors.success : AppColors.purple,
              ),
            )
          else
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter({required this.filter});

  final BringListFilter filter;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          filter == BringListFilter.open
              ? 'Everything is covered!'
              : 'No items match this filter.',
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}
