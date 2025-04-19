import UIKit

class CalibrationCardService {
    /// Genera una imagen de la tarjeta de calibración
    /// - Returns: La imagen generada
    func generateCalibrationCard() -> UIImage? {
        // Crear un PDF temporal
        let pdfData = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: pdfData)!
        
        var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
            return nil
        }
        
        // Configurar el contexto
        pdfContext.beginPDFPage(nil)
        pdfContext.translateBy(x: 0, y: 842) // Mover al origen
        pdfContext.scaleBy(x: 1.0, y: -1.0) // Invertir el eje Y
        
        // Configurar el texto
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let textFont = UIFont.systemFont(ofSize: 12)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.black
        ]
        
        // Dibujar el título
        let title = "Tarjeta de Calibración Básica"
        title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
        
        // Dibujar las instrucciones
        let instructions = [
            "Instrucciones de uso:",
            "1. Imprime esta tarjeta en una impresora de calidad",
            "2. Asegúrate de que los colores se impriman correctamente",
            "3. Coloca la tarjeta sobre una superficie plana",
            "4. Evita sombras y reflejos",
            "5. Usa iluminación uniforme (preferiblemente luz natural indirecta)",
            "6. Mantén la tarjeta paralela a la cámara al tomar la foto",
            "",
            "Nota: Esta tarjeta básica proporciona una calibración aproximada.",
            "Para resultados profesionales, se recomienda usar el X-Rite ColorChecker Classic."
        ]
        
        var yPosition: CGFloat = 100
        for instruction in instructions {
            instruction.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: textAttributes)
            yPosition += 20
        }
        
        // Añadir espacio extra antes de la cuadrícula
        yPosition += 40
        
        // Dibujar la cuadrícula de colores
        let gridSize: CGFloat = 60
        let gridSpacing: CGFloat = 10
        let startX: CGFloat = 50
        let startY = yPosition
        
        // Colores de referencia para la cuadrícula
        let colors: [[UIColor]] = [
            [
                UIColor(red: 0.400, green: 0.350, blue: 0.336, alpha: 1.0), // dark skin
                UIColor(red: 0.713, green: 0.586, blue: 0.524, alpha: 1.0), // light skin
                UIColor(red: 0.247, green: 0.251, blue: 0.378, alpha: 1.0), // blue sky
                UIColor(red: 0.337, green: 0.422, blue: 0.286, alpha: 1.0), // foliage
                UIColor(red: 0.265, green: 0.240, blue: 0.329, alpha: 1.0), // blue flower
                UIColor(red: 0.261, green: 0.343, blue: 0.359, alpha: 1.0)  // bluish green
            ],
            [
                UIColor(red: 0.638, green: 0.445, blue: 0.164, alpha: 1.0), // orange
                UIColor(red: 0.242, green: 0.238, blue: 0.475, alpha: 1.0), // purplish blue
                UIColor(red: 0.449, green: 0.127, blue: 0.127, alpha: 1.0), // moderate red
                UIColor(red: 0.288, green: 0.187, blue: 0.292, alpha: 1.0), // purple
                UIColor(red: 0.491, green: 0.484, blue: 0.169, alpha: 1.0), // yellow green
                UIColor(red: 0.656, green: 0.484, blue: 0.156, alpha: 1.0)  // orange yellow
            ],
            [
                UIColor(red: 0.153, green: 0.198, blue: 0.558, alpha: 1.0), // blue
                UIColor(red: 0.283, green: 0.484, blue: 0.247, alpha: 1.0), // green
                UIColor(red: 0.558, green: 0.158, blue: 0.147, alpha: 1.0), // red
                UIColor(red: 0.890, green: 0.798, blue: 0.196, alpha: 1.0), // yellow
                UIColor(red: 0.558, green: 0.188, blue: 0.372, alpha: 1.0), // magenta
                UIColor(red: 0.168, green: 0.302, blue: 0.484, alpha: 1.0)  // cyan
            ],
            [
                UIColor(red: 0.950, green: 0.950, blue: 0.950, alpha: 1.0), // white
                UIColor(red: 0.773, green: 0.773, blue: 0.773, alpha: 1.0), // neutral 8
                UIColor(red: 0.604, green: 0.604, blue: 0.604, alpha: 1.0), // neutral 6.5
                UIColor(red: 0.422, green: 0.422, blue: 0.422, alpha: 1.0), // neutral 5
                UIColor(red: 0.249, green: 0.249, blue: 0.249, alpha: 1.0), // neutral 3.5
                UIColor(red: 0.104, green: 0.104, blue: 0.104, alpha: 1.0)  // black
            ]
        ]
        
        // Dibujar cada celda de la cuadrícula
        for (rowIndex, row) in colors.enumerated() {
            for (colIndex, color) in row.enumerated() {
                let x = startX + CGFloat(colIndex) * (gridSize + gridSpacing)
                let y = startY + CGFloat(rowIndex) * (gridSize + gridSpacing)
                
                let rect = CGRect(x: x, y: y, width: gridSize, height: gridSize)
                pdfContext.setFillColor(color.cgColor)
                pdfContext.fill(rect)
                
                // Añadir borde negro
                pdfContext.setStrokeColor(UIColor.black.cgColor)
                pdfContext.setLineWidth(1.0)
                pdfContext.stroke(rect)
            }
        }
        
        // Finalizar el PDF
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        // Convertir el PDF a una imagen
        let pdfDataRef = pdfData as CFData
        guard let dataProvider = CGDataProvider(data: pdfDataRef),
              let pdfDocument = CGPDFDocument(dataProvider),
              let pdfPage = pdfDocument.page(at: 1) else {
            return nil
        }
        
        let pageRect = pdfPage.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(bounds: CGRect(origin: .zero, size: pageRect.size))
        
        return renderer.image { context in
            context.cgContext.translateBy(x: 0, y: pageRect.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            context.cgContext.drawPDFPage(pdfPage)
        }
    }
} 