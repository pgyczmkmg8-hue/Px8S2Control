# Px8S2Control

[한국어](README.md) | **English**

An unofficial iOS app that switches the noise cancelling (ANC) mode of **Bowers & Wilkins Px8 S2** headphones with a single tap.
You can change modes from **Shortcuts, the Action Button, Control Center and home screen widgets** without opening the B&W Music app.

> **This is an unofficial open-source project with no affiliation to B&W.** It was built by analyzing the Bluetooth (BLE) traffic between the headphones and the B&W app.
> A firmware update may change the behavior, and it has been **verified on the Px8 S2 only**. Use it at your own risk.

## Contents

- [Features](#features)
- [Installation (sideloading)](#installation-sideloading)
- [First-time setup](#first-time-setup)
- [Creating a shortcut](#creating-a-shortcut)
- [Control Center, Action Button and Lock Screen](#control-center-action-button-and-lock-screen)
- [Home screen widgets (experimental)](#home-screen-widgets-experimental)
- [App screens](#app-screens)
- [Troubleshooting](#troubleshooting)
- [Building from source](#building-from-source)
- [Limitations](#limitations)

## Features

- Three modes: **Noise Cancelling / Transparency / Off**
- A Shortcuts action, **"Connect / Cycle ANC"**
  - If the headphones are not connected to this device, it **only connects** them.
  - If they are connected, it **cycles through the modes you pick** (2 or 3, in your order).
- A button that **pulls the headphones over to this device** when they are connected to another one (Mac, iPad, ...)
- Home screen widgets: a fixed-button widget and one where you choose which modes to show

## Installation (sideloading)

The app is not on the App Store. Download the unsigned `Px8S2Control.ipa` from [Releases](../../releases) and sign it yourself.

1. Download `Px8S2Control.ipa` from Releases.
2. Sign and install it with a tool such as AltStore, Sideloadly or Feather, using **your own Apple ID (or developer certificate)**.
3. Follow [First-time setup](#first-time-setup) below.

Things to know when signing:

- **Keep the bundle ID unchanged if you can.** The app (`com.MACHU.Px8S2Control`) and the widget (`com.MACHU.Px8S2Control.Widgets`) must share the same prefix. If your tool can change the bundle ID, turn that off, or make sure the widget ID stays under the app ID.
- With a **free Apple ID** you have to re-sign every 7 days, and there is a limit on the number of apps. The widget extension uses one extra app ID.
- The **App Group** (the entitlement that lets the app and the widget share settings) may not be attached, depending on how you sign. Mode switching still works without it; only the "last mode sent" highlight in the widget stops updating.

## First-time setup

You only need to do this once. It takes about five minutes.

### 1. Connect the headphones to your iPhone

Pair and connect the **Px8 S2** in Settings → Bluetooth as usual. The app does not ask you to pair anything itself.

### 2. Quit the B&W Music app

If the B&W Music app is holding a connection to the headphones, it can collide with this app. Swipe the B&W Music app away in the app switcher to **fully quit** it. (It's fine to leave it installed.)

### 3. Trust the app and enable Developer Mode

Sideloaded apps may need the following before the first launch. Skip anything you've already done. (Menu names vary a little between iOS versions.)

- **Developer Mode**: Settings → Privacy & Security → turn on Developer Mode and restart.
- **Trust the app**: Settings → General → VPN & Device Management → trust the certificate you used to install it.

### 4. Open the app and tap a mode

1. Open **Px8S2Control**.
2. Tap one of the **Sound mode** rows (for example Transparency).
3. If a Bluetooth permission prompt appears, tap **Allow**.
4. If the headphones change mode and the app says the mode was applied, you're done.

If you denied the permission by mistake, turn on Settings → Px8S2Control → **Bluetooth**.

### 5. (Only if needed) Check this device's slot

The headphones store the devices you've paired with as a list (slots). When the app sends "Connect to this device", it needs to know **which entry is this device**. It normally finds it automatically.

- If you only use mode switching, you can ignore this.
- If the Connect button connects the wrong device, pick the right entry yourself in the app's **Settings** (see [Settings](#settings)).

## Creating a shortcut

This is the core feature. Once you've made one, you can use it from the Action Button, Control Center, Siri and more.

### A shortcut that cycles through modes (recommended)

1. Open the **Shortcuts** app and tap **+** in the top right.
2. Tap **Add Action** and search for `Px8S2Control` (or `ANC`).
3. Tap **Connect / Cycle ANC** to add it. It reads like `Cycle [Noise Cancelling, Transparency]`.
4. Tap the blue mode list and choose the **modes to cycle through**.
   - You must pick **at least 2**. (For example Noise Cancelling + Transparency, or all three.)
   - If you pick only one, the shortcut fails with an error asking for at least 2 different modes.
5. Tap the name at the top to rename it (for example `Toggle ANC`) and tap **Done**.

What happens when you run it:

| State | Behavior |
|---|---|
| Headphones are not connected to this device | **Only connects.** It does not change the mode. |
| Connected, and the current mode is in your list | Switches to the **next mode** in the list. After the last one it wraps around to the first. |
| Connected, but the current mode is not in your list | Switches to the **first mode** in the list. |

When it finishes you get a message such as "Switched to Transparency" or "Connected the headphones".

### A shortcut that sets a specific mode

1. In a new shortcut, add the **Change ANC Mode** action.
2. Tap the blue mode name and choose **Noise Cancelling / Transparency / Off**.
3. Make one per mode if you want to trigger each one separately from Siri or elsewhere.

### Siri

Say the shortcut's name. The app also provides these phrases out of the box (they are in Korean):

- "Px8S2Control 전환" (switch)
- "Px8S2Control 노이즈캔슬링" (noise cancelling)
- "Px8S2Control 주변음 허용" (transparency)
- "Px8S2Control 끄기" (off)

## Control Center, Action Button and Lock Screen

Assign the shortcut you made above to any of these.

### Control Center

The app does not ship its own Control Center control. Instead, point the system **"Shortcuts" control** at your shortcut. (Control Center controls run their intents inside the widget extension, where Bluetooth cannot be used, so they don't work.)

1. Open Control Center and tap **+** in the top left, or touch and hold an empty area and tap **Add a Control**.
2. Find and add the **Shortcuts** control.
3. On the added control, tap **Choose** (or touch and hold it to configure) and pick your shortcut.
4. Resize it as you like and finish.

### Action Button (iPhone 15 Pro and later)

Settings → Action Button → **Shortcut**, and choose your shortcut. Each press cycles the mode.

### Lock Screen

Touch and hold the Lock Screen, tap **Customize** → Lock Screen, tap a control slot, add the **Shortcuts** control and choose your shortcut.

### Back Tap

Settings → Accessibility → Touch → **Back Tap**: assign your shortcut to Double Tap or Triple Tap.

## Home screen widgets (experimental)

Depending on how the app is installed, the widget buttons may not work. If they don't, use a shortcut instead.

1. Touch and hold an empty area of the home screen to enter edit mode and tap **+**.
2. Find **Px8S2Control**. There are two widgets, both **medium size**.

| Widget | Description |
|---|---|
| PX8 ANC (fixed) | Shows all three buttons: Off / Noise Cancelling / Transparency. |
| PX8 ANC (choose modes) | Lets you choose which modes to show. |

3. For the **choose modes** widget, touch and hold the widget, tap **Edit Widget**, and pick the modes under **Modes to show**.
4. The last mode sent is highlighted. (On installs without the App Group, this highlight does not update.)

## App screens

### Main

- **Sound mode**: Noise Cancelling / Transparency / Off. Tapping a row changes the headphones right away. The checkmark is the **last mode this app sent**. (Changes made with the headphone buttons or the B&W app may not be reflected.)
- **Connect headphones to this device**: pulls the headphones over when they are connected to another device. If they are already connected, it tells you so.
- A spinner shows while it works, and a dialog explains the reason if something fails.

### Settings

**Which entry in the headphones is this device?**

- **Read the headphones' device list** shows the device names stored on the headphones. An entry marked "Connected now" is the device the headphones are currently connected to.
- Tap the entry that **corresponds to this device** to choose it yourself. The checkmark is the current choice.
- The note at the top shows the current state: "Automatic", "Chosen manually" or "Not detected yet".
- **Reset to automatic** clears a manual choice. The next time it connects, the app finds the entry again by device type (iPhone/iPad) and name.

> iOS hides the real device name from apps and only reports "iPhone" or "iPad". So the app picks the entry whose name starts with "iPhone"/"iPad". If several devices of the same kind are paired, it may pick the wrong one; in that case choose it yourself.

### How to use shortcuts and widgets

The shortcut, Control Center and widget instructions from this README, inside the app. (The in-app text is in Korean.)

### About

Version, verified model, things to know (unofficial app, firmware changes may break it) and a privacy note. The app only talks to the headphones over Bluetooth and sends nothing to any server.

## Troubleshooting

| Symptom | What to check |
|---|---|
| It can't find the headphones | Make sure the headphones are connected to your iPhone over Bluetooth and **fully quit the B&W Music app**. Also check that Bluetooth is on in Settings. |
| "Bluetooth permission missing" | Turn on Settings → Px8S2Control → **Bluetooth**. |
| The mode doesn't change | Check the headphones' power and connection, and try the app's mode buttons first. If the app works but the shortcut doesn't, check that the shortcut contains the action properly. |
| The shortcut only "connects" | It decided the headphones aren't connected to this device. Run it once more and it will change the mode. If it keeps happening, pick this device's entry in **Settings**. |
| It connects to the wrong device | Pick this device's entry in **Settings**. |
| The first cycle goes the wrong way | The app can't read the headphones' current mode, so it relies on the last mode it sent. If you changed it with a headphone button or the B&W app, it can be off once. After that it follows the state reported by the headphones. |
| Shortcut error about picking at least 2 modes | Choose at least 2 different modes to cycle through. |
| Widget buttons don't respond | Widgets are experimental. Use a shortcut. |
| The headphones beep every time the keyboard opens | Unrelated to this app. iOS **keyboard sounds** open a silent audio stream, and the headphones make a sound when it starts. Turn off Settings → Sounds & Haptics → Keyboard Feedback → **Sound**. |
| The app won't open after 7 days | Apps installed with a free Apple ID must be re-signed every 7 days. Reinstall with the same bundle ID. |

## Building from source

You need Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
xcodegen generate
open PX8Control.xcodeproj
```

To sign it, change these values in `project.yml` to your own:

- `DEVELOPMENT_TEAM`
- Bundle ID: `com.MACHU.Px8S2Control` (the widget is `….Widgets`)
- App Group: `group.com.MACHU.Px8S2Control` (also change `appGroup` in `Shared/PX8Config.swift`)

To build an unsigned IPA only:

```bash
xcodebuild -project PX8Control.xcodeproj -scheme PX8Control -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
mkdir Payload && cp -R build/Build/Products/Release-iphoneos/Px8S2Control.app Payload/
zip -qry Px8S2Control.ipa Payload
```

## How it works

The app sends the short commands the headphones receive over BLE. The analysis is written up in [PROTOCOL.md](PROTOCOL.md) (in Korean).

## Limitations

- Verified on the Px8 S2 only. Other B&W headphones that use the same protocol might work, but this hasn't been checked.
- System entry points such as widgets and shortcuts depend on the iOS version and the way the app is installed. It was developed for iOS 18 and later.
- The app can't read the headphones' current mode (no query command was found). It tracks the last mode sent plus the state events the headphones report.
- The app does not ship its own Control Center control. Use the system "Shortcuts" control.

## License

[MIT](LICENSE)
