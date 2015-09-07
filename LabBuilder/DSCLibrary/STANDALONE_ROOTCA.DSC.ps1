<#########################################################################################################################################
DSC Template Configuration File For use by LabBuilder
.Title
	STANDALONE_ROOTCA
.Desription
	Builds a Standalone Root CA.
.Parameters:    
	CACommonName = "BMDLAB.COM Root CA"
	CADistinguishedNameSuffix = "DC=BMDLAB,DC=COM"
	DSConfigDN = "CN=Configuration,DC=BMDLAB,DC=COM"
	CRLPublicationURLs = "1:C:\Windows\system32\CertSrv\CertEnroll\%1_%3%4.crt\n2:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11\n2:http://pki.bmdlab.local/CertEnroll/%1_%3%4.crt"
	CACertPublicationURLs = "1:C:\Windows\system32\CertSrv\CertEnroll\%1_%3%4.crt\n2:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11\n2:http://pki.bmdlab.local/CertEnroll/%1_%3%4.crt"  
#########################################################################################################################################>

Configuration STANDALONE_ROOTCA
{
	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	Import-DscResource -ModuleName xAdcsDeployment
	Node $AllNodes.NodeName {
		# Assemble the Local Admin Credentials
		If ($Node.LocalAdminPassword) {
			[PSCredential]$LocalAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.LocalAdminPassword -AsPlainText -Force))
		}

		WindowsFeature ADCSCA {
			Name = 'ADCS-Cert-Authority'
			Ensure = 'Present'
			}
		
		WindowsFeature ADCSRSAT {
			Name = 'RSAT-ADCS'
			Ensure = 'Present'
			}

		File CAPolicy
		{
			DestinationPath = 'C:\Windows\CAPolicy.inf'
			Contents = "[Version]`r`n Signature= `"$Windows NT$`"`r`n[Certsrv_Server]`r`n RenewalKeyLength=4096`r`n RenewalValidityPeriod=Years`r`n RenewalValidityPeriodUnits=20`r`n CRLDeltaPeriod=Days`r`n CRLDeltaPeriodUnits=0`r`n[CRLDistributionPoint]`r`n[AuthorityInformationAccess]`r`n"
			Ensure = 'Present'
			DependsOn = '[WindowsFeature]ADCSCA'
			Type = 'File'
		}
		
		xADCSCertificationAuthority ADCS
        {
            Ensure = 'Present'
            Credential = $LocalAdminCredential
            CAType = 'StandaloneRootCA'
			CACommonName = $Node.CACommonName
			CADistinguishedNameSuffix = $Node.CADistinguishedNameSuffix
			ValidityPeriod = 'Years'
			ValidityPeriodUnits = 20
            DependsOn = '[File]CAPolicy'
        }
		Script ADCSAdvConfig
		{
			SetScript = {
				If ($Using:Node.DSConifgDN) {
					& "$($ENV:SystemRoot)\system32\certutil.exe" -setreg CA\DSConfigDN $($Using:Node.DSConfigDN)
				}
				If ($Using:Node.CRLPublicationURLs) {
					& "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\CRLPublicationURLs $($Using:Node.CRLPublicationURLs)
				}
				If ($Using:Node.CACertPublicationURLs) {
					& "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\CACertPublicationURLs $($Using:Node.CACertPublicationURLs)
				}
				Restart-Service -Name CertSvc
				Add-Content -Path 'c:\windows\setup\scripts\certutil.log' -Value "Certificate Service Restarted ..."
			}
			GetScript = {
				Return @{
					'DSConfigDN' = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('DSConfigDN');
					'CRLPublicationURLs'  = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CRLPublicationURLs');
					'CACertPublicationURLs'  = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CACertPublicationURLs')
				}
			}
			TestScript = { 
				If (($Using:Node.DSConfigDN) -and ((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('DSConfigDN') -ne $Using:Node.DSConfigDN)) {
					Return $False
				}
				If (($Using:Node.CRLPublicationURLs) -and ((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CRLPublicationURLs') -ne $Using:Node.CRLPublicationURLs)) {
					Return $False
				}
				If (($Using:Node.CACertPublicationURLs) -and ((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CACertPublicationURLs') -ne $Using:Node.CACertPublicationURLs)) {
					Return $False
				}
				Return $True
			}
			DependsOn = '[xADCSCertificationAuthority]ADCS'
		}
	}
}