# Deploy langfuse to Azure - WIP

Use the Azure Developer CLI to deploy langfuse to Azure. The following steps will guide you through the process.

Run:

```shell
azd up
```

## Enabling authentication

By default, the deployed Azure web app will have no authentication or access restrictions enabled, meaning anyone with routable network access to the web app can chat with your indexed data.

To enable AAD-based authentication, set the `AZURE_USE_AUTHENTICATION` variable to true before running `azd up`:

1. Run `azd env set AZURE_USE_AUTHENTICATION true`
1. Run `azd up`

When that is true, `azd up` will enable Azure authentication for the App Service app by:

* Using a preprovision hook to call `auth_init.py` to create an App Registration. That script sets the `AZURE_AUTH_APP_ID`, `AZURE_AUTH_CLIENT_ID`, and `AZURE_AUTH_CLIENT_SECRET` environment variables.
* During provisioning, using configuration in `appservice.bicep` to set the registered app as the authentication provider for the App Service app.
* Using a postprovision hook to call `auth_update.py` to set the redirect URI to the URL of the deployed App Service app

## TODO:

1. readme on auth, tenantid
2. Document how to use in azure-search-openai-demo
3. Move to Azure-Samples?
4. Check in hooks for auth before calling python
4. Dev Container
5. CI/CD