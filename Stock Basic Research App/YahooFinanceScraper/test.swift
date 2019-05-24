import Foundation

let baseURL = "https://finance.yahoo.com/quote/"
let statURL = "/key-statistics?p="

let today = Date()
let five_years_in_sec = TimeInterval(1825 * 86400)
let one_year_in_sec = TimeInterval(365 * 86400)
let three_months_in_sec = TimeInterval(93 * 86400)
let one_week_in_sec = TimeInterval(7 * 86400)

let invalid_symbol_string = "<title>Symbol Lookup from Yahoo Finance</title>"

struct Company {
    var symbol: String
    var name: String
    var marketCap: String
    var enterpriseValue: String
    var trailingPE: String
    var forwardPE: String
}

var company_dictionary:[String:Company] = [:]

// Build URL to get historical data of a given stock
// symbol: String of the symbol. eg) AAPL
// start: start date.
// end: end date
// interval: 1d, 1wk, 1mo
func historical_url(symbol: String,
                    start: Int,
                    end: Int,
                    interval: String) -> String {
    return String(format: "%@%@/history?period1=%d&period2=%d&interval=%@&filter=history&frequency=%@",
                  baseURL, symbol, start, end, interval, interval)
    
}

// Presets: "5y1m": 5 years in 1 month interval
//                    "1y1w": 1 year in 1 week interval
//                    "3m1d": 3 months in 1 day interval
//                    "1w1d": 1 week in 1 day interval
func historical_url(symbol: String,
                    preset: String) -> String {
    var start = 0
    let end = Int(today.timeIntervalSince1970)
    var interval = ""
    
    switch preset {
    case "5y1m":
        start = Int((today - five_years_in_sec).timeIntervalSince1970)
        interval = "1mo"
    case "1y1w":
        start = Int((today - one_year_in_sec).timeIntervalSince1970)
        interval = "1wk"
    case "3m1d":
        start = Int((today - three_months_in_sec).timeIntervalSince1970)
        interval = "1d"
    case "1k1d":
        start = Int((today - one_week_in_sec).timeIntervalSince1970)
        interval = "1d"
    default:
        print("Error: unrecognized preset in historical_url")
        return "";
    }
    
    return historical_url(symbol: symbol,
                          start: start,
                          end: end,
                          interval: interval)
}

func get_basic_info(symbol: String) {
    let url = URL(string: baseURL + symbol + statURL + symbol)!
    
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else {
            print("data was nil")
            return
        }
        guard let htmlString = String(data: data, encoding: .utf8) else {
            print("couldn't cast data into String")
            return
        }
        
        if htmlString.contains(invalid_symbol_string) {
            print("Invalid Symbol/No data on Symbol")
            return
        }
        
        
        // parse for name of company
        var leftString = "Key Statistics | "
        var rightString = " Stock - Yahoo Finance"
        var leftSideRange = htmlString.range(of: leftString)
        var rightSideRange = htmlString.range(of: rightString)
        if leftSideRange == nil {
            print("couldn't find left range when parsing for name of company")
            return
        }
        if rightSideRange == nil {
            print("couldn't find right range when parsing for name of company")
            return
        }
        var rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
        let name = String(htmlString[rangeOfTheData])
        
        
        // parse for market cap
        leftString = """
                    <td class="Fz(s) Fw(500) Ta(end)" data-reactid="19">
                    """
        rightString = """
                    </td></tr><tr data-reactid="20">
                    """
        leftSideRange = htmlString.range(of: leftString)
        rightSideRange = htmlString.range(of: rightString)
        if leftSideRange == nil {
            print("couldn't find left range when parsing for market cap")
            return
        }
        if rightSideRange == nil {
            print("couldn't find right range when parsing for market cap")
            return
        }
        rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
        let marketCap = String(htmlString[rangeOfTheData])
        
        
        // parse for enterprise value
        leftString = """
        <td class="Fz(s) Fw(500) Ta(end)" data-reactid="26">
        """
        rightString = """
        </td></tr><tr data-reactid="27">
        """
        leftSideRange = htmlString.range(of: leftString)
        rightSideRange = htmlString.range(of: rightString)
        if leftSideRange == nil {
            print("couldn't find left range when parsing for enterprise value")
            return
        }
        if rightSideRange == nil {
            print("couldn't find right range when parsing for enterprise value")
            return
        }
        rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
        let enterpriseValue = String(htmlString[rangeOfTheData])
        
        
        // parse for trailingPE
        leftString = """
        <td class="Fz(s) Fw(500) Ta(end)" data-reactid="33">
        """
        rightString = """
        </td></tr><tr data-reactid="34">
        """
        leftSideRange = htmlString.range(of: leftString)
        rightSideRange = htmlString.range(of: rightString)
        if leftSideRange == nil {
            print("couldn't find left range when parsing for trailingPE")
            return
        }
        if rightSideRange == nil {
            print("couldn't find right range when parsing for trailingPE")
            return
        }
        rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
        let trailingPE = String(htmlString[rangeOfTheData])
        
        
        // parse for forwardPE
        leftString = """
        <td class="Fz(s) Fw(500) Ta(end)" data-reactid="40">
        """
        rightString = """
        </td></tr><tr data-reactid="41">
        """
        leftSideRange = htmlString.range(of: leftString)
        rightSideRange = htmlString.range(of: rightString)
        if leftSideRange == nil {
            print("couldn't find left range when parsing for forwardPE")
            return
        }
        if rightSideRange == nil {
            print("couldn't find right range when parsing for forwardPE")
            return
        }
        rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
        let forwardPE = String(htmlString[rangeOfTheData])
        
        
        let c = Company(symbol: symbol,
                        name: name,
                        marketCap: marketCap,
                        enterpriseValue: enterpriseValue,
                        trailingPE: trailingPE,
                        forwardPE: forwardPE)
        company_dictionary[symbol] = c
        
        print(company_dictionary)
        //print(htmlString)
        
    }
    
    task.resume()
}

get_basic_info(symbol: "AAPL")
get_basic_info(symbol: "AMZN")

