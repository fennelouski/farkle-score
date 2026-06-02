# Farkle – Busche & Neller (2017) „minimale“ Regeln

Referenzzusammenfassung des Regelsatzes, der in *Optimal Play of the Farkle Dice Game* (ACG 2017) verwendet wird. Die Autoren haben sich bewusst für eine **kleine Wertungstabelle** entschieden – nur **einzelne 1er/5er** und **drei Gleiche** – mit **keinen** Straights, drei Paaren, vier/fünf/sechs Gleichen oder anderen Kombinationsboni. Das macht es zu einer nützlichen **Referenzimplementierung**, wenn Sie den einfachsten gemeinsamen Farkle-Kern ohne zusätzliche Meldungen wünschen.

**Quelle:** Matthew Busche und Todd W. Neller, „Optimal Play of the Farkle Dice Game“, in *Advances in Computer Games* (ACG 2017), LNCS 10664, Springer, 2017.
**Open-Access-PDF (Autoren-Hosting):** [cs.gettysburg.edu — acg2017.pdf](http://cs.gettysburg.edu/~tneller/papers/acg2017.pdf)
**DOI:** [10.1007/978-3-319-71649-7_6](https://doi.org/10.1007/978-3-319-71649-7_6)

## Ziel

Seien Sie der **erste Spieler, der eine Bankpunktzahl von 10.000 oder mehr erreicht** (Wortlaut des Papiers; die Analyse gilt für **zwei** Spieler, aber das Spiel verallgemeinert).

## Ausrüstung

Sechs standardmäßige sechsseitige Würfel; Bleistift und Papier (oder gleichwertiges Material) für Partituren.

## Turn-Struktur

1. **Zugbeginn:** Wirf alle sechs Würfel.
2. **Wertung:** Identifizieren Sie **Kombinationen** aus **nur diesem Wurf** (siehe Tabelle). Jeder Würfel darf in **höchstens einer** Kombination verwendet werden. Sie können **mehrere** nicht überlappende Kombinationen aus demselben Wurf nehmen.
3. **Beiseite legen:** Wenn es Kombinationen gibt, **müssen** Sie **mindestens eine** Kombination beiseite legen und können weitere beiseite legen. Addieren Sie diese Punkte zu Ihrer **Spielzugsumme**.
4. **Wählen Sie:** Werfen Sie die Würfel erneut, nicht in Kombinationen, oder **bankieren** (addieren Sie die Rundensumme zur Bankpunktzahl und beenden Sie die Runde).
5. **Farkle:** Wenn der Wurf **keine** zulässige Kombination hat, **erzielen Sie 0 für den Zug**; Bankscore bleibt unverändert; Gib die Würfel weiter.
6. **Heiße Würfel:** Wenn Kombinationen **alle sechs** Würfel verwenden, würfeln Sie **alle sechs noch einmal** und setzen Sie den gleichen Spielzug fort (gleicher Spielzug auf Risiko, bis Sie Bank oder Farkle verwenden).

## Wertungskombinationen (vollständige Liste in Papierform)

Dies sind die **einzigen** Bewertungsmuster in dieser Variante:

| Kombination | Punkte |
|-------------|--------|
| Ein **1** | 100 |
| Ein **5** | 50 |
| Drei **1**s | 1.000 |
| Drei **2**s | 200 |
| Drei **3**s | 300 |
| Three **4**s | 400 |
| Drei **5**s | 500 |
| Drei **6**er | 600 |

In diesem Regelwerk gibt es **keine** Punkte für einen 1–6-Lauf, drei Paare, zwei Drillinge oder vier+ Gleiche.

## Optionaler Fairness-Hinweis (aus dem Papier)

Für **zwei Spieler** „fairste“ Eröffnungspositionen empfehlen die Autoren 200 Kompensationspunkte** für den **zweiten** Spieler zu Spielbeginn (siehe Zusammenfassung und Hauptteil des Papiers). Hierbei handelt es sich um eine Forschungs-/Turnieroptimierung, die nicht Teil der meisten Gelegenheitsregelblätter ist.

## Beziehung zu anderen Dateien in diesem Repo

Diese Variante ist **strikt enger** als „FARKLE_RULES.md“ (Cardgames.io), „FARKLE_RULES_WIKIPEDIA_ARNOLD.md“ und „FARKLE_RULES_PLAYMONSTER.md“, die Straights, zusätzliche Vielfache, Paare usw. hinzufügen. Verwenden Sie Busche & Neller, wenn Sie **minimale** Punkte und **maximale** Freiheit bei der Entscheidung wünschen, welche Würfel Sie behalten möchten (das Papier). betont dieses Designziel).
