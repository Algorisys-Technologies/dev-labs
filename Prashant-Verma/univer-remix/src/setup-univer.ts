import { LocaleType, Univer, UniverInstanceType } from '@univerjs/core'
import { defaultTheme } from '@univerjs/design'
import { UniverDocsPlugin } from '@univerjs/docs'
import { UniverDocsUIPlugin } from '@univerjs/docs-ui'
import { UniverFormulaEnginePlugin } from '@univerjs/engine-formula'
import { UniverRenderEnginePlugin } from '@univerjs/engine-render'
import { UniverSheetsPlugin } from '@univerjs/sheets'
import { UniverSheetsFormulaPlugin } from '@univerjs/sheets-formula'
import { UniverSheetsNumfmtPlugin } from '@univerjs/sheets-numfmt'
import { UniverSheetsUIPlugin } from '@univerjs/sheets-ui'
import { UniverUIPlugin } from '@univerjs/ui'
import { UniverSheetsZenEditorPlugin } from '@univerjs/sheets-zen-editor'
import { FUniver } from '@univerjs/facade'
import { enUS } from 'univer:locales'
import { setupComment } from './setups/setupComment'

import '@univerjs/drawing-ui/lib/index.css';
import '@univerjs/sheets-drawing-ui/lib/index.css';
 
import { UniverDrawingPlugin } from '@univerjs/drawing';
import { UniverDrawingUIPlugin } from '@univerjs/drawing-ui';
import { UniverSheetsDrawingPlugin } from '@univerjs/sheets-drawing';
import { UniverSheetsDrawingUIPlugin } from '@univerjs/sheets-drawing-ui';
import { Tools } from '@univerjs/core';
import DrawingUIEnUS from '@univerjs/drawing-ui/locale/en-US';
import SheetsDrawingUIEnUS from '@univerjs/sheets-drawing-ui/locale/en-US';

export function setupUniver() {
  const univer = new Univer({
    theme: defaultTheme,
    locale: LocaleType.EN_US,
    locales: {
      [LocaleType.EN_US]: Tools.deepMerge(
        DrawingUIEnUS,
        SheetsDrawingUIEnUS
      ),
    },
  })

  univer.registerPlugin(UniverDocsPlugin, {
    hasScroll: false,
  })
  univer.registerPlugin(UniverDocsUIPlugin)
  univer.registerPlugin(UniverRenderEnginePlugin)
  univer.registerPlugin(UniverUIPlugin, {
    container: 'univer',
    header: true,
    footer: true,
  })
  univer.registerPlugin(UniverSheetsPlugin)
  univer.registerPlugin(UniverSheetsUIPlugin)

  univer.registerPlugin(UniverSheetsNumfmtPlugin)
  univer.registerPlugin(UniverFormulaEnginePlugin)
  univer.registerPlugin(UniverSheetsFormulaPlugin)

  univer.registerPlugin(UniverSheetsZenEditorPlugin)

  univer.createUnit(UniverInstanceType.UNIVER_SHEET, {})

  univer.registerPlugin(UniverDrawingPlugin);
univer.registerPlugin(UniverDrawingUIPlugin);
univer.registerPlugin(UniverSheetsDrawingPlugin);
univer.registerPlugin(UniverSheetsDrawingUIPlugin);

  // In version v0.1.15, please register the comment plugin after calling univer.createUnit.
  setupComment(univer)

  return FUniver.newAPI(univer)
}
