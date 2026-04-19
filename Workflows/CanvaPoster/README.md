# Canva Poster Workflow

## Luong hoat dong

```
Excel Local (Jobs_Local.xlsx)
    |
    v
[1] Read Input + Config
    |
    v
[2] Canva API Authentication
    |
    v
[3-4] Loop: For Each Job
    |-- [3] Create Design (Autofill from Brand Template)
    |-- [4] Export Design (PNG/PDF) + Download to local
    |
    v
[5] Generate Execution Report
```

## Cau truc Workflow

| File | Muc dich |
|------|----------|
| `0_CanvaPoster_Main.xaml` | Entry point, dieu phoi toan bo flow |
| `1_CanvaPoster_ReadInput.xaml` | Doc Config.xlsx + Excel input |
| `2_CanvaPoster_CanvaAuth.xaml` | Lay & validate Canva API token |
| `3_CanvaPoster_CreateDesign.xaml` | Goi Autofill API tao design tu template |
| `4_CanvaPoster_ExportDesign.xaml` | Export design + download file |
| `5_CanvaPoster_Report.xaml` | Ghi report ket qua |

## Yeu cau

- **Canva Pro/Teams/Enterprise** (cho Brand Templates + API access)
- **Canva Developer App** (tao tai https://www.canva.com/developers/)
- **UiPath.System.Activities** (co san - chua HTTP Request)
- **Newtonsoft.Json** (co san trong UiPath)

## Cach thiet lap Canva Template

1. Mo template trong Canva
2. Vao **Apps** > **Bulk Create**
3. Tao cac data fields: `job_title`, `company_name`, `location`, `salary`...
4. Connect tung text element voi data field tuong ung
5. Luu template → Lay **Brand Template ID**

## Config.xlsx can bo sung

### Sheet: Settings
- `InputFilePath` - Duong dan Excel input
- `Canva_AccessToken` - Bearer token (nen luu trong Orchestrator Asset)
- `Canva_BrandTemplateId` - ID cua brand template
- `Canva_ExportFormat` - png / pdf / jpg
- `Canva_OutputFolder` - Thu muc luu poster

### Sheet: FieldMappings
Map giua cot Excel va data field trong Canva template.

## Tham khao

- Framework chi tiet: `Framework/CanvaPoster_Framework.md`
- Canva Connect API docs: https://www.canva.dev/docs/connect/
