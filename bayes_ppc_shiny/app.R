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

# Allow uploads up to 100 MB (full brms objects > 100 MB should use compact export)
options(shiny.maxRequestSize = 100 * 1024^2)

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

# ── Translations ─────────────────────────────────────────────
i18n <- list(
  de = list(
    tb_sub    = "Modellprüfung · bayesplot · brms · Geführtes Tutorial",
    tb_auth   = "© Dr. Rainer Düsing · Interactive Tools by Claude",
    btn_back  = "\u2190 Zum Lab",
    btn_model = "\u2b21 Model Builder",
    btn_lang  = '<svg width="18" height="12" viewBox="0 0 18 12" style="vertical-align:middle;margin-right:4px"><rect width="18" height="12" fill="#012169"/><polygon points="0,0 2,0 18,10 18,12 16,12 0,2" fill="#fff"/><polygon points="0,2 0,0 2,0" fill="#fff"/><polygon points="16,12 18,12 18,10" fill="#fff"/><polygon points="0,10 0,12 2,12 18,2 18,0 16,0" fill="#fff"/><polygon points="0,12 2,12 0,10" fill="#fff"/><polygon points="16,0 18,0 18,2" fill="#fff"/><polygon points="0,0 1,0 18,11 18,12 17,12 0,1" fill="#C8102E"/><polygon points="17,0 18,0 18,1" fill="#C8102E"/><polygon points="0,11 0,12 1,12" fill="#C8102E"/><polygon points="0,10 0,12 1,12 18,2 18,0 17,0" fill="#C8102E"/><rect x="7.5" width="3" height="12" fill="#fff"/><rect y="4.5" width="18" height="3" fill="#fff"/><rect x="8" width="2" height="12" fill="#C8102E"/><rect y="5" width="18" height="2" fill="#C8102E"/></svg> EN',
    prog_label = "Fortschritt:",
    prog_0 = "0 \u00b7 Einf\u00fchrung", prog_1 = "1 \u00b7 Upload",
    prog_2 = "2 \u00b7 Diagnose",      prog_3 = "3 \u00b7 PPC Tour",
    prog_4 = "4 \u00b7 Bewertung",     prog_5 = "5 \u00b7 Exploration",
    phase0_title = "Was ist ein Posterior Predictive Check?",
    phase1_title = "Modell hochladen",
    phase2_title = "Modelldiagnose \u2014 bevor wir PPCs schauen",
    phase3_title = "Gef\u00fchrte PPC Tour",
    phase4_title = "Gesamtbewertung & n\u00e4chste Schritte",
    phase5_title = "Freie Exploration",
    phase5_sub   = "F\u00fcr Fortgeschrittene \u2014 alle bayesplot-Plots verf\u00fcgbar",
    # Phase 0
    p0_princ_b = "Das Grundprinzip in einem Satz:",
    p0_princ   = " Wenn dein Modell gut ist, sollten Daten, die es neu simuliert, wie deine echten Daten aussehen.",
    p0_text    = "Du hast ein brms-Modell gefittet. Der Posterior enth\u00e4lt nun tausende von Parameterkombinationen \u2014 quasi tausende \u201eVersionen\u201c deines Modells, jede etwas verschieden. Mit jeder Version kann man einen neuen Datensatz simulieren. Wenn diese simulierten Datens\u00e4tze systematisch von deinen echten Daten abweichen, stimmt etwas mit dem Modell nicht.",
    p0_cav_b   = "Wichtig:",
    p0_cav     = " Ein PPC pr\u00fcft nicht, ob dein Modell \u201ewahr\u201c ist. Er pr\u00fcft, ob dein Modell die wesentlichen Eigenschaften deiner Daten einf\u00e4ngt \u2014 Verteilung, Mittelwert, Varianz, Extremwerte.",
    p0_good_b  = "\u2713 Gutes Modell: was du sehen willst",
    p0_good    = "Die schwarze Kurve (echte Daten) liegt inmitten der blauen Linien (simulierte Daten). Keine systematischen Abweichungen.",
    p0_bad_b   = "\u2717 Problematisches Modell: Warnsignale",
    p0_bad     = "Die schwarze Kurve liegt au\u00dferhalb oder hat eine komplett andere Form. Z.B. die echten Daten haben einen langen rechten Schwanz, das Modell simuliert symmetrische Daten.",
    # Phase 1 modes
    mode_c_lbl  = "\u25cf Kompakt-Export (empfohlen)",
    mode_c_desc = "Exportiere nur yrep + y aus R (Skript unten herunterladen). Kleine Datei, schnell, stabil \u2014 kein RAM-Problem.",
    mode_f_lbl  = "\u25cb Vollst\u00e4ndiges brms-Objekt",
    mode_f_desc = "Lade dein gespeichertes Modell (.rds) hoch. Die App berechnet posterior_predict() selbst.",
    mode_f_warn = "\u26a0 Bei gro\u00dfen Modellen kann es zu Server-Disconnects kommen. Nur f\u00fcr kleinere Modelle geeignet.",
    privacy     = "<b>Datenschutz:</b> Dateien werden nur f\u00fcr diese Sitzung geladen und nicht gespeichert.",
    upload_placeholder = "Datei ausw\u00e4hlen...",
    upload_button      = "Durchsuchen",
    # Phase 2
    p2_why_b = "Warum zuerst Konvergenz pr\u00fcfen?",
    p2_why   = " Ein PPC ist nur aussagekr\u00e4ftig, wenn der MCMC-Sampler tats\u00e4chlich den Posterior gefunden hat. Wenn die Ketten nicht konvergiert sind, zeigen die PPCs Artefakte des Sampling-Prozesses \u2014 nicht Eigenschaften des Modells.",
    # Phase 3 disclaimer
    p3_disc_b = "\u26a0 Hinweis zu den automatischen Bewertungen",
    p3_disc   = "Die farbigen Einsch\u00e4tzungen (\u2713 Unauff\u00e4llig / \u26a0 Auff\u00e4llig) sind <b>automatisch generierte Heuristiken</b> basierend auf einfachen statistischen Kennzahlen. Sie sind als erste Orientierung gedacht \u2014 kein Ersatz f\u00fcr eine inhaltliche Beurteilung durch dich.<br>Insbesondere bei kleinen Stichproben, stark schiefen Verteilungen oder komplexen Modellstrukturen k\u00f6nnen die Bewertungen irref\u00fchrend sein. Schaue immer selbst auf die Plots und beurteile, ob das Modell inhaltlich sinnvolle Vorhersagen macht.",
    # Station labels
    sta1_lbl = "Station 1 \u2014 Globale Verteilung",
    sta2_lbl = "Station 2 \u2014 Statistische Kennzahlen",
    sta3_lbl = "Station 3 \u2014 Fehlerstruktur",
    sta4_lbl = "Station 4 \u2014 Kalibrierung: PIT-ECDF",
    sta4b_lbl  = "Station 4b \u2014 Vorhersageintervalle (erg\u00e4nzend)",
    sta4b2_lbl = "Station 4b \u2014 Gruppierter PPC",
    # Station narr content
    sta1_what_b = "Was du siehst:", sta1_what = " Die <b>helle Linie</b> = deine echten Daten (KDE). Die <b>blauen Linien</b> = 50 simulierte Datens\u00e4tze aus deinem Posterior. Frage: Liegt die helle Linie innerhalb des blauen Bandes?",
    sta1_prob_b = "Was w\u00e4re problematisch?", sta1_prob = " Helle Linie liegt dauerhaft au\u00dferhalb \u00b7 Falscher Modalwert \u00b7 Falscher Definitionsbereich (z.B. negative Werte bei einer Z\u00e4hlvariable)",
    sta2_what_b = "Was du siehst:", sta2_what = " F\u00fcr jede Kennzahl (Mittelwert, SD, Minimum, Maximum) zeigt das Histogramm die Verteilung der simulierten Werte. Die <b>senkrechte Linie</b> ist dein beobachteter Wert.",
    sta2_bp_b   = "Bayesianischer p-Wert:", sta2_bp = " Anteil der simulierten Werte, die extremer sind als der beobachtete. 0.5 = perfekt. < 0.05 oder > 0.95 = auff\u00e4llig. Nicht wie frequentistisches p \u2014 kein Signifikanztest!",
    sta4_pit_b  = "Was ist der PIT-ECDF?",
    sta4_pit    = "PIT steht f\u00fcr <em>Probability Integral Transform</em>. F\u00fcr jede Beobachtung wird berechnet: Welcher Anteil der simulierten Werte liegt <em>unter</em> dem echten beobachteten Wert? Bei einem perfekt kalibrierten Modell ist dieser Anteil gleichm\u00e4\u00dfig zwischen 0 und 1 verteilt \u2014 die ECDF-Kurve l\u00e4uft dann diagonal (45\u00b0-Linie).",
    sta4_band_b = "Die Unsicherheitsh\u00fclle (ovales Band):", sta4_band = " Das graue/blaue Band zeigt, wie viel Abweichung von der Diagonalen durch reinen Zufall entstehen w\u00fcrde \u2014 auch bei einem perfekt kalibrierten Modell. Die Kurve sollte <b>innerhalb</b> dieses Bandes verlaufen.",
    sta4_prob_b = "Was ist problematisch?",
    sta4_s   = "\u2022 Kurve <b>S-f\u00f6rmig</b>: Verteilungsform falsch, z.B. zu schmale oder zu breite Posterior-Verteilung",
    sta4_abo = "\u2022 Kurve <b>liegt dauerhaft \u00fcber der Diagonale</b>: Modell \u00fcbersch\u00e4tzt systematisch",
    sta4_bel = "\u2022 Kurve <b>liegt dauerhaft unter der Diagonale</b>: Modell untersch\u00e4tzt systematisch",
    sta4_out = "\u2022 Kurve <b>verl\u00e4sst das Band</b>: Kalibrierungsproblem, das \u00fcber Zufall hinausgeht",
    sta4b_what_b = "Was du siehst:", sta4b_what = " F\u00fcr jede Beobachtung: das 50%%- und 90%%-Vorhersageintervall. Die Punkte sind die echten Werte.",
    sta4b_chk_b  = "Was du pr\u00fcfst:", sta4b_chk = " Liegen ~90%% der echten Punkte im 90%%-Band? Zu enge B\u00e4nder = Unsicherheit untersch\u00e4tzt. Zu breite B\u00e4nder = Unsicherheit \u00fcbersch\u00e4tzt.",
    # Phase 5
    p5_intro = "Du hast die gef\u00fchrte Tour abgeschlossen. Hier kannst du alle verf\u00fcgbaren PPC-Plots frei erkunden und eigene Gruppierungen w\u00e4hlen.",
    p5_type = "Plot-Typ", p5_go = "Plot erstellen", p5_group = "Gruppe:", p5_groupvar = "Gruppierungsvariable:", p5_stat = "Statistik:",
    p5_dist = "Verteilung", p5_stats = "Kennzahlen", p5_intv = "Intervalle", p5_scat = "Streuung", p5_spec = "Spezial",
    # Upload
    scr_b = "R-Skript f\u00fcr Kompakt-Export:", scr_desc = "F\u00fchre dieses Skript in R aus, dann lade die erzeugte Datei hoch:",
    scr_code = "library(brms)\n# Dein Modell:  fit <- readRDS(\"mein_modell.rds\")\n\n# Kompakt-Export fuer PPC-App\nnd   <- min(200, posterior::ndraws(fit))\nyrep <- posterior_predict(fit, ndraws = nd)\ny    <- fit$data[[as.character(fit$formula$resp)]]\nfam  <- family(fit)$family\n\n# Gruppen-Variable (optional, NULL wenn nicht vorhanden):\ndat  <- fit$data\ngroups <- names(dat)[sapply(dat, function(x) is.factor(x)|is.character(x))]\ngrp_data <- if(length(groups)>0) dat[groups] else NULL\n\nsaveRDS(list(\n  yrep    = yrep,\n  y       = y,\n  family  = fam,\n  formula = as.character(fit$formula),\n  n_obs   = nrow(fit$data),\n  grp_data = grp_data\n), \"ppc_export.rds\")",
    ul_lbl_c = "Kompakt-Export laden (ppc_export.rds)", ul_lbl_f = "Vollst\u00e4ndiges brms-Modell (.rds)",
    ul_ok_c = "\u2713 Kompakt-Export geladen", ul_ok_f = "\u2713 Modell erfolgreich geladen",
    ul_err_b = "\u2717 Fehler beim Laden:", ul_err_hint = "Stelle sicher, dass du ein mit <code>saveRDS()</code> gespeichertes brms-Modellobjekt hochl\u00e4dst.",
    ul_toobig = "Datei zu gro\u00df f\u00fcr den direkten Upload. Bitte verwende den Kompakt-Export.",
    ul_processing = "Datei wird verarbeitet...",
    # Diagnosis
    diag_mode = "MODUS", diag_fam = "FAMILIE", diag_nobs = "BEOBACHTUNGEN",
    diag_chains = "KETTEN", diag_rhat = "R\u0302 MAX", diag_divs = "DIVERGENZEN",
    diag_compact = "Kompakt-Export",
    diag_noconv = "Konvergenzinformationen (R\u0302, Divergenzen) sind im Kompakt-Export nicht verf\u00fcgbar. Pr\u00fcfe diese in R mit summary(fit) vor dem Export.",
    # Convergence
    cv_ok = "\u2713 Konvergenz sieht gut aus.", cv_ok_text = " R\u0302-Werte unter 1.01 und keine Divergenzen bedeuten: der Sampler hat den Posterior zuverl\u00e4ssig erkundet. Der PPC ist aussagekr\u00e4ftig.",
    cv_warn_b = "\u26a0 Konvergenzprobleme erkannt.", cv_warn_text = " Der PPC kann trotzdem informativ sein, aber Ergebnisse mit Vorsicht interpretieren.",
    cv_probs = "Probleme:", cv_sols = "L\u00f6sungsans\u00e4tze in R:",
    cv_rhat_p = "R\u0302 = %.3f (Grenze: 1.01) \u2014 Ketten haben nicht konvergiert",
    cv_divs_p = "%d Divergenzen \u2014 Sampler hatte numerische Probleme",
    cv_rhat_s = "Mehr Iterationen (iter = 4000), l\u00e4ngeres Warmup",
    cv_divs_s1 = "adapt_delta erh\u00f6hen (z.B. control = list(adapt_delta = 0.99))",
    cv_divs_s2 = "Priors \u00fcberpr\u00fcfen \u2014 m\u00f6glicherweise zu flach",
    cv_compact = "Konvergenzdetails sind im Kompakt-Export nicht verf\u00fcgbar.",
    cv_badge_rhat_ok   = "R\u0302 < 1.01 \u2014 Konvergenz OK",
    cv_badge_rhat_fail = "R\u0302 = %.3f \u2014 Konvergenzproblem!",
    cv_badge_divs_ok   = "Keine Divergenzen",
    cv_badge_divs_fail = "%d Divergenzen \u2014 Vorsicht!",
    # eval_pval
    ev_unknown = "unbekannt", ev_unknown_msg = "Konnte nicht berechnet werden.",
    ev_warn = "\u26a0 Auff\u00e4llig",
    ev_warn_msg = "Der beobachtete Wert liegt im %.0f%%-Extrembereich der simulierten Verteilung. Das Modell hat Schwierigkeiten, %s der Daten zu reproduzieren.",
    ev_border = "~ Grenzwertig",
    ev_border_msg = "Leichte Auff\u00e4lligkeit bei %s. Nicht kritisch, aber beachtenswert.",
    ev_ok = "\u2713 Unauff\u00e4llig", ev_ok_msg = "%s wird vom Modell gut reproduziert.",
    # ppc_dens_eval
    dens_ok = "\u2713 Globale Verteilung unauff\u00e4llig", dens_warn = "\u26a0 Auff\u00e4lligkeit in globaler Verteilung",
    dens_ok_t = "Der Mittelwert der simulierten Daten liegt nahe am beobachteten Mittelwert. Die globale Form scheint gut getroffen.",
    dens_warn_t = "Der beobachtete Mittelwert (%.2f) weicht systematisch von den simulierten Mittelwerten (%.2f \u00b1 %.2f) ab. \u00dcberpr\u00fcfe die Modellspezifikation.",
    # stats
    st_mean = "Mittelwert", st_sd = "SD", st_min = "Minimum", st_max = "Maximum",
    st_mean_l = "des Mittelwerts", st_sd_l = "der Standardabweichung", st_min_l = "des Minimums", st_max_l = "des Maximums",
    st_heading = "Bayesianische p-Werte f\u00fcr Kennzahlen:",
    st_remind  = "Erinnerung: p \u2248 0.5 ist ideal. p < 0.05 oder p > 0.95 ist auff\u00e4llig.",
    # pit_eval
    pit_ok = "\u2713 PIT unauff\u00e4llig \u2014 Kalibrierung gut",
    pit_border = "~ PIT grenzwertig \u2014 leichte Kalibrierungsprobleme",
    pit_warn = "\u26a0 PIT auff\u00e4llig \u2014 Kalibrierungsprobleme erkennbar",
    pit_ks   = "KS-Statistik: %.3f  (< 0.06 = gut, 0.06\u20130.12 = grenzwertig, > 0.12 = auff\u00e4llig)",
    pit_rem_b = "Zur Erinnerung: ", pit_rem = "Kurve innerhalb des Bandes & diagonal = gut. S-Form = falsche Verteilungsbreite. Dauerhafte Abweichung = systematischer Bias.",
    pit_cav_b = "\u26a0 Hinweis: ", pit_cav = "KS-Statistik ist eine Heuristik \u2014 immer auch den Plot selbst beurteilen.",
    pit_na = "PIT-Bewertung nicht verf\u00fcgbar.", pit_na_err = "PIT nicht verf\u00fcgbar:",
    # intervals_eval
    iv_cov = "90%%-Intervall Abdeckung: %.0f%% der Beobachtungen",
    iv_ok  = "\u2713 Nahe an den erwarteten 90%%. Das Modell kalibriert Unsicherheit gut.",
    iv_low = "\u26a0 Zu wenige Beobachtungen im 90%%-Band \u2014 das Modell untersch\u00e4tzt die Unsicherheit (zu enge Intervalle).",
    iv_high = "~ Etwas zu viele Beobachtungen im Band \u2014 das Modell \u00fcbersch\u00e4tzt m\u00f6glicherweise die Unsicherheit.",
    # grouped
    grp_b = "Gruppenvergleich:", grp_t = " Dein Datensatz enth\u00e4lt kategoriale Variablen. Ein gruppierter PPC pr\u00fcft, ob dein Modell die Gruppen gleich gut reproduziert \u2014 oder ob es f\u00fcr manche Gruppen systematisch schlechter ist.",
    grp_lbl = "Gruppierungsvariable:",
    # overall
    ov_ok = "\u2713 Modell besteht den PPC gut", ov_one = "~ Ein Aspekt ist auff\u00e4llig", ov_many = "\u26a0 %d Aspekte auff\u00e4llig",
    ov_sd = "Standardabweichung", ov_mm = "Minimum / Maximum", ov_cov = "90%%-Intervall Abdeckung",
    ov_ok_v = "\u2713 OK", ov_warn_v = "\u26a0 p=%.2f", ov_warn_p = "\u26a0 Auff\u00e4llig", ov_cov_ok = "\u2713 OK", ov_cov_w = "\u26a0 Kalibrierung",
    # next_steps
    ns_intro = "Basierend auf den Ergebnissen folgende \u00dcberlegungen:",
    ns_nob = "\u2713 Keine spezifischen Handlungsempfehlungen.",
    ns_no  = "Dein Modell besteht alle gepr\u00fcften Aspekte des PPC gut. Das bedeutet nicht, dass das Modell perfekt ist \u2014 aber es gibt keine offensichtlichen Spezifikationsfehler.",
    ns_sd_t = "SD untersch\u00e4tzt \u2014 Modell zu eng",
    ns_sd_x = "Das Modell simuliert Daten mit zu wenig Streuung. M\u00f6gliche Ursachen: fehlende Pr\u00e4diktoren, heteroskedastische Fehler. Versuch: Student-t statt Gaussian, oder ein distributional model mit sigma ~ Pr\u00e4diktoren.",
    ns_max_t = "Extremwerte nicht gut abgedeckt",
    ns_max_x = "Das Modell produziert selten so extreme Werte wie in den echten Daten. Hinweis auf heavy tails. Versuch: family = student statt gaussian.",
    ns_cov_t = "Intervalle zu eng \u2014 Unsicherheit untersch\u00e4tzt",
    ns_cov_x = "Nur weniger als 82%% der Daten liegen im 90%%-Band. M\u00f6gliche Ursachen: fehlende Varianz-Komponenten, falsche Familie, oder Ausrei\u00dfer. \u00dcberpr\u00fcfe den Residualplot.",
    # error narr
    en_root_b = "Rootogramm (Z\u00e4hldaten)", en_root = " \u2014 Vergleicht beobachtete und erwartete H\u00e4ufigkeiten je Z\u00e4hlwert. Die h\u00e4ngenden Balken sollten nahe bei 0 sein.",
    en_zi_b = "Zero-Inflation/Hurdle-Modell:", en_zi = " Pr\u00fcfe besonders den Balken bei 0 \u2014 er sollte gut sitzen.",
    en_pois_b = "Poisson-Typisch:", en_pois = " Zero-Inflation zeigt sich als stark positiver 0-Balken (mehr Nullen beobachtet als erwartet).",
    en_calib_b = "Calibration Plot (bin\u00e4re/binomiale Daten)", en_calib = " \u2014 Wie gut sind die vorhergesagten Wahrscheinlichkeiten kalibriert? Bei perfekter Kalibrierung liegen alle Punkte auf der Diagonalen.",
    en_beta_b = "Beta-Verteilung (0\u20131 Werte):", en_beta = " Dichte auf Originalskala (0 bis 1). Pr\u00fcfe ob H\u00e4ufungen nahe 0 oder 1 (Grenzwertprobleme) gut reproduziert werden.",
    en_log_b = "Rechts-schiefe Verteilung \u2014 Log-Skala:", en_log = " Die Dichte wird auf log(y+1)-Skala gezeigt. Auf dieser Skala sollte die Verteilung eher symmetrisch sein. Abweichungen deuten auf falsche Schiefe oder fehlende Kovariaten hin.",
    en_ord_b = "Ordinale Daten \u2014 Balkendiagramm:", en_ord = " Vergleicht beobachtete und simulierte H\u00e4ufigkeiten je Antwortkategorie. Alle Kategorien sollten gut getroffen sein.",
    en_res_b = "Residualverteilung", en_res = " \u2014 Symmetrisch und zentriert bei 0? Systematische Muster deuten auf falsche Linkfunktion oder fehlende Pr\u00e4diktoren hin.",
    en_re_b = "Random Effects erkannt:", en_re = " posterior_predict() ber\u00fccksichtigt die RE-Struktur automatisch. Der gruppierte PPC in Station 4b ist besonders informativ.",
    # plot titles
    plt_mean = "Mittelwert", plt_sd = "Standardabweichung", plt_min = "Minimum", plt_max = "Maximum",
    plt_log_t = "Dichte auf Log-Skala", plt_log_x = "log(y + 1)",
    # family
    fam_gaussian = "Normal (Gaussian)", fam_bernoulli = "Bernoulli (0/1)", fam_binomial = "Binomial",
    fam_poisson = "Poisson (Z\u00e4hldaten)", fam_negbinomial = "Negativ-Binomial",
    fam_gamma = "Gamma (positive Werte)", fam_lognormal = "Lognormal", fam_student = "Student-t", fam_beta = "Beta (0\u20131)",
    # plot explanations
    xpl_dens  = "KDE-Dichte-Vergleich: Schwarze Linie = echte Daten, blaue Linien = simulierte Datens\u00e4tze. Ideal: helle Linie (echte Daten) mitten im blauen Band.",
    xpl_ecdf  = "Empirische CDF. Robuster als KDE f\u00fcr diskrete oder schiefe Daten. Systematische Verschiebungen gut erkennbar.",
    xpl_hist  = "Histogramme der simulierten Datens\u00e4tze. Weniger glatt als KDE, daf\u00fcr genauer bei diskreten Daten.",
    xpl_stat  = "Verteilung einer Test-Statistik \u00fcber simulierte Datens\u00e4tze. Senkrechte Linie = beobachteter Wert. Linie sollte mittig liegen.",
    xpl_statg = "Wie ppc_stat, aber separat f\u00fcr jede Gruppe. Zeigt ob bestimmte Gruppen schlechter reproduziert werden.",
    xpl_intv  = "90%%-Vorhersageintervalle f\u00fcr jede Beobachtung. ~90%% der echten Punkte sollten im Band liegen.",
    xpl_rib   = "Wie ppc_intervals, aber als Band. Gut f\u00fcr zeitliche oder geordnete Daten.",
    xpl_scat  = "Streudiagramm: beobachtete vs. durchschnittliche vorhergesagte Werte. Ideal: Punkte auf der Diagonalen.",
    xpl_errh  = "Histogramm der Residuen. Sollte symmetrisch um 0 sein.",
    xpl_root  = "F\u00fcr Z\u00e4hldaten: beobachtete vs. erwartete H\u00e4ufigkeiten je Z\u00e4hlwert. Balken nahe 0 = gut.",
    xpl_pit   = "Probability Integral Transform. F\u00fcr gut kalibrierte Modelle: ann\u00e4hernd gerade Diagonale."
  ),
  en = list(
    tb_sub    = "Model checking \u00b7 bayesplot \u00b7 brms \u00b7 Guided Tutorial",
    tb_auth   = "\u00a9 Dr. Rainer D\u00fcsing \u00b7 Interactive Tools by Claude",
    btn_back  = "\u2190 Back to Lab",
    btn_model = "\u2b21 Model Builder",
    btn_lang  = '<svg width="18" height="12" viewBox="0 0 18 12" style="vertical-align:middle;margin-right:4px"><rect width="18" height="4" fill="#000"/><rect y="4" width="18" height="4" fill="#DD0000"/><rect y="8" width="18" height="4" fill="#FFCE00"/></svg> DE',
    prog_label = "Progress:",
    prog_0 = "0 \u00b7 Intro",         prog_1 = "1 \u00b7 Upload",
    prog_2 = "2 \u00b7 Diagnostics",   prog_3 = "3 \u00b7 PPC Tour",
    prog_4 = "4 \u00b7 Assessment",    prog_5 = "5 \u00b7 Exploration",
    phase0_title = "What is a Posterior Predictive Check?",
    phase1_title = "Upload Model",
    phase2_title = "Model Diagnostics \u2014 before looking at PPCs",
    phase3_title = "Guided PPC Tour",
    phase4_title = "Overall Assessment & Next Steps",
    phase5_title = "Free Exploration",
    phase5_sub   = "For advanced users \u2014 all bayesplot plots available",
    # Phase 0
    p0_princ_b = "The core principle in one sentence:",
    p0_princ   = " If your model is good, data it simulates should look like your real data.",
    p0_text    = "You have fitted a brms model. The posterior now contains thousands of parameter combinations \u2014 essentially thousands of \u201cversions\u201d of your model, each slightly different. With each version you can simulate a new dataset. If these simulated datasets systematically deviate from your real data, something is wrong with the model.",
    p0_cav_b   = "Important:",
    p0_cav     = " A PPC does not test whether your model is \u201ctrue\u201d. It tests whether your model captures the essential characteristics of your data \u2014 distribution, mean, variance, extremes.",
    p0_good_b  = "\u2713 Good model: what you want to see",
    p0_good    = "The black curve (real data) lies within the blue lines (simulated data). No systematic deviations.",
    p0_bad_b   = "\u2717 Problematic model: warning signs",
    p0_bad     = "The black curve lies outside or has a completely different shape. E.g. real data have a long right tail, but the model simulates symmetric data.",
    # Phase 1 modes
    mode_c_lbl  = "\u25cf Compact Export (recommended)",
    mode_c_desc = "Export only yrep + y from R (download script below). Small file, fast, stable \u2014 no RAM issues.",
    mode_f_lbl  = "\u25cb Full brms object",
    mode_f_desc = "Upload your saved model (.rds). The app computes posterior_predict() itself.",
    mode_f_warn = "\u26a0 Large models may cause server disconnects. Only suitable for smaller models.",
    privacy     = "<b>Privacy:</b> Files are only loaded for this session and not stored.",
    upload_placeholder = "Select file...",
    upload_button      = "Browse",
    # Phase 2
    p2_why_b = "Why check convergence first?",
    p2_why   = " A PPC is only meaningful if the MCMC sampler has actually found the posterior. If chains have not converged, PPCs show artifacts of the sampling process \u2014 not properties of the model.",
    # Phase 3 disclaimer
    p3_disc_b = "\u26a0 Note on automatic evaluations",
    p3_disc   = "The colored ratings (\u2713 Unremarkable / \u26a0 Notable) are <b>automatically generated heuristics</b> based on simple statistical summaries. They are meant as a first orientation \u2014 not a substitute for your own substantive judgment.<br>In particular for small samples, heavily skewed distributions, or complex model structures, the ratings may be misleading. Always look at the plots yourself and judge whether the model makes substantively sensible predictions.",
    # Station labels
    sta1_lbl = "Station 1 \u2014 Global Distribution",
    sta2_lbl = "Station 2 \u2014 Summary Statistics",
    sta3_lbl = "Station 3 \u2014 Error Structure",
    sta4_lbl = "Station 4 \u2014 Calibration: PIT-ECDF",
    sta4b_lbl  = "Station 4b \u2014 Prediction Intervals (supplementary)",
    sta4b2_lbl = "Station 4b \u2014 Grouped PPC",
    # Station narr content
    sta1_what_b = "What you see:", sta1_what = " The <b>light line</b> = your real data (KDE). The <b>blue lines</b> = 50 simulated datasets from your posterior. Question: Is the light line within the blue band?",
    sta1_prob_b = "What would be problematic?", sta1_prob = " Light line consistently outside the band \u00b7 Wrong mode \u00b7 Wrong support (e.g. negative values for count data)",
    sta2_what_b = "What you see:", sta2_what = " For each summary (mean, SD, min, max) the histogram shows the distribution of simulated values. The <b>vertical line</b> is your observed value.",
    sta2_bp_b   = "Bayesian p-value:", sta2_bp = " Proportion of simulated values more extreme than observed. 0.5 = perfect. < 0.05 or > 0.95 = notable. Not a frequentist p \u2014 not a significance test!",
    sta4_pit_b  = "What is the PIT-ECDF?",
    sta4_pit    = "PIT stands for <em>Probability Integral Transform</em>. For each observation, we compute: what proportion of simulated values falls <em>below</em> the real observed value? For a perfectly calibrated model, this proportion is uniformly distributed between 0 and 1 \u2014 the ECDF curve runs diagonally (45\u00b0 line).",
    sta4_band_b = "The uncertainty envelope (oval band):", sta4_band = " The grey/blue band shows how much deviation from the diagonal would arise by chance alone. The curve should stay <b>within</b> this band.",
    sta4_prob_b = "What is problematic?",
    sta4_s   = "\u2022 Curve is <b>S-shaped</b>: wrong distributional shape, e.g. posterior too narrow or too wide",
    sta4_abo = "\u2022 Curve <b>consistently above diagonal</b>: model systematically overpredicts",
    sta4_bel = "\u2022 Curve <b>consistently below diagonal</b>: model systematically underpredicts",
    sta4_out = "\u2022 Curve <b>leaves the band</b>: calibration problem beyond chance variation",
    sta4b_what_b = "What you see:", sta4b_what = " For each observation: the 50%%- and 90%%-prediction interval. The dots are the real values.",
    sta4b_chk_b  = "What you check:", sta4b_chk = " Do ~90%% of real points fall within the 90%% band? Too narrow = uncertainty underestimated. Too wide = uncertainty overestimated.",
    # Phase 5
    p5_intro = "You have completed the guided tour. Here you can freely explore all available PPC plots and choose your own groupings.",
    p5_type = "Plot type", p5_go = "Create plot", p5_group = "Group:", p5_groupvar = "Grouping variable:", p5_stat = "Statistic:",
    p5_dist = "Distribution", p5_stats = "Statistics", p5_intv = "Intervals", p5_scat = "Scatter", p5_spec = "Special",
    # Upload
    scr_b = "R script for compact export:", scr_desc = "Run this script in R, then upload the generated file:",
    scr_code = "library(brms)\n# Your model:  fit <- readRDS(\"my_model.rds\")\n\n# Compact export for PPC app\nnd   <- min(200, posterior::ndraws(fit))\nyrep <- posterior_predict(fit, ndraws = nd)\ny    <- fit$data[[as.character(fit$formula$resp)]]\nfam  <- family(fit)$family\n\n# Group variable (optional, NULL if not present):\ndat  <- fit$data\ngroups <- names(dat)[sapply(dat, function(x) is.factor(x)|is.character(x))]\ngrp_data <- if(length(groups)>0) dat[groups] else NULL\n\nsaveRDS(list(\n  yrep    = yrep,\n  y       = y,\n  family  = fam,\n  formula = as.character(fit$formula),\n  n_obs   = nrow(fit$data),\n  grp_data = grp_data\n), \"ppc_export.rds\")",
    ul_lbl_c = "Load compact export (ppc_export.rds)", ul_lbl_f = "Full brms model (.rds)",
    ul_ok_c = "\u2713 Compact export loaded", ul_ok_f = "\u2713 Model successfully loaded",
    ul_err_b = "\u2717 Error loading file:", ul_err_hint = "Make sure you upload a brms model object saved with <code>saveRDS()</code>.",
    ul_toobig = "File too large for direct upload. Please use the compact export.",
    ul_processing = "Processing file...",
    # Diagnosis
    diag_mode = "MODE", diag_fam = "FAMILY", diag_nobs = "OBSERVATIONS",
    diag_chains = "CHAINS", diag_rhat = "R\u0302 MAX", diag_divs = "DIVERGENCES",
    diag_compact = "Compact Export",
    diag_noconv = "Convergence information (R\u0302, divergences) is not available in compact export. Check these in R with summary(fit) before exporting.",
    # Convergence
    cv_ok = "\u2713 Convergence looks good.", cv_ok_text = " R\u0302 values below 1.01 and no divergences mean: the sampler has reliably explored the posterior. The PPC is informative.",
    cv_warn_b = "\u26a0 Convergence problems detected.", cv_warn_text = " The PPC may still be informative, but interpret results with caution.",
    cv_probs = "Problems:", cv_sols = "Solutions in R:",
    cv_rhat_p = "R\u0302 = %.3f (threshold: 1.01) \u2014 chains have not converged",
    cv_divs_p = "%d divergences \u2014 sampler had numerical problems",
    cv_rhat_s = "More iterations (iter = 4000), longer warmup",
    cv_divs_s1 = "Increase adapt_delta (e.g. control = list(adapt_delta = 0.99))",
    cv_divs_s2 = "Check priors \u2014 possibly too flat",
    cv_compact = "Convergence details are not available in compact export.",
    cv_badge_rhat_ok   = "R\u0302 < 1.01 \u2014 Convergence OK",
    cv_badge_rhat_fail = "R\u0302 = %.3f \u2014 Convergence problem!",
    cv_badge_divs_ok   = "No divergences",
    cv_badge_divs_fail = "%d divergences \u2014 Caution!",
    # eval_pval
    ev_unknown = "unknown", ev_unknown_msg = "Could not be computed.",
    ev_warn = "\u26a0 Notable",
    ev_warn_msg = "The observed value is in the %.0f%% extreme range of the simulated distribution. The model struggles to reproduce %s in the data.",
    ev_border = "~ Borderline",
    ev_border_msg = "Slight anomaly in %s. Not critical, but worth noting.",
    ev_ok = "\u2713 Unremarkable", ev_ok_msg = "%s is well reproduced by the model.",
    # ppc_dens_eval
    dens_ok = "\u2713 Global distribution unremarkable", dens_warn = "\u26a0 Anomaly in global distribution",
    dens_ok_t = "The mean of simulated data is close to the observed mean. The global shape appears well captured.",
    dens_warn_t = "The observed mean (%.2f) systematically deviates from simulated means (%.2f \u00b1 %.2f). Check the model specification.",
    # stats
    st_mean = "Mean", st_sd = "SD", st_min = "Minimum", st_max = "Maximum",
    st_mean_l = "of the mean", st_sd_l = "of the SD", st_min_l = "of the minimum", st_max_l = "of the maximum",
    st_heading = "Bayesian p-values for summary statistics:",
    st_remind  = "Reminder: p \u2248 0.5 is ideal. p < 0.05 or p > 0.95 is notable.",
    # pit_eval
    pit_ok = "\u2713 PIT unremarkable \u2014 calibration good",
    pit_border = "~ PIT borderline \u2014 slight calibration issues",
    pit_warn = "\u26a0 PIT notable \u2014 calibration problems detectable",
    pit_ks   = "KS statistic: %.3f  (< 0.06 = good, 0.06\u20130.12 = borderline, > 0.12 = notable)",
    pit_rem_b = "Reminder: ", pit_rem = "Curve within band & diagonal = good. S-shape = wrong distributional width. Persistent deviation = systematic bias.",
    pit_cav_b = "\u26a0 Note: ", pit_cav = "KS statistic is a heuristic \u2014 always judge the plot itself.",
    pit_na = "PIT assessment not available.", pit_na_err = "PIT not available:",
    # intervals_eval
    iv_cov = "90%% interval coverage: %.0f%% of observations",
    iv_ok  = "\u2713 Close to the expected 90%%. The model calibrates uncertainty well.",
    iv_low = "\u26a0 Too few observations in the 90%% band \u2014 the model underestimates uncertainty (intervals too narrow).",
    iv_high = "~ Slightly too many observations in the band \u2014 the model may overestimate uncertainty.",
    # grouped
    grp_b = "Group comparison:", grp_t = " Your dataset contains categorical variables. A grouped PPC checks whether your model reproduces all groups equally well \u2014 or is systematically worse for some groups.",
    grp_lbl = "Grouping variable:",
    # overall
    ov_ok = "\u2713 Model passes the PPC well", ov_one = "~ One aspect is notable", ov_many = "\u26a0 %d aspects notable",
    ov_sd = "Standard deviation", ov_mm = "Minimum / Maximum", ov_cov = "90%% interval coverage",
    ov_ok_v = "\u2713 OK", ov_warn_v = "\u26a0 p=%.2f", ov_warn_p = "\u26a0 Notable", ov_cov_ok = "\u2713 OK", ov_cov_w = "\u26a0 Calibration",
    # next_steps
    ns_intro = "Based on the results, consider the following:",
    ns_nob = "\u2713 No specific recommendations.",
    ns_no  = "Your model passes all tested PPC aspects well. This does not mean the model is perfect \u2014 but there are no obvious misspecification issues.",
    ns_sd_t = "SD underestimated \u2014 model too narrow",
    ns_sd_x = "The model simulates data with too little spread. Possible causes: missing predictors, heteroscedastic errors. Try: Student-t instead of Gaussian, or a distributional model with sigma ~ predictors.",
    ns_max_t = "Extreme values not well covered",
    ns_max_x = "The model rarely produces values as extreme as those in the real data. Suggests heavy tails. Try: family = student instead of gaussian.",
    ns_cov_t = "Intervals too narrow \u2014 uncertainty underestimated",
    ns_cov_x = "Fewer than 82%% of the data fall within the 90%% band. Possible causes: missing variance components, wrong family, or outliers. Check the residual plot.",
    # error narr
    en_root_b = "Rootogram (count data)", en_root = " \u2014 Compares observed and expected frequencies per count value. Hanging bars should be close to 0.",
    en_zi_b = "Zero-Inflation/Hurdle model:", en_zi = " Check especially the bar at 0 \u2014 it should fit well.",
    en_pois_b = "Poisson-typical:", en_pois = " Zero-inflation shows up as a strongly positive bar at 0 (more zeros observed than expected).",
    en_calib_b = "Calibration plot (binary/binomial data)", en_calib = " \u2014 How well are the predicted probabilities calibrated? With perfect calibration, all points lie on the diagonal.",
    en_beta_b = "Beta distribution (0\u20131 values):", en_beta = " Density on original scale (0 to 1). Check whether accumulations near 0 or 1 (boundary effects) are well reproduced.",
    en_log_b = "Right-skewed distribution \u2014 log scale:", en_log = " Density shown on log(y+1) scale. On this scale the distribution should be roughly symmetric. Deviations indicate wrong skew or missing covariates.",
    en_ord_b = "Ordinal data \u2014 bar chart:", en_ord = " Compares observed and simulated frequencies per response category. All categories should be well matched.",
    en_res_b = "Residual distribution", en_res = " \u2014 Symmetric and centered at 0? Systematic patterns indicate wrong link function or missing predictors.",
    en_re_b = "Random effects detected:", en_re = " posterior_predict() accounts for the RE structure automatically. The grouped PPC in Station 4b is particularly informative.",
    # plot titles
    plt_mean = "Mean", plt_sd = "Standard deviation", plt_min = "Minimum", plt_max = "Maximum",
    plt_log_t = "Density on log scale", plt_log_x = "log(y + 1)",
    # family
    fam_gaussian = "Normal (Gaussian)", fam_bernoulli = "Bernoulli (0/1)", fam_binomial = "Binomial",
    fam_poisson = "Poisson (count data)", fam_negbinomial = "Negative Binomial",
    fam_gamma = "Gamma (positive values)", fam_lognormal = "Lognormal", fam_student = "Student-t", fam_beta = "Beta (0\u20131)",
    # plot explanations
    xpl_dens  = "KDE density comparison: Black line = real data, blue lines = simulated datasets. Ideal: light line (real data) in the middle of the blue band.",
    xpl_ecdf  = "Empirical CDF. More robust than KDE for discrete or skewed data. Systematic shifts clearly visible.",
    xpl_hist  = "Histograms of simulated datasets. Less smooth than KDE, but more precise for discrete data.",
    xpl_stat  = "Distribution of a test statistic across simulated datasets. Vertical line = observed value. Line should be roughly centered.",
    xpl_statg = "Like ppc_stat, but separately for each group. Shows whether certain groups are less well reproduced.",
    xpl_intv  = "90%% prediction intervals for each observation. ~90%% of real points should fall within the band.",
    xpl_rib   = "Like ppc_intervals, but as a ribbon. Good for temporal or ordered data.",
    xpl_scat  = "Scatter plot: observed vs. average predicted values. Ideal: points on the diagonal.",
    xpl_errh  = "Histogram of residuals. Should be symmetric around 0.",
    xpl_root  = "For count data: observed vs. expected frequencies per count value. Bars close to 0 = good.",
    xpl_pit   = "Probability Integral Transform. For well-calibrated models: approximately straight diagonal."
  )
)

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
eval_pval <- function(p, stat_name = "Statistik", l = "de") {
  tr <- i18n[[l]]
  if (is.na(p)) return(list(rating = tr$ev_unknown, color = "gray", msg = tr$ev_unknown_msg))
  if (p < 0.025 || p > 0.975) {
    list(rating = tr$ev_warn, color = ACCENT,
         msg = sprintf(tr$ev_warn_msg, min(p, 1-p)*200, stat_name))
  } else if (p < 0.05 || p > 0.95) {
    list(rating = tr$ev_border, color = LAB_COLORS$a4,
         msg = sprintf(tr$ev_border_msg, stat_name))
  } else {
    list(rating = tr$ev_ok, color = LAB_COLORS$a3,
         msg = sprintf(tr$ev_ok_msg, stat_name))
  }
}

# Bayesian p-value for a statistic
bayes_pval <- function(yrep, y, stat_fn) {
  t_obs  <- stat_fn(y)
  t_rep  <- apply(yrep, 1, stat_fn)
  mean(t_rep >= t_obs)
}

# Parse family from brms fit
get_family_label <- function(fit, l = "de") {
  tr  <- i18n[[l]]
  fam <- family(fit)$family
  switch(fam,
    gaussian    = tr$fam_gaussian,
    bernoulli   = tr$fam_bernoulli,
    binomial    = tr$fam_binomial,
    poisson     = tr$fam_poisson,
    negbinomial = tr$fam_negbinomial,
    Gamma       = tr$fam_gamma,
    lognormal   = tr$fam_lognormal,
    student     = tr$fam_student,
    beta        = tr$fam_beta,
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
      .prog-step.done  { opacity: .7; }
      .prog-step.active { opacity: 1; font-weight: 600; }
      #prog-0.active, #prog-0.done { color: var(--ink2); }
      #prog-1.active, #prog-1.done { color: var(--a2); }
      #prog-2.active, #prog-2.done { color: var(--a6); }
      #prog-3.active, #prog-3.done { color: var(--a5); }
      #prog-4.active, #prog-4.done { color: var(--a3); }
      #prog-5.active, #prog-5.done { color: var(--a4); }

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
      uiOutput("topbar_sub")
    ),
    div(style = "display:flex;gap:.4rem;align-items:flex-start",
      uiOutput("topbar_buttons")
    )
  ),

  # ── Progress strip ─────────────────────────────────────
  div(id = "progress-bar",
    uiOutput("progress_bar_ui")
  ),
  # JS: track scroll position to update progress bar
  tags$script(HTML("
    function initProgressTracker() {
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
    }
    // Re-init after Shiny re-renders the progress bar uiOutput
    $(document).on('shiny:value', function(e) {
      if (e.name === 'progress_bar_ui') setTimeout(initProgressTracker, 100);
    });
    document.addEventListener('DOMContentLoaded', function() {
      setTimeout(initProgressTracker, 500);
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
        uiOutput("phase0_title_ui")
      ),
      div(class = "phase-body",
        uiOutput("phase0_body_ui")
      )
    ),

    # ═══════════════════════════════════════════════════
    # PHASE 1 — Upload
    # ═══════════════════════════════════════════════════
    div(id = "phase-box-1", class = "phase-box",
      div(class = "phase-header",
        span(class = "phase-num", style = "border-color:var(--a2);color:var(--a2)", "Phase 1"),
        uiOutput("phase1_title_ui")
      ),
      div(class = "phase-body",

        # Mode selector
        uiOutput("phase1_modes_ui"),

        # Hidden mode selector input — default: compact
        tags$input(type = "hidden", id = "upload_mode_val", value = "compact"),
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
              compactBox.style.borderColor = 'var(--a3)';
              compactBox.style.background  = 'var(--panel)';
              compactBox.querySelector('div').style.color = 'var(--a3)';
              fullBox.style.borderColor    = 'var(--grid)';
              fullBox.style.background     = 'transparent';
              fullBox.querySelector('div').style.color = 'var(--ink2)';
            }
          }
          // Initialize compact as selected once Shiny is connected
          $(document).on('shiny:connected', function() {
            Shiny.setInputValue('upload_mode', 'compact');
          });
        ")),

        # Compact mode: download script
        uiOutput("compact_script_download"),

        uiOutput("phase1_privacy_ui"),

        uiOutput("file_input_ui"),
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
          uiOutput("phase2_title_ui")
        ),
        div(class = "phase-body",
          uiOutput("phase2_narr_ui"),
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
          uiOutput("phase3_title_ui")
        ),
        div(class = "phase-body",
          uiOutput("phase3_disclaimer_ui"),

          # Station 1
          div(style = "margin-bottom:1.4rem",
            uiOutput("sta1_lbl_ui"),
            uiOutput("sta1_narr_ui"),
            div(class = "plot-wrap",
              plotOutput("ppc_dens", height = "380px")
            ),
            uiOutput("ppc_dens_eval")
          ),

          hr(class = "lab-hr"),

          # Station 2
          div(style = "margin-bottom:1.4rem",
            uiOutput("sta2_lbl_ui"),
            uiOutput("sta2_narr_ui"),
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

          # Station 3
          div(style = "margin-bottom:1.4rem",
            uiOutput("sta3_lbl_ui"),
            div(class = "narr-box",
              uiOutput("ppc_error_narr")
            ),
            div(class = "plot-wrap",
              plotOutput("ppc_error_plot", height = "380px")
            ),
            uiOutput("ppc_error_eval")
          ),

          hr(class = "lab-hr"),

          # Station 4
          div(style = "margin-bottom:1.4rem",
            uiOutput("sta4_lbl_ui"),
            uiOutput("sta4_narr_ui"),
            div(class = "plot-wrap",
              plotOutput("ppc_pit", height = "380px")
            ),
            uiOutput("ppc_pit_eval"),
            hr(class = "lab-hr"),
            uiOutput("sta4b_lbl_ui"),
            uiOutput("sta4b_narr_ui"),
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
          uiOutput("phase4_title_ui")
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
          uiOutput("phase5_title_ui"),
          uiOutput("phase5_sub_ui")
        ),
        div(class = "phase-body",
          uiOutput("phase5_body_ui")
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

  # ── Language ───────────────────────────────────────────
  lang <- reactiveVal("de")
  observeEvent(input$lang_toggle, {
    lang(if (lang() == "de") "en" else "de")
  })
  # Shorthand: tr() returns the translation list for current lang
  tr <- reactive({ i18n[[lang()]] })

  # ── Static UI outputs (language-reactive) ─────────────

  output$topbar_sub <- renderUI({
    t <- tr()
    tagList(
      div(class = "tb-sub", t$tb_sub),
      div(class = "tb-auth", t$tb_auth)
    )
  })

  output$topbar_buttons <- renderUI({
    t <- tr()
    tagList(
      tags$a(href = "https://github.com/raduesing/Bayes_Thinking_Lab/index.html",
             class = "lab-btn lab-btn-accent", t$btn_back),
      tags$a(href = "https://github.com/raduesing/Bayes_Thinking_Lab/Brms_model_builder.html",
             class = "lab-btn", t$btn_model),
      tags$button(
        id = "lang_toggle_btn",
        class = "lab-btn",
        style = "border-color:var(--a6);color:var(--a6)",
        onclick = "Shiny.setInputValue('lang_toggle', Math.random(), {priority:'event'})",
        HTML(t$btn_lang)
      )
    )
  })

  output$progress_bar_ui <- renderUI({
    t  <- tr()
    c0 <- LAB_COLORS$ink2; c1 <- LAB_COLORS$a2; c2 <- LAB_COLORS$a6
    c3 <- LAB_COLORS$a5;   c4 <- LAB_COLORS$a3; c5 <- LAB_COLORS$a4
    sep <- span(style = "color:var(--grid)", "\u00b7")
    tagList(
      span(style = "color:var(--ink2);opacity:.6", t$prog_label),
      tags$span(id = "prog-0", class = "prog-step active", style = sprintf("color:%s", c0), t$prog_0), sep,
      tags$span(id = "prog-1", class = "prog-step",        style = sprintf("color:%s", c1), t$prog_1), sep,
      tags$span(id = "prog-2", class = "prog-step",        style = sprintf("color:%s", c2), t$prog_2), sep,
      tags$span(id = "prog-3", class = "prog-step",        style = sprintf("color:%s", c3), t$prog_3), sep,
      tags$span(id = "prog-4", class = "prog-step",        style = sprintf("color:%s", c4), t$prog_4), sep,
      tags$span(id = "prog-5", class = "prog-step",        style = sprintf("color:%s", c5), t$prog_5)
    )
  })

  output$phase0_title_ui  <- renderUI({ span(class = "phase-title", style = sprintf("color:%s", LAB_COLORS$ink2), tr()$phase0_title) })
  output$phase1_title_ui  <- renderUI({ span(class = "phase-title", style = sprintf("color:%s", LAB_COLORS$a2),   tr()$phase1_title) })
  output$phase2_title_ui  <- renderUI({ span(class = "phase-title", style = sprintf("color:%s", LAB_COLORS$a6),   tr()$phase2_title) })
  output$phase3_title_ui  <- renderUI({ span(class = "phase-title", style = sprintf("color:%s", LAB_COLORS$a5),   tr()$phase3_title) })
  output$phase4_title_ui  <- renderUI({ span(class = "phase-title", style = sprintf("color:%s", LAB_COLORS$a3),   tr()$phase4_title) })
  output$phase5_title_ui  <- renderUI({ span(class = "phase-title", style = sprintf("color:%s", LAB_COLORS$a4),   tr()$phase5_title) })
  output$phase5_sub_ui    <- renderUI({
    span(style = "font-size:.6rem;color:var(--ink2);margin-left:auto", tr()$phase5_sub)
  })

  output$phase0_body_ui <- renderUI({
    t <- tr()
    tagList(
      div(class = "narr-box",
        tags$b(t$p0_princ_b), t$p0_princ,
        tags$br(), tags$br(),
        t$p0_text,
        tags$br(), tags$br(),
        tags$b(t$p0_cav_b), t$p0_cav
      ),
      div(style = "display:grid;grid-template-columns:1fr 1fr;gap:.6rem;margin-bottom:.8rem",
        div(class = "compare-good", tags$b(t$p0_good_b), t$p0_good),
        div(class = "compare-bad",  tags$b(t$p0_bad_b),  t$p0_bad)
      )
    )
  })

  output$phase1_modes_ui <- renderUI({
    t <- tr()
    tagList(
      div(style = "display:grid;grid-template-columns:1fr 1fr;gap:.6rem;margin-bottom:1rem",
        div(id = "mode-compact-box",
          style = "border:2px solid var(--a3);padding:.7rem .9rem;cursor:pointer;background:var(--panel)",
          onclick = "selectMode('compact')",
          div(style = "font-size:.85rem;color:var(--a3);font-weight:500;margin-bottom:.25rem", t$mode_c_lbl),
          div(style = "font-size:.72rem;color:var(--ink2);line-height:1.6", t$mode_c_desc)
        ),
        div(id = "mode-full-box",
          style = "border:2px solid var(--grid);padding:.7rem .9rem;cursor:pointer",
          onclick = "selectMode('full')",
          div(style = "font-size:.85rem;color:var(--ink2);font-weight:500;margin-bottom:.25rem", t$mode_f_lbl),
          div(style = "font-size:.72rem;color:var(--ink2);line-height:1.6", t$mode_f_desc),
          div(style = "font-size:.66rem;color:var(--a1);margin-top:.35rem;line-height:1.5", t$mode_f_warn)
        )
      )
    )
  })

  output$phase1_privacy_ui <- renderUI({
    div(class = "narr-box", HTML(tr()$privacy))
  })

  output$file_input_ui <- renderUI({
    t <- tr()
    fileInput("rds_file",
      label       = uiOutput("upload_label"),
      accept      = ".rds",
      placeholder = t$upload_placeholder,
      buttonLabel = t$upload_button
    )
  })

  output$phase2_narr_ui <- renderUI({
    t <- tr()
    div(class = "narr-box", tags$b(t$p2_why_b), HTML(t$p2_why))
  })

  output$phase3_disclaimer_ui <- renderUI({
    t <- tr()
    div(style = paste0("background:", LAB_COLORS$bg, ";border:1.5px solid ", LAB_COLORS$a4, ";",
                       "padding:.7rem 1rem;margin-bottom:1rem;font-size:.78rem;color:", LAB_COLORS$ink2),
      tags$b(style = paste0("color:", LAB_COLORS$a4), t$p3_disc_b),
      tags$br(),
      HTML(t$p3_disc)
    )
  })

  output$sta1_lbl_ui <- renderUI({ div(class = "station-lbl", tr()$sta1_lbl) })
  output$sta2_lbl_ui <- renderUI({ div(class = "station-lbl", tr()$sta2_lbl) })
  output$sta3_lbl_ui <- renderUI({ div(class = "station-lbl", tr()$sta3_lbl) })
  output$sta4_lbl_ui <- renderUI({ div(class = "station-lbl", tr()$sta4_lbl) })
  output$sta4b_lbl_ui <- renderUI({
    div(class = "station-lbl", style = "margin-top:.8rem", tr()$sta4b_lbl)
  })

  output$sta1_narr_ui <- renderUI({
    t <- tr()
    div(class = "narr-box",
      tags$b(t$sta1_what_b), HTML(t$sta1_what),
      tags$br(), tags$br(),
      tags$b(t$sta1_prob_b), t$sta1_prob
    )
  })

  output$sta2_narr_ui <- renderUI({
    t <- tr()
    div(class = "narr-box",
      tags$b(t$sta2_what_b), HTML(t$sta2_what),
      tags$br(), tags$br(),
      tags$b(t$sta2_bp_b), t$sta2_bp
    )
  })

  output$sta4_narr_ui <- renderUI({
    t <- tr()
    div(class = "narr-box",
      tags$b(t$sta4_pit_b), tags$br(),
      HTML(t$sta4_pit),
      tags$br(), tags$br(),
      tags$b(t$sta4_band_b), HTML(t$sta4_band),
      tags$br(), tags$br(),
      tags$b(t$sta4_prob_b),
      tags$br(), HTML(t$sta4_s),
      tags$br(), HTML(t$sta4_abo),
      tags$br(), HTML(t$sta4_bel),
      tags$br(), HTML(t$sta4_out)
    )
  })

  output$sta4b_narr_ui <- renderUI({
    t <- tr()
    div(class = "narr-box",
      tags$b(t$sta4b_what_b), t$sta4b_what,
      tags$br(), tags$br(),
      tags$b(t$sta4b_chk_b), t$sta4b_chk
    )
  })

  output$phase5_body_ui <- renderUI({
    t <- tr()
    tagList(
      div(class = "narr-box", t$p5_intro),
      fluidRow(
        column(4,
          selectInput("free_plot_type",
            label   = t$p5_type,
            choices = list(
              setNames(list(c("ppc_dens_overlay", "ppc_ecdf_overlay", "ppc_hist")), t$p5_dist),
              setNames(list(c("ppc_stat", "ppc_stat_grouped")), t$p5_stats),
              setNames(list(c("ppc_intervals", "ppc_ribbon")), t$p5_intv),
              setNames(list(c("ppc_scatter_avg", "ppc_error_hist")), t$p5_scat),
              setNames(list(c("ppc_rootogram", "ppc_pit_ecdf")), t$p5_spec)
            )
          ),
          uiOutput("free_group_ui"),
          uiOutput("free_stat_ui"),
          actionButton("free_go", t$p5_go,
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
  })

  # ── Reactive: upload mode ─────────────────────────────
  upload_mode <- reactive({
    if (is.null(input$upload_mode)) "compact" else input$upload_mode
  })

  # ── Reactive: export R script ─────────────────────────
  output$compact_script_download <- renderUI({
    if (upload_mode() != "compact") return(NULL)
    t <- tr()
    div(class = "narr-box",
      style = paste0("border-color:", LAB_COLORS$a2),
      tags$b(style = paste0("color:", LAB_COLORS$a2), t$scr_b),
      tags$br(), t$scr_desc, tags$br(), tags$br(),
      tags$pre(
        style = paste0("background:", LAB_COLORS$bg, ";padding:.6rem;font-size:.72rem;",
                        "color:", LAB_COLORS$ink, ";line-height:1.6;overflow-x:auto"),
        t$scr_code
      )
    )
  })

  # ── Reactive: upload label ─────────────────────────────
  output$upload_label <- renderUI({
    t <- tr()
    if (upload_mode() == "compact") t$ul_lbl_c else t$ul_lbl_f
  })

  # ── Reactive: load model ──────────────────────────────
  fit_data <- reactive({
    req(input$rds_file)
    validate(need(input$rds_file$size < 100 * 1024^2, tr()$ul_toobig))
    withProgress(message = tr()$ul_processing, {
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
          if (object.size(obj) >= 200 * 1024^2) {
            stop(tr()$ul_toobig)
          }
          fit  <- obj
          y    <- fit$data[[as.character(fit$formula$resp)]]
          nd   <- min(200, posterior::ndraws(fit))
          yrep <- posterior_predict(fit, ndraws = nd)
          # Subsample for large datasets to keep plots fast
          if (length(y) > 2000) {
            idx  <- sample(seq_along(y), 2000)
            y    <- y[idx]
            yrep <- yrep[, idx]
          }
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
    req(!is.null(fd))
    t <- tr()
    l <- lang()
    if (!fd$ok) {
      div(class = "narr-box",
        style = sprintf("border-color:%s", LAB_COLORS$a1),
        tags$b(style = sprintf("color:%s", LAB_COLORS$a1), t$ul_err_b),
        tags$br(), fd$error, tags$br(), tags$br(),
        HTML(t$ul_err_hint)
      )
    } else if (isTRUE(fd$compact)) {
      fam_lbl <- switch(fd$family_str %||% "gaussian",
        gaussian = t$fam_gaussian, bernoulli = t$fam_bernoulli, binomial = t$fam_binomial,
        poisson = t$fam_poisson, negbinomial = t$fam_negbinomial,
        Gamma = t$fam_gamma, lognormal = t$fam_lognormal, student = t$fam_student,
        beta = t$fam_beta, fd$family_str %||% "")
      div(
        style = sprintf("border-left:3px solid %s;padding:.5rem .8rem;background:%s;font-size:.68rem;color:%s",
                        LAB_COLORS$a3, LAB_COLORS$panel, LAB_COLORS$ink2),
        tags$b(style = sprintf("color:%s", LAB_COLORS$a3), t$ul_ok_c),
        tags$br(),
        sprintf("%s: %s \u00b7 %d %s", t$diag_fam, fam_lbl, fd$n_obs, t$diag_nobs)
      )
    } else {
      s <- model_summary_text(fd$fit)
      div(
        style = sprintf("border-left:3px solid %s;padding:.5rem .8rem;background:%s;font-size:.68rem;color:%s",
                        LAB_COLORS$a3, LAB_COLORS$panel, LAB_COLORS$ink2),
        tags$b(style = sprintf("color:%s", LAB_COLORS$a3), t$ul_ok_f),
        tags$br(),
        sprintf("%s: %s \u00b7 %d %s \u00b7 %d %s",
                t$diag_fam, get_family_label(fd$fit, l),
                s$n_obs, t$diag_nobs, s$n_pred,
                if (l == "de") "Pr\u00e4diktoren" else "predictors")
      )
    }
  })

  # ── Model diagnosis ────────────────────────────────────
  output$model_diagnosis <- renderUI({
    req(fit_data()$ok)
    t <- tr(); l <- lang()

    lbl <- function(key) tags$span(style = sprintf("color:%s;font-size:.58rem;display:block", LAB_COLORS$ink2), t[[key]])

    if (isTRUE(fit_data()$compact)) {
      fd <- fit_data()
      fam_lbl <- switch(fd$family_str %||% "gaussian",
        gaussian = t$fam_gaussian, bernoulli = t$fam_bernoulli, binomial = t$fam_binomial,
        poisson = t$fam_poisson, negbinomial = t$fam_negbinomial,
        Gamma = t$fam_gamma, lognormal = t$fam_lognormal, student = t$fam_student,
        beta = t$fam_beta, fd$family_str %||% "")
      return(div(
        div(style = sprintf("background:%s;padding:.75rem 1rem;font-size:.68rem;margin-bottom:.75rem", LAB_COLORS$panel),
          div(style = "display:grid;grid-template-columns:1fr 1fr 1fr;gap:.5rem",
            div(lbl("diag_mode"),  tags$b(t$diag_compact)),
            div(lbl("diag_fam"),   tags$b(fam_lbl)),
            div(lbl("diag_nobs"),  tags$b(fd$n_obs))
          )
        ),
        div(class = "narr-box",
          style = sprintf("border-color:%s;font-size:.67rem", LAB_COLORS$ink2),
          t$diag_noconv
        )
      ))
    }

    s   <- model_summary_text(fit_data()$fit)
    fam <- get_family_label(fit_data()$fit, l)
    iters_lbl <- if (l == "de") sprintf("%d \u00d7 %d Iterationen", s$chains, s$iters - s$warmup) else sprintf("%d \u00d7 %d iterations", s$chains, s$iters - s$warmup)
    outcome_lbl <- if (l == "de") "OUTCOME-VARIABLE" else "OUTCOME VARIABLE"

    div(
      div(style = sprintf("background:%s;padding:.75rem 1rem;font-size:.68rem;margin-bottom:.75rem", LAB_COLORS$panel),
        div(style = "display:grid;grid-template-columns:1fr 1fr 1fr;gap:.5rem",
          div(tags$span(style = sprintf("color:%s;font-size:.58rem;display:block", LAB_COLORS$ink2), outcome_lbl),
              tags$b(as.character(fit_data()$fit$formula$resp))),
          div(lbl("diag_fam"),   tags$b(fam)),
          div(lbl("diag_nobs"),  tags$b(s$n_obs)),
          div(lbl("diag_chains"), tags$b(iters_lbl)),
          div(lbl("diag_rhat"),
              tags$b(style = sprintf("color:%s", if (s$rhat_ok) LAB_COLORS$a3 else LAB_COLORS$a1),
                     sprintf("%.3f", s$rhat_max))),
          div(lbl("diag_divs"),
              tags$b(style = sprintf("color:%s", if (s$divs_ok) LAB_COLORS$a3 else LAB_COLORS$a1),
                     s$divs))
        )
      ),
      div(style = "margin-bottom:.5rem",
        convergence_badge(s$rhat_ok,
          if (s$rhat_ok) t$cv_badge_rhat_ok
          else sprintf(t$cv_badge_rhat_fail, s$rhat_max)),
        convergence_badge(s$divs_ok,
          if (s$divs_ok) t$cv_badge_divs_ok
          else sprintf(t$cv_badge_divs_fail, s$divs))
      )
    )
  })

  output$convergence_detail <- renderUI({
    req(fit_data()$ok)
    t <- tr()
    if (isTRUE(fit_data()$compact)) {
      return(div(class = "narr-box",
        style = sprintf("border-color:%s;font-size:.67rem", LAB_COLORS$ink2),
        t$cv_compact
      ))
    }
    s <- model_summary_text(fit_data()$fit)
    if (s$rhat_ok && s$divs_ok) {
      div(class = "narr-box", style = sprintf("border-color:%s", LAB_COLORS$a3),
        tags$b(style = sprintf("color:%s", LAB_COLORS$a3), t$cv_ok),
        t$cv_ok_text
      )
    } else {
      problems <- character(0)
      solutions <- character(0)
      if (!s$rhat_ok) {
        problems  <- c(problems,  sprintf(t$cv_rhat_p, s$rhat_max))
        solutions <- c(solutions, t$cv_rhat_s)
      }
      if (!s$divs_ok) {
        problems  <- c(problems,  sprintf(t$cv_divs_p, s$divs))
        solutions <- c(solutions, t$cv_divs_s1)
        solutions <- c(solutions, t$cv_divs_s2)
      }
      div(
        div(class = "narr-box", style = sprintf("border-color:%s", LAB_COLORS$a1),
          tags$b(style = sprintf("color:%s", LAB_COLORS$a1), t$cv_warn_b),
          t$cv_warn_text, tags$br(), tags$br(),
          tags$b(t$cv_probs), tags$br(),
          tags$ul(lapply(problems, tags$li)),
          tags$b(t$cv_sols), tags$br(),
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
    bayesplot::ppc_stat(fit_data()$y, fit_data()$yrep, stat = "mean") + ggtitle(tr()$plt_mean)
  }, bg = LAB_COLORS$panel, res = 110)

  output$ppc_stat_sd <- renderPlot({
    req(fit_data()$ok)
    bayesplot::ppc_stat(fit_data()$y, fit_data()$yrep, stat = "sd") + ggtitle(tr()$plt_sd)
  }, bg = LAB_COLORS$panel, res = 110)

  output$ppc_stat_min <- renderPlot({
    req(fit_data()$ok)
    bayesplot::ppc_stat(fit_data()$y, fit_data()$yrep, stat = "min") + ggtitle(tr()$plt_min)
  }, bg = LAB_COLORS$panel, res = 110)

  output$ppc_stat_max <- renderPlot({
    req(fit_data()$ok)
    bayesplot::ppc_stat(fit_data()$y, fit_data()$yrep, stat = "max") + ggtitle(tr()$plt_max)
  }, bg = LAB_COLORS$panel, res = 110)

  # Family-dependent error plot
  output$ppc_error_narr <- renderUI({
    req(fit_data()$ok)
    t   <- tr()
    fam <- get_fam(fit_data())
    has_re <- if (!isTRUE(fit_data()$compact) && !is.null(fit_data()$fit))
               length(lme4::findbars(fit_data()$fit$formula$formula)) > 0
             else FALSE
    re_note <- if (has_re) tagList(tags$br(), tags$br(), tags$b(t$en_re_b), t$en_re) else NULL

    if (fam %in% c("poisson", "negbinomial", "zero_inflated_poisson",
                   "zero_inflated_negbinomial", "hurdle_poisson")) {
      tagList(
        tags$b(t$en_root_b), t$en_root,
        tags$br(), tags$br(),
        if (grepl("zero_inflated|hurdle", fam))
          tagList(tags$b(t$en_zi_b), t$en_zi)
        else
          tagList(tags$b(t$en_pois_b), t$en_pois),
        re_note
      )
    } else if (fam %in% c("bernoulli", "binomial")) {
      tagList(tags$b(t$en_calib_b), t$en_calib, re_note)
    } else if (fam %in% c("beta")) {
      tagList(tags$b(t$en_beta_b), t$en_beta, re_note)
    } else if (fam %in% c("Gamma", "lognormal", "weibull")) {
      tagList(tags$b(t$en_log_b), t$en_log, re_note)
    } else if (fam %in% c("cumulative", "cratio", "sratio", "acat")) {
      tagList(tags$b(t$en_ord_b), t$en_ord, re_note)
    } else {
      tagList(tags$b(t$en_res_b), t$en_res, re_note)
    }
  })

  output$ppc_error_plot <- renderPlot({
    req(fit_data()$ok)
    t   <- tr()
    fam <- get_fam(fit_data())
    if (fam %in% c("poisson", "negbinomial", "zero_inflated_poisson", "hurdle_poisson")) {
      bayesplot::ppc_rootogram(fit_data()$y, fit_data()$yrep)
    } else if (fam %in% c("bernoulli", "binomial")) {
      bayesplot::ppc_error_binned(fit_data()$y, fit_data()$yrep[1:50,])
    } else if (fam %in% c("beta", "Gamma", "lognormal")) {
      bayesplot::ppc_dens_overlay(log1p(fit_data()$y), log1p(fit_data()$yrep[1:50,])) +
        ggplot2::xlab(t$plt_log_x) + ggplot2::ggtitle(t$plt_log_t)
    } else if (fam %in% c("cumulative", "cratio", "sratio", "acat")) {
      bayesplot::ppc_bars(fit_data()$y, fit_data()$yrep)
    } else {
      bayesplot::ppc_error_hist(fit_data()$y, fit_data()$yrep[1:25,])
    }
  }, bg = LAB_COLORS$panel, res = 110)

  # ── PIT-ECDF ──────────────────────────────────────────
  output$ppc_pit <- renderPlot({
    req(fit_data()$ok)
    t <- tr()
    tryCatch(
      bayesplot::ppc_pit_ecdf(fit_data()$y, fit_data()$yrep, prob = 0.99),
      error = function(e) {
        ggplot() +
          annotate("text", x=.5, y=.5,
                   label=paste(t$pit_na_err, conditionMessage(e)),
                   color=LAB_COLORS$a1, size=4, family="mono") +
          theme_void() +
          theme(plot.background=element_rect(fill=LAB_COLORS$panel, color=NA))
      }
    )
  }, bg = LAB_COLORS$panel, res = 110)

  output$ppc_pit_eval <- renderUI({
    req(fit_data()$ok)
    t    <- tr()
    y    <- fit_data()$y
    yrep <- fit_data()$yrep
    pit  <- tryCatch(
      sapply(seq_len(length(y)), function(i) mean(yrep[,i] <= y[i])),
      error = function(e) NULL
    )
    if (is.null(pit)) return(div(class="narr-box", t$pit_na))

    ks  <- tryCatch(ks.test(pit, "punif")$statistic, error=function(e) NA)
    ok  <- !is.na(ks) && ks < 0.06
    bd  <- !is.na(ks) && ks >= 0.06 && ks < 0.12
    col <- if(ok) LAB_COLORS$a3 else if(bd) LAB_COLORS$a4 else ACCENT
    lbl <- if(ok) t$pit_ok else if(bd) t$pit_border else t$pit_warn

    div(class="narr-box", style=paste0("border-color:",col),
      tags$b(style=paste0("color:",col), lbl),
      if(!is.na(ks)) tagList(tags$br(), sprintf(t$pit_ks, ks)),
      tags$br(), tags$br(),
      tags$b(t$pit_rem_b), t$pit_rem,
      tags$br(),
      div(style=paste0("font-size:.7rem;color:",LAB_COLORS$ink2,
                       ";border-top:1px solid ",LAB_COLORS$grid,
                       ";padding-top:.35rem;margin-top:.35rem"),
        tags$b(t$pit_cav_b), t$pit_cav
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

    t <- tr()
    div(style = "margin-top:.5rem",
      div(class = "narr-box",
        style = sprintf("border-color:%s", if (ok) LAB_COLORS$a3 else ACCENT),
        tags$b(style = sprintf("color:%s", if (ok) LAB_COLORS$a3 else ACCENT),
               if (ok) t$dens_ok else t$dens_warn),
        tags$br(),
        if (ok) t$dens_ok_t
        else sprintf(t$dens_warn_t, obs_mean, mean(sim_means), sd(sim_means))
      )
    )
  })

  output$ppc_stats_eval <- renderUI({
    req(fit_data()$ok)
    t    <- tr()
    l    <- lang()
    y    <- fit_data()$y
    yrep <- fit_data()$yrep

    stats <- list(
      list(name = t$st_mean, fn = mean, label = t$st_mean_l),
      list(name = t$st_sd,   fn = sd,   label = t$st_sd_l),
      list(name = t$st_min,  fn = min,  label = t$st_min_l),
      list(name = t$st_max,  fn = max,  label = t$st_max_l)
    )

    evals <- lapply(stats, function(s) {
      p  <- bayes_pval(yrep, y, s$fn)
      ev <- eval_pval(p, s$label, l)
      div(class = "summary-row",
        span(s$name),
        span(sprintf("p = %.2f", p)),
        span(style = sprintf("color:%s;font-size:.65rem", ev$color), ev$rating)
      )
    })

    div(style = "margin-top:.5rem",
      div(class = "narr-box",
        tags$b(t$st_heading), tags$br(),
        do.call(div, evals),
        tags$br(), t$st_remind
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

    t <- tr()
    col_cov <- if (ok) LAB_COLORS$a3 else if (cov < 0.82) ACCENT else LAB_COLORS$a4
    div(style = "margin-top:.5rem",
      div(class = "narr-box",
        style = sprintf("border-color:%s", col_cov),
        tags$b(sprintf(t$iv_cov, cov * 100)),
        tags$br(),
        tags$span(style = sprintf("color:%s", col_cov),
          if (ok) t$iv_ok else if (cov < 0.82) t$iv_low else t$iv_high
        )
      )
    )
  })

  output$ppc_grouped_section <- renderUI({
    req(fit_data()$ok)
    t <- tr()
    dat <- if (!isTRUE(fit_data()$compact)) fit_data()$fit$data else fit_data()$grp_data
    if (is.null(dat)) return(NULL)
    groups <- names(dat)[sapply(dat, function(x) is.factor(x) | is.character(x))]
    if (length(groups) == 0) return(NULL)

    div(style = "margin-top:1rem",
      div(class = "station-lbl", t$sta4b2_lbl),
      div(class = "narr-box", tags$b(t$grp_b), t$grp_t),
      selectInput("group_var", t$grp_lbl, choices = groups),
      div(class = "plot-wrap", plotOutput("ppc_grouped", height = "380px"))
    )
  })

  output$ppc_grouped <- renderPlot({
    req(fit_data()$ok, input$group_var)
    dat   <- if (!isTRUE(fit_data()$compact)) fit_data()$fit$data else fit_data()$grp_data
    req(!is.null(dat))
    group <- dat[[input$group_var]]
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

    t <- tr()
    ok_v  <- function(p) p > 0.05 & p < 0.95
    overall_col <- if (n_warn == 0) LAB_COLORS$a3 else if (n_warn <= 1) LAB_COLORS$a4 else ACCENT
    overall_lbl <- if (n_warn == 0) t$ov_ok
                   else if (n_warn == 1) t$ov_one
                   else sprintf(t$ov_many, n_warn)

    div(
      div(class = "narr-box",
        style = sprintf("border-color:%s;font-size:.72rem", overall_col),
        tags$b(style = sprintf("color:%s", overall_col), overall_lbl),
        tags$br(), tags$br(),
        div(class = "summary-row", span(t$st_mean), span(""), span(style = sprintf("color:%s", if(ok_v(p_mean)) LAB_COLORS$a3 else ACCENT), if(ok_v(p_mean)) t$ov_ok_v else sprintf(t$ov_warn_v, p_mean))),
        div(class = "summary-row", span(t$ov_sd),   span(""), span(style = sprintf("color:%s", if(ok_v(p_sd))   LAB_COLORS$a3 else ACCENT), if(ok_v(p_sd))   t$ov_ok_v else sprintf(t$ov_warn_v, p_sd))),
        div(class = "summary-row", span(t$ov_mm),   span(""), span(style = sprintf("color:%s", if(ok_v(p_min)&ok_v(p_max)) LAB_COLORS$a3 else ACCENT), if(ok_v(p_min)&ok_v(p_max)) t$ov_ok_v else t$ov_warn_p)),
        div(class = "summary-row", span(t$ov_cov),  span(sprintf("%.0f%%", cov*100)), span(style = sprintf("color:%s", if(abs(cov-0.9)<0.08) LAB_COLORS$a3 else ACCENT), if(abs(cov-0.9)<0.08) t$ov_cov_ok else t$ov_cov_w))
      )
    )
  })

  output$next_steps <- renderUI({
    req(fit_data()$ok)
    t    <- tr()
    y    <- fit_data()$y
    yrep <- fit_data()$yrep
    fam  <- get_fam(fit_data())

    p_sd  <- bayes_pval(yrep, y, sd)
    p_max <- bayes_pval(yrep, y, max)
    lo    <- apply(yrep, 2, function(x) quantile(x, 0.05))
    hi    <- apply(yrep, 2, function(x) quantile(x, 0.95))
    cov   <- mean(y >= lo & y <= hi)

    suggestions <- list()
    if (p_sd < 0.05)               suggestions <- c(suggestions, list(list(title = t$ns_sd_t,  text = t$ns_sd_x)))
    if (p_max > 0.95 && fam == "gaussian") suggestions <- c(suggestions, list(list(title = t$ns_max_t, text = t$ns_max_x)))
    if (cov < 0.82)                suggestions <- c(suggestions, list(list(title = t$ns_cov_t, text = t$ns_cov_x)))

    if (length(suggestions) == 0) {
      div(class = "narr-box",
        style = sprintf("border-color:%s", LAB_COLORS$a3),
        tags$b(style = sprintf("color:%s", LAB_COLORS$a3), t$ns_nob),
        tags$br(), t$ns_no
      )
    } else {
      div(
        div(style = sprintf("color:%s;font-size:.68rem;margin-bottom:.5rem", LAB_COLORS$ink2), t$ns_intro),
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
      dat <- if (!isTRUE(fit_data()$compact)) fit_data()$fit$data else fit_data()$grp_data
      if (is.null(dat)) return(NULL)
      groups <- names(dat)[sapply(dat, function(x) is.factor(x) | is.character(x))]
      if (length(groups) > 0)
        selectInput("free_group", tr()$p5_group, choices = groups)
    }
  })

  output$free_stat_ui <- renderUI({
    req(fit_data()$ok)
    if (input$free_plot_type == "ppc_stat" ||
        input$free_plot_type == "ppc_stat_grouped") {
      selectInput("free_stat", tr()$p5_stat,
        choices = c("mean", "sd", "median", "min", "max", "var"))
    }
  })

  output$free_plot_explanation <- renderUI({
    req(input$free_plot_type)
    t <- tr()
    expl_map <- list(
      ppc_dens_overlay = t$xpl_dens, ppc_ecdf_overlay = t$xpl_ecdf,
      ppc_hist = t$xpl_hist, ppc_stat = t$xpl_stat, ppc_stat_grouped = t$xpl_statg,
      ppc_intervals = t$xpl_intv, ppc_ribbon = t$xpl_rib,
      ppc_scatter_avg = t$xpl_scat, ppc_error_hist = t$xpl_errh,
      ppc_rootogram = t$xpl_root, ppc_pit_ecdf = t$xpl_pit
    )
    expl <- expl_map[[input$free_plot_type]]
    if (!is.null(expl)) div(class = "narr-box", style = "margin-top:.5rem", expl)
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
          dat_free <- if (!isTRUE(fit_data()$compact)) fit_data()$fit$data else fit_data()$grp_data
          req(!is.null(dat_free))
          grp <- dat_free[[input$free_group]]
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
