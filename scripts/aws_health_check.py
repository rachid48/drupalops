#!/usr/bin/env python3
"""Read-only health check for the DrupalOps AWS infrastructure."""

import argparse
import os
import sys
import time

import boto3
from botocore.exceptions import BotoCoreError, ClientError


DEFAULT_ALARMS = (
    "drupalops-apache-down",
    "drupalops-high-5xx-errors",
    "drupalops-high-cpu",
    "drupalops-high-disk",
    "drupalops-high-memory",
)


def check_asg(client, asg_name):
    """Return whether the ASG has its desired number of healthy instances."""
    response = client.describe_auto_scaling_groups(
        AutoScalingGroupNames=[asg_name]
    )
    groups = response["AutoScalingGroups"]
    if not groups:
        print(f"ASG:        UNHEALTHY ({asg_name} not found)")
        return False

    group = groups[0]
    desired = group["DesiredCapacity"]
    healthy = sum(
        instance["LifecycleState"] == "InService"
        and instance["HealthStatus"] == "Healthy"
        for instance in group["Instances"]
    )
    status = "HEALTHY" if desired > 0 and healthy >= desired else "UNHEALTHY"
    print(f"ASG:        {status} ({healthy}/{desired} healthy and InService)")
    return status == "HEALTHY"


def check_target_group(client, target_group_name):
    """Return whether every registered ALB target is healthy."""
    response = client.describe_target_groups(Names=[target_group_name])
    target_group_arn = response["TargetGroups"][0]["TargetGroupArn"]
    descriptions = client.describe_target_health(
        TargetGroupArn=target_group_arn
    )["TargetHealthDescriptions"]

    states = [target["TargetHealth"]["State"] for target in descriptions]
    healthy = sum(state == "healthy" for state in states)
    status = "HEALTHY" if states and healthy == len(states) else "UNHEALTHY"
    print(f"ALB target: {status} ({healthy}/{len(states)} healthy)")
    return status == "HEALTHY"


def check_alarms(client, alarm_names):
    """Return whether all expected CloudWatch alarms exist and are OK."""
    response = client.describe_alarms(AlarmNames=list(alarm_names))
    states = {alarm["AlarmName"]: alarm["StateValue"] for alarm in response["MetricAlarms"]}

    healthy = True
    print("Alarms:")
    for name in alarm_names:
        state = states.get(name, "MISSING")
        print(f"  - {name}: {state}")
        healthy = healthy and state == "OK"
    return healthy


def run_check(session, args):
    """Run all checks once and return the combined result."""
    asg_ok = check_asg(session.client("autoscaling"), args.asg_name)
    target_ok = check_target_group(
        session.client("elbv2"), args.target_group_name
    )
    alarms_ok = check_alarms(session.client("cloudwatch"), DEFAULT_ALARMS)
    return asg_ok and target_ok and alarms_ok


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--region", default=os.getenv("AWS_REGION", "eu-west-3")
    )
    parser.add_argument("--profile", help="Optional local AWS CLI profile")
    parser.add_argument("--asg-name", default="drupal-asg")
    parser.add_argument("--target-group-name", default="drupal-tg")
    parser.add_argument("--attempts", type=int, default=1)
    parser.add_argument("--interval", type=int, default=30)
    return parser.parse_args()


def main():
    args = parse_args()
    if args.attempts < 1 or args.interval < 0:
        print("Error: --attempts must be >= 1 and --interval must be >= 0")
        return 2

    session = boto3.Session(profile_name=args.profile, region_name=args.region)

    try:
        for attempt in range(1, args.attempts + 1):
            print(f"\nDrupalOps health check ({args.region}) - attempt {attempt}/{args.attempts}")
            if run_check(session, args):
                print("Overall:    HEALTHY")
                return 0

            print("Overall:    UNHEALTHY")
            if attempt < args.attempts:
                print(f"Retrying in {args.interval} seconds...")
                time.sleep(args.interval)
    except (BotoCoreError, ClientError) as error:
        print(f"AWS API error: {error}")

    return 1


if __name__ == "__main__":
    sys.exit(main())
