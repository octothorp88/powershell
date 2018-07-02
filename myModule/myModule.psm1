# THis is my test/template powershell file
#
# To Generate the template run the following
#
# New-ModuleManifest -RootModule 'myModule.psm1' -Author 'ziggy' -Path 'myModule.psd1'


function Get-OSInfo {
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='low')]
    param(
        [Parameter(ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [Alias('hostname')]
        [ValidateLength(1,20)]
        [string[]]$computername = @("."),
        [switch]$namelog
        )

        BEGIN{
        # this executes just once
        if ($namelog) {
            write-verbose "Finding name log file"
            $i = 0
            do {
                $logfile = "names-$i.txt"
                $i++
            } while (test-path $logfile)
            Write-Verbose "log file is $logfile"
        } else {
            write-verbose "Name Logging off"
        }
        
        write-debug "finished Setting name log"

        }

        PROCESS {
        Write-Debug "Set Namelog"
        if ($namelog) {
            write-verbose "Name log on"
        } else {
                write-verbose "Name log off"
                }
        # This block will execute once for each item
        write-debug "start processing computer(s)"
            foreach ($computer in $computername) {
                if ($pscmdlet.ShouldProcess($computer)) {
                    write-verbose "Now connecting to $computer"
                    if ($namelog) {$computer | Out-File $logfile -Append}
                    try {
                        $continue = $True
                        $os = get-wmiobject -ErrorVariable myError -erroraction 'stop' -computername $computer -class Win32_OperatingSystem |
                        Select Caption, BuildNumber, OSArchitecture,ServicePackMajorVersion
                        } catch {
                            $continue = $False
                            write-host "ERROR connecting to $computer" -ForegroundColor Red
                            # write-host $myError -ForegroundColor Red
                        }
                    if ($continue) {
                        $bios = Get-WmiObject -ComputerName $computer -class Win32_BIOS | 
                            select SerialNumber
                        $processor = Get-WmiObject -ComputerName $computer -class Win32_Processor | 
                            select AddressWidth -first 1
                        $properties = @{'ComputerName'=$computer;
                                        'OSVersion'=$os.Caption;
                                        'OSBuild'=$os.BuildNumber;
                                        'OSArchitecture'=$os.OSArchitecture -replace '-bit', '';
                                        'OSSPVersion'=$os.servicepackmajorversion;
                                        'BIOSSerial'=$bios.SerialNumber;
                                        'ProcArchitecture'=$processor.addresswidth}
                        $obj = New-Object -TypeName psobject -Property $properties

                        Write-Output $obj
                    }
                }
            }
        }
        END{}
}

# get-OSinfo -computername .
# Get-OSInfo -computername .,localhost -Verbose -namelog -debug
# Get-OSInfo -host localhost
# get-osinfo -computername badcomputer -namelog -verbose