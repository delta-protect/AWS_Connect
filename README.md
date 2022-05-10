# AWS_Connect

To-Do: Address [Confused Deputy problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html#:~:text=accessing%20your%20resources.-,Cross%2Dservice%20confused%20deputy%20prevention,-We%20recommend%20using) with STS

# ACCOUNT A (Trusting account - "Client")
Requirements: AWS CLI installed and configured with an administrative access. 
Extras: cURL, AWK in Linux/MacOS or AWS' native Cloudshell

* Run `curl https://(Repository URL) -s | ACCOUNT_ID="<DELTAPROTECT-ACCOUNT-ID>" bash`
(Remote script will check for the necessary programs and permissions in order to execute the commands. If not properly installed or configured, it will give a descriptive error and exit)

(Optional) **CLEANUP: ACCOUNT A (TRUSTING ACCOUNT)**
* Script `Cleanup.sh` - this will automatically detach the policy from the Role, and delete the Role. Success/error flags will be printed in stdout

# ACCOUNT B (TRUSTED ACCOUNT - "Auditor")
* Receive the full **ARN** for the role (This ARN will already include the Account A's ID as well as the name of the role) - Format: `aws:arn:iam::1234561235:role/RoleName`
