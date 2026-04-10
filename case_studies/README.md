# Case Studies — Bayes Thinking Lab

Drei vollständige Workflow-Beispiele als R Markdown, je ein Beispiel pro Link-Funktion.

| Datei | Outcome | Familie | Link | Beispiel |
|---|---|---|---|---|
| `01_gaussian_schlaf_kognition.Rmd` | Kontinuierlich | Gaussian | identity | Schlafintervention → Kognitions-Score |
| `02_poisson_panikattacken.Rmd` | Zähldaten | Poisson | log | Expositionstherapie → Panikattacken/Woche |
| `03_bernoulli_remission.Rmd` | Binär (0/1) | Bernoulli | logit | KVT → Remission bei Depression |

Jede Datei enthält: DAG · Datensimulation · Prior-Spezifikation · Prior Predictive Check ·
Modell-Fit · Posterior Predictive Check · HDI/ROPE-Entscheidung · PPC-Shiny-Export.
