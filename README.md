# Phantom Deeplink Demo App (Unofficial)

A Flutter application demonstrating integration with the Phantom wallet using deeplinks for Solana blockchain interactions. This is an **unofficial** Dart example for deep link integration with Phantom wallet.

## Features

- **Wallet Connection**: Connect to Phantom wallet using universal links
- **Message Signing**: Sign arbitrary messages with your Phantom wallet
- **Transaction Signing**: Sign Solana transactions
- **Session Management**: Persistent wallet sessions across app launches
- **Modern UI**: Beautiful interface following brand design guidelines

## Setup

### Prerequisites

1. **Flutter SDK**: Install Flutter 3.10.0 or higher
2. **Phantom Wallet**: Install Phantom wallet app on your mobile device
3. **Development Environment**: Android Studio/VS Code with Flutter extensions

### Installation

1. Clone or download this project
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### Platform Configuration

#### Android
The app is configured to handle `phantomdemo://` deeplinks. The Android manifest includes:
- Custom URL scheme handling
- Phantom app query permissions
- Internet permissions

#### iOS
The Info.plist is configured with:
- Custom URL scheme registration
- LSApplicationQueriesSchemes for Phantom app detection

## Usage

### 1. Connect Wallet
- Tap "Connect Phantom Wallet"
- Phantom app will open for approval
- Approve the connection in Phantom
- Return to the demo app

### 2. Sign Messages
- Enter any text message
- Tap "Sign Message"
- Approve in Phantom wallet
- Signature will be returned to the app

### 3. Sign Transactions
- Enter transaction data (base64 encoded)
- Tap "Sign Transaction"
- Approve in Phantom wallet
- Signed transaction will be returned

## Architecture

### Core Components

- **PhantomService**: Main service handling wallet interactions
- **DeeplinkHandler**: Manages incoming deeplinks and responses
- **UI Components**: Modern, accessible interface components

### Deeplink Flow

1. App constructs Phantom deeplink URL
2. Launches Phantom app with parameters
3. User approves action in Phantom
4. Phantom returns to app via custom URL scheme
5. App processes response and updates UI

### Security

- Session tokens are stored locally using SharedPreferences
- Encryption keys are generated for secure communication
- Error handling for all wallet operations

## Brand Theme

The app implements a comprehensive design system with:

- **Color Tokens**: Consistent brand colors throughout the app
- **Typography**: Inter font family with proper weight hierarchy
- **Components**: Reusable UI components following design guidelines
- **Accessibility**: Proper contrast ratios and interactive elements

## Development

### Key Files

- `lib/services/phantom_service.dart`: Core wallet integration
- `lib/services/deeplink_handler.dart`: Deeplink processing
- `lib/screens/home_screen.dart`: Main application interface
- `lib/theme/`: Brand theme and color definitions
- `lib/widgets/`: Reusable UI components

### Testing

1. **Device Testing**: Test on physical devices with Phantom installed
2. **Deeplink Testing**: Use ADB or iOS Simulator to test deeplinks
3. **Error Scenarios**: Test wallet rejection and network errors

### Extending

To add new Phantom wallet features:

1. Add method to `PhantomService`
2. Update `DeeplinkHandler` for response processing
3. Add UI components in the home screen
4. Follow brand theme guidelines

## Phantom Wallet Integration

This app demonstrates an unofficial integration with Phantom wallet using their deeplink API:

- **Universal Links**: `https://phantom.app/ul/v1/`
- **Supported Methods**: connect, disconnect, signTransaction, signAllTransactions, signMessage

This is an unofficial implementation intended as an educational example and is not affiliated with, endorsed by, or officially connected to Phantom.

For more information about the official API, visit the [Phantom Developer Documentation](https://docs.phantom.com/phantom-deeplinks/deeplinks-ios-and-android).

## Troubleshooting

### Common Issues

1. **Phantom Not Opening**: Ensure Phantom wallet is installed
2. **Deeplinks Not Working**: Check URL scheme configuration
3. **Connection Fails**: Verify app URL scheme matches configuration
4. **Build Issues**: Run `flutter clean` and `flutter pub get`

### Debug Mode

Enable debug prints by checking the console output for:
- Deeplink reception logs
- Phantom service operation logs
- Error messages and stack traces



