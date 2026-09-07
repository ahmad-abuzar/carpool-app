# Google Sign-In Setup

## Android: fix `ApiException: 10`

`ApiException: 10` means Google rejected the Android app because its package name
and signing certificate do not match an OAuth client in the Firebase project.

This project uses:

- Firebase project: `carpool-app-5abb3`
- Android package: `com.carpool.carpool_app`
- Local debug SHA-1 on this machine: `32:00:D7:AB:70:8F:0B:14:EC:8B:16:D0:62:15:79:AB:0A:52:ED:CA`

### Register the local Android build

1. Open [Firebase Console](https://console.firebase.google.com/) and select `carpool-app-5abb3`.
2. Open **Project settings** → **Your apps** → the Android app with package `com.carpool.carpool_app`.
3. Select **Add fingerprint**, enter the SHA-1 above, and save it.
4. In **Authentication** → **Sign-in method**, enable **Google** and select a support email if requested.
5. Download the updated `google-services.json` and replace `android/app/google-services.json`.
6. Rebuild the application completely:

```powershell
flutter clean
flutter pub get
flutter run
```

For a release build, register the SHA-1 from the release keystore as well. If the
app is distributed through Google Play, also register the Play App Signing SHA-1.

## Current Issue
The Android build must have a matching Firebase OAuth client. The web setup below
is separate and does not fix Android `ApiException: 10`.

## Steps to Fix

### 1. Get Your Google Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select the project: **carpool-app-5abb3**
3. Navigate to **APIs & Services** → **Credentials**
4. Look for **OAuth 2.0 Client IDs** section
5. Click on the **Web client** (or create one if it doesn't exist)
6. Copy the **Client ID** (format: `123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com`)

### 2. Update Configuration Files

#### Option A: Update .env file (Recommended)
Edit `.env` file and replace the placeholder:

```env
GOOGLE_CLIENT_ID=YOUR_ACTUAL_CLIENT_ID_HERE
```

Example:
```env
GOOGLE_CLIENT_ID=821231678050-a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6.apps.googleusercontent.com
```

#### Option B: Update web/index.html (Direct approach)
Edit `web/index.html` and find this line:

```html
<meta name="google-signin-client_id" content="821231678050-abcdefghijklmnopqrstuvwxyz1234567890abcd.apps.googleusercontent.com">
```

Replace the `content` attribute with your actual Client ID:

```html
<meta name="google-signin-client_id" content="YOUR_ACTUAL_CLIENT_ID_HERE">
```

### 3. Configure Authorized Redirect URIs

In Google Cloud Console, you need to add the web app origin to **Authorized redirect URIs**:

1. Go back to the Web client in Google Cloud Console
2. Scroll down to **Authorized redirect URIs**
3. Add these URIs:
   - `http://localhost:54585` (for local development)
   - `http://localhost:8080` (alternative dev port)
   - Your production domain (when deployed)

### 4. Enable Google+ API (if not already enabled)

1. Go to **APIs & Services** → **Library**
2. Search for **Google+ API**
3. Click on it and press **Enable**

### 5. Test the Sign-In

1. Hot reload the app (press `R` in terminal)
2. Click "Sign in with Google"
3. Follow the Google authentication flow

## Troubleshooting

### Error: "ClientID not set"
- Make sure the Google Client ID is correctly placed in `web/index.html` meta tag
- Clear browser cache and refresh the page
- Check that the Client ID format is correct

### Error: "Redirect URI mismatch"
- Ensure `localhost:PORT` is added to Authorized redirect URIs in Google Cloud Console
- The port should match what's shown in the terminal when running the app

### Sign-in popup doesn't appear
- Check browser console (F12) for specific errors
- Verify the Client ID is valid and not expired
- Ensure Google+ API is enabled

## Security Note
- **Never commit the real .env file to version control**
- The `.env` file is already in `.gitignore`
- Placeholder value in `web/index.html` should be replaced with actual ID

## Additional Resources
- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Sign-In Web Documentation](https://developers.google.com/identity/sign-in/web)
- [Flutter google_sign_in Package](https://pub.dev/packages/google_sign_in)
