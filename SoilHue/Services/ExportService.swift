import Foundation
import XlsxWriter

/// Servicio para exportar análisis de suelo en diferentes formatos
@MainActor
class ExportService {
    /// Errores que pueden ocurrir durante la exportación
    enum ExportError: LocalizedError {
        case failedToCreateFile
        case failedToWriteData
        case invalidFormat
        case noDataToExport
        
        var errorDescription: String? {
            switch self {
            case .failedToCreateFile:
                return "No se pudo crear el archivo de exportación"
            case .failedToWriteData:
                return "Error al escribir los datos"
            case .invalidFormat:
                return "Formato de exportación no válido"
            case .noDataToExport:
                return "No hay datos para exportar"
            }
        }
    }
    
    /// Formatos de exportación soportados
    enum ExportFormat {
        case json
        case csv
        case excel
        
        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            case .excel: return "xlsx"
            }
        }
        
        var mimeType: String {
            switch self {
            case .json: return "application/json"
            case .csv: return "text/csv"
            case .excel: return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            }
        }
    }
    
    /// Exporta un conjunto de análisis al formato especificado
    /// - Parameters:
    ///   - analyses: Lista de análisis a exportar
    ///   - format: Formato de exportación deseado
    ///   - baseURL: URL base donde guardar el archivo
    /// - Returns: URL del archivo exportado
    func exportAnalyses(_ analyses: [SoilAnalysis], to format: ExportFormat, baseURL: URL) async throws -> URL {
        guard !analyses.isEmpty else {
            throw ExportError.noDataToExport
        }
        
        let fileName = "SoilHue_Export_\(Date().ISO8601Format()).\(format.fileExtension)"
        let exportURL = baseURL.appendingPathComponent(fileName)
        
        switch format {
        case .json:
            return try await exportToJSON(analyses, to: exportURL)
        case .csv:
            return try await exportToCSV(analyses, to: exportURL)
        case .excel:
            return try await exportToExcel(analyses, to: exportURL)
        }
    }
    
    /// Exporta los análisis a formato JSON
    private func exportToJSON(_ analyses: [SoilAnalysis], to url: URL) async throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(analyses)
        try data.write(to: url)
        return url
    }
    
    /// Exporta los análisis a formato CSV
    private func exportToCSV(_ analyses: [SoilAnalysis], to url: URL) async throws -> URL {
        var csvString = "ID,Fecha,Notación Munsell,Clasificación,Descripción,RGB Corregido,Calibrado,Factores de Corrección,Notas,Etiquetas\n"
        
        for analysis in analyses {
            let row = [
                analysis.id.uuidString,
                ISO8601DateFormatter().string(from: analysis.timestamp),
                analysis.colorInfo.munsellNotation,
                analysis.colorInfo.soilClassification,
                analysis.colorInfo.soilDescription,
                "\(analysis.colorInfo.correctedRGB.red),\(analysis.colorInfo.correctedRGB.green),\(analysis.colorInfo.correctedRGB.blue)",
                analysis.calibrationInfo.wasCalibrated ? "Sí" : "No",
                "\(analysis.calibrationInfo.correctionFactors.red),\(analysis.calibrationInfo.correctionFactors.green),\(analysis.calibrationInfo.correctionFactors.blue)",
                analysis.metadata.notes ?? "",
                analysis.metadata.tags.joined(separator: ";")
            ].map { "\"\($0)\"" }.joined(separator: ",")
            
            csvString.append(row + "\n")
        }
        
        try csvString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    /// Exporta los análisis a formato Excel
    private func exportToExcel(_ analyses: [SoilAnalysis], to url: URL) async throws -> URL {
        let workbook = Workbook(url.path)
        let worksheet = workbook.addWorksheet("Análisis de Suelo")
        
        // Estilo para el encabezado
        let headerFormat = workbook.addFormat()
        headerFormat.setBold()
        headerFormat.setAlign(.center)
        headerFormat.setBackground(.gray)
        headerFormat.setFontColor(.white)
        
        // Encabezados
        let headers = [
            "ID", "Fecha", "Notación Munsell", "Clasificación", "Descripción",
            "RGB Corregido", "Calibrado", "Factores de Corrección", "Notas", "Etiquetas"
        ]
        
        // Escribir encabezados
        for (col, header) in headers.enumerated() {
            worksheet.write(0, col, header, headerFormat)
            worksheet.setColumn(col, col, 15) // Ancho de columna
        }
        
        // Escribir datos
        for (row, analysis) in analyses.enumerated() {
            let rowIndex = row + 1
            worksheet.write(rowIndex, 0, analysis.id.uuidString)
            worksheet.write(rowIndex, 1, ISO8601DateFormatter().string(from: analysis.timestamp))
            worksheet.write(rowIndex, 2, analysis.colorInfo.munsellNotation)
            worksheet.write(rowIndex, 3, analysis.colorInfo.soilClassification)
            worksheet.write(rowIndex, 4, analysis.colorInfo.soilDescription)
            worksheet.write(rowIndex, 5, "\(analysis.colorInfo.correctedRGB.red),\(analysis.colorInfo.correctedRGB.green),\(analysis.colorInfo.correctedRGB.blue)")
            worksheet.write(rowIndex, 6, analysis.calibrationInfo.wasCalibrated ? "Sí" : "No")
            worksheet.write(rowIndex, 7, "\(analysis.calibrationInfo.correctionFactors.red),\(analysis.calibrationInfo.correctionFactors.green),\(analysis.calibrationInfo.correctionFactors.blue)")
            worksheet.write(rowIndex, 8, analysis.metadata.notes ?? "")
            worksheet.write(rowIndex, 9, analysis.metadata.tags.joined(separator: ";"))
        }
        
        workbook.close()
        return url
    }
} 