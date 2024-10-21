$adapters = Get-NetAdapter

foreach ($adapter in $adapters ){

Get-NetIPInterface -InterfaceAlias $adapter.Name -AddressFamily IPV4|Set-NetIPInterface -NlMtuBytes 1500
}