# Kubernetty — Live Demo Access Guide

Kubernetty is a separate, standalone exercise from Restauranty: a small
highly-available k3s cluster built from raw AWS EC2 instances, proving
operational understanding of what a managed Kubernetes control plane (like
EKS) is doing underneath. Full writeup on the portfolio site.

This document describes how the cluster is accessed and demoed, since it
runs on temporary infrastructure without a permanent public URL.

## Architecture

- One nginx TCP load balancer proxying port 6443 to both k3s server nodes
- Two k3s server nodes in server mode, sharing cluster state through an
  external MySQL datastore rather than each keeping an isolated copy
- One agent (worker) node, joined through the load balancer rather than
  directly to a server
- All four nodes live in a dedicated VPC on temporary EC2 instances

## Terminal access (the reliable path)

SSH into any server node with the cluster's dedicated key, then:

    sudo k3s kubectl get nodes
    sudo k3s kubectl get pods -o wide

This shows the real cluster state: which nodes are control-plane versus
worker, and where the running workload is actually scheduled.

## The HA proof, reproducible on demand

With a real workload running, stop k3s on one server node entirely:

    sudo systemctl stop k3s

From the other server node, the cluster and the workload both keep
running without interruption. Restarting the stopped node's service
rejoins it to the cluster automatically, with no manual reconfiguration:

    sudo systemctl start k3s

## Dashboard access

The Kubernetes Dashboard is deployed on the cluster but its direct login
has a known compatibility issue on this Dashboard/k3s version combination.
It's reached instead through an authenticated kubectl proxy tunnel:

1. Open an SSH session with local port forwarding to a server node
2. Inside that session, run: sudo k3s kubectl proxy --accept-hosts='.*' --address=0.0.0.0
3. In a second terminal, generate a login token with:
   sudo k3s kubectl -n kubernetes-dashboard create token admin-user --duration=24h
4. Open the local proxy URL in a browser and log in with that token

## Why this cluster isn't permanently live

Running a 4-node HA cluster continuously has real, ongoing cost for
infrastructure that exists purely to demonstrate a skill, not to serve
traffic. It's provisioned, demoed, and torn down deliberately, the same
way the AWS EKS side of Restauranty is treated as temporary and retired
once its purpose is served.
