# Shift Left Demo – Microsoft Defender for Cloud

This demo shows how Microsoft Defender for Cloud helps prevent misconfigurations before deployment – applying the **Shift Left** security approach.

## Scenario
A developer writes an IaC (Bicep) template that creates a VM with a hardcoded password.

```bicep
resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'demo-vm'
  location: resourceGroup().location
  properties: {
    osProfile: {
      adminUsername: 'azureuser'
      adminPassword: 'P@ssword123!'
    }
  }
}
