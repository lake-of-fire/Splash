/**
 *  Splash
 *  Copyright (c) John Sundell 2019
 *  MIT license - see LICENSE.md
 */

import Foundation

/// Type used to decorate a Markdown file with Splash-highlighted code blocks
public struct MarkdownDecorator {
    private let classPrefix: String
    private let highlighter: SyntaxHighlighter<HTMLOutputFormat>
    private let skipHighlightingPrefix = "no-highlight"

    /// Create a Markdown decorator with a given prefix to apply to all CSS
    /// classes used when highlighting code blocks within a Markdown string.
    public init(classPrefix: String = "", grammar: Grammar = SwiftGrammar()) {
        self.classPrefix = classPrefix
        highlighter = SyntaxHighlighter(format: HTMLOutputFormat(classPrefix: classPrefix), grammar: grammar)
    }

    /// Decorate all code blocks within a given Markdown string. This API assumes
    /// that the passed Markdown is valid. Each code block will be replaced by
    /// Splash-highlighted HTML for that block's code. To skip highlighting for
    /// any given code block, add "no-highlight" next to the opening row of
    /// backticks for that block.
    public func decorate(_ markdown: String) -> String {
        let components = markdown.components(separatedBy: "```")
        var output = ""

        for (index, component) in components.enumerated() {
            guard index % 2 != 0 else {
                output.append(component)
                continue
            }

            var code = component.trimmingCharacters(in: .whitespacesAndNewlines)

            if code.hasPrefix(skipHighlightingPrefix) {
                let charactersToDrop = skipHighlightingPrefix + "\n"
                code = code.dropFirst(charactersToDrop.count).escapingHTMLEntities()
            } else if code.lowercased().hasPrefix("yaml") || code.lowercased().hasPrefix("yml") {
                code = SyntaxHighlighter(format: HTMLOutputFormat(classPrefix: self.classPrefix), grammar: YamlGrammar()).highlight(code)
            } else if code.lowercased().hasPrefix("kotlin") {
                code = SyntaxHighlighter(format: HTMLOutputFormat(classPrefix: self.classPrefix), grammar: KotlinGrammar()).highlight(code)
            } else if code.lowercased().hasPrefix("python") || code.lowercased().hasPrefix("py") {
                code = SyntaxHighlighter(format: HTMLOutputFormat(classPrefix: self.classPrefix), grammar: PythonGrammar()).highlight(code)
            } else if code.lowercased().hasPrefix("dart") {
                code = SyntaxHighlighter(format: HTMLOutputFormat(classPrefix: self.classPrefix), grammar: DartGrammar()).highlight(code)
            } else if code.lowercased().hasPrefix("javascript") || code.lowercased().hasPrefix("js") {
                code = SyntaxHighlighter(format: HTMLOutputFormat(classPrefix: self.classPrefix), grammar: JavaScriptGrammar()).highlight(code)
            } else {
                code = highlighter.highlight(code)
            }

            output.append("""
            <pre class="splash"><code>\(code)</code></pre>
            """)
        }

        return output
    }
}
