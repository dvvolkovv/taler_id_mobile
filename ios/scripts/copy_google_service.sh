#!/bin/bash
# Copy the correct GoogleService-Info.plist based on build configuration
if [[ "${CONFIGURATION}" == *"-dev"* ]] || [[ "${PRODUCT_BUNDLE_IDENTIFIER}" == *".dev"* ]]; then
    PLIST_SOURCE="${PROJECT_DIR}/Runner/Firebase/dev/GoogleService-Info.plist"
    echo "Using DEV GoogleService-Info.plist"
elif [[ "${CONFIGURATION}" == *"-talerid"* ]] || [[ "${PRODUCT_BUNDLE_IDENTIFIER}" == "io.talerid.app" ]]; then
    PLIST_SOURCE="${PROJECT_DIR}/Runner/Firebase/talerid/GoogleService-Info.plist"
    echo "Using TALERID GoogleService-Info.plist"
else
    PLIST_SOURCE="${PROJECT_DIR}/Runner/Firebase/prod/GoogleService-Info.plist"
    echo "Using PROD GoogleService-Info.plist"
fi

PLIST_DEST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

if [ -f "${PLIST_SOURCE}" ]; then
    cp "${PLIST_SOURCE}" "${PLIST_DEST}"
    echo "Copied ${PLIST_SOURCE} -> ${PLIST_DEST}"
else
    echo "WARNING: ${PLIST_SOURCE} not found, using default"
fi
