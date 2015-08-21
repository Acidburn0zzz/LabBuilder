﻿#Requires -version 5.0

##########################################################################################################################################
function Get-LabConfiguration {
	[CmdLetBinding(DefaultParameterSetName="Path")]
	[OutputType([XML])]
	param (
		[parameter(Mandatory=$true, ParameterSetName="Path")]
		[String]$Path,

		[parameter(Mandatory=$true, ParameterSetName="Content")]
		[String]$Content
	) # Param
	If ($Path) {
		If (-not (Test-Path -Path $Path)) {
			Throw "Configuration file $Path is not found."
		} # If
		$Content = Get-Content -Path $Path  
	} # If
	If (($Content -eq $null) -or ($Content -eq '')) {
		Throw "Configuration is empty."
	} # If
	[XML]$Configuration = New-Object -TypeName XML
	$Configuration.LoadXML($Content)
	Return $Configuration
} # Get-LabConfiguration
##########################################################################################################################################

##########################################################################################################################################
function Test-LabConfiguration {
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration
	)

	If ($Configuration.labbuilderconfig -eq $null) {
		Throw "<labbuilderconfig> node is missing from the configuration."
	}

	# Check folders exist
	[String]$VMPath = $Configuration.labbuilderconfig.SelectNodes('settings').vmpath
	If (-not $VMPath) {
		Throw "<settings>\<vmpath> is missing or empty in the configuration."
	}

	If (-not (Test-Path -Path $VMPath)) {
		Throw "The VM Path $VMPath is not found."
	}

	[String]$VHDParentPath = $Configuration.labbuilderconfig.SelectNodes('settings').vhdparentpath
	If (-not $VHDParentPath) {
		Throw "<settings>\<vhdparentpath> is missing or empty in the configuration."
	}

	If (-not (Test-Path -Path $VHDParentPath)) {
		Throw "The VHD Parent Path $VHDParentPath is not found."
	}

	Return $True
} # Test-LabConfiguration
##########################################################################################################################################

##########################################################################################################################################
function Initialize-LabHyperV {
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration
	)
	
	# Install Hyper-V Components
	Write-Verbose "Initializing Lab Hyper-V Components ..."
	
	If ((Get-CimInstance Win32_OperatingSystem).ProductType -eq 1) {
		# Desktop OS
		Get-WindowsOptionalFeature -Online -FeatureName *Hyper-V* | Where-Object -Property State -Eq 'Disabled' | Enable-WindowsOptionalFeature -Online
	} Else {
		# Server OS
		Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools
	}

	[String]$MacAddressMinimum = $Configuration.labbuilderconfig.SelectNodes('settings').macaddressminimum
	If (-not $MacAddressMinimum) {
		$MacAddressMinimum = '00155D010600'
	}

	[String]$MacAddressMaximum = $Configuration.labbuilderconfig.SelectNodes('settings').macaddressmaximum
	If (-not $MacAddressMaximum) {
		$MacAddressMaximum = '00155D0106FF'
	}

	Write-Verbose "Configuring Lab Hyper-V Components ..."
	Set-VMHost -MacAddressMinimum $MacAddressMinimum -MacAddressMaximum $MacAddressMaximum
} # Initialize-LabHyperV
##########################################################################################################################################

##########################################################################################################################################
function Initialize-LabDSC {
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration
	)
	
	# Install DSC Components
	Write-Verbose "Configuring Lab DSC Components ..."
} # Initialize-LabDSC
##########################################################################################################################################

##########################################################################################################################################
function Get-LabSwitches {
	[OutputType([System.Collections.Hashtable[]])]
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration
	)

	[System.Collections.Hashtable[]]$Switches = @()
	$ConfigSwitches = $Configuration.labbuilderconfig.SelectNodes('switches').Switch
	Foreach ($ConfigSwitch in $ConfigSwitches) {
		[System.Collections.Hashtable[]]$ConfigAdapters = @()
		If ($ConfigSwitch.Adapters) {
			Foreach ($Adapter in $ConfigSwitch.Adapters) {
				$ConfigAdapters += @{ Name = $Adapter.Name; MACAddress = $Adapter.MacAddress }
			}
		}
		$Switches += @{ Name = $ConfigSwitch.Name; Type = $ConfigSwitch.Type; Adapters = $ConfigAdapters; Vlan = $ConfigSwitch.Vlan } 
	}
	return $Switches
} # Get-LabSwitches
##########################################################################################################################################

##########################################################################################################################################
function Initialize-LabSwitches {
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration,
	
		[Parameter(Mandatory=$true)]
		[System.Collections.Hashtable[]]$Switches
	)
	
	# Create Hyper-V Switches
	Foreach ($Switch in $Switches) {
		If ((Get-VMSwitch | Where-Object -Property Name -eq $Switch.Name).Count -eq 0) {
			[String]$SwitchName = $Switch.Name
			[string]$SwitchType = $Switch.Type
			Write-Verbose "Creating Virtual Switch '$SwitchName' ..."
			Switch ($SwitchType) {
				'External' {
					New-VMSwitch -Name $SwitchName -SwitchType External
					If ($Switch.Adapters) {
						Foreach ($Adapter in $Switch.Adapters) {
							If ($Switch.VLan) {
								# A default VLAN is assigned to this Switch so assign it to the management adapters
								Add-VMNetworkAdapter -ManagementOS -SwitchName $Switch.Name -Name $Adapter.Name -StaticMacAddress $Adapter.MacAddress -Passthru | Set-VMNetworkAdapterVlan -Access -VlanId $Switch.Vlan | Out-Nul
							} Else { 
								Add-VMNetworkAdapter -ManagementOS -SwitchName $Switch.Name -Name $Adapter.Name -StaticMacAddress $Adapter.MacAddress | Out-Null
							} # If
						} # Foreach
					} # If
					Break
				} # 'External'
				'Private' {
					New-VMSwitch -Name $SwitchName -SwitchType Private
					Break
				} # 'Private'
				'Internal' {
					New-VMSwitch -Name $SwitchName -SwitchType Internal
					Break
				} # 'Internal'
				Default {
					Throw "Unknown Switch Type $SwitchType."
				}
			} # Switch
		} # If
	} # Foreach        

} # Initialize-LabSwitches
##########################################################################################################################################

##########################################################################################################################################
function Get-LabVMTemplates {
	[OutputType([System.Collections.Hashtable[]])]
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration
	)

	[System.Collections.Hashtable[]]$VMTemplates = @()
	[String]$VHDParentPath = $Configuration.labbuilderconfig.SelectNodes('settings').vhdparentpath
	[String]$FromVM=$Configuration.labbuilderconfig.SelectNodes('templates').fromvm
	If (($FromVM -ne $null) -and ($FromVM -ne '')) {
		$Templates = Get-VM -Name $FromVM
		Foreach ($Template in $Templates) {
			[String]$VMTemplateName = $Template.Name
			[String]$VMTemplateSourceVHD = ($Template | Get-VMHardDiskDrive).Path
			[String]$VMTemplateDestVHD = "$VHDParentPath\$([System.IO.Path]::GetFileName($VMTemplateSourceVHD))"
			$VMTemplates += @{ Name = $VMTemplateName; SourceVHD = $VMTemplateSourceVHD; DestVHD = $VMTemplateDestVHD; }
		} # Foreach
	}
	$Templates = $Configuration.labbuilderconfig.SelectNodes('templates').template
	Foreach ($Template in $Templates) {
	   [String]$VMTemplateName = $Template.Name
	   [String]$VMTemplateSourceVHD = $Template.SourceVHD
	   [String]$VMTemplateDestVHD = "$VHDParentPath\$([System.IO.Path]::GetFileName($VMTemplateSourceVHD))"
	   $VMTemplates += @{ Name = $VMTemplateName; SourceVHD = $VMTemplateSourceVHD; DestVHD = $VMTemplateDestVHD; }
	} # Foreach
	Return $VMTemplates
} # Get-LabVMTemplates
##########################################################################################################################################

##########################################################################################################################################
function Initialize-LabVMTemplates {
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration,

		[Parameter(Mandatory=$true)]
		[System.Collections.Hashtable[]]$VMTemplates
	)
	
	Foreach ($VMTemplate in $VMTemplates) {
		If (-not (Test-Path $VMTemplate.DestVHD)) {
			# The template VHD isn't in the VHD Parent folder - so copy it there after optimizing it
			Set-ItemProperty -Path $VMTemplate.SourceVHD -Name IsReadOnly -Value $False
			Write-Verbose "Optimizing template source VHD $($VMTemplate.SourceVHD) ..."
			Optimize-VHD -Path $VMTemplate.SourceVHD -Mode Full
			Set-ItemProperty -Path $VMTemplate.SourceVHD -Name IsReadOnly -Value $True
			Write-Verbose "Copying template source VHD $($VMTemplate.SourceVHD) to $($VMTemplate.DestVHD) ..."
			Copy-Item -Path $VMTemplate.SourceVHD -Destination $VMTemplate.DestVHD
			Set-ItemProperty -Path $VMTemplate.DestVHD -Name IsReadOnly -Value $True
		}
	}
} # Initialize-LabVMTemplates
##########################################################################################################################################

##########################################################################################################################################
function Get-LabVMs {
	[OutputType([System.Collections.Hashtable[]])]
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration,

		[Parameter(Mandatory=$true)]
		[System.Collections.Hashtable[]]$VMTemplates,

		[Parameter(Mandatory=$true)]
		[System.Collections.Hashtable[]]$Switches
	)

	[System.Collections.Hashtable[]]$LabVMs = @()
	[String]$VHDParentPath = $Configuration.labbuilderconfig.SelectNodes('settings').vhdparentpath
	$VMs = $Configuration.labbuilderconfig.SelectNodes('vms').vm
	[Microsoft.HyperV.PowerShell.VMSwitch[]]$CurrentSwitches = Get-VMSwitch

	Foreach ($VM in $VMs) {
		# Find the template that this VM uses and get the Parent VHD Path
		[String]$TemplateVHDPath = $null
		Foreach ($VMTemplate in $VMTemplates) {
			If ($VMTemplate.Name -eq $VM.Template) {
				$TemplateVHDPath = $VMTemplate.DestVHD
				Break
			}
		}
		If ($TemplateVHDPath -eq $null)
		{
			throw "The template $($VM.Template) is not available."
		}
		If (-not (Test-Path $TemplateVHDPath))
		{
			throw "The template VHD $TemplateVHDPath can not be found."
		}

		[System.Collections.Hashtable[]]$VMAdapters = @()
		Foreach ($VMAdapter in $VM.Adapters.Adapter) {
			# Check the switch is in the switch list
			[Boolean]$Found = $False
			Foreach ($Switch in $Switches) {
				If ($Switch.Name -eq $VMAdapter.SwitchName) {
					# The switch is found in the switch list - record the VLAN (if there is one)
					$Found = $True
					$SwitchVLan = $Switch.Vlan
					Break
				} # If
			} # Foreach
			If (-not $Found) {
				throw "The switch $($VMAdapter.SwitchName) could not be found in Hyper-V."
			} # If
			# Check the switch is available in Hyper-V
			If (($CurrentSwitches | Where-Object -Property Name -eq $VMAdapter.SwitchName).Count -eq 0) {
				throw "The switch $($VMAdapter.SwitchName) could not be found in Hyper-V."
			}
			
			# Figure out the VLan - If defined in the VM use it, otherwise use the one defined in the Switch, otherwise keep blank.
			$VLan = $VMAdapter.VLan
			If (-not $VLan) {
				$VLan = $SwitchVLan
			}
			$VMAdapters += @{ Name = $VMAdapter.Name; SwitchName = $VMAdapter.SwitchName; MACAddress = $VMAdapter.macaddress; VLan = $VLan }
		}

		$LabVMs += @{
			Name = $VM.name;
			Template = $VM.template;
			TemplateVHD = $TemplateVHDPath;
			UseDifferencingDisk = $VM.usedifferencingbootdisk;
			MemoryStartupBytes = (Invoke-Expression $VM.memorystartupbytes);
			ProcessorCount = $VM.processorcount;
			AdministratorPassword = $VM.administratorpassword;
			ProductKey = $VM.productkey;
			TimeZone = $VM.timezone;
			Adapters = $VMAdapters;
			DataVHDSize = (Invoke-Expression $VM.DataVHDSize);
		}
	} # Foreach        

	Return $LabVMs
} # Get-LabVMs
##########################################################################################################################################

##########################################################################################################################################
function Initialize-LabVMs {
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration,

		[Parameter(Mandatory=$true)]
		[System.Collections.Hashtable[]]$VMs
	)
	
	$CurrentVMs = Get-VM
	[String]$VMPath = $Configuration.labbuilderconfig.SelectNodes('settings').vmpath
	
	Foreach ($VM in $VMs) {
		If (($CurrentVMs | Where-Object -Property Name -eq $VM.Name).Count -eq 0) {
			Write-Verbose "Creating VM $($VM.Name) ..."

			# Create the paths for the VM
			If (-not (Test-Path -Path "$VMPath\$($VM.Name)")) {
				New-Item -Path "$VMPath\$($VM.Name)" -ItemType Directory | Out-Null
			}
			If (-not (Test-Path -Path "$VMPath\$($VM.Name)\Virtual Machines")) {
				New-Item -Path "$VMPath\$($VM.Name)\Virtual Machines" -ItemType Directory | Out-Null
			}
			If (-not (Test-Path -Path "$VMPath\$($VM.Name)\Virtual Hard Disks")) {
				New-Item -Path "$VMPath\$($VM.Name)\Virtual Hard Disks" -ItemType Directory | Out-Null
			}

			# Create the boot disk
			$VMBootDiskPath = "$VMPath\$($VM.Name)\Virtual Hard Disks\$($VM.Name) Boot Disk.vhdx"
			If (-not (Test-Path -Path $VMBootDiskPath)) {
				If ($VM.UseDifferencingDisk -eq 'Y') {
					Write-Verbose "VM $($VM.Name) differencing boot disk $VMBootDiskPath being created ..."
					New-VHD -Differencing -Path $VMBootDiskPath -ParentPath $VM.TemplateVHD | Out-Null
				} Else {
					Write-Verbose "VM $($VM.Name) boot disk $VMBootDiskPath being created ..."
					Copy-Item -Path $VM.TemplateVHD -Destination $VMBootDiskPath | Out-Null
				}            
				# Because this is a new boot disk create an unattend file and inject it into the VHD
				Set-LabVMUnattendFile -Configuration $Configuration -VMBootDiskPath $VMBootDiskPath -VM $VM
			} Else {
				Write-Verbose "VM $($VM.Name) boot disk $VMBootDiskPath already exists..."
			} # If
			New-VM -Name $VM.Name -MemoryStartupBytes $VM.MemoryStartupBytes -Generation 2 -Path $VMPath -VHDPath $VMBootDiskPath | Out-Null
			# Just get rid of all network adapters bcause New-VM automatically creates one which we don't need
			Get-VMNetworkAdapter -VMName $VM.Name | Remove-VMNetworkAdapter | Out-Null
		}

		# Set the processor count if different to default and if specified in config file
		If ($VM.ProcessorCount) {
			If ($VM.ProcessorCount -ne (Get-VM -Name $VMs.Name).ProcessorCount) {
				Set-VM -Name $VM.Name -ProcessorCount $VM.ProcessorCount
			} # If
		} # If

		# Do we need to add a data disk?
		If ($VM.DataVHDSize -and ($VMs.DataVHDSize -gt 0)) {
			[String]$VMDataDiskPath = "$VMPath\$($VM.Name)\Virtual Hard Disks\$($VM.Name) Data Disk.vhdx"
			# Does the disk already exist?
			If (Test-Path -Path $VMDataDiskPath) {
				Write-Verbose "VM $($VM.Name) data disk $VMDataDiskPath already exists ..."
				# Does the disk need to shrink or grow?
				If ((Get-VHD -Path $VMDataDiskPath).Size -ne $VMs.DataVHDSize) {
					Write-Verbose "VM $($VM.Name) Data Disk $VMDataDiskPath resizing to $($VMs.DataVHDSize) ..."
					Resize-VHD -Path $VMDataDiskPath -SizeBytes $VMs.DataVHDSize | Out-Null
				}
			} Else {
				# Create a new VHD
				Write-Verbose "VM $($VM.Name) data disk $VMDataDiskPath is being created ..."
				New-VHD -Path $VMDataDiskPath -SizeBytes $VM.DataVHDSize -Dynamic | Out-Null
			} # If
			# Does the disk already exist in the VM
			If ((Get-VMHardDiskDrive -VMName $VMs.Name | Where-Object -Property Path -EQ $VMDataDiskPath).Count -EQ 0) {
				Write-Verbose "VM $($VM.Name) data disk $VMDataDiskPath is being added to VM ..."
				Add-VMHardDiskDrive -VMName $VM.Name -Path $VMDataDiskPath -ControllerType SCSI -ControllerLocation 1 -ControllerNumber 0 | Out-Null
			} # If
		} # If
			
		# Create any network adapters
		Foreach ($VMAdapter in $VM.Adapters) {
			If ((Get-VMNetworkAdapter -VMName $VM.Name | Where-Object -Property Name -EQ $VMAdapter.Name).Count -eq 0) {
				Write-Verbose "VM $($VM.Name) network adapter ($VMAdapter.Name) is being added ..."
				Add-VMNetworkAdapter -VMName $VM.Name -SwitchName $VMAdapter.SwitchName -Name $VMAdapter.Name
			} # If
			$Vlan = $VMAdapter.VLan
			If ($VLan) {
				Write-Verbose "VM $($VM.Name) network adapter $($VMAdapter.Name) VLAN is set to $Vlan ..."
				Get-VMNetworkAdapter -VMName $VM.Name -Name $VMAdapter.Name | Set-VMNetworkAdapterVlan -Access -VlanId $Vlan | Out-Null
			} Else {
				Write-Verbose "VM $($VM.Name) network adapter $($VMAdapter.Name) VLAN is cleared ..."
				Get-VMNetworkAdapter -VMName $VM.Name -Name $VMAdapter.Name | Set-VMNetworkAdapterVlan -Untagged | Out-Null
			} # If
			If ($VMAdapter.MACAddress) {
				Get-VMNetworkAdapter -VMName $VM.Name -Name $VMAdapter.Name | Set-VMNetworkAdapter -StaticMacAddress $VMAdapter.MACAddress | Out-Null
			} Else {
				Get-VMNetworkAdapter -VMName $VM.Name -Name $VMAdapter.Name | Set-VMNetworkAdapter -DynamicMacAddress | Out-Null
			} # If
		} # Foreach
		
		# The VM is now ready to be started
		If ((Get-VM -Name $VMs.Name).State -eq 'Off') {
			Write-Verbose "VM $($VM.Name) is starting ..."
			$StartTime = Get-Date

			Start-VM -VMName $VM.Name
			# Wait for the VM to become ready so any post build configuration (e.g. DSC) can be applied.
			
			Wait-LabVMStart -VM $VM | Out-Null

			$EndTime = Get-Date
			Write-Verbose "VM $($VM.Name) started in $(($EndTime - $StartTime).Seconds)..."

			# Even though the VM has started it might still be in the process installing (after a sysprep).
			# So will need to wait for this process to complete
		} # If

		# Now it is time to assign any post initialize scripts/DSC etc.
	} # Foreach
} # Initialize-LabVMs
##########################################################################################################################################

##########################################################################################################################################
function Remove-LabVMs {
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration,

		[Parameter(Mandatory=$true)]
		[System.Collections.Hashtable[]]$VMs,

		[Switch]$RemoveVHDs
	)
	
	$CurrentVMs = Get-VM
	[String]$VMPath = $Configuration.labbuilderconfig.SelectNodes('settings').vmpath
	
	Foreach ($VM in $VMs) {
		If (($CurrentVMs | Where-Object -Property Name -eq $VM.Name).Count -ne 0) {
			If ((Get-VM -Name $VM.Name).State -eq 'Running') {
				Write-Verbose "Stopping VM $($VM.Name) ..."
				Stop-VM -Name $VM.Name
				Wait-LabVMOff -VM $VM
			}
			Write-Verbose "Removing VM $($VM.Name) ..."
			If ($RemoveVHDs) {
				Write-Verbose "Deleting VM $($VM.Name) hard drive(s) ..."
				Get-VMHardDiskDrive -VMName $VM.Name | Select-Object -Property Path | Remove-Item
			}
			Remove-VM -VM $VM.Name
			Write-Verbose "Removed VM $($VM.Name) ..."
		}
	}
}
##########################################################################################################################################

##########################################################################################################################################
function Wait-LabVMStart {
	[OutputType([Boolean])]
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[System.Collections.Hashtable]$VM
	)
	$Heartbeat = Get-VMIntegrationService -VMName $VM.Name -Name Heartbeat
	while ($Heartbeat.PrimaryStatusDescription -ne "OK")
	{
		$Heartbeat = Get-VMIntegrationService -VMName $VM.Name -Name Heartbeat
		sleep 1
	} # while

	Return $True
} # Wait-LabVMStart
##########################################################################################################################################

##########################################################################################################################################
function Wait-LabVMOff {
	[OutputType([Boolean])]
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[System.Collections.Hashtable]$VM
	)
	$VM = Get-VM -Name $VM.Name
	while ($VM.State -ne "Off")
	{
		$VM = Get-VM -Name $VM.Name
		sleep 1
	} # while

	Return $True
} # Wait-LabVMOff
##########################################################################################################################################

##########################################################################################################################################
function Set-LabVMUnattendFile {
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration,

		[Parameter(Mandatory=$true)]
		[String]$VMBootDiskPath,

		[Parameter(Mandatory=$true)]
		[System.Collections.Hashtable]$VM
	)
[String]$DomainName = $Configuration.labbuilderconfig.SelectNodes('settings').domainname
[String]$Email = $Configuration.labbuilderconfig.SelectNodes('settings').email

$UnattendContent = [String] @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
	<settings pass="offlineServicing">
		<component name="Microsoft-Windows-LUA-Settings" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<EnableLUA>false</EnableLUA>
		</component>
	</settings>
	<settings pass="generalize">
		<component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<SkipRearm>1</SkipRearm>
		</component>
	</settings>
	<settings pass="specialize">
		<component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<InputLocale>0409:00000409</InputLocale>
			<SystemLocale>en-US</SystemLocale>
			<UILanguage>en-US</UILanguage>
			<UILanguageFallback>en-US</UILanguageFallback>
			<UserLocale>en-US</UserLocale>
		</component>
		<component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<SkipAutoActivation>true</SkipAutoActivation>
		</component>
		<component name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<CEIPEnabled>0</CEIPEnabled>
		</component>
		<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<ComputerName>$($VM.ComputerName)</ComputerName>
			<ProductKey>$($VM.ProductKey)</ProductKey>
		</component>
	</settings>
	<settings pass="oobeSystem">
		<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<OOBE>
				<HideEULAPage>true</HideEULAPage>
				<HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
				<HideOnlineAccountScreens>true</HideOnlineAccountScreens>
				<HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
				<NetworkLocation>Work</NetworkLocation>
				<ProtectYourPC>1</ProtectYourPC>
				<SkipUserOOBE>true</SkipUserOOBE>
				<SkipMachineOOBE>true</SkipMachineOOBE>
			</OOBE>
			<UserAccounts>
			   <AdministratorPassword>
				  <Value>$($VM.AdministratorPassword)</Value>
				  <PlainText>true</PlainText>
			   </AdministratorPassword>
			</UserAccounts>
			<RegisteredOrganization>$($DomainName)</RegisteredOrganization>
			<RegisteredOwner>$($Email)</RegisteredOwner>
			<DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>
			<TimeZone>$($VM.TimeZone)</TimeZone>
		</component>
		<component name="Microsoft-Windows-ehome-reg-inf" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="NonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<RestartEnabled>true</RestartEnabled>
		</component>
		<component name="Microsoft-Windows-ehome-reg-inf" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="NonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<RestartEnabled>true</RestartEnabled>
		</component>
	</settings>
</unattend>
"@
	Write-Verbose "Applying VM $($VM.Name) Unattend File ..."
	[String]$UnattendFile = $ENV:Temp+"\Unattend.xml"
	[String]$MountPount = "C:\TempMount"
	Set-Content -Path $UnattendFile -Value $UnattendContent | Out-Null
	New-Item -Path $MountPount -ItemType Directory | Out-Null
	Mount-WindowsImage -ImagePath $VMBootDiskPath -Path $MountPount -Index 1 | Out-Null
	Copy-Item -Path $UnattendFile -Destination c:\tempMount\Windows\Panther\ -Force | Out-Null
	Dismount-WindowsImage -Path $MountPount -Save | Out-Null
	Remove-Item -Path $MountPount | Out-Null
	Remove-Item -Path $UnattendFile | Out-Null
} # Set-LabVMUnattendFile
##########################################################################################################################################

##########################################################################################################################################
function Set-LabVMInitalDSCPushMode {
	[CmdLetBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[XML]$Configuration,

		[Parameter(Mandatory=$true)]
		[String]$VMBootDiskPath,

		[Parameter(Mandatory=$true)]
		[System.Collections.Hashtable]$VM
	)
	Write-Verbose "Starting VM $($VM.Name) DSC Push Mode ..."
	[String]$UnattendFile = $ENV:Temp+"\Unattend.xml"
	[String]$MountPount = "C:\TempMount"
	Set-Content -Path $UnattendFile -Value $UnattendContent | Out-Null
	New-Item -Path $MountPount -ItemType Directory | Out-Null
	Mount-WindowsImage -ImagePath $VMBootDiskPath -Path $MountPount -Index 1 | Out-Null
	Copy-Item -Path $UnattendFile -Destination c:\tempMount\Windows\Panther\ -Force | Out-Null
	Dismount-WindowsImage -Path $MountPount -Save | Out-Null
	Remove-Item -Path $MountPount | Out-Null
	Remove-Item -Path $UnattendFile | Out-Null
} # Set-LabVMUnattendFile
##########################################################################################################################################

##########################################################################################################################################
Function Install-Lab {
	[CmdLetBinding(DefaultParameterSetName="Path")]
	param (
		[parameter(Mandatory=$true, ParameterSetName="Path")]
		[String]$Path,

		[parameter(Mandatory=$true, ParameterSetName="Content")]
		[String]$Content
	) # Param

	If ($Path) {
		[XML]$Config = Get-LabConfiguration -Path $Path
	} Else {
		[XML]$Config = Get-LabConfiguration -Content $Content
	}
	# Make sure everything is OK to install the lab
	If (-not (Test-LabConfiguration -Configuration $Config)) {
		return
	}
	   
	Initialize-LabHyperV -Configuration $Config

	Initialize-LabDSC -Configuration $Config

	$Switches = Get-LabSwitches -Configuration $Config
	Initialize-LabSwitches -Configuration $Config -Switches $Switches

	$VMTemplates = Get-LabVMTemplates -Configuration $Config
	Initialize-LabVMTemplates -Configuration $Config -VMTemplates $VMTemplates

	$VMs = Get-LabVMs -Configuration $Config -VMTemplates $VMTemplates -Switches $Switches
	Initialize-LabVMs -Configuration $Config -VMs $VMs
} # Build-Lab
##########################################################################################################################################

##########################################################################################################################################
Function Uninstall-Lab {
	[CmdLetBinding(DefaultParameterSetName="Path")]
	param (
		[parameter(Mandatory=$true, ParameterSetName="Path")]
		[String]$Path,

		[parameter(Mandatory=$true, ParameterSetName="Content")]
		[String]$Content,

		[Switch]$RemoveSwitches,

		[Switch]$RemoveTemplates,

		[Switch]$RemoveVHDs
	) # Param

	If ($Path) {
		[XML]$Config = Get-LabConfiguration -Path $Path
	} Else {
		[XML]$Config = Get-LabConfiguration -Content $Content
	}
	# Make sure everything is OK to install the lab
	If (-not (Test-LabConfiguration -Configuration $Config)) {
		return
	} # If

	$VMTemplates = Get-LabVMTemplates -Configuration $Config

	$Switches = Get-LabSwitches -Configuration $Config

	$VMs = Get-LabVMs -Configuration $Config -VMTemplates $VMTemplates -Switches $Switches
	If ($RemoveVHDs) {
		Remove-LabVMs -Configuration $Config -VMs $VMs -RemoveVHDs
	} Else {
		Remove-LabVMs -Configuration $Config -VMs $VMs
	} # If

	If ($RemoveTemplates) {
	} # If

	If ($RemoveSwitches) {
	} # If
} # Uninstall-Lab
##########################################################################################################################################

##########################################################################################################################################
# Export the Module Cmdlets
Export-ModuleMember -Function Get-LabConfiguration,Test-LabConfiguration, `
	Initialize-LabHyperV, `
	Get-LabSwitches,Initialize-LabSwitches, `
	Get-LabVMTemplates,Initialize-LabVMTemplates, `
	Get-LabVMs,Initialize-LabVMs, `
	Install-Lab,Uninstall-Lab
##########################################################################################################################################