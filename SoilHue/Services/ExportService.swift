import Foundation
import CoreLocation

/// Servicio para exportar análisis de suelo en diferentes formatos
@MainActor
class ExportService: ObservableObject {
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
            return try await exportToCSV(analyses, to: exportURL) // Temporalmente usando CSV mientras arreglamos Excel
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
        var csvString = "ID,Fecha,Notación Munsell,Clasificación,Descripción,RGB Corregido,Calibrado,Factores de Corrección,Latitud,Longitud,Altitud,Dirección,Notas,Etiquetas\n"
        
        let geocoder = CLGeocoder()
        
        for analysis in analyses {
            print("DEBUG: Exportando análisis \(analysis.id) con localización: \(String(describing: analysis.locationInfo))")
            var locationColumns = ["","","",""] // [latitud, longitud, altitud, dirección]
            
            if let location = analysis.locationInfo {
                print("DEBUG: Procesando localización - lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude), alt: \(String(describing: location.altitude))")
                locationColumns[0] = String(format: "%.6f", location.coordinate.latitude)
                locationColumns[1] = String(format: "%.6f", location.coordinate.longitude)
                locationColumns[2] = String(format: "%.1f", location.altitude)
                
                // Intentar obtener la dirección
                if !Task.isCancelled {
                    do {
                        let placemarks = try await geocoder.reverseGeocodeLocation(location)
                        if let placemark = placemarks.first {
                            let components = [
                                placemark.thoroughfare,
                                placemark.locality,
                                placemark.administrativeArea,
                                placemark.country
                            ].compactMap { $0 }
                            locationColumns[3] = components.joined(separator: ", ")
                        }
                    } catch {
                        print("Error geocoding location: \(error)")
                    }
                }
            }
            
            // Preparar los datos básicos
            let idString = analysis.id.uuidString
            let dateString = ISO8601DateFormatter().string(from: analysis.timestamp)
            let munsellString = analysis.munsellColor ?? ""
            let classificationString = analysis.soilClassification ?? ""
            let descriptionString = analysis.soilDescription ?? ""
            let rgbString = "N/A" // RGB Corregido - no disponible en la estructura actual
            
            // Preparar información de calibración
            let calibratedString = analysis.calibrationInfo?.wasCalibrated == true ? "Sí" : "No"
            
            // Preparar factores de corrección
            var correctionFactorsString = "N/A"
            if let calibrationInfo = analysis.calibrationInfo {
                correctionFactorsString = String(format: "%.3f,%.3f,%.3f",
                    calibrationInfo.correctionFactors.red,
                    calibrationInfo.correctionFactors.green,
                    calibrationInfo.correctionFactors.blue)
            }
            
            // Preparar notas y etiquetas
            let notesString = analysis.notes
            let tagsString = analysis.tags.joined(separator: ";")
            
            // Construir la fila CSV
            let basicColumns = [
                "\"\(idString)\"",
                "\"\(dateString)\"",
                "\"\(munsellString)\"",
                "\"\(classificationString)\"",
                "\"\(descriptionString)\"",
                "\"\(rgbString)\"",
                "\"\(calibratedString)\"",
                "\"\(correctionFactorsString)\""
            ]
            
            let locationColumnsQuoted = locationColumns.map { "\"\($0)\"" }
            
            let metadataColumns = [
                "\"\(notesString)\"",
                "\"\(tagsString)\""
            ]
            
            let row = basicColumns + locationColumnsQuoted + metadataColumns
            csvString.append(row.joined(separator: ",") + "\n")
        }
        
        try csvString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
} 
