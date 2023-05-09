# automate-report-generator

This repository contains bash scripts which can generate HTML reports for Builds that you run on BrowserStack Automate.

## Prerequisites

-   Linux or MacOS operating system.
-   Ability to run bash scripts and `curl` command.
-   Permission to download and save logs.

## Setup

-   Download the script relevant to your operating system from the GitHub release section.
-   Run the following command to make sure you can run the scripts

    ```sh
    chmod +x /path/to/reporter-linux.sh
    # or
    chmod +x /path/to/reporter-osx.sh
    ```

## Input

1. Expected predefined Environment Variables

    ```sh
    export BROWSERSTACK_USERNAME=<username>
    export BROWSERSTACK_ACCESS_KEY=<access-key>
    ```

2. Command line arguments

    ```sh
    # for linux
    BROWSERSTACK_BUILD_NAME="<build name that you used on BrowserStack>" /path/to/reporter-linux.sh /path/to/save/logs

    # for macos
    BROWSERSTACK_BUILD_NAME="<build name that you used on BrowserStack>" /path/to/reporter-osx.sh /path/to/save/logs
    ```
