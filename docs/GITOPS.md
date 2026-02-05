This module documents the setup of GitOps practices using this repository.

- Use Git as the single source of truth.
- Store all infrastructure, automation, and deployment scripts.
- Enable environment separation and controlled promotions.
- Track changes with PRs for auditability.

- `helm/` - K8s charts.
- `ansible/` - Configuration automation.
- `bash/` - Scripts for deployments, DR, chaos experiments.
- `terraform/` - IaC modules.

1. Developer creates a feature branch.
2. Changes are tested locally or in a dev cluster.
3. PR is opened for review.
4. Upon approval, code is merged to main.
5. CI/CD pipeline deploys changes to the appropriate environment.

