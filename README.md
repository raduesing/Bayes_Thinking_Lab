<p align="center">
  <img src="images/ChatGPT Image 17. März 2026, 00_12_14.png" width="900">
</p>

<div align="center">

# Bayes Thinking Lab `v0.6`
### Statistical Intuition, Reimagined.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Static Badge](https://img.shields.io/badge/Status-Academic_Project-blue)]()
[![Static Badge](https://img.shields.io/badge/Tech-Vanilla_JS-orange)]()

**A comprehensive, interactive suite designed to bridge the gap between frequentist foundations and Bayesian multi-level modeling.**

[ [Explore the Lab](#-the-ecosystem) ] • [ [Philosophy](#-scientific-philosophy) ] • [ [Usage](#-getting-started) ] • [ [GitHub Repository](https://github.com/raduesing/Bayes_Thinking_Lab) ]

---

</div>

## 🔭 Scientific Philosophy

The **Bayes Thinking Lab (BTL)** moves away from the "black-box" approach of statistical software. Inspired by the pedagogical works of **John Kruschke** and **Richard McElreath**, this project emphasizes:

* **Visual Proofs:** Concepts like *Partial Pooling* and *Link Functions* become tangible through real-time manipulation.
* **The Formula-Graphic Duality:** Every model is simultaneously represented as a **Kruschke-style DAG** and in **McElreath-style mathematical notation**.
* **Workflow Integration:** Beyond simple demos, the lab functions as a productivity tool by generating production-ready `brms` code for R.

---

## 🛠 The Ecosystem

The lab is structured into four logical modules that guide users from undergraduate basics to advanced research-level modeling.

### 0. Statistical Foundations
*The prerequisite for Bayesian thinking: mastering the GLM.*
* **Interactive LM:** Experience OLS minimization and residuals manually.
* **Maximum Likelihood:** Grasp the critical distinction between Probability and Likelihood.
* **LM to GLM Transition:** Understand why link functions are necessary for non-normal data.

### I. From LM to GLMM
*Scaling the hierarchy of linear modeling.*
* **Conditional Distributions:** Visualize $y|x$ along a predictor — the heart of every GLM.
* **GLM in 3D:** Interact with regression planes and residuals in a spatial environment.
* **Interactive GLMM:** Compare *Complete Pooling*, *No Pooling*, and *Partial Pooling*.

### II. Bayesian Intuition
*Learning to think in probability distributions.*
* **Thinking Simulator:** 8 psychological scenarios to build qualitative updating skills without math.
* **Prior Lab:** Translate verbal uncertainty into mathematical parameters with a real-time CI-solver.
* **MCMC Visualizer:** Watch the "animated hiker" (Metropolis-Hastings) sample from the posterior.
* **Bayes Interactive:** Watch how priors, sample size togehter with the data form the posterior.

### III. Bayesian Workflow
*Tools for the professional scientist.*
* **Model Architect:** Visually build hierarchical structures in Kruschke style and with McElreath notation.
* **brms Model Builder:** A powerful R-code generator to build complex hierarchical models and transfer to prior checks.
* **Prior Predictive Checks:** Import and Validate your models via Prior Predictive Checking.
* **Posterior Predictive Checks:** Specialized ShinyApp to check your brms results and get feedback.

---

## 🚀 Getting Started

The Bayes Thinking Lab is a **serverless web application**. No installation, no backend, and no data leaves your machine.

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/raduesing/Bayes_Thinking_Lab.git]
    (https://github.com/raduesing/Bayes_Thinking_Lab.git)
    ```
2.  **Open `index.html`** in any modern web browser.
3.  **Start Building:** Design your model, configure your priors, and copy the generated `brms` code into your R script.

---

## 🎓 Target Audience

| Level | Recommended Tools |
| :--- | :--- |
| **BSc. Students** | Interactive LM, Bayes Simulator, GLM Basics |
| **MSc. Students** | Interactive GLMM, Prior Lab, MCMC Visualizer |
| **PhD / Researchers** | Model Architect, brms Builder, Posterior PPC |

---

## 🖋 Scientific Acknowledgments

The development of the **Bayes Thinking Lab** is based on the pedagogical and methodological frameworks established by the following researchers. Their work has been instrumental in shaping the conceptual logic of this suite:

| Author | Framework / Contribution | Resource |
| :--- | :--- | :--- |
| **John K. Kruschke** | The visual model representations are based on the "Kruschke Diagrams" introduced in *Doing Bayesian Data Analysis*. | [Institutional Page](https://doingbayesiandataanalysis.blogspot.com/) |
| **Richard McElreath** | The integration of model architectures and the Bayesian workflow is informed by the principles in *Statistical Rethinking*. | [Institutional Page](https://github.com/rmcelreath) |
| **A. Solomon Kurz** | Acknowledgment is given to his comprehensive translations of statistical textbooks into the *brms* and *tidyverse* framework. | [Project Documentation](https://solomonkurz.netlify.app/) |
| **Paul-Christian Bürkner** | Computational compatibility is maintained with the R package *brms*, developed for high-level Bayesian regression modeling. | [brms Project Site](https://paul-buerkner.github.io/) |

> **Note on Licensing:** This project is released under the MIT License. All external references and conceptual frameworks belong to their respective copyright holders.

---

## 🎓 Citation

If you use the **Bayes Thinking Lab** for your research, teaching, or software development, please cite it as follows:

<div align="left">

### APA Style
> Düsing, R. (2026). *Bayes Thinking Lab: An interactive suite for Bayesian intuition and brms workflow* (Version 0.6). GitHub. https://github.com/raduesing/Bayes_Thinking_Lab

 
### BibTeX (for LaTeX users)
```latex
@software{Duesing_Bayes_Thinking_Lab_2024,
  author = {Düsing, Rainer},
  title = {{Bayes Thinking Lab: An interactive suite for Bayesian intuition and brms workflow}},
  url = {[https://github.com/raduesing/Bayes_Thinking_Lab](https://github.com/raduesing/Bayes_Thinking_Lab)},
  version = {0.6.0},
  year = {2026}
}

</div>
