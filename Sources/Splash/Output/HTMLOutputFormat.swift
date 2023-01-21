/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

/// Output format to use to generate an HTML string with a semantic
/// representation of the highlighted code. Each token will be wrapped
/// in a `span` element with a CSS class matching the token's type.
/// Optionally, a `classPrefix` can be set to prefix each CSS class with
/// a given string.
public struct HTMLOutputFormat: OutputFormat {
    public var classPrefix: String
    static var CSSBody: [Substring] = []
    
    public init(classPrefix: String = "") {
        self.classPrefix = classPrefix
        guard let CSSFileURL = Bundle.main.path(forResource: "sundellsColors", ofType: "css") else { return }
        
        do {
            HTMLOutputFormat.CSSBody = try String(contentsOf: URL(fileURLWithPath: CSSFileURL), encoding: .utf8).split(separator: "\n")
        } catch {
            print("Error finding file 'sundellsColors.css' in \(CSSFileURL)")
        }
    }
    
    public func makeBuilder() -> Builder {
        return Builder(classPrefix: classPrefix)
    }
}

public extension HTMLOutputFormat {
    struct Builder: OutputBuilder {
        private let classPrefix: String
        private var html = ""
        private var pendingToken: (string: String, type: TokenType)?
        private var pendingWhitespace: String?
        private var inline: Bool = true

        fileprivate init(classPrefix: String) {
            self.classPrefix = classPrefix
            
            if(inline) {
                let style = getTillNextBracket(startFrom: 0)!.replacingOccurrences(of: "\n", with: "", options: .literal, range: nil).replacingOccurrences(of: " ", with: "", options: .literal, range: nil)
                html.append(
                    """
                    <div style="\(style)">\n
                    """)
            }
        }

        public mutating func addToken(_ token: String, ofType type: TokenType) {
            if var pending = pendingToken {
                guard pending.type != type else {
                    pendingWhitespace.map { pending.string += $0 }
                    pendingWhitespace = nil
                    pending.string += token
                    pendingToken = pending
                    return
                }
            }

            appendPending()
            pendingToken = (token, type)
        }

        public mutating func addPlainText(_ text: String) {
            appendPending()
            html.append(text.escapingHTMLEntities())
        }

        public mutating func addWhitespace(_ whitespace: String) {
            if pendingToken != nil {
                pendingWhitespace = (pendingWhitespace ?? "") + whitespace
            } else {
                html.append(whitespace)
            }
        }

        public mutating func build() -> String {
            appendPending()
            html.append("\n</div><br>")
            return html
        }

        private mutating func appendPending() {
            if let pending = pendingToken {
                
                if(self.inline) {
                    html.append(
                    """
                    <span style="\(getCSSBody(classPrefix: pending.type.string).replacingOccurrences(of: " ", with: ""))">\(pending.string.escapingHTMLEntities())</span>
                    """)
                } else {
                    html.append(
                    """
                    <span class="\(classPrefix)\(pending.type.string)">\(pending.string.escapingHTMLEntities())</span>
                    """)
                }
                

                pendingToken = nil
            }

            if let whitespace = pendingWhitespace {
                html.append(whitespace)
                pendingWhitespace = nil
            }
        }
        
        public func getCSSBody(classPrefix: String) -> Substring {
            guard let tokenIndex = HTMLOutputFormat.CSSBody.firstIndex(of: "pre code .\(classPrefix) {") else { return "" }
            return HTMLOutputFormat.CSSBody[tokenIndex+1]
        }
        
        public mutating func flipInline() {
            self.inline = !self.inline
        }
    }
    
    static func getTillNextBracket(startFrom: Int) -> String? {
        var firstBracket: Bool = false, secondBracket: Bool = false
        var traversed: String = ""
        
        for line in CSSBody.enumerated() {
            if(firstBracket) {
                if(!secondBracket) {
                    if(line.element.contains("}")) {
                        secondBracket = true
                        break
                    } else {
                        traversed += line.element
                    }
                }
            } else {
                if(line.element.contains("{")) {
                    firstBracket = true
                }
            }
            traversed += "\n"
        }
        
        if(firstBracket && secondBracket) {
            return traversed.replacingOccurrences(of: " ", with: "", options: .literal, range: nil)
        } else {
            return nil
        }
        
    }
}
