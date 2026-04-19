using UiPath.CodedWorkflows;
using System;

namespace JobPosting_Final
{
    public class ConnectionsManager
    {
        public GoogleDocsFactory GoogleDocs { get; set; }
        public DriveFactory Drive { get; set; }
        public GoogleFormsFactory GoogleForms { get; set; }
        public GmailFactory Gmail { get; set; }
        public GoogleSheetsFactory GoogleSheets { get; set; }
        public GoogleTasksFactory GoogleTasks { get; set; }
        public GoogleWorkspaceFactory GoogleWorkspace { get; set; }

        public ConnectionsManager(ICodedWorkflowsServiceContainer resolver)
        {
            GoogleDocs = new GoogleDocsFactory(resolver);
            Drive = new DriveFactory(resolver);
            GoogleForms = new GoogleFormsFactory(resolver);
            Gmail = new GmailFactory(resolver);
            GoogleSheets = new GoogleSheetsFactory(resolver);
            GoogleTasks = new GoogleTasksFactory(resolver);
            GoogleWorkspace = new GoogleWorkspaceFactory(resolver);
        }
    }
}