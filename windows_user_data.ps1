<powershell>

# Function to watch for a file - to be used later to make sure salt state is complete.
function WaitForFile($File) {

    while(!(Test-Path $File)) {

        Start-Sleep -s 10;

        }

    }


# Set the Powershell Policy to Unrestricted - for easier script development
Set-ExecutionPolicy Unrestricted


# Configuration Variables 
# Salt Minion Version, URL to fetch Salt Minion and Local directory to dump it.
$SaltMinionFileName = "Salt-Minion-2014.7.2-AMD64-Setup.exe"
$GetSaltMinionFile = "http://docs.saltstack.com/downloads/$SaltMinionFileName" 
$LocalSaltMinionFile ="C:\$SaltMinionFileName"

# get the instance-id - will need this for salt install
$response = Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id
$instanceId = $response.Content

#define Salt Master (value stubbed)
$saltMaster="<saltmaster.organization.com>"


# Set the Amazon Instance to use EST
Invoke-Expression "C:\Windows\System32\tzutil.exe /s 'Eastern Standard Time' "


# Install and configure Chocolatey Package Manager
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
$oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path

$newPath=$oldPath+";C:\ProgramData\chocolatey\bin"
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath


# Go out to the web, and fetch salt minion
Invoke-WebRequest $GetSaltMinionFile  -OutFile $LocalSaltMinionFile

# Install Salt Master
Invoke-Expression "$LocalSaltMinionFile /S /master=$saltMaster /minion-name=$instanceId"

# Check Salt Service
$service = Get-Service
$service.WaitForStatus('Running','00:05:00')


# Using salt-call reach out to the salt master, and apply the desired machine state - replace <<configuration state>> with state name.
Invoke-Expression "c:\salt\salt-call.exe state.sls <<configuration state>> 2>&1 >> c:\UserDataProc.log"

# This assumes that the Salt state referenced above writes out a text file named "salt_complete.txt" at completion - if not comment out the WaitForFile call - or this will hang.
WaitForFile("c:\salt_complete.txt")

# Clean up 
Invoke-Expression "del $LocalSaltMinionFile 2>&1 >> c:\UserDataProc.log"
Invoke-Expression "del c:\salt_complete.txt 2>&1 >> c:\UserDataProc.log"

# If you are using this to make an AMI - remove the comment from the line below to run the sysprep utility (sysprep configs can be altered using a salt state).  
# Invoke-Expression "c:\'Program Files'\Amazon\Ec2ConfigService\Ec2Config.exe -sysprep

</powershell>