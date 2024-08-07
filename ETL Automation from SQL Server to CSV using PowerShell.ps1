#Configuring variables
$serverName = "***.**.*.**"
$databaseName = "stage"
$username = "****"
$password = "****"
$query1 = "select * from table A"  
$query2 = "select * from table B"  
$outputCsvPath1 = "\\foldermain\foldersub\flatfile1.csv" 
$outputCsvPath2 = "\\foldermain\foldersub\flatfile2.txt" 

#Creating function to run query and export to csv
function Execute-QueryAndExportToCsv ($query, $outputCsvPath) {
    try {
        $connectionString = "Server=$serverName;Database=$databaseName;User Id=$username;Password=$password;"
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString

        $command = $connection.CreateCommand()
        $command.CommandText = $query

        $dataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $dataAdapter.SelectCommand = $command

        $dataSet = New-Object System.Data.DataSet

        $connection.Open()
        $dataAdapter.Fill($dataSet) | Out-Null
        $connection.Close()

        if ($dataSet.Tables.Count -gt 0) {
            $dataSet.Tables[0] | Export-Csv -Path $outputCsvPath -NoTypeInformation
            Write-Host "Query results exported to $outputCsvPath"
        } else {
            Write-Host "No data returned by the query."
        }
    } catch {
        Write-Host "Error: $_"
    }
}

Execute-QueryAndExportToCsv -query $query1 -outputCsvPath $outputCsvPath1
Execute-QueryAndExportToCsv -query $query2 -outputCsvPath $outputCsvPath2


