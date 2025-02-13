import pandas as pd
from openpyxl import load_workbook
from openpyxl.styles import PatternFill, Font, Alignment
from openpyxl.utils import get_column_letter

def read_file(filename):
    with open(filename, 'r') as f:
        return [line.strip() for line in f if line.strip()]

def get_kernel_version(filename):
    try:
        with open(filename, 'r') as f:
            version = f.read().strip()
            # Extract version in x.x.x format
            parts = version.split('.')
            if len(parts) >= 3:
                return f"{parts[0]}.{parts[1]}.{parts[2].split('_')[0]}"
    except Exception as e:
        print(f"Error reading kernel version: {str(e)}")
        return "N/A"

def pad_array(arr, length, pad_value=''):
    return arr + [pad_value] * (length - len(arr))

def create_excel():
    try:
        # Get kernel version
        kernel_version = get_kernel_version('/var/lib/lkp-automation-data/state-files/kernel-version')

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
        excel_file = 'test-results.xlsx'
        df.to_excel(excel_file, index=False)

        # Load the workbook to apply formatting
        wb = load_workbook(excel_file)
        ws = wb.active

        # Delete the first row and insert a new one
        ws.delete_rows(1)
        ws.insert_rows(1)

        # Add kernel version information to the new first row
        kernel_headers = {
            3: f"kernel ver: {kernel_version} (Base-kernel)",
            4: f"kernel ver: {kernel_version} (kernel-with-patches)",
            5: f"kernel ver: {kernel_version} (Base-kernel)",
            6: f"kernel ver: {kernel_version} (kernel-with-patches)",
            7: f"kernel ver: {kernel_version} (Base-kernel)",
            8: f"kernel ver: {kernel_version} (kernel-with-patches)"
        }

        # Apply formatting to the new first row
        sea_blue = PatternFill(start_color='87CEEB', end_color='87CEEB', fill_type='solid')
        bold_font = Font(bold=True)
        left_align = Alignment(horizontal='left', vertical='top', wrap_text=True)

        for col, text in kernel_headers.items():
            cell = ws.cell(row=1, column=col, value=text)
            cell.fill = sea_blue
            cell.font = bold_font
            cell.alignment = left_align

        # Insert new row for "Run Time(sec)" labels
        ws.insert_rows(2)
        
        # Add "Run Time(sec)" labels to the new row
        for col in range(3, 9):  # Columns C to H
            cell = ws.cell(row=2, column=col, value="Run Time(sec)")
            cell.alignment = Alignment(horizontal='center')
            cell.font = Font(bold=True)

        # Define colors
        light_orange = PatternFill(start_color='FFE0B2', end_color='FFE0B2', fill_type='solid')
        light_blue = PatternFill(start_color='E3F2FD', end_color='E3F2FD', fill_type='solid')
        light_violet = PatternFill(start_color='E6E6FA', end_color='E6E6FA', fill_type='solid')
        very_light_green = PatternFill(start_color='F0FFF0', end_color='F0FFF0', fill_type='solid')

        # Format cell A11 
        cell_a11 = ws['A11']
        cell_a11.fill = light_violet
        cell_a11.alignment = Alignment(horizontal='center', vertical='center', text_rotation=90)
        cell_a11.font = Font(bold=True, size=22)

        # Insert empty rows before and after row 11
        ws.insert_rows(11)
        ws.insert_rows(13)

        # Merge cells and apply formatting for rows 3-10
        ws.merge_cells('A3:A10')
        merged_cell = ws['A3']
        merged_cell.alignment = Alignment(horizontal='center', vertical='center', text_rotation=90)
        merged_cell.font = Font(bold=True, size=22)
        merged_cell.fill = light_orange

        # Set cell A12 to horizontal alignment
        cell_a12 = ws['A12']
        if cell_a12:
            cell_a12.alignment = Alignment(horizontal='center', vertical='center', text_rotation=0)
            cell_a12.font = Font(bold=True, size=22)

        # Merge cells and apply formatting for rows 14-41
        ws.merge_cells('A14:A41')
        merged_cell = ws['A14']
        merged_cell.alignment = Alignment(horizontal='center', vertical='center', text_rotation=90)
        merged_cell.font = Font(bold=True, size=22)
        merged_cell.fill = light_blue

        # Set column widths to fit "kernel ver: x.x.x"
        for col in range(3, 9):  # Columns C to H
            ws.column_dimensions[get_column_letter(col)].width = 15

        # Set column widths for A and B
        ws.column_dimensions['A'].width = 15
        ws.column_dimensions['B'].width = 23  # Width to fit "100%-300s-whetstone-double"

        # Convert numeric values from string to float and apply left alignment
        left_align = Alignment(horizontal='left', vertical='center')
        for row in ws.iter_rows(min_row=3, max_row=41, min_col=3, max_col=8):
            for cell in row:
                cell.alignment = left_align
                if cell.value and isinstance(cell.value, str) and cell.value.strip():
                    try:
                        cell.value = float(cell.value)
                    except ValueError:
                        pass

        # Color rows 11 and 13 with very light green background
        for row_num in [11, 13]:
            for cell in ws[row_num]:
                cell.fill = very_light_green

        # Set vertical text rotation for all cells in column A except A12
        vertical_alignment = Alignment(horizontal='center', vertical='center', text_rotation=90)
        for row in ws.iter_rows(min_row=3, max_row=41, min_col=1, max_col=1):
            for cell in row:
                if cell.value and cell.row != 12:
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
