# Bayes Thinking Lab

Sammlung eigenständiger, interaktiver HTML/JS-Lehrtools rund um Bayesianisches Denken,
GLMs/GLMMs, Prior-Wahl, kausale Inferenz und den Bayesianischen Workflow. Kein Build-System,
kein npm/Python — jede `.html`-Datei ist vollständig eigenständig (Markup + CSS + JS inline).

## Struktur

- `repo/*.html` — deutsche Version der Tools (Referenz/Primärsprache).
- `repo/en/*.html` — englische Version, gleicher Dateiname. Muss inhaltlich/funktional mit
  der DE-Version synchron gehalten werden — **jeder Logik-Fix in einer Version muss auch in
  der anderen nachgezogen werden.**
- `index_de.html` / `index.html` — Übersichtsseiten, gliedern die Tools in 6 Abschnitte
  (Grundlagen, Einstieg GLMMs, Bayes, Small Worlds, Workflow, Entscheidung).
- Kein zentrales JS-Modul: jede Tool-Datei definiert ihre eigenen Hilfsfunktionen
  (PDFs/PMFs, Log-Likelihoods, HDI/ROPE etc.) unabhängig und redundant.

## Lokale Vorschau

`file://`-URLs lassen sich über claude-in-chrome nicht öffnen (Sicherheitsbeschränkung des
Tools). Für eine Vorschau im Browser einen lokalen Server starten (siehe Memory
`reference-local-html-preview-server` bzw. PowerShell `HttpListener`-Skript) und über
`http://localhost:<port>/ToolName.html` öffnen.

## QA-Checkliste beim Bauen/Ändern eines Tools

Diese vier Punkte haben bei einem vollständigen Review aller 22 Tools (2026-08) die
tatsächlich gefundenen Bugs verursacht — gezielt danach fragen, bevor eine Änderung als
fertig gilt:

1. **CSV/Paste-Input?** Nach dem Parsen prüfen: sind alle zurückgegebenen Spalten/Arrays
   gleich lang? Werden Zeilen mit fehlendem Wert in *einer* Spalte konsequent aus *allen*
   Spalten entfernt (nicht nur der einen)? — Sonst verrutschen Y/X-Zuordnungen bei echten
   Datensätzen mit Lücken still und unbemerkt (siehe Bayesian_PP_Check.html Fix).

2. **Code-Generierung für ≥2 gleichartige Elemente** (mehrere Prädiktoren, Gruppen,
   Interaktionsterme)? Bekommt jedes Element im generierten Code eine eindeutige Kennung
   (`coef=`, Name, Index), oder könnten zwei Elemente denselben generischen Bezeichner
   teilen? — Sonst gehen individuelle Einstellungen im erzeugten R/brms-Code verloren bzw.
   brms bricht mit einem Fehler ab (siehe Bayesian_model_architect.html Fix).

3. **Verteilungs-/Wahrscheinlichkeitsfunktion mit natürlichem Parameter-Rand**
   (p=0/1, λ=0, σ=0, n=0)? Was liefert die Funktion tatsächlich an diesem Rand — den
   korrekten Grenzwert, oder schlägt eine Guard-Klausel (z.B. `if(p<=0) return -Infinity`)
   unnötig fehl, obwohl der wahre Wert dort endlich und gültig (oft sogar das Maximum) ist?
   (siehe MLE_tool.html Fix: `bernoulliLogLik`/`poissonLogLik` am Rand).

4. **Neue globale CSS-Variable oder JS-Konstante?** In Light- *und* Dark-Theme definiert?
   In DE- *und* EN-Version ergänzt?

Reine Formel-/Statistik-Korrektheit (PDFs, GLM-Fits, HDI, Cholesky, MCMC-Ratios etc.) war im
Review durchgehend korrekt — das Risiko liegt fast nie in der Mathematik selbst, sondern in
den Rändern und Übergängen oben.
