//
//  StockDataRetriever.swift
//  Stock Basic Research App
//
//  Created by Isaac Ng on 5/24/19.
//  Copyright © 2019 Isaac Ng. All rights reserved.
//

import Foundation
import CoreData

let stockInfoEntity = "StockInfo"

class StockDataRetriever {

    static func get_stock_info(context: NSManagedObjectContext,
                        entity: NSEntityDescription,
                        symbol: String) -> NSManagedObject {
        var stock:NSManagedObject
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: stockInfoEntity)
        fetchRequest.predicate = NSPredicate(format: "symbol = %@", symbol)
        
        do {
            let results = try context.fetch(fetchRequest) as! [NSManagedObject]
            
            if results.count > 1 {
                // there should only be one record: Delete all but one if there is more than one record
                for i in 1..<results.count {
                    context.delete(results[i])
                }
                stock = results[0]
            }
            else if results.count == 1 {
                // There is already a record; update instead
                stock = results[0]
            }
            else {
                stock = NSManagedObject(entity: entity, insertInto: context)
            }
            
            let c = YahooFinanceScraper.get(symbol: symbol)
            stock.setValuesForKeys(c.asDictionary)
            
        } catch {
            fatalError("Error in StockDataRetriever: (1).")
        }
        
        do {
            try context.save()
        } catch let error as NSError {
            fatalError("Could not save. \(error), \(error.userInfo)")
        }
        
        return stock
    }
}
