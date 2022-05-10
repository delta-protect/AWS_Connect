# AWS_Connect

To-Do: Address [Confused Deputy problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html#:~:text=accessing%20your%20resources.-,Cross%2Dservice%20confused%20deputy%20prevention,-We%20recommend%20using) with STS

# ACCOUNT A (Trusting account - "Client")
Requirements: AWS CLI installed and configured with an administrative access. 
Extras: cURL, AWK in Linux/MacOS or AWS' native Cloudshell

## 1. Via AWS Web Console:

Open the preconfigured console using [this link](https://us-east-1.console.aws.amazon.com/iamv2/home#/roles/create?awsAccount=678625457521&step=selectEntities&trustedEntityType=AWS_ACCOUNT), uncheck MFA token usage. Click "Next", add ReadOnly access policy to the role, select a new Role Name and Tags. Click "Create Role". Take note of the Role ARN (Format: `aws:arn:iam::1234561235:role/RoleName`).

## 2. Programatically (AWS CLI):

Run `curl https://raw.githubusercontent.com/delta-protect/Path/script -s | ACCOUNT_ID="<DELTAPROTECT-ACCOUNT-ID>" bash` to automatically create a new Role and give ReadOnly access to the remote account via STS.

*(Remote script will check for the necessary programs and permissions in order to execute the commands. If not properly installed or configured, it will give a descriptive error and exit)*

## (Optional) **Cleanup: Ran by account A (Trustinmg account)**
* Script `Cleanup.sh` - this will automatically detach the policy from the Role, and delete the Role. Success/error flags will be printed in stdout

# ACCOUNT B (Trusted account - "Auditor")
* Receive the full **ARN** for the role (This ARN will already include the Account A's ID as well as the name of the role) - Format: `aws:arn:iam::1234561235:role/RoleName`
