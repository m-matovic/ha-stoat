# HA Stoat on Hetzner Cloud

Highly Available symmetric 3-node cluster for Stoat on Hetzner Cloud (or other clouds, with modifications).

We use a Hetzner Floating IP with Keepalived for IP failover, with fully clustered components (MongoDB Replica Set, RabbitMQ Cluster, Garage S3 Distributed Storage, KeyDB in multimaster active-active replication, and multi-node livekit).

Stoat itself *should* be stateless and all nodes contain the full stack of services. Only a small patch was needed to the **pushd** component to make use of AMQP quorum queues for replicated messages (Take a look at https://github.com/m-matovic/stoatchat-0.11.1-ha-patch for details).

This setup doesn't include any SMTP setup, so anyone can register on your instance without any validation. If you want to use this for real it's better to enable invite-only mode like in the officail self hosting guide:
https://github.com/stoatchat/self-hosted

## Prerequisites

### Infrastructure (Hetzner Cloud)
* **3 Cloud Servers** (Stoat recommends Ubuntu) attached to the same Hetzner Private Network, ensure they have public connectivity as well
* Use whatever architecture is on your machine, look below for details
* **Private Network** containing all of your machines for reliable inter-node connection
* **1 Hetzner Floating IP**
* **Hetzner API Token** with **Read & Write** permissions (required for dynamic Floating IP reassignment during failover)
* A registered **Domain Name** with an `A` record pointing to your Hetzner Floating IP

### Other Clouds
* Ensure they have an API driven Floating IP equivalent (AWS calls them Elastic IPs, for example)
* Edit the `files/notify.sh` script to use their API for reassigning the floating IP
* Everything else should be the same, but this was not tested

### Local Tools
* `git`
* `docker`
* `ansible`
* `openssl`

---

## Installation

### 1. Clone the Repo
Use the `--recursive` flag to pull in the patched pushd component as a submodule

```bash
git clone --recursive https://github.com/m-matovic/ha-stoat
cd ha-stoat
```

### 2. Build the Patched Pushd Image
Run the build script to build the patched `ha-stoat-pushd` Docker image and save it to a tarball. This tarball will be automatically distributed to the nodes by Ansible.
It uses the Dockerfile for compiling on your current architecture, if you want to cross-build the image you can fiddle with the base Dockerfile (not tested).

```bash
./build_pushd_image.sh
```

### 3. Configure the inventory
Edit the file `inventory.yml`.
Replace all variables in `<>` with information from your cloud nodes, domain, etc.
For the secrets at the bottom, either generate them yourself or run the script to replace the placeholders:

```bash
./generate_secrets.sh
```

### 4. Deploy
Once your inventory is configured, run the deployment playbook. Ansible will install Docker on the remote nodes and setup everything needed to run the whole stack.

```bash
ansible-playbook -i inventory.yml deploy.yml
```

Some errors are expected on first deployment:
- **Check if S3 key exists**: it was not created yet

Some other errors are expected on subsequent deployments
- **MongoDB ReplicaSet already initialized**: Replication state is saved across runs
- **Connect Garage S3 Nodes**, **Assign Garage Layout**, **Create S3 Bucket**: Layout and bucket already exist

For other issues, mainly with RabbitMQ (*Khepri timeout* or *Khepri cluster minority*), restart the deployment.

---

### Stop the Cluster

```bash
ansible-playbook -i inventory.yml stop.yml
```

### Permanently Delete the Cluster
Completely wipe the cluster, destroying all Docker volumes (databases, storage), images, the Keepalived state, and the application user:

```bash
ansible-playbook -i inventory.yml delete.yml
```

Docker will remain installed on the nodes.
