# Ahab Images

This directory contains branding assets for the Ahab project.

## Logo

**File:** `ahab-logo.png`

**Status:** ✅ Logo file ready to be added

### Logo Details

- **Format:** PNG with background
- **Dimensions:** 1024x1024px
- **Design:** Captain Ahab silhouette with harpoon, ship, and ocean waves
- **Colors:** Navy blue (#3d5a6c), slate blue, white
- **Text:** "AHAB" with "Automated Host Administration & Build" tagline

### How to Add the Logo

1. Save the Ahab logo image (from chat) as `ahab-logo.png`
2. Place it in this directory: `ansible-control/docs/images/`
3. Commit and push to the prod branch:
   ```bash
   cd ~/git/ansible-control
   git checkout prod
   git add docs/images/ahab-logo.png
   git commit -m "Add Ahab logo"
   git push origin prod
   ```

### Logo Usage

The logo is referenced in all three repository README files:
- `ansible-control/README.md`
- `ansible-inventory/README.md`
- `ansible-config/README.md`

All references use the GitHub raw URL pointing to the prod branch:
```
https://raw.githubusercontent.com/waltdundore/ansible-control/prod/docs/images/ahab-logo.png
```

### Logo Requirements

- **Format:** PNG with transparent background
- **Size:** Recommended 400-600px wide
- **Style:** Should represent Docker/container management theme
- **Colors:** Professional, tech-focused palette

## Current Status

✅ Directory structure created
✅ README files updated with logo references
⚠️ Logo image file needs to be added

Once the logo file is added and pushed to prod, it will automatically appear in all three repository README files on GitHub.
