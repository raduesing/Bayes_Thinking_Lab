# ═══════════════════════════════════════════════════════════
#  Posterior Predictive Check — Bayes Thinking Lab
#  Shiny App
# ═══════════════════════════════════════════════════════════

library(shiny)
library(bslib)
library(brms)
library(bayesplot)
library(ggplot2)
library(posterior)
library(dplyr)
library(lme4)

# Allow large file uploads (brms objects can be 100-300 MB)
options(shiny.maxRequestSize = 500 * 1024^2)

# ── Design tokens (matching the Lab) ────────────────────────
LAB_COLORS <- list(
  bg       = "#0d1018",
  paper    = "#141820",
  ink      = "#ebe5d8",
  ink2     = "#8a8070",
  a1       = "#e8614a",  # red
  a2       = "#4ab0d8",  # blue
  a3       = "#80cb52",  # green
  a4       = "#c87ad8",  # purple
  a5       = "#e07830",  # orange  ← Posterior PPC accent
  a6       = "#2bc7c4",  # teal
  grid     = "#20262f",
  panel    = "#1a2030",
  border   = "#2c3445"
)

ACCENT <- LAB_COLORS$a5  # orange = Posterior PPC

# ── bayesplot theme matching Lab ────────────────────────────
bayesplot_theme_set(
  theme_minimal(base_family = "mono") +
    theme(
      plot.background   = element_rect(fill = LAB_COLORS$paper, color = NA),
      panel.background  = element_rect(fill = LAB_COLORS$panel, color = NA),
      panel.grid.major  = element_line(color = LAB_COLORS$grid, linewidth = 0.5),
      panel.grid.minor  = element_blank(),
      text              = element_text(color = LAB_COLORS$ink2, size = 13),
      axis.text         = element_text(color = "#b0b8c8", size = 12),
      axis.title        = element_text(color = LAB_COLORS$ink2, size = 13),
      plot.title        = element_text(color = LAB_COLORS$ink, size = 14, face = "bold"),
      plot.subtitle     = element_text(color = LAB_COLORS$ink2, size = 12),
      strip.text        = element_text(color = LAB_COLORS$ink, size = 12, face = "bold"),
      strip.background  = element_rect(fill = LAB_COLORS$grid, color = NA),
      legend.background = element_rect(fill = LAB_COLORS$panel, color = NA),
      legend.text       = element_text(color = LAB_COLORS$ink2, size = 12),
      legend.title      = element_text(color = LAB_COLORS$ink2, size = 12)
    )
)
# skyblue for yrep lines, dark navy for observed y
color_scheme_set(c(
  "#1a3a5c",  # light (used for y observed) — dark navy
  "#2c5282",
  "#87ceeb",  # skyblue (yrep lines)
  "#5aa8d8",
  "#87ceeb",
  "#b3dff5"   # lightest yrep
))

# ── Helper functions ─────────────────────────────────────────

# Auto-evaluate a p-value: returns list(rating, color, message)
eval_pval <- function(p, stat_name = "Statistik") {
  if (is.na(p)) return(list(rating = "unbekannt", color = "gray", msg = "Konnte nicht berechnet werden."))
  if (p < 0.025 || p > 0.975) {
    list(rating = "⚠ Auffällig", color = ACCENT,
         msg = sprintf("Der beobachtete Wert liegt im %.0f%%-Extrembereich der simulierten Verteilung. Das Modell hat Schwierigkeiten, %s der Daten zu reproduzieren.", min(p, 1-p)*200, stat_name))
  } else if (p < 0.05 || p > 0.95) {
    list(rating = "~ Grenzwertig", color = LAB_COLORS$a4,
         msg = sprintf("Leichte Auffälligkeit bei %s. Nicht kritisch, aber beachtenswert.", stat_name))
  } else {
    list(rating = "✓ Unauffällig", color = LAB_COLORS$a3,
         msg = sprintf("%s wird vom Modell gut reproduziert.", stat_name))
  }
}

# Bayesian p-value for a statistic
bayes_pval <- function(yrep, y, stat_fn) {
  t_obs  <- stat_fn(y)
  t_rep  <- apply(yrep, 1, stat_fn)
  mean(t_rep >= t_obs)
}

# Parse family from brms fit
get_family_label <- function(fit) {
  fam <- family(fit)$family
  link <- family(fit)$link
  switch(fam,
    gaussian   = "Normal (Gaussian)",
    bernoulli  = "Bernoulli (0/1)",
    binomial   = "Binomial",
    poisson    = "Poisson (Zähldaten)",
    negbinomial = "Negativ-Binomial",
    Gamma      = "Gamma (positive Werte)",
    lognormal  = "Lognormal",
    student    = "Student-t",
    beta       = "Beta (0–1)",
    fam
  )
}

# Auto-generate model summary text
model_summary_text <- function(fit) {
  fam    <- get_family_label(fit)
  n_obs  <- nrow(fit$data)
  n_pred <- length(all.vars(fit$formula$formula)[-1])
  chains <- fit$fit@sim$chains
  iters  <- fit$fit@sim$iter
  warmup <- fit$fit@sim$warmup

  # Convergence check
  rhat_vals <- rhat(fit)
  rhat_max  <- max(rhat_vals, na.rm = TRUE)
  divs      <- sum(nuts_params(fit)$Value[nuts_params(fit)$Parameter == "divergent__"])

  list(
    fam = fam, n_obs = n_obs, n_pred = n_pred,
    chains = chains, iters = iters, warmup = warmup,
    rhat_max = rhat_max, divs = divs,
    rhat_ok = rhat_max < 1.01,
    divs_ok = divs == 0
  )
}

convergence_badge <- function(ok, label) {
  col <- if (ok) LAB_COLORS$a3 else LAB_COLORS$a1
  icon <- if (ok) "✓" else "✗"
  tags$span(
    style = sprintf("font-family:'DM Mono',monospace;font-size:.7rem;
                     padding:.15rem .5rem;border:1.5px solid %s;color:%s;margin-right:.4rem", col, col),
    paste(icon, label)
  )
}

# ═══════════════════════════════════════════════════════════
#  UI
# ═══════════════════════════════════════════════════════════

ui <- fluidPage(
  title = "Posterior Predictive Check — Bayes Thinking Lab",
  theme = bs_theme(
    version = 5,
    bg       = LAB_COLORS$bg,
    fg       = LAB_COLORS$ink,
    primary  = ACCENT,
    base_font = font_google("DM Mono"),
    heading_font = font_google("Fraunces")
  ),

  # ── Custom CSS ──────────────────────────────────────────
  tags$head(
    tags$style(HTML(sprintf('
      /* ── Lab Design Tokens ── */
      :root {
        --bg: %s; --paper: %s; --ink: %s; --ink2: %s;
        --a1: %s; --a2: %s; --a3: %s; --a4: %s; --a5: %s; --a6: %s;
        --grid: %s; --panel: %s; --border: %s;
      }
      body { background: var(--bg); font-family: "DM Mono", monospace; }

      /* ── Topbar ── */
      #topbar {
        background: var(--paper); border-bottom: 1.5px solid var(--border);
        padding: .7rem 1.4rem; display: flex; align-items: flex-start;
        justify-content: space-between; gap: 1rem;
      }
      .tb-title { font-family: "Fraunces", Georgia, serif; font-size: 1.7rem;
                  font-weight: 300; letter-spacing: -.02em; }
      .tb-title em { font-style: italic; color: var(--a5); }
      .tb-sub  { font-size: .78rem; color: var(--ink2); margin-top: .15rem; letter-spacing: .03em; }
      .tb-auth { font-size: .68rem; color: var(--ink2); opacity: .5; margin-top: .08rem; }

      /* ── Buttons ── */
      .lab-btn {
        font-family: "DM Mono", monospace; font-size: .68rem;
        padding: .3rem .75rem; border: 1.5px solid var(--border);
        background: transparent; cursor: pointer; color: var(--ink2);
        transition: all .15s; white-space: nowrap; border-radius: 0;
      }
      .lab-btn:hover { border-color: var(--a5); color: var(--a5); }
      .lab-btn-accent {
        border-color: var(--a5) !important; color: var(--a5) !important;
      }
      .lab-btn-accent:hover { background: var(--a5) !important; color: var(--bg) !important; }

      /* ── Phase containers ── */
      .phase-box {
        background: var(--paper); border: 1px solid var(--border);
        margin: .75rem 0; padding: 0;
      }
      .phase-header {
        background: var(--panel); border-bottom: 1px solid var(--border);
        padding: .6rem 1.1rem; display: flex; align-items: center; gap: .65rem;
      }
      .phase-num {
        font-size: .7rem; letter-spacing: .1em; text-transform: uppercase;
        border: 1px solid var(--a5); color: var(--a5); padding: .1rem .4rem;
      }
      .phase-title { font-size: 1rem; color: var(--ink); font-weight: 500; }
      .phase-body  { padding: 1rem 1.2rem; }

      /* ── Narrative / explanation boxes ── */
      .narr-box {
        background: var(--panel); border-left: 3px solid var(--a5);
        padding: .8rem 1.1rem; font-size: .78rem; color: var(--ink2);
        line-height: 1.8; margin-bottom: .8rem;
      }
      .narr-box b { color: var(--ink); }
      .narr-box code {
        background: var(--bg); border: 1px solid var(--border);
        color: var(--a2); padding: .02rem .28rem; font-size: .7rem;
      }

      /* ── Rating badges ── */
      .badge-good { color: var(--a3); border-color: var(--a3); }
      .badge-warn { color: var(--a4); border-color: var(--a4); }
      .badge-bad  { color: var(--a1); border-color: var(--a1); }

      /* ── Station labels ── */
      .station-lbl {
        font-size: .72rem; letter-spacing: .08em; text-transform: uppercase;
        color: var(--ink2); margin-bottom: .35rem;
      }

      /* ── Plots ── */
      .plot-wrap { background: var(--panel); padding: .5rem; }

      /* ── Comparison panels ── */
      .compare-grid { display: grid; grid-template-columns: 1fr 1fr; gap: .5rem; }
      .compare-good { border-left: 3px solid var(--a3); padding: .6rem .8rem;
                      background: var(--panel); font-size: .75rem; color: var(--ink2); }
      .compare-bad  { border-left: 3px solid var(--a1); padding: .6rem .8rem;
                      background: var(--panel); font-size: .75rem; color: var(--ink2); }
      .compare-good b, .compare-bad b { color: var(--ink); display: block; margin-bottom: .2rem; }

      /* ── Summary table ── */
      .summary-row {
        display: flex; justify-content: space-between; align-items: center;
        border-bottom: 1px solid var(--grid); padding: .45rem .1rem;
        font-size: .78rem;
      }
      .summary-row:last-child { border-bottom: none; }

      /* ── Progress bar ── */
      #progress-bar {
        position: sticky; top: 0; z-index: 100;
        background: var(--paper); border-bottom: 1px solid var(--border);
        padding: .3rem 1.2rem; display: flex; gap: 1rem; align-items: center;
        font-size: .72rem; letter-spacing: .06em; text-transform: uppercase;
      }
      .prog-step { color: var(--ink2); opacity: .4; }
      .prog-step.done { color: var(--a3); opacity: .75; }
      .prog-step.active { opacity: 1; font-weight: 600; }
      #prog-0.active { color: var(--ink2); }
      #prog-1.active { color: var(--a2); }
      #prog-2.active { color: var(--a6); }
      #prog-3.active { color: var(--a5); }
      #prog-4.active { color: var(--a3); }
      #prog-5.active { color: var(--a4); }

      /* ── File input ── */
      .form-control { background: var(--panel) !important; border-color: var(--border) !important;
                      color: var(--ink) !important; font-size: .7rem !important; border-radius: 0 !important; }
      .form-label { font-size: .85rem; color: var(--ink2); }

      /* ── Collapsible details ── */
      .details-toggle {
        font-size: .63rem; color: var(--a2); cursor: pointer; border: none;
        background: none; padding: 0; text-decoration: underline dotted;
        margin-top: .4rem; display: inline-block;
      }
      .details-box {
        background: var(--bg); border: 1px solid var(--border);
        padding: .5rem .7rem; font-size: .63rem; color: var(--ink2);
        line-height: 1.75; margin-top: .35rem;
      }
      .details-box b { color: var(--ink); }

      /* ── Back to Lab link ── */
      .back-link {
        font-size: .65rem; color: var(--a5); text-decoration: none;
        border: 1.5px solid var(--a5); padding: .25rem .65rem;
      }
      .back-link:hover { background: var(--a5); color: var(--bg); }

      hr.lab-hr { border: none; border-top: 1px solid var(--border); margin: 1rem 0; }

      /* Overwrite bslib defaults */
      .card { background: var(--paper) !important; border: 1px solid var(--border) !important;
              border-radius: 0 !important; }
      .shiny-output-error { color: var(--a1); font-size: .7rem; }
    ',
    LAB_COLORS$bg, LAB_COLORS$paper, LAB_COLORS$ink, LAB_COLORS$ink2,
    LAB_COLORS$a1, LAB_COLORS$a2, LAB_COLORS$a3, LAB_COLORS$a4, LAB_COLORS$a5, LAB_COLORS$a6,
    LAB_COLORS$grid, LAB_COLORS$panel, LAB_COLORS$border
    )))
  ),

  # ── Topbar ─────────────────────────────────────────────
  div(id = "topbar",
    div(
      div(class = "tb-title", "Posterior Predictive", tags$em("Check")),
      div(class = "tb-sub", "Modellprüfung · bayesplot · brms · Geführtes Tutorial"),
      div(class = "tb-auth", "© Dr. Rainer Düsing · Interactive Tools by Claude")
    ),
    div(style = "display:flex;gap:.4rem;align-items:flex-start",
      tags$a(href = "https://github.com/raduesing/Bayes_Thinking_Lab/index.html", class = "lab-btn lab-btn-accent",
             "← Zum Lab"),
      tags$a(href = "https://github.com/raduesing/Bayes_Thinking_Lab/Brms_model_builder.html", class = "lab-btn",
             "⬡ Model Builder")
    )
  ),

  # ── Progress strip ─────────────────────────────────────
  div(id = "progress-bar",
    span(style = "color:var(--ink2);opacity:.6", "Fortschritt:"),
    tags$span(id = "prog-0", class = "prog-step active", "0 · Einführung"),
    span(style = "color:var(--grid)", "·"),
    tags$span(id = "prog-1", class = "prog-step", "1 · Upload"),
    span(style = "color:var(--grid)", "·"),
    tags$span(id = "prog-2", class = "prog-step", "2 · Diagnose"),
    span(style = "color:var(--grid)", "·"),
    tags$span(id = "prog-3", class = "prog-step", "3 · PPC Tour"),
    span(style = "color:var(--grid)", "·"),
    tags$span(id = "prog-4", class = "prog-step", "4 · Bewertung"),
    span(style = "color:var(--grid)", "·"),
    tags$span(id = "prog-5", class = "prog-step", "5 · Exploration")
  ),
  # JS: track scroll position to update progress bar
  tags$script(HTML("
    document.addEventListener('DOMContentLoaded', function() {
      var phases = [
        { id: 'prog-0', selector: '#phase-box-0' },
        { id: 'prog-1', selector: '#phase-box-1' },
        { id: 'prog-2', selector: '#phase-box-2' },
        { id: 'prog-3', selector: '#phase-box-3' },
        { id: 'prog-4', selector: '#phase-box-4' },
        { id: 'prog-5', selector: '#phase-box-5' }
      ];
      function updateProgress() {
        var scrollY = window.scrollY + 120;
        var activeIdx = 0;
        for (var i = 0; i < phases.length; i++) {
          var el = document.querySelector(phases[i].selector);
          if (el && el.getBoundingClientRect().top + window.scrollY <= scrollY) {
            activeIdx = i;
          }
        }
        for (var j = 0; j < phases.length; j++) {
          var btn = document.getElementById(phases[j].id);
          if (!btn) continue;
          btn.classList.remove('active', 'done');
          if (j < activeIdx) btn.classList.add('done');
          else if (j === activeIdx) btn.classList.add('active');
        }
      }
      window.addEventListener('scroll', updateProgress, { passive: true });
      updateProgress();
    });
  ")),

  # ── Main content ───────────────────────────────────────
  div(style = "max-width:1300px;margin:0 auto;padding:1rem 2rem 4rem",

    # ═══════════════════════════════════════════════════
    # PHASE 0 — Einführung
    # ═══════════════════════════════════════════════════
    div(id = "phase-box-0", class = "phase-box",
      div(class = "phase-header", style = "border-left:3px solid var(--ink2)",
        span(class = "phase-num", style = "border-color:var(--ink2);color:var(--ink2)", "Phase 0"),
        span(class = "phase-title", "Was ist ein Posterior Predictive Check?")
      ),
      div(class = "phase-body",
        div(class = "narr-box",
          tags$b("Das Grundprinzip in einem Satz:"),
          " Wenn dein Modell gut ist, sollten Daten, die es neu simuliert,
          wie deine echten Daten aussehen.",
          tags$br(), tags$br(),
          "Du hast ein brms-Modell gefittet. Der Posterior enthält nun tausende von
          Parameterkombinationen — quasi tausende \"Versionen\" deines Modells,
          jede etwas verschieden. Mit jeder Version kann man einen neuen Datensatz
          simulieren. Wenn diese simulierten Datensätze systematisch von deinen
          echten Daten abweichen, stimmt etwas mit dem Modell nicht.",
          tags$br(), tags$br(),
          tags$b("Wichtig:"), " Ein PPC prüft nicht, ob dein Modell \"wahr\" ist.
          Er prüft, ob dein Modell die ", tags$em("wesentlichen Eigenschaften"),
          " deiner Daten einfängt — Verteilung, Mittelwert, Varianz, Extremwerte."
        ),
        div(style = "display:grid;grid-template-columns:1fr 1fr;gap:.6rem;margin-bottom:.8rem",
          div(class = "compare-good",
            tags$b("✓ Gutes Modell: was du sehen willst"),
            "Die schwarze Kurve (echte Daten) liegt inmitten der blauen Linien
            (simulierte Daten). Keine systematischen Abweichungen."
          ),
          div(class = "compare-bad",
            tags$b("✗ Problematisches Modell: Warnsignale"),
            "Die schwarze Kurve liegt außerhalb oder hat eine komplett andere Form.
            Z.B. die echten Daten haben einen langen rechten Schwanz, das Modell
            simuliert symmetrische Daten."
          )
        ),

      )
    ),

    # ═══════════════════════════════════════════════════
    # PHASE 1 — Upload
    # ═══════════════════════════════════════════════════
    div(id = "phase-box-1", class = "phase-box",
      div(class = "phase-header",
        span(class = "phase-num", style = "border-color:var(--a2);color:var(--a2)", "Phase 1"),
        span(class = "phase-title", "Modell hochladen")
      ),
      div(class = "phase-body",

        # Mode selector
        div(style = "display:grid;grid-template-columns:1fr 1fr;gap:.6rem;margin-bottom:1rem",
          div(id = "mode-full-box",
            style = "border:2px solid var(--a2);padding:.7rem .9rem;cursor:pointer;background:var(--panel)",
            onclick = "selectMode('full')",
            div(style = "font-size:.85rem;color:var(--a2);font-weight:500;margin-bottom:.25rem",
                "● Vollständiges brms-Objekt"),
            div(style = "font-size:.72rem;color:var(--ink2);line-height:1.6",
                "Lade dein gespeichertes Modell (.rds) hoch. Die App berechnet
                 posterior_predict() selbst. Dateigröße: 50–300 MB. Braucht mehr RAM.")
          ),
          div(id = "mode-compact-box",
            style = "border:2px solid var(--grid);padding:.7rem .9rem;cursor:pointer",
            onclick = "selectMode('compact')",
            div(style = "font-size:.85rem;color:var(--ink2);font-weight:500;margin-bottom:.25rem",
                "○ Kompakt-Export (empfohlen)"),
            div(style = "font-size:.72rem;color:var(--ink2);line-height:1.6",
                "Exportiere nur yrep + y aus R (Skript unten herunterladen).
                 Dateigröße: 5–15 MB. Schnell, stabil, kein RAM-Problem.")
          )
        ),

        # Hidden mode selector input
        tags$input(type = "hidden", id = "upload_mode_val", value = "full"),
        tags$script(HTML("
          function selectMode(mode) {
            document.getElementById('upload_mode_val').value = mode;
            Shiny.setInputValue('upload_mode', mode, {priority: 'event'});
            var fullBox    = document.getElementById('mode-full-box');
            var compactBox = document.getElementById('mode-compact-box');
            if (mode === 'full') {
              fullBox.style.borderColor    = 'var(--a2)';
              fullBox.style.background     = 'var(--panel)';
              fullBox.querySelector('div').style.color = 'var(--a2)';
              compactBox.style.borderColor = 'var(--grid)';
              compactBox.style.background  = 'transparent';
              compactBox.querySelector('div').style.color = 'var(--ink2)';
            } else {
              compactBox.style.borderColor = 'var(--a2)';
              compactBox.style.background  = 'var(--panel)';
              compactBox.querySelector('div').style.color = 'var(--a2)';
              fullBox.style.borderColor    = 'var(--grid)';
              fullBox.style.background     = 'transparent';
              fullBox.querySelector('div').style.color = 'var(--ink2)';
            }
          }
        ")),

        # Compact mode: download script
        uiOutput("compact_script_download"),

        div(class = "narr-box",
          tags$b("Datenschutz:"),
          " Dateien werden nur für diese Sitzung geladen und nicht gespeichert."
        ),

        fileInput("rds_file",
          label       = uiOutput("upload_label"),
          accept      = ".rds",
          placeholder = "Datei auswählen...",
          buttonLabel = "Durchsuchen"
        ),
        uiOutput("upload_status")
      )
    ),

    # ═══════════════════════════════════════════════════
    # PHASE 2 — Modelldiagnose
    # ═══════════════════════════════════════════════════
    conditionalPanel("output.model_loaded",
      div(id = "phase-box-2", class = "phase-box",
        div(class = "phase-header", style = "border-left:3px solid var(--a6)",
          span(class = "phase-num", style = "border-color:var(--a6);color:var(--a6)", "Phase 2"),
          span(class = "phase-title", "Modelldiagnose — bevor wir PPCs schauen")
        ),
        div(class = "phase-body",
          div(class = "narr-box",
            tags$b("Warum zuerst Konvergenz prüfen?"),
            " Ein PPC ist nur aussagekräftig, wenn der MCMC-Sampler tatsächlich
            den Posterior gefunden hat. Wenn die Ketten nicht konvergiert sind,
            zeigen die PPCs Artefakte des Sampling-Prozesses — nicht Eigenschaften
            des Modells."
          ),
          uiOutput("model_diagnosis"),
          hr(class = "lab-hr"),
          uiOutput("convergence_detail")
        )
      ),

      # ═══════════════════════════════════════════════
      # PHASE 3 — Geführte PPC Tour
      # ═══════════════════════════════════════════════
      div(id = "phase-box-3", class = "phase-box",
        div(class = "phase-header", style = "border-left:3px solid var(--a5)",
          span(class = "phase-num", style = "border-color:var(--a5);color:var(--a5)", "Phase 3"),
          span(class = "phase-title", "Geführte PPC Tour")
        ),
        div(class = "phase-body",
          # ── Disclaimer ──
          div(style = paste0(
            "background:", LAB_COLORS$bg, ";border:1.5px solid ", LAB_COLORS$a4, ";",
            "padding:.7rem 1rem;margin-bottom:1rem;font-size:.78rem;",
            "color:", LAB_COLORS$ink2
          ),
            tags$b(style = paste0("color:", LAB_COLORS$a4), "⚠ Hinweis zu den automatischen Bewertungen"),
            tags$br(),
            "Die farbigen Einschätzungen (✓ Unauffällig / ⚠ Auffällig) sind ",
            tags$b("automatisch generierte Heuristiken"), " basierend auf einfachen
            statistischen Kennzahlen. Sie sind als erste Orientierung gedacht —
            kein Ersatz für eine inhaltliche Beurteilung durch dich.",
            tags$br(),
            "Insbesondere bei kleinen Stichproben, stark schiefen Verteilungen oder
            komplexen Modellstrukturen können die Bewertungen irreführend sein.
            Schaue immer selbst auf die Plots und beurteile, ob das Modell
            inhaltlich sinnvolle Vorhersagen macht."
          ),

          # Station 1 — Globale Verteilung
          div(style = "margin-bottom:1.4rem",
            div(class = "station-lbl", "Station 1 — Globale Verteilung"),
            div(class = "narr-box",
              tags$b("Was du siehst:"),
              " Die ", tags$b("helle Linie"), " = deine echten Daten (KDE) — im dunklen Theme weiß/hell,
              im hellen Theme dunkel.
              Die ", tags$b("blauen Linien"), " = 50 simulierte Datensätze aus deinem
              Posterior. Frage: Liegt die helle Linie innerhalb des blauen Bandes?",
              tags$br(), tags$br(),
              tags$b("Was wäre problematisch?"), " Helle Linie liegt dauerhaft
              außerhalb · Falscher Modalwert · Falscher Definitionsbereich
              (z.B. negative Werte bei einer Zählvariable)"
            ),
            div(class = "plot-wrap",
              plotOutput("ppc_dens", height = "380px")
            ),
            uiOutput("ppc_dens_eval")
          ),

          hr(class = "lab-hr"),

          # Station 2 — Kennzahlen
          div(style = "margin-bottom:1.4rem",
            div(class = "station-lbl", "Station 2 — Statistische Kennzahlen"),
            div(class = "narr-box",
              tags$b("Was du siehst:"),
              " Für jede Kennzahl (Mittelwert, SD, Minimum, Maximum) zeigt das
              Histogramm die Verteilung der simulierten Werte. Die ",
              tags$b("senkrechte Linie"), " ist dein beobachteter Wert.",
              tags$br(), tags$br(),
              tags$b("Bayesianischer p-Wert:"),
              " Anteil der simulierten Werte, die extremer sind als der beobachtete.
              0.5 = perfekt. < 0.05 oder > 0.95 = auffällig.
              Nicht wie frequentistisches p — kein Signifikanztest!"
            ),
            fluidRow(
              column(6, div(class = "plot-wrap", plotOutput("ppc_stat_mean", height = "280px"))),
              column(6, div(class = "plot-wrap", plotOutput("ppc_stat_sd",   height = "280px")))
            ),
            fluidRow(
              column(6, div(class = "plot-wrap", plotOutput("ppc_stat_min",  height = "280px"))),
              column(6, div(class = "plot-wrap", plotOutput("ppc_stat_max",  height = "280px")))
            ),
            uiOutput("ppc_stats_eval")
          ),

          hr(class = "lab-hr"),

          # Station 3 — Fehlerstruktur (family-dependent)
          div(style = "margin-bottom:1.4rem",
            div(class = "station-lbl", "Station 3 — Fehlerstruktur"),
            div(class = "narr-box",
              uiOutput("ppc_error_narr")
            ),
            div(class = "plot-wrap",
              plotOutput("ppc_error_plot", height = "380px")
            ),
            uiOutput("ppc_error_eval")
          ),

          hr(class = "lab-hr"),

          # Station 4 — PIT-ECDF (Kalibrierung)
          div(style = "margin-bottom:1.4rem",
            div(class = "station-lbl", "Station 4 — Kalibrierung: PIT-ECDF"),
            div(class = "narr-box",
              tags$b("Was ist der PIT-ECDF?"), tags$br(),
              "PIT steht für ", tags$em("Probability Integral Transform"),
              ". Für jede Beobachtung wird berechnet: Welcher Anteil der
              simulierten Werte liegt ", tags$em("unter"), " dem echten beobachteten Wert?
              Bei einem perfekt kalibrierten Modell ist dieser Anteil gleichmäßig
              zwischen 0 und 1 verteilt — die ECDF-Kurve läuft dann
              diagonal (45°-Linie).",
              tags$br(), tags$br(),
              tags$b("Die Unsicherheitshülle (ovales Band):"),
              " Das graue/blaue Band zeigt, wie viel Abweichung von der Diagonalen
              durch reinen Zufall entstehen würde — auch bei einem perfekt
              kalibrierten Modell. Die Kurve sollte ", tags$b("innerhalb"),
              " dieses Bandes verlaufen.",
              tags$br(), tags$br(),
              tags$b("Was ist problematisch?"),
              tags$br(),
              "• Kurve ", tags$b("S-förmig"), " (erst unter, dann über Diagonale):
              Verteilungsform falsch, z.B. zu schmale oder zu breite Posterior-Verteilung",
              tags$br(),
              "• Kurve ", tags$b("liegt dauerhaft über der Diagonale"),
              ": Modell überschätzt systematisch — echte Werte liegen häufig
              im unteren Bereich der simulierten Verteilung",
              tags$br(),
              "• Kurve ", tags$b("liegt dauerhaft unter der Diagonale"),
              ": Modell unterschätzt systematisch",
              tags$br(),
              "• Kurve ", tags$b("verlässt das Band"),
              ": Kalibrierungsproblem, das über Zufall hinausgeht"
            ),
            div(class = "plot-wrap",
              plotOutput("ppc_pit", height = "380px")
            ),
            uiOutput("ppc_pit_eval"),
            hr(class = "lab-hr"),

            # Station 4b — Vorhersageintervalle
            div(class = "station-lbl", style = "margin-top:.8rem",
                "Station 4b — Vorhersageintervalle (ergänzend)"),
            div(class = "narr-box",
              tags$b("Was du siehst:"),
              " Für jede Beobachtung: das 50%- und 90%-Vorhersageintervall.
              Die Punkte sind die echten Werte.",
              tags$br(), tags$br(),
              tags$b("Was du prüfst:"),
              " Liegen ~90% der echten Punkte im 90%-Band?
              Zu enge Bänder = Unsicherheit unterschätzt.
              Zu breite Bänder = Unsicherheit überschätzt."
            ),
            div(class = "plot-wrap",
              plotOutput("ppc_intervals", height = "320px")
            ),
            uiOutput("ppc_intervals_eval"),
            uiOutput("ppc_grouped_section")
          )
        )
      ),

      # ═══════════════════════════════════════════════
      # PHASE 4 — Gesamtbewertung
      # ═══════════════════════════════════════════════
      div(id = "phase-box-4", class = "phase-box",
        div(class = "phase-header", style = "border-left:3px solid var(--a3)",
          span(class = "phase-num", style = "border-color:var(--a3);color:var(--a3)", "Phase 4"),
          span(class = "phase-title", "Gesamtbewertung & nächste Schritte")
        ),
        div(class = "phase-body",
          uiOutput("overall_summary"),
          hr(class = "lab-hr"),
          uiOutput("next_steps")
        )
      ),

      # ═══════════════════════════════════════════════
      # PHASE 5 — Freie Exploration
      # ═══════════════════════════════════════════════
      div(id = "phase-box-5", class = "phase-box",
        div(class = "phase-header", style = "border-left:3px solid var(--a4)",
          span(class = "phase-num", style = "border-color:var(--a4);color:var(--a4)", "Phase 5"),
          span(class = "phase-title", "Freie Exploration"),
          span(style = "font-size:.6rem;color:var(--ink2);margin-left:auto",
               "Für Fortgeschrittene — alle bayesplot-Plots verfügbar")
        ),
        div(class = "phase-body",
          div(class = "narr-box",
            "Du hast die geführte Tour abgeschlossen. Hier kannst du alle
            verfügbaren PPC-Plots frei erkunden und eigene Gruppierungen wählen."
          ),
          fluidRow(
            column(4,
              selectInput("free_plot_type",
                label    = "Plot-Typ",
                choices  = list(
                  "Verteilung"    = c("ppc_dens_overlay", "ppc_ecdf_overlay", "ppc_hist"),
                  "Kennzahlen"    = c("ppc_stat", "ppc_stat_grouped"),
                  "Intervalle"    = c("ppc_intervals", "ppc_ribbon"),
                  "Streuung"      = c("ppc_scatter_avg", "ppc_error_hist"),
                  "Spezial"       = c("ppc_rootogram", "ppc_pit_ecdf")
                )
              ),
              uiOutput("free_group_ui"),
              uiOutput("free_stat_ui"),
              actionButton("free_go", "Plot erstellen",
                class = "lab-btn lab-btn-accent",
                style = "width:100%;margin-top:.5rem"
              )
            ),
            column(8,
              div(class = "plot-wrap",
                plotOutput("free_plot", height = "420px")
              ),
              uiOutput("free_plot_explanation")
            )
          )
        )
      )
    ) # end conditionalPanel
  ) # end main content div
)

# ═══════════════════════════════════════════════════════════
#  SERVER
# ═══════════════════════════════════════════════════════════

server <- function(input, output, session) {

  # Null coalescing helper
  `%||%` <- function(a, b) if (!is.null(a)) a else b

  # ── Reactive: upload mode ─────────────────────────────
  upload_mode <- reactive({
    if (is.null(input$upload_mode)) "full" else input$upload_mode
  })

  # ── Reactive: export R script ─────────────────────────
  output$compact_script_download <- renderUI({
    if (upload_mode() != "compact") return(NULL)
    div(class = "narr-box",
      style = paste0("border-color:", LAB_COLORS$a2),
      tags$b(style = paste0("color:", LAB_COLORS$a2), "R-Skript für Kompakt-Export:"),
      tags$br(),
      "Führe dieses Skript in R aus, dann lade die erzeugte Datei hoch:",
      tags$br(), tags$br(),
      tags$pre(
        style = paste0("background:", LAB_COLORS$bg, ";padding:.6rem;font-size:.72rem;",
                        "color:", LAB_COLORS$ink, ";line-height:1.6;overflow-x:auto"),
        paste0(
          "library(brms)\n",
          "# Dein Modell:  fit <- readRDS(\"mein_modell.rds\")\n\n",
          "# Kompakt-Export fuer PPC-App\n",
          "yrep <- posterior_predict(fit, ndraws = 500)\n",
          "y    <- fit$data[[as.character(fit$formula$resp)]]\n",
          "fam  <- family(fit)$family\n\n",
          "# Gruppen-Variable (optional, NULL wenn nicht vorhanden):\n",
          "dat  <- fit$data\n",
          "groups <- names(dat)[sapply(dat, function(x) is.factor(x)|is.character(x))]\n",
          "grp_data <- if(length(groups)>0) dat[groups] else NULL\n\n",
          "saveRDS(list(\n",
          "  yrep    = yrep,\n",
          "  y       = y,\n",
          "  family  = fam,\n",
          "  formula = as.character(fit$formula),\n",
          "  n_obs   = nrow(fit$data),\n",
          "  grp_data = grp_data\n",
          "), \"ppc_export.rds\")"
        )
      )
    )
  })

  # ── Reactive: upload label ─────────────────────────────
  output$upload_label <- renderUI({
    if (upload_mode() == "compact")
      "Kompakt-Export laden (ppc_export.rds)"
    else
      "Vollständiges brms-Modell (.rds)"
  })

  # ── Reactive: load model ──────────────────────────────
  fit_data <- reactive({
    req(input$rds_file)
    withProgress(message = "Datei wird verarbeitet...", {
      tryCatch({
        obj <- readRDS(input$rds_file$datapath)

        # Detect compact export vs full brms object
        if (is.list(obj) && !is.null(obj$yrep) && !is.null(obj$y)) {
          # Compact mode
          y    <- obj$y
          yrep <- obj$yrep
          fam  <- obj$family %||% "gaussian"
          grp_data <- obj$grp_data
          list(fit = NULL, y = y, yrep = yrep, ok = TRUE, error = NULL,
               compact = TRUE, family_str = fam,
               formula_str = obj$formula %||% "",
               n_obs = obj$n_obs %||% length(y),
               grp_data = grp_data)
        } else {
          # Full brms object
          fit  <- obj
          y    <- fit$data[[as.character(fit$formula$resp)]]
          yrep <- posterior_predict(fit, ndraws = 500)
          list(fit = fit, y = y, yrep = yrep, ok = TRUE, error = NULL,
               compact = FALSE)
        }
      }, error = function(e) {
        list(ok = FALSE, error = conditionMessage(e))
      })
    })
  })

  # Helper: get family string from fit_data
  get_fam <- function(fd) {
    if (isTRUE(fd$compact)) return(fd$family_str %||% "gaussian")
    family(fd$fit)$family
  }

  # Signal whether model is loaded (for conditionalPanel)
  output$model_loaded <- reactive({ !is.null(fit_data()) && fit_data()$ok })
  outputOptions(output, "model_loaded", suspendWhenHidden = FALSE)

  # ── Upload status ──────────────────────────────────────
  output$upload_status <- renderUI({
    req(input$rds_file)
    fd <- fit_data()
    if (!fd$ok) {
      div(class = "narr-box",
        style = sprintf("border-color:%s", LAB_COLORS$a1),
        tags$b(style = sprintf("color:%s", LAB_COLORS$a1), "✗ Fehler beim Laden:"),
        tags$br(),
        fd$error,
        tags$br(), tags$br(),
        "Stelle sicher, dass du ein mit ", tags$code("saveRDS()"), " gespeichertes
        brms-Modellobjekt hochlädst."
      )
    } else {
      s <- model_summary_text(fd$fit)
      div(
        style = sprintf("border-left:3px solid %s;padding:.5rem .8rem;
                         background:%s;font-size:.68rem;color:%s",
                        LAB_COLORS$a3, LAB_COLORS$panel, LAB_COLORS$ink2),
        tags$b(style = sprintf("color:%s", LAB_COLORS$a3), "✓ Modell erfolgreich geladen"),
        tags$br(),
        sprintf("Familie: %s · %d Beobachtungen · %d Prädiktoren",
                s$fam, s$n_obs, s$n_pred)
      )
    }
  })

  # ── Model diagnosis ────────────────────────────────────
  output$model_diagnosis <- renderUI({
    req(fit_data()$ok)
    s <- model_summary_text(fit_data()$fit)

    div(
      # Model info
      div(style = sprintf("background:%s;padding:.75rem 1rem;
                           font-size:.68rem;margin-bottom:.75rem", LAB_COLORS$panel),
        div(style = "display:grid;grid-template-columns:1fr 1fr 1fr;gap:.5rem",
          div(tags$span(style = sprintf("color:%s;font-size:.58rem;display:block", LAB_COLORS$ink2),
                        "OUTCOME-VARIABLE"),
              tags$b(as.character(fit_data()$fit$formula$resp))),
          div(tags$span(style = sprintf("color:%s;font-size:.58rem;display:block", LAB_COLORS$ink2),
                        "FAMILIE"),
              tags$b(s$fam)),
          div(tags$span(style = sprintf("color:%s;font-size:.58rem;display:block", LAB_COLORS$ink2),
                        "BEOBACHTUNGEN"),
              tags$b(s$n_obs)),
          div(tags$span(style = sprintf("color:%s;font-size:.58rem;display:block", LAB_COLORS$ink2),
                        "KETTEN"),
              tags$b(sprintf("%d × %d Iterationen", s$chains, s$iters - s$warmup))),
          div(tags$span(style = sprintf("color:%s;font-size:.58rem;display:block", LAB_COLORS$ink2),
                        "R̂ MAX"),
              tags$b(style = sprintf("color:%s", if (s$rhat_ok) LAB_COLORS$a3 else LAB_COLORS$a1),
                     sprintf("%.3f", s$rhat_max))),
          div(tags$span(style = sprintf("color:%s;font-size:.58rem;display:block", LAB_COLORS$ink2),
                        "DIVERGENZEN"),
              tags$b(style = sprintf("color:%s", if (s$divs_ok) LAB_COLORS$a3 else LAB_COLORS$a1),
                     s$divs))
        )
      ),
      # Convergence badges
      div(style = "margin-bottom:.5rem",
        convergence_badge(s$rhat_ok,
          if (s$rhat_ok) sprintf("R̂ < 1.01 — Konvergenz OK")
          else sprintf("R̂ = %.3f — Konvergenzproblem!", s$rhat_max)),
        convergence_badge(s$divs_ok,
          if (s$divs_ok) "Keine Divergenzen"
          else sprintf("%d Divergenzen — Vorsicht!", s$divs))
      )
    )
  })

  output$convergence_detail <- renderUI({
    req(fit_data()$ok)
    s <- model_summary_text(fit_data()$fit)
    if (s$rhat_ok && s$divs_ok) {
      div(class = "narr-box", style = sprintf("border-color:%s", LAB_COLORS$a3),
        tags$b(style = sprintf("color:%s", LAB_COLORS$a3), "✓ Konvergenz sieht gut aus."),
        " R̂-Werte unter 1.01 und keine Divergenzen bedeuten: der Sampler hat
        den Posterior zuverlässig erkundet. Der PPC ist aussagekräftig."
      )
    } else {
      problems <- character(0)
      solutions <- character(0)
      if (!s$rhat_ok) {
        problems <- c(problems, sprintf("R̂ = %.3f (Grenze: 1.01) — Ketten haben nicht konvergiert", s$rhat_max))
        solutions <- c(solutions, "Mehr Iterationen (iter = 4000), längeres Warmup")
      }
      if (!s$divs_ok) {
        problems <- c(problems, sprintf("%d Divergenzen — Sampler hatte numerische Probleme", s$divs))
        solutions <- c(solutions, "adapt_delta erhöhen (z.B. control = list(adapt_delta = 0.99))")
        solutions <- c(solutions, "Priors überprüfen — möglicherweise zu flach")
      }
      div(
        div(class = "narr-box", style = sprintf("border-color:%s", LAB_COLORS$a1),
          tags$b(style = sprintf("color:%s", LAB_COLORS$a1), "⚠ Konvergenzprobleme erkannt."),
          " Der PPC kann trotzdem informatisch sein, aber Ergebnisse mit Vorsicht
          interpretieren.", tags$br(), tags$br(),
          tags$b("Probleme:"), tags$br(),
          tags$ul(lapply(problems, tags$li)),
          tags$b("Lösungsansätze in R:"), tags$br(),
          tags$ul(lapply(solutions, tags$li))
        )
      )
    }
  })

  # ── PPC Plots ─────────────────────────────────────────

  output$ppc_dens <- renderPlot({
    req(fit_data()$ok)
    bayesplot::ppc_dens_overlay(fit_data()$y, fit_data()$yrep[1:50,])
  }, bg = LAB_COLORS$panel, res = 110)

  output$ppc_stat_mean <- renderPlot({
    req(fit_data()$ok)
    bayesplot::ppc_stat(fit_data()$y, fit_data()$yrep, stat = "mean") +
      ggtitle("Mittelwert")
  }, bg = LAB_COLORS$panel, res = 110)

  output$ppc_stat_sd <- renderPlot({
    req(fit_data()$ok)
    bayesplot::ppc_stat(fit_data()$y, fit_data()$yrep, stat = "sd") +
      ggtitle("Standardabweichung")
  }, bg = LAB_COLORS$panel, res = 110)

  output$ppc_stat_min <- renderPlot({
    req(fit_data()$ok)
    bayesplot::ppc_stat(fit_data()$y, fit_data()$yrep, stat = "min") +
      ggtitle("Minimum")
  }, bg = LAB_COLORS$panel, res = 110)

  output$ppc_stat_max <- renderPlot({
    req(fit_data()$ok)
    bayesplot::ppc_stat(fit_data()$y, fit_data()$yrep, stat = "max") +
      ggtitle("Maximum")
  }, bg = LAB_COLORS$panel, res = 110)

  # Family-dependent error plot
  output$ppc_error_narr <- renderUI({
    req(fit_data()$ok)
    fam <- get_fam(fit_data())
    # Detect random effects
    has_re <- if (!isTRUE(fit_data()$compact) && !is.null(fit_data()$fit))
               length(lme4::findbars(fit_data()$fit$formula$formula)) > 0
             else FALSE

    re_note <- if (has_re) {
      tagList(tags$br(), tags$br(),
        tags$b("Random Effects erkannt:"),
        " posterior_predict() berücksichtigt die RE-Struktur automatisch.
        Der gruppierte PPC in Station 4b ist besonders informativ um zu prüfen,
        ob das Modell alle Gruppen gut reproduziert.")
    } else NULL

    if (fam %in% c("poisson", "negbinomial", "zero_inflated_poisson",
                   "zero_inflated_negbinomial", "hurdle_poisson")) {
      tagList(
        tags$b("Rootogramm (Zähldaten)"),
        " — Vergleicht beobachtete und erwartete Häufigkeiten je Zählwert.
        Die hängenden Balken sollten nahe bei 0 sein.",
        tags$br(), tags$br(),
        if (grepl("zero_inflated|hurdle", fam))
          tagList(tags$b("Zero-Inflation/Hurdle-Modell:"),
            " Prüfe besonders den Balken bei 0 — er sollte gut sitzen.")
        else
          tagList(tags$b("Poisson-Typisch:"),
            " Zero-Inflation zeigt sich als stark positiver 0-Balken
            (mehr Nullen beobachtet als erwartet)."),
        re_note
      )
    } else if (fam %in% c("bernoulli", "binomial")) {
      tagList(
        tags$b("Calibration Plot (binäre/binomiale Daten)"),
        " — Wie gut sind die vorhergesagten Wahrscheinlichkeiten kalibriert?
        Bei perfekter Kalibrierung liegen alle Punkte auf der Diagonalen.",
        re_note
      )
    } else if (fam %in% c("beta")) {
      tagList(
        tags$b("Beta-Verteilung (0–1 Werte):"),
        " Dichte auf Originalskala (0 bis 1). Prüfe ob Häufungen nahe 0 oder 1
        (Grenzwertprobleme) gut reproduziert werden.",
        re_note
      )
    } else if (fam %in% c("Gamma", "lognormal", "weibull")) {
      tagList(
        tags$b("Rechts-schiefe Verteilung — Log-Skala:"),
        " Die Dichte wird auf log(y+1)-Skala gezeigt. Auf dieser Skala sollte
        die Verteilung eher symmetrisch sein. Abweichungen deuten auf falsche
        Schiefe oder fehlende Kovariaten hin.",
        re_note
      )
    } else if (fam %in% c("cumulative", "cratio", "sratio", "acat")) {
      tagList(
        tags$b("Ordinale Daten — Balkendiagramm:"),
        " Vergleicht beobachtete und simulierte Häufigkeiten je Antwortkategorie.
        Alle Kategorien sollten gut getroffen sein.",
        re_note
      )
    } else {
      tagList(
        tags$b("Residualverteilung"),
        " — Symmetrisch und zentriert bei 0? Systematische Muster deuten auf
        falsche Linkfunktion oder fehlende Prädiktoren hin.",
        re_note
      )
    }
  })

  output$ppc_error_plot <- renderPlot({
    req(fit_data()$ok)
    fam <- get_fam(fit_data())
    if (fam %in% c("poisson", "negbinomial", "zero_inflated_poisson", "hurdle_poisson")) {
      bayesplot::ppc_rootogram(fit_data()$y, fit_data()$yrep)
    } else if (fam %in% c("bernoulli", "binomial")) {
      bayesplot::ppc_error_binned(fit_data()$y, fit_data()$yrep[1:50,])
    } else if (fam %in% c("beta", "Gamma", "lognormal")) {
      # For positive/bounded: overlay on log scale is more informative
      bayesplot::ppc_dens_overlay(log1p(fit_data()$y), log1p(fit_data()$yrep[1:50,])) +
        ggplot2::xlab("log(y + 1)") + ggplot2::ggtitle("Dichte auf Log-Skala")
    } else if (fam %in% c("cumulative", "cratio", "sratio", "acat")) {
      # Ordinal: bar chart comparison
      bayesplot::ppc_bars(fit_data()$y, fit_data()$yrep)
    } else {
      bayesplot::ppc_error_hist(fit_data()$y, fit_data()$yrep[1:25,])
    }
  }, bg = LAB_COLORS$panel, res = 110)

  # ── PIT-ECDF ──────────────────────────────────────────
  output$ppc_pit <- renderPlot({
    req(fit_data()$ok)
    tryCatch(
      bayesplot::ppc_pit_ecdf(fit_data()$y, fit_data()$yrep, prob = 0.99),
      error = function(e) {
        ggplot() +
          annotate("text", x=.5, y=.5,
                   label=paste("PIT nicht verfügbar:", conditionMessage(e)),
                   color=LAB_COLORS$a1, size=4, family="mono") +
          theme_void() +
          theme(plot.background=element_rect(fill=LAB_COLORS$panel, color=NA))
      }
    )
  }, bg = LAB_COLORS$panel, res = 110)

  output$ppc_pit_eval <- renderUI({
    req(fit_data()$ok)
    y    <- fit_data()$y
    yrep <- fit_data()$yrep
    pit  <- tryCatch(
      sapply(seq_len(length(y)), function(i) mean(yrep[,i] <= y[i])),
      error = function(e) NULL
    )
    if (is.null(pit)) return(div(class="narr-box", "PIT-Bewertung nicht verfügbar."))

    ks  <- tryCatch(ks.test(pit, "punif")$statistic, error=function(e) NA)
    ok  <- !is.na(ks) && ks < 0.06
    bd  <- !is.na(ks) && ks >= 0.06 && ks < 0.12
    col <- if(ok) LAB_COLORS$a3 else if(bd) LAB_COLORS$a4 else ACCENT
    lbl <- if(ok) "✓ PIT unauffällig — Kalibrierung gut"
           else if(bd) "~ PIT grenzwertig — leichte Kalibrierungsprobleme"
           else "⚠ PIT auffällig — Kalibrierungsprobleme erkennbar"

    div(class="narr-box", style=paste0("border-color:",col),
      tags$b(style=paste0("color:",col), lbl),
      if(!is.na(ks)) tagList(tags$br(),
        sprintf("KS-Statistik: %.3f  (< 0.06 = gut, 0.06–0.12 = grenzwertig, > 0.12 = auffällig)", ks)),
      tags$br(), tags$br(),
      tags$b("Zur Erinnerung: "), "Kurve innerhalb des Bandes & diagonal = gut.
      S-Form = falsche Verteilungsbreite. Dauerhafte Abweichung = systematischer Bias.",
      tags$br(),
      div(style=paste0("font-size:.7rem;color:",LAB_COLORS$ink2,
                       ";border-top:1px solid ",LAB_COLORS$grid,
                       ";padding-top:.35rem;margin-top:.35rem"),
        tags$b("⚠ Hinweis: "), "KS-Statistik ist eine Heuristik — immer auch den Plot selbst beurteilen."
      )
    )
  })

  output$ppc_intervals <- renderPlot({
    req(fit_data()$ok)
    n <- length(fit_data()$y)
    idx <- if (n > 80) sample(n, 80) else seq_len(n)
    bayesplot::ppc_intervals(fit_data()$y[idx], fit_data()$yrep[, idx],
                             prob = 0.5, prob_outer = 0.9)
  }, bg = LAB_COLORS$panel)

  # ── Evaluations ────────────────────────────────────────

  output$ppc_dens_eval <- renderUI({
    req(fit_data()$ok)
    # Simple heuristic: compare KDE peaks
    y    <- fit_data()$y
    yrep <- fit_data()$yrep
    # Check if observed mode is within range of simulated modes
    sim_means <- rowMeans(yrep)
    obs_mean  <- mean(y)
    z_mean    <- (obs_mean - mean(sim_means)) / sd(sim_means)
    ok        <- abs(z_mean) < 2

    div(style = "margin-top:.5rem",
      div(class = "narr-box",
        style = sprintf("border-color:%s", if (ok) LAB_COLORS$a3 else ACCENT),
        tags$b(style = sprintf("color:%s", if (ok) LAB_COLORS$a3 else ACCENT),
               if (ok) "✓ Globale Verteilung unauffällig" else "⚠ Auffälligkeit in globaler Verteilung"),
        tags$br(),
        if (ok) {
          "Der Mittelwert der simulierten Daten liegt nahe am beobachteten Mittelwert.
          Die globale Form scheint gut getroffen."
        } else {
          sprintf("Der beobachtete Mittelwert (%.2f) weicht systematisch von den
          simulierten Mittelwerten (%.2f ± %.2f) ab. Überprüfe die Modellspezifikation.",
          obs_mean, mean(sim_means), sd(sim_means))
        }
      )
    )
  })

  output$ppc_stats_eval <- renderUI({
    req(fit_data()$ok)
    y    <- fit_data()$y
    yrep <- fit_data()$yrep

    stats <- list(
      list(name = "Mittelwert", fn = mean,  label = "des Mittelwerts"),
      list(name = "SD",         fn = sd,    label = "der Standardabweichung"),
      list(name = "Minimum",    fn = min,   label = "des Minimums"),
      list(name = "Maximum",    fn = max,   label = "des Maximums")
    )

    evals <- lapply(stats, function(s) {
      p  <- bayes_pval(yrep, y, s$fn)
      ev <- eval_pval(p, s$label)
      div(class = "summary-row",
        span(s$name),
        span(sprintf("p = %.2f", p)),
        span(style = sprintf("color:%s;font-size:.65rem", ev$color), ev$rating)
      )
    })

    div(style = "margin-top:.5rem",
      div(class = "narr-box",
        tags$b("Bayesianische p-Werte für Kennzahlen:"),
        tags$br(),
        do.call(div, evals),
        tags$br(),
        "Erinnerung: p ≈ 0.5 ist ideal. p < 0.05 oder p > 0.95 ist auffällig."
      )
    )
  })

  output$ppc_intervals_eval <- renderUI({
    req(fit_data()$ok)
    y    <- fit_data()$y
    yrep <- fit_data()$yrep
    # Coverage check: what % of obs fall within 90% interval?
    lo   <- apply(yrep, 2, function(x) quantile(x, 0.05))
    hi   <- apply(yrep, 2, function(x) quantile(x, 0.95))
    cov  <- mean(y >= lo & y <= hi)
    ok   <- abs(cov - 0.9) < 0.08

    div(style = "margin-top:.5rem",
      div(class = "narr-box",
        style = sprintf("border-color:%s", if (ok) LAB_COLORS$a3 else ACCENT),
        tags$b(sprintf("90%%-Intervall Abdeckung: %.0f%% der Beobachtungen", cov * 100)),
        tags$br(),
        if (ok) {
          tags$span(style = sprintf("color:%s", LAB_COLORS$a3),
            "✓ Nahe an den erwarteten 90%. Das Modell kalibriert Unsicherheit gut.")
        } else if (cov < 0.82) {
          tags$span(style = sprintf("color:%s", ACCENT),
            "⚠ Zu wenige Beobachtungen im 90%-Band — das Modell unterschätzt
            die Unsicherheit (zu enge Intervalle).")
        } else {
          tags$span(style = sprintf("color:%s", LAB_COLORS$a4),
            "~ Etwas zu viele Beobachtungen im Band — das Modell überschätzt
            möglicherweise die Unsicherheit.")
        }
      )
    )
  })

  output$ppc_grouped_section <- renderUI({
    req(fit_data()$ok)
    # Check if there are factor/group variables
    dat    <- fit_data()$fit$data
    groups <- names(dat)[sapply(dat, function(x) is.factor(x) | is.character(x))]
    if (length(groups) == 0) return(NULL)

    div(style = "margin-top:1rem",
      div(class = "station-lbl", "Station 4b — Gruppierter PPC"),
      div(class = "narr-box",
        tags$b("Gruppenvergleich:"),
        " Dein Datensatz enthält kategoriale Variablen. Ein gruppierter PPC
        prüft, ob dein Modell die Gruppen gleich gut reproduziert —
        oder ob es für manche Gruppen systematisch schlechter ist."
      ),
      selectInput("group_var", "Gruppierungsvariable:", choices = groups),
      div(class = "plot-wrap",
        plotOutput("ppc_grouped", height = "380px")
      )
    )
  })

  output$ppc_grouped <- renderPlot({
    req(fit_data()$ok, input$group_var)
    group <- fit_data()$fit$data[[input$group_var]]
    bayesplot::ppc_stat_grouped(
      fit_data()$y, fit_data()$yrep,
      group = group, stat = "mean"
    )
  }, bg = LAB_COLORS$panel)

  # ── Overall summary ────────────────────────────────────

  output$overall_summary <- renderUI({
    req(fit_data()$ok)
    y    <- fit_data()$y
    yrep <- fit_data()$yrep

    p_mean <- bayes_pval(yrep, y, mean)
    p_sd   <- bayes_pval(yrep, y, sd)
    p_min  <- bayes_pval(yrep, y, min)
    p_max  <- bayes_pval(yrep, y, max)

    lo   <- apply(yrep, 2, function(x) quantile(x, 0.05))
    hi   <- apply(yrep, 2, function(x) quantile(x, 0.95))
    cov  <- mean(y >= lo & y <= hi)

    n_ok  <- sum(c(p_mean, p_sd, p_min, p_max) > 0.05 & c(p_mean, p_sd, p_min, p_max) < 0.95)
    n_warn<- sum(c(p_mean, p_sd, p_min, p_max) <= 0.05 | c(p_mean, p_sd, p_min, p_max) >= 0.95)

    overall_col <- if (n_warn == 0) LAB_COLORS$a3 else if (n_warn <= 1) LAB_COLORS$a4 else ACCENT
    overall_lbl <- if (n_warn == 0) "✓ Modell besteht den PPC gut"
                   else if (n_warn == 1) "~ Ein Aspekt ist auffällig"
                   else sprintf("⚠ %d Aspekte auffällig", n_warn)

    div(
      div(class = "narr-box",
        style = sprintf("border-color:%s;font-size:.72rem", overall_col),
        tags$b(style = sprintf("color:%s", overall_col), overall_lbl),
        tags$br(), tags$br(),
        div(class = "summary-row", span("Mittelwert"), span(""), span(style = sprintf("color:%s", if(p_mean>0.05&p_mean<0.95) LAB_COLORS$a3 else ACCENT), if(p_mean>0.05&p_mean<0.95) "✓ OK" else sprintf("⚠ p=%.2f",p_mean))),
        div(class = "summary-row", span("Standardabweichung"), span(""), span(style = sprintf("color:%s", if(p_sd>0.05&p_sd<0.95) LAB_COLORS$a3 else ACCENT), if(p_sd>0.05&p_sd<0.95) "✓ OK" else sprintf("⚠ p=%.2f",p_sd))),
        div(class = "summary-row", span("Minimum / Maximum"), span(""), span(style = sprintf("color:%s", if(p_min>0.05&p_min<0.95&p_max>0.05&p_max<0.95) LAB_COLORS$a3 else ACCENT), if(p_min>0.05&p_min<0.95&p_max>0.05&p_max<0.95) "✓ OK" else "⚠ Auffällig")),
        div(class = "summary-row", span("90%-Intervall Abdeckung"), span(sprintf("%.0f%%", cov*100)), span(style = sprintf("color:%s", if(abs(cov-0.9)<0.08) LAB_COLORS$a3 else ACCENT), if(abs(cov-0.9)<0.08) "✓ OK" else "⚠ Kalibrierung"))
      )
    )
  })

  output$next_steps <- renderUI({
    req(fit_data()$ok)
    y    <- fit_data()$y
    yrep <- fit_data()$yrep
    fam  <- family(fit_data()$fit)$family

    p_sd  <- bayes_pval(yrep, y, sd)
    p_max <- bayes_pval(yrep, y, max)
    lo    <- apply(yrep, 2, function(x) quantile(x, 0.05))
    hi    <- apply(yrep, 2, function(x) quantile(x, 0.95))
    cov   <- mean(y >= lo & y <= hi)

    suggestions <- list()

    if (p_sd < 0.05) {
      suggestions <- c(suggestions, list(
        list(title = "SD unterschätzt — Modell zu eng",
             text  = "Das Modell simuliert Daten mit zu wenig Streuung.
             Mögliche Ursachen: fehlende Prädiktoren, heteroskedastische Fehler.
             Versuch: Student-t statt Gaussian, oder ein distributional model mit
             sigma ~ Prädiktoren.")
      ))
    }
    if (p_max > 0.95 && fam == "gaussian") {
      suggestions <- c(suggestions, list(
        list(title = "Extremwerte nicht gut abgedeckt",
             text  = "Das Modell produziert selten so extreme Werte wie in den echten
             Daten. Hinweis auf heavy tails. Versuch: family = student statt gaussian.")
      ))
    }
    if (cov < 0.82) {
      suggestions <- c(suggestions, list(
        list(title = "Intervalle zu eng — Unsicherheit unterschätzt",
             text  = "Nur weniger als 82% der Daten liegen im 90%-Band.
             Mögliche Ursachen: fehlende Varianz-Komponenten, falsche Familie,
             oder Ausreißer. Überprüfe den Residualplot.")
      ))
    }

    if (length(suggestions) == 0) {
      div(class = "narr-box",
        style = sprintf("border-color:%s", LAB_COLORS$a3),
        tags$b(style = sprintf("color:%s", LAB_COLORS$a3),
               "✓ Keine spezifischen Handlungsempfehlungen."),
        tags$br(),
        "Dein Modell besteht alle geprüften Aspekte des PPC gut.
        Das bedeutet nicht, dass das Modell perfekt ist — aber es gibt
        keine offensichtlichen Spezifikationsfehler."
      )
    } else {
      div(
        div(style = sprintf("color:%s;font-size:.68rem;margin-bottom:.5rem", LAB_COLORS$ink2),
            "Basierend auf den Ergebnissen folgende Überlegungen:"),
        lapply(suggestions, function(s) {
          div(class = "narr-box",
            style = sprintf("border-color:%s;margin-bottom:.4rem", ACCENT),
            tags$b(s$title), tags$br(), s$text
          )
        })
      )
    }
  })

  # ── Free exploration ────────────────────────────────────

  output$free_group_ui <- renderUI({
    req(fit_data()$ok)
    plt <- input$free_plot_type
    if (grepl("grouped", plt)) {
      dat    <- fit_data()$fit$data
      groups <- names(dat)[sapply(dat, function(x) is.factor(x) | is.character(x))]
      if (length(groups) > 0)
        selectInput("free_group", "Gruppe:", choices = groups)
    }
  })

  output$free_stat_ui <- renderUI({
    req(fit_data()$ok)
    if (input$free_plot_type == "ppc_stat" ||
        input$free_plot_type == "ppc_stat_grouped") {
      selectInput("free_stat", "Statistik:",
        choices = c("mean", "sd", "median", "min", "max", "var"))
    }
  })

  # Plot explanations for free exploration
  plot_explanations <- list(
    ppc_dens_overlay = "KDE-Dichte-Vergleich: Schwarze Linie = echte Daten, blaue Linien = simulierte Datensätze. Ideal: helle Linie (echte Daten) mitten im blauen Band.",
    ppc_ecdf_overlay = "Empirische CDF. Robuster als KDE für diskrete oder schiefe Daten. Systematische Verschiebungen gut erkennbar.",
    ppc_hist = "Histogramme der simulierten Datensätze. Weniger glatt als KDE, dafür genauer bei diskreten Daten.",
    ppc_stat = "Verteilung einer Test-Statistik über simulierte Datensätze. Senkrechte Linie = beobachteter Wert. Linie sollte mittig liegen.",
    ppc_stat_grouped = "Wie ppc_stat, aber separat für jede Gruppe. Zeigt ob bestimmte Gruppen schlechter reproduziert werden.",
    ppc_intervals = "90%-Vorhersageintervalle für jede Beobachtung. ~90% der echten Punkte sollten im Band liegen.",
    ppc_ribbon = "Wie ppc_intervals, aber als Band. Gut für zeitliche oder geordnete Daten.",
    ppc_scatter_avg = "Streudiagramm: beobachtete vs. durchschnittliche vorhergesagte Werte. Ideal: Punkte auf der Diagonalen.",
    ppc_error_hist = "Histogramm der Residuen. Sollte symmetrisch um 0 sein.",
    ppc_rootogram = "Für Zähldaten: beobachtete vs. erwartete Häufigkeiten je Zählwert. Balken nahe 0 = gut.",
    ppc_pit_ecdf = "Probability Integral Transform. Für gut kalibrierte Modelle: annähernd gerade Diagonale."
  )

  output$free_plot_explanation <- renderUI({
    req(input$free_plot_type)
    expl <- plot_explanations[[input$free_plot_type]]
    if (!is.null(expl)) {
      div(class = "narr-box", style = "margin-top:.5rem", expl)
    }
  })

  observeEvent(input$free_go, {
    output$free_plot <- renderPlot({
      req(fit_data()$ok)
      y    <- fit_data()$y
      yrep <- fit_data()$yrep
      plt  <- input$free_plot_type
      stat <- if (!is.null(input$free_stat)) input$free_stat else "mean"

      tryCatch({
        if (plt == "ppc_dens_overlay") {
          bayesplot::ppc_dens_overlay(y, yrep[1:50,])
        } else if (plt == "ppc_ecdf_overlay") {
          bayesplot::ppc_ecdf_overlay(y, yrep[1:50,])
        } else if (plt == "ppc_hist") {
          bayesplot::ppc_hist(y, yrep[1:8,])
        } else if (plt == "ppc_stat") {
          bayesplot::ppc_stat(y, yrep, stat = stat)
        } else if (plt == "ppc_stat_grouped") {
          req(input$free_group)
          grp <- fit_data()$fit$data[[input$free_group]]
          bayesplot::ppc_stat_grouped(y, yrep, group = grp, stat = stat)
        } else if (plt == "ppc_intervals") {
          n   <- length(y)
          idx <- if (n > 80) sample(n, 80) else seq_len(n)
          bayesplot::ppc_intervals(y[idx], yrep[, idx])
        } else if (plt == "ppc_ribbon") {
          bayesplot::ppc_ribbon(y, yrep[1:50,])
        } else if (plt == "ppc_scatter_avg") {
          bayesplot::ppc_scatter_avg(y, yrep)
        } else if (plt == "ppc_error_hist") {
          bayesplot::ppc_error_hist(y, yrep[1:25,])
        } else if (plt == "ppc_rootogram") {
          bayesplot::ppc_rootogram(y, yrep)
        } else if (plt == "ppc_pit_ecdf") {
          bayesplot::ppc_pit_ecdf(y, yrep)
        }
      }, error = function(e) {
        ggplot() +
          annotate("text", x = 0.5, y = 0.5, label = paste("Fehler:", conditionMessage(e)),
                   color = LAB_COLORS$a1, size = 4, family = "mono") +
          theme_void() +
          theme(plot.background = element_rect(fill = LAB_COLORS$panel, color = NA))
      })
    }, bg = LAB_COLORS$panel)
  })
}

# ── Run ──────────────────────────────────────────────────
shinyApp(ui = ui, server = server)
