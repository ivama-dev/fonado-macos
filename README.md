# Fonado für macOS

Native SwiftUI/AppKit-App ab macOS 14, Bundle-ID `ai.fonado.macos`, Scheme **FonadoMac**. Kein Catalyst. Dieses Repository enthält die Mac-App samt benötigten gemeinsamen Apple-Dateien, Assets, isolierten Prüfungen und Hersteller-Lizenzen. Ein zweiter iOS-Checkout ist zum Bauen nicht erforderlich.

## Bauen und prüfen

Xcode 27 und Swift auf macOS verwenden. Das bestehende Entwicklungsteam und die HIDAPI-Anbindung bleiben erhalten. Auf einem anderen Mac die eigene passende Signierung einrichten; private Schlüssel und Kontodaten gehören nicht in Git.

```sh
bash Checks/run-checks.sh
python3 Checks/customer-provisioning-checks.py
bash macos/Checks/run-device-checks.sh
bash macos/Checks/run-menu-bar-checks.sh
./macos/build.sh
```

Die gebaute App liegt standardmäßig unter `/private/tmp/FonadoMacNativeBuild/Build/Products/Debug/Fonado.app`. Bei synchronisierten Dokumentenordnern aus einer sauberen lokalen Quellkopie ohne Finder-Metadaten bauen. Intel, Notarisierung und ein echter Headset-Hörvergleich sind gesondert zu prüfen.

## Größere Schrift und Bedienung

Build **35** bietet oben im Hauptfenster eine kleinere/größere Schrift-Schaltfläche
und eine Prozentwahl für **100, 110, 125, 150, 175 oder 200 %**. Damit werden
Schrift, Symbole, Listen und Bedienelemente gemeinsam vergrößert. Die Auswahl
bleibt lokal auf diesem Mac gespeichert und gilt auch nach einem Neustart.

Im Menü **Darstellung** stehen **Vergrößern (⌘+)**, **Verkleinern (⌘−)** und
**Standardgröße (⌘0)** zur Verfügung. Separate Dialoge und Schnellzugriff werden
ebenfalls vergrößert; das kleine Gesprächsfenster passt seine Größe an.
Reicht der Bildschirm nicht aus, bleiben Inhalte über Bildlaufleisten erreichbar.
Die Telefonieverbindung und eingegebene Nummern bleiben beim Größenwechsel erhalten.

`bash macos/Checks/run-display-checks.sh` prüft gültige/ungültige gespeicherte
Größen, die Schrittgrenzen, Layoutgrößen bis 200 % und die Speicherung.
Eine isolierte Debug-Vorschau mit eigener Bundle-ID prüft die Oberfläche ohne
gespeicherte Konten, Registrierung oder echte Anrufe. Der Debug-Schlüssel
`FonadoTeamPreview` in der Vorschau-Info.plist aktiviert dieselben Beispieldaten
wie `--preview-team-ui`; Release-Builds werten ihn nicht aus.

Prüfstand 15. Oktober 2026: Größenprüfungen sowie Debug- und signierter
Release-Build bestanden. Die native Vorschau bestätigte 150/200 %, erhaltene
Wählfeldeingaben, Teamnavigation, deutsche Tastenkürzel, Speicherung nach Neustart
und vollständige vergrößerte Dialoge. Build 35 wurde aus einer festen Quellkopie
gebaut, lokal mit Sicherung der bisherigen App installiert und wieder gestartet.
Die installierte Version zeigt die Größenregler; Firma, Nebenstelle und die
registrierte Telefonieverbindung sind wiederhergestellt. Standardgröße: 100 %.

## Menüleiste und Hintergrundbetrieb

Der Menüleistenstatus bietet einen interaktiven Schnellzugriff über das Fonado-Signet oben rechts. Ein Klick zeigt den aktuellen Verbindungsstatus, Firma/Nebenstelle, Anrufprofil, Direktwahl sowie Verknüpfungen zu Favoriten, Team und Anrufliste. Während eines Gesprächs stehen Annehmen/Ablehnen, Mikrofon, Halten/Fortsetzen und Auflegen zur Verfügung. Rechtsklick öffnet das kompakte native Menü. Beide Ansichten verwenden denselben bestehenden Kontostand und Anrufmanager.

Minimieren oder Schließen des Hauptfensters beendet die Telefonie nicht. **Fonado öffnen** bzw. die Verknüpfungen stellen das Fenster wieder her. Der Schnellzugriff ist auch über **Fonado → Schnellzugriff öffnen** bzw. **⌥⌘M** erreichbar. **Beenden** und Cmd-Q beenden die App; bei laufendem Gespräch bleibt die bisherige Rückfrage erhalten. Eingehende Anrufe benötigen einen wachen Mac. Der automatische Start beim Mac-Login wird dadurch nicht geändert.

Build **29** hält das Menüleistensymbol auch während eines Gesprächs kompakt. Neue Installationen beginnen am rechten Rand; eine später selbst gewählte Position bleibt erhalten. Falls macOS das Symbol durch Platzmangel verdeckt, stellt **Fonado → Menüleistensymbol rechts einblenden** nur die Fonado-Position wieder her, ohne die Telefonieverbindung neu zu starten. Die Diagnose protokolliert, ob die Symbolfläche innerhalb eines sichtbaren Bildschirmbereichs liegt; `isVisible` allein erkennt den Platzmangel unter der Notch nicht. macOS kann bei einer vollständig belegten Menüleiste weiterhin Symbole verdrängen. Gesprächsdauer und Audiowellen bleiben im Schnellzugriff sichtbar.

Prüfstand 11. Oktober 2026: isolierte Positions-/Notch-Prüfungen und signierter Release-Build 29 bestanden, lokale App installiert und mit dem bisherigen Konto registriert. Die tatsächliche Sichtbarkeit nach Betätigung der Wiederherstellung ist noch zu bestätigen.

Prüfstand 10. Oktober 2026: signierte Debug-/Release-Builds und die Mac-Audio-/Gesprächszustandsprüfungen bestanden. Mit isoliertem Testgespräch geprüft: Minimieren, Schließen/Wiederöffnen, fortlaufende Gesprächsdauer, Stummschalten, Halten/Fortsetzen und Auflegen mit Rückkehr zur Direktwahl. Die lokale Release-App bleibt nach Schließen des Hauptfensters registriert; Firma, Nebenstelle und aktives Profil erscheinen im Schnellzugriff. Der Team-Link öffnet das vorhandene Firmenadressbuch. Die Anrufbedienung wurde mit simulierten Gesprächsdaten geprüft.

## LDAP-Adressbuch

Build **36** wurde am 15.10.2026 als signierter universeller Release für Apple Silicon und Intel gebaut und lokal installiert. Die damalige Version `0.1.0 (36)` verband sich mit dem vorhandenen Konto. Der Vorgänger und die Rollout-Nachweise sind in der lokalen Rollout-Sicherung archiviert.

Wenn LDAP für die ausgewählte Firma aktiviert ist, erscheint **Adressbuch** in der Seitenleiste. Die Suche nach Name, E-Mail oder Telefonnummer startet ab zwei Zeichen und zeigt die vom Firmenserver gelieferten Telefonnummern zum Anrufen und Übernehmen als Favorit. Bei weiteren Treffern lässt sich die Suche eingrenzen. Aktivierung, Serverdaten, Attributzuordnung und Verbindungstest liegen unter **Administration → Cloud-Kunde → Adressbuch**; die App erhält keine LDAP-Zugangsdaten.

Eingehende Rufnummern werden nach Team und Mac-Kontakten zusätzlich im LDAP-Adressbuch aufgelöst, sofern diese Funktion beim Kunden aktiviert wurde. Nur eindeutige Treffer liefern einen Namen; die ursprüngliche Rufnummer bleibt erhalten. Ein LDAP-Ausfall unterbricht keinen Anruf. Die Aktivierung wird im Vordergrund alle 30 Sekunden aktualisiert. Ergebnisse bleiben im Arbeitsspeicher und werden bei Firmenwechsel, Abmelden oder Deaktivierung entfernt. Die neue Prüfung `LDAPAddressBookChecks` deckt insbesondere verspätete Suchantworten und Firmenwechsel ab.

## Struktur und gemeinsame Dateien

Ab Build **33** öffnet in der **Anrufliste** die Aktion **Rückrufbitte per E-Mail** das Standard-Mailprogramm mit einem vorbereiteten Entwurf. Sie steht im Drei-Punkte-Menü, im Rechtsklick-Menü und in den Anrufdetails bereit. Betreff und Nachricht enthalten Name (sofern eindeutig bekannt), die ursprüngliche Rufnummer, Anrufzeit mit Zeitzone und Anrufstatus. Der Empfänger bleibt frei wählbar. Für unterdrückte oder ungültige Rufnummern ist die Aktion deaktiviert.

Favoriten werden in eigenen, pro Benutzer gespeicherten Gruppen angezeigt. **Favoriten → Gruppen verwalten** ermöglicht Anlegen, Umbenennen und Verschieben per Drag & Drop oder Pfeilen. Das Kontextmenü eines Favoriten verschiebt ihn in eine andere Gruppe; innerhalb einer Gruppe lässt sich die Reihenfolge verschieben. Beim Löschen einer Gruppe bleiben ihre Favoriten unter **Allgemein** erhalten. Bestehende Favoriten werden dem bestätigten bisherigen Konto zugeordnet; die alte Datei bleibt erhalten.

Favoriten und Gruppen werden nach der Anmeldung automatisch mit dem persönlichen Fonado-Konto synchronisiert. Gruppen anlegen, umbenennen, löschen und sortieren sowie Kontakte zuordnen oder sortieren gilt auf jedem Gerät. Die Gruppe **Allgemein** bleibt erhalten; beim Löschen einer eigenen Gruppe werden deren Favoriten dorthin verschoben. Nur ausgewählte Favoriten werden übertragen, nicht das gesamte Adressbuch. Es gibt keinen Schalter zum Starten oder Beenden der Synchronisierung.

Änderungen funktionieren offline und werden bei der nächsten Verbindung abgeglichen. Gleichzeitige Änderungen werden anhand des letzten bestätigten Kontostands zusammengeführt; bei konkurrierenden Änderungen desselben Feldes gewinnt die noch ausstehende lokale Änderung beim erneuten Speichern. Löschungen haben Vorrang vor veralteten Kopien. Der automatische Worker wiederholt Revisionskonflikte höchstens dreimal pro Durchlauf und prüft im Vordergrund alle fünf Sekunden. Abmelden leert die Anzeige und schützt vor verspäteten Antworten einer alten Sitzung. Andere Benutzer und Firmenadministratoren haben keinen Zugriff auf die persönlichen Favoriten.

Bestehende Favoriten werden einmalig dem bestätigten bisherigen Konto zugeordnet. Die alte Datei bleibt unverändert. Alte Favoriten ohne belegte Kontozuordnung erfordern weiterhin **Vorhandene Favoriten übernehmen**, damit die Favoriten einer anderen Person nicht versehentlich übertragen werden.

Build **30** (macOS) enthält die automatische Synchronisierung. Gemeinsame Swift-/Windows-Testdaten prüfen Gruppen, Felder, Zuordnung, Reihenfolge und Löschungen. Die Worker-Prüfungen decken Offline-Neustart, zwei Geräte, begrenzte Revisionswiederholungen, Änderungen während eines Uploads, verlorene Antworten, Kontowechsel und beschädigte Caches ab. API: `GET/POST /v1/cloud/favorites`, Schema 1, Revision pro Benutzer, verschlüsselte serverseitige Speicherung.

Echte Geräteabnahme zwischen iPhone, Mac und Windows bleibt erforderlich. Ein erfolgreicher Quellbuild bestätigt keine Veröffentlichung in TestFlight oder im Windows Store.


- `macos/FonadoMac/`: Oberfläche, Geräte-/Headset-Wahl, Gesprächsfenster und Menüleistenstatus.
- `Shared/`: die von der Mac-App verwendeten gemeinsamen Apple-Dateien; ursprüngliches Verhalten bleibt erhalten.
- `Checks/`: gemeinsame Verbindungs-, Konto-, Profil-, Präsenz- und Anrufhistorienprüfungen.
- `macos/Checks/`: Mac-Audiogeräte- und SDK-Laufzeitprüfungen.

Liblinphone 5.5.23 bleibt die einzige Telefonie-Engine. Team, Profile, Präsenz, Anrufhistorie, Weiterleitungen, Anmeldung und Audioverarbeitung bleiben erhalten. Der Kontoserver wird separat verwaltet.

Die [iOS-App](https://github.com/ivama-dev/fonado-ios) ist die Referenz für die gemeinsamen Dateien. Mit `python3 scripts/sync-shared-from-ios.py --source ../fonado-ios --check` lässt sich ihr Stand vergleichen. Ohne `--check` werden freigegebene Änderungen übernommen; lokal geänderte gemeinsame Dateien werden nicht überschrieben. Anschließend beide Apps bauen und ihre Prüfungen ausführen. Die Herkunft und Dateihashes stehen in `Shared/upstream.json`.

Die [Mac-Oberfläche als Referenz für Windows](macos/WINDOWS-UI-REFERENZ.md) bleibt enthalten.

## Übernahme

Übernommen wurde der aktuelle Quellstand vom 9. Oktober 2026 (Build 26). Ausschließlich Projektpfade und Prüfpfade wurden an das eigene Repository angepasst. Die ursprüngliche private Git-Historie bleibt im bisherigen Repository und wird wegen des dort enthaltenen Servercodes nicht hier veröffentlicht. Eine Store-Veröffentlichung erfolgt durch die Migration nicht.

## Lizenz

Die Fonado-macOS-App steht wie der Windows-Client unter **GNU Affero General Public License v3 oder später** (`AGPL-3.0-or-later`). Siehe [LICENSE](LICENSE) und [NOTICE.md](NOTICE.md). Drittanbieter behalten ihre eigenen Lizenzen; [Hinweise und unveränderte Lizenzdateien](THIRD-PARTY-NOTICES.md). GitHub-Prüfungen verwenden synthetische Daten und benötigen keine Produktionszugänge.

## Fonado-Projekt und technische Identität · Build 41

Das Xcode-Projekt liegt unter `macos/FonadoMac.xcodeproj`, Target und Scheme heißen **FonadoMac**. Der App-Einstiegspunkt ist `FonadoMacApp`; Quellen und Entitlements liegen unter `macos/FonadoMac/`. Das Produkt heißt `Fonado.app`, die Bundle-ID lautet `ai.fonado.macos`.

Auch lokale Speicherkennungen, Vorschau-Schlüssel, Build-Variablen und die App-Protokollkennungen verwenden Fonado. Die Übernahme einer bestehenden Installation auf die neue App-Identität erfolgt als gesondert geprüfte lokale Migration, damit Konten, Favoriten, Verlauf und Einstellungen erhalten bleiben.

Die Oberfläche verwendet die systemIQ-Farben Grün `#96B914`, Anthrazit `#373737`, Hellgrau und Weiß. Darkmode-Beschriftungen bleiben neutral hell; grüne Aktionsflächen erhalten anthrazitfarbene Beschriftungen.
