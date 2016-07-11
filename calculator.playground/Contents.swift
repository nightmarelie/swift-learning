import UIKit

extension String {
    func split(regex pattern: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.CaseInsensitive])
            else { return [] }
        
        let nsString = self as NSString
        let stop = "<SomeStringThatYouDoNotExpectToOccurInSelf>"
        let modifiedString = re.stringByReplacingMatchesInString(
            self,
            options: .WithTransparentBounds,
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: stop)
        return modifiedString.componentsSeparatedByString(stop)
    }
    
    func exec(str: String) -> Array<String> {
        do {
            let regex = try NSRegularExpression(pattern: self, options: NSRegularExpressionOptions(rawValue: 0))
            let nsstr = str as NSString
            let all = NSRange(location: 0, length: nsstr.length)
            var matches : Array<String> = Array<String>()
            regex.enumerateMatchesInString(str, options: NSMatchingOptions(rawValue: 0), range: all) {
                (result : NSTextCheckingResult?, _, _) in
                let theResult = nsstr.substringWithRange(result!.range)
                matches.append(theResult)
            }
            return matches
        } catch {
            return Array<String>()
        }
    }}

class Stack {
    var data = [Expression]()
    
    func push(element: Expression) {
        self.data.append(element)
    }
    
    func poke() -> Expression? {
        if self.data.count > 0 {
            return self.data[data.endIndex - 1]
        }
        
        return nil
    }
    
    func pop() -> Expression? {
        if self.data.count > 0 {
            return self.data.removeLast()
        }
        
        return nil
    }
}

class Parenthesis: Expression {
    override init (value: String) {
        super.init(value: value)
        self.precedence = 6
    }
    
    override func isNoOp() -> Bool {
        return true
    }
    
    override func isParenthesis() -> Bool {
        return true
    }
    
    func isOpen() -> Bool {
        return self.value == "("
    }
}

class Number: Expression {
    override func operate(stack: Stack) -> Double {
        return Double(self.value)!
    }
}

class Operator: Expression {
    override init (value: String) {
        super.init(value: value)
    }
    
    var leftAssoc: Bool = true
    
    func isLeftAssoc() -> Bool {
        return self.leftAssoc
    }
    
    override func isOperator() -> Bool {
        return true
    }
}

final class Addition: Operator {
    override init (value: String) {
        super.init(value: value)
        self.precedence = 4
    }
    
    final override func operate(stack: Stack) -> Double {
        return Double(stack.pop()!.operate(stack)) + Double(stack.pop()!.operate(stack))
    }
}

final class Subtraction: Operator {
    override init (value: String) {
        super.init(value: value)
        self.precedence = 4
    }
    
    final override func operate(stack: Stack) -> Double {
        let left = Double(stack.pop()!.operate(stack))
        let right = Double(stack.pop()!.operate(stack))
        return right - left
    }
}

final class Multiplication: Operator {
    override init (value: String) {
        super.init(value: value)
        self.precedence = 5
    }
    
    final override func operate(stack: Stack) -> Double {
        return Double(stack.pop()!.operate(stack)) * Double(stack.pop()!.operate(stack))
    }
}

final class Division: Operator {
    override init (value: String) {
        super.init(value: value)
        self.precedence = 4
    }
    
    final override func operate(stack: Stack) -> Double {
        let left = Double(stack.pop()!.operate(stack))
        let right = Double(stack.pop()!.operate(stack))
        return right / left
    }
}

enum ExpressionError: ErrorType {
    
    case InvalidValue(explanations: String)
    
}

class Expression {
    var value: String
    
    var precedence: Int = 0
    
    init (value: String) {
        self.value = value
    }
    
    func getPrecedence() -> Int {
        return self.precedence
    }
    
    static func factory(value: String) throws -> Expression {

        switch value {
            case _ where ["(", ")"].contains(value):
                return Parenthesis(value: value)
            case _ where Int(value) != nil:
                return Number(value: value)
            case _ where Double(value) != nil:
                return Number(value: value)
            case "+":
                return Addition(value: value)
            case "-":
                return Subtraction(value: value)
            case "/":
                return Division(value: value)
            case "*":
                return Multiplication(value: value)
            default:
                throw ExpressionError.InvalidValue(explanations: "Unrecognized Value \(value)")
        }
    }
    
    func operate(stack: Stack) -> Double {
        preconditionFailure("This method must be overridden")
    }
    
    func isOperator() -> Bool {
        return false
    }
    
    func isParenthesis() -> Bool {
        return false
    }
    
    func isNoOp() -> Bool {
        return false
    }
    
    func render() -> String {
         return self.value
    }
}


enum CalculatorError: ErrorType {
    case RuntimeException(explanations: String)
}

class Calculator {
    func calc(mathString : String) -> String {
        let stack = self.parse(mathString)
        
        return self.execute(stack)
    }
    
    func parse(mathString: String) -> Stack {
        let tokens = self.tokenize(mathString)
        
        let output    = Stack()
        let operators = Stack()
        var expression: Expression
        
        do {
            for token in tokens {
                do {
                    try expression = Expression.factory(token)
                    
                    if expression.isOperator() {
                        self.parseOperator(expression as! Operator, output: output, operators: operators)
                    } else if expression.isParenthesis() {
                        try self.parseParenthesis(expression as! Parenthesis, output: output, operators: operators)
                    } else {
                        output.push(expression)
                    }
                } catch CalculatorError.RuntimeException(let explanations) {
                    print("Error: \(explanations)")
                } catch ExpressionError.InvalidValue(let explanations) {
                    print("Error: \(explanations)")
                } catch {
                    print("Error!!!!111")
                }
                
            }
            
            var op = operators.poke()
            repeat {
                op = operators.pop()
                
                if (op == nil) {
                    break
                }
                
                if (op!.isParenthesis()) {
                    throw ExpressionError.InvalidValue(explanations: "Mismatched parenthesis")
                }
                
                output.push(op!)
                
            } while op != nil
        
        
        } catch CalculatorError.RuntimeException(let explanations) {
            print("Error: \(explanations)")
        } catch {
            print("Error!!!!111")
        }
        
        return output
    }
    
    
    func parseOperator(oper: Operator, output: Stack, operators: Stack) {
        var end = operators.poke()
        
        if (end == nil) {
            operators.push(oper)
        } else if (end!.isOperator()) {

            repeat {

                end = operators.poke()
                
                if (end == nil) {
                    break
                }
                
                if (oper.isLeftAssoc() && oper.getPrecedence() <= end!.getPrecedence()) {
                    output.push(operators.pop()!)
                } else if (!oper.isLeftAssoc() && oper.getPrecedence() < end!.getPrecedence()) {
                    output.push(operators.pop()!)
                } else {
                    break
                }
                
            } while (end != nil && end!.isOperator())
                operators.push(oper)
        } else {
            operators.push(oper)
        }
    }
    
    func parseParenthesis(parenthesis: Parenthesis, output: Stack, operators: Stack) throws {
        var end = operators.poke()
        
        if parenthesis.isOpen() {
            operators.push(parenthesis)
        } else {
            var clean = false
            
            repeat {
                end = operators.pop()
            
                if (end == nil) {
                    break
                }
                
                if end!.isParenthesis() {
                    clean = true
                    break
                } else {
                    output.push(end!)
                }
                
            
            } while end != nil

            if (!clean) {
                throw ExpressionError.InvalidValue(explanations: "Mismatched parenthesis")
            }
        }
    }
    
    func execute(stack: Stack) -> String {
        var oper = stack.poke()

        var value: String
        
        repeat {
            oper = stack.pop()
            
            if (oper == nil || !oper!.isOperator()) {
                break
            }

            if oper!.isOperator() {
                value = String(oper!.operate(stack))
                if !value.isEmpty {
                    do {
                        try stack.push(Expression.factory(value))
                    } catch ExpressionError.InvalidValue(let explanations) {
                        print("Error: \(explanations)")
                    } catch {
                        print("Error!!!!111")
                    }
                }
            }

        } while oper!.isOperator()
        
        do {
            if (oper == nil) {
                try self.render(stack)
            } else {
                return oper!.render()
            }
        } catch CalculatorError.RuntimeException(let explanations) {
            print("Error: \(explanations)")
        } catch {
            print("Error!!!!111")
        }
        
        return ""
    }
    
    
    func render(stack: Stack) throws -> String {
        var output: String = ""
    
        while let el: Expression = stack.pop() {
            output += el.render()
        }
    
        if !output.isEmpty {
            return output
        }
    
        throw CalculatorError.RuntimeException(explanations: "Can't render output")
    }
    
    
    func tokenize(mathString: String) -> [String] {
        
        let rawArray = "(([-+]?(\\d+)\\.?\\d*|\\+|\\-|\\(|\\)|\\*|/)|\\s+)".exec(mathString)
        
        return rawArray.filter { !($0 ?? "").isEmpty && !($0 == " ") }
    }
}

// Demonstration
var calculator = Calculator()

var mathString = "3 + 5 * ( ( 5 - 4 ) / 3 )"
mathString = "3 + 5*((5 - 4)/3)"
mathString = "(2 + 2 * 2) + -100"
mathString = "((2 + 2) + 1) * 2 - 5"
mathString = "7 * 2 * 4 - 100 + -20"
mathString = "-3 / 12 + 3 * 4"
mathString = "((1000 + 8) / 2) + 2 - ((20 + 120) * 2)"

print(calculator.calc(mathString))
