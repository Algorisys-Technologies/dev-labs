// eslint
import type { FUniver } from '@univerjs/facade'
import { ScrollToCellCommand } from '@univerjs/sheets-ui'
import * as XLSX from 'xlsx';


export function setupImportSheetData($toolbar: HTMLElement, univerAPI: FUniver) {
  const $importButton = document.createElement('input');
  $importButton.type = 'file';
  $importButton.accept = '.xlsx';
  $toolbar.appendChild($importButton);

  $importButton.addEventListener('change', (event) => {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      const data = new Uint8Array(e.target?.result as ArrayBuffer);
      const workbook = XLSX.read(data, { type: 'array' });

      const activeWorkbook = univerAPI.getActiveWorkbook();
      if (!activeWorkbook) throw new Error('activeWorkbook is not defined');

      workbook.SheetNames.forEach((sheetName) => {
        const sheetData = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName], { header: 1 });
        const sheet = activeWorkbook.create(sheetName, sheetData.length, sheetData[0].length);

        sheetData.forEach((row, rowIndex) => {
          row.forEach((cell, colIndex) => {
            const range = sheet.getRange(rowIndex, colIndex);
            range.setValue(cell);
          });
        });
      });

      // Trigger any necessary UI updates or commands
      univerAPI.executeCommand('univer.command.updateUI');
    };

    reader.readAsArrayBuffer(file);
  });
}

export function setupExportSheetData($toolbar: HTMLElement, univerAPI: FUniver) {
  const $getButton = document.createElement('a');
  $getButton.textContent = 'Save';
  $toolbar.appendChild($getButton);

  $getButton.addEventListener('click', () => {
    const activeWorkbook = univerAPI.getActiveWorkbook();
    if (!activeWorkbook) throw new Error('activeWorkbook is not defined');

    const snapshot = activeWorkbook.getSnapshot();

    // Create a new workbook for export
    const wb = XLSX.utils.book_new();

    for (const [sheetName, sheetData] of Object.entries(snapshot.sheets)) {
      // Extract cell data from the sheet's cellData object
      const cellData: (string | number)[][] = [];
      const cells = sheetData.cellData || {};

      for (const [rowKey, rowCells] of Object.entries(cells)) {
        const rowIndex = parseInt(rowKey, 10);
        for (const [colKey, cell] of Object.entries(rowCells)) {
          const colIndex = parseInt(colKey, 10);
          if (!cellData[rowIndex]) cellData[rowIndex] = [];
          // Handle both value and formula cases
          if (cell.f) {
            // If there's a formula, store it as a string
            cellData[rowIndex][colIndex] = cell.f;
          } else {
            // Otherwise, store the value
            cellData[rowIndex][colIndex] = cell.v;
          }
        }
      }

      // Convert cell data to worksheet
      const ws = XLSX.utils.aoa_to_sheet(cellData);

      // Add the worksheet to the workbook
      XLSX.utils.book_append_sheet(wb, ws, sheetName);
    }

    // Generate Excel file and trigger download
    XLSX.writeFile(wb, 'WorkbookData.xlsx');
  });
}


export function setupSetValue($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'set A1 Value'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    const value = 'Hello, World!'

    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')
    const activeSheet = activeWorkbook.getActiveSheet()
    if (!activeSheet)
      throw new Error('activeSheet is not defined')

    const range = activeSheet.getRange(0, 0)
    if (!range)
      throw new Error('range is not defined')

    /**
     * @see https://univer.ai/typedoc/@univerjs/facade/classes/FRange#setValue
     */
    range.setValue(value)
  })
}

export function setupSetValues($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'set A1:B2 values'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    const values = [
      ['Hello', 'World!'],
      ['Hello', 'Univer!'],
    ]

    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')
    const activeSheet = activeWorkbook.getActiveSheet()
    if (!activeSheet)
      throw new Error('activeSheet is not defined')

    const range = activeSheet.getRange(0, 0, values.length, values[0].length)
    if (!range)
      throw new Error('range is not defined')

    /**
     * @see https://univer.ai/typedoc/@univerjs/facade/classes/FRange#setValues
     */
    range.setValues(values)
  })
}

export function setupGetValue($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'get A1 value'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    const values = [
      ['Hello', 'World!'],
      ['Hello', 'Univer!'],
      ['Hello', 'Sheets!'],
    ]

    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')
    const activeSheet = activeWorkbook.getActiveSheet()
    if (!activeSheet)
      throw new Error('activeSheet is not defined')

    const range = activeSheet.getRange(0, 0, values.length, values[0].length)
    if (!range)
      throw new Error('range is not defined')

    /**
     * @see https://univer.ai/typedoc/@univerjs/facade/classes/FRange#getValue
     */
    // eslint-disable-next-line no-alert
    alert(JSON.stringify(range.getValue(), null, 2))
    // eslint-disable-next-line no-console
    console.log(JSON.stringify(range.getValue(), null, 2))
  })
}

export function setupGetA1CellData($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'get A1 CellData'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')
    const activeSheet = activeWorkbook.getActiveSheet()
    if (!activeSheet)
      throw new Error('activeSheet is not defined')

    const range = activeSheet.getRange(0, 0, 1, 1)
    if (!range)
      throw new Error('range is not defined')

    /**
     * @see https://univer.ai/typedoc/@univerjs/facade/classes/FRange#getValue
     */
    // eslint-disable-next-line no-alert
    alert(JSON.stringify(range.getCellData(), null, 2))
    // eslint-disable-next-line no-console
    console.log(JSON.stringify(range.getCellData(), null, 2))
  })
}

export function setupValues($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'get A1:B2 values'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    const values = [
      ['Hello', 'World!'],
      ['Hello', 'Univer!'],
      ['Hello', 'Sheets!'],
    ]

    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')
    const activeSheet = activeWorkbook.getActiveSheet()
    if (!activeSheet)
      throw new Error('activeSheet is not defined')

    const range = activeSheet.getRange(0, 0, values.length, values[0].length)
    if (!range)
      throw new Error('range is not defined')

    // TODO: add facade API
    const data: (string | undefined)[][] = []
    range.forEach((row, col, cell) => {
      data[row] = data[row] || []
      data[row][col] = cell.v?.toString()
    })

    // eslint-disable-next-line no-alert
    alert(JSON.stringify(data, null, 2))
    // eslint-disable-next-line no-console
    console.log(JSON.stringify(data, null, 2))
  })
}

export function setupGetWorkbookData($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'get workbook data'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')

    // eslint-disable-next-line no-alert
    alert(JSON.stringify(activeWorkbook.getSnapshot(), null, 2))
    // eslint-disable-next-line no-console
    console.log(JSON.stringify(activeWorkbook.getSnapshot(), null, 2))
  })
}

export function setupGetSheetData($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'get Sheet1 data'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')

    const snapshot = activeWorkbook.getSnapshot()
    const sheet1 = Object.values(snapshot.sheets).find((sheet) => {
      return sheet.name === 'Sheet1'
    })

    if (!sheet1)
      throw new Error('sheet1 is not defined')

    // eslint-disable-next-line no-alert
    alert(JSON.stringify(sheet1, null, 2))
    // eslint-disable-next-line no-console
    console.log(JSON.stringify(sheet1, null, 2))
  })
}

export function setupCreateSheet($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'create Sheet2'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')

    const sheet = activeWorkbook.create('Sheet2', 10, 10)

    if (!sheet)
      throw new Error('sheet is not defined')

    // eslint-disable-next-line no-alert
    alert('Sheet created')
  })
}

export function setupScrollToCell($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'scroll to B100'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    if (!univerAPI)
      throw new Error('univerAPI is not defined')

    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')

    univerAPI.executeCommand(ScrollToCellCommand.id, {
      range: {
        startColumn: 1,
        startRow: 99,
      },
    })
  })
}

export function setupScrollToTop($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'scroll to top'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    if (!univerAPI)
      throw new Error('univerAPI is not defined')

    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')

    univerAPI.executeCommand('sheet.command.scroll-to-cell', {
      range: {
        startColumn: 0,
        startRow: 0,
      },
    })
  })
}

export function setupScrollToBottom($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'scroll to bottom'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    if (!univerAPI)
      throw new Error('univerAPI is not defined')

    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')
    const activeSheet = activeWorkbook.getActiveSheet()
    if (!activeSheet)
      throw new Error('activeSheet is not defined')

    // eslint-disable-next-line ts/ban-ts-comment
    // @ts-expect-error
    const { rowCount } = activeSheet._worksheet.getSnapshot()
    univerAPI.executeCommand('sheet.command.scroll-to-cell', {
      range: {
        startColumn: 0,
        startRow: rowCount - 1,
      },
    })
  })
}

export function setupSetBackground($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'set A1 background'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    if (!univerAPI)
      throw new Error('univerAPI is not defined')

    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')
    const activeSheet = activeWorkbook.getActiveSheet()
    if (!activeSheet)
      throw new Error('activeSheet is not defined')

    const range = activeSheet.getRange(0, 0, 1, 1)
    range?.setBackgroundColor('red')
  })
}

export function setupCommandsListenerSwitch($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'start listening commands'
  $toolbar.appendChild($button)
  const el = $button
  let listener: any = null

  $button.addEventListener('click', () => {
    if (!univerAPI)
      throw new Error('univerAPI is not defined')

    if (listener) {
      listener.dispose()
      listener = null
      el.innerHTML = 'start listening commands'
      return
    }

    listener = univerAPI.onCommandExecuted((command) => {
      // eslint-disable-next-line no-console
      console.log(command)
    })
    el.innerHTML = 'stop listening commands'

    // eslint-disable-next-line no-alert
    alert('Press "Ctrl + Shift + I" to open the console and do some actions in the Univer Sheets, you will see the commands in the console.')
  })
}

export function setupEditSwitch($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'disable edit'
  $toolbar.appendChild($button)
  const el = $button
  let listener: any = null
  let errListener: any = null

  $button.addEventListener('click', () => {
    if (!univerAPI)
      throw new Error('univerAPI is not defined')

    class DisableEditError extends Error {
      constructor() {
        super('editing is disabled')
        this.name = 'DisableEditError'
      }
    }

    if (listener) {
      listener.dispose()
      window.removeEventListener('error', errListener)
      window.removeEventListener('unhandledrejection', errListener)
      listener = null
      el.innerHTML = 'disable edit'
      return
    }

    errListener = (e: PromiseRejectionEvent | ErrorEvent) => {
      const error = e instanceof PromiseRejectionEvent ? e.reason : e.error
      if (error instanceof DisableEditError) {
        e.preventDefault()
        console.warn('editing is disabled')
      }
    }
    window.addEventListener('error', errListener)
    window.addEventListener('unhandledrejection', errListener)
    listener = univerAPI.onBeforeCommandExecute(() => {
      throw new DisableEditError()
    })

    // eslint-disable-next-line no-alert
    alert('Editing is disabled, try to edit a cell to see the effect')
    el.innerHTML = 'enable edit'
  })
}

export function setupUndo($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'undo'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    if (!univerAPI)
      throw new Error('univerAPI is not defined')

    univerAPI.executeCommand('univer.command.undo')
  })
}

export function setupRedo($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'redo'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    if (!univerAPI)
      throw new Error('univerAPI is not defined')

    univerAPI.executeCommand('univer.command.redo')
  })
}

export function setupSetSelection($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'select A1'
  $toolbar.appendChild($button)

  $button.addEventListener('click', () => {
    if (!univerAPI)
      throw new Error('univerAPI is not defined')
    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')
    const activeSheet = activeWorkbook.getActiveSheet()
    if (!activeSheet)
      throw new Error('activeSheet is not defined')

    const subUnitId = activeSheet.getSheetId()

    univerAPI.executeCommand('sheet.operation.set-selections', {
      selections: [{
        range: {
          startRow: 0,
          startColumn: 0,
          endRow: 0,
          endColumn: 0,
          rangeType: 0,
        },
      }],
      subUnitId,
      unitId: activeWorkbook.getId(),
      type: 2,
    })
  })
}

export function setupClearStyles($toolbar: HTMLElement, univerAPI: FUniver) {
  const $button = document.createElement('a')
  $button.textContent = 'clear A1 styles'
  $toolbar.appendChild($button)

  $button.addEventListener('click', async () => {
    if (!univerAPI)
      throw new Error('univerAPI is not defined')

    const activeWorkbook = univerAPI.getActiveWorkbook()
    if (!activeWorkbook)
      throw new Error('activeWorkbook is not defined')
    const activeSheet = activeWorkbook.getActiveSheet()
    if (!activeSheet)
      throw new Error('activeSheet is not defined')

    const subUnitId = activeSheet.getSheetId()

    await univerAPI.executeCommand('sheet.operation.set-selections', {
      selections: [{
        range: {
          startRow: 0,
          startColumn: 0,
          endRow: 0,
          endColumn: 0,
          rangeType: 0,
        },
      }],
      subUnitId,
      unitId: activeWorkbook.getId(),
      type: 2,
    })

    univerAPI.executeCommand('sheet.command.clear-selection-format')
  })
}