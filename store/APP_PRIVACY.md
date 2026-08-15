# PulsIQ — App Privacy answers (App Store Connect)

App Store Connect → your app → **App Privacy** → "Get Started".
Answer the questionnaire exactly as below. Apple penalizes inaccurate
labels, so two items marked ⚠️ are judgment calls — confirm they match how
the backend actually behaves before you submit.

---

## 1. "Do you or your third-party partners collect data from this app?"
**Yes.**
(Even though health data is encrypted on-device, you collect an email for
sign-in and send food text/photos to the AI provider for Plus estimates, so
the honest answer is Yes.)

---

## 2. Data types — select ONLY these

### Contact Info → Email Address
- Collected: **Yes**
- Used for: **App Functionality** (account sign-in)
- Linked to the user's identity: **Yes**
- Used for tracking: **No**

### Health & Fitness → Health
- Collected: **Yes**  (heart rate, HRV, sleep, respiratory rate from Apple Health / WHOOP)
- Used for: **App Functionality**
- Linked to the user's identity: **Yes** ⚠️
  *(Data is end-to-end encrypted and stored on device; optional cloud backup
  holds only ciphertext you cannot read. Apple still treats data associated
  with an account as "Linked." Marking Linked is the safe, honest choice.)*
- Used for tracking: **No**

### Health & Fitness → Fitness
- Collected: **Yes**  (workouts, activity)
- Used for: **App Functionality**
- Linked: **Yes**
- Tracking: **No**

### User Content → Other User Content
- Collected: **Yes**  (food logs, meal photos, voice notes)
- Used for: **App Functionality** ⚠️
  *(On-device by default. For PulsIQ Plus, food descriptions and meal photos
  are sent to the AI provider to estimate calories/macros. If that transmission
  is NOT tied to the user's identity at the proxy, keep "Linked = No"; if it is,
  set "Linked = Yes." Confirm against your worker code.)*
- Linked: **No** ⚠️ (see note)
- Tracking: **No**

### Identifiers → User ID
- Collected: **Yes**  (account identifier)
- Used for: **App Functionality**
- Linked: **Yes**
- Tracking: **No**

### Purchases → Purchase History
- Collected: **Yes**  (PulsIQ Plus subscription status)
- Used for: **App Functionality**
- Linked: **Yes**
- Tracking: **No**

---

## 3. Do NOT select these
- Location — not collected
- Browsing/Search History — not collected
- Contacts — not collected
- Diagnostics / Usage Data — **none** (no third-party analytics, no crash SDK)
- Financial Info, Sensitive Info, Advertising Data — none

---

## 4. Tracking
"Do you use data to track users across apps and websites owned by other
companies?" → **No.**
(No ad networks, no data brokers, no cross-app tracking. This means you do
NOT need App Tracking Transparency prompts.)

---

## 5. Privacy Policy URL (required on this screen)
```
https://pulsiqapp.com/#privacy
```

---

### Resulting label a user will see
- Data Linked to You: Health, Fitness, Contact Info, Identifiers, Purchases
- Data Not Linked to You: User Content
- Data Used to Track You: none
