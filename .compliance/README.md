# Compliance Evidence Directory

**Purpose**: Store evidence that Ahab's core principles are being upheld.

**Last Updated**: 2025-12-08

---

## Directory Structure

```
.compliance/
├── evidence/       # Verification evidence (test results, logs, proofs)
├── reports/        # Compliance reports and dashboards
└── logs/           # Detailed logs from verification scripts
```

---

## What Goes Here

### evidence/
- Test results from real infrastructure
- Verification outputs from compliance scripts
- Proof of self-use (command history, deployment records)
- License compliance checks
- DRY violation reports

### reports/
- COMPLIANCE_REPORT.md (generated dashboard)
- Principle-specific compliance summaries
- Audit results
- Trend analysis

### logs/
- Detailed output from verification scripts
- Timestamped execution logs
- Debug information for failed checks

---

## Privacy and Security

- **Public**: YAML evidence files and markdown reports (curated)
- **Private**: Detailed logs and traces (may contain sensitive info)
- See `.gitignore` for what's excluded from version control

---

## Usage

### Generate Compliance Report
```bash
make compliance-report
```

### Run Verification Scripts
```bash
make verify-compliance
```

### View Latest Report
```bash
cat .compliance/reports/COMPLIANCE_REPORT.md
```

---

## Maintenance

- Evidence files should be updated weekly
- Reports should be regenerated before each release
- Logs older than 30 days can be archived or deleted
- Failed checks should be investigated immediately

---

## Related Files

- `self-use-evidence.yml` - Proof we use what we document
- `infrastructure-test-evidence.yml` - Proof tests run on real infrastructure
- `LESSONS_LEARNED.md` - Transparency about mistakes
- `DEVELOPMENT_RULES.md` - Codified development practices

---

## Philosophy

**Trust is earned through consistent demonstration, not claims.**

This directory exists to provide concrete, verifiable evidence that Ahab's core principles are not aspirational - they're enforceable requirements embedded in our development process.
