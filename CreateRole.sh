#!/bin/sh

ROLE_NAME='assumeRole-Role'
SESSION_DURATION='43200'
POLICY_DOCUMENT='trustPolicy.json'

# 1.- Sanity check: if necessary programs are not installed (List below), program exits.
function _CHECK_PROGRAM () {
		echo "[i] Checking if $1 is installed and on the user's path..."
		sleep 0.3
        ! which $1 &>/dev/null && \
				echo " !  $1 not installed or on the user's path. Exiting... " && exit 1 || \
				echo " - Ok"
}

_CHECK_PROGRAM aws
_CHECK_PROGRAM awk
_CHECK_PROGRAM sed

# Generate JSON trust policy
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


# Create JSON file with name $JSON_FILE & Handling errors after creation
JSON_FILE=trustPolicy.json
echo $POLICY_FILE_CONTENT > $JSON_FILE
if [ -f "$JSON_FILE" ]; then
    echo "[+] File $JSON_FILE created"
else
    echo "[!] Error creating JSON file. Exiting..." && exit 1
fi

# AWS Execution
echo "[i] Creating a new IAM role"
aws iam create-role \
		--assume-role-policy-document file://$JSON_FILE \
		--max-session-duration $SESSION_DURATION \
		--role-name $ROLE_NAME \
		--permissions-boundary arn:aws:iam::aws:policy/job-function/ViewOnlyAccess &>/dev/null \
		&& \
		aws iam attach-role-policy \
			--role-name $ROLE_NAME \
			--policy-arn arn:aws:iam::aws:policy/job-function/ViewOnlyAccess &>/dev/null && \
			echo "[+] 1/1 SUCCESS CREATING $ROLE_NAME" || echo "[x] ERROR CREATING $ROLE_NAME

# Get Role's ARN and print it to stdout:
ROLE_ARN=$(aws iam list-roles | grep assumeRole-Role | grep Arn | sed 's/"//g' | sed 's/,//' | awk '{print $2}')
echo "------------------------"
echo "[i] Role ARN: $ROLE_ARN"
rm $JSON_FILE && echo "[+] Deleted $JSON_FILE"
