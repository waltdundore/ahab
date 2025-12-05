---
# Ahab Branding Guidelines

## Company Information

**Legal Name:** Ahab Software, LLC  
**Website:** ahabsoftware.com  
**Copyright:** © 2024 Ahab Software, LLC. All rights reserved.

## Project Name

**Official Name:** Ahab  
**Full Name:** Automated Host Administration & Build  
**Acronym:** AHAB

## Usage

### In Documentation
- **Headers:** Use "Ahab" followed by component name
  - "Ahab Control"
  - "Ahab Inventory"
  - "Ahab Config"

### In Code/Comments
- **Makefiles:** "Ahab [Component] - Makefile"
- **Scripts:** Include "Ahab" in header comments
- **Configuration:** Use "ahab" in lowercase for filenames

### In README Files
Always include the full branding block at the top:

```markdown
<div align="center">

# Ahab [Component]

![Ahab Logo](https://raw.githubusercontent.com/waltdundore/ansible-control/prod/docs/images/ahab-logo.png)

**Automated Host Administration & Build**

*[Component description]*

</div>

---
```

## Logo

### File Information
- **Filename:** `ahab-logo.png`
- **Location:** `ansible-control/docs/images/ahab-logo.png`
- **Format:** PNG with background
- **Dimensions:** 1024x1024px
- **Colors:** Navy blue (#3d5a6c), slate blue (#5a7a8c), white (#ffffff)

### Logo Design
- **Theme:** Captain Ahab from Moby Dick - command, control, mastery
- **Elements:** 
  - Silhouette of Captain Ahab with harpoon
  - Ship and sails in background
  - Ocean waves at bottom
  - Oval frame
- **Text:** "AHAB" in bold white letters with full name below

### Logo Usage

#### In README Files
All three repository README files must display the logo:

```markdown
![Ahab Logo](https://raw.githubusercontent.com/waltdundore/ansible-control/prod/docs/images/ahab-logo.png)
```

**Important:** Logo URL points to prod branch for stability.

#### Size Guidelines
- **GitHub README:** Full size (displays at ~600px wide automatically)
- **Documentation:** Can be resized with HTML if needed:
  ```html
  <img src="..." width="400" alt="Ahab Logo">
  ```

### Logo Colors

**Primary Palette:**
- **Dark Navy:** `#3d5a6c` - Background, primary brand color
- **Slate Blue:** `#5a7a8c` - Accents, secondary elements
- **Light Blue:** `#8ba9bc` - Highlights, ship sails
- **White:** `#ffffff` - Text, contrast elements

**Usage:**
- Use navy blue for professional, serious contexts
- White text on navy background for high contrast
- Slate blue for UI elements and accents

## Taglines

### Primary Tagline
**"Automated Host Administration & Build"**

Use this as the main descriptor in all official documentation.

### Component Taglines

**Ahab Control:**
- Primary: "Automated Host Administration & Build"
- Secondary: "Ansible-based infrastructure automation for provisioning and managing Linux systems"

**Ahab Inventory:**
- Primary: "Automated Host Administration & Build - Inventory"
- Secondary: "Environment-specific host definitions"

**Ahab Config:**
- Primary: "Automated Host Administration & Build - Config"
- Secondary: "Configuration settings"

## Naming Conventions

### Repository Names
- `ansible-control` (keep existing GitHub repo name)
- `ansible-inventory` (keep existing GitHub repo name)
- `ansible-config` (keep existing GitHub repo name)

**Note:** GitHub repository names remain unchanged for URL stability. Branding is applied in README files and documentation.

### Company References

Always use the full legal name in:
- Copyright notices: "© 2024 Ahab Software, LLC"
- Legal documents
- Footer sections
- LICENSE files

Website reference:
- Use: "ahabsoftware.com" (no www, no https://)

### File Naming
- **Logo:** `ahab-logo.png` (lowercase)
- **Documentation:** Use descriptive names with context
- **Scripts:** Prefix with component if needed: `ahab-deploy.sh`

### Branch Names
- `prod` - Production branch
- `dev` - Development branch
- `workstation` - Local workstation branch

## Documentation Standards

### README Structure

Every repository README must follow this structure:

1. **Branding Header** (centered, with logo)
2. **Horizontal rule** (`---`)
3. **Repository Dependencies** (if applicable)
4. **Quick Setup** section
5. **Branch Structure** section
6. **Usage** section
7. **Configuration** section
8. **Available Commands** section

### Makefile Headers

All Makefiles must include:

```makefile
# ==============================================================================
# Ahab [Component] - Makefile
# ==============================================================================
# Automated Host Administration & Build
# [Brief description of what this Makefile does]
```

### Script Headers

All shell scripts must include:

```bash
#!/bin/bash
# ==============================================================================
# Ahab [Component] - [Script Name]
# ==============================================================================
# Automated Host Administration & Build
# [Brief description of what this script does]
```

## Consistency Requirements

### Across All Repositories

All three repositories must maintain consistent:
- Logo display (same URL, same placement)
- Tagline usage
- Color scheme in documentation
- Header formatting
- Makefile structure

### In User-Facing Content

- Always spell "Ahab" correctly (capital A, lowercase hab)
- Always include full name on first mention: "Ahab (Automated Host Administration & Build)"
- Use "Ahab" alone in subsequent mentions
- Never abbreviate to "AHB" or other variations

## Theme and Voice

### Project Theme
**Nautical/Maritime Command & Control**

The Ahab branding evokes:
- **Command:** Captain at the helm, directing operations
- **Control:** Mastery over complex systems (like commanding a ship)
- **Determination:** Ahab's focused pursuit of his goal
- **Automation:** Systematic, repeatable processes

### Voice and Tone

**Professional but Approachable:**
- Technical accuracy without jargon overload
- Clear, direct instructions
- Helpful, not condescending
- Confident, not arrogant

**Example Good:**
> "Ahab automates your infrastructure deployment with Ansible, making it easy to manage multiple hosts across different environments."

**Example Bad:**
> "AHAB is the ultimate solution for all your infrastructure needs!!!"

## Logo Placement

### Required Locations

The Ahab logo MUST appear in:
1. ✅ `ansible-control/README.md` (top, centered)
2. ✅ `ansible-inventory/README.md` (top, centered)
3. ✅ `ansible-config/README.md` (top, centered)
4. ✅ `ansible-control/docs/images/ahab-logo.png` (actual file)

### Optional Locations

The logo MAY appear in:
- Documentation pages (if helpful for branding)
- Presentation materials
- Wiki pages (if created)

### Prohibited Locations

Do NOT include the logo in:
- Source code files
- Configuration files
- Log files
- Temporary files

## Updating Branding

### When to Update

Update branding when:
- Creating new repositories
- Adding new documentation
- Creating new scripts or tools
- Updating README files

### How to Update

1. **Check this file** for current branding guidelines
2. **Use the logo** from `ansible-control/docs/images/ahab-logo.png`
3. **Follow the templates** provided in this document
4. **Maintain consistency** across all three repositories

### Branding Checklist

When adding Ahab branding to a file:

- [ ] Logo displayed (if README)
- [ ] "Ahab [Component]" in header
- [ ] "Automated Host Administration & Build" tagline included
- [ ] Consistent formatting with other repos
- [ ] Logo URL points to prod branch
- [ ] Colors match brand palette (if applicable)
- [ ] Voice and tone appropriate

## Examples

### Complete README Header

```markdown
<div align="center">

# Ahab Control

![Ahab Logo](https://raw.githubusercontent.com/waltdundore/ansible-control/prod/docs/images/ahab-logo.png)

**Automated Host Administration & Build**

*Ansible-based infrastructure automation for provisioning and managing Linux systems*

</div>

---
```

### Makefile Header

```makefile
# ==============================================================================
# Ahab Control - Makefile
# ==============================================================================
# Automated Host Administration & Build
# Automates Vagrant VM management, Ansible deployments, and Git workflows
```

### Script Header

```bash
#!/bin/bash
# ==============================================================================
# Ahab Control - Security Scan
# ==============================================================================
# Automated Host Administration & Build
# Scans for security vulnerabilities before committing code
```

## Anti-Patterns

### Don't Do This

❌ Inconsistent capitalization: "ahab", "AHAB", "AHab"  
❌ Wrong tagline: "Automated Build and Host Administration"  
❌ Missing logo in README files  
❌ Logo pointing to dev branch instead of prod  
❌ Using old "DockMaster" branding  
❌ Abbreviating to "AHB" or other acronyms  
❌ Different logo sizes across repos  
❌ Inconsistent header formatting  

### Do This Instead

✅ Always: "Ahab" (capital A, lowercase hab)  
✅ Correct tagline: "Automated Host Administration & Build"  
✅ Logo in all three README files  
✅ Logo URL: `https://raw.githubusercontent.com/.../prod/docs/images/ahab-logo.png`  
✅ Consistent branding across all repos  
✅ Use full name "Ahab" in documentation  
✅ Same logo display size (let GitHub handle it)  
✅ Follow templates in this document  

## Maintenance

### Regular Checks

Periodically verify:
- Logo displays correctly on GitHub
- All README files have consistent branding
- No old "DockMaster" references remain
- Logo file exists in prod branch
- Logo URL is accessible

### When Adding New Files

1. Check this branding guide first
2. Use appropriate header template
3. Include Ahab branding
4. Maintain consistency with existing files
5. Test logo display (if applicable)

## Website

### Official Website
- **URL:** ahabsoftware.com
- **GitHub Pages:** waltdundore.github.io
- **Purpose:** Single-page marketing site for Ahab software

### Website Requirements

The official website must include:
- Ahab logo prominently displayed
- Project description and tagline
- Links to all three GitHub repositories
- Quick start guide
- Footer with company information

### Footer Requirements

All documentation and websites should include:

```
Ahab Software, LLC
Automated Host Administration & Build
ahabsoftware.com

© 2024 Ahab Software, LLC. All rights reserved.
```

## Summary

**Company:** Ahab Software, LLC  
**Website:** ahabsoftware.com  
**Project Name:** Ahab (Automated Host Administration & Build)  
**Theme:** Nautical command and control  
**Logo:** Captain Ahab silhouette with ship and harpoon  
**Colors:** Navy blue, slate blue, white  
**Voice:** Professional, clear, helpful  

All documentation, code, and user-facing content must follow these branding guidelines to maintain a consistent, professional appearance across the entire Ahab project.
