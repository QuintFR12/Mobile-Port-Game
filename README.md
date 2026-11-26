# Mobile Port Game

Een onbeheerde, eigen placeholder-versie van een haven-terminalspel in Swift en SwiftUI. De app gebruikt geen externe SDK's, merklogo's, echte havennamen of externe API's.

## Wat zit erin

- Casual modus zonder stressvolle ronde-timer.
- Competitieve modus met 90 seconden en vaste startcondities.
- Roguelike-run van 4-6 rondes met tijdelijke upgradekeuzes.
- Sleep containers naar Schip, Trein of Terminal.
- Lokale persoonlijke highscore via `UserDefaults`.
- Feature-flagged rewarded-ad-stub; standaard uitgeschakeld.
- Geen IAP, multiplayer-backend of verplichte advertenties.

## Vereisten

- Een Mac met macOS 14 of nieuwer voor de SwiftPM-macOS-target.
- Xcode 15 of nieuwer met iOS 16 SDK of nieuwer.
- Een Apple ID voor Simulator. Voor apparaatbuilds of TestFlight wordt een Apple Development/Distribution-account gebruikt.

## Openen in Xcode

1. Clone en open de repository:

   ```bash
   git clone https://github.com/QuintFR12/Mobile-Port-Game.git
   cd Mobile-Port-Game
   open Package.swift
   ```

2. Kies in Xcode het target `MobilePortApp`.
3. Kies een iPhone- of iPad-simulator bij **Product > Destination**.
4. Start met **Product > Run** of druk op `Cmd-R`.
5. Xcode kan het Swift-package-executable openen als een macOS-laadbare app. Voor een echte iOS-app moet het package als iOS-app-product worden gegenereerd of als Xcode-appproject worden aangemaakt en op het package targeten.

## Unit tests

Via Xcode:

1. Open `Package.swift`.
2. Kies een macOS-destination.
3. Voer `Product > Test` uit of druk op `Cmd-U`.

Via de terminal op een Mac met Xcode:

```bash
swift test
```

De tests dekken scores, ronde-einde, roguelike-rondes en upgrade-effecten.

## Testen op iPhone en iPad

### Simulator

1. Start een iPhone Simulator via **Window > Devices and Simulators**.
2. Kies het simulatorapparaat als bestemming.
3. Start de app met `Cmd-R`.
4. Herhaal met minimaal een iPad-model en draai vervolgens naar liggend en staand.

### Echt apparaat

1. Verbind een iPhone/iPad via USB.
2. Kies het apparaat onder **Destination**.
3. Onder **Signing & Capabilities**: kies je Team.
4. Controleer dat het package/app-target iOS ondersteunt.
5. Voer `Cmd-R` uit en accepteer eventuele vertrouwen-/ontwikkelaarsinstellingen op het apparaat.

## TestFlight

1. Maak in App Store Connect een apprecord voor Mobile Port Game.
2. Voeg je Apple Development-team en -gebruiker toe.
3. Open het iOS-Xcodeproject/app-target en kies een correcte Bundle ID.
4. Kies in Xcode **Product > Archive**.
5. Upload via de Organizer naar App Store Connect.
6. Voeg onder **TestFlight** externe of interne testers toe.
7. Beantwoord eventuele export-, privacy- en nalevingsvragen.
8. Wacht tot Apple de build verwerkt heeft en distributeer het interne/externe testtraject.

## Rewarded-ad stub

De stub staat standaard uit. De integratie in `RewardedAdStub` accepteert alleen een optionele beloning en levert geen echte advertentie op. Om een SDK later te verbinden, gebruik een aparte feature-flag, controleer netwerk- en SDK-status en geef alleen het beloningsresultaat door na een geldig SDK-callback.
