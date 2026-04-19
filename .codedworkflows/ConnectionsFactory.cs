using UiPath.CodedWorkflows;
using System;

namespace JobPosting_Final
{
    public class GoogleDocsFactory
    {
        public GoogleDocsFactory(ICodedWorkflowsServiceContainer resolver)
        {
        }
    }

    public class DriveFactory
    {
        public UiPath.GSuite.Activities.Api.DriveConnection Shared_duongduy12314_gmail_com { get; set; }
        public UiPath.GSuite.Activities.Api.DriveConnection Shared_duongduy12314_gmail_com__2 { get; set; }

        public DriveFactory(ICodedWorkflowsServiceContainer resolver)
        {
            Shared_duongduy12314_gmail_com = new UiPath.GSuite.Activities.Api.DriveConnection("cc203844-2624-448b-8fdf-c30a5c27d14a", resolver);
            Shared_duongduy12314_gmail_com__2 = new UiPath.GSuite.Activities.Api.DriveConnection("b83a2c9b-c136-4bab-9cec-889fdefcab85", resolver);
        }
    }

    public class GoogleFormsFactory
    {
        public GoogleFormsFactory(ICodedWorkflowsServiceContainer resolver)
        {
        }
    }

    public class GmailFactory
    {
        public UiPath.GSuite.Activities.Api.GmailConnection Shared_gmail_20260413093817752 { get; set; }
        public UiPath.GSuite.Activities.Api.GmailConnection My_Workspace_duongduy12314_gmail_com { get; set; }

        public GmailFactory(ICodedWorkflowsServiceContainer resolver)
        {
            Shared_gmail_20260413093817752 = new UiPath.GSuite.Activities.Api.GmailConnection("fd1b9265-dae8-4011-b32d-b3c99ec71d0a", resolver);
            My_Workspace_duongduy12314_gmail_com = new UiPath.GSuite.Activities.Api.GmailConnection("a03a0f0a-762f-44c5-9d07-4d280413f2ed", resolver);
        }
    }

    public class GoogleSheetsFactory
    {
        public GoogleSheetsFactory(ICodedWorkflowsServiceContainer resolver)
        {
        }
    }

    public class GoogleTasksFactory
    {
        public GoogleTasksFactory(ICodedWorkflowsServiceContainer resolver)
        {
        }
    }

    public class GoogleWorkspaceFactory
    {
        public GoogleWorkspaceFactory(ICodedWorkflowsServiceContainer resolver)
        {
        }
    }
}