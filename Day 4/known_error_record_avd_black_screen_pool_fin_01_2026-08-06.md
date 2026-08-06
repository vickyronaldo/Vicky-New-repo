Symptom: Users in the affected Finance AVD pool see a black screen after login. For some users it clears after about 30 seconds; for others the session disconnects and they must reconnect.

Cause: An image-coupled graphics/display regression was introduced by the overnight POOL-FIN-01 image update. The failure occurs during session initialization when Desktop Window Manager (dwm.exe) crashes in igdumd64.dll.

Scope: Affected systems were hosts in POOL-FIN-01, with approximately 40% of users impacted during the incident window. POOL-FIN-02 was unaffected and did not receive the overnight update.

Workaround: Restore service by moving affected POOL-FIN-01 hosts back to the last known-good image path and controlling rollout in waves. During incident handling, stop further exposure to the affected image path and keep non-remediated hosts out of new user placement.

Permanent fix: Correct the POOL-FIN-01 image by removing or replacing the unstable graphics component lineage associated with the crash path, then redeploy through controlled pilot and staged rollout. The incident was verified resolved at 10:00 with successful POOL-FIN-01 logins and no new user issues reported.

How to spot it: On affected hosts, look for Event ID 1000 (Application Error) showing dwm.exe faulting module igdumd64.dll with exception 0xc0000005, followed by Event ID 9009 (Desktop Window Manager exited) and Event ID 40 (session disconnected). In healthy comparison hosts, Event ID 9011 shows Desktop Window Manager started successfully and there are no matching Event ID 1000 errors in the same window.