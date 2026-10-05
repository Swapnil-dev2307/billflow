import React, { useState, useEffect, useRef } from 'react';
import {
  Receipt, ShoppingBag, Package, Users, History, Store, Plus, Search, Trash2, Edit, Printer, Share2, Download, AlertTriangle, CheckCircle, ArrowRight, LogOut, DollarSign, TrendingUp, ShieldCheck, X
} from 'lucide-react';
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';

// Initial Mock Inventory
const INITIAL_PRODUCTS = [
  { id: 'p1', name: 'Organic Wheat Flour 5kg', sku: '890123456789', category: 'Groceries', costPrice: 210, sellingPrice: 250, stock: 45, threshold: 10, unit: 'Kg', gstRate: 5 },
  { id: 'p2', name: 'Refined Sunflower Oil 1L', sku: '890987654321', category: 'Groceries', costPrice: 120, sellingPrice: 145, stock: 4, threshold: 10, unit: 'Ltr', gstRate: 5 },
  { id: 'p3', name: 'Premium Basmati Rice 10kg', sku: '890555444333', category: 'Groceries', costPrice: 750, sellingPrice: 920, stock: 25, threshold: 8, unit: 'Kg', gstRate: 5 },
  { id: 'p4', name: 'Wireless Ergonomic Mouse', sku: '890111222333', category: 'Electronics', costPrice: 450, sellingPrice: 799, stock: 12, threshold: 5, unit: 'Pcs', gstRate: 18 },
  { id: 'p5', name: 'Bluetooth Headset Pro', sku: '890444555666', category: 'Electronics', costPrice: 1200, sellingPrice: 1899, stock: 2, threshold: 5, unit: 'Pcs', gstRate: 18 },
  { id: 'p6', name: 'Dark Chocolate Bar 100g', sku: '890777888999', category: 'Confectionery', costPrice: 60, sellingPrice: 95, stock: 60, threshold: 15, unit: 'Pack', gstRate: 12 }
];

// Initial Mock Customers
const INITIAL_CUSTOMERS = [
  { id: 'c1', name: 'Rahul Sharma', phone: '9876543210', email: 'rahul@gmail.com', balance: 450 },
  { id: 'c2', name: 'Priya Verma', phone: '9811223344', email: 'priya@gmail.com', balance: 0 },
  { id: 'c3', name: 'Amit Patel', phone: '9765432109', email: 'amit@gmail.com', balance: 1200 }
];

export default function App() {
  // Navigation & View Tabs
  const [activeTab, setActiveTab] = useState('dashboard'); // 'dashboard', 'billing', 'inventory', 'customers', 'invoices'

  // Business Profile
  const [business, setBusiness] = useState({
    shopName: 'BillFlow Supermarket',
    ownerName: 'Vaibhav Vivek Singh',
    address: 'Shop #12, Central Arcade, MG Road, Mumbai - 400001',
    contact: '+91 98765 43210',
    gstin: '27AAAAA0000A1Z5',
    invoicePrefix: 'INV-'
  });

  // Data Stores
  const [products, setProducts] = useState(INITIAL_PRODUCTS);
  const [customers, setCustomers] = useState(INITIAL_CUSTOMERS);
  const [invoices, setInvoices] = useState([]);

  // Billing Cart & POS State
  const [cart, setCart] = useState([]);
  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const [walkInName, setWalkInName] = useState('Walk-in Customer');
  const [walkInPhone, setWalkInPhone] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('Cash'); // 'Cash', 'UPI/Online', 'Credit/Pending'
  const [isInterStateTax, setIsInterStateTax] = useState(false);
  const [flatDiscount, setFlatDiscount] = useState(0);
  const [productSearch, setProductSearch] = useState('');
  const [posCategory, setPosCategory] = useState('All');
  const [amountReceived, setAmountReceived] = useState('');

  // Modals State
  const [showProductModal, setShowProductModal] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);
  const [showCustomerModal, setShowCustomerModal] = useState(false);
  const [showInvoiceModal, setShowInvoiceModal] = useState(false);
  const [activeInvoice, setActiveInvoice] = useState(null);

  // Low Stock Filter State
  const [lowStockOnly, setLowStockOnly] = useState(false);

  // PDF Printing Ref
  const invoicePrintRef = useRef();

  // Financial Analytics Calculations
  const todayRevenue = invoices.reduce((sum, inv) => sum + inv.grandTotal, 0);
  const todayInvoicesCount = invoices.length;
  const totalTaxCollected = invoices.reduce((sum, inv) => sum + inv.totalTax, 0);
  const lowStockProducts = products.filter(p => p.stock <= p.threshold);

  // Cart Operation Functions
  const addToCart = (product) => {
    if (product.stock === 0) return;
    const existingIndex = cart.findIndex(item => item.product.id === product.id);
    if (existingIndex > -1) {
      if (cart[existingIndex].qty < product.stock) {
        const updated = [...cart];
        updated[existingIndex].qty += 1;
        setCart(updated);
      }
    } else {
      setCart([...cart, { product, qty: 1, lineDiscount: 0 }]);
    }
  };

  const updateCartQty = (productId, delta) => {
    setCart(prev => prev.map(item => {
      if (item.product.id === productId) {
        const newQty = item.qty + delta;
        if (newQty <= 0) return null;
        if (newQty > item.product.stock) return item;
        return { ...item, qty: newQty };
      }
      return item;
    }).filter(Boolean));
  };

  // Tax and Calculation Summaries
  const subTotal = cart.reduce((sum, item) => sum + (item.product.sellingPrice * item.qty - item.lineDiscount), 0);
  const totalTax = cart.reduce((sum, item) => {
    const itemSub = (item.product.sellingPrice * item.qty - item.lineDiscount);
    return sum + (itemSub * item.product.gstRate) / 100;
  }, 0);
  const cgst = isInterStateTax ? 0 : totalTax / 2;
  const sgst = isInterStateTax ? 0 : totalTax / 2;
  const igst = isInterStateTax ? totalTax : 0;
  const grandTotal = Math.max(0, subTotal + totalTax - flatDiscount);

  // Checkout Handler
  const handleCheckout = () => {
    if (cart.length === 0) return;

    const invoiceNum = `${business.invoicePrefix}${String(invoices.length + 1).padStart(4, '0')}`;
    const newInvoice = {
      id: `inv_${Date.now()}`,
      invoiceNumber: invoiceNum,
      customerName: selectedCustomer ? selectedCustomer.name : (walkInName || 'Walk-in Customer'),
      customerPhone: selectedCustomer ? selectedCustomer.phone : walkInPhone,
      items: cart.map(item => ({
        name: item.product.itemName,
        qty: item.qty,
        unit: item.product.unit,
        price: item.product.sellingPrice,
        gstRate: item.product.gstRate,
        tax: ((item.product.sellingPrice * item.qty - item.lineDiscount) * item.product.gstRate) / 100,
        total: (item.product.sellingPrice * item.qty - item.lineDiscount) * (1 + item.product.gstRate / 100)
      })),
      subTotal,
      flatDiscount,
      totalTax,
      cgst,
      sgst,
      igst,
      grandTotal,
      paymentMethod,
      paymentStatus: paymentMethod === 'Credit/Pending' ? 'Pending' : 'Paid',
      createdAt: new Date().toLocaleString()
    };

    // Decrement inventory stock
    setProducts(prev => prev.map(p => {
      const cartItem = cart.find(c => c.product.id === p.id);
      if (cartItem) {
        return { ...p, stock: Math.max(0, p.stock - cartItem.qty) };
      }
      return p;
    }));

    // Update customer outstanding balance if credit
    if (paymentMethod === 'Credit/Pending' && selectedCustomer) {
      setCustomers(prev => prev.map(c => c.id === selectedCustomer.id ? { ...c, balance: c.balance + grandTotal } : c));
    }

    setInvoices([newInvoice, ...invoices]);
    setActiveInvoice(newInvoice);
    setShowInvoiceModal(true);

    // Clear Cart
    setCart([]);
    setSelectedCustomer(null);
    setWalkInName('Walk-in Customer');
    setWalkInPhone('');
    setFlatDiscount(0);
  };

  // Print PDF Invoice
  const handlePrint = () => {
    window.print();
  };

  // Download PDF Invoice
  const handleDownloadPDF = async () => {
    const input = document.getElementById('printable-invoice');
    if (!input) return;
    const canvas = await html2canvas(input, { scale: 2 });
    const imgData = canvas.toDataURL('image/png');
    const pdf = new jsPDF('p', 'mm', 'a4');
    const imgProps = pdf.getImageProperties(imgData);
    const pdfWidth = pdf.internal.pageSize.getWidth();
    const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;
    pdf.addImage(imgData, 'PNG', 0, 0, pdfWidth, pdfHeight);
    pdf.save(`Invoice_${activeInvoice.invoiceNumber}.pdf`);
  };

  // Share via WhatsApp
  const handleShareWhatsApp = () => {
    if (!activeInvoice) return;
    const text = encodeURIComponent(
      `*TAX INVOICE ${activeInvoice.invoiceNumber}*\nFrom: ${business.shopName}\nCustomer: ${activeInvoice.customerName}\nTotal Amount: ₹${activeInvoice.grandTotal.toFixed(2)}\nPayment: ${activeInvoice.paymentMethod}\nThank you for shopping with us!`
    );
    window.open(`https://api.whatsapp.com/send?text=${text}`, '_blank');
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', backgroundColor: '#f8fafc' }}>
      {/* Top Corporate Navbar */}
      <header style={{ backgroundColor: '#0f172a', color: 'white', padding: '1rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <div style={{ backgroundColor: '#2563eb', padding: '0.6rem', borderRadius: '0.5rem', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Receipt size={24} color="white" />
          </div>
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 'bold', margin: 0, letterSpacing: '0.5px' }}>BillFlow</h1>
            <p style={{ fontSize: '0.75rem', color: '#94a3b8', margin: 0 }}>Smart Billing & Inventory Application</p>
          </div>
        </div>

        {/* Navigation Tabs */}
        <nav style={{ display: 'flex', gap: '0.5rem' }}>
          {[
            { id: 'dashboard', label: 'Dashboard', icon: Store },
            { id: 'billing', label: 'Fast POS Billing', icon: ShoppingBag },
            { id: 'inventory', label: 'Inventory', icon: Package },
            { id: 'customers', label: 'Customers', icon: Users },
            { id: 'invoices', label: 'Invoice History', icon: History }
          ].map(tab => {
            const IconComp = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  padding: '0.5rem 1rem',
                  borderRadius: '0.5rem',
                  border: 'none',
                  backgroundColor: isActive ? '#2563eb' : 'transparent',
                  color: isActive ? 'white' : '#94a3b8',
                  fontWeight: isActive ? '600' : 'normal',
                  cursor: 'pointer',
                  transition: 'all 0.2s'
                }}
              >
                <IconComp size={18} />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </nav>

        {/* Store Profile Avatar */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', backgroundColor: '#1e293b', padding: '0.4rem 0.8rem', borderRadius: '0.5rem' }}>
          <div style={{ width: '32px', height: '32px', borderRadius: '50%', backgroundColor: '#2563eb', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
            {business.shopName.charAt(0)}
          </div>
          <div>
            <div style={{ fontSize: '0.85rem', fontWeight: 'bold', color: 'white' }}>{business.shopName}</div>
            <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>GSTIN: {business.gstin}</div>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main style={{ flex: 1, padding: '1.5rem', maxWidth: '1400px', margin: '0 auto', width: '100%' }}>

        {/* ================= DASHBOARD VIEW ================= */}
        {activeTab === 'dashboard' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            {/* Low Stock Warning Banner */}
            {lowStockProducts.length > 0 && (
              <div style={{ backgroundColor: '#fffbe6', border: '1px solid #ffe58f', padding: '1rem', borderRadius: '0.75rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <AlertTriangle size={24} color="#faad14" />
                  <div>
                    <h4 style={{ margin: 0, color: '#873800', fontSize: '0.95rem' }}>Stock Alert: {lowStockProducts.length} items are running low!</h4>
                    <p style={{ margin: 0, color: '#614700', fontSize: '0.8rem' }}>Replenish inventory to avoid missing sales during checkout.</p>
                  </div>
                </div>
                <button
                  onClick={() => { setLowStockOnly(true); setActiveTab('inventory'); }}
                  style={{ backgroundColor: '#faad14', color: 'white', border: 'none', padding: '0.4rem 0.8rem', borderRadius: '0.375rem', fontWeight: 'bold', cursor: 'pointer' }}
                >
                  View Low Stock Items
                </button>
              </div>
            )}

            {/* Financial Overview Cards */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1rem' }}>
              <div className="card-hover" style={{ backgroundColor: 'white', padding: '1.25rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#64748b' }}>
                  <span style={{ fontSize: '0.85rem', fontWeight: '600' }}>Today's Revenue</span>
                  <DollarSign size={20} color="#10b981" />
                </div>
                <h2 style={{ fontSize: '1.75rem', fontWeight: 'bold', marginTop: '0.5rem', color: '#10b981' }}>₹{todayRevenue.toFixed(2)}</h2>
                <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Real-time POS aggregate</span>
              </div>

              <div className="card-hover" style={{ backgroundColor: 'white', padding: '1.25rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#64748b' }}>
                  <span style={{ fontSize: '0.85rem', fontWeight: '600' }}>Bills Generated</span>
                  <Receipt size={20} color="#2563eb" />
                </div>
                <h2 style={{ fontSize: '1.75rem', fontWeight: 'bold', marginTop: '0.5rem', color: '#2563eb' }}>{todayInvoicesCount}</h2>
                <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Invoices generated today</span>
              </div>

              <div className="card-hover" style={{ backgroundColor: 'white', padding: '1.25rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#64748b' }}>
                  <span style={{ fontSize: '0.85rem', fontWeight: '600' }}>GST Tax Collected</span>
                  <ShieldCheck size={20} color="#f59e0b" />
                </div>
                <h2 style={{ fontSize: '1.75rem', fontWeight: 'bold', marginTop: '0.5rem', color: '#f59e0b' }}>₹{totalTaxCollected.toFixed(2)}</h2>
                <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Total CGST + SGST + IGST</span>
              </div>

              <div className="card-hover" style={{ backgroundColor: 'white', padding: '1.25rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#64748b' }}>
                  <span style={{ fontSize: '0.85rem', fontWeight: '600' }}>Total Products</span>
                  <Package size={20} color="#8b5cf6" />
                </div>
                <h2 style={{ fontSize: '1.75rem', fontWeight: 'bold', marginTop: '0.5rem', color: '#8b5cf6' }}>{products.length}</h2>
                <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Active inventory items</span>
              </div>
            </div>

            {/* Quick Actions & Recent Invoices */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '1.5rem' }}>
              <div style={{ backgroundColor: 'white', padding: '1.25rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
                <h3 style={{ fontSize: '1.1rem', marginBottom: '1rem', color: '#0f172a' }}>Quick Operations</h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  <button onClick={() => setActiveTab('billing')} style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', width: '100%', padding: '0.8rem', backgroundColor: '#2563eb', color: 'white', border: 'none', borderRadius: '0.5rem', fontWeight: 'bold', cursor: 'pointer' }}>
                    <Plus size={18} /> Create New POS Invoice
                  </button>
                  <button onClick={() => { setEditingProduct(null); setShowProductModal(true); }} style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', width: '100%', padding: '0.8rem', backgroundColor: '#f1f5f9', color: '#0f172a', border: '1px solid #cbd5e1', borderRadius: '0.5rem', fontWeight: '600', cursor: 'pointer' }}>
                    <Package size={18} /> Add Inventory Product
                  </button>
                  <button onClick={() => setShowCustomerModal(true)} style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', width: '100%', padding: '0.8rem', backgroundColor: '#f1f5f9', color: '#0f172a', border: '1px solid #cbd5e1', borderRadius: '0.5rem', fontWeight: '600', cursor: 'pointer' }}>
                    <Users size={18} /> Add Customer Record
                  </button>
                </div>
              </div>

              {/* Recent Transactions List */}
              <div style={{ backgroundColor: 'white', padding: '1.25rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                  <h3 style={{ fontSize: '1.1rem', margin: 0 }}>Recent Bills</h3>
                  <button onClick={() => setActiveTab('invoices')} style={{ background: 'none', border: 'none', color: '#2563eb', fontWeight: 'bold', cursor: 'pointer', fontSize: '0.85rem' }}>View All</button>
                </div>

                {invoices.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>
                    <Receipt size={40} style={{ marginBottom: '0.5rem' }} />
                    <p>No invoices created yet. Click "Create New POS Invoice" to start billing!</p>
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                    {invoices.slice(0, 5).map(inv => (
                      <div key={inv.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem', backgroundColor: '#f8fafc', borderRadius: '0.5rem', border: '1px solid #e2e8f0' }}>
                        <div>
                          <div style={{ fontWeight: 'bold', fontSize: '0.9rem' }}>{inv.invoiceNumber} • {inv.customerName}</div>
                          <div style={{ fontSize: '0.75rem', color: '#64748b' }}>{inv.createdAt} | Mode: {inv.paymentMethod}</div>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ fontWeight: 'bold', color: '#0f172a' }}>₹{inv.grandTotal.toFixed(2)}</div>
                          <span className={`badge ${inv.paymentStatus === 'Paid' ? 'badge-success' : 'badge-danger'}`}>{inv.paymentStatus}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* ================= FAST POS BILLING VIEW ================= */}
        {activeTab === 'billing' && (
          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.5rem', height: 'calc(100vh - 120px)' }}>
            {/* Left Column: Product Catalog & Cart List */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {/* Product Search & Category Barcode Header */}
              <div style={{ backgroundColor: 'white', padding: '1rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
                <div style={{ display: 'flex', gap: '0.75rem', marginBottom: '0.75rem' }}>
                  <div style={{ flex: 1, position: 'relative' }}>
                    <Search size={18} style={{ position: 'absolute', left: '10px', top: '12px', color: '#94a3b8' }} />
                    <input
                      type="text"
                      placeholder="Search product name, SKU, or scan barcode (Press Enter to add)..."
                      value={productSearch}
                      onChange={e => setProductSearch(e.target.value)}
                      onKeyDown={e => {
                        if (e.key === 'Enter' && productSearch.trim()) {
                          const query = productSearch.trim().toLowerCase();
                          const match = products.find(p => (p.itemName || '').toLowerCase().includes(query) || (p.sku || '').toLowerCase() === query);
                          if (match) {
                            addToCart(match);
                            setProductSearch('');
                          }
                        }
                      }}
                      style={{ width: '100%', padding: '0.6rem 0.6rem 0.6rem 2.2rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1', fontSize: '0.9rem' }}
                    />
                  </div>
                  {productSearch && (
                    <button onClick={() => setProductSearch('')} style={{ padding: '0.6rem 0.8rem', backgroundColor: '#f1f5f9', border: '1px solid #cbd5e1', borderRadius: '0.5rem', cursor: 'pointer', fontWeight: 'bold' }}>
                      Clear
                    </button>
                  )}
                </div>

                {/* Category Pills */}
                <div style={{ display: 'flex', gap: '0.5rem', overflowX: 'auto', paddingBottom: '0.5rem', marginBottom: '0.5rem' }}>
                  {['All', ...Array.from(new Set(products.map(p => p.category)))].map(cat => (
                    <button
                      key={cat}
                      onClick={() => setPosCategory(cat)}
                      style={{
                        padding: '0.35rem 0.75rem',
                        borderRadius: '9999px',
                        border: 'none',
                        fontSize: '0.8rem',
                        fontWeight: '600',
                        cursor: 'pointer',
                        backgroundColor: posCategory === cat ? '#2563eb' : '#f1f5f9',
                        color: posCategory === cat ? 'white' : '#64748b'
                      }}
                    >
                      {cat}
                    </button>
                  ))}
                </div>

                {/* Grid of Searchable Products */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: '0.75rem', maxHeight: '200px', overflowY: 'auto' }}>
                  {products
                    .filter(p => {
                      const matchesCategory = posCategory === 'All' || p.category === posCategory;
                      const q = productSearch.toLowerCase();
                      const matchesSearch = (p.itemName || '').toLowerCase().includes(q) || (p.sku || '').toLowerCase().includes(q);
                      return matchesCategory && matchesSearch;
                    })
                    .map(p => (
                      <div
                        key={p.id}
                        onClick={() => addToCart(p)}
                        style={{
                          padding: '0.75rem',
                          backgroundColor: p.stock === 0 ? '#f1f5f9' : '#ffffff',
                          border: '1px solid #e2e8f0',
                          borderRadius: '0.5rem',
                          cursor: p.stock === 0 ? 'not-allowed' : 'pointer',
                          opacity: p.stock === 0 ? 0.5 : 1,
                          transition: 'all 0.2s'
                        }}
                        className="card-hover"
                      >
                        <div style={{ fontWeight: 'bold', fontSize: '0.85rem', color: '#0f172a' }}>{p.itemName}</div>
                        <div style={{ fontSize: '0.75rem', color: '#64748b' }}>₹{p.sellingPrice} / {p.unit} | GST: {p.gstRate}%</div>
                        <div style={{ fontSize: '0.7rem', color: p.stock <= p.threshold ? '#ef4444' : '#10b981', fontWeight: 'bold', marginTop: '0.25rem' }}>
                          Stock: {p.stock} {p.unit}
                        </div>
                      </div>
                    ))}
                </div>
              </div>

              {/* Cart Table List */}
              <div style={{ backgroundColor: 'white', padding: '1rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0', flex: 1, display: 'flex', flexDirection: 'column' }}>
                <h3 style={{ fontSize: '1rem', marginBottom: '0.75rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span>Current Cart Items ({cart.length})</span>
                  {cart.length > 0 && (
                    <button onClick={() => setCart([])} style={{ background: 'none', border: 'none', color: '#ef4444', fontSize: '0.8rem', cursor: 'pointer', fontWeight: 'bold' }}>Empty Cart</button>
                  )}
                </h3>

                {cart.length === 0 ? (
                  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: '#94a3b8' }}>
                    <ShoppingBag size={48} style={{ marginBottom: '0.5rem' }} />
                    <p>Select products from catalog above or scan barcode to start billing</p>
                  </div>
                ) : (
                  <div style={{ flex: 1, overflowY: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
                      <thead>
                        <tr style={{ borderBottom: '2px solid #e2e8f0', textAlign: 'left', color: '#64748b' }}>
                          <th style={{ padding: '0.5rem' }}>Item</th>
                          <th style={{ padding: '0.5rem' }}>Price</th>
                          <th style={{ padding: '0.5rem', textAlign: 'center' }}>Qty</th>
                          <th style={{ padding: '0.5rem' }}>GST %</th>
                          <th style={{ padding: '0.5rem', textAlign: 'right' }}>Total</th>
                          <th style={{ padding: '0.5rem', textAlign: 'center' }}>Action</th>
                        </tr>
                      </thead>
                      <tbody>
                        {cart.map((item, idx) => (
                          <tr key={idx} style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <td style={{ padding: '0.5rem', fontWeight: '600' }}>{item.product.itemName}</td>
                            <td style={{ padding: '0.5rem' }}>₹{item.product.sellingPrice}</td>
                            <td style={{ padding: '0.5rem', textAlign: 'center' }}>
                              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '0.4rem', backgroundColor: '#f1f5f9', borderRadius: '0.375rem', padding: '0.2rem 0.4rem' }}>
                                <button onClick={() => updateCartQty(item.product.id, -1)} style={{ border: 'none', background: 'none', cursor: 'pointer', fontWeight: 'bold' }}>-</button>
                                <span style={{ fontWeight: 'bold' }}>{item.qty}</span>
                                <button onClick={() => updateCartQty(item.product.id, 1)} style={{ border: 'none', background: 'none', cursor: 'pointer', fontWeight: 'bold' }}>+</button>
                              </div>
                            </td>
                            <td style={{ padding: '0.5rem' }}>{item.product.gstRate}%</td>
                            <td style={{ padding: '0.5rem', textAlign: 'right', fontWeight: 'bold', color: '#0f172a' }}>
                              ₹{((item.product.sellingPrice * item.qty) * (1 + item.product.gstRate / 100)).toFixed(2)}
                            </td>
                            <td style={{ padding: '0.5rem', textAlign: 'center' }}>
                              <button
                                onClick={() => setCart(cart.filter(c => c.product.id !== item.product.id))}
                                style={{ border: 'none', background: 'none', color: '#ef4444', cursor: 'pointer' }}
                              >
                                <Trash2 size={16} />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>

            {/* Right Column: Tax Breakdown, Customer & Checkout */}
            <div style={{ backgroundColor: 'white', padding: '1.25rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                <h3 style={{ fontSize: '1.1rem', margin: 0 }}>Bill Summary & Checkout</h3>

                {/* Customer Attachment Selector */}
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: '600', color: '#64748b' }}>Select Customer</label>
                  <select
                    value={selectedCustomer ? selectedCustomer.id : 'walkin'}
                    onChange={e => {
                      if (e.target.value === 'walkin') setSelectedCustomer(null);
                      else setSelectedCustomer(customers.find(c => c.id === e.target.value));
                    }}
                    style={{ width: '100%', padding: '0.6rem', marginTop: '0.25rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                  >
                    <option value="walkin">Walk-in Customer</option>
                    {customers.map(c => (
                      <option key={c.id} value={c.id}>{c.name} ({c.phone})</option>
                    ))}
                  </select>
                </div>

                {!selectedCustomer && (
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
                    <input
                      type="text"
                      placeholder="Walk-in Name"
                      value={walkInName}
                      onChange={e => setWalkInName(e.target.value)}
                      style={{ padding: '0.5rem', borderRadius: '0.375rem', border: '1px solid #cbd5e1', fontSize: '0.8rem' }}
                    />
                    <input
                      type="text"
                      placeholder="Phone Number"
                      value={walkInPhone}
                      onChange={e => setWalkInPhone(e.target.value)}
                      style={{ padding: '0.5rem', borderRadius: '0.375rem', border: '1px solid #cbd5e1', fontSize: '0.8rem' }}
                    />
                  </div>
                )}

                {/* Tax Configuration Mode */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#f8fafc', padding: '0.6rem', borderRadius: '0.5rem' }}>
                  <span style={{ fontSize: '0.85rem', fontWeight: '600' }}>Interstate Sale (IGST)</span>
                  <input
                    type="checkbox"
                    checked={isInterStateTax}
                    onChange={e => setIsInterStateTax(e.target.checked)}
                    style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                  />
                </div>

                {/* Flat Discount Input */}
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: '600', color: '#64748b' }}>Flat Bill Discount (₹)</label>
                  <input
                    type="number"
                    min="0"
                    placeholder="0.00"
                    value={flatDiscount || ''}
                    onChange={e => setFlatDiscount(parseFloat(e.target.value) || 0)}
                    style={{ width: '100%', padding: '0.5rem', marginTop: '0.25rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                  />
                </div>

                {/* Payment Method Selector */}
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: '600', color: '#64748b' }}>Payment Method</label>
                  <select
                    value={paymentMethod}
                    onChange={e => setPaymentMethod(e.target.value)}
                    style={{ width: '100%', padding: '0.6rem', marginTop: '0.25rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                  >
                    <option value="Cash">Cash</option>
                    <option value="UPI/Online">UPI / Online Payment</option>
                    <option value="Credit/Pending">Credit / Pending (Udhar Ledger)</option>
                  </select>
                </div>

                {/* Cash Tender Calculator */}
                {paymentMethod === 'Cash' && (
                  <div style={{ backgroundColor: '#fffbe6', padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #ffe58f' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#873800' }}>Amount Received (₹):</label>
                    <input
                      type="number"
                      placeholder={`e.g. ${Math.ceil(grandTotal)}`}
                      value={amountReceived}
                      onChange={e => setAmountReceived(e.target.value)}
                      style={{ width: '100%', padding: '0.4rem', marginTop: '0.2rem', borderRadius: '0.375rem', border: '1px solid #d9d9d9' }}
                    />
                    {amountReceived && parseFloat(amountReceived) >= grandTotal && (
                      <div style={{ marginTop: '0.4rem', fontSize: '0.85rem', fontWeight: 'bold', color: '#10b981' }}>
                        Change to Return: ₹{(parseFloat(amountReceived) - grandTotal).toFixed(2)}
                      </div>
                    )}
                  </div>
                )}

                {/* Financial Tax Summary Box */}
                <div style={{ backgroundColor: '#f1f5f9', padding: '0.85rem', borderRadius: '0.5rem', display: 'flex', flexDirection: 'column', gap: '0.4rem', fontSize: '0.85rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: '#64748b' }}>Subtotal:</span>
                    <span style={{ fontWeight: '600' }}>₹{subTotal.toFixed(2)}</span>
                  </div>
                  {flatDiscount > 0 && (
                    <div style={{ display: 'flex', justifyContent: 'space-between', color: '#ef4444' }}>
                      <span>Discount:</span>
                      <span>-₹{flatDiscount.toFixed(2)}</span>
                    </div>
                  )}
                  {!isInterStateTax ? (
                    <>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ color: '#64748b' }}>CGST:</span>
                        <span>₹{cgst.toFixed(2)}</span>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ color: '#64748b' }}>SGST:</span>
                        <span>₹{sgst.toFixed(2)}</span>
                      </div>
                    </>
                  ) : (
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span style={{ color: '#64748b' }}>IGST:</span>
                      <span>₹{igst.toFixed(2)}</span>
                    </div>
                  )}
                  <div style={{ display: 'flex', justifyContent: 'space-between', borderTop: '1px solid #cbd5e1', paddingTop: '0.4rem', fontWeight: 'bold', fontSize: '1.15rem', color: '#0f172a' }}>
                    <span>Grand Total:</span>
                    <span style={{ color: '#2563eb' }}>₹{grandTotal.toFixed(2)}</span>
                  </div>
                </div>
              </div>

              {/* Checkout Button */}
              <button
                disabled={cart.length === 0}
                onClick={handleCheckout}
                style={{
                  width: '100%',
                  padding: '1rem',
                  backgroundColor: cart.length === 0 ? '#cbd5e1' : '#10b981',
                  color: 'white',
                  border: 'none',
                  borderRadius: '0.5rem',
                  fontWeight: 'bold',
                  fontSize: '1rem',
                  cursor: cart.length === 0 ? 'not-allowed' : 'pointer',
                  marginTop: '0.75rem',
                  transition: 'all 0.2s'
                }}
              >
                CHECKOUT & PRINT INVOICE
              </button>
            </div>
          </div>
        )}

        {/* ================= INVENTORY MANAGEMENT VIEW ================= */}
        {activeTab === 'inventory' && (
          <div style={{ backgroundColor: 'white', padding: '1.5rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              <div>
                <h2 style={{ fontSize: '1.25rem', margin: 0 }}>Inventory & Stock Management</h2>
                <p style={{ fontSize: '0.8rem', color: '#64748b', margin: 0 }}>Manage products, prices, low stock alerts, and GST tax categories</p>
              </div>
              <div style={{ display: 'flex', gap: '0.75rem' }}>
                <button
                  onClick={() => setLowStockOnly(!lowStockOnly)}
                  style={{
                    padding: '0.6rem 1rem',
                    borderRadius: '0.5rem',
                    border: '1px solid #cbd5e1',
                    backgroundColor: lowStockOnly ? '#fef3c7' : 'white',
                    color: lowStockOnly ? '#92400e' : '#0f172a',
                    fontWeight: 'bold',
                    cursor: 'pointer'
                  }}
                >
                  {lowStockOnly ? 'Show All Products' : 'Low Stock Filter'}
                </button>
                <button
                  onClick={() => { setEditingProduct(null); setShowProductModal(true); }}
                  style={{ padding: '0.6rem 1rem', backgroundColor: '#2563eb', color: 'white', border: 'none', borderRadius: '0.5rem', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.5rem' }}
                >
                  <Plus size={18} /> Add New Product
                </button>
              </div>
            </div>

            {/* Inventory Table */}
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.9rem' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid #e2e8f0', textAlign: 'left', color: '#64748b' }}>
                  <th style={{ padding: '0.75rem' }}>Item Name</th>
                  <th style={{ padding: '0.75rem' }}>SKU / Barcode</th>
                  <th style={{ padding: '0.75rem' }}>Category</th>
                  <th style={{ padding: '0.75rem' }}>Cost Price</th>
                  <th style={{ padding: '0.75rem' }}>Selling Price</th>
                  <th style={{ padding: '0.75rem' }}>GST %</th>
                  <th style={{ padding: '0.75rem' }}>Stock Qty</th>
                  <th style={{ padding: '0.75rem', textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {products
                  .filter(p => !lowStockOnly || p.stock <= p.threshold)
                  .map(p => (
                    <tr key={p.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                      <td style={{ padding: '0.75rem', fontWeight: 'bold' }}>{p.itemName}</td>
                      <td style={{ padding: '0.75rem', color: '#64748b' }}>{p.sku}</td>
                      <td style={{ padding: '0.75rem' }}><span className="badge badge-primary">{p.category}</span></td>
                      <td style={{ padding: '0.75rem' }}>₹{p.costPrice}</td>
                      <td style={{ padding: '0.75rem', fontWeight: 'bold', color: '#0f172a' }}>₹{p.sellingPrice}</td>
                      <td style={{ padding: '0.75rem' }}>{p.gstRate}%</td>
                      <td style={{ padding: '0.75rem' }}>
                        <span className={`badge ${p.stock <= p.threshold ? 'badge-danger' : 'badge-success'}`}>
                          {p.stock} {p.unit}
                        </span>
                      </td>
                      <td style={{ padding: '0.75rem', textAlign: 'right' }}>
                        <button
                          onClick={() => { setEditingProduct(p); setShowProductModal(true); }}
                          style={{ border: 'none', background: 'none', color: '#2563eb', cursor: 'pointer', marginRight: '0.5rem' }}
                        >
                          <Edit size={18} />
                        </button>
                        <button
                          onClick={() => setProducts(products.filter(item => item.id !== p.id))}
                          style={{ border: 'none', background: 'none', color: '#ef4444', cursor: 'pointer' }}
                        >
                          <Trash2 size={18} />
                        </button>
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        )}

        {/* ================= CUSTOMERS VIEW ================= */}
        {activeTab === 'customers' && (
          <div style={{ backgroundColor: 'white', padding: '1.5rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              <div>
                <h2 style={{ fontSize: '1.25rem', margin: 0 }}>Customer Directory & Udhar Ledger</h2>
                <p style={{ fontSize: '0.8rem', color: '#64748b', margin: 0 }}>Track customer credit balances and contact information</p>
              </div>
              <button
                onClick={() => setShowCustomerModal(true)}
                style={{ padding: '0.6rem 1rem', backgroundColor: '#2563eb', color: 'white', border: 'none', borderRadius: '0.5rem', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.5rem' }}
              >
                <Plus size={18} /> Add Customer
              </button>
            </div>

            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.9rem' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid #e2e8f0', textAlign: 'left', color: '#64748b' }}>
                  <th style={{ padding: '0.75rem' }}>Customer Name</th>
                  <th style={{ padding: '0.75rem' }}>Phone</th>
                  <th style={{ padding: '0.75rem' }}>Email</th>
                  <th style={{ padding: '0.75rem' }}>Outstanding Balance</th>
                  <th style={{ padding: '0.75rem', textAlign: 'right' }}>Status</th>
                </tr>
              </thead>
              <tbody>
                {customers.map(c => (
                  <tr key={c.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <td style={{ padding: '0.75rem', fontWeight: 'bold' }}>{c.name}</td>
                    <td style={{ padding: '0.75rem' }}>{c.phone}</td>
                    <td style={{ padding: '0.75rem', color: '#64748b' }}>{c.email || 'N/A'}</td>
                    <td style={{ padding: '0.75rem', fontWeight: 'bold', color: c.balance > 0 ? '#ef4444' : '#10b981' }}>₹{c.balance.toFixed(2)}</td>
                    <td style={{ padding: '0.75rem', textAlign: 'right' }}>
                      <span className={`badge ${c.balance > 0 ? 'badge-danger' : 'badge-success'}`}>
                        {c.balance > 0 ? 'Credit Outstanding' : 'Settled'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* ================= INVOICE HISTORY VIEW ================= */}
        {activeTab === 'invoices' && (
          <div style={{ backgroundColor: 'white', padding: '1.5rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
            <h2 style={{ fontSize: '1.25rem', marginBottom: '1rem' }}>Invoice History Audit Log</h2>

            {invoices.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '3rem', color: '#94a3b8' }}>
                <History size={48} style={{ marginBottom: '0.5rem' }} />
                <p>No transactions logged yet.</p>
              </div>
            ) : (
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.9rem' }}>
                <thead>
                  <tr style={{ borderBottom: '2px solid #e2e8f0', textAlign: 'left', color: '#64748b' }}>
                    <th style={{ padding: '0.75rem' }}>Invoice #</th>
                    <th style={{ padding: '0.75rem' }}>Customer</th>
                    <th style={{ padding: '0.75rem' }}>Date</th>
                    <th style={{ padding: '0.75rem' }}>Payment</th>
                    <th style={{ padding: '0.75rem' }}>Total Tax</th>
                    <th style={{ padding: '0.75rem' }}>Grand Total</th>
                    <th style={{ padding: '0.75rem', textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {invoices.map(inv => (
                    <tr key={inv.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                      <td style={{ padding: '0.75rem', fontWeight: 'bold', color: '#2563eb' }}>{inv.invoiceNumber}</td>
                      <td style={{ padding: '0.75rem' }}>{inv.customerName}</td>
                      <td style={{ padding: '0.75rem', color: '#64748b' }}>{inv.createdAt}</td>
                      <td style={{ padding: '0.75rem' }}>{inv.paymentMethod}</td>
                      <td style={{ padding: '0.75rem' }}>₹{inv.totalTax.toFixed(2)}</td>
                      <td style={{ padding: '0.75rem', fontWeight: 'bold' }}>₹{inv.grandTotal.toFixed(2)}</td>
                      <td style={{ padding: '0.75rem', textAlign: 'right' }}>
                        <button
                          onClick={() => { setActiveInvoice(inv); setShowInvoiceModal(true); }}
                          style={{ border: 'none', background: '#2563eb', color: 'white', padding: '0.3rem 0.6rem', borderRadius: '0.375rem', cursor: 'pointer', fontSize: '0.8rem' }}
                        >
                          View PDF
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )}
      </main>

      {/* ================= MODAL: ADD / EDIT PRODUCT ================= */}
      {showProductModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ padding: '1.5rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h3 style={{ margin: 0 }}>{editingProduct ? 'Edit Product' : 'Add Inventory Product'}</h3>
              <button onClick={() => setShowProductModal(false)} style={{ border: 'none', background: 'none', cursor: 'pointer' }}><X size={20} /></button>
            </div>
            <form onSubmit={e => {
              e.preventDefault();
              const formData = new FormData(e.target);
              const newProd = {
                id: editingProduct ? editingProduct.id : `p_${Date.now()}`,
                itemName: formData.get('name'),
                sku: formData.get('sku'),
                category: formData.get('category'),
                costPrice: parseFloat(formData.get('costPrice')) || 0,
                sellingPrice: parseFloat(formData.get('sellingPrice')) || 0,
                stock: parseInt(formData.get('stock')) || 0,
                threshold: parseInt(formData.get('threshold')) || 5,
                unit: formData.get('unit'),
                gstRate: parseFloat(formData.get('gstRate')) || 18
              };
              if (editingProduct) {
                setProducts(products.map(p => p.id === editingProduct.id ? newProd : p));
              } else {
                setProducts([...products, newProd]);
              }
              setShowProductModal(false);
            }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                <input name="name" defaultValue={editingProduct?.itemName} placeholder="Product Name *" required style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }} />
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                  <input name="sku" defaultValue={editingProduct?.sku} placeholder="SKU / Barcode" style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }} />
                  <input name="category" defaultValue={editingProduct?.category || 'Groceries'} placeholder="Category" style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }} />
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                  <input name="costPrice" type="number" step="0.01" defaultValue={editingProduct?.costPrice} placeholder="Cost Price (₹)" style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }} />
                  <input name="sellingPrice" type="number" step="0.01" defaultValue={editingProduct?.sellingPrice} placeholder="Selling Price (₹) *" required style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }} />
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                  <input name="stock" type="number" defaultValue={editingProduct?.stock || 10} placeholder="Stock Qty *" required style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }} />
                  <select name="unit" defaultValue={editingProduct?.unit || 'Pcs'} style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}>
                    <option value="Pcs">Pcs</option>
                    <option value="Kg">Kg</option>
                    <option value="Ltr">Ltr</option>
                    <option value="Box">Box</option>
                    <option value="Pack">Pack</option>
                  </select>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                  <select name="gstRate" defaultValue={editingProduct?.gstRate || 18} style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}>
                    <option value="0">0% GST</option>
                    <option value="5">5% GST</option>
                    <option value="12">12% GST</option>
                    <option value="18">18% GST</option>
                    <option value="28">28% GST</option>
                  </select>
                  <input name="threshold" type="number" defaultValue={editingProduct?.threshold || 5} placeholder="Low Stock Alert Qty" style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }} />
                </div>
                <button type="submit" style={{ padding: '0.8rem', backgroundColor: '#2563eb', color: 'white', border: 'none', borderRadius: '0.5rem', fontWeight: 'bold', cursor: 'pointer', marginTop: '0.5rem' }}>
                  {editingProduct ? 'Update Product' : 'Save Product'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ================= MODAL: ADD CUSTOMER ================= */}
      {showCustomerModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ padding: '1.5rem', maxWidth: '450px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h3 style={{ margin: 0 }}>Add Customer Record</h3>
              <button onClick={() => setShowCustomerModal(false)} style={{ border: 'none', background: 'none', cursor: 'pointer' }}><X size={20} /></button>
            </div>
            <form onSubmit={e => {
              e.preventDefault();
              const formData = new FormData(e.target);
              const newCust = {
                id: `c_${Date.now()}`,
                name: formData.get('name'),
                phone: formData.get('phone'),
                email: formData.get('email'),
                balance: 0
              };
              setCustomers([...customers, newCust]);
              setShowCustomerModal(false);
            }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                <input name="name" placeholder="Customer Name *" required style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }} />
                <input name="phone" placeholder="Phone Number *" required style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }} />
                <input name="email" type="email" placeholder="Email Address" style={{ padding: '0.6rem', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }} />
                <button type="submit" style={{ padding: '0.8rem', backgroundColor: '#2563eb', color: 'white', border: 'none', borderRadius: '0.5rem', fontWeight: 'bold', cursor: 'pointer' }}>
                  Save Customer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ================= MODAL: PRINTABLE PDF TAX INVOICE PREVIEW ================= */}
      {showInvoiceModal && activeInvoice && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '750px', padding: '1.5rem' }}>
            {/* Toolbar Buttons */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', borderBottom: '1px solid #e2e8f0', paddingBottom: '0.75rem' }}>
              <h3 style={{ margin: 0 }}>Tax Invoice #{activeInvoice.invoiceNumber}</h3>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button onClick={handlePrint} style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', padding: '0.4rem 0.8rem', backgroundColor: '#0f172a', color: 'white', border: 'none', borderRadius: '0.375rem', cursor: 'pointer', fontSize: '0.85rem' }}>
                  <Printer size={16} /> Print
                </button>
                <button onClick={handleDownloadPDF} style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', padding: '0.4rem 0.8rem', backgroundColor: '#2563eb', color: 'white', border: 'none', borderRadius: '0.375rem', cursor: 'pointer', fontSize: '0.85rem' }}>
                  <Download size={16} /> Download PDF
                </button>
                <button onClick={handleShareWhatsApp} style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', padding: '0.4rem 0.8rem', backgroundColor: '#10b981', color: 'white', border: 'none', borderRadius: '0.375rem', cursor: 'pointer', fontSize: '0.85rem' }}>
                  <Share2 size={16} /> WhatsApp
                </button>
                <button onClick={() => setShowInvoiceModal(false)} style={{ border: 'none', background: 'none', cursor: 'pointer', marginLeft: '0.5rem' }}>
                  <X size={20} />
                </button>
              </div>
            </div>

            {/* Printable Thermal/A4 Invoice Document */}
            <div id="printable-invoice" ref={invoicePrintRef} style={{ padding: '1.5rem', backgroundColor: 'white', border: '1px solid #cbd5e1', borderRadius: '0.5rem', fontFamily: 'Inter, sans-serif' }}>
              {/* Header Details */}
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '2px solid #0f172a', paddingBottom: '1rem', marginBottom: '1rem' }}>
                <div>
                  <h2 style={{ fontSize: '1.5rem', color: '#0f172a', margin: 0 }}>{business.shopName}</h2>
                  <p style={{ fontSize: '0.8rem', color: '#64748b', margin: '0.2rem 0' }}>{business.address}</p>
                  <p style={{ fontSize: '0.8rem', color: '#64748b', margin: 0 }}>Phone: {business.contact} | GSTIN: {business.gstin}</p>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ backgroundColor: '#0f172a', color: 'white', padding: '0.3rem 0.8rem', borderRadius: '0.25rem', fontWeight: 'bold', fontSize: '0.9rem', display: 'inline-block' }}>
                    TAX INVOICE
                  </div>
                  <p style={{ fontSize: '0.85rem', fontWeight: 'bold', margin: '0.4rem 0 0 0' }}>Invoice #: {activeInvoice.invoiceNumber}</p>
                  <p style={{ fontSize: '0.75rem', color: '#64748b', margin: 0 }}>Date: {activeInvoice.createdAt}</p>
                </div>
              </div>

              {/* Billed To Details */}
              <div style={{ backgroundColor: '#f8fafc', padding: '0.75rem', borderRadius: '0.375rem', marginBottom: '1rem', display: 'flex', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ fontSize: '0.75rem', color: '#64748b' }}>Billed To:</div>
                  <div style={{ fontWeight: 'bold', fontSize: '0.95rem' }}>{activeInvoice.customerName}</div>
                  {activeInvoice.customerPhone && <div style={{ fontSize: '0.8rem', color: '#64748b' }}>Phone: {activeInvoice.customerPhone}</div>}
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: '0.8rem' }}>Payment Mode: <strong>{activeInvoice.paymentMethod}</strong></div>
                  <div style={{ fontSize: '0.8rem' }}>Status: <strong style={{ color: activeInvoice.paymentStatus === 'Paid' ? '#10b981' : '#ef4444' }}>{activeInvoice.paymentStatus}</strong></div>
                </div>
              </div>

              {/* Items Table */}
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem', marginBottom: '1rem' }}>
                <thead>
                  <tr style={{ backgroundColor: '#0f172a', color: 'white' }}>
                    <th style={{ padding: '0.5rem', textAlign: 'left' }}>Item</th>
                    <th style={{ padding: '0.5rem', textAlign: 'right' }}>Qty</th>
                    <th style={{ padding: '0.5rem', textAlign: 'right' }}>Rate</th>
                    <th style={{ padding: '0.5rem', textAlign: 'right' }}>GST %</th>
                    <th style={{ padding: '0.5rem', textAlign: 'right' }}>Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {activeInvoice.items.map((item, idx) => (
                    <tr key={idx} style={{ borderBottom: '1px solid #e2e8f0' }}>
                      <td style={{ padding: '0.5rem' }}>{item.name}</td>
                      <td style={{ padding: '0.5rem', textAlign: 'right' }}>{item.qty} {item.unit}</td>
                      <td style={{ padding: '0.5rem', textAlign: 'right' }}>₹{item.price.toFixed(2)}</td>
                      <td style={{ padding: '0.5rem', textAlign: 'right' }}>{item.gstRate}%</td>
                      <td style={{ padding: '0.5rem', textAlign: 'right', fontWeight: 'bold' }}>₹{item.total.toFixed(2)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {/* Tax Summary & Grand Total */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ fontSize: '0.75rem', color: '#64748b', border: '1px solid #e2e8f0', padding: '0.5rem 0.75rem', borderRadius: '0.25rem', width: '220px' }}>
                  <div style={{ fontWeight: 'bold', marginBottom: '0.2rem' }}>GST Tax Breakdown:</div>
                  {activeInvoice.cgst > 0 && <div>CGST Total: ₹{activeInvoice.cgst.toFixed(2)}</div>}
                  {activeInvoice.sgst > 0 && <div>SGST Total: ₹{activeInvoice.sgst.toFixed(2)}</div>}
                  {activeInvoice.igst > 0 && <div>IGST Total: ₹{activeInvoice.igst.toFixed(2)}</div>}
                </div>
                <div style={{ width: '240px', fontSize: '0.9rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.2rem 0' }}>
                    <span>Subtotal:</span>
                    <span>₹{activeInvoice.subTotal.toFixed(2)}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.2rem 0' }}>
                    <span>Total Tax:</span>
                    <span>₹{activeInvoice.totalTax.toFixed(2)}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', borderTop: '2px solid #0f172a', paddingTop: '0.4rem', fontWeight: 'bold', fontSize: '1.1rem', color: '#0f172a' }}>
                    <span>Grand Total:</span>
                    <span style={{ color: '#2563eb' }}>₹{activeInvoice.grandTotal.toFixed(2)}</span>
                  </div>
                </div>
              </div>

              <div style={{ textAlign: 'center', marginTop: '1.5rem', paddingTop: '1rem', borderTop: '1px dashed #cbd5e1', fontSize: '0.75rem', color: '#64748b' }}>
                Thank you for your business! | Generated via BillFlow Smart Billing Application
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
