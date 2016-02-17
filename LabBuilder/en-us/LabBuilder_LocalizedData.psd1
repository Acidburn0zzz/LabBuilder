# culture="en-US"
ConvertFrom-StringData -StringData @'
    FileDownloadError=Error downloading {0} from '{1}'; {2}.
    FileExtractError=Error extracting {0}; {1}.
    ConfigurationFileNotFoundError=Configuration file {0} is not found.
    ConfigurationFileEmptyError=Configuration file {0} is empty.
    ConfigurationInvalidError=Configuration is invalid.
    ConfigurationMissingElementError=Element '{0}' is missing or empty in the configuration.
    PathNotFoundError={0} path '{1}' is not found.
    ResourceModuleNameEmptyError=Resource Module Name is missing or empty.
    ModuleNotAvailableError=Error installing Module '{0}' ({1}); {2}.
    SwitchNameIsEmptyError=Switch name is empty.
    UnknownSwitchTypeError=Unknown switch type '{0}' specified for switch '{1}'.
    AdapterSpecifiedError=Adapter specified on '{0}' switch '{1}'.
    NatSubnetAddressEmptyError=Switch NAT Subnet Address is empty '{0}'.
    EmptyTemplateNameError=Template Name is missing or empty.
    EmptyTemplateVHDError=VHD in Template '{0}' is empty.
    EmptyTemplateVHDNameError=Template VHD name is empty.
    EmptyTemplateVHDISOPathError=The ISO Path in Template VHD '{0}' is empty.
    EmptyTemplateVHDPathError=The VHD Path in Template VHD '{0}' is empty.
    TemplateVHDISORootPathNotFoundError=The default ISO Folder '{0}' for template VHDs is not found.
    TemplateVHDISOPathNotFoundError=The ISO file '{1}' for Template VHD '{0}' could not be found.
    TemplateVHDRootPathNotFoundError=The default VHD Folder '{0}' for template VHDs is not found.
    TemplateSourceVHDNotFoundError=The Template Source VHD '{0}' in Template '{1}' could not be found.
    DSCModuleDownloadError=Module '{2}' required by DSC Config File '{0}' in VM '{1}' could not be found or downloaded.					
    DSCModuleNotFoundError=Module '{2}' required by DSC Config File '{0}' in VM '{1}' could not be found in the module path.
    CertificateCreateError=The self-signed certificate for VM '{0}' could not be created and downloaded.
    CertificateDownloadError=The self-signed certificate for VM '{0}' could not be downloaded.
    DSCConfigMetaMOFCreateError=A Meta MOF File was not created by the DSC LCM Config for VM '{0}'.
    DSCConfigMoreThanOneNodeError=A single Node element cannot be found in the DSC Config File '{0}' in VM '{1}'.
    DSCConfigMOFCreateError=A MOF File was not created by the DSC Config File '{0}' in VM '{1}'.
    NetworkAdapterNotFoundError=VM Network Adapter '{0}' could not be found attached to VM '{1}'.
    NetworkAdapterBlankMacError=VM Network Adapter '{0}' attached to VM '{1}' has a blank MAC Address.
    ManagmentIPAddressError=An IPv4 address for the network adapter connected to the {0} for VM '{1}' could not be identified.
    DSCInitializationError=An error occurred initializing DSC for VM '{0}'.
    RemotingConnectionError=An error occurred connecting to VM '{0}' using PowerShell Remoting.
    InitialSetupCompleteError=The Initial Setup for VM '{0}' did not complete before the timeout occurred.
    InitializationDidNotCompleteError=Initialization for VM '{0}' did not complete.
    SetupCompleteScriptMissingError=The Setup Complete Script file '{1}' specified in VM '{0}' could not be found.
    UnattendFileMissingError=The Unattend file '{1}' specified in VM '{0}' could not be found.
    SetupCompleteFileMissingError=The Setup Complete file '{1}' specified in VM '{0}' could not be found.
    SetupCompleteFileBadTypeError=The Setup Complete file '{1}' specified in VM '{0}' must be either a PS1 or CMD file.
    DSCConfigFileMissingError=The DSC Config file '{1}' specified in VM '{0}' could not be found.
    DSCConfigFileBadTypeError=The DSC Config file '{1}' specified in VM '{0}' must be a PS1 file.
    DSCConfigNameIsEmptyError=The DSC Config Name specified in VM '{0}' is empty.
    VMNameError=The VM name cannot be 'VM' or empty.
    VMTemplateNameEmptyError=The template name in VM '{0}' is empty.
    VMTemplateNotFoundError=The template '{1}' specified in VM '{0}' could not be found.
    VMTemplateVHDPathEmptyError=The template VHD path set in template '{0}' is empty.
    VMAdapterNameError=The Adapter Name in VM '{0}' cannot be 'adapter' or empty.
    VMAdapterSwitchNameError=The Switch Name specified in adapter '{1}' specified in VM '{0}' cannot be empty.
    VMAdapterSwitchNotFoundError=The switch '{2}' specified in adapter '{1}' in VM '{0}' could not be found in Switches.
    VMDataDiskVHDEmptyError=The Data Disk VHD in VM '{0}' cannot be 'datavhd' or empty.
    VMDataDiskCantBeCreatedError=The Data Disk VHD '{1}' specified in VM '{0}' does not exist but the size and type or Source VHD was not provided so it not be created.
    VMDataDiskParentVHDNotFoundError=The Data Disk Parent VHD '{1}' specified in VM '{0}' could not be found.
    VMDataDiskParentVHDMissingError=The Differencing Data Disk Parent VHD specified in VM '{0}' is empty.
    VMDataDiskSourceVHDNotFoundError=The Data Disk Source VHD '{1}' specified in VM '{0}' could not be found.
    VMDataDiskUnknownTypeError=Unknown Data Disk type '{2}' specified in VM '{0}' for VHD '{1}'.
    VMDataDiskSupportPRError=The SupportPR flag is not supported for non-shared Data Disk VHD '{1}' specified in VM '{0}'.
    VMDataDiskSharedDifferencingError=The Differencing Data Disk VHD '{1}' specified in VM '{0}' can not be set as Shared.
    VMDataDiskSourceVHDIfMoveError=The Data Disk VHD '{1}' specified in VM '{0}' must have a Source VHD specified if MoveSourceVHD is set.
    VMDataDiskVHDConvertError=The Data Disk '{1}' in VM '{0}' cannot be converted to a {2} type.
    VMDataDiskVHDShrinkError=The Data Disk '{1}' in VM '{0}' cannot be shrunk to {2}.
    InstallingHyperVComponentsMesage=Installing {0} Hyper-V Components.
    InitializingHyperVComponentsMesage=Initializing Hyper-V Components.
    DownloadingLabResourcesMessage=Downloading Lab Resources.
    CreatingLabManagementSwitchMessage=Creating Lab Management Switch {0} on Vlan {1}.
    UpdatingLabManagementSwitchMessage=Updating Lab Management Switch {0} to Vlan {1}.
    ModuleNotInstalledMessage=Module {0} ({1}) is not installed.
    DownloadingLabResourceWebMessage=Downloading Module {0} ({1}) from '{2}'.
    InstallingLabResourceWebMessage=Installing Module {0} ({1}) to Modules Folder '{2}'.
    InstalledLabResourceWebMessage=Installed Module {0} ({1}) to '{2}'.
    CreatingVirtualSwitchMessage=Creating {0} Virtual Switch '{1}'.
    DeleteingVirtualSwitchMessage=Deleting {0} Virtual Switch '{1}'.
    CopyingTemplateSourceVHDMessage=Copying template source VHD '{0}' to '{1}'.
    OptimizingTemplateVHDMessage=Optimizing template VHD '{0}'.
    SettingTemplateVHDReadonlyMessage=Setting template VHD '{0}' as readonly.
    SkippingTemplateVHDFileMessage=Skipping template VHD file '{0}' because it already exists.
    DeletingTemplateVHDMessage=Deleting Template VHD '{0}'.
    DSCConfigIdentifyModulesMessage=Identifying Modules used by DSC Config File '{0}' in VM '{1}'.
    DSCConfigSearchingForModuleMessage=Searching for Module '{2}' required by DSC Config File '{0}' in VM '{1}'.
    DSCConfigInstallingModuleMessage=Installing Module '{2}' required by DSC Config File '{0}' in VM '{1}'.
    DSCConfigSavingModuleMessage=Saving Module '{2}' required by DSC Config File '{0}' in VM '{1}' to LabBuilder files.
    DSCConfigCreatingLCMMOFMessage=Creating DSC LCM Config file '{0}' in VM '{1}'.
    DSCConfigCreatingMOFMessage=Creating DSC Config file '{0}' in VM '{1}'.
    DSCConfigMOFCreatedMessage=DSC MOF File '{0}' for VM '{1}'. was created successfully.
    ConnectingVMMessage=Connecting to VM '{0}'.
    ConnectingVMFailedMessage=Connection to VM '{0}' failed ({2}), retrying in {1} seconds.
    ConnectingVMAccessDeniedMessage=Access Denied connecting to VM '{0}', the connection will not be retried.
    CopyingFilesToVMMessage=Copying {1} Files to VM '{0}'.
    CopyingFilesToVMFailedMessage=Copying {1} Files to VM '{0}' failed, retrying in {2} seconds.
    CreatingVMMessage=Creating VM '{0}'.
    CreatingVMDiskMessage=Creating {2} disk '{1}' for VM '{0}'.
    CreatingVMDiskByMovingSourceVHDMessage=Creating disk {1} for VM '{0}' by moving Source VHD '{2}'.
    CreatingVMDiskByCopyingSourceVHDMessage=Creating disk {1} for VM '{0}' by copying Source VHD '{2}'.
    VMDiskAlreadyExistsMessage={2} disk '{1}' for VM '{0}' already exists.
    ExpandingVMDiskMessage=Expanding {2} disk '{1}' for VM '{0}' to {3}.
    AddingVMDiskMessage=Adding {2} disk '{1}' to VM '{0}'.
    DeletingVMAllDisksMessage=Deleting all disks from VM '{0}'.
    AddingVMNetworkAdapterMessage=Adding {2} network adapter {1} to VM '{0}'.
    SettingVMNetworkAdapterVlanMessage=Setting VLAN on {2} network adapter {1} in VM '{0}' to {3}.
    ClearingVMNetworkAdapterVlanMessage=Clearing VLAN on {2} network adapter {1} in VM '{0}'.
    StartingVMMessage=Starting VM '{0}'.
    StoppingVMMessage=Stopping VM '{0}'.
    RemovingVMMessage=Removing VM '{0}'.
    RemovedVMMessage=Removed VM '{0}'.
    StartingDSCMessage=Starting DSC on VM '{0}'.
    WriteMountingVMBootDiskMessage=Mounting VM '{0}' VHD Boot Disk '{1}'.
    DownloadingVMBootDiskFileMessage=Downloading VM '{0}' {1} file '{2}'.
    ApplyingVMBootDiskFileMessage=Applying {1} file '{2}' to VHD Boot Disk for VM '{0}'.
    CreatingVMBootDiskPantherFolderMessage=Creating Panther folder to VHD Boot Disk for VM '{0}'.
    DismountingVMBootDiskMessage=Dismounting VM '{0}' VHD Boot Disk '{1}'.
    AddingIPAddressToTrustedHostsMessage=Adding IP Address '{1}' to WS-Man Trusted Hosts to allow remoting to '{0}'.
    WaitingForIPAddressAssignedMessage=Waiting for valid IP Address to be assigned to VM '{0}', retrying in {1} seconds.
    WaitingForInitialSetupCompleteMessage=Waiting for Initial Setup to be complete on VM '{0}', retrying in {1} seconds.
    WaitingForCertificateMessage=Waiting for Certificate file on VM '{0}', retrying in {1} seconds.
    FailedToUploadCertificateCreateScriptMessage=Failed to upload certificate create script to VM '{0}', retrying in {1} seconds.
    FailedToDownloadCertificateMessage=Failed to download certificate from VM '{0}', retrying in {1} seconds.
    FailedToExecuteCertificateCreateScriptMessage=Failed to execute certificate create script to VM '{0}', retrying in {1} seconds.
    InitialSetupIsAlreadyCompleteMessaage=Initial Setup on VM '{0}' has already been completed.
    CertificateDownloadStartedMessage=Certificate download from VM '{0}' started.
    CertificateDownloadCompleteMessage=Certificate download from VM '{0}' complete.
    VMNotFoundMessage=VM '{0}' was not found in Hyper-V server.
    EnableVMIntegrationServiceMessage=The '{1}' Integration Service has been enabled in VM '{0}'.
    DisableVMIntegrationServiceMessage=The '{1}' Integration Service has been disabled in VM '{0}'.
    ISONotFoundDownloadURLMessage=The ISO '{1}' for VM template VHD '{0}' could not be found. It can be downloaded from '{2}'.
    CreatingMountFolderMessage=Creating a temporary mount folder '{0}'.
    CreatingVMTemplateVHDMessage=Creating the '{0}' VM Template VHD '{1}'.
    MountingVMTemplateVHISODMessage=Mounting the ISO '{1}' VM Template VHD '{0}'.
    DismountingVMTemplateVHISODMessage=Dismounting the ISO '{1}' VM Template VHD '{0}'.
    RemovingMountFolderMessage=Removing the temporary mount folder '{0}'.
    ConvertingWIMtoVHDMessage=Converting '{3}' in '{0}' to a bootable {4} {5} {2} '{1}'.
'@
