/*This example would work in an environment where internal DNS is set up so that it can only resolve internal host names, and the goal is to use a proxy only for hosts which aren't resolvable:*/

function FindProxyForURL(url, host)
{
    if (isResolvable(host))
        return "DIRECT";
    else
        return "PROXY proxy.mydomain.com:8080";
}

/*Again, use of DNS in the above can be minimized by adding redundant rules in the beginning:*/

function FindProxyForURL(url, host)
{
    if (isPlainHostName(host) ||
            dnsDomainIs(host, ".mydomain.com") ||
            isInNet(host, "198.95.0.0", "255.255.0.0"))
        return "DIRECT";
    else
        return "PROXY proxy.mydomain.com:8080";
}
