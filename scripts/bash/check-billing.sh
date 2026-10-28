#!/usr/bin/env bash
# Lists resources that bill by the hour and are still running in the Shipit account.
# Exit codes: 0 = all clear, 1 = something is still running, 2 = could not check.
set -uo pipefail

REGION="${AWS_REGION:-eu-west-2}"
export AWS_PAGER=""

# Use a named profile if one is set; otherwise use credentials from the environment
# (which is how Jenkins provides them).
aws_cmd() {
  if [ -n "${AWS_PROFILE:-}" ]; then
    aws --profile "$AWS_PROFILE" --region "$REGION" "$@"
  else
    aws --region "$REGION" "$@"
  fi
}

if ! aws_cmd sts get-caller-identity > /dev/null 2>&1; then
  echo "ERROR: cannot reach AWS. On a laptop try: aws sso login --profile shipit" >&2
  exit 2
fi

found=0

# check "<label>" <command...>  -> prints a line, sets found=1 if the command returns anything
check() {
  local label="$1"
  shift
  local out
  if ! out=$("$@" 2>&1); then
    echo "ERROR: check failed for $label: $out" >&2
    exit 2
  fi
  if [ -n "$out" ] && [ "$out" != "None" ]; then
    echo "STILL RUNNING - $label:"
    echo "$out" | sed 's/^/    /'
    found=1
  else
    echo "ok - no $label"
  fi
}

running_tasks() {
  local cluster
  for cluster in $(aws_cmd ecs list-clusters --query "clusterArns[]" --output text); do
    aws_cmd ecs list-tasks --cluster "$cluster" --desired-status RUNNING \
      --query "taskArns[]" --output text
  done
}

check "load balancers" \
  aws_cmd elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerName" --output text
check "NAT gateways" \
  aws_cmd ec2 describe-nat-gateways --filter "Name=state,Values=available,pending" \
    --query "NatGateways[].NatGatewayId" --output text
check "ECS tasks" running_tasks
check "EC2 instances" \
  aws_cmd ec2 describe-instances --filters "Name=instance-state-name,Values=running,pending" \
    --query "Reservations[].Instances[].InstanceId" --output text
check "RDS databases" \
  aws_cmd rds describe-db-instances --query "DBInstances[].DBInstanceIdentifier" --output text
check "unattached Elastic IPs" \
  aws_cmd ec2 describe-addresses --query "Addresses[?AssociationId==null].PublicIp" --output text

echo
if [ "$found" -eq 1 ]; then
  echo "RESULT: billable resources are still running"
  exit 1
fi
echo "RESULT: all clear"
