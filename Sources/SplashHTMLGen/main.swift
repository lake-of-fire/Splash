/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation
import Splash

guard CommandLine.arguments.count > 1 else {
    print("⚠️  Please supply the code to generate HTML for as a string argument")
    exit(1)
}

//let code = CommandLine.arguments[1]

let code =      """
                    func test(arg1: String) -> Int {
                        if(true) {
                            return 1
                        } else {
                            return 0
                        }
                    }

                """

let highlighter = SyntaxHighlighter(format: HTMLOutputFormat())



print("\n\n\(highlighter.highlight(code))")
