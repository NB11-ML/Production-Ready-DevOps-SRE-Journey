# DevOps & SRE Fundamentals

DevOps and Site Reliability Engineering (SRE) bridge the gap between software development and IT operations. They accelerate delivery while ensuring system stability.

## Core Theory & Philosophy

* **DevOps Definition**: A cultural and technical movement unifying software development (Dev) and IT operations (Ops).
* **SRE Definition**: Google's specific implementation of DevOps, treating operations as a software engineering problem.
* **The Goal**: Deliver high-quality software faster while maintaining system reliability and uptime.
* **The Wall of Confusion**: Traditional siloed teams caused friction, slow deployments, and blame-shifting.

## The DevOps Lifecycle

The DevOps lifecycle is continuous, often visualized as an infinity loop.

1. **Plan**: Defining business requirements, project metrics, and tracking tasks.
2. **Code**: Writing software, refactoring, and managing source control.
3. **Build**: Compiling code and creating deployable artifacts.
4. **Test**: Running automated scripts to ensure code quality.
5. **Release**: Preparing artifacts for production deployment.
6. **Deploy**: Pushing code changes to the live infrastructure.
7. **Operate**: Managing environment configurations and maintaining system availability.
8. **Monitor**: Collecting logs and metrics to track performance.

   <img width="1418" height="752" alt="image" src="https://github.com/user-attachments/assets/ee633886-ff90-4b96-b60c-7e7d61325201" />


## Culture & Practices

Culture is the foundation of successful DevOps and SRE adoption.

* **Shared Responsibility**: Development and operations teams share ownership of product success and failure.
* **Blameless Postmortems**: Focus on fixing system flaws instead of punishing human mistakes.
* **Automation**: Eliminating repetitive, manual tasks to save time and reduce human error.
* **SRE Golden Signals**: Monitoring latency, traffic, errors, and saturation to track system health.

### SLO, SLA, SLI
* **SLI (Indicator)**: Metric showing current performance (e.g., error rate).
* **SLO (Objective)**: Target goal for the metric (e.g., under 0.1% errors).
* **SLA (Agreement)**: Business contract promising specific uptime to users.
* **Error Budget**: The acceptable amount of system downtime or errors allowed before deployment stops.

## CI/CD Basics

Continuous Integration and Continuous Deployment form the technical backbone of DevOps.

* **Continuous Integration (CI)**: Developers frequently merge code into a central repository, triggering automated builds and tests.
* **Continuous Delivery (CD)**: Automated deployment of tested code to staging or testing environments.
* **Continuous Deployment (CD)**: Automated, direct deployment of validated code straight to production.
* **Key Benefits**: Faster time-to-market, smaller code changes, and immediate feedback loops.
