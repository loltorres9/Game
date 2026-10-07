# Entwicklungsplan – Arbeitstitel „Zellenlauf“

Dieses Dokument beschreibt Spielidee, Regeln, Architektur und Meilensteine für ein rundenbasiertes 3D-Multiplayer-Spiel. Es ist als Arbeitsgrundlage für Claude Code gedacht. Bitte Meilenstein für Meilenstein vorgehen und nach jedem Meilenstein auf Feedback warten.

---

## 1. Spielidee in einem Satz

Mehrere Spieler müssen in einer Arena aus Zellen Runde für Runde in eine neue Zelle rennen, bis sie jede Zelle einmal besucht haben – während freigelassene Tiere sie jagen, behindern oder in den Zellen auf sie warten.

---

## 2. Tech-Stack

- **Engine:** Godot 4 (aktuelle stabile Version), **GDScript**
- **Multiplayer:** Godot High-Level Multiplayer API, **server-autoritativ** (ein Host entscheidet alle Spielzustände; Clients senden nur Eingaben)
- **Grafik:** zunächst nur Primitive (Würfel = Spieler, Kugeln/Kapseln = Tiere, Boxen = Zellen). Später Low-Poly-Assets (z. B. Kenney, Quaternius)
- **Tests:** Spiellogik als reine Logik-Klassen, testbar ohne Szene (z. B. mit GUT)
- **Versionskontrolle:** Git, ein Commit pro abgeschlossenem Teilschritt

### Architektur-Grundsätze

1. **Logik und Darstellung trennen.** Der gesamte Spielzustand (Runde, Phase, Zellen, Spieler, Tiere, Effekte) liegt in einem zentralen `GameState`, der nicht von Szenen abhängt. Szenen lesen den Zustand und stellen ihn dar.
2. **Von Anfang an server-autoritativ denken**, auch im Singleplayer-Prototyp. Spieleraktionen gehen als Eingaben an den `GameState`, nicht direkt an Nodes. So lässt sich Multiplayer später einbauen, ohne die Logik umzuschreiben.
3. **Alle Balancing-Werte in einer Konfigurationsdatei** (`res://config/balance.tres` oder JSON): Timer, Geschwindigkeiten, Verzögerungen, Effektdauern, Tierwerte, Anzahl Zellen. Keine Magic Numbers im Code.
4. **Tiere als Zustandsautomaten** mit gemeinsamer Basisklasse und datengetriebenen Typen (Werte pro Tierart aus der Konfiguration).

---

## 3. Spielwelt

- Die Arena ist ein **Rechteck**. In der Mitte liegt ein offener **Hof**.
- Rund um den Hof liegen **Zellen** (Startwert: 12, konfigurierbar).
- Jede Zelle besteht aus:
  - **Vorderraum** mit einer **elektronischen Tür** zum Hof (vom Spiel gesteuert)
  - **Hinterraum** mit einer **Handtür** zwischen Vorder- und Hinterraum (von Spielern per Interaktion zu öffnen/schließen)
- Jede Zelle hat eine eindeutige Nummer, die im Spiel sichtbar ist.

---

## 4. Spielregeln

### 4.1 Rundenablauf

Jede Runde hat drei Phasen:

1. **Beobachtungsphase** (Startwert 8 s): Elektronische Türen sind geschlossen. Spieler können durch Gitter in den Hof schauen und Geräusche aus anderen Zellen hören.
2. **Laufphase** (Startwert 25 s): Alle elektronischen Türen öffnen sich. Spieler müssen ihre Zelle verlassen und eine neue erreichen. Tiere werden freigelassen bzw. verlassen ihre Zellen.
3. **Schließung:** Alle elektronischen Türen schließen sich. Danach wird ausgewertet (siehe 4.4).

### 4.2 Zellen-Regeln

- **Ein Spieler pro Zelle pro Runde.** Wer eine Zelle zuerst betritt, beansprucht sie. Für andere Spieler ist sie in dieser Runde gesperrt (Tür blockiert Spieler). **Tiere können trotzdem hinein.**
- **Bereits besuchte Zellen dürfen nicht erneut betreten werden.**
- Wer am Ende der Laufphase **in keiner gültigen Zelle** steht, **scheidet aus**.
- Die Startzelle zählt als besucht (Annahme, siehe offene Punkte).

### 4.3 Siegbedingung

- **Alle Spieler, die überleben und jede Zelle besucht haben, gewinnen.**
- Das Spiel endet, wenn alle noch lebenden Spieler alle Zellen besucht haben oder kein Spieler mehr lebt.
- Ein Spieler, der eine Runde ohne neue Zelle verbracht hat (z. B. festsitzend im Hinterraum, siehe 4.5), braucht entsprechend mehr Runden. Das Spiel läuft für ihn weiter, bis er fertig ist oder ausscheidet.
- **Designziel:** Im Durchschnitt überleben etwa 20–30 % der Spieler. Die Tiere sind das Werkzeug, um das zu erreichen.

### 4.4 Auswertung nach der Schließung

- Befindet sich ein **gefährliches Tier** mit einem Spieler im selben Vorderraum, wird der Spieler angegriffen und scheidet aus – außer er ist im **Hinterraum bei geschlossener Handtür**.
- Befindet sich ein **Störtier** mit einem Spieler im selben Raum, erhält der Spieler den Effekt des Tieres (siehe 6).
- Angriffe können auch schon während der Laufphase passieren (Tier holt Spieler im Hof ein).

### 4.5 Der Hinterraum

Für den Hinterraum gilt eine einheitliche Regel: **Wer im Hinterraum ist (Spieler oder Tier), startet in der nächsten Runde verzögert.**

**Spieler versteckt sich im Hinterraum:**
- Schutz vor Tieren im Vorderraum, solange die Handtür geschlossen ist.
- Nächste Runde: Der Spieler kommt erst heraus, wenn das Tier den Vorderraum verlassen hat. Die Verzögerung hängt von der Tierart ab (siehe 5.1).
- Bleibt das Tier die ganze Laufphase im Vorderraum, sitzt der Spieler die Runde fest (keine neue Zelle, aber nicht ausgeschieden).
- Option: Der Spieler darf die Tür auf eigenes Risiko früher öffnen und versuchen, am Tier vorbeizurennen.

**Tier wird im Hinterraum eingesperrt:**
- Läuft ein Tier in den Hinterraum und ein Spieler schließt die Handtür, ist das Tier für diese Runde eingesperrt.
- Nächste Runde: Das Tier startet verzögert, abhängig von der Tierart. Der Spieler hat dadurch einen Vorsprung.
- Das Tier kommt dann mitten in der Laufphase in den Hof – gefährlich für langsame Spieler.

**Hilfsmittel** liegen in Hinterräumen (siehe 7). Wer sie holen will, muss die Handtür öffnen, ohne zu wissen, ob ein Tier dahinter ist.

---

## 5. Tiere

### 5.1 Gefährliche Tiere

| Tier | Verhalten beim Türöffnen | Verzögerung für eingesperrten Spieler | Verzögerung, wenn selbst im Hinterraum eingesperrt |
|---|---|---|---|
| Wolf | rennt sofort raus, will jagen | kurz | kurz (ungeduldig, kratzt sich schnell frei) |
| Bär | trottet langsam raus | mittel | lang, kommt dann mit Wucht |
| Schlange | bleibt lange liegen, schwer zu sehen | lang und unsicher | sehr lang, unberechenbar |
| Raubkatze | lauert noch kurz an der Tür | unvorhersehbar (Zufallsbereich) | mittel, zufällig |

Jede Tierart hat konfigurierbare Werte: Geschwindigkeit, Sichtweite, Verzögerungsbereich (min/max), Aggressivität.

### 5.2 Tierverhalten (Zustandsautomat)

Mindestzustände: `Idle` (in Zelle), `Leaving` (verlässt Zelle mit Verzögerung), `Roaming` (Hof), `Hunting` (verfolgt Spieler), `EnteringCell`, `Trapped` (im Hinterraum eingesperrt).

Tiere wählen am Ende der Laufphase eine Zelle, in die sie laufen. Spieler müssen beobachten können, welches Tier wohin läuft – das ist eine Kernmechanik.

### 5.3 Schwierigkeitssteigerung (später, Meilenstein 7)

Optionen zur Einhaltung des Überlebensziels, einzeln aktivierbar:
- mehr bzw. gefährlichere Tiere pro Runde
- Spielleiter-System: Tiere werden aggressiver, je mehr Spieler noch leben
- Hunger: Tier wird aggressiver, je länger es niemanden erwischt hat; nach einem Angriff kurz satt
- ausgeschiedene Spieler steuern Tiere

---

## 6. Störtiere und Statuseffekte

Störtiere töten nicht, sondern belegen Spieler mit Effekten.

### 6.1 Störtiere (Kandidaten)

| Tier | Effekt |
|---|---|
| Stinktier | Spieler ist langsamer **und** wird von Raubtieren gewittert (größere Erkennungsreichweite) |
| Stachelschwein | Spieler ist langsamer |
| Gans | lockt in der laufenden Runde Raubtiere zur Zelle des Spielers |
| Affe | stiehlt ein Hilfsmittel |
| Skorpion | verzögertes Gift: Verlangsamung erst in der übernächsten Runde |
| Fledermäuse | eingeschränkte Sicht für den Spieler |
| Waschbär | Handtür der Zelle kann in dieser Runde nicht geschlossen werden |

Für den ersten Prototyp reichen **Stinktier und Stachelschwein**.

### 6.2 Regeln für Effekte

- Ein Effekt hält **maximal 2 Runden**.
- Effekte **stapeln sich**: Verschiedene Effekte wirken gleichzeitig. Derselbe Effekt erneut setzt die Dauer wieder auf 2 Runden (keine Verlängerung darüber hinaus, keine Verstärkung).
- Effekte sind **für alle Spieler sichtbar**:
  - Stinktier: grünliche Duftwolke hinter dem Spieler
  - Stachelschwein: sichtbares Humpeln
  - Skorpion: Schwanken, sobald das Gift wirkt
  - Fledermäuse: eigener Bildschirm eingeschränkt, für andere orientierungsloses Taumeln
- Effekte können durch **Hilfsmittel** entfernt werden.

---

## 7. Hilfsmittel

- Liegen zufällig verteilt in **Hinterräumen**.
- **Inventar:** 2 Plätze (konfigurierbar).
- Hilfsmittel sind am Spieler sichtbar (z. B. Taschenlampe am Gürtel).
- Nutzung nur für sich selbst (Annahme, siehe offene Punkte).

| Hilfsmittel | Wirkung |
|---|---|
| Seife / Waschlappen | entfernt Stinktier-Effekt |
| Pinzette | entfernt Stachelschwein-Effekt |
| Gegengift | entfernt Skorpion-Effekt, auch vorbeugend vor Wirkungsbeginn |
| Taschenlampe | entfernt Fledermaus-Effekt |
| Erste-Hilfe-Kasten | entfernt alle Effekte, sehr selten |

---

## 8. Informationen und Sichtbarkeit

- Anzahl besuchter Zellen anderer Spieler: sichtbar
- **Welche** Zellen andere besucht haben: **nicht** sichtbar (muss beobachtet werden)
- Eigene besuchte Zellen: sichtbar (Markierung in der Welt und im HUD)
- Ob sich ein Spieler im Hinterraum versteckt: für andere sichtbar
- Später: Proximity-Voice-Chat (über fertige Lösung, z. B. Steam Voice, nicht selbst bauen)

---

## 9. Meilensteine

Jeder Meilenstein endet mit einem spielbaren Stand. Nach jedem Meilenstein stoppen, kurz zusammenfassen, was gebaut wurde und was getestet werden sollte.

### M0 – Projekt-Setup
- Godot-4-Projekt mit Ordnerstruktur (`scenes/`, `scripts/logic/`, `scripts/view/`, `config/`, `tests/`)
- Balancing-Konfiguration mit allen Startwerten aus diesem Dokument
- Test-Framework eingerichtet
- **Fertig, wenn:** Projekt startet, ein leerer Test läuft durch

### M1 – Arena und Rundensystem (Singleplayer, keine Tiere)
- Arena mit Hof und 12 Zellen aus Primitiven, Vorder- und Hinterraum, beide Türen
- Spieler mit Third-Person-Steuerung (Laufen, Interagieren)
- Rundenphasen mit Timer und HUD (Phase, Restzeit, besuchte Zellen)
- Zellen-Regeln: Beanspruchen, keine erneuten Besuche, Ausscheiden außerhalb einer Zelle
- Siegbedingung
- **Fertig, wenn:** Man allein alle 12 Zellen nacheinander besuchen und gewinnen oder durch Stehenbleiben ausscheiden kann

### M2 – Gefährliche Tiere
- Basisklasse Tier mit Zustandsautomat
- Wolf, Bär, Schlange, Raubkatze mit Werten aus der Konfiguration
- Tiere starten in Hinterräumen, verlassen Zellen, laufen in neue Zellen
- Angriffe und Auswertung nach der Schließung
- **Fertig, wenn:** Man beobachten kann, welches Tier in welche Zelle läuft, und stirbt, wenn man mit einem Raubtier in einer Zelle endet

### M3 – Hinterraum-Mechaniken
- Handtür schließen/öffnen
- Schutz im Hinterraum
- Verzögerter Start für Spieler und Tiere, abhängig von Tierart
- Tiere im Hinterraum einsperren
- Früher Ausbruch auf eigenes Risiko
- Festsitzen über eine ganze Runde
- **Fertig, wenn:** Alle Fälle aus Abschnitt 4.5 im Spiel funktionieren

### M4 – Störtiere, Effekte, Hilfsmittel
- Stinktier und Stachelschwein
- Effektsystem mit Dauer, Stapelung, visueller Darstellung
- Hilfsmittel in Hinterräumen, Inventar, Benutzung
- **Fertig, wenn:** Effekte wirken, sichtbar sind, nach 2 Runden enden und mit Hilfsmitteln entfernt werden können

### M5 – Bots als Mitspieler
- Einfache KI-Spieler, die die Regeln einhalten, um Zellen konkurrieren und auf Tiere reagieren
- 7 Bots + 1 menschlicher Spieler
- Debug-Overlay mit Statistiken (Überlebensrate pro Spiel)
- **Fertig, wenn:** Ein komplettes Spiel mit 8 Teilnehmern läuft und man die Konkurrenz um Zellen spürt

### M6 – Multiplayer
- Host/Client über Godot High-Level Multiplayer
- Lobby (Beitreten per IP für den Anfang)
- Synchronisation von Spielern, Tieren, Türen, Effekten
- Server entscheidet, wer eine Zelle zuerst betreten hat
- Bots füllen leere Plätze auf
- **Fertig, wenn:** Mehrere Instanzen lokal zusammen ein komplettes Spiel spielen können

### M7 – Balancing und erweiterte Tiermechaniken
- Restliche Störtiere
- Optional: Spielleiter-System, Hunger, ausgeschiedene Spieler steuern Tiere
- Feinabstimmung auf Überlebensziel 20–30 %

### M8 – Grafik und Atmosphäre
- Low-Poly-Assets für Arena, Spieler, Tiere
- Animationen, Sounds, Geräusche aus Hinterräumen
- Visuelle Effekte für Statuseffekte

### M9 – Online-Anbindung
- Steam-Integration (z. B. GodotSteam) für Lobby und Matchmaking
- Proximity-Voice-Chat

---

## 10. Offene Punkte

Diese Punkte sind noch nicht endgültig entschieden. Bis auf Weiteres gilt jeweils die genannte Annahme; bitte die Umsetzung so gestalten, dass sie leicht änderbar ist.

| Frage | Annahme |
|---|---|
| Zählt die Startzelle als besucht? | Ja |
| Können Hilfsmittel an andere Spieler weitergegeben werden? | Nein |
| Wie viele Zellen und Spieler? | 12 Zellen, 8 Spieler |
| Wie viele Tiere pro Runde, und wie steigt die Zahl? | Start mit 2 gefährlichen + 2 Störtieren, +1 Tier alle 3 Runden |
| Was passiert bei exakt gleichzeitigem Betreten einer Zelle? | Server entscheidet nach Zeitstempel |
| Kameraperspektive? | Third Person |

---

## 11. Arbeitsweise für Claude Code

- Immer nur einen Meilenstein auf einmal umsetzen.
- Vor jedem Meilenstein kurz den geplanten Ansatz beschreiben.
- Spiellogik mit Tests absichern, besonders Zellen-Regeln, Rundenphasen und Effekte.
- Keine Assets erfinden oder generieren; Primitive verwenden, bis M8.
- Bei Unklarheiten in den Regeln nachfragen statt raten.
- Nach jedem Meilenstein: Zusammenfassung, wie man das Ergebnis testet, und welche Werte man in der Konfiguration ausprobieren sollte.
