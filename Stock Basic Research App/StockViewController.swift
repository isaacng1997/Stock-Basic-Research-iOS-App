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

    var sym: String = ""
    let favoriteEntity = "Favorite"
    let stockInfoEntity = "StockInfo"
    
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    let toggleEditSelector = #selector(favoriteButtonTap)
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let context = appDelegate.persistentContainer.viewContext
        
        // change button if this stock is favorited
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: favoriteEntity)
        fetchRequest.predicate = NSPredicate(format: "symbol = %@", sym)
        
        do {
            let test = try context.fetch(fetchRequest)
            if test.count > 0 {
                let stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: toggleEditSelector)
                navigationItem.rightBarButtonItem = stopBarButtonItem
                setEditing(true, animated: true)
            }
        } catch {
            fatalError("Error in StockViewController: Failed fetch while loading page.")
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
            let stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: toggleEditSelector)
            navigationItem.rightBarButtonItem = stopBarButtonItem
            setEditing(true, animated: true)
            
            // add to core data
            let c = StockDataRetriever.get_stock_info(context: context,
                                                      entity: NSEntityDescription.entity(forEntityName: stockInfoEntity, in: context)!,
                                                      symbol: sym)
            let stock = NSManagedObject(entity: entity, insertInto: context)
            stock.setValue(sym, forKey: "symbol")
            stock.setValue(c.value(forKey: "name"), forKey: "name")
            stock.setValue(c.value(forKey: "lastPrice"), forKey: "lastPrice")
            
        case UIBarButtonItem.SystemItem.stop.rawValue:
            let addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: toggleEditSelector)
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
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
