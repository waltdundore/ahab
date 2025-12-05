#!/bin/bash
# ==============================================================================
# Ahab Control - Update README Footers
# ==============================================================================
# Automated Host Administration & Build
# Adds company information footer to all repository README files

set -e

FOOTER='

---

## About

**Ahab Software, LLC**  
Automated Host Administration & Build

Website: [ahabsoftware.com](https://ahabsoftware.com)  
GitHub: [github.com/waltdundore](https://github.com/waltdundore)

© 2024 Ahab Software, LLC. All rights reserved.
'

echo "Updating README footers with company information..."

# Update ansible-inventory
if [ -f "../ansible-inventory/README.md" ]; then
    if ! grep -q "Ahab Software, LLC" "../ansible-inventory/README.md"; then
        echo "$FOOTER" >> "../ansible-inventory/README.md"
        echo "✓ Updated ansible-inventory/README.md"
    else
        echo "✓ ansible-inventory/README.md already has footer"
    fi
fi

# Update ansible-config
if [ -f "../ansible-config/README.md" ]; then
    if ! grep -q "Ahab Software, LLC" "../ansible-config/README.md"; then
        echo "$FOOTER" >> "../ansible-config/README.md"
        echo "✓ Updated ansible-config/README.md"
    else
        echo "✓ ansible-config/README.md already has footer"
    fi
fi

# ansible-control is already updated
echo "✓ ansible-control/README.md already has footer"

echo ""
echo "All README files updated with company information!"
echo ""
echo "Next steps:"
echo "1. Review the changes in each repository"
echo "2. Commit to dev branch"
echo "3. Push to GitHub"
