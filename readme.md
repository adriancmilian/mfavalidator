# mfavalidator
---
### *Currently this is only checking for softwareOathmethods and the Microsoft Authenticator app if your requirements are different you will want to change line 36 & 71 of the Get-UsersMFAStatus.ps1 file*

#### mfavalidator is used to disable user accounts after 7 days of MFA not being setup on their Azure AD account

Using the Microsoft Graph API we're able to assign custom attributes to users to flag them when mfa is disabled on the account. Utilizing this method we can keep track of the date they were flagged and disable their accounts if it's greater then 7 days. This is to help prevent attackers from compromising an account without MFA setup.

---
## Steps to set up
1. Create a new Service Principal in Azure AD with the following permissions
    - User.ReadWrite.All
    - UserAuthenticationMethod.Read.All
    - CustomSecAttributeAssignment.ReadWrite.All
    - CustomSecAttributeDefinition.ReadWrite.All
2. Create a attribute set under "Custom Security Attributes"
    - attribute set should be named "mfaregistration"
    - The following 2 attributes should be created
      - dateflagged (String data type)
      - mfaenabled (Boolean data type)
3. You'll want to adjust the mfavalidator.ps1 file to use your Tenant ID, App ID, Secret

---
## Description
The script mfavalidator.ps1 will import the functions by calling mfavalidator.psm1, once the functions are imported it will get the access token by authenticating with the service principal that you setup.

The script will grab all enabled licensed users in your tenant and check if MFA is enabled on each user and set custom security attributes for their user object. If MFA is enabled it will set the attribute mfaenabled = true, if MFA is disabled it will set mfaenabled = false & dateflagged = (Current Date). Once the attributes are set it will gather the users with MFA disabled for over 7 days using the dateflagged attribute and store them in an array. If the user is a synced user from on-prem it will get the users samAccountName and disable their account on-premises. If the user does not have a samAccountName and are cloud-only it will disable them in AzureAD. Once disabled it will clear the dateflagged attribute.



