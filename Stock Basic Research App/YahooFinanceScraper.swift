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
    
    var revenue: String
    var revenuePerShare: String
    var quarterlyRevenueGrowth: String
    var grossProfit: String
    var ebitda: String
    var netIncomeAviToCommon: String
    var dilutedEps: String
    var quarterlyEarningGrowth: String
    
    var totalCash: String
    var totalCashPerShare: String
    var totalDebt: String
    var totalDebtEquity: String
    var currentRatio: String
    var bookValuePerShare: String
    
    var operatingCashFlow: String
    var leveredFreeCashFlow: String
    
    var beta: String
    var fiftyTwoWeekChange: String
    var sp500FiftyTwoWeekChange: String
    var fiftyTwoWeekHigh: String
    var fiftyTwoWeekLow: String
    var fiftyDayMovingAverage: String
    var twoHundredDayMovingAverage: String
    
    var avgVolthreeMonth: String
    var avgBoltenDay: String
    var sharesOutstanding: String
    var float: String
    var percentHeldByInsiders: String
    var percentHeldByInstitutions: String
    var sharesShort: String
    var shortRatio: String
    var shortPercentOfFloat: String
    var shortPercentOfSharesOutstanding: String
    var sharesShortPriorMonth: String
    
    var forwardAnnualDividendRate: String
    var forwardAnnualDividendYield: String
    var trailingAnnualDividendRate: String
    var trailingAnnualDividendYield: String
    var fiveYearAverageDividentYield: String
    var payoutRatio: String
    var dividendDate: String
    var exDividendDate: String
    var lastSplitFactor: String
    var lastSplitDate: String
    
    var sector: String
    var industry: String
    var fullTimeEmployees: String
    
    var lastPrice: String
    
    var asDictionary : [String:Any] {
        let mirror = Mirror(reflecting: self)
        let dict = Dictionary(uniqueKeysWithValues: mirror.children.lazy.map({ (label:String?,value:Any) -> (String,Any)? in
            guard label != nil else { return nil }
            return (label!,value)
        }).compactMap{ $0 })
        return dict
    }
}

var company_dictionary:[String:Company] = [:]
var ready:[String:Bool] = [:]

class YahooFinanceScraper {
    
    static func get(symbol: String) -> Company {
        get_basic_info(symbol: symbol)
        while(ready[symbol]! == false) {
            sleep(1)
        }
        return company_dictionary[symbol]!
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
    
    static func scrap_from_statistics(htmlString: inout String,
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
    
    
    private static func get_profile_info(symbol: String) {
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
            
            
            company_dictionary[symbol]!.sector = sector
            company_dictionary[symbol]!.industry = industry
            company_dictionary[symbol]!.fullTimeEmployees = fullTimeEmployees
            
            ready[symbol] = true
        }
        
        task.resume()
        
    }
    
    
    static func get_basic_info(symbol: String) {
        ready[symbol] = false
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
            }
            
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
            
            let c = Company(symbol: symbol,
                            name: name,
                            marketCap:              self.scrap_from_statistics(htmlString: &htmlString, left: 19, name_of_stat: "marketCap"),
                            enterpriseValue:        self.scrap_from_statistics(htmlString: &htmlString, left: 26, name_of_stat: "enterpriseValue"),
                            trailingPE:             self.scrap_from_statistics(htmlString: &htmlString, left: 33, name_of_stat: "trailingPE"),
                            forwardPE:              self.scrap_from_statistics(htmlString: &htmlString, left: 40, name_of_stat: "forwardPE"),
                            pegRatio:               self.scrap_from_statistics(htmlString: &htmlString, left: 47, name_of_stat: "pegRatio"),
                            priceSale:              self.scrap_from_statistics(htmlString: &htmlString, left: 54, name_of_stat: "priceSale"),
                            priceBook:              self.scrap_from_statistics(htmlString: &htmlString, left: 61, name_of_stat: "priceBook"),
                            enterpriseValueRevenue: self.scrap_from_statistics(htmlString: &htmlString, left: 68, name_of_stat: "enterpriseValueRevenue"),
                            enterpriseValueEBITDA:  self.scrap_from_statistics(htmlString: &htmlString, left: 75, name_of_stat: "enterpriseValueEBITDA", end_of_div: true),
                            
                            profitMargin:       self.scrap_from_statistics(htmlString: &htmlString, left: 112, name_of_stat: "profitMargin"),
                            operativeMargin:    self.scrap_from_statistics(htmlString: &htmlString, left: 119, name_of_stat: "operativeMargin", end_of_table: true),
                            
                            returnOnAssets: self.scrap_from_statistics(htmlString: &htmlString, left: 131, name_of_stat: "returnOnAssets"),
                            returnOnEquity: self.scrap_from_statistics(htmlString: &htmlString, left: 138, name_of_stat: "returnOnEquity", end_of_table: true),
                            
                            revenue:                self.scrap_from_statistics(htmlString: &htmlString, left: 150, name_of_stat: "revenue"),
                            revenuePerShare:        self.scrap_from_statistics(htmlString: &htmlString, left: 157, name_of_stat: "revenuePerShare"),
                            quarterlyRevenueGrowth: self.scrap_from_statistics(htmlString: &htmlString, left: 164, name_of_stat: "quarterlyRevenueGrowth"),
                            grossProfit:            self.scrap_from_statistics(htmlString: &htmlString, left: 171, name_of_stat: "grossProfit"),
                            ebitda:                 self.scrap_from_statistics(htmlString: &htmlString, left: 178, name_of_stat: "ebitda"),
                            netIncomeAviToCommon:   self.scrap_from_statistics(htmlString: &htmlString, left: 185, name_of_stat: "netIncomeAviToCommon"),
                            dilutedEps:             self.scrap_from_statistics(htmlString: &htmlString, left: 192, name_of_stat: "dilutedEps"),
                            quarterlyEarningGrowth: self.scrap_from_statistics(htmlString: &htmlString, left: 199, name_of_stat: "quarterlyEarningGrowth", end_of_table: true),
                            
                            totalCash:          self.scrap_from_statistics(htmlString: &htmlString, left: 211, name_of_stat: "totalCash"),
                            totalCashPerShare:  self.scrap_from_statistics(htmlString: &htmlString, left: 218, name_of_stat: "totalCashPerShare"),
                            totalDebt:          self.scrap_from_statistics(htmlString: &htmlString, left: 225, name_of_stat: "totalDebt"),
                            totalDebtEquity:    self.scrap_from_statistics(htmlString: &htmlString, left: 232, name_of_stat: "totalDebtEquity"),
                            currentRatio:       self.scrap_from_statistics(htmlString: &htmlString, left: 239, name_of_stat: "currentRatio"),
                            bookValuePerShare:  self.scrap_from_statistics(htmlString: &htmlString, left: 246, name_of_stat: "bookValuePerShare", end_of_table: true),
                            
                            operatingCashFlow:      self.scrap_from_statistics(htmlString: &htmlString, left: 258, name_of_stat: "operatingCashFlow"),
                            leveredFreeCashFlow:    self.scrap_from_statistics(htmlString: &htmlString, left: 265, name_of_stat: "operatingCashFlow", end_of_div: true),
                            
                            beta:                       self.scrap_from_statistics(htmlString: &htmlString, left: 284, name_of_stat: "beta"),
                            fiftyTwoWeekChange:         self.scrap_from_statistics(htmlString: &htmlString, left: 291, name_of_stat: "fiftyTwoWeekChange"),
                            sp500FiftyTwoWeekChange:    self.scrap_from_statistics(htmlString: &htmlString, left: 298, name_of_stat: "sp500FiftyTwoWeekChange"),
                            fiftyTwoWeekHigh:           self.scrap_from_statistics(htmlString: &htmlString, left: 305, name_of_stat: "fiftyTwoWeekHigh"),
                            fiftyTwoWeekLow:            self.scrap_from_statistics(htmlString: &htmlString, left: 312, name_of_stat: "fiftyTwoWeekLow"),
                            fiftyDayMovingAverage:      self.scrap_from_statistics(htmlString: &htmlString, left: 319, name_of_stat: "fiftyDayMovingAverage"),
                            twoHundredDayMovingAverage: self.scrap_from_statistics(htmlString: &htmlString, left: 326, name_of_stat: "twoHundredDayMovingAverage", end_of_table: true),
                            
                            avgVolthreeMonth:                   self.scrap_from_statistics(htmlString: &htmlString, left: 338, name_of_stat: "avgVolthreeMonth"),
                            avgBoltenDay:                       self.scrap_from_statistics(htmlString: &htmlString, left: 345, name_of_stat: "avgBoltenDay"),
                            sharesOutstanding:                  self.scrap_from_statistics(htmlString: &htmlString, left: 352, name_of_stat: "sharesOutstanding"),
                            float:                              self.scrap_from_statistics(htmlString: &htmlString, left: 359, name_of_stat: "float"),
                            percentHeldByInsiders:              self.scrap_from_statistics(htmlString: &htmlString, left: 366, name_of_stat: "percentHeldByInsiders"),
                            percentHeldByInstitutions:          self.scrap_from_statistics(htmlString: &htmlString, left: 373, name_of_stat: "percentHeldByInstitutions"),
                            sharesShort:                        self.scrap_from_statistics(htmlString: &htmlString, left: 380, name_of_stat: "sharesShort"),
                            shortRatio:                         self.scrap_from_statistics(htmlString: &htmlString, left: 387, name_of_stat: "shortRatio"),
                            shortPercentOfFloat:                self.scrap_from_statistics(htmlString: &htmlString, left: 394, name_of_stat: "shortPercentOfFloat"),
                            shortPercentOfSharesOutstanding:    self.scrap_from_statistics(htmlString: &htmlString, left: 401, name_of_stat: "shortPercentOfSharesOutstanding"),
                            sharesShortPriorMonth:              self.scrap_from_statistics(htmlString: &htmlString, left: 408, name_of_stat: "sharesShortPriorMonth", end_of_table: true),
                            
                            forwardAnnualDividendRate:      self.scrap_from_statistics(htmlString: &htmlString, left: 420, name_of_stat: "forwardAnnualDividendRate"),
                            forwardAnnualDividendYield:     self.scrap_from_statistics(htmlString: &htmlString, left: 427, name_of_stat: "forwardAnnualDividendYield"),
                            trailingAnnualDividendRate:     self.scrap_from_statistics(htmlString: &htmlString, left: 434, name_of_stat: "trailingAnnualDividendRate"),
                            trailingAnnualDividendYield:    self.scrap_from_statistics(htmlString: &htmlString, left: 441, name_of_stat: "trailingAnnualDividendYield"),
                            fiveYearAverageDividentYield:   self.scrap_from_statistics(htmlString: &htmlString, left: 448, name_of_stat: "fiveYearAverageDividentYield"),
                            payoutRatio:                    self.scrap_from_statistics(htmlString: &htmlString, left: 455, name_of_stat: "payoutRatio"),
                            dividendDate:                   self.scrap_from_statistics(htmlString: &htmlString, left: 462, name_of_stat: "dividendDate"),
                            exDividendDate:                 self.scrap_from_statistics(htmlString: &htmlString, left: 469, name_of_stat: "exDividendDate"),
                            lastSplitFactor:                self.scrap_from_statistics(htmlString: &htmlString, left: 476, name_of_stat: "lastSplitFactor"),
                            lastSplitDate:                  lastSplitDate,
                            
                            sector: "",
                            industry: "",
                            fullTimeEmployees: "",
                            
                            lastPrice: lastPrice
            )
            company_dictionary[symbol] = c
            get_profile_info(symbol: symbol)
        }
        
        task.resume()
    }
}
