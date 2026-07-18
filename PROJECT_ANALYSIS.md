# YT-Uploader Project Analysis

**Status**: Existing Production Project  
**Deployment**: Render (backend already deployed)  
**Date**: 2026-07-18

---

## 1. CURRENT PROJECT ARCHITECTURE

### Backend (Node.js/Express)
- **Framework**: Express.js
- **Database**: MongoDB
- **Auth**: JWT + Google OAuth
- **Deployment**: Render
- **Core Features**:
  - Google authentication & JWT
  - YouTube OAuth integration
  - Video scheduling (via node-cron)
  - Payment transaction management
  - User role management (USER/ADMIN)
  - Admin panel functionality

### Frontend (Flutter)
- **Framework**: Flutter 3.3.0+
- **State Management**: Provider
- **HTTP Client**: http
- **Storage**: shared_preferences, flutter_secure_storage
- **Current Screens**:
  - AuthScreen (login)
  - DashboardScreen (main navigation)

---

## 2. CURRENT DATABASE MODELS

### User Model
```
- googleId (unique)
- email (unique)
- username
- youtubeChannelName
- encryptedRefreshToken
- diamondBalance (default: 0)
- role (USER/ADMIN)
- isSessionActive
- timestamps
```

### Transaction Model
```
- userId (ref: User)
- username
- amount
- diamondsCredited
- status (PENDING/APPROVED/REJECTED)
- timestamp
- timestamps
```

### ScheduledVideo Model
```
- userId (ref: User)
- title
- description
- tags []
- scheduledAt (Date)
- status (PENDING/UPLOADING/SUCCESS/FAILED)
- storageProvider
- remoteFileId
- timestamps
```

---

## 3. CURRENT BACKEND API ROUTES

### Authentication Routes (`/api/auth`)
- `POST /google-login` - Google authentication
- `POST /register` - User registration (via Google)
- `POST /youtube-connect` - Connect YouTube account

### Payment Routes (`/api/payments`)
- `POST /create` - Create payment transaction
- `POST /approve` - Admin approve payment
- `POST /reject` - Admin reject payment

### Upload Routes (`/api/uploads`)
- [To be explored]

### Schedule Routes (`/api/schedules`)
- [To be explored]

### Admin Routes (`/api/admin`)
- [To be explored]

### Existing Middleware
- `requireAuth` - JWT verification
- `requireAdmin` - Admin role check

---

## 4. CURRENT DEPENDENCIES

### Backend
- express, cors, helmet, morgan (HTTP)
- mongoose (Database)
- jsonwebtoken (Auth)
- googleapis, google-auth-library (YouTube)
- cloudinary (Image storage)
- multer (File upload)
- node-cron (Scheduling)
- express-rate-limit (Rate limiting)
- dotenv (Config)
- uuid (ID generation)

### Frontend
- provider (State)
- http (API)
- shared_preferences (Local storage)
- flutter_secure_storage (Secure storage)
- url_launcher (External links)
- intl (Internationalization)

---

## 5. REQUIRED UPGRADES (Per MASTER_UPDATE_PROMPT.md)

### Phase A: Payment System Redesign
**Current State**: Transaction ID/UTR verification system  
**Required State**: 
- Secure payment URL generation (with user ID, package, timestamp, token)
- Admin-managed payment settings (QR, UPI, merchant name, instructions)
- Payment settings API endpoints
- Updated payment flow (no UTR/screenshot input)

**New Database Needs**:
- PaymentSettings collection (admin-managed)
- Enhanced Payment/Transaction model

**New API Endpoints Required**:
- `GET /api/payment/settings` - Get public payment settings
- `GET /api/admin/payment-settings` - Get current settings (admin)
- `PUT /api/admin/payment-settings` - Update payment settings (admin)
- `GET /api/payments/request/:paymentId` - Get specific payment request status

### Phase B: Wallet System
**Current State**: diamondBalance field on User model  
**Required State**:
- Dedicated Wallet model
- Transaction history
- Purchase history
- Pending/Rejected request tracking

**New Database Needs**:
- Wallet collection (with detailed breakdown)
- WalletHistory collection (for audit trail)

### Phase C: Admin Dashboard
**Current State**: Basic admin routes  
**Required State**:
- Payment request management (pending/approved/rejected)
- User search functionality
- Payment ID search
- Analytics and reporting
- CSV export

### Phase D: Frontend UI Update
**Current State**: 2 basic screens (Auth + Dashboard)  
**Required State**: 15 screens (per UI design):
1. Splash screen
2-4. Onboarding (3 screens)
5. Login screen
6. Username setup
7. Dashboard (home)
8. Upload video
9. Schedule video
10. Upload progress
11. Upcoming videos
12. Analytics
13. Diamond store
14. Wallet
15. Profile & Settings

**Design Requirements**:
- Dark theme with purple/violet accents
- Glass morphism effects
- Rounded corners & smooth animations
- Bottom navigation (5 main sections)
- Professional SaaS feel
- Responsive layout

---

## 6. CRITICAL PRESERVATION REQUIREMENTS

### ✅ DO NOT CHANGE
- Render deployment configuration
- Existing API routes (unless explicitly required)
- Google OAuth implementation
- JWT authentication
- YouTube integration
- Database schema structure (only extend, don't replace)
- Existing User, ScheduledVideo models
- Current project folder structure
- GitHub repository configuration

### ✅ SAFE TO ADD/UPDATE
- New database models (PaymentSettings, Wallet, WalletHistory)
- New API routes for payment settings & wallet
- Frontend UI (complete overhaul)
- Frontend state management (can be enhanced)
- Frontend screens (add all 15 new screens)
- Backend validators & middleware (add new ones)
- Security enhancements (rate limiting, CSRF, etc.)

---

## 7. IMPLEMENTATION STRATEGY

### Step 1: Backend Enhancements
1. Create new models: PaymentSettings, Wallet, WalletHistory
2. Add new API endpoints for payment settings management
3. Create admin settings endpoints
4. Update Transaction model with secure token & payment URL support
5. Add wallet transaction logging

### Step 2: Frontend Structure
1. Create complete screen hierarchy (15 screens)
2. Set up comprehensive routing/navigation
3. Build bottom navigation system
4. Create reusable UI components

### Step 3: Frontend Implementation
1. Implement authentication screens
2. Implement dashboard & navigation
3. Implement upload & scheduling
4. Implement diamond store & wallet
5. Implement admin panel
6. Implement analytics

### Step 4: Styling & Polish
1. Apply design system (colors, spacing, typography)
2. Add animations & transitions
3. Implement responsive layouts
4. Add loading states & error handling

### Step 5: Testing & Verification
1. Build and verify compilation
2. Test API connections
3. Verify existing functionality preservation
4. Verify admin workflow
5. Verify payment workflow

---

## 8. KEY CONFLICTS/DECISIONS

### Conflict 1: Payment System
- **Current**: Uses Transaction model with UTR verification
- **Required**: Payment URL-based system with secure tokens
- **Decision**: Keep Transaction model, add new fields for secure tokens & payment URLs

### Conflict 2: Admin Email Hardcoding
- **Current**: Admin role determined by hardcoded email in authRoutes.js
- **Required**: Admin to manage payment settings dynamically
- **Decision**: Keep current admin role assignment, add admin endpoints for settings management

### Conflict 3: Diamond Storage
- **Current**: diamondBalance on User model
- **Required**: Comprehensive wallet system with history
- **Decision**: Keep User.diamondBalance, create new Wallet model for detailed tracking

---

## 9. MIGRATION PLAN

### No Data Loss Strategy
1. All new models will be created (not replacing existing ones)
2. Existing User model fields preserved
3. New fields added to Transaction model only when needed
4. Database migrations will be additive only
5. All existing data remains accessible

---

## 10. QUALITY ASSURANCE CHECKLIST

Before completion, verify:
- [ ] Flutter analysis runs without warnings
- [ ] All imports resolve correctly
- [ ] Backend tests pass
- [ ] No compilation errors
- [ ] Render deployment config untouched
- [ ] All existing APIs still work
- [ ] Admin workflow functional
- [ ] Payment workflow complete
- [ ] Wallet system operational
- [ ] UI matches design image
- [ ] Responsive on all screen sizes
- [ ] Dark theme applied
- [ ] Animations working
- [ ] Authentication preserved
- [ ] YouTube integration preserved
- [ ] Database migrations ready
- [ ] No hardcoded secrets in code

---

## 11. PROJECT STRUCTURE (UPDATED)

### Backend Additions Needed
```
src/
├── models/
│   ├── PaymentSettings.js (NEW)
│   ├── Wallet.js (NEW)
│   ├── WalletHistory.js (NEW)
│   └── ... (existing models preserved)
├── routes/
│   ├── paymentSettingsRoutes.js (NEW)
│   ├── walletRoutes.js (NEW)
│   └── ... (existing routes preserved)
└── services/
    └── ... (existing services preserved)
```

### Frontend Additions Needed
```
lib/
├── screens/
│   ├── splash_screen.dart (NEW)
│   ├── onboarding_screen.dart (NEW)
│   ├── upload_screen.dart (NEW)
│   ├── schedule_screen.dart (NEW)
│   ├── analytics_screen.dart (NEW)
│   ├── diamond_store_screen.dart (NEW)
│   ├── wallet_screen.dart (NEW)
│   ├── profile_screen.dart (NEW)
│   ├── admin_panel_screen.dart (NEW)
│   └── ... (existing screens preserved)
├── widgets/
│   ├── bottom_navigation.dart (NEW)
│   ├── diamond_card.dart (NEW)
│   ├── payment_page.dart (NEW)
│   └── ... (other components)
├── utils/
│   └── ... (preserved)
└── config/
    └── ... (preserved)
```

---

## NEXT STEPS

1. ✅ Understand project structure (COMPLETE)
2. ✅ Analyze UI design (COMPLETE)
3. ✅ Create this analysis (COMPLETE)
4. ⏳ Start backend implementation
5. ⏳ Implement frontend screens
6. ⏳ Test & verify
7. ⏳ Generate final summary

---

**Analysis Date**: 2026-07-18  
**Status**: Ready for Implementation  
**Risk Level**: LOW (Additive changes only)  
**Expected Timeline**: To be determined based on implementation

