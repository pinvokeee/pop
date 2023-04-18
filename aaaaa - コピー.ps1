$url = "ws://localhost:9222/devtools/page/4178A4BCD8DB56F8CBAC7F35E6287091"

Class CDPConnecter {

    [string]$debuggerUrl
    [Net.WebSockets.ClientWebSocket]$websocket
    [Threading.CancellationToken]$cancelToken

    [int]$id

    CDPConnecter($wsDebuggerUrl) {

        $This.debuggerUrl = $wsDebuggerUrl
        $This.websocket = New-Object Net.WebSockets.ClientWebSocket
        $This.cancelToken = [Threading.CancellationToken]::None
    }

    Connect() {

        Write-Host "CONNECTING..."

        $connection = $This.websocket.ConnectAsync($This.debuggerUrl, $This.cancelToken) 
        do { Sleep(1) } until ($connection.IsCompleted)

        Write-Host "CONNECT...SUCCESS"
    }

    [void]EnableConsoleEvents() {

        $message = @{
            "id" = ++$This.id
            "method" = "Console.enable"
            "params" = @{}
        } | ConvertTo-Json

        $This.Send($message)
    }

    [string]EvalScript($script) {

        $message = @{
            "id" = ++$This.id
            "method" = "Runtime.evaluate"
            "params" = @{"expression" = $script}
        } 

        [ArraySegment[byte]]$buffer = [Text.Encoding]::UTF8.GetBytes(($message | ConvertTo-Json))
        $task = $This.websocket.SendAsync($buffer, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $This.cancelToken)
        do { Sleep(1) } until ($task.IsCompleted)

        return ""
    }

    [void]Send($message) {

        [ArraySegment[byte]]$buffer = [Text.Encoding]::UTF8.GetBytes($message)
        $task = $This.websocket.SendAsync($buffer, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $This.cancelToken)
        do { Sleep(1) } until ($task.IsCompleted)

    }

    [void]ReciveStart() {

        $buffer = @()
        [Threading.Tasks.Task[Net.WebSockets.WebSocketReceiveResult]]$task = $null

        while ($This.websocket.State -eq [Net.WebSockets.WebSocketState]::Open) {
            
            while (($task -eq $null) -or (-not $task.Result.EndOfMessage)) {

                $temp = [Net.WebSockets.WebSocket]::CreateClientBuffer(1024, 1024)
                $task = $This.websocket.ReceiveAsync($temp, $This.cancelToken)
                
                do { Sleep(1) } until ($task.IsCompleted)
                Write-Host "RECIVE..."($task.Result.Count - 1)"bytes..."
                $a = @($temp)[0..($task.Result.Count - 1)]
                $buffer += $a
            }
    
            Write-Host "COMPLETE..."($buffer.length - 1)"bytes..."
            $message = ([Text.Encoding]::UTF8.GetString($buffer, 0, $buffer.length))

            $task = $null
            $buffer = @()

            $obj = $message | ConvertFrom-Json
            
 
            if (($obj.method -eq "Console.messageAdded") -or ($obj.params.message.level -eq "debug")) {    

                if ($This.TestJson($obj.params.message.text)) {

                    $action = $obj.params.message.text | ConvertFrom-Json

                    Write-Host $action.method
    
                    if ($action.method -eq "GET") {
    
                        $webr = Invoke-WebRequest $action.url

                        $result = @{ 
                            result = $webr
                        }

                        $callback = $action.callback
                        $exec = $callback + "(" + ($result ) + ");"
                        Write-Host $exec
                        $This.EvalScript($exec)
    
                    }
                }
            }
        }
    }

    [Boolean]TestJson($str) {
        try {            
            $c = $str | ConvertFrom-Json
            return $true
        }
        catch {

            return $false
        }
    }
}

[CDPConnecter]$c = New-Object CDPConnecter($url)
$c.Connect()
$c.EnableConsoleEvents()
$c.ReciveStart()