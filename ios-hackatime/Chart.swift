//
//  Chart.swift
//  ios-hackatime
//
//  Created by divpreet on 08/09/2025.
//


import SwiftUI
import Charts

struct languageChart: View {
    let languages: [LangStat]
    
    var body: some View {
        Chart(languages) { lang in
            SectorMark(
                angle: .value("Time", lang.total_seconds)
            )
            .foregroundStyle(by: .value("Language", lang.name ?? "-"))
        }
        .frame(height: 250)
        .chartLegend(position: .trailing)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.hcMuted, lineWidth: 2)
            )
    }
}

struct editorChart: View {
    let editor: [EditorStat]
    
    var body: some View {
        Chart(editor) { editor in
            BarMark (
                x: .value("Editor", editor.editor),
                y: .value("Sessions", editor.count)
                
            )
            .foregroundStyle(by: .value("Editor", editor.editor))
        }
        .frame(height: 250)
        .chartLegend(position: .trailing)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.hcMuted, lineWidth: 2)
            )
    }
}


