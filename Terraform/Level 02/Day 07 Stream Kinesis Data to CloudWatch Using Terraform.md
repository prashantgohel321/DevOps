# Terraform Level 02 Day 07: Stream Kinesis Data to CloudWatch

This document outlines the solution for Terraform Level 02 Day 07. The objective was to enhance infrastructure observability by provisioning an Amazon Kinesis Data Stream and configuring a CloudWatch Alarm to detect when write throughput exceeds provisioned limits.

## Table of Contents
- [Terraform Level 02 Day 07: Stream Kinesis Data to CloudWatch](#terraform-level-02-day-07-stream-kinesis-data-to-cloudwatch)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create Infrastructure (`main.tf`)](#1-create-infrastructure-maintf)
    - [2. Define Outputs (`outputs.tf`)](#2-define-outputs-outputstf)
    - [3. Execution and Validation](#3-execution-and-validation)
  - [Deep Dive: Kinesis Monitoring \& Metrics](#deep-dive-kinesis-monitoring--metrics)
    - [WriteProvisionedThroughputExceeded](#writeprovisionedthroughputexceeded)
    - [Shard-Level Metrics](#shard-level-metrics)
    - [CloudWatch Alarm Thresholds](#cloudwatch-alarm-thresholds)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision a monitored Kinesis stream and a CloudWatch alarm.

* **Working Directory:** `/home/bob/terraform`
* **Kinesis Stream:** `xfusion-kinesis-stream` with Shard Count: 1.
* **CloudWatch Alarm:** `xfusion-kinesis-alarm` monitoring the `WriteProvisionedThroughputExceeded` metric.
* **Outputs Required:**
    * `kke_kinesis_stream_name`
    * `kke_kinesis_alarm_name`

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create Infrastructure (`main.tf`)
<a name="1-create-infrastructure"></a>
This file initializes the AWS provider, creates the Kinesis Data Stream with shard-level metrics enabled, and configures the CloudWatch alarm.

**Command:**
```bash
cd /home/bob/terraform
vi main.tf
```

**Content:**
```hcl
provider "aws" {
  region = "us-east-1"
}

# 1. Create Kinesis Data Stream
resource "aws_kinesis_stream" "xfusion_kinesis" {
  name             = "xfusion-kinesis-stream"
  shard_count      = 1
  retention_period = 24

  # Enable monitoring for throughput errors
  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
    "WriteProvisionedThroughputExceeded"
  ]
}

# 2. Create CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "kinesis_alarm" {
  alarm_name          = "xfusion-kinesis-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = "60" # 1 minute
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Monitoring write throughput exceeding provisioned limits"

  dimensions = {
    StreamName = aws_kinesis_stream.xfusion_kinesis.name
  }
}
```

### 2. Define Outputs (`outputs.tf`)
<a name="2-define-outputs"></a>
Export the required identifiers for validation.

**Command:**
```bash
vi outputs.tf
```

**Content:**
```hcl
output "kke_kinesis_stream_name" {
  value = aws_kinesis_stream.xfusion_kinesis.name
}

output "kke_kinesis_alarm_name" {
  value = aws_cloudwatch_metric_alarm.kinesis_alarm.alarm_name
}
```

### 3. Execution and Validation
<a name="3-execution-and-validation"></a>
Follow the standard Terraform lifecycle to deploy the monitoring stack.

1.  **Initialize:** `terraform init`
2.  **Plan:** `terraform plan` (Verify 2 resources to add).
3.  **Apply:** `terraform apply -auto-approve`
4.  **Verification:** Run `terraform output` to see the results.

**Final Check:**
Run `terraform plan` again. It must return:
**"No changes. Your infrastructure matches the configuration."**

---

## Deep Dive: Kinesis Monitoring & Metrics
<a name="deep-dive-kinesis-monitoring"></a>

### WriteProvisionedThroughputExceeded
This metric is critical for Kinesis health. Amazon Kinesis Data Streams limits the throughput per shard (1 MB/sec or 1,000 records/sec for writes). When your producer sends data faster than the shard can handle, Kinesis throttles the request and increments this metric.

### Shard-Level Metrics
By default, Kinesis provides stream-level metrics every minute at no charge. However, to pinpoint which specific shard is overwhelmed, we enabled `shard_level_metrics`. This provides granular visibility into the performance of individual shards within the stream.

### CloudWatch Alarm Thresholds
We configured the alarm with `statistic = "Sum"` and `threshold = "1"`. This means if even a single record is throttled within a 1-minute period, the alarm will trigger. In a high-traffic production environment, you might set this threshold higher to avoid "noisy" alerts for minor, transient spikes.
 
