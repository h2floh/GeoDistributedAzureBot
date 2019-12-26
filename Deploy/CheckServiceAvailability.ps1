###
#
# Check for availability of DNS
# returns $False if service is already
#
###
# Parameters
param(
    [Parameter(HelpMessage="Service Name")]
    [string] $Service,

    # Only needed in Issuing Mode
    [Parameter(HelpMessage="Full Qualified Domain Name to check")]
    [string] $FQDN
)

Resolve-DnsName -Name $FQDN -DnsOnly > $null 2> $1
if ($?)
{
    Write-Host "### ERROR, $Service with name '$FQDN' already exists. Please try another Bot Name."
    return $False
} else {
    return $True
}