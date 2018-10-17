<# test.ps1

Environment Variables to use in your script:

Directories in the test asset:
 - MEDIA_DIRECTORY: Path to the media directory in the test asset 
 - SCRIPTS_DIRECTORY: Path to the scripts directory in the test asset
 
To generate test results:
 - REPORT_DIRECTORY: Path to the report directory, contents will be downloadable as test results
 - LOG_DIRECTORY: Path to REPORT_DIRECTORY\log

Deployment properties
 - DEPLOYMENT_PROPERTIES_FILE: Path to the deployment-properties.ps1 file.  Use this to read IP
 address information or custom properties for your test.

 #>

 # Set the error action proference
 $ErrorActionPreference = "Stop"
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Load the PATH environment variable
$env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine")

########################### VARIABLES ###############################

# Logging vars
$logtag = "powershell-test-script"
$logfile = "env:log_directory\$logtag.log"

# Default testEndState is pass
$defaultTestEndState = "pass"

######################## HELPER FUNCTIONS ############################

# Set up logging functions
function logger($level, $logstring) {
    $stamp = get-date -f yyyyMMdd-HHmmss
    $logmsg = "$stamp - $LOGTAG - [$level] - $logstring"
    write-output $logmsg
 }
 function logErr($logstring) { logger "ERROR" $logstring }
 function logWarn($logstring) { logger "WARNING" $logstring }
 function logInfo($logstring) { logger "INFO" $logstring }

######################## SCRIPT EXECUTION ############################

new-item $LOGFILE -itemType file -force
start-transcript -append -path $LOGFILE
logInfo "Running $LOGTAG..."

try {
    logInfo "Running the sample test.ps1 Powershell test script..."

    $testEndStateValue = $defaultTestEndState

    # Ensure the deployment properties file exists
    if (test-path $env:DEPLOYMENT_PROPERTIES_FILE) {
        logInfo "Found deployment properties file: $env:DEPLOYMENT_PROPERTIES_FILE"

        # Check for testEndState custom property
        $testEndState = gc $env:DEPLOYMENT_PROPERTIES_FILE | select-string "testEndState"

        # Check what was found (or not found) in the props file
        if (!$testEndState) {
            logInfo "Custom property not found for testEndState, using default: $defaultTestEndState"
        }
        else {
            # Use the default if more than 1 value was found
            if ($testEndState.length -ne 1) {
                logWarn "More than one value for testEndState found, using default: $defaultTestEndState"
            }
            else {
                logInfo "Found testEndState property: $testEndState"
                
                # Use the default if the prop is malformed
                if ($testEndState.split("=").length -ne 2) {
                    logWarn "Found malformed custom property with more than 1 equals sign: $testEndState, using default: $defaultTestEndState"
                }
                else {
                    # Use the prop value
                    $prop,$value = $testEndState.split("=")
                    logInfo "Found property $prop, and value $value"
                    $testEndStateValue = $value.toLower()
                }
            }
        }
    }
    else {
        logWarn "Deployment properties file not found: $env:DEPLOYMENT_PROPERTIES_FILE"
    }
    
    logInfo "Using testEndState value = $testEndStateValue"

    # Print test warning and a test error
    logWarn "This is a test warning"
    logErr "This is a test error"

    # Print the media and scripts directories
    logInfo "Test asset media directory: $env:media_directory"
    logInfo "Test asset scripts directory: $env:scripts_directory"

    # Print locations of the report directoiries
    logInfo "Attempting to print desired Environment vars..."
    logInfo "Results Dir: $env:report_directory"
    logInfo "Log Dir: $env:log_directory"

    # Add some test results
    logInfo "Adding file to results dir..."
    new-item $env:report_directory\testresults.txt -itemType file -force
    add-content $env:report_directory\testresults.txt -value "HELLO WORLD TEST RESULTS!!"

    # Add a test log file
    logInfo "Adding file to log dir..."
    new-item $env:log_directory\testlog.log -itemType file -force
    add-content $env:log_directory\testlog.log -value "HELLO WORLD TEST LOG!!"

    # Add enviroinment variables to the test results
    logInfo "Adding an environment.log file to the test results..."
    Get-ChildItem Env: | Out-File $env:log_directory\environment.log

    logInfo "Note, this log file should be located in the lgo directory"

    # Exiting based on the desired test end state
    if ($testEndStateValue -eq "fail") {
        $errMsg = "The tester requested a test error! So, here you go!"
        logErr $errMsg
        throw $errMsg
    }
    logInfo "The tester requested a test pass!  Yay!  We passed!"
}
catch {
    logErr "Caught exception: $_"
    $exitCode = -1
}
finally {
    logInfo "$LOGTAG complete in $($stopwatch.Elapsed)"
}

###################### END SCRIPT EXECUTION ##########################

logInfo "Exiting with code: $exitCode"
stop-transcript
get-content -Path $logfile
exit $exitCode
