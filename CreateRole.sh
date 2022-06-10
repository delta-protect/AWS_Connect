#!/bin/sh

_PWD=$(pwd)

# Sanity check 1: Make sure the script is running in a folder that is writable
echo "[i] Checking for read/write access to the current folder..."
cd ~/ || echo "[!] No home directory found"
touch test.txt || { echo "[!] No write permissions in $_PWD"; exit 1; }
rm test.txt

ROLE_NAME='assumeRole-Role'
SESSION_DURATION='43200'
POLICY_DOCUMENT='trustPolicy.json'

# Sanity check #2: if necessary programs are not installed (List below), program exits.
echo "[i] Checking if necessary programs are installed: AWS CLI, AWK, SED"
function _CHECK_PROGRAM () {
	sleep 0.3
        ! which $1 &>/dev/null && \ 
		echo " [X] $1 not installed or on the user's path. Exiting... " && exit 1 || \
		echo "    Ok - $1 installed."
}

_CHECK_PROGRAM aws
_CHECK_PROGRAM awk
_CHECK_PROGRAM sed

# Generate JSON trust policy && Create JSON file with name $JSON_FILE & Handling errors after creation
POLICY_FILE_CONTENT=$(cat <<-END
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "$ACCOUNT_ID"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
END
)

JSON_FILE=trustPolicy.json
echo $POLICY_FILE_CONTENT > $JSON_FILE
if [ -f "$JSON_FILE" ]; then
    echo "[i] File $JSON_FILE created"
else
    echo "[X] Error creating JSON file. Exiting..." && exit 1
fi

# Generate Additions policy && Create JSON file with name $POLICY_FILE & Handling errors after creation
POLICY_FILE='role-additions.json'
POLICY_NAME='additions-policy'

json=$(cat <<-END
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ds:Get*",
                "ds:Describe*",
                "ds:List*",
                "ec2:GetEbsEncryptionByDefault",
                "ecr:Describe*",
                "elasticfilesystem:DescribeBackupPolicy",
                "glue:GetConnections",
                "glue:GetSecurityConfiguration",
                "glue:SearchTables",
                "lambda:GetFunction",
                "s3:GetAccountPublicAccessBlock",
                "shield:DescribeProtection",
                "shield:GetSubscriptionState",
                "ssm:GetDocument",
                "support:Describe*",
                "tag:GetTagKeys"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "AllowMoreReadForAuditing"
        },
        {
            "Effect": "Allow",
            "Action": [
                "apigateway:GET"
            ],
            "Resource": [
                "arn:aws:apigateway:*::/restapis/*"
            ]
        }
    ]
}
END
)
echo $json > $POLICY_FILE && echo "[i] File $POLICY_FILE created"

ADDITIONS_POLICY=$(aws iam create-policy --policy-name $POLICY_NAME --policy-document file://$POLICY_FILE && echo "[1] Policy \"$POLICY_NAME\" created" || echo "[X] ERROR creating policy \"$POLICY_NAME\"")

ADDITIONS_POLICY_ARN=$(echo $ADDITIONS_POLICY | sed 's/ /\n/g' | grep arn | sed 's/"/ /g' | awk '{print $1}')

# AWS Execution
echo "[i] Creating a new IAM role"
aws iam create-role \
		--assume-role-policy-document file://$JSON_FILE \
		--max-session-duration $SESSION_DURATION \
		--role-name $ROLE_NAME \
		--permissions-boundary arn:aws:iam::aws:policy/job-function/ViewOnlyAccess &>/dev/null && \
        echo "[2] SUCCESS CREATING $ROLE_NAME. Attaching permissions..." && \

        aws iam put-role-permissions-boundary \
            --permissions-boundary arn:aws:iam::aws:policy/SecurityAudit \
            --role-name $ROLE_NAME &>/dev/null && \
			echo " +  1/4 Permissions Boundary: SecurityAudit policy attached" || echo "[X] Error attaching permissions boundary - SecurityAudit policy" && \

		aws iam attach-role-policy \
			--role-name $ROLE_NAME \
			--policy-arn arn:aws:iam::aws:policy/job-function/ViewOnlyAccess &>/dev/null && \
			echo " +  2/4 ViewOnlyAccess policy attached" || echo "[X] Error attaching ViewOnlyAccess policy" && \

        aws iam attach-role-policy \
            --role-name $ROLE_NAME \
                --policy-arn arn:aws:iam::aws:policy/SecurityAudit && \
			echo " + 3/4 SecurityAudit policy attached" || echo "[X] Error attaching SecurityAudit policy" && \

        aws iam attach-role-policy \
            --role-name $ROLE_NAME \
                --policy-arn $ADDITIONS_POLICY_ARN &>/dev/null && \
			echo " + 4/4 additions-policy policy attached" || echo "[X] Error attaching additions-policy policy" && \

if [[ $? -gt 0 ]]; then echo "[x] ERROR CREATING $ROLE_NAME". Exiting... && exit 1;fi
echo "[i] SUCCESS"

# Get Role's ARN and print it to stdout:
ROLE_ARN=$(aws iam list-roles | grep assumeRole-Role | grep Arn | sed 's/"//g' | sed 's/,//' | awk '{print $2}')
echo "[i] Cleanup: Deleting previously generated JSON files"
rm $JSON_FILE && echo " - Deleted $JSON_FILE" || echo "[!] Error deleting $JSON_FILE"
rm $POLICY_FILE && echo " - Deleted $POLICY_FILE" || echo "[!] Error deleting $POLICY_FILE"
echo "------------------------"
echo "[i] Role ARN:"
echo $ROLE_ARN
echo "------------------------"
