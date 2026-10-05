# BillFlow – Smart Billing & Inventory Application 🧾
**TYIT SEM 5 (2026–27) – CEP Project under NEP Curriculum**
**Student:** Vaibhav Vivek Singh (Roll No. 64)

---

## 📌 Project Overview
**BillFlow** is a modern, cross-platform Flutter & Firebase mobile application designed for local shopkeepers, retailers, supermarkets, medical stores, and small businesses. It replaces manual handwritten billing with a fast, digital, and automated POS system featuring real-time inventory tracking, automatic GST calculation (CGST + SGST or IGST), customer ledger management, and instant PDF invoice printing & sharing via WhatsApp and Email.

---

## 🚀 Key Features & Modules
1. **Authentication & Store Profile:**
   - Email & Phone authentication via Firebase Auth.
   - Store registration: Shop Name, Owner Name, Address, Contact Number, and GSTIN.
2. **Product & Inventory Management:**
   - Full CRUD operations with Item Name, SKU/Barcode, Category, Cost Price, Selling Price, Unit, and GST %.
   - Real-time stock decrement on bill generation.
   - Low-stock visual highlight and quick alert filters.
3. **Fast Billing & POS Cart:**
   - Dynamic product search & instant cart addition.
   - Dynamic quantity adjustment (+/-) & line-item/flat discounts.
   - Real-time GST calculation (CGST/SGST split or IGST toggle).
   - Customer attachment (Walk-in or registered customer).
   - Flexible Payment Modes: Cash, UPI/Online, and Credit/Pending (Udhar Ledger).
4. **PDF Invoice Generation & Sharing:**
   - Instant A4 & Thermal PDF tax invoice rendering using `pdf` & `printing`.
   - Export & Share directly to **WhatsApp** and **Email** using `share_plus`.
5. **Customer Ledger & Dashboard Analytics:**
   - Customer purchase history and outstanding balances.
   - Financial sales summary: Today's Revenue, Today's Bill Count, Monthly Sales, and Total Tax Collected.

---

## 📂 Project Architecture

```
lib/
├── main.dart                       # Entry point & Provider configuration
├── constants/
│   ├── app_colors.dart             # Corporate Slate & Blue Design System
│   └── app_theme.dart              # Typography & Material 3 Theme
├── models/
│   ├── user_model.dart             # User profile data model
│   ├── business_model.dart         # Shop & GST profile model
│   ├── product_model.dart          # Inventory item & stock alert model
│   ├── customer_model.dart         # Customer ledger data model
│   └── invoice_model.dart          # Invoice & line item models
├── repositories/
│   ├── auth_repository.dart        # Firebase Auth API handler
│   ├── business_repository.dart    # Firestore Business collection API
│   ├── inventory_repository.dart   # Stock CRUD & atomic batch updates
│   ├── customer_repository.dart    # Customer collection & ledger balance
│   └── invoice_repository.dart     # Firestore atomic batch invoice creation
├── providers/
│   ├── auth_provider.dart          # User Auth State Manager
│   ├── business_provider.dart      # Business Store State Manager
│   ├── inventory_provider.dart     # Inventory & Stock Filter State Manager
│   ├── cart_provider.dart          # Dynamic Cart & Tax Calculation State
│   ├── customer_provider.dart      # Customer Ledger State Manager
│   └── invoice_provider.dart       # Invoice History & Analytics State
├── services/
│   ├── pdf_invoice_service.dart    # PDF Generator engine
│   └── share_service.dart          # WhatsApp & Email share plugin wrapper
└── views/
    ├── auth/                       # Login & Business Setup screens
    ├── dashboard/                  # Sales Analytics Hub
    ├── billing/                    # Fast Billing POS & PDF Preview
    ├── inventory/                  # Inventory listing & Add/Edit modal
    ├── customers/                  # Customer directory & outstanding balances
    └── invoices/                   # Historical Invoice log & search
```

---

## 🛠 Setup & Run Instructions

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.0.0 or higher)
- Android Studio / VS Code with Flutter extension
- Firebase project configured on Google Cloud / Firebase Console

### 2. Install Dependencies
In the root directory of the application, run:
```bash
flutter pub get
```

### 3. Firebase Configuration
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication** (Email/Password & Phone).
3. Enable **Cloud Firestore** and deploy `firestore.rules`.
4. Enable **Firebase Storage** and deploy `storage.rules`.
5. Add Android app (`com.billflow.app`) and download `google-services.json` to `android/app/`.
6. Add iOS app and download `GoogleService-Info.plist` to `ios/Runner/`.

### 4. Run Application
```bash
# Run on connected Android / iOS device or emulator
flutter run
```

---

## 📜 Security & Multi-Tenancy
Multi-tenancy isolation is enforced at the database level using `firestore.rules` and `storage.rules`. Every query requires authentication and checks that `request.auth.uid` matches the shop `ownerId`.
