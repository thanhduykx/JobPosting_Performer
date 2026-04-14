Imports System
Imports System.Data
Imports System.IO
Imports System.Text
Imports System.Net

Module Program
    Sub Main()
        Dim in_JobIds As String = "1"
        Dim in_TemplateName As String = "WeeklyTemplate.html"
        Dim in_dt_Jobs As New DataTable()
        in_dt_Jobs.Columns.Add("JobID")
        in_dt_Jobs.Columns.Add("Role")
        in_dt_Jobs.Rows.Add("1", "Developer")
        
        Dim str_CandidateEmail As String = "test@example.com"
        
        Dim requestedIds As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase)
        If Not String.IsNullOrWhiteSpace(in_JobIds) Then
            For Each idPart In in_JobIds.Split({","c, ";"c, "|"c}, StringSplitOptions.RemoveEmptyEntries)
                Dim cleaned = idPart.Trim()
                If Not String.IsNullOrWhiteSpace(cleaned) Then requestedIds.Add(cleaned)
            Next
        End If

        Dim hasFilter As Boolean = requestedIds.Count > 0
        Dim selectedIds As New List(Of String)()
        Dim rowsBuilder As New System.Text.StringBuilder()

        Dim firstRole As String = String.Empty
        Dim firstLevel As String = String.Empty
        Dim firstLocation As String = String.Empty
        Dim firstSetup As String = String.Empty
        Dim firstSchedule As String = String.Empty

        For Each row As DataRow In in_dt_Jobs.Rows
            Dim jobId As String = If(row.Table.Columns.Contains("JobID"), row("JobID").ToString().Trim(), If(row.Table.Columns.Contains("Role"), row("Role").ToString().Trim(), String.Empty))
            If String.IsNullOrWhiteSpace(jobId) AndAlso row.Table.Columns.Contains("Role") Then jobId = row("Role").ToString().Trim()
            If hasFilter AndAlso Not requestedIds.Contains(jobId) Then Continue For

            Dim roleVal As String = If(row.Table.Columns.Contains("Title"), row("Title").ToString().Trim(), If(row.Table.Columns.Contains("Role"), row("Role").ToString().Trim(), String.Empty))
            Dim levelVal As String = If(row.Table.Columns.Contains("CareerLevel"), row("CareerLevel").ToString().Trim(), If(row.Table.Columns.Contains("Career Level "), row("Career Level ").ToString().Trim(), String.Empty))
            Dim locationVal As String = If(row.Table.Columns.Contains("WorkLocation"), row("WorkLocation").ToString().Trim(), If(row.Table.Columns.Contains("Work Location "), row("Work Location ").ToString().Trim(), String.Empty))
            Dim setupVal As String = If(row.Table.Columns.Contains("WorkSetup"), row("WorkSetup").ToString().Trim(), If(row.Table.Columns.Contains("Work Set-up"), row("Work Set-up").ToString().Trim(), String.Empty))
            Dim scheduleVal As String = If(row.Table.Columns.Contains("WorkSchedule"), row("WorkSchedule").ToString().Trim(), If(row.Table.Columns.Contains("Work Schedule"), row("Work Schedule").ToString().Trim(), String.Empty))

            If selectedIds.Count = 0 Then
                firstRole = roleVal
                firstLevel = levelVal
                firstLocation = locationVal
                firstSetup = setupVal
                firstSchedule = scheduleVal
            End If

            selectedIds.Add(jobId)
            rowsBuilder.AppendLine("<tr>")
            rowsBuilder.AppendLine("<td><strong>" & System.Net.WebUtility.HtmlEncode(roleVal) & "</strong></td>")
            rowsBuilder.AppendLine("<td>" & System.Net.WebUtility.HtmlEncode(levelVal) & "</td>")
            rowsBuilder.AppendLine("<td>" & System.Net.WebUtility.HtmlEncode(locationVal) & "</td>")
            rowsBuilder.AppendLine("<td>" & System.Net.WebUtility.HtmlEncode(setupVal) & "</td>")
            rowsBuilder.AppendLine("<td>" & System.Net.WebUtility.HtmlEncode(scheduleVal) & "</td>")
            rowsBuilder.AppendLine("</tr>")
        Next

        Dim chosenTemplate As String = If(String.IsNullOrWhiteSpace(in_TemplateName), "WeeklyTemplate.html", in_TemplateName.Trim())
        Dim templatePath As String = Path.Combine("Templates", chosenTemplate)
        Dim html As String
        If File.Exists(templatePath) Then
            html = File.ReadAllText(templatePath)
        Else
            html = File.ReadAllText(Path.Combine("Templates", "WeeklyTemplate.html"))
        End If

        Dim recipientName As String = If(str_CandidateEmail.Contains("@"), str_CandidateEmail.Split("@"c)(0), str_CandidateEmail)
        html = html.Replace("{{Name}}", System.Net.WebUtility.HtmlEncode(recipientName))
        html = html.Replace("{{Email}}", System.Net.WebUtility.HtmlEncode(str_CandidateEmail))
        html = html.Replace("{{Role}}", System.Net.WebUtility.HtmlEncode(firstRole))
        html = html.Replace("{{CareerLevel}}", System.Net.WebUtility.HtmlEncode(firstLevel))
        html = html.Replace("{{WorkLocation}}", System.Net.WebUtility.HtmlEncode(firstLocation))
        html = html.Replace("{{WorkSetup}}", System.Net.WebUtility.HtmlEncode(firstSetup))
        html = html.Replace("{{WorkSchedule}}", System.Net.WebUtility.HtmlEncode(firstSchedule))

        Dim tbodyStart As Integer = html.IndexOf("<tbody>", StringComparison.OrdinalIgnoreCase)
        Dim tbodyEnd As Integer = html.IndexOf("</tbody>", StringComparison.OrdinalIgnoreCase)
        If tbodyStart >= 0 AndAlso tbodyEnd > tbodyStart Then
            Dim beforePart As String = html.Substring(0, tbodyStart + 7)
            Dim afterPart As String = html.Substring(tbodyEnd)
            html = beforePart & vbCrLf & rowsBuilder.ToString() & vbCrLf & afterPart
        End If
        
        File.WriteAllText("test_output.html", html)
        Console.WriteLine("Done. Output size: " & html.Length)
    End Sub
End Module
