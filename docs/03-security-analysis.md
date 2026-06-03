# Security Analysis

> ⬜ Not started — last updated: [date]

## 1. Methodology
Tested against the **OWASP Mobile Top 10** and **OWASP MASVS** using:
- MobSF (static + dynamic analysis of the built APK)
- osv-scanner / Snyk (dependency CVE scan)
- Manual review (secure storage, network, auth)

## 2. MobSF Scan
- Security score: __ / 100
- Report file: `reports/mobsf-report.pdf`
- Key findings: [list]

## 3. OWASP Mobile Top 10 Mapping
| Risk | Status | Mitigation |
|------|--------|------------|
| M1 Improper Credential Usage | | |
| M2 Inadequate Supply Chain Security | | |
| M3 Insecure Authentication/Authorization | | |
| ... | | |

## 4. Dependency Vulnerabilities
[osv-scanner / Snyk output summary.]

## 5. Implemented Protections
- [ ] HTTPS enforced
- [ ] Secure token storage (flutter_secure_storage)
- [ ] Input validation
- [ ] Release build obfuscation (--obfuscate --split-debug-info)

## 6. Conclusion
[Overall security posture.]
