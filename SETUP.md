# Locus — install & first teleport

## 1. Sideload the IPA

Install the latest `Locus-1.0.0.ipa` from [Releases](https://github.com/ChrisMack32/Locus/releases) (or build from source) with Feather, SideStore, AltStore, or Sideloadly.

Bundle ID: `com.chrismack.locus`

## 2. Pairing

### On iOS 27 — no computer

1. Open Locus → **Settings → Pair on this iPhone** → **Start pairing**.
2. Allow **Local Network** (and Location / Notifications if asked).
3. Leave Locus open. Go to **Settings › Privacy & Security › Developer Mode › Pair with Host**.
4. Pick **Locus** → **Pair**.
5. Enter your **iPhone unlock passcode** first (authorizes pairing).
6. When the second prompt appears, type the **6-digit code** Locus shows (also sent as a notification).
7. Done — RPPairing file is saved on-device.

### On iOS 18–26

1. On a computer, download [idevice_pair](https://github.com/jkcoxson/idevice_pair/releases).
2. Plug in your iPhone, unlock, Trust.
3. Generate an **RPPairing** file (not lockdown / SideStore `.mobiledevicepairing`).
4. AirDrop → Open in **Locus**, or Settings → Import RPPairing file.

## 3. LocalDevVPN

Install [LocalDevVPN](https://apps.apple.com/us/app/localdevvpn/id6755608044), connect it (default tunnel IP `10.7.0.1`).

## 4. Teleport

On Wi‑Fi: drop a pin → **Teleport**. Then joystick / routes / GPX work; the session can continue on cellular.
