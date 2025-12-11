# Ansible Playbook Audit

![Ahab Logo](../docs/images/ahab-logo.png)

**Date**: December 7, 2025  
**Purpose**: Identify hardcoded values and inefficiencies in Ansible playbooks

---

## Critical Issues Found

### 1. HARDCODED HTML CONTENT (CRITICAL)

**Issue**: Entire HTML pages hardcoded in playbooks

**Locations**:
- `webserver.yml` lines 35-75 - Full HTML page in playbook
- `webserver-docker.yml` lines 25-70 - Full HTML page in playbook

**Problems**:
- HTML mixed with infrastructure code
- Duplicates HTML that already exists in waltdundore.github.io repository
- Can't reuse HTML across playbooks
- Hard to maintain and update
- Violates separation of concerns
- Makes playbooks unreadable

**WE ALREADY HAVE THIS**: https://github.com/waltdundore/waltdundore.github.io

**Should Be**: Use existing website repository, don't recreate HTML

**Fix**:
```yaml
# Option 1: Clone website repo and copy files
- name: Clone website repository
  ansible.builtin.git:
    repo: https://github.com/waltdundore/waltdundore.github.io.git
    dest: /tmp/website
    version: main

- name: Copy index.html from website repo
  ansible.builtin.copy:
    src: /tmp/website/index.html
    dest: /var/www/html/index.html
    mode: '0644'
    remote_src: true

# Option 2: Download directly from GitHub
- name: Download index.html from website repo
  ansible.builtin.get_url:
    url: https://raw.githubusercontent.com/waltdundore/waltdundore.github.io/main/index.html
    dest: /var/www/html/index.html
    mode: '0644'
```

---

### 2. HARDCODED PATHS (HIGH)

**Issue**: Paths hardcoded instead of using variables

**Examples**:

**webserver.yml**:
- `/var/www/html/index.html` - hardcoded (line 76)

**webserver-docker.yml**:
- `/opt/ahab/apache` - hardcoded (line 18)
- `/opt/ahab/apache/index.html` - hardcoded (line 72)
- `/usr/local/apache2/htdocs/index.html` - hardcoded (line 93)

**workstation.yml**:
- No path variables defined

**Should Be**:
```yaml
vars:
  apache_document_root: /var/www/html
  ahab_base_dir: /opt/ahab
  apache_container_root: /usr/local/apache2/htdocs
```

---

### 3. HARDCODED PACKAGE NAMES (HIGH)

**Issue**: Package names hardcoded, not using variables

**workstation.yml** lines 23-30:
```yaml
- name: Install base development tools
  ansible.builtin.dnf:
    name:
      - git
      - vim
      - curl
      - wget
      - tar
      - unzip
```

**Problems**:
- Can't customize package list
- Can't override for different environments
- Hardcoded to dnf (Fedora only)

**Should Be**:
```yaml
vars:
  workstation_packages:
    - git
    - vim
    - curl
    - wget
    - tar
    - unzip

tasks:
  - name: Install base development tools
    ansible.builtin.package:
      name: "{{ workstation_packages }}"
      state: present
```

---

### 4. HARDCODED DOCKER IMAGES (HIGH)

**Issue**: Docker image versions hardcoded

**webserver-docker.yml** line 86:
```yaml
image: httpd:2.4-alpine
```

**Problems**:
- Can't change version without editing playbook
- No version control
- Can't test different versions

**Should Be**:
```yaml
vars:
  apache_docker_image: httpd:2.4-alpine
  apache_docker_tag: "2.4-alpine"

tasks:
  - name: Run Apache in Docker container
    community.docker.docker_container:
      image: "{{ apache_docker_image }}"
```

---

### 5. HARDCODED PORTS (MEDIUM)

**Issue**: Port numbers hardcoded

**webserver-docker.yml** line 89:
```yaml
ports:
  - "80:80"
```

**Problems**:
- Can't change port without editing playbook
- Port conflicts not configurable

**Should Be**:
```yaml
vars:
  apache_host_port: 80
  apache_container_port: 80

tasks:
  - name: Run Apache in Docker container
    ports:
      - "{{ apache_host_port }}:{{ apache_container_port }}"
```

---

### 6. HARDCODED CONTAINER NAMES (MEDIUM)

**Issue**: Container names hardcoded

**webserver-docker.yml** lines 79, 85:
```yaml
name: ahab-apache
```

**Should Be**:
```yaml
vars:
  apache_container_name: ahab-apache
```

---

### 7. HARDCODED USER NAMES (MEDIUM)

**Issue**: User names hardcoded

**workstation.yml** line 52:
```yaml
name: vagrant
```

**Problems**:
- Assumes vagrant user
- Won't work in other environments

**Should Be**:
```yaml
vars:
  workstation_user: "{{ ansible_user | default('vagrant') }}"
```

---

### 8. DUPLICATE CODE (HIGH)

**Issue**: Same HTML content duplicated across playbooks AND duplicates existing website

**Locations**:
- `webserver.yml` - HTML page (duplicates waltdundore.github.io)
- `webserver-docker.yml` - Nearly identical HTML page (duplicates waltdundore.github.io)
- `ahab/index.html` - Separate HTML file (duplicates waltdundore.github.io)
- `index.html` in root - Another duplicate

**Problems**:
- We already have a website repository: https://github.com/waltdundore/waltdundore.github.io
- Creating duplicate HTML in multiple places
- Update one, must update all others
- Inconsistency risk
- Maintenance nightmare

**Should Be**: Use the existing waltdundore.github.io repository as the single source of truth for HTML

---

### 9. MISSING VARIABLES FILE (CRITICAL)

**Issue**: No vars files, no defaults, no group_vars

**Current Structure**:
```
playbooks/
  ├── webserver.yml
  ├── webserver-docker.yml
  ├── lamp.yml
  └── workstation.yml
```

**Should Be**:
```
playbooks/
  ├── webserver.yml
  ├── webserver-docker.yml
  ├── lamp.yml
  ├── workstation.yml
group_vars/
  ├── all.yml          # Variables for all hosts
  └── webservers.yml   # Variables for webservers
templates/
  ├── index.html.j2    # HTML template
  └── test.php.j2      # PHP test template
defaults/
  └── main.yml         # Default variables
```

---

### 10. HARDCODED FEDORA-SPECIFIC COMMANDS (HIGH)

**Issue**: Playbooks assume Fedora/dnf

**workstation.yml** - Uses `dnf` everywhere:
- Line 20: `ansible.builtin.dnf`
- Line 24: `ansible.builtin.dnf`
- Line 33: `ansible.builtin.dnf`
- Line 38: `ansible.builtin.dnf`

**Problems**:
- Won't work on Debian/Ubuntu
- Not cross-platform
- Violates "works everywhere" principle

**Should Be**:
```yaml
- name: Install packages
  ansible.builtin.package:  # Works on all distros
    name: "{{ item }}"
    state: present
```

---

## Inefficiencies Found

### 1. NO IDEMPOTENCY CHECKS

**Issue**: Tasks don't check if already done

**Example**: `workstation.yml` updates all packages every time
```yaml
- name: Update system packages
  ansible.builtin.dnf:
    name: "*"
    state: present
```

**Should Be**: Only update if needed, or make optional

---

### 2. NO ERROR HANDLING

**Issue**: Most tasks have no error handling

**Example**: Docker container stop fails silently
```yaml
failed_when: false  # Hides all errors
```

**Should Be**: Proper error handling with meaningful messages

---

### 3. NO TAGS

**Issue**: Can't run specific parts of playbooks

**Only lamp.yml has tags** - others have none

**Should Be**: All playbooks should have tags for selective execution

---

### 4. NO HANDLERS

**Issue**: Services restarted even when not needed

**Should Be**: Use handlers to restart only when config changes

---

### 5. NO VALIDATION

**Issue**: No validation of variables or prerequisites

**Should Be**:
```yaml
- name: Validate required variables
  ansible.builtin.assert:
    that:
      - apache_document_root is defined
      - apache_port is defined
    fail_msg: "Required variables not defined"
```

---

## Recommendations

### Immediate Actions (CRITICAL)

1. **Use Existing Website Repository**
   - Use https://github.com/waltdundore/waltdundore.github.io as HTML source
   - Remove hardcoded HTML from playbooks
   - Clone or download from website repo in playbooks
   - Delete duplicate index.html files in ahab

2. **Create Variables Files**
   - `group_vars/all.yml` - Common variables including website_repo_url
   - `group_vars/webservers.yml` - Webserver variables
   - `defaults/main.yml` - Default values

3. **Remove Hardcoded Paths**
   - Define path variables
   - Use variables in all tasks

### High Priority Actions

1. **Fix Platform-Specific Code**
   - Replace `dnf` with `package` module
   - Test on multiple distributions

2. **Remove Duplicate Code**
   - Single template for HTML
   - Reusable tasks

3. **Add Variables for Everything**
   - Docker images
   - Ports
   - Container names
   - Package lists

### Medium Priority Actions

1. **Add Error Handling**
   - Proper `failed_when` conditions
   - Meaningful error messages

2. **Add Tags**
   - Tag all tasks
   - Enable selective execution

3. **Add Handlers**
   - Restart services only when needed
   - Improve efficiency

4. **Add Validation**
   - Check required variables
   - Validate prerequisites

---

## Example Refactored Playbook

### Before (webserver.yml):
```yaml
- name: Create Hello World page
  ansible.builtin.copy:
    content: |
      <!DOCTYPE html>
      <html>
      ... 40 lines of HTML ...
    dest: /var/www/html/index.html
```

### After:
```yaml
# group_vars/webservers.yml
apache_document_root: /var/www/html
apache_index_file: index.html
apache_service_name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'apache2' }}"

# templates/index.html.j2
<!DOCTYPE html>
<html>
<head>
    <title>{{ page_title | default('Ahab - Hello World') }}</title>
</head>
<body>
    <h1>{{ page_heading | default('Hello World!') }}</h1>
    <p>Deployed: {{ ansible_date_time.iso8601 }}</p>
</body>
</html>

# playbooks/webserver.yml
- name: Deploy Apache Web Server
  hosts: webservers
  become: true
  
  vars_files:
    - ../group_vars/webservers.yml
  
  tasks:
    - name: Install Apache
      ansible.builtin.package:
        name: "{{ apache_service_name }}"
        state: present
      tags: [apache, install]
    
    - name: Deploy index page
      ansible.builtin.template:
        src: templates/index.html.j2
        dest: "{{ apache_document_root }}/{{ apache_index_file }}"
        mode: '0644'
      notify: Restart Apache
      tags: [apache, content]
  
  handlers:
    - name: Restart Apache
      ansible.builtin.service:
        name: "{{ apache_service_name }}"
        state: restarted
```

---

## Summary

**Total Issues**: 10 categories
- 3 CRITICAL (hardcoded HTML, no vars files, Fedora-only)
- 5 HIGH (paths, packages, images, duplicate code, platform-specific)
- 2 MEDIUM (ports, container names, user names)

**Inefficiencies**: 5 categories
- No idempotency checks
- No error handling
- No tags (except lamp.yml)
- No handlers
- No validation

**Recommendation**: Refactor all playbooks before adding new features

---

*This audit should guide playbook refactoring efforts.*
