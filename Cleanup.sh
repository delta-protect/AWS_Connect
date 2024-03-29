ROLE_NAME="assumeRole-Role"

# Get Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# 1.- Detach policies from Role $ROLE_NAME
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/job-function/ViewOnlyAccess && \
          echo "[+] 1/5 Successfully dettached policy from role" || echo "[-] Failure dettaching policy from role"
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/SecurityAudit && \
          echo "[+] 2/5 Successfully dettached policy from role" || echo "[-] Failure dettaching policy from role"
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/additions-policy && \
                        echo "[+] 3/5 Detached policy from role" || echo "[-] Failure detaching policy from role"

# 2.- Delete Role $ROLE_NAME
aws iam delete-role --role-name $ROLE_NAME && \
                        echo "[+] 4/5 Successfully deleted role from the acocunt" || echo "[-] Failure deleting role from the account"

# 3.- Delete Custom policy "Additions Policy"
aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/additions-policy && \
                        echo "[+] 5/5 Successfully deleted additions-policy" || echo "[-] Failure deleting additions-policy"
