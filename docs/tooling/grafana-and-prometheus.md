# Grafana and Prometheus

Our monitoring stack leverages [Prometheus](https://prometheus.io) for metrics collection and [Grafana](https://grafana.com/) for visualization, giving us deep insight into system performance and application health.

## Overview

-   **Prometheus:**  
    An open-source systems monitoring and alerting toolkit. It scrapes metrics from configured endpoints and stores them as time series data.
-   **Grafana:**  
    A feature-rich open-source dashboard and graph editor that lets you query, visualize, and alert on your metrics.

## Getting Started

### Accessing the Dashboard

[Go to Grafana Dashboard](https://metrics.zid-internal.com). You can log in using your GitHub credentials.

### Key Features

-   **Pre-built Dashboards:**  
    Explore dashboards tailored to our environment.
-   **Custom Queries:**  
    Use Grafana’s query editor to build ad-hoc queries.
-   **Alerting:**  
    Configure alerts to be notified of potential issues.

## Troubleshooting

-   **No Data Displayed:**  
    Confirm that Prometheus is properly scraping the intended targets.
-   **Dashboard Issues:**  
    Check that the data sources in Grafana are correctly configured.
-   **Alerting Problems:**  
    Verify the alert rules and ensure they match your desired thresholds.

## Additional Resources

-   [Prometheus Documentation](https://prometheus.io/docs/)
-   [Grafana Documentation](https://grafana.com/docs/)
