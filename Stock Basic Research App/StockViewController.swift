//
//  StockViewController.swift
//  Stock Basic Research App
//
//  Created by Isaac Ng on 5/19/19.
//  Copyright © 2019 Isaac Ng. All rights reserved.
//

import UIKit
import CoreData

class StockViewController: UIViewController {

    var sym = ""
    var name = ""
    var lastPrice = ""
    let favoriteEntity = "Favorite"
    let stockInfoEntity = "StockInfo"
    
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    let toggleEditSelector = #selector(favoriteButtonTap)
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var stopBarButtonItem = UIBarButtonItem()
    var addBarButtonItem = UIBarButtonItem()
    
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    // 1 = 1d; 2 = 1w; 3 = 1m; 4 = 3m 5 = 1y; 6 = 5y
    var graphRange = 1
    
    var stockInfo:NSManagedObject = NSManagedObject()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        symbolLabel.text = sym
        nameLabel.text = name
        priceLabel.text = lastPrice

        // set up add/stop buttons
        stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: toggleEditSelector)
        addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: toggleEditSelector)
        
        // change button if this stock is favorited
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: favoriteEntity)
        fetchRequest.predicate = NSPredicate(format: "symbol = %@", sym)
        
        do {
            let test = try context.fetch(fetchRequest)
            if test.count > 0 {
                navigationItem.rightBarButtonItem = stopBarButtonItem
                setEditing(true, animated: true)
            }
        } catch {
            fatalError("Error in StockViewController: Failed fetch while loading page.")
        }
        DispatchQueue.global(qos: .background).async { [weak self] in
            let retrieved = StockDataRetriever.get_stock_info(context: context, symbol: self!.sym)
            DispatchQueue.main.async {
                self?.stockInfo = retrieved
                self?.nameLabel.text = self?.stockInfo.value(forKey: "name") as! String?
                self?.priceLabel.text = self?.stockInfo.value(forKey: "lastPrice") as! String?
            }
        }
    }
    
    @IBAction func favoriteButtonTap(_ sender: UIBarButtonItem) {
        guard let systemItem = sender.value(forKey: "systemItem") as? Int else {
            fatalError("Error in StockViewController: can't find systemItem")
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: favoriteEntity, in: context)!

        // switch between add and stop button, and add/remove stock symbol from favorite accordingly
        switch systemItem {
        case UIBarButtonItem.SystemItem.add.rawValue:
            // switch to stop button
            
            navigationItem.rightBarButtonItem = stopBarButtonItem
            setEditing(true, animated: true)
            
            // add to core data
            let c = StockDataRetriever.get_stock_info(context: context,
                                                      symbol: sym)
            let stock = NSManagedObject(entity: entity, insertInto: context)
            stock.setValue(sym, forKey: "symbol")
            stock.setValue(c.value(forKey: "name"), forKey: "name")
            stock.setValue(c.value(forKey: "lastPrice"), forKey: "lastPrice")
            
        case UIBarButtonItem.SystemItem.stop.rawValue:
            // switch to add button
            
            navigationItem.rightBarButtonItem = addBarButtonItem
            setEditing(false, animated: true)
            
            // remove from core data
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: favoriteEntity)
            fetchRequest.predicate = NSPredicate(format: "symbol = %@", sym)
            
            do {
                let test = try context.fetch(fetchRequest)
                let objectToDelete = test[0] as! NSManagedObject
                context.delete(objectToDelete)
            } catch {
                fatalError("Error in StockViewController: Failed fetch while deleting.")
            }
            
        default:
            fatalError("Error in StockViewController: UIBarButtonItem ststem item not recognized")
        }
        
        do {
            try context.save()
        } catch let error as NSError {
            fatalError("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    @IBAction func oneDayButtonPressed(_ sender: Any) {
        self.graphRange = 1
    }
    
    @IBAction func oneWeekButtonPressed(_ sender: Any) {
        self.graphRange = 2
    }
    
    @IBAction func oneMonthButtonPressed(_ sender: Any) {
        self.graphRange = 3
    }
    
    @IBAction func threeMonthButtonPressed(_ sender: Any) {
        self.graphRange = 4
    }
    
    @IBAction func oneYearButtonPressed(_ sender: Any) {
        self.graphRange = 5
    }
    
    @IBAction func fiveYearButtonPressed(_ sender: Any) {
        self.graphRange = 6
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
