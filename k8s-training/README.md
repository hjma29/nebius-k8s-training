# Nebius K8s Training — 2-Node GPU NCCL Test Cluster

This repo spins up a Nebius Managed Kubernetes (MK8s) cluster with a single
fixed GPU node group — **2 nodes, 8 GPUs each (16 GPUs total)**, connected via
InfiniBand — for running NCCL benchmark tests. It intentionally has no CPU
node group, autoscaling, observability stack, shared filesystem, RBAC
bindings, or KubeRay enabled by default; see `variables.tf` if you need any
of those for your own use.

## Prerequisites

1. Install the [Nebius AI CLI](https://docs.nebius.com/cli/install/):
   ```bash
   curl -sSL https://storage.eu-north1.nebius.cloud/cli/install.sh | bash
   exec -l $SHELL
   ```
2. [Configure the Nebius CLI](https://docs.nebius.com/cli/configure/) (a
   [service account](https://docs.nebius.com/iam/service-accounts/manage/) is
   recommended).
3. Install `jq`, `kubectl`, and `terraform`.

## 1. Deploy the cluster

1. Set `NEBIUS_TENANT_ID`, `NEBIUS_PROJECT_ID`, and `NEBIUS_REGION` in
   `environment.sh`, then load them:
   ```bash
   source ./environment.sh
   ```
2. Adjust `terraform.tfvars` for your needs (GPU platform/preset, InfiniBand
   fabric, region — see inline comments; `variables.tf` has the full list).
3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
   Wait for the GPU node group to reach `Ready`.

## 2. Run the NCCL test

Once the cluster is up and its GPU nodes are `Ready`, run the steps below.
(`test_mode = false` in `terraform.tfvars` means the NCCL test is run
manually, not auto-deployed by Terraform.) This follows the official flow
from [docs.nebius.com/kubernetes/gpu/nccl-test](https://docs.nebius.com/kubernetes/gpu/nccl-test)
picking up after cluster/node-group setup, which Terraform already handles.

### Get kubeconfig credentials for the cluster

```bash
nebius mk8s cluster list --parent-id <project-id> --format json | jq -r '.items[0].metadata.id'
nebius mk8s cluster get-credentials --id <cluster-id> --external
kubectl cluster-info   # verify kubectl is connected
```

### Confirm GPU nodes are Ready

```bash
kubectl get nodes
```

### Install the Kubeflow Training Operator

Required for the `MPIJob` CRD; not auto-installed when `test_mode = false`.

```bash
kubectl apply --server-side -k "github.com/kubeflow/training-operator/manifests/overlays/standalone?ref=v1.9.3"
```

### Create the nccl-test namespace

```bash
kubectl create ns nccl-test
```

`nccl-test.yaml` has no `namespace:` field, so this step is required —
otherwise `kubectl apply -f nccl-test.yaml` (without `-n nccl-test`) silently
lands the MPIJob in `default` instead.

### Deploy the NCCL benchmark MPIJob

```bash
kubectl apply -f nccl-test.yaml -n nccl-test
```

`nccl-test.yaml` runs `mpirun -np 16 ... all_reduce_perf -b 512M -e 8G -f 2 -g 1`
across `slotsPerWorker: 8` with 2 workers (16 GPUs total).

### Watch it run

```bash
kubectl get pods -n nccl-test -w
```

Wait until all pods are `Running`, then stream the launcher's logs (`grep -v`
filters out the noisy per-channel `NCCL INFO` lines):

```bash
kubectl logs -n nccl-test -l training.kubeflow.org/replica-type=launcher -f | grep -v "NCCL INFO"
```

If the job already finished (no longer running), `-f` won't show anything —
use `--tail` instead:

```bash
kubectl logs -n nccl-test -l training.kubeflow.org/replica-type=launcher --tail=100
```

Check the `# Avg bus bandwidth` line — above 300 GB/sec indicates a stable
InfiniBand connection (per the official doc's guidance).

### Clean up

You should delete the `MPIJob` even if you want to run another test —
redeploy it fresh rather than reapplying on top of a finished job:

```bash
kubectl delete -f nccl-test.yaml -n nccl-test
```

### Check GPU and InfiniBand info on the nodes (optional)

```bash
kubectl get pods -n nccl-test   # find a worker pod name

# GPU info
kubectl exec -n nccl-test <worker-pod> -- nvidia-smi

# InfiniBand link state/rate per HCA
kubectl exec -n nccl-test <worker-pod> -- ibstat
kubectl exec -n nccl-test <worker-pod> -- ibv_devinfo -v
```
