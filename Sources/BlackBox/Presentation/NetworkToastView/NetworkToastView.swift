//
//  File.swift
//  BlackBox
//
//  Created by furkan vural on 3.04.2026.
//

import SwiftUI

@available(iOS 13.0, *)
struct NetworkToastView: View {
    let request: NetworkRequest
    let response: NetworkResponse?
    let onDismiss: () -> Void
    
    enum Tab: String, CaseIterable {
        case response = "Response"
        case headers = "Headers"
        case request = "Request"
    }
    
    @State private var isExpanded: Bool
    @State private var selectedTab: Tab = .response
    
    init(request: NetworkRequest, response: NetworkResponse?, isExpanded: Bool = false, onDismiss: @escaping () -> Void) {
        self.request = request
        self.response = response
        self.onDismiss = onDismiss
        _isExpanded = State(initialValue: isExpanded)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(alignment: .leading, spacing: 12) {
                // Row 1: Method + URL
                HStack(spacing: 12) {
                    methodBadge
                    Text(request.url.absoluteString)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                // Row 2: Status + Duration + Size + Expand
                HStack(spacing: 16) {
                    if let response = response {
                        statusBadge(response.statusCode)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 10, height: 10)
                            Text(response.formattedDuration)
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .foregroundColor(.gray)
                        
                        if let size = response.formattedDataSize {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 10, height: 10)
                                Text(size)
                                    .font(.system(size: 11, design: .monospaced))
                            }
                            .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                            NetworkToastManager.shared.setExpanded(isExpanded)
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 24, height: 24)
                    }
                }
                
                if isExpanded {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    Picker("", selection: $selectedTab) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 4)
                    
                    ScrollView {
                        Text(currentContent)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                }
            }
            .padding(12)
            .background(Color(UIColor(white: 0.1, alpha: 1.0)))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
        }
    }
    
    private var methodBadge: some View {
        Text(request.method)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(methodColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(methodColor.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(methodColor, lineWidth: 1)
            )
            .cornerRadius(6)
    }
    
    private var methodColor: Color {
        switch request.method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .gray
        }
    }
    
    private func statusBadge(_ code: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor(code))
                .frame(width: 6, height: 6)
            
            Text("\(code)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(UIColor(white: 0.2, alpha: 1.0)))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(6)
    }
    
    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        case 500..<600: return .red
        default: return .gray
        }
    }
    
    private var currentContent: String {
        switch selectedTab {
        case .response:
             if let response = response, let json = response.prettyJSON {
                 return json
             }
             return "No response body"
        case .headers:
            var text = ""
            if let response = response {
                text += "[Response Headers]\n"
                text += response.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            }
            text += "\n\n[Request Headers]\n"
            text += request.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            return text
        case .request:
            return request.toCURL()
        }
    }
}
