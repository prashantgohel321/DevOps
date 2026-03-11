# Kafka Monitoring Stack Setup Using Docker

<br>
<br>

- [Kafka Monitoring Stack Setup Using Docker](#kafka-monitoring-stack-setup-using-docker)
  - [1. What we are building](#1-what-we-are-building)
  - [2. Basic prerequisites](#2-basic-prerequisites)
  - [3. Creating the project directory](#3-creating-the-project-directory)
  - [4. Creating Prometheus configuration](#4-creating-prometheus-configuration)
  - [5. Creating Docker Compose file](#5-creating-docker-compose-file)
  - [6. Starting the monitoring stack](#6-starting-the-monitoring-stack)
  - [7. Verifying Kafka exporter](#7-verifying-kafka-exporter)
  - [8. Accessing Prometheus](#8-accessing-prometheus)
  - [9. Accessing Grafana](#9-accessing-grafana)
  - [10. Connecting Grafana to Prometheus](#10-connecting-grafana-to-prometheus)
  - [11. Importing Kafka dashboards](#11-importing-kafka-dashboards)
  - [12. Checking logs and troubleshooting](#12-checking-logs-and-troubleshooting)
  - [13. Stopping the stack](#13-stopping-the-stack)
  - [14. What a Linux administrator typically maintains](#14-what-a-linux-administrator-typically-maintains)
  - [15. Quick recap](#15-quick-recap)


<br>
<br>

## 1. What we are building

- In many environments Kafka is already running as part of the application infrastructure. Administrators usually do not manage the Kafka application itself, but they are responsible for monitoring it. Monitoring helps detect problems such as broker failures, message backlog, or consumers falling behind.

<br>

**To monitor Kafka properly we usually combine three tools:**
- Kafka Exporter
- Prometheus
- Grafanḁ

<br>

- **Kafka exporter** collects operational metrics from Kafka.
- **Prometheus** stores those metrics as time‑series data.
- **Grafana** displays the metrics visually in dashboards.̥

<br>

In this guide the entire monitoring stack will run inside Docker containers. Docker is a container runtime that allows applications to run in isolated environments called containers. A container includes the application and its dependencies so it behaves the same way on any server.

Using Docker makes deployment easier because we do not have to install each tool manually on the host system.

**The architecture we will build looks like this:**

```bash

Kafka Cluster → Kafka Exporter → Prometheus → Grafana Dashboard

------------------------------------------------------------------------

→ Kafka exporter reads metrics from Kafka.
→ Prometheus periodically collects those metrics.
→ Grafana connects to Prometheus and visualizes them.
```

<br>
<br>

## 2. Basic prerequisites

Before starting, the Linux server should already have the following components installed.

- Docker
- Docker Compose̥

Docker Compose is a tool that allows multiple containers to be defined and started together using a single configuration file. Instead of running several docker run commands manually, we describe all containers inside a compose file and start them together.

**Verify Docker installation:**

```bash
docker --version
```

**Verify Docker Compose:**

```bash
docker compose version
```

**Kafka cluster must also already be reachable. For example:**

```bash
192.168.1.50:9092
```

Port 9092 is the default Kafka broker port where clients communicate with Kafka.

<br>
<br>

## 3. Creating the project directory

Create a directory that will store all configuration files.

```bash
mkdir kafka-monitoring
cd kafka-monitoring
```

**Inside this directory we will keep:**

```bash
kafka-monitoring

├── docker-compose.yml
├── prometheus
│   └── prometheus.yml
└── grafana
```

Prometheus requires its own configuration file which tells it where to collect metrics from.

<br>
<br>

## 4. Creating Prometheus configuration

**Create the Prometheus directory:**

```bash
mkdir prometheus
```

Now create the configuration file.

```bash
vi prometheus/prometheus.yml
```

**Example configuration:**

```bash
global:
  scrape_interval: 15s

scrape_configs:

  - job_name: kafka-exporter

    static_configs:
      - targets: ['kafka-exporter:9308']
```

**Explanation:**

- **`scrape_interval`** defines how often Prometheus collects metrics. In this configuration Prometheus collects metrics every 15 seconds.

- **`scrape_configs`** defines monitoring targets.

- The target **`kafka-exporter:9308`** refers to the Kafka exporter container. Docker containers inside the same network can communicate using container names.

Port 9308 is the default metrics port exposed by kafka exporter.

<br>
<br>

## 5. Creating Docker Compose file

Now create the compose file.

```bash
vi docker-compose.yml
```

Example configuration:

```bash
version: '3'

services:

  kafka-exporter:
    image: danielqsj/kafka-exporter
    container_name: kafka-exporter
    command:
      - "--kafka.server=192.168.1.50:9092"
    ports:
      - "9308:9308"

  prometheus:
    image: prom/prometheus
    container_name: prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  grafana-data:
```

**Explanation of important parts:**

**image**: This defines which container image Docker will pull from Docker Hub.

**For example:**
- prom/prometheus is the official Prometheus image.
- grafana/grafana is the official Grafana image.

<br>

**container_name**: This assigns a fixed name to the container. It helps when identifying containers using docker commands.

**command**: This section provides startup arguments to Kafka exporter.

```bash
--kafka.server=192.168.1.50:9092
```

This tells the exporter which Kafka broker to connect to.

<br>
<br>

**ports**: This maps container ports to host ports.

**Example:**

```bash
9308:9308

# to check if any service is listening on port 9308 on the host:
netstat -tuln | grep 9308

# Breakdown:
# netstat: shows network connections
# -t: TCP connections
# -u: UDP connections
# -l: listening ports
# -n: show numeric addresses
```

The first value is the host port and the second value is the container port.

<br>
<br>

**volumes**: This section defines persistent storage for containers.
- Grafana stores dashboards and configuration data in **`/var/lib/grafana`**. Without a volume, dashboards would disappear when the container restarts.

<br>
<br>

## 6. Starting the monitoring stack

Once all files are ready, start the containers.

```bash
docker compose up -d
```

**Explanation:**
- **`up`** starts the containers defined in **`docker-compose.yml`**
- **`-d`** runs them in detached mode, meaning they run in the background.

**Check running containers:**

```bash
docker ps
```

**Expected containers:**

- kafka-exporter
- prometheus
- grafana

<br>
<br>

## 7. Verifying Kafka exporter

Kafka exporter exposes metrics on port 9308.

Test using curl:

```bash
curl localhost:9308/metrics
```

**Example output:**

```bash
kafka_brokers 3
kafka_topic_partitions{topic="orders"} 5
```

This confirms exporter is collecting Kafka metrics successfully.

<br>
<br>

## 8. Accessing Prometheus

**Open Prometheus in browser:**

```bash
http://SERVER-IP:9090
```

**Go to:**

```bash

Status → Targets

```

**You should see:**
```bash

kafka-exporter (UP)

```

This means Prometheus is successfully scraping metrics from Kafka exporter.

<br>
<br>

## 9. Accessing Grafana

**Open Grafana:**

```bash
http://SERVER-IP:3000
```

**Default login:**

```bash
username: admin
password: admin
```

Grafana will ask you to change the password during first login.

<br>
<br>

## 10. Connecting Grafana to Prometheus

**Inside Grafana:**

```bash

Go to Settings → Data Sources

→ Add data source
→ Select Prometheus
```



**Prometheus URL:**

```bash
http://prometheus:9090
```

<mark><b>Because Grafana and Prometheus run inside the same Docker network, Grafana can reach Prometheus using the container name.</b></mark>

```bash

Click Save & Test.

```

If successful, Grafana will confirm the connection.

<br>
<br>

## 11. Importing Kafka dashboards

Grafana dashboards help visualize Kafka metrics clearly.

**Common Kafka dashboards include panels showing:**
- Broker status
- Consumer lag
- Partition distribution
- Message throughput̥

<br>

**Inside Grafana:**

```bash

Go to Dashboards → Import

```

You can import community dashboards from Grafana dashboard repository by entering dashboard ID.

Many Kafka monitoring dashboards are already available publicly.

<br>
<br>

## 12. Checking logs and troubleshooting

If something does not work correctly, check container logs.

**logs:**

```bash
docker logs kafka-exporter
docker logs prometheus
docker logs grafana

================================


# To follow logs in real time:
docker logs -f kafka-exporter

# tail last 100 lines:
docker logs --tail 100 kafka-exporter
```


These logs usually reveal connection problems such as Kafka unreachable or configuration mistakes.

<br>
<br>

## 13. Stopping the stack

To stop the monitoring environment:

```bash
docker compose down
```

This stops and removes all containers defined in the compose file.

Volumes will remain unless explicitly removed.

<br>
<br>

## 14. What a Linux administrator typically maintains

**In production environments Linux administrators usually handle the following tasks:**

- Deploy exporter containers
- Ensure Prometheus can reach exporters
- Monitor container health
- Maintain dashboards
- Create alert rules

They rarely modify application code but instead focus on infrastructure visibility and operational reliability.

<br>
<br>

## 15. Quick recap
- Kafka generates operational metrics.
- Kafka exporter collects those metrics.
- Prometheus stores them as time‑series monitoring data.
- Grafana visualizes the metrics in dashboards.
- Using Docker Compose allows the entire monitoring stack to run together in a simple and reproducible environment.
