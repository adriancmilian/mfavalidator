# mfavalidator
---

#### mfavalidator is used to disable user accounts after 72 hours of MFA not being setup on their Azure AD account

Using the Microsoft Graph API we're able to assign custom attributes to users to flag them when mfa is disabled on the account. Utilizing this method we can keep track of the date they were flagged and disable their accounts if it's greater then 3 days. This is to help prevent attackers from compromising an account without MFA setup.

##### *Currently this is only checking for softwareOathmethods if your requirements are different you will want to change line 87 & 104 of the Get-UsersMFAStatus method*
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
3. You'll want to adjust the mfavalidator.ps1 file to use your authentication method of your choosing.

---
## Description
The script mfavalidator.ps1 will import the functions by calling mfavalidator.psm1, once the functions are imported it will get the access token by authenticating with the service principal that you setup.

The script will then call the function Get-AllEnabledMgUsers and store the data in memory ($users variable)
Then the script will then call the following two functions Get-EnabledMfaUsersCustomSecAttributes, Get-DisabledMfaUsersCustomSecAttributes to get the users who need to be flagged and store them in memory

If either of those variables contain a value it will flag the users to be disabled or if MFA is enabled it will flag them as enabled



