function Invoke-HttpServer {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [int]
        $Port = 8080
    )

    $server = [System.Net.HttpListener]::new();
    $server.Prefixes.Add("http://localhost:${Port}/");

    return $server;
}

function Start-HttpServer {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [int]
        $Port = 8080
    )
    
    $server = (Invoke-HttpServer -Port $Port);
    $server.Start();
    Write-Debug "Http server started !";

    return $server;
}

$http = Start-HttpServer;
$context = $null;

function Add-Route {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path,
        [Parameter(Mandatory = $true)]
        [string]
        $Method,
        [Parameter(Mandatory = $true)]
        [scriptblock]
        $Callback
    )
 
    if ($context.Request.HttpMethod -eq $Method -and $context.Request.RawUrl -eq $Path) {
        $Callback.Invoke($context);
    }
}

$Get_RouteRoot = {
    param (
        [Parameter(Mandatory = $true)]
        [pscustomobject]
        $Context
    )
    
    Write-Host "$($Context.Request.UserHostAddress)  =>  $($Context.Request.Url)" -f 'mag'

    [string]$html = "<h1>A Powershell Webserver</h1><p>home page</p>" 
    
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert htmtl to bytes
    $Context.Response.ContentLength64 = $buffer.Length
    $Context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
    $Context.Response.OutputStream.Close() # close the response
};

$POST_SomePostRoute = {
    param (
        [Parameter(Mandatory = $true)]
        [pscustomobject]
        $Context
    )
    
    $FormContent = [System.IO.StreamReader]::new($Context.Request.InputStream).ReadToEnd()

    # We can log the request to the terminal
    Write-Host "$($Context.Request.UserHostAddress)  =>  $($Context.Request.Url)" -f 'mag'
    Write-Host $FormContent -f 'Green'

    # the html/data
    [string]$html = "<h1>A Powershell Webserver</h1><p>Post Successful!</p>" 

    #resposed to the request
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    $Context.Response.ContentLength64 = $buffer.Length
    $Context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Context.Response.OutputStream.Close()
};

while ($http.IsListening) {
    $context = $http.GetContext()

    Add-Route -Path "/" -Method "GET" -Callback $Get_RouteRoot
    Add-Route -Path "/some/post" -Method "POST" -Callback $POST_SomePostRoute
}