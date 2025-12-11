# Zero Trust Checking Report: zero-trust-example
Generated: Wed Dec 10 12:38:53 EST 2025

## Summary
- Total Checks: 0
- Passed: 12
- Failed: 4
- Warnings: 3
- Critical Failures: 1

## State History
init:zero-trust-example:Wed Dec 10 12:38:53 EST 2025
2025-12-10 12:38:53:file_op:exists:/Users/waltdundore/git/DockMaster/ahab/scripts/lib/../Makefile
2025-12-10 12:38:53:fail:normal:File does not exist: /Users/waltdundore/git/DockMaster/ahab/scripts/lib/../Makefile
2025-12-10 12:38:53:fail:critical:Critical file missing: /Users/waltdundore/git/DockMaster/ahab/scripts/lib/../Makefile
2025-12-10 12:38:53:warn:Example function failed: example_file_operations
2025-12-10 12:38:53:file_op:exists:/tmp/zt-test-99839
2025-12-10 12:38:53:pass:File exists: /tmp/zt-test-99839
2025-12-10 12:38:53:execute:wc-test with timeout 10
2025-12-10 12:38:53:pass:wc-test: Completed successfully in 0s
2025-12-10 12:38:53:pass:Command execution verified: wc output correct
2025-12-10 12:38:53:pass:Test file cleanup verified
2025-12-10 12:38:53:file_op:exists:/Users/waltdundore/git/DockMaster/ahab/scripts/lib/../Makefile
2025-12-10 12:38:53:fail:normal:File does not exist: /Users/waltdundore/git/DockMaster/ahab/scripts/lib/../Makefile
2025-12-10 12:38:53:fail:normal:Makefile not found in expected location: /Users/waltdundore/git/DockMaster/ahab/scripts/lib/..
2025-12-10 12:38:53:warn:Example function failed: example_make_verification
2025-12-10 12:38:53:pass:Docker available for service verification
2025-12-10 12:38:53:network_op:ping:127.0.0.1
2025-12-10 12:38:53:pass:Network ping successful: 127.0.0.1
2025-12-10 12:38:53:pass:Local network stack functional
2025-12-10 12:38:53:network_op:ping:8.8.8.8
2025-12-10 12:38:53:pass:Network ping successful: 8.8.8.8
2025-12-10 12:38:53:pass:External network connectivity verified
2025-12-10 12:38:53:pass:Expected failure occurred (cannot write to invalid path)
2025-12-10 12:38:53:file_op:exists:/tmp/zt-recovery-99839
2025-12-10 12:38:53:pass:File exists: /tmp/zt-recovery-99839
2025-12-10 12:38:53:pass:Error recovery successful
2025-12-10 12:38:53:pass:Sufficient disk space available: 2946442064KB
2025-12-10 12:38:53:warn:Memory checking not available (free command not found)
2025-12-10 12:38:53:finalize:zero-trust-example
