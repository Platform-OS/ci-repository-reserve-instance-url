# ci-repository-reserve-instance-url

## install

### contact DEVOPS department to get and add GHA secret [/settings/secrets/actions]

    POS_CI_REPO_ACCESS_TOKEN 
    
### replace old code like

#### beginning

    - name: Get ci-instance-url
      shell: sh
      run: |
        export MPKIT_URL=https://$(./scripts/ci/repository reserve)
        export REPORT_PATH=$(echo $MPKIT_URL | cut -d'/' -f3)/$(date +'%Y-%m-%d-%H-%M-%S')
        echo "MPKIT_URL=$MPKIT_URL" >> $GITHUB_ENV
        echo "REPORT_PATH=$REPORT_PATH" >> $GITHUB_ENV

#### closing

    - name: Release instance
      if: ${{ always() }}
      shell: sh
      run: |
        ./scripts/ci/repository release
        
### with the following

#### beginning of test suite

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
            
            
#### closing

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

### also update your jobs code with

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
      
# troubleshooting

##  you can use act  for testing

- https://github.com/nektos/act

## usage 

    act pull_request --secret-file .secrets --pull=false

    act pull_request --secret-file .secrets 
    
