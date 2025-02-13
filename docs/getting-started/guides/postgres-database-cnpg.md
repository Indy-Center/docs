# Databases with CloudNative PG

[CloudNative PG](https://cloudnative-pg.io/) is our chosen PostgreSQL operator for Kubernetes. It provides a robust, cloud-native way to run and manage PostgreSQL clusters in our environment.

## Overview

CloudNative PG allows us to:

-   Run PostgreSQL clusters with high availability
-   Manage backups and restores
-   Handle database upgrades seamlessly
-   Monitor database health and performance

## Basic Setup

To create a PostgreSQL database for your application, you'll need to define a `Cluster` resource. Here's a basic example:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: my-app-db
spec:
  instances: 1

  # Resource allocation
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"

  # Storage configuration
  storage:
    size: 1Gi
    storageClass: local-path

  # Database initialization
  bootstrap:
    initdb:
      database: myapp
      owner: myapp
```

Place this manifest in your application directory (e.g., `apps/my-app/database.yaml`).

<!-- prettier-ignore-start -->
!!! tip "Development vs Production"
    For development environments, you can use a simpler configuration without high availability or backups. For production, consider enabling these features for data safety.
<!-- prettier-ignore-end -->

## Advanced Configuration

### With Backups

For production databases that need backup capabilities:

=== "cluster.yaml"

    ```yaml
    apiVersion: postgresql.cnpg.io/v1
    kind: Cluster
    metadata:
      name: my-app-db
      annotations:
        cnpg.io/skipEmptyWalArchiveCheck: "enabled"
    spec:
      instances: 1
      logLevel: debug
      postgresql:
        parameters:
          max_connections: "100"
          shared_buffers: "128MB"
      resources:
        requests:
          memory: "256Mi"
          cpu: "100m"
        limits:
          memory: "512Mi"
          cpu: "500m"
      storage:
        size: 1Gi
        storageClass: local-path
      bootstrap:
        initdb:
          database: myapp
          owner: myapp
      backup:
        barmanObjectStore:
          destinationPath: "s3://indy-db-backups-development"
          endpointURL: "https://s3.amazonaws.com"
          s3Credentials:
            accessKeyId:
              name: aws-creds
              key: ACCESS_KEY_ID
            secretAccessKey:
              name: aws-creds
              key: ACCESS_SECRET_KEY
        retentionPolicy: "30d"
    ```

=== "backup-config.yaml"

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: backup-config
    data:
      destinationPath: "s3://indy-db-backups-development"
      endpointURL: "https://s3.amazonaws.com"
    ```

<!-- prettier-ignore-start -->
!!! warning "Backup Credentials"
    The backup configuration requires AWS credentials. These should be stored as [Sealed Secrets](sealed-secrets.md) in your application directory. Reach out to the tech team for access to the backup bucket.
<!-- prettier-ignore-end -->

## Connecting to Your Database

CloudNative PG creates a service for your database that you can connect to using:

```
<cluster-name>-rw.<namespace>.svc.cluster.local
```

For example, if your cluster is named `my-app-db` in the `production` namespace:

```
my-app-db-rw.production.svc.cluster.local
```

### Credentials Management

CloudNative PG automatically handles password generation and management for your databases. When you create a cluster, it will:

1. Generate a secure password for your database user
2. Create a Kubernetes secret containing the credentials
3. Automatically rotate passwords when needed

The secret will be created with the name `<cluster-name>-app` in the same namespace. For example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-db-app
type: kubernetes.io/basic-auth
data:
  username: bXlhcHA=      # Base64 encoded "myapp"
  password: UGFzc3dvcmQ=  # Base64 encoded auto-generated password
```

### Example Application Configuration

You can reference this secret in your application configuration:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
data:
  # Basic connection string
  DATABASE_HOST: "my-app-db-rw:5432"
  DATABASE_NAME: "myapp"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
        - name: my-app
          env:
            - name: DATABASE_USER
              valueFrom:
                secretKeyRef:
                  name: my-app-db-app
                  key: username
            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: my-app-db-app
                  key: password
            - name: DATABASE_URL
              value: "postgresql://$(DATABASE_USER):$(DATABASE_PASSWORD)@$(DATABASE_HOST)/$(DATABASE_NAME)"
```

<!-- prettier-ignore-start -->
!!! tip "Secret Management"
    You don't need to create or manage the database passwords yourself - CloudNative PG handles all of this automatically. Just reference the auto-generated secret in your application configuration.
<!-- prettier-ignore-end -->

## Best Practices

1. **Resource Management**

    - Set appropriate resource requests and limits
    - Monitor database performance using our [Grafana dashboards](https://metrics.zid-internal.com)
    - Scale resources based on actual usage

2. **Backup Strategy**

    - Enable backups for production databases
    - Set an appropriate retention policy
    - Regularly test backup restoration

3. **Security**
    - Use strong passwords stored as [Sealed Secrets](sealed-secrets.md)
    - Limit database access to necessary applications
    - Keep PostgreSQL versions up to date

## Troubleshooting

1. **Database Won't Start**

    - Check the cluster events:
        ```bash
        kubectl describe cluster my-app-db
        ```
    - View operator logs:
        ```bash
        kubectl logs -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg
        ```

2. **Backup Issues**
    - Verify AWS credentials are correct
    - Check backup pod logs:
        ```bash
        kubectl logs -l cnpg.io/cluster=my-app-db -c backup
        ```

## Additional Resources

-   [CloudNative PG Documentation](https://cloudnative-pg.io/documentation/)
-   [PostgreSQL Documentation](https://www.postgresql.org/docs/)
-   [Backup and Recovery Guide](https://cloudnative-pg.io/documentation/current/backup_recovery/)
