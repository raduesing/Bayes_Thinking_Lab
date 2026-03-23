<p align="center">
  <img src="images/ChatGPT Image 17. März 2026, 00_12_14.png" width="900">
</p>

<div align="center">

# Bayes Thinking Lab `v0.7`
### Statistical Intuition, Reimagined.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Static Badge](https://img.shields.io/badge/Status-Academic_Project-blue)]()
[![Static Badge](https://img.shields.io/badge/Tech-Vanilla_JS-orange)]()

**A comprehensive, interactive suite that guides users from frequentist foundations through Bayesian multi-level modeling to principled posterior decision-making.**

[ [Learning Path](#-the-learning-path) ] • [ [Ecosystem](#-the-ecosystem) ] • [ [Philosophy](#-scientific-philosophy) ] • [ [Usage](#-getting-started) ] • [ [GitHub Repository](https://github.com/raduesing/Bayes_Thinking_Lab) ]

---

</div>

## 🔭 Scientific Philosophy

The **Bayes Thinking Lab (BTL)** moves away from the "black-box" approach of statistical software. Inspired by the pedagogical works of **John Kruschke** and **Richard McElreath**, this project emphasizes:

* **Visual Proofs:** Concepts like *Partial Pooling*, *Link Functions*, and *HDI vs. ROPE* become tangible through real-time manipulation.
* **The Formula-Graphic Duality:** Hierarchical models are simultaneously represented as **Kruschke-style diagrams** and in **mathematical notation** consistent with McElreath and brms.
* **Workflow Integration:** Beyond interactive demos, the lab functions as a productivity tool — generating production-ready `brms` code for R and supporting the full Bayesian workflow from prior specification to posterior decision.

---

## 🗺 The Learning Path

The lab is organized into five sections that build on each other. Work through them in order, or jump in wherever your current knowledge begins.

| Section | What you will learn | Key Tools |
| :--- | :--- | :--- |
| **0 · Foundations** | Why the GLM is the gateway to Bayesian thinking | Interactive LM · MLE Tool · LM→GLM Transition |
| **I · GLM & GLMM** | How regression generalizes across distributions and hierarchies | GLM Conditional Distributions · GLM 3D · Interactive GLMM |
| **II · Bayesian Intuition** | How to think in probability distributions and update beliefs from data | Thinking Simulator · Prior Lab · MCMC Visualizer · Bayes Interactive |
| **III · Bayesian Workflow** | How to specify, build, check, and export hierarchical Bayesian models | Model Architect · brms Model Builder · Prior & Posterior Predictive Check |
| **IV · Posterior Decision** | How to make principled, transparent decisions from posterior distributions | Decision Lab · Decision Maker |

> **⬡ Recommended alongside Section III — not obligatory:**
> The **[Golem Builder](Golem_builder.html)** supports causal reasoning via DAGs before model specification. Many workflows do not require DAGs, but when causal questions matter, starting here pays off. See Section III below.

---

## 🛠 The Ecosystem

### 0. Statistical Foundations
*Master the GLM — the prerequisite for Bayesian thinking.*

* **Interactive LM** — Manipulate data points and watch OLS minimization and residuals update in real time. Build intuition for what a regression line actually optimizes.
* **Maximum Likelihood** — Explore the conceptual distinction between probability and likelihood by adjusting parameters interactively against simulated data.
* **LM → GLM Transition** — Discover why link functions are necessary for non-normal outcomes and how the GLM generalizes the linear model across distribution families.

---

### I. From LM to GLMM
*Scale the hierarchy of linear modeling.*

* **GLM Conditional Distributions** — Visualize the conditional distribution y|x along a predictor across **8 model families**: Normal, Student-t, Bernoulli (logistic), Poisson, Gamma, Ordinal (cumulative logit), Zero-Inflated Poisson, and Hurdle-Poisson. Compare parameter behavior and link functions across families.
* **GLM in 3D** — Interact with regression planes and residuals in a spatial environment. Explore how multiple predictors jointly determine the outcome surface.
* **Interactive GLMM** — Simulate grouped data and compare **Complete Pooling**, **No Pooling**, and **Partial Pooling** side by side. Observe Simpson's Paradox, the Intraclass Correlation Coefficient (ICC), and the shrinkage mechanism — for Normal, Poisson, Gamma, and logistic outcomes.

---

### II. Bayesian Intuition
*Learn to think in probability distributions.*

* **Bayesian Thinking Simulator** — Work through 8 psychological scenarios that build qualitative updating intuition without requiring mathematical notation.
* **Prior Lab** — Translate verbal uncertainty statements into mathematical priors. A real-time CI-solver maps your beliefs onto distribution parameters.
* **MCMC Visualizer** — Watch the Metropolis-Hastings sampler navigate the posterior landscape — the "animated hiker" analogy made interactive.
* **Bayes Interactive** — Manipulate prior strength, likelihood, and sample size and see how they jointly shape the posterior. Includes CI and PPI bands for the full posterior predictive.

---

### III. Bayesian Workflow
*Tools for the applied scientist.*

* **Bayesian Model Architect** — Build hierarchical Bayesian model structures visually in Kruschke-diagram style. See how priors, hyperpriors, and random effects (intercepts and slopes: u₀ⱼ, u₁ⱼ, τ₀, τ₁) connect in a live diagram — then generate R simulation code for prior predictive checking.
* **brms Model Builder** — Specify complex hierarchical models step by step across 15+ likelihood families, polynomial terms, interactions, and distributional parameters. Export production-ready `brms` code for R.
* **Prior Predictive Check** — Import your brms model specification, explore the prior predictive distribution, and validate that your priors generate plausible data before fitting.
* **Posterior Predictive Check** — Evaluate model fit and posterior behavior via a dedicated Shiny app with visual diagnostics and feedback.

> **⬡ Recommended: Causal Reasoning with the Golem Builder**
>
> Before specifying your model, consider making your causal assumptions explicit in a DAG. The **[Golem Builder](Golem_builder.html)** lets you draw directed acyclic graphs, compute d-separation and testable implications (compatible with dagitty), identify minimal adjustment sets, detect instrumental variables and front-door criteria, and generate brms simulation code — all in the browser. Causal reasoning is not a required step in the workflow, but when the causal question matters, starting here pays off.

---

### IV. Posterior Decision
*Move from estimation to decision.*

* **Decision Lab** — Apply three principled decision frameworks to any posterior distribution: **Kruschke's HDI vs. ROPE trichotomy** (accept / reject / undecided), **Full ROPE %** (probability of practical equivalence), and **ETI vs. ROPE**. Supports Normal, Student-t, and Gamma posteriors with analytically correct HDI and ETI computation.
* **Decision Maker** — Upload your own posterior samples via CSV, define a Region of Practical Equivalence (ROPE / SESOI), compute HDI and ETI, and export a complete **APA-formatted decision report** — ready to paste into a manuscript.

---

## 🚀 Getting Started

The Bayes Thinking Lab is a **serverless web application**. No installation, no backend, and no data leaves your machine.

1. **Clone the repository:**
    ```bash
    git clone https://github.com/raduesing/Bayes_Thinking_Lab.git
    ```
2. **Open `index.html`** in any modern web browser.
3. **Follow the learning path** — or jump directly to the tool that matches your current need.

> **Tip:** Each tool includes a built-in **ℹ Help panel** and inline explanations for every parameter. Use the Guide in Model Architect and brms Builder for step-by-step walkthroughs.

---

## 🎓 Target Audience

| Level | Recommended Entry Point | Tools to Explore |
| :--- | :--- | :--- |
| **BSc Students** | Section 0 — Foundations | Interactive LM · MLE Tool · Thinking Simulator · Bayes Interactive |
| **MSc Students** | Section I–II | GLM Conditional Distributions · Interactive GLMM · Prior Lab · Model Architect |
| **PhD / Researchers** | Section III–IV | brms Model Builder · Golem Builder · Prior & Posterior P. Check · Decision Maker |

---

## 🖋 Scientific Acknowledgments

The development of the **Bayes Thinking Lab** is grounded in the pedagogical and methodological frameworks established by the following researchers:

| Author | Framework / Contribution | Resource |
| :--- | :--- | :--- |
| **John K. Kruschke** | Graphical model representations follow the Kruschke Diagram conventions from *Doing Bayesian Data Analysis*. | [Blog](https://doingbayesiandataanalysis.blogspot.com/) |
| **Richard McElreath** | Model notation, workflow structure, and prior predictive thinking are informed by *Statistical Rethinking* (Ch. 5–6, 14). | [GitHub](https://github.com/rmcelreath) |
| **A. Solomon Kurz** | Acknowledgment to his brms and tidyverse translations of Kruschke and McElreath, which informed several implementation details. | [Website](https://solomonkurz.netlify.app/) |
| **Paul-Christian Bürkner** | All exported code targets the `brms` R package. Prior notation (class=sd, τ₀, τ₁) follows brms conventions. | [brms](https://paul-buerkner.github.io/) |

> **Note on Licensing:** This project is released under the MIT License. All external references and conceptual frameworks belong to their respective copyright holders.

---

## 🎓 Citation

If you use the **Bayes Thinking Lab** for research, teaching, or software development, please cite it as follows:

<div align="left">

### APA Style
> Düsing, R. (2026). *Bayes Thinking Lab: An interactive suite for Bayesian intuition and brms workflow* (Version 0.7). GitHub. https://github.com/raduesing/Bayes_Thinking_Lab

### BibTeX
```bibtex
@software{Duesing_Bayes_Thinking_Lab_2026,
  author  = {Düsing, Rainer},
  title   = {{Bayes Thinking Lab: An interactive suite for Bayesian intuition and brms workflow}},
  url     = {https://github.com/raduesing/Bayes_Thinking_Lab},
  version = {0.7.0},
  year    = {2026}
}
```

</div>
