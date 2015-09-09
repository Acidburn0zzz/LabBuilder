<#########################################################################################################################################
DSC Template Configuration File For use by LabBuilder
.Title
	MEMBER_DHCP
.Desription
	Builds a Server that is joined to a domain and then made into a DHCP Server.
.Parameters:          
	DomainName = "LABBUILDER.COM"
	DomainAdminPassword = "P@ssword!1"
#########################################################################################################################################>

Configuration MEMBER_DHCP
{
	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	Import-DscResource -ModuleName xActiveDirectory
	Import-DscResource -ModuleName xComputerManagement
	Import-DscResource -ModuleName xDHCPServer
	Node $AllNodes.NodeName {
		# Assemble the Local Admin Credentials
		If ($Node.LocalAdminPassword) {
			[PSCredential]$LocalAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.LocalAdminPassword -AsPlainText -Force))
		}
		If ($Node.DomainAdminPassword) {
			[PSCredential]$DomainAdminCredential = New-Object System.Management.Automation.PSCredential ("$($Node.DomainName)\Administrator", (ConvertTo-SecureString $Node.DomainAdminPassword -AsPlainText -Force))
		}

		WindowsFeature DHCPInstall 
        { 
            Ensure = "Present" 
            Name = "DHCP" 
        }

		WindowsFeature RSATADPowerShell
        { 
            Ensure = "Present" 
            Name = "RSAT-AD-PowerShell" 
			DependsOn = "[WindowsFeature]DHCPInstall" 
        } 

        xWaitForADDomain DscDomainWait
        {
            DomainName = $Node.DomainName
            DomainUserCredential = $DomainAdminCredential 
            RetryCount = 100 
            RetryIntervalSec = 10 
			DependsOn = "[WindowsFeature]RSATADPowerShell" 
        }

		xComputer JoinDomain 
        { 
            Name          = $Node.NodeName
            DomainName    = $Node.DomainName
            Credential    = $DomainAdminCredential 
			DependsOn = "[xWaitForADDomain]DscDomainWait" 
        } 

		Script DHCPAuthorize
		{
			PSDSCRunAsCredential = $DomainAdminCredential
			SetScript = {
				Add-DHCPServerInDC
			}
			GetScript = {
				Return @{
					'Authorized' = (@(Get-DHCPServerInDC | Where-Object { $_.IPAddress -In (Get-NetIPAddress).IPAddress }).Count -gt 0);
				}
			}
			TestScript = { 
				Return (-not (@(Get-DHCPServerInDC | Where-Object { $_.IPAddress -In (Get-NetIPAddress).IPAddress }).Count -eq 0))
			}
			DependsOn = '[xComputer]JoinDomain'
		}

	}
}
