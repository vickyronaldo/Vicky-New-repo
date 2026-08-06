Symptom     : User FINBRIDGE\cthompson was unable to log in to host access during the incident window starting around 08:40. Access failure persisted until remediation was applied.

Cause       : Verified root cause was repeated authentication attempts with outdated/incorrect saved credentials from more than one source, which triggered account lockout. The lockout then prevented successful sign-in.

Scope       : Impact was limited to one user account (cthompson). Systems involved were AD account authentication and the affected user authentication sources observed in the security logs.

Workaround  : Restore service by resetting the user password, unlocking the AD account, and running one controlled sign-in. In parallel, clear or update stale saved credentials on involved sources to stop repeated bad-auth attempts.

Permanent fix: Remove/update stale saved credentials across all involved sources and enforce credential updates after password changes. For lockout incidents, require source mapping and stale-credential cleanup before closure.

How to spot it: Look for Event 4776 with error 0xC000006A (wrong password), repeated Event 4625 (unknown user name or bad password), Event 4740 (account locked out), and Event 4771 with failure code 0x18 (wrong password). In this incident, failures were seen from DESKTOP-FB022 and a secondary source IP 10.10.8.112, including a post-lockout Event 4625 showing account locked out.
