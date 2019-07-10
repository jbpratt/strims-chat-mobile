# Mobile chat.strims.gg

Welcome to the GitHub for development of the mobile version of [strims](https://strims.gg/)!

Note that this is explicitly chat until things change!

## Installing Dependencies

1. [Install Flutter](https://flutter.dev/docs/get-started/install). Make sure to set up a device (either an emulator or an actual mobile device) during this process so that you can run the app itself later.
2. [Switch to Flutter dev channel](https://flutter.dev/docs/development/tools/sdk/upgrading#switching-flutter-channels). The app will not run if you don't use the Flutter dev channel. Specifically, you need the following command(s):
```
flutter channel dev
```
```
flutter upgrade
```
3. Optionally, [install Visual Studio Code with Flutter plugins](https://flutter.dev/docs/get-started/editor?tab=vscode).
4. Optionally, [install Visual Studio Code Live Share](https://code.visualstudio.com/blogs/2017/11/15/live-share) to collaboratively code.
5. [Install Git](https://www.atlassian.com/git/tutorials/install-git)

## Cloning the repository

Run

```
git clone https://github.com/jbpratt78/strims-chat-mobile.git
```

## Running the app

### From Visual Studio Code

1. Go to `File -> Open Folder`.
2. Navigate to the directory you just cloned, most likely `strims-chat-mobile/`.
3. Open the `lib` folder.
4. Go to `Debug -> Start Debugging`, or press `F5`.

The app should begin running on your emulator or device.

### From Terminal

1. Navigate to the directory you just cloned, most likely `strims-chat-mobile/`.
2. Run `flutter clean`.
3. Run `flutter run`.

The app should begin running on your emulator or device.