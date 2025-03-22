import 'package:dbz/Auth/loginpage.dart';
import 'package:dbz/serachscerrn.dart';
import 'package:dbz/services/uapiserive.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dbz/cart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> categories = [];
  List<dynamic> products = [];
  List<dynamic> restaurants = [];
  bool isLoadingCategories = true;
  bool isLoadingProducts = true;
  bool isLoadingRestaurants = true;
  String? errorMessage;

  // Change to nullable to indicate no selection yet
  int? selectedRestaurantId;

  int? selectedCategoryId;
  bool isViewingAllProducts = false;
  int currentPage = 1;
  bool isLoadingMoreProducts = false;
  bool hasMoreProducts = true;
  int productsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // First fetch restaurants so we can select the first one
    await _fetchRestaurants();

    // Then fetch categories and products in parallel
    await Future.wait([_fetchCategories(), _loadProducts()]);
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

  Future<void> _fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
      errorMessage = null;
    });

    try {
      // ApiService.getCategories() returns Future<List<dynamic>>
      final categoriesList = await ApiService.getCategories();
      setState(() {
        categories = categoriesList;
        isLoadingCategories = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to load categories: ${error.toString()}';
        isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    print(
      'Loading products - Category ID: $selectedCategoryId, Restaurant ID: $selectedRestaurantId, Page: $currentPage',
    );

    setState(() {
      if (currentPage == 1) {
        isLoadingProducts = true;
        products = [];
      } else {
        isLoadingMoreProducts = true;
      }
      errorMessage = null;
    });

    try {
      final Map<String, dynamic> data = await ApiService.getProducts(
        page: currentPage,
        pageSize: productsPerPage,
      );

      List<dynamic> newProducts = [];

      // Extract results from the response
      if (data.containsKey('results') && data['results'] is List) {
        newProducts = data['results'] as List<dynamic>;
      } else {
        // Try to find any list in the response
        for (var value in data.values) {
          if (value is List) {
            newProducts = value;
            break;
          }
        }
      }

      // Apply frontend filtering
      if (selectedRestaurantId != null) {
        newProducts =
            newProducts.where((product) {
              return product['restaurant'] == selectedRestaurantId;
            }).toList();
      }

      if (selectedCategoryId != null) {
        newProducts =
            newProducts.where((product) {
              return product['category'] == selectedCategoryId;
            }).toList();
      }

      print('Found ${newProducts.length} products after filtering');

      setState(() {
        if (currentPage == 1) {
          products = newProducts;
        } else {
          products.addAll(newProducts);
        }

        // Check if there are more products to load
        if (data.containsKey('next') && data['next'] != null) {
          hasMoreProducts = true;
        } else if (newProducts.length < productsPerPage) {
          hasMoreProducts = false;
        }

        isLoadingProducts = false;
        isLoadingMoreProducts = false;
      });
    } catch (error) {
      print('Error loading products: $error');
      setState(() {
        errorMessage = 'Failed to load products: ${error.toString()}';
        isLoadingProducts = false;
        isLoadingMoreProducts = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (!isLoadingMoreProducts && hasMoreProducts) {
      setState(() {
        currentPage++;
      });
      await _loadProducts();
    }
  }

  void _selectCategory(int categoryId) {
    setState(() {
      // If the same category is selected again, deselect it
      if (selectedCategoryId == categoryId) {
        selectedCategoryId = null;
      } else {
        selectedCategoryId = categoryId;
      }

      // Reset to page 1 when changing category
      currentPage = 1;
      isViewingAllProducts = false;

      // Reset products list to show loading state
      products = [];
      isLoadingProducts = true;

      // Load products for the selected category AND restaurant (if selected)
      _loadProducts();
    });
  }

  void _onSeeAllPressed() {
    setState(() {
      isViewingAllProducts = true;
      selectedCategoryId = null;
      currentPage = 1;
      _loadProducts();
    });
  }

  Future<void> _fetchRestaurants() async {
    setState(() {
      isLoadingRestaurants = true;
      errorMessage = null;
    });

    try {
      print(
        'Attempting to fetch restaurants from ${ApiService.baseUrl}/api/restaurant/',
      );
      final restaurantsList = await ApiService.getRestaurants();
      print('Restaurants fetched successfully: ${restaurantsList.length}');

      setState(() {
        restaurants = restaurantsList;
        isLoadingRestaurants = false;

        // Select the first restaurant by default if we have restaurants
        if (restaurants.isNotEmpty && selectedRestaurantId == null) {
          selectedRestaurantId = restaurants[0]['id'];
          print('Selected first restaurant ID: $selectedRestaurantId');
        }
      });
    } catch (error) {
      print('Error fetching restaurants: $error');
      setState(() {
        errorMessage = 'Failed to load restaurants: ${error.toString()}';
        isLoadingRestaurants = false;
      });
    }
  }

  void _onRestaurantChanged(int? restaurantId) {
    if (restaurantId != null && restaurantId != selectedRestaurantId) {
      setState(() {
        selectedRestaurantId = restaurantId;
        selectedCategoryId = null;
        isViewingAllProducts = false;
        currentPage = 1;
      });
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 245, 245, 1),
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        automaticallyImplyLeading: false,
        title: const Text('Food Delivery'),
        actions: [
      
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen55()),
              );
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child:
            errorMessage != null
                ? _buildErrorView()
                : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                      _loadMoreProducts();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Restaurants'),
                        _buildRestaurantsSection(),
                        // Categories
                        _buildSectionTitle(
                          'Categories',
                          onSeeAllPressed: _onSeeAllPressed,
                        ),
                        _buildCategoriesSection(),

                        // Products Title
                        _buildProductsTitle(),

                        // Products Grid
                        _buildProductsGrid(),

                        // Loading indicator at the bottom
                        if (isLoadingMoreProducts)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  // Add this to your HomeScreen class
  Widget _buildRestaurantsSection() {
    if (isLoadingRestaurants) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (restaurants.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('No restaurants available')),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: restaurants.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          final id = restaurant['id'];
          final name = restaurant['name'] ?? 'Restaurant';
          final isSelected = selectedRestaurantId == id;

          return GestureDetector(
            onTap: () => _onRestaurantChanged(id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              width: 120,
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    color: isSelected ? Colors.orange : Colors.grey.shade700,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.orange : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsTitle() {
    String title = 'Popular Items';

    if (isViewingAllProducts) {
      title = 'All Products';
    } else if (selectedCategoryId != null) {
      // Find the category name
      final category = categories.firstWhere(
        (cat) => cat['id'] == selectedCategoryId,
        orElse: () => {'name': 'Category'},
      );
      title = '${category['name']} Products';
    } else if (selectedRestaurantId != null) {
      // Find the restaurant name to show in title
      final restaurant = restaurants.firstWhere(
        (rest) => rest['id'] == selectedRestaurantId,
        orElse: () => {'name': 'Restaurant'},
      );
      title = '${restaurant['name']} Popular Items';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (selectedCategoryId != null || isViewingAllProducts)
            TextButton(
              onPressed: () {
                // Reset to default view
                setState(() {
                  selectedCategoryId = null;
                  isViewingAllProducts = false;
                  currentPage = 1;
                  _loadProducts();
                });
              },
              child: const Text('Back to Featured'),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Function()? onSeeAllPressed}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (isLoadingCategories) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final id = category['id'];
          final isSelected = selectedCategoryId == id;

          return _buildCategoryItem(
            category,
            isSelected: isSelected,
            onTap: () => _selectCategory(id),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(
    dynamic category, {
    bool isSelected = false,
    Function()? onTap,
  }) {
    final name = category['name'] ?? 'Category';
    final id = category['id'];

    // Generate a color based on the category ID for visual differentiation
    final Color categoryColor = Color.fromARGB(
      255,
      ((id * 83) % 255),
      ((id * 73) % 200) + 55,
      ((id * 53) % 200) + 55,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? categoryColor.withOpacity(0.3)
                            : categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: categoryColor,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.orange : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (isLoadingProducts) {
      return const SizedBox(
        height: 290,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductItem(product);
      },
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
            errorMessage ?? 'Something went wrong',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _fetchData, child: const Text('Try Again')),
        ],
      ),
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
