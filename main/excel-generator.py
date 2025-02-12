import pandas as pd
from openpyxl import load_workbook
from openpyxl.styles import PatternFill, Font, Alignment
from openpyxl.utils import get_column_letter

def read_file(filename):
    with open(filename, 'r') as f:
        return [line.strip() for line in f if line.strip()]

def pad_array(arr, length, pad_value=''):
    return arr + [pad_value] * (length - len(arr))

def create_excel():
    try:
        # Read all files
        test_suites = read_file('/var/lib/lkp-automation-data/results/test_suites')
        base_without_vms = read_file('/var/lib/lkp-automation-data/results/Base-without_vms')
        patch_without_vms = read_file('/var/lib/lkp-automation-data/results/Patch-without_vms')
        base_with_vms = read_file('/var/lib/lkp-automation-data/results/Base-with_vms')
        patch_with_vms = read_file('/var/lib/lkp-automation-data/results/Patch-with_vms')
        base_with_lkp_vms = read_file('/var/lib/lkp-automation-data/results/Base-with_lkp_vms')
        patch_with_lkp_vms = read_file('/var/lib/lkp-automation-data/results/Patch-with_lkp_vms')

        # Process test_suites into two columns
        test_suite_col = []
        test_col = []
        
        for line in test_suites[1:]:  # Skip header
            if line.startswith(','):
                test_suite_col.append('')
                test_col.append(line[1:])
            else:
                parts = line.split(',')
                if len(parts) > 1:
                    test_suite_col.append(parts[0])
                    test_col.append(parts[1])
                else:
                    test_suite_col.append(parts[0])
                    test_col.append('')

        # Find the maximum length needed
        max_length = max(
            len(test_suite_col),
            len(test_col),
            len(base_without_vms) - 1,
            len(patch_without_vms) - 1,
            len(base_with_vms) - 1,
            len(patch_with_vms) - 1,
            len(base_with_lkp_vms) - 1,
            len(patch_with_lkp_vms) - 1
        )

        # Pad all arrays
        test_suite_col = pad_array(test_suite_col, max_length)
        test_col = pad_array(test_col, max_length)
        
        # Create DataFrame with padded arrays
        df = pd.DataFrame({
            'Test_Suites': test_suite_col,
            'Test': test_col,
            'Base-without_vms': pad_array(base_without_vms[1:], max_length),
            'Patch-without_vms': pad_array(patch_without_vms[1:], max_length),
            'Base-with_vms': pad_array(base_with_vms[1:], max_length),
            'Patch-with_vms': pad_array(patch_with_vms[1:], max_length),
            'Base-with_lkp_vms': pad_array(base_with_lkp_vms[1:], max_length),
            'Patch-with_lkp_vms': pad_array(patch_with_lkp_vms[1:], max_length)
        })

        # Save to Excel directly in the current directory
        excel_file = '/var/lib/lkp-automation-data/results/lkp-results.xlsx'
        df.to_excel(excel_file, index=False)

        # Load the workbook to apply formatting
        wb = load_workbook(excel_file)
        ws = wb.active

        # Apply formatting to headers (row 1)
        header_fill = PatternFill(start_color='CCE5FF', end_color='CCE5FF', fill_type='solid')
        header_font = Font(bold=True, size=12)
        header_alignment = Alignment(horizontal='center')

        for cell in ws[1]:
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = header_alignment

        # Define colors
        light_orange = PatternFill(start_color='FFE0B2', end_color='FFE0B2', fill_type='solid')
        light_blue = PatternFill(start_color='E3F2FD', end_color='E3F2FD', fill_type='solid')
        light_violet = PatternFill(start_color='E6E6FA', end_color='E6E6FA', fill_type='solid')
        very_light_green = PatternFill(start_color='F0FFF0', end_color='F0FFF0', fill_type='solid')

        # Format cell A10 before inserting rows
        cell_a10 = ws['A10']
        cell_a10.fill = light_violet
        cell_a10.alignment = Alignment(horizontal='center', vertical='center', text_rotation=90)
        cell_a10.font = Font(bold=True, size=22)

        # Insert empty rows before and after row 10
        ws.insert_rows(10)
        ws.insert_rows(12)

        # Merge cells and apply formatting for rows 2-9
        ws.merge_cells('A2:A9')
        merged_cell = ws['A2']
        merged_cell.alignment = Alignment(horizontal='center', vertical='center', text_rotation=90)
        merged_cell.font = Font(bold=True, size=22)
        merged_cell.fill = light_orange

        # Set cell A11 to horizontal alignment
        cell_a11 = ws['A11']
        if cell_a11:
            cell_a11.alignment = Alignment(horizontal='center', vertical='center', text_rotation=0)
            cell_a11.font = Font(bold=True, size=22)

        # Merge cells and apply formatting for rows 13-40
        ws.merge_cells('A13:A40')
        merged_cell = ws['A13']
        merged_cell.alignment = Alignment(horizontal='center', vertical='center', text_rotation=90)
        merged_cell.font = Font(bold=True, size=22)
        merged_cell.fill = light_blue

        # Set column widths
        ws.column_dimensions['A'].width = 15
        ws.column_dimensions['B'].width = 30
        ws.column_dimensions['C'].width = 20
        ws.column_dimensions['D'].width = 20
        ws.column_dimensions['E'].width = 20
        ws.column_dimensions['F'].width = 20
        ws.column_dimensions['G'].width = 20
        ws.column_dimensions['H'].width = 20

        # Convert numeric values from string to float
        for row in ws.iter_rows(min_row=2):
            for cell in row[2:]:
                if cell.value and isinstance(cell.value, str) and cell.value.strip():
                    try:
                        cell.value = float(cell.value)
                    except ValueError:
                        pass

        # Color rows 10 and 12 with very light green background
        for row_num in [10, 12]:
            for cell in ws[row_num]:
                cell.fill = very_light_green

        # Set vertical text rotation for all cells in column A except A11
        vertical_alignment = Alignment(horizontal='center', vertical='center', text_rotation=90)
        for row in ws.iter_rows(min_row=2, max_row=40, min_col=1, max_col=1):
            for cell in row:
                if cell.value and cell.row != 11:  # Skip row 11
                    cell.alignment = vertical_alignment

        # Save the formatted workbook
        wb.save(excel_file)
        print(f"Excel file '{excel_file}' has been created successfully!")

    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    create_excel()
