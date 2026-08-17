#!/usr/bin/env bash
# install-omnistudio-components.sh
#
# Fetches the minimum required OmniStudio base LWC components from the
# @omnistudio/omniscript_customization npm package and copies them into
# the SFDX project so the project can be deployed to any org.
#
# Requires: npm, an NPM access key from Salesforce Customer Support
#
# Usage:
#   bash scripts/install-omnistudio-components.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="$PROJECT_ROOT/force-app/main/default"
WORK_DIR="$(mktemp -d)"

# Required components — minimum transitive dependency closure for StepChart override
COMPONENTS=(
    asyncUtils
    buffer
    dayjs
    expressionEngine
    lodash
    navigationUtils
    nearley
    newportLoader
    oaUtils
    oaVtag
    omniscriptActionUtils
    omniscriptBaseMixin
    omniscriptFormattedRichText
    omniscriptInternalUtils
    omniscriptRestApi
    omniscriptRestApiUtilsForCore
    omniscriptStepChart
    omniscriptStepChartItems
    omniscriptTrackingServiceUtils
    omniscriptUtils
    pubsub
    salesforceUtils
)

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo ""
echo "OmniStudio Component Installer"
echo "================================"
echo "This script requires an NPM access key obtained from Salesforce Customer Support."
echo "See: https://help.salesforce.com/s/articleView?id=xcloud.os_standard_set_up_your_environment_for_customizing_omniscript_elements.htm"
echo ""
read -rp "Enter your NPM access key: " NPM_KEY

if [ -z "$NPM_KEY" ]; then
    echo "Error: NPM access key is required."
    exit 1
fi

echo ""
echo "Installing @omnistudio/omniscript_customization@254.0.0 ..."

cat > "$WORK_DIR/.npmrc" << EOF
always-auth=true
registry=https://repo.vlocity.com/repository/npm-public/
//repo.vlocity.com/repository/npm-public/:_auth="${NPM_KEY}"
EOF

cd "$WORK_DIR"
npm install @omnistudio/omniscript_customization@254.0.0 --silent

PKG="$WORK_DIR/node_modules/@omnistudio/omniscript_customization"

echo "Copying LWC components..."
mkdir -p "$DEST/lwc"
for comp in "${COMPONENTS[@]}"; do
    if [ -d "$PKG/lwc/$comp" ]; then
        cp -r "$PKG/lwc/$comp" "$DEST/lwc/"
        echo "  ✓ $comp"
    else
        echo "  ✗ $comp (not found in package — check package version)"
    fi
done

echo ""
echo "Copying labels..."
mkdir -p "$DEST/labels"
cp "$PKG/labels/CustomLabels.labels" "$DEST/labels/CustomLabels.labels-meta.xml"
echo "  ✓ CustomLabels"

echo ""
echo "Copying message channels..."
mkdir -p "$DEST/messageChannels"
cp "$PKG/messageChannels/"* "$DEST/messageChannels/"
echo "  ✓ omniscriptMessageIn"
echo "  ✓ omniscriptMessageOut"

echo ""
echo "Done. You can now deploy the project:"
echo ""
echo "  sf project deploy start \\"
echo "    --source-dir force-app/main/default/labels \\"
echo "    --target-org <alias>"
echo ""
echo "  sf project deploy start \\"
echo "    --source-dir force-app/main/default/messageChannels \\"
echo "    --target-org <alias>"
echo ""
echo "  sf project deploy start \\"
echo "    --source-dir force-app/main/default/lwc \\"
echo "    --target-org <alias>"
