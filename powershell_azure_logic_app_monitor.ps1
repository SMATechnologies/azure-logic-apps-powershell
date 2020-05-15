#powershell "C:\a\powershell_azure_logic_app_monitor.ps1" -url "'https://prod-29.centralus.logic.azure.com:443/workflows/abcdefg123/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=abc123'" -maxruntime 20 

Param(
  [string]$url,
  [decimal]$maxruntime
)
$JSONBody = ''
echo "---"
echo "1. START THE WORKFLOW."
$execRecord = Invoke-WebRequest -Method POST -Uri $url -Headers @{"Accept" = "application/json"} -ContentType "application/json" -Body $JSONBody -UseBasicParsing

$rawcontent = $execRecord.RawContent
echo "---"
echo "2. CAPTURE RAW CONTENT RESPONSE WHEN WORKFLOW IS STARTED." + $rawcontent

$rawarray = $rawcontent.split("`r`n")
echo "---"
echo "3. PARSE RESPONSE AND EXTRACT THE POLLING URL."
foreach ($element in $rawarray) 
{
	if ($element.Length -gt 13)
	{
		if ($element.Substring(0,14) -eq 'Location: http')
		{
			echo "line:"$element
			$MonitorURL = $element
			$MonitorURL = $MonitorURL -replace 'Location: ',''
		}
	}
}
if ($MonitorURL.Length -lt 1)
{
	echo "NO POLLING URL FOUND."
	exit 44;
}

echo "---"
echo "4. MONITOR WORKFLOW STATUS VIA POLLING URL."
echo $MonitorURL

$timeout = new-timespan -Minutes $maxruntime
$sw = [diagnostics.stopwatch]::StartNew()
while ($sw.elapsed -lt $timeout){
	$execRecord = Invoke-Restmethod -Method GET -Uri $MonitorURL -Headers @{"Accept" = "application/json"} -ContentType "application/json"
	echo "POLLING RESULT: " + $execRecord
	if($execRecord -eq 'success')
	{
		exit 0;
	}
	if($execRecord -eq 'failure')
	{
		exit 22;
	}
	start-sleep -seconds 10
}
echo "MAX RUNTIME EXCEEDED."
exit 33

