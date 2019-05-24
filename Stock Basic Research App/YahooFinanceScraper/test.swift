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
    var pegRatio: String
    var priceSale: String
    var priceBook: String
    var enterpriseValueRevenue: String
    var enterpriseValueEBITDA: String
    var profitMargin: String
    var operativeMargin: String
    var returnOnAssets: String
    var returnOnEquity: String
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

func scrap_from_statistics(htmlString:String, left:Int, right:Int, name_of_stat:String) -> String {
    let leftString = """
    <td class="Fz(s) Fw(500) Ta(end)" data-reactid="\(left)">
    """
    let rightString = """
    </td></tr><tr data-reactid="\(right)">
    """
    guard let leftSideRange = htmlString.range(of: leftString) else {
        print("couldn't find left range when parsing for " + name_of_stat)
        return ""
    }
    guard let rightSideRange = htmlString.range(of: rightString) else {
        print("couldn't find right range when parsing for " + name_of_stat)
        return ""
    }
    let rangeOfTheData = leftSideRange.upperBound..<rightSideRange.lowerBound
    return String(htmlString[rangeOfTheData])
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
        
        let marketCap = scrap_from_statistics(htmlString: htmlString, left: 19, right: 20, name_of_stat: "marketCap")
        let enterpriseValue = scrap_from_statistics(htmlString: htmlString, left: 26, right: 27, name_of_stat: "enterpriseValue")
        let trailingPE = scrap_from_statistics(htmlString: htmlString, left: 33, right: 34, name_of_stat: "trailingPE")
        let forwardPE = scrap_from_statistics(htmlString: htmlString, left: 40, right: 41, name_of_stat: "forwardPE")
        let pegRatio = scrap_from_statistics(htmlString: htmlString, left: 47, right: 48, name_of_stat: "pegRatio")
        let priceSale = scrap_from_statistics(htmlString: htmlString, left: 54, right: 55, name_of_stat: "priceSale")
        let priceBook = scrap_from_statistics(htmlString: htmlString, left: 61, right: 62, name_of_stat: "priceBook")
        let enterpriseValueRevenue = scrap_from_statistics(htmlString: htmlString, left: 68, right: 69, name_of_stat: "enterpriseValueRevenue")
        
        leftString = """
        <td class="Fz(s) Fw(500) Ta(end)" data-reactid="75">
        """
        rightString = """
        </td></tr></tbody></table></div></div><div class="" data-reactid="76">
        """
        leftSideRange = htmlString.range(of: leftString)
        rightSideRange = htmlString.range(of: rightString)
        if leftSideRange == nil {
            print("couldn't find left range when parsing for name of enterpriseValueEBITDA")
            return
        }
        if rightSideRange == nil {
            print("couldn't find right range when parsing for name of enterpriseValueEBITDA")
            return
        }
        rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
        let enterpriseValueEBITDA = String(htmlString[rangeOfTheData])
        
        let profitMargin = scrap_from_statistics(htmlString: htmlString, left: 112, right: 113, name_of_stat: "profitMargin")
        
        leftString = """
        <td class="Fz(s) Fw(500) Ta(end)" data-reactid="119">
        """
        rightString = """
        </td></tr></tbody></table></div><div data-reactid="120">
        """
        leftSideRange = htmlString.range(of: leftString)
        rightSideRange = htmlString.range(of: rightString)
        if leftSideRange == nil {
            print("couldn't find left range when parsing for name of operativeMargin")
            return
        }
        if rightSideRange == nil {
            print("couldn't find right range when parsing for name of operativeMargin")
            return
        }
        rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
        let operativeMargin = String(htmlString[rangeOfTheData])
        
        let returnOnAssets = scrap_from_statistics(htmlString: htmlString, left: 131, right: 132, name_of_stat: "profitMargin")
        
        leftString = """
        <td class="Fz(s) Fw(500) Ta(end)" data-reactid="138">
        """
        rightString = """
        </td></tr></tbody></table></div><div data-reactid="139">
        """
        leftSideRange = htmlString.range(of: leftString)
        rightSideRange = htmlString.range(of: rightString)
        if leftSideRange == nil {
            print("couldn't find left range when parsing for name of returnOnEquity")
            return
        }
        if rightSideRange == nil {
            print("couldn't find right range when parsing for name of returnOnEquity")
            return
        }
        rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
        let returnOnEquity = String(htmlString[rangeOfTheData])
        
        let c = Company(symbol: symbol,
                        name: name,
                        marketCap: marketCap,
                        enterpriseValue: enterpriseValue,
                        trailingPE: trailingPE,
                        forwardPE: forwardPE,
                        pegRatio: pegRatio,
                        priceSale: priceSale,
                        priceBook: priceBook,
                        enterpriseValueRevenue: enterpriseValueRevenue,
                        enterpriseValueEBITDA: enterpriseValueEBITDA,
                        profitMargin: profitMargin,
                        operativeMargin: operativeMargin,
                        returnOnAssets: returnOnAssets,
                        returnOnEquity: returnOnEquity)
        company_dictionary[symbol] = c
        
        print(company_dictionary)
        //print(htmlString)
        
    }
    
    task.resume()
}

get_basic_info(symbol: "AAPL")
get_basic_info(symbol: "AMZN")
get_basic_info(symbol: "GOOGL")
