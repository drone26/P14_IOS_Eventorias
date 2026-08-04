# Eventorias (P14_DA-iOS_Eventorias)

An iOS application integrated with Firebase.

## Prerequisites

- **macOS** with the latest version of **Xcode**
- **Firebase CLI** installed locally

## Project Setup

1. Clone this repository.
2. Open `P14_DA-iOS_Eventorias.xcodeproj` in Xcode.
3. Ensure you have a valid `GoogleService-Info.plist` file. You can use the provided `GoogleService-Info.plist.example` as a template and replace the placeholder values with your actual Firebase project configuration.
4. Copy P14_IOS_Eventorias/Service/APIKeys.swift.example to P14_IOS_Eventorias/Service/APIKeys.swift and replace with your api key
5. Build and run the project.

## Firebase Local Emulator Suite (needed by UI tests)

### How to generate / create all files needed for the Firestore Emulation Suite

If you need to configure or generate the necessary files for the Firebase Local Emulator Suite from scratch (such as `firebase.json`, `firestore.rules`, etc.), follow these steps:

1. **Install Firebase CLI** (if you haven't already):
   ```bash
   curl -sL https://firebase.tools | bash
   ```

2. **Login to your Firebase account**:
   ```bash
   firebase login
   ```

3. **Initialize the Firebase Project and Emulators**:
   Run the following command at the root of the project directory:
   ```bash
   firebase init
   ```
   During the interactive initialization process:
   - **Features**: Select **Firestore**, **Storage**, and **Emulators** (use the Spacebar to select, then Enter to confirm).
   - **Project Setup**: Select an existing Firebase project, or create a new one.
   - **Firestore Setup**: Press Enter to accept the default file names for the Security Rules (`firestore.rules`) and Indexes (`firestore.indexes.json`).
   - **Storage Setup**: Press Enter to accept the default file name for the Security Rules (`storage.rules`).
   - **Emulators Setup**: Select the emulators you wish to use (at minimum, **Firestore Emulator** and **Storage Emulator**).
   - **Ports**: You can accept the default ports for each emulator or customize them.
   - **Emulator UI**: Enable the Emulator UI when prompted.
   - **Download**: Confirm to download the emulators immediately.

   This process will generate or overwrite your `firebase.json` file to include the emulator configuration, and ensure your `.firebaserc`, rules, and index files are properly set up.

4. **Start the Emulators**:
   Once the initialization is complete, you can start the local environment:
   ```bash
   firebase emulators:start
   ```
   The terminal will output the local URLs where you can access the Emulator UI and the respective services.
