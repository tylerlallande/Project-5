import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../tailgate_setup/tailgate_draft.dart';
import '../tailgate_setup/tailgate_repository.dart';
import 'bring_item.dart';

enum BringListFilter { all, open, mine, packed }

class BringListSection extends StatefulWidget {
  const BringListSection({
    super.key,
    required this.currentUser,
    this.entry,
    this.repository,
  });

  final String currentUser;
  final TailgateEntry? entry;
  final TailgateRepository? repository;

  @override
  State<BringListSection> createState() => _BringListSectionState();
}

class _BringListSectionState extends State<BringListSection> {
  BringListFilter _filter = BringListFilter.all;
  final List<BringItem> _items = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _connected => widget.entry != null && widget.repository != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_connected) return;
    setState(() => _loading = true);
    try {
      final items = await widget.repository!.listBringItems(widget.entry!);
      if (mounted) {
        setState(() => _items..replaceRange(0, _items.length, items));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
              onPressed: _saving || !_connected ? null : _showAddItemDialog,
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
        if (_error != null)
          _MessageCard(message: _error!, onRetry: _load)
        else if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (!_connected)
          const _MessageCard(
            message: 'Host or join a tailgate to create a bring list.',
          )
        else if (visibleItems.isEmpty)
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
                      onEdit: () => _showItemDialog(existing: item),
                      onDelete: () => _delete(item),
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

  Future<void> _claim(BringItem item) async {
    await _save(item, item.copyWith(claimedBy: widget.currentUser));
  }

  Future<void> _unclaim(BringItem item) async {
    await _save(item, item.copyWith(clearClaim: true, isPacked: false));
  }

  Future<void> _setPacked(BringItem item, bool value) async {
    await _save(item, item.copyWith(isPacked: value));
  }

  Future<void> _save(BringItem oldItem, BringItem newItem) async {
    if (!_connected || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.repository!.updateBringItem(
        widget.entry!,
        newItem,
      );
      if (mounted) {
        setState(
          () => _items[_items.indexWhere((item) => item.id == oldItem.id)] =
              saved,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAddItemDialog() async {
    await _showItemDialog();
  }

  Future<void> _showItemDialog({BringItem? existing}) async {
    var name = existing?.name ?? '';
    var quantityText = (existing?.quantity ?? 1).toString();
    var category = existing?.category ?? BringItemCategory.food;

    final item = await showDialog<BringItem>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Add to the bring-list' : 'Edit bring-list item',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('new-item-name'),
                autofocus: true,
                controller: TextEditingController(text: name),
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
                    id: existing?.id ?? '',
                    name: cleanName,
                    quantity: quantity,
                    category: category,
                  ),
                );
              },
              child: Text(existing == null ? 'Add item' : 'Save changes'),
            ),
          ],
        ),
      ),
    );

    if (item == null || !mounted || !_connected) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (existing == null) {
        final saved = await widget.repository!.addBringItem(
          widget.entry!,
          item,
        );
        if (mounted) setState(() => _items.add(saved));
      } else {
        final saved = await widget.repository!.updateBringItem(
          widget.entry!,
          item.copyWith(
            claimedBy: existing.claimedBy,
            isPacked: existing.isPacked,
          ),
        );
        if (mounted) {
          setState(
            () =>
                _items[_items.indexWhere((value) => value.id == existing.id)] =
                    saved,
          );
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(BringItem item) async {
    if (!_connected || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository!.deleteBringItem(widget.entry!, item);
      if (mounted) {
        setState(() => _items.removeWhere((value) => value.id == item.id));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _BringItemTile extends StatelessWidget {
  const _BringItemTile({
    required this.item,
    required this.isMine,
    required this.onClaim,
    required this.onUnclaim,
    required this.onPackedChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final BringItem item;
  final bool isMine;
  final VoidCallback onClaim;
  final VoidCallback onUnclaim;
  final ValueChanged<bool> onPackedChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isClaimed)
                OutlinedButton(
                  key: Key('claim-${item.id}'),
                  onPressed: onClaim,
                  child: const Text('Claim'),
                ),
              if (isClaimed && !isMine)
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
              if (!isClaimed) const SizedBox(width: 4),
              if (!isClaimed || isMine)
                PopupMenuButton<String>(
                  key: Key('bring-item-actions-${item.id}'),
                  tooltip: '',
                  onSelected: (action) {
                    if (action == 'packed') onPackedChanged(!item.isPacked);
                    if (action == 'unclaim') onUnclaim();
                    if (action == 'edit') onEdit();
                    if (action == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    if (isMine)
                      PopupMenuItem(
                        value: 'packed',
                        child: Text(
                          item.isPacked ? 'Mark unpacked' : 'Mark packed',
                        ),
                      ),
                    if (isMine)
                      const PopupMenuItem(
                        value: 'unclaim',
                        child: Text('Unclaim item'),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit item'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete item'),
                    ),
                  ],
                  child: Icon(
                    item.isPacked
                        ? Icons.check_circle_rounded
                        : Icons.more_vert_rounded,
                    color: item.isPacked ? AppColors.success : AppColors.purple,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
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
