$url = "ws://localhost:9222/devtools/page/B33F45D2908D4C929122B2F89FDF4097"

# $ws = New-Object Net.WebSockets.ClientWebSocket
# $ct = [Threading.CancellationToken]::None


# $message = @{
#     "id" = 1
#     "method" = "Runtime.evaluate"
#     "params" = @{"expression" = 'console.log("test")'}
# } | ConvertTo-Json

# $message = @{
#     "id" = 1
#     "method" = "Console.enable"
#     "params" = @{}
# } | ConvertTo-Json


# $connection = $ws.ConnectAsync($url, $ct) 

# do { Sleep(1) }
# until ($connection.IsCompleted)
# Write-Output "Connected!"

# [ArraySegment[byte]]$buffer = [Text.Encoding]::UTF8.GetBytes($message)
# $aa = $ws.SendAsync($buffer, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $ct)

# do { Sleep(1) }
# until ($aa.IsCompleted)
# Write-Output "Send!"
# $aa
# # while ($ws.State -eq [Net.WebSockets.WebSocketState]::Open) {
    
#     Write-Output "Rec!"
#     $buffer = [Net.WebSockets.WebSocket]::CreateClientBuffer(1024,1024)
#     $aa = $ws.ReceiveAsync($buffer, $ct)
#     $aa

#     [Text.Encoding]::UTF8.GetString($buffer)
# # }

# #

# Write-Output "RecEnd"

#$connection.Close



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

        $connection = $This.websocket.ConnectAsync($This.debuggerUrl, $This.cancelToken) 
        do { Sleep(1) } until ($connection.IsCompleted)

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

        return $This.Recive()
    }

    [void]EnabledConsole() {

        $message = @{
            "id" = ++$This.id
            "method" = "Console.enable"
            "params" = @{}
        } | ConvertTo-Json

        $This.Send($message)
    }

    [void]Send($message) {

        [ArraySegment[byte]]$buffer = [Text.Encoding]::UTF8.GetBytes($message)
        $task = $This.websocket.SendAsync($buffer, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $This.cancelToken)
        do { Sleep(1) } until ($task.IsCompleted)

    }

    [PSCustomObject]Recive() {

        $buffer = [Net.WebSockets.WebSocket]::CreateClientBuffer(1024,1024)
        $task = $This.websocket.ReceiveAsync($buffer, $This.cancelToken)
        do { Sleep(1) } until ($task.IsCompleted)

        Write-Host ([Text.Encoding]::UTF8.GetString($buffer, 0, $task.Result.Count))

        return @{
            a = ([Text.Encoding]::UTF8.GetString($buffer, 0, $task.Result.Count) | ConvertFrom-Json)
            
        }



        # return (([Text.Encoding]::UTF8.GetString($buffer, 0, $task.Result.Count) | ConvertFrom-Json).result.result.value)
    }
}

[CDPConnecter]$c = New-Object CDPConnecter($url)
$c.Connect()
"Test1"
# $c.EnabledConsole()
# $c.EvalScript("console.log('TEST');")
# $c.EvalScript("
#     Array.from(
#             document.querySelectorAll('.productCard'))
#             .filter(e => e.innerText.indexOf('パンフレット') > -1)[0].innerText")
# $c.EvalScript("Array.from(document.querySelectorAll('.productCard')).filter(e => e.innerText.indexOf('トレーディングアクリルキーホルダー') > -1)[0].innerText")
# $c.EvalScript("Array.from(document.querySelectorAll('.productCard')).filter(e => e.innerText.indexOf('アクリルスタンド【全13種】') > -1)[0].innerText")
# $messageA = @{
#     "id" = 1
#     "method" = "Input.dispatchKeyEvent"
#     "params" = @{
#         type = "keyDown"
#         modifiers = 0
#         code = "F"
#     }
# } | ConvertTo-Json



$messageB = @{
    "id" = 1
    "method" = "Input.dispatchKeyEvent"
    "params" = @{
        type = "rawKeyDown"
        modifiers = 2
        "key" = "F"
        "code" = "F"
        "nativeVirtualKeyCode" = 0x46
        "windowsVirtualKeyCode" = 0x46
      
    }
} | ConvertTo-Json
# $c.Send($messageA)
$c.Send($messageB)


"Test2"
# Read-Host