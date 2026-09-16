# DRY Fix: Web Content Decoupled from YAML

![Ahab Logo](docs/images/ahab-logo.png)

**Date**: 2025-12-08  
**Issue**: HTML and PHP content was embedded directly in Ansible YAML files, violating DRY principles

## Problem

The PHP role had web content embedded in `copy` tasks with `content: |` blocks:

```yaml
# BEFORE (WRONG)
- name: Create PHP test file
  copy:
    content: |
      <!DOCTYPE html>
      <html>
      <head><title>PHP Test</title></head>
      ...
    dest: "{{ apache_document_root }}/test.php"
```

This violates DRY because:
1. Content is mixed with configuration
2. Hard to maintain and edit
3. No syntax highlighting for embedded content
4. Difficult to reuse across roles

## Solution

Moved all web content to separate template files:

```yaml
# AFTER (CORRECT)
- name: Create PHP test file
  template:
    src: test.php.j2
    dest: "{{ apache_document_root }}/test.php"
    owner: "{{ apache_user }}"
    group: "{{ apache_group }}"
    mode: '0644'
```

## Files Changed

### Created Templates
- `ahab/roles/php/templates/info.php.j2` - PHP info page
- `ahab/roles/php/templates/test.php.j2` - PHP test page

### Modified
- `ahab/roles/php/tasks/main.yml` - Changed from `copy` with `content` to `template` with `src`

## Benefits

1. **Separation of Concerns**: Content separate from configuration
2. **Maintainability**: Easy to edit HTML/PHP in proper files
3. **Syntax Highlighting**: IDEs can properly highlight template files
4. **Reusability**: Templates can be reused across roles
5. **DRY Compliance**: Single source of truth for content

## Testing

```bash
make test
```

All tests pass after refactoring.

## Pattern to Follow

**Always use templates for content:**

```yaml
# ✅ GOOD
- name: Deploy config file
  template:
    src: myfile.conf.j2
    dest: /etc/myapp/myfile.conf

# ❌ BAD
- name: Deploy config file
  copy:
    content: |
      [section]
      key=value
    dest: /etc/myapp/myfile.conf
```

## Audit Recommendation

Add automated check to detect `copy` tasks with `content: |` blocks and flag them for refactoring.
