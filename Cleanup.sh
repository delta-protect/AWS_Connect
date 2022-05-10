ROLE_NAME="assumeRole-Role"

aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/job-function/ViewOnlyAccess && \
  echo "[+] 1/2 Successfully dettached policy from role" || echo "[-] Failure dettaching policy from role"

aws iam delete-role --role-name $ROLE_NAME && \
	echo "[+] 2/2 Successfully deleted role from the acocunt" || echo "[-] Failure deleting role from the account"
