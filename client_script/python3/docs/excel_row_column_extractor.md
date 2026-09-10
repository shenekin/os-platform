# Excel Row and Column Data Extractor

This application extracts rows from an `.xlsx` workbook when the configured row conditions match. Matching rows may be consecutive or non-consecutive. The source worksheet, header row, row conditions, selected output columns, and output path are all controlled by a JSON configuration file.

## Project Layout

```text
python3/
├── config/
│   └── config.json
├── docs/
│   └── excel_row_column_extractor.md
├── scripts/
│   └── excel_row_column_extractor.py
└── requirements.txt
```

## Installation

```bash
cd /Users/ekin/Documents/Development_Codes/os-platform/client_script/python3
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
```

On Windows PowerShell, use:

```powershell
Set-Location C:\path\to\python3
py -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
```

## Configuration

Edit `config/config.json`. The file is valid JSON. JSON does not support `//` comments, so the configuration includes an optional `_comments` object containing English explanations. The application ignores keys beginning with `_`.

Relative paths in `input_file` and `output_file` are resolved from the directory containing `config.json`, not from the shell's current directory. This allows the command to be launched from any directory. Absolute paths are also supported.

The sample configuration is stored in `config/config.json`, so:

- `../scripts/source.xlsx` means the `scripts` directory one level above `config`.
- `../output/result.xlsx` means an `output` directory one level above `config`.

Run the command from the project root:

```bash
cd /Users/ekin/Documents/Development_Codes/os-platform/client_script/python3
.venv/bin/python scripts/excel_row_column_extractor.py --config config/config.json
```

On Windows PowerShell, use:

```powershell
Set-Location C:\path\to\python3
.venv\Scripts\python.exe scripts\excel_row_column_extractor.py --config config\config.json
```

### Configuration Fields

| Field | Required | Description |
| --- | --- | --- |
| `input_file` | Yes | Path to the source `.xlsx` workbook. |
| `output_file` | Yes | Path for the generated `.xlsx` workbook. Existing output is replaced. |
| `sheet_name` | No | One worksheet name, for example `windows`. Use `null` to scan every worksheet. |
| `header_row` | No | One-based row number containing column headers. The supplied workbook uses `2`. |
| `data_start_row` | No | One-based first row eligible for extraction. It must be greater than `header_row`. The supplied workbook uses `4` because row 3 is a section label. |
| `data_only` | No | Use `true` to read cached formula results; use `false` to read formulas. |
| `condition_mode` | No | `all` means every condition must match. `any` means at least one condition must match. |
| `row_conditions` | No | List of rules that decide which rows are extracted. An empty list matches every data row. |
| `output_columns` | No | Columns to export. An empty list exports the complete row. |
| `preserve_format_columns` | No | Copies source cell formatting for every extracted cell in the listed columns. |
| `preserve_format_values` | No | Copies the source cell style when a configured column contains one of the configured values. |
| `output_sheet_name` | No | Name of the worksheet in the generated workbook. |

### Platform-Specific Paths

Use forward slashes in relative paths on every platform. Python handles these paths on Windows, macOS, and Linux.

Relative path examples:

```json
{
  "input_file": "../input/source.xlsx",
  "output_file": "../output/extracted.xlsx"
}
```

Absolute path examples:

macOS or Linux:

```json
{
  "input_file": "/data/firewall/source.xlsx",
  "output_file": "/data/firewall/output/extracted.xlsx"
}
```

Windows:

```json
{
  "input_file": "C:/data/firewall/source.xlsx",
  "output_file": "C:/data/firewall/output/extracted.xlsx"
}
```

Windows paths may also use escaped backslashes:

```json
{
  "input_file": "C:\\data\\firewall\\source.xlsx",
  "output_file": "C:\\data\\firewall\\output\\extracted.xlsx"
}
```

Only the JSON configuration needs to change when the source or destination changes. The Python script does not contain an input or output workbook path.

### Choosing Header and Data Rows

The row numbers are configured independently:

- `header_row` is the row containing field names such as `ISID`, `Environment`, and `Proxy Destination URL`.
- `data_start_row` is the first row that can be extracted after the header.
- Rows between `header_row` and `data_start_row` are ignored.
- Both values are one-based Excel row numbers.

For the supplied workbook, use:

```json
"header_row": 2,
"data_start_row": 4
```

If another workbook has field names on row 5 and data beginning on row 6, use:

```json
"header_row": 5,
"data_start_row": 6
```

`data_start_row` must always be greater than `header_row`.

### Selecting Rows

Each item in `row_conditions` has this structure:

```json
{
  "column": "Column Header Name",
  "operator": "operator_name",
  "value": "comparison value"
}
```

The `value` field is required for comparison operators such as `equals` and `contains`. It is not needed for `not_empty` or `empty`.

The current configuration selects every row where `Proxy Destination URL` contains data:

```json
"condition_mode": "all",
"row_conditions": [
  {
    "column": "Proxy Destination URL",
    "operator": "not_empty"
  }
]
```

To add another required condition, add another object and keep `condition_mode` as `all`:

```json
"condition_mode": "all",
"row_conditions": [
  {
    "column": "Proxy Destination URL",
    "operator": "not_empty"
  },
  {
    "column": "Environment",
    "operator": "equals",
    "value": "Prod"
  }
]
```

This extracts rows where both conditions match: the URL is not empty and `Environment` equals `Prod`.

To match either condition, use `any`:

```json
"condition_mode": "any",
"row_conditions": [
  {
    "column": "Environment",
    "operator": "equals",
    "value": "Prod"
  },
  {
    "column": "Environment",
    "operator": "equals",
    "value": "Stage"
  }
]
```

This extracts rows where `Environment` is either `Prod` or `Stage`.

### Selecting Columns

Set `output_columns` to an empty list to export every column from each matching row:

```json
"output_columns": []
```

To export selected columns, list their exact header names in the required output order:

```json
"output_columns": [
  "ISID",
  "Environment",
  "Destination IP Address",
  "Proxy Destination URL",
  "Remark"
]
```

You can also identify columns by Excel letter or one-based number:

```json
"output_columns": ["A", "D", "O", 16]
```

Do not mix duplicate references to the same column. Header names must match the source header exactly, including spaces and line breaks in the header cell.

### Preserving Source Formatting

Use `preserve_format_values` when specific source values must keep their original formatting in the output workbook. The extractor copies the source cell style, including font, fill, border, alignment, protection, and number format.

Use `preserve_format_columns` when every extracted cell in a column must keep its source formatting. The extractor also preserves the source row height and column width. This is important for long text that uses wrapped lines.

The current configuration preserves the wrapping and formatting of every extracted `Proxy Destination URL` cell:

```json
"preserve_format_columns": [
  "Proxy Destination URL"
]
```

The source column width is copied to the output workbook, so long URLs keep the same display width and wrapping behavior.

For example, the following source value keeps its four separate lines in the output workbook:

```text
*.crowdstrike.com*
*.cloudsink.net*
*.crowdstrike.com/*
*.cloudsink.net/*
```

The extractor copies the cell value without replacing or flattening newline characters. It also keeps `wrap_text` enabled and preserves the source row height, so Excel displays the value as four visible lines.

The current configuration preserves the formatting of `Security Proxy VIP` and `Proxy VIP` in the `Destination Service Name` column:

```json
"preserve_format_values": [
  {
    "column": "Destination Service Name",
    "values": [
      "Security Proxy VIP",
      "Proxy VIP"
    ]
  }
]
```

To preserve formatting for additional values, add them to the same `values` list:

```json
"preserve_format_values": [
  {
    "column": "Destination Service Name",
    "values": [
      "Security Proxy VIP",
      "Proxy VIP",
      "Database Proxy"
    ]
  }
]
```

To preserve formatting in another column, add another configuration object:

```json
"preserve_format_values": [
  {
    "column": "Destination Service Name",
    "values": ["Security Proxy VIP", "Proxy VIP"]
  },
  {
    "column": "Remark",
    "values": ["Default CyberArk rules"]
  }
]
```

Matching is exact after surrounding whitespace is removed. The values must exist in the source workbook and the column name must match the source header exactly. This setting affects formatting only; it does not decide which rows are extracted. Row selection is still controlled by `row_conditions`.

### Supported Operators

Supported condition operators:

| Operator | Meaning |
| --- | --- |
| `not_empty` | Cell contains a non-whitespace value. |
| `empty` | Cell is empty or contains only whitespace. |
| `equals` | Cell exactly equals `value`. |
| `not_equals` | Cell does not equal `value`. |
| `contains` | Cell contains `value`. |
| `not_contains` | Cell does not contain `value`. |
| `starts_with` | Cell starts with `value`. |
| `ends_with` | Cell ends with `value`. |
| `regex` | Cell matches the regular expression in `value`. |

Examples:

```json
{"column": "Remark", "operator": "contains", "value": "CyberArk"}
{"column": "Environment", "operator": "not_equals", "value": "Test"}
{"column": "Proxy Destination URL", "operator": "starts_with", "value": "https://"}
{"column": "Proxy Destination URL", "operator": "regex", "value": "^https://.+"}
```

### Common Recipes

Extract every data row from one worksheet:

```json
"sheet_name": "windows",
"header_row": 2,
"data_start_row": 4,
"row_conditions": [],
"output_columns": []
```

Extract only rows where the URL is empty:

```json
"row_conditions": [
  {
    "column": "Proxy Destination URL",
    "operator": "empty"
  }
]
```

Extract rows containing a URL and export only selected fields:

```json
"row_conditions": [
  {
    "column": "Proxy Destination URL",
    "operator": "not_empty"
  }
],
"output_columns": [
  "ISID",
  "Node Name",
  "Destination IP Address",
  "Proxy Destination URL"
]
```

Example with multiple conditions:

```json
{
  "condition_mode": "all",
  "row_conditions": [
    {"column": "Proxy Destination URL", "operator": "not_empty"},
    {"column": "Action", "operator": "equals", "value": "Allow"}
  ],
  "output_columns": ["Rule Name", "Proxy Destination URL", "Action"]
}
```

## Usage

The program writes an `.xlsx` file and prints the number of matching rows and selected columns in English. It does not modify the source workbook.

After changing the configuration, run the same command again. A successful message looks like this:

```text
Extraction completed: 200 matching rows and 18 columns written to CMP-S2C-PROD-Default-Firewall-Rule-20260823-extracted.xlsx
```

If the input workbook cannot be found, check the path in `input_file` and remember that relative paths start from the `config.json` directory. If the output is written somewhere unexpected, check `output_file`. If a header cannot be found, check that `header_row` is correct and that the configured header name exactly matches the Excel header. If rows are missing, check `data_start_row`. If the output contains only one column, check that `output_columns` is `[]` rather than a list containing only one header.