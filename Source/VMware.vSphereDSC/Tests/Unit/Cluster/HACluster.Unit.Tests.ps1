<#
Copyright (c) 2018 VMware, Inc.  All rights reserved

The BSD-2 license (the "License") set forth below applies to all parts of the Desired State Configuration Resources for VMware project.  You may not use this file except in compliance with the License.

BSD-2 License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>

using module VMware.vSphereDSC

function Invoke-TestSetup {
    $script:modulePath = $env:PSModulePath
    $script:unitTestsFolder = Join-Path (Join-Path (Get-Module VMware.vSphereDSC -ListAvailable).ModuleBase 'Tests') 'Unit'
    $script:mockModuleLocation = "$script:unitTestsFolder\TestHelpers"

    $script:moduleName = 'VMware.vSphereDSC'
    $script:resourceName = 'HACluster'

    $script:user = 'user'
    $password = 'password' | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($script:user, $password)

    $script:resourceProperties = @{
        Server = '10.23.80.58'
        Credential = $credential
        Name = 'MyCluster'
        Ensure = 'Present'
    }

    $script:constants = @{
        FolderType = 'Folder'
        RootFolderValue = 'group-d1'
        DatacentersFolderName = 'Datacenters'
        DatacenterId = 'MyDatacenter-datacenter-1'
        DatacenterName = 'MyDatacenter'
        DatacenterPathItemOne = 'MyDatacenterFolderOne'
        DatacenterPathItemTwoId = 'my-datacenter-folder-two'
        DatacenterPathItemTwo = 'MyDatacenterFolderTwo'
        HostFolderId = 'group-h4'
        HostFolderName = 'HostFolder'
        DatacenterInventoryPathItemOneId = 'my-cluster-location-one'
        DatacenterInventoryPathItemOne = 'MyClusterFolderOne'
        DatacenterInventoryPathItemTwoId = 'my-cluster-location-two'
        DatacenterInventoryPathItemTwo = 'MyClusterFolderTwo'
        ClusterId = 'my-cluster-id'
        ClusterName = 'MyCluster'
    }

    $script:vCenterWithRootFolderScriptBlock = @'
        return [VMware.VimAutomation.ViCore.Impl.V1.VIServerImpl] @{
            Name = '$($script:resourceProperties.Server)'
            User = '$($script:user)'
            ExtensionData = [VMware.Vim.ServiceInstance] @{
                Content = [VMware.Vim.ServiceContent] @{
                    RootFolder = [VMware.Vim.ManagedObjectReference] @{
                        Type = '$($script:constants.FolderType)'
                        Value = '$($script:constants.RootFolderValue)'
                    }
                }
            }
        }
'@

    $script:rootFolderViewBaseObjectScriptBlock = @'
        return [VMware.Vim.Folder] @{
            Name = '$($script:constants.DatacentersFolderName)'
            MoRef = [VMware.Vim.ManagedObjectReference] @{
                Type = '$($script:constants.FolderType)'
                Value = '$($script:constants.RootFolderValue)'
            }
            ChildEntity = @(
                [VMware.Vim.ManagedObjectReference] @{
                    Type = '$($script:constants.FolderType)'
                    Value = '$($script:constants.DatacenterPathItemOne)'
                }
            )
        }
'@

    $script:datacenterPathItemOneScriptBlock = @'
        return [VMware.Vim.Folder] @{
            Name = '$($script:constants.DatacenterPathItemOne)'
            ChildEntity = @(
                [VMware.Vim.ManagedObjectReference] @{
                    Type = '$($script:constants.FolderType)'
                    Value = '$($script:constants.DatacenterPathItemTwo)'
                }
            )
        }
'@

    $script:datacenterPathItemTwoScriptBlock = @'
        return [VMware.Vim.Folder] @{
            Name = '$($script:constants.DatacenterPathItemTwo)'
            ChildEntity = @(
                [VMware.Vim.ManagedObjectReference] @{
                    Type = '$($script:constants.FolderType)'
                    Value = 'DatacenterPathItemTwo Child Entity'
                }
            )
            MoRef = [VMware.Vim.ManagedObjectReference] @{
                Type = '$($script:constants.FolderType)'
                Value = '$($script:constants.DatacenterPathItemTwoId)'
            }
        }
'@

    $script:datacenterFolderScriptBlock = @'
        return [VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl] @{
            Id = '$($script:constants.DatacenterPathItemTwoId)'
            Name = '$($script:constants.DatacenterPathItemTwo)'
        }
'@

    $script:datacenterWithPathItemTwoAsParentScriptBlock = @'
        return [VMware.VimAutomation.ViCore.Impl.V1.Inventory.DatacenterImpl] @{
            Id = '$($script:constants.DatacenterId)'
            Name = '$($script:constants.DatacenterName)'
            ParentFolderId = '$($script:constants.DatacenterPathItemTwoId)'
            ExtensionData = [VMware.Vim.Datacenter] @{
                HostFolder = [VMware.Vim.ManagedObjectReference] @{
                    Type = '$($script:constants.FolderType)'
                    Value = '$($script:constants.HostFolderId)'
                }
            }
        }
'@

    $script:hostFolderOfDatacenterViewBaseObjectScriptBlock = @'
        return [VMware.Vim.Folder] @{
            Name = '$($script:constants.HostFolderName)'
            MoRef = [VMware.Vim.ManagedObjectReference] @{
                Type = '$($script:constants.FolderType)'
                Value = '$($script:constants.HostFolderId)'
            }
    }
'@

    $script:hostFolderScriptBlock = @'
        return [VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl] @{
            Id = '$($script:constants.HostFolderId)'
            Name = '$($script:constants.HostFolderName)'
        }
'@

    $script:locationsScriptBlock = @'
        return @(
            [VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl] @{
                Id = '$($script:constants.DatacenterInventoryPathItemTwoId)'
                ExtensionData = [VMware.Vim.Folder] @{
                    Name = '$($script:constants.DatacenterInventoryPathItemTwo)'
                    MoRef = [VMware.Vim.ManagedObjectReference] @{
                        Type = '$($script:constants.FolderType)'
                        Value = '$($script:constants.DatacenterInventoryPathItemTwoId)'
                    }
                }
            }
        )
'@

    $script:locationViewBaseObjectScriptBlock = @'
        return [VMware.Vim.Folder] @{
            Name = '$($script:constants.DatacenterInventoryPathItemTwo)'
            Parent = [VMware.Vim.ManagedObjectReference] @{
                Type = '$($script:constants.FolderType)'
                Value = '$($script:constants.DatacenterInventoryPathItemOneId)'
            }
        }
'@

    $script:locationParentScriptBlock = @'
        return [VMware.Vim.Folder] @{
            Name = '$($script:constants.DatacenterInventoryPathItemOne)'
            Parent = [VMware.Vim.ManagedObjectReference] @{
                Type = '$($script:constants.FolderType)'
                Value = '$($script:constants.DatacenterInventoryPathItemOneId)'
            }
        }
'@

    $script:clusterScriptBlock = @'
        return [VMware.VimAutomation.ViCore.Impl.V1.Inventory.ClusterImpl] @{
            Id = '$($script:constants.ClusterId)'
            Name = '$($script:constants.ClusterName)'
            ParentId = '$($script:constants.DatacenterInventoryPathItemTwoId)'
            HAEnabled = '$($true)'
            HAAdmissionControlEnabled = '$($true)'
            HAFailoverLevel = 4
            HAIsolationResponse = 'DoNothing'
            HARestartPriority = 'High'
            ExtensionData = [VMware.Vim.ClusterComputeResource] @{
                ConfigurationEx = [VMware.Vim.ClusterConfigInfoEx] @{
                    DrsConfig = [VMware.Vim.ClusterDrsConfigInfo] @{}
                }
            }
        }
'@

    $env:PSModulePath = $script:mockModuleLocation
    $vimAutomationModule = Get-Module -Name VMware.VimAutomation.Core
    if ($null -ne $vimAutomationModule -and $vimAutomationModule.Path -NotMatch 'TestHelpers') {
        throw 'The Original VMware.VimAutomation.Core Module is loaded in the current session. If you want to run the unit tests please open a new PowerShell session.'
    }

    Import-Module -Name VMware.VimAutomation.Core

    $script:vCenter = [VMware.VimAutomation.ViCore.Impl.V1.VIServerImpl] @{
        Name = $script:resourceProperties.Server
        User = $script:user
        ExtensionData = [VMware.Vim.ServiceInstance] @{
            Content = [VMware.Vim.ServiceContent] @{
                RootFolder = [VMware.Vim.ManagedObjectReference] @{
                    Type = $script:constants.FolderType
                    Value = $script:constants.RootFolderValue
                }
            }
        }
    }

    $script:rootFolder = [VMware.Vim.ManagedObjectReference] @{
        Type = $script:constants.FolderType
        Value = $script:constants.RootFolderValue
    }

    $script:datacenterPathItemOne = [VMware.Vim.ManagedObjectReference] @{
        Type = $script:constants.FolderType
        Value = $script:constants.DatacenterPathItemOne
    }

    $script:datacenterPathItemTwo = [VMware.Vim.ManagedObjectReference] @{
        Type = $script:constants.FolderType
        Value = $script:constants.DatacenterPathItemTwo
    }

    $script:datacenterLocation = [VMware.Vim.ManagedObjectReference] @{
        Type = $script:constants.FolderType
        Value = $script:constants.DatacenterPathItemTwoId
    }

    $script:hostFolder = [VMware.Vim.ManagedObjectReference] @{
        Type = $script:constants.FolderType
        Value = $script:constants.HostFolderId
    }

    $script:hostFolderLocation = [VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl] @{
        Id = $script:constants.HostFolderId
        Name = $script:constants.HostFolderName
    }

    $script:clusterLocation = [VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl] @{
        Id = $script:constants.DatacenterInventoryPathItemTwoId
        ExtensionData = [VMware.Vim.Folder] @{
            Name = $script:constants.DatacenterInventoryPathItemTwo
            MoRef = [VMware.Vim.ManagedObjectReference] @{
                Type = $script:constants.FolderType
                Value = $script:constants.DatacenterInventoryPathItemTwoId
            }
        }
    }

    $script:locationParent = [VMware.Vim.ManagedObjectReference] @{
        Type = $script:constants.FolderType
        Value = $script:constants.DatacenterInventoryPathItemOneId
    }

    $script:cluster = [VMware.VimAutomation.ViCore.Impl.V1.Inventory.ClusterImpl] @{
        Id = $script:constants.ClusterId
        Name = $script:constants.ClusterName
        ParentId = $script:constants.DatacenterInventoryPathItemTwoId
        HAEnabled = $true
        HAAdmissionControlEnabled = $true
        HAFailoverLevel = 4
        HAIsolationResponse = 'DoNothing'
        HARestartPriority = 'High'
        ExtensionData = [VMware.Vim.ClusterComputeResource] @{
            ConfigurationEx = [VMware.Vim.ClusterConfigInfoEx] @{
                DrsConfig = [VMware.Vim.ClusterDrsConfigInfo] @{}
            }
        }
    }
}

function Invoke-TestCleanup {
    Remove-Module -Name VMware.VimAutomation.Core
    $env:PSModulePath = $script:modulePath
}

try {
    # Calls the function to Import the mocked VMware.VimAutomation.Core module before all tests.
    Invoke-TestSetup

    Describe 'HACluster\Set' -Tag 'Set' {
        BeforeEach {
            # Arrange
            $script:resourceProperties.Datacenter = "$($script:constants.DatacenterPathItemOne)/$($script:constants.DatacenterPathItemTwo)/$($script:constants.DatacenterName)"
            $script:resourceProperties.DatacenterInventoryPath = "$($script:constants.DatacenterInventoryPathItemOne)/$($script:constants.DatacenterInventoryPathItemTwo)"

            $vCenterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:vCenterWithRootFolderScriptBlock))
            $rootFolderMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:rootFolderViewBaseObjectScriptBlock))
            $datacenterPathItemOneMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterPathItemOneScriptBlock))
            $datacenterPathItemTwoMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterPathItemTwoScriptBlock))
            $datacenterFolderMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterFolderScriptBlock))
            $datacenterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterWithPathItemTwoAsParentScriptBlock))
            $hostFolderViewBaseObjectMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:hostFolderOfDatacenterViewBaseObjectScriptBlock))
            $hostFolderMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:hostFolderScriptBlock))
            $locationsMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:locationsScriptBlock))
            $locationViewBaseObjectMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:locationViewBaseObjectScriptBlock))
            $locationParentMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:locationParentScriptBlock))

            Mock -CommandName Connect-VIServer -MockWith $vCenterMock -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $rootFolderMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:rootFolder } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $datacenterPathItemOneMock -ParameterFilter { $Server -eq $script:vCenter -and (($Id | ConvertTo-Json) -eq ($script:datacenterPathItemOne | ConvertTo-Json)) } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $datacenterPathItemTwoMock -ParameterFilter { $Server -eq $script:vCenter -and (($Id | ConvertTo-Json) -eq ($script:datacenterPathItemTwo | ConvertTo-Json)) } -ModuleName $script:moduleName
            Mock -CommandName Get-Inventory -MockWith $datacenterFolderMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:datacenterLocation } -ModuleName $script:moduleName
            Mock -CommandName Get-Datacenter -MockWith $datacenterMock -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $hostFolderViewBaseObjectMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:hostFolder } -ModuleName $script:moduleName
            Mock -CommandName Get-Inventory -MockWith $hostFolderMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:hostFolder } -ModuleName $script:moduleName
            Mock -CommandName Get-Inventory -MockWith $locationsMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:constants.DatacenterInventoryPathItemTwo -and $Location -eq $script:hostFolderLocation } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $locationViewBaseObjectMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:constants.DatacenterInventoryPathItemTwoId } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $locationParentMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:locationParent } -ModuleName $script:moduleName

            $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties
        }

        AfterEach {
            $script:resourceProperties.Datacenter = [string]::Empty
            $script:resourceProperties.DatacenterInventoryPath = [string]::Empty
        }

        Context 'Invoking with Ensure Present, non existing Cluster and no HA settings specified' {
            BeforeAll {
                # Arrange
                Mock -CommandName Get-Inventory -MockWith { return $null } -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
                Mock -CommandName New-Cluster -MockWith { return $null } -ModuleName $script:moduleName
            }

            It 'Should call the New-Cluster mock with the passed parameters once' {
                # Act
                $resource.Set()

                # Assert
                $assertMockCalledParams = @{
                    CommandName = 'New-Cluster'
                    ParameterFilter = { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name -and $Location -eq $script:clusterLocation -and !$Confirm }
                    ModuleName = $script:moduleName
                    Exactly = $true
                    Times = 1
                    Scope = 'It'
                }

                Assert-MockCalled @assertMockCalledParams
            }
        }

        Context 'Invoking with Ensure Present, non existing Cluster and HA settings specified' {
            BeforeAll {
                # Arrange
                $script:resourceProperties.HAEnabled = $true
                $script:resourceProperties.HAAdmissionControlEnabled = $true
                $script:resourceProperties.HAFailoverLevel = 4
                $script:resourceProperties.HAIsolationResponse = 'DoNothing'
                $script:resourceProperties.HARestartPriority = 'High'

                $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties

                Mock -CommandName Get-Inventory -MockWith { return $null } -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
                Mock -CommandName New-Cluster -MockWith { return $null } -ModuleName $script:moduleName
            }

            AfterAll {
                $script:resourceProperties.HAEnabled = $null
                $script:resourceProperties.HAAdmissionControlEnabled = $null
                $script:resourceProperties.HAFailoverLevel = $null
                $script:resourceProperties.HAIsolationResponse = 'Unset'
                $script:resourceProperties.HARestartPriority = 'Unset'
            }

            It 'Should call the New-Cluster mock with the passed parameters once' {
                # Act
                $resource.Set()

                # Assert
                $assertMockCalledParams = @{
                    CommandName = 'New-Cluster'
                    ParameterFilter = { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name -and $Location -eq $script:clusterLocation -and `
                                        !$Confirm -and $HAEnabled -eq $true -and $HAAdmissionControlEnabled -eq $true -and $HAFailoverLevel -eq 4 -and `
                                        $HAIsolationResponse -eq 'DoNothing' -and $HARestartPriority -eq 'High' }
                    ModuleName = $script:moduleName
                    Exactly = $true
                    Times = 1
                    Scope = 'It'
                }

                Assert-MockCalled @assertMockCalledParams
            }
        }

        Context 'Invoking with Ensure Present, existing Cluster and no HA settings specified' {
            BeforeAll {
                # Arrange
                $clusterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:clusterScriptBlock))

                Mock -CommandName Get-Inventory -MockWith $clusterMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
                Mock -CommandName Set-Cluster -MockWith { return $null } -ModuleName $script:moduleName
            }

            It 'Should call the Set-Cluster mock with the passed parameters once' {
                # Act
                $resource.Set()

                # Assert
                $assertMockCalledParams = @{
                    CommandName = 'Set-Cluster'
                    ParameterFilter = { $Cluster -eq $script:cluster -and $Server -eq $script:vCenter -and !$Confirm }
                    ModuleName = $script:moduleName
                    Exactly = $true
                    Times = 1
                    Scope = 'It'
                }

                Assert-MockCalled @assertMockCalledParams
            }
        }

        Context 'Invoking with Ensure Present, existing Cluster and HA settings specified' {
            BeforeAll {
                # Arrange
                $script:resourceProperties.HAEnabled = $false
                $script:resourceProperties.HAAdmissionControlEnabled = $false
                $script:resourceProperties.HAFailoverLevel = 4
                $script:resourceProperties.HAIsolationResponse = 'DoNothing'
                $script:resourceProperties.HARestartPriority = 'High'

                $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties

                $clusterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:clusterScriptBlock))

                Mock -CommandName Get-Inventory -MockWith $clusterMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
                Mock -CommandName Set-Cluster -MockWith { return $null } -ModuleName $script:moduleName
            }

            AfterAll {
                $script:resourceProperties.HAEnabled = $null
                $script:resourceProperties.HAAdmissionControlEnabled = $null
                $script:resourceProperties.HAFailoverLevel = $null
                $script:resourceProperties.HAIsolationResponse = 'Unset'
                $script:resourceProperties.HARestartPriority = 'Unset'
            }

            It 'Should call the Set-Cluster mock with the passed parameters once' {
                # Act
                $resource.Set()

                # Assert
                $assertMockCalledParams = @{
                    CommandName = 'Set-Cluster'
                    ParameterFilter = { $Cluster -eq $script:cluster -and $Server -eq $script:vCenter -and !$Confirm -and $HAEnabled -eq $false -and `
                                        $HAAdmissionControlEnabled -eq $false -and $HAFailoverLevel -eq 4 -and $HAIsolationResponse -eq 'DoNothing' -and $HARestartPriority -eq 'High' }
                    ModuleName = $script:moduleName
                    Exactly = $true
                    Times = 1
                    Scope = 'It'
                }

                Assert-MockCalled @assertMockCalledParams
            }
        }

        Context 'Invoking with Ensure Absent and existing Cluster' {
            BeforeAll {
                # Arrange
                $script:resourceProperties.Ensure = 'Absent'
                $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties

                $clusterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:clusterScriptBlock))

                Mock -CommandName Get-Inventory -MockWith $clusterMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
                Mock -CommandName Remove-Cluster -MockWith { return $null } -ModuleName $script:moduleName
            }

            AfterAll {
                $script:resourceProperties.Ensure = 'Present'
            }

            It 'Should call the Remove-Cluster mock with the passed parameters once' {
                # Act
                $resource.Set()

                # Assert
                $assertMockCalledParams = @{
                    CommandName = 'Remove-Cluster'
                    ParameterFilter = { $Cluster -eq $script:cluster -and $Server -eq $script:vCenter -and !$Confirm }
                    ModuleName = $script:moduleName
                    Exactly = $true
                    Times = 1
                    Scope = 'It'
                }

                Assert-MockCalled @assertMockCalledParams
            }
        }

        Context 'Invoking with Ensure Absent and non existing Cluster' {
            BeforeAll {
                # Arrange
                $script:resourceProperties.Ensure = 'Absent'
                $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties

                Mock -CommandName Get-Inventory -MockWith { return $null } -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
                Mock -CommandName Remove-Cluster -MockWith { return $null } -ModuleName $script:moduleName
            }

            AfterAll {
                $script:resourceProperties.Ensure = 'Present'
            }

            It 'Should not call the Remove-Cluster mock' {
                # Act
                $resource.Set()

                # Assert
                $assertMockCalledParams = @{
                    CommandName = 'Remove-Cluster'
                    ParameterFilter = { $Cluster -eq $script:cluster -and $Server -eq $script:vCenter -and !$Confirm }
                    ModuleName = $script:moduleName
                    Exactly = $true
                    Times = 0
                    Scope = 'It'
                }

                Assert-MockCalled @assertMockCalledParams
            }
        }
    }

    Describe 'HACluster\Test' -Tag 'Test' {
        BeforeEach {
            # Arrange
            $script:resourceProperties.Datacenter = "$($script:constants.DatacenterPathItemOne)/$($script:constants.DatacenterPathItemTwo)/$($script:constants.DatacenterName)"
            $script:resourceProperties.DatacenterInventoryPath = "$($script:constants.DatacenterInventoryPathItemOne)/$($script:constants.DatacenterInventoryPathItemTwo)"

            $vCenterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:vCenterWithRootFolderScriptBlock))
            $rootFolderMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:rootFolderViewBaseObjectScriptBlock))
            $datacenterPathItemOneMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterPathItemOneScriptBlock))
            $datacenterPathItemTwoMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterPathItemTwoScriptBlock))
            $datacenterFolderMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterFolderScriptBlock))
            $datacenterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterWithPathItemTwoAsParentScriptBlock))
            $hostFolderViewBaseObjectMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:hostFolderOfDatacenterViewBaseObjectScriptBlock))
            $hostFolderMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:hostFolderScriptBlock))
            $locationsMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:locationsScriptBlock))
            $locationViewBaseObjectMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:locationViewBaseObjectScriptBlock))
            $locationParentMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:locationParentScriptBlock))

            Mock -CommandName Connect-VIServer -MockWith $vCenterMock -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $rootFolderMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:rootFolder } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $datacenterPathItemOneMock -ParameterFilter { $Server -eq $script:vCenter -and (($Id | ConvertTo-Json) -eq ($script:datacenterPathItemOne | ConvertTo-Json)) } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $datacenterPathItemTwoMock -ParameterFilter { $Server -eq $script:vCenter -and (($Id | ConvertTo-Json) -eq ($script:datacenterPathItemTwo | ConvertTo-Json)) } -ModuleName $script:moduleName
            Mock -CommandName Get-Inventory -MockWith $datacenterFolderMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:datacenterLocation } -ModuleName $script:moduleName
            Mock -CommandName Get-Datacenter -MockWith $datacenterMock -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $hostFolderViewBaseObjectMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:hostFolder } -ModuleName $script:moduleName
            Mock -CommandName Get-Inventory -MockWith $hostFolderMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:hostFolder } -ModuleName $script:moduleName
            Mock -CommandName Get-Inventory -MockWith $locationsMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:constants.DatacenterInventoryPathItemTwo -and $Location -eq $script:hostFolderLocation } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $locationViewBaseObjectMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:constants.DatacenterInventoryPathItemTwoId } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $locationParentMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:locationParent } -ModuleName $script:moduleName

            $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties
        }

        AfterEach {
            $script:resourceProperties.Datacenter = [string]::Empty
            $script:resourceProperties.DatacenterInventoryPath = [string]::Empty
        }

        Context 'Invoking with Ensure Present and non existing Cluster' {
            BeforeAll {
                # Arrange
                Mock -CommandName Get-Inventory -MockWith { return $null } -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
            }

            It 'Should return $false' {
                # Act
                $result = $resource.Test()

                # Assert
                $result | Should -Be $false
            }
        }

        Context 'Invoking with Ensure Present, existing Cluster and matching settings' {
            BeforeAll {
                # Arrange
                $script:resourceProperties.HAEnabled = $true
                $script:resourceProperties.HAAdmissionControlEnabled = $true
                $script:resourceProperties.HAFailoverLevel = 4
                $script:resourceProperties.HAIsolationResponse = 'DoNothing'
                $script:resourceProperties.HARestartPriority = 'High'

                $clusterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:clusterScriptBlock))
                Mock -CommandName Get-Inventory -MockWith $clusterMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName

                $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties
            }

            AfterAll {
                $script:resourceProperties.HAEnabled = $null
                $script:resourceProperties.HAAdmissionControlEnabled = $null
                $script:resourceProperties.HAFailoverLevel = $null
                $script:resourceProperties.HAIsolationResponse = 'Unset'
                $script:resourceProperties.HARestartPriority = 'Unset'
            }

            It 'Should return $true' {
                # Act
                $result = $resource.Test()

                # Assert
                $result | Should -Be $true
            }
        }

        Context 'Invoking with Ensure Present, existing Cluster and non matching settings' {
            BeforeAll {
                # Arrange
                $script:resourceProperties.HAEnabled = $true
                $script:resourceProperties.HAAdmissionControlEnabled = $true
                $script:resourceProperties.HAFailoverLevel = 3
                $script:resourceProperties.HAIsolationResponse = 'DoNothing'
                $script:resourceProperties.HARestartPriority = 'High'

                $clusterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:clusterScriptBlock))
                Mock -CommandName Get-Inventory -MockWith $clusterMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName

                $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties
            }

            AfterAll {
                $script:resourceProperties.HAEnabled = $null
                $script:resourceProperties.HAAdmissionControlEnabled = $null
                $script:resourceProperties.HAFailoverLevel = $null
                $script:resourceProperties.HAIsolationResponse = 'Unset'
                $script:resourceProperties.HARestartPriority = 'Unset'
            }

            It 'Should return $false' {
                # Act
                $result = $resource.Test()

                # Assert
                $result | Should -Be $false
            }
        }

        Context 'Invoking with Ensure Absent and non existing Cluster' {
            BeforeAll {
                # Arrange
                $script:resourceProperties.Ensure = 'Absent'
                $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties

                Mock -CommandName Get-Inventory -MockWith { return $null } -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
            }

            AfterAll {
                $script:resourceProperties.Ensure = 'Present'
            }

            It 'Should return $true' {
                # Act
                $result = $resource.Test()

                # Assert
                $result | Should -Be $true
            }
        }

        Context 'Invoking with Ensure Absent and existing Cluster' {
            BeforeAll {
                # Arrange
                $script:resourceProperties.Ensure = 'Absent'
                $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties

                $clusterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:clusterScriptBlock))
                Mock -CommandName Get-Inventory -MockWith $clusterMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
            }

            AfterAll {
                $script:resourceProperties.Ensure = 'Present'
            }

            It 'Should return $false' {
                # Act
                $result = $resource.Test()

                # Assert
                $result | Should -Be $false
            }
        }
    }

    Describe 'HACluster\Get' -Tag 'Get' {
        BeforeEach {
            # Arrange
            $script:resourceProperties.Datacenter = "$($script:constants.DatacenterPathItemOne)/$($script:constants.DatacenterPathItemTwo)/$($script:constants.DatacenterName)"
            $script:resourceProperties.DatacenterInventoryPath = "$($script:constants.DatacenterInventoryPathItemOne)/$($script:constants.DatacenterInventoryPathItemTwo)"
            $script:resourceProperties.HAEnabled = $true
            $script:resourceProperties.HAAdmissionControlEnabled = $true
            $script:resourceProperties.HAFailoverLevel = 4
            $script:resourceProperties.HAIsolationResponse = 'DoNothing'
            $script:resourceProperties.HARestartPriority = 'High'

            $vCenterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:vCenterWithRootFolderScriptBlock))
            $rootFolderMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:rootFolderViewBaseObjectScriptBlock))
            $datacenterPathItemOneMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterPathItemOneScriptBlock))
            $datacenterPathItemTwoMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterPathItemTwoScriptBlock))
            $datacenterFolderMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterFolderScriptBlock))
            $datacenterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:datacenterWithPathItemTwoAsParentScriptBlock))
            $hostFolderViewBaseObjectMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:hostFolderOfDatacenterViewBaseObjectScriptBlock))
            $hostFolderMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:hostFolderScriptBlock))
            $locationsMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:locationsScriptBlock))
            $locationViewBaseObjectMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:locationViewBaseObjectScriptBlock))
            $locationParentMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:locationParentScriptBlock))

            Mock -CommandName Connect-VIServer -MockWith $vCenterMock -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $rootFolderMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:rootFolder } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $datacenterPathItemOneMock -ParameterFilter { $Server -eq $script:vCenter -and (($Id | ConvertTo-Json) -eq ($script:datacenterPathItemOne | ConvertTo-Json)) } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $datacenterPathItemTwoMock -ParameterFilter { $Server -eq $script:vCenter -and (($Id | ConvertTo-Json) -eq ($script:datacenterPathItemTwo | ConvertTo-Json)) } -ModuleName $script:moduleName
            Mock -CommandName Get-Inventory -MockWith $datacenterFolderMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:datacenterLocation } -ModuleName $script:moduleName
            Mock -CommandName Get-Datacenter -MockWith $datacenterMock -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $hostFolderViewBaseObjectMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:hostFolder } -ModuleName $script:moduleName
            Mock -CommandName Get-Inventory -MockWith $hostFolderMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:hostFolder } -ModuleName $script:moduleName
            Mock -CommandName Get-Inventory -MockWith $locationsMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:constants.DatacenterInventoryPathItemTwo -and $Location -eq $script:hostFolderLocation } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $locationViewBaseObjectMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:constants.DatacenterInventoryPathItemTwoId } -ModuleName $script:moduleName
            Mock -CommandName Get-View -MockWith $locationParentMock -ParameterFilter { $Server -eq $script:vCenter -and $Id -eq $script:locationParent } -ModuleName $script:moduleName

            $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties
        }

        AfterEach {
            $script:resourceProperties.Datacenter = [string]::Empty
            $script:resourceProperties.DatacenterInventoryPath = [string]::Empty
            $script:resourceProperties.HAEnabled = $null
            $script:resourceProperties.HAAdmissionControlEnabled = $null
            $script:resourceProperties.HAFailoverLevel = $null
            $script:resourceProperties.HAIsolationResponse = 'Unset'
            $script:resourceProperties.HARestartPriority = 'Unset'
        }

        Context 'Invoking with Ensure Present and non existing Cluster' {
            BeforeAll {
                # Arrange
                Mock -CommandName Get-Inventory -MockWith { return $null } -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
            }

            It 'Should retrieve the correct settings from the server' {
                # Act
                $result = $resource.Get()

                # Assert
                $result.Server | Should -Be $script:resourceProperties.Server
                $result.DatacenterInventoryPath | Should -Be $script:resourceProperties.DatacenterInventoryPath
                $result.Datacenter | Should -Be $script:resourceProperties.Datacenter
                $result.Name | Should -Be $script:resourceProperties.Name
                $result.Ensure | Should -Be 'Absent'
                $result.HAEnabled | Should -Be $script:resourceProperties.HAEnabled
                $result.HAAdmissionControlEnabled | Should -Be $script:resourceProperties.HAAdmissionControlEnabled
                $result.HAFailoverLevel | Should -Be $script:resourceProperties.HAFailoverLevel
                $result.HAIsolationResponse | Should -Be $script:resourceProperties.HAIsolationResponse
                $result.HARestartPriority | Should -Be $script:resourceProperties.HARestartPriority
            }
        }

        Context 'Invoking with Ensure Present and existing Cluster' {
            BeforeAll {
                # Arrange
                $clusterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:clusterScriptBlock))

                Mock -CommandName Get-Inventory -MockWith $clusterMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
            }

            It 'Should retrieve the correct settings from the server' {
                # Act
                $result = $resource.Get()

                # Assert
                $result.Server | Should -Be $script:resourceProperties.Server
                $result.DatacenterInventoryPath | Should -Be $script:resourceProperties.DatacenterInventoryPath
                $result.Datacenter | Should -Be $script:resourceProperties.Datacenter
                $result.Name | Should -Be $script:cluster.Name
                $result.Ensure | Should -Be 'Present'
                $result.HAEnabled | Should -Be $script:cluster.HAEnabled
                $result.HAAdmissionControlEnabled | Should -Be $script:cluster.HAAdmissionControlEnabled
                $result.HAFailoverLevel | Should -Be $script:cluster.HAFailoverLevel
                $result.HAIsolationResponse.ToString() | Should -Be $script:cluster.HAIsolationResponse.ToString()
                $result.HARestartPriority | Should -Be $script:cluster.HARestartPriority
            }
        }

        Context 'Invoking with Ensure Absent and non existing Cluster' {
            BeforeAll {
                # Arrange
                $script:resourceProperties.Ensure = 'Absent'
                $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties

                Mock -CommandName Get-Inventory -MockWith { return $null } -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
            }

            AfterAll {
                $script:resourceProperties.Ensure = 'Present'
            }

            It 'Should retrieve the correct settings from the server' {
                # Act
                $result = $resource.Get()

                # Assert
                $result.Server | Should -Be $script:resourceProperties.Server
                $result.DatacenterInventoryPath | Should -Be $script:resourceProperties.DatacenterInventoryPath
                $result.Datacenter | Should -Be $script:resourceProperties.Datacenter
                $result.Name | Should -Be $script:resourceProperties.Name
                $result.Ensure | Should -Be 'Absent'
                $result.HAEnabled | Should -Be $script:resourceProperties.HAEnabled
                $result.HAAdmissionControlEnabled | Should -Be $script:resourceProperties.HAAdmissionControlEnabled
                $result.HAFailoverLevel | Should -Be $script:resourceProperties.HAFailoverLevel
                $result.HAIsolationResponse | Should -Be $script:resourceProperties.HAIsolationResponse
                $result.HARestartPriority | Should -Be $script:resourceProperties.HARestartPriority
            }
        }

        Context 'Invoking with Ensure Absent and existing Cluster' {
            BeforeAll {
                # Arrange
                $script:resourceProperties.Ensure = 'Absent'
                $resource = New-Object -TypeName $script:resourceName -Property $script:resourceProperties

                $clusterMock = [ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($script:clusterScriptBlock))
                Mock -CommandName Get-Inventory -MockWith $clusterMock -ParameterFilter { $Server -eq $script:vCenter -and $Name -eq $script:resourceProperties.Name } -ModuleName $script:moduleName
            }

            AfterAll {
                $script:resourceProperties.Ensure = 'Present'
            }

            It 'Should retrieve the correct settings from the server' {
                # Act
                $result = $resource.Get()

                # Assert
                $result.Server | Should -Be $script:resourceProperties.Server
                $result.DatacenterInventoryPath | Should -Be $script:resourceProperties.DatacenterInventoryPath
                $result.Datacenter | Should -Be $script:resourceProperties.Datacenter
                $result.Name | Should -Be $script:cluster.Name
                $result.Ensure | Should -Be 'Present'
                $result.HAEnabled | Should -Be $script:cluster.HAEnabled
                $result.HAAdmissionControlEnabled | Should -Be $script:cluster.HAAdmissionControlEnabled
                $result.HAFailoverLevel | Should -Be $script:cluster.HAFailoverLevel
                $result.HAIsolationResponse.ToString() | Should -Be $script:cluster.HAIsolationResponse.ToString()
                $result.HARestartPriority | Should -Be $script:cluster.HARestartPriority
            }
        }
    }
}
finally {
    # Calls the function to Remove the mocked VMware.VimAutomation.Core module after all tests.
    Invoke-TestCleanup
}
