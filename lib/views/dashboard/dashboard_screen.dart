import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/customer_provider.dart';
import '../../constants/app_colors.dart';
import '../billing/billing_screen.dart';
import '../inventory/inventory_screen.dart';
import '../customers/customer_ledger_screen.dart';
import '../invoices/invoice_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final business = Provider.of<BusinessProvider>(context, listen: false).currentBusiness;
      if (business != null) {
        Provider.of<InventoryProvider>(context, listen: false).listenToProducts(business.id);
        Provider.of<InvoiceProvider>(context, listen: false).listenToInvoices(business.id);
        Provider.of<CustomerProvider>(context, listen: false).listenToCustomers(business.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    final business = businessProvider.currentBusiness;

    return Scaffold(
      appBar: AppBar(
        title: Text(business?.shopName ?? 'BillFlow Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (business != null) {
            inventoryProvider.listenToProducts(business.id);
            invoiceProvider.listenToInvoices(business.id);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header Banner
              Card(
                color: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          business?.shopName.substring(0, 1).toUpperCase() ?? 'B',
                          style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business?.shopName ?? 'Store Name',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'GSTIN: ${business?.gstin.isEmpty ?? true ? 'N/A' : business!.gstin}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BillingScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('NEW BILL'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Low Stock Warning Alert (If Any)
              if (inventoryProvider.lowStockProducts.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    inventoryProvider.toggleLowStockFilter(true);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InventoryScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Warning: ${inventoryProvider.lowStockProducts.length} items are running low on stock!',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ),
                        const Text(
                          'View Items',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Financial Metrics Summary Grid
              Text('Sales Overview', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard(
                    title: "Today's Revenue",
                    value: currencyFormatter.format(invoiceProvider.todayRevenue),
                    icon: Icons.payments,
                    color: AppColors.success,
                  ),
                  _buildMetricCard(
                    title: "Today's Invoices",
                    value: "${invoiceProvider.todayInvoiceCount} Bills",
                    icon: Icons.receipt,
                    color: AppColors.accent,
                  ),
                  _buildMetricCard(
                    title: "Monthly Sales",
                    value: currencyFormatter.format(invoiceProvider.monthlyRevenue),
                    icon: Icons.trending_up,
                    color: AppColors.primary,
                  ),
                  _buildMetricCard(
                    title: "Tax Collected",
                    value: currencyFormatter.format(invoiceProvider.totalTaxCollected),
                    icon: Icons.account_balance,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Action Navigation Cards
              Text('Quick Operations', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      title: 'Inventory',
                      subtitle: '${inventoryProvider.products.length} Items',
                      icon: Icons.inventory_2_outlined,
                      color: Colors.purple,
                      onTap: () {
                        inventoryProvider.toggleLowStockFilter(false);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const InventoryScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionTile(
                      title: 'Customers',
                      subtitle: 'Ledgers & Balances',
                      icon: Icons.people_outline,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CustomerLedgerScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                title: 'Invoice History & Reports',
                subtitle: '${invoiceProvider.invoices.length} Invoices Generated',
                icon: Icons.history,
                color: Colors.teal,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InvoiceHistoryScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Invoices', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InvoiceHistoryScreen()),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              invoiceProvider.invoices.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text('No invoices created yet. Tap "NEW BILL" to start billing!'),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: invoiceProvider.invoices.length > 5 ? 5 : invoiceProvider.invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoiceProvider.invoices[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.accent.withOpacity(0.1),
                              child: const Icon(Icons.receipt_long, color: AppColors.accent),
                            ),
                            title: Text(
                              invoice.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${invoice.invoiceNumber} • ${invoice.paymentMethod}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(invoice.grandTotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: invoice.paymentStatus == 'Paid'
                                        ? AppColors.success.withOpacity(0.15)
                                        : AppColors.danger.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    invoice.paymentStatus,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: invoice.paymentStatus == 'Paid' ? AppColors.success : AppColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
