# MARS-ED Study Interface

![Example](/uploads/8b27ec222d436badb9eedc327af4bcdb/image.png)

The **MARS-ED (Machine Learning for Rapid Risk Stratification in the Emergency Department)** study interface is a Shiny application developed to support real-time risk stratification and structured data collection in the MARS-ED randomized controlled trial. The tool displays the **RISKINDEX**, a machine learning–derived 31-day mortality prediction score based on routine laboratory tests, age, and sex. The application is implemented using **R** and **Shiny**, packaged with **Docker** for reproducible deployment, and optionally connects to the local Laboratory Information System (LIS) when used inside hospital infrastructure.

> **Reference to the study:**  
> van Dam P.M.E.L., van Doorn W.P.T.M., et al. *Machine learning for risk stratification in the emergency department (MARS-ED): a randomized controlled trial.*  
> Currently under submission.

## Table of Contents
- About the Application
- Prerequisites
- Installation
- Usage
- Data Privacy and Security
- License
- Acknowledgements

## About the Application

This interface was developed as part of the **MARS-ED randomized controlled trial** to evaluate the accuracy, feasibility, and clinical impact of the RISKINDEX when integrated into routine ED workflows. The interface provides:

- A calibrated probability display of the RISKINDEX (0–100% mortality risk)  
- Structured collection of clinical intuition assessments  
- Recording of physician alignment with the model output  
- Optional linkage to the LIS for real-time laboratory retrieval  

The interface was used by internal medicine physicians during the trial and is released to support transparency, reproducibility, and further development.

## Prerequisites

Before running the application, ensure the following:

- Docker (required): https://www.docker.com/get-started  
- Git (optional) for cloning the repository

## Installation

1. Clone the repository
   ```
   git clone https://gitlab.maastrichtuniversity.nl/centraal-diagnostisch-laboratorium/mars-ed-study-interface.git
   ```

2. Navigate to the directory
   ```
   cd mars-ed-study-interface
   ```

3. Build the Docker image
   ```
   docker build -t mars-ed .
   ```

## Usage

1. Run the Docker container
   ```
   docker run -d -p 3838:3838 --name mars-ed-app mars-ed
   ```

2. Open in browser  
   http://localhost:3838  

3. Stop and remove the container
   ```
   docker stop mars-ed-app && docker rm mars-ed-app
   ```

## Data Privacy and Security

- Intended for deployment within secure hospital networks  
- LIS connections access identifiable clinical data under GDPR  
- Use synthetic data for development or demonstration  
- No patient data stored inside the Docker container

## License

This project is distributed under the **MIT License**.  
See the LICENSE file for details.

## Acknowledgements

- R for statistical computing  
- Shiny for the web framework  
- Docker for reproducible deployment  
- MARS-ED research team, ED physicians, and medical students  
- Authors of all R packages used in this interface  
