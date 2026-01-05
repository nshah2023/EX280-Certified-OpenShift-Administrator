#!/bin/bash

# OpenShift Network Policy Automation Script
# Usage: ./network-automation.sh [apply|delete|status] [environment]

ENVIRONMENT=${2:-dev}
ACTION=${1:-status}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}OpenShift Network Automation Tool${NC}"
echo -e "Environment: ${ENVIRONMENT}"
echo -e "Action: ${ACTION}\n"

apply_policies() {
    echo -e "${GREEN}[INFO]${NC} Applying network policies for ${ENVIRONMENT}..."

    # Apply default deny-all first
    oc apply -f network-policy-template.yaml

    # Label the namespace for policy selection
    oc label namespace $(oc project -q) environment=${ENVIRONMENT} --overwrite

    # Verify policies
    echo -e "\n${GREEN}[SUCCESS]${NC} Network policies applied!"
    oc get networkpolicies
}

delete_policies() {
    echo -e "${RED}[INFO]${NC} Removing network policies..."
    oc delete networkpolicies --all
    echo -e "${GREEN}[SUCCESS]${NC} Network policies removed!"
}

check_status() {
    echo -e "${BLUE}[STATUS]${NC} Current network policies:"
    oc get networkpolicies -o wide

    echo -e "\n${BLUE}[STATUS]${NC} Pod connectivity test:"
    # Test connectivity between pods
    PODS=$(oc get pods -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    if [ ! -z "$PODS" ]; then
        for POD in $PODS; do
            echo "Testing pod: $POD"
            oc exec $POD -- nc -z -w3 google.com 80 2>/dev/null && \
                echo -e "  ${GREEN}✓${NC} External connectivity: OK" || \
                echo -e "  ${RED}✗${NC} External connectivity: BLOCKED"
        done
    else
        echo -e "  ${RED}✗${NC} No pods found to test"
    fi
}

case $ACTION in
    apply)
        apply_policies
        ;;
    delete)
        delete_policies
        ;;
    status)
        check_status
        ;;
    *)
        echo "Usage: $0 [apply|delete|status] [environment]"
        echo "  apply  - Apply network policies"
        echo "  delete - Remove all network policies"
        echo "  status - Show current policies and test connectivity"
        exit 1
        ;;
esac