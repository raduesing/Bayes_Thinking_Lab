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

<div id="credits" style="padding: 40px; background: #f8f3e8; color: #18130e; border: 1px solid #d1c9b8; border-radius: 4px; font-family: 'Segoe UI', Helvetica, Arial, sans-serif;">
    
    <h2 style="text-align: center; border-bottom: 1.5px solid #18130e; padding-bottom: 10px; margin-bottom: 25px; color: #18130e; font-weight: 600;">Scientific Acknowledgments</h2>
    
    <p style="text-align: center; color: #5a4f42; margin-bottom: 35px; font-size: 0.95em;">
        The development of the Bayes Thinking Lab is based on the pedagogical and methodological frameworks established by the following authors and researchers:
    </p>

    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; line-height: 1.5;">
        
        <div style="padding: 20px; border: 1px solid #e0d8c0; background: #ffffff;">
            <strong style="display: block; margin-bottom: 8px; font-size: 1.05em; color: #18130e;">John K. Kruschke</strong>
            <span style="font-size: 0.9em; color: #18130e;">The visual representation of models in this lab is based on the "Kruschke Diagrams" introduced in <em>Doing Bayesian Data Analysis</em>.</span><br>
            <a href="https://doingbayesiandataanalysis.blogspot.com/" style="color: #2a6e8a; text-decoration: underline; font-size: 0.85em; display: inline-block; margin-top: 10px;">Institutional Page</a>
        </div>

        <div style="padding: 20px; border: 1px solid #e0d8c0; background: #ffffff;">
            <strong style="display: block; margin-bottom: 8px; font-size: 1.05em; color: #18130e;">Richard McElreath</strong>
            <span style="font-size: 0.9em; color: #18130e;">The integration of model architectures and the <em>brms</em>-workflow is informed by the principles outlined in <em>Statistical Rethinking</em>.</span><br>
            <a href="https://github.com/rmcelreath" style="color: #2a6e8a; text-decoration: underline; font-size: 0.85em; display: inline-block; margin-top: 10px;">Institutional Page</a>
        </div>

        <div style="padding: 20px; border: 1px solid #e0d8c0; background: #ffffff;">
            <strong style="display: block; margin-bottom: 8px; font-size: 1.05em; color: #18130e;">A. Solomon Kurz</strong>
            <span style="font-size: 0.9em; color: #18130e;">Credit is given to his comprehensive translations of statistical textbooks into the <em>brms</em> and tidyverse computational framework.</span><br>
            <a href="https://solomonkurz.netlify.app/" style="color: #2a6e8a; text-decoration: underline; font-size: 0.85em; display: inline-block; margin-top: 10px;">Project Documentation</a>
        </div>

        <div style="padding: 20px; border: 1px solid #e0d8c0; background: #ffffff;">
            <strong style="display: block; margin-bottom: 8px; font-size: 1.05em; color: #18130e;">Paul-Christian Bürkner</strong>
            <span style="font-size: 0.9em; color: #18130e;">Computational compatibility is maintained with the R package <em>brms</em>, developed for high-level Bayesian regression modeling.</span><br>
            <a href="https://paul-buerkner.github.io/" style="color: #2a6e8a; text-decoration: underline; font-size: 0.85em; display: inline-block; margin-top: 10px;">brms Project Site</a>
        </div>

    </div>

    <div style="margin-top: 30px; text-align: center; font-size: 0.8em; color: #8a7f72; border-top: 1px solid #e0d8c0; padding-top: 15px;">
        Licensing: MIT License. All references belong to their respective copyright holders.
    </div>
</div>

---

## 🎓 Citation

If you use the **Bayes Thinking Lab** for your research, teaching, or software development, please cite it as follows:

<div align="left">

### APA Style
> Düsing, R. (2024). *Bayes Thinking Lab: An interactive suite for Bayesian intuition and brms workflow* (Version 0.6). GitHub. https://github.com/raduesing/Bayes_Thinking_Lab

 
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
