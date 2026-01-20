# DevOps Day 100: Create and Configure Alarm Using CloudWatch Using Terraform

This document outlines the solution for DevOps Day 100. The objective was to enhance operational monitoring by creating an EC2 instance and a corresponding CloudWatch alarm. This alarm monitors CPU utilization and triggers an alert via SNS if the threshold is breached.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Create Infrastructure (`main.tf`)](#1-create-infrastructure-maintf)
    * [2. Define Outputs (`outputs.tf`)](#2-define-outputs-outputstf)
    * [3. Initialize and Apply](#3-initialize-and-apply)
3.  [Deep Dive: Terraform Concepts Used](#deep-dive-terraform-concepts-used)
    * [SNS Topic Resource](#sns-topic-resource)
    * [CloudWatch Metric Alarm](#cloudwatch-metric-alarm)
4.  [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision an EC2 instance and a CloudWatch CPU utilization alarm.

**Requirements:**
1.  **EC2 Instance:** `xfusion-ec2` (AMI: `ami-0c02fb55956c7d316`, Type: `t2.micro`).
2.  **SNS Topic:** `xfusion-sns-topic` (Already exists or needs creation for the alarm action).
3.  **CloudWatch Alarm:** `xfusion-alarm`.
    * **Metric:** CPUUtilization >= 90%.
    * **Period:** 5 minutes (300 seconds).
    * **Action:** Notify the SNS topic.
4.  **Outputs:** Export the instance name and alarm name.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create Infrastructure (`main.tf`)
<a name="1-create-infrastructure-maintf"></a>
The configuration creates the SNS topic (to ensure we have a valid ARN for the alarm), the EC2 instance, and the CloudWatch alarm linked to that specific instance.

**Command:**
```bash
cd /home/bob/terraform
vi main.tf
```

**Content:**
```hcl
# 1. Create SNS Topic for Notifications
resource "aws_sns_topic" "sns_topic" {
  name = "xfusion-sns-topic"
}

# 2. Launch EC2 Instance
resource "aws_instance" "nautilus_node" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  tags = {
    Name = "xfusion-ec2"
  }
}

# 3. Create CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_alert" {
  alarm_name          = "xfusion-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "Alarm when CPU exceeds 90%"
  
  # Actions to take when the alarm state changes to ALARM
  alarm_actions       = [aws_sns_topic.sns_topic.arn]

  # Dimensions map the metric to a specific resource (our EC2 instance)
  dimensions = {
    InstanceId = aws_instance.nautilus_node.id
  }
}
```

### 2. Define Outputs (`outputs.tf`)
<a name="2-define-outputs-outputstf"></a>
We define outputs to confirm the resource creation names.

**Command:**
```bash
vi outputs.tf
```

**Content:**
```hcl
output "KKE_instance_name" {
  value = aws_instance.nautilus_node.tags.Name
}

output "KKE_alarm_name" {
  value = aws_cloudwatch_metric_alarm.cpu_alert.alarm_name
}
```

### 3. Initialize and Apply
<a name="3-initialize-and-apply"></a>
Run the Terraform workflow to deploy the monitoring stack.

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

**Verification:**
```bash
terraform state list
# Expected:
# aws_cloudwatch_metric_alarm.cpu_alert
# aws_instance.nautilus_node
# aws_sns_topic.sns_topic
```

---

## Deep Dive: Terraform Concepts Used
<a name="deep-dive-terraform-concepts-used"></a>

### SNS Topic Resource
<a name="sns-topic-resource"></a>
* **`aws_sns_topic`**: Simple Notification Service. It acts as a pub/sub messaging channel. In this context, CloudWatch "publishes" an alarm message to this topic, and any subscribers (email, SMS, Lambda) would receive it.

### CloudWatch Metric Alarm
<a name="cloudwatch-metric-alarm"></a>
* **`aws_cloudwatch_metric_alarm`**: Defines the rule for monitoring.
* **`metric_name` & `namespace`**: These define *what* to watch. `AWS/EC2` and `CPUUtilization` are standard metrics provided by the AWS hypervisor.
* **`dimensions`**: This is critical. Without dimensions, CloudWatch looks at the aggregate CPU of *all* instances. By specifying `InstanceId`, we target only the specific instance we just created.
* **`alarm_actions`**: Links the alarm to the SNS topic ARN.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: Invalid AMI**
* **Cause:** The AMI ID `ami-0c02fb55956c7d316` might not exist in the configured region if it's not `us-east-1` (or if the AMI is deprecated).
* **Fix:** Ensure the provider region matches the region where the AMI exists.

**Issue: Alarm stuck in "Insufficient Data"**
* **Cause:** This is normal immediately after creation. It takes at least one period (300 seconds/5 minutes) for CloudWatch to gather enough data points to evaluate the state.
  
