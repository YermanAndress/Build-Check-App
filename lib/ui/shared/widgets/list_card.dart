import 'package:flutter/material.dart';

class SearchableList<T> extends StatefulWidget {
  final Future<List<T>> Function() fetchData;
  final String Function(T)
  searchPredicate; // función que devuelve el texto por el cual filtrar
  final Widget Function(T) itemBuilder;
  final String title;
  final String hintText;
  final String emptyMessage; // mensaje cuando la lista está vacía
  final String
  noResultsMessage; // mensaje cuando la búsqueda no arroja resultados

  const SearchableList({
    super.key,
    required this.fetchData,
    required this.searchPredicate,
    required this.itemBuilder,
    required this.title,
    required this.hintText,
    this.emptyMessage = "No hay registros aún",
    this.noResultsMessage = "No se encontraron resultados",
  });

  @override
  State<SearchableList<T>> createState() => _SearchableListState<T>();
}

class _SearchableListState<T> extends State<SearchableList<T>> {
  List<T> _allItems = [];
  List<T> _filteredItems = [];
  bool _loading = true;

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
        _filteredItems = items;
        _loading = false;
      });
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredItems = _allItems.where((item) {
          final searchText = widget.searchPredicate(item);
          return searchText.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // ✓ mismo fondo
      appBar: AppBar(
        backgroundColor: Colors.white, // ✓ mismo color
        elevation: 0, // ✓ sin sombra
        title: Text(
          widget.title, // ← título parametrizado
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true, // ✓ título centrado
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: _filter, // ← función de filtrado interna
              decoration: InputDecoration(
                hintText: widget.hintText, // ← hint parametrizado
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
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
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filteredItems.isEmpty
          ? Center(
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
            )
          : ListView.separated(
              // ✓ misma lista
              padding: const EdgeInsets.all(16),
              itemCount: _filteredItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  widget.itemBuilder(_filteredItems[index]),
            ),
    );
  }
}
