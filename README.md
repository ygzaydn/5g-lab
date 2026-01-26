# open5gs-k8s (5G + IMS PCAP-first testlab)

This repository is a Kubernetes-based 5G testlab focused on learning packet-level flows.

The core idea is simple: run a full Open5GS 5GC and a Kamailio-based IMS on a dedicated Multus network where each network function has a fixed, known IP. That makes PCAPs readable, repeatable, and easy to correlate with procedures (Registration, PDU Session Establishment, IMS Registration, calls, etc.).

## What this repo contains

- **Open5GS 5GC (Kubernetes manifests)**
  - NFs deployed under the `open5gs` namespace.
  - MongoDB backend.
  - Open5GS WebUI (NodePort).
- **IMS (Kamailio IMS)**
  - P-CSCF / I-CSCF / S-CSCF.
  - IMS DNS and MySQL.
  - RTPengine for media anchoring.
- **HSS (PyHSS)**
  - A PyHSS deployment intended for a lab HSS/IMS subscriber backend.
  - This repo includes a local PyHSS build context under `ims/pyhss/`.
- **Monitoring (optional)**
  - Prometheus + Grafana manifests (also pinned to static IPs on the Multus network).
- **Network plumbing**
  - A Multus `NetworkAttachmentDefinition` (`network/sbi-network.yaml`) using the bridge CNI plugin.
  - Pods attach a second interface (typically `net1`) with a static IP for the lab.

## When to use this

Use this repo when you want a **repeatable 5G+IMS lab** where:

- You want to **capture and study PCAPs** (Wireshark/tshark) without chasing changing pod IPs.
- You are teaching or learning **5G procedures** (SBI, N2/N3/PFCP) and **IMS signaling** (SIP/DNS/Diameter/RTP).
- You are validating or demonstrating **UERANSIM-based** UE/RAN behavior against a known-good core.

This is not intended for production deployments.

## Repository layout

- `open5gs/` — Open5GS network functions, MongoDB, WebUI.
- `ims/` — IMS components (DNS, P-/I-/S-CSCF, RTPengine, MySQL, PyHSS).
- `network/` — Multus network attachment definition (`sbi-network`).
- `monitoring/` — Prometheus/Grafana manifests.

## IP plan (Multus `sbi-network`)

All of these addresses live on `10.10.10.0/24` and are assigned via Multus (static IPAM).

| Component | Role | IP | Where |
| --- | --- | ---: | --- |
| `nrf` | NRF | 10.10.10.10 | `open5gs/nrf.yaml` |
| `scp` | SCP | 10.10.10.11 | `open5gs/scp.yaml` |
| `amf` | AMF | 10.10.10.12 | `open5gs/amf.yaml` |
| `smf` | SMF | 10.10.10.13 | `open5gs/smf.yaml` |
| `udm` | UDM | 10.10.10.14 | `open5gs/udm.yaml` |
| `ausf` | AUSF | 10.10.10.15 | `open5gs/ausf.yaml` |
| `nssf` | NSSF | 10.10.10.16 | `open5gs/nssf.yaml` |
| `pcf` | PCF | 10.10.10.17 | `open5gs/pcf.yaml` |
| `udr` | UDR | 10.10.10.18 | `open5gs/udr.yaml` |
| `webui` | Open5GS WebUI | 10.10.10.19 | `open5gs/web-ui.yaml` |
| `bsf` | BSF | 10.10.10.20 | `open5gs/bsf.yaml` |
| `upf` | UPF | 10.10.10.21 | `open5gs/upf.yaml` |
| `prometheus` | Prometheus | 10.10.10.22 | `monitoring/prometheus.yaml` |
| `grafana` | Grafana | 10.10.10.23 | `monitoring/grafana.yaml` |
| `ims-dns` | IMS DNS | 10.10.10.60 | `ims/dns.yaml` |
| `pcscf` | P-CSCF | 10.10.10.61 | `ims/pcscf.yaml` |
| `icscf` | I-CSCF | 10.10.10.62 | `ims/icscf.yaml` |
| `scscf` | S-CSCF | 10.10.10.63 | `ims/scscf.yaml` |
| `rtpengine` | RTPengine | 10.10.10.64 | `ims/rtpengine.yaml` |
| `ims-mysql` | IMS MySQL | 10.10.10.65 | `ims/mysql.yaml` |
| `pyhss` | PyHSS | 10.10.10.66 | `ims/pyhss.yaml` |

## Images (including GHCR)

Most Open5GS components use published images (for example `gradiant/open5gs:2.7.6`).

This repo also uses **custom images** for some components (notably PyHSS and, depending on your setup, the IMS containers). The intent is to publish these to **GitHub Container Registry (GHCR)**.

Until your GHCR images are available (or if you are iterating locally), you have two options:

1. **Build locally and keep `imagePullPolicy: Never`** (works well for single-node labs).
2. **Change the manifests to use `ghcr.io/<your-org>/<image>:<tag>` and set `imagePullPolicy: IfNotPresent`**.

## Prerequisites

- A working Kubernetes cluster (single-node is fine for a lab).
- **Multus CNI** installed.
- The **bridge CNI plugin** available on nodes (used by `network/sbi-network.yaml`).
- `kubectl` access to the cluster.
- Host kernel support for the UPF pod (it uses `/dev/net/tun` and runs privileged).

Storage note:

- This repo uses **PVCs** for MongoDB and IMS MySQL. Your cluster needs a default `StorageClass` (common on most local clusters).

## Multus + bridge network setup

You do not need to manually create a Linux bridge in advance.

This repo ships a Multus `NetworkAttachmentDefinition` in `network/sbi-network.yaml` that tells Multus to use the **bridge CNI plugin** and create/use a bridge called `br-int`.

### 1) Install Multus

How you install Multus depends on your Kubernetes distro. Typical options:

- MicroK8s: `microk8s enable multus`
- Generic Kubernetes: apply the official Multus manifest from the upstream repo (recommended to follow the upstream instructions):
  - `https://github.com/k8snetworkplumbingwg/multus-cni`

After installing, you should see Multus pods in `kube-system`:

```bash
kubectl -n kube-system get pods | grep -i multus
```

### 2) Ensure the bridge CNI plugin exists on nodes

Multus calls the underlying CNI plugin binaries on the node. The bridge plugin usually lives under `/opt/cni/bin/bridge` (path can vary by distro).

On a node, check for the `bridge` plugin binary:

```bash
sudo ls -l /opt/cni/bin/bridge || true
sudo ls -l /usr/lib/cni/bridge || true
```

### 3) Confirm the NAD is created

Once Multus is installed, this should work:

```bash
kubectl -n open5gs get network-attachment-definitions
```

## Deploying the lab

Quickstart checklist (for a fresh cluster):

- Multus must be installed (required for the `NetworkAttachmentDefinition` and the static `net1` IPs).
- A default `StorageClass` must exist (required for MongoDB + IMS MySQL PVCs).

The simplest way to deploy (recommended) is a single command from the repo root:

```bash
kubectl apply -k .
```

Check status:

```bash
kubectl -n open5gs get pods -o wide
```

## Accessing UIs

- **Open5GS WebUI**
  - Recommended (works from your laptop): `http://<node-ip>:30000`
  - Optional (if you are on the Kubernetes node and can reach `br-int`): `http://10.10.10.19:9999/`

- **Monitoring (Grafana)**
  - Recommended: port-forward
    - `kubectl -n open5gs port-forward deploy/grafana 3000:3000`
    - then open `http://127.0.0.1:3000`
  - Optional (if you are on the Kubernetes node and can reach `br-int`): `http://10.10.10.23:3000`

Default credentials:

- Open5GS WebUI: `admin` / `12345`
- Grafana: `admin` / `admin`

## Troubleshooting (common)

- `kubectl apply -k .` fails with `no matches for kind "NetworkAttachmentDefinition"`:
  - Multus is not installed (or its CRDs are missing).
- Pods stuck in `Pending` and PVCs show `Pending`:
  - Your cluster likely has no default `StorageClass`.
- Pods stuck in `Init` / `CrashLoopBackOff` with image pull errors:
  - If your `ghcr.io/ygzaydn/*` images are private, you need an `imagePullSecret`.


## Capturing PCAPs (the point of this lab)

Because all NFs share a deterministic /24 on the Multus bridge, capturing traffic is straightforward.

### Option A: capture on the Kubernetes node (recommended)

If your Multus bridge interface is `br-int` (as defined in `network/sbi-network.yaml`), capture the entire SBI/IMS subnet:

```bash
sudo tcpdump -i br-int -w sbi-ims.pcap net 10.10.10.0/24
```

### Option B: capture on a single pod interface

If the container image includes `tcpdump` (not always the case), you can capture directly on `net1`:

```bash
kubectl -n open5gs exec -it deploy/amf -- tcpdump -i net1 -w /tmp/amf.pcap
```

If your images don’t include `tcpdump`, use node capture (Option A) or an ephemeral debug container.

## Typical learning workflows

- **5G Registration**: follow AMF/SMF/NSSF/AUSF interactions and correlate with NGAP.
- **PDU Session Establishment**: focus on SMF↔UPF PFCP, and N3/N4 behavior.
- **IMS Registration**: SIP REGISTER via P-CSCF → I-CSCF → S-CSCF and Diameter to PyHSS.
- **IMS Call setup**: SIP INVITE/200/ACK and RTP anchoring via RTPengine.

## Safety and legal

Run this in an isolated lab environment. Do not connect it to real operator networks, and ensure you comply with local radio and telecom regulations when using any RF hardware.

## Contributing / customization

This repo is intentionally opinionated for PCAP-driven learning.

If you change the IP plan, update both:

- Multus static IP annotations inside the manifests
- The environment config (`ims/ims-env-kamailio.yaml`) and any Open5GS config maps that reference IMS/core addresses
