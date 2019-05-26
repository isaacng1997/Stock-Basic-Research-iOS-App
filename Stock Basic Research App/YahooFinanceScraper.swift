//
//  YahooFinanceScraper.swift
//  Stock Basic Research App
//
//  Created by Isaac Ng on 5/24/19.
//  Copyright © 2019 Isaac Ng. All rights reserved.
//

//
//  YahooFinanceScraper.swift
//  Stock Basic Research App
//
//  Created by Isaac Ng on 5/24/19.
//  Copyright © 2019 Isaac Ng. All rights reserved.
//

import Foundation

let baseURL = "https://finance.yahoo.com/quote/"
let statURL = "/key-statistics?p="
let profileURL = "/profile?p="

let today = Date()
let five_years_in_sec = TimeInterval(1825 * 86400)
let one_year_in_sec = TimeInterval(365 * 86400)
let three_months_in_sec = TimeInterval(93 * 86400)
let one_week_in_sec = TimeInterval(7 * 86400)

let invalid_symbol_string = "<title>Symbol Lookup from Yahoo Finance</title>"

class YahooFinanceScraper {
    private var get_all_info_result:[String:String] = [:]
    
    func get_all_info(symbol: String) -> [String: String] {
        get_all_info_result = [:]
        let semaphore = DispatchSemaphore(value: 0)
        print("in get all info")
        
        get_info_from_stat(symbol: symbol, semaphore: semaphore)
        semaphore.wait()
        get_info_from_profile(symbol: symbol, semaphore: semaphore)
        semaphore.wait()
        return get_all_info_result
        
    }
    
    func get_newest_price(symbol:String) -> String {
        let url = URL(string: baseURL + symbol + statURL + symbol)!
        let semaphore = DispatchSemaphore(value: 0)
        var result = "-1"
        
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
            
            var lastPrice = ""
            
            let leftString = """
            "currency":"USD","regularMarketPrice":{"raw":
            """
            var rightString = """
            "},"regularMarketVolume":{"raw":
            """
            guard let leftSideRange = htmlString.range(of: leftString) else {
                print("couldn't find left range when parsing for last price")
                return
            }
            guard let rightSideRange = htmlString.range(of: rightString) else {
                print("couldn't find right range when parsing for last price")
                return
            }
            var rangeOfTheData = leftSideRange.upperBound..<rightSideRange.lowerBound
            lastPrice = String(htmlString[rangeOfTheData])
            
            
            rightString = """
            ,"fmt":"
            """
            guard let rightSideRange2 = lastPrice.range(of: rightString) else {
                print("couldn't find right range when parsing for last price")
                return
            }
            rangeOfTheData = lastPrice.startIndex..<rightSideRange2.lowerBound
            result = String(lastPrice[rangeOfTheData])
            
            
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return result
    }
    
    private func shorten_stat_htmlString(htmlString: String) -> String {
        let leftString = """
        <td class="Fz(s) Fw(500) Ta(end)" data-reactid="19">
        """
        let rightString = """
        </td></tr></tbody></table></div></div></div><div class="Cl(b)" data-reactid="484">
        """
        
        guard let leftSideRange = htmlString.range(of: leftString) else {
            print("couldn't find left range when shortening htmlString")
            return htmlString
        }
        guard let rightSideRange = htmlString.range(of: rightString) else {
            print("couldn't find right range when shortening htmlString")
            return htmlString
        }
        let rangeOfTheData = leftSideRange.lowerBound ..< rightSideRange.upperBound
        return String(htmlString[rangeOfTheData])
    }
    
    private func replace_sumbols(string: String) -> String {
        var result = string.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&#x27;", with: "'")
        
        return string
    }
    
    
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
    
    private func scrap_from_statistics(htmlString: inout String,
                                      left: Int,
                                      name_of_stat: String,
                                      end_of_table: Bool = false,
                                      end_of_div: Bool = false) -> String {
        let leftString = """
        <td class="Fz(s) Fw(500) Ta(end)" data-reactid="\(left)">
        """
        var rightString = """
        </td></tr><tr data-reactid="\(left + 1)">
        """
        if end_of_table {
            rightString = """
            </td></tr></tbody></table></div><div data-reactid="\(left + 1)">
            """
        }
        if end_of_div {
            rightString = """
            </td></tr></tbody></table></div></div><div class="" data-reactid="\(left + 1)">
            """
        }
        
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
    
    func get_info_from_stat(symbol: String, semaphore: DispatchSemaphore) {
        let url = URL(string: baseURL + symbol + statURL + symbol)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                print("data was nil")
                return
            }
            guard var htmlString = String(data: data, encoding: .utf8) else {
                print("couldn't cast data into String")
                return
            }
            
            if htmlString.contains(invalid_symbol_string) {
                print("Invalid Symbol/No data on Symbol")
                return
            }
            
            // parse for name of company
            var error = false
            var leftString = "Key Statistics | "
            var rightString = " Stock - Yahoo Finance"
            var leftSideRange = htmlString.range(of: leftString)
            var rightSideRange = htmlString.range(of: rightString)
            var rangeOfTheData = htmlString.startIndex ..< htmlString.startIndex
            var name = ""
            if leftSideRange == nil {
                print("couldn't find left range when parsing for name of company")
                error = true
            }
            if rightSideRange == nil {
                print("couldn't find right range when parsing for name of company")
                error = true
            }
            if !error {
                rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
                name = String(htmlString[rangeOfTheData])
                name = self.replace_sumbols(string: name)
            }
            
            
            // parse for last price
            error = false
            leftString = """
            "currency":"USD","regularMarketPrice":{"raw":
            """
            rightString = """
            "},"regularMarketVolume":{"raw":
            """
            leftSideRange = htmlString.range(of: leftString)
            rightSideRange = htmlString.range(of: rightString)
            var lastPrice = ""
            if leftSideRange == nil {
                print("couldn't find left range when parsing for last price")
                error = true
            }
            if rightSideRange == nil {
                print("couldn't find right range when parsing for last price")
                error = true
            }
            if !error {
                rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
                lastPrice = String(htmlString[rangeOfTheData])
                
                error = false
                rightString = """
                ,"fmt":"
                """
                rightSideRange = lastPrice.range(of: rightString)
                if rightSideRange == nil {
                    print("couldn't find right range when parsing for last price")
                    error = true
                }
                
                if !error {
                    rangeOfTheData = lastPrice.startIndex..<rightSideRange!.lowerBound
                    lastPrice = String(lastPrice[rangeOfTheData])
                }
            }
            
            htmlString = self.shorten_stat_htmlString(htmlString: htmlString)
            
            // parse for last split date
            error = false
            leftString = """
            <td class="Fz(s) Fw(500) Ta(end)" data-reactid="483">
            """
            rightString = """
            </td></tr></tbody></table></div></div></div><div class="Cl(b)" data-reactid="484">
            """
            leftSideRange = htmlString.range(of: leftString)
            rightSideRange = htmlString.range(of: rightString)
            var lastSplitDate = ""
            if leftSideRange == nil {
                print("couldn't find left range when parsing for last split date")
                error = true
            }
            if rightSideRange == nil {
                print("couldn't find right range when parsing for last split date")
                error = true
            }
            if !error {
                rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
                lastSplitDate = String(htmlString[rangeOfTheData])
            }
            
            self.get_all_info_result["symbol"] =                    symbol
            self.get_all_info_result["name"] =                      name
            self.get_all_info_result["marketCap"] =                 self.scrap_from_statistics(htmlString: &htmlString, left: 19, name_of_stat: "marketCap")
            self.get_all_info_result["enterpriseValue"] =           self.scrap_from_statistics(htmlString: &htmlString, left: 26, name_of_stat: "enterpriseValue")
            self.get_all_info_result["trailingPE"] =                self.scrap_from_statistics(htmlString: &htmlString, left: 33, name_of_stat: "trailingPE")
            self.get_all_info_result["forwardPE"] =                 self.scrap_from_statistics(htmlString: &htmlString, left: 40, name_of_stat: "forwardPE")
            self.get_all_info_result["pegRatio"] =                  self.scrap_from_statistics(htmlString: &htmlString, left: 47, name_of_stat: "pegRatio")
            self.get_all_info_result["priceSale"] =                 self.scrap_from_statistics(htmlString: &htmlString, left: 54, name_of_stat: "priceSale")
            self.get_all_info_result["priceBook"] =                 self.scrap_from_statistics(htmlString: &htmlString, left: 61, name_of_stat: "priceBook")
            self.get_all_info_result["enterpriseValueRevenue"] =    self.scrap_from_statistics(htmlString: &htmlString, left: 68, name_of_stat: "enterpriseValueRevenue")
            self.get_all_info_result["enterpriseValueEBITDA"] =     self.scrap_from_statistics(htmlString: &htmlString, left: 75, name_of_stat: "enterpriseValueEBITDA", end_of_div: true)
            
            self.get_all_info_result["profitMargin"] =      self.scrap_from_statistics(htmlString: &htmlString, left: 112, name_of_stat: "profitMargin")
            self.get_all_info_result["operativeMargin"] =   self.scrap_from_statistics(htmlString: &htmlString, left: 119, name_of_stat: "operativeMargin", end_of_table: true)
            
            self.get_all_info_result["returnOnAssets"] = self.scrap_from_statistics(htmlString: &htmlString, left: 131, name_of_stat: "returnOnAssets")
            self.get_all_info_result["returnOnEquity"] = self.scrap_from_statistics(htmlString: &htmlString, left: 138, name_of_stat: "returnOnEquity", end_of_table: true)
            
            self.get_all_info_result["revenue"] =                   self.scrap_from_statistics(htmlString: &htmlString, left: 150, name_of_stat: "revenue")
            self.get_all_info_result["revenuePerShare"] =           self.scrap_from_statistics(htmlString: &htmlString, left: 157, name_of_stat: "revenuePerShare")
            self.get_all_info_result["quarterlyRevenueGrowth"] =    self.scrap_from_statistics(htmlString: &htmlString, left: 164, name_of_stat: "quarterlyRevenueGrowth")
            self.get_all_info_result["grossProfit"] =               self.scrap_from_statistics(htmlString: &htmlString, left: 171, name_of_stat: "grossProfit")
            self.get_all_info_result["ebitda"] =                    self.scrap_from_statistics(htmlString: &htmlString, left: 178, name_of_stat: "ebitda")
            self.get_all_info_result["netIncomeAviToCommon"] =      self.scrap_from_statistics(htmlString: &htmlString, left: 185, name_of_stat: "netIncomeAviToCommon")
            self.get_all_info_result["dilutedEps"] =                self.scrap_from_statistics(htmlString: &htmlString, left: 192, name_of_stat: "dilutedEps")
            self.get_all_info_result["quarterlyEarningGrowth"] =    self.scrap_from_statistics(htmlString: &htmlString, left: 199, name_of_stat: "quarterlyEarningGrowth", end_of_table: true)
            
            self.get_all_info_result["totalCash"] =         self.scrap_from_statistics(htmlString: &htmlString, left: 211, name_of_stat: "totalCash")
            self.get_all_info_result["totalCashPerShare"] = self.scrap_from_statistics(htmlString: &htmlString, left: 218, name_of_stat: "totalCashPerShare")
            self.get_all_info_result["totalDebt"] =         self.scrap_from_statistics(htmlString: &htmlString, left: 225, name_of_stat: "totalDebt")
            self.get_all_info_result["totalDebtEquity"] =   self.scrap_from_statistics(htmlString: &htmlString, left: 232, name_of_stat: "totalDebtEquity")
            self.get_all_info_result["currentRatio"] =      self.scrap_from_statistics(htmlString: &htmlString, left: 239, name_of_stat: "currentRatio")
            self.get_all_info_result["bookValuePerShare"] = self.scrap_from_statistics(htmlString: &htmlString, left: 246, name_of_stat: "bookValuePerShare", end_of_table: true)
            
            self.get_all_info_result["operatingCashFlow"] =     self.scrap_from_statistics(htmlString: &htmlString, left: 258, name_of_stat: "operatingCashFlow")
            self.get_all_info_result["leveredFreeCashFlow"] =   self.scrap_from_statistics(htmlString: &htmlString, left: 265, name_of_stat: "operatingCashFlow", end_of_div: true)
            
            self.get_all_info_result["beta"] =                          self.scrap_from_statistics(htmlString: &htmlString, left: 284, name_of_stat: "beta")
            self.get_all_info_result["fiftyTwoWeekChange"] =            self.scrap_from_statistics(htmlString: &htmlString, left: 291, name_of_stat: "fiftyTwoWeekChange")
            self.get_all_info_result["sp500FiftyTwoWeekChange"] =       self.scrap_from_statistics(htmlString: &htmlString, left: 298, name_of_stat: "sp500FiftyTwoWeekChange")
            self.get_all_info_result["fiftyTwoWeekHigh"] =              self.scrap_from_statistics(htmlString: &htmlString, left: 305, name_of_stat: "fiftyTwoWeekHigh")
            self.get_all_info_result["fiftyTwoWeekLow"] =               self.scrap_from_statistics(htmlString: &htmlString, left: 312, name_of_stat: "fiftyTwoWeekLow")
            self.get_all_info_result["fiftyDayMovingAverage"] =         self.scrap_from_statistics(htmlString: &htmlString, left: 319, name_of_stat: "fiftyDayMovingAverage")
            self.get_all_info_result["twoHundredDayMovingAverage"] =    self.scrap_from_statistics(htmlString: &htmlString, left: 326, name_of_stat: "twoHundredDayMovingAverage", end_of_table: true)
            
            self.get_all_info_result["avgVolthreeMonth"] =                  self.scrap_from_statistics(htmlString: &htmlString, left: 338, name_of_stat: "avgVolthreeMonth")
            self.get_all_info_result["avgBoltenDay"] =                      self.scrap_from_statistics(htmlString: &htmlString, left: 345, name_of_stat: "avgBoltenDay")
            self.get_all_info_result["sharesOutstanding"] =                 self.scrap_from_statistics(htmlString: &htmlString, left: 352, name_of_stat: "sharesOutstanding")
            self.get_all_info_result["float"] =                             self.scrap_from_statistics(htmlString: &htmlString, left: 359, name_of_stat: "float")
            self.get_all_info_result["percentHeldByInsiders"] =             self.scrap_from_statistics(htmlString: &htmlString, left: 366, name_of_stat: "percentHeldByInsiders")
            self.get_all_info_result["percentHeldByInstitutions"] =         self.scrap_from_statistics(htmlString: &htmlString, left: 373, name_of_stat: "percentHeldByInstitutions")
            self.get_all_info_result["sharesShort"] =                       self.scrap_from_statistics(htmlString: &htmlString, left: 380, name_of_stat: "sharesShort")
            self.get_all_info_result["shortRatio"] =                        self.scrap_from_statistics(htmlString: &htmlString, left: 387, name_of_stat: "shortRatio")
            self.get_all_info_result["shortPercentOfFloat"] =               self.scrap_from_statistics(htmlString: &htmlString, left: 394, name_of_stat: "shortPercentOfFloat")
            self.get_all_info_result["shortPercentOfSharesOutstanding"] =   self.scrap_from_statistics(htmlString: &htmlString, left: 401, name_of_stat: "shortPercentOfSharesOutstanding")
            self.get_all_info_result["sharesShortPriorMonth"] =             self.scrap_from_statistics(htmlString: &htmlString, left: 408, name_of_stat: "sharesShortPriorMonth", end_of_table: true)
            
            self.get_all_info_result["forwardAnnualDividendRate"] =     self.scrap_from_statistics(htmlString: &htmlString, left: 420, name_of_stat: "forwardAnnualDividendRate")
            self.get_all_info_result["forwardAnnualDividendYield"] =    self.scrap_from_statistics(htmlString: &htmlString, left: 427, name_of_stat: "forwardAnnualDividendYield")
            self.get_all_info_result["trailingAnnualDividendRate"] =    self.scrap_from_statistics(htmlString: &htmlString, left: 434, name_of_stat: "trailingAnnualDividendRate")
            self.get_all_info_result["trailingAnnualDividendYield"] =   self.scrap_from_statistics(htmlString: &htmlString, left: 441, name_of_stat: "trailingAnnualDividendYield")
            self.get_all_info_result["fiveYearAverageDividentYield"] =  self.scrap_from_statistics(htmlString: &htmlString, left: 448, name_of_stat: "fiveYearAverageDividentYield")
            self.get_all_info_result["payoutRatio"] =                   self.scrap_from_statistics(htmlString: &htmlString, left: 455, name_of_stat: "payoutRatio")
            self.get_all_info_result["dividendDate"] =                  self.scrap_from_statistics(htmlString: &htmlString, left: 462, name_of_stat: "dividendDate")
            self.get_all_info_result["exDividendDate"] =                self.scrap_from_statistics(htmlString: &htmlString, left: 469, name_of_stat: "exDividendDate")
            self.get_all_info_result["lastSplitFactor"] =               self.scrap_from_statistics(htmlString: &htmlString, left: 476, name_of_stat: "lastSplitFactor")
            self.get_all_info_result["lastSplitDate"] =                 lastSplitDate
            
            self.get_all_info_result["lastPrice"] =  lastPrice
            
            semaphore.signal()
        }
        
        task.resume()
    }
    
    
    private func get_info_from_profile(symbol: String, semaphore: DispatchSemaphore) {
        let url = URL(string: baseURL + symbol + profileURL + symbol)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                print("data was nil")
                return
            }
            guard let htmlString = String(data: data, encoding: .utf8) else {
                print("couldn't cast data into String")
                return
            }
            
            // parse for sector
            var error = false
            var leftString = """
            <span class="Fw(600)" data-reactid="21">
            """
            var rightString = """
            </span><br data-reactid="22"/>
            """
            var leftSideRange = htmlString.range(of: leftString)
            var rightSideRange = htmlString.range(of: rightString)
            var rangeOfTheData = htmlString.startIndex ..< htmlString.startIndex
            var sector = ""
            if leftSideRange == nil {
                print("couldn't find left range when parsing for sector")
                error = true
            }
            if rightSideRange == nil {
                print("couldn't find right range when parsing for sector")
                error = true
            }
            
            if !error {
                rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
                sector = String(htmlString[rangeOfTheData])
            }
            
            // parse for industry
            error = false
            leftString = """
            <span class="Fw(600)" data-reactid="25">
            """
            rightString = """
            </span><br data-reactid="26"/>
            """
            leftSideRange = htmlString.range(of: leftString)
            rightSideRange = htmlString.range(of: rightString)
            var industry = ""
            if leftSideRange == nil {
                print("couldn't find left range when parsing for industry")
                error = true
            }
            if rightSideRange == nil {
                print("couldn't find right range when parsing for industry")
                error = true
            }
            if !error {
                rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
                industry = String(htmlString[rangeOfTheData])
            }
            
            industry = industry.replacingOccurrences(of: "&amp;", with: "&")
            
            // parse for fullTimeEmployees
            error = false
            leftString = """
            <span data-reactid="30">
            """
            rightString = """
            </span></span></p></div></div></div><div class="" data-reactid="31">
            """
            leftSideRange = htmlString.range(of: leftString)
            rightSideRange = htmlString.range(of: rightString)
            var fullTimeEmployees = ""
            if leftSideRange == nil {
                print("couldn't find left range when parsing for fullTimeEmployees")
                error = true
            }
            if rightSideRange == nil {
                print("couldn't find right range when parsing for fullTimeEmployees")
                error = true
            }
            if !error {
                rangeOfTheData = leftSideRange!.upperBound..<rightSideRange!.lowerBound
                fullTimeEmployees = String(htmlString[rangeOfTheData])
            }
            
            self.get_all_info_result["sector"] = sector
            self.get_all_info_result["industry"] = industry
            self.get_all_info_result["fullTimeEmployees"] = fullTimeEmployees
            semaphore.signal()
        }
        
        task.resume()
        
    }
}
