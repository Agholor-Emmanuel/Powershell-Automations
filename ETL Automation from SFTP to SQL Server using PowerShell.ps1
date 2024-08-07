#Configuring SFTP Credentials
Add-Type -Path "E:\WinSCP-6.1.1-Automation\WinSCPnet.dll"
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = "**.**.**.**"
    PortNumber = ** 
    UserName = "*****"
    Password = "*****"
    SshHostKeyFingerprint = "*****************************"
}

#Configuring SQL Server Credential
$serverName = "***.**.*.**"
$databaseName = "stage"
$username = "****"
$password = "******"
$TableName = "Table A"
$TruncateTableQuery = "Truncate table A;" 
$connectionString = "Server=$serverName;Database=$databaseName;User Id=$username;Password=$password;"


# Configuring Variables
$yesterdayDate = (Get-Date).AddDays(-1).ToString("dd.MM.yyyy")
$todayDate = (Get-Date).ToString("dd.MM.yyyy")
$remoteCsvFile1 = "Sample_File_" #+ $todayDate
$remoteCsvFile2 = "New_File_" #+ $todayDate
$remoteCsvFile3 = "Old_File_" #+ $yesterdayDate
$remoteCsvFile4 = "Test_File_" #+ $yesterdayDate
$remoteCsvFileFolder_1_2 = "/sftp/reports/new/"
$remoteCsvFileFolder_3_4 = "/sftp/reports/old/"
$localFolder =  "K:\files" 

$filesToProcess = @(
    @{ RemoteFilePattern = $remoteCsvFile1; RemoteFolder = $remoteCsvFileFolder_1_2 },
    @{ RemoteFilePattern = $remoteCsvFile2; RemoteFolder = $remoteCsvFileFolder_1_2 },
    @{ RemoteFilePattern = $remoteCsvFile3; RemoteFolder = $remoteCsvFileFolder_3_4 },
    @{ RemoteFilePattern = $remoteCsvFile4; RemoteFolder = $remoteCsvFileFolder_3_4 }
)

function Download-FileFromSftp($sessionOptions, $remoteFilePath, $localFilePath) {
    try {
        $session = New-Object WinSCP.Session
        $session.Open($sessionOptions)
        $session.Timeout = New-TimeSpan -Seconds 300
        $session.GetFiles($remoteFilePath, $localFilePath).Check()
        $session.Dispose()
        Write-Host "File downloaded to: $localFilePath"
    } catch {
        Write-Host "Error downloading file: $_"
    }
}

function Execute-Query($connectionString, $query) {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $command.ExecuteNonQuery()
    $connection.Close()
}

function BulkInsert-CsvToSql($dataTable, $connectionString, $tableName) {
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()

        $bulkCopy = New-Object Data.SqlClient.SqlBulkCopy($connection)
        $bulkCopy.DestinationTableName = $tableName
        $bulkCopy.WriteToServer($dataTable)

        $connection.Close()
        Write-Host "Data inserted into SQL Server table in bulk."
    } catch {
        Write-Host "Error: $_"
    }
}

function Get-RemoteFileList($sessionOptions, $remoteFolder) {
    $session = New-Object WinSCP.Session
    $session.Open($sessionOptions)
    $session.Timeout = New-TimeSpan -Seconds 300
    $directory = $session.ListDirectory($remoteFolder)
    $session.Dispose()
    return $directory.Files
}

function Process-File($remoteCsvFilePattern, $remoteCsvFileFolder, $localFolder, $sessionOptions, $dataTable) {
    $remoteFiles = Get-RemoteFileList -sessionOptions $sessionOptions -remoteFolder $remoteCsvFileFolder | Where-Object { $_.Name -like "*$remoteCsvFilePattern*" }
    
    foreach ($remoteFile in $remoteFiles) {
        $remoteFilePath = $remoteCsvFileFolder + $remoteFile.Name
        $localFilePath = Join-Path -Path $localFolder -ChildPath $remoteFile.Name
        Download-FileFromSftp -sessionOptions $sessionOptions -remoteFilePath $remoteFilePath -localFilePath $localFilePath
        
        $csvData = Import-Csv -Path $localFilePath
        
        foreach ($csvRow in $csvData) {
            $dataRow = $dataTable.NewRow()
            foreach ($column in $csvData[0].PSObject.Properties.Name) {
                $dataRow[$column] = $csvRow.$column
            }
            $dataTable.Rows.Add($dataRow)
        }
    }
}

# Prepare the DataTable to hold all data
$dataTable = New-Object System.Data.DataTable
$firstRemoteFile = Get-RemoteFileList -sessionOptions $sessionOptions -remoteFolder $filesToProcess[0].RemoteFolder | Where-Object { $_.Name -like "*$($filesToProcess[0].RemoteFilePattern)*" } | Select-Object -First 1
$firstLocalFilePath = Join-Path -Path $localFolder -ChildPath $firstRemoteFile.Name
Download-FileFromSftp -sessionOptions $sessionOptions -remoteFilePath ($filesToProcess[0].RemoteFolder + $firstRemoteFile.Name) -localFilePath $firstLocalFilePath
$firstCsvData = Import-Csv -Path $firstLocalFilePath

foreach ($column in $firstCsvData[0].PSObject.Properties.Name) {
    $dataColumn = New-Object System.Data.DataColumn
    $dataColumn.ColumnName = $column
    $dataColumn.DataType = [System.String]
    $dataTable.Columns.Add($dataColumn)
}

foreach ($file in $filesToProcess) {
    Process-File -remoteCsvFilePattern $file.RemoteFilePattern -remoteCsvFileFolder $file.RemoteFolder -localFolder $localFolder -sessionOptions $sessionOptions -dataTable $dataTable
}

Execute-Query -connectionString $connectionString -query $TruncateTableQuery
BulkInsert-CsvToSql -dataTable $dataTable -connectionString $connectionString -tableName $TableName

Write-Host "All files processed and data loaded into table A."
