# T-1003

## Summary
AVD session disconnects after about 10 minutes, then reconnects.

## Impact
Affected users and scope to-verify; could be a single user, multiple users, or a host pool issue; business urgency is to-verify, but potentially high where repeated disconnects interrupt access to business applications and remote working.

## Known facts
- The issue is in Azure Virtual Desktop.
- A session disconnect occurs after approximately 10 minutes.
- The session reconnects afterwards.

## Missing information to gather
- Which users are affected and how many to-verify.
- Whether the issue is limited to one host pool, one session host, or multiple hosts to-verify.
- Whether the disconnect happens at the same interval every time to-verify.
- Whether the user is idle or actively working when the disconnect happens to-verify.
- Exact user-visible message or symptom during disconnect/reconnect to-verify.
- Whether the issue happens from different devices, networks, or locations to-verify.
- Whether recent changes were made to AVD policies, session timeout settings, networking, or the client version to-verify.
- Whether session hosts show resource pressure or maintenance activity at the same time to-verify.

## Likely catagory
Azure Virtual Desktop / session stability / connectivity issue.

## First diagnostic step
Check whether the disconnect timing is consistent across affected users and review AVD connection diagnostics and session host logs for the disconnect reason at the same timestamp.
