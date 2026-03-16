Interactive Learning Tool
Bayesian Statistics
Educational Project

# Bayes Thinking Lab

<p align="center">
  <img src="ChatGPT Image 17. März 2026, 00_12_14.png" width="900">
</p>

**Interactive tools for understanding, visualizing, and applying Bayesian statistics.**

The **Bayes Thinking Lab** is a collection of interactive web tools designed to make statistical concepts visually intuitive and conceptually clear. The project is intended for students, teachers, and researchers who want to **understand Bayesian models rather than just apply them**.

The lab connects three perspectives:

* visual model representations
* mathematical notation (in the spirit of McElreath-style model descriptions)
* practical implementation using **R and brms**

---

# Project Motivation

Learning Bayesian statistics can be challenging for several reasons:

* many concepts are abstract
* models appear mathematically complex
* statistical software hides the underlying mechanics

The **Bayes Thinking Lab** addresses these challenges through three guiding principles.

### 1. Intuition before formalism

Concepts are first introduced visually and conceptually before formal mathematical expressions are emphasized.

### 2. Diagrams and mathematics together

Each tool combines

* graphical representations of statistical models
* explicit mathematical notation

This helps users connect intuition with formal model definitions.

### 3. Direct path to practical modeling

The workflow tools generate **actual `brms` code**, allowing users to directly translate conceptual models into applied Bayesian analysis.

---

# Target Audience

The project is designed for multiple levels of statistical experience:

* undergraduate students learning statistics
* graduate students working with regression or Bayesian models
* PhD students and researchers
* instructors teaching regression, GLMs, or Bayesian methods

Fields where the tools are particularly relevant include:

* psychology
* social sciences
* medicine and health sciences
* applied data science

---

# Structure of the Lab

The Bayes Thinking Lab follows a structured learning path.

---

## 0 — Statistical Foundations

Interactive tools introducing core statistical ideas before Bayesian modeling.

Examples include:

* **Interactive Linear Model Tool**
  Explore regression by manually adjusting model parameters and observing residuals.

* **Maximum Likelihood Explorer**
  Visualize likelihood functions and understand how MLE identifies parameter estimates.

* **From LM to GLM**
  Demonstrates why linear models fail for binary or count data.

---

## I — From Linear Models to GLMMs

These tools extend classical regression models.

Topics include:

* conditional distributions in GLMs
* geometric interpretation of GLMs
* **interactive GLMMs and partial pooling**

The goal is to develop a clear understanding of modern regression structures before introducing Bayesian inference.

---

## II — Bayesian Intuition

This section introduces the logic of Bayesian inference.

Tools include:

* **Bayesian Thinking Simulator**
  Multiple scenarios illustrating belief updating through data.

* **Prior Lab**
  Interactive exploration of prior distributions, including credible interval calculations.

* **MCMC Visualizer**
  Animated explanation of the Metropolis-Hastings algorithm.

* **Interactive Bayes**
  Visualization of prior, likelihood, and posterior relationships.

---

## III — Bayesian Modeling Workflow

The final section focuses on practical model building.

The workflow includes:

1. **Model Architect**
   Visual design of a statistical model.

2. **brms Model Builder**
   Interactive generator for `brms` model code.

3. **Prior Predictive Checks**
   Simulation of model predictions before observing data.

4. **Posterior Predictive Checks**
   Model validation after fitting.

---

# Example Workflow

A typical modeling workflow using the Bayes Thinking Lab:

1. Define the model structure in **Model Architect**
2. Configure priors and model components using the **brms Model Builder**
3. Perform **prior predictive checks**
4. Fit the model in **R using brms**
5. Evaluate model fit with **posterior predictive checks**

---

# Technologies

The project uses:

* HTML
* CSS
* JavaScript
* interactive browser visualizations
* R
* brms
* Stan
* Shiny (for selected tools)

---

# Usage

Most tools are **browser-based applications**.

To explore the lab:

1. Clone or download the repository
2. Open `index.html` in your browser

Some tools link to external Shiny applications.

---

# Teaching Context

The Bayes Thinking Lab was developed for:

* university statistics courses
* Bayesian methods courses
* workshops on regression and multilevel models
* self-study

It is particularly useful for courses covering:

* regression analysis
* generalized linear models
* multilevel models
* Bayesian statistics

---

# Repository

GitHub repository:

https://github.com/raduesing/Bayes_Thinking_Lab

---

# License

Open source.
See the LICENSE file for details.

---

# Author

Rainer Düsing

