# PROJECT UPDATE ONLY (DO NOT REBUILD)

IMPORTANT

This project already exists.

Backend is already deployed on Render.

Frontend is already connected with backend.

GitHub repository already exists.

DO NOT recreate project.

DO NOT replace architecture.

DO NOT delete existing APIs.

DO NOT break Render deployment.

DO NOT remove current authentication.

DO NOT change existing routes unless necessary.

Only UPDATE the existing project.


------------------------------------------------
PROJECT NAME
------------------------------------------------

Yt-Uploader


------------------------------------------------
GOAL
------------------------------------------------

Upgrade the existing project into the final production version.

Everything must remain compatible with the existing backend deployment.


=====================================================
1. KEEP EXISTING FEATURES
=====================================================

Keep everything already working:

Google Login

JWT

YouTube OAuth

Video Upload

Scheduling

Diamond System

Storage

Dashboard

History

Render deployment compatibility

Existing API routes

Existing Database


Nothing should break.


=====================================================
2. UI UPDATE ONLY
=====================================================

Do NOT redesign.

Use the uploaded UI image exactly.

Match:

Spacing

Cards

Fonts

Rounded Corners

Colors

White Backend Dashboard

Glass Effect

Animations

Bottom Navigation

Dashboard Cards

Diamond Store

Schedule Screen

History Screen

Settings

Admin Panel

Responsive Layout

Professional SaaS Feel


=====================================================
3. PAYMENT SYSTEM UPDATE
=====================================================

Remove the previous Transaction ID / UTR verification system.

Instead implement the following.

When user clicks Buy Diamonds:

Generate a UNIQUE PAYMENT URL.

The URL must include:

User ID

Diamond Package

Timestamp

Secure Token

Example

/pay/anik123?package=100&token=xxxxx

This URL must open a payment page containing:

Our own QR Code

Our own UPI ID

Package Details

User ID

Payment Instructions

No UTR input.

No Transaction ID input.

No Screenshot upload.

=====================================================
3.1 PAYMENT SETTINGS (ADMIN MANAGED)
=====================================================

Do NOT hardcode QR image, UPI ID, merchant name or payment details inside Flutter.

Create an Admin Payment Settings module.

Admin must be able to manage:

- Merchant Name
- UPI ID
- QR Code Image
- Payment Instructions
- Support WhatsApp
- Support Email

Store these values securely in database.

Create APIs:

GET /api/payment/settings
GET /api/admin/payment-settings
PUT /api/admin/payment-settings

Admin can upload a new QR image.

Admin can update UPI ID anytime.

Frontend must always fetch latest payment settings from backend.

Changing QR or UPI should never require app update.


=====================================================
3.2 PAYMENT PAGE
=====================================================

When user clicks Buy Diamonds:

Generate a secure payment request.

Generate unique payment URL.

The payment page must display:

Merchant Name

QR Image

UPI ID

Diamond Package

Price

User ID

Generated Payment ID

Payment Instructions

Copy UPI Button

Download QR Button

Share Payment Link Button

Refresh Status Button

Payment Timer

No UTR field.

No Transaction ID.

No Screenshot Upload.

After payment, show:

"I have completed payment"

This only sends payment request to admin.

Admin manually verifies payment.


=====================================================
3.3 ADMIN PAYMENT REQUESTS
=====================================================

Admin Dashboard should contain:

Pending Requests

Approved

Rejected

Search User

Search Payment ID

Search Package

Generated Time

Approve

Reject

Notes

Payment History

Export CSV

Approve should automatically:

Add Diamonds

Create Wallet History

Create Notification

Update User Balance

Reject should:

Save rejection reason

Notify user


=====================================================
3.4 WALLET SYSTEM
=====================================================

Create production wallet.

Wallet should contain:

Current Diamonds

Lifetime Diamonds Purchased

Lifetime Diamonds Used

Wallet History

Purchase History

Credit History

Debit History

Pending Requests

Rejected Requests

Wallet APIs

Secure Transactions


=====================================================
3.5 PAYMENT SECURITY
=====================================================

Every payment request must contain:

Unique Payment ID

Secure Random Token

User ID

Package ID

Timestamp

IP Address (optional)

Status

Pending

Approved

Rejected

Expired

Prevent duplicate payment requests.

Prevent replay attacks.

Validate all requests.


=====================================================
3.6 FILE STORAGE
=====================================================

QR images should be stored securely.

Support:

Local Storage

Cloudinary

AWS S3

Render Persistent Disk (if configured)

Store only image URL in database.


=====================================================
3.7 FRONTEND
=====================================================

Create beautiful Buy Diamonds page.

Professional Cards

Smooth Animation

Glass UI

Package Cards

Wallet Balance

Payment Button

Payment Success Dialog

Pending Dialog

Rejected Dialog

Approved Dialog

Loading Skeleton

Responsive Layout

Dark/Light support.


=====================================================
3.8 ADMIN SETTINGS
=====================================================

Create Admin Settings page.

Manage:

UPI ID

QR Image

Merchant Name

Support Email

Support WhatsApp

Diamond Packages

Package Prices

Enable/Disable Packages

Maintenance Mode

Save Settings

Settings should immediately reflect in frontend.

=====================================================
4. ADMIN VERIFICATION SYSTEM
=====================================================

Admin panel should have:

Pending Payments

Approved

Rejected

Search by User ID

Search by Email

Payment Package

Generated URL

Created Time

Approve Button

Reject Button

Notes

When Admin clicks APPROVE

Automatically:

Add Diamonds

Save History

Notify User

Update Wallet

When Reject

Save rejection reason

Notify user

Do NOT ask user for any proof.

Admin verifies payment manually.


=====================================================
5. DIAMOND STORE
=====================================================

Create production ready store.

Packages

100 Diamonds

500 Diamonds

1000 Diamonds

5000 Diamonds

Premium Badge

Popular Badge

Discount Badge

Wallet Balance

Purchase History

Beautiful Cards

Smooth Animation


=====================================================
6. USER PROFILE
=====================================================

Profile should show

Current Diamonds

Uploads

Scheduled Videos

Completed Videos

Payment History

Membership

Notifications

Settings


=====================================================
7. VIDEO UPLOAD
=====================================================

Improve upload flow.

Drag Drop (Web)

Progress

Remaining Time

Pause

Resume

Cancel

Thumbnail Upload

Visibility

Schedule Date

Schedule Time

Category

Playlist

Audience

Tags

Description

Shorts Detection


=====================================================
8. DASHBOARD
=====================================================

Professional Dashboard

Cards

Today's Uploads

Scheduled

Completed

Diamonds

Revenue Saved

Upload Progress

Latest Activity

Calendar


=====================================================
9. ADMIN DASHBOARD
=====================================================

White Theme

Analytics

Users

Revenue

Pending Payments

Diamond Sales

Uploads

Failed Uploads

Recent Users

Search

Filters

Charts

Export CSV


=====================================================
10. NOTIFICATIONS
=====================================================

Push Notifications

Payment Approved

Payment Rejected

Video Uploaded

Video Scheduled

Upload Failed

Diamond Added


=====================================================
11. SECURITY
=====================================================

JWT

Refresh Token

Encryption

Rate Limiting

Helmet

Input Validation

Sanitization

CSRF Protection

Secure Cookies

Environment Variables

No hardcoded secrets.


=====================================================
12. DATABASE
=====================================================

Only update schema.

Do NOT destroy data.

Create migrations.

Collections/Tables

Users

Payments

Diamonds

Uploads

Schedules

Notifications

Logs


=====================================================
13. BACKEND
=====================================================

Keep existing Render compatibility.

Do NOT change deployment configuration.

Update existing APIs only.

No breaking changes.

Maintain compatibility.


=====================================================
14. FRONTEND
=====================================================

Keep existing Flutter architecture.

Only improve.

Do NOT recreate project.

Improve animations.

Improve responsiveness.

Improve performance.

Improve loading.


=====================================================
15. FINAL TASK
=====================================================

After finishing:

Run Flutter Analyze

Fix every warning

Run backend tests

Fix errors

Build Release APK

Verify APIs

Verify Database

Verify Scheduling

Verify Diamond Purchase

Verify Admin Approval

Verify Notifications

Verify Authentication

Commit all changes.

Do NOT push.

Show complete list of modified files.

Explain every update.

Project must compile without errors.
