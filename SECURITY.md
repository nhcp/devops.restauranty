# Security

This document describes how Restauranty actually handles secrets, authentication, network access, and data — including known trade-offs. Nothing here is aspirational; everything is either implemented and verified, or explicitly flagged as a limitation.

## Secret management

- Database URI, JWT signing secret, and Cloudinary API credentials are stored as a Kubernetes `Secret` (`restauranty-secrets`), injected into pods as environment variables. Nothing is baked into Docker images.
- The real secret values live only in `k8s/06-secrets.yaml`, which is gitignored. A committed template (`k8s/06-secrets.example.yaml`) documents the required keys with placeholder values only.
- CI/CD credentials (Docker Hub token, AWS access keys) are stored as GitHub Actions repository secrets, never in workflow files.

## Authentication & authorization

- The `auth` service issues JSON Web Tokens (JWTs) on successful login/signup. This is **authentication** — establishing who the caller is.
- `discounts` and `items` validate incoming JWTs on protected routes via `express-jwt`. This is **authorization** — deciding whether that caller may perform the requested action.
- **Known trade-off:** all three services share one signing secret (`SECRET`), rather than each service having its own key or using asymmetric (public/private key) signing. This is a common simplification in small systems, but it means any service that leaks its `SECRET` value compromises token validation for all three. A production system at larger scale would move to per-service keys or a centralized identity provider.

## Network access

- **TLS**: The public Ingress terminates HTTPS using a certificate issued by Let's Encrypt via `cert-manager`, auto-renewing. Verified with a real browser padlock at `restauranty.kelenva.com`, not a self-signed cert.
- **CORS**: All three backend services previously allowed `origin: '*'` (any website). This has been tightened to an explicit allowlist containing only the real deployed frontend origin and local development origins.
- **NetworkPolicies**: Two Kubernetes NetworkPolicies restrict pod-to-pod traffic within the cluster:
  1. Only pods in the `ingress-nginx` namespace may reach `frontend`, `auth`, `discounts`, or `items` — nothing else in the cluster can call these services directly, bypassing the Ingress.
  2. Only `auth`, `discounts`, and `items` may reach `mongo` — `frontend` and anything else cannot connect to the database directly.
  Enforcement was verified directly: a test pod deployed inside the same namespace, outside the allowed source list, received `Connection refused` when attempting to reach `auth` directly. Enforcement mode was also confirmed active on the cluster's CNI (`NETWORK_POLICY_ENFORCING_MODE: standard`) before relying on this test as proof.

## IAM / cloud identity

- The EKS worker node IAM role holds only three AWS-managed policies: `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`, and `AmazonEKSWorkerNodePolicy` — the standard minimal set for an EKS node group, with no account-wide or administrative permissions attached.
- The EBS CSI driver runs under its own separate IAM role (`AmazonEKS_EBS_CSI_DriverRole_Restauranty_nazmul`), scoped via IRSA (IAM Roles for Service Accounts) to only the `AmazonEBSCSIDriverPolicy` — it cannot assume broader permissions than volume management.

## Data storage & GDPR-relevant data

- **Known trade-off**: all three backend services connect to a single shared MongoDB database (`Restauranty`), rather than each service owning its own isolated database. This is a pragmatic simplification for a system this size, not full data isolation between services — a production system serving multiple teams would likely split this per service.
- User-identifying data stored includes: email addresses and hashed passwords (`auth`), and order/purchase history associated with a user ID (`items`, `discounts`). Passwords are never stored in plaintext.
- No separate log/metric retention policy is currently configured beyond Kubernetes' and the cloud provider's defaults; this is a known gap for a production deployment handling real user data long-term.

## What's intentionally out of scope for this project

- Per-service database isolation (see trade-off above)
- Centralized secret management (e.g. AWS Secrets Manager / HashiCorp Vault) — Kubernetes Secrets are used directly
- Formal penetration testing or a third-party security audit
