//
//  HomeTableViewController.swift
//  Stock Basic Research App
//
//  Created by Isaac Ng on 5/19/19.
//  Copyright © 2019 Isaac Ng. All rights reserved.
//

import UIKit
import CoreData

class HomeTableViewController: UITableViewController {
    
    var favoriteStockSymbolList:Array<NSManagedObject> = []
    
    let favoriteEntity = "Favorite"
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var updating = false        // prevent spamming the update button
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        favoriteStockSymbolList = []
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: favoriteEntity)
        let sort = NSSortDescriptor(key: "symbol", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        do {
            let favorites = try context.fetch(fetchRequest)
            for i in 0 ..< favorites.count {
                let row = favorites[i] as! NSManagedObject
                favoriteStockSymbolList.append(row)
            }
        } catch {
            fatalError("Error in HoneTableViewController while fetch favorites")
        }
        
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteStockSymbolList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "HomeTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? HomeTableViewCell else {
            fatalError("The dequeued cell is not an instance of HomeTableViewCell.")
        }
        let cellStock = favoriteStockSymbolList[indexPath.row]
        cell.symbolLabel.text = cellStock.value(forKey: "symbol") as? String
        cell.nameLabel.text = cellStock.value(forKey: "name") as? String
        cell.priceLabel.text = cellStock.value(forKey: "lastPrice") as? String
        
        return cell
    }
    
    @IBAction func refreshButton(_ sender: Any) {
        if(updating) {
            return
        }
        
        updating = true
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: favoriteEntity)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                let results = try context.fetch(fetchRequest)
                for i in 0 ..< results.count {
                    let favStock = results[i] as! NSManagedObject
                    let lastPrice = StockDataRetriever.get_newest_price(symbol: favStock.value(forKey: "symbol") as! String)
                    favStock.setValue(lastPrice, forKey: "lastPrice")
                }
            } catch {
                fatalError("Error in HomeTableViewController: Failed fetch while refreshing.")
            }
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updating = false
            }
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let stockViewController = segue.destination as? StockViewController else {
            // not going to stockView
            return
        }
        
        guard let selectedStockCell = sender as? HomeTableViewCell else {
            fatalError("Unexpected sender: \(sender ?? "unknown")")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedStockCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        
        let selectedStock = favoriteStockSymbolList[indexPath.row]
        stockViewController.sym = selectedStock.value(forKey: "symbol") as! String
        stockViewController.title = selectedStock.value(forKey: "symbol") as? String
    }

}
