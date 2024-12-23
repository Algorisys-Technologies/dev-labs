declare module 'xlsx-populate' {
    export class Workbook {
        sheets(): Sheet[];
        static fromDataAsync(data: ArrayBuffer): Promise<Workbook>;
    }

    export class Sheet {
        _imageRels: { [key: string]: ImageRel };
        name(): string;
    }

    export class ImageRel {
        name: string;
        base64: string;
        position: {
            from: {
                row: number;
                col: number;
            },
            to: {
                row: number;
                col: number;
            }
        };
    }
}
