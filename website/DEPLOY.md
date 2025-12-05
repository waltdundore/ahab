# Ahab Software Website - Deployment Instructions

## Website Files

The Ahab Software website files are in this directory:
- `index.html` - Main website page
- `style.css` - Stylesheet

## Deployment Steps

### 1. Copy Files to GitHub Pages Repository

```bash
# Copy website files
cp ~/git/DockMaster/ansible-control/website/index.html ~/git/DockMaster/waltdundore.github.io/
cp ~/git/DockMaster/ansible-control/website/style.css ~/git/DockMaster/waltdundore.github.io/
```

### 2. Commit and Push

```bash
cd ~/git/DockMaster/waltdundore.github.io

# Check status
git status

# Add files
git add index.html style.css

# Commit
git commit -m "Update to Ahab Software, LLC website"

# Push
git push origin main
```

### 3. Verify Deployment

After pushing, the website will be live at:
- https://waltdundore.github.io

GitHub Pages typically updates within 1-2 minutes.

## Website Features

### Hero Section
- Ahab logo (from ansible-control/prod branch)
- Project name and tagline
- Professional gradient background

### About Section
- Project description
- Three key features with icons:
  - Multi-Distribution Support
  - Environment Management
  - Security First

### Repositories Section
- Cards for all three repositories:
  - Ahab Control
  - Ahab Inventory
  - Ahab Config
- Direct links to GitHub repos

### Quick Start Section
- Code block with setup instructions
- Copy-paste ready commands

### Footer
- Company information: Ahab Software, LLC
- Website: ahabsoftware.com
- Links to resources
- Social media links (GitHub, LinkedIn)
- Copyright notice

## Customization

### Colors
The website uses the Ahab brand colors:
- Navy: `#3d5a6c`
- Slate: `#5a7a8c`
- Light Blue: `#8ba9bc`
- Dark backgrounds for contrast

### Logo
The logo is loaded from:
```
https://raw.githubusercontent.com/waltdundore/ansible-control/prod/docs/images/ahab-logo.png
```

Make sure the logo is committed to the prod branch before deploying the website.

### Responsive Design
The website is fully responsive and works on:
- Desktop (1200px+)
- Tablet (768px - 1199px)
- Mobile (< 768px)

## Maintenance

### Updating Content

To update the website:
1. Edit files in `ansible-control/website/`
2. Copy to `waltdundore.github.io/`
3. Commit and push

### Adding New Sections

Follow the existing pattern:
- Use semantic HTML5 tags (`<section>`, `<footer>`, etc.)
- Apply consistent spacing (80px padding)
- Use brand colors from CSS variables
- Maintain responsive design

## Domain Setup (Future)

To use ahabsoftware.com:

1. **Purchase domain** at registrar (Namecheap, GoDaddy, etc.)

2. **Configure DNS** with these records:
   ```
   A     @     185.199.108.153
   A     @     185.199.109.153
   A     @     185.199.110.153
   A     @     185.199.111.153
   CNAME www   waltdundore.github.io
   ```

3. **Add CNAME file** to repository:
   ```bash
   echo "ahabsoftware.com" > ~/git/DockMaster/waltdundore.github.io/CNAME
   git add CNAME
   git commit -m "Add custom domain"
   git push
   ```

4. **Enable HTTPS** in GitHub Pages settings

5. **Wait for DNS propagation** (up to 24 hours)

## Troubleshooting

### Logo Not Displaying
- Verify logo exists in ansible-control prod branch
- Check URL in index.html
- Clear browser cache

### Styles Not Applied
- Verify style.css is in same directory as index.html
- Check browser console for errors
- Clear browser cache

### GitHub Pages Not Updating
- Check GitHub Actions tab for build status
- Verify files are in main/master branch
- Wait 1-2 minutes for deployment

## Current Status

✅ Website files created  
✅ Responsive design implemented  
✅ Ahab branding applied  
⚠️ Needs deployment to waltdundore.github.io  
⚠️ Logo needs to be in prod branch  

## Next Steps

1. Deploy logo to ansible-control prod branch
2. Copy website files to waltdundore.github.io
3. Commit and push
4. Verify at https://waltdundore.github.io
5. (Optional) Set up custom domain ahabsoftware.com
