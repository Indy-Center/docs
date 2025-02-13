# Deploying Applications

This guide walks you through the process of deploying applications to our Kubernetes cluster using our GitOps workflow.

{% set k8s_guide_path = './accessing-kubernetes.md' %}
{% include 'kubernetes-access.md' %}

## Overview

We follow GitOps principles for all deployments, which means:

1. All infrastructure configuration lives in our [infrastructure repository](https://github.com/indy-center/infrastructure)
2. Changes are made through pull requests
3. Argo CD automatically syncs approved changes to the cluster

You can deploy any application that has a container image - it doesn't have to be something we built! Common examples include:

-   Your own applications built and published to [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
-   Official images from [Docker Hub](https://hub.docker.com/)
-   Helm charts from public repositories
-   Third-party applications with container support

<!-- prettier-ignore-start -->
!!! tip "Need a Database?"
    Check out [Guide: PostgreSQL with CloudNativePG](../guides/postgres-database-cnpg.md) to provision a managed database for your application.
<!-- prettier-ignore-end -->

## App of Apps Pattern

We use Argo CD's [App of Apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern) to manage all applications in our cluster. This means:

1. A root application (`root-application.yaml`) in the `apps/` directory manages all other applications
2. Each application directory must include an `application.yaml` to be picked up by the root application
3. Applications are automatically synced when changes are merged to the main branch

### Root Application

The `root-application.yaml` serves as our App of Apps.

### Application Requirements

Each application in the `apps/` directory must:

1. Have a unique name that matches its directory name
2. Include an `application.yaml` file with:
    - Correct namespace (`argocd`)
    - Proper source path pointing to the application directory
    - Appropriate destination namespace (`production` or `development`)
    - Automated sync policy configuration
3. Follow our standard directory structure:
    ```
    apps/
    ├── your-app/
    │   ├── application.yaml    # Required: Argo CD application definition
    │   ├── deployment.yaml     # Your application's deployment
    │   ├── service.yaml        # Service configuration
    │   ├── ingress.yaml        # Ingress configuration
    │   └── kustomization.yaml  # Optional: If using Kustomize
    ```

<!-- prettier-ignore-start -->
!!! info "Alternative Structures"
    This folder can also follow [Helm](https://helm.sh/) or [Kustomize](https://kustomize.io/) structures. Check out their respective documentation for more details:
    
    - [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
    - [Kustomize Examples](https://github.com/kubernetes-sigs/kustomize/tree/master/examples)
<!-- prettier-ignore-end -->

## Deployment Process

### 1. Prepare Your Application

Your application should:

-   Be containerized with a [Dockerfile](https://docs.docker.com/engine/reference/builder/)
-   Have container images published to our registry ([Indy-Center on GitHub](https://github.com/orgs/Indy-Center/packages))
-   Include [health checks and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/), and [resource requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).

### 2. Create Kubernetes Manifests

<!-- prettier-ignore-start -->
!!! warning "Example Manifests"
    There is a good chance this documentation is out of date.

    You can view the [Kubernetes Documentation](https://kubernetes.io/docs/home/) for more information on how these manifests should look.

    Reach out to `#tech-team` on the [Indy Center Discord](https://discord.gg/quYNCbnDfw) if you need more help.
<!-- prettier-ignore-end -->

Create a new directory in the appropriate location in our infrastructure repository.

Here are some example manifests.

=== "deployment.yaml"

    ```yaml
    # apps/production/my-app/deployment.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-app
      namespace: production
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: my-app
      template:
        metadata:
          labels:
            app: my-app
        spec:
          containers:
          - name: my-app
            image: ghcr.io/indy-center/my-app:latest
            ports:
            - containerPort: 8080
            resources:
              requests:
                memory: "64Mi"
                cpu: "250m"
              limits:
                memory: "128Mi"
                cpu: "500m"
            readinessProbe:
              httpGet:
                path: /health
                port: 8080
              initialDelaySeconds: 5
              periodSeconds: 10
    ```

=== "service.yaml"

    ```yaml
    # apps/production/my-app/service.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: my-app
      namespace: production
    spec:
      selector:
        app: my-app
      ports:
      - port: 80
        targetPort: 8080
    ```

=== "ingress.yaml"

    ```yaml
    # apps/production/my-app/ingress.yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: my-app
      namespace: production
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt-prod
    spec:
      rules:
      - host: my-app.zid-internal.com
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
      tls:
      - hosts:
        - my-app.zid-internal.com
        secretName: my-app-tls
    ```

### 3. Configure Argo CD Application

<!-- prettier-ignore-start -->
!!! warning "Application Configuration"
    Make sure to follow the [Argo CD User Guide](https://argo-cd.readthedocs.io/en/stable/user-guide/) for the most up-to-date configuration options.
<!-- prettier-ignore-end -->

Create an `application.yaml` in your app directory:

```yaml
# apps/production/my-app/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/indy-center/infrastructure.git
    targetRevision: HEAD
    path: apps/production/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 4. Submit and Deploy

1. Create a new branch
2. Add your manifests
3. Submit a pull request
4. Once approved and merged, Argo CD will automatically deploy your application

## Best Practices

### Resource Management

-   Always set [resource requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
-   Use [horizontal pod autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) for scalable applications
-   Monitor resource usage with [Grafana](https://metrics.zid-internal.com)

### Configuration

-   Use [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) for application configuration
-   Use [Sealed Secrets](sealed-secrets.md) for sensitive data
-   Keep environment-specific configuration separate

### Monitoring

-   Implement [health checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
-   Export [Prometheus metrics](https://prometheus.io/docs/introduction/overview/)
-   Create [Grafana dashboards](https://grafana.com/docs/grafana/latest/dashboards/) for monitoring

### Security

-   Follow the [principle of least privilege](https://kubernetes.io/docs/concepts/security/rbac-good-practices/)
-   Use [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) to restrict traffic
-   Keep container images up to date

## Troubleshooting

### Common Issues

1. **Application Not Syncing**

    - Check [Argo CD dashboard](https://argocd.zid-internal.com) for sync errors
    - Verify manifest syntax
    - Check if namespace exists
    - Ensure `application.yaml` is properly configured

2. **Pod Crashes**

    - Check pod logs:
        ```bash
        kubectl logs -n <namespace> <pod-name>
        ```
    - Verify resource limits
    - Check readiness probe configuration

3. **Network Issues**
    - Verify service selectors match pod labels
    - Check ingress configuration
    - Verify DNS resolution

## Additional Resources

-   [Argo CD App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern)
-   [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
-   [Argo CD User Guide](https://argo-cd.readthedocs.io/en/stable/user-guide/)
-   [Sealed Secrets Guide](sealed-secrets.md)
-   [Kubernetes Documentation](https://kubernetes.io/docs/home/)
-   [GitHub Container Registry Guide](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
-   [Helm Documentation](https://helm.sh/docs/)
-   [Kustomize Documentation](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
