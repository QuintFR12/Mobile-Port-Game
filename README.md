# Mobile Port Game

Een oorspronkelijk, haven-geinspireerd SwiftUI-puzzelspel voor iOS en iPadOS. De app gebruikt geen merknamen, officiële logo's, externe SDK's, IAP of backend.

De visuals zijn een compact, fictief havengebied met native RealityKit-primitives: asfalt, havenwater, kade, terminalgebouwen, containerkranen, barges, shortsea- en deepsea-placeholders, treinwagons en vrachtwagens. De camera staat vast in een diagonaal/top-down planweergave; er is geen AR-camera-verplichting. Gameplaymenu's, timers, scores en upgrademenu's blijven SwiftUI.

Deze placeholders stellen alleen verschillende speltypen en capaciteiten voor. Zij leggen geen actuele havenprocedures, bedrijfsverplichtingen of feitelijke havenroutes vast.

## Inhoud

- Casual modus zonder timer.
- Competitieve 90-seconderonde met stabiele startsituatie en persoonlijke highscore.
- Roguelike-run van 4-6 rondes met drie tijdelijke upgrademogelijkheden na iedere ronde.
- Sleep containerkaarten naar barge-, shortsea-, deepsea-, trein-, truck- of terminalplekken.
- Score, streak, fouten, ronde-einde en plaatselijke `UserDefaults`-highscore.
- Optionele rewarded-ad-hook als stub, standaard uitgeschakeld.
- Lokale avatarcreator: havenachtergrond, containerkleur, kraansymbool en initialen.

## Vereisten

- macOS met een volledige Xcode-installatie (Xcode 16 of nieuwer; iOS 18 SDK of nieuwer voor `RealityView`).
- Voor een echt apparaat: Apple ID of Apple Developer-account en een geldig signing-team.
- Voor TestFlight: Apple Developer-programma-toegang en App Store Connect.

## Xcode-project openen

```bash
cd /pad/naar/Mobile-Port-Game
open MobilePortGame.xcodeproj
```

Kies in Xcode het scheme **MobilePortGame** en daarna het target **MobilePortApp**.

Controleer onder **Signing & Capabilities**:

- Bundle Identifier: `com.mobileport.game`
- Signing & Capabilities > Team: jouw gekozen development team
- Target > General > Supported Destinations: iPhone en iPad

## Bouwen en draaien

1. Kies een iPhone- of iPad-simulator onder **Product > Destination**.
2. Voer **Product > Run** uit of druk op `Cmd-R`.
3. Wacht tot de build klaar is en gebruik het appvenster.

Voor een CLI-build met Xcode geselecteerd:

```bash
xcodebuild \
  -project MobilePortGame.xcodeproj \
  -scheme MobilePortGame \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  build
```

In deze shellomgeving is `xcodebuild` mogelijk niet actief omdat alleen Command Line Tools beschikbaar zijn. Gebruik dan een terminal waar Xcode als actieve developer directory staat:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## Unit tests

Open het project en voer **Product > Test** uit (`Cmd-U`), of vanaf een terminal met Xcode:

```bash
xcodebuild \
  -project MobilePortGame.xcodeproj \
  -scheme MobilePortGame \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

De suite test scores, rondestatus/timer-einde, upgrade-effecten en run-lengtes.

Het Swift Package blijft optioneel beschikbaar voor core-only ontwikkeling:

```bash
swift test
```

## iPhone/iPad-simulator

1. Open **Window > Devices and Simulators**.
2. Voeg minimaal een iPhone en iPad toe.
3. Kies ieder toestel als Destination en voer `Cmd-R` uit.
4. Test portret en landscape; de SwiftUI-layout schaalt voor beide.

## Installatie op een echt toestel

1. Verbind het iPhone of iPad via USB.
2. Ontgrendel het toestel en toets Vertrouw deze computer toe.
3. Kies het toestel als Destination.
4. Kies je Team onder **Signing & Capabilities**.
5. Voer `Cmd-R` uit.
6. Bij een restrictie onder iOS: vertrouw het ontwikkelaarsprofiel via **Instellingen > Algemeen > VPN & apparaatbeheer**.

## TestFlight

1. Maak in App Store Connect een apprecord met dezelfde bundle identifier.
2. Meld je Apple Developer-team aan en activeer App Store Distribution signing.
3. Kies in Xcode **Product > Archive** met een Device-destination.
4. Open via **Window > Organizer** de nieuwe archive.
5. Kies **Distribute App > App Store Connect > Upload**.
6. Volg de validatievragen voor privacy, export en eventuele compliance.
7. Open de build onder **TestFlight** in App Store Connect.
8. Voeg interne testers toe of publiceer eerst via een interne review voor externe testers.
9. Testers installeren de build via de TestFlight-app.

## Feature flag voor rewarded ads

`RewardedAdStub` staat standaard op `false`. Er worden geen advertenties, SDK's, netwerkverzoeken of IAP-transacties uitgevoerd. Verbind pas later een SDK na een productbeslissing en behoud de externe beloning buiten de core-game-engine.
