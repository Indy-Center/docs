# Managing Sealed Secrets

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) allows us to store encrypted Kubernetes secrets in Git. This guide will show you how to create and manage sealed secrets in our cluster.

{% set k8s_guide_path = 'accessing-kubernetes.md' %}
{% include 'kubernetes-access.md' %}

## Overview

Regular Kubernetes secrets are base64 encoded but not encrypted, making them unsafe to store in Git. Sealed Secrets solves this by:

1. Encrypting secrets using the cluster's public key
2. Creating a `SealedSecret` resource that can be safely stored in Git
3. Automatically decrypting secrets in the cluster using the private key

!!! question "Too much work?"

    You can use the [Sealed Secrets Web UI](https://secrets.zid-internal.com) to create a sealed secret. This tool will _not_ let you decrypt secrets.

## Prerequisites

1. Install the `kubeseal` CLI tool by following the [official installation guide](https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#kubeseal)

2. Verify your installation:
    ```bash
    kubeseal --version
    ```

## Creating a Sealed Secret

Let's walk through creating a sealed secret for a database password:

1. First, create a regular Kubernetes secret manifest:

    ```yaml
    # secret.yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: database-creds
      namespace: production  # Specify your target namespace
    type: Opaque
    stringData:  # Using stringData allows us to use plain text instead of base64
      DB_PASSWORD: super-secret-password
      DB_USER: admin
    ```

2. Use `kubeseal` to encrypt it:

    ```bash
    # Encrypt the secret and save it to a new file
    kubeseal --format yaml < secret.yaml > sealed-secret.yaml
    ```

3. The resulting `sealed-secret.yaml` will look something like this:

    ```yaml
    apiVersion: bitnami.com/v1alpha1
    kind: SealedSecret
    metadata:
      name: database-creds
      namespace: production
    spec:
      encryptedData:
        DB_PASSWORD: AgBy8hCF8...  # Long encrypted string
        DB_USER: AgCtr4wBv...      # Long encrypted string
      template:
        metadata:
          name: database-creds
          namespace: production
        type: Opaque
    ```

This sealed secret can now be safely committed to Git!

## Deploying Sealed Secrets

We use GitOps to manage our cluster, so deploying secrets is as simple as:

1. Add your sealed secret to the appropriate directory in our [infrastructure repository](https://github.com/indy-center/infrastructure)
2. Commit and push your changes
3. Argo CD will automatically detect the change and apply the sealed secret
4. The Sealed Secrets controller will decrypt it and create a regular Kubernetes secret

<!-- prettier-ignore-start -->
!!! tip "Where to Put Secrets"
    Place your sealed secret YAML files in the appropriate application directory in the infrastructure repository. For example, if it's for the ICT application, add it under `apps/ict/`.
<!-- prettier-ignore-end -->

## Using Secrets in Applications

Once deployed, your applications can use the secret as normal:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: database-creds
              key: DB_PASSWORD
```

## Best Practices

1. **Never commit the original `secret.yaml`** - only commit the sealed version
2. Use descriptive names and namespaces
3. Keep sealed secrets close to the applications that use them in the infrastructure repository
4. Document any required secrets in your application's README
5. Use separate secrets for different environments (development, production)

## Troubleshooting

-   If sealing fails, ensure you have cluster access:

    ```bash
    kubectl cluster-info
    ```

-   If the controller can't decrypt a secret, check the controller logs:

    ```bash
    kubectl logs -n kube-system -l name=sealed-secrets-controller
    ```

-   If Argo CD shows the secret as "OutOfSync":
    ```bash
    # Check Argo CD's application status
    kubectl describe application -n argocd <app-name>
    ```

## Additional Resources

-   [Sealed Secrets GitHub Repository](https://github.com/bitnami-labs/sealed-secrets)
-   [Sealed Secrets Controller Documentation](https://github.com/bitnami-labs/sealed-secrets#sealed-secrets-for-kubernetes)
-   [kubeseal CLI Documentation](https://github.com/bitnami-labs/sealed-secrets#installation-from-source)
-   [Argo CD Documentation](https://argo-cd.readthedocs.io/)
