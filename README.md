# Mobile Port Game - Test MVP

Deze `Test/`-worktree draait op branch `test/main` en is niet gekoppeld aan Live.

## MVP

- Opens direct in een havensandbox.
- Lokale in-process room service; vrije kamer wordt automatisch gebruikt, anders wordt een nieuwe kamer gemaakt.
- Maximum twee spelers per kamer.
- Barge, shortsea en deepsea zijn bronlabels; trein en vrachtwagen zijn destinations.
- Gedeelde containerstaat, kraanpositie, havenscore, contracten en maximaal twee tijdelijke hulpverzoeken.
- Geen accountservice, backend, SDK of betaalde rewardintegratie.

## Vereisten

- macOS met volledige Xcode 16 of nieuwer.
- iOS 18 SDK of nieuwer.
- Een iPhone 18 Pro-simulator en/of iPad-simulator.

## Openen en bouwen

```bash
cd /Users/adanevanarkel/Desktop/Quint/GitHub/Mobile-Port-Game/Test
open MobilePortGame.xcodeproj
```

In Xcode:

1. Kies scheme `MobilePortGame`.
2. Kies onder Destination een iPhone 18 Pro of iPad.
3. Voer **Product > Run** uit (`Cmd-R`).

CLI simulatorbuild:

```bash
xcodebuild \
  -project MobilePortGame.xcodeproj \
  -scheme MobilePortGame \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Voor een specifiek iPhone 18 Pro destination:

```bash
xcodebuild \
  -project MobilePortGame.xcodeproj \
  -scheme MobilePortGame \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  build
```

## Unit tests

Via Xcode: **Product > Test** (`Cmd-U`) op het `MobilePortGame`-scheme.

Core package:

```bash
cd /Users/adanevanarkel/Desktop/Quint/GitHub/Mobile-Port-Game/Test
swift test
```

Geteste onderwerpen: containers en lift/drops, room-capaciteit, matchmaking, hulpverzoeken, havenscore en shared contractvoortgang.

## Handmatige test

1. **Nieuw kamer/lobby**: vul een naam in en kies "Nieuwe of vrije kamer".
2. **Claim kraan**: kies Claim kraan.
3. **Selecteer en hef**: kies Barge/Shortsea/Deepsea; beweeg Links/Rechts indien nodig.
4. **Los**: kies Los op Treinwagon of Vrachtwagen.
5. **Help**: open Request Help en kies één of twee tijdelijke needs.

## MVP-beperkingen

- Multiplayer is alleen in-process en niet over meerdere apparaten/processen.
- Er is nog geen persistentie, echte WebSocket-server, account of cloudroom.
- Er is geen rewarded-ad SDK. De stub blijft optioneel en uitgeschakeld.
