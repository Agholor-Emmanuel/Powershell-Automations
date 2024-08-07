#Configure data source and destination connection details
$Assembly = [System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient")
$OracleConnectionString = "Data Source=***.**.**.***:****/*****; User=****; Pwd=****"
$Flatfile1 = "\\foldermain\foldersub\flatfile1.txt" 
$Flatfile2 = "\\foldermain\foldersub\flatfile2.txt"  
$OracleConnection = New-Object System.Data.OracleClient.OracleConnection($OracleConnectionString);

try {
    $OracleConnection.Open()
} catch {
    Write-Host "Error opening Oracle connection: $_"
    exit
}

$Query1 = "Select * from table A"    

$Query2 = "Select * from table B"

#create Query command object
$QueryCommand1 = New-Object System.Data.OracleClient.OracleCommand;
$QueryCommand1.Connection = $OracleConnection
$QueryCommand1.CommandText = $Query1
$QueryCommand1.CommandType = [System.Data.CommandType]::Text

$QueryCommand2 = New-Object System.Data.OracleClient.OracleCommand;
$QueryCommand2.Connection = $OracleConnection
$QueryCommand2.CommandText = $Query2
$QueryCommand2.CommandType = [System.Data.CommandType]::Text

#create table and load results into table
$DataTable1 = New-Object System.Data.DataTable
$DataTable2 = New-Object System.Data.DataTable
Write-Host "Query 1 start time:  " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$DataTable1.Load($QueryCommand1.ExecuteReader())
Write-Host "Query 1 End time:  " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$DataTable2.Load($QueryCommand2.ExecuteReader())
Write-Host "Query 2 End time:  " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")


# Close the Oracle connection
try {
    $OracleConnection.Close()
} catch {
    Write-Host "Error closing Oracle connection: $_"
}


# Export DataTable to flat file
Write-Host "Query1 result  Export Start time:  " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$DataTable1 | Export-Csv -Path $Flatfile1 -NoTypeInformation
Write-Host "Query1 results exported to $Flatfile1 at " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

$DataTable2 | Export-Csv -Path $Flatfile2 -NoTypeInformation
Write-Host "Query2 results exported to $Flatfile2 at " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")








