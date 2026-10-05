import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/business_provider.dart';
import '../../constants/app_colors.dart';

class AddEditProductDialog extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductDialog({super.key, this.product});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _categoryController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _lowStockThresholdController;

  String _selectedUnit = 'Pcs';
  double _selectedGstRate = 18.0;

  final List<String> _units = ['Pcs', 'Kg', 'Ltr', 'Box', 'Meter', 'Pack', 'Gram'];
  final List<double> _gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.itemName ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _categoryController = TextEditingController(text: p?.category ?? 'General');
    _costPriceController = TextEditingController(text: p?.costPrice.toString() ?? '');
    _sellingPriceController = TextEditingController(text: p?.sellingPrice.toString() ?? '');
    _stockController = TextEditingController(text: p?.stockQuantity.toString() ?? '10');
    _lowStockThresholdController = TextEditingController(text: p?.lowStockThreshold.toString() ?? '5');

    if (p != null) {
      _selectedUnit = p.unit;
      _selectedGstRate = p.gstRate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final business = Provider.of<BusinessProvider>(context, listen: false).currentBusiness;
    if (business == null) return;

    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

    final product = ProductModel(
      id: widget.product?.id ?? '',
      businessId: business.id,
      itemName: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
      costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
      stockQuantity: int.tryParse(_stockController.text) ?? 0,
      lowStockThreshold: int.tryParse(_lowStockThresholdController.text) ?? 5,
      unit: _selectedUnit,
      gstRate: _selectedGstRate,
      updatedAt: DateTime.now(),
    );

    if (widget.product == null) {
      await inventoryProvider.addProduct(product);
    } else {
      await inventoryProvider.updateProduct(product);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Product' : 'Add New Inventory Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name *', prefixIcon: Icon(Icons.shopping_bag)),
                validator: (val) => val == null || val.isEmpty ? 'Enter item name' : null,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(labelText: 'SKU / Barcode', prefixIcon: Icon(Icons.qr_code)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cost Price (₹)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Selling Price (₹) *'),
                      validator: (val) => val == null || val.isEmpty ? 'Enter price' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Initial Stock *'),
                      validator: (val) => val == null || val.isEmpty ? 'Enter stock' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) => setState(() => _selectedUnit = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<double>(
                      value: _selectedGstRate,
                      decoration: const InputDecoration(labelText: 'GST Tax Rate'),
                      items: _gstRates.map((r) => DropdownMenuItem(value: r, child: Text('${r.toStringAsFixed(0)}%'))).toList(),
                      onChanged: (val) => setState(() => _selectedGstRate = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lowStockThresholdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Low Stock Alert Qty'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () async {
              await Provider.of<InventoryProvider>(context, listen: false).deleteProduct(widget.product!.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: AppColors.danger)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'UPDATE' : 'SAVE ITEM'),
        ),
      ],
    );
  }
}
