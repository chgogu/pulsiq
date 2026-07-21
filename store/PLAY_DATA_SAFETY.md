# Google Play — Data Safety form answers (PulsIQ)

Fill these into the Play Console → App content → Data safety section.

## Overview
- **Does your app collect or share any of the required user data types?** Yes (collects), No (shares).
- **Is all user data encrypted in transit?** Yes (LLM proxy calls over HTTPS; all other processing is on-device).
- **Do you provide a way for users to request that their data be deleted?** Yes — Settings → Delete everything (in-app, immediate, ≤3 taps). Also full JSON export.

## Data types collected

| Data type | Collected | Shared | Purpose | Optional | On-device / encrypted |
|-----------|-----------|--------|---------|----------|-----------------------|
| Health & fitness (heart rate, HRV, respiratory rate, sleep, steps, active minutes) | Yes | No | App functionality | Yes (works without a wearable) | Read-only from Health Connect; encrypted at rest (SQLCipher) |
| Health info — food, drink, hydration, exercise logs | Yes | No | App functionality | No | Encrypted at rest on device |
| Voice / audio (voice notes for logging) | Yes | No | App functionality | Yes | Transcribed on-device; audio not stored |
| Photos (menu scans) | Yes | No | App functionality | Yes | OCR'd on-device; images not stored |

## Data NOT collected
- No name, email tied to health data, contacts, location (weather uses coarse IP geolocation, not device GPS, and is not stored beyond a 3-hour cache), financial info, or device identifiers for tracking.
- **No third-party analytics SDKs** in v1 (OS-native crash reporting only).
- No advertising or tracking. Data is never sold or shared.

## Security practices
- Data encrypted in transit (HTTPS) and at rest (SQLCipher, per-device key in Android Keystore).
- Users can request deletion in-app.
- Committed to the Play Families / sensitive-data policies: health data is used only to power the app's coaching features.
