#!/usr/bin/env bash
# Tests check-billing.sh against a fake `aws` command, so nothing real is created or billed.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

make_fake_aws() {
  # $1 = what describe-load-balancers should return ("" for nothing)
  cat > "$tmp/aws" << FAKE
#!/usr/bin/env bash
case "\$*" in
  *"sts get-caller-identity"*) exit 0 ;;
  *"describe-load-balancers"*) echo "$1" ;;
  *) ;;
esac
FAKE
  chmod +x "$tmp/aws"
}

failures=0

make_fake_aws "fake-alb"
out="$(PATH="$tmp:$PATH" "$here/check-billing.sh")"; code=$?
if [ "$code" -eq 1 ] && echo "$out" | grep -q "STILL RUNNING - load balancers"; then
  echo "PASS: reports a running load balancer (exit 1)"
else
  echo "FAIL: expected exit 1 and a load balancer warning, got exit $code"; failures=1
fi

make_fake_aws ""
out="$(PATH="$tmp:$PATH" "$here/check-billing.sh")"; code=$?
if [ "$code" -eq 0 ] && echo "$out" | grep -q "RESULT: all clear"; then
  echo "PASS: reports all clear when nothing is running (exit 0)"
else
  echo "FAIL: expected exit 0 and all clear, got exit $code"; failures=1
fi

exit "$failures"
