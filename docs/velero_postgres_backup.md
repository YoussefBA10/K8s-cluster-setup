# PostgreSQL Disaster Recovery with Velero (S3)

## 📌 Objective

Implement a **real-world Disaster Recovery (DR)** solution for PostgreSQL running on Kubernetes using **Velero** with **Amazon S3** as backup storage.

This documentation covers:

* Architecture
* Installation steps
* Common pitfalls encountered
* Verification & testing
* Restore scenario
* RPO / RTO explanation

This setup reflects **production-grade DevOps practices**.

---

## 🧱 Architecture Overview

```
[Kubernetes Cluster]
      |
      | (Snapshots + Metadata)
      v
[Velero]
      |
      | (S3 API)
      v
[Amazon S3 Bucket]
```

Components:

* Kubernetes cluster (on‑prem / VM / cloud)
* PostgreSQL (Bitnami Helm chart)
* Velero (Helm installed)
* Amazon S3 (backup object storage)

---

## 🧰 Prerequisites

* Kubernetes cluster (Minikube / kubeadm / cloud)
* kubectl configured
* Helm v3
* AWS S3 bucket created
* AWS IAM user with S3 permissions

---

## 🗂️ S3 Bucket

* Bucket name: `rock-solid-backups`
* Region: `us-east-1`
* Permissions:

  * `s3:PutObject`
  * `s3:GetObject`
  * `s3:DeleteObject`
  * `s3:ListBucket`

---

## 🔐 AWS Credentials (Kubernetes Secret)

Credentials file (`credentials-velero.ini`):

```ini
AWS_ACCESS_KEY_ID=XXXX
AWS_SECRET_ACCESS_KEY=XXXX
AWS_DEFAULT_REGION=us-east-1
```

Create secret:

```bash
kubectl create secret generic cloud-credentials \
  -n velero \
  --from-env-file=credentials-velero.ini
```

---

## 🚀 Velero Installation (Helm)

### Helm Repository

```bash
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update
```

### values-velero.yaml

```yaml
configuration:
  backupStorageLocation:
    - name: aws
      provider: aws
      bucket: rock-solid-backups
      default: true
      config:
        region: us-east-1

initContainers:
  - name: velero-plugin-for-aws
    image: velero/velero-plugin-for-aws:v1.9.0
    volumeMounts:
      - mountPath: /target
        name: plugins
```

### Install Velero

```bash
helm install velero vmware-tanzu/velero \
  -n velero \
  --create-namespace \
  -f values-velero.yaml
```

---

## ⚠️ Issue Encountered: BackupStorageLocation Not Default

**Symptoms**:

* Velero logs repeatedly show:

```
There is no existing BackupStorageLocation set as default
```

**Root Cause**:
BackupStorageLocation existed but was not marked as `default`.

**Fix**:

```bash
velero backup-location set velero/aws --default
```

---

## 🐘 PostgreSQL Installation

Using Bitnami PostgreSQL Helm chart.

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Install:

```bash
helm install rocksolid-postgres bitnami/postgresql \
  -n database \
  --create-namespace
```

PostgreSQL runs with persistent volumes and credentials stored in Kubernetes secrets.

---

## 💾 PostgreSQL Logical Backup (pg_dumpall)

Bitnami chart creates a **CronJob** for logical backups.

### Manual Test Backup

```bash
kubectl create job \
  --from=cronjob/rocksolid-postgres-postgresql-pgdumpall \
  test-s3-backup \
  -n database
```

### Observed Behavior

* Job runs
* Pod status: `Completed`
* Backup stored **inside PVC**

⚠️ **Important**: This backup **does NOT push to S3**.
It only prepares local dumps.

Velero is responsible for:

* Capturing PVC snapshot
* Uploading snapshot metadata to S3

---

## 🧪 Velero Backup Test

### Install Velero CLI

```bash
curl -LO https://github.com/vmware-tanzu/velero/releases/download/v1.13.2/velero-v1.13.2-linux-amd64.tar.gz

tar -xzf velero-v1.13.2-linux-amd64.tar.gz
sudo mv velero-v1.13.2-linux-amd64/velero /usr/local/bin/
```

Verify:

```bash
velero version
```

---

### Create Backup

```bash
velero backup create test-backup --include-namespaces database
```

Check status:

```bash
velero backup get
velero backup logs test-backup
```

Expected result:

* Status: `Completed`
* Objects appear in S3 bucket

---

## ♻️ Restore Scenario (Disaster Simulation)

### 1️⃣ Simulate Disaster

```bash
kubectl delete namespace database
```

### 2️⃣ Restore

```bash
velero restore create --from-backup test-backup
```

### 3️⃣ Verify

```bash
kubectl get pods -n database
kubectl get pvc -n database
```

PostgreSQL should be:

* Running
* Data intact

---

## ⏱️ RPO / RTO

### RPO (Recovery Point Objective)

* Maximum acceptable data loss
* Defined by backup frequency

Example:

* Backup every 6h → **RPO = 6 hours**

---

### RTO (Recovery Time Objective)

* Time to restore service after failure

Includes:

* Velero restore time
* PVC reattachment
* PostgreSQL startup

Typical:

* **RTO = 5–10 minutes** (lab)

---

## 🧠 Lessons Learned

* Velero **does not backup databases logically** by default
* PostgreSQL backups require **pg_dump + PVC snapshot**
* BackupStorageLocation must be explicitly default
* CLI is required for real testing

---

## ✅ Production Improvements

* Encrypt S3 bucket
* Enable versioning
* Off‑cluster MinIO for on‑prem
* Use CSI snapshots
* Add monitoring on Velero jobs

---

## 🏁 Conclusion

This Disaster Recovery setup:

* Matches **real interview expectations**
* Covers **stateful workloads**
* Demonstrates strong Kubernetes + DevOps mastery

🔥 This alone puts you ahead of most candidates.

---


