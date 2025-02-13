# Argo CD

[Argo CD](https://argo-cd.readthedocs.io/en/stable/) is our declarative GitOps continuous delivery tool for Kubernetes. It automatically synchronizes the desired state stored in Git with the live state running in our clusters.

## Overview

-   **Declarative Deployment:** Manage Kubernetes deployments through Git repositories.
-   **Real-time Sync:** Automatically detect configuration drift and initiate synchronization.
-   **User-friendly Dashboard:** Provides a clear view of application health, sync status, and history.

## Getting Started

1. **Access the Dashboard:**  
   [Go to the Argo CD Dashboard](https://argocd.zid-internal.com)
2. **Log In:**  
   Use your GitHub credentials to log in. If you don't have access, reach out in `#tech-team` on discord.
3. **Deploy an Application:**
    - Choose an application from the dashboard.
    - Click the **Sync** button to apply any changes.
4. **Monitor Deployments:**  
   Check the status and logs directly from the UI to ensure your application is running as expected.

## Troubleshooting

-   **Sync Failures:**  
    Check the application logs in the dashboard for error details.
-   **Drift Detection:**  
    Use the visual diff tool in Argo CD to identify and resolve any differences between Git and the live state.

## Additional Resources

-   [Argo CD Official Documentation](https://argo-cd.readthedocs.io/)
-   [GitOps Principles](https://argo-cd.readthedocs.io/en/latest/user-guide/best_practices/)
