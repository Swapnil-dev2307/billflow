import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/product_model.dart';
import '../../constants/app_colors.dart';
import 'add_edit_product_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _searchController = TextEditingController();

  void _openAddEditProductModal(BuildContext context, [ProductModel? product]) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditProductDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Stock'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditProductModal(context),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ADD PRODUCT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter & Search Controls Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => inventoryProvider.setSearchQuery(val),
                  decoration: const InputDecoration(
                    hintText: 'Search by product name, category, or SKU...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Category Filter Chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: inventoryProvider.categories.map((cat) {
                            final isSelected = inventoryProvider.selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) inventoryProvider.setCategory(cat);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Low Stock Filter Toggle
                    FilterChip(
                      label: const Text('Low Stock'),
                      selected: inventoryProvider.showLowStockOnly,
                      selectedColor: AppColors.warning.withOpacity(0.2),
                      onSelected: (val) => inventoryProvider.toggleLowStockFilter(val),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: inventoryProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : inventoryProvider.filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('No products found in inventory.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: inventoryProvider.filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = inventoryProvider.filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: product.isLowStock
                                      ? AppColors.danger.withOpacity(0.1)
                                      : AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  product.isLowStock ? Icons.warning_amber : Icons.check_circle_outline,
                                  color: product.isLowStock ? AppColors.danger : AppColors.accent,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.itemName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  if (product.isLowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'LOW STOCK',
                                        style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'SKU: ${product.sku.isEmpty ? "N/A" : product.sku} • Cost: ${currencyFormatter.format(product.costPrice)} • GST: ${product.gstRate}%',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormatter.format(product.sellingPrice),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                  ),
                                  Text(
                                    'Stock: ${product.stockQuantity} ${product.unit}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: product.isLowStock ? AppColors.danger : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _openAddEditProductModal(context, product),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
