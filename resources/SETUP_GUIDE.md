# Medi Diary — Setup Guide

All manual Apple configuration steps consolidated in one place.

---

## 1. Apple Developer Portal

Go to [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list).

Find your App ID (`io.codedancoffee.medi-diary-app`) and ensure these capabilities are **enabled**:

- **iCloud** — with **CloudKit** selected (not just Key-Value storage)
- **Sign In with Apple**
- **Push Notifications** (required for CloudKit sync)
- **In-App Purchase**

> **Important:** You need a **paid** Apple Developer account ($99/year) for CloudKit.

### CloudKit Container

1. Go to [CloudKit Containers](https://developer.apple.com/account/resources/containers/list)
2. Verify `iCloud.io.codedancoffee.medi-diary-app.medi-diary-app` exists
3. If not, create it with that exact identifier

---

## 2. Xcode Capabilities

In Xcode → Target → **Signing & Capabilities**:

| Capability | Setting |
|------------|---------|
| **iCloud** | CloudKit checked, container selected |
| **Push Notifications** | Present |
| **Sign In with Apple** | Present |
| **In-App Purchase** | Click "+ Capability" to add if missing |

Signing Team must be a valid **paid** Apple Developer account.

---

## 3. StoreKit Configuration (Local Testing)

StoreKit 2 works in the Simulator (unlike CloudKit).

### Create the configuration file:

1. In Xcode: **File → New → File** → search "StoreKit Configuration File"
2. Name it `Products`
3. Click **"+"** → **Add Auto-Renewable Subscription**
4. Create subscription group: `premium`
5. Add monthly product:
   - Product ID: `io.codedancoffee.medidiary.premium.monthly`
   - Price: **2.99**
   - Duration: **1 Month**
6. Add yearly product:
   - Product ID: `io.codedancoffee.medidiary.premium.yearly`
   - Price: **24.99**
   - Duration: **1 Year**
7. Add lifetime product (Non-Consumable):
   - Product ID: `io.codedancoffee.medidiary.premium.lifetime`
   - Price: **49.99**
   - Type: **Non-Consumable**

### Enable for testing:

1. **Edit Scheme → Run → Options**
2. Set **StoreKit Configuration** → select `Products.storekit`

---

## 4. Testing CloudKit on a Real Device

CloudKit does **not** work in the Simulator. You must test on a physical device.

1. Connect a physical iPhone signed into iCloud
2. Build & run on device (not Simulator)
3. Add some data (medicines, supplements, appointments)
4. Verify in [CloudKit Dashboard](https://icloud.developer.apple.com):
   - Select your container
   - Look in **Private Database** for `CD_Medicine`, `CD_Supplement`, `CD_Appointment` records
5. To test data persistence:
   - Delete the app from the device
   - Reinstall from Xcode
   - Data should reappear within 10–30 seconds

---

## 5. Testing Auth Persistence (Keychain)

Auth credentials are now stored in the iOS Keychain, which persists across app installs.

1. Build & run → Sign in with Apple
2. Quit the app → Reopen → Should still be signed in
3. Delete the app → Reinstall → Should still be signed in (Keychain survives deletion)

---

## 6. Testing StoreKit Purchases (Simulator)

1. Run with the StoreKit configuration enabled (see step 3)
2. Navigate until paywall appears (add 5+ items on free tier)
3. Tap a subscription product → Purchase succeeds immediately (sandbox)
4. Verify premium access is granted
5. To test restore:
   - Use Debug → StoreKit → Manage Transactions to manage active subscriptions
   - Delete app → Reinstall → Tap "Restore Purchase" → Premium should restore

---

## 7. App Store Connect (When Ready for Release)

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create your app
3. Go to **Monetization → Subscriptions**
4. Create subscription group: **Medi Diary Premium**
5. Add products with **exact same IDs** as in code:
   - `io.codedancoffee.medidiary.premium.monthly` — Auto-Renewable Subscription, $2.99/month
   - `io.codedancoffee.medidiary.premium.yearly` — Auto-Renewable Subscription, $24.99/year
   - `io.codedancoffee.medidiary.premium.lifetime` — Non-Consumable, $49.99 one-time
6. Set upgrade/downgrade order for subscriptions: yearly should be **higher level** than monthly
7. Fill in display names, descriptions, and at least one localization per product
8. Status must be **"Ready to Submit"** or **"Approved"** before release

### App Review Preparation

1. Provide a **screenshot of the paywall** in the review notes
2. Add review notes explaining how to test premium features
3. Create a **Sandbox Test Account**: App Store Connect → Users and Access → Sandbox Testers
4. Share sandbox credentials with Apple reviewers if needed

### App Privacy

Update your App Privacy details in App Store Connect:

- Declare **"Identifiers"** (iCloud user ID) under data collected if using CloudKit
- Declare **purchase history** if tracked

Until then, the local StoreKit Configuration file handles all testing.

---

## 8. CloudKit Production Deployment

> **CRITICAL:** You must deploy the CloudKit schema to production before releasing the app.

### Steps

1. **Run the app on a physical device** in Development mode (debug build)
2. Add sample data — at least one medicine, supplement, and appointment
3. Open [CloudKit Dashboard](https://icloud.developer.apple.com)
4. Select container `iCloud.io.codedancoffee.medi-diary-app`
5. Go to **Private Database** and verify these record types exist:
   - `CD_Medicine`
   - `CD_Supplement`
   - `CD_Appointment`
6. Go to **Schema** → click **"Deploy Schema to Production"**
7. Confirm the deployment

> If you skip this step, production users will get CloudKit errors when they try to sync.

---

## 9. Premium + CloudKit Gating — Testing Checklist

CloudKit sync is now gated behind premium. Free users get local-only storage.

### How It Works

- At launch, the app reads a cached `isPremium` value from UserDefaults (synchronous)
- Premium users get `cloudKitDatabase: .automatic` (CloudKit mirroring enabled)
- Free users get `cloudKitDatabase: .none` (local SQLite only)
- When subscription status changes mid-session, a banner appears prompting the user to restart the app

### Test Flow (Physical Device Required)

1. **Fresh install as free user**
   - Confirm no CloudKit activity (check CloudKit Dashboard — no new records)
   - Add items up to the 5-item limit per category
   - Verify paywall appears when trying to add a 6th item

2. **Purchase premium via sandbox**
   - On device: Settings → App Store → Sandbox Account (sign in with sandbox tester)
   - Purchase a subscription from the paywall
   - Verify the paywall auto-dismisses on purchase
   - Verify the banner appears: "iCloud sync will activate on next app launch"
   - Verify Settings → Data shows `icloud.fill` + "Enabled"

3. **Restart to activate CloudKit**
   - Force-quit the app and relaunch
   - Add new items — verify they appear in CloudKit Dashboard (Private Database)
   - Test on a second device signed into the same iCloud account — data should sync

4. **Downgrade / cancel subscription**
   - Cancel the sandbox subscription (device Settings or Xcode → Debug → StoreKit → Manage Transactions)
   - Wait for StoreKit to update (or use `resetToFree()` in debug)
   - Verify banner appears about sync deactivating on next launch
   - Restart — confirm CloudKit mirroring stops
   - Existing data remains in local SQLite (no data loss)

5. **Re-upgrade**
   - Purchase again → restart → verify CloudKit resumes and merges local data with cloud

### Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Fresh install, no subscription | Local-only, cache defaults to `false` |
| Reinstall with existing subscription | First launch is local-only; StoreKit restores entitlement; cache updates; next launch enables CloudKit |
| No internet | `Transaction.currentEntitlements` reads on-device receipt — works offline |
| Free user with existing cloud data | Data stays in local SQLite, stops syncing. Upgrade later resumes sync and merges |

---

## 10. Release Checklist

- [ ] Both IAP products are "Ready to Submit" in App Store Connect
- [ ] Subscription group configured with correct upgrade/downgrade order
- [ ] CloudKit schema deployed to Production (see section 8)
- [ ] StoreKit configuration points to App Store (not local `.storekit` file) for release builds
- [ ] App Privacy declarations updated in App Store Connect
- [ ] Sandbox tester credentials ready for App Review
- [ ] Tested full purchase + sync flow on physical device with sandbox account
- [ ] Tested downgrade flow (cancel → restart → local-only)
- [ ] Tested reinstall with existing subscription (restore flow)
