# how to use

## steps

### Entra id / Azure AD and Azure

1. create reg app or user manage identity: copy app/client ID and tenant id
2. configure certificates / secrets, use federated creds: GHE-orgName, repo name, type: environement, env name. IE: gh_org_name/repo_name:environment:sbx
   1. Use same process for the identity to apply the environment 'sbx-Apply'
3. Assign role to created application in Azure: Contributor

### GHE 

Configure authentication to download terraform modules stored in GHE private repositories.

#### GH Authentication App

1. create Auth in GHE account (<https://github.com/settings/apps>)
   1. NOTE: in my free account, the app must be made public to have the option to install it in my orgs.
   2. name: tf-app-module-auth
   3. description: This app serves as authentication app (SPN) in GHE to download modules stored in GHE internal/private repo. App is required to be installed in the organization private/internal module repos are hosted. permissions must be given to the app.
   4. home page: <https://github.com/account>
   5. call back url: <https://github.com/orgname>
   6. Request user authorization (OAuth) during installation: selected
   7. Enable Device Flow: selected
2. generate private key and pem
   1. store private key in security vault service such as KV
   2. download PEM and store it in a secure service such as KV
   3. generate a secret only if required. store it in a vault service such as KV
3. install app in the target org name.(<https://github.com/apps/tf-app-module-auth/installations>)
   1. Select the org you want the app to be install
   2. Select repositories you authorize the app permission
      1. All repositories or only selected repositories
      2. Setting can be change at any time by org owner
4. capture required values
   1. App ID
   2. App private key (value from PEM)
   3. Organization name where the app was installed

##### configure workflow repo

1. create secrets and variables (organization wide, repository or environment specific)
   1. TF_APP_PRIVATE_KEY secret (value from PEM)
   2. TF_OWNER_ORG_NAME variable
   3. TF_APP_ID variable

#### classic token and repo environment settings

1. create environment name: sbx (in this example the environment name is sbx)
   1. Add a secret name: **GH_TOKEN** (value for this is GH classic token https://github.com/settings/tokens. user-profile>settings>developer settings>personal access token>token (classic))

### repo files to update

1. create a caller workflow: workflow-fullstac-working-001\.github\workflows\_example-apply-caller.yml
   1. update information on caller yml file
   2. cloud_provider: azure
      azure_client_id: [replace me] # app id
      azure_tenant_id: [replace me] # entra id tenant
      environment_name: sbx
      optfile_path: optfiles/sbx.json # optfiles/envName.json
      optfile_runner: ubuntu-latest # ubuntu-latest 
      ref: workflows # ${{ inputs.version }} #<branch or tag name containing your released code>
2. create optfiles folder: workflow-fullstac-working-001\optfiles
3. create json file for environment in optfiles: workflow-fullstac-working-001\optfiles\**sbx**.json (in this example, the environment is sbx)


TBD
- doc requirements such as details to TF backend state