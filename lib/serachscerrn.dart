import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dbz/services/uapiserive.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> searchResults = [];
  bool isLoading = false;
  String? errorMessage;
  bool hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
        hasSearched = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      hasSearched = true;
    });

    try {
      final results = await ApiService.getProducts(search: query);
      setState(() {
        if (results.containsKey('results') && results['results'] is List) {
          searchResults = results['results'];
        } else {
          for (var value in results.values) {
            if (value is List) {
              searchResults = value;
              break;
            }
          }
          if (searchResults.isEmpty) {
            searchResults = [];
          }
        }
      });
    } catch (error) {
      setState(() {
        errorMessage = 'Search failed: ${error.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addToCart(int productId) async {
    try {
      final result = await ApiService.addToCart(
        productId: productId,
        quantity: 1,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for dishes',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              searchResults = [];
                              hasSearched = false;
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (value) => _performSearch(value),
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? _buildErrorView()
                    : searchResults.isEmpty
                    ? _buildEmptyView()
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearched ? Icons.search_off : Icons.search,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearched ? 'No results found' : 'Search for dishes',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _performSearch(_searchController.text),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return _buildProductItem(searchResults[index]);
      },
    );
  }

  Widget _buildProductItem(dynamic product) {
    final name = product['name'] ?? 'Product';
    final description = product['description'] ?? '';

    // Convert price string to double
    final priceStr = product['price'] ?? '0.00';
    final price = double.tryParse(priceStr) ?? 0.0;

    final imagePath = product['image'] ?? '';
    final restaurantName = product['restaurant_name'] ?? '';
    final categoryName = product['category_name'] ?? '';
    final isAvailable = product['is_available'] ?? false;

    // Construct the full image URL
    final imageUrl =
        imagePath.isNotEmpty ? '${ApiService.baseUrl}$imagePath' : '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child:
                      imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  height: 130,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  height: 130,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.fastfood, size: 40),
                                      const SizedBox(height: 4),
                                      Text(
                                        categoryName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          )
                          : Container(
                            height: 130,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.fastfood, size: 40),
                                const SizedBox(height: 4),
                                Text(
                                  categoryName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
                if (!isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Currently Unavailable',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  restaurantName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 16,
                      ),
                    ),
                    if (isAvailable)
                      InkWell(
                        onTap: () => addToCart(product['id']),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
