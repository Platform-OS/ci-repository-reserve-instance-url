# ci-repository-reserve-instance-url

This repository provides a custom GitHub Action for reserving and releasing CI instances. These instances are important for deploying applications and running tests in isolated and consistent environments, which helps avoid conflicts and ensures reliable test results.

## Why Reserve an Instance?

Each developer working on a branch triggers tests, and the tests need to run somewhere on platformOS. We need to **reserve an instance** on which the application will be deployed and then the test will be run against it. This avoids conflicts that might arise from running multiple tests simultaneously on the same instance. It also ensures consistency across test runs, making it easier to identify issues.

The reserved instance needs to be **released** after the tests are complete. This is an important step to ensure that the instance is available for future tests. PlatformOS' internal solution involves a pool of 6 instances (ci.1, ci.2, ci.3, ci.4, ci.5, ci.6) shared across projects.

The process works as follows:

- The first available instance that is not currently used by any other GitHub Action is taken and removed from the pool.
- This prevents multiple projects from running their tests in parallel on the same instance, which would cause conflicts.
- The instance is reserved for the duration of the tests, regardless of whether the tests fail or succeed.
- Once the tests are done, the instance is given back to the pool.
- Without this reserve and release mechanism, we would quickly run out of available instances, preventing new tests from running.

### Custom Action Details

The custom action `Platform-OS/ci-repository-reserve-instance-url@0.0.9` handles both reserving and releasing instances. It operates based on the method provided (`reserve` or `release`). The action communicates with the CI repository to manage instance reservations.

## Installation

### Contact DEVOPS

To get started, contact the DEVOPS department to obtain and add the necessary GitHub Actions (GHA) secret:

- **POS_CI_REPO_ACCESS_TOKEN**

You can add this secret in your repository settings under **Settings** -> **Security** -> **Secrets and variables** -> **Actions**.

## Replace old worfklow code like

Replace your existing code for releasing an instance:

### beginning

```yaml
    - name: Get ci-instance-url
      shell: sh
      run: |
        export MPKIT_URL=https://$(./scripts/ci/repository reserve)
        export REPORT_PATH=$(echo $MPKIT_URL | cut -d'/' -f3)/$(date +'%Y-%m-%d-%H-%M-%S')
        echo "MPKIT_URL=$MPKIT_URL" >> $GITHUB_ENV
        echo "REPORT_PATH=$REPORT_PATH" >> $GITHUB_ENV
```

### closing

```yaml
    - name: Release instance
      if: ${{ always() }}
      shell: sh
      run: |
        ./scripts/ci/repository release
```
        
## With the following

Use the following code to reserve an instance:

### beginning

```yaml
    reserve-ci-instance:
      runs-on: ubuntu-latest
      container: alpine:3.15
      outputs:
        mpkit-url: ${{ steps.reserve.outputs.mpkit-url }}
        report-path: ${{ steps.reserve.outputs.report-path }}
      steps:
        - name: reserve ci-instance-url
          id: reserve
          uses: Platform-OS/ci-repository-reserve-instance-url@0.0.9
          with:
            repository-url: https://ci-repository.staging.oregon.platform-os.com
            method: reserve
            pos-ci-repo-token: ${{ secrets.POS_CI_REPO_ACCESS_TOKEN }}
```          
            
### closing

```yaml
    cleanup:
      if: ${{ always() }}
      needs: ["reserve-ci-instance","deploy","tests"]
      runs-on: ubuntu-latest
      container: alpine:3.15
      steps:
        - name: release ci-instance-url back to the instance-pool
          uses: Platform-OS/ci-repository-reserve-instance-url@0.0.9
          with:
            method: release
            repository-url: https://ci-repository.staging.oregon.platform-os.com
            pos-ci-repo-token: ${{ secrets.POS_CI_REPO_ACCESS_TOKEN }}
```

## Update Your Jobs

Also update your jobs code with the following:

```yaml
deploy: 
  needs: ["reserve-ci-instance"]
  env:
    MPKIT_URL: ${{ needs.reserve-ci-instance.outputs.mpkit-url }}
  [...]

tests:
  needs: ["reserve-ci-instance", "deploy"]
  env:
    MPKIT_URL: ${{ needs.reserve-ci-instance.outputs.mpkit-url }}
    REPORT_PATH: ${{ needs.reserve-ci-instance.outputs.report-path }}
  [...]
```

## Troubleshooting

### Using `act` for Testing

You can use the `act` tool for local testing of GitHub Actions:

- [act](https://github.com/nektos/act)

Usage:

```sh
act pull_request --secret-file .secrets --pull=false

act pull_request --secret-file .secrets 
```

## Script Details

The action's entry point script (`entrypoint.sh`) handles the logic for reserving and releasing instances. The script processes the method argument to perform the appropriate action (reserve or release). 

- **Script Entry Point**: `entrypoint.sh` is designed for use in Docker.
- **Method Argument**: The first argument provided to the script determines the method.

### Key Actions:
1. **Release**: Triggers a delete request when the method is `release`.

2. **Reserve**: Sends a post request and logs it when the method is `reserve`.

Additional Responsibilities:

- **Instance Setup and Report Path Preparation**: The script sets up the instance and prepares the report path.
- **Persistent Log Access**: It ensures that you can access previous test logs even after running new tests. This is important for accessing test results at a later time (e.g., triggering a test on Friday and accessing the results on Monday).
- **Timestamped Report Path**: To keep logs organized and unique, it creates a report path with the current timestamp. 

For more details, check the [entrypoint.sh script](https://github.com/Platform-OS/ci-repository-reserve-instance-url/blob/main/entrypoint.sh).

### Instance Naming Conventions

The custom action still uses some legacy naming conventions like `mpkit-url`. This refers to the instance URL. For clarity, consider this as the instance URL.