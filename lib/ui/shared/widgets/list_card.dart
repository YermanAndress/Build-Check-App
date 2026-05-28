import 'package:flutter/material.dart';

class SearchableList<T> extends StatefulWidget {
  final Future<List<T>> Function() fetchData;
  final String Function(T) searchPredicate;
  final Widget Function(T) itemBuilder;
  final String title;
  final String hintText;
  final String emptyMessage;
  final String
  noResultsMessage; // mensaje cuando la búsqueda no arroja resultados
  final Widget? floatingActionButton; // botón flotante opcional
  final bool enableSortToggle;
  final String Function(T)? sortValue;
  final bool Function(T)? filterPredicate;

  const SearchableList({
    super.key,
    required this.fetchData,
    required this.searchPredicate,
    required this.itemBuilder,
    required this.title,
    required this.hintText,
    this.emptyMessage = "No hay registros aún",
    this.noResultsMessage = "No se encontraron resultados",
    this.floatingActionButton,
    this.enableSortToggle = false,
    this.sortValue,
    this.filterPredicate,
  });

  @override
  State<SearchableList<T>> createState() => _SearchableListState<T>();
}

class _SearchableListState<T> extends State<SearchableList<T>> {
  List<T> _allItems = [];
  List<T> _filteredItems = [];
  bool _loading = true;
  bool _isDescending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final items = await widget.fetchData();
    if (mounted) {
      setState(() {
        _allItems = items;
        _filteredItems = _sortedItems(_applyFilter(items));
        _loading = false;
      });
    }
  }

  List<T> _applyFilter(List<T> items) {
    if (widget.filterPredicate == null) return items;
    return items.where(widget.filterPredicate!).toList();
  }

  List<T> _sortedItems(List<T> items) {
    if (!widget.enableSortToggle || widget.sortValue == null) {
      return items;
    }

    final sorted = [...items];
    sorted.sort((a, b) {
      final va = widget.sortValue!(a);
      final vb = widget.sortValue!(b);
      return _isDescending ? vb.compareTo(va) : va.compareTo(vb);
    });
    return sorted;
  }

  void _filter(String query) {
    setState(() {
      final base = _applyFilter(_allItems);
      if (query.isEmpty) {
        _filteredItems = _sortedItems(base);
      } else {
        final lowerQuery = query.toLowerCase();
        final filtered = base.where((item) {
          final searchText = widget.searchPredicate(item);
          return searchText.toLowerCase().contains(lowerQuery);
        }).toList();
        _filteredItems = _sortedItems(filtered);
      }
    });
  }

  void _toggleOrder() {
    setState(() {
      _isDescending = !_isDescending;
      _filteredItems = _sortedItems(_filteredItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _filter,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF4CAF50),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                if (widget.enableSortToggle && widget.sortValue != null) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _toggleOrder,
                    icon: Icon(
                      _isDescending
                          ? Icons.swap_vert
                          : Icons.swap_vert_circle,
                      color: const Color(0xFF4CAF50),
                    ),
                    tooltip: _isDescending
                        ? 'Orden: más nuevo'
                        : 'Orden: más viejo',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: const Color(0xFF4CAF50),
              onRefresh: _loadData,
              child: _filteredItems.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_rounded, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  _allItems.isEmpty
                                      ? widget.emptyMessage
                                      : widget.noResultsMessage,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          widget.itemBuilder(_filteredItems[index]),
                    ),
            ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
