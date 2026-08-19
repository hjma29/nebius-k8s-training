# Mk8s cluster name. By default it is "k8s-training"
cluster_name = "hj-k8s-training"

# SSH config
ssh_user_name = "ubuntu" # Username you want to use to connect to the nodes
ssh_public_key = {
  key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDkm1nH+7IC/bCT73sk9DiS6zf+3j4poM+/HL1Kxrk+8sp3QlY/R/ZYppEjjoAa6bopnVKTuz0M7/wDOtJaxnfWv2pUMiErpFv/A1oarV6LtxS+hMtSg+6Sl/fLINoJiPHWTclhkq2kFpEECx4rICt96ahAVxv5BAvOtlolAXVpGcJ2J4+I4VXtxxSh1/J+1HkjtPQMxOGhpJ5nxWOc2bvAlTmxDzQnyUeoKV73ex2L34HuEr7Kwq8XKdOeNbxAi4jurG/SCWGOdMZp02QIoNsoT+O48+qDG/zWW4VbFWeCUSC5tIM4ljPgNLsjEf9kqqIb+PP0Z95ZeeXaJMNfD+CjTuoBeDX1IIRJ+tE2+U8vBN1HzFOkeVyDi2/vbveBpeEa6lM+mWwj6eoHHFvMyGKNRptFXByLQwunLuouifHFkALgoXm+75LjWKoWuqEwbnRJ72DGzovpoJX8DvB3It4qfcOIriSGaT2f4Faii0UmRyaLRGqCfsS02tKr2aAUfHs= hjma@HSTHJMA02"
  # path = "put path to public ssh key here"
}

# K8s nodes
gpu_nodes_fixed_count_per_group = 2 # Number of GPU nodes per group, used only when gpu_nodes_autoscaling.enabled = false
gpu_nodes_autoscaling = {
  enabled = false
  # min_size options:
  # - null: min=max, no scale-down (default, recommended - saves ~10 min on initial provisioning)
  #   it can be changed to a number later if needed.
  # - N: can scale down to N nodes
  min_size = null
  max_size = 1
}
gpu_node_groups = 1 # In case you need more then 100 nodes in cluster you have to put multiple node groups
# GPU platform and preset: https://docs.nebius.com/compute/virtual-machines/types#gpu-configurations
# --- eu-north1 H100 (backed up 2026-08-18 while testing us-central1 H200) ---
# gpu_nodes_platform = "gpu-h100-sxm"        # GPU nodes platform: gpu-h100-sxm, gpu-h200-sxm, gpu-b200-sxm
# gpu_nodes_preset   = "8gpu-128vcpu-1600gb" # GPU nodes preset: 8gpu-128vcpu-1600gb, 8gpu-128vcpu-1600gb, 8gpu-160vcpu-1792gb
# Infiniband fabrics: https://docs.nebius.com/compute/clusters/gpu#fabrics
# infiniband_fabric = "fabric-2" # H100 fabric in eu-north1, needed for real cross-node NCCL/InfiniBand

# --- us-central1 H200 test ---
gpu_nodes_platform = "gpu-h200-sxm"        # GPU nodes platform: gpu-h100-sxm, gpu-h200-sxm, gpu-b200-sxm
gpu_nodes_preset   = "8gpu-128vcpu-1600gb" # GPU nodes preset: 8gpu-128vcpu-1600gb, 8gpu-128vcpu-1600gb, 8gpu-160vcpu-1792gb
infiniband_fabric  = "us-central1-a"       # H200 fabric in us-central1, needed for real cross-node NCCL/InfiniBand

gpu_nodes_driverfull_image = true
enable_k8s_node_group_sa   = false
enable_egress_gateway      = false
gpu_nodes_preemptible      = true # on-demand/Regular capacity has repeatedly shown Low chance of launch across regions/fabrics per the Capacity dashboard; always use preemptible
test_mode                  = false # Manual test flow: only spin up nodes, run nccl-test yourself

gpu_nodes_public_ips         = false
mk8s_cluster_public_endpoint = true # Set it to FALSE only in case if you've deployed the [bastion](https://github.com/nebius/nebius-solutions-library/blob/main/bastion/README.md)
# host first, and you are deploying cluster from the bastion instance

# Observability by Nebius
enable_nebius_o11y_agent = false # Enable or disable Nebius Observability Agent deployment with true or false
enable_grafana           = false # Enable or disable Grafana® solution by Nebius with true or false

# Local Observability installation
enable_prometheus = false # Enable or disable Prometheus and Grafana deployment with true or false
loki = {
  enabled            = false # Enable or disable Loki deployment with true or false
  replication_factor = 2     # Number of Loki replicas for each log chunk (higher = better availability, more storage/network cost)
}

# Storage, KubeRay, RBAC bindings, OPA Gatekeeper, and binpacking all left at their
# disabled defaults (unused for this test) — see variables.tf if you need to enable them.